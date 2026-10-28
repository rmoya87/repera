package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** Paridad `EffortUnitSettingsTests` iOS: intensidad canónica = RIR. */
class EffortUnitSettingsTest {
    @Test
    fun canonicalRirAndDisplayRpeRoundTrip() {
        for (rir in 0..5) {
            val stored = rir.toDouble()
            val displayed = Effort.fromRIR(stored, "rpe")
            assertEquals(10.0 - stored, displayed, 0.0)
            assertEquals(stored, Effort.toRIR(displayed, "rpe"), 0.0)
        }
    }

    @Test
    fun rpeLabelsFollowDisplayPreference() {
        assertEquals("RIR 2", Effort.label(2.0, "rir"))
        assertEquals("RPE 8", Effort.label(2.0, "rpe"))
        assertNull(Effort.label(null, "rpe"))
        assertEquals("RIR", Effort.displayName("rir"))
        assertEquals("RPE", Effort.displayName("rpe"))
    }
}
