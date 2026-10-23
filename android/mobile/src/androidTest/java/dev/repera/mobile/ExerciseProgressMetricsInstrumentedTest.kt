package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ExerciseProgressMetricsInstrumentedTest {
    private fun exercise(id: String, planned: JSONArray, logged: JSONArray = JSONArray()) =
        JSONObject().put("exercise", JSONObject().put("id", id).put("name", "Squat"))
            .put("plannedSets", planned).put("loggedSets", logged)
    private fun planned(reps: Int, weight: Double) =
        JSONObject().put("targetReps", reps).put("targetWeightKg", weight)
    private fun workout(phase: String, started: String, vararg exercises: JSONObject) =
        JSONObject().put("phase", phase).put("startedAt", started)
            .put("exercises", JSONArray().apply { exercises.forEach { put(it) } })

    @Test fun finishedPrescribedSetsUpdateE1RmAndFrequencyButNoJsonMutation() {
        val id = "exercise1"
        val first = exercise(id, JSONArray().put(planned(8, 50.0)).put(planned(6, 55.0)))
        val second = exercise(id, JSONArray().put(planned(3, 60.0)), JSONArray()
            .put(JSONObject().put("reps", 5).put("phase", "warmup")
                .put("weightKg", 20.0))
            .put(JSONObject().put("reps", 3).put("weightKg", 60.0)))
        val workouts = JSONArray().put(workout("finished", "2026-10-22T08:00:00Z", first))
            .put(workout("finished", "2026-10-23T08:00:00Z", second))
        val original = workouts.toString()
        val metrics = ExerciseProgressMetrics.fromWorkouts(workouts)[id]!!
        assertEquals(2, metrics.timesPerformed)
        assertEquals(60.0, metrics.maxWeightKg!!, 0.001)
        assertEquals(3, metrics.repsAtMaxWeight)
        assertEquals(66.0, metrics.estimatedOneRM!!, 0.001)
        assertEquals(8, metrics.bestReps)
        assertEquals("2026-10-23T08:00:00Z", metrics.lastDate)
        assertEquals(original, workouts.toString())
    }

    @Test fun unfinishedPrescriptionsAndScoreOnlyWodsDoNotProduceFakeRecords() {
        val id = "e"
        val pending = exercise(id, JSONArray().put(planned(8, 40.0)))
        val wod = exercise(id, JSONArray())
        val archive = JSONArray().put(workout("counting", "2026-10-23T09:00:00Z", pending))
            .put(workout("finished", "2026-10-23T10:00:00Z", wod))
        assertFalse(ExerciseProgressMetrics.fromWorkouts(archive).containsKey(id))
    }

    @Test fun exerciseHistoryCountsOneVisitWhenMovementAppearsTwiceInOneWorkout() {
        val archive = JSONArray().put(workout("finished", "2026-10-23T10:00:00Z",
            exercise("e", JSONArray().put(planned(5, 10.0))),
            exercise("e", JSONArray().put(planned(5, 15.0)))))
        val metrics = ExerciseProgressMetrics.fromWorkouts(archive)["e"]!!
        assertEquals(1, metrics.timesPerformed)
        assertEquals(15.0, metrics.maxWeightKg!!, 0.01)
    }
}
