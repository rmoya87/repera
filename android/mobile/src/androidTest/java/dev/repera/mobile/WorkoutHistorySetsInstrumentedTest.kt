package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class WorkoutHistorySetsInstrumentedTest {
    private fun finished(exercises: JSONArray): JSONObject =
        JSONObject().put("phase", "finished").put("exercises", exercises)
    private fun planned(reps: Int, kg: Double): JSONObject =
        JSONObject().put("targetReps", reps).put("targetWeightKg", kg)

    @Test fun archivedExerciseShowsEveryUnchangedPrescribedSetWithoutChangingJson() {
        val exercise = JSONObject()
            .put("exercise", JSONObject().put("name", "Sentadilla"))
            .put("plannedSets", JSONArray().put(planned(8, 40.0))
                .put(planned(8, 45.0)).put(planned(6, 50.0)))
            .put("loggedSets", JSONArray())
        val session = finished(JSONArray().put(exercise))
        val before = session.toString()
        val rows = WorkoutHistorySets.displayLines(session, exercise)
        assertEquals(3, rows.size)
        assertEquals("8 reps · 40.0 kg", rows[0])
        assertEquals("8 reps · 45.0 kg", rows[1])
        assertEquals("6 reps · 50.0 kg", rows[2])
        assertEquals(before, session.toString())
        assertEquals(0, exercise.getJSONArray("loggedSets").length())
    }

    @Test fun actualWorkoutEntriesAlwaysWinAndKeepWarmupsAndEqualWodScore() {
        val exercise = JSONObject()
            .put("plannedSets", JSONArray().put(planned(10, 40.0)))
            .put("loggedSets", JSONArray()
                .put(JSONObject().put("reps", 5).put("phase", "warmup"))
                .put(JSONObject().put("reps", 10).put("weightKg", 42.5)))
        val session = finished(JSONArray().put(exercise))
            .put("wodResults", JSONArray().put(JSONObject().put("totalReps", 10)))
        val rows = WorkoutHistorySets.displayLines(session, exercise)
        assertEquals(2, rows.size)
        assertEquals("Calentamiento · 5 reps", rows[0])
        assertEquals("10 reps · 42.5 kg", rows[1])
    }

    @Test fun unfinishedSessionNeverPretendsPrescribedSetsWereRecorded() {
        val exercise = JSONObject()
            .put("plannedSets", JSONArray().put(planned(8, 40.0)))
            .put("loggedSets", JSONArray())
        val session = JSONObject().put("phase", "counting")
        assertTrue(WorkoutHistorySets.displayLines(session, exercise).isEmpty())
    }

    @Test fun archivedPrescriptionsKeepCaloriesMetersAndRir() {
        val exercise = JSONObject().put("quantityUnit", "calories")
            .put("plannedSets", JSONArray()
                .put(JSONObject().put("targetReps", 25).put("targetRir", 2.0)))
        assertEquals(listOf("25 cal · RIR 2.0"),
            WorkoutHistorySets.displayLines(JSONObject().put("phase", "finished"), exercise))
        exercise.put("quantityUnit", "meters")
        assertEquals(listOf("25 m · RIR 2.0"),
            WorkoutHistorySets.displayLines(JSONObject().put("phase", "finished"), exercise))
    }

    @Test fun finishedWodWithPlannedTargetsAndBlockScoreIsNotAConfirmedSet() {
        val exercise = JSONObject().put("blockKind", "wod")
            .put("blockId", "block1")
            .put("loggedSets", JSONArray())
            .put("plannedSets", JSONArray().put(JSONObject().put("targetReps", 21)))
        val workout = JSONObject().put("phase", "finished")
            .put("wodResults", JSONArray().put(JSONObject().put("id", "block1")
                .put("format", "forTime").put("elapsedSeconds", 387)))
        assertTrue(WorkoutHistorySets.displayLines(workout, exercise).isEmpty())
        assertTrue(WorkoutHistorySets.effectiveWorkSets(workout, exercise).isEmpty())
    }

    @Test fun scoreOnlyWodDoesNotFabricateMovementSets() {
        val exercise = JSONObject().put("blockKind", "wod")
            .put("loggedSets", JSONArray()).put("plannedSets", JSONArray())
        assertTrue(WorkoutHistorySets.displayLines(JSONObject().put("phase", "finished"), exercise).isEmpty())
    }
}
