import Testing
@testable import ReperaDomain

struct BoardScanLiteParserTests {
    @Test func importsActualScreenshotAsThreeEditableBlocks() {
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
        let result = BoardScanLiteParser.parse(ocrText: board, catalog: Catalog.seed())
        #expect(result.blocks.count == 3)

        let emom = result.blocks[0]
        #expect(emom.kind == .wod)
        #expect(emom.wodFormat == .emom)
        #expect(emom.timeCapMinutes == 8)
        #expect(emom.movements.count == 1)
        #expect(emom.movements.first?.exerciseId != nil)
        #expect(emom.wodNotes?.contains("@6-8") == true)

        let strength = result.blocks[1]
        #expect(strength.kind == .strength)
        #expect(strength.emomIntervalSeconds == 120)
        #expect(strength.timeCapMinutes == 8)
        #expect(strength.exercises.count == 1)
        #expect(strength.exercises.first?.plannedSets.map(\.targetReps) == [4, 3, 3, 2])
        #expect(strength.exercises.first?.plannedSets.first?.targetRir == 3.0)
        #expect(strength.wodNotes?.contains("BACK SQUAT @6-8") == true)

        let rft = result.blocks[2]
        #expect(rft.wodFormat == .forTime)
        #expect(rft.rounds == 4)
        #expect(rft.timeCapMinutes == 12)
        #expect(rft.restBetweenRoundsSeconds == 60)
        #expect(rft.movements.count == 4)
        #expect(rft.movements[0].weightMaleKg == 40)
        #expect(rft.movements[0].weightFemaleKg == 25)
        #expect(rft.movements[1].name == "Bar facing burpee")
        #expect(rft.movements[2].name == "Zancadas inversas con barra")
        #expect(rft.movements[2].exerciseId != nil)
        #expect(rft.movements[2].weightMaleKg == 40)
        #expect(rft.movements[2].weightFemaleKg == 25)
        #expect(rft.movements[3].isRest)
        #expect(rft.movements[3].restSeconds == 60)
    }

    @Test func keepsMultiStationEveryAsAnEmom() {
        let board = """
        EVERY 2' X 4
        5 POWER SNATCH 40/25
        8 BOB
        """
        let blocks = BoardScanLiteParser.parse(ocrText: board, catalog: Catalog.seed()).blocks
        #expect(blocks.count == 1)
        #expect(blocks[0].wodFormat == .emom)
        #expect(blocks[0].rounds == 4)
        #expect(blocks[0].emomIntervalSeconds == 120)
        #expect(blocks[0].movements.count == 2)
    }

    @Test func keepsUnmatchedWODMovementForManualReview() {
        let board = """
        3 RFT (TC 9')
        6 MYSTERY BARBELL MOVEMENT 30/20
        """
        let blocks = BoardScanLiteParser.parse(ocrText: board, catalog: Catalog.seed()).blocks
        #expect(blocks.count == 1)
        #expect(blocks[0].rounds == 3)
        #expect(blocks[0].timeCapMinutes == 9)
        #expect(blocks[0].movements.count == 1)
        #expect(blocks[0].movements[0].exerciseId == nil)
        #expect(blocks[0].movements[0].weightMaleKg == 30)
        #expect(blocks[0].movements[0].weightFemaleKg == 20)
    }

    /// Casuística real: Vision pegó RFT→RFf y BOB sin espacio; el 3.er bloque
    /// acababa como movimiento dentro del EVERY.
    @Test func splitsNoisyOCRBoardIntoThreeBlocksWithBOB() {
        let noisy = """
        EMOM 8' @6-8
        2 HIGH HSQ SNATCH
        EVERY 2' X 4
        4-3-3-2 BACK SQUAT @6-8
        4RFf(TC 12?
        6 POWER SNATCH 40/25
        8BOB
        10 BACK RACK R. LUNGES 40/25
        1' REST
        """
        let result = BoardScanLiteParser.parse(ocrText: noisy, catalog: Catalog.seed())
        #expect(result.blocks.count == 3)
        #expect(result.blocks[2].wodFormat == .forTime)
        #expect(result.blocks[2].rounds == 4)
        #expect(result.blocks[2].timeCapMinutes == 12)
        let work = result.blocks[2].movements.filter { !$0.isRest }
        #expect(work.count == 3)
        #expect(work[1].name == "Bar facing burpee")
        #expect(work[1].reps == 8)
        #expect(work[1].exerciseId != nil)
    }

    @Test func glossaryResolvesGluedBOB() {
        let parsed = CrossFitGlossary.parseMovementLine("8BOB")
        #expect(parsed.reps == 8)
        #expect(parsed.name == "Bar facing burpee")
        #expect(CrossFitGlossary.canonicalName(for: "BOB") == "Bar facing burpee")
        #expect(CrossFitGlossary.canonicalName(for: "burpee over the bar") == "Bar facing burpee")
    }
}
