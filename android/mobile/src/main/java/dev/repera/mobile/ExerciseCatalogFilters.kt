package dev.repera.mobile

import dev.repera.domain.ExerciseAliasSearch

/** Curated discovery tags; never rewrite or replace iOS sportTag with Hyrox. */
object ExerciseCatalogFilters {
    // Apple (live main) HyroxExercises.matchingNames, en la forma ya normalizada por
    // ExerciseAliasSearch.normalize (sin diacríticos, minúsculas, puntuación como espacio).
    private val hyrox = setOf(
        // iOS renamed "Carrera" to "Run" in the seed; both kept for older snapshots.
        "skierg", "esqui ergometro", "remo maquina", "remoergometro", "rowerg", "rowing",
        "carrera", "cinta carrera", "run", "running",
        "sled push", "empuje de trineo", "sled pull", "arrastre de trineo",
        "farmer carry", "farmer walk", "farmers carry", "paseo del granjero",
        "burpee broad jump", "burpee broad jumps",
        "burpee con salto de longitud", "burpees con salto de longitud",
        "sandbag lunges", "sandbag lunge", "zancadas con saco",
        "wall ball", "wall balls", "lanzamiento de balon a pared"
    )

    fun isHyroxTrainingMovement(name: String): Boolean =
        ExerciseAliasSearch.normalize(name) in hyrox

    fun matches(entry: ExerciseEntry, filter: String): Boolean = when (filter) {
        "Todos", "Favoritos" -> true
        "Hyrox", "HYROX" -> entry.hyroxTraining ||
            entry.sportTag.equals("HYROX", ignoreCase = true)
        "Cardio" -> entry.muscleGroup.equals("Cardio", ignoreCase = true) ||
            entry.loggingStyle == "machineWork" || entry.loggingStyle == "repsAndTime"
        else -> entry.sportTag.equals(filter, ignoreCase = true)
    }

    fun available(entries: List<ExerciseEntry>): List<String> {
        val fixed = listOf("Todos", "Cardio", "Hyrox")
        val tags = entries.mapNotNull { it.sportTag }.distinct()
            .filterNot { tag -> fixed.any { it.equals(tag, ignoreCase = true) } }.sorted()
        val filters = fixed + tags
        return filters.distinct().filter { it == "Todos" || entries.any { entry -> matches(entry, it) } }
    }
}
