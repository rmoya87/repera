package dev.repera.mobile

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.size
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import dev.repera.domain.ReviewDimension
import dev.repera.domain.ScoreBasis
import dev.repera.domain.SessionReview

/**
 * Mismos factores visibles que Recuperación: KPI a la izquierda,
 * nota global a la derecha y confianza segmentada bajo ambos.
 * Sin interacción para desplegar cálculos ocultos ni estimaciones ficticias.
 */
private fun SessionReview.isVerified(): Boolean =
    scoreBasis == ScoreBasis.PERSONAL_HISTORY &&
        (indicators.size == ReviewDimension.entries.size ||
            (indicators.isEmpty() && vsHistorySummary != null)) &&
        (evidenceCoverage ?: 0.0) >= 0.60

@Suppress("UNUSED_PARAMETER")
@Composable
internal fun SessionReviewCard(review: SessionReview, startsExpanded: Boolean = false) {
    if (!review.isVerified()) return
    val personal = review.indicators.firstOrNull {
        it.dimension == ReviewDimension.PERSONAL_PROGRESS
    }?.score ?: review.overallScore.takeIf { review.indicators.isEmpty() }
    val performance = review.indicators.firstOrNull {
        it.dimension == ReviewDimension.WOD_PERFORMANCE
    }?.score ?: review.indicators.firstOrNull {
        it.dimension == ReviewDimension.PERSONAL_PROGRESS
    }?.score ?: review.overallScore

    ReperaCard(modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.fillMaxWidth().padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(13.dp)) {
            Row(Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                Column(Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(9.dp)) {
                    TrainingScoreMetric("Evolución personal", personal?.let { "${it}/10" } ?: "—")
                    TrainingScoreMetric("Rendimiento", "${performance}/10")
                    review.evidenceCoverage?.let {
                        TrainingScoreMetric("Cobertura", "${kotlin.math.round(it * 100).toInt()} %")
                    }
                }
                val accent = MaterialTheme.colorScheme.primary
                val track = MaterialTheme.colorScheme.surfaceVariant
                Box(Modifier.size(112.dp).semantics {
                    contentDescription = "Puntuación global de rendimiento ${review.overallScore} de 10"
                }, contentAlignment = Alignment.Center) {
                    Canvas(Modifier.fillMaxSize().padding(5.dp)) {
                        val stroke = 10.dp.toPx()
                        drawCircle(track, style = Stroke(stroke))
                        drawArc(accent, -90f, review.overallScore * 36f, false,
                            style = Stroke(stroke, cap = StrokeCap.Round))
                    }
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text("${review.overallScore}", fontSize = 36.sp, fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onSurface)
                        Text("de 10", style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            }
            TrainingScoreConfidenceBar(review.confidenceLabel)
            review.vsHistorySummary?.takeIf { it.isNotBlank() }?.let {
                Text(it, style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

@Composable
private fun TrainingScoreMetric(title: String, value: String) {
    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(title, style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(value, fontSize = 16.sp, fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurface)
    }
}

private enum class TrainingConfidence(val title: String) {
    LEARNING("Aprendiendo"),
    LOW("Baja"),
    MEDIUM("Media"),
    HIGH("Alta")
}

@Composable
internal fun TrainingScoreConfidenceBar(
    label: String?,
    caption: String = "Confianza",
    compactInProgress: Boolean = false,
    showSelectedLevelInCaption: Boolean = true
) {
    val normalized = label.orEmpty().lowercase(java.util.Locale.ROOT)
    val current = when {
        "alta" in normalized -> TrainingConfidence.HIGH
        "en construcción" in normalized -> TrainingConfidence.MEDIUM
        "media" in normalized -> TrainingConfidence.MEDIUM
        "baja" in normalized -> TrainingConfidence.LOW
        "construcción" in normalized || "construccion" in normalized -> TrainingConfidence.MEDIUM
        else -> TrainingConfidence.LEARNING
    }
    val levelTitle = if ("construcción" in normalized || "construccion" in normalized) {
        "En construcción"
    } else {
        current.title
    }
    val colors = MaterialTheme.colorScheme
    Column(
        Modifier.fillMaxWidth().semantics {
            contentDescription = "Confianza: $levelTitle"
        },
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Text(
            if (showSelectedLevelInCaption) "$caption · $levelTitle" else caption,
            style = MaterialTheme.typography.labelMedium,
            fontWeight = FontWeight.SemiBold,
            color = colors.onSurfaceVariant
        )
        // La tarjeta de Progreso limita la barra al 50 % del ancho.
        // El segmento seleccionado solo crece 1,5×, sin repetir el nivel del título.
        BoxWithConstraints(Modifier.fillMaxWidth()) {
            val barWidth = maxWidth * (if (compactInProgress) 0.5f else 1f)
            Row(
                Modifier.width(barWidth).height(22.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                TrainingConfidence.entries.forEach { tier ->
                    val selected = tier == current
                    val tint = when (tier) {
                        TrainingConfidence.LEARNING -> colors.onSurfaceVariant
                        TrainingConfidence.LOW -> colors.error
                        TrainingConfidence.MEDIUM -> colors.tertiary
                        TrainingConfidence.HIGH -> colors.primary
                    }
                    Box(
                        Modifier
                            .weight(if (selected) 1.5f else 1f)
                            .height(if (selected) 18.dp else 13.dp)
                            .clip(androidx.compose.foundation.shape.CircleShape)
                            .background(tint.copy(alpha = if (selected) 1f else 0.25f))
                    )
                }
            }
        }
    }
}

/**
 * Hoja post-entreno (SessionReviewSheet iOS): título + card + ✓ Listo.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun SessionReviewSheet(
    review: SessionReview,
    onDismiss: () -> Unit,
) {
    ReperaModalBottomSheet(onDismissRequest = onDismiss) {
        Column(modifier = Modifier.fillMaxWidth()
            .padding(horizontal = 16.dp)
            .padding(top = 28.dp)
            .padding(bottom = 18.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Row(modifier = Modifier.fillMaxWidth().heightIn(min = 40.dp),
                verticalAlignment = Alignment.CenterVertically) {
                Text("Tu rendimiento", fontSize = 23.sp, fontWeight = FontWeight.Bold,
                    modifier = Modifier.weight(1f))
                ReperaDoneCheckButton(onClick = onDismiss)
            }
            SessionReviewCard(review, startsExpanded = true)
        }
    }
}
