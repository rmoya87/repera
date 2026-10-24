package dev.repera.domain

import java.time.Instant
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId
import java.time.temporal.WeekFields

/** Tipos reducidos de entrada para las estadísticas (adaptados desde el
 *  snapshot JSON en mobile). Semántica 1:1 con StatsEngine.swift (iOS). */
data class StatsSet(
    val reps: Int,
    val weightKg: Double? = null,
    val quantityUnit: String? = null,
    val deficitCm: Double? = null,
    val isWarmup: Boolean = false,
    val rir: Double? = null,
    val durationSeconds: Int? = null,
    val drops: List<Pair<Int, Double?>> = emptyList()
) {
    /** Volumen en kg (LoggedSet.volumeKg, Models.swift:728). */
    val volumeKg: Double
        get() {
            if (quantityUnit == "calories" || quantityUnit == "meters") return 0.0
            if (deficitCm != null) return 0.0
            val main = reps * (weightKg ?: 0.0)
            val extra = drops.sumOf { it.first * (it.second ?: 0.0) }
            return main + extra
        }
}

data class StatsExercise(
    val exerciseId: String,
    val exerciseName: String,
    val muscleGroup: String? = null,
    val isMobility: Boolean = false,
    val sets: List<StatsSet> = emptyList()
)

data class StatsWorkout(
    val epochMillis: Long,
    val durationMinutes: Double,
    val finished: Boolean = true,
    val activeEnergyKcal: Double? = null,
    val exercises: List<StatsExercise> = emptyList()
) {
    val totalVolumeKg: Double get() = exercises.sumOf { e -> e.sets.sumOf { it.volumeKg } }
}

data class ExternalDaySample(
    val epochMillis: Long,
    val minutes: Double = 0.0,
    val cardioMinutes: Double = 0.0,
    val activeEnergyKcal: Double = 0.0,
    val volumeKg: Double = 0.0
)

data class ProgressHealthSummary(
    val averageMinutes: Double?,
    val totalKcal: Double,
    val averageCardioMinutes: Double?,
    val volumeKg: Double,
    val sessionCount: Int
)

data class PersonalRecord(
    val exerciseId: String,
    val exerciseName: String,
    val weightKg: Double,
    val reps: Int,
    val epochMillis: Long
) {
    val estimatedOneRM: Double get() = StatsEngine.epleyOneRM(weightKg, reps)
}

data class ProgressDayPoint(
    val day: LocalDate,
    val value: Double
)

data class DayActivityContribution(
    val day: LocalDate,
    val minutes: Double,
    val volumeKg: Double,
    val sessionCount: Int
)

enum class ProgressSeriesGranularity { DAY, WEEK, MONTH }

private class SeriesAcc(var date: LocalDate, var sum: Double, var count: Int)

/** Estadísticas de Progreso. Port de StatsEngine.swift (iOS) sobre java.time. */
object StatsEngine {

    fun epleyOneRM(weightKg: Double, reps: Int): Double =
        if (weightKg > 0 && reps > 0) weightKg * (1 + reps / 30.0) else 0.0

    private fun dayOf(epochMillis: Long, zone: ZoneId): LocalDate =
        Instant.ofEpochMilli(epochMillis).atZone(zone).toLocalDate()

    private fun weekFields(monday: Boolean): WeekFields =
        WeekFields.of(if (monday) java.time.DayOfWeek.MONDAY else java.time.DayOfWeek.SUNDAY, 1)

    private fun weekKey(date: LocalDate, monday: Boolean): String {
        val wf = weekFields(monday)
        return "${date.get(wf.weekBasedYear())}-${date.get(wf.weekOfWeekBasedYear())}"
    }

    fun startOfWeek(date: LocalDate, monday: Boolean): LocalDate {
        val first = if (monday) java.time.DayOfWeek.MONDAY else java.time.DayOfWeek.SUNDAY
        return date.minusDays(((date.dayOfWeek.value - first.value) + 7L) % 7L)
    }

    // ---- Registros personales -------------------------------------------

