import Testing
@testable import GymbroDomain

struct BoardImportParserTests {
    @Test func parsesSetsRepsAndWeight() {
        let catalog = Catalog.seed()
        let lines = BoardImportParser.parse(
            ocrText: """
            Bench Press 3x8 @60
            Squat 4×5
            Face Pulls
            """,
            catalog: catalog
        )
        #expect(lines.count == 3)
        #expect(lines[0].sets == 3)
        #expect(lines[0].reps == 8)
        #expect(lines[0].weightKg == 60)
        #expect(lines[1].sets == 4)
        #expect(lines[1].reps == 5)
    }

    @Test func buildsRoutineAndCustomExercises() {
        var catalog = Catalog.seed()
        let lines = [
            BoardImportLine(raw: "Mystery Curl 3x12", matchedName: "Mystery Curl", sets: 3, reps: 12),
        ]
        let routine = BoardImportParser.buildRoutine(title: "Board", lines: lines, catalog: &catalog)
        #expect(routine.exercises.count == 1)
        #expect(catalog.contains { $0.name == "Mystery Curl" && $0.isCustom })
    }

    @Test func parsesAMRAPWOD() {
        let catalog = Catalog.seed()
        let text = """
        AMRAP 12'
        5 HANG SQUAT CLEAN 50/35
        10 WALL BALL 12/9
        5 POWER CLEAN 50/35
        50 DU / 100 SU
        """
        let block = BoardImportParser.parseWODBlock(ocrText: text, catalog: catalog)
        #expect(block != nil)
        #expect(block?.wodFormat == .amrap)
        #expect(block?.timeCapMinutes == 12)
        #expect(block?.movements.count == 4)
        #expect(block?.movements.first?.reps == 5)
        #expect(block?.movements.first?.weightMaleKg == 50)
        #expect(block?.movements.last?.scaleAlternative != nil)
    }

    @Test func parsesRFTWithRest() {
        let catalog = Catalog.seed()
        let text = """
        4 RFT (TC 12')
        300M RUN AFAP
        1' REST
        """
        let block = BoardImportParser.parseWODBlock(ocrText: text, catalog: catalog)
        #expect(block != nil)
        #expect(block?.wodFormat == .forTime)
        #expect(block?.rounds == 4)
        #expect(block?.timeCapMinutes == 12)
        #expect(block?.movements.contains(where: \.isRest) == true)
        #expect(block?.movements.contains(where: { $0.distanceMeters == 300 }) == true)
    }

    @Test func parsesThreeBoardBlocks() {
        let catalog = Catalog.seed()
        let text = """
        EMOM 8'
        2 HIGH HANG SQUAT CLEAN @6-8

        EVERY 2' X 4
        3X 1 PUSH PRESS BN + 1 OHSQ @6-8

        AMRAP 12'
        5 HANG SQUAT CLEAN 50/35
        10 WALL BALL 12/9
        5 POWER CLEAN 50/35
        50 DU / 100 SU
        """
        let blocks = BoardImportParser.parseBlocks(ocrText: text, catalog: catalog)
        #expect(blocks.count == 3)
        #expect(blocks[0].wodFormat == .emom)
        #expect(blocks[0].timeCapMinutes == 8)
        #expect(blocks[0].movements.count == 1)
        #expect(blocks[1].wodFormat == .emom)
        #expect(blocks[1].emomIntervalSeconds == 120)
        #expect(blocks[1].rounds == 4)
        // Complejo Push press BN + OHSQ → 2 movimientos tipados
        #expect(blocks[1].movements.count >= 2)
        #expect(blocks[2].wodFormat == .amrap)
        #expect(blocks[2].movements.count == 4)
        #expect(blocks[2].movements.last?.scaleAlternative != nil)
    }

    @Test func glossaryExpandsDU() {
        let expanded = CrossFitGlossary.expand("50 DU")
        #expect(expanded.lowercased().contains("doble") || expanded.lowercased().contains("comba"))
        #expect(CrossFitGlossary.canonicalName(for: "OHSQ") == "Overhead squat")
    }

