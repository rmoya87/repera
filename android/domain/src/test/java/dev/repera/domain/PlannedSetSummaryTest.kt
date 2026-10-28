package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Test

/** Espejo de PlannedSetSummaryTests.swift (Apple) + rama de segundos (35be5a8d). */
class PlannedSetSummaryTest {
    private fun set(reps: Int, kg: Double? = null, seconds: Int? = null,
                    pct: Double? = null, min: Boolean = false) =
        PlannedSet(targetReps = reps, targetDurationSeconds = seconds,
            targetWeightKg = kg, targetPercent1RM = pct, targetPercent1RMIsMinimum = min)

    @Test fun uniformWeight() {
        assertEquals("3×8 · 60 kg",
            PlannedSetSummary.compactSummary(listOf(set(8, 60.0), set(8, 60.0), set(8, 60.0))))
    }
    @Test fun sameWeightDifferentReps() {
        assertEquals("2×3, 2×1 · 150 kg",
            PlannedSetSummary.compactSummary(listOf(set(3, 150.0), set(3, 150.0), set(1, 150.0), set(1, 150.0))))
    }
    @Test fun mixedWeights() {
        assertEquals("3 @ 100 kg, 2 @ 110 kg",
            PlannedSetSummary.compactSummary(listOf(set(3, 100.0), set(2, 110.0))))
    }
    @Test fun emptyIsDash() {
        assertEquals("—", PlannedSetSummary.compactSummary(emptyList()))
    }
    @Test fun holdSecondsSingleRep() {
        // Apple: targetReps == 1 muestra solo los segundos.
        assertEquals("45s", PlannedSetSummary.compactSummary(listOf(set(1, seconds = 45))))
    }
    @Test fun holdSecondsMultiRep() {
        assertEquals("3 reps · 30s", PlannedSetSummary.compactSummary(listOf(set(3, seconds = 30))))
    }
    @Test fun holdSecondsMixedMissing() {
        assertEquals("2 reps · 30s, —",
            PlannedSetSummary.compactSummary(listOf(set(2, seconds = 30), set(1))))
    }
    @Test fun percentScheme() {
        assertEquals("2×5 @ >80% 1RM",
            PlannedSetSummary.compactSummary(listOf(set(5, pct = 80.0, min = true), set(5, pct = 80.0, min = true))))
    }
    @Test fun repsOnlySummary() {
        assertEquals("2×3, 2×1",
            PlannedSetSummary.compactRepsSummary(listOf(set(3), set(3), set(1), set(1))))
    }
}
