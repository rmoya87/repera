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
        assertEquals("Últimos 7 días", ProgressTimeRange.WEEK.title)
        assertEquals("Este mes", ProgressTimeRange.MONTH.title)
        assertEquals("90 días", ProgressTimeRange.DAYS_90.title)
        assertEquals(1, ProgressTimeRange.TODAY.chartDayCount)
        assertEquals(7, ProgressTimeRange.WEEK.chartDayCount)
        assertEquals(31, ProgressTimeRange.MONTH.chartDayCount)
        assertEquals(90, ProgressTimeRange.DAYS_90.chartDayCount)
        assertEquals(360, ProgressTimeRange.DAYS_360.chartDayCount)
    }

    @Test fun weekIsRollingSevenDays() {
        // Sábado 24 -> domingo 18 (hoy inclusive + 6 atrás).
        assertEquals(LocalDate.of(2026, 10, 18), ProgressTimeRange.WEEK.startDate(now))
        assertEquals(LocalDate.of(2026, 10, 18),
            ProgressTimeRange.WEEK.startDate(now, weekStartsOnMonday = false))
        assertEquals(LocalDate.of(2026, 10, 1), ProgressTimeRange.MONTH.startDate(now))
        assertEquals(LocalDate.of(2026, 7, 27), ProgressTimeRange.DAYS_90.startDate(now))
    }

    @Test fun containsBoundsAndFuture() {
        assertTrue(ProgressTimeRange.WEEK.contains(LocalDate.of(2026, 10, 18), now))
        assertTrue(ProgressTimeRange.WEEK.contains(now, now))
        assertFalse(ProgressTimeRange.WEEK.contains(LocalDate.of(2026, 10, 17), now))
        assertFalse(ProgressTimeRange.WEEK.contains(now.plusDays(1), now))
        assertTrue(ProgressTimeRange.TODAY.contains(now, now))
        assertFalse(ProgressTimeRange.TODAY.contains(now.minusDays(1), now))
    }

    @Test fun previousPeriodWindows() {
        // Ventana móvil previa: 11–18 (fin exclusivo = inicio actual).
        assertEquals(LocalDate.of(2026, 10, 11) to LocalDate.of(2026, 10, 18),
            ProgressTimeRange.WEEK.previousPeriodBounds(now))
        assertEquals(LocalDate.of(2026, 9, 1) to LocalDate.of(2026, 9, 25),
            ProgressTimeRange.MONTH.previousPeriodBounds(now))
        assertEquals(LocalDate.of(2026, 10, 23) to LocalDate.of(2026, 10, 24),
            ProgressTimeRange.TODAY.previousPeriodBounds(now))
        assertTrue(ProgressTimeRange.WEEK.containsInPreviousPeriod(
            LocalDate.of(2026, 10, 15), now))
        assertFalse(ProgressTimeRange.WEEK.containsInPreviousPeriod(
            LocalDate.of(2026, 10, 18), now))
    }

    @Test fun healthFetchMarginsMatchIos() {
        assertEquals(7, ProgressTimeRange.TODAY.healthFetchDayCount)
        assertEquals(16, ProgressTimeRange.WEEK.healthFetchDayCount)
        assertEquals(70, ProgressTimeRange.MONTH.healthFetchDayCount)
        assertEquals(190, ProgressTimeRange.DAYS_90.healthFetchDayCount)
        assertEquals(730, ProgressTimeRange.DAYS_360.healthFetchDayCount)
    }

    @Test fun healthFetchWideningOnlyGrows() {
        // Apple 479d8407: 730d solo cuando el rango 360d lo pide.
        assertEquals(null, ProgressTimeRange.healthFetchWidening(370, ProgressTimeRange.WEEK))
        assertEquals(null, ProgressTimeRange.healthFetchWidening(370, ProgressTimeRange.DAYS_180))
        assertEquals(730, ProgressTimeRange.healthFetchWidening(370, ProgressTimeRange.DAYS_360))
        assertEquals(null, ProgressTimeRange.healthFetchWidening(730, ProgressTimeRange.DAYS_360))
        assertEquals(16, ProgressTimeRange.healthFetchWidening(0, ProgressTimeRange.WEEK))
    }
}
