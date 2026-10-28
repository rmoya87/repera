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

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
class WearTechniqueRoutingTest {
    private val userId = "wear-technique-test"

    private fun seed() {
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        val state = JSONObject()
            .put("workouts", JSONArray())
            .put("routines", JSONArray())
            .put("exercises", JSONArray())
            .put("activeSession", JSONObject()
                .put("id", "s1")
                .put("title", "Fuerza")
                .put("phase", "counting")
                .put("currentIndex", 0)
                .put("exercises", JSONArray().put(JSONObject()
                    .put("id", "e1")
                    .put("blockKind", "strength")
                    .put("blockId", "b1")
                    .put("isCompleted", false)
                    .put("completedReps", 0)
                    .put("restSeconds", 90)
                    .put("plannedSets", JSONArray().put(JSONObject().put("targetReps", 5)))
                    .put("loggedSets", JSONArray())
                    .put("exercise", JSONObject()
                        .put("id", "ex1").put("name", "Back Squat")
                        .put("equipment", "Barbell").put("targetMuscle", "Quads")
                        .put("muscleGroup", "Legs").put("sportTag", "Fuerza")))))
        LocalSnapshotStore(context, userId).write(state.toString().toByteArray(Charsets.UTF_8))
    }

    private fun repo() = WorkoutRepository(
        ApplicationProvider.getApplicationContext(), userId)

    private fun logged(): JSONObject {
        val state = LocalSnapshotStore(
            ApplicationProvider.getApplicationContext(), userId).read()!!
        return JSONObject(String(state)).getJSONObject("activeSession")
            .getJSONArray("exercises").getJSONObject(0)
            .getJSONArray("loggedSets").getJSONObject(0)
    }

    @Before fun reset() {
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        java.io.File(context.filesDir, "users").deleteRecursively()
    }

    @Test fun logWearSetDropUsesSameSetIdIdempotent() {
        seed()
        assertTrue(repo().logWearSet("s1", 0, "watch-drop", 10, 60.0,
            kind = "dropset", drops = listOf(8 to 50.0, 6 to 40.0)))
        assertTrue(repo().logWearSet("s1", 0, "watch-drop", 10, 60.0,
            kind = "dropset", drops = listOf(8 to 50.0, 6 to 40.0)))
        val set = logged()
        assertEquals("watch-drop", set.getString("id"))
        assertEquals("dropset", set.getString("kind"))
        assertEquals(2, set.getJSONArray("drops").length())
        assertEquals(1, JSONObject(String(LocalSnapshotStore(
            ApplicationProvider.getApplicationContext(), userId).read()!!))
            .getJSONObject("activeSession").getJSONArray("exercises")
            .getJSONObject(0).getJSONArray("loggedSets").length())
    }

    @Test fun logWearSetRestPausePersistsClusters() {
        seed()
        assertTrue(repo().logWearSet("s1", 0, "watch-rp", 13, 80.0,
            kind = "restpause", clusters = listOf(8 to 15, 5 to 15)))
        val set = logged()
        assertEquals("restpause", set.getString("kind"))
        assertEquals(13, set.getInt("reps"))
        assertEquals(2, set.getJSONArray("clusters").length())
    }
}
