package dev.repera.domain

import org.json.JSONArray
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.BeforeClass
import org.junit.Test

/**
 * Port de BoardScanLiteParserTests.swift (13 tests). Las expectativas de nombre
 * usan el catálogo Android (catalog_seed.json), que conserva los nombres base
 * en español donde iOS aplica SportExerciseNames.displayName (inglés):
 * Clean Pull→Tirón de cargada, Snatch Balance→Balance de arrancada,
 * Clean→Cargada, Power Clean→Cargada de potencia,
 * American Kettlebell Swing→Swing americano, Double-Under→Dobles de comba,
 * Dumbbell Clean and Jerk→Cargada y envión con mancuerna,
 * Back rack reverse lunge→Zancadas inversas con barra.
 * Las aserciones de SessionController (iOS) no se portan: ese tipo no existe
 * en el dominio Android.
 */
class BoardScanLiteParserTest {

    companion object {
        lateinit var catalog: List<CatalogExercise>

        @BeforeClass @JvmStatic
        fun loadCatalog() {
            val text = requireNotNull(
                BoardScanLiteParserTest::class.java.classLoader
                    ?.getResource("catalog_seed.json")
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

    private fun nameOf(id: String?): String? = catalog.firstOrNull { it.id == id }?.name

    @Test
    fun photographedNinetySecondComplexAndSnatchBalanceWave() {
        val board = """
        EVERY 90" X 6 @6-8
        1 CLEAN PULL
        1 HANG POWER CLEAN
        1 T&G SQUAT CLEAN

        EVERY 2' X 4
        3-3-2-2 SNATCH BALANCE @6-8

        AMRAP 12'
        5 POWER CLEAN 50/35
        5 FRONT SQUAT 50/35
        10 PULL UPS
        100M RUN
        """.trimIndent()
        val result = BoardScanLiteParser.parse(ocrText = board, catalog = catalog)
        assertEquals(3, result.blocks.size)

        val complex = result.blocks[0]
        assertEquals(RoutineBlockKind.STRENGTH, complex.kind)
        assertEquals(90, complex.emomIntervalSeconds)
        assertEquals(9, complex.timeCapMinutes)
        assertEquals(3, complex.exercises.size)
        complex.exercises.forEach { entry ->
            assertEquals(6, entry.plannedSets.size)
            entry.plannedSets.forEach {
                assertEquals(1, it.targetReps)
                assertEquals(3.0, it.targetRir!!, 0.0001)
            }
        }
        assertEquals(listOf("Tirón de cargada", "Hang power clean", "Cargada"),
            complex.exercises.map { nameOf(it.exerciseId) })
        assertTrue(complex.wodNotes!!.contains("T&G SQUAT CLEAN"))

        val snatch = result.blocks[1]
        assertEquals(RoutineBlockKind.STRENGTH, snatch.kind)
        assertEquals(120, snatch.emomIntervalSeconds)
        assertEquals(1, snatch.exercises.size)
        assertEquals(listOf(3, 3, 2, 2), snatch.exercises[0].plannedSets.map { it.targetReps })
        assertEquals(3.0, snatch.exercises[0].plannedSets[0].targetRir!!, 0.0001)
        assertEquals("Balance de arrancada", nameOf(snatch.exercises[0].exerciseId))

        val amrap = result.blocks[2]
        assertEquals(WODFormat.AMRAP, amrap.wodFormat)
        assertEquals(12, amrap.timeCapMinutes)
        assertEquals(4, amrap.movements.size)
        assertTrue(amrap.movements.all { it.exerciseId != null })
        assertEquals("Cargada de potencia", amrap.movements[0].name)
        assertEquals(5, amrap.movements[0].reps)
        assertEquals(50.0, amrap.movements[0].weightMaleKg!!, 0.001)
        assertEquals(35.0, amrap.movements[0].weightFemaleKg!!, 0.001)
        assertEquals(5, amrap.movements[1].reps)
        assertEquals(10, amrap.movements[2].reps)
        assertEquals("Carrera", amrap.movements[3].name)
        assertEquals(100, amrap.movements[3].distanceMeters)
    }

    @Test
    fun scanEnglishCompoundNamesHaveDistinctCanonicalMatches() {
        val names = listOf("CLEAN PULL", "HANG POWER CLEAN", "SQUAT CLEAN", "SNATCH BALANCE")
        val expected = listOf("Tirón de cargada", "Hang power clean", "Cargada",
            "Balance de arrancada")
        for ((input, output) in names.zip(expected)) {
            val b = BoardScanLiteParser.parse(
                ocrText = "AMRAP 10'\n5 $input", catalog = catalog).blocks
            assertEquals(1, b.size)
            assertEquals(output, b[0].movements[0].name)
            assertNotNull(b[0].movements[0].exerciseId)
        }
    }

    @Test
    fun spacedSexSpecificCaloriesDoNotBecomeScalingAlternatives() {
        val blocks = BoardScanLiteParser.parse(ocrText = """
            FOR TIME (TC 14')
            400M RUN
            20 / 16 CAL*
            400M RUN
            """.trimIndent(), catalog = catalog).blocks
        assertEquals(1, blocks.size)
        assertEquals(WODFormat.FOR_TIME, blocks[0].wodFormat)
        assertEquals(14, blocks[0].timeCapMinutes)
        assertNull(blocks[0].rounds)
        assertEquals(3, blocks[0].movements.size)
        assertEquals("Air bike", blocks[0].movements[1].name)
        assertEquals(20, blocks[0].movements[1].calories)
        assertNull(blocks[0].movements[1].scaleAlternative)
        assertNull(blocks[0].movements[1].weightMaleKg)
        assertEquals(1, blocks[0].plannedSets(blocks[0].movements[1]).size)
    }

    @Test
    fun scanAmrapAndForTimeWithCapButNoInventedRounds() {
        val board = """
        AMRAP 16'
        3 GTOH 60/40
        3 BMU / 6 C2B / 9 PULL UPS
        10 WALL BALL 9/7
        15 AKBS 24/16
        40 DU / 80 SU

        FOR TIME (TC 14')
        400M RUN
        20/16 CAL*
        400M RUN
        20/16 CAL*
        400M RUN
        (1' REST BTWN**)
        """.trimIndent()
        val result = BoardScanLiteParser.parse(ocrText = board, catalog = catalog)
        assertEquals(2, result.blocks.size)

        val amrap = result.blocks[0]
        assertEquals(WODFormat.AMRAP, amrap.wodFormat)
        assertEquals(16, amrap.timeCapMinutes)
        assertEquals(5, amrap.movements.size)
        assertEquals("Ground to overhead", amrap.movements[0].name)
        assertNotNull(amrap.movements[0].exerciseId)
        assertEquals(3, amrap.movements[0].reps)
        assertEquals(60.0, amrap.movements[0].weightMaleKg!!, 0.001)
        assertEquals(40.0, amrap.movements[0].weightFemaleKg!!, 0.001)
        assertEquals("Muscle-up barra", amrap.movements[1].name)
        assertNotNull(amrap.movements[1].exerciseId)
        assertTrue(amrap.movements[1].scaleAlternative!!.contains("Chest to bar"))
        assertTrue(amrap.movements[1].scaleAlternative!!.contains("Dominadas"))
        assertEquals("Swing americano", amrap.movements[3].name)
        assertNotNull(amrap.movements[3].exerciseId)
        assertEquals(24.0, amrap.movements[3].weightMaleKg!!, 0.001)
        assertEquals(16.0, amrap.movements[3].weightFemaleKg!!, 0.001)
        assertEquals("Dobles de comba", amrap.movements[4].name)
        assertTrue(amrap.movements[4].scaleAlternative!!.contains("Simples de comba"))

        val forTime = result.blocks[1]
        assertEquals(WODFormat.FOR_TIME, forTime.wodFormat)
        assertEquals(14, forTime.timeCapMinutes)
        assertNull(forTime.rounds)
        assertEquals(5, forTime.movements.size)
        assertEquals(400, forTime.movements[0].distanceMeters)
        assertEquals(400, forTime.movements[2].distanceMeters)
        assertEquals(400, forTime.movements[4].distanceMeters)
        assertEquals("Air bike", forTime.movements[1].name)
        assertNotNull(forTime.movements[1].exerciseId)
        assertEquals(20, forTime.movements[1].calories)
        assertNull(forTime.movements[1].weightMaleKg)
        assertNull(forTime.movements[1].weightFemaleKg)
        assertTrue(forTime.movements[1].notes!!.contains("16"))
        assertEquals(20, forTime.movements[3].calories)
        assertEquals(60, forTime.restBetweenRoundsSeconds)
        assertTrue(forTime.wodNotes!!.contains("REST BTWN"))
    }

    @Test
    fun uniqueGlossaryMappingsPreferSpecificExercises() {
        assertEquals("Carrera", CrossFitGlossary.canonicalName("RUN"))
        assertEquals("Carrera", CrossFitGlossary.canonicalName("RUNNING"))
        assertEquals("Carrera", CrossFitGlossary.canonicalName("RUNS"))
        assertEquals("Cinta / carrera", CrossFitGlossary.canonicalName("CINTA"))
        assertEquals("Swing americano", CrossFitGlossary.canonicalName("AMERICAN SWING"))
        assertEquals("Peso muerto", CrossFitGlossary.canonicalName("DEADLIFT"))
        assertEquals("Bar facing burpee", CrossFitGlossary.canonicalName("BURPEES OVER THE BAR"))
    }

    @Test
    fun fullNamesAndAcronymsShareCanonicalExercises() {
        assertEquals("Ground to overhead", CrossFitGlossary.canonicalName("GTOH"))
        assertEquals("Ground to overhead", CrossFitGlossary.canonicalName("ground-to-overhead"))
        assertEquals("Muscle-up barra", CrossFitGlossary.canonicalName("BMU"))
        assertEquals("Muscle-up barra", CrossFitGlossary.canonicalName("bar muscle up"))
        assertEquals("Swing americano", CrossFitGlossary.canonicalName("AKBS"))
        assertEquals("Swing americano",
            CrossFitGlossary.canonicalName("american kettlebell swing"))
        val calories = CrossFitGlossary.parseMovementLine("20/16 CAL")
        assertEquals("Air bike", calories.name)
        assertEquals(20, calories.calories)
        assertNull(calories.weightMaleKg)
        assertNull(calories.weightFemaleKg)
    }

    @Test
    fun importsActualScreenshotAsThreeEditableBlocks() {
        val board = """
        EMOM 8' @6-8
        2 HIGH HSQ SNATCH

        EVERY 2' X 4
        4-3-3-2 BACK SQUAT @6-8

        4 RFT (TC 12')
        6 POWER SNATCH 40/25
        8 BOB
        10 BACK RACK R. LUNGES 40/25
        1' REST
        """.trimIndent()
        val result = BoardScanLiteParser.parse(ocrText = board, catalog = catalog)
        assertEquals(3, result.blocks.size)

        val emom = result.blocks[0]
        assertEquals(RoutineBlockKind.WOD, emom.kind)
        assertEquals(WODFormat.EMOM, emom.wodFormat)
        assertEquals(8, emom.timeCapMinutes)
        assertEquals(1, emom.movements.size)
        assertNotNull(emom.movements[0].exerciseId)
        assertTrue(emom.wodNotes!!.contains("@6-8"))

        val strength = result.blocks[1]
        assertEquals(RoutineBlockKind.STRENGTH, strength.kind)
        assertEquals(120, strength.emomIntervalSeconds)
        assertEquals(8, strength.timeCapMinutes)
        assertEquals(1, strength.exercises.size)
        assertEquals(listOf(4, 3, 3, 2), strength.exercises[0].plannedSets.map { it.targetReps })
        assertEquals(3.0, strength.exercises[0].plannedSets[0].targetRir!!, 0.0001)
        assertTrue(strength.wodNotes!!.contains("BACK SQUAT @6-8"))

        val rft = result.blocks[2]
        assertEquals(WODFormat.FOR_TIME, rft.wodFormat)
        assertEquals(4, rft.rounds)
        assertEquals(12, rft.timeCapMinutes)
        assertEquals(60, rft.restBetweenRoundsSeconds)
        assertEquals(4, rft.movements.size)
        assertEquals(40.0, rft.movements[0].weightMaleKg!!, 0.001)
        assertEquals(25.0, rft.movements[0].weightFemaleKg!!, 0.001)
        assertEquals("Bar facing burpee", rft.movements[1].name)
        assertEquals("Zancadas inversas con barra", rft.movements[2].name)
        assertNotNull(rft.movements[2].exerciseId)
        assertEquals(40.0, rft.movements[2].weightMaleKg!!, 0.001)
        assertEquals(25.0, rft.movements[2].weightFemaleKg!!, 0.001)
        assertTrue(rft.movements[3].isRest)
        assertEquals(60, rft.movements[3].restSeconds)
    }

    @Test
    fun keepsMultiStationEveryAsAnEmom() {
        val board = """
        EVERY 2' X 4
        5 POWER SNATCH 40/25
        8 BOB
        """.trimIndent()
        val blocks = BoardScanLiteParser.parse(ocrText = board, catalog = catalog).blocks
        assertEquals(1, blocks.size)
        assertEquals(WODFormat.EMOM, blocks[0].wodFormat)
        assertEquals(4, blocks[0].rounds)
        assertEquals(120, blocks[0].emomIntervalSeconds)
        assertEquals(2, blocks[0].movements.size)
    }

    @Test
    fun keepsUnmatchedWODMovementForManualReview() {
        val board = """
        3 RFT (TC 9')
        6 MYSTERY BARBELL MOVEMENT 30/20
        """.trimIndent()
        val blocks = BoardScanLiteParser.parse(ocrText = board, catalog = catalog).blocks
        assertEquals(1, blocks.size)
        assertEquals(3, blocks[0].rounds)
        assertEquals(9, blocks[0].timeCapMinutes)
        assertEquals(1, blocks[0].movements.size)
        assertNull(blocks[0].movements[0].exerciseId)
        assertEquals(30.0, blocks[0].movements[0].weightMaleKg!!, 0.001)
        assertEquals(20.0, blocks[0].movements[0].weightFemaleKg!!, 0.001)
    }

    @Test
    fun splitsNoisyOCRBoardIntoThreeBlocksWithBOB() {
        val noisy = """
        EMOM 8' @6-8
        2 HIGH HSQ SNATCH
        EVERY 2' X 4
        4-3-3-2 BACK SQUAT @6-8
        4RFf(TC 12?
        6 POWER SNATCH 40/25
        8BOB
        10 BACK RACK R. LUNGES 40/25
        1' REST
        """.trimIndent()
        val result = BoardScanLiteParser.parse(ocrText = noisy, catalog = catalog)
        assertEquals(3, result.blocks.size)
        assertEquals(WODFormat.FOR_TIME, result.blocks[2].wodFormat)
        assertEquals(4, result.blocks[2].rounds)
        assertEquals(12, result.blocks[2].timeCapMinutes)
        val work = result.blocks[2].movements.filter { !it.isRest }
        assertEquals(3, work.size)
        assertEquals("Bar facing burpee", work[1].name)
        assertEquals(8, work[1].reps)
        assertNotNull(work[1].exerciseId)
    }

    @Test
    fun glossaryResolvesGluedBOB() {
        val parsed = CrossFitGlossary.parseMovementLine("8BOB")
        assertEquals(8, parsed.reps)
        assertEquals("Bar facing burpee", parsed.name)
        assertEquals("Bar facing burpee", CrossFitGlossary.canonicalName("BOB"))
        assertEquals("Bar facing burpee", CrossFitGlossary.canonicalName("burpee over the bar"))
    }

    @Test
    fun importsQualityEmomAndSpecificMovementsFromActualBoard() {
        val photo = """
        EMOM 12'
        4-3-3-2 PUSH PRESS @7-8
        2 DEADLIFT T&G @6-8
        1' REST

        EMOM 9' @FOR
        QUALITY
        5-10 KIPPING RING DIPS
        6-10 ALT PISTOL SQUAT
        1' REST

        AMRAP 8'
        20 ALT DB HANG C&J 22,5/15
        10 BBJO
        """.trimIndent()
        val result = BoardScanLiteParser.parse(ocrText = photo, catalog = catalog)
        assertEquals(3, result.blocks.size)

        val strength = result.blocks[0]
        assertEquals(WODFormat.EMOM, strength.wodFormat)
        assertEquals(12, strength.timeCapMinutes)
        assertEquals(3, strength.movements.size)
        assertEquals(listOf(4, 3, 3, 2), strength.movements[0].repScheme)
        assertTrue(strength.movements[0].notes!!.contains("RPE 7-8"))
        assertEquals("Peso muerto", strength.movements[1].name)
        assertTrue(strength.movements[1].notes!!.contains("Touch & go"))
        assertEquals(60, strength.movements[2].restSeconds)

        val quality = result.blocks[1]
        assertEquals(WODFormat.EMOM, quality.wodFormat)
        assertEquals(9, quality.timeCapMinutes)
        assertTrue(quality.wodNotes!!.contains("FOR QUALITY"))
        assertEquals(3, quality.movements.size)
        assertEquals("Fondos en anillas kipping", quality.movements[0].name)
        assertNotNull(quality.movements[0].exerciseId)
        assertEquals(10, quality.movements[0].reps)
        assertTrue(quality.movements[0].notes!!.contains("5-10"))
        assertEquals("Pistol squat", quality.movements[1].name)
        assertTrue(quality.movements[1].notes!!.contains("Alternando"))
        assertTrue(quality.movements[1].notes!!.contains("6-10"))
        assertEquals(60, quality.movements[2].restSeconds)

        val amrap = result.blocks[2]
        assertEquals(WODFormat.AMRAP, amrap.wodFormat)
        assertEquals(8, amrap.timeCapMinutes)
        assertEquals(2, amrap.movements.size)
        assertEquals("Cargada y envión con mancuerna", amrap.movements[0].name)
        assertNotNull(amrap.movements[0].exerciseId)
        assertEquals(22.5, amrap.movements[0].weightMaleKg!!, 0.001)
        assertEquals(15.0, amrap.movements[0].weightFemaleKg!!, 0.001)
        assertTrue(amrap.movements[0].notes!!.contains("Alternando"))
        assertEquals("Burpee box jump over", amrap.movements[1].name)
        assertNotNull(amrap.movements[1].exerciseId)
        assertEquals(10, amrap.movements[1].reps)
        assertFalse(amrap.movements[1].name == "Box jump over")
    }

    @Test
    fun qualityNotesDoNotSpawnGhostExercisesAndOCRBBJZeroIsCorrected() {
        val board = """
        EMOM 9'
        @FOR QUALITY
        5 KIPPING RING DIPS
        10BBJ0

        3 ROUNDS FOR QUALITY
        6 RING DIPS
        """.trimIndent()
        val result = BoardScanLiteParser.parse(ocrText = board, catalog = catalog)
        assertEquals(2, result.blocks.size)
        assertEquals(2, result.blocks[0].movements.size)
        assertEquals("Fondos en anillas kipping", result.blocks[0].movements[0].name)
        assertEquals("Burpee box jump over", result.blocks[0].movements[1].name)
        assertEquals(10, result.blocks[0].movements[1].reps)
        assertEquals(WODFormat.ROUNDS_FOR_QUALITY, result.blocks[1].wodFormat)
        assertEquals(3, result.blocks[1].rounds)
        assertEquals(1, result.blocks[1].movements.size)
        assertEquals("Fondos en anillas", result.blocks[1].movements[0].name)
        assertNotNull(result.blocks[1].movements[0].exerciseId)
    }
}
