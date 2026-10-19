import Testing
@testable import ReperaDomain

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

    @Test func recognizesReperaScreenshotMovements() {
        let catalog = Catalog.seed()
        let blocks = BoardImportParser.parseBlocks(
            ocrText: """
            EMOM 8’ @6-8
            2 HIGH HSQ SNATCH

            EVERY 2’ X 4
            4-3-3-2 BACK SQUAT @6-8

            4 RFT (TC 12’)
            6 POWER SNATCH 40/25
            8 BOB
            10 BACK RACK R. LUNGES 40/25
            1’ REST
            """,
            catalog: catalog
        )
        #expect(blocks.count == 3)
        #expect(blocks[0].movements.first?.name == "Arrancada colgante completa")
        #expect(blocks[1].kind == .strength)
        #expect(blocks[1].exercises.first?.plannedSets.map(\.targetReps) == [4, 3, 3, 2])
        #expect(blocks[1].exercises.count == 1)
        #expect(blocks[2].rounds == 4)
        #expect(blocks[2].timeCapMinutes == 12)
        #expect(blocks[2].movements.count == 4)
        #expect(blocks[2].movements[2].name == "Zancadas inversas con barra")
        #expect(blocks[2].movements[2].exerciseId != nil)
        #expect(blocks[2].movements[2].weightMaleKg == 40)
        #expect(blocks[2].movements[2].weightFemaleKg == 25)
        #expect(blocks[2].movements[3].restSeconds == 60)
    }


    @Test func importsReperaUserBoardWithTimedStrengthAndReverseLunge() {
        let catalog = Catalog.seed()
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
        let blocks = BoardImportParser.parseBlocks(ocrText: board, catalog: catalog)
        #expect(blocks.count == 3)
        #expect(blocks[0].wodFormat == .emom)
        #expect(blocks[0].timeCapMinutes == 8)
        #expect(blocks[0].movements.first?.exerciseId != nil)

        let strength = blocks[1]
        #expect(strength.kind == .strength)
        #expect(strength.emomIntervalSeconds == 120)
        #expect(strength.exercises.count == 1)
        #expect(strength.exercises.first?.plannedSets.map(\.targetReps) == [4, 3, 3, 2])
        #expect(strength.exercises.first?.plannedSets.first?.targetRir == 3)
        #expect(strength.wodNotes?.contains("@6-8") == true)

        let rft = blocks[2]
        #expect(rft.wodFormat == .forTime)
        #expect(rft.rounds == 4)
        #expect(rft.timeCapMinutes == 12)
        let work = rft.movements.filter { !$0.isRest }
        #expect(work.count == 3)
        #expect(work[0].weightMaleKg == 40)
        #expect(work[0].weightFemaleKg == 25)
        #expect(CrossFitGlossary.canonicalName(for: "Bar facing burpee") == "Bar facing burpee")
        #expect(work[1].name == "Bar facing burpee")
        #expect(work[2].name == "Zancadas inversas con barra")
        #expect(work[2].exerciseId != nil)
        #expect(rft.movements.last?.restSeconds == 60)
    }

    @Test func glossaryExpandsDU() {
        let expanded = CrossFitGlossary.expand("50 DU")
        #expect(expanded.lowercased().contains("doble") || expanded.lowercased().contains("comba"))
        #expect(CrossFitGlossary.canonicalName(for: "OHSQ") == "Overhead squat")
    }

    @Test func glossaryCleansBoardNoiseForLookup() {
        #expect(CrossFitGlossary.canonicalName(for: "W.S. Dominadas @RIR 2-1") == "Dominadas")
        #expect(CrossFitGlossary.canonicalName(for: "KIPPING HSPU @FQ") == "HSPU")
        #expect(CrossFitGlossary.canonicalName(for: "6-8 DB ALT Arrancada colgante") == "Arrancada colgante")
    }

    @Test func dbHangSnatchMapsToDumbbellSnatch() {
        let line = CrossFitGlossary.parseMovementLine("6-8 DB ALT HANG SNATCH")
        #expect(line.name == "Snatch mancuerna")
        #expect(line.equipmentNote?.localizedCaseInsensitiveContains("mancuerna") == true)
        #expect(CrossFitGlossary.canonicalName(for: "db hang snatch") == "Snatch mancuerna")
        #expect(CrossFitGlossary.resolveCatalogName("Arrancada colgante", notes: "Mancuerna") == "Snatch mancuerna")
    }

    @Test func equipmentVariantsMapToCatalogExercises() {
        #expect(CrossFitGlossary.resolveCatalogName("Thruster", notes: "Mancuerna") == "Thruster mancuernas")
        #expect(CrossFitGlossary.resolveCatalogName("Thruster", notes: "Doble mancuerna") == "Thruster mancuernas")
        #expect(CrossFitGlossary.resolveCatalogName("Thruster", notes: "Kettlebell") == "Thruster kettlebell")
        #expect(CrossFitGlossary.resolveCatalogName("Cargada", notes: "Mancuerna") == "Clean mancuerna")
        #expect(CrossFitGlossary.resolveCatalogName("Arrancada", notes: "Kettlebell") == "Snatch kettlebell")
        #expect(CrossFitGlossary.resolveCatalogName("Press banca", notes: "Mancuerna") == "Press mancuernas")
        #expect(CrossFitGlossary.resolveCatalogName("Snatch mancuerna", notes: "Barra") == "Arrancada")
        #expect(CrossFitGlossary.canonicalName(for: "db thruster") == "Thruster mancuernas")
        #expect(CrossFitGlossary.canonicalName(for: "kb snatch") == "Snatch kettlebell")

        let thruster = CrossFitGlossary.parseMovementLine("10 DB THRUSTER 20/12,5")
        #expect(thruster.name == "Thruster mancuernas")
        #expect(thruster.equipmentNote?.localizedCaseInsensitiveContains("mancuerna") == true)
    }

    @Test func parseMovementLineSplitsRepsMetersEquipment() {
        let t2b = CrossFitGlossary.parseMovementLine("10 toes to bar")
        #expect(t2b.name == "Toes to bar")
        #expect(t2b.reps == 10)
        #expect(t2b.distanceMeters == nil)

        let run = CrossFitGlossary.parseMovementLine("200M RUN")
        #expect(run.name == "Cinta / carrera")
        #expect(run.distanceMeters == 200)
        #expect(run.reps == nil)

        let cinta = CrossFitGlossary.parseMovementLine("200m cinta/carrera")
        #expect(cinta.name == "Cinta / carrera")
        #expect(cinta.distanceMeters == 200)

        let ddb = CrossFitGlossary.parseMovementLine("5 DDB DEVIL PRESS 20/12,5")
        #expect(ddb.name == "Devil press")
        #expect(ddb.reps == 5)
        #expect(ddb.equipmentNote == "Doble mancuerna")
        #expect(ddb.weightMaleKg == 20)
        #expect(ddb.weightFemaleKg == 12.5)

        // Orden invertido: el mayor sigue siendo hombre.
        let swapped = CrossFitGlossary.parseMovementLine("5 DEVIL PRESS 12,5/20")
        #expect(swapped.weightMaleKg == 20)
        #expect(swapped.weightFemaleKg == 12.5)
    }

    @Test func parseMovementLineTreats5to10AsRangeNotWave() {
        let hspu = CrossFitGlossary.parseMovementLine("5-10 KIPPING HSPU @FQ")
        #expect(hspu.name == "HSPU")
        #expect(hspu.repScheme == nil)
        #expect(hspu.reps == 10)
        #expect(hspu.equipmentNote?.contains("5-10") == true)

        let wave = CrossFitGlossary.parseMovementLine("4-3-3-2 W.S. PULL UPS @RIR 2-1")
        #expect(wave.repScheme == [4, 3, 3, 2])
        #expect(wave.name == "Dominadas")
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
        // 3 estaciones (push, deadlift, rest) → 12/3 = 4 vueltas
        #expect(blocks[0].rounds == 4)
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

    @Test func derivesEmomRoundsFromStations() {
        let catalog = Catalog.seed()
        let text = """
        EMOM 12'
        4-3-3-2 W.S. PULL UPS @RIR 2-1
        5-10 KIPPING HSPU @FQ
        1' REST

        EMOM 8'
        6-8 DB ALT HANG SNATCH @HEAVY
        45\" MAX DU

        AMRAP 12'
        5 DDB DEVIL PRESS 20/12,5
        10 T2B
        200M RUN
        """
        let blocks = BoardImportParser.parseBlocks(ocrText: text, catalog: catalog)
        #expect(blocks.count == 3)
        #expect(blocks[0].wodFormat == .emom)
        #expect(blocks[0].timeCapMinutes == 12)
        #expect(blocks[0].rounds == 4)
        #expect(blocks[0].emomTimerIntervals == 12)
        #expect(blocks[1].wodFormat == .emom)
        #expect(blocks[1].timeCapMinutes == 8)
        #expect(blocks[1].rounds == 4)
        #expect(blocks[2].wodFormat == .amrap)
        #expect(blocks[2].timeCapMinutes == 12)
    }

    @Test func parsesOrphanStrengthThenWOD() {
        let catalog = Catalog.seed()
        let text = """
        5x5 BACK SQUAT
        3x8 BENCH PRESS

        AMRAP 10'
        10 THRUSTERS
        10 PULL UPS
        """
        let blocks = BoardImportParser.parseBlocks(ocrText: text, catalog: catalog)
        #expect(blocks.count >= 2)
        let strength = blocks[0]
        #expect(strength.kind == .strength || strength.wodFormat == .strength)
        #expect(blocks.contains { $0.wodFormat == .amrap })
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
