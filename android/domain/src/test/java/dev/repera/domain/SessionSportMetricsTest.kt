package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test

class SessionSportMetricsTest {
    private fun p(speed: Double?) = WorkoutRoutePoint(0, 0.0, 0.0, 0L, speedMps = speed)

    @Test fun averagesUseWholeActivityTotals() {
        assertEquals(10.0, SessionSportMetrics.averageSpeedKmh(3600.0, 10_000.0)!!, 1e-9)
        assertEquals("6:00", SessionSportMetrics.averagePace(3600.0, 10_000.0))
        assertEquals("5:05", SessionSportMetrics.averagePace(1525.0, 5_000.0))
        assertNull(SessionSportMetrics.averageSpeedKmh(null, 10_000.0))
        assertNull(SessionSportMetrics.averagePace(3600.0, 0.0))
        assertEquals("10,0", SessionSportMetrics.decimal(10.0))
    }

    @Test fun maxSpeedPrefersRecordedThenFiltersSamples() {
        assertEquals(30.0, SessionSportMetrics.maxSpeedKmh(30.0, listOf(p(10.0)))!!, 1e-9)
        assertEquals(36.0, SessionSportMetrics.maxSpeedKmh(null, listOf(p(5.0), p(10.0), p(60.0), p(Double.NaN), p(null), p(0.0)))!!, 1e-9)
        assertNull(SessionSportMetrics.maxSpeedKmh(0.0, listOf(p(null))))
    }

    @Test fun gpsTilesNeedOutdoorMovement() {
        assertTrue(SessionSportMetrics.showsGpsTiles(LiveSport.RUNNING, 1000.0, emptyList(), false))
        assertFalse(SessionSportMetrics.showsGpsTiles(LiveSport.BOXING, 1000.0, listOf(p(1.0), p(1.0)), true))
        assertTrue(SessionSportMetrics.showsGpsTiles(null, null, listOf(p(1.0), p(1.0)), false))
        assertFalse(SessionSportMetrics.showsGpsTiles(LiveSport.RUNNING, null, emptyList(), false))
        assertTrue(SessionSportMetrics.showsDistanceInsteadOfPace(LiveSport.CYCLING))
        assertFalse(SessionSportMetrics.showsDistanceInsteadOfPace(LiveSport.RUNNING))
    }

    @org.junit.Test fun rangesRoundAndIgnoreMissingValues() {
        assertNull(SessionSportMetrics.heartRange(emptyList()))
        assertNull(SessionSportMetrics.heartRange(listOf(0, 0)))
        assertEquals(SessionSportMetrics.Range(100, 120, 140), SessionSportMetrics.heartRange(listOf(100, 120, 140, 0)))
        val pts = listOf(10.4, null, 20.6).map { WorkoutRoutePoint(1, 0.0, 0.0, 0L, altitudeMeters = it) }
        assertEquals(SessionSportMetrics.Range(10, 16, 21), SessionSportMetrics.altitudeRange(pts))
        assertNull(SessionSportMetrics.altitudeRange(listOf(WorkoutRoutePoint(1, 0.0, 0.0, 0L))))
    }

    @org.junit.Test fun splitRowsSkipInvalidAndFormatColumns() {
        val r = SessionSportMetrics.splitRows(listOf(300.0, Double.NaN, 0.0, 330.0), false, mapOf(1 to 150.4))
        assertEquals(listOf(1, 4), r.map { it.kilometer })
        assertEquals(SessionSportMetrics.SplitRow(1, "5:00", "5:00/km", "150 LPM"), r[0])
        assertEquals("—", r[1].bpm)
        assertEquals("12.0", SessionSportMetrics.splitRows(listOf(300.0), true, emptyMap())[0].rateOrSpeed)
    }
}
