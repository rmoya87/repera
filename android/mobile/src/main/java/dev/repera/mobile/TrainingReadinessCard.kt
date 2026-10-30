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
 * (Sueño, Carga, VFC, Cardio) + puntuación a la derecha. Sin consejo ni disclaimer.
 */
@Composable
internal fun TrainingReadinessCard(recovery: RecoveryState) {
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        ReperaSectionTitle("Preparación para entrenar")
        ReperaCard(Modifier.fillMaxWidth()) {
            Column(
                Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                val ready = recovery.readiness
                if (ready == null) {
                    Text(
                        "Necesitamos datos de sueño y entrenamientos recientes",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                } else {
                    val score = ready.score.coerceIn(0.0, 10.0)
                    val tint = when {
                        score >= 8 -> MaterialTheme.colorScheme.primary
                        score >= 6 -> MaterialTheme.colorScheme.tertiary
                        else -> MaterialTheme.colorScheme.error
                    }
                    val cardiac = recovery.vitals.lastOrNull { it.day == java.time.LocalDate.now() }
                    val cardiacText = listOfNotNull(
                        cardiac?.hrvMilliseconds?.let { "${it.roundToInt()} ms" },
                        cardiac?.restingHeartRateBpm?.let { "${it.roundToInt()} lpm" }
                    ).joinToString(" · ").ifBlank { "Sin datos" }
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .height(IntrinsicSize.Min),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        Column(
                            Modifier.weight(1f),
                            verticalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            ReadinessFactor(
                                "Sueño",
                                recovery.lastNightHours?.let { "${formatWeight(it)} h" } ?: "Sin datos"
                            )
                            ReadinessFactor(
                                "Carga",
                                when {
                                    ready.fatiguePenalty >= 2.3 -> "Alta"
                                    ready.fatiguePenalty >= 1.1 -> "Moderada"
                                    else -> "Baja"
                                }
                            )
                            ReadinessFactor("VFC", cardiacText)
                            ReadinessFactor(
                                "Cardio",
                                ready.cardioMinutes48h?.let { "${it.roundToInt()} min" } ?: "Sin datos"
                            )
                        }
                        val track = MaterialTheme.colorScheme.surfaceVariant
                        Box(
                            Modifier
                                .fillMaxHeight()
                                .aspectRatio(1f)
                                .widthIn(min = 120.dp, max = 168.dp)
                                .semantics(mergeDescendants = true) {
                                    contentDescription = "Preparación ${score.roundToInt()} de 10"
                                },
                            contentAlignment = Alignment.Center
                        ) {
                            Canvas(Modifier.fillMaxSize().padding(8.dp)) {
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
                                    score.roundToInt().toString(),
                                    style = MaterialTheme.typography.headlineLarge,
                                    fontWeight = FontWeight.Bold
                                )
                                Text("de 10", style = MaterialTheme.typography.labelSmall)
                            }
                        }
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
