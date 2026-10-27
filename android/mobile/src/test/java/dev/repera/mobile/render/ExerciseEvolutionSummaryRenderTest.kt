package dev.repera.mobile.render

import android.graphics.Bitmap
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import dev.repera.domain.ExerciseHistorySummary
import dev.repera.mobile.ExerciseEntry
import dev.repera.mobile.ExerciseEvolutionSection
import dev.repera.mobile.ExerciseProgressMetric
import dev.repera.mobile.ExerciseProgressPoint
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File
import java.io.FileOutputStream

/** Apple 025828b5 summaryTiles: fichas centradas (Max/e1RM/Reps/Veces en
 *  fuerza) sobre el grafico. Previsualizacion JVM, NO dispositivo. */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [35], qualifiers = "w1000dp-h1400dp")
class ExerciseEvolutionSummaryRenderTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun strengthSummaryTilesVisible() {
        val entry = ExerciseEntry("e1", "Press banca", true, true)
        composeRule.setContent {
            MaterialTheme {
                Surface(Modifier.testTag("evowrap")) {
                    ExerciseEvolutionSection(
                        entry = entry,
                        exerciseSeries = { _, metric, _ ->
                            // Coherente con summary: 14 sesiones, top set 100 kg.
                            if (metric == ExerciseProgressMetric.TOP_SET)
                                listOf(
                                    ExerciseProgressPoint(1_700_000_000_000L, 80.0, 80.0, 10),
                                    ExerciseProgressPoint(1_700_500_000_000L, 90.0, 90.0, 8),
                                    ExerciseProgressPoint(1_701_000_000_000L, 100.0, 100.0, 6))
                            else emptyList()
                        },
                        testedOneRM = null, onSetTestedOneRM = {}, busy = false,
                        summary = ExerciseHistorySummary(timesPerformed = 14,
                            maxWeightKg = 100.0, estimatedOneRM = 112.5,
                            bestReps = 12, lastReps = 8, lastWeightKg = 80.0))
                }
            }
        }
        composeRule.onNodeWithTag("exercise_evolution_chart").assertIsDisplayed()
        composeRule.onNodeWithText("Máx.").assertIsDisplayed()
        composeRule.onNodeWithText("e1RM").assertIsDisplayed()
        composeRule.onNodeWithText("Reps máx.").assertIsDisplayed()
        composeRule.onNodeWithText("Veces").assertIsDisplayed()
        composeRule.onNodeWithText("100 kg").assertIsDisplayed()
        composeRule.onNodeWithText("14").assertIsDisplayed()
        val chart=composeRule.onNodeWithTag("exercise_evolution_chart").captureToImage().asAndroidBitmap()
        File("build/reports/render").mkdirs()
        FileOutputStream("build/reports/render/exercise-evolution-curve.png").use {chart.compress(Bitmap.CompressFormat.PNG,100,it)}
        org.junit.Assert.assertEquals(220,chart.height)
        val bmp = composeRule.onNodeWithTag("evowrap").captureToImage().asAndroidBitmap()
        File("build/reports/render").mkdirs()
        FileOutputStream("build/reports/render/evolution-summary-tiles.png").use {
            bmp.compress(Bitmap.CompressFormat.PNG, 100, it)
        }
    }

    @Test
    fun mobilityHoldSummaryTiles() {
        val entry = ExerciseEntry("e2", "Plancha", true, false,
            sportTag = "Movilidad", mobilityHold = true)
        composeRule.setContent {
            MaterialTheme {
                ExerciseEvolutionSection(
                    entry = entry,
                    exerciseSeries = { _, _, _ -> emptyList() },
                    testedOneRM = null, onSetTestedOneRM = {}, busy = false,
                    summary = ExerciseHistorySummary(timesPerformed = 3,
                        bestDurationSeconds = 75, lastDurationSeconds = 60))
            }
        }
        composeRule.onNodeWithText("Mejor sostén").assertIsDisplayed()
        composeRule.onNodeWithText("1:15").assertIsDisplayed()
        composeRule.onNodeWithText("Sesiones").assertIsDisplayed()
        composeRule.onNodeWithText("Último tiempo").assertIsDisplayed()
    }

    @Test
    fun summaryWithDataButEmptyMetricFilterIsRealState() {
        // La gráfica filtra por metrica+rango; el resumen cubre todo el
        // historial. Con datos solo en otra metrica/periodo, tiles visibles
        // y mensaje de vacio a la vez es un estado real posible por filtro.
        val entry = ExerciseEntry("e1", "Press banca", true, true)
        composeRule.setContent {
            MaterialTheme {
                ExerciseEvolutionSection(
                    entry = entry,
                    exerciseSeries = { _, metric, _ ->
                        if (metric == ExerciseProgressMetric.TOP_SET) emptyList()
                        else listOf(ExerciseProgressPoint(1_700_000_000_000L, 1.0))
                    },
                    testedOneRM = null, onSetTestedOneRM = {}, busy = false,
                    summary = ExerciseHistorySummary(timesPerformed = 14,
                        maxWeightKg = 100.0))
            }
        }
        composeRule.onNodeWithText("Máx.").assertIsDisplayed()
        composeRule.onNodeWithText("Todavía no hay sesiones registradas con esta métrica.")
            .assertIsDisplayed()
    }
}