    fun personalRecords(workouts: List<StatsWorkout>): List<PersonalRecord> {
        val best = mutableMapOf<String, PersonalRecord>()
        for (workout in workouts) {
            if (!workout.finished) continue
            for (exercise in workout.exercises) {
                if (exercise.isMobility) continue
                for (set in exercise.sets) {
                    val weight = set.weightKg ?: continue
                    if (weight <= 0 || set.reps <= 0) continue
                    val candidate = PersonalRecord(
                        exercise.exerciseId, exercise.exerciseName,
                        weight, set.reps, workout.epochMillis)
                    val existing = best[exercise.exerciseId]
                    if (existing == null ||
                        candidate.estimatedOneRM > existing.estimatedOneRM) {
                        best[exercise.exerciseId] = candidate
                    }
                }
            }
        }
        return best.values.sortedByDescending { it.estimatedOneRM }
    }

    // ---- Series semanales -------------------------------------------------

    fun weeklyVolumeSeries(
        workouts: List<StatsWorkout>,
        weeks: Int = 8,
        now: LocalDate = LocalDate.now(),
        zone: ZoneId = ZoneId.systemDefault(),
        weekStartsOnMonday: Boolean = true
    ): List<Pair<LocalDate, Double>> {
        if (weeks <= 0) return emptyList()
        val thisWeek = startOfWeek(now, weekStartsOnMonday)
        return (weeks - 1 downTo 0).map { offset ->
            val start = thisWeek.minusWeeks(offset.toLong())
            val end = start.plusDays(7)
            val volume = workouts.filter {
                val d = dayOf(it.epochMillis, zone)
                !d.isBefore(start) && d.isBefore(end)
            }.sumOf { it.totalVolumeKg }
            start to volume
        }
    }

    fun weeklySessionSeries(
        workouts: List<StatsWorkout>,
        weeks: Int = 8,
        now: LocalDate = LocalDate.now(),
        zone: ZoneId = ZoneId.systemDefault(),
        weekStartsOnMonday: Boolean = true
    ): List<Pair<LocalDate, Int>> {
        if (weeks <= 0) return emptyList()
        val thisWeek = startOfWeek(now, weekStartsOnMonday)
        return (weeks - 1 downTo 0).map { offset ->
            val start = thisWeek.minusWeeks(offset.toLong())
            val end = start.plusDays(7)
            val count = workouts.count {
                val d = dayOf(it.epochMillis, zone)
                !d.isBefore(start) && d.isBefore(end)
            }
            start to count
        }
    }

    fun weeklyVolume(workouts: List<StatsWorkout>,
                     now: LocalDate = LocalDate.now(),
                     zone: ZoneId = ZoneId.systemDefault(),
                     weekStartsOnMonday: Boolean = true): Double {
        val start = startOfWeek(now, weekStartsOnMonday)
        return workouts.filter { !dayOf(it.epochMillis, zone).isBefore(start) }
            .sumOf { it.totalVolumeKg }
    }

    fun workoutCount(workouts: List<StatsWorkout>, days: Int = 30,
                     now: LocalDate = LocalDate.now(),
                     zone: ZoneId = ZoneId.systemDefault()): Int {
        val cutoff = now.minusDays(days.toLong())
        return workouts.count { !dayOf(it.epochMillis, zone).isBefore(cutoff) }
    }

    fun averageSessionMinutes(workouts: List<StatsWorkout>, days: Int = 30,
                              now: LocalDate = LocalDate.now(),
                              zone: ZoneId = ZoneId.systemDefault()): Double? {
        val cutoff = now.minusDays(days.toLong())
        val mins = workouts.filter { !dayOf(it.epochMillis, zone).isBefore(cutoff) }
            .map { it.durationMinutes }.filter { it > 0 }
        return if (mins.isEmpty()) null else mins.average()
    }

