package dev.repera.mobile

import androidx.test.core.app.ApplicationProvider
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** Apple 44713457: el reloj registra series WOD por movimiento (EMOM/Tabata/
 *  circuito) en el telefono; nunca fabrica series ni duplica por reintento. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
class WearWodSetRoutingTest {

    private val userId = "wear-wod-test"

    private fun movement(name: String, blockId: String, format: String) = JSONObject()
        .put("blockKind", "wod")
        .put("wodFormat", format)
        .put("blockId", blockId)
        .put("exercise", JSONObject().put("name", name))
        .put("plannedSets", JSONArray())
        .put("loggedSets", JSONArray())

    private fun seed(format: String = "emom", completed: Boolean = false) {
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        val exercises = JSONArray()
            .put(movement("Wall Ball", "b1", format).put("isCompleted", completed))
            .put(movement("Kettlebell Swing", "b1", format).put("isCompleted", completed))
        val state = JSONObject()
            .put("workouts", JSONArray())
            .put("routines", JSONArray())
            .put("exercises", JSONArray())
            .put("activeSession", JSONObject()
                .put("id", "s1")
                .put("title", "WOD")
                .put("currentIndex", 0)
                .put("exercises", exercises)
                .put("routineBlocks", JSONArray().put(JSONObject()
                    .put("id", "b1").put("title", "EMOM")
                    .put("rounds", 10).put("emomIntervalSeconds", 60))))
        LocalSnapshotStore(context, userId).write(state.toString().toByteArray(Charsets.UTF_8))
    }

    private fun repo() = WorkoutRepository(
        ApplicationProvider.getApplicationContext(), userId)

    @Before fun reset() {
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        java.io.File(context.filesDir, "users").deleteRecursively()
    }

    @Test fun routesWatchSetToWodMovement() {
        seed()
        // El reloj esta en el 2o movimiento; el telefono sigue en el 1o del mismo bloque.
        assertTrue(repo().logWearSet("s1", 1, "watch-1", 12, 24.0, intervalIndex = 2))
        val state = LocalSnapshotStore(
            ApplicationProvider.getApplicationContext(), userId).read()!!
        val exercises = JSONObject(String(state)).getJSONObject("activeSession")
            .getJSONArray("exercises")
        val logged = exercises.getJSONObject(1).getJSONArray("loggedSets")
        assertEquals(1, logged.length())
        val set = logged.getJSONObject(0)
        assertEquals("watch-1", set.getString("id"))
        assertEquals(12, set.getInt("reps"))
        assertEquals(2, set.getInt("intervalIndex"))
        assertEquals(24.0, set.getDouble("weightKg"), 0.001)
        assertEquals(12, exercises.getJSONObject(1).getInt("completedReps"))
        // El primer movimiento no recibe nada.
        assertEquals(0, exercises.getJSONObject(0).getJSONArray("loggedSets").length())
    }

    @Test fun retriedWatchSetDoesNotDuplicate() {
        seed()
        assertTrue(repo().logWearSet("s1", 0, "watch-2", 8, null, intervalIndex = 0))
        assertTrue(repo().logWearSet("s1", 0, "watch-2", 8, null, intervalIndex = 0))
        val state = LocalSnapshotStore(
            ApplicationProvider.getApplicationContext(), userId).read()!!
        val logged = JSONObject(String(state)).getJSONObject("activeSession")
            .getJSONArray("exercises").getJSONObject(0).getJSONArray("loggedSets")
        assertEquals(1, logged.length())
    }

    @Test(expected = IllegalStateException::class)
    fun rejectsGlobalScoreFormat() {
        seed(format = "amrap")
        repo().logWearSet("s1", 0, "watch-3", 8, null, intervalIndex = 0)
    }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsMissingInterval() {
        seed()
        repo().logWearSet("s1", 0, "watch-4", 8, null)
    }

    @Test(expected = IllegalStateException::class)
    fun rejectsCompletedBlock() {
        seed(completed = true)
        repo().logWearSet("s1", 0, "watch-5", 8, null, intervalIndex = 0)
    }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsIntervalOutsideProgram() {
        seed()
        repo().logWearSet("s1", 0, "watch-6", 8, null, intervalIndex = 10)
    }

    @Test(expected = IllegalArgumentException::class)
    fun zeroQuantityNeverRegisters() {
        // Cero reps: el reloj avanza sin registrar; si llegara un 0, se rechaza.
        seed()
        repo().logWearSet("s1", 0, "watch-7", 0, null, intervalIndex = 0)
    }

    @Test(expected = IllegalStateException::class)
    fun rejectsSetForOtherBlock() {
        // El reloj manda un movimiento del bloque b2 mientras el telefono
        // tiene activo el bloque b1: misma sesion, bloque distinto.
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        seed()
        val raw = LocalSnapshotStore(context, userId).read()!!
        val state = JSONObject(String(raw))
        val exercises = state.getJSONObject("activeSession").getJSONArray("exercises")
        exercises.put(movement("Double Under", "b2", "emom"))
        state.getJSONObject("activeSession").getJSONArray("routineBlocks")
            .put(JSONObject().put("id", "b2").put("rounds", 5).put("emomIntervalSeconds", 60))
        LocalSnapshotStore(context, userId).write(state.toString().toByteArray(Charsets.UTF_8))
        repo().logWearSet("s1", 2, "watch-8", 8, null, intervalIndex = 0)
    }

    @Test(expected = IllegalStateException::class)
    fun rejectsSetForOtherSession() {
        seed()
        repo().logWearSet("sesion-antigua", 0, "watch-9", 8, null, intervalIndex = 0)
    }

    @Test fun movementIndexIsRelativeToBlockNotPositionZero() {
        // Bloque WOD desplazado tras un ejercicio de fuerza (orden real de
        // sesion): exerciseIndex global 2 = 2o movimiento del bloque b1.
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        val exercises = JSONArray()
            .put(JSONObject()
                .put("blockKind", "strength")
                .put("blockId", "b0")
                .put("exercise", JSONObject().put("name", "Sentadilla"))
                .put("plannedSets", JSONArray())
                .put("loggedSets", JSONArray()))
            .put(movement("Wall Ball", "b1", "emom"))
            .put(movement("Kettlebell Swing", "b1", "emom"))
        val state = JSONObject()
            .put("workouts", JSONArray())
            .put("routines", JSONArray())
            .put("exercises", JSONArray())
            .put("activeSession", JSONObject()
                .put("id", "s1")
                .put("title", "Mixta")
                .put("currentIndex", 1)
                .put("exercises", exercises)
                .put("routineBlocks", JSONArray().put(JSONObject()
                    .put("id", "b1").put("rounds", 10).put("emomIntervalSeconds", 60))))
        LocalSnapshotStore(context, userId).write(state.toString().toByteArray(Charsets.UTF_8))
        assertTrue(repo().logWearSet("s1", 2, "watch-10", 9, null, intervalIndex = 3))
        val after = JSONObject(String(LocalSnapshotStore(context, userId).read()!!))
        val exs = after.getJSONObject("activeSession").getJSONArray("exercises")
        val logged = exs.getJSONObject(2).getJSONArray("loggedSets")
        assertEquals(1, logged.length())
        assertEquals("watch-10", logged.getJSONObject(0).getString("id"))
        assertEquals(3, logged.getJSONObject(0).getInt("intervalIndex"))
        assertEquals(0, exs.getJSONObject(1).getJSONArray("loggedSets").length())
        assertEquals(0, exs.getJSONObject(0).getJSONArray("loggedSets").length())
    }
}
