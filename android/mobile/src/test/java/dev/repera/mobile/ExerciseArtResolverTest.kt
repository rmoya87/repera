package dev.repera.mobile

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ExerciseArtResolverTest {
    private val noAliases = emptyMap<String, String>()

    @Test fun exactCatalogNameResolvesItsHero() {
        assertEquals("art_press_banca",
            ExerciseArtResolver.heroFor("Press banca", isMobility = false, aliases = noAliases))
    }

    @Test fun legacyAliasResolvesEnglishSportNameToSpanishHero() {
        // Cadena iOS: "Snatch" → SportExerciseNames.spanishAlias → "Arrancada" → nameMap.
        assertEquals("art_cf_arrancada",
            ExerciseArtResolver.heroFor("Snatch", isMobility = false, aliases = noAliases))
    }

    @Test fun jerkDipAndDriveHasNoArtYetLikeIos() {
        // Entrada nueva del catálogo iOS sin stem propio ni clave nameMap alcanzable;
        // iOS tampoco resuelve arte para ella (hueco compartido, no regresión Android).
        assertNull(ExerciseArtResolver.heroFor("Jerk Dip and Drive", false, emptyMap()))
    }

    @Test fun genericEnglishNameWithoutLegacyAliasDoesNotResolve() {
        // iOS no consulta la tabla de alias de búsqueda para el arte: "bench press"
        // sin entrada legacy queda sin héroe (paridad con ExerciseArt.swift).
        val aliases = mapOf("bench press" to "Press banca")
        assertNull(ExerciseArtResolver.heroFor("bench press", isMobility = false, aliases = aliases))
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

    @Test fun canonicalEnglishHalteroNamesResolveViaLegacyChain() {
        for (name in listOf("Snatch", "Hang Snatch", "Clean and Jerk", "Squat Jerk",
                "Snatch High Pull", "Clean High Pull", "Clean Deadlift",
                "Block Power Snatch", "Block Power Clean", "Snatch-Grip Push Press")) {
            assertNotNull(name + " sin hero", ExerciseArtResolver.heroFor(name, false, emptyMap()))
        }
    }

    @Test fun carouselRequiresEnoughPhaseCaptions_iosGate() {
        val exists = setOf("art_cf_manmaker", "art_cf_manmaker_1", "art_cf_manmaker_2",
            "art_cf_manmaker_3", "art_cf_manmaker_4", "art_cf_manmaker_5", "art_cf_manmaker_6")
        // Con captions suficientes: carrusel numerado.
        val frames = ExerciseArtResolver.framesFor("Man maker", "art_cf_manmaker",
            captionCount = 12) { it in exists }
        assertEquals(6, frames.size)
        assertEquals("art_cf_manmaker_1", frames.first())
        // Con menos captions que fases: degrada a hero (imageNames iOS).
        val degraded = ExerciseArtResolver.framesFor("Man maker", "art_cf_manmaker",
            captionCount = 3) { it in exists }
        assertEquals(listOf("art_cf_manmaker"), degraded)
    }

    @Test fun carouselWithoutNumberedFramesKeepsHero() {
        val exists = setOf("art_cf_pistol")
        val frames = ExerciseArtResolver.framesFor("Pistol squat", "art_cf_pistol",
            captionCount = 9) { it in exists }
        assertEquals(listOf("art_cf_pistol"), frames)
    }
    @Test fun missingHeroKeepsOneExistingStepButInsufficientCaptionsNeverInventHero() {
        assertEquals(listOf("art_missing_1"),ExerciseArtResolver.framesFor("Example","art_missing") {it=="art_missing_1"})
        assertEquals(emptyList<String>(),ExerciseArtResolver.framesFor("Example","art_missing",captionCount=1) {it in setOf("art_missing_1","art_missing_2")})
    }
    @Test fun mobilityMissingHeroDoesNotFallBackToAnOrphanSingleStep() {
        assertEquals(emptyList<String>(),ExerciseArtResolver.framesFor("Mobility","art_missing",isMobility=true) {it=="art_missing_1"})
    }
}
