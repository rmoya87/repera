package dev.repera.domain

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class TimerCompletionDetailsTest {
    @Test
    fun timerWorkoutRoundTripPreservesIdentityAndDuration() {
        val details = TimerCompletionDetails(
            modeRaw = "intervals",
            configuredSeconds = 90,
            rounds = 3,
            workSeconds = 30,
            restSeconds = 0,
            countdownSeconds = 3
        )
        val session = JSONObject()
            .put("id", "timer-1")
            .put("title", "Temporizador · Intervalos")
            .put("phase", "finished")
            .put("startedAt", "2026-10-28T10:00:00Z")
            .put("finishedAt", "2026-10-28T10:01:32Z")
            .put("exercises", org.json.JSONArray())
            .put("timerDetails", details.toJson())

        val restored = TimerCompletionDetails.fromSession(session)
        assertEquals(details, restored)
        assertEquals("Intervalos", restored!!.modeTitle)
        assertEquals(1.5, restored.displayDurationMinutes, 0.001)
        assertNull(session.opt("healthKitWorkoutUUID")?.takeIf { it != JSONObject.NULL })
        assertNull(session.opt("appleActiveEnergyKcal")?.takeIf { it != JSONObject.NULL })
    }

    @Test
    fun legacyWorkoutCompatibilityWithoutTimerDetails() {
        val old = JSONObject()
            .put("id", "force-1")
            .put("title", "Fuerza")
            .put("phase", "finished")
            .put("startedAt", "2026-01-01T10:00:00Z")
            .put("finishedAt", "2026-01-01T10:01:00Z")
            .put("exercises", org.json.JSONArray())
        assertNull(TimerCompletionDetails.fromSession(old))
    }
}
