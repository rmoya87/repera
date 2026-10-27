package dev.repera.domain

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/** Punto diario de pulso con mínimo/medio/máximo (Health Connect / HealthKit). */
data class DailyHeartRatePoint(
    val day: LocalDate,
    val minBpm: Double,
    val avgBpm: Double,
    val maxBpm: Double
)

/** Punto diario de energía activa en kcal. */
data class DailyActiveEnergyPoint(val day: LocalDate, val kcal: Double)

data class HeartRatePlotPoint(
    val day: LocalDate,
    val minBpm: Double,
    val avgBpm: Double,
    val maxBpm: Double
)

data class ProgressPreparedCharts(
    val range: ProgressTimeRange,
    val weekStartsOnMonday: Boolean,
    val heartRate: List<HeartRatePlotPoint>,
    val calories: List<ProgressDayPoint>,
    val caloriesTotal: Double,
    val averageHeartRate: Double?,
    val granularity: ProgressSeriesGranularity,
    /** Apple caloriesDailyAverage: media por día CON dato (no se cuentan ausencias como 0 kcal). */
    val caloriesDailyAverage: Double? = null,
    /** Apple previousCaloriesDailyAverage: null si no hay periodo anterior comparable (menos días que el actual). */
    val previousCaloriesDailyAverage: Double? = null
)

/** Preparación de series para las gráficas de Progreso.
 *  Port de ProgressChartBuilder.swift (iOS). */
object ProgressChartBuilder {

    /** Máximo de puntos en la gráfica (más = más lento). */
    const val MAX_PLOT_POINTS = 48

    fun build(
        range: ProgressTimeRange,
        weekStartsOnMonday: Boolean,
        heartRateDays: List<DailyHeartRatePoint>,
        energyDays: List<DailyActiveEnergyPoint>,
        workouts: List<StatsWorkout>,
        external: List<ExternalDaySample>,
        now: LocalDate = LocalDate.now()
    ): ProgressPreparedCharts {
        val granularity = StatsEngine.granularityForChart(range)
        val start = range.startDate(now, weekStartsOnMonday)
        val endExclusive = now.plusDays(1)

        val hrRaw = heartRateDays
            .filter { !it.day.isBefore(start) && it.day.isBefore(endExclusive) }
            .sortedBy { it.day }
        val energyRaw = energyDays
            .filter { !it.day.isBefore(start) && it.day.isBefore(endExclusive) }

        val hrAgg = aggregateHeartRate(hrRaw, granularity, weekStartsOnMonday)
        val hrPlot = downsample(hrAgg, MAX_PLOT_POINTS)

        val kcalDaily = mergedDailyCalories(
            energyDays = energyRaw,
            external = external,
            start = start,
            endExclusive = endExclusive
        )
        val kcalTotal = kcalDaily.sumOf { it.value }
        val dailyAverage = if (kcalDaily.isEmpty()) null else kcalTotal / kcalDaily.size
        val (prevStart, prevEnd) = range.previousPeriodBounds(now, weekStartsOnMonday)
        val previousDays = mergedDailyCalories(energyDays = energyDays, external = external, start = prevStart, endExclusive = prevEnd)
        val previousAverage = if (previousDays.isEmpty() || previousDays.size < kcalDaily.size) null
            else previousDays.sumOf { it.value } / previousDays.size
        val kcalAgg = StatsEngine.averagedSeries(
            kcalDaily, granularity, weekStartsOnMonday)
        val kcalPlot = downsample(kcalAgg, MAX_PLOT_POINTS)

        val avgHr = if (hrRaw.isEmpty()) null
            else hrRaw.map { it.avgBpm }.average()

        return ProgressPreparedCharts(
            range = range,
            weekStartsOnMonday = weekStartsOnMonday,
            heartRate = hrPlot,
            calories = kcalPlot,
            caloriesTotal = kcalTotal,
            averageHeartRate = avgHr,
            granularity = granularity,
            caloriesDailyAverage = dailyAverage,
            previousCaloriesDailyAverage = previousAverage
        )
    }

    /** Calorías por día exclusivamente desde Salud, sin estimaciones de
     *  Repera. Las kcal de entrenos externos son datos registrados por el
     *  dispositivo, no MET calculados. Repera no aporta kcal a las gráficas. */
    fun mergedDailyCalories(
        energyDays: List<DailyActiveEnergyPoint>,
        external: List<ExternalDaySample>,
        start: LocalDate,
        endExclusive: LocalDate,
        zone: ZoneId = ZoneId.systemDefault()
    ): List<ProgressDayPoint> {
        val healthByDay = mutableMapOf<LocalDate, Double>()
        for (day in energyDays) {
            if (day.day.isBefore(start) || !day.day.isBefore(endExclusive)) continue
            healthByDay[day.day] = (healthByDay[day.day] ?: 0.0) + max(0.0, day.kcal)
        }
        val cardsByDay = mutableMapOf<LocalDate, Double>()
        for (sample in external) {
            val day = Instant.ofEpochMilli(sample.epochMillis).atZone(zone).toLocalDate()
            if (day.isBefore(start) || !day.isBefore(endExclusive)) continue
            val add = max(0.0, sample.activeEnergyKcal)
            if (add <= 0) continue
            cardsByDay[day] = (cardsByDay[day] ?: 0.0) + add
        }
        return (healthByDay.keys + cardsByDay.keys).mapNotNull { day ->
            val value = max(healthByDay[day] ?: 0.0, cardsByDay[day] ?: 0.0)
            if (value <= 0) null else ProgressDayPoint(day, value)
        }.sortedBy { it.day }
    }

    private fun aggregateHeartRate(
        raw: List<DailyHeartRatePoint>,
        granularity: ProgressSeriesGranularity,
        weekStartsOnMonday: Boolean
    ): List<HeartRatePlotPoint> {
        val mapped = raw.map {
            HeartRatePlotPoint(it.day, it.minBpm, it.avgBpm, it.maxBpm)
        }
        if (granularity == ProgressSeriesGranularity.DAY || mapped.size <= 1) {
            return mapped
        }
        class Acc(var day: LocalDate, var minSum: Double, var avgSum: Double,
                  var maxSum: Double, var count: Int)
        val groups = LinkedHashMap<String, Acc>()
        for (p in mapped) {
            val bucketStart = when (granularity) {
                ProgressSeriesGranularity.DAY -> p.day
                ProgressSeriesGranularity.WEEK ->
                    StatsEngine.startOfWeek(p.day, weekStartsOnMonday)
                ProgressSeriesGranularity.MONTH ->
                    p.day.withDayOfMonth(1)
            }
            val key = bucketStart.toString()
            val acc = groups.getOrPut(key) { Acc(bucketStart, 0.0, 0.0, 0.0, 0) }
            acc.minSum += p.minBpm
            acc.avgSum += p.avgBpm
            acc.maxSum += p.maxBpm
            acc.count += 1
            if (bucketStart.isBefore(acc.day)) acc.day = bucketStart
        }
        return groups.values.map { acc ->
            val n = max(1, acc.count).toDouble()
            HeartRatePlotPoint(acc.day, acc.minSum / n, acc.avgSum / n, acc.maxSum / n)
        }.sortedBy { it.day }
    }

    private fun <T> downsample(points: List<T>, maxCount: Int): List<T> {
        if (points.size <= maxCount || maxCount <= 2) return points
        val step = (points.size - 1).toDouble() / (maxCount - 1)
        return (0 until maxCount).map { i ->
            points[min(points.size - 1, (i * step).roundToInt())]
        }
    }
}
