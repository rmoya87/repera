package dev.repera.domain

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class WatchSessionReconciliationTest {
    @Test fun emptyPhoneSnapshotMustPreserveWatchOwnedOfflineWork() {
        // The mobile can be offline or recently installed. Empty is not
        // proof that the user discarded a watch-owned workout.
        assertTrue(WatchSessionReconciliation.preserveLocal(true, "local", null, null))
        assertTrue(WatchSessionReconciliation.preserveLocal(true, "local", null, "other"))
        assertTrue(WatchSessionReconciliation.phoneDiscarded("local", null, null))
        assertTrue(WatchSessionReconciliation.phoneDiscarded("local", null, "other"))
    }

    @Test fun otherLivePhoneSessionStillPreservesWatchOwnedWork() {
        assertTrue(WatchSessionReconciliation.preserveLocal(true, "local", "other", null))
    }

    @Test fun matchingAdoptionOrMatchingFinishedSessionCanReconcile() {
        assertFalse(WatchSessionReconciliation.preserveLocal(true, "local", "local", null))
        assertFalse(WatchSessionReconciliation.preserveLocal(true, "local", null, "local"))
        assertFalse(WatchSessionReconciliation.preserveLocal(false, "local", null, null))
        assertFalse(WatchSessionReconciliation.preserveLocal(true, null, null, null))
        assertFalse(WatchSessionReconciliation.phoneDiscarded("local", null, "local"))
    }
}
