package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class WodMovementProgressTest {
    private fun entry(id: String, interval: Int = 0, quantity: Int = 10) =
        WodMovementEntry(id, "block", "squat", interval, quantity, 30.0, 1000L)

    @Test fun emomRecordsOnlyConfirmedMovementsAndIntervals() {
        val empty = WodMovementProgress("block", WodFormat.EMOM)
        assertTrue(empty.entries.isEmpty())
        val after = empty.record(entry("a")).record(entry("b", 1, 12))
        assertEquals(10, after.forInterval(0).single().quantity)
        assertEquals(12, after.forInterval(1).single().quantity)
        assertEquals(22, after.confirmedQuantity("squat"))
    }

    @Test fun correctionIsIdempotentAndSupportsUndo() {
        val progress = WodMovementProgress("block", WodFormat.TABATA)
            .record(entry("a")).record(entry("a", quantity = 8))
        assertEquals(1, progress.entries.size)
        assertEquals(8, progress.confirmedQuantity("squat"))
        assertTrue(progress.remove("a").entries.isEmpty())
    }

    @Test(expected = IllegalArgumentException::class)
    fun globalAmrapCannotBeSavedAsPerMovementSets() {
        WodMovementProgress("block", WodFormat.AMRAP)
    }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsNegativeQuantity() {
        entry("a", quantity = -1)
    }

    @Test(expected = IllegalArgumentException::class)
    fun refusesCrossBlockWrites() {
        WodMovementProgress("block", WodFormat.CIRCUIT).record(
            WodMovementEntry("a", "other", "squat", 0, 10, null, 1000L)
        )
    }
}
