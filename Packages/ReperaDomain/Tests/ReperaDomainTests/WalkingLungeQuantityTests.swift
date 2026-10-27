import XCTest
@testable import ReperaDomain

final class WalkingLungeQuantityTests: XCTestCase {
    func testWalkingLungeAllowsWeightWithEitherQuantityUnit() {
        for title in ["Walking lunge", "Walking lunges", "Walking lung", "Zancadas caminando"] {
            let exercise = Exercise(name: title, muscleGroup: "Piernas", equipment: "Peso corporal")
            XCTAssertTrue(exercise.supportsWeightedRepsOrMeters, title)
            XCTAssertEqual(exercise.loggingStyle, .loadAndReps, title)
            XCTAssertEqual(exercise.loadField, .weightKg, title)
            XCTAssertEqual(exercise.defaultQuantityUnit, .reps, title)
        }
    }

    func testOtherLoadedDistanceExercisesSupportKgAndMetres() {
        for (name, unit) in [
            ("Sandbag Lunges", ExerciseQuantityUnit.meters),
            ("Farmer carry", .meters), ("Farmer walk", .meters),
            ("Yoke carry", .meters), ("Sled push", .meters), ("Sled pull", .meters)
        ] {
            let exercise = Exercise(name: name, muscleGroup: "Piernas", equipment: "Trineo")
            XCTAssertTrue(exercise.supportsWeightedRepsOrMeters, name)
            XCTAssertTrue(exercise.supportsRepsOrMeters, name)
            XCTAssertEqual(exercise.loggingStyle, .loadAndReps, name)
            XCTAssertEqual(exercise.loadField, .weightKg, name)
            XCTAssertEqual(exercise.defaultQuantityUnit, unit, name)
        }
        for name in ["Bear crawl", "Burpee Broad Jump"] {
            let exercise = Exercise(name: name, muscleGroup: "Cardio", equipment: "Peso corporal")
            XCTAssertTrue(exercise.supportsRepsOrMeters, name)
            XCTAssertFalse(exercise.supportsWeightedRepsOrMeters, name)
            XCTAssertEqual(exercise.loadField, .none, name)
        }
    }

    func testOtherLungesDoNotGainDistanceToggleAutomatically() {
        let exercise = Exercise(name: "Zancadas inversas con barra", muscleGroup: "Piernas")
        XCTAssertFalse(exercise.supportsWeightedRepsOrMeters)
    }

    func testMetersAndRepsKeepWeightAndUnitSeparately() throws {
        let distance = LoggedSet(reps: 20, weightKg: 16, quantityUnit: .meters)
        let repetitions = LoggedSet(reps: 12, weightKg: 20, quantityUnit: .reps)
        XCTAssertEqual(distance.displaySummaryLine, "20 m · 16 kg")
        XCTAssertEqual(repetitions.weightKg, 20)
        XCTAssertEqual(repetitions.quantityUnit, .reps)
        // No interpretar metros × kg como volumen de repeticiones.
        XCTAssertEqual(distance.volumeKg, 0)

        let stored = try JSONEncoder().encode([distance, repetitions])
        let decoded = try JSONDecoder().decode([LoggedSet].self, from: stored)
        XCTAssertEqual(decoded.map(\.quantityUnit), [.meters, .reps])
        XCTAssertEqual(decoded.map(\.weightKg), [16, 20])
        XCTAssertEqual(decoded.map(\.reps), [20, 12])
    }

    func testLegacyLogWithoutUnitIsNotReinterpretedOrMigrated() throws {
        let old = LoggedSet(reps: 14, weightKg: 12)
        let restored = try JSONDecoder().decode(
            LoggedSet.self, from: JSONEncoder().encode(old)
        )
        XCTAssertNil(restored.quantityUnit)
        XCTAssertEqual(restored.reps, 14)
        XCTAssertEqual(restored.weightKg, 12)
    }

    func testScannedLoadDistanceAndSetsPreserveBothUnits() {
        let catalog = Catalog.seed()
        let board = BoardScanLiteParser.parse(ocrText: """
            AMRAP 15'
            14m WALKING LUNGES 2x16kg
            20m FARMER CARRY 24/16kg
            15m SLED PUSH 100kg
            10 BEAR CRAWL
            10 SANDBAG LUNGES 20kg
            """, catalog: catalog).blocks
        XCTAssertEqual(board.count, 1)
        guard let moves = board.first?.movements, moves.count == 5 else {
            XCTFail("El escáner ha omitido movimientos")
            return
        }
        XCTAssertEqual(moves[0].distanceMeters, 14)
        XCTAssertEqual(moves[0].weightMaleKg, 16)
        XCTAssertEqual(moves[0].prescribedQuantityUnit, .meters)
        XCTAssertEqual(moves[1].distanceMeters, 20)
        XCTAssertEqual(moves[1].weightMaleKg, 24)
        XCTAssertEqual(moves[1].weightFemaleKg, 16)
        XCTAssertEqual(moves[2].weightMaleKg, 100)
        XCTAssertEqual(moves[3].reps, 10)
        XCTAssertEqual(moves[3].prescribedQuantityUnit, .reps)
        XCTAssertEqual(moves[4].reps, 10)
        XCTAssertEqual(moves[4].weightMaleKg, 20)
        XCTAssertEqual(moves[4].prescribedQuantityUnit, .reps)

        let session = SessionController.from(
            routine: Routine(title: "Pizarra cargas y distancia", blocks: board),
            exercises: catalog
        )
        let weighted = session.exercises.filter { $0.exercise.supportsWeightedRepsOrMeters }
        XCTAssertTrue(weighted.contains { $0.quantityUnit == .meters && $0.plannedSets.first?.targetWeightKg == 16 })
    }

    func testFullBoardParserAlsoKeepsDistanceAndSingleLoad() {
        let blocks = BoardImportParser.parseBlocks(
            ocrText: "AMRAP 10'\n20 m SLED PUSH 100kg\n15 m FARMER CARRY 2x24kg",
            catalog: Catalog.seed()
        )
        guard let moves = blocks.first?.movements, moves.count == 2 else {
            XCTFail("El parser completo no mantuvo los dos movimientos")
            return
        }
        XCTAssertEqual(moves[0].distanceMeters, 20)
        XCTAssertEqual(moves[0].weightMaleKg, 100)
        XCTAssertEqual(moves[1].distanceMeters, 15)
        XCTAssertEqual(moves[1].weightMaleKg, 24)
    }

    func testDistanceWODKeepsWeightForAllPlannedSets() {
        let move = WODMovement(
            name: "Walking lunge", distanceMeters: 14, weightMaleKg: 18
        )
        XCTAssertEqual(move.prescribedQuantityUnit, .meters)
        XCTAssertEqual(move.plannedSetsFromReps.first?.targetReps, 14)
        XCTAssertEqual(move.plannedSetsFromReps.first?.targetWeightKg, 18)
    }
}
