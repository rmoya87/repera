package dev.repera.domain

import kotlin.math.max
import kotlin.math.min
import kotlin.math.round

enum class ProgressionPolicy(val wire: String, val displayName: String, val detail: String) {
    OFF("off", "Sin progresión", "Los objetivos se quedan como los dejas."),
    LINEAR("linear", "Lineal",
        "Si completas todas las reps, sube el peso. Fallos seguidos → deload."),
    DOUBLE("double", "Doble (rango de reps)",
        "Sube reps en el rango; al llegar al tope, sube peso y vuelve al mínimo."),
    GREYSKULL("greyskull", "Greyskull LP",
        "Series fijas + última al fallo. Si bates el objetivo en la AMRAP, " +
            "sube peso (el doble si doblas reps). Un fallo → deload 10%."),
    TRIPLE("triple", "Triple progresión",
        "Sube reps → luego añade series → luego peso, y reinicia reps/series.");

    companion object {
        fun fromWire(wire: String): ProgressionPolicy? =
            entries.firstOrNull { it.wire == wire }
    }
}

data class ProgressionSuggestion(
    val weightKg: Double?,
    val reps: Int,
    val setCount: Int,
    val reason: String
)

/** Serie planificada mínima para la progresión. */
data class PlannedTarget(val targetReps: Int, val targetWeightKg: Double? = null)

/**
 * Motor de progresión de fuerza. Port 1:1 de ProgressionEngine.swift (iOS).
 * El historial llega como StatsWorkout (mismo archivo que StatsEngine).
 */
object ProgressionEngine {
    const val defaultIncrementKg = 2.5
    const val deloadFactor = 0.9
    const val deloadAfterMisses = 3
    const val doubleRepMin = 6
    const val doubleRepMax = 12
    const val tripleMinSets = 3
    const val tripleMaxSets = 5

    fun suggest(
        exerciseId: String,
        planned: List<PlannedTarget>,
        policy: ProgressionPolicy,
        workouts: List<StatsWorkout>,
        incrementKg: Double = defaultIncrementKg
    ): ProgressionSuggestion {
        val baselineReps = planned.firstOrNull()?.targetReps ?: 8
        val baselineSets = max(planned.size, 1)
        val baselineWeight = planned.firstOrNull()?.targetWeightKg
            ?: lastWorkingWeight(exerciseId, workouts)

        if (policy == ProgressionPolicy.OFF) {
            return ProgressionSuggestion(baselineWeight, baselineReps, baselineSets,
                "Progresión desactivada — se mantienen los objetivos del plan.")
        }

        val history = recentPerformances(exerciseId, workouts)
        val last = history.firstOrNull()
            ?: return ProgressionSuggestion(baselineWeight, baselineReps,
                max(baselineSets, if (policy == ProgressionPolicy.GREYSKULL) 3 else baselineSets),
                "Primera vez con este ejercicio — usa el peso del plan.")

        return when (policy) {
            ProgressionPolicy.OFF -> ProgressionSuggestion(
                baselineWeight, baselineReps, baselineSets, "Progresión desactivada.")
            ProgressionPolicy.LINEAR -> linearSuggest(
                last, history, baselineWeight, baselineReps, baselineSets, incrementKg)
            ProgressionPolicy.DOUBLE -> doubleSuggest(
                last, baselineWeight, baselineSets, incrementKg)
            ProgressionPolicy.GREYSKULL -> greyskullSuggest(
                last, baselineWeight, baselineReps, max(baselineSets, 3), incrementKg)
            ProgressionPolicy.TRIPLE -> tripleSuggest(
                last, baselineWeight, baselineReps, baselineSets, incrementKg)
        }
    }

    // ---- Políticas ---------------------------------------------------------

