package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test

/** Fixtures por formato de RoutineBlock.plannedSets(for:) (Models.swift). */
class WodPlannedSetsTest {
    private fun m(id: String, reps: Int? = null, scheme: List<Int>? = null, cal: Int? = null, dist: Int? = null,
                  kg: Double? = null, rest: Boolean = false, explicit: List<PlannedSetValue>? = null) =
        WodMovementSpec(id, reps, scheme, dist, cal, kg, rest, explicit)

    private fun reps(l: List<PlannedSetValue>) = l.map { it.targetReps }

    @Test fun explicitSetsWinOverEverything() {
        val ex = listOf(PlannedSetValue(3, 20.0, 1.0))
        val mv = m("a", reps = 10, explicit = ex)
        assertEquals(ex, WodPlannedSets.forMovement(WodFormat.EMOM, 5, listOf(mv), mv))
    }

    @Test fun restMovementHasNoSets() {
        val r = m("r", rest = true)
        assertTrue(WodPlannedSets.forMovement(WodFormat.EMOM, 5, listOf(r), r).isEmpty())
    }

    @Test fun emomAndCircuitRepeatBaseSetPerRound() {
        val mv = m("a", reps = 10, kg = 40.0)
        assertEquals(listOf(10, 10, 10, 10), reps(WodPlannedSets.forMovement(WodFormat.EMOM, 4, listOf(mv), mv)))
        assertEquals(40.0, WodPlannedSets.forMovement(WodFormat.CIRCUIT, 2, listOf(mv), mv)[1].targetWeightKg!!, 0.0)
        assertEquals(listOf(10), reps(WodPlannedSets.forMovement(WodFormat.EMOM, null, listOf(mv), mv)))
    }

    @Test fun emomPadsExplicitWaveWithLastValue() {
        val mv = m("a", scheme = listOf(4, 3))
        assertEquals(listOf(4, 3, 3, 3), reps(WodPlannedSets.forMovement(WodFormat.EMOM, 4, listOf(mv), mv)))
        assertEquals(listOf(4, 3), reps(WodPlannedSets.forMovement(WodFormat.EMOM, 2, listOf(mv), mv)))
    }

    @Test fun waveOutsideEmomIsNotPadded() {
        val mv = m("a", scheme = listOf(21, 15, 9))
        assertEquals(listOf(21, 15, 9), reps(WodPlannedSets.forMovement(WodFormat.LADDER, 5, listOf(mv), mv)))
        assertEquals(listOf(21, 15, 9), reps(WodPlannedSets.forMovement(WodFormat.FOR_TIME, 5, listOf(mv), mv)))
    }

    @Test fun ascendingRangeUsesCeilingAsSingleSet() {
        val mv = m("a", scheme = listOf(5, 10))
        assertTrue(WodPlannedSets.isAscendingRepRange(mv.repScheme))
        assertEquals(listOf(10), reps(WodPlannedSets.forMovement(WodFormat.AMRAP, null, listOf(mv), mv)))
        assertFalse(WodPlannedSets.isAscendingRepRange(listOf(5, 30)))
        assertFalse(WodPlannedSets.isAscendingRepRange(listOf(10, 5)))
    }

    @Test fun tabataSplitsWorkWindowsAcrossStations() {
        val a = m("a", reps = 10); val rest = m("r", rest = true); val b = m("b", reps = 12); val c = m("c", reps = 8)
        val all = listOf(a, rest, b, c)
        fun n(x: WodMovementSpec) = WodPlannedSets.forMovement(WodFormat.TABATA, 8, all, x).size
        assertEquals(listOf(3, 3, 2), listOf(n(a), n(b), n(c)))
        assertEquals(8, WodPlannedSets.forMovement(WodFormat.TABATA, null, listOf(a), a).size)
    }

    @Test fun forTimeAndRoundsForQualityRepeatByRounds() {
        val mv = m("a", reps = 10)
        assertEquals(3, WodPlannedSets.forMovement(WodFormat.FOR_TIME, 3, listOf(mv), mv).size)
        assertEquals(3, WodPlannedSets.forMovement(WodFormat.ROUNDS_FOR_QUALITY, 3, listOf(mv), mv).size)
        assertEquals(1, WodPlannedSets.forMovement(WodFormat.FOR_TIME, 1, listOf(mv), mv).size)
        assertEquals(1, WodPlannedSets.forMovement(WodFormat.FOR_TIME, null, listOf(mv), mv).size)
    }

    @Test fun otherFormatsAndNoFormatUseBase() {
        val mv = m("a", reps = 7)
        for (f in listOf(WodFormat.AMRAP, WodFormat.CHIPPER, WodFormat.AFAP, WodFormat.BUY_IN_CASH_OUT,
            WodFormat.PARTNER, WodFormat.DEATH_BY, WodFormat.MAX_EFFORT, WodFormat.STRENGTH, null))
            assertEquals(listOf(7), reps(WodPlannedSets.forMovement(f, 5, listOf(mv), mv)))
    }

    @Test fun caloriesAndMetersGoWholeToTargetAndDefaultsToTen() {
        assertEquals(listOf(30), reps(WodPlannedSets.fromReps(m("a", reps = 5, cal = 30))))
        assertEquals(listOf(400), reps(WodPlannedSets.fromReps(m("a", dist = 400))))
        assertEquals(listOf(10), reps(WodPlannedSets.fromReps(m("a"))))
        assertEquals(listOf(1), reps(WodPlannedSets.fromReps(m("a", reps = 0))))
    }

    @Test fun paddedEdgeCases() {
        val mv = m("a", reps = 6)
        assertTrue(WodPlannedSets.padded(mv, 0).isEmpty())
        assertEquals(listOf(6, 6, 6), reps(WodPlannedSets.padded(mv, 3)))
    }
}
