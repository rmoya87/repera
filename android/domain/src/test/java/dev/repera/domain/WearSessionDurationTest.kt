package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

class WearSessionDurationTest {
    @Test fun prefersMeasuredAndFormatsHours() {
        assertEquals("1:05:03", WearSessionDuration.format(
            WearSessionDuration.resolveSeconds(null, null, 3903.0)))
    }

    @Test fun clampsStaleWallClock() {
        // ~4 days between stamps would become Apple's «5865:52» with %02d:%02d of seconds/60.
        val seconds = WearSessionDuration.resolveSeconds(
            "2026-10-25T07:00:00Z", "2026-10-29T08:45:52Z", null)
        assertEquals(WearSessionDuration.MAX_SECONDS, seconds)
        val label = WearSessionDuration.format(seconds)
        assertFalse(label.startsWith("5865"))
        assertEquals("12:00:00", label)
    }

    @Test fun shortSessionsStayMmSs() {
        assertEquals("33:00", WearSessionDuration.format(
            WearSessionDuration.resolveSeconds(
                "2026-10-29T07:11:00Z", "2026-10-29T07:44:00Z", null)))
    }
}
