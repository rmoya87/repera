package dev.repera.mobile

import dev.repera.domain.BoardScanLiteParser
import dev.repera.domain.CatalogExercise
import dev.repera.domain.RoutineBlockKind
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** El escáner escribe el mismo JSON wire que consume iOS (Routine Codable). */
class BoardScanImportTest {

    private val catalog = listOf(
        CatalogExercise("id-cargada", "Cargada de potencia"),
        CatalogExercise("id-carrera", "Carrera")
    )

    @Test
    fun wodBlockKeepsWeightsDistancesAndRestBetweenRounds() {
        val parsed = BoardScanLiteParser.parse(ocrText = """
            4 RFT (TC 12')
            6 POWER CLEAN 50/35
            100M RUN
            1' REST
            """.trimIndent(), catalog = catalog)
        assertEquals(1, parsed.blocks.size)
        val wire = BoardScanImport.wireBlock(parsed.blocks[0])
        assertEquals("wod", wire.getString("kind"))
        assertEquals("forTime", wire.getString("wodFormat"))
        assertEquals(4, wire.getInt("rounds"))
        assertEquals(12, wire.getInt("timeCapMinutes"))
        assertEquals(60, wire.getInt("restBetweenRoundsSeconds"))
        val movements = wire.getJSONArray("movements")
        assertEquals(3, movements.length())
        val clean = movements.getJSONObject(0)
        assertEquals("id-cargada", clean.getString("exerciseId"))
        assertEquals(6, clean.getInt("reps"))
        assertEquals(50.0, clean.getDouble("weightMaleKg"), 0.001)
        assertEquals(35.0, clean.getDouble("weightFemaleKg"), 0.001)
        val run = movements.getJSONObject(1)
        assertEquals(100, run.getInt("distanceMeters"))
        assertFalse(run.has("reps"))
        val rest = movements.getJSONObject(2)
        assertTrue(rest.getBoolean("isRest"))
        assertEquals(60, rest.getInt("restSeconds"))
        assertTrue(wire.getString("wodNotes").contains("RFT"))
    }

    @Test
    fun strengthBlockKeepsSchemeRirAndWeights() {
        val parsed = BoardScanLiteParser.parse(ocrText = """
            EVERY 2' X 4
            3-3-2-2 CLEAN PULL @6-8
            """.trimIndent(),
            catalog = listOf(CatalogExercise("id-tiron", "Tirón de cargada")))
        assertEquals(1, parsed.blocks.size)
        assertEquals(RoutineBlockKind.STRENGTH, parsed.blocks[0].kind)
        val wire = BoardScanImport.wireBlock(parsed.blocks[0])
        assertEquals("strength", wire.getString("kind"))
        assertEquals(120, wire.getInt("emomIntervalSeconds"))
        val exercises = wire.getJSONArray("exercises")
        assertEquals(1, exercises.length())
        val ex = exercises.getJSONObject(0)
        assertEquals("id-tiron", ex.getString("exerciseId"))
        val sets = ex.getJSONArray("plannedSets")
        assertEquals(4, sets.length())
        assertEquals(listOf(3, 3, 2, 2),
            (0 until sets.length()).map { sets.getJSONObject(it).getInt("targetReps") })
        assertEquals(3.0, sets.getJSONObject(0).getDouble("targetRir"), 0.0001)
        assertTrue(wire.getString("wodNotes").contains("CLEAN PULL"))
    }

