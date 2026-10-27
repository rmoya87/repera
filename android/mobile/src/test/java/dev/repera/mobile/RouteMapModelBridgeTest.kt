package dev.repera.mobile

import dev.repera.domain.WorkoutRoutePoint
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** Apple d5c263d3 visualBridge/referenceBridge: huecos temporales se puentean
 *  SOLO para pantalla con el GPX enlazado (o recta corta plausible), siempre
 *  estimados, nunca velocidades imposibles. */
class RouteMapModelBridgeTest {

    private fun pt(i: Int, lat: Double, lon: Double, t: Long, speed: Double? = 2.0) =
        WorkoutRoutePoint(i, lat, lon, t, speedMps = speed)

    @Test fun longGapWithGpxReferenceIsBridgedAsEstimated() {
        // GPX enlazado que pasa cerca de ambos extremos del hueco.
        val gpx = (0..10).map { pt(100 + it, 40.0000 + it * 0.0001, -3.7000, 0L) }
        val a = pt(0, 40.0000, -3.7000, 0L)
        val b = pt(1, 40.0010, -3.7000, 300_000L) // 5 min de hueco
        val segments = RouteMapModel.segments(listOf(a, b), reference = gpx)
        assertTrue(segments.isNotEmpty())
        assertTrue(segments.all { it.estimated })
    }

    @Test fun shortPlausibleGapWithoutGpxIsStraightBridge() {
        val a = pt(0, 40.0, -3.7, 0L)
        val b = pt(1, 40.0005, -3.7, 120_000L) // ~55m en 2min, <=350m y <=6 m/s
        val segments = RouteMapModel.segments(listOf(a, b))
        assertEquals(1, segments.size)
        assertTrue(segments[0].estimated)
    }

    @Test fun implausibleGapWithoutGpxStaysOpen() {
        val a = pt(0, 40.0, -3.7, 0L)
        val b = pt(1, 40.05, -3.7, 120_000L) // ~5.5km en 2min: teletransporte
        assertTrue(RouteMapModel.segments(listOf(a, b)).isEmpty())
    }

    @Test fun gpxTooFarFromGapEndsDoesNotBridge() {
        val gpx = (0..10).map { pt(100 + it, 41.0 + it * 0.0001, -3.7, 0L) } // a ~111km
        val a = pt(0, 40.0, -3.7, 0L)
        val b = pt(1, 40.05, -3.7, 120_000L)
        assertTrue(RouteMapModel.segments(listOf(a, b), reference = gpx).isEmpty())
    }

    @Test fun normalConsecutivePointsAreUnaffected() {
        val a = pt(0, 40.0, -3.7, 0L)
        val b = pt(1, 40.0001, -3.7, 5_000L) // ~11m en 5s: tramo real
        val segments = RouteMapModel.segments(listOf(a, b))
        assertEquals(1, segments.size)
        assertTrue(!segments[0].estimated)
    }
}
