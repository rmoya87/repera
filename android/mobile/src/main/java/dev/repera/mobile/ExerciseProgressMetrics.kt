package dev.repera.mobile

/** Aggregates the same effective sets as iOS StatsEngine.history, across ALL saved workouts. */
data class ExerciseProgressSummary(
    val timesPerformed: Int,
    val maxWeightKg: Double?,
    val repsAtMaxWeight: Int?,
    val estimatedOneRM: Double?,
    val bestReps: Int?,
    val bestCalories: Int?,
    val bestMeters: Int?,
    val bestDurationSeconds: Int?,
    val lastDate: String?
)

internal object ExerciseProgressMetrics {
    private class Accumulator {
        var times = 0
        var maxWeight = 0.0
        var repsAtMaxWeight = 0
        var bestE1RM = 0.0
        var bestReps = 0
        var bestCalories = 0
        var bestMeters = 0
        var bestDurationSeconds = 0
        var lastDate: String? = null

        fun add(sets: List<WorkoutHistorySets.EffectiveSet>, date: String?) {
            if (sets.isEmpty()) return
            times++
            if (!date.isNullOrBlank() && (lastDate == null || date > lastDate!!)) lastDate = date
            sets.forEach { set ->
                if (set.durationSeconds != null)
                    bestDurationSeconds = maxOf(bestDurationSeconds, set.durationSeconds)
                when (set.unit) {
                    "cal" -> bestCalories = maxOf(bestCalories, set.reps)
                    "m" -> bestMeters = maxOf(bestMeters, set.reps)
                    else -> if (!set.mobilityHold)
                        bestReps = maxOf(bestReps, set.reps)
                }
                val weight = set.weightKg
                if (weight != null && weight > 0) {
                    // Carries and sleds have kg + metres; metres are not reps and
                    // must never be fed into Epley estimated one-rep-max.
                    if (set.unit == "reps") {
                        bestE1RM = maxOf(bestE1RM, weight * (1.0 + set.reps / 30.0))
                    }
                    if (weight > maxWeight ||
                        (kotlin.math.abs(weight - maxWeight) < 0.05 &&
                            set.unit == "reps" && set.reps > repsAtMaxWeight)) {
                        maxWeight = weight
                        repsAtMaxWeight = if (set.unit == "reps") set.reps else 0
                    }
                }
            }
        }

        fun summary() = ExerciseProgressSummary(
            timesPerformed = times,
            maxWeightKg = maxWeight.takeIf { it > 0 },
            repsAtMaxWeight = repsAtMaxWeight.takeIf { maxWeight > 0 },
            estimatedOneRM = bestE1RM.takeIf { it > 0 },
            bestReps = bestReps.takeIf { it > 0 },
            bestCalories = bestCalories.takeIf { it > 0 },
            bestMeters = bestMeters.takeIf { it > 0 },
            bestDurationSeconds = bestDurationSeconds.takeIf { it > 0 },
            lastDate = lastDate
        )
    }

    fun fromWorkouts(workouts: org.json.JSONArray): Map<String, ExerciseProgressSummary> {
        val byExercise = linkedMapOf<String, Accumulator>()
        for (w in 0 until workouts.length()) {
            val workout = workouts.optJSONObject(w) ?: continue
            val movements = workout.optJSONArray("exercises") ?: continue
            val grouped = linkedMapOf<String, MutableList<WorkoutHistorySets.EffectiveSet>>()
            for (i in 0 until movements.length()) {
                val exercise = movements.optJSONObject(i) ?: continue
                val id = exercise.optJSONObject("exercise")?.optString("id").orEmpty()
                if (id.isBlank()) continue
                val effective = WorkoutHistorySets.effectiveWorkSets(workout, exercise)
                if (effective.isNotEmpty()) grouped.getOrPut(id) { mutableListOf() }.addAll(effective)
            }
            val date = workout.optString("finishedAt").takeUnless { it.isBlank() || it == "null" }
                ?: workout.optString("startedAt").takeUnless { it.isBlank() || it == "null" }
            grouped.forEach { (id, sets) ->
                byExercise.getOrPut(id) { Accumulator() }.add(sets, date)
            }
        }
        return byExercise.mapValues { (_, value) -> value.summary() }
    }
}
