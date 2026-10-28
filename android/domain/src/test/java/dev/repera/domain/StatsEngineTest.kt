package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId

class StatsEngineTest {
    private val zone: ZoneId = ZoneId.of("Europe/Madrid")
    private val now = LocalDate.of(2026, 10, 24) // sabado

    private fun epoch(day: LocalDate): Long =
        day.atTime(LocalTime.NOON).atZone(zone).toInstant().toEpochMilli()

    private fun benchWorkout(day: LocalDate, weight: Double, reps: Int,
                             duration: Double = 50.0) = StatsWorkout(
        epochMillis = epoch(day), durationMinutes = duration,
        exercises = listOf(StatsExercise(
            exerciseId = "press", exerciseName = "Press banca",
            muscleGroup = "Pecho",
            sets = listOf(StatsSet(reps = reps, weightKg = weight)))))

    @Test fun epleyAndRecordsKeepBestPerExercise() {
        assertEquals(130.0, StatsEngine.epleyOneRM(100.0, 9), 0.0001)
        assertEquals(0.0, StatsEngine.epleyOneRM(0.0, 5), 0.0001)
        val workouts = listOf(
            benchWorkout(now.minusDays(2), 100.0, 5),  // 1RM 116.7
            benchWorkout(now.minusDays(1), 90.0, 10))  // 1RM 120.0 -> gana
        val records = StatsEngine.personalRecords(workouts)
        assertEquals(1, records.size)
        assertEquals(90.0, records[0].weightKg, 0.0001)
        assertEquals(10, records[0].reps)
        assertEquals(epoch(now.minusDays(1)), records[0].epochMillis)
    }

    @Test fun mobilityAndWarmupAreExcludedFromRecords() {
        val mobility = StatsWorkout(epoch(now), 30.0, exercises = listOf(
            StatsExercise("str", "Estiramiento", isMobility = true,
                sets = listOf(StatsSet(reps = 1, weightKg = 50.0)))))
        assertEquals(0, StatsEngine.personalRecords(listOf(mobility)).size)
    }

    @Test fun volumeSkipsCaloriesMetersAndCountsDrops() {
        val set = StatsSet(reps = 10, weightKg = 20.0,
            drops = listOf(8 to 15.0, 6 to 10.0))
        assertEquals(10 * 20.0 + 8 * 15.0 + 6 * 10.0, set.volumeKg, 0.0001)
        assertEquals(0.0, StatsSet(reps = 500, quantityUnit = "meters",
            weightKg = 10.0).volumeKg, 0.0001)
        assertEquals(0.0, StatsSet(reps = 10, weightKg = 20.0,
            deficitCm = 5.0).volumeKg, 0.0001)
    }

    @Test fun weekStreakCountsConsecutiveWeeks() {
        // Esta semana, la anterior y hace 3 (hueco en medio): racha = 2.
        val dates = listOf(epoch(now), epoch(now.minusDays(8)),
            epoch(now.minusDays(22)))
        assertEquals(2, StatsEngine.consecutiveWeekStreak(dates,
            now = now, zone = zone))
        // Sin actividad esta semana pero sí la anterior: racha cuenta
        // desde la semana actual vacía (i==0 no rompe) -> 1.
        assertEquals(1, StatsEngine.consecutiveWeekStreak(
            listOf(epoch(now.minusDays(8))), now = now, zone = zone))
        assertEquals(0, StatsEngine.consecutiveWeekStreak(emptyList(),
            now = now, zone = zone))
    }

    @Test fun filtersRespectRangeAndPreviousPeriod() {
        val thisWeek = benchWorkout(now, 100.0, 5)
        val lastWeek = benchWorkout(now.minusDays(7), 100.0, 5)
        val workouts = listOf(thisWeek, lastWeek)
        assertEquals(1, StatsEngine.filterWorkouts(workouts,
            ProgressTimeRange.WEEK, now = now, zone = zone).size)
        assertEquals(1, StatsEngine.filterWorkoutsInPreviousPeriod(workouts,
            ProgressTimeRange.WEEK, now = now, zone = zone).size)
        assertEquals(2, StatsEngine.filterWorkouts(workouts,
            ProgressTimeRange.MONTH, now = now, zone = zone).size)
    }