    fun workoutsThisMonth(workouts: List<StatsWorkout>,
                          externalDates: List<Long> = emptyList(),
                          now: LocalDate = LocalDate.now(),
                          zone: ZoneId = ZoneId.systemDefault()): Int {
        val start = now.withDayOfMonth(1)
        val end = start.plusMonths(1)
        val gym = workouts.count {
            val d = dayOf(it.epochMillis, zone)
            !d.isBefore(start) && d.isBefore(end)
        }
        val ext = externalDates.count {
            val d = dayOf(it, zone)
            !d.isBefore(start) && d.isBefore(end)
        }
        return gym + ext
    }

    /** Δ peso corporal últimos ~30 días (último − más cercano a hace 30d). */
    fun bodyWeightDelta30d(entries: List<Pair<Long, Double>>,
                           now: LocalDate = LocalDate.now(),
                           zone: ZoneId = ZoneId.systemDefault()): Double? {
        val latest = entries.maxByOrNull { it.first } ?: return null
        val cutoff = now.minusDays(30)
        val older = entries.filter { dayOf(it.first, zone) <= cutoff }
            .maxByOrNull { it.first } ?: return null
        return latest.second - older.second
    }

    // ---- Racha ------------------------------------------------------------

    /** Semanas consecutivas con ≥1 sesión (Repera o externa). */
    fun consecutiveWeekStreak(
        workoutDates: List<Long>,
        externalDates: List<Long> = emptyList(),
        weekStartsOnMonday: Boolean = true,
        now: LocalDate = LocalDate.now(),
        zone: ZoneId = ZoneId.systemDefault()
    ): Int {
        val active = (workoutDates + externalDates)
            .map { weekKey(dayOf(it, zone), weekStartsOnMonday) }.toSet()
        if (active.isEmpty()) return 0
        var streak = 0
        var cursor = now
        for (i in 0 until 520) {
            if (weekKey(cursor, weekStartsOnMonday) in active) {
                streak++
            } else if (i > 0) {
                break
            }
            cursor = cursor.minusDays(7)
        }
        return streak
    }

    // ---- Actividad diaria / heatmap ---------------------------------------

    fun dailyActivity(
        workouts: List<StatsWorkout>,
        external: List<ExternalDaySample> = emptyList(),
        zone: ZoneId = ZoneId.systemDefault()
    ): Map<LocalDate, DayActivityContribution> {
        val agg = mutableMapOf<LocalDate, Triple<Double, Double, Int>>()
        fun add(day: LocalDate, minutes: Double, volume: Double) {
            val row = agg[day] ?: Triple(0.0, 0.0, 0)
            agg[day] = Triple(row.first + maxOf(0.0, minutes),
                row.second + maxOf(0.0, volume), row.third + 1)
        }
        for (workout in workouts) {
            add(dayOf(workout.epochMillis, zone), workout.durationMinutes,
                workout.totalVolumeKg)
        }
        for (sample in external) {
            add(dayOf(sample.epochMillis, zone), sample.minutes, sample.volumeKg)
        }
        return agg.mapValues { (day, row) ->
            DayActivityContribution(day, row.first, row.second, row.third)
        }
    }

    /** Nivel 0…4 por cuartiles del valor (tiempo o volumen), como openGym. */
    fun heatmapLevel(value: Double, hasActivity: Boolean,
                     thresholds: Triple<Double, Double, Double>): Int {
        if (!hasActivity) return 0
        if (value <= 0) return 1
        if (value >= thresholds.third) return 4
        if (value >= thresholds.second) return 3
        if (value >= thresholds.first) return 2
        return 1
    }

    fun heatmapThresholds(values: List<Double>): Triple<Double, Double, Double> {
        val sorted = values.filter { it > 0 }.sorted()
        if (sorted.isEmpty()) return Triple(0.0, 0.0, 0.0)
        fun q(p: Double): Double =
            sorted[minOf(sorted.size - 1, (p * sorted.size).toInt())]
        return Triple(q(0.25), q(0.5), q(0.75))
    }

    // ---- Filtros por rango --------------------------------------------------

