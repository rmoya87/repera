package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class CatalogWodsTest {
    @Test
    fun seedContainsAllBenchmarksWithUniqueIds() {
        val all = CatalogWods.seed()
        assertEquals(31, all.size)
        assertEquals(all.size, all.map { it.id }.toSet().size)
        all.forEach { template ->
            assertTrue(template.name.isNotBlank())
            assertTrue(template.movements.isNotEmpty())
            assertTrue(template.muscles.isNotEmpty())
        }
        // Only the ten banded benchmarks carry published score bands,
        // mirroring the iOS seed.
        assertEquals(10, all.count { it.scoreBands != null })
    }

    @Test
    fun franMirrorsTheIosSeed() {
        val fran = CatalogWods.template("fran")!!
        assertEquals("Fran", fran.name)
        assertEquals(WodFormat.FOR_TIME, fran.format)
        assertEquals(10, fran.timeCapMinutes)
        assertEquals(6, fran.movements.size)
        assertEquals(21, fran.movements.first().reps)
        assertEquals(43.0, fran.movements.first().weightMaleKg!!, 0.0)
        assertEquals(180, fran.scoreBands?.eliteMaxSeconds)
    }

    @Test
    fun cindyUsesRoundBands() {
        val cindy = CatalogWods.template("cindy")!!
        assertEquals(WodFormat.AMRAP, cindy.format)
        assertEquals(20.0, cindy.scoreBands?.eliteMinRounds!!, 0.0)
    }

    @Test
    fun searchMatchesNameFormatAndMuscles() {
        assertTrue(CatalogWods.search("fran").any { it.id == "fran" })
        assertTrue(CatalogWods.search("amrap").any { it.id == "cindy" })
        assertTrue(CatalogWods.search("").size == 31)
        assertTrue(CatalogWods.search("inexistente-xyz").isEmpty())
    }

    @Test
    fun labelsMatchIosPresentation() {
        val fran = CatalogWods.template("fran")!!
        assertEquals("For Time / RFT", fran.formatLabel)
        assertEquals("~5 min", fran.typicalLabel)
        assertEquals(fran.muscles.joinToString(" · "), fran.musclesLabel)
    }
}
