package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test

class LiveGPSOdometerTest {
    private fun fix(seconds: Long, lat: Double = 40.0, accuracy: Double = 5.0) =
        LiveGPSOdometer.Fix(lat,-3.0,seconds*1000,accuracy,8.0,650.0,3.0)
    @Test fun ownershipAccuracyFutureAndDuplicateTimesAreChecked() {
        val o=LiveGPSOdometer(); assertTrue(o.start("a",0,LiveSport.RUNNING))
        assertFalse(o.start("b",0,LiveSport.RUNNING)); assertNull(o.accept(fix(0,accuracy=36.0),0))
        assertNull(o.accept(fix(11),0)); assertNotNull(o.accept(fix(0),0))
        assertNull(o.accept(fix(0),0)); assertFalse(o.stop("b"))
    }
    @Test fun jitterIgnoredButValidSegmentAddsMeasuredDistance() {
        val o=LiveGPSOdometer();o.start("a",0,LiveSport.RUNNING)
        o.accept(fix(0),0); assertNull(o.accept(fix(1,40.000001),1000))
        val u=o.accept(fix(10,40.0005),10_000)!!
        assertEquals(55.6,u.distanceMeters,1.0);assertEquals(5.0,u.point.horizontalAccuracyMeters!!,0.0)
        assertEquals(8.0,u.point.verticalAccuracyMeters!!,0.0)
    }
    @Test fun gapJumpAndResumeDoNotConnectSegments() {
        val o=LiveGPSOdometer();o.start("a",0,LiveSport.RUNNING);o.accept(fix(0),0)
        assertEquals(0.0,o.accept(fix(60,41.0),60_000)!!.distanceMeters,0.0)
        assertEquals(0.0,o.accept(fix(61,42.0),61_000)!!.distanceMeters,0.0)
        val points=o.points;o.stop("a",false)
        o.start("a",120_000,LiveSport.RUNNING,points,123.0)
        assertEquals(123.0,o.accept(fix(120,43.0),120_000)!!.distanceMeters,0.0)
        assertNull(o.accept(fix(115,44.0),120_000))
    }
    @Test fun fastSportLimitAndVerticalAccuracyAreNotHardcoded() {
        val o=LiveGPSOdometer();o.start("a",0,LiveSport.SKIING);o.accept(fix(0),0)
        val u=o.accept(fix(1,40.0003).copy(verticalAccuracy=60.0),1000)!!
        assertTrue(u.distanceMeters>30);assertNull(u.point.altitudeMeters);assertNull(u.point.verticalAccuracyMeters)
    }
}
