package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class MuscleMapEngineTest {
    private val now = 1_800_000_000_000L

    private fun workout(hoursAgo: Double, vararg exercises: MuscleStimulusExercise) =
        MuscleStimulusWorkout(
            epochMillis = now - (hoursAgo * 3_600_000).toLong(),
            exercises = exercises.toList())

    private fun benchPress(sets: List<MuscleStimulusSet>) = MuscleStimulusExercise(
        sportTag = "Gimnasio",
        targetMuscle = "pectorals",
        secondaryMuscles = listOf("triceps", "shoulders"),
        muscleGroup = "Pecho",
        sets = sets)

    @Test fun taxonomyResolvesAliasesAndGroups() {
        assertEquals("chest", MuscleTaxonomy.canonical("pectorals"))
        assertEquals("chest", MuscleTaxonomy.canonical("Pecho"))
        assertEquals("upper-back", MuscleTaxonomy.canonical("Lats"))
        assertEquals(null, MuscleTaxonomy.canonical("cardio"))
        assertEquals(null, MuscleTaxonomy.canonical("full body"))
        assertEquals("Pecho", MuscleTaxonomy.displayName("chest"))
        assertEquals("Pecho",
            MuscleTaxonomy.libraryMuscleGroup(listOf("pectorals"), null))
        assertEquals("Cardio",
            MuscleTaxonomy.libraryMuscleGroup(emptyList(), "cardiovascular system"))
        assertEquals("Custom",
            MuscleTaxonomy.libraryMuscleGroup(emptyList(), null))
    }

    @Test fun muscleWeightsFollowIosPriorities() {
        // Press banca: target pectorals=1, triceps 0.55 (1º secundario),
        // shoulders 0.35 (resto), refuerzo suave del grupo Pecho (ya cubierto).
        val w = MuscleTaxonomy.muscleWeights(
            targetMuscle = "pectorals",
            primaryRegions = emptyList(),
            secondaryMuscles = listOf("triceps", "shoulders"),
            secondaryRegions = emptyList(),
            bodyPart = null,
            muscleGroup = "Pecho")
        assertEquals(1.0, w["chest"]!!, 0.0001)
        assertEquals(0.55, w["triceps"]!!, 0.0001)
        assertEquals(0.35, w["deltoids"]!!, 0.0001)
        // bodyPart genérico no pinta a peso 1; fallback al grupo ES.
        val cardio = MuscleTaxonomy.muscleWeights(
            null, emptyList(), emptyList(), emptyList(),
            bodyPart = "cardio", muscleGroup = "Cardio")
        assertTrue(cardio.isEmpty() || cardio.values.all { it <= 0.2 })
    }

    @Test fun retainedLoadDecaysWithHalfLife() {
        val sets = List(4) { MuscleStimulusSet(reps = 8, rir = 1.0) }
        val recent = workout(0.0, benchPress(sets))
        val old = workout(30.0, benchPress(sets)) // una vida media de pecho (30h)
        val scoresRecent = MuscleMapEngine.retainedLoad(listOf(recent), nowMillis = now)
        val scoresOld = MuscleMapEngine.retainedLoad(listOf(old), nowMillis = now)
        // 4 series duras / 8 = 0.5 en pecho recién hecho.
        assertEquals(0.5, scoresRecent["chest"]!!, 0.0001)
        // A las 30h el pecho retiene la mitad.
        assertEquals(0.25, scoresOld["chest"]!!, 0.0001)
        // Tríceps cargó con 0.55 de peso en ambos casos.
        assertEquals(scoresRecent["triceps"]!!, 0.5 * 0.55, 0.0001)
    }

    @Test fun filtersMobilityWarmupAndOldWorkouts() {
        val mobility = MuscleStimulusExercise(
            sportTag = "Movilidad",
            muscleGroup = "Core",
            sets = listOf(MuscleStimulusSet(reps = 1, durationSeconds = 300)))
        val scores = MuscleMapEngine.retainedLoad(
            listOf(workout(1.0, mobility)), nowMillis = now)
        assertTrue(scores.isEmpty())
        val warmupOnly = workout(1.0, benchPress(
            listOf(MuscleStimulusSet(reps = 10, isWarmup = true))))
        // Calentamiento cuenta 0.25 en el modo general, nada en hardOnly.
        assertTrue(MuscleMapEngine.retainedLoad(
            listOf(warmupOnly), hardOnly = true, nowMillis = now).isEmpty())
        assertTrue(MuscleMapEngine.retainedLoad(
            listOf(warmupOnly), nowMillis = now).isNotEmpty())
        val ancient = workout(31.0 * 24, benchPress(
            listOf(MuscleStimulusSet(reps = 5, rir = 0.0))))
        assertTrue(MuscleMapEngine.retainedLoad(listOf(ancient), nowMillis = now).isEmpty())
    }

    @Test fun levelsAndStatesMatchIosThresholds() {
        assertEquals(0, MuscleMapEngine.level(0.0))
        assertEquals(1, MuscleMapEngine.level(0.1))
        assertEquals(2, MuscleMapEngine.level(0.3))
        assertEquals(3, MuscleMapEngine.level(0.6))
        assertEquals(4, MuscleMapEngine.level(1.0))
        assertEquals(FatigueState.READY, MuscleMapEngine.state(0.2))
        assertEquals(FatigueState.RECOVERING, MuscleMapEngine.state(0.4))
        assertEquals(FatigueState.FATIGUED, MuscleMapEngine.state(0.9))
        val levels = MuscleMapEngine.levels(mapOf("chest" to 0.9))
        assertEquals(4, levels["chest"])
        assertEquals(0, levels["calves"])
        assertEquals(18, levels.size)
    }

    @Test fun effortThresholdsMatchIos() {
        assertTrue(Effort.isHard(2.0))
        assertTrue(Effort.isHard(0.0))
        assertTrue(!Effort.isHard(2.5))
        assertTrue(!Effort.isHard(null))
        assertEquals(8.0, Effort.toRIR(2.0, "rpe"), 0.0001)
        assertEquals(3.0, Effort.fromRIR(3.0, "rir"), 0.0001)
        assertEquals("Duro (cerca del fallo)", Effort.plainLanguage(1.5))
    }

    @Test fun externalStimulusAddsLoad() {
        val external = listOf(ExternalMuscleStimulus(now, mapOf("quadriceps" to 4.0)))
        val scores = MuscleMapEngine.retainedLoad(emptyList(), external, nowMillis = now)
        assertEquals(0.5, scores["quadriceps"]!!, 0.0001)
    }
}
