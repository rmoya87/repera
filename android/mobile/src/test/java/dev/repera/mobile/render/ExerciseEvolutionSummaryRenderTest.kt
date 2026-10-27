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
@Config(sdk = [35], qualifiers = "w1000dp")
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
                        exerciseSeries = { _, _, _ -> emptyList() },
                        testedOneRM = null, onSetTestedOneRM = {}, busy = false,
                        summary = ExerciseHistorySummary(timesPerformed = 14,
                            maxWeightKg = 100.0, estimatedOneRM = 112.5,
                            bestReps = 12, lastReps = 8, lastWeightKg = 80.0))
                }
            }
        }
        composeRule.onNodeWithText("Máx.").assertIsDisplayed()
        composeRule.onNodeWithText("e1RM").assertIsDisplayed()
        composeRule.onNodeWithText("Reps máx.").assertIsDisplayed()
        composeRule.onNodeWithText("Veces").assertIsDisplayed()
        composeRule.onNodeWithText("100 kg").assertIsDisplayed()
        composeRule.onNodeWithText("14").assertIsDisplayed()
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
}
