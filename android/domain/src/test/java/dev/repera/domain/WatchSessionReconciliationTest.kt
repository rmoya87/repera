package dev.repera.domain

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class WatchSessionReconciliationTest {
    @Test fun stalePhoneEmptySnapshotMustNotDeleteOfflineWatchWork() {
        assertTrue(WatchSessionReconciliation.preserveLocal(true, "local", null, null))
        assertTrue(WatchSessionReconciliation.preserveLocal(true, "local", null, "other"))
        assertFalse(WatchSessionReconciliation.phoneDiscarded("local", null, null))
        assertFalse(WatchSessionReconciliation.phoneDiscarded("local", null, "other"))
    }

    @Test fun otherLivePhoneSessionStillPreservesWatchOwnedWork() {
        assertTrue(WatchSessionReconciliation.preserveLocal(true, "local", "other", null))
    }

    @Test fun matchingAdoptionOrFinishedSessionCanReconcile() {
        assertFalse(WatchSessionReconciliation.preserveLocal(true, "local", "local", null))
        assertFalse(WatchSessionReconciliation.preserveLocal(true, "local", null, "local"))
        assertFalse(WatchSessionReconciliation.preserveLocal(false, "local", null, null))
        assertFalse(WatchSessionReconciliation.preserveLocal(true, null, null, null))
        assertFalse(WatchSessionReconciliation.phoneDiscarded("local", null, "local", "local"))
    }

    @Test fun onlyExplicitMatchingDiscardMayClearWatch() {
        assertTrue(WatchSessionReconciliation.phoneDiscarded("local", null, null, "local"))
        assertFalse(WatchSessionReconciliation.phoneDiscarded("local", null, null, "other"))
        assertFalse(WatchSessionReconciliation.preserveLocal(true, "local", null, null, "local"))
        assertTrue(WatchSessionReconciliation.preserveLocal(true, "local", null, null, "other"))
    }
}
