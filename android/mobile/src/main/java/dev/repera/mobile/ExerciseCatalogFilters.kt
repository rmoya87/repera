package dev.repera.mobile

import dev.repera.domain.ExerciseAliasSearch

/** Curated discovery tags; never rewrite or replace iOS sportTag with Hyrox. */
object ExerciseCatalogFilters {
    private val hyrox = setOf(
        // iOS renamed "Carrera" to "Run" in the seed; both kept for older snapshots.
        "skierg", "remo maquina", "carrera", "cinta carrera", "run",
        "sled push", "sled pull", "farmer carry", "farmer walk",
        "burpee broad jump", "sandbag lunges", "wall ball"
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
