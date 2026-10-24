package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

class ProgressTimeRangeTest {
    private val now = LocalDate.of(2026, 10, 24) // sabado

    @Test fun titlesAndChartDaysMatchIos() {
        assertEquals("Hoy", ProgressTimeRange.TODAY.title)
        assertEquals("Esta semana", ProgressTimeRange.WEEK.title)
        assertEquals("Este mes", ProgressTimeRange.MONTH.title)
        assertEquals("90 días", ProgressTimeRange.DAYS_90.title)
        assertEquals(1, ProgressTimeRange.TODAY.chartDayCount)
        assertEquals(7, ProgressTimeRange.WEEK.chartDayCount)
        assertEquals(31, ProgressTimeRange.MONTH.chartDayCount)
        assertEquals(90, ProgressTimeRange.DAYS_90.chartDayCount)
        assertEquals(360, ProgressTimeRange.DAYS_360.chartDayCount)
    }

    @Test fun weekStartsOnMondayByDefault() {
        // Sabado 24 -> lunes 19 de la misma semana.
        assertEquals(LocalDate.of(2026, 10, 19), ProgressTimeRange.WEEK.startDate(now))
        // Con semana empezando en domingo -> domingo 18.
        assertEquals(LocalDate.of(2026, 10, 18),
            ProgressTimeRange.WEEK.startDate(now, weekStartsOnMonday = false))
        assertEquals(LocalDate.of(2026, 10, 1), ProgressTimeRange.MONTH.startDate(now))
        assertEquals(LocalDate.of(2026, 7, 27), ProgressTimeRange.DAYS_90.startDate(now))
    }

    @Test fun containsBoundsAndFuture() {
        assertTrue(ProgressTimeRange.WEEK.contains(LocalDate.of(2026, 10, 19), now))
        assertTrue(ProgressTimeRange.WEEK.contains(now, now))
        assertFalse(ProgressTimeRange.WEEK.contains(LocalDate.of(2026, 10, 18), now))
        assertFalse(ProgressTimeRange.WEEK.contains(now.plusDays(1), now))
        assertTrue(ProgressTimeRange.TODAY.contains(now, now))
        assertFalse(ProgressTimeRange.TODAY.contains(now.minusDays(1), now))
    }

    @Test fun previousPeriodWindows() {
        assertEquals(LocalDate.of(2026, 10, 12) to LocalDate.of(2026, 10, 19),
            ProgressTimeRange.WEEK.previousPeriodBounds(now))
        assertEquals(LocalDate.of(2026, 9, 1) to LocalDate.of(2026, 10, 1),
            ProgressTimeRange.MONTH.previousPeriodBounds(now))
        assertEquals(LocalDate.of(2026, 10, 23) to LocalDate.of(2026, 10, 24),
            ProgressTimeRange.TODAY.previousPeriodBounds(now))
        assertTrue(ProgressTimeRange.WEEK.containsInPreviousPeriod(
            LocalDate.of(2026, 10, 15), now))
        assertFalse(ProgressTimeRange.WEEK.containsInPreviousPeriod(
            LocalDate.of(2026, 10, 19), now))
    }

    @Test fun healthFetchMarginsMatchIos() {
        assertEquals(7, ProgressTimeRange.TODAY.healthFetchDayCount)
        assertEquals(14, ProgressTimeRange.WEEK.healthFetchDayCount)
        assertEquals(45, ProgressTimeRange.MONTH.healthFetchDayCount)
        assertEquals(100, ProgressTimeRange.DAYS_90.healthFetchDayCount)
        assertEquals(370, ProgressTimeRange.DAYS_360.healthFetchDayCount)
    }
}
