package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test
import java.time.LocalDate

/** Espejo de ProgressSnapshotEngineTests (Apple 602e9c39). */
class ProgressTimeRangeComparableTest {
    private fun day(y: Int, m: Int, d: Int) = LocalDate.of(y, m, d)

    @Test fun weekComparisonOnlyUsesElapsedWeekdays() {
        val tuesday = day(2026, 10, 27)
        val (start, end) = ProgressTimeRange.WEEK.previousPeriodBounds(now = tuesday, weekStartsOnMonday = true)
        assertEquals(day(2026, 10, 19), start)
        assertEquals(day(2026, 10, 21), end)
        assertTrue(ProgressTimeRange.WEEK.containsInPreviousPeriod(day(2026, 10, 20), now = tuesday))
        assertFalse(ProgressTimeRange.WEEK.containsInPreviousPeriod(day(2026, 10, 21), now = tuesday))
    }

    @Test fun monthComparisonOnlyUsesSameElapsedMonthDays() {
        val tuesday = day(2026, 10, 27)
        val (start, end) = ProgressTimeRange.MONTH.previousPeriodBounds(now = tuesday)
        assertEquals(day(2026, 9, 1), start)
        assertEquals(day(2026, 9, 28), end)
        assertTrue(ProgressTimeRange.MONTH.containsInPreviousPeriod(day(2026, 9, 27), now = tuesday))
        assertFalse(ProgressTimeRange.MONTH.containsInPreviousPeriod(day(2026, 9, 28), now = tuesday))
    }

    @Test fun previousMonthClampsAtEndOfShorterMonth() {
        val now = day(2026, 3, 31)
        val (start, end) = ProgressTimeRange.MONTH.previousPeriodBounds(now = now)
        assertEquals(day(2026, 2, 1), start)
        assertEquals(day(2026, 3, 1), end)
    }

    @Test fun streakReferenceUsesSameRelativeDayOfPreviousPeriod() {
        // Apple b4b8f8b8: bounds.end - 1s, no el ultimo dia del periodo anterior.
        // Martes 27oct: fin comparable = miercoles 21oct 00:00 -> racha a 20oct.
        assertEquals(day(2026, 10, 20),
            ProgressTimeRange.WEEK.previousPeriodStreakReference(now = day(2026, 10, 27)))
        // Lunes: fin comparable = martes 20oct 00:00 (prevStart+1 dia transcurrido)
        // -> racha al lunes 19oct (mismo dia relativo), no al lunes 26oct - 7d.
        assertEquals(day(2026, 10, 19),
            ProgressTimeRange.WEEK.previousPeriodStreakReference(now = day(2026, 10, 26)))
        assertEquals(day(2026, 10, 26),
            ProgressTimeRange.TODAY.previousPeriodStreakReference(now = day(2026, 10, 27)))
        assertEquals(day(2026, 9, 27),
            ProgressTimeRange.MONTH.previousPeriodStreakReference(now = day(2026, 10, 27)))
    }

    @Test fun rollingWindowComparesFullPriorWindow() {
        val now = day(2026, 10, 27)
        val (start, end) = ProgressTimeRange.DAYS_90.previousPeriodBounds(now = now)
        assertEquals(90, java.time.temporal.ChronoUnit.DAYS.between(start, end))
    }

    @Test fun healthFetchCountsMatchApple() {
        assertEquals(7, ProgressTimeRange.TODAY.healthFetchDayCount)
        assertEquals(16, ProgressTimeRange.WEEK.healthFetchDayCount)
        assertEquals(70, ProgressTimeRange.MONTH.healthFetchDayCount)
        assertEquals(190, ProgressTimeRange.DAYS_90.healthFetchDayCount)
        assertEquals(370, ProgressTimeRange.DAYS_180.healthFetchDayCount)
        assertEquals(730, ProgressTimeRange.DAYS_360.healthFetchDayCount)
    }
}
