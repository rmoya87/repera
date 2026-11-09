package dev.repera.mobile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.Canvas
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.contentDescription
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
    val previousMinutes: Double,
    val dailyMinutes: List<Double> = emptyList()
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
        val zone = java.time.ZoneId.systemDefault()
        val today = java.time.Instant.ofEpochMilli(nowMillis).atZone(zone).toLocalDate()
        val daily = (13 downTo 0).map { offset ->
            val date = today.minusDays(offset.toLong())
            val own = sessions.filter {
                java.time.Instant.ofEpochMilli(it.second).atZone(zone).toLocalDate() == date
            }.sumOf { it.third }
            val health = externals.filter {
                java.time.Instant.ofEpochMilli(it.endMillis).atZone(zone).toLocalDate() == date
            }.sumOf { it.minutes }
            own + health
        }
        return RecoveryTrainingLoad(
            daily.takeLast(7).sum(), daily.take(7).sum(), daily
        )
    }
}

@Composable
internal fun RecoveryTrainingLoadCard(overview: StateOverview?) {
    val nowMillis = System.currentTimeMillis()
    val load = remember(overview, nowMillis / 60_000L) {
        RecoveryTrainingLoadCalculator.fromOverview(overview, nowMillis)
    }
    val green = MaterialTheme.colorScheme.primary
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        ReperaSectionTitle("Carga · 14 días")
        ReperaCard(Modifier.fillMaxWidth()) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Row(verticalAlignment = androidx.compose.ui.Alignment.Bottom) {
                    Text(
                        if (load.recentMinutes > 0) load.recentMinutes.toInt().toString() else "—",
                        style = MaterialTheme.typography.headlineMedium,
                        fontWeight = FontWeight.Bold,
                        color = green
                    )
                    Spacer(Modifier.width(7.dp))
                    Text("min · últimos 7 días", style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(bottom = 5.dp))
                    Spacer(Modifier.weight(1f))
                    Text(
                        if (load.previousMinutes > 0) "${load.previousMinutes.toInt()} min antes" else "— antes",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(bottom = 5.dp)
                    )
                }
                val values = load.dailyMinutes
                val peak = maxOf(30.0, (values.maxOrNull() ?: 0.0) * 1.12)
                Canvas(Modifier.fillMaxWidth().height(116.dp).semantics {
                    contentDescription = "Minutos registrados diariamente en catorce días: " +
                        "${load.recentMinutes.toInt()} minutos la última semana, " +
                        "${load.previousMinutes.toInt()} la semana anterior."
                }) {
                    if (values.size < 2) return@Canvas
                    val bottom = size.height - 4.dp.toPx()
                    val graphHeight = size.height - 16.dp.toPx()
                    val line = Path()
                    val area = Path()
                    values.forEachIndexed { index, value ->
                        val x = size.width * index / (values.size - 1).toFloat()
                        val y = bottom - (value / peak * graphHeight).toFloat()
                        if (index == 0) {
                            line.moveTo(x, y)
                            area.moveTo(x, bottom)
                            area.lineTo(x, y)
                        } else {
                            line.lineTo(x, y)
                            area.lineTo(x, y)
                        }
                    }
                    area.lineTo(size.width, bottom)
                    area.close()
                    drawPath(area, green.copy(alpha = 0.13f))
                    drawPath(line, green, style = Stroke(width = 2.2.dp.toPx()))
                }
                Row(modifier = Modifier.fillMaxWidth()) {
                    Text("Hace 14 días", style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Spacer(Modifier.weight(1f))
                    Text("Hoy", style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                if (load.recentMinutes == 0.0 && load.previousMinutes == 0.0) {
                    Text("Sin sesiones registradas",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
    }
}
