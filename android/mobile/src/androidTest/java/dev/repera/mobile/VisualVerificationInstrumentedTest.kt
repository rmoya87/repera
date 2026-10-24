package dev.repera.mobile

import android.graphics.Bitmap
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onRoot
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
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
}
