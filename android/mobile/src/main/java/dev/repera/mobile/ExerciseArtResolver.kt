package dev.repera.mobile

import dev.repera.domain.ExerciseAliasSearch

/**
 * Resolution of exercise names to bundled art stems, following the iOS
 * ExerciseArt chain for catalog browsing: exact nameMap hit, alias-table hit
 * (the same EN↔ES assets the search uses), normalized-key match and finally
 * the longest contained key. Mobility never falls back to fuzzy reuse.
 * Board-noise cleanup (CrossFitGlossary.canonicalName) belongs to the scanner
 * phase and is deliberately not reproduced here.
 */
internal object ExerciseArtResolver {

    fun heroFor(name: String, isMobility: Boolean, aliases: Map<String, String>): String? {
        ExerciseArtData.nameMap[name]?.let { return accepted(it) }
        aliases[ExerciseAliasSearch.normalize(name)]
            ?.let { ExerciseArtData.nameMap[it] }
            ?.let { return accepted(it) }
        if (isMobility) return null
        val needle = ExerciseAliasSearch.normalize(name)
        if (needle.isEmpty()) return null
        for ((key, base) in ExerciseArtData.nameMap) {
            if (ExerciseAliasSearch.normalize(key) == needle) return accepted(base)
        }
        if (needle.length < 3) return null
        var best: Pair<Int, String>? = null
        for ((key, base) in ExerciseArtData.nameMap) {
            val nk = ExerciseAliasSearch.normalize(key)
            if (nk.length < 3) continue
            if (!needle.contains(nk) && !nk.contains(needle)) continue
            val hit = accepted(base) ?: continue
            if (best == null || nk.length > best!!.first) best = nk.length to hit
        }
        return best?.second
    }

    /**
     * Carousel stems for the ficha, mirroring iOS imageNames(for:): numbered
     * hero_1..hero_8 steps probed in order REPLACE the hero when at least two
     * exist; static holds and quarantined sequences keep the single hero.
     * The movementFrames table is carried as data but, exactly as in iOS
     * today, no exercise is verified to use it.
     *
     * @param exists asset-existence probe, e.g. assets list("exercise-art").
     */
    fun framesFor(name: String, hero: String, exists: (String) -> Boolean): List<String> {
        if (name in ExerciseArtData.staticHoldExercises) return listOf(hero)
        if (hero in ExerciseArtData.quarantinedSequences) return listOf(hero)
        val numbered = (1..8).asSequence().map { "${hero}_$it" }.takeWhile { exists(it) }.toList()
        return if (numbered.size >= 2) numbered else listOf(hero)
    }

    private fun accepted(base: String?): String? =
        base?.takeIf { it.isNotEmpty() && it !in ExerciseArtData.quarantinedHeroes }
}
