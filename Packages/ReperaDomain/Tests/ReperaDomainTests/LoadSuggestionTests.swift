import XCTest
@testable import ReperaDomain

final class LoadSuggestionTests: XCTestCase {
    func testPercentFromNotes() {
        XCTAssertEqual(LoadSuggestion.percentOfOneRM(from: "#70%")?.value, 70)
        XCTAssertEqual(LoadSuggestion.percentOfOneRM(from: "#>80%")?.value, 80)
        XCTAssertEqual(LoadSuggestion.percentOfOneRM(from: "#>80%")?.isMinimum, true)
        XCTAssertNil(LoadSuggestion.percentOfOneRM(from: "sin porcentaje"))
    }

    func testWeightFromOneRM() {
        let kg = LoadSuggestion.weightKg(oneRM: 100, percent: 70, roundTo: 2.5)
        XCTAssertEqual(kg, 70)
    }

    func testWeightForRepsAndRIR() {
        // 100 kg 1RM · 8 reps @ RIR 2 → RTF 10 → 100 / (1+10/30) = 75 → round 2.5 → 75
        let kg = LoadSuggestion.weightKg(oneRM: 100, reps: 8, targetRir: 2, roundTo: 2.5)
        XCTAssertEqual(kg, 75)
    }

    func testWeightFromLastSet() {
        // Last 80×8 @ RIR 2 → e1RM = 80*(1+10/30) ≈ 106.67
        // Target 8 @ RIR 2 → same RTF → ≈ 80
        let kg = LoadSuggestion.weightKgFromLastSet(
            lastWeightKg: 80,
            lastReps: 8,
            lastRir: 2,
            targetReps: 8,
            targetRir: 2,
            roundTo: 2.5
        )
        XCTAssertEqual(kg, 80)
    }
}
