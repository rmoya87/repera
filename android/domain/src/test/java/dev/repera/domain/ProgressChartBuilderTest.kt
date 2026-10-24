package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

class ProgressChartBuilderTest {

    private val now = LocalDate.of(2026, 6, 15) // lunes

    @Test
    fun `calorias diarias eligen el mayor entre salud y externas`() {
        val monday = now
        val energy = listOf(DailyActiveEnergyPoint(monday, 500.0))
        val external = listOf(ExternalDaySample(
            epochMillis = monday.atTime(12, 0)
                .atZone(java.time.ZoneId.of("Europe/Madrid")).toInstant().toEpochMilli(),
            activeEnergyKcal = 650.0))
        val out = ProgressChartBuilder.mergedDailyCalories(
            energy, external, monday, monday.plusDays(1))
        assertEquals(1, out.size)
        assertEquals(650.0, out[0].value, 1e-9)
    }

    @Test
    fun `calorias cero no generan punto`() {
        val out = ProgressChartBuilder.mergedDailyCalories(
            listOf(DailyActiveEnergyPoint(now, 0.0)), emptyList(),
            now, now.plusDays(1))
        assertTrue(out.isEmpty())
    }

    @Test
    fun `build semana agrega pulso por dia y downsampling respeta tope`() {
        val hr = (0L..59L).map {
            DailyHeartRatePoint(now.minusDays(it), 50.0 + it, 60.0 + it, 90.0 + it)
        }
        val charts = ProgressChartBuilder.build(
            range = ProgressTimeRange.DAYS_360,
            weekStartsOnMonday = true,
            heartRateDays = hr,
            energyDays = emptyList(),
            workouts = emptyList(),
            external = emptyList(),
            now = now)
        assertEquals(ProgressSeriesGranularity.MONTH, charts.granularity)
        assertTrue(charts.heartRate.size <= ProgressChartBuilder.MAX_PLOT_POINTS)
        assertTrue(charts.heartRate.isNotEmpty())
        // Media del rango completo.
        assertEquals(89.5, charts.averageHeartRate!!, 0.5)
    }

    @Test
    fun `build sin pulso no inventa media`() {
        val charts = ProgressChartBuilder.build(
            range = ProgressTimeRange.WEEK,
            weekStartsOnMonday = true,
            heartRateDays = emptyList(),
            energyDays = listOf(DailyActiveEnergyPoint(now, 300.0)),
            workouts = emptyList(),
            external = emptyList(),
            now = now)
        assertEquals(null, charts.averageHeartRate)
        assertEquals(300.0, charts.caloriesTotal, 1e-9)
    }
}
