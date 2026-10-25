package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test

class LiveGPXTest {
    private fun parse(xml: String) = LiveGPXParser.parse(xml.toByteArray()) { 123L }
    @Test fun namespacesRouteAndTrackPointsWithOptionalTime() {
        val points = parse("""<g:gpx xmlns:g="urn:gpx"><g:trk><g:trkpt lat="40" lon="-3"><g:time>2026-10-25T10:00:00Z</g:time></g:trkpt></g:trk><g:rte><g:rtept lat="41" lon="-3"/></g:rte></g:gpx>""")
        assertEquals(2, points.size); assertEquals(1792922400000L, points[0].recordedAtEpochMs)
        assertEquals(123L, points[1].recordedAtEpochMs); assertEquals(1, points[1].id)
    }
    @Test fun skipsInvalidCoordinatesAndCapsAtTwentyThousand() {
        val xml = "<gpx><trkpt lat=\"91\" lon=\"0\"/>" +
            (0..20_002).joinToString("") { "<trkpt lat=\"40\" lon=\"-3\"/>" } + "</gpx>"
        val points = parse(xml); assertEquals(20_000, points.size); assertEquals(19_999, points.last().id)
    }
    @Test fun rejectsEmptyCorruptAndExternalEntityDocuments() {
        for (xml in listOf("<gpx/>", "<gpx>", """<!DOCTYPE gpx [<!ENTITY xxe SYSTEM "file:///etc/passwd">]><gpx>&xxe;</gpx>""")) {
            try { parse(xml); fail("GPX inválido aceptado") } catch (_: IllegalArgumentException) {}
        }
    }
    private fun p(lat: Double, lon: Double) = WorkoutRoutePoint(0, lat, lon, 0)
    @Test fun straightRouteHasNoTurnAndCornerTurnsRight() {
        val a = p(40.0,-3.0); val b = p(40.001,-3.0); val c = p(40.001,-2.999)
        assertTrue(LiveGPXTurnDetection.detect(listOf(a,b,p(40.002,-3.0))).isEmpty())
        val turn = LiveGPXTurnDetection.detect(listOf(a,b,c)).single()
        assertEquals("Gira a la derecha", turn.instruction)
        assertEquals(90.0, turn.angleDegrees, 0.1)
        assertTrue(turn.metersAlongRoute > 100)
    }
    @Test fun instructionForLeftAndReversalAndInsufficientGeometry() {
        assertEquals("Gira a la izquierda", LiveGPXTurnDetection.Turn(1,100.0,-90.0).instruction)
        assertEquals("Cambio de sentido", LiveGPXTurnDetection.Turn(1,100.0,170.0).instruction)
        assertTrue(LiveGPXTurnDetection.detect(listOf(p(40.0,-3.0))).isEmpty())
        assertTrue(LiveGPXTurnDetection.cumulative(emptyList()).isEmpty())
    }
}
