import XCTest
@testable import ReperaDomain

final class AdaptiveLoadGuardTests: XCTestCase {
    private func observation(_ completed: Bool, rir: Double? = 3) -> AdaptiveLoadObservation {
        .init(completed: completed, rir: rir,
              relativeE1RMChange: 0.01, hoursSincePreviousSession: 72)
    }

    func testNeverIncreasesFromSingleWorkout() {
        XCTAssertEqual(AdaptiveLoadGuard.evaluate(recent: [observation(true)]).decision,
                       .insufficientData)
    }

    func testOnlyIncreasesWithRepeatedCompletionAndMargin() {
        XCTAssertEqual(AdaptiveLoadGuard.evaluate(
            recent: [observation(true), observation(true)]).decision, .increase)
        XCTAssertEqual(AdaptiveLoadGuard.evaluate(
            recent: [observation(true, rir: 0), observation(true)]).decision, .maintain)
    }

    func testRecoveryAndRepeatedFailuresBlockIncrease() {
        XCTAssertEqual(AdaptiveLoadGuard.evaluate(
            recent: [observation(true), observation(true)], recoveryReady: false).decision,
                       .maintain)
        XCTAssertEqual(AdaptiveLoadGuard.evaluate(
            recent: [observation(false), observation(false), observation(false)]).decision,
                       .deload)
    }
}
