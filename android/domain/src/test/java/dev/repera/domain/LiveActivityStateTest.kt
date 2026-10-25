package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test

class LiveActivityStateTest {
    private fun point(seconds: Long, alt: Double? = null, accuracy: Double? = null) =
        WorkoutRoutePoint(seconds.toInt(),40.0,-3.0,seconds*1000,3.0,alt,8.0,accuracy)
    @Test fun pausesAndFinishedReviewNeverCountWallClockPause() {
        val s = LiveActivityState(); s.start(0,"a"); s.pause(60_000)
        assertEquals(60.0,s.durationSeconds(300_000),0.0)
        s.resume(300_000); s.finish(360_000)
        assertEquals(120.0,s.durationSeconds(900_000),0.0)
        assertEquals(LiveActivityState.Phase.REVIEW,s.phase)
    }
    @Test fun restoreAlwaysPausesAtCheckpointAndRejectsOldCallbacks() {
        val s = LiveActivityState(); s.start(0,"a"); s.receive("a",point(100),500.0)
        val r = LiveActivityState(); assertTrue(r.restore(s.snapshot(120_000)!!))
        assertEquals(LiveActivityState.Phase.PAUSED,r.phase)
        assertEquals(120.0,r.durationSeconds(600_000),0.0)
        r.resume(600_000); assertEquals(180.0,r.durationSeconds(660_000),0.0)
        assertFalse(r.receive("old",point(660),700.0)); assertEquals(500.0,r.distanceMeters,0.0)
    }
    @Test fun kilometerCrossingInterpolatesActiveTimeAndSupportsMultipleBoundaries() {
        val s = LiveActivityState(); s.start(0,"a")
        s.receive("a",point(0),0.0); s.receive("a",point(600),2000.0)
        assertEquals(listOf(300.0,300.0),s.splitsSeconds)
        assertEquals(3,s.activeKilometer); assertEquals(0.0,s.activeKilometerMeters,0.0)
        assertEquals(12.0,s.averageSpeedKmh(600_000)!!,0.001)
    }
    @Test fun gpsCannotRecordWhilePausedOrIndoorAndNoDistanceDoubleCounting() {
        val s = LiveActivityState(); s.choose(LiveSport.PADEL); s.start(0,"a")
        assertFalse(s.receive("a",point(10),50.0)); assertEquals(0.0,s.distanceMeters,0.0)
        s.discard();s.choose(LiveSport.RUNNING);s.start(0,"b")
        s.receive("b",point(10),50.0);s.receive("b",point(20),50.0)
        assertEquals(50.0,s.distanceMeters,0.0)
        assertFalse(s.receive("b",point(30),40.0)); assertFalse(s.receive("b",point(30),Double.NaN))
        s.pause(30_000); assertFalse(s.receive("b",point(40),100.0))
    }
    @Test fun elevationUsesAccuracyAndThreeMeterNoiseThreshold() {
        val s = LiveActivityState();s.choose(LiveSport.HIKING);s.start(0,"a")
        s.receive("a",point(0,600.0,5.0),0.0)
        s.receive("a",point(10,602.0,5.0),10.0)
        s.receive("a",point(20,604.0,5.0),20.0)
        s.receive("a",point(30,610.0,40.0),30.0)
        s.receive("a",point(40,601.0,5.0),40.0)
        assertEquals(4.0,s.elevationGainMeters,0.0);assertEquals(3.0,s.elevationLossMeters,0.0)
    }
    @Test fun discardClearsEverySessionFieldAndCannotRestoreIdleSnapshot() {
        val s = LiveActivityState();s.selectRoute("r");s.start(0,"a");s.receive("a",point(100),500.0)
        s.discard();assertNull(s.snapshot(500_000));assertNull(s.startedMillis)
        assertNull(s.selectedRouteID);assertNull(s.currentSpeedMps);assertTrue(s.points.isEmpty())
        assertTrue(s.splitsSeconds.isEmpty());assertEquals(0.0,s.distanceMeters,0.0)
        assertEquals(0.0,s.durationSeconds(500_000),0.0)
    }
}
