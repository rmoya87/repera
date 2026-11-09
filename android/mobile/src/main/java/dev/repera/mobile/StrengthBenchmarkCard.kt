package dev.repera.mobile

import android.content.Context
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Card
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
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

/** Privacy: comparison category, age and bodyweight remain local preferences. */
@Composable
internal fun StrengthBenchmarkCard(exerciseName: String, testedOneRM: Double?) {
    val lift = remember(exerciseName) { strengthLiftForExerciseName(exerciseName) } ?: return
    val context = androidx.compose.ui.platform.LocalContext.current
    val prefs = remember(context) { context.getSharedPreferences("strength_benchmarks", Context.MODE_PRIVATE) }
    var sexRaw by rememberSaveable { mutableStateOf(prefs.getString("sex", "") ?: "") }
    var ageRaw by rememberSaveable { mutableStateOf(prefs.getString("age", "") ?: "") }
    var weightRaw by rememberSaveable { mutableStateOf(prefs.getString("weight", "") ?: "") }
    val references by produceState<List<StrengthBenchmarkDistribution>?>(null, context) {
        value = withContext(Dispatchers.IO) { StrengthBenchmarkAssets.load(context) }
    }
    val sex = when (sexRaw) {
        "female" -> StrengthBenchmarkSex.FEMALE
        "male" -> StrengthBenchmarkSex.MALE
        else -> null
    }
    val age = ageRaw.toIntOrNull()
    val bodyWeightKg = weightRaw.trim().replace(',', '.').toDoubleOrNull()
    val comparison = if (sex != null && age != null && bodyWeightKg != null &&
        testedOneRM != null && testedOneRM > 0 && references != null) {
        StrengthBenchmarkEngine.compareCompetitionOneRepMax(
            weightKg = testedOneRM, lift = lift, sex = sex,
            equipment = StrengthBenchmarkEquipment.RAW,
            age = age, bodyWeightKg = bodyWeightKg, distributions = references!!
        )
    } else null

    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        ReperaSectionTitle("Tu nivel · fuerza")
        Card(modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text("Referencia de competición", style = MaterialTheme.typography.titleMedium)
                Text(
                    "Compara tu 1RM registrado con resultados OpenPowerlifting. " +
                        "Es orientativo: no mide tu nivel entre la población ni equivale a una marca oficial.",
                    style = MaterialTheme.typography.bodySmall
                )
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FilterChip(
                        selected = sexRaw == "female",
                        onClick = { sexRaw = "female"; prefs.edit().putString("sex", sexRaw).apply() },
                        label = { Text("Femenina") }
                    )
                    FilterChip(
                        selected = sexRaw == "male",
                        onClick = { sexRaw = "male"; prefs.edit().putString("sex", sexRaw).apply() },
                        label = { Text("Masculina") }
                    )
                }
                OutlinedTextField(
                    value = ageRaw,
                    onValueChange = {
                        ageRaw = it.filter(Char::isDigit).take(3)
                        prefs.edit().putString("age", ageRaw).apply()
                    },
                    label = { Text("Edad") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.fillMaxWidth(), singleLine = true
                )
                OutlinedTextField(
                    value = weightRaw,
                    onValueChange = {
                        weightRaw = it.take(8)
                        prefs.edit().putString("weight", weightRaw).apply()
                    },
                    label = { Text("Peso corporal (kg)") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    modifier = Modifier.fillMaxWidth(), singleLine = true
                )
                when {
                    references == null -> Text("Preparando referencia…", style = MaterialTheme.typography.bodySmall)
                    testedOneRM == null || testedOneRM <= 0 ->
                        Text("Registra un 1RM probado en Evolución. El e1RM estimado no se compara.")
                    sex == null || age == null || bodyWeightKg == null || bodyWeightKg <= 0 ->
                        Text("Introduce categoría competitiva, edad y peso corporal.")
                    comparison == null ->
                        Text("Sin muestra suficiente o fuera del rango publicado: no se calcula un percentil.")
                    else -> {
                        Text(
                            "P${comparison.percentile.toInt()} orientativo",
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.primary
                        )
                        Text(
                            "1RM: ${String.format(Locale.ROOT, "%.1f", testedOneRM)} kg · " +
                                "${comparison.sampleCount} resultados de competición " +
                                (if (comparison.ageSpecific) "de tu edad" else "de todas las edades") +
                                ". Datos de mayo de 2026.",
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                }
                Text(
                    "Fuente: OpenPowerlifting · CC0. Resultados competitivos, no población general.",
                    style = MaterialTheme.typography.labelSmall
                )
            }
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
