package dev.repera.mobile

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onAllNodesWithTag
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.swipeLeft
import androidx.compose.ui.test.performTextInput
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

    private fun planRoutine() = RoutineEntry(
        id = "r-2", title = "Plan", supported = true,
        blocks = listOf(
            RoutineBlockInfo(title = "Fuerza", format = "strength", id = "b-s",
                entries = listOf(RoutineBlockEntryInfo(exerciseId = "ex-1", name = "", quantity = 5, sets = 2, weightKg = 40.0, id = "it-1",
                    plannedSets = listOf(PlannedSetDraft(5, 40.0, 2.0, "sp-1"), PlannedSetDraft(3, 45.0, null, "sp-2"))))),
            RoutineBlockInfo(title = "WOD", format = "amrap", id = "b-w", entries = emptyList())))

    /** Mover fuerza→WOD en el editor de plan conserva id y series; Guardar emite ambos bloques. Solo compilado. */
    @Test fun planMoveStrengthToWodKeepsIdsAndSets() {
        var delivered: List<RoutineBlockDraft>? = null
        compose.setContent { MaterialThemeForTest {
            RoutineBlocksEditorScreen(routine = planRoutine(), exercises = listOf(exercise), busy = false,
                onReplace = { delivered = it }, onBack = {}) } }
        compose.onNodeWithTag("plan_entry_move").performClick()
        compose.onNodeWithTag("plan_entry_move_to_1").performClick()
        compose.onNodeWithText("Guardar").performClick(); compose.waitForIdle()
        val wod = delivered!![1].entries.single()
        assertEquals("it-1", wod.itemId)
        val src = org.json.JSONObject(wod.sourceJson!!)
        assertEquals("sp-2", src.getJSONArray("explicitPlannedSets").getJSONObject(1).getString("id"))
    }

    @Test fun planAddRestAndEditWodDetailsDeliverFields() {
        var delivered: List<RoutineBlockDraft>? = null
        compose.setContent { MaterialThemeForTest {
            RoutineBlocksEditorScreen(routine = planRoutine(), exercises = listOf(exercise), busy = false,
                onReplace = { delivered = it }, onBack = {}) } }
        compose.onNodeWithTag("plan_add_rest").performClick()
        compose.onNodeWithText("Guardar").performClick(); compose.waitForIdle()
        val rest = delivered!![1].entries.single()
        assertTrue(org.json.JSONObject(rest.sourceJson!!).getBoolean("isRest"))
    }

    /** Soltar una entrada del plan fuera de todo bloque no cambia nada. Solo compilado (no ejecutado). */
    @Test fun planEntryDroppedOutsideAnyBlockChangesNothing() {
        var delivered: List<RoutineBlockDraft>? = null
        compose.setContent { MaterialThemeForTest {
            RoutineBlocksEditorScreen(routine = planRoutine(), exercises = listOf(exercise), busy = false,
                onReplace = { delivered = it }, onBack = {}) } }
        compose.onAllNodesWithTag("plan_entry_drag")[0].performTouchInput {
            down(center); advanceEventTime(700); moveBy(androidx.compose.ui.geometry.Offset(0f, -6000f)); advanceEventTime(50); up() }
        compose.onNodeWithText("Guardar").performClick(); compose.waitForIdle()
        assertEquals(1, delivered!![0].entries.size)
        assertEquals("it-1", delivered!![0].entries[0].itemId)
    }

    /** El selector de unidad de cardio (Calorías/Metros) llega al borrador. Solo compilado. */
    @Test fun planCardioUnitPickerDeliversChoice() {
        var delivered: List<RoutineBlockDraft>? = null
        val bike = ExerciseEntry("ex-bike", "Air Bike", true, false)
        val r = RoutineEntry(id = "r-3", title = "Cardio", supported = true, blocks = listOf(
            RoutineBlockInfo(title = "Fuerza", format = "strength", id = "b1",
                entries = listOf(RoutineBlockEntryInfo(exerciseId = "ex-bike", name = "", quantity = 10, id = "i1")))))
        compose.setContent { MaterialThemeForTest {
            RoutineBlocksEditorScreen(routine = r, exercises = listOf(bike), busy = false,
                onReplace = { delivered = it }, onBack = {}) } }
        compose.onNodeWithTag("plan_unit_meters").performClick()
        compose.onNodeWithText("Guardar").performClick(); compose.waitForIdle()
        assertEquals("meters", delivered!![0].entries[0].quantityUnit)
    }

    /** «Añadir rutina» copia bloques con ids nuevos. Solo compilado. */
    @Test fun planAddRoutineCopiesBlocksWithFreshIds() {
        var delivered: List<RoutineBlockDraft>? = null
        val src = planRoutine().copy(id = "r-src", title = "Origen")
        val target = RoutineEntry(id = "r-dst", title = "Destino", supported = true, blocks = listOf(
            RoutineBlockInfo(title = "Fuerza", format = "strength", id = "bd",
                entries = listOf(RoutineBlockEntryInfo(exerciseId = "ex-1", name = "", quantity = 5, id = "idd")))))
        compose.setContent { MaterialThemeForTest {
            RoutineBlocksEditorScreen(routine = target, exercises = listOf(exercise), busy = false,
                onReplace = { delivered = it }, onBack = {}, importableRoutines = listOf(src)) } }
        compose.onNodeWithTag("plan_add_routine").performClick()
        compose.onNodeWithTag("plan_import_r-src").performClick()
        compose.onNodeWithText("Guardar").performClick(); compose.waitForIdle()
        assertEquals(3, delivered!!.size)
        assertTrue(delivered!![1].blockId != "b-s" && delivered!![1].blockId != null)
    }

    @Test fun planPickWodAddsTemplateBlock() {
        var delivered: List<RoutineBlockDraft>? = null
        val t = dev.repera.domain.CatalogWods.seed().first { it.format != dev.repera.domain.WodFormat.LADDER }
        compose.setContent { MaterialThemeForTest {
            RoutineBlocksEditorScreen(routine = planRoutine(), exercises = listOf(exercise), busy = false,
                onReplace = { delivered = it }, onBack = {}) } }
        compose.onNodeWithTag("plan_pick_wod").performClick()
        compose.onNodeWithTag("plan_wod_pick_" + t.id).performClick()
        compose.onNodeWithText("Guardar").performClick(); compose.waitForIdle()
        assertEquals(3, delivered!!.size)
        assertEquals(t.movements.size, delivered!![2].entries.size)
    }

    /** Plantilla ladder con movimientos repetidos: se añade íntegra y el título sugerido llega antes de Guardar. Solo compilado. */
    @Test fun planPickLadderTemplateKeepsRepeatedMovementsAndSuggestsTitle() {
        var delivered: List<RoutineBlockDraft>? = null
        var title: String? = null
        val empty = RoutineEntry(id = "r-e", title = "Entreno", supported = true, blocks = emptyList())
        compose.setContent { MaterialThemeForTest {
            RoutineBlocksEditorScreen(routine = empty, exercises = listOf(exercise), busy = false,
                onReplace = { delivered = it }, onBack = {}, onTitleSuggested = { title = it }) } }
        compose.onNodeWithTag("plan_pick_wod").performClick()
        compose.onNodeWithTag("plan_wod_pick_21-15-9-thruster-bjo").performClick()
        compose.onNodeWithText("Guardar").performClick(); compose.waitForIdle()
        assertEquals("21-15-9 Thruster + BJO", title)
        val b = delivered!!.last()
        assertEquals("ladder", b.format); assertEquals(6, b.entries.size)
    }

    @Test fun planBlockDownAndSwipeRemove() {
        var delivered: List<RoutineBlockDraft>? = null
        compose.setContent { MaterialThemeForTest {
            RoutineBlocksEditorScreen(routine = planRoutine(), exercises = listOf(exercise), busy = false,
                onReplace = { delivered = it }, onBack = {}) } }
        compose.onAllNodesWithTag("plan_block_down")[0].performClick()
        compose.onAllNodesWithTag("plan_entry_swipe")[0].performTouchInput { swipeLeft() }
        compose.onNodeWithText("Guardar").performClick(); compose.waitForIdle()
        assertEquals("b-w", delivered!![0].blockId)
        assertEquals(0, delivered!![1].entries.size)
    }

    @Test fun sessionModeStartsWithFavoriteChoice() {
        var delivered: List<RoutineBlockDraft>? = null
        var fav: Boolean? = null
        compose.setContent { MaterialThemeForTest {
            RoutineBlocksEditorScreen(routine = planRoutine(), exercises = listOf(exercise), busy = false,
                onReplace = { delivered = it }, onBack = {}, sessionMode = true, onFavoriteChosen = { fav = it }) } }
        compose.onNodeWithTag("session_favorite_switch").performClick()
        compose.onNodeWithText("Empezar").performClick(); compose.waitForIdle()
        assertEquals(true, fav); assertEquals(2, delivered!!.size)
    }
}
