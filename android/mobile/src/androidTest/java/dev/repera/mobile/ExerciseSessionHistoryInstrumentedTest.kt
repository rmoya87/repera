package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ExerciseSessionHistoryInstrumentedTest {
    private fun entry(id: String, planned: Int, wok: Boolean = false): JSONObject {
        val plan = JSONArray().put(JSONObject().put("targetReps", planned))
        val logs = if (wok) JSONArray().put(JSONObject().put("reps", 5)
            .put("phase", "work")) else JSONArray()
        return JSONObject().put("exercise", JSONObject().put("id", id))
            .put("plannedSets", plan).put("loggedSets", logs)
    }

    @Test fun completeHistoryGroupsTwoBlocksPerVisitAndOrdersNewestFirst() {
        val older = JSONObject().put("id", "old").put("phase", "finished")
            .put("startedAt", "2026-10-20T08:00:00Z")
            .put("exercises", JSONArray().put(entry("a", 10)).put(entry("a", 8)))
        val newer = JSONObject().put("id", "new").put("phase", "finished")
            .put("startedAt", "2026-10-23T08:00:00Z")
            .put("exercises", JSONArray().put(entry("a", 10, wok = true)))
        val archive = JSONArray().put(older).put(newer)
        val original = archive.toString()
        val timeline = ExerciseSessionHistory.fromArchive(archive)["a"]!!
        assertEquals(2, timeline.size)
        assertEquals("new", timeline[0].workoutId)
        assertEquals("old", timeline[1].workoutId)
        assertEquals(listOf("10 reps", "8 reps"), timeline[1].lines)
        assertEquals("5 reps", timeline[0].lines.single())
        assertEquals(original, archive.toString())
    }

    @Test fun scoreOnlyWodIsNotAnExerciseVisitAndDraftIsNotRecorded() {
        val wod = entry("a", 21).put("blockKind", "wod")
        val workout = JSONObject().put("id", "wod")
            .put("phase", "finished").put("startedAt", "2026-10-23T11:00:00Z")
            .put("wodResults", JSONArray().put(JSONObject().put("totalReps", 300)))
            .put("exercises", JSONArray().put(wod))
        val draft = JSONObject().put("id", "draft")
            .put("phase", "ready").put("startedAt", "2026-10-23T12:00:00Z")
            .put("exercises", JSONArray().put(entry("b", 9)))
        assertTrue(ExerciseSessionHistory.fromArchive(JSONArray().put(workout).put(draft)).isEmpty())
    }
}
