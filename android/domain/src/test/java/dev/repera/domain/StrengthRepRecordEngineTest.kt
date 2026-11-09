package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class StrengthRepRecordEngineTest {
    @Test fun recordsUseRealWorkingSetsOnly() {
        val session = StatsWorkout(
            epochMillis = 200_000L, durationMinutes = 40.0, sessionId = "one",
            exercises = listOf(StatsExercise(
                exerciseId = "squat", exerciseName = "Sentadilla",
                sets = listOf(
                    StatsSet(reps = 5, weightKg = 100.0),
                    StatsSet(reps = 10, weightKg = 75.0),
                    StatsSet(reps = 1, weightKg = 200.0, isWarmup = true),
                    StatsSet(reps = 12, weightKg = 250.0, fromPrescription = true)
                )
            ))
        )
        val result = StrengthRepRecordEngine.bestSets("squat", listOf(session, session))
        assertEquals(listOf(3, 5, 10), result.map { it.minimumReps })
        assertEquals(listOf(100.0, 100.0, 75.0), result.map { it.bestWeightKg })
    }
    @Test fun incompleteSessionsDoNotProduceRecords() {
        val incomplete = StatsWorkout(epochMillis = 1, durationMinutes = 0.0,
            finished = false, exercises = listOf(StatsExercise(
                exerciseId = "squat", exerciseName = "Sentadilla",
                sets = listOf(StatsSet(reps = 10, weightKg = 300.0))
            )))
        assertTrue(StrengthRepRecordEngine.bestSets("squat", listOf(incomplete)).isEmpty())
    }
}