    @Test fun summaryAveragesAndTotalsMatchIos() {
        val gym = benchWorkout(now, 100.0, 5, duration = 60.0)
        val cardio = StatsWorkout(epoch(now), 30.0, activeEnergyKcal = 200.0,
            exercises = listOf(StatsExercise("run", "Carrera",
                muscleGroup = "Cardio")))
        val summary = StatsEngine.progressHealthSummary(
            listOf(gym, cardio), range = ProgressTimeRange.WEEK,
            now = now, zone = zone)
        assertEquals(45.0, summary.averageMinutes!!, 0.0001)
        assertEquals(200.0, summary.totalKcal, 0.0001)
        assertEquals(30.0, summary.averageCardioMinutes!!, 0.0001)
        assertEquals(100.0 * (1 + 5 / 30.0) * 0 + 500.0, summary.volumeKg, 0.0001)
        assertEquals(2, summary.sessionCount)
    }

    @Test fun heatmapQuartilesAndLevels() {
        // iOS: sorted[min(n-1, floor(p*n))] -> (20, 30, 40) con estos valores.
        val thresholds = StatsEngine.heatmapThresholds(listOf(10.0, 20.0, 30.0, 40.0))
        assertEquals(20.0, thresholds.first, 0.0001)
        assertEquals(30.0, thresholds.second, 0.0001)
        assertEquals(40.0, thresholds.third, 0.0001)
        assertEquals(0, StatsEngine.heatmapLevel(100.0, false, thresholds))
        assertEquals(1, StatsEngine.heatmapLevel(0.0, true, thresholds))
        assertEquals(1, StatsEngine.heatmapLevel(15.0, true, thresholds))
        assertEquals(2, StatsEngine.heatmapLevel(25.0, true, thresholds))
        assertEquals(3, StatsEngine.heatmapLevel(35.0, true, thresholds))
        assertEquals(4, StatsEngine.heatmapLevel(45.0, true, thresholds))
    }

    @Test fun dailyMetricSeriesFillsZerosOnlyForDayGranularity() {
        val cardio = StatsWorkout(epoch(now), 25.0,
            exercises = listOf(StatsExercise("run", "Carrera",
                muscleGroup = "Cardio")))
        val week = StatsEngine.dailyMetricSeries(listOf(cardio),
            metric = "cardioMinutes", range = ProgressTimeRange.WEEK,
            now = now, zone = zone)
        assertEquals(6, week.size) // lunes 19 .. sabado 24
        assertEquals(25.0, week.last().value, 0.0001)
        assertEquals(0.0, week.first().value, 0.0001)
        val long = StatsEngine.dailyMetricSeries(listOf(cardio),
            metric = "cardioMinutes", range = ProgressTimeRange.DAYS_360,
            now = now, zone = zone)
        assertEquals(1, long.size) // sin relleno de ceros en 360 días
    }

    @Test fun averagedSeriesGroupsByWeekAndMonth() {
        val points = listOf(
            ProgressDayPoint(LocalDate.of(2026, 10, 19), 10.0),
            ProgressDayPoint(LocalDate.of(2026, 10, 20), 20.0),
            ProgressDayPoint(LocalDate.of(2026, 9, 5), 30.0),
            ProgressDayPoint(LocalDate.of(2026, 9, 20), 50.0))
        val weekly = StatsEngine.averagedSeries(points, ProgressSeriesGranularity.WEEK)
        assertEquals(3, weekly.size) // sem 7 sep, sem 14 sep, sem 19 oct
        assertEquals(LocalDate.of(2026, 10, 19), weekly.last().day)
        assertEquals(15.0, weekly.last().value, 0.0001)
        val monthly = StatsEngine.averagedSeries(points, ProgressSeriesGranularity.MONTH)
        assertEquals(2, monthly.size)
        assertEquals(40.0, monthly.first().value, 0.0001)
        assertEquals(LocalDate.of(2026, 10, 1), monthly.last().day)
    }

    @Test fun bodyWeightDeltaUsesClosestTo30DaysAgo() {
        val entries = listOf(
            epoch(now.minusDays(40)) to 80.0,
            epoch(now.minusDays(31)) to 78.0,
            epoch(now.minusDays(5)) to 77.0,
            epoch(now) to 76.5)
        assertEquals(-1.5, StatsEngine.bodyWeightDelta30d(entries,
            now = now, zone = zone)!!, 0.0001)
        assertNull(StatsEngine.bodyWeightDelta30d(
            listOf(epoch(now) to 76.5), now = now, zone = zone))
    }

    @Test fun calendarHelpersMatchSpanishIos() {
        assertEquals(6, StatsEngine.isoWeekday(now)) // sabado
        assertEquals("Sábado", StatsEngine.weekdayName(6))
        assertEquals(now.plusDays(2), StatsEngine.nextDate(1, now))
        assertEquals(now, StatsEngine.nextDate(6, now))
    }
}
