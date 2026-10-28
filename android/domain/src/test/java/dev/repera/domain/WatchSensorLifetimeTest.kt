package dev.repera.domain
import org.junit.Assert.*
import org.junit.Test
class WatchSensorLifetimeTest {
    @Test fun terminalDuringStartDoesNotReleaseOwnerBeforeStartSettles() {
        assertFalse(WatchSensorLifetime.mayRetire(true,true))
        assertTrue(WatchSensorLifetime.mayRetire(false,true))
    }
    @Test fun stopDuringStartWaitsEvenBeforeFirstRecordingCallback() {
        assertFalse(WatchSensorLifetime.mayRetire(true,false))
        assertFalse(WatchSensorLifetime.mayRetire(false,false))
    }
    @Test fun requestedStopIsNotConfirmationWhileStillRecording() {
        assertFalse(WatchSensorLifetime.mayRetire(false,false))
        assertTrue(WatchSensorLifetime.mayRetire(false,true))
    }
    @Test fun idleWithoutEndRequestIsNotTerminalEvidence() {
        assertFalse(WatchSensorLifetime.mayRetire(false,false))
        assertFalse(WatchSensorLifetime.mayRetire(false,false))
    }
}
