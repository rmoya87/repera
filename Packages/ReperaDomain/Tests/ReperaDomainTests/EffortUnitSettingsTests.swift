import XCTest
@testable import ReperaDomain

final class EffortUnitSettingsTests: XCTestCase {
    func testCanonicalRirAndDisplayRpeRoundTrip() {
        for rir in 0...5 {
            let stored = Double(rir)
            let displayed = Effort.fromRIR(stored, unit: .rpe)
            XCTAssertEqual(displayed, 10 - stored)
            XCTAssertEqual(Effort.toRIR(value: displayed, unit: .rpe), stored)
        }
    }

    func testRPELabelsFollowDisplayPreference() {
        XCTAssertEqual(Effort.label(rir: 2, unit: .rir), "RIR 2")
        XCTAssertEqual(Effort.label(rir: 2, unit: .rpe), "RPE 8")
        XCTAssertNil(Effort.label(rir: nil, unit: .rpe))
    }
}
