package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test

/** Espejo de WalkingLungeQuantityTests.swift (Apple ae8b8089). */
class WalkingLungeQuantityTest {
    @Test fun walkingLungeAllowsWeightWithEitherQuantityUnit() {
        for (title in listOf("Walking lunge", "Walking lunges", "Walking lung", "Zancadas caminando")) {
            assertTrue(title, ExerciseInput.supportsWeightedRepsOrMeters(title))
            assertEquals(title, "reps", ExerciseInput.defaultQuantityUnit(title, "Peso corporal"))
        }
    }

    @Test fun otherLungesDoNotGainDistanceToggleAutomatically() {
        assertFalse(ExerciseInput.supportsWeightedRepsOrMeters("Zancadas inversas con barra"))
    }

    @Test fun carriesAndSledsStartInMeters() {
        for (title in listOf("Farmer carry", "Sled push", "Sandbag lunges", "Yoke carry")) {
            assertTrue(title, ExerciseInput.supportsWeightedRepsOrMeters(title))
            assertEquals(title, "meters", ExerciseInput.defaultQuantityUnit(title, null))
        }
        // Sin lastre: repeticiones o m, nunca kg.
        assertTrue(ExerciseInput.supportsRepsOrMeters("Burpee broad jump"))
        assertFalse(ExerciseInput.supportsWeightedRepsOrMeters("Burpee broad jump"))
        assertTrue(ExerciseInput.supportsRepsOrMeters("Bear crawl"))
    }

    @Test fun metersAndRepsKeepWeightAndUnitSeparately() {
        // displaySummaryLine Apple: "20 m · 16 kg"; metros x kg no es volumen.
        assertEquals("20 m · 16 kg",
            SetSummaryLine.displayLine(20, quantityUnit = "meters", weightKg = 16.0))
        assertEquals("20×12",
            SetSummaryLine.displayLine(12, quantityUnit = "reps", weightKg = 20.0))
    }

    @Test fun legacyLineWithoutUnitIsNotReinterpreted() {
        assertEquals("12×14", SetSummaryLine.displayLine(14, weightKg = 12.0))
    }

    @Test fun loadedDistanceNamesAreLoadAndReps() {
        // Apple 1d1edc8b: supportsWeightedRepsOrMeters -> loadAndReps incluso
        // con peso corporal en el seed (Walking lunge admite kg + reps/m).
        assertEquals(dev.repera.domain.ExerciseInputMode.LOAD_REPS,
            ExerciseInput.mode("Walking lunge", "Peso corporal", null, "Piernas"))
        assertEquals(dev.repera.domain.ExerciseInputMode.LOAD_REPS,
            ExerciseInput.mode("Zancadas caminando", "Mancuernas", null, "Piernas"))
        assertEquals(dev.repera.domain.ExerciseInputMode.LOAD_REPS,
            ExerciseInput.mode("Yoke carry", "Yoke", null, "Full body"))
        // Los 5 Hyrox consolidados conservan LOAD_DISTANCE (metros + kg).
        assertEquals(dev.repera.domain.ExerciseInputMode.LOAD_DISTANCE,
            ExerciseInput.mode("Sled push", "Trineo", null, "Piernas"))
    }

    @Test fun weightedMachineQuantityDoesNotScaleByMinutes() {
        // Apple 1d1edc8b fatigueSetEquivalent: (isMachineQuantity || duration)
        // && weightKg == nil. Con kg, cae a la logica RIR normal.
        val loaded = dev.repera.domain.MuscleStimulusSet(reps = 20,
            isMachineQuantity = true, weightKg = 16.0, durationSeconds = 120)
        assertEquals(0.7, loaded.fatigueSetEquivalent, 1e-9)
        val unloaded = dev.repera.domain.MuscleStimulusSet(reps = 20,
            isMachineQuantity = true, durationSeconds = 120)
        assertEquals(2.0, unloaded.fatigueSetEquivalent, 1e-9)
    }
}
