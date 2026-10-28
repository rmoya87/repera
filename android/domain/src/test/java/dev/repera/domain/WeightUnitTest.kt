package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Test

class WeightUnitTest {
    @Test
    fun unitRoundTripPreservesStoredKilograms() {
        val weightKg = 100.0
        val shownLb = WeightUnit.LB.displayValue(fromKilograms = weightKg)
        assertEquals(220.46226218, shownLb, 0.000001)
        assertEquals(
            weightKg,
            WeightUnit.LB.kilograms(fromDisplayValue = shownLb),
            0.000001
        )
        assertEquals(weightKg, WeightUnit.KG.displayValue(fromKilograms = weightKg), 0.0)
        assertEquals("lb", WeightUnit.LB.label)
        assertEquals(WeightUnit.KG, WeightUnit.fromWire(null))
        assertEquals(WeightUnit.LB, WeightUnit.fromWire("LB"))
    }
}
