package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test

class AppleCardioUnitsTest {
    @Test fun toggleMatchesSwiftRules() {
        assertTrue(AppleCardioUnits.allowsCalorieOrDistanceToggle("Air Bike", null))
        assertTrue(AppleCardioUnits.allowsCalorieOrDistanceToggle("SkiErg", null))
        assertTrue(AppleCardioUnits.allowsCalorieOrDistanceToggle("Remo máquina", null))
        assertTrue(AppleCardioUnits.allowsCalorieOrDistanceToggle("Sled Push", "Trineo"))
        assertFalse(AppleCardioUnits.allowsCalorieOrDistanceToggle("Sled Push", null))
        assertFalse(AppleCardioUnits.allowsCalorieOrDistanceToggle("Carrera", null))
        assertFalse(AppleCardioUnits.allowsCalorieOrDistanceToggle("Remo con barra", null))
        assertFalse(AppleCardioUnits.allowsCalorieOrDistanceToggle("Farmer Carry", null))
        assertFalse(AppleCardioUnits.allowsCalorieOrDistanceToggle("Sentadilla", null))
    }
    @Test fun defaultsMatchSwift() {
        assertEquals("calories", AppleCardioUnits.defaultQuantityUnit("Air Bike", null))
        assertEquals("meters", AppleCardioUnits.defaultQuantityUnit("Remoergómetro", null))
        assertEquals("meters", AppleCardioUnits.defaultQuantityUnit("Farmer Carry", null))
        assertEquals("meters", AppleCardioUnits.defaultQuantityUnit("Sled Push", "Trineo"))
        assertEquals("reps", AppleCardioUnits.defaultQuantityUnit("Sentadilla", null))
    }
}
