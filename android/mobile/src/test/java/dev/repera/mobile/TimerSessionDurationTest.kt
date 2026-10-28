package dev.repera.mobile

import dev.repera.domain.TimerCompletionDetails
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

class TimerSessionDurationTest {
    @Test
    fun progressSnapshotUsesConfiguredTimerMinutes() {
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
            .put("finishedAt", "2026-10-28T10:10:00Z") // pared 10 min; configurado 1,5
            .put("exercises", JSONArray())
            .put("timerDetails", details.toJson())
        val state = JSONObject().put("workouts", JSONArray().put(session))
        val stats = ProgressSnapshotBuilder.statsWorkouts(state)
        assertEquals(1, stats.size)
        assertEquals(1.5, stats.single().durationMinutes, 0.001)
        assertFalse(FinishedSessionDuration.shouldDeriveFromSchedule(session))
    }
}
