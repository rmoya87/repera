package dev.repera.mobile
import dev.repera.domain.WorkoutRoutePoint
import org.junit.Assert.*
import org.junit.Test
class LiveMapCameraTest {
    private val p=WorkoutRoutePoint(0,40.0,-3.0,0)
    @Test fun flatMapUsesExactMeasuredPositionNorthUp() {
        val t=LiveMapCamera.target(p,listOf(p),false)
        assertEquals(p.latitude,t.latitude,0.0);assertEquals(p.longitude,t.longitude,0.0)
        assertEquals(0.0,t.pitch,0.0);assertEquals(0.0,t.bearing,0.0)
    }
    @Test fun navigationLooks35MetersAheadUsingMeasuredHeadingAndNoIdleOffset() {
        val east=p.copy(id=1,longitude=-2.999,recordedAtEpochMs=1000)
        val t=LiveMapCamera.target(east,listOf(p,east),true)
        assertEquals(90.0,t.bearing,0.01);assertTrue(t.longitude>east.longitude)
        assertEquals(60.0,t.pitch,0.0)
        val idle=LiveMapCamera.target(p,emptyList(),true)
        assertEquals(p.latitude,idle.latitude,0.0);assertEquals(p.longitude,idle.longitude,0.0)
    }
}
