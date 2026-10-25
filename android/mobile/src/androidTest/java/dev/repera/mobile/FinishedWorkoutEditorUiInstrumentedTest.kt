package dev.repera.mobile

import androidx.compose.ui.test.swipeLeft
import androidx.compose.ui.test.onAllNodesWithTag
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.down
import androidx.compose.ui.test.moveBy
import androidx.compose.ui.test.up
import androidx.compose.ui.test.cancel
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.test.performTextClearance
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.*
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.verticalScroll
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
            androidx.compose.foundation.layout.Column(
                androidx.compose.ui.Modifier.fillMaxSize()
                    .verticalScroll(androidx.compose.foundation.rememberScrollState())) {
                FinishedWorkoutEditorSection(workout, accountId = "acc", busy = false, onSave = onSave)
            }
        }
    }

    /** Host real del editor es desplazable (LazyColumn en Home/Progress); el
     *  fixture reproduce ese host para que los nodos bajo el pliegue sean
     *  alcanzables con performScrollTo antes de pulsarlos. */
    private fun showEditor(w: WorkoutHistoryEntry, catalog: List<ExerciseEntry> = emptyList(),
                           onSave: (WorkoutRepository.FinishedWorkoutEdit) -> Unit) {
        compose.setContent {
            androidx.compose.foundation.layout.Column(
                androidx.compose.ui.Modifier.fillMaxSize()
                    .verticalScroll(androidx.compose.foundation.rememberScrollState())) {
                FinishedWorkoutEditorSection(w, "acc", false, catalog, onSave)
            }
        }
    }

    private fun clickTag(tag: String) {
        compose.onNodeWithTag(tag).performScrollTo().performClick()
    }

    @Test fun saveEmitsEditedDraft() {
        var saved: WorkoutRepository.FinishedWorkoutEdit? = null
        show { saved = it }
        clickTag("edit_finished_workout")
        compose.onNodeWithTag("edit_title").performScrollTo().performTextClearance()
        compose.onNodeWithTag("edit_title").performScrollTo().performTextInput("Nuevo")
        clickTag("edit_save")
        assertEquals("Nuevo", saved?.title)
        assertEquals("nota", saved?.notes)
        assertEquals(false, saved?.pinEdited)
        compose.onNodeWithTag("edit_finished_workout").assertIsDisplayed()
    }

    @Test fun cancelEmitsNothingAndRestoresView() {
        var calls = 0
        show { calls++ }
        clickTag("edit_finished_workout")
        compose.onNodeWithTag("edit_title").performScrollTo().performTextInput("basura")
        clickTag("edit_cancel")
        assertEquals(0, calls)
        compose.onNodeWithTag("edit_finished_workout").assertIsDisplayed()
    }

    private val blocks = """[{"id":"b1","title":"A","kind":"strength","exercises":[
        {"id":"e1","exerciseId":"x1","plannedSets":[{"id":"p1","targetReps":5,"targetWeightKg":60}]},
        {"id":"e2","exerciseId":"x2","plannedSets":[{"id":"p2","targetReps":8}]}]}]"""

    @Test fun reorderAndCancelNeverEmitsContent() {
        var saved: WorkoutRepository.FinishedWorkoutEdit? = null
        val w = workout.copy(editableBlocksJson = blocks)
        showEditor(w, listOf(ExerciseEntry("x1", "Sentadilla", true, true), ExerciseEntry("x2", "Press", true, true))) { saved = it }
        clickTag("edit_finished_workout")
        clickTag("ex_down_0_0")
        clickTag("edit_cancel")
        assertNull(saved)
    }

    @Test fun reorderThenSaveEmitsReorderedBlocksOnly() {
        var saved: WorkoutRepository.FinishedWorkoutEdit? = null
        val w = workout.copy(editableBlocksJson = blocks)
        showEditor(w, listOf(ExerciseEntry("x1", "Sentadilla", true, true), ExerciseEntry("x2", "Press", true, true))) { saved = it }
        clickTag("edit_finished_workout")
        clickTag("ex_down_0_0")
        clickTag("edit_save")
        val ids = org.json.JSONArray(saved!!.blocksJson).getJSONObject(0).getJSONArray("exercises")
        assertEquals("e2", ids.getJSONObject(0).getString("id"))
        assertEquals("e1", ids.getJSONObject(1).getString("id"))
    }

    @Test fun untouchedContentEmitsNoBlocks() {
        var saved: WorkoutRepository.FinishedWorkoutEdit? = null
        val w = workout.copy(editableBlocksJson = blocks)
        showEditor(w, emptyList()) { saved = it }
        clickTag("edit_finished_workout")
        clickTag("edit_save")
        assertNull(saved!!.blocksJson)
    }

    private val twoBlocks = """[
        {"id":"b1","title":"A","kind":"strength","exercises":[
          {"id":"e1","exerciseId":"x1","plannedSets":[{"id":"p1","targetReps":5,"targetWeightKg":60,"targetRir":2}]}]},
        {"id":"b2","title":"B","kind":"strength","exercises":[
          {"id":"e2","exerciseId":"x2","plannedSets":[{"id":"p2","targetReps":8}]}]}]"""

    @Test fun moveBetweenBlocksKeepsItemIdAndEmitsOnSave() {
        var saved: WorkoutRepository.FinishedWorkoutEdit? = null
        val w = workout.copy(editableBlocksJson = twoBlocks)
        showEditor(w, listOf(ExerciseEntry("x1", "Sentadilla", true, true), ExerciseEntry("x2", "Press", true, true))) { saved = it }
        clickTag("edit_finished_workout")
        clickTag("ex_move_0_0")
        clickTag("ex_move_to_0_0_1")
        clickTag("edit_save")
        val arr = org.json.JSONArray(saved!!.blocksJson)
        assertEquals(0, arr.getJSONObject(0).getJSONArray("exercises").length())
        val dest = arr.getJSONObject(1).getJSONArray("exercises")
        assertEquals(listOf("e2", "e1"), (0 until 2).map { dest.getJSONObject(it).getString("id") })
    }

    @Test fun searchFindsExerciseAcrossFullCatalogIgnoringAccents() {
        var saved: WorkoutRepository.FinishedWorkoutEdit? = null
        val catalog = (1..200).map { ExerciseEntry("c$it", "Ejercicio $it", true, true) } +
            ExerciseEntry("tri", "Extensión de tríceps", true, true)
        val w = workout.copy(editableBlocksJson = blocks)
        showEditor(w, catalog) { saved = it }
        clickTag("edit_finished_workout")
        clickTag("ex_add_0")
        compose.onNodeWithTag("ex_search").performTextInput("triceps")
        clickTag("ex_pick_tri")
        clickTag("edit_save")
        val items = org.json.JSONArray(saved!!.blocksJson).getJSONObject(0).getJSONArray("exercises")
        assertEquals(3, items.length())
        assertEquals("tri", items.getJSONObject(2).getString("exerciseId"))
        assertEquals(0, items.getJSONObject(2).getJSONArray("plannedSets").getJSONObject(0).optInt("targetRir", 0))
    }

    @Test fun rirEditPersistsInDraft() {
        var saved: WorkoutRepository.FinishedWorkoutEdit? = null
        val w = workout.copy(editableBlocksJson = twoBlocks)
        showEditor(w, emptyList()) { saved = it }
        clickTag("edit_finished_workout")
        compose.onNodeWithTag("set_rir_0_0_0").performScrollTo().performTextClearance()
        compose.onNodeWithTag("set_rir_0_0_0").performScrollTo().performTextInput("1")
        clickTag("edit_save")
        val set = org.json.JSONArray(saved!!.blocksJson).getJSONObject(0).getJSONArray("exercises")
            .getJSONObject(0).getJSONArray("plannedSets").getJSONObject(0)
        assertEquals(1.0, set.getDouble("targetRir"), 0.0)
    }

    private val wodBlocks = """[{"id":"b1","title":"A","kind":"strength","exercises":[
        {"id":"e1","exerciseId":"x1","plannedSets":[{"id":"p1","targetReps":5,"targetWeightKg":60}]}]},
        {"id":"b2","title":"W","kind":"wod","wodFormat":"amrap","movements":[
        {"id":"m1","exerciseId":"x2","name":"Press","reps":10,"weightFemaleKg":30,"scaleAlternative":"30 kg","notes":"n"}]}]"""
    private val cat = listOf(ExerciseEntry("x1", "Sentadilla", true, true), ExerciseEntry("x2", "Press", true, true))

    @Test fun wodMovementEditSavesAndKeepsOtherFields() {
        var saved: WorkoutRepository.FinishedWorkoutEdit? = null
        val w = workout.copy(editableBlocksJson = wodBlocks)
        showEditor(w, cat) { saved = it }
        clickTag("edit_finished_workout")
        compose.onNodeWithTag("mv_name_1_0").performScrollTo().performTextClearance()
        compose.onNodeWithTag("mv_name_1_0").performScrollTo().performTextInput("Thruster")
        clickTag("edit_save")
        val m = org.json.JSONArray(saved!!.blocksJson).getJSONObject(1).getJSONArray("movements").getJSONObject(0)
        assertEquals("Thruster", m.getString("name")); assertEquals("m1", m.getString("id"))
        assertEquals("30 kg", m.getString("scaleAlternative")); assertEquals(30.0, m.getDouble("weightFemaleKg"), 0.0)
    }

    @Test fun moveStrengthToWodConvertsAndCancelKeepsHistory() {
        var saved: WorkoutRepository.FinishedWorkoutEdit? = null
        val w = workout.copy(editableBlocksJson = wodBlocks)
        showEditor(w, cat) { saved = it }
        clickTag("edit_finished_workout")
        clickTag("ex_move_0_0")
        clickTag("ex_move_to_0_0_1")
        clickTag("edit_cancel")
        assertNull(saved)
    }

    @Test fun addWodBlockAndChangeFormat() {
        var saved: WorkoutRepository.FinishedWorkoutEdit? = null
        val w = workout.copy(editableBlocksJson = wodBlocks)
        showEditor(w, cat) { saved = it }
        clickTag("edit_finished_workout")
        clickTag("block_add_wod")
        clickTag("block_format_1")
        clickTag("block_format_1_emom")
        clickTag("edit_save")
        val arr = org.json.JSONArray(saved!!.blocksJson)
        assertEquals(3, arr.length()); assertEquals("emom", arr.getJSONObject(1).getString("wodFormat"))
    }

    /** Long-press + arrastre del asa reordena (un único reorden al soltar); sin long-press no hay cambio. */
    @Test fun longPressDragReordersExercises() {
        var saved: WorkoutRepository.FinishedWorkoutEdit? = null
        val w = workout.copy(editableBlocksJson = blocks)
        showEditor(w, cat) { saved = it }
        clickTag("edit_finished_workout")
        compose.onNodeWithTag("ex_drag_0_0").performTouchInput {
            down(center); advanceEventTime(700); moveBy(Offset(0f, 600f)); advanceEventTime(50); up()
        }
        compose.waitForIdle()
        clickTag("edit_save")
        val ids = org.json.JSONArray(saved!!.blocksJson).getJSONObject(0).getJSONArray("exercises")
        assertEquals("e2", ids.getJSONObject(0).getString("id")); assertEquals("e1", ids.getJSONObject(1).getString("id"))
    }

    @Test fun quickSwipeWithoutLongPressDoesNotReorder() {
        var saved: WorkoutRepository.FinishedWorkoutEdit? = null
        val w = workout.copy(editableBlocksJson = blocks)
        showEditor(w, cat) { saved = it }
        clickTag("edit_finished_workout")
        compose.onNodeWithTag("ex_drag_0_0").performTouchInput { down(center); moveBy(Offset(0f, 600f)); up() }
        compose.waitForIdle()
        clickTag("edit_save")
        assertNull(saved!!.blocksJson)
    }

    @Test fun longPressDragReordersBlocks() {
        var saved: WorkoutRepository.FinishedWorkoutEdit? = null
        val w = workout.copy(editableBlocksJson = wodBlocks)
        showEditor(w, cat) { saved = it }
        clickTag("edit_finished_workout")
        compose.onNodeWithTag("block_drag_0").performTouchInput {
            down(center); advanceEventTime(700); moveBy(Offset(0f, 2500f)); advanceEventTime(50); up()
        }
        compose.waitForIdle()
        clickTag("edit_save")
        val arr = org.json.JSONArray(saved!!.blocksJson)
        assertEquals("b2", arr.getJSONObject(0).getString("id")); assertEquals("b1", arr.getJSONObject(1).getString("id"))
    }

    private val twoStrengthPlusEmpty = """[{"id":"b1","title":"A","kind":"strength","exercises":[
        {"id":"e1","exerciseId":"x1","plannedSets":[{"id":"p1","targetReps":5}]}]},
        {"id":"b2","title":"B","kind":"strength","exercises":[]}]"""

    private fun dragExercise(tag: String, dy: Float) = compose.onNodeWithTag(tag).performTouchInput {
        down(center); advanceEventTime(700); moveBy(Offset(0f, dy)); advanceEventTime(50); up()
    }

    /** Fuerza→bloque vacío (Apple dropDestination): el ítem conserva id y series. Depende de layout real: solo compilado. */
    @Test fun dragExerciseIntoEmptyBlockMovesItKeepingId() {
        var saved: WorkoutRepository.FinishedWorkoutEdit? = null
        val w = workout.copy(editableBlocksJson = twoStrengthPlusEmpty)
        showEditor(w, cat) { saved = it }
        clickTag("edit_finished_workout")
        // Destino por bounds reales del bloque vacío (un offset fijo puede caer fuera de toda zona de drop).
        val startY = compose.onNodeWithTag("ex_drag_0_0").fetchSemanticsNode().boundsInRoot.center.y
        val targetY = compose.onNodeWithTag("block_title_1").fetchSemanticsNode().boundsInRoot.center.y
        compose.onNodeWithTag("ex_drag_0_0").performTouchInput {
            down(center); advanceEventTime(700)
            repeat(12) { moveBy(Offset(0f, (targetY - startY) / 12f)); advanceEventTime(50) }
            advanceEventTime(50); up()
        }
        compose.waitForIdle(); clickTag("edit_save")
        assertNotNull("el drop en el bloque vacío debe registrar el cambio", saved!!.blocksJson)
        val arr = org.json.JSONArray(saved!!.blocksJson)
        assertEquals(0, arr.getJSONObject(0).getJSONArray("exercises").length())
        assertEquals("e1", arr.getJSONObject(1).getJSONArray("exercises").getJSONObject(0).getString("id"))
    }

    /** Fuerza→WOD convierte a movimiento con el mismo id. */
    @Test fun dragExerciseIntoWodBlockConvertsToMovement() {
        var saved: WorkoutRepository.FinishedWorkoutEdit? = null
        val w = workout.copy(editableBlocksJson = wodBlocks)
        showEditor(w, cat) { saved = it }
        clickTag("edit_finished_workout")
        dragExercise("ex_drag_0_0", 900f)
        compose.waitForIdle(); clickTag("edit_save")
        val mv = org.json.JSONArray(saved!!.blocksJson).getJSONObject(1).getJSONArray("movements")
        assertTrue((0 until mv.length()).any { mv.getJSONObject(it).getString("id") == "e1" })
    }

    /** Soltar fuera de cualquier bloque (muy por encima) no cambia nada ni marca el borrador. */
    @Test fun dropOutsideAnyBlockLeavesDraftUntouched() {
        var saved: WorkoutRepository.FinishedWorkoutEdit? = null
        val w = workout.copy(editableBlocksJson = twoStrengthPlusEmpty)
        showEditor(w, cat) { saved = it }
        clickTag("edit_finished_workout")
        dragExercise("ex_drag_0_0", -3000f)
        compose.waitForIdle(); clickTag("edit_save")
        assertNull(saved!!.blocksJson)
    }

    /** Host desplazable con el editor y un bloque destino muy por debajo de la pantalla.
     *  Mueve en varios pasos (como un dedo real) para que el autoscroll event-driven acerque el destino.
     *  NO demuestra comodidad: offsets/pasos aproximados, solo compilado. */
    @Test fun dragToOffscreenBlockInScrollableHostKeepsIds() {
        val many = (1..12).joinToString(",") { """{"id":"f$it","title":"F$it","kind":"strength","exercises":[
            {"id":"fe$it","exerciseId":"x1","plannedSets":[{"id":"fp$it","targetReps":5},{"id":"fq$it","targetReps":5},{"id":"fr$it","targetReps":5}]}]}""" }
        val big = "[$many]"
        var saved: WorkoutRepository.FinishedWorkoutEdit? = null
        val w = workout.copy(editableBlocksJson = big)
        val scrollState = androidx.compose.foundation.ScrollState(0)
        compose.setContent {
            androidx.compose.runtime.CompositionLocalProvider(
                LocalDragAutoScroller provides DragScroller({ d -> scrollState.dispatchRawDelta(d) }, { null })) {
                androidx.compose.foundation.layout.Column(
                    androidx.compose.ui.Modifier.fillMaxSize().verticalScroll(scrollState)) {
                    FinishedWorkoutEditorSection(w, "acc", false, cat) { saved = it }
                }
            }
        }
        clickTag("edit_finished_workout")
        val windowBottom = compose.onRoot().fetchSemanticsNode().boundsInRoot.height
        compose.onNodeWithTag("ex_drag_0_0").performTouchInput {
            down(center); advanceEventTime(700)
            val edge = windowBottom - 24f // un dedo real no sale de la pantalla: se queda en el borde
            var y = center.y
            while (y < edge) { moveBy(Offset(0f, minOf(60f, edge - y))); y += 60f; advanceEventTime(50) }
            advanceEventTime(1500) // dedo quieto en el borde: el autoscroll continuo debe seguir
            up()
        }
        compose.waitForIdle(); clickTag("edit_save")
        assertNotNull("el arrastre con autoscroll debe registrar el cambio (scroll=${'$'}scrollState.value, " +
            "destino=${'$'}{compose.onNodeWithTag(\"block_title_11\").fetchSemanticsNode().boundsInRoot})",
            saved!!.blocksJson)
        val arr = org.json.JSONArray(saved!!.blocksJson)
        val ids = (0 until arr.length()).flatMap { b -> val ex = arr.getJSONObject(b).getJSONArray("exercises")
            (0 until ex.length()).map { ex.getJSONObject(it).getString("id") } }
        assertEquals("ningún ejercicio se pierde ni se duplica", (1..12).map { "fe$it" }.toSet(), ids.toSet())
        assertEquals(12, ids.size)
    }

    @Test fun cancelledGestureMovesNothing() {
        var saved: WorkoutRepository.FinishedWorkoutEdit? = null
        val w = workout.copy(editableBlocksJson = twoStrengthPlusEmpty)
        showEditor(w, cat) { saved = it }
        clickTag("edit_finished_workout")
        compose.onNodeWithTag("ex_drag_0_0").performTouchInput {
            down(center); advanceEventTime(700); moveBy(Offset(0f, 900f)); advanceEventTime(50); cancel()
        }
        compose.waitForIdle(); clickTag("edit_save")
        assertNull(saved!!.blocksJson)
    }

    /** Deslizar una fila de ejercicio la quita del borrador (no de lo guardado hasta Guardar). Solo compilado. */
    @Test fun swipeRemovesExerciseFromDraft() {
        var saved: WorkoutRepository.FinishedWorkoutEdit? = null
        val w = workout.copy(editableBlocksJson = blocks)
        showEditor(w, emptyList()) { saved = it }
        clickTag("edit_finished_workout")
        val before = org.json.JSONArray(blocks).getJSONObject(0).getJSONArray("exercises").length()
        compose.onAllNodesWithTag("ex_swipe")[0].performTouchInput { swipeLeft() }
        clickTag("edit_save")
        val after = org.json.JSONArray(saved!!.blocksJson).getJSONObject(0).getJSONArray("exercises").length()
        assertEquals(before - 1, after)
    }

    @Test fun saveAsFavoriteFlagReachesEdit() {
        var saved: WorkoutRepository.FinishedWorkoutEdit? = null
        val w = workout.copy(editableBlocksJson = blocks)
        showEditor(w, emptyList()) { saved = it }
        clickTag("edit_finished_workout")
        clickTag("edit_save_favorite")
        clickTag("edit_save")
        assertEquals(true, saved!!.saveAsFavorite)
    }
}
