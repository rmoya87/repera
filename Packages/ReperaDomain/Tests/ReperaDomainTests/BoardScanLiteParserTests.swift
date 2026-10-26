import Testing
@testable import ReperaDomain

struct BoardScanLiteParserTests {
    @Test func mixedCaseBTTAndT2BPreferOfficialCatalogWhenOldCustomExists() {
        let catalog = Catalog.seed()
        guard let btt = catalog.first(where: { $0.name == "Burpee to target" }),
              let t2b = catalog.first(where: { $0.name == "Toes to bar" }) else {
            Issue.record("Faltan ejercicios en el catálogo del paquete")
            return
        }
        let oldBTT = Exercise(name: "Burpee to target", muscleGroup: "Custom", isCustom: true)
        let oldT2B = Exercise(name: "Toes to bar", muscleGroup: "Custom", isCustom: true)
        let blocks = BoardScanLiteParser.parse(
            ocrText: "AMRAP 15'\n6 BTt\n8 T2B",
            catalog: [oldBTT, oldT2B] + catalog
        ).blocks
        #expect(blocks.count == 1)
        #expect(blocks.first?.movements.count == 2)
        #expect(blocks.first?.movements.first?.name == "Burpee to target")
        #expect(blocks.first?.movements.first?.exerciseId == btt.id)
        #expect(blocks.first?.movements.last?.name == "Toes to bar")
        #expect(blocks.first?.movements.last?.exerciseId == t2b.id)
    }