    private fun linearSuggest(
        last: Performance, history: List<Performance>,
        baselineWeight: Double?, baselineReps: Int, baselineSets: Int,
        incrementKg: Double
    ): ProgressionSuggestion {
        val weight = last.averageWeight ?: baselineWeight ?: 0.0
        if (last.hitAll) {
            val next = snap(weight + incrementKg, incrementKg)
            return ProgressionSuggestion(next, baselineReps, baselineSets,
                "Hit completo la última vez → +${format(incrementKg)} kg.")
        }
        val missStreak = history.take(deloadAfterMisses).takeWhile { !it.hitAll }.size
        if (missStreak >= deloadAfterMisses) {
            val deloaded = snap(weight * deloadFactor, incrementKg)
            return ProgressionSuggestion(deloaded, baselineReps, baselineSets,
                "$missStreak fallos seguidos → deload ${(deloadFactor * 100).toInt()}%.")
        }
        return ProgressionSuggestion(
            if (weight > 0) weight else baselineWeight,
            baselineReps, baselineSets,
            "No se completaron todas las reps — se mantiene el peso.")
    }

    private fun doubleSuggest(
        last: Performance, baselineWeight: Double?, baselineSets: Int,
        incrementKg: Double
    ): ProgressionSuggestion {
        val weight = last.averageWeight ?: baselineWeight ?: 0.0
        val lastReps = last.minRepsAcrossSets ?: doubleRepMin
        if (last.hitAll && lastReps >= doubleRepMax) {
            val next = snap(weight + incrementKg, incrementKg)
            return ProgressionSuggestion(next, doubleRepMin, baselineSets,
                "Rango completo ($doubleRepMax) → +${format(incrementKg)} kg y reps a $doubleRepMin.")
        }
        if (last.hitAll) {
            val nextReps = min(doubleRepMax, lastReps + 1)
            return ProgressionSuggestion(
                if (weight > 0) weight else baselineWeight,
                nextReps, baselineSets,
                "Hit → reps $lastReps→$nextReps (rango $doubleRepMin–$doubleRepMax).")
        }
        return ProgressionSuggestion(
            if (weight > 0) weight else baselineWeight,
            max(doubleRepMin, lastReps), baselineSets,
            "Fallaste el rango — se mantienen peso y reps.")
    }

    private fun greyskullSuggest(
        last: Performance, baselineWeight: Double?, baselineReps: Int,
        baselineSets: Int, incrementKg: Double
    ): ProgressionSuggestion {
        val weight = last.averageWeight ?: baselineWeight ?: 0.0
        val sets = max(baselineSets, 3)
        if (!last.greyskullStraightHits) {
            val deloaded = snap(max(weight, 0.0) * deloadFactor, incrementKg)
            return ProgressionSuggestion(deloaded, baselineReps, sets,
                "Greyskull: fallaste series fijas → deload 10%.")
        }
        val amrap = last.lastSetReps
            ?: return ProgressionSuggestion(
                if (weight > 0) weight else baselineWeight,
                baselineReps, sets,
                "Greyskull: sin AMRAP registrada — se mantiene el peso.")
        if (amrap >= baselineReps * 2) {
            val next = snap(weight + incrementKg * 2, incrementKg)
            return ProgressionSuggestion(next, baselineReps, sets,
                "Greyskull: AMRAP $amrap (≥2×) → +${format(incrementKg * 2)} kg.")
        }
        if (amrap > baselineReps) {
            val next = snap(weight + incrementKg, incrementKg)
            return ProgressionSuggestion(next, baselineReps, sets,
                "Greyskull: AMRAP $amrap > $baselineReps → +${format(incrementKg)} kg.")
        }
        return ProgressionSuggestion(
            if (weight > 0) weight else baselineWeight,
            baselineReps, sets,
            "Greyskull: AMRAP $amrap no superó el objetivo — mismo peso.")
    }

