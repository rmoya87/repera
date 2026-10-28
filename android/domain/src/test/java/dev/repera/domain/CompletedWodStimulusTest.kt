package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test

/** Apple MuscleCompletedWODStimulus (live main 26 Oct). JVM only; the ProgressSnapshot adapter flag is not covered here. */
class CompletedWodStimulusTest {
    private val now = 10_000_000_000L
    private fun ex(eq: Double, sets: List<MuscleStimulusSet> = emptyList()) =
        MuscleStimulusExercise(muscleGroup = "Pecho", targetMuscle = "Pectoral", sets = sets, completedWodSetEquivalent = eq)
    private fun wk(e: MuscleStimulusExercise) = listOf(MuscleStimulusWorkout(now, listOf(e)))

    @Test fun completedWodWithoutSetsCountsConservativelyOnlyOutsideHardLayer() {
        assertTrue(ex(1.0).weights.isNotEmpty())
        val none = MuscleMapEngine.retainedLoad(wk(ex(0.0)), hardOnly = false, nowMillis = now)
        val wod = MuscleMapEngine.retainedLoad(wk(ex(1.0)), hardOnly = false, nowMillis = now)
        val hard = MuscleMapEngine.retainedLoad(wk(ex(1.0)), hardOnly = true, nowMillis = now)
        assertTrue(none.isEmpty())
        assertTrue(wod.isNotEmpty())
        assertTrue(hard.isEmpty())
    }

    @Test fun recordedSetsWinOverTheEstimate() {
        val rec = ex(1.0, listOf(MuscleStimulusSet(reps = 5)))
        val a = MuscleMapEngine.retainedLoad(wk(rec), nowMillis = now)
        val b = MuscleMapEngine.retainedLoad(wk(ex(0.0, listOf(MuscleStimulusSet(reps = 5)))), nowMillis = now)
        assertEquals(b, a)
    }

    @Test fun weeklyLoadUsesOneSetEquivalent() {
        val st = MuscleMapEngine.statuses(wk(ex(1.0)), hardOnly = false, nowMillis = now)
        assertTrue(st.isNotEmpty())
        assertTrue(MuscleMapEngine.statuses(wk(ex(1.0)), hardOnly = true, nowMillis = now).isEmpty())
    }
}
