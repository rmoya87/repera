import Foundation
import XCTest
@testable import ReperaDomain

final class WatchClockMathTests: XCTestCase {
    func testTwoHoursInBackgroundAreNotTruncated() {
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        let tick = WorkoutClockMath.advance(
            from: t0, to: t0.addingTimeInterval(7_200),
            sessionElapsed: 120, blockElapsed: 120, restRemaining: 0,
            isCounting: true, isWOD: false, timeCapSeconds: 0
        )
        XCTAssertEqual(tick.advancedSeconds, 7_200)
        XCTAssertEqual(tick.sessionElapsed, 7_320)
        XCTAssertEqual(tick.blockElapsed, 7_320)
        XCTAssertFalse(tick.reachedTimeCap)
    }

    func testBackgroundAMRAPRespectsCapIncludingRest() {
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        let tick = WorkoutClockMath.advance(
            from: t0, to: t0.addingTimeInterval(3_600),
            sessionElapsed: 0, blockElapsed: 50, restRemaining: 35,
            isCounting: true, isWOD: true, timeCapSeconds: 12 * 60
        )
        XCTAssertEqual(tick.sessionElapsed, 3_600)
        XCTAssertEqual(tick.blockElapsed, 720)
        XCTAssertEqual(tick.restRemaining, 0)
        XCTAssertTrue(tick.reachedTimeCap)
    }

    func testStrengthRestFinishesInsideSuspendedInterval() {
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        let tick = WorkoutClockMath.advance(
            from: t0, to: t0.addingTimeInterval(75),
            sessionElapsed: 100, blockElapsed: 15, restRemaining: 60,
            isCounting: true, isWOD: false, timeCapSeconds: 0
        )
        XCTAssertEqual(tick.sessionElapsed, 175)
        XCTAssertEqual(tick.blockElapsed, 30)
        XCTAssertEqual(tick.restRemaining, 0)
    }

    func testStoppedExerciseDoesNotAdvanceBlockButSessionContinues() {
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        let tick = WorkoutClockMath.advance(
            from: t0, to: t0.addingTimeInterval(45),
            sessionElapsed: 120, blockElapsed: 20, restRemaining: 0,
            isCounting: false, isWOD: false, timeCapSeconds: 0
        )
        XCTAssertEqual(tick.sessionElapsed, 165)
        XCTAssertEqual(tick.blockElapsed, 20)
    }
}
