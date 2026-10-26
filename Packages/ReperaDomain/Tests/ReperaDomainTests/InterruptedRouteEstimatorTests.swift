import XCTest
@testable import ReperaDomain

final class InterruptedRouteEstimatorTests: XCTestCase {
    private let origin = Date(timeIntervalSince1970: 1_800_000_000)

    func testPlausibleGapIsEstimatedWithoutChangingMeasuredEndpoints() {
        let first = WorkoutRoutePoint(id: 0, latitude: 40.500, longitude: -3.900, recordedAt: origin)
        let last = WorkoutRoutePoint(id: 1, latitude: 40.501, longitude: -3.900,
                                     recordedAt: origin.addingTimeInterval(120))
        let gap = InterruptedRouteEstimator.bridge(from: first, to: last, maximumSpeedMps: 2.8)
        XCTAssertNotNil(gap)
        XCTAssertTrue(gap?.points.allSatisfy { $0.isEstimated == true } ?? false)
        XCTAssertGreaterThan(gap?.distanceMeters ?? 0, 100)
        XCTAssertEqual(gap?.missingSeconds, 120)
    }

    func testStaleOrImplausibleGapNeverCreatesSyntheticRoute() {
        let first = WorkoutRoutePoint(id: 0, latitude: 40.5, longitude: -3.9, recordedAt: origin)
        let jump = WorkoutRoutePoint(id: 1, latitude: 41.5, longitude: -3.9,
                                     recordedAt: origin.addingTimeInterval(90))
        let stale = WorkoutRoutePoint(id: 2, latitude: 40.501, longitude: -3.9,
                                      recordedAt: origin.addingTimeInterval(3600))
        XCTAssertNil(InterruptedRouteEstimator.bridge(from: first, to: jump, maximumSpeedMps: 2.8))
        XCTAssertNil(InterruptedRouteEstimator.bridge(from: first, to: stale, maximumSpeedMps: 2.8))
    }

    func testOldGPSSamplesDecodeWithoutEstimatedFlag() throws {
        let sample = WorkoutRoutePoint(id: 0, latitude: 40.5, longitude: -3.9, recordedAt: origin)
        let data = try JSONEncoder().encode(sample)
        let decoded = try JSONDecoder().decode(WorkoutRoutePoint.self, from: data)
        XCTAssertNil(decoded.isEstimated)
    }
}
