import XCTest
@testable import ReperaDomain

final class WallClockTimerTests: XCTestCase {
    func testRemainingUsesWallClockNotTicks() {
        let now = Date(timeIntervalSince1970: 1_000)
        let end = now.addingTimeInterval(90)
        XCTAssertEqual(WallClockTimer.remainingSeconds(until: end, now: now), 90)
        XCTAssertEqual(WallClockTimer.remainingSeconds(until: end, now: now.addingTimeInterval(30)), 60)
        XCTAssertEqual(WallClockTimer.remainingSeconds(until: end, now: now.addingTimeInterval(120)), 0)
    }

    func testElapsedCountUp() {
        let start = Date(timeIntervalSince1970: 500)
        XCTAssertEqual(WallClockTimer.elapsedSeconds(since: start, now: start.addingTimeInterval(12.9)), 12)
    }

    func testResumePreservesRemaining() {
        let now = Date(timeIntervalSince1970: 2_000)
        let end = WallClockTimer.resumeEndDate(remaining: 45, now: now)
        XCTAssertEqual(WallClockTimer.remainingSeconds(until: end, now: now), 45)
    }
}