    @Test
    fun percentAndMinimumFlagSurvive() {
        val set = dev.repera.domain.PlannedSet(
            targetReps = 3, targetPercent1RM = 75.0, targetPercent1RMIsMinimum = true)
        val wire = BoardScanImport.wirePlannedSet(set)
        assertEquals(75.0, wire.getDouble("targetPercent1RM"), 0.001)
        assertTrue(wire.getBoolean("targetPercent1RMIsMinimum"))
        val plain = BoardScanImport.wirePlannedSet(
            dev.repera.domain.PlannedSet(targetReps = 5, targetWeightKg = 60.0))
        assertFalse(plain.has("targetPercent1RMIsMinimum"))
        assertEquals(60.0, plain.getDouble("targetWeightKg"), 0.001)
    }
    @Test fun orphanStrengthKeepsSetsLoadAndOfficialAliasInReviewWire() {
        val official=dev.repera.domain.CatalogExercise("official","Press banca",listOf("BXT-PRO"))
        val old=dev.repera.domain.CatalogExercise("old","BXT-PRO",emptyList(),isCustom=true)
        val block=BoardScanLiteParser.parse("3x8 BXT-PRO @60",listOf(old,official)).blocks.single()
        val wire=BoardScanImport.wireBlock(block)
        assertEquals("strength",wire.getString("kind"))
        val entry=wire.getJSONArray("exercises").getJSONObject(0)
        assertEquals("official",entry.getString("exerciseId"))
        val sets=entry.getJSONArray("plannedSets")
        assertEquals(3,sets.length())
        assertEquals(8,sets.getJSONObject(0).getInt("targetReps"))
        assertEquals(60.0,sets.getJSONObject(0).getDouble("targetWeightKg"),0.001)
        assertEquals(block.exercises.single().plannedSets[0].id,sets.getJSONObject(0).getString("id"))
    }
    @Test fun explicitHeadersKeepFormatCadenceAndCapInWire() {
        val blocks=BoardScanLiteParser.parse("21-15-9\nTHRUSTER 40/30\nE2MOM 10'\n5 POWER CLEAN\nPARTNER WOD\n100 CAL ROW").blocks
        assertEquals(listOf("ladder","emom","partner"),blocks.map {BoardScanImport.wireBlock(it).getString("wodFormat")})
        val emom=BoardScanImport.wireBlock(blocks[1])
        assertEquals(120,emom.getInt("emomIntervalSeconds"))
        assertEquals(10,emom.getInt("timeCapMinutes"))
        assertEquals(1,emom.getJSONArray("movements").length())
        assertEquals(blocks[1].id,emom.getString("id"))
    }
    @Test fun complexParentKgPairStaysOnFirstWireMovement() {
        val parsed=BoardScanLiteParser.parse("AMRAP 10'\n1 POWER CLEAN + 2 PUSH PRESS #50/35kg",catalog=catalog)
        val wire=BoardScanImport.wireBlock(parsed.blocks.single())
        val movements=wire.getJSONArray("movements")
        assertEquals(2,movements.length())
        assertEquals(50.0,movements.getJSONObject(0).getDouble("weightMaleKg"),0.001)
        assertEquals(35.0,movements.getJSONObject(0).getDouble("weightFemaleKg"),0.001)
        assertFalse(movements.getJSONObject(1).has("weightMaleKg"))
        assertFalse(movements.getJSONObject(1).has("weightFemaleKg"))
    }
    @Test fun complexScaleAndSharedNotesSurviveReviewWire() {
        val block=BoardScanLiteParser.parse("AMRAP 10'\n1 POWER CLEAN + 40 DU / 80 SU #70% @7-8",catalog=catalog).blocks.single()
        val wire=BoardScanImport.wireBlock(block).getJSONArray("movements")
        assertEquals(2,wire.length())
        assertFalse(wire.getJSONObject(0).has("scaleAlternative"))
        assertEquals(block.movements[1].scaleAlternative,wire.getJSONObject(1).getString("scaleAlternative"))
        for(i in 0..1) {
            assertTrue(wire.getJSONObject(i).getString("notes").contains("RPE 7-8"))
            assertTrue(wire.getJSONObject(i).getString("notes").contains("70%"))
        }
    }
    @Test fun deathByAndChipperHeadersKeepFormatAndRawNotesInWire() {
        for((header,format) in listOf("DEATH BY BURPEES" to "deathBy","CHIPPER" to "chipper")) {
            val block=BoardScanLiteParser.parse(header+"\n2 AIR SQUAT",catalog=catalog).blocks.single()
            val wire=BoardScanImport.wireBlock(block)
            assertEquals(format,wire.getString("wodFormat"))
            assertEquals(1,wire.getJSONArray("movements").length())
            assertTrue(wire.getString("wodNotes").contains(header))
        }
    }
    @Test fun explicitBuyInFormatSurvivesReviewWire() {
        val block=BoardScanLiteParser.parse("BUY-IN\n200M RUN",catalog=catalog).blocks.single()
        val wire=BoardScanImport.wireBlock(block)
        assertEquals("buyInCashOut",wire.getString("wodFormat"))
        assertEquals(1,wire.getJSONArray("movements").length())
        assertEquals(200,wire.getJSONArray("movements").getJSONObject(0).getInt("distanceMeters"))
        assertFalse(wire.has("rounds"))
    }
    @Test fun everyForSynonymsKeepDurationCadenceAndRoundsInWire() {
        for(header in listOf("CADA 2 MIN PARA 12 MIN (5 SETS)","CADA 2 PARA 12 (5 SETS)")) {
        val block=BoardScanLiteParser.parse(header+"\n2 AIR SQUAT",catalog=catalog).blocks.single()
        val wire=BoardScanImport.wireBlock(block)
        assertEquals("emom",wire.getString("wodFormat"))
        assertEquals(120,wire.getInt("emomIntervalSeconds"))
        assertEquals(12,wire.getInt("timeCapMinutes"))
        assertEquals(5,wire.getInt("rounds"))
        assertEquals(1,wire.getJSONArray("movements").length())
        assertTrue(wire.getString("wodNotes").contains(header))
        }
    }
    @Test fun findAHeavyDescriptionKeepsMaxEffortInWire() {
        val header="FIND A HEAVY 3 REP BACK SQUAT"
        val block=BoardScanLiteParser.parse(header+"\n1 PUSH PRESS",catalog=catalog).blocks.single()
        val wire=BoardScanImport.wireBlock(block)
        assertEquals("maxEffort",wire.getString("wodFormat"))
        assertEquals(header,wire.getString("title"))
        assertEquals(3,wire.getInt("timeCapMinutes"))
        assertEquals(1,wire.getJSONArray("movements").length())
        assertFalse(wire.has("rounds"))
        assertTrue(wire.getString("wodNotes").contains(header))
    }
    @Test fun describedMaxEffortHeadersKeepSourceFormatInWire() {
        for(header in listOf("MAX LOAD CLEAN","MAX REPS PULL UPS","HEAVY SINGLE BACK SQUAT","1RM SNATCH")) {
            val block=BoardScanLiteParser.parse(header+"\n1 PUSH PRESS",catalog=catalog).blocks.single()
            val wire=BoardScanImport.wireBlock(block)
            assertEquals("maxEffort",wire.getString("wodFormat"))
            assertEquals(header,wire.getString("title"))
            assertEquals(1,wire.getJSONArray("movements").length())
            assertFalse(wire.has("rounds"))
            assertTrue(wire.getString("wodNotes").contains(header))
        }
    }
    @Test fun initialQualityHeaderKeepsFormatWithoutInventedRoundsInWire() {
        for(header in listOf("FOR QUALITY","RFQ","ROUNDS FOR QUALITY")) {
            val block=BoardScanLiteParser.parse(header+"\n2 AIR SQUAT",catalog=catalog).blocks.single()
            val wire=BoardScanImport.wireBlock(block)
            assertEquals("roundsForQuality",wire.getString("wodFormat"))
            assertEquals(header,wire.getString("title"))
            assertEquals(1,wire.getJSONArray("movements").length())
            assertFalse(wire.has("rounds"))
            assertFalse(wire.has("timeCapMinutes"))
            assertTrue(wire.getString("wodNotes").contains(header))
        }
    }
    @Test fun numberedRfqHeaderKeepsExplicitRoundsInWire() {
        val header="3 RFQ"
        val block=BoardScanLiteParser.parse(header+"\n2 AIR SQUAT",catalog=catalog).blocks.single()
        val wire=BoardScanImport.wireBlock(block)
        assertEquals("roundsForQuality",wire.getString("wodFormat"))
        assertEquals(3,wire.getInt("rounds"))
        assertEquals(1,wire.getJSONArray("movements").length())
        assertFalse(wire.has("timeCapMinutes"))
        assertTrue(wire.getString("wodNotes").contains(header))
    }
}
