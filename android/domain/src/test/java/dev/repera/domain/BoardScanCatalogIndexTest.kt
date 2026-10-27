package dev.repera.domain

import org.json.JSONArray
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.BeforeClass
import org.junit.Test

/**
 * Matching del escáner contra el catálogo actual (288 entradas) con el índice
 * de alias. Apple (live main) BoardScanLiteParser.catalogIndex: nombres
 * oficiales primero, fichas custom solo si la clave está libre, y alias
 * publicados sin pisar nombres canónicos (un alias sí desplaza a un custom).
 * Las expectativas de nombre replican los tests de Apple en bd4/main
 * (BoardScanLiteParserTests.swift) sobre el catálogo bilingüe actual.
 */
class BoardScanCatalogIndexTest {

    companion object {
        lateinit var catalog: List<CatalogExercise>

        @BeforeClass @JvmStatic
        fun loadCatalog() {
            val text = requireNotNull(
                BoardScanCatalogIndexTest::class.java.classLoader
                    ?.getResource("catalog_seed_288.json")
            ).readText()
            val array = JSONArray(text)
            catalog = (0 until array.length()).map {
                val o = array.getJSONObject(it)
                CatalogExercise(
                    id = o.getString("id"),
                    name = o.getString("name"),
                    searchAliases = SportExerciseNames.searchAliases(o.getString("name")),
                    isCustom = o.optBoolean("isCustom", false)
                )
            }
        }
    }

    @Test
    fun resolvesDumbbellCleanAndJerkThroughPublishedAlias() {
        // Repro duradera del trace de «20 ALT DB HANG C&J 22,5/15»: el parser
        // produce «Cargada y envión con mancuerna» y el índice lo resuelve al
        // ejercicio oficial inglés vía su alias publicado (SportExerciseNames).
        val board = """
        AMRAP 8'
        20 ALT DB HANG C&J 22,5/15
        10 BBJO
        """.trimIndent()
        val result = BoardScanLiteParser.parse(ocrText = board, catalog = catalog)
        assertEquals(1, result.blocks.size)
        val amrap = result.blocks[0]
        assertEquals(2, amrap.movements.size)
        assertEquals("Dumbbell Clean and Jerk", amrap.movements[0].name)
        assertNotNull(amrap.movements[0].exerciseId)
        assertEquals(22.5, amrap.movements[0].weightMaleKg!!, 0.001)
        assertEquals(15.0, amrap.movements[0].weightFemaleKg!!, 0.001)
        assertTrue(amrap.movements[0].notes!!.contains("Alternando"))
        assertEquals("Burpee box jump over", amrap.movements[1].name)
    }

    @Test
    fun modernizedEnglishNamesMatchAppleExpectations() {
        // Mismos inputs que los tests del fixture 196; el catálogo actual (288)
        // los nombra en inglés, igual que esperan los tests de Apple en bd4/main.
        val pulls = BoardScanLiteParser.parse(
            ocrText = """
            AMRAP 5'
            1 CLEAN PULL
            1 SQUAT CLEAN
            20 AMERICAN SWING 24/16
            """.trimIndent(),
            catalog = catalog
        )
        val moves = pulls.blocks[0].movements
        assertEquals(listOf("Clean Pull", "Clean", "American Kettlebell Swing"),
            moves.map { it.name })
        moves.forEach { assertNotNull(it.exerciseId) }

        val lunges = BoardScanLiteParser.parse(
            ocrText = """
            AMRAP 5'
            10 BACK RACK R. LUNGES 40/25
            """.trimIndent(),
            catalog = catalog
        )
        assertEquals("Back rack reverse lunge", lunges.blocks[0].movements[0].name)
        assertNotNull(lunges.blocks[0].movements[0].exerciseId)
        assertEquals(40.0, lunges.blocks[0].movements[0].weightMaleKg!!, 0.001)
        assertEquals(25.0, lunges.blocks[0].movements[0].weightFemaleKg!!, 0.001)
    }

    @Test
    fun aliasDoesNotOverrideOfficialName() {
        // Con el nombre oficial español presente en catálogo (como el seed de
        // Apple en main), el alias publicado no lo desplaza.
        val cat = listOf(
            CatalogExercise("off-es", "Cargada y envión con mancuerna"),
            CatalogExercise(
                "off-en", "Dumbbell Clean and Jerk",
                searchAliases = listOf("Cargada y envión con mancuerna")
            )
        )
        val r = BoardScanLiteParser.parse(
            ocrText = "AMRAP 8'\n20 ALT DB HANG C&J", catalog = cat
        )
        assertEquals("off-es", r.blocks[0].movements[0].exerciseId)
        assertEquals("Cargada y envión con mancuerna", r.blocks[0].movements[0].name)
    }

    @Test
    fun aliasReplacesCustomHomonym() {
        // Un alias oficial sí desplaza a una ficha custom homónima (ca7b1ae2).
        val cat = listOf(
            CatalogExercise("custom", "Cargada y envión con mancuerna", isCustom = true),
            CatalogExercise(
                "off-en", "Dumbbell Clean and Jerk",
                searchAliases = listOf("Cargada y envión con mancuerna")
            )
        )
        val r = BoardScanLiteParser.parse(
            ocrText = "AMRAP 8'\n20 ALT DB HANG C&J", catalog = cat
        )
        assertEquals("off-en", r.blocks[0].movements[0].exerciseId)
        assertEquals("Dumbbell Clean and Jerk", r.blocks[0].movements[0].name)
    }

    @Test
    fun customHomonymDoesNotOverrideOfficial() {
        val cat = listOf(
            CatalogExercise("custom", "Clean", isCustom = true),
            CatalogExercise("off", "Clean")
        )
        val r = BoardScanLiteParser.parse(
            ocrText = "AMRAP 5'\n1 SQUAT CLEAN", catalog = cat
        )
        assertEquals("off", r.blocks[0].movements[0].exerciseId)
        assertEquals("Clean", r.blocks[0].movements[0].name)
    }
}
