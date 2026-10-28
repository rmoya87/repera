package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test

class AdaptiveRoutePaceTest {
    @Test fun uniformWalkRemainsNeutral() {
        val scale = AdaptiveRoutePace.scale(
            List(100) { AdaptiveRoutePace.Sample(4.8 / 3.6, 8.0) },
            AdaptiveRoutePace.Mode.WALKING)!!
        assertFalse(scale.hasMeaningfulVariation)
        assertEquals(0.5, scale.position(4.8 / 3.6), 0.0001)
    }
    @Test fun accelerationAndOutlier() {
        val samples = (0 until 100).map { i ->
            AdaptiveRoutePace.Sample((if (i < 20) 4.0 else if (i < 80) 4.8 else 5.6) / 3.6, 10.0)
        } + AdaptiveRoutePace.Sample(40.0, 1.0)
        val scale = AdaptiveRoutePace.scale(samples, AdaptiveRoutePace.Mode.WALKING)!!
        assertTrue(scale.hasMeaningfulVariation)
        assertEquals(4.8, scale.medianMps * 3.6, 0.01)
        assertTrue(scale.position(4.0 / 3.6) < 0.2)
        assertTrue(scale.position(5.6 / 3.6) > 0.8)
    }
    @Test fun estimatedGPSCannotSkewScale() {
        val samples = List(40) { AdaptiveRoutePace.Sample(1.3, 8.0) } +
            AdaptiveRoutePace.Sample(15.0, 500.0, true)
        val scale = AdaptiveRoutePace.scale(samples, AdaptiveRoutePace.Mode.WALKING)!!
        assertEquals(1.3, scale.medianMps, 0.001)
        assertFalse(scale.hasMeaningfulVariation)
    }
}
