package dev.repera.wear

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
class WearLocalWodClockTest {
    private fun exercise() = JSONObject()
        .put("wodFormat", "emom")
        .put("blockIntervalSeconds", 60)
        .put("blockRounds", 10)
        .put("blockHeader", "EMOM")
        .put("exercise", JSONObject().put("name", "Thruster"))

    @Test fun seedBuildsPhoneShapedTimer() {
        val timer = WearLocalWodClock.seed("s1", 2, exercise())
        assertNotNull(timer)
        assertEquals("s1", timer!!.getString("sessionId"))
        assertEquals(2, timer.getInt("blockIndex"))
        assertEquals("emom", timer.getString("format"))
        assertTrue(timer.getBoolean("local"))
        assertFalse(timer.getBoolean("running"))
        assertEquals(0, timer.getInt("elapsedSeconds"))
        assertTrue(wearTimerMatches(timer, "s1", 3))
        assertEquals(0, wearWodIntervalIndex(timer, "s1", 3, 0))
        assertEquals(2, wearWodIntervalIndex(timer, "s1", 3, 125))
    }

    @Test fun startPauseResetPreserveElapsed() {
        val seeded = WearLocalWodClock.seed("s1", 0, exercise())!!
        val started = WearLocalWodClock.start(seeded, nowWallMs = 1_000_000L)
        assertTrue(started.getBoolean("running"))
        assertEquals(1_000_000L, started.getLong("zeroAtWallMs"))
        val paused = WearLocalWodClock.pause(started, nowWallMs = 1_045_000L)
        assertFalse(paused.getBoolean("running"))
        assertEquals(45, paused.getInt("elapsedSeconds"))
        val reset = WearLocalWodClock.reset(paused)
        assertEquals(0, reset.getInt("elapsedSeconds"))
        assertFalse(reset.getBoolean("running"))
    }
}
