package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test

class SessionMovementTest {
    @Test fun associatedWinsOverWindowAndIsNotTimed() {
        val m = SessionMovementMetrics.resolve("running", 4000.0, 9000.0, 3200.0, 8000.0)!!
        assertEquals(4000, m.steps);assertEquals(3200.0, m.distanceMeters!!, 0.0)
        assertEquals("Distancia a pie", m.distanceLabel);assertFalse(m.usesTimeWindow)
    }
    @Test fun windowIsUsedOnlyWithoutAssociatedAndIsFlagged() {
        val m = SessionMovementMetrics.resolve("cycling", null, null, null, 12000.0)!!
        assertNull(m.steps);assertEquals("Distancia bici", m.distanceLabel);assertTrue(m.usesTimeWindow)
    }
    @Test fun waterTypesNeverReuseWalkingDistanceButKeepSteps() {
        val m = SessionMovementMetrics.resolve("surfingSports", 500.0, null, 900.0, 900.0)!!
        assertNull(m.distanceMeters);assertNull(m.distanceLabel);assertEquals(500, m.steps)
        assertNull(SessionMovementMetrics.resolve("rowing", null, null, 900.0, 900.0))
    }
    @Test fun mixedUsesGenericLabelAndInvalidValuesAreIgnored() {
        assertEquals("Distancia recorrida", SessionMovementMetrics.resolve("traditionalStrengthTraining", null, null, 1500.0, null)!!.distanceLabel)
        assertNull(SessionMovementMetrics.resolve("running", 0.0, Double.NaN, -5.0, Double.POSITIVE_INFINITY))
        assertEquals("Distancia nieve", SessionMovementMetrics.resolve("snowboarding", null, null, 100.0, null)!!.distanceLabel)
        assertEquals("Distancia nado", SessionMovementMetrics.resolve("swimming", null, null, 100.0, null)!!.distanceLabel)
    }
    @Test fun mixedFlagWhenOnlyOneFigureIsWindowBased() {
        val m = SessionMovementMetrics.resolve("running", 4000.0, null, null, 5000.0)!!
        assertTrue(m.usesTimeWindow)
    }
    @Test fun windowNeverSumsOrPicksAmongSeveralOrigins() {
        assertEquals(5000.0, SessionMovementMetrics.windowTotal(mapOf("a" to 5000.0))!!, 0.0)
        assertNull(SessionMovementMetrics.windowTotal(mapOf("a" to 5000.0, "b" to 5000.0)))
        assertNull(SessionMovementMetrics.windowTotal(mapOf("a" to 5000.0, "b" to 300.0)))
        assertNull(SessionMovementMetrics.windowTotal(emptyMap()))
        assertNull(SessionMovementMetrics.windowTotal(mapOf("a" to 0.0)))
    }
}
