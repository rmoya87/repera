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

    func testDistanceWODKeepsWeightForAllPlannedSets() {
        let move = WODMovement(
            name: "Walking lunge", distanceMeters: 14, weightMaleKg: 18
        )
        XCTAssertEqual(move.prescribedQuantityUnit, .meters)
        XCTAssertEqual(move.plannedSetsFromReps.first?.targetReps, 14)
        XCTAssertEqual(move.plannedSetsFromReps.first?.targetWeightKg, 18)
    }
}
