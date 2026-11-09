import XCTest
@testable import ReperaDomain

final class WODComparisonEngineTests: XCTestCase {
    private func context(reps: Int, rx: Bool = true,
                         movementReps: Int = 10, format: WODFormat = .amrap) -> WODComparisonContext {
        let block = RoutineBlock(
            title: "Benchmark", kind: .wod,
            movements: [WODMovement(name: "Burpee", reps: movementReps)],
            wodFormat: format, timeCapMinutes: 12
        )
        let result = WODBlockResult(id: block.id, format: format, totalReps: reps)
        return WODComparisonContext(prescribed: block, result: result, isRx: rx)
    }

    func testEquivalentAmrapComparesReps() {
        let value = WODComparisonEngine.compare(
            previous: context(reps: 100), current: context(reps: 115))
        XCTAssertEqual(value?.improvement, 15)
        XCTAssertEqual(value?.unit, "reps")
    }

    func testScaledOrDifferentPrescriptionCannotCompare() {
        XCTAssertNil(WODComparisonEngine.compare(
            previous: context(reps: 100, rx: true),
            current: context(reps: 115, rx: false)))
        XCTAssertNil(WODComparisonEngine.compare(
            previous: context(reps: 100, movementReps: 10),
            current: context(reps: 115, movementReps: 15)))
    }

    func testUnsupportedFormatDoesNotManufactureScore() {
        XCTAssertNil(WODComparisonEngine.compare(
            previous: context(reps: 100, format: .emom),
            current: context(reps: 115, format: .emom)))
    }
}
