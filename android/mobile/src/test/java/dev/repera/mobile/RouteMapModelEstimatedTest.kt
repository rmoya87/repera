package dev.repera.mobile

import dev.repera.domain.WorkoutRoutePoint
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Apple 303453ff/9f62c49a: un tramo con un extremo estimado se marca estimado
 *  (se dibuja discontinuo y se rotula; nunca como medicion GPS). */
class RouteMapModelEstimatedTest {
    private val t0 = 1_800_000_000_000L
    private fun p(id: Int, lat: Double, est: Boolean? = null, speed: Double? = 2.0) =
        WorkoutRoutePoint(id, lat, -3.9, t0 + id * 10_000, speedMps = speed, isEstimated = est)

    @Test fun segmentWithEstimatedEndpointIsEstimated() {
        // Apple 9f62c49a: a.isEstimated || b.isEstimated -> el punto estimado
        // marca los DOS tramos que lo tocan.
        val points = listOf(p(0, 40.500), p(1, 40.501, est = true), p(2, 40.502))
        val segments = RouteMapModel.segments(points)
        assertEquals(2, segments.size)
        assertTrue(segments[0].estimated)
        assertTrue(segments[1].estimated)
    }

    @Test fun onlyLeadingMeasuredSegmentsStaySolid() {
        val points = listOf(p(0, 40.500), p(1, 40.501), p(2, 40.502, est = true))
        val segments = RouteMapModel.segments(points)
        assertEquals(2, segments.size)
        assertFalse(segments[0].estimated)
        assertTrue(segments[1].estimated)
    }

    @Test fun allMeasuredRouteHasNoEstimatedSegments() {
        val points = listOf(p(0, 40.500), p(1, 40.501), p(2, 40.502))
        assertTrue(RouteMapModel.segments(points).none { it.estimated })
    }
}
