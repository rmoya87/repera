package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Test

/**
 * Espejo de AbbreviatedWODCatalogTests (Apple 0a640da8). El Catalog.seed() de
 * Apple se modela con una lista empaquetada explícita; la ficha «Burpee to
 * target» no existe hoy en el seed 288 de Android, así que el respaldo
 * empaquetado se construye a mano en estos tests.
 */
class CatalogExerciseReconciliationTest {

    private val packaged = listOf(
        CatalogExercise(id = "pack-btt", name = "Burpee to target"),
        CatalogExercise(id = "pack-ttb", name = "Toes to bar")
    )

    @Test
    fun bttAndT2BResolveAgainstPackagedCatalogEvenWithProvisionalIDs() {
        for ((raw, expected) in listOf("BTt" to "Burpee to target", "T2B" to "Toes to bar")) {
            val provisional = CatalogExercise(id = "prov-$raw", name = raw, isCustom = true)
            val movement = WODMovement(exerciseId = provisional.id, name = raw, reps = 8)
            val match = CrossFitGlossary.catalogExercise(movement, listOf(provisional) + packaged)
            assertEquals(expected, match?.name)
            assertEquals(false, match?.isCustom)
        }
    }

    @Test
    fun officialOfflineFallbackWhenOnlyAProvisionalExerciseExists() {
        for ((raw, official) in listOf("BTt" to "Burpee to target", "T2B" to "Toes to bar")) {
            val provisional = CatalogExercise(id = "prov-$raw", name = raw, isCustom = true)
            val movement = WODMovement(exerciseId = provisional.id, name = raw, reps = 6)
            val resolved = CrossFitGlossary.catalogExercise(
                movement, listOf(provisional), packagedFallback = packaged
            )
            assertEquals(official, resolved?.name)
            assertEquals(false, resolved?.isCustom)
            assertNotEquals(provisional.id, resolved?.id)
        }
    }

    @Test
    fun officialRemoteAliasHasPriorityOverOfflineFallback() {
        val official = CatalogExercise(
            id = "off-btt", name = "Burpee to target", searchAliases = listOf("BTt")
        )
        val provisional = CatalogExercise(id = "prov-btt", name = "BTt", isCustom = true)
        val movement = WODMovement(exerciseId = provisional.id, name = "BTt", reps = 6)
        assertEquals(
            official.id,
            CrossFitGlossary.catalogExercise(movement, listOf(provisional, official))?.id
        )
    }

    @Test
    fun staleOfficialAbbreviationDoesNotReplaceTheCanonicalExercise() {
        for ((short, canonical) in listOf("BTt" to "Burpee to target", "T2B" to "Toes to bar")) {
            // Catálogos antiguos guardaron estos rótulos con isCustom=false.
            val legacy = CatalogExercise(id = "leg-$short", name = short)
            val correct = CatalogExercise(id = "ok-$short", name = canonical)
            val movement = WODMovement(exerciseId = legacy.id, name = short, reps = 6)
            assertEquals(
                correct.id,
                CrossFitGlossary.catalogExercise(movement, listOf(legacy, correct))?.id
            )
            assertEquals(
                canonical,
                CrossFitGlossary.catalogExercise(
                    movement, listOf(legacy), packagedFallback = packaged
                )?.name
            )
        }
    }

    @Test
    fun preservesOtherCustomMovementsWithoutFalseReplacements() {
        val free = CatalogExercise(id = "free-1", name = "Movimiento inventado", isCustom = true)
        val movement = WODMovement(exerciseId = free.id, name = free.name)
        assertEquals(free.id, CrossFitGlossary.catalogExercise(movement, listOf(free))?.id)
    }

    @Test
    fun restMovementsNeverResolve() {
        val rest = WODMovement(name = "Rest 1:00", isRest = true, restSeconds = 60)
        assertEquals(null, CrossFitGlossary.catalogExercise(rest, packaged))
        assertFalse(CrossFitGlossary.catalogExercise(rest, packaged)?.isCustom == true)
    }
    @Test
    fun archivedCanonicalAndAliasCandidatesAreExcluded() {
        val archived = CatalogExercise("archived", "Toes to bar", listOf("T2B"), isCatalogArchived = true)
        val actual = CrossFitGlossary.catalogExercise(
            WODMovement(name = "T2B"), listOf(archived), packaged
        )
        assertEquals("pack-ttb", actual?.id)
    }

}
