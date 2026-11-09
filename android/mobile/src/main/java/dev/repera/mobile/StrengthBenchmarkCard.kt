package dev.repera.mobile

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.ShowChart
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import dev.repera.domain.ReperaNumberFormat
import dev.repera.domain.StrengthBenchmarkDistribution
import dev.repera.domain.StrengthBenchmarkEngine
import dev.repera.domain.StrengthBenchmarkEquipment
import dev.repera.domain.StrengthBenchmarkLift
import dev.repera.domain.StrengthBenchmarkLiftResolver
import dev.repera.domain.StrengthBenchmarkSex
import dev.repera.domain.StrengthReferenceFrame
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlin.math.abs
import kotlin.math.exp

/**
 * Gaussian-style illustrative band based on published competition quantiles.
 * It is not an empirically fitted normal distribution nor a population ranking.
 */
@Composable
internal fun StrengthBenchmarkVisual(
    exerciseName: String,
    testedOneRM: Double?,
    estimatedOneRM: Double?,
    competitionSex: String?,
    birthYear: Int?,
    bodyWeightKg: Double?,
    strengthReferenceFrame: String = StrengthReferenceFrame.AMATEUR.wire,
    lastMarkKg: Double? = null,
) {
    val lift = strengthLiftForExerciseName(exerciseName) ?: return
    val context = LocalContext.current
    val rows by produceState<List<StrengthBenchmarkDistribution>?>(null, context) {
        value = withContext(Dispatchers.IO) {
            val store = StrengthBenchmarkRemoteStore.get(context)
            store.current()
        }
    }
    val frame = StrengthReferenceFrame.fromWire(strengthReferenceFrame)
    val allowed = frame.allowedSources
    val sex = when (competitionSex) {
        "female" -> StrengthBenchmarkSex.FEMALE
        "male" -> StrengthBenchmarkSex.MALE
        else -> null
    }
    val yearNow = java.time.Year.now().value
    val age = birthYear?.let { yearNow - it }?.takeIf { it in 14..100 }
    val peakKg = testedOneRM?.takeIf { it.isFinite() && it > 0 }
        ?: estimatedOneRM?.takeIf { it.isFinite() && it > 0 }
    val isEstimate = testedOneRM?.let { it.isFinite() && it > 0 } != true
    val lastKg = lastMarkKg?.takeIf { it.isFinite() && it > 0 }
    val coincide = peakKg != null && lastKg != null && abs(peakKg - lastKg) < 0.51
    val reference = if (sex != null && age != null && bodyWeightKg != null &&
        bodyWeightKg.isFinite() && bodyWeightKg > 0) {
        val eligible = rows.orEmpty().filter {
            it.cohort.matches(lift, sex, StrengthBenchmarkEquipment.RAW, age, bodyWeightKg)
                && it.sampleCount >= StrengthBenchmarkEngine.MINIMUM_SAMPLE_COUNT
                && it.source in allowed
        }
        val span = eligible.minOfOrNull { it.cohort.ageMax - it.cohort.ageMin }
        eligible.filter { it.cohort.ageMax - it.cohort.ageMin == span }
            .maxWithOrNull(
                compareBy<StrengthBenchmarkDistribution> { it.sampleCount }
                    .thenBy { it.sourceRevision }
            )
    } else null
    val pct = if (peakKg != null && sex != null && age != null && bodyWeightKg != null) {
        StrengthBenchmarkEngine.compareCompetitionOneRepMax(
            peakKg, lift, sex, StrengthBenchmarkEquipment.RAW, age, bodyWeightKg, rows.orEmpty(), frame
        )
    } else null
    val p25 = reference?.quantiles?.firstOrNull { kotlin.math.abs(it.percentile - 25) < 1 }
    val p50 = reference?.quantiles?.firstOrNull { kotlin.math.abs(it.percentile - 50) < 1 }
    val p75 = reference?.quantiles?.firstOrNull { kotlin.math.abs(it.percentile - 75) < 1 }
    val sigma = if (p25 != null && p75 != null)
        (p75.weightKg - p25.weightKg) / 1.349 else 0.0
    val valid = peakKg != null && p50 != null && sigma.isFinite() && sigma > 0
    val accent = MaterialTheme.colorScheme.primary
    val blue = Color(0xFF0A84FF)
    val muted = MaterialTheme.colorScheme.onSurfaceVariant
    val missingMessage = when {
        rows == null -> "Preparando referencia…"
        peakKg == null -> "Sin series suficientes para estimar tu marca."
        sex == null || birthYear == null ->
            "Configura género y año de nacimiento en Ajustes · Entrenamiento."
        bodyWeightKg == null || bodyWeightKg <= 0 -> "Registra tu peso corporal en Progreso."
        else -> "Sin referencia suficiente para esta categoría."
    }
    val emptyIcon = when {
        rows == null -> Icons.Outlined.Info
        peakKg == null -> Icons.Outlined.ShowChart
        sex == null || birthYear == null -> Icons.Outlined.Person
        bodyWeightKg == null || bodyWeightKg <= 0 -> Icons.Outlined.Info
        else -> Icons.Outlined.ShowChart
    }
    Column(verticalArrangement = Arrangement.spacedBy(5.dp)) {
        Row(modifier = Modifier.fillMaxWidth()) {
            Text("Rendimiento", style = MaterialTheme.typography.titleSmall)
            Spacer(Modifier.weight(1f))
            pct?.let {
                Text("P${it.percentile.toInt()}", style = MaterialTheme.typography.titleMedium,
                    color = accent, fontWeight = FontWeight.Bold)
            }
        }
        if (valid) {
            val score = peakKg!!
            val median = p50!!.weightKg
            val marks = listOfNotNull(score, lastKg?.takeUnless { coincide })
            val lo = (kotlin.math.min(median - 3 * sigma, marks.minOrNull() ?: score))
                .coerceAtLeast(0.0)
            val hi = kotlin.math.max(median + 3 * sigma, marks.maxOrNull() ?: score)
            val a11y = buildString {
                append("Campana ilustrativa de referencia ")
                append(if (frame == StrengthReferenceFrame.ELITE) "de competición" else "de gimnasio")
                append(". Tu ")
                append(if (isEstimate) "e1RM estimado" else "1RM registrado")
                append(" máximo: ${score.toInt()} kilogramos")
                if (!coincide && lastKg != null) {
                    append(". Última marca: ${lastKg.toInt()} kilogramos")
                }
            }
            Canvas(Modifier.fillMaxWidth().height(118.dp).semantics {
                contentDescription = a11y
            }) {
                val baseline = size.height - 10.dp.toPx()
                val height = size.height - 28.dp.toPx()
                val xFor: (Double) -> Float = { v ->
                    (((v - lo) / (hi - lo)).coerceIn(0.0, 1.0) * size.width).toFloat()
                }
                val gaussian: (Double) -> Double = { v ->
                    val z = (v - median) / sigma
                    exp(-0.5 * z * z)
                }
                val area = Path()
                val stroke = Path()
                for (index in 0..64) {
                    val weight = lo + (hi - lo) * index / 64.0
                    val x = xFor(weight)
                    val y = baseline - (gaussian(weight) * height).toFloat()
                    if (index == 0) {
                        area.moveTo(x, baseline)
                        area.lineTo(x, y)
                        stroke.moveTo(x, y)
                    } else {
                        area.lineTo(x, y)
                        stroke.lineTo(x, y)
                    }
                }
                area.lineTo(size.width, baseline)
                area.close()
                drawPath(area, accent.copy(alpha = 0.13f))
                drawPath(stroke, accent.copy(alpha = 0.48f), style = Stroke(width = 2.dp.toPx()))

                fun drawMark(kg: Double, color: Color) {
                    val x = xFor(kg)
                    val y = baseline - (gaussian(kg) * height).toFloat()
                    drawLine(
                        color,
                        start = Offset(x, 0f),
                        end = Offset(x, baseline),
                        strokeWidth = 2.dp.toPx()
                    )
                    drawCircle(color, radius = 4.dp.toPx(), center = Offset(x, y))
                    val label = "${ReperaNumberFormat.decimal(kg)} kg"
                    val paint = android.graphics.Paint().apply {
                        isAntiAlias = true
                        textAlign = android.graphics.Paint.Align.CENTER
                        textSize = 11.dp.toPx()
                        this.color = android.graphics.Color.argb(
                            255,
                            (color.red * 255).toInt(),
                            (color.green * 255).toInt(),
                            (color.blue * 255).toInt()
                        )
                        typeface = android.graphics.Typeface.create(
                            android.graphics.Typeface.DEFAULT,
                            android.graphics.Typeface.BOLD
                        )
                    }
                    drawContext.canvas.nativeCanvas.drawText(
                        label,
                        x,
                        (y - 8.dp.toPx()).coerceAtLeast(12.dp.toPx()),
                        paint
                    )
                }

                if (coincide || lastKg == null) {
                    drawMark(score, accent)
                } else {
                    drawMark(score, accent)
                    drawMark(lastKg, blue)
                }
            }
        } else {
            val median = p50?.weightKg ?: 180.0
            val emptySigma = if (sigma.isFinite() && sigma > 0) sigma else 45.0
            val lo = (median - 3 * emptySigma).coerceAtLeast(0.0)
            val hi = median + 3 * emptySigma
            Canvas(Modifier.fillMaxWidth().height(88.dp)) {
                val baseline = size.height - 8.dp.toPx()
                val height = size.height - 16.dp.toPx()
                val area = Path()
                val stroke = Path()
                for (index in 0..48) {
                    val weight = lo + (hi - lo) * index / 48.0
                    val z = (weight - median) / emptySigma
                    val density = exp(-0.5 * z * z)
                    val x = (((weight - lo) / (hi - lo)).coerceIn(0.0, 1.0) * size.width).toFloat()
                    val y = baseline - (density * height).toFloat()
                    if (index == 0) {
                        area.moveTo(x, baseline)
                        area.lineTo(x, y)
                        stroke.moveTo(x, y)
                    } else {
                        area.lineTo(x, y)
                        stroke.lineTo(x, y)
                    }
                }
                area.lineTo(size.width, baseline)
                area.close()
                drawPath(area, muted.copy(alpha = 0.12f))
                drawPath(stroke, muted.copy(alpha = 0.35f), style = Stroke(width = 2.dp.toPx()))
            }
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .semantics { contentDescription = missingMessage },
                horizontalArrangement = Arrangement.spacedBy(10.dp),
                verticalAlignment = Alignment.Top
            ) {
                Icon(
                    emptyIcon,
                    contentDescription = null,
                    tint = accent,
                    modifier = Modifier.size(20.dp)
                )
                Text(
                    missingMessage,
                    style = MaterialTheme.typography.labelMedium,
                    color = muted,
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

internal fun strengthLiftForExerciseName(name: String): StrengthBenchmarkLift? =
    StrengthBenchmarkLiftResolver.liftForExerciseName(name)

internal fun lastSessionMarkKg(lastWeightKg: Double?, lastReps: Int?): Double? {
    val w = lastWeightKg?.takeIf { it.isFinite() && it > 0 } ?: return null
    val r = lastReps?.takeIf { it > 0 }
    return if (r != null) w * (1.0 + r / 30.0) else w
}
