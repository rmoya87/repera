package dev.repera.domain

/**
 * Apple startToday + selectBlock leaves HealthKit paused. The Wear health service starts asynchronously and has no
 * start-paused mode, so the watch keeps an intent and pauses sensors once recording is confirmed.
 * Pure decision logic: the Activity feeds it each sensor update and obeys the result.
 */
class WearStartPauseIntent(val sessionId: String) {
    enum class Decision { PAUSE, WAIT, DROP }
    private var issued = false

    fun onSensorState(
        visibleSessionId: String?, stateSessionId: String?, recording: Boolean,
        sensorsPaused: Boolean, uiPaused: Boolean
    ): Decision {
        if (visibleSessionId != sessionId) return Decision.DROP   // another session or none
        if (!uiPaused) return Decision.DROP                       // user pressed Reanudar first
        if (stateSessionId != sessionId) return Decision.WAIT     // update for another owner
        if (sensorsPaused) return Decision.DROP                   // pause confirmed by the sensor callback
        if (!recording) return Decision.WAIT                      // service not recording yet
        if (issued) return Decision.WAIT                          // one request until confirmed or dropped
        issued = true
        return Decision.PAUSE
    }
}
