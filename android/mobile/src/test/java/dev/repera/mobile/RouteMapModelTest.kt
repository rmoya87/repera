package dev.repera.mobile

import dev.repera.domain.WorkoutRoutePoint
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class RouteMapModelTest {

    private fun pt(lat: Double, lon: Double, speed: Double? = null, seconds: Long = 0) =
        WorkoutRoutePoint(id = 0, latitude = lat, longitude = lon,
            recordedAtEpochMs = seconds * 1000, speedMps = speed)

    @Test fun segmentsAreOneLessThanPointsAndEmptyBelowTwo() {
        assertTrue(RouteMapModel.segments(emptyList()).isEmpty())
        assertTrue(RouteMapModel.segments(listOf(pt(40.0, -3.7))).isEmpty())
        assertEquals(2, RouteMapModel.segments(
            listOf(pt(40.0, -3.7), pt(40.0001, -3.7, seconds=10), pt(40.0002, -3.7, seconds=20))).size)
    }

    @Test fun speedColorMatchesIosGradient() {
        // Apple live main HistoryView.speedColor: four stops, bytes truncated like Color(red:green:blue:) -> (v*255).toLong().
        fun argb(r: Double, g: Double, b: Double) = 0xFF000000L or ((r*255).toLong() shl 16) or ((g*255).toLong() shl 8) or (b*255).toLong()
        assertEquals(argb(0.15, 0.88, 0.30), RouteMapModel.speedColor(0.0, 0.0, 10.0))
        assertEquals(argb(0.10, 0.84, 0.42), RouteMapModel.speedColor(0.0, 0.0, 10.0, water = true))
        assertEquals(argb(0.96, 0.18, 0.13), RouteMapModel.speedColor(10.0, 0.0, 10.0))
        assertEquals(argb(0.96, 0.18, 0.13), RouteMapModel.speedColor(10.0, 0.0, 10.0, water = true))
        // t = 1/3 and 2/3 are the inner stops (floating point: allow one byte).
        val third = RouteMapModel.speedColor(10.0 / 3, 0.0, 10.0)
        assertTrue(kotlin.math.abs(((third shr 8) and 0xFF) - (0.87*255).toLong()) <= 1)
        // t = 0.5: halfway between stops 2 and 3 (1.0,0.87,0.10)-(1.0,0.48,0.06) -> (1.0,0.675,0.08).
        assertEquals(argb(1.0, 0.675, 0.08), RouteMapModel.speedColor(5.0, 0.0, 10.0))
        // Span degenerado: se usa 0.1 como en iOS, sin NaN.
        RouteMapModel.speedColor(3.0, 3.0, 3.0)
    }

    @Test fun waterPaletteOnlyChangesTheSlowStop() {
        org.junit.Assert.assertNotEquals(RouteMapModel.speedColor(0.0, 0.0, 10.0), RouteMapModel.speedColor(0.0, 0.0, 10.0, water = true))
        assertEquals(RouteMapModel.speedColor(10.0, 0.0, 10.0), RouteMapModel.speedColor(10.0, 0.0, 10.0, water = true))
    }

    @Test fun gapsPausesAndImpossibleJumpsNeverCreateConnectingSegments() {
        val a=pt(40.0,-3.7,3.0)
        assertTrue(RouteMapModel.segments(listOf(a,pt(40.0001,-3.7,3.0,seconds=31))).isEmpty())
        assertTrue(RouteMapModel.segments(listOf(a,pt(40.0001,-3.7,3.0,seconds=0))).isEmpty())
        assertTrue(RouteMapModel.segments(listOf(a,pt(41.0,-3.7,3.0,seconds=10))).isEmpty())
        val valid=RouteMapModel.segments(listOf(a,pt(40.0001,-3.7,seconds=10)))
        assertEquals(1,valid.size)
    }
    @Test fun cameraCentersBoundsWith15xMarginAndMinSpan() {
        val cam = RouteMapModel.camera(listOf(
            pt(40.0, -3.8), pt(40.2, -3.6)))!!
        assertEquals(40.1, cam.centerLat, 1e-9)
        assertEquals(-3.7, cam.centerLon, 1e-9)
        assertEquals(0.3, cam.spanLat, 1e-9)   // 0.2 * 1.5
        assertEquals(0.3, cam.spanLon, 1e-9)
        // Recorrido puntual: span mínimo 0.008 como iOS.
        val single = RouteMapModel.camera(listOf(pt(41.0, -4.0)))!!
        assertEquals(0.008, single.spanLat, 1e-12)
        assertNull(RouteMapModel.camera(emptyList()))
    }

    @Test fun segmentUsesValidMeasuredSpeedAfterTimingAndGeometryValidation() {
        val segs = RouteMapModel.segments(listOf(
            pt(40.0, -3.7, speed = null), pt(40.0001, -3.7, speed = 4.0, seconds=10)))
        assertEquals(1, segs.size)
        // Apple 5890215d: measured second speed preferred after validity gate.
        assertEquals(RouteMapModel.speedColor(4.0, 4.0, 4.1), segs[0].argb)
    }
}
