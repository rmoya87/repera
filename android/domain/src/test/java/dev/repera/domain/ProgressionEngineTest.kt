package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class ProgressionEngineTest {
    private var clock = 1_000_000L
    private fun workout(vararg sets: StatsSet,
                        plannedReps: Int = 8, plannedCount: Int = 3): StatsWorkout {
        clock += 86_400_000L
        return StatsWorkout(clock, 45.0, exercises = listOf(StatsExercise(
            exerciseId = "squat", exerciseName = "Sentadilla",
            sets = sets.toList(),
            plannedTargetReps = plannedReps, plannedSetCount = plannedCount)))
    }

    private fun hit(reps: Int, weight: Double) = StatsSet(reps = reps, weightKg = weight)
    private fun miss(reps: Int, weight: Double) = StatsSet(reps = reps, weightKg = weight)

    @Test fun offKeepsPlanTargets() {
        val s = ProgressionEngine.suggest("squat",
            listOf(PlannedTarget(5, 100.0)), ProgressionPolicy.OFF, emptyList())
        assertEquals(100.0, s.weightKg!!, 0.0001)
        assertEquals(5, s.reps)
        assertEquals(1, s.setCount)
    }

    @Test fun linearRaisesWeightAfterFullHit() {
        val history = listOf(workout(hit(8, 100.0), hit(8, 100.0), hit(8, 100.0)))
        val s = ProgressionEngine.suggest("squat",
            listOf(PlannedTarget(8, 100.0), PlannedTarget(8, 100.0), PlannedTarget(8, 100.0)),
            ProgressionPolicy.LINEAR, history)
        assertEquals(102.5, s.weightKg!!, 0.0001)
        assertEquals(8, s.reps)
    }

    @Test fun linearDeloadsAfterThreeMisses() {
        val history = listOf(
            workout(miss(5, 100.0), miss(5, 100.0), miss(4, 100.0)),
            workout(miss(6, 100.0), miss(5, 100.0), miss(5, 100.0)),
            workout(miss(7, 100.0), miss(6, 100.0), miss(5, 100.0)))
        val s = ProgressionEngine.suggest("squat",
            listOf(PlannedTarget(8, 100.0)), ProgressionPolicy.LINEAR, history)
        assertEquals(90.0, s.weightKg!!, 0.0001)
    }

    @Test fun doubleProgressionAddsRepsThenWeight() {
        // Hit con 8/8/8 (< tope 12) -> 9 reps, mismo peso.
        var history = listOf(workout(hit(8, 60.0), hit(8, 60.0), hit(8, 60.0)))
        var s = ProgressionEngine.suggest("squat",
            listOf(PlannedTarget(8, 60.0)), ProgressionPolicy.DOUBLE, history)
        assertEquals(9, s.reps)
        assertEquals(60.0, s.weightKg!!, 0.0001)
        // Hit en el tope 12 -> +2.5 kg y vuelta a 6.
        history = listOf(workout(hit(12, 60.0), hit(12, 60.0), hit(12, 60.0)))
        s = ProgressionEngine.suggest("squat",
            listOf(PlannedTarget(12, 60.0)), ProgressionPolicy.DOUBLE, history)
        assertEquals(62.5, s.weightKg!!, 0.0001)
        assertEquals(6, s.reps)
    }

    @Test fun greyskullAmrapDoublingAndDeload() {
        // Series fijas ok + AMRAP 17 (≥2×8) -> +5 kg.
        var history = listOf(workout(hit(8, 80.0), hit(8, 80.0), hit(17, 80.0)))
        var s = ProgressionEngine.suggest("squat",
            listOf(PlannedTarget(8, 80.0)), ProgressionPolicy.GREYSKULL, history)
        assertEquals(85.0, s.weightKg!!, 0.0001)
        // AMRAP 12 (>8 pero <16) -> +2.5 kg.
        history = listOf(workout(hit(8, 80.0), hit(8, 80.0), hit(12, 80.0)))
        s = ProgressionEngine.suggest("squat",
            listOf(PlannedTarget(8, 80.0)), ProgressionPolicy.GREYSKULL, history)
        assertEquals(82.5, s.weightKg!!, 0.0001)
        // Serie fija fallada -> deload 10%.
        history = listOf(workout(hit(8, 80.0), miss(5, 80.0), hit(9, 80.0)))
        s = ProgressionEngine.suggest("squat",
            listOf(PlannedTarget(8, 80.0)), ProgressionPolicy.GREYSKULL, history)
        assertEquals(72.5, s.weightKg!!, 0.0001) // snap(72, 2.5)
    }

    @Test fun tripleProgressionRepsThenSetsThenWeight() {
        // Hit con 10 (<12) -> 11 reps.
        var history = listOf(workout(hit(10, 50.0), hit(10, 50.0), hit(10, 50.0)))
        var s = ProgressionEngine.suggest("squat",
            listOf(PlannedTarget(10, 50.0)), ProgressionPolicy.TRIPLE, history)
        assertEquals(11, s.reps)
        // Hit en 12 con 3 series -> 4 series.
        history = listOf(workout(hit(12, 50.0), hit(12, 50.0), hit(12, 50.0)))
        s = ProgressionEngine.suggest("squat",
            listOf(PlannedTarget(12, 50.0)), ProgressionPolicy.TRIPLE, history)
        assertEquals(4, s.setCount)
        assertEquals(12, s.reps)
        // Hit en 12 con 5 series -> peso y reinicio 3×6.
        history = listOf(workout(hit(12, 50.0), hit(12, 50.0), hit(12, 50.0),
            hit(12, 50.0), hit(12, 50.0), plannedCount = 5))
        s = ProgressionEngine.suggest("squat",
            listOf(PlannedTarget(12, 50.0)), ProgressionPolicy.TRIPLE, history)
        assertEquals(52.5, s.weightKg!!, 0.0001)
        assertEquals(3, s.setCount)
        assertEquals(6, s.reps)
    }

    @Test fun firstTimeUsesPlanAndWarmupsIgnored() {
        val history = listOf(workout(
            StatsSet(reps = 20, weightKg = 40.0, isWarmup = true),
            hit(8, 100.0), hit(8, 100.0), hit(8, 100.0)))
        // Solo 3 series de trabajo; el calentamiento no infla el hit.
        val s = ProgressionEngine.suggest("squat",
            listOf(PlannedTarget(8, 100.0)), ProgressionPolicy.LINEAR, history)
        assertEquals(102.5, s.weightKg!!, 0.0001)
        val fresh = ProgressionEngine.suggest("press",
            listOf(PlannedTarget(10)), ProgressionPolicy.GREYSKULL, emptyList())
        assertNull(fresh.weightKg)
        assertEquals(3, fresh.setCount)
    }
}
