package dev.repera.mobile

import org.json.JSONArray
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

/** Métricas de la ficha de progreso por ejercicio
 *  (ExerciseProgressMetric de StatsEngine.swift). */
enum class ExerciseProgressMetric(val wire: String, val title: String) {
    TOP_SET("topSet", "Top set"),
    ESTIMATED_ONE_RM("estimatedOneRM", "1RM est."),
    EFFORT("effort", "Esfuerzo"),
    BEST_QUANTITY("bestQuantity", "Mejor"),
    TOTAL_QUANTITY("totalQuantity", "Total"),
    BEST_METERS("bestMeters", "m máx."),
    BEST_CALORIES("bestCalories", "cal máx."),
    TOTAL_METERS("totalMeters", "m total"),
    TOTAL_CALORIES("totalCalories", "cal total"),
    BEST_HOLD("bestHold", "Mejor sostén"),
    DURATION("duration", "Tiempo");

    companion object {
        /** Métricas útiles según estilo de apunte (available(for:) de iOS). */
        fun available(loggingStyle: String): List<ExerciseProgressMetric> =
            when (loggingStyle) {
                "loadAndReps" -> listOf(TOP_SET, ESTIMATED_ONE_RM, EFFORT)
                "repsOnly" -> listOf(BEST_QUANTITY, TOTAL_QUANTITY)
                "repsAndTime" -> listOf(BEST_QUANTITY, TOTAL_QUANTITY, DURATION)
                "machineWork" -> listOf(BEST_METERS, BEST_CALORIES,
                    TOTAL_METERS, TOTAL_CALORIES, DURATION)
                else -> listOf(TOP_SET, ESTIMATED_ONE_RM, EFFORT)
            }
    }
}

/** Rango de la ficha (ProgressRange de iOS). */
enum class ExerciseProgressRange(val wire: String, val title: String) {
    ONE_MONTH("oneMonth", "1M"),
    THREE_MONTHS("threeMonths", "3M"),
    ONE_YEAR("oneYear", "1A"),
    ALL("all", "Todo");

    fun startDate(now: LocalDate): LocalDate? = when (this) {
        ONE_MONTH -> now.minusMonths(1)
        THREE_MONTHS -> now.minusMonths(3)
        ONE_YEAR -> now.minusYears(1)
        ALL -> null
    }
}

data class ExerciseProgressPoint(
    val epochMillis: Long,
    val value: Double,
    val weightKg: Double? = null,
    val reps: Int? = null,
    val rir: Double? = null,
    val quantityUnit: String? = null,
    val durationSeconds: Int? = null
)

/** Serie temporal de la ficha de progreso de un ejercicio.
 *  Port de StatsEngine.exerciseProgressSeries (iOS) sobre el archivo JSON. */
object ExerciseProgressSeries {

