package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class SwipeRevealMathTest {

    @Test fun clampedOffsetFollowsFingerWithoutJump() {
        val reveal = 72f
        assertEquals(-10f, SwipeRevealMath.clampedOffset(0f, -10f, reveal))
        assertEquals(-40f, SwipeRevealMath.clampedOffset(0f, -40f, reveal))
        assertEquals(-72f, SwipeRevealMath.clampedOffset(0f, -100f, reveal))
        // No pasar de 0 a la derecha.
        assertEquals(0f, SwipeRevealMath.clampedOffset(-20f, 30f, reveal))
    }

    @Test fun swipeDoesNotBeginOnChipsBand() {
        val height = 120f
        val band = 48f
        assertTrue(SwipeRevealMath.shouldBeginSwipe(20f, height, band))
        assertTrue(SwipeRevealMath.shouldBeginSwipe(70f, height, band))
        assertFalse(SwipeRevealMath.shouldBeginSwipe(80f, height, band))
        assertFalse(SwipeRevealMath.shouldBeginSwipe(119f, height, band))
    }

    @Test fun openThresholdStable() {
        val reveal = 72f
        assertFalse(SwipeRevealMath.shouldOpen(-20f, -10f, reveal))
        assertTrue(SwipeRevealMath.shouldOpen(-40f, -10f, reveal))
        assertTrue(SwipeRevealMath.shouldOpen(-10f, -40f, reveal))
    }
}