    @Test func parsesWaveRepSchemeInsideEMOM() {
        let catalog = Catalog.seed()
        let text = """
        EMOM 12'
        4-4-3-3 PUSH PRESS @7-8
        3 DEADLIFT T&G @6-8
        1' REST

        EVERY 5' X 4
        10 THRUSTERS 45/30
        15 PULL UPS
        200M RUN
        15 AMERICAN KB SWING 24/16
        10 CAL
        """
        let blocks = BoardImportParser.parseBlocks(ocrText: text, catalog: catalog)
        #expect(blocks.count == 2)
        #expect(blocks[0].wodFormat == .emom)
        #expect(blocks[0].timeCapMinutes == 12)
        // 4-4-3-3 es movimiento, NO cabecera ladder
        #expect(blocks[0].title != "4-4-3-3 PUSH PRESS @7-8")
        let push = blocks[0].movements.first { !$0.isRest }
        #expect(push?.repScheme == [4, 4, 3, 3])
        #expect(push?.name == "Push press")
        #expect(push?.exerciseId != nil)
        let deadlift = blocks[0].movements.first { $0.name.localizedCaseInsensitiveContains("muerto") || $0.name.localizedCaseInsensitiveContains("dead") }
        #expect(deadlift?.exerciseId != nil)
        #expect(blocks[0].movements.contains(where: { $0.isRest }))
        #expect(blocks[1].wodFormat == .emom)
        #expect(blocks[1].emomIntervalSeconds == 300)
        #expect(blocks[1].rounds == 4)
        let thruster = blocks[1].movements.first { $0.name.localizedCaseInsensitiveContains("Thruster") }
        #expect(thruster?.exerciseId != nil)
        #expect(blocks[1].movements.filter { !$0.isRest }.count >= 4)
    }

    @Test func parsesExtendedBoardStructures() {
        let catalog = Catalog.seed()
        let text = """
        STRENGTH
        5x2 BACK SQUAT @7

        21-15-9
        THRUSTER 40/30
        PULL-UP

        E2MOM 10'
        5 POWER CLEAN

        PARTNER WOD
        100 CAL ROW
        """
        let blocks = BoardImportParser.parseBlocks(ocrText: text, catalog: catalog)
        #expect(blocks.count >= 3)
        #expect(blocks.contains { $0.wodFormat == .strength })
        #expect(blocks.contains { $0.wodFormat == .ladder })
        #expect(blocks.contains { $0.wodFormat == .emom })
        #expect(blocks.contains { $0.wodFormat == .partner })
        if let e2 = blocks.first(where: { $0.wodFormat == .emom && ($0.emomIntervalSeconds ?? 0) == 120 }) {
            #expect(e2.timeCapMinutes == 10)
        }
    }

    @Test func parsesWeightliftingAndMetconBoard() {
        let catalog = Catalog.seed()
        let text = """
        Weightlifting "Squat Clean Work"
        Every 90s For 12min (8 Series)
        Sets 1-2: 3 Squat Clean #70%
        Sets 3-4: 2 Squat Clean #75%
        Sets 5-8: 1 Squat Clean #>80%
        *NO Touch & Go. Trabaja a singles
        22:02

        Metcon
        For Time: (20min Cap)
        Round 1
        750m Run
        15 Overhead squat #40/25kg
        15 Push Jek #40/25kg
        15 Burpee Over the Bar
        Round 2
        500m Run
        12 Overhead squat #50/35kg
        12 Push Jerk #50/35kg
        12 Burpee Over the Bar
        Round 3
        250m Run
        9 Overhead squat #60/40kg
        9 Push Jerk #60/40kg
        9 Burpee Over the Bar
        """
        let blocks = BoardImportParser.parseBlocks(ocrText: text, catalog: catalog)
        #expect(blocks.count == 2)

        let lift = blocks[0]
        #expect(lift.wodFormat == .emom)
        #expect(lift.title.localizedCaseInsensitiveContains("Squat Clean"))
        #expect(lift.emomIntervalSeconds == 90)
        #expect(lift.timeCapMinutes == 12)
        #expect(lift.rounds == 8)
        #expect(lift.movements.filter { !$0.isRest }.count == 3)
        #expect(lift.movements.contains { ($0.notes ?? "").contains("70%") })
        #expect(lift.wodNotes?.localizedCaseInsensitiveContains("Touch") == true)

        let metcon = blocks[1]
        #expect(metcon.wodFormat == .forTime)
        #expect(metcon.title.localizedCaseInsensitiveContains("Metcon") || metcon.title == "Metcon")
        #expect(metcon.timeCapMinutes == 20)
        let work = metcon.movements.filter { !$0.isRest }
        #expect(work.count == 12)
        #expect(work.contains { $0.distanceMeters == 750 })
        #expect(work.contains { $0.distanceMeters == 250 })
        let ohs = work.first { $0.name.localizedCaseInsensitiveContains("Overhead") }
        #expect(ohs?.weightMaleKg == 40)
        #expect(ohs?.weightFemaleKg == 25)
        #expect(work.contains { $0.name.localizedCaseInsensitiveContains("jerk") || $0.name.localizedCaseInsensitiveContains("Jerk") })
        #expect(work.contains { ($0.notes ?? "").localizedCaseInsensitiveContains("Ronda 1") })
        #expect(work.contains { ($0.notes ?? "").localizedCaseInsensitiveContains("Ronda 3") })
    }
}
