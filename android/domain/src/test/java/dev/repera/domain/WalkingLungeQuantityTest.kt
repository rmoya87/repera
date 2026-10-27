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
}
