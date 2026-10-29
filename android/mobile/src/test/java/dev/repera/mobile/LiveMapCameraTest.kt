package dev.repera.mobile
import dev.repera.domain.WorkoutRoutePoint
import org.junit.Assert.*
import org.junit.Test
class LiveMapCameraTest {
    private val p=WorkoutRoutePoint(0,40.0,-3.0,0)
    @Test fun stationaryFixHasNoInventedHeading() {
        val stationary=p.copy(id=1,longitude=-2.999999,recordedAtEpochMs=5000)
        assertNull(LiveMapCamera.measuredHeading(listOf(p,stationary)))
        assertNull(LiveMapCamera.measuredHeading(listOf(p)))
    }
    @Test fun movingEastProvidesReliableHeading() {
        val east=p.copy(id=1,longitude=-2.9999,recordedAtEpochMs=5000)
        assertEquals(90.0,LiveMapCamera.measuredHeading(listOf(p,east))!!,0.2)
    }
    @Test fun flatMapFollowsMeasuredWalkingDirectionWithoutOffset() {
        val east=p.copy(id=1,longitude=-2.9999,recordedAtEpochMs=5000)
        val t=LiveMapCamera.target(east,listOf(p,east),false)
        assertEquals(east.latitude,t.latitude,0.0)
        assertEquals(east.longitude,t.longitude,0.0)
        assertEquals(0.0,t.pitch,0.0)
        assertEquals(90.0,t.bearing,0.2)
    }
    @Test fun noMeasuredHeadingKeepsLastReliableCourseAndNeverInventsOne() {
        val t=LiveMapCamera.target(p,listOf(p),false,135.0)
        assertEquals(135.0,t.bearing,0.0)
        assertEquals(135.0,LiveMapCamera.target(p,listOf(p),true,135.0).bearing,0.0)
        assertEquals(0.0,LiveMapCamera.target(p,listOf(p),false).bearing,0.0)
        assertEquals(0.0,LiveMapCamera.target(p,listOf(p),true,Double.NaN).bearing,0.0)
    }
    @Test fun measuredCourseTakesPrecedenceOverPreviouslyRememberedHeading() {
        val east=p.copy(id=1,longitude=-2.9999,recordedAtEpochMs=5000)
        val t=LiveMapCamera.target(east,listOf(p,east),true,180.0)
        assertEquals(90.0,t.bearing,0.2)
    }
    @Test fun navigationLooks35MetersAheadUsingMeasuredHeadingAndNoIdleOffset() {
        val east=p.copy(id=1,longitude=-2.999,recordedAtEpochMs=1000)
        val t=LiveMapCamera.target(east,listOf(p,east),true)
        assertEquals(90.0,t.bearing,0.01);assertTrue(t.longitude>east.longitude)
        assertEquals(60.0,t.pitch,0.0)
        val idle=LiveMapCamera.target(p,emptyList(),true)
        assertEquals(p.latitude,idle.latitude,0.0);assertEquals(p.longitude,idle.longitude,0.0)
    }
    @Test fun returnsToUserAfterFiveSecondsSinceLastGestureOnly() {
        assertFalse(LiveMapCamera.shouldResumeFollowing(false,1000L,5999L))
        assertTrue(LiveMapCamera.shouldResumeFollowing(false,1000L,6000L))
        // Un nuevo arrastre reinicia el plazo: no recentrar a los 5 s del primero.
        assertFalse(LiveMapCamera.shouldResumeFollowing(false,5000L,6000L))
        assertTrue(LiveMapCamera.shouldResumeFollowing(false,5000L,10000L))
        assertFalse(LiveMapCamera.shouldResumeFollowing(true,1000L,10000L))
        assertFalse(LiveMapCamera.shouldResumeFollowing(false,0L,10000L))
    }
}
