package dev.repera.mobile

import android.content.Context
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.weight
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import dev.repera.domain.StrengthBenchmarkCohort
import dev.repera.domain.StrengthBenchmarkDistribution
import dev.repera.domain.StrengthBenchmarkEngine
import dev.repera.domain.StrengthBenchmarkEquipment
import dev.repera.domain.StrengthBenchmarkLift
import dev.repera.domain.StrengthBenchmarkQuantile
import dev.repera.domain.StrengthBenchmarkSex
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import java.util.Locale
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
    bodyWeightKg: Double?
) {
    val lift = strengthLiftForExerciseName(exerciseName) ?: return
    val context = LocalContext.current
    val rows by produceState<List<StrengthBenchmarkDistribution>?>(null, context) {
        value = withContext(Dispatchers.IO) { StrengthBenchmarkAssets.load(context) }
    }
    val sex = when (competitionSex) {
        "female" -> StrengthBenchmarkSex.FEMALE
        "male" -> StrengthBenchmarkSex.MALE
        else -> null
    }
    val yearNow = java.time.Year.now().value
    val age = birthYear?.let { yearNow - it }?.takeIf { it in 14..100 }
    val kg = testedOneRM?.takeIf { it.isFinite() && it > 0 }
        ?: estimatedOneRM?.takeIf { it.isFinite() && it > 0 }
    val isEstimate = testedOneRM?.let { it.isFinite() && it > 0 } != true
    val reference = if (sex != null && age != null && bodyWeightKg != null &&
        bodyWeightKg.isFinite() && bodyWeightKg > 0) {
        val eligible = rows.orEmpty().filter {
            it.cohort.matches(lift, sex, StrengthBenchmarkEquipment.RAW, age, bodyWeightKg)
                && it.sampleCount >= StrengthBenchmarkEngine.MINIMUM_SAMPLE_COUNT
                && it.source == "OpenPowerlifting"
        }
        val span = eligible.minOfOrNull { it.cohort.ageMax - it.cohort.ageMin }
        eligible.filter { it.cohort.ageMax - it.cohort.ageMin == span }
            .singleOrNull()
    } else null
    val pct = if (kg != null && sex != null && age != null && bodyWeightKg != null) {
        StrengthBenchmarkEngine.compareCompetitionOneRepMax(
            kg, lift, sex, StrengthBenchmarkEquipment.RAW, age, bodyWeightKg, rows.orEmpty()
        )
    } else null
    val p25 = reference?.quantiles?.firstOrNull { kotlin.math.abs(it.percentile - 25) < 1 }
    val p50 = reference?.quantiles?.firstOrNull { kotlin.math.abs(it.percentile - 50) < 1 }
    val p75 = reference?.quantiles?.firstOrNull { kotlin.math.abs(it.percentile - 75) < 1 }
    val sigma = if (p25 != null && p75 != null)
        (p75.weightKg - p25.weightKg) / 1.349 else 0.0
    val valid = kg != null && p50 != null && sigma.isFinite() && sigma > 0
    val accent = MaterialTheme.colorScheme.primary
    Column(verticalArrangement = Arrangement.spacedBy(5.dp)) {
        Row(modifier = Modifier.fillMaxWidth()) {
            Text("Tu nivel · fuerza", style = MaterialTheme.typography.titleSmall)
            Spacer(Modifier.weight(1f))
            pct?.let {
                Text("P${it.percentile.toInt()}", style = MaterialTheme.typography.titleMedium,
                    color = accent, fontWeight = FontWeight.Bold)
            }
        }
        if (valid) {
            val score = kg!!
            val median = p50!!.weightKg
            val lo = kotlin.math.min(median - 3 * sigma, score).coerceAtLeast(0.0)
            val hi = kotlin.math.max(median + 3 * sigma, score)
            Canvas(Modifier.fillMaxWidth().height(118.dp).semantics {
                contentDescription = "Campana ilustrativa de competición. Tu " +
                    (if (isEstimate) "e1RM estimado" else "1RM registrado") +
                    ": ${score.toInt()} kilogramos"
            }) {
                val baseline = size.height - 10.dp.toPx()
                val height = size.height - 20.dp.toPx()
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
                val x = xFor(score)
                val y = baseline - (gaussian(score) * height).toFloat()
                drawLine(accent, start = androidx.compose.ui.geometry.Offset(x, 0f),
                    end = androidx.compose.ui.geometry.Offset(x, baseline),
                    strokeWidth = 2.dp.toPx())
                drawCircle(accent, radius = 4.dp.toPx(),
                    center = androidx.compose.ui.geometry.Offset(x, y))
            }
            Row(modifier = Modifier.fillMaxWidth()) {
                Text(
                    (if (isEstimate) "e1RM estimado" else "1RM registrado") +
                        " · ${String.format(Locale.ROOT, "%.1f", score)} kg",
                    style = MaterialTheme.typography.labelSmall
                )
                Spacer(Modifier.weight(1f))
                Text("Competición · orientativo",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        } else {
            Text(
                when {
                    rows == null -> "Preparando referencia…"
                    kg == null -> "Sin marcas suficientes para estimar tu fuerza."
                    sex == null || birthYear == null -> "Configura género y nacimiento en Ajustes · Entrenamiento."
                    bodyWeightKg == null || bodyWeightKg <= 0 -> "Registra tu peso corporal en Progreso."
                    else -> "Sin referencia competitiva suficiente."
                }, style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

internal fun strengthLiftForExerciseName(name: String): StrengthBenchmarkLift? {
    val normalized = java.text.Normalizer.normalize(name.trim().lowercase(Locale.ROOT),
        java.text.Normalizer.Form.NFD).replace(Regex("\\p{M}+"), "")
    return when (normalized) {
        "sentadilla", "sentadilla trasera", "back squat", "barbell back squat" -> StrengthBenchmarkLift.SQUAT
        "press banca", "press de banca", "bench press", "barbell bench press" -> StrengthBenchmarkLift.BENCH_PRESS
        "peso muerto", "peso muerto convencional", "deadlift", "conventional deadlift" -> StrengthBenchmarkLift.DEADLIFT
        else -> null
    }
}

private object StrengthBenchmarkAssets {
    @Volatile private var cache: List<StrengthBenchmarkDistribution>? = null

    @Synchronized
    fun load(context: Context): List<StrengthBenchmarkDistribution> {
        cache?.let { return it }
        val values = try {
            val raw = context.assets.open("strength_benchmarks.json")
                .bufferedReader(Charsets.UTF_8).use { it.readText() }
            val rows = JSONArray(raw)
            buildList {
                for (index in 0 until rows.length()) {
                    val row = rows.getJSONObject(index)
                    val c = row.getJSONObject("cohort")
                    val lift = when (c.getString("lift")) {
                        "squat" -> StrengthBenchmarkLift.SQUAT
                        "benchPress" -> StrengthBenchmarkLift.BENCH_PRESS
                        "deadlift" -> StrengthBenchmarkLift.DEADLIFT
                        else -> continue
                    }
                    val sex = when (c.getString("sex")) {
                        "female" -> StrengthBenchmarkSex.FEMALE
                        "male" -> StrengthBenchmarkSex.MALE
                        else -> continue
                    }
                    val q = row.getJSONArray("quantiles")
                    val points = buildList {
                        for (i in 0 until q.length()) {
                            val x = q.getJSONObject(i)
                            add(StrengthBenchmarkQuantile(x.getDouble("percentile"), x.getDouble("weightKg")))
                        }
                    }
                    add(StrengthBenchmarkDistribution(
                        cohort = StrengthBenchmarkCohort(
                            lift, sex, StrengthBenchmarkEquipment.RAW,
                            c.getInt("ageMin"), c.getInt("ageMax"),
                            c.getDouble("bodyWeightMinKg"), c.getDouble("bodyWeightMaxKg")
                        ),
                        source = row.getString("source"),
                        sourceRevision = row.getString("sourceRevision"),
                        sampleCount = row.getInt("sampleCount"),
                        quantiles = points
                    ))
                }
            }
        } catch (_: Exception) {
            emptyList()
        }
        cache = values
        return values
    }
}
