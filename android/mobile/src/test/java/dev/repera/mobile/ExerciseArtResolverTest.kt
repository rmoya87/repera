package dev.repera.mobile

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ExerciseArtResolverTest {
    private val noAliases = emptyMap<String, String>()

    @Test fun exactCatalogNameResolvesItsHero() {
        assertEquals("art_press_banca",
            ExerciseArtResolver.heroFor("Press banca", isMobility = false, aliases = noAliases))
    }

    @Test fun aliasTableResolvesEnglishNameToSpanishHero() {
        val aliases = mapOf("bench press" to "Press banca")
        assertEquals("art_press_banca",
            ExerciseArtResolver.heroFor("bench press", isMobility = false, aliases = aliases))
    }

    @Test fun normalizedKeyMatchIgnoresCaseAndDiacritics() {
        assertEquals("art_dominadas",
            ExerciseArtResolver.heroFor("DOMINADAS", isMobility = false, aliases = noAliases))
    }

    @Test fun mobilityNeverFallsBackToFuzzyReuse() {
        assertNull(ExerciseArtResolver.heroFor(
            "Respiración 90/90 con lift-off inexistente", isMobility = true, aliases = noAliases))
    }

    @Test fun unknownNameResolvesNothing() {
        assertNull(ExerciseArtResolver.heroFor(
            "movimiento inventado xyz", isMobility = false, aliases = noAliases))
    }

    @Test fun staticHoldsKeepASingleFrame() {
        val hero = "art_gy_hs_hold"
        val frames = ExerciseArtResolver.framesFor("Handstand hold", hero) { true }
        assertEquals(listOf(hero), frames)
    }

    @Test fun numberedStepsReplaceTheHeroWhenAtLeastTwoExist() {
        // iOS imageNames(for:): the carousel is the numbered steps, hero out.
        val bundled = setOf("art_press_banca", "art_press_banca_1", "art_press_banca_2")
        val frames = ExerciseArtResolver.framesFor("Press banca", "art_press_banca") {
            it in bundled
        }
        assertEquals(listOf("art_press_banca_1", "art_press_banca_2"), frames)
    }

    @Test fun aSingleNumberedStepKeepsTheHero() {
        val bundled = setOf("art_dominadas", "art_dominadas_1")
        val frames = ExerciseArtResolver.framesFor("Dominadas", "art_dominadas") {
            it in bundled
        }
        assertEquals(listOf("art_dominadas"), frames)
    }

    @Test fun everyNameMapAndFrameStemIsBundledNamingShape() {
        val stems = ExerciseArtData.nameMap.values + ExerciseArtData.movementFrames.values.flatten()
        assertTrue(stems.isNotEmpty())
        assertTrue(stems.all { it.matches(Regex("art_[a-z0-9_]+")) })
        assertEquals(stems.size, stems.toSet().size + (stems.size - stems.toSet().size))
    }
}
