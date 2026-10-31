package dev.repera.mobile.render

import android.graphics.Bitmap
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.compose.foundation.layout.height
import androidx.compose.ui.unit.dp
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import dev.repera.mobile.ExerciseEntry
import dev.repera.mobile.FinishedWorkoutEditorSection
import dev.repera.mobile.WorkoutHistoryEntry
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File
import java.io.FileOutputStream

/** Apple f7109bd7 (WorkoutDetailView edit): cabecera «Reps / m» y picker de
 *  unidad por serie en la edicion de un entreno terminado. */
abstract class FinishedEditorUnitPickerRenderBase {

    @get:Rule
    val composeRule = createComposeRule()

    private fun blocksJson(): String {
        val set = JSONObject().put("id", "l1").put("targetReps", 12)
            .put("targetWeightKg", 16.0).put("targetQuantityUnit", "reps")
        val item = JSONObject().put("id", "re1").put("exerciseId", "wl")
            .put("plannedSets", JSONArray().put(set))
        val block = JSONObject().put("id", "b1").put("title", "Bloque A")
            .put("kind", "strength").put("exercises", JSONArray().put(item))
        return JSONArray().put(block).toString()
    }

    protected open fun pngName(): String = "finished-editor-unit-picker.png"

    @Test
    fun unitPickerAndRepsMetersHeaderVisible() {
        val workout = WorkoutHistoryEntry(
            id = "s1", title = "Fuerza", startedAt = "20 oct 2026, 10:00",
            results = emptyList(), movements = emptyList(),
            editableBlocksJson = blocksJson())
        val catalog = listOf(ExerciseEntry("wl", "Walking lunge", true, true))
        composeRule.setContent {
            MaterialTheme {
                Surface(Modifier.testTag("fweditor").height(1400.dp)) {
                    FinishedWorkoutEditorSection(
                        workout, "acc", false, catalog, onSave = {}
                    )
                }
            }
        }
        composeRule.onNodeWithTag("edit_finished_workout").performClick()
        composeRule.onNodeWithText("Reps / m", useUnmergedTree = true)
            .assertExists()
        composeRule.onNodeWithTag("set_unit_reps_0_0_0", useUnmergedTree = true)
            .assertExists()
        composeRule.onNodeWithTag("set_unit_meters_0_0_0", useUnmergedTree = true)
            .assertExists()
        val bmp = composeRule.onNodeWithTag("fweditor").captureToImage().asAndroidBitmap()
        File("build/reports/render").mkdirs()
        FileOutputStream("build/reports/render/" + pngName()).use {
            bmp.compress(Bitmap.CompressFormat.PNG, 100, it)
        }
    }
}

/** Ancho de telefono estrecho: la fila Reps/m + Kg + RIR + chips no debe recortarse. */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [35], qualifiers = "w360dp-h900dp")
class FinishedEditorUnitPickerRenderNarrowTest : FinishedEditorUnitPickerRenderBase() {
    override fun pngName(): String = "finished-editor-unit-picker-narrow.png"
}

/** Ancho grande (tableta/plegable). */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [35], qualifiers = "w1000dp-h1400dp")
class FinishedEditorUnitPickerRenderTest : FinishedEditorUnitPickerRenderBase()
