package dev.repera.mobile

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class CloudSyncGateTest {
    @Test fun gateIsClosedOnlyDuringDriveSyncAndReleasedOnFailure() {
        assertFalse(CloudSyncGate.isDriveSyncRunning())
        CloudSyncGate.driveSync { assertTrue(CloudSyncGate.isDriveSyncRunning()) }
        assertFalse(CloudSyncGate.isDriveSyncRunning())
        try { CloudSyncGate.driveSync<Unit> { error("fallo de red") } } catch (_: IllegalStateException) {}
        assertFalse(CloudSyncGate.isDriveSyncRunning())
    }
    @Test fun nestedSyncsKeepGateClosedUntilTheLastEnds() {
        CloudSyncGate.driveSync {
            CloudSyncGate.driveSync { }
            assertTrue(CloudSyncGate.isDriveSyncRunning())
        }
        assertEquals(false, CloudSyncGate.isDriveSyncRunning())
    }
}
