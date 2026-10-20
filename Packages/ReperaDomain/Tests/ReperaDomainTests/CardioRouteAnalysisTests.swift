import XCTest
@testable import ReperaDomain

final class CardioRouteAnalysisTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_700_000_000)

    /// Segmentos de ~111 m en el ecuador; cada tramo dura 60 segundos.
    private func path(_ points: Int = 23, altitude: (Int) -> Double? = { _ in nil }) -> [CardioRouteAnalysis.Sample] {
        (0..<points).map { index in
            CardioRouteAnalysis.Sample(
                date: start.addingTimeInterval(Double(index) * 60),
                latitude: 0,
                longitude: Double(index) * 0.001,
                altitudeMeters: altitude(index)
            )
        }
    }

    func testKilometerCrossingsInterpolateTimeAndPace() {
        let track = path()
        let heart: [CardioRouteAnalysis.HeartSample] = (0..<23).map {
            .init(date: start.addingTimeInterval(Double($0) * 60), bpm: 120 + Double($0))
        }
        let result = CardioRouteAnalysis.analyze(route: track, heart: heart)
        XCTAssertEqual(result.splits.count, 2)
        XCTAssertEqual(result.splits.map(\.kilometer), [1, 2])
        XCTAssertEqual(result.splits[0].seconds, 539.6, accuracy: 7)
        XCTAssertEqual(result.splits[1].seconds, 539.6, accuracy: 7)
        XCTAssertEqual(result.splits[0].speedKmh, 3600 / result.splits[0].seconds, accuracy: 0.001)
        XCTAssertNotNil(result.splits[0].averageBpm)
    }

    func testAltitudeAndElevationAccumulation() {
        let result = CardioRouteAnalysis.analyze(
            route: path(5) { [100.0, 106.0, 112.0, 104.0, 104.0][$0] }
        )
        XCTAssertEqual(result.profile.count, 5)
        XCTAssertEqual(result.profile[0].altitudeMeters, 100)
        XCTAssertEqual(result.ascentMeters, 12, accuracy: 0.1)
        XCTAssertEqual(result.descentMeters, 8, accuracy: 0.1)
    }

    func testMissingElevationAndMissingHeartRateRemainUnavailable() {
        let result = CardioRouteAnalysis.analyze(route: path())
        XCTAssertTrue(result.profile.isEmpty)
        XCTAssertEqual(result.splits.count, 2)
        XCTAssertNil(result.splits[0].averageBpm)
    }

    func testInsufficientDistanceProducesNoFakeKilometer() {
        let result = CardioRouteAnalysis.analyze(route: path(3))
        XCTAssertTrue(result.splits.isEmpty)
    }

    func testMissingOrImplausibleGPSCannotGenerateSplits() {
        var points = path(2)
        points[1].longitude = 20
        points[1].date = start.addingTimeInterval(1)
        let result = CardioRouteAnalysis.analyze(route: points)
        XCTAssertTrue(result.splits.isEmpty)
        XCTAssertEqual(result.distanceMeters, 0)
        XCTAssertTrue(CardioRouteAnalysis.analyze(route: []).profile.isEmpty)
    }

    func testCrossingWithoutEnoughHeartSamplesHasNilAverage() {
        let result = CardioRouteAnalysis.analyze(
            route: path(),
            heart: [.init(date: start.addingTimeInterval(200), bpm: 145)]
        )
        XCTAssertEqual(result.splits.count, 2)
        XCTAssertNil(result.splits[0].averageBpm)
        XCTAssertNil(result.splits[1].averageBpm)
    }

    func testRoutePointsDoNotCarryAirQualityOrWeatherData() {
        let model = WorkoutRoutePoint(id: 1, latitude: 40.4, longitude: -3.7,
                                      recordedAt: start, speedMps: 2, altitudeMeters: 700)
        XCTAssertEqual(model.altitudeMeters, 700)
        let data = try? JSONEncoder().encode(model)
        XCTAssertNotNil(data)
        let decoded = data.flatMap { try? JSONDecoder().decode(WorkoutRoutePoint.self, from: $0) }
        XCTAssertEqual(decoded?.altitudeMeters, 700)
    }
    func testLegacyRouteWithoutAltitudeDecodesWithoutDataLoss() throws {
        let legacy = """
        {"id":1,"latitude":40.45,"longitude":-3.73,
         "recordedAt":721000000,"speedMps":3.2}
        """
        let point = try JSONDecoder().decode(WorkoutRoutePoint.self, from: Data(legacy.utf8))
        XCTAssertNil(point.altitudeMeters)
        XCTAssertEqual(point.speedMps, 3.2)
        XCTAssertEqual(point.latitude, 40.45)
    }

    func testGradualElevationIsNotDiscardedAsNoise() {
        let result = CardioRouteAnalysis.analyze(route: path(10) { 100 + Double($0) })
        XCTAssertEqual(result.profile.count, 10)
        XCTAssertEqual(result.ascentMeters, 9, accuracy: 2)
    }

}
