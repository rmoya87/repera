import Testing
import Foundation
@testable import ReperaDomain

struct BoardScanConfidenceTests {
    @Test func highScoreCleanMultiBlockBoard() {
        let board = """
        EMOM 8' @6-8
        2 HIGH HSQ SNATCH

        EVERY 2' X 4
        4-3-3-2 BACK SQUAT @6-8

        4 RFT (TC 12')
        6 POWER SNATCH 40/25
        8 BOB
        10 BACK RACK R. LUNGES 40/25
        1' REST
        """
        let parsed = BoardScanLiteParser.parse(ocrText: board, catalog: Catalog.seed())
        let assessment = BoardScanConfidence.assess(ocrText: board, output: parsed)
        #expect(assessment.score >= 0.85)
        #expect(parsed.blocks.count >= 2)
    }

    @Test func lowScoreCatchAllBlob() {
        let board = """
        something weird
        more weird text
        still not a wod header
        random line four
        fifth line here
        """
        let parsed = BoardScanLiteParser.parse(ocrText: board, catalog: [])
        let assessment = BoardScanConfidence.assess(ocrText: board, output: parsed)
        #expect(assessment.score < 0.85)
        #expect(assessment.reasons.contains("catch_all_block") || assessment.reasons.contains("catalog_match_low") || assessment.reasons.contains("untyped_movements"))
    }

    @Test func localPipelineRepairsOCRNoise() {
        let noisy = """
        4RFf (TC 12')
        8BOB
        6 POWER SNATCH 40/25
        """
        let result = BoardScanLocalPipeline.interpret(ocrText: noisy, catalog: Catalog.seed())
        #expect(result.blocks.count >= 1)
        #expect(result.ocrText.uppercased().contains("RFT"))
        #expect(!result.confidence.reasons.contains("ocr_noise"))
        #expect(result.didRepair)
    }

    @Test func extraNormalizeFixesJerkTypo() {
        let cleaned = BoardScanLocalRepair.extraNormalize("5 PUSH JEK 40/25")
        #expect(cleaned.uppercased().contains("JERK"))
    }
}
