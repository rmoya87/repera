package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Test

/** e048d814 (en ventana): aliases BTT/T2B añadidos por Apple a SportExerciseNames. */
class SportExerciseNamesBttAliasesTest {
    @Test fun newBttAndT2bVariantsResolveToCanonical() {
        for ((alias, canonical) in listOf(
            "t2bs" to "Toes to bar", "t 2 b" to "Toes to bar",
            "btt" to "Burpee to target", "burpee to target" to "Burpee to target",
            "burpees to target" to "Burpee to target", "burpee a diana" to "Burpee to target"
        )) {
            assertEquals(alias, canonical, SportExerciseNames.canonicalNameForSearchAlias(alias))
        }
    }

    @Test fun searchAliasesExposePublishedVariants() {
        val aliases = SportExerciseNames.searchAliases("Burpee to target")
        assertEquals(true, aliases.contains("btt"))
        assertEquals(true, aliases.contains("burpee a diana"))
        assertEquals(true, SportExerciseNames.searchAliases("Toes to bar").contains("t2bs"))
    }
}
