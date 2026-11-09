package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test

class WearOwnedLiveDeliveryPolicyTest {
    private val now = 1_800_000_000_000L

    @Test fun freshActiveWatchSnapshotAccepted() {
        assertTrue(WearOwnedLiveDeliveryPolicy.accepts(
            "recording", now - 1_000L, now, 0L, false
        ))
        assertTrue(WearOwnedLiveDeliveryPolicy.accepts(
            "paused", now - 1_000L, now, 0L, false
        ))
    }

    @Test fun oldOutOfOrderAndDuplicatedActiveSnapshotsRejected() {
        assertFalse(WearOwnedLiveDeliveryPolicy.accepts(
            "recording", now - 8_000L, now, now - 5_000L, false
        ))
        assertFalse(WearOwnedLiveDeliveryPolicy.accepts(
            "paused", now - 5_000L, now, now - 5_000L, false
        ))
    }

    @Test fun staleAndFuturePacketsRejected() {
        assertFalse(WearOwnedLiveDeliveryPolicy.accepts(
            "recording", now - 90_001L, now, 0L, false
        ))
        assertFalse(WearOwnedLiveDeliveryPolicy.accepts(
            "recording", now + 5_001L, now, 0L, false
        ))
        assertFalse(WearOwnedLiveDeliveryPolicy.accepts(
            "finished", now - 3_600_001L, now, 0L, false
        ))
        assertFalse(WearOwnedLiveDeliveryPolicy.accepts(
            "unknown", now, now, 0L, false
        ))
    }

    @Test fun terminalMayCloseEvenIfInitialSnapshotWasMissed() {
        assertTrue(WearOwnedLiveDeliveryPolicy.accepts(
            "finished", now - 120_000L, now, now - 1_000L, false
        ))
        assertTrue(WearOwnedLiveDeliveryPolicy.accepts(
            "finished", now - 120_000L, now, now, true
        ))
    }

    @Test fun closedSessionNeverRestarts() {
        assertFalse(WearOwnedLiveDeliveryPolicy.accepts(
            "recording", now, now, 0L, true
        ))
    }
}