    fun filterWorkouts(workouts: List<StatsWorkout>, range: ProgressTimeRange,
                       weekStartsOnMonday: Boolean = true,
                       now: LocalDate = LocalDate.now(),
                       zone: ZoneId = ZoneId.systemDefault()): List<StatsWorkout> =
        workouts.filter { range.contains(dayOf(it.epochMillis, zone), now, weekStartsOnMonday) }

    fun filterWorkoutsInPreviousPeriod(
        workouts: List<StatsWorkout>, range: ProgressTimeRange,
        weekStartsOnMonday: Boolean = true,
        now: LocalDate = LocalDate.now(),
        zone: ZoneId = ZoneId.systemDefault()
    ): List<StatsWorkout> = workouts.filter {
        range.containsInPreviousPeriod(dayOf(it.epochMillis, zone), now, weekStartsOnMonday)
    }

    fun filterExternal(samples: List<ExternalDaySample>, range: ProgressTimeRange,
                       weekStartsOnMonday: Boolean = true,
                       now: LocalDate = LocalDate.now(),
                       zone: ZoneId = ZoneId.systemDefault()): List<ExternalDaySample> =
        samples.filter { range.contains(dayOf(it.epochMillis, zone), now, weekStartsOnMonday) }

    // ---- Series de métricas -------------------------------------------------

    /** Hoy/semana = día; mes/90/180 = semana; 360 = mes. */
    fun granularityForChart(range: ProgressTimeRange): ProgressSeriesGranularity =
        when (range) {
            ProgressTimeRange.TODAY, ProgressTimeRange.WEEK -> ProgressSeriesGranularity.DAY
            ProgressTimeRange.MONTH, ProgressTimeRange.DAYS_90,
            ProgressTimeRange.DAYS_180 -> ProgressSeriesGranularity.WEEK
            ProgressTimeRange.DAYS_360 -> ProgressSeriesGranularity.MONTH
        }

    /** Serie diaria de cardio (min) o kcal para gráficas de Progreso. */
    fun dailyMetricSeries(
        workouts: List<StatsWorkout>,
        external: List<ExternalDaySample> = emptyList(),
        metric: String, // "cardioMinutes" | "activeEnergyKcal"
        range: ProgressTimeRange = ProgressTimeRange.WEEK,
        weekStartsOnMonday: Boolean = true,
        now: LocalDate = LocalDate.now(),
        zone: ZoneId = ZoneId.systemDefault()
    ): List<ProgressDayPoint> {
        val start = range.startDate(now, weekStartsOnMonday)
        val buckets = sortedMapOf<LocalDate, Double>()
        val fillZeros = granularityForChart(range) == ProgressSeriesGranularity.DAY
        if (fillZeros) {
            var cursor = start
            var guard = 0
            while (!cursor.isAfter(now) && guard <= 120) {
                buckets[cursor] = 0.0
                cursor = cursor.plusDays(1)
                guard++
            }
        }
        fun add(day: LocalDate, value: Double) {
            if (day.isBefore(start) || day.isAfter(now)) return
            buckets[day] = (buckets[day] ?: 0.0) + value
        }
        for (workout in workouts) {
            val day = dayOf(workout.epochMillis, zone)
            when (metric) {
                "cardioMinutes" -> {
                    val isCardio = workout.exercises.any { it.muscleGroup == "Cardio" }
                    add(day, if (isCardio) maxOf(0.0, workout.durationMinutes) else 0.0)
                }
                "activeEnergyKcal" -> add(day, maxOf(0.0, workout.activeEnergyKcal ?: 0.0))
            }
        }
        for (sample in external) {
            val day = dayOf(sample.epochMillis, zone)
            when (metric) {
                "cardioMinutes" -> add(day, maxOf(0.0, sample.cardioMinutes))
                "activeEnergyKcal" -> add(day, maxOf(0.0, sample.activeEnergyKcal))
            }
        }
        return buckets.map { (day, value) -> ProgressDayPoint(day, value) }
    }

