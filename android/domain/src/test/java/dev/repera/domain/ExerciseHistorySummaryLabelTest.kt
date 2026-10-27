package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test

/** Apple StatsEngine.swift: hasData y lastQuantityLabel 1:1. */
class ExerciseHistorySummaryLabelTest {
    @Test fun hasDataOnlyWithSessions() {
        assertFalse(ExerciseHistorySummary(timesPerformed = 0).hasData)
        assertTrue(ExerciseHistorySummary(timesPerformed = 1).hasData)
    }
    @Test fun lastQuantityLabelByUnit() {
        assertNull(ExerciseHistorySummary(timesPerformed = 1).lastQuantityLabel)
        assertEquals("12 cal", ExerciseHistorySummary(timesPerformed = 1,
            lastReps = 12, lastQuantityUnit = "calories").lastQuantityLabel)
        assertEquals("12 m", ExerciseHistorySummary(timesPerformed = 1,
            lastReps = 12, lastQuantityUnit = "meters").lastQuantityLabel)
        assertEquals("12 reps", ExerciseHistorySummary(timesPerformed = 1,
            lastReps = 12, lastWeightKg = 60.0).lastQuantityLabel)
        assertEquals("12", ExerciseHistorySummary(timesPerformed = 1,
            lastReps = 12).lastQuantityLabel)
    }
}