    fun compute(
        archive: JSONArray,
        exerciseId: String,
        metric: ExerciseProgressMetric,
        range: ExerciseProgressRange,
        now: LocalDate = LocalDate.now(),
        zone: ZoneId = ZoneId.systemDefault()
    ): List<ExerciseProgressPoint> {
        val start = range.startDate(now)
        val points = mutableListOf<ExerciseProgressPoint>()
        for (w in 0 until archive.length()) {
            val workout = archive.optJSONObject(w) ?: continue
            val finishedRaw = workout.optString("finishedAt")
            val finished = workout.optString("phase") == "finished" ||
                (finishedRaw.isNotBlank() && finishedRaw != "null")
            if (!finished) continue
            val dateRaw = finishedRaw.takeIf { it.isNotBlank() && it != "null" }
                ?: workout.optString("startedAt")
                    .takeIf { it.isNotBlank() && it != "null" }
                ?: continue
            val millis = runCatching { Instant.parse(dateRaw).toEpochMilli() }
                .getOrNull() ?: continue
            val day = Instant.ofEpochMilli(millis).atZone(zone).toLocalDate()
            if (start != null && day.isBefore(start)) continue
            val movements = workout.optJSONArray("exercises") ?: continue
            // Apple exerciseProgressSeries: una sesion = un punto, uniendo todas las apariciones
            // del ejercicio (p. ej. EMOM y RFT del mismo movimiento).
            val occurrences = (0 until movements.length()).mapNotNull { movements.optJSONObject(it) }
                .filter { it.optJSONObject("exercise")?.optString("id").orEmpty() == exerciseId }
            if (occurrences.isEmpty()) continue
            for (n in 0 until 1) {
                val work = occurrences.flatMap {
                    WorkoutHistorySets.confirmedWorkSets(workout, it, includeWodPrescribed = true)
                }
                if (work.isEmpty()) continue
                when (metric) {
                    ExerciseProgressMetric.TOP_SET -> {
                        val best = work.maxByOrNull { it.weightKg ?: 0.0 }
                        val kg = best?.weightKg
                        if (best == null || kg == null || kg <= 0) continue
                        points.add(ExerciseProgressPoint(millis, kg,
                            weightKg = kg, reps = best.reps, rir = best.rir))
                    }
                    ExerciseProgressMetric.ESTIMATED_ONE_RM -> {
                        var bestE1 = 0.0
                        var bestSet: WorkoutHistorySets.EffectiveSet? = null
                        for (set in work) {
                            val weight = set.weightKg ?: continue
                            if (weight <= 0 || set.unit != "reps") continue
                            val e1 = weight * (1.0 + set.reps / 30.0)
                            if (e1 > bestE1) { bestE1 = e1; bestSet = set }
                        }
                        val best = bestSet ?: continue
                        if (bestE1 <= 0) continue
                        points.add(ExerciseProgressPoint(millis, bestE1,
                            weightKg = best.weightKg, reps = best.reps,
                            rir = best.rir))
                    }
                    ExerciseProgressMetric.EFFORT -> {
                        val rirs = work.mapNotNull { it.rir }
                        if (rirs.isEmpty()) continue
                        val avg = rirs.average()
                        points.add(ExerciseProgressPoint(millis, avg,
                            weightKg = work.mapNotNull { it.weightKg }.maxOrNull(),
                            rir = avg))
                    }
                    ExerciseProgressMetric.BEST_METERS,
                    ExerciseProgressMetric.BEST_CALORIES -> {
                        val unit = if (metric == ExerciseProgressMetric.BEST_METERS)
                            "m" else "cal"
                        val matching = work.filter { it.unit == unit && it.reps > 0 }
                        val best = matching.maxByOrNull { it.reps } ?: continue
                        points.add(ExerciseProgressPoint(millis,
                            best.reps.toDouble(), weightKg = best.weightKg,
                            reps = best.reps, rir = best.rir, quantityUnit = unit,
                            durationSeconds = best.durationSeconds))
                    }
                    ExerciseProgressMetric.TOTAL_METERS,
                    ExerciseProgressMetric.TOTAL_CALORIES -> {
                        val unit = if (metric == ExerciseProgressMetric.TOTAL_METERS)
                            "m" else "cal"
                        val matching = work.filter { it.unit == unit && it.reps > 0 }
                        if (matching.isEmpty()) continue
                        val total = matching.sumOf { it.reps }
                        points.add(ExerciseProgressPoint(millis, total.toDouble(),
                            reps = total, quantityUnit = unit))
                    }
                    ExerciseProgressMetric.BEST_QUANTITY -> {
                        val best = work.maxByOrNull { it.reps } ?: continue
                        points.add(ExerciseProgressPoint(millis,
                            best.reps.toDouble(), weightKg = best.weightKg,
                            reps = best.reps, rir = best.rir,
                            quantityUnit = best.unit,
                            durationSeconds = best.durationSeconds))
                    }
                    ExerciseProgressMetric.TOTAL_QUANTITY -> {
                        val total = work.sumOf { it.reps }
                        if (total <= 0) continue
                        points.add(ExerciseProgressPoint(millis, total.toDouble(),
                            reps = total, quantityUnit = work.first().unit))
                    }
                    ExerciseProgressMetric.BEST_HOLD -> {
                        val seconds = work.mapNotNull { it.durationSeconds }
                            .maxOrNull() ?: continue
                        if (seconds <= 0) continue
                        points.add(ExerciseProgressPoint(millis,
                            seconds.toDouble(), durationSeconds = seconds))
                    }
                    ExerciseProgressMetric.DURATION -> {
                        val totalSec = work.mapNotNull { it.durationSeconds }.sum()
                        if (totalSec <= 0) continue
                        points.add(ExerciseProgressPoint(millis,
                            totalSec.toDouble(), durationSeconds = totalSec))
                    }
                }
            }
        }
        return points.sortedBy { it.epochMillis }
    }
}
