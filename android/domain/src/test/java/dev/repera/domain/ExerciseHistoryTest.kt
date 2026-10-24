package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class ExerciseHistoryTest {

    private fun workout(epoch: Long, vararg exercises: StatsExercise) =
        StatsWorkout(epochMillis = epoch, durationMinutes = 60.0,
            exercises = exercises.toList())

    private fun ex(id: String, name: String, vararg sets: StatsSet) =
        StatsExercise(exerciseId = id, exerciseName = name, sets = sets.toList())

    @Test fun emptyHistoryWhenExerciseNeverAppears() {
        val h = StatsEngine.exerciseHistory("e1", "Press banca",
            listOf(workout(1000L, ex("e2", "Sentadilla", StatsSet(5, 100.0)))))
        assertEquals(0, h.timesPerformed)
        assertNull(h.maxWeightKg)
        assertNull(h.lastEpochMillis)
    }

    @Test fun warmupSetsDoNotCountAndLastSessionIsTheNewest() {
        val older = workout(1000L, ex("e1", "Press banca",
            StatsSet(8, 80.0, isWarmup = true), StatsSet(5, 100.0)))
        val newer = workout(2000L, ex("e1", "Press banca", StatsSet(3, 110.0)))
        val h = StatsEngine.exerciseHistory("e1", "Press banca", listOf(older, newer))
        assertEquals(2, h.timesPerformed)
        assertEquals(2000L, h.lastEpochMillis)
        assertEquals(110.0, h.lastWeightKg!!, 0.001)
        assertEquals(3, h.lastReps)
        // PR: 110x3 gana a 100x5; e1RM de 110x3 = 121.
        assertEquals(110.0, h.maxWeightKg!!, 0.001)
        assertEquals(3, h.repsAtMaxWeight)
        assertEquals(121.0, h.estimatedOneRM!!, 0.001)
    }

    @Test fun caloriesMetersAndDurationTrackedSeparately() {
        val w = workout(3000L,
            ex("e3", "Assault bike", StatsSet(40, quantityUnit = "calories")),
            ex("e4", "Remo máquina", StatsSet(500, quantityUnit = "meters")),
            ex("e5", "Plancha", StatsSet(1, durationSeconds = 90)))
        val cal = StatsEngine.exerciseHistory("e3", "Assault bike", listOf(w))
        assertEquals(40, cal.bestCalories)
        assertNull(cal.bestReps)
        val met = StatsEngine.exerciseHistory("e4", "Remo máquina", listOf(w))
        assertEquals(500, met.bestMeters)
        assertEquals("meters", met.lastQuantityUnit)
        val dur = StatsEngine.exerciseHistory("e5", "Plancha", listOf(w))
        assertEquals(90, dur.bestDurationSeconds)
    }

    @Test fun nameEquivalenceMatchesRenamedCatalogEntry() {
        val w = workout(4000L, ex("otro-id", "Press banca con barra",
            StatsSet(5, 60.0)))
        val h = StatsEngine.exerciseHistory("id-original", "press banca con barra",
            listOf(w))
        assertEquals(1, h.timesPerformed)
    }
}
