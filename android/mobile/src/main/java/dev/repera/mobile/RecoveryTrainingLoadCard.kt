package dev.repera.mobile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import java.time.Instant
import java.util.Locale

/** Observed minutes only; not a proprietary physiological load score. */
internal data class RecoveryTrainingLoad(
    val recentMinutes: Double,
    val previousMinutes: Double
) {
    val relativeChangePercent: Int?
        get() = if (recentMinutes > 0 && previousMinutes > 0)
            ((recentMinutes / previousMinutes - 1.0) * 100).toInt() else null
}

internal object RecoveryTrainingLoadCalculator {
    fun fromOverview(overview: StateOverview?, nowMillis: Long): RecoveryTrainingLoad {
        val currentStart = nowMillis - 7L * 86_400_000L
        val priorStart = nowMillis - 14L * 86_400_000L
        val sessions = overview?.completeHistory.orEmpty()
            .distinctBy { it.id }
            .filter { it.timerDetails == null && it.finishedAtIso != null }
            .mapNotNull { workout ->
                val end = workout.finishedAtIso?.let {
                    runCatching { Instant.parse(it).toEpochMilli() }.getOrNull()
                } ?: return@mapNotNull null
                val start = workout.startedAtIso?.let {
                    runCatching { Instant.parse(it).toEpochMilli() }.getOrNull()
                } ?: end - (workout.displayDurationMinutes() * 60_000.0).toLong()
                val minutes = workout.displayDurationMinutes()
                if (!minutes.isFinite() || minutes <= 0 || end > nowMillis || end < priorStart) null
                else Triple(start, end, minutes)
            }
        val externals = overview?.externalHealthHistory.orEmpty()
            .distinctBy { it.id }
            .filter { ext ->
                ext.minutes.isFinite() && ext.minutes > 0 && ext.endMillis <= nowMillis &&
                    ext.endMillis >= priorStart &&
                    sessions.none { (start, end, minutes) ->
                        // A mirrored Health Connect workout should not duplicate the
                        // same Repera session. Reader also excludes linked IDs.
                        kotlin.math.abs(ext.startMillis - start) < 90_000L &&
                            kotlin.math.abs(ext.endMillis - end) < 180_000L &&
                            kotlin.math.abs(ext.minutes - minutes) < 3.0
                    }
            }
        val current = sessions.filter { it.second > currentStart }
            .sumOf { it.third } +
            externals.filter { it.endMillis > currentStart }.sumOf { it.minutes }
        val previous = sessions.filter { it.second <= currentStart }
            .sumOf { it.third } +
            externals.filter { it.endMillis <= currentStart }.sumOf { it.minutes }
        return RecoveryTrainingLoad(current, previous)
    }
}

@Composable
internal fun RecoveryTrainingLoadCard(overview: StateOverview?) {
    val today = System.currentTimeMillis()
    val load = remember(overview, today / 60_000L) {
        RecoveryTrainingLoadCalculator.fromOverview(overview, today)
    }
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        ReperaSectionTitle("Carga · últimas dos semanas")
        ReperaCard(Modifier.fillMaxWidth()) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text("Minutos de entrenamiento registrados",
                    style = MaterialTheme.typography.titleMedium)
                Row {
                    Text(
                        if (load.recentMinutes > 0) load.recentMinutes.toInt().toString() else "—",
                        style = MaterialTheme.typography.headlineMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.primary
                    )
                    Spacer(Modifier.padding(4.dp))
                    Text("min · últimos 7 días", style = MaterialTheme.typography.bodySmall)
                }
                Text(
                    "7 días anteriores: " + (if (load.previousMinutes > 0)
                        "${load.previousMinutes.toInt()} min" else "sin sesiones con duración"),
                    style = MaterialTheme.typography.bodySmall
                )
                load.relativeChangePercent?.let { percent ->
                    Text(
                        "Variación: " + (if (percent > 0) "+" else "") + "\u0024{percent}% · tiempo registrado, no intensidad fisiológica",
                        style = MaterialTheme.typography.labelSmall
                    )
                }
                Text(
                    "Sesiones terminadas y Health Connect sin solapes identificables. " +
                        "Sin dato real se muestra —; no es una recomendación médica.",
                    style = MaterialTheme.typography.labelSmall
                )
            }
        }
    }
}
