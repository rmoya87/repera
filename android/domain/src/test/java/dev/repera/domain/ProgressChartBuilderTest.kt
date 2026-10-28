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

    private fun week(energy: List<DailyActiveEnergyPoint>) = ProgressChartBuilder.build(
        range = ProgressTimeRange.WEEK, weekStartsOnMonday = true, heartRateDays = emptyList(),
        energyDays = energy, workouts = emptyList(), external = emptyList(), now = now)

    @Test
    fun `media diaria y periodo anterior comparables`() {
        val charts = week(listOf(DailyActiveEnergyPoint(now, 300.0),
            DailyActiveEnergyPoint(now.minusDays(1), 200.0), DailyActiveEnergyPoint(now.minusDays(2), 200.0)))
        assertEquals(300.0, charts.caloriesDailyAverage!!, 1e-9)
        // 602e9c39: el lunes solo es comparable con el lunes anterior; sin datos
        // de ese día no hay media previa (antes se usaba toda la semana previa).
        assertEquals(null, charts.previousCaloriesDailyAverage)
        assertEquals(null, CalorieAverageStats.change(charts.caloriesDailyAverage, charts.previousCaloriesDailyAverage))
    }

    @Test
    fun `periodo anterior mas corto o ausente no da variacion enganosa`() {
        val none = week(listOf(DailyActiveEnergyPoint(now, 300.0)))
        assertEquals(null, none.previousCaloriesDailyAverage)
        // actual con 2 dias de datos (lunes y martes) frente a 1 dia previo: no comparable
        val shorter = ProgressChartBuilder.build(range = ProgressTimeRange.WEEK, weekStartsOnMonday = true, heartRateDays = emptyList(),
            energyDays = listOf(DailyActiveEnergyPoint(now, 300.0), DailyActiveEnergyPoint(now.plusDays(1), 100.0),
                DailyActiveEnergyPoint(now.minusDays(1), 200.0)), workouts = emptyList(), external = emptyList(), now = now.plusDays(1))
        assertEquals(null, shorter.previousCaloriesDailyAverage)
        assertEquals(200.0, shorter.caloriesDailyAverage!!, 1e-9)
        assertEquals(null, CalorieAverageStats.change(100.0, 0.0))
        assertEquals("—", CalorieAverageStats.kcalLabel(null))
        assertEquals("+50 %", CalorieAverageStats.changeLabel(50.0))
        assertEquals("-10 %", CalorieAverageStats.changeLabel(-10.0))
    }
}
