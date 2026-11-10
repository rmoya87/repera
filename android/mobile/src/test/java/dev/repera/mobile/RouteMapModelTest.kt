package dev.repera.mobile

import dev.repera.domain.WorkoutRoutePoint
import dev.repera.domain.AdaptiveRoutePace
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

    @Test fun speedColorMatchesAdaptiveRoutePacePalette() {
        // The currently shipped iOS/Android gradient is the adaptive five-stop
        // scale, not the older four-stop absolute speed ramp.
        for (speed in listOf(0.0, 2.5, 5.0, 7.5, 10.0)) {
            assertEquals(
                AdaptiveRoutePace.color(speed / 10.0),
                RouteMapModel.speedColor(speed, 0.0, 10.0)
            )
            assertEquals(
                AdaptiveRoutePace.color(speed / 10.0, water = true),
                RouteMapModel.speedColor(speed, 0.0, 10.0, water = true)
            )
        }
        assertEquals(AdaptiveRoutePace.color(0.0),
            RouteMapModel.speedColor(-5.0, 0.0, 10.0))
        assertEquals(AdaptiveRoutePace.color(1.0),
            RouteMapModel.speedColor(20.0, 0.0, 10.0))
    }

    @Test fun waterPaletteOnlyChangesTheSlowStop() {
        org.junit.Assert.assertNotEquals(RouteMapModel.speedColor(0.0, 0.0, 10.0), RouteMapModel.speedColor(0.0, 0.0, 10.0, water = true))
        assertEquals(RouteMapModel.speedColor(10.0, 0.0, 10.0), RouteMapModel.speedColor(10.0, 0.0, 10.0, water = true))
    }

    @Test fun gapsPausesAndImpossibleJumpsFollowCutBridgingRules() {
        val a=pt(40.0,-3.7,3.0)
        // Apple e048d814: ventana GPS 30s -> 45s; 31s y ~11 m a ritmo plausible
        // es ahora un tramo REAL (antes iba puenteado como estimado).
        val real31=RouteMapModel.segments(listOf(a,pt(40.0001,-3.7,3.0,seconds=31)))
        assertEquals(1,real31.size)
        assertTrue(!real31[0].estimated)
        // Apple e048d814: visualBridge cubre huecos de >0s..2h (antes 30 min),
        // siempre como tramo estimado (discontinuo, rotulado).
        val bridged=RouteMapModel.segments(listOf(a,pt(40.0001,-3.7,3.0,seconds=1801)))
        assertEquals(1,bridged.size)
        assertTrue(bridged[0].estimated)
        // Huecos que el puente no cubre: mismo instante, salto imposible, hueco
        // >2h y hueco largo sin GPX a mas de 6 m/s.
        assertTrue(RouteMapModel.segments(listOf(a,pt(40.0001,-3.7,3.0,seconds=0))).isEmpty())
        assertTrue(RouteMapModel.segments(listOf(a,pt(41.0,-3.7,3.0,seconds=10))).isEmpty())
        assertTrue(RouteMapModel.segments(listOf(a,pt(40.0001,-3.7,3.0,seconds=7201))).isEmpty())
        assertTrue(RouteMapModel.segments(listOf(a,pt(40.02,-3.7,null,seconds=60))).isEmpty())
        val valid=RouteMapModel.segments(listOf(a,pt(40.0001,-3.7,seconds=10)))
        assertEquals(1,valid.size)
    }

    @Test fun nearStationaryPointsStayAsLegsInsteadOfOpeningGaps() {
        // Apple e048d814: puntos casi inmoviles (<0.5 m) pertenecen al mismo
        // recorrido real; descartarlos abria huecos en el dibujo.
        val a=pt(40.0,-3.7,3.0)
        val segs=RouteMapModel.segments(listOf(a,pt(40.000001,-3.7,3.0,seconds=5)))
        assertEquals(1,segs.size)
        assertTrue(!segs[0].estimated)
        // Sin velocidad medida el tramo se pinta con el minimo 0.2 (no hueco).
        val slow=RouteMapModel.segments(listOf(pt(40.0,-3.7),pt(40.000001,-3.7,seconds=10)))
        assertEquals(1,slow.size)
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
        // One real leg has no meaningful relative variation: adaptive pacing
        // paints it at the median, not a fabricated minimum/maximum.
        assertEquals(AdaptiveRoutePace.color(0.5), segs[0].argb)
        assertTrue(!segs[0].estimated)
    }
}
