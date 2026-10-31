package dev.repera.wear

import org.junit.Assert.assertEquals
import org.junit.Test

class WearHubSwipeTest {

    @Test
    fun swipeDownAdvancesIndex() {
        val (steps, rem) = wearHubSwipeSteps(accumulatedPx = 50f, thresholdPx = 48f)
        assertEquals(1, steps)
        assertEquals(2f, rem, 0.01f)
    }

    @Test
    fun swipeUpGoesPrevious() {
        val (steps, rem) = wearHubSwipeSteps(accumulatedPx = -50f, thresholdPx = 48f)
        assertEquals(-1, steps)
        assertEquals(-2f, rem, 0.01f)
    }

    @Test
    fun belowThresholdDoesNothing() {
        val (steps, rem) = wearHubSwipeSteps(accumulatedPx = 20f, thresholdPx = 48f)
        assertEquals(0, steps)
        assertEquals(20f, rem, 0.01f)
    }

    @Test
    fun applyStepsClamps() {
        assertEquals(2, wearHubIndexAfterSteps(index = 0, steps = 2, itemCount = 3))
        assertEquals(0, wearHubIndexAfterSteps(index = 0, steps = -5, itemCount = 3))
        assertEquals(2, wearHubIndexAfterSteps(index = 2, steps = 5, itemCount = 3))
        assertEquals(0, wearHubIndexAfterSteps(index = 0, steps = 1, itemCount = 0))
    }
}
