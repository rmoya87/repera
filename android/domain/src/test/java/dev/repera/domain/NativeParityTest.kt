package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test

class NativeParityTest {
    @Test fun clockUsesWallTimeAndRestCountsOnlyInWod() {
        val strength = WorkoutClock.advance(1_000, 6_000, 30, 10, 3, true, false, 0)
        assertEquals(5, strength.advancedSeconds)
        assertEquals(35, strength.sessionElapsed)
        assertEquals(12, strength.blockElapsed)
        assertEquals(0, strength.restRemaining)
        val wod = WorkoutClock.advance(1_000, 6_000, 30, 10, 3, true, true, 12)
        assertEquals(12, wod.blockElapsed)
        assertTrue(wod.reachedTimeCap)
    }

    @Test fun pausedClockKeepsBlockWhileSessionProgresses() {
        val step = WorkoutClock.advance(1_000, 8_000, 11, 6, 4, false, false, 0)
        assertEquals(18, step.sessionElapsed)
        assertEquals(6, step.blockElapsed)
        assertEquals(0, step.restRemaining)
    }

    @Test fun scoringMatchesSwiftContractsForEveryFormat() {
        assertEquals(14, WodFormat.entries.size)
        assertEquals(ResultCapture.TOTAL_REPS, WodFormat.AMRAP.capture)
        assertEquals(ResultCapture.TOTAL_REPS, WodFormat.MAX_EFFORT.capture)
        assertEquals(ResultCapture.ELAPSED_TIME, WodFormat.FOR_TIME.capture)
        assertEquals(ResultCapture.PER_MOVEMENT_SETS, WodFormat.EMOM.capture)
        assertEquals(ResultCapture.PER_MOVEMENT_SETS, WodFormat.TABATA.capture)
        WodFormat.entries.forEach { assertEquals(it, WodFormat.fromWire(it.wireName)) }
    }

    @Test fun warmupDoesNotConsumeWorkPrescription() {
        val prescribed = listOf(PrescribedSet(10, 30.0), PrescribedSet(8, 35.0))
        val warmup = RecordedSet(quantity=5, weightKg=20.0, phase=SetPhase.WARMUP, completedAtMillis=1)
        assertEquals(prescribed.first(), SetPrescription.nextWorkSet(prescribed, listOf(warmup)))
        val work = warmup.copy(id="work", quantity=10, phase=SetPhase.WORK)
        assertEquals(prescribed.last(), SetPrescription.nextWorkSet(prescribed, listOf(warmup, work)))
        assertEquals(prescribed.last(), SetPrescription.nextWorkSet(prescribed, listOf(work, work.copy(id="work2"))))
    }

    @Test fun editingPreservesCountAndIdentity() {
        val before = RecordedSet(id="set1", quantity=10, weightKg=50.0, completedAtMillis=123)
        val edited = before.copy(quantity=8, weightKg=55.0)
        val after = SetPrescription.replaceLoggedSet(listOf(before), edited)!!
        assertEquals(1, after.size)
        assertEquals("set1", after.single().id)
        assertEquals(123, after.single().completedAtMillis)
        assertEquals(8, SetPrescription.completedWorkReps(after))
    }
}
