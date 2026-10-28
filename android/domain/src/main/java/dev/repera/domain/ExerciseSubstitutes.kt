package dev.repera.domain

/** Sugiere ejercicios alternativos del mismo músculo / target.
 *  Port 1:1 de ExerciseSubstitutes.swift (iOS). */
object ExerciseSubstitutes {

    /** Vista mínima del ejercicio para puntuar sustitutos (el catálogo
     *  Android vive como JSON en mobile; el dominio puntúa esta forma). */
    data class Candidate(
        val id: String,
        val name: String,
        val targetMuscle: String?,
        val muscleGroup: String,
        val equipment: String?,
        val bodyPart: String?
    )

    fun substitutes(
        forExercise: Candidate,
        catalog: List<Candidate>,
        limit: Int = 12
    ): List<Candidate> {
        val target = forExercise.targetMuscle
        val muscle = forExercise.muscleGroup
        return catalog
            .filter { it.id != forExercise.id }
            .map { candidate ->
                var score = 0
                if (target != null && candidate.targetMuscle == target) score += 3
                if (candidate.muscleGroup == muscle) score += 2
                if (candidate.equipment != null && candidate.equipment == forExercise.equipment) score += 1
                if (candidate.bodyPart != null && candidate.bodyPart == forExercise.bodyPart) score += 1
                candidate to score
            }
            .filter { it.second >= 2 }
            .sortedWith(
                compareByDescending<Pair<Candidate, Int>> { it.second }
                    .thenBy { it.first.name.lowercase() }
            )
            .take(limit)
            .map { it.first }
    }
}
