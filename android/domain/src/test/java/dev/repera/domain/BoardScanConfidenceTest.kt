package dev.repera.domain

import org.junit.Assert.assertTrue
import org.junit.Test

class BoardScanConfidenceTest {
    @Test
    fun highScoreCleanMultiBlockBoard() {
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
        val catalog = emptyList<CatalogExercise>()
        val parsed = BoardScanLiteParser.parse(board, catalog)
        val assessment = BoardScanConfidence.assess(board, parsed)
        assertTrue(assessment.score >= 0.5)
        assertTrue(parsed.blocks.isNotEmpty())
    }

    @Test
    fun lowScoreCatchAllBlobTriggersRepairThreshold() {
        val board = """
            something weird
            more weird text
            still not a wod header
            random line four
            fifth line here
        """.trimIndent()
        val parsed = BoardScanLiteParser.parse(board, emptyList())
        val assessment = BoardScanConfidence.assess(board, parsed)
        assertTrue(assessment.score < BoardScanConfidence.Assessment.REPAIR_THRESHOLD)
    }

    @Test
    fun extraNormalizeFixesJerkTypo() {
        val cleaned = BoardScanLocalRepair.extraNormalize("5 PUSH JEK 40/25")
        assertTrue(cleaned.uppercase().contains("JERK"))
    }

    @Test
    fun localPipelineRunsWithoutCrash() {
        val result = BoardScanLocalPipeline.interpret(
            "4RFf (TC 12')\n8BOB\n6 POWER SNATCH 40/25"
        )
        assertTrue(result.blocks.isNotEmpty() || result.lines.isNotEmpty() || result.ocrText.isNotEmpty())
    }
}
