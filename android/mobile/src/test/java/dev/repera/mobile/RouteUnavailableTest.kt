package dev.repera.mobile
import dev.repera.domain.LiveSport
import org.junit.Assert.*
import org.junit.Test
class RouteUnavailableTest {
    private val gps = LiveSport.values().first { it.usesGPS }
    private val noGps = LiveSport.values().firstOrNull { !it.usesGPS }
    @Test fun appliesOnlyForGpsSportWithDistanceAndNoRoute() {
        assertTrue(RouteUnavailable.applies(gps, 5000.0, 0))
        assertFalse(RouteUnavailable.applies(gps, 5000.0, 2))
        assertFalse(RouteUnavailable.applies(gps, 0.0, 0))
        assertFalse(RouteUnavailable.applies(gps, null, 0))
        assertFalse(RouteUnavailable.applies(null, 5000.0, 0))
        if (noGps != null) assertFalse(RouteUnavailable.applies(noGps, 5000.0, 0))
    }
}
