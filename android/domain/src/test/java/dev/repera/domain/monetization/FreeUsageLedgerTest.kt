package dev.repera.domain.monetization

import java.util.Calendar
import java.util.TimeZone
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class FreeUsageLedgerTest {

    private fun cal(): Calendar = Calendar.getInstance(TimeZone.getTimeZone("UTC"))

    private fun utc(year: Int, month: Int, day: Int): Long =
        cal().apply { clear(); set(year, month - 1, day) }.timeInMillis

    @Test
    fun `primer escaneo consume`() {
        val (state, ok) = FreeUsageLedger.consumeBoardScan(FreeUsageState(), "a1", isPro = false)
        assertTrue(ok)
        assertEquals(1, state.boardScansConsumed)
        assertTrue(state.consumedAttemptIDs.contains("a1"))
    }

    @Test
    fun `cuarto OK, quinto no puede empezar`() {
        var state = FreeUsageState(boardScanPeriodKey = FreeUsageLedger.periodKey())
        for (i in 1..4) {
            val (next, ok) = FreeUsageLedger.consumeBoardScan(state, "a$i", isPro = false)
            assertTrue(ok)
            state = next
        }
        assertFalse(FreeUsageLedger.canStartBoardScan(state, isPro = false))
        assertEquals(0, FreeUsageLedger.boardScansRemaining(state))
    }

    @Test
    fun `Pro no consume cuota`() {
        val (state, ok) = FreeUsageLedger.consumeBoardScan(FreeUsageState(), "p1", isPro = true)
        assertFalse(ok)
        assertEquals(0, state.boardScansConsumed)
        assertTrue(FreeUsageLedger.canStartBoardScan(state, isPro = true))
    }

    @Test
    fun `doble callback mismo intento no cuenta dos veces`() {
        val (s1, ok1) = FreeUsageLedger.consumeBoardScan(FreeUsageState(), "same", isPro = false)
        assertTrue(ok1)
        val (s2, ok2) = FreeUsageLedger.consumeBoardScan(s1, "same", isPro = false)
        assertFalse(ok2)
        assertEquals(1, s2.boardScansConsumed)
    }

    @Test
    fun `cambio de mes resetea`() {
        val state = FreeUsageState(
            boardScanPeriodKey = "2026-01",
            boardScansConsumed = 4,
            consumedAttemptIDs = listOf("x")
        )
        val normalized = FreeUsageLedger.normalized(state, now = utc(2026, 2, 1), calendar = cal())
        assertEquals("2026-02", normalized.boardScanPeriodKey)
        assertEquals(0, normalized.boardScansConsumed)
        assertTrue(normalized.consumedAttemptIDs.isEmpty())
    }

    @Test
    fun `cambio de año`() {
        val state = FreeUsageState(boardScanPeriodKey = "2025-12", boardScansConsumed = 3)
        assertEquals(4, FreeUsageLedger.boardScansRemaining(state, now = utc(2026, 1, 15), calendar = cal()))
    }

    @Test
    fun `reapertura tras varios meses`() {
        val old = FreeUsageState(boardScanPeriodKey = "2025-06", boardScansConsumed = 4)
        val oct = utc(2026, 10, 19)
        assertTrue(FreeUsageLedger.canStartBoardScan(old, isPro = false, now = oct, calendar = cal()))
        val (state, ok) = FreeUsageLedger.consumeBoardScan(old, "new", isPro = false, now = oct, calendar = cal())
        assertTrue(ok)
        assertEquals("2026-10", state.boardScanPeriodKey)
        assertEquals(1, state.boardScansConsumed)
    }

    @Test
    fun `period key estable en UTC`() {
        val t = cal().apply { clear(); set(2026, 9, 31, 23, 0) }.timeInMillis
        assertEquals("2026-10", FreeUsageLedger.periodKey(t, cal()))
    }
}
