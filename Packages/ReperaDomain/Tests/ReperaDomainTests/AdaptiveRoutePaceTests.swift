import XCTest
@testable import ReperaDomain

final class AdaptiveRoutePaceTests: XCTestCase {
    func testUniformWalkRemainsYellow() throws {
        let samples = (0..<100).map { _ in AdaptiveRoutePace.Sample(speedMps: 4.8 / 3.6, distanceMeters: 8) }
        let scale = try XCTUnwrap(AdaptiveRoutePace.scale(samples: samples, mode: .walking))
        XCTAssertFalse(scale.hasMeaningfulVariation)
        XCTAssertEqual(scale.position(for: 4.8 / 3.6), 0.5, accuracy: 0.0001)
    }
    func testAccelerationAndOutlier() throws {
        let samples = (0..<100).map { i in
            AdaptiveRoutePace.Sample(speedMps: (i < 20 ? 4.0 : i < 80 ? 4.8 : 5.6) / 3.6, distanceMeters: 10)
        } + [.init(speedMps: 40, distanceMeters: 1)]
        let scale = try XCTUnwrap(AdaptiveRoutePace.scale(samples: samples, mode: .walking))
        XCTAssertTrue(scale.hasMeaningfulVariation)
        XCTAssertEqual(scale.medianMps * 3.6, 4.8, accuracy: 0.01)
        XCTAssertLessThan(scale.position(for: 4.0 / 3.6), 0.2)
        XCTAssertGreaterThan(scale.position(for: 5.6 / 3.6), 0.8)
    }
    func testEstimatedGPSCannotSkewScale() throws {
        let samples = (0..<40).map { _ in AdaptiveRoutePace.Sample(speedMps: 1.3, distanceMeters: 8) }
            + [.init(speedMps: 15, distanceMeters: 500, isEstimated: true)]
        let scale = try XCTUnwrap(AdaptiveRoutePace.scale(samples: samples, mode: .walking))
        XCTAssertEqual(scale.medianMps, 1.3, accuracy: 0.001)
        XCTAssertFalse(scale.hasMeaningfulVariation)
    }
}
