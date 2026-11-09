package dev.repera.domain

/** Actual logged sets of 3+, 5+ and 10+ reps. Not a tested 1RM or e1RM. */
data class StrengthRepRecord(
    val minimumReps: Int,
    val bestWeightKg: Double,
    val achievedReps: Int,
    val sessionId: String?,
    val epochMillis: Long
)

object StrengthRepRecordEngine {
    fun bestSets(
        exerciseId: String, workouts: List<StatsWorkout>,
        targets: List<Int> = listOf(3, 5, 10)
    ): List<StrengthRepRecord> {
        val best = mutableMapOf<Int, StrengthRepRecord>()
        val dedup = workouts.filter { it.finished }
            .sortedBy { it.epochMillis }
            .distinctBy { it.sessionId ?: "legacy-${it.epochMillis}-${it.exercises.hashCode()}" }
        for (workout in dedup) {
            for (exercise in workout.exercises.filter { it.exerciseId == exerciseId }) {
                for (set in exercise.sets) {
                    val kg = set.weightKg
                    if (set.isWarmup || set.fromPrescription ||
                        set.quantityUnit == "meters" || set.quantityUnit == "calories" ||
                        set.deficitCm != null || kg == null || !kg.isFinite() || kg <= 0 ||
                        set.reps <= 0) continue
                    for (target in targets.filter { it > 0 && set.reps >= it }) {
                        val previous = best[target]
                        if (previous != null && previous.bestWeightKg > kg) continue
                        best[target] = StrengthRepRecord(
                            target, kg, set.reps, workout.sessionId, workout.epochMillis
                        )
                    }
                }
            }
        }
        return targets.mapNotNull { best[it] }
    }
}
