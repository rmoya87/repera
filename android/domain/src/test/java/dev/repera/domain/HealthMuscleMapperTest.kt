package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class HealthMuscleMapperTest {
    @Test fun cardioClassificationMatchesIos() {
        assertTrue(HealthMuscleMapper.isCardio("running"))
        assertTrue(HealthMuscleMapper.isCardio("crossTraining"))
        assertFalse(HealthMuscleMapper.isCardio("traditionalStrengthTraining"))
        // Deportes no listados cuentan como cardio.
        assertTrue(HealthMuscleMapper.isCardio("soccer"))
    }

    @Test fun setUnitsWeightIntensity() {
        // HIIT: 30 min a 10 min/serie = 3 series efectivas.
        val hiit = HealthMuscleMapper.muscleLoad(
            "highIntensityIntervalTraining", 30.0)
        assertEquals(0.45, hiit["quadriceps"]!!, 0.0001)
        // Paseo suave: 22 min = 1 serie efectiva.
        val walk = HealthMuscleMapper.muscleLoad("walking", 22.0)
        assertEquals(0.3, walk["quadriceps"]!!, 0.0001)
        // Mínimo 0.5 series aunque dure 1 minuto.
        val tiny = HealthMuscleMapper.muscleLoad("running", 1.0)
        assertEquals(0.15, tiny["quadriceps"]!!, 0.0001)
    }

    @Test fun templatesCoverSportFamilies() {
        assertEquals(0.5, HealthMuscleMapper.muscleLoad("coreTraining", 12.0)["abs"]!!, 0.0001)
        assertEquals(0.3, HealthMuscleMapper.muscleLoad("golf", 22.0)["obliques"]!!, 0.0001)
        // Tipo desconocido: plantilla genérica, nunca vacía.
        assertTrue(HealthMuscleMapper.muscleLoad("other", 16.0).isNotEmpty())
    }

    @Test fun daySamplesKeepStrengthOutOfCardio() {
        val activities = listOf(
            HealthMuscleMapper.ExternalActivity(1000L, "running", 30.0, 200.0),
            HealthMuscleMapper.ExternalActivity(2000L, "functionalStrengthTraining", 45.0, 150.0))
        val samples = HealthMuscleMapper.daySamples(activities)
        assertEquals(30.0, samples[0].cardioMinutes, 0.0001)
        assertEquals(0.0, samples[1].cardioMinutes, 0.0001)
        assertEquals(45.0, samples[1].minutes, 0.0001)
        assertEquals(150.0, samples[1].activeEnergyKcal, 0.0001)
        val stimuli = HealthMuscleMapper.stimuli(activities)
        assertEquals(2, stimuli.size)
        assertTrue(stimuli[1].load.containsKey("chest"))
    }
}
