package dev.repera.mobile

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextClearance
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/** Borrador del editor de entreno terminado: Guardar emite la edición, Cancelar
 *  no emite nada (historial intacto). Fixture sintético; sin mapa ni ubicación. */
@RunWith(AndroidJUnit4::class)
class FinishedWorkoutEditorUiInstrumentedTest {
    @get:Rule val compose = createAndroidComposeRule<androidx.activity.ComponentActivity>()

    private val workout = WorkoutHistoryEntry(
        id = "w1", title = "Original", startedAt = "20 oct", results = emptyList(), movements = emptyList(),
        startedAtIso = "2026-10-20T10:00:00Z", finishedAtIso = "2026-10-20T11:00:00Z", notes = "nota")

    private fun show(onSave: (WorkoutRepository.FinishedWorkoutEdit) -> Unit) {
        compose.setContent {
            FinishedWorkoutEditorSection(workout, accountId = "acc", busy = false, onSave = onSave)
        }
    }

    @Test fun saveEmitsEditedDraft() {
        var saved: WorkoutRepository.FinishedWorkoutEdit? = null
        show { saved = it }
        compose.onNodeWithTag("edit_finished_workout").performClick()
        compose.onNodeWithTag("edit_title").performTextClearance()
        compose.onNodeWithTag("edit_title").performTextInput("Nuevo")
        compose.onNodeWithTag("edit_save").performClick()
        assertEquals("Nuevo", saved?.title)
        assertEquals("nota", saved?.notes)
        assertEquals(false, saved?.pinEdited)
        compose.onNodeWithTag("edit_finished_workout").assertIsDisplayed()
    }

    @Test fun cancelEmitsNothingAndRestoresView() {
        var calls = 0
        show { calls++ }
        compose.onNodeWithTag("edit_finished_workout").performClick()
        compose.onNodeWithTag("edit_title").performTextInput("basura")
        compose.onNodeWithTag("edit_cancel").performClick()
        assertEquals(0, calls)
        compose.onNodeWithTag("edit_finished_workout").assertIsDisplayed()
    }
}
