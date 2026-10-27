package dev.repera.domain
import dev.repera.domain.WearStartPauseIntent.Decision.*
import org.junit.Assert.assertEquals
import org.junit.Test

class WearStartPauseIntentTest {
    private fun d(i: WearStartPauseIntent, visible: String? = "s", state: String? = "s", rec: Boolean = true,
                  paused: Boolean = false, ui: Boolean = true) = i.onSensorState(visible, state, rec, paused, ui)
    @Test fun waitsUntilRecordingThenPausesOnce() {
        val i = WearStartPauseIntent("s")
        assertEquals(WAIT, d(i, rec = false))
        assertEquals(PAUSE, d(i))
        assertEquals(WAIT, d(i))          // no spam while the callback is pending
        assertEquals(DROP, d(i, paused = true))
    }
    @Test fun userResumingBeforeRecordingDropsIntent() = assertEquals(DROP, d(WearStartPauseIntent("s"), ui = false, rec = false))
    @Test fun otherSessionDropsIntent() = assertEquals(DROP, d(WearStartPauseIntent("s"), visible = "other"))
    @Test fun updateForOtherOwnerNeverPauses() = assertEquals(WAIT, d(WearStartPauseIntent("s"), state = "other"))
    @Test fun noVisibleSessionDrops() = assertEquals(DROP, d(WearStartPauseIntent("s"), visible = null))
    @Test fun freshIntentAfterRestartPausesSensorsThatKeepRecording() {
        // Durable UI pause restored, sensors recording unpaused: a new intent issues exactly one pause.
        val i = WearStartPauseIntent("s")
        assertEquals(PAUSE, d(i, rec = true, paused = false, ui = true))
        assertEquals(WAIT, d(i, rec = true, paused = false, ui = true))
    }
}