    @Test func photographedNinetySecondComplexAndSnatchBalanceWave() {
        let board = """
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
        """
        let catalog = Catalog.seed()
        let result = BoardScanLiteParser.parse(ocrText: board, catalog: catalog)
        #expect(result.blocks.count == 3)
        guard result.blocks.count == 3 else { return }

        let complex = result.blocks[0]
        #expect(complex.kind == .strength)
        #expect(complex.emomIntervalSeconds == 90)
        #expect(complex.timeCapMinutes == 9)
        #expect(complex.exercises.count == 3)
        #expect(complex.exercises.allSatisfy {
            $0.plannedSets.count == 6
                && $0.plannedSets.allSatisfy { $0.targetReps == 1 && $0.targetRir == 3 }
        })
        let complexNames = complex.exercises.compactMap { entry in
            catalog.first(where: { $0.id == entry.exerciseId })?.name
        }
        #expect(complexNames == ["Clean Pull", "Hang power clean", "Clean"])
        #expect(complex.wodNotes?.contains("T&G SQUAT CLEAN") == true)

        let snatch = result.blocks[1]
        #expect(snatch.kind == .strength)
        #expect(snatch.emomIntervalSeconds == 120)
        #expect(snatch.exercises.count == 1)
        #expect(snatch.exercises.first?.plannedSets.map(\.targetReps) == [3, 3, 2, 2])
        #expect(snatch.exercises.first?.plannedSets.first?.targetRir == 3)
        let snatchName = snatch.exercises.first.flatMap { entry in
            catalog.first(where: { $0.id == entry.exerciseId })?.name
        }
        #expect(snatchName == "Snatch Balance")

        let amrap = result.blocks[2]
        #expect(amrap.wodFormat == .amrap)
        #expect(amrap.timeCapMinutes == 12)
        #expect(amrap.movements.count == 4)
        #expect(amrap.movements.allSatisfy { $0.exerciseId != nil })
        #expect(amrap.movements[0].name == "Power Clean")
        #expect(amrap.movements[0].reps == 5)
        #expect(amrap.movements[0].weightMaleKg == 50)
        #expect(amrap.movements[0].weightFemaleKg == 35)
        #expect(amrap.movements[1].reps == 5)
        #expect(amrap.movements[2].reps == 10)
        #expect(amrap.movements[3].name == "Run")
        #expect(amrap.movements[3].distanceMeters == 100)

        let session = SessionController.from(
            routine: Routine(title: "Pizarra fotografiada", blocks: result.blocks),
            exercises: catalog
        )
        #expect(session.exercises.count == 8)
        #expect(session.exercises.filter { $0.blockId == complex.id }.count == 3)
        #expect(session.exercises.filter { $0.blockId == complex.id }
            .allSatisfy { $0.plannedSets.count == 6 })
    }

    @Test func scanEnglishCompoundNamesHaveDistinctCanonicalMatches() {
        let catalog = Catalog.seed()
        let names = ["CLEAN PULL", "HANG POWER CLEAN", "SQUAT CLEAN", "SNATCH BALANCE"]
        let expected = ["Clean Pull", "Hang power clean", "Clean", "Snatch Balance"]
        for (input, output) in zip(names, expected) {
            let b = BoardScanLiteParser.parse(
                ocrText: "AMRAP 10'\n5 \(input)", catalog: catalog
            ).blocks
            #expect(b.count == 1)
            #expect(b.first?.movements.first?.name == output)
            #expect(b.first?.movements.first?.exerciseId != nil)
        }
    }

    @Test func spacedSexSpecificCaloriesDoNotBecomeScalingAlternatives() {
        let blocks = BoardScanLiteParser.parse(ocrText: """
            FOR TIME (TC 14')
            400M RUN
            20 / 16 CAL*
            400M RUN
            """, catalog: Catalog.seed()).blocks
        #expect(blocks.count == 1)
        #expect(blocks[0].wodFormat == .forTime)
        #expect(blocks[0].timeCapMinutes == 14)
        #expect(blocks[0].rounds == nil)
        #expect(blocks[0].movements.count == 3)
        #expect(blocks[0].movements[1].name == "Air bike")
        #expect(blocks[0].movements[1].calories == 20)
        #expect(blocks[0].movements[1].scaleAlternative == nil)
        #expect(blocks[0].movements[1].weightMaleKg == nil)
        #expect(blocks[0].plannedSets(for: blocks[0].movements[1]).count == 1)
    }


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
        #expect(amrap.movements[3].name == "American Kettlebell Swing")
        #expect(amrap.movements[3].exerciseId != nil)
        #expect(amrap.movements[3].weightMaleKg == 24)
        #expect(amrap.movements[3].weightFemaleKg == 16)
        #expect(amrap.movements[4].name == "Double-Under")
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
        // Iniciar Play no debe convertir un TC de 14 min en 14 series por ejercicio.
        let session = SessionController.from(
            routine: Routine(title: "Pizarra", blocks: result.blocks),
            exercises: Catalog.seed()
        )
        #expect(session.exercises.count == 10)
        #expect(session.exercises.filter { $0.blockId == forTime.id }.count == 5)
        #expect(session.exercises.filter { $0.blockId == forTime.id }
            .allSatisfy { $0.plannedSets.count == 1 })
    }

    @Test func uniqueGlossaryMappingsPreferSpecificExercises() {
        // Las variantes de OCR tienen un único destino. No colapsar RUN en cinta de correr.
        #expect(CrossFitGlossary.canonicalName(for: "RUN") == "Carrera")
        #expect(CrossFitGlossary.canonicalName(for: "RUNNING") == "Carrera")
        #expect(CrossFitGlossary.canonicalName(for: "RUNS") == "Carrera")
        #expect(CrossFitGlossary.canonicalName(for: "CINTA") == "Cinta / carrera")
        #expect(CrossFitGlossary.canonicalName(for: "AMERICAN SWING") == "Swing americano")
        #expect(CrossFitGlossary.canonicalName(for: "DEADLIFT") == "Peso muerto")
        #expect(CrossFitGlossary.canonicalName(for: "BURPEES OVER THE BAR") == "Bar facing burpee")
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
        #expect(rft.movements[2].name == "Back rack reverse lunge")
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
    @Test func importsQualityEmomAndSpecificMovementsFromActualBoard() {
        let photo = """
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
        """
        let catalog = Catalog.seed()
        let result = BoardScanLiteParser.parse(ocrText: photo, catalog: catalog)
        #expect(result.blocks.count == 3)

        let strength = result.blocks[0]
        #expect(strength.wodFormat == .emom)
        #expect(strength.timeCapMinutes == 12)
        #expect(strength.movements.count == 3)
        #expect(strength.movements[0].repScheme == [4, 3, 3, 2])
        #expect(strength.movements[0].notes?.contains("RPE 7-8") == true)
        #expect(strength.movements[1].name == "Peso muerto")
        #expect(strength.movements[1].notes?.contains("Touch & go") == true)
        #expect(strength.movements[2].restSeconds == 60)

        let quality = result.blocks[1]
        #expect(quality.wodFormat == .emom)
        #expect(quality.timeCapMinutes == 9)
        #expect(quality.wodNotes?.contains("FOR QUALITY") == true)
        #expect(quality.movements.count == 3) // 2 ejercicios + descanso; QUALITY no es ejercicio.
        #expect(quality.movements[0].name == "Fondos en anillas kipping")
        #expect(quality.movements[0].exerciseId != nil)
        #expect(quality.movements[0].reps == 10)
        #expect(quality.movements[0].notes?.contains("5-10") == true)
        #expect(quality.movements[1].name == "Pistol squat")
        #expect(quality.movements[1].notes?.contains("Alternando") == true)
        #expect(quality.movements[1].notes?.contains("6-10") == true)
        #expect(quality.movements[2].restSeconds == 60)

        let amrap = result.blocks[2]
        #expect(amrap.wodFormat == .amrap)
        #expect(amrap.timeCapMinutes == 8)
        #expect(amrap.movements.count == 2)
        #expect(amrap.movements[0].name == "Dumbbell Clean and Jerk")
        #expect(amrap.movements[0].exerciseId != nil)
        #expect(amrap.movements[0].weightMaleKg == 22.5)
        #expect(amrap.movements[0].weightFemaleKg == 15)
        #expect(amrap.movements[0].notes?.contains("Alternando") == true)
        #expect(amrap.movements[1].name == "Burpee box jump over")
        #expect(amrap.movements[1].exerciseId != nil)
        #expect(amrap.movements[1].reps == 10)
        #expect(amrap.movements[1].name != "Box jump over")
    }

    @Test func qualityNotesDoNotSpawnGhostExercisesAndOCRBBJZeroIsCorrected() {
        let board = """
        EMOM 9'
        @FOR QUALITY
        5 KIPPING RING DIPS
        10BBJ0

        3 ROUNDS FOR QUALITY
        6 RING DIPS
        """
        let result = BoardScanLiteParser.parse(ocrText: board, catalog: Catalog.seed())
        #expect(result.blocks.count == 2)
        #expect(result.blocks[0].movements.count == 2)
        #expect(result.blocks[0].movements[0].name == "Fondos en anillas kipping")
        #expect(result.blocks[0].movements[1].name == "Burpee box jump over")
        #expect(result.blocks[0].movements[1].reps == 10)
        #expect(result.blocks[1].wodFormat == .roundsForQuality)
        #expect(result.blocks[1].rounds == 3)
        #expect(result.blocks[1].movements.count == 1)
        #expect(result.blocks[1].movements[0].name == "Fondos en anillas")
        #expect(result.blocks[1].movements[0].exerciseId != nil)
    }

}
