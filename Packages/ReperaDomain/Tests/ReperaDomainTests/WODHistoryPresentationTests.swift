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
        // Variantes que OCR produce con grafías indistinguibles.
        XCTAssertEqual(WODHistoryPresentation.officialName(for: "BTт"), "Burpee to target")
        XCTAssertEqual(WODHistoryPresentation.officialName(for: "Ｔ２Ｂ"), "Toes to bar")
        XCTAssertNil(WODHistoryPresentation.officialName(for: "Wall ball"))
    }

    func testHistoricalAMRAPRetainsOriginalRecordedSets() {
        // La pantalla ya no repite «Registrado», pero la serie real sigue
        // disponible para la edición, la analítica y la sincronización.
        let exercise = Exercise(name: "Wall ball", muscleGroup: "Piernas")
        let set = LoggedSet(reps: 10, weightKg: 9)
        let entry = SessionExercise(
            exercise: exercise,
            plannedSets: [PlannedSet(targetReps: 10, targetWeightKg: 9)],
            loggedSets: [set]
        )
        XCTAssertEqual(entry.loggedSets.count, 1)
        XCTAssertEqual(entry.loggedSets[0].reps, 10)
        XCTAssertEqual(entry.loggedSets[0].weightKg, 9)
        XCTAssertEqual(entry.loggedSets[0].id, set.id)
    }

}