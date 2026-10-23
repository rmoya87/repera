package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.util.UUID

@RunWith(AndroidJUnit4::class)
class WodTimerStoreInstrumentedTest {
    @Test fun monotonicClockSurvivesRecreationAndPause() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val googleUser = UUID.randomUUID().toString()
        var uptime = 100000L
        val first = WodTimerStore(context, googleUser) { uptime }
        assertEquals(0, first.read("session-a", 0).elapsedSeconds)
        assertTrue(first.update("session-a", 0, "start").running)
        uptime += 7200
        val recreated = WodTimerStore(context, googleUser) { uptime }
        assertEquals(7, recreated.read("session-a", 0).elapsedSeconds)
        recreated.update("session-a", 0, "pause")
        uptime += 3000
        assertEquals(7, first.read("session-a", 0).elapsedSeconds)
        assertFalse(first.read("session-a", 0).running)
        first.update("session-a", 0, "start")
        uptime += 1500
        assertEquals(8, first.read("session-a", 0).elapsedSeconds)
        assertEquals(0, first.read("session-b", 0).elapsedSeconds)
        assertEquals(0, first.read("session-a", 1).elapsedSeconds)
        first.update("session-a", 0, "reset")
        assertEquals(0, first.read("session-a", 0).elapsedSeconds)
    }

    @Test fun separateGoogleAccountsNeverShareTheClock() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        var uptime = 100000L
        val a = WodTimerStore(ctx, UUID.randomUUID().toString()) { uptime }
        val b = WodTimerStore(ctx, UUID.randomUUID().toString()) { uptime }
        a.update("session", 0, "start")
        uptime += 2500
        assertEquals(2, a.read("session", 0).elapsedSeconds)
        assertEquals(0, b.read("session", 0).elapsedSeconds)
    }
}
