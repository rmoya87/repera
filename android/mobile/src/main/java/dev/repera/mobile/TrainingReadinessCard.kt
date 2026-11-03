package dev.repera.mobile

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.Alignment
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import kotlin.math.roundToInt

/**
 * Preparación: título fuera (ReperaSectionTitle). Dentro: métricas a la izquierda
 * (Sueño, Entrenamiento, VFC, Cardio) + puntuación a la derecha. Sin consejo ni disclaimer.
 */
@Composable
internal fun TrainingReadinessCard(recovery: RecoveryState) {
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        ReperaSectionTitle("Preparación para entrenar")
        ReperaCard(Modifier.fillMaxWidth()) {
            Column(
                Modifier.padding(horizontal = 12.dp, vertical = 12.dp),
                verticalArrangement = Arrangement.spacedBy(0.dp)
            ) {
                val ready = recovery.readiness
                run {
                    val score = ready?.score?.coerceIn(0.0, 10.0) ?: 0.0
                    val tint = when {
                        score >= 8 -> MaterialTheme.colorScheme.primary
                        score >= 6 -> MaterialTheme.colorScheme.tertiary
                        else -> MaterialTheme.colorScheme.error
                    }
                    val cardiac = recovery.vitals.lastOrNull {
                        it.hrvMilliseconds != null || it.restingHeartRateBpm != null
                    }
                    val cardiacText = listOfNotNull(
                        cardiac?.hrvMilliseconds?.let { "${it.roundToInt()} ms" },
                        cardiac?.restingHeartRateBpm?.let { "${it.roundToInt()} lpm" }
                    ).joinToString(" · ").ifBlank { "—" }.let { value ->
                        if (cardiac != null && cardiac.day != java.time.LocalDate.now())
                            "$value · ${cardiac.day}" else value
                    }
                    Row(
                        Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(14.dp)
                    ) {
                        Column(
                            Modifier.weight(1f),
                            verticalArrangement = Arrangement.spacedBy(7.dp)
                        ) {
                            ReadinessFactor(
                                "Sueño",
                                recovery.nights.lastOrNull { it.day == java.time.LocalDate.now() }
                                    ?.hours?.let { "${formatWeight(it)} h" } ?: "—"
                            )
                            ReadinessFactor(
                                "Entrenamiento",
                                recovery.trainingMinutes96h?.let { "${it.roundToInt()} min" } ?: "—"
                            )
                            ReadinessFactor("VFC · reposo", cardiacText)
                            ReadinessFactor(
                                "Cardio",
                                recovery.cardioAverageBpm?.let { "${it.roundToInt()} lpm" }
                                    ?: recovery.cardioMinutes48h?.let { "${it.roundToInt()} min" }
                                    ?: "—"
                            )
                        }
                        val track = MaterialTheme.colorScheme.surfaceVariant
                        Box(
                            Modifier
                                .size(124.dp)
                                .semantics(mergeDescendants = true) {
                                    contentDescription = if (ready == null)
                                        "Preparación actual sin puntuación"
                                    else "Preparación ${score.roundToInt()} de 10"
                                },
                            contentAlignment = Alignment.Center
                        ) {
                            Canvas(Modifier.fillMaxSize().padding(4.dp)) {
                                val stroke = 11.dp.toPx()
                                drawCircle(track, style = Stroke(stroke))
                                drawArc(
                                    tint,
                                    -90f,
                                    (score * 36).toFloat(),
                                    false,
                                    Offset.Zero,
                                    Size(size.width, size.height),
                                    style = Stroke(
                                        stroke,
                                        cap = androidx.compose.ui.graphics.StrokeCap.Round
                                    )
                                )
                            }
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Text(
                                    if (ready == null) "—" else score.roundToInt().toString(),
                                    style = MaterialTheme.typography.displaySmall,
                                    fontWeight = FontWeight.Bold
                                )
                                Text(
                                    "de 10",
                                    style = MaterialTheme.typography.labelMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    }
                    if (ready?.isPartial == true) {
                        Text(
                            "Estimación parcial · sin sueño registrado. Basada en carga real y constantes calibradas.",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    } else if (ready == null) {
                        val learned = dev.repera.domain.RecoveryEngine.vitalLearningDays(
                            java.time.LocalDate.now(), recovery.vitals
                        )
                        val message = if (recovery.trainingMinutes96h == null) {
                            "Repera está aprendiendo de ti. Necesita al menos 1 entrenamiento finalizado con duración medida durante los últimos 7 días."
                        } else {
                            "Repera está aprendiendo de ti. Sin sueño registrado necesita 7 días anteriores con pulso en reposo, VFC o respiración (\$learned/7) y una medición de hoy, o 1 noche de sueño."
                        }
                        Text(
                            message,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun ReadinessFactor(title: String, value: String) {
    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(
            title,
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            value,
            style = MaterialTheme.typography.bodyLarge,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurface
        )
    }
}