    private fun tripleSuggest(
        last: Performance, baselineWeight: Double?, baselineReps: Int,
        baselineSets: Int, incrementKg: Double
    ): ProgressionSuggestion {
        val weight = last.averageWeight ?: baselineWeight ?: 0.0
        val reps = last.minRepsAcrossSets ?: max(baselineReps, doubleRepMin)
        val sets = maxOf(last.setCount, baselineSets, tripleMinSets)
        if (!last.hitAll) {
            return ProgressionSuggestion(
                if (weight > 0) weight else baselineWeight,
                max(doubleRepMin, min(reps, doubleRepMax)),
                min(sets, tripleMaxSets),
                "Triple: no hit — se mantienen reps/series/peso.")
        }
        if (reps < doubleRepMax) {
            return ProgressionSuggestion(
                if (weight > 0) weight else baselineWeight,
                reps + 1, min(sets, tripleMaxSets),
                "Triple: hit → reps $reps→${reps + 1}.")
        }
        if (sets < tripleMaxSets) {
            return ProgressionSuggestion(
                if (weight > 0) weight else baselineWeight,
                doubleRepMax, sets + 1,
                "Triple: tope de reps → +1 serie ($sets)→${sets + 1}.")
        }
        val next = snap(weight + incrementKg, incrementKg)
        return ProgressionSuggestion(next, doubleRepMin, tripleMinSets,
            "Triple: tope series+reps → +${format(incrementKg)} kg y reinicio " +
                "${tripleMinSets}×${doubleRepMin}.")
    }

    // ---- Historial ----------------------------------------------------------

    private class Performance(
        val hitAll: Boolean,
        val averageWeight: Double?,
        val minRepsAcrossSets: Int?,
        val lastSetReps: Int?,
        val setCount: Int,
        val greyskullStraightHits: Boolean
    )

    private fun recentPerformances(
        exerciseId: String,
        workouts: List<StatsWorkout>
    ): List<Performance> =
        workouts.sortedByDescending { it.epochMillis }
            .mapNotNull { workout ->
                val entry = workout.exercises.firstOrNull {
                    it.exerciseId == exerciseId
                } ?: return@mapNotNull null
                // countsForProgression = phase == .work (no calentamiento).
                val workSets = entry.sets.filter { !it.isWarmup }
                if (workSets.isEmpty()) return@mapNotNull null
                // iOS: plannedSets.first.targetReps, con fallback al máximo logrado.
                val target = entry.plannedTargetReps?.takeIf { it > 0 }
                    ?: workSets.maxOf { it.reps }
                val setCountTarget = max(
                    if (entry.plannedSetCount > 0) entry.plannedSetCount else 0, 1)
                val hitSets = workSets.filter { it.reps >= target }
                val hitAll = hitSets.size >= setCountTarget &&
                    workSets.size >= setCountTarget
                val weights = workSets.mapNotNull { it.weightKg }.filter { it > 0 }
                val avg = if (weights.isEmpty()) null else weights.average()
                val straight = if (workSets.size < 2) {
                    workSets.firstOrNull()?.let { it.reps >= target } ?: false
                } else {
                    workSets.dropLast(1).all { it.reps >= target }
                }
                Performance(
                    hitAll = hitAll,
                    averageWeight = avg,
                    minRepsAcrossSets = workSets.minOf { it.reps },
                    lastSetReps = workSets.lastOrNull()?.reps,
                    setCount = workSets.size,
                    greyskullStraightHits = straight
                )
            }

    private fun lastWorkingWeight(
        exerciseId: String,
        workouts: List<StatsWorkout>
    ): Double? =
        workouts.sortedByDescending { it.epochMillis }
            .firstNotNullOfOrNull { workout ->
                workout.exercises.firstOrNull { it.exerciseId == exerciseId }
                    ?.sets?.filter { !it.isWarmup }
                    ?.mapNotNull { it.weightKg }
                    ?.filter { it > 0 }
                    ?.lastOrNull()
            }

    private fun snap(value: Double, step: Double): Double =
        if (step <= 0) round(value * 10) / 10 else round(value / step) * step

    private fun format(value: Double): String =
        if (value % 1.0 == 0.0) value.toInt().toString() else value.toString()
}
