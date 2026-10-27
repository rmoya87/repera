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
    @Test fun recoveryIsSkippedInsideDriveAndWorksAfterItEnds() {
        CloudSyncGate.driveSync {assertEquals(null,CloudSyncGate.recoverUnlessDrive {error("must not run")})}
        assertEquals(7,CloudSyncGate.recoverUnlessDrive {7})
    }
    @Test fun driveCannotReplaceSnapshotHalfwayThroughRecoveryApply() {
        val entered=java.util.concurrent.CountDownLatch(1)
        val release=java.util.concurrent.CountDownLatch(1)
        val driveEntered=java.util.concurrent.CountDownLatch(1)
        val pool=java.util.concurrent.Executors.newFixedThreadPool(2)
        try {
            val recovery=pool.submit {CloudSyncGate.recoverUnlessDrive {entered.countDown();release.await()}}
            assertTrue(entered.await(3,java.util.concurrent.TimeUnit.SECONDS))
            val drive=pool.submit {CloudSyncGate.driveSync {driveEntered.countDown()}}
            assertFalse(driveEntered.await(100,java.util.concurrent.TimeUnit.MILLISECONDS))
            release.countDown()
            recovery.get(3,java.util.concurrent.TimeUnit.SECONDS);drive.get(3,java.util.concurrent.TimeUnit.SECONDS)
            assertTrue(driveEntered.await(3,java.util.concurrent.TimeUnit.SECONDS))
        } finally {release.countDown();pool.shutdownNow()}
    }
}
