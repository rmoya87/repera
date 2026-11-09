package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Test

class AdaptiveProgressionIntegrationTest {
    private fun workout(epoch: Long, rir: Double? = 3.0, reps: Int = 8,
                        id: String? = null): StatsWorkout =
        StatsWorkout(epochMillis = epoch, durationMinutes = 45.0,
            sessionId = id,
            exercises = listOf(StatsExercise(
                exerciseId = "squat", exerciseName = "Sentadilla",
                sets = List(3) { StatsSet(reps = reps, weightKg = 100.0, rir = rir) },
                plannedTargetReps = 8, plannedSetCount = 3
            )))

    private fun suggest(workouts: List<StatsWorkout>): ProgressionSuggestion =
        ProgressionEngine.suggest("squat", List(3) { PlannedTarget(8, 100.0) },
            ProgressionPolicy.ADAPTIVE, workouts, 2.5)

    @Test fun needsTwoSessionsWithEffort() {
        val a = workout(100_000_000L)
        val b = workout(300_000_000L)
        assertEquals(100.0, suggest(listOf(a)).weightKg!!, 0.001)
        assertEquals(102.5, suggest(listOf(a, b)).weightKg!!, 0.001)
        assertEquals(100.0, suggest(listOf(a, workout(300_000_000L, rir = null))).weightKg!!, 0.001)
    }

    @Test fun sameSessionIsNotTwoObservations() {
        val one = workout(100_000_000L, id = "stable-uuid")
        assertEquals(100.0, suggest(listOf(one, one)).weightKg!!, 0.001)
    }

    @Test fun threeMissesDeload() {
        val history = listOf(workout(100_000_000L, reps = 5),
            workout(300_000_000L, reps = 5), workout(500_000_000L, reps = 5))
        assertEquals(90.0, suggest(history).weightKg!!, 0.001)
    }
}
