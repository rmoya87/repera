package dev.repera.mobile

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollToNode
import androidx.compose.ui.test.hasScrollAction
import androidx.compose.ui.test.onFirst
import androidx.compose.ui.test.onAllNodesWithText
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Editor de bloques a nivel UI: Guardar persiste la mutación (onReplace con
 * los borradores), Volver descarta sin onReplace, y el contenido largo es
 * alcanzable por scroll (Column + verticalScroll). Fixtures sintéticos.
 */
@RunWith(AndroidJUnit4::class)
class EditorUiInstrumentedTest {

    @get:Rule
    val compose = createAndroidComposeRule<androidx.activity.ComponentActivity>()

    private val exercise = ExerciseEntry(
        id = "ex-1", name = "Dominadas", supportsBasicInput = true,
        allowsWeight = true, muscleGroup = "Espalda")

    private fun routine(): RoutineEntry = RoutineEntry(
        id = "r-1", title = "Rutina sintética", supported = true,
        blocks = listOf(
            RoutineBlockInfo(
                title = "Bloque A", format = "strength",
                entries = listOf(
                    RoutineBlockEntryInfo(exerciseId = "ex-1", name = "Dominadas",
                        quantity = 5, sets = 3, weightKg = 20.0)))))

    @Test fun saveDeliversMutatedDrafts() {
        var delivered: List<RoutineBlockDraft>? = null
        compose.setContent {
            MaterialThemeForTest {
                RoutineBlocksEditorScreen(
                    routine = routine(), exercises = listOf(exercise), busy = false,
                    onReplace = { delivered = it }, onBack = {})
            }
        }
        compose.onNodeWithText("Añadir bloque").performClick()
        compose.onNodeWithText("Guardar").performClick()
        compose.waitForIdle()
        assertEquals("Guardar entrega el bloque original + el añadido",
            2, delivered?.size)
    }

    @Test fun backDiscardsMutationWithoutReplace() {
        var delivered: List<RoutineBlockDraft>? = null
        var backed = false
        compose.setContent {
            MaterialThemeForTest {
                RoutineBlocksEditorScreen(
                    routine = routine(), exercises = listOf(exercise), busy = false,
                    onReplace = { delivered = it }, onBack = { backed = true })
            }
        }
        compose.onNodeWithText("Añadir bloque").performClick()
        compose.onNodeWithText("Volver").performClick()
        compose.waitForIdle()
        assertTrue("Volver navega atrás", backed)
        assertNull("Volver NO guarda: la mutación se descarta", delivered)
    }

    @Test fun longEditorContentReachableByScroll() {
        val manyBlocks = (1..12).map { i ->
            RoutineBlockInfo(title = "Bloque $i", format = "strength",
                entries = listOf(RoutineBlockEntryInfo(
                    exerciseId = "ex-1", name = "Dominadas", quantity = 5, sets = 3)))
        }
        compose.setContent {
            MaterialThemeForTest {
                RoutineBlocksEditorScreen(
                    routine = routine().copy(blocks = manyBlocks),
                    exercises = listOf(exercise), busy = false,
                    onReplace = {}, onBack = {})
            }
        }
        compose.onAllNodesWithText("Añadir bloque").onFirst().assertDoesNotExist()
        compose.onNode(hasScrollAction())
            .performScrollToNode(androidx.compose.ui.test.hasText("Añadir bloque"))
        compose.onNodeWithText("Añadir bloque").assertIsDisplayed()
    }

    @androidx.compose.runtime.Composable
    private fun MaterialThemeForTest(content: @androidx.compose.runtime.Composable () -> Unit) {
        androidx.compose.material3.MaterialTheme(content = content)
    }
}
