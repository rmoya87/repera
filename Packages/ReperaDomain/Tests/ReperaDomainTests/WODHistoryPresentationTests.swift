import XCTest
@testable import ReperaDomain

final class WODHistoryPresentationTests: XCTestCase {
    func testHistoricalAliasesResolveDespiteMixedCaseAndSpacing() {
        for raw in ["BTt", "btt", "B T T", "Burpee to target"] {
            XCTAssertEqual(WODHistoryPresentation.officialName(for: raw), "Burpee to target")
        }
        for raw in ["T2B", "t2b", "T 2 B", "TTB", "toes-to-bar"] {
            XCTAssertEqual(WODHistoryPresentation.officialName(for: raw), "Toes to bar")
        }
        XCTAssertNil(WODHistoryPresentation.officialName(for: "Wall ball"))
    }

    func testAMRAPLogIsNotRepeatedIfIdenticalToPrescription() {
        let exercise = Exercise(name: "Wall ball", muscleGroup: "Piernas")
        let entry = SessionExercise(
            exercise: exercise,
            plannedSets: [PlannedSet(targetReps: 10, targetWeightKg: 9)],
            loggedSets: [LoggedSet(reps: 10, weightKg: 9)]
        )
        XCTAssertEqual(WODHistoryPresentation.recordedSummary(for: entry), "Registrado")
        XCTAssertEqual(entry.loggedSets.count, 1)
        XCTAssertEqual(entry.loggedSets[0].reps, 10)
        XCTAssertEqual(entry.loggedSets[0].weightKg, 9)
    }

    func testDifferentOrMultipleLoggedSetsRemainVisible() {
        let exercise = Exercise(name: "Wall ball", muscleGroup: "Piernas")
        let changed = SessionExercise(
            exercise: exercise,
            plannedSets: [PlannedSet(targetReps: 10, targetWeightKg: 9)],
            loggedSets: [LoggedSet(reps: 12, weightKg: 9)]
        )
        XCTAssertEqual(WODHistoryPresentation.recordedSummary(for: changed), "Registrado · 9×12")
        let multiple = SessionExercise(
            exercise: exercise,
            plannedSets: [PlannedSet(targetReps: 10, targetWeightKg: 9)],
            loggedSets: [LoggedSet(reps: 10, weightKg: 9), LoggedSet(reps: 10, weightKg: 9)]
        )
        XCTAssertNotEqual(WODHistoryPresentation.recordedSummary(for: multiple), "Registrado")
    }

    func testUnrecordedWODMovementHasNoRegisteredMarker() {
        let exercise = Exercise(name: "BTt", muscleGroup: "Custom", isCustom: true)
        let entry = SessionExercise(
            exercise: exercise,
            plannedSets: [PlannedSet(targetReps: 6)]
        )
        XCTAssertNil(WODHistoryPresentation.recordedSummary(for: entry))
    }
}
