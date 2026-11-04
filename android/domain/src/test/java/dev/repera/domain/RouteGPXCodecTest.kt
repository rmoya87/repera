package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test

class RouteGPXCodecTest {
    private fun pt(id:Int,lat:Double,long:Double,ms:Long,estimated:Boolean=false) =
        WorkoutRoutePoint(id,lat,long,ms,isEstimated=estimated)

    @Test fun exportsOriginalGpsAndSegmentsMissingIntervals() {
        val xml=RouteGPXCodec.encode(listOf(
            pt(1,40.0,-3.0,10_000L),
            pt(2,40.01,-3.01,20_000L),
            pt(3,40.02,-3.02,80_000L)
        ))!!
        assertTrue(xml.contains("http://www.topografix.com/GPX/1/1"))
        assertTrue(xml.contains("40.0100000"))
        assertEquals(2, Regex("<trkseg>").findAll(xml).count())
        assertEquals(3, Regex("<trkpt ").findAll(xml).count())
    }

    @Test fun excludesEstimatedAndInvalidGps() {
        val xml=RouteGPXCodec.encode(listOf(
            pt(1,40.0,-3.0,10_000L),
            pt(2,40.01,-3.01,20_000L,true),
            pt(3,40.02,-3.02,30_000L),
            pt(4,99.0,-3.0,40_000L)
        ))!!
        assertEquals(2,Regex("<trkpt ").findAll(xml).count())
        assertFalse(xml.contains("40.0100000"))
        assertFalse(xml.contains("99.0000000"))
    }

    @Test fun requiresAtLeastTwoRealPoints() {
        assertNull(RouteGPXCodec.encode(listOf(pt(1,40.0,-3.0,10_000L))))
        assertNull(RouteGPXCodec.encode(listOf(pt(1,40.0,-3.0,10_000L),pt(2,40.1,-3.1,20_000L,true))))
    }
}
