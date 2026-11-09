import XCTest
@testable import ReperaDomain

final class WODComparisonEngineTests: XCTestCase {
    private func context(reps: Int, rounds: Int = 0, rx: Bool = true,
                         movementReps: Int = 10, format: WODFormat = .amrap) -> WODComparisonContext {
        let block = RoutineBlock(
            title: "Benchmark", kind: .wod,
            movements: [WODMovement(name: "Burpee", reps: movementReps)],
            wodFormat: format, timeCapMinutes: 12
        )
        let result = WODBlockResult(id: block.id, format: format, totalReps: reps, roundsCompleted: rounds)
        return WODComparisonContext(prescribed: block, result: result, isRx: rx)
    }

    func testEquivalentAmrapComparesReps() {
        let value = WODComparisonEngine.compare(
            previous: context(reps: 0, rounds: 10), current: context(reps: 5, rounds: 11))
        XCTAssertEqual(value?.improvement, 15)
        XCTAssertEqual(value?.unit, "reps")
    }

    func testScaledOrDifferentPrescriptionCannotCompare() {
        XCTAssertNil(WODComparisonEngine.compare(
            previous: context(reps: 0, rounds: 10, rx: true),
            current: context(reps: 5, rounds: 11, rx: false)))
        XCTAssertNil(WODComparisonEngine.compare(
            previous: context(reps: 0, rounds: 10, movementReps: 10),
            current: context(reps: 5, rounds: 11, movementReps: 15)))
    }


    func testAmrapCannotCompareMissingRoundsOrNonstandardExtraReps() {
        XCTAssertNil(WODComparisonEngine.compare(
            previous: context(reps: 10, rounds: 10),
            current: context(reps: 5, rounds: 11)))
    }

    func testUnsupportedFormatDoesNotManufactureScore() {
        XCTAssertNil(WODComparisonEngine.compare(
            previous: context(reps: 100, format: .emom),
            current: context(reps: 115, format: .emom)))
    }
}
