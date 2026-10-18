import XCTest
@testable import GymbroDomain

final class SwipeRevealMathTests: XCTestCase {
    func testClampedOffsetFollowsFingerWithoutJump() {
        let reveal: CGFloat = 72
        // Arrastre continuo hacia la izquierda.
        XCTAssertEqual(SwipeRevealMath.clampedOffset(start: 0, translation: -10, revealWidth: reveal), -10)
        XCTAssertEqual(SwipeRevealMath.clampedOffset(start: 0, translation: -40, revealWidth: reveal), -40)
        XCTAssertEqual(SwipeRevealMath.clampedOffset(start: 0, translation: -100, revealWidth: reveal), -72)
        // No pasar de 0 a la derecha.
        XCTAssertEqual(SwipeRevealMath.clampedOffset(start: -20, translation: 30, revealWidth: reveal), 0)
    }

    func testSwipeDoesNotBeginOnChipsBand() {
        let height: CGFloat = 120
        let band: CGFloat = 48
        XCTAssertTrue(SwipeRevealMath.shouldBeginSwipe(locationY: 20, viewHeight: height, chipsBandHeight: band))
        XCTAssertTrue(SwipeRevealMath.shouldBeginSwipe(locationY: 70, viewHeight: height, chipsBandHeight: band))
        XCTAssertFalse(SwipeRevealMath.shouldBeginSwipe(locationY: 80, viewHeight: height, chipsBandHeight: band))
        XCTAssertFalse(SwipeRevealMath.shouldBeginSwipe(locationY: 119, viewHeight: height, chipsBandHeight: band))
    }

    func testOpenThresholdStable() {
        let reveal: CGFloat = 72
        XCTAssertFalse(SwipeRevealMath.shouldOpen(projected: -20, current: -10, revealWidth: reveal))
        XCTAssertTrue(SwipeRevealMath.shouldOpen(projected: -40, current: -10, revealWidth: reveal))
        XCTAssertTrue(SwipeRevealMath.shouldOpen(projected: -10, current: -40, revealWidth: reveal))
    }
}
