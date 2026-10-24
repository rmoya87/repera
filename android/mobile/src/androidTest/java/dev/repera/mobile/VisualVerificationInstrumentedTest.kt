package dev.repera.mobile

import android.graphics.Bitmap
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onRoot
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.json.JSONObject
import dev.repera.domain.DailyActiveEnergyPoint
import dev.repera.domain.DailyHeartRatePoint
import dev.repera.domain.HeartRatePlotPoint
import dev.repera.domain.ProgressChartBuilder
import dev.repera.domain.ProgressDayPoint
import dev.repera.domain.ProgressPreparedCharts
import dev.repera.domain.ProgressSeriesGranularity
import dev.repera.domain.ProgressTimeRange
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.time.LocalDate

/** Capturas de las pantallas/gráficas nuevas para verificación visual.
 *  Los PNG se extraen del emulador en CI (ver workflow). */
@RunWith(AndroidJUnit4::class)
class VisualVerificationInstrumentedTest {

    @get:Rule
    val compose = createComposeRule()

    private fun save(name: String, bitmap: ImageBitmap) {
        // MediaStore (Pictures): visible para `adb pull` en CI; Android/data está
        // filtrado por scoped storage incluso para shell/root en el emulador.
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val values = android.content.ContentValues().apply {
            put(android.provider.MediaStore.Images.Media.DISPLAY_NAME, "$name.png")
            put(android.provider.MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(android.provider.MediaStore.Images.Media.RELATIVE_PATH,
                "Pictures/ReperaVerification")
        }
        val uri = ctx.contentResolver.insert(
            android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
            ?: error("MediaStore no aceptó la captura $name")
        ctx.contentResolver.openOutputStream(uri)!!.use { out ->
            bitmap.asAndroidBitmap().compress(Bitmap.CompressFormat.PNG, 100, out)
        }
        android.util.Log.i("VisualVerification", "guardada en MediaStore: $uri")
    }

    private fun fixtureCharts(): ProgressPreparedCharts {
        val today = LocalDate.now()
        val hr = (13L downTo 0).map {
            DailyHeartRatePoint(today.minusDays(it),
                52.0 + (it % 5), 68.0 + (it % 9), 132.0 + (it % 23) * 3)
        }
        val kcal = (13L downTo 0).map {
            DailyActiveEnergyPoint(today.minusDays(it), 220.0 + (it % 6) * 85)
        }
        return ProgressChartBuilder.build(
            range = ProgressTimeRange.WEEK,
            weekStartsOnMonday = true,
            heartRateDays = hr,
            energyDays = kcal,
            workouts = emptyList(),
            external = emptyList(),
            now = today)
    }

    @Test
    fun capturaGraficasActividadYPulso() {
        val charts = fixtureCharts()
        compose.setContent {
            MaterialTheme {
                ProgressChartsCard(charts)
            }
        }
        compose.waitForIdle()
        save("progreso_actividad_pulso", compose.onRoot().captureToImage())
    }

    @Test
    fun capturaHeatmaps() {
        val today = LocalDate.now()
        val time = (69L downTo 0).map {
            today.minusDays(it) to ((it * 7) % 5).toInt()
        }
        val volume = (69L downTo 0).map {
            today.minusDays(it) to ((it * 3) % 5).toInt()
        }
        compose.setContent {
            MaterialTheme {
                Column(modifier = Modifier.verticalScroll(rememberScrollState())) {
                    HeatmapCard("Constancia (minutos por día)", time)
                    HeatmapCard("Volumen (kg por día)", volume)
                }
            }
        }
        compose.waitForIdle()
        save("progreso_heatmaps", compose.onRoot().captureToImage())
    }

    @Test
    fun capturaLineasPesoYCardio() {
        val today = LocalDate.now()
        val weight = (29L downTo 0 step 2).map {
            ProgressDayPoint(today.minusDays(it), 82.5 - it * 0.06 + (it % 3) * 0.15)
        }
        val cardio = (13L downTo 0).map {
            ProgressDayPoint(today.minusDays(it), 12.0 + (it % 5) * 9)
        }
        compose.setContent {
            MaterialTheme {
                Column(modifier = Modifier.verticalScroll(rememberScrollState())) {
                    DayPointLineChart(weight)
                    DayPointLineChart(cardio)
                }
            }
        }
        compose.waitForIdle()
        save("progreso_peso_cardio", compose.onRoot().captureToImage())
    }

    @Test
    fun capturaPantallaProgresoCompletaConTemaRepera() {
        // Pantalla real: tema de marca (verde Repera) + datos reales construidos
        // por el pipeline StateOverview.fromBytes, no composables aislados.
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val today = LocalDate.now()
        fun exercise(id: String, name: String, muscle: String, equipment: String?) =
            JSONObject().put("id", id).put("name", name).put("muscleGroup", muscle)
                .put("equipment", equipment ?: JSONObject.NULL).put("targetMuscle", muscle)
        val squat = exercise("ex-sentadilla", "Sentadilla", "Piernas", "Barra")
        val bench = exercise("ex-banca", "Press banca", "Pecho", "Barra")
        val run = exercise("ex-carrera", "Carrera", "Cardio", null)
        val workouts = JSONArray()
        val days = listOf(0L, 1L, 3L, 4L, 7L, 8L, 10L, 11L, 14L, 15L, 17L, 18L)
        days.forEachIndexed { i, d ->
            val date = today.minusDays(d)
            val ex = when (i % 3) { 0 -> squat; 1 -> bench; else -> squat }
            val sets = JSONArray()
            repeat(4) { n ->
                sets.put(JSONObject()
                    .put("id", java.util.UUID.randomUUID().toString())
                    .put("reps", 5).put("weightKg", 80.0 + i * 2.5 - n)
                    .put("rir", 2.0).put("phase", "work"))
            }
            val entry = JSONObject()
                .put("id", java.util.UUID.randomUUID().toString())
                .put("exercise", JSONObject(ex.toString()))
                .put("plannedSets", JSONArray())
                .put("loggedSets", sets)
                .put("completedReps", 20).put("isCompleted", true)
                .put("blockId", "b1").put("blockKind", "strength")
            val session = JSONObject()
                .put("id", java.util.UUID.randomUUID().toString())
                .put("title", if (i % 3 == 1) "Empuje" else "Pierna")
                .put("startedAt", date.atTime(18, 0)
                    .atZone(java.time.ZoneId.systemDefault()).toInstant().toString())
                .put("finishedAt", date.atTime(19, 0)
                    .atZone(java.time.ZoneId.systemDefault()).toInstant().toString())
                .put("phase", "finished")
                .put("exercises", JSONArray().put(entry))
            workouts.put(session)
        }
        val weights = JSONArray()
        (20L downTo 0 step 2).forEach { d ->
            weights.put(JSONObject()
                .put("date", today.minusDays(d).toString())
                .put("weightKg", 83.5 - (20 - d) * 0.05))
        }
        val state = JSONObject()
            .put("exercises", JSONArray().put(squat).put(bench).put(run))
            .put("routines", JSONArray())
            .put("workouts", workouts)
            .put("bodyWeights", weights)
            .put("favoriteTimers", JSONArray())
            .put("exerciseLoadPrefs", JSONObject())
            .put("syncRevision", 1)
            .put("lastWriterDeviceId", "visual-test")
        val bytes = state.toString().toByteArray(Charsets.UTF_8)
        val overview = StateOverview.fromBytes(bytes)!!
        compose.setContent {
            MaterialTheme(colorScheme = androidx.compose.material3.lightColorScheme(
                primary = brandGreen,
                onPrimary = androidx.compose.ui.graphics.Color.Black)) {
                Surface(modifier = Modifier.fillMaxSize()) {
                    ProgressTab(
                        busy = false, syncing = false, status = null,
                        overview = overview,
                        onInitializeLocal = {}, onImportJson = {}, onDriveSync = {},
                        onExportJson = {}, onSignOut = {},
                        onReviseFinishedSet = { _, _, _, _, _, _ -> },
                        onDeleteFinishedSet = { _, _, _ -> },
                        onLogBodyWeight = {})
                }
            }
        }
        compose.waitForIdle()
        save("pantalla_progreso_tema_repera", compose.onRoot().captureToImage())
    }
}