    /** Promedia puntos diarios por semana o mes (eje X = inicio del bucket). */
    fun averagedSeries(points: List<ProgressDayPoint>,
                       granularity: ProgressSeriesGranularity,
                       weekStartsOnMonday: Boolean = true): List<ProgressDayPoint> {
        if (granularity == ProgressSeriesGranularity.DAY || points.size <= 1) return points
        val groups = mutableMapOf<String, SeriesAcc>()
        for (point in points) {
            val key: String
            val bucketStart: LocalDate
            when (granularity) {
                ProgressSeriesGranularity.DAY -> {
                    key = point.day.toString(); bucketStart = point.day
                }
                ProgressSeriesGranularity.WEEK -> {
                    key = weekKey(point.day, weekStartsOnMonday)
                    bucketStart = startOfWeek(point.day, weekStartsOnMonday)
                }
                ProgressSeriesGranularity.MONTH -> {
                    val ym = YearMonth.from(point.day)
                    key = ym.toString(); bucketStart = ym.atDay(1)
                }
            }
            val acc = groups.getOrPut(key) { SeriesAcc(bucketStart, 0.0, 0) }
            acc.sum += point.value
            acc.count += 1
            if (bucketStart.isBefore(acc.date)) acc.date = bucketStart
        }
        return groups.values.map { acc ->
            ProgressDayPoint(acc.date, acc.sum / acc.count)
        }.sortedBy { it.day }
    }

    // ---- Resumen de salud ---------------------------------------------------

    fun progressHealthSummary(
        workouts: List<StatsWorkout>,
        external: List<ExternalDaySample> = emptyList(),
        range: ProgressTimeRange = ProgressTimeRange.WEEK,
        weekStartsOnMonday: Boolean = true,
        now: LocalDate = LocalDate.now(),
        zone: ZoneId = ZoneId.systemDefault(),
        applyRangeFilter: Boolean = true
    ): ProgressHealthSummary {
        val filteredW = if (applyRangeFilter)
            filterWorkouts(workouts, range, weekStartsOnMonday, now, zone) else workouts
        val filteredE = if (applyRangeFilter)
            filterExternal(external, range, weekStartsOnMonday, now, zone) else external

        val minutes = mutableListOf<Double>()
        val cardioMinutes = mutableListOf<Double>()
        var kcal = 0.0
        var volume = 0.0
        for (workout in filteredW) {
            if (workout.durationMinutes > 0) minutes.add(workout.durationMinutes)
            volume += maxOf(0.0, workout.totalVolumeKg)
            workout.activeEnergyKcal?.let { if (it > 0) kcal += it }
            val isCardio = workout.exercises.any { it.muscleGroup == "Cardio" }
            if (isCardio && workout.durationMinutes > 0) cardioMinutes.add(workout.durationMinutes)
        }
        for (sample in filteredE) {
            if (sample.minutes > 0) minutes.add(sample.minutes)
            volume += maxOf(0.0, sample.volumeKg)
            kcal += maxOf(0.0, sample.activeEnergyKcal)
            if (sample.cardioMinutes > 0) cardioMinutes.add(sample.cardioMinutes)
        }
        return ProgressHealthSummary(
            averageMinutes = if (minutes.isEmpty()) null else minutes.average(),
            totalKcal = kcal,
            averageCardioMinutes = if (cardioMinutes.isEmpty()) null else cardioMinutes.average(),
            volumeKg = volume,
            sessionCount = filteredW.size + filteredE.size
        )
    }

    // ---- Calendario ES ------------------------------------------------------

    fun isoWeekday(date: LocalDate): Int = date.dayOfWeek.value

    fun weekdayName(iso: Int): String = when (iso) {
        1 -> "Lunes"
        2 -> "Martes"
        3 -> "Miércoles"
        4 -> "Jueves"
        5 -> "Viernes"
        6 -> "Sábado"
        7 -> "Domingo"
        else -> "Día $iso"
    }

    /** Próxima fecha (incluido `from`) con ese weekday ISO. */
    fun nextDate(iso: Int, from: LocalDate = LocalDate.now()): LocalDate {
        for (offset in 0 until 7) {
            val d = from.plusDays(offset.toLong())
            if (isoWeekday(d) == iso) return d
        }
        return from
    }
}
