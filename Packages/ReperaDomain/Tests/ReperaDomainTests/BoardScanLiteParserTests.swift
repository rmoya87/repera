import Testing
@testable import ReperaDomain

struct BoardScanLiteParserTests {
    @Test func scanAmrapAndForTimeWithCapButNoInventedRounds() {
        let board = """
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
        """
        let result = BoardScanLiteParser.parse(ocrText: board, catalog: Catalog.seed())
        #expect(result.blocks.count == 2)

        let amrap = result.blocks[0]
        #expect(amrap.wodFormat == .amrap)
        #expect(amrap.timeCapMinutes == 16)
        #expect(amrap.movements.count == 5)
        #expect(amrap.movements[0].name == "Ground to overhead")
        #expect(amrap.movements[0].exerciseId != nil)
        #expect(amrap.movements[0].reps == 3)
        #expect(amrap.movements[0].weightMaleKg == 60)
        #expect(amrap.movements[0].weightFemaleKg == 40)
        #expect(amrap.movements[1].name == "Muscle-up barra")
        #expect(amrap.movements[1].exerciseId != nil)
        #expect(amrap.movements[1].scaleAlternative?.contains("Chest to bar") == true)
        #expect(amrap.movements[1].scaleAlternative?.contains("Dominadas") == true)
        #expect(amrap.movements[3].name == "Swing americano")
        #expect(amrap.movements[3].exerciseId != nil)
        #expect(amrap.movements[3].weightMaleKg == 24)
        #expect(amrap.movements[3].weightFemaleKg == 16)
        #expect(amrap.movements[4].name == "Dobles de comba")
        #expect(amrap.movements[4].scaleAlternative?.contains("Simples de comba") == true)

        let forTime = result.blocks[1]
        #expect(forTime.wodFormat == .forTime)
        #expect(forTime.timeCapMinutes == 14)
        #expect(forTime.rounds == nil)
        #expect(forTime.movements.count == 5)
        #expect(forTime.movements[0].distanceMeters == 400)
        #expect(forTime.movements[2].distanceMeters == 400)
        #expect(forTime.movements[4].distanceMeters == 400)
        #expect(forTime.movements[1].name == "Air bike")
        #expect(forTime.movements[1].exerciseId != nil)
        #expect(forTime.movements[1].calories == 20)
        #expect(forTime.movements[1].weightMaleKg == nil)
        #expect(forTime.movements[1].weightFemaleKg == nil)
        #expect(forTime.movements[1].notes?.contains("16") == true)
        #expect(forTime.movements[3].calories == 20)
        #expect(forTime.restBetweenRoundsSeconds == 60)
        #expect(forTime.wodNotes?.contains("REST BTWN") == true)
    }

    @Test func fullNamesAndAcronymsShareCanonicalExercises() {
        #expect(CrossFitGlossary.canonicalName(for: "GTOH") == "Ground to overhead")
        #expect(CrossFitGlossary.canonicalName(for: "ground-to-overhead") == "Ground to overhead")
        #expect(CrossFitGlossary.canonicalName(for: "BMU") == "Muscle-up barra")
        #expect(CrossFitGlossary.canonicalName(for: "bar muscle up") == "Muscle-up barra")
        #expect(CrossFitGlossary.canonicalName(for: "AKBS") == "Swing americano")
        #expect(CrossFitGlossary.canonicalName(for: "american kettlebell swing") == "Swing americano")
        let calories = CrossFitGlossary.parseMovementLine("20/16 CAL*")
        #expect(calories.name == "Air bike")
        #expect(calories.calories == 20)
        #expect(calories.weightMaleKg == nil)
        #expect(calories.weightFemaleKg == nil)
    }

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
