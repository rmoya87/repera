import XCTest
@testable import ReperaDomain

final class PlannedSetSummaryTests: XCTestCase {
    func testUniformSets() {
        let sets = (0..<3).map { _ in PlannedSet(targetReps: 8, targetWeightKg: 60) }
        XCTAssertEqual(sets.compactSummary, "3×8 · 60 kg")
        XCTAssertEqual(sets.compactRepsSummary, "3×8")
    }

    func testGroupedDifferentRepsSameWeight() {
        let sets = [
            PlannedSet(targetReps: 3, targetWeightKg: 150),
            PlannedSet(targetReps: 3, targetWeightKg: 150),
            PlannedSet(targetReps: 1, targetWeightKg: 150),
            PlannedSet(targetReps: 1, targetWeightKg: 150),
        ]
        XCTAssertEqual(sets.compactSummary, "2×3, 2×1 · 150 kg")
        XCTAssertEqual(sets.compactRepsSummary, "2×3, 2×1")
    }

    func testProgressiveWeights() {
        let sets = [
            PlannedSet(targetReps: 5, targetWeightKg: 100),
            PlannedSet(targetReps: 5, targetWeightKg: 110),
            PlannedSet(targetReps: 3, targetWeightKg: 120),
        ]
        XCTAssertEqual(sets.compactSummary, "5 @ 100 kg, 5 @ 110 kg, 3 @ 120 kg")
    }

    func testSingleSetsListed() {
        let sets = [
            PlannedSet(targetReps: 8, targetWeightKg: 40),
            PlannedSet(targetReps: 6, targetWeightKg: 40),
        ]
        XCTAssertEqual(sets.compactSummary, "8, 6 · 40 kg")
    }
}
