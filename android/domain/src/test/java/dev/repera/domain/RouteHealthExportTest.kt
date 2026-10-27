package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class RouteHealthExportTest {

    private fun pt(lat: Double, lon: Double, t: Long) =
        WorkoutRoutePoint(id = 0, latitude = lat, longitude = lon, recordedAtEpochMs = t)

    @Test fun pointsOutsideSessionWindowPlusSlackAreDropped() {
        val start = 100_000L; val end = 200_000L
        val inside = pt(40.0, -3.7, start - 60_000) to pt(40.0, -3.7, end + 60_000)
        val points = listOf(
            pt(40.0, -3.7, start - 60_001), // fuera por 1 ms
            inside.first,
            pt(40.0, -3.7, 150_000),
            inside.second,                  // borde inclusivo
            pt(40.0, -3.7, end + 60_001))   // fuera por 1 ms
        val out = RouteHealthExport.exportablePoints(points, start, end)
        assertEquals(3, out.size)
        assertEquals(listOf(start - 60_000, 150_000, end + 60_000), out.map { it.recordedAtEpochMs })
    }

    @Test fun invalidCoordinatesAreDropped() {
        val points = listOf(
            pt(91.0, -3.7, 150_000), pt(40.0, -181.0, 150_000),
            pt(40.0, -3.7, 150_000), pt(40.0, -3.7001, 151_000))
        val out = RouteHealthExport.exportablePoints(points, 100_000, 200_000)
        assertEquals(2, out.size)
        assertEquals(listOf(150_000L, 151_000L), out.map { it.recordedAtEpochMs })
    }

    @Test fun fewerThanTwoValidPointsExportsNothing() {
        assertTrue(RouteHealthExport.exportablePoints(
            listOf(pt(40.0, -3.7, 150_000)), 100_000, 200_000).isEmpty())
        assertTrue(RouteHealthExport.exportablePoints(emptyList(), 100_000, 200_000).isEmpty())
        assertTrue(RouteHealthExport.exportablePoints(
            listOf(pt(40.0, -3.7, 10_000), pt(40.0, -3.7, 20_000)), 100_000, 200_000).isEmpty())
    }

    @Test fun recordingOrderIsPreserved() {
        val points = listOf(
            pt(40.0, -3.70, 150_000), pt(40.0, -3.71, 149_000), pt(40.0, -3.72, 151_000))
        assertEquals(listOf(150_000L, 149_000L, 151_000L),
            RouteHealthExport.exportablePoints(points, 100_000, 200_000).map { it.recordedAtEpochMs })
    }
}

class RouteHealthConnectExportTest {

    private fun pt(lat: Double, lon: Double, t: Long) =
        WorkoutRoutePoint(id = 0, latitude = lat, longitude = lon, recordedAtEpochMs = t)

    @Test fun pointsAreClampedToExactSessionRangeForHealthConnect() {
        // HC rechaza puntos fuera de [start,end] aunque la ventana Apple ±60s los admita.
        val start = 100_000L; val end = 200_000L
        val points = listOf(
            pt(40.0, -3.7, start - 30_000),  // dentro del slack Apple, fuera de HC
            pt(40.0, -3.7, start),
            pt(40.0, -3.7, 150_000),
            pt(40.0, -3.7, end),
            pt(40.0, -3.7, end + 30_000))    // dentro del slack Apple, fuera de HC
        val out = RouteHealthExport.healthConnectRoutePoints(points, start, end)
        assertEquals(listOf(start, 150_000L, end), out.map { it.recordedAtEpochMs })
    }

    @Test fun duplicateTimestampsCollapseToFirstPointAndOutputIsMonotonic() {
        val points = listOf(
            pt(40.0, -3.70, 150_000),
            pt(40.0, -3.71, 140_000),  // desordenado
            pt(40.0, -3.72, 150_000))  // timestamp duplicado
        val out = RouteHealthExport.healthConnectRoutePoints(points, 100_000, 200_000)
        assertEquals(listOf(140_000L, 150_000L), out.map { it.recordedAtEpochMs })
        assertEquals(-3.71, out[0].longitude, 1e-9)
        assertEquals(-3.70, out[1].longitude, 1e-9) // primer punto del instante
    }

    @Test fun fewerThanTwoPointsInsideExactRangeExportsNothing() {
        val start = 100_000L; val end = 200_000L
        val points = listOf(
            pt(40.0, -3.7, start - 10_000), // solo entra por slack Apple
            pt(40.0, -3.7, 150_000))
        assertEquals(2, RouteHealthExport.exportablePoints(points, start, end).size)
        assertTrue(RouteHealthExport.healthConnectRoutePoints(points, start, end).isEmpty())
    }
}
