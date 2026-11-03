package dev.repera.mobile

import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
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
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import dev.repera.domain.ReviewDimension
import dev.repera.domain.ReviewIndicator
import dev.repera.domain.ScoreBasis
import dev.repera.domain.SessionReview

/**
 * Port 1:1 de SessionReviewCard / SessionReviewSheet (iOS): una única fuente
 * de verdad para Inicio, Historial y fin de entreno. Nunca presenta
 * puntuaciones sin indicadores verificables: una review sin evidencia se
 * considera no evaluada y no se muestra.
 */
private fun SessionReview.isVerified(): Boolean =
    scoreBasis == ScoreBasis.PERSONAL_HISTORY &&
        (indicators.size == ReviewDimension.entries.size ||
            (indicators.isEmpty() && vsHistorySummary != null)) &&
        (evidenceCoverage ?: 0.0) >= 0.60

@Composable
internal fun SessionReviewCard(review: SessionReview, startsExpanded: Boolean = false) {
    if (!review.isVerified()) return
    var expanded by rememberSaveable(review.headline) { mutableStateOf(startsExpanded) }
    ReperaCard(modifier = Modifier.fillMaxWidth().animateContentSize()) {
        Column(modifier = Modifier.fillMaxWidth()) {
            TextButton(onClick = { expanded = !expanded },
                modifier = Modifier.fillMaxWidth()) {
                Row(modifier = Modifier.fillMaxWidth().padding(4.dp),
                    verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(88.dp), contentAlignment = Alignment.Center) {
                        val accent = MaterialTheme.colorScheme.primary
                        val track = MaterialTheme.colorScheme.surfaceVariant
                        Canvas(Modifier.fillMaxWidth().heightIn(min = 88.dp).padding(5.dp)) {
                            val stroke = 9.dp.toPx()
                            drawCircle(track, style = Stroke(stroke))
                            drawArc(accent, -90f, review.overallScore * 36f, false,
                                style = Stroke(stroke, cap = StrokeCap.Round))
                        }
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text("${review.overallScore}", fontSize = 31.sp,
                                fontWeight = FontWeight.Bold)
                            Text("de 10", style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text("Rendimiento personal", style = MaterialTheme.typography.titleSmall)
                        Text("Confianza: ${review.confidenceLabel ?: "En construcción"}",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                        review.evidenceCoverage?.let {
                            Text("${kotlin.math.round(it * 100).toInt()}% del trabajo con referencias",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        review.indicators.firstOrNull { it.score != null }?.let { metric ->
                            Text("${metric.dimension.title} · ${metric.score}/10",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                    Text(if (expanded) "▲" else "▼", fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            if (expanded) {
                Column(modifier = Modifier.padding(horizontal = 14.dp).padding(bottom = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    review.indicators.forEach { IndicatorRow(it) }
                    Text(
                        if (review.indicators.isEmpty())
                            listOfNotNull(review.vsHistorySummary, review.vsStandardSummary).joinToString(" ")
                        else "Solo se puntúa el rendimiento con al menos dos días anteriores " +
                            "comparables. Las series registradas no aportan puntos; la nota no " +
                            "mide técnica ni esfuerzo percibido.",
                        fontSize = 11.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
    }
}

@Composable
private fun IndicatorRow(indicator: ReviewIndicator) {
    ReperaCard(modifier = Modifier.fillMaxWidth()) {
        Row(modifier = Modifier.fillMaxWidth().padding(12.dp),
            verticalAlignment = Alignment.Top) {
            Column(modifier = Modifier.weight(1f)) {
                Text(indicator.dimension.title, fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold)
                if (indicator.score != null && indicator.comparisonLevel != null) {
                    val tier = indicator.comparisonLevel
                    Text(when (tier) {
                        1 -> "Nivel 1 · Referencia idéntica"
                        2 -> "Nivel 2 · Mismo ejercicio"
                        else -> "Nivel 3 · Estímulo comparable"
                    }, fontSize = 11.sp, fontWeight = FontWeight.SemiBold,
                        color = if (tier == 3) MaterialTheme.colorScheme.onSurfaceVariant
                        else brandGreen)
                }
                Text(indicator.detail, fontSize = 12.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Spacer(Modifier.width(8.dp))
            if (indicator.score != null) {
                Text("${indicator.score}/10", fontSize = 17.sp,
                    fontWeight = FontWeight.Bold)
            } else {
                Text(if (indicator.dimension == ReviewDimension.ADHERENCE) "Registro"
                    else "Sin referencia",
                    fontSize = 11.sp, fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
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
