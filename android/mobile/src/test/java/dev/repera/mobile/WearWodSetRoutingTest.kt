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
}
