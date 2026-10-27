package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class MuscleLoadEngineTest {

    private fun set(reps: Int, warmup: Boolean = false, rir: Double? = null) =
        MuscleStimulusSet(reps = reps, isWarmup = warmup, rir = rir)

    private fun workout(vararg exercises: MuscleStimulusExercise) =
        MuscleStimulusWorkout(epochMillis = 0L, exercises = exercises.toList())

    @Test
    fun `load suma series efectivas por peso muscular`() {
        val w = workout(
            MuscleStimulusExercise(
                targetMuscle = "pectorals",
                sets = listOf(set(10), set(8), set(0), set(12, warmup = true))
            )
        )
        val load = MuscleLoadEngine.load(listOf(w))
        // 2 series válidas (reps 0 y calentamiento no cuentan), pecho peso 1.
        assertEquals(2.0, load["chest"] ?: 0.0, 1e-9)
    }

    @Test
    fun `load hardOnly exige RIR duro`() {
        val w = workout(
            MuscleStimulusExercise(
                targetMuscle = "pectorals",
                sets = listOf(set(10, rir = 1.0), set(10, rir = 4.0), set(10))
            )
        )
        val hard = MuscleLoadEngine.load(listOf(w), hardOnly = true)
        assertEquals(1.0, hard["chest"] ?: 0.0, 1e-9)
    }

    @Test
    fun `load suma estimulos externos`() {
        val load = MuscleLoadEngine.load(
            emptyList(),
            external = listOf(ExternalMuscleStimulus(0L, mapOf("quadriceps" to 3.0)))
        )
        assertEquals(3.0, load["quadriceps"] ?: 0.0, 1e-9)
    }

    @Test
    fun `levels normaliza contra el maximo del periodo`() {
        val levels = MuscleLoadEngine.levels(mapOf("chest" to 8.0, "abs" to 4.0, "calves" to 0.0))
        assertEquals(4, levels["chest"])
        assertEquals(2, levels["abs"])
        assertEquals(0, levels["calves"])
    }

    @Test
    fun `ranked separa trabajados y omitidos en orden de carga`() {
        val (worked, missed) = MuscleLoadEngine.ranked(mapOf("abs" to 2.0, "chest" to 5.0))
        assertEquals(listOf("chest", "abs"), worked)
        assertTrue("calves" in missed)
        assertTrue(missed.none { it == "chest" || it == "abs" })
    }

    @Test
    fun `load suma equivalente estimado de WOD completado sin series`() {
        val w = workout(
            MuscleStimulusExercise(
                targetMuscle = "pectorals",
                sets = emptyList(),
                completedWodSetEquivalent = 1.0
            )
        )
        val load = MuscleLoadEngine.load(listOf(w))
        assertEquals(1.0, load["chest"] ?: 0.0, 1e-9)
    }

    @Test
    fun `load hardOnly ignora el equivalente estimado WOD`() {
        val w = workout(
            MuscleStimulusExercise(
                targetMuscle = "pectorals",
                sets = emptyList(),
                completedWodSetEquivalent = 1.0
            )
        )
        assertTrue(MuscleLoadEngine.load(listOf(w), hardOnly = true).isEmpty())
    }

    @Test
    fun `load con series reales no suma el equivalente estimado`() {
        val w = workout(
            MuscleStimulusExercise(
                targetMuscle = "pectorals",
                sets = listOf(set(10), set(8)),
                completedWodSetEquivalent = 1.0
            )
        )
        assertEquals(2.0, MuscleLoadEngine.load(listOf(w))["chest"] ?: 0.0, 1e-9)
    }
}
