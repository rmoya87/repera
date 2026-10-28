package dev.repera.mobile

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class WeightDisplayTest {
    @Test
    fun lbRoundTripAndLabels() {
        assertEquals("lb", WeightDisplay.label("lb"))
        assertEquals("kg", WeightDisplay.label(null))
        val shown = WeightDisplay.fieldText(100.0, "lb")
        assertTrue(shown.contains("220"))
        val kg = WeightDisplay.parseToKg(shown, "lb")
        assertEquals(100.0, kg!!, 0.01)
        assertNull(WeightDisplay.parseToKg("", "lb"))
        assertTrue(WeightDisplay.suffix(100.0, "kg").contains("kg"))
        assertTrue(WeightDisplay.suffix(100.0, "lb").contains("lb"))
    }
}
