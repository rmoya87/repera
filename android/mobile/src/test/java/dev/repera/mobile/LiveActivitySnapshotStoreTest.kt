package dev.repera.mobile

import dev.repera.domain.LiveActivityState
import dev.repera.domain.WorkoutRoutePoint
import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File

class LiveActivitySnapshotStoreTest {
    @get:Rule val folder=TemporaryFolder()
    private fun snapshot(): LiveActivityState.Snapshot {
        val s=LiveActivityState();s.selectRoute("route");s.start(0,"session")
        s.receive("session",WorkoutRoutePoint(0,40.0,-3.0,0,3.0,600.0,5.0,8.0),0.0)
        s.receive("session",WorkoutRoutePoint(1,40.01,-3.0,300_000,3.0,605.0,5.0,8.0),1000.0)
        return s.snapshot(310_000)!!
    }
    @Test fun roundTripRestoresPausedWithExactRouteSplitsIdentityAndMeasuredAccuracy() {
        val file=File(folder.root,"activity.json");val store=LiveActivitySnapshotStore(file)
        val snap=snapshot();store.write(snap);assertEquals(snap,store.read())
        val s=LiveActivityState();s.restore(store.read()!!)
        assertEquals(LiveActivityState.Phase.PAUSED,s.phase)
        assertEquals(310.0,s.durationSeconds(900_000),0.0)
        assertEquals("session",s.gpsSessionID);assertEquals(listOf(300.0),s.splitsSeconds)
        assertEquals(8.0,s.points.last().verticalAccuracyMeters!!,0.0)
        store.clear();assertNull(store.read())
    }
    @Test fun failedWritePreservesPriorCheckpoint() {
        val file=File(folder.root,"activity.json");val store=LiveActivitySnapshotStore(file)
        val snap=snapshot();store.write(snap)
        File(file.path+".tmp").mkdir();File(file.path+".tmp/block").writeText("block")
        try { store.write(snap.copy(distanceMeters=2000.0));fail() } catch (_: java.io.IOException) {}
        assertEquals(snap,store.read())
    }
    @Test fun corruptFileRemainsAvailableRatherThanBeingSilentlyDeleted() {
        val file=File(folder.root,"activity.json");file.writeText("broken")
        try { LiveActivitySnapshotStore(file).read();fail() } catch (_: org.json.JSONException) {}
        assertEquals("broken",file.readText())
    }
}
