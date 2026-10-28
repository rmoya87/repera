package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Espejo de InterruptedRouteEstimatorTests (Apple ca3c0383). */
class InterruptedRouteEstimatorTest {

    private val originMs = 1_800_000_000_000L

    @Test fun plausibleGapIsEstimatedWithoutChangingMeasuredEndpoints() {
        val first = WorkoutRoutePoint(id = 0, latitude = 40.500, longitude = -3.900, recordedAtEpochMs = originMs)
        val last = WorkoutRoutePoint(id = 1, latitude = 40.501, longitude = -3.900, recordedAtEpochMs = originMs + 120_000)
        val gap = InterruptedRouteEstimator.bridge(first, last, maximumSpeedMps = 2.8)
        assertNotNull(gap)
        assertTrue(gap!!.points.all { it.isEstimated == true })
        assertTrue(gap.distanceMeters > 100)
        assertEquals(120.0, gap.missingSeconds, 0.0001)
    }

    @Test fun staleOrImplausibleGapNeverCreatesSyntheticRoute() {
        val first = WorkoutRoutePoint(id = 0, latitude = 40.5, longitude = -3.9, recordedAtEpochMs = originMs)
        val jump = WorkoutRoutePoint(id = 1, latitude = 41.5, longitude = -3.9, recordedAtEpochMs = originMs + 90_000)
        val stale = WorkoutRoutePoint(id = 2, latitude = 40.501, longitude = -3.9, recordedAtEpochMs = originMs + 3_600_000)
        assertNull(InterruptedRouteEstimator.bridge(first, jump, maximumSpeedMps = 2.8))
        assertNull(InterruptedRouteEstimator.bridge(first, stale, maximumSpeedMps = 2.8))
    }

    @Test fun oldGpsSamplesKeepEstimatedFlagAbsent() {
        // Equivalente al test de decodificación sin flag: el campo nuevo es
        // opcional y los puntos antiguos lo conservan en null.
        val sample = WorkoutRoutePoint(id = 0, latitude = 40.5, longitude = -3.9, recordedAtEpochMs = originMs)
        assertNull(sample.isEstimated)
    }
}
