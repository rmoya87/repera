package dev.repera.mobile

import dev.repera.domain.CrossFitGlossary
import dev.repera.domain.ExerciseAliasSearch
import dev.repera.domain.SportExerciseNames

/**
 * Resolution of exercise names to bundled art stems, port of the current iOS
 * ExerciseArt chain (origin/main): exact nameMap hit → SportExerciseNames
 * legacy ES alias → CrossFitGlossary.canonicalName → cleanMovementLabel →
 * normalized-key equality over those needles → longest contained key.
 * Mobility only matches its own art exactly (or via legacy alias), never
 * fuzzy; "bbjo"/burpee-box-over variants share art_cf_burpee_box as in iOS.
 */
internal object ExerciseArtResolver {

    fun heroFor(name: String, isMobility: Boolean, aliases: Map<String, String>): String? {
        if (isMobility) {
            ExerciseArtData.nameMap[name]?.let { return accepted(it) }
            val legacyMob = SportExerciseNames.spanishAlias(name) ?: name
            if (legacyMob != name) ExerciseArtData.nameMap[legacyMob]?.let { return accepted(it) }
            return null
        }
        val normalizedName = CrossFitGlossary.normalize(name)
        if (normalizedName == "bbjo" || (normalizedName.contains("burpee") &&
                normalizedName.contains("box") &&
                (normalizedName.contains("over") || normalizedName.contains("jump")))) {
            accepted("art_cf_burpee_box")?.let { return it }
        }
        ExerciseArtData.nameMap[name]?.let { return accepted(it) }
        val legacy = SportExerciseNames.spanishAlias(name) ?: name
        ExerciseArtData.nameMap[legacy]?.let { return accepted(it) }
        val canonical = CrossFitGlossary.canonicalName(legacy)
        ExerciseArtData.nameMap[canonical]?.let { return accepted(it) }
        val cleaned = CrossFitGlossary.cleanMovementLabel(legacy)
        if (cleaned != name) ExerciseArtData.nameMap[cleaned]?.let { return accepted(it) }
        val needles = listOf(name, legacy, canonical, cleaned)
            .map { CrossFitGlossary.normalize(it) }.filter { it.isNotEmpty() }.toSet()
        for (needle in needles) {
            for ((key, base) in ExerciseArtData.nameMap) {
                if (CrossFitGlossary.normalize(key) == needle) {
                    accepted(base)?.let { return it }
                }
            }
        }
        val haystack = CrossFitGlossary.normalize(
            listOf(cleaned, canonical, legacy, name).firstOrNull { it.isNotEmpty() } ?: name)
        if (haystack.length < 3) return null
        var best: Pair<Int, String>? = null
        for ((key, base) in ExerciseArtData.nameMap) {
            val nk = CrossFitGlossary.normalize(key)
            if (nk.length < 3) continue
            if (!haystack.contains(nk) && !nk.contains(haystack)) continue
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
    fun framesFor(name: String, hero: String, captionCount: Int = Int.MAX_VALUE,
                  exists: (String) -> Boolean): List<String> {
        if (name in ExerciseArtData.staticHoldExercises) return listOf(hero)
        if (hero in ExerciseArtData.quarantinedSequences) return listOf(hero)
        val numbered = (1..8).asSequence().map { "${hero}_$it" }.takeWhile { exists(it) }.toList()
        // iOS: el carrusel exige captions de fase suficientes; si no, hero solo.
        if (numbered.size >= 2 && captionCount < numbered.size) return listOf(hero)
        return if (numbered.size >= 2) numbered else listOf(hero)
    }

    private fun accepted(base: String?): String? =
        base?.takeIf { it.isNotEmpty() && it !in ExerciseArtData.quarantinedHeroes }
}
