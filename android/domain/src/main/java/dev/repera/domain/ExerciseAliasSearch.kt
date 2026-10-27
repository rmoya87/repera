package dev.repera.domain

import java.text.Normalizer
import java.util.Locale

/**
 * Bilingual search ranking port: exact name first, then known English→Spanish aliases.
 * The alias table itself is generated from Swift ExerciseSearch.bilingualPhrases.
 */
object ExerciseAliasSearch {
    fun normalize(value: String): String = Normalizer.normalize(value, Normalizer.Form.NFD)
        .replace(Regex("\\p{Mn}+"), "")
        .lowercase(Locale.ROOT)
        .replace(Regex("[^a-z0-9]+"), " ")
        .trim()
        .replace(Regex("\\s+"), " ")

    fun score(query: String, exerciseName: String, aliases: Map<String, String>, extraTerms: String = ""): Int {
        val search = normalize(query)
        if (search.isBlank()) return 1
        val name = normalize(exerciseName)
        if (name == search) return 100
        if (name.startsWith(search)) return 85
        if (name.contains(search)) return 70
        val candidates = mutableListOf<String>()
        aliases[search]?.let { candidates += it }
        for ((key, target) in aliases) {
            if (normalize(key) == search || normalize(key).startsWith("$search ")) {
                candidates += target
            }
        }
        val bestAlias = candidates.map { normalize(it) }.maxOfOrNull { alias ->
            when {
                name == alias -> 95
                name.startsWith(alias) -> 80
                name.contains(alias) -> 60
                else -> -1
            }
        } ?: -1
        if (bestAlias >= 0) return bestAlias
        val tokens = search.split(" ").filter { it.isNotEmpty() }
        if (tokens.all { name.contains(it) }) return 50
        // Apple (live main) ExerciseSearch: disciplineTags joined into the meta field
        // (perTokenInMeta, below every name/alias weight). Android carries the HYROX
        // discipline on ExerciseEntry.hyroxTraining; call sites pass it here.
        if (extraTerms.isNotBlank()) {
            val extra = normalize(extraTerms)
            if (tokens.all { extra.contains(it) }) return 40
        }
        return -1
    }
}
