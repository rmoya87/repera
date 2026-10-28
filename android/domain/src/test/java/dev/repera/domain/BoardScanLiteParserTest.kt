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
    @Test
    fun mixedCaseBTTAndT2BPreferOfficialCatalogWhenOldCustomExists() {
        // Espejo de Apple 3684a6ec: fichas provisionales guardadas antes del
        // seed que comparten nombre con la oficial; el escaner elige la oficial.
        // El fixture 196 de esta clase es historico y no incluye BTT; el seed
        // actual (289) si, igual que Catalog.seed() de Apple.
        val seedArray = JSONArray(requireNotNull(
            BoardScanLiteParserTest::class.java.classLoader
                ?.getResource("catalog_seed_288.json")).readText())
        val seed289 = (0 until seedArray.length()).map {
            val o = seedArray.getJSONObject(it)
            CatalogExercise(o.getString("id"), o.getString("name"),
                SportExerciseNames.searchAliases(o.getString("name")),
                o.optBoolean("isCustom", false))
        }
        val btt = seed289.first { it.name == "Burpee to target" }
        val t2b = seed289.first { it.name == "Toes to bar" }
        val oldBTT = CatalogExercise("old-btt", "Burpee to target", emptyList(), isCustom = true)
        val oldT2B = CatalogExercise("old-t2b", "Toes to bar", emptyList(), isCustom = true)
        val result = BoardScanLiteParser.parse(
            ocrText = "AMRAP 15'\n6 BTt\n8 T2B", catalog = listOf(oldBTT, oldT2B) + seed289)
        assertEquals(1, result.blocks.size)
        assertEquals(2, result.blocks[0].movements.size)
        assertEquals("Burpee to target", result.blocks[0].movements[0].name)
        assertEquals(btt.id, result.blocks[0].movements[0].exerciseId)
        assertEquals("Toes to bar", result.blocks[0].movements[1].name)
        assertEquals(t2b.id, result.blocks[0].movements[1].exerciseId)
    }

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
    @Test fun unloadedComplexParentMultiplierStaysAnnotationNotInventedSets() {
        val block=BoardScanLiteParser.parse(ocrText="AMRAP 10'\n3X 1 PUSH PRESS + 2 AIR SQUAT",catalog=catalog).blocks.single()
        assertEquals(2,block.movements.size)
        assertEquals(1,block.movements[0].reps)
        assertEquals(2,block.movements[1].reps)
        assertTrue(block.movements[0].notes!!.contains("Complejo ×3"))
        assertTrue(block.movements[1].notes!!.contains("Parte 2/2"))
        assertNull(block.movements[0].explicitPlannedSets)
    }
    @Test fun complexMultiplierUnsupportedLoadsAndOverflowStayOnReviewPath() {
        for(line in listOf("3X 1 PUSH PRESS + 2 AIR SQUAT 40/25lb","999999999999X 1 PUSH PRESS + 2 AIR SQUAT","3X 1 PUSH PRESS + 2 AIR SQUAT @7.5-8.5","3X 1 PUSH PRESS + 2 AIR SQUAT @7-8.5")) {
            val block=BoardScanLiteParser.parse(ocrText="AMRAP 10'\n"+line,catalog=catalog).blocks.single()
            assertEquals(1,block.movements.size)
            assertFalse(block.movements.single().notes?.contains("Complejo ×3") == true)
        }
    }
    @Test fun unloadedComplexWaveAppliesOnlyToFirstPart() {
        val block=BoardScanLiteParser.parse(ocrText="AMRAP 10'\n4-3-3-2 PUSH PRESS + 2 AIR SQUAT",catalog=catalog).blocks.single()
        assertEquals(2,block.movements.size)
        assertEquals(listOf(4,3,3,2),block.movements[0].repScheme)
        assertNull(block.movements[0].reps)
        assertEquals(2,block.movements[1].reps)
        assertNull(block.movements[1].repScheme)
        assertTrue(block.movements.all {it.notes!!.contains("Series 4-3-3-2")})
    }
    @Test fun ascendingRangeOrLoadedWaveComplexRemainsUnsplit() {
        for(line in listOf("5-10 PUSH PRESS + 2 AIR SQUAT","4-3-3-2 PUSH PRESS + 2 AIR SQUAT 40/25lb")) {
            val block=BoardScanLiteParser.parse(ocrText="AMRAP 10'\n"+line,catalog=catalog).blocks.single()
            assertEquals(1,block.movements.size)
        }
    }
    @Test fun explicitKgComplexParentPairIsOnlyOnFirstPart() {
        val block=BoardScanLiteParser.parse(ocrText="AMRAP 10'\n3X 1 PUSH PRESS + 2 AIR SQUAT #25/40kg",catalog=catalog).blocks.single()
        assertEquals(2,block.movements.size)
        assertEquals(40.0,block.movements[0].weightMaleKg!!,0.001)
        assertEquals(25.0,block.movements[0].weightFemaleKg!!,0.001)
        assertNull(block.movements[1].weightMaleKg)
        assertNull(block.movements[1].weightFemaleKg)
        assertEquals(1,block.movements[0].reps)
        assertEquals(2,block.movements[1].reps)
        assertTrue(block.movements.all {it.notes!!.contains("Complejo ×3")})
    }
    @Test fun malformedOrNonPositiveParentKgPairNeverSplitsComplex() {
        for(load in listOf("-25/40kg","- 25/40kg","25/-40kg","0/40kg","25..5/40kg","1e3/40kg")) {
            val block=BoardScanLiteParser.parse(ocrText="AMRAP 10'\n1 PUSH PRESS + 2 AIR SQUAT "+load,catalog=catalog).blocks.single()
            assertEquals(load,1,block.movements.size)
        }
    }
    @Test fun complexParentPercentageAndRpeAreSharedNotLoadsOrReps() {
        for(percent in listOf("#70%","#>80%","@70%")) {
            val block=BoardScanLiteParser.parse(ocrText="AMRAP 10'\n3X 1 PUSH PRESS + 2 AIR SQUAT "+percent+" @7-8",catalog=catalog).blocks.single()
            assertEquals(2,block.movements.size)
            assertEquals(1,block.movements[0].reps)
            assertEquals(2,block.movements[1].reps)
            assertTrue(block.movements.all {it.notes!!.contains(percent.removePrefix("#").removePrefix("@")) && it.notes!!.contains("RPE 7-8")})
            assertTrue(block.movements.all {it.weightMaleKg==null && it.explicitPlannedSets==null})
        }
    }
    @Test fun complexSharedRpeKeepsKgPairOnlyOnFirstPart() {
        val block=BoardScanLiteParser.parse(ocrText="AMRAP 10'\n4-3-2 PUSH PRESS + 2 AIR SQUAT @6–8 #50/35kg",catalog=catalog).blocks.single()
        assertEquals(2,block.movements.size)
        assertEquals(listOf(4,3,2),block.movements[0].repScheme)
        assertEquals(50.0,block.movements[0].weightMaleKg!!,0.001)
        assertNull(block.movements[1].weightMaleKg)
        assertTrue(block.movements.all {it.notes!!.contains("RPE 6–8")})
    }
    @Test fun complexScaleAlternativesBelongOnlyToLastPart() {
        val block=BoardScanLiteParser.parse(ocrText="AMRAP 10'\n3X 1 PUSH PRESS + 40 DU / 80 SU / 60 DU #70% @7-8",catalog=catalog).blocks.single()
        assertEquals(2,block.movements.size)
        assertNull(block.movements[0].scaleAlternative)
        assertEquals(CrossFitGlossary.expand("80 SU")+" / "+CrossFitGlossary.expand("60 DU"),block.movements[1].scaleAlternative)
        assertEquals(40,block.movements[1].reps)
        assertTrue(block.movements.all {it.notes!!.contains("70%") && it.notes!!.contains("RPE 7-8")})
        assertTrue(block.movements.all {it.weightMaleKg==null})
    }
    @Test fun complexSpacedKgPairRemainsLoadAndAmbiguousScaleStaysReview() {
        val loaded=BoardScanLiteParser.parse(ocrText="AMRAP 10'\n1 PUSH PRESS + 2 AIR SQUAT 50 / 35 kg",catalog=catalog).blocks.single()
        assertEquals(2,loaded.movements.size)
        assertEquals(50.0,loaded.movements[0].weightMaleKg!!,0.001)
        assertTrue(loaded.movements.all {it.scaleAlternative==null})
        val review=BoardScanLiteParser.parse(ocrText="AMRAP 10'\n1 PUSH PRESS + 40 DU / 80 SU + 1 AIR SQUAT",catalog=catalog).blocks.single()
        assertEquals(1,review.movements.size)
    }
    @Test fun complexParentSetRangeIsSharedNoteNotPlannedSets() {
        val block=BoardScanLiteParser.parse(ocrText="AMRAP 10'\nSets 1-2: 3X 1 PUSH PRESS + 40 DU / 80 SU #>80% @7-8",catalog=catalog).blocks.single()
        assertEquals(2,block.movements.size)
        assertEquals(1,block.movements[0].reps)
        assertEquals(40,block.movements[1].reps)
        assertTrue(block.movements.all {it.notes!!.contains("Series 1-2") && it.notes!!.contains("Complejo ×3") && it.notes!!.contains(">80%")})
        assertTrue(block.movements.all {it.explicitPlannedSets==null})
        assertNull(block.movements[0].scaleAlternative)
        assertNotNull(block.movements[1].scaleAlternative)
    }
    @Test fun invalidComplexSetRangeStaysUnsplitForReview() {
        for(range in listOf("0-2","5-2","1-201","99999999999-999999999999")) {
            val block=BoardScanLiteParser.parse(ocrText="AMRAP 10'\nSETS "+range+": 1 PUSH PRESS + 2 AIR SQUAT",catalog=catalog).blocks.single()
            assertEquals(range,1,block.movements.size)
        }
    }
    @Test fun trailingComplexAtTokenStaysSharedVerbatimNotLoad() {
        for(at in listOf("@7","@7.5","@7,5","@60")) {
            val block=BoardScanLiteParser.parse(ocrText="AMRAP 10'\n1 PUSH PRESS + 2 AIR SQUAT "+at,catalog=catalog).blocks.single()
            assertEquals(at,2,block.movements.size)
            assertTrue(block.movements.all {it.notes!!.contains(at)})
            assertTrue(block.movements.all {it.weightMaleKg==null && it.weightFemaleKg==null && it.explicitPlannedSets==null})
            assertEquals(1,block.movements[0].reps)
            assertEquals(2,block.movements[1].reps)
        }
    }
    @Test fun malformedComplexAtTokenRemainsUnsplit() {
        for(at in listOf("@-7","@7..5","@7.5-8.5","@7kg","@1e3")) {
            val block=BoardScanLiteParser.parse(ocrText="AMRAP 10'\n1 PUSH PRESS + 2 AIR SQUAT "+at,catalog=catalog).blocks.single()
            assertEquals(at,1,block.movements.size)
        }
    }
    @Test fun emptyComplexPartsAndUnboundedQuantitiesRemainReview() {
        for(line in listOf("1 PUSH PRESS ++ 2 AIR SQUAT","+ 1 PUSH PRESS + 2 AIR SQUAT","1 PUSH PRESS + 2 AIR SQUAT +","0 PUSH PRESS + 2 AIR SQUAT","100001 PUSH PRESS + 2 AIR SQUAT","1 PUSH PRESS + 999999999999 AIR SQUAT")) {
            val block=BoardScanLiteParser.parse(ocrText="AMRAP 10'\n"+line,catalog=catalog).blocks.single()
            assertEquals(line,1,block.movements.size)
        }
    }
    @Test fun unsupportedAnnotationsInScaleCannotBypassComplexReview() {
        for(annotation in listOf("@7.5-8.5","#mystery","@7kg")) {
            val block=BoardScanLiteParser.parse(ocrText="AMRAP 10'\n1 PUSH PRESS + 40 DU / 80 SU "+annotation,catalog=catalog).blocks.single()
            assertEquals(annotation,1,block.movements.size)
        }
    }
    @Test fun complexRestLineKeepsWholeLineRestPrecedence() {
        for(line in listOf("1 PUSH PRESS + 2 REST","3X 1 PUSH PRESS + 2 DESCANSO")) {
            val block=BoardScanLiteParser.parse(ocrText="AMRAP 10'\n"+line,catalog=catalog).blocks.single()
            assertEquals(line,1,block.movements.size)
            assertTrue(block.movements.single().isRest)
            assertEquals("REST",block.movements.single().name)
        }
    }
    @Test fun complexModifierCandidateUsesOfficialAliasBeforeOldCustom() {
        val official=CatalogExercise("official","Press oficial",listOf("ZPRESS"))
        val old=CatalogExercise("old","ZPRESS BN",emptyList(),isCustom=true)
        val squat=CatalogExercise("squat","Sentadilla",listOf("AIR SQUAT"))
        val block=BoardScanLiteParser.parse("AMRAP 10'\n1 ZPRESS BN + 2 AIR SQUAT",listOf(old,official,squat)).blocks.single()
        assertEquals(2,block.movements.size)
        assertEquals("official",block.movements[0].exerciseId)
        assertEquals("Press oficial",block.movements[0].name)
        assertEquals("squat",block.movements[1].exerciseId)
    }
    @Test fun complexCandidateMatchingDoesNotEnableFuzzyAndKeepsOfficialExactFirst() {
        val exact=CatalogExercise("exact","ZPRESS",emptyList())
        val alias=CatalogExercise("alias","Press oficial",listOf("ZPRESS"))
        val near=CatalogExercise("near","ZPRESS UNKNOWN EXTRA",emptyList())
        val block=BoardScanLiteParser.parse("AMRAP 10'\n1 ZPRESS BN + 2 UNKNOWN EXTRA",listOf(alias,near,exact)).blocks.single()
        assertEquals("exact",block.movements[0].exerciseId)
        assertNull(block.movements[1].exerciseId)
        val single=BoardScanLiteParser.parse("AMRAP 10'\n1 UNKNOWN EXTRA",listOf(near)).blocks.single()
        assertNull(single.movements.single().exerciseId)
    }
    @Test fun complexExactCandidateKeepsExistingDumbbellCleanVariant() {
        val raw="1 DB CLEAN"
        val parsed=CrossFitGlossary.parseMovementLine(raw)
        val variant=CatalogExercise("variant",parsed.name,emptyList())
        val generic=CatalogExercise("generic","Cargada",emptyList())
        val block=BoardScanLiteParser.parse("AMRAP 10'\n"+raw+" + 2 AIR SQUAT",listOf(generic,variant)).blocks.single()
        assertEquals("variant",block.movements[0].exerciseId)
        assertEquals(parsed.name,block.movements[0].name)
    }
    @Test fun describedStrengthHeadersStayHeadersNotMovements() {
        for(header in listOf("TECHNIQUE: CLEAN WORK","SUPERSET UPPER BODY","GIANT SET: ACCESSORY","WARM UP SHOULDERS","COOL DOWN: EASY")) {
            val block=BoardScanLiteParser.parse(header+"\n1 PUSH PRESS",catalog=catalog).blocks.single()
            assertEquals(header,WODFormat.STRENGTH,block.wodFormat)
            assertEquals(header,block.title)
            assertEquals(1,block.movements.size)
            assertEquals(1,block.movements.single().reps)
        }
    }
    @Test fun strengthHeaderPrefixRequiresWordOrColonBoundary() {
        val block=BoardScanLiteParser.parse("TECHNIQUELESS MOVEMENT\n2 AIR SQUAT",catalog=catalog).blocks.single()
        assertEquals(WODFormat.CHIPPER,block.wodFormat)
        assertEquals(2,block.movements.size)
    }
    @Test fun chipperAndDeathByHeadersCreateFormatsNotMovements() {
        for((header,format,title) in listOf(Triple("CHIPPER",WODFormat.CHIPPER,"Chipper"),Triple("DEATH BY BURPEES",WODFormat.DEATH_BY,"Muerte por"),Triple("MUERTE POR REMO",WODFormat.DEATH_BY,"Muerte por"))) {
            val block=BoardScanLiteParser.parse(header+"\n2 AIR SQUAT",catalog=catalog).blocks.single()
            assertEquals(header,format,block.wodFormat)
            assertEquals(title,block.title)
            assertEquals(1,block.movements.size)
            assertEquals(2,block.movements.single().reps)
            assertTrue(block.wodNotes!!.contains(header))
        }
    }
    @Test fun plainRoundHeaderAndTabataUseSourceDefaultsNotFakeMovements() {
        val rounds=BoardScanLiteParser.parse("5 ROUNDS OF\n2 AIR SQUAT",catalog=catalog).blocks.single()
        assertEquals(WODFormat.FOR_TIME,rounds.wodFormat)
        assertEquals(5,rounds.rounds)
        assertEquals(12,rounds.timeCapMinutes)
        assertEquals(1,rounds.movements.size)
        val tabata=BoardScanLiteParser.parse("TABATA AIR SQUAT\n2 AIR SQUAT",catalog=catalog).blocks.single()
        assertEquals(WODFormat.TABATA,tabata.wodFormat)
        assertEquals(8,tabata.rounds)
        assertEquals("Tabata",tabata.title)
        assertTrue(tabata.wodNotes!!.contains("TABATA AIR SQUAT"))
        assertEquals(1,tabata.movements.size)
        assertNull(tabata.timeCapMinutes)
    }
    @Test fun standaloneNoiseLabelsDoNotBecomeExercisesAndNotesRemain() {
        val block=BoardScanLiteParser.parse("AMRAP 10'\nSETS\nREPS\nCIRCUITO\n2 AIR SQUAT\nCIRCUIT",catalog=catalog).blocks.single()
        assertEquals(1,block.movements.size)
        assertEquals(2,block.movements.single().reps)
        assertTrue(block.wodNotes!!.contains("SETS"))
        assertTrue(block.wodNotes!!.contains("CIRCUITO"))
        val named=BoardScanLiteParser.parse("AMRAP 10'\n2 CIRCUIT PRESS",catalog=catalog).blocks.single()
        assertEquals(1,named.movements.size)
        assertEquals(2,named.movements.single().reps)
    }
    @Test fun explicitOnTheMinuteHeadersKeepCadenceAndCap() {
        for(header in listOf("OTM 12'","ON THE MINUTE 12'")) {
            val block=BoardScanLiteParser.parse(header+"\n2 AIR SQUAT",catalog=catalog).blocks.single()
            assertEquals(WODFormat.EMOM,block.wodFormat)
            assertEquals(60,block.emomIntervalSeconds)
            assertEquals(12,block.timeCapMinutes)
            assertEquals(1,block.movements.size)
            assertTrue(block.wodNotes!!.contains(header))
        }
        val defaults=BoardScanLiteParser.parse("OTM\n2 AIR SQUAT",catalog=catalog).blocks.single()
        assertEquals(10,defaults.timeCapMinutes)
    }
    @Test fun namedLadderHeadersDoNotBecomeExercises() {
        for(header in listOf("LADDER","ESCALERA","PYRAMID","PIRÁMIDE","PIRAMIDE")) {
            val block=BoardScanLiteParser.parse(header+"\n2 AIR SQUAT",catalog=catalog).blocks.single()
            assertEquals(header,WODFormat.LADDER,block.wodFormat)
            assertEquals(header,block.title)
            assertEquals(1,block.movements.size)
            assertNull(block.rounds)
        }
        val ordinary=BoardScanLiteParser.parse("AMRAP 10'\n2 LADDER CLIMB",catalog=catalog).blocks.single()
        assertEquals(WODFormat.AMRAP,ordinary.wodFormat)
        assertEquals(1,ordinary.movements.size)
    }
    @Test fun explicitBuyInCashOutHeadersSelectFormatWithoutInventingRecipe() {
        for(header in listOf("BUY-IN","BUY IN","CASH OUT","CASH-OUT","CASHOUT")) {
            val block=BoardScanLiteParser.parse(header+"\n200M RUN",catalog=catalog).blocks.single()
            assertEquals(header,WODFormat.BUY_IN_CASH_OUT,block.wodFormat)
            assertEquals(header,block.title)
            assertEquals(1,block.movements.size)
            assertEquals(200,block.movements.single().distanceMeters)
            assertNull(block.rounds)
            assertTrue(block.wodNotes!!.contains(header))
        }
    }
    @Test fun explicitAsManyHeadersUseAmrapWithoutFakeMovement() {
        for(header in listOf("AS MANY ROUNDS 14'","AS MANY REPS 14'")) {
            val block=BoardScanLiteParser.parse(header+"\n2 AIR SQUAT",catalog=catalog).blocks.single()
            assertEquals(WODFormat.AMRAP,block.wodFormat)
            assertEquals(14,block.timeCapMinutes)
            assertEquals("AMRAP 14'",block.title)
            assertEquals(1,block.movements.size)
            assertTrue(block.wodNotes!!.contains(header))
        }
        val defaults=BoardScanLiteParser.parse("AS MANY ROUNDS\n2 AIR SQUAT",catalog=catalog).blocks.single()
        assertEquals(12,defaults.timeCapMinutes)
    }
    @Test fun countedStationHeadersSelectCircuitWithSourceRounds() {
        for(header in listOf("4 STATIONS","4 ESTACIONES")) {
            val block=BoardScanLiteParser.parse(header+"\n2 AIR SQUAT\n3 PUSH PRESS",catalog=catalog).blocks.single()
            assertEquals(WODFormat.CIRCUIT,block.wodFormat)
            assertEquals(4,block.rounds)
            assertEquals(2,block.movements.size)
            assertEquals(header,block.title)
        }
        val ordinary=BoardScanLiteParser.parse("AMRAP 10'\n2 STATION PRESS",catalog=catalog).blocks.single()
        assertEquals(WODFormat.AMRAP,ordinary.wodFormat)
        assertEquals(1,ordinary.movements.size)
    }
    @Test fun exactAfapHeadersAreNotMovementSuffixes() {
        for(header in listOf("AFAP","AS FAST AS POSSIBLE","AFAP 9'","AS FAST AS POSSIBLE 9'")) {
            val block=BoardScanLiteParser.parse(header+"\n300M RUN",catalog=catalog).blocks.single()
            assertEquals(WODFormat.AFAP,block.wodFormat)
            assertEquals("AFAP",block.title)
            assertEquals(if(header.contains("9")) 9 else null,block.timeCapMinutes)
            assertEquals(1,block.movements.size)
            assertEquals(300,block.movements.single().distanceMeters)
            assertTrue(block.wodNotes!!.contains(header))
        }
        val movement=BoardScanLiteParser.parse("AMRAP 10'\n300M RUN AFAP",catalog=catalog).blocks.single()
        assertEquals(WODFormat.AMRAP,movement.wodFormat)
        assertEquals(1,movement.movements.size)
    }
    @Test fun exactForCompletionHeaderKeepsCapWithoutInventedRounds() {
        for((header,cap) in listOf("FOR COMPLETION" to 12,"FOR COMPLETION (TC 14)" to 14,"FOR COMPLETION (20min Cap)" to 20)) {
            val block=BoardScanLiteParser.parse(header+"\n300M RUN",catalog=catalog).blocks.single()
            assertEquals(WODFormat.FOR_TIME,block.wodFormat)
            assertEquals(cap,block.timeCapMinutes)
            assertNull(block.rounds)
            assertEquals(1,block.movements.size)
            assertTrue(block.wodNotes!!.contains(header))
        }
    }
    @Test fun exactMaxEffortHeadersDoNotConsumeMaxCalMovementText() {
        for(header in listOf("MAX LOAD","MAX REPS","HEAVY SINGLE","1RM")) {
            val block=BoardScanLiteParser.parse(header+"\n1 PUSH PRESS",catalog=catalog).blocks.single()
            assertEquals(WODFormat.MAX_EFFORT,block.wodFormat)
            assertEquals(header,block.title)
            assertEquals(if(header=="1RM") 1 else null,block.timeCapMinutes)
            assertEquals(1,block.movements.size)
            assertNull(block.rounds)
        }
        val ordinary=BoardScanLiteParser.parse("AMRAP 10'\nMAX CAL ROW",catalog=catalog).blocks.single()
        assertEquals(WODFormat.AMRAP,ordinary.wodFormat)
        assertEquals(1,ordinary.movements.size)
    }
    @Test fun everyForExplicitUnitSynonymsKeepCadenceDurationAndRounds() {
        for((header,seconds) in listOf("CADA 90 SEC PARA 12 MIN" to 90,"EVERY 90 SECONDS FOR 12 MINUTES" to 90,"CADA 2 MIN PARA 12 MIN" to 120,"EVERY 90S FOR 12MIN" to 90, "CADA 90\" PARA 12'" to 90)) {
            val block=BoardScanLiteParser.parse(header+"\n2 AIR SQUAT",catalog=catalog).blocks.single()
            assertEquals(header,WODFormat.EMOM,block.wodFormat)
            assertEquals(header,seconds,block.emomIntervalSeconds)
            assertEquals(12,block.timeCapMinutes)
            assertEquals(720/seconds,block.rounds)
            assertEquals(1,block.movements.size)
            assertTrue(block.wodNotes!!.contains(header))
        }
    }
    @Test fun everyForExplicitRoundsOverrideDerivedRounds() {
        for(suffix in listOf("(5 SETS)","(5 SERIES)","(5 ROUNDS)","(5 RONDAS)")) {
            val block=BoardScanLiteParser.parse("EVERY 2 MIN FOR 12 MIN $suffix\n2 AIR SQUAT",catalog=catalog).blocks.single()
            assertEquals(5,block.rounds)
            assertEquals(120,block.emomIntervalSeconds)
            assertEquals(12,block.timeCapMinutes)
        }
    }
    @Test fun everyForMissingIntervalUnitUsesSourceThreshold() {
        for((header,seconds) in listOf("EVERY 90 FOR 12 MIN" to 90,"CADA 2 PARA 12 MIN" to 120,"EVERY 30 FOR 12" to 30,"EVERY 29 FOR 58" to 1740)) {
            val block=BoardScanLiteParser.parse(header+"\n2 AIR SQUAT",catalog=catalog).blocks.single()
            val minutes=if(seconds==1740) 58 else 12
            assertEquals(header,seconds,block.emomIntervalSeconds)
            assertEquals(header,minutes,block.timeCapMinutes)
            assertEquals(header,minutes*60/seconds,block.rounds)
            assertEquals(1,block.movements.size)
            assertTrue(block.wodNotes!!.contains(header))
        }
    }
    @Test fun findAHeavyHeaderKeepsDescriptionAndSourceCap() {
        for(header in listOf("FIND A HEAVY", "FIND A HEAVY CLEAN", "FIND A HEAVY 3 REP BACK SQUAT")) {
            val block=BoardScanLiteParser.parse(header+"\n1 PUSH PRESS",catalog=catalog).blocks.single()
            assertEquals(header,WODFormat.MAX_EFFORT,block.wodFormat)
            assertEquals(header,block.title)
            assertEquals(if(header.contains("3")) 3 else null,block.timeCapMinutes)
            assertEquals(1,block.movements.size)
            assertNull(block.rounds)
            assertTrue(block.wodNotes!!.contains(header))
        }
        val ordinary=BoardScanLiteParser.parse("AMRAP 10'\n2 FIND A HEAVY PRESS",catalog=catalog).blocks.single()
        assertEquals(WODFormat.AMRAP,ordinary.wodFormat)
        assertEquals(1,ordinary.movements.size)
    }
    @Test fun explicitMaxEffortPrefixesKeepDescriptionsWithoutGlobalMaxRule() {
        for(header in listOf("MAX LOAD CLEAN", "MAX REPS PULL UPS", "HEAVY SINGLE BACK SQUAT", "1RM SNATCH")) {
            val block=BoardScanLiteParser.parse(header+"\n1 PUSH PRESS",catalog=catalog).blocks.single()
            assertEquals(header,WODFormat.MAX_EFFORT,block.wodFormat)
            assertEquals(header,block.title)
            assertEquals(if(header.startsWith("1RM")) 1 else null,block.timeCapMinutes)
            assertEquals(1,block.movements.size)
            assertNull(block.rounds)
            assertTrue(block.wodNotes!!.contains(header))
        }
        for(name in listOf("MAX CAL ROW","2 MAX LOAD PRESS","2 MAX REPS PRESS","2 HEAVY SINGLE PRESS")) {
            val block=BoardScanLiteParser.parse("AMRAP 10'\n"+name,catalog=catalog).blocks.single()
            assertEquals(name,WODFormat.AMRAP,block.wodFormat)
            assertEquals(1,block.movements.size)
        }
    }
    @Test fun standaloneInitialQualityHeaderDoesNotDisappearIntoChipper() {
        for(header in listOf("FOR QUALITY","RFQ","ROUNDS FOR QUALITY")) {
            val block=BoardScanLiteParser.parse(header+"\n2 AIR SQUAT",catalog=catalog).blocks.single()
            assertEquals(header,WODFormat.ROUNDS_FOR_QUALITY,block.wodFormat)
            assertEquals(header,block.title)
            assertNull(block.rounds)
            assertNull(block.timeCapMinutes)
            assertEquals(1,block.movements.size)
            assertTrue(block.wodNotes!!.contains(header))
        }
        val annotated=BoardScanLiteParser.parse("EMOM 9'\nRFQ\n2 AIR SQUAT",catalog=catalog).blocks.single()
        assertEquals(WODFormat.EMOM,annotated.wodFormat)
        assertEquals(9,annotated.timeCapMinutes)
        assertEquals(1,annotated.movements.size)
        assertTrue(annotated.wodNotes!!.contains("FOR QUALITY"))
    }
    @Test fun numberedRfqHeaderStartsQualityBlockWithoutFalseMovement() {
        for(header in listOf("3 RFQ","3 FOR QUALITY","3 ROUNDS FOR QUALITY")) {
            val blocks=BoardScanLiteParser.parse("AMRAP 10'\n2 AIR SQUAT\n"+header+"\n4 PUSH PRESS",catalog=catalog).blocks
            assertEquals(header,2,blocks.size)
            assertEquals(WODFormat.AMRAP,blocks[0].wodFormat)
            val block=blocks[1]
            assertEquals(header,WODFormat.ROUNDS_FOR_QUALITY,block.wodFormat)
            assertEquals(3,block.rounds)
            assertNull(block.timeCapMinutes)
            assertEquals(1,block.movements.size)
            assertTrue(block.wodNotes!!.contains(header))
        }
        val block=BoardScanLiteParser.parse("AMRAP 10'\n3 RFQ PRESS",catalog=catalog).blocks.single()
        assertEquals(WODFormat.AMRAP,block.wodFormat)
        assertEquals(1,block.movements.size)
    }
    @Test fun singleCharacterOcrNoiseDoesNotCreateExercisesOrBlockExplicitStrength() {
        val wod=BoardScanLiteParser.parse("AMRAP 10'\n|\nA\n2 AIR SQUAT",catalog=catalog).blocks.single()
        assertEquals(1,wod.movements.size)
        assertTrue(wod.wodNotes!!.contains("|"))
        val strength=BoardScanLiteParser.parse("|\n3x8 AIR SQUAT\nA",catalog=catalog).blocks.single()
        assertEquals(RoutineBlockKind.STRENGTH,strength.kind)
        assertEquals(1,strength.exercises.size)
        assertEquals(3,strength.exercises.single().plannedSets.size)
        assertTrue(strength.wodNotes!!.contains("|"))
    }
}
