package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test

class WatchQuantityPolicyTest {
    @Test fun onlyRepetitionModesUseMotion() {
        listOf("strength", "repsOnly", "hspuDeficit").forEach {
            assertTrue(it, WatchQuantityPolicy.usesMotion(it))
        }
        listOf("machineWork", "repsAndTime", "loadDistance", "unknown").forEach {
            assertFalse(it, WatchQuantityPolicy.usesMotion(it))
        }
    }
    @Test fun manualQuantityPreservesSeedAndBoundsWithoutCounterReset() {
        assertEquals(2, WatchQuantityPolicy.adjusted(1, 1))
        assertEquals(501, WatchQuantityPolicy.adjusted(500, 1))
        assertEquals(0, WatchQuantityPolicy.adjusted(0, -1))
        assertEquals(10000, WatchQuantityPolicy.adjusted(10000, 1))
        assertEquals(10000, WatchQuantityPolicy.adjusted(Int.MAX_VALUE, Int.MAX_VALUE))
    }
}
