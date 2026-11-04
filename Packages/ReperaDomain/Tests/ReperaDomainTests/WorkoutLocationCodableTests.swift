import XCTest
@testable import ReperaDomain

final class WorkoutLocationCodableTests: XCTestCase {
    func testLegacySessionDecodesWithoutLocationFields() throws {
        let json = """
        {
          "id": "A0A0A0A0-A0A0-A0A0-A0A0-A0A0A0A0A0A0",
          "title": "Push",
          "exercises": [],
          "currentIndex": 0,
          "phase": "finished",
          "wodResults": []
        }
        """.data(using: .utf8)!
        let session = try JSONDecoder().decode(WorkoutSession.self, from: json)
        XCTAssertNil(session.locationPin)
        XCTAssertTrue(session.routePoints.isEmpty)
    }

    func testStartPointCarriesAccuracyAndSourceWithoutCreatingRoute() throws {
        var workout = WorkoutSession(title: "HIIT interior", exercises: [])
        let capturedAt = Date(timeIntervalSince1970: 1_700_000_000)
        workout.locationPin = WorkoutLocationPin(
            latitude: 40.429, longitude: -3.868,
            recordedAt: capturedAt,
            horizontalAccuracyMeters: 14.5,
            source: "appleWatch"
        )
        let payload = try JSONEncoder().encode(workout)
        let decoded = try JSONDecoder().decode(WorkoutSession.self, from: payload)
        XCTAssertEqual(decoded.locationPin?.source, "appleWatch")
        XCTAssertEqual(decoded.locationPin?.horizontalAccuracyMeters, 14.5)
        XCTAssertEqual(decoded.locationPin?.recordedAt, capturedAt)
        XCTAssertTrue(decoded.routePoints.isEmpty)
        XCTAssertFalse(try XCTUnwrap(decoded.locationPin).hasChosenPlace)
    }

    func testLegacyLocationPinStillDecodesWithoutNewMetadata() throws {
        let raw = """
        {"latitude":40.4,"longitude":-3.7,"recordedAt":700000000,"name":"Box"}
        """.data(using: .utf8)!
        let pin = try JSONDecoder().decode(WorkoutLocationPin.self, from: raw)
        XCTAssertEqual(pin.name, "Box")
        XCTAssertNil(pin.horizontalAccuracyMeters)
        XCTAssertNil(pin.source)
    }

    func testRoundTripLocationPinAndRoute() throws {
        var session = WorkoutSession(title: "Run", exercises: [])
        session.locationPin = WorkoutLocationPin(
            latitude: 40.4,
            longitude: -3.7,
            name: "Retiro",
            mapItemIdentifier: "I63802885C8189B2B",
            pointOfInterestCategory: "MKPOICategoryPark"
        )
        session.routePoints = [
            WorkoutRoutePoint(id: 0, latitude: 40.4, longitude: -3.7, speedMps: 2.5),
            WorkoutRoutePoint(id: 1, latitude: 40.41, longitude: -3.71, speedMps: 3.0),
        ]
        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(WorkoutSession.self, from: data)
        XCTAssertEqual(decoded.locationPin?.latitude, 40.4)
        XCTAssertEqual(decoded.locationPin?.name, "Retiro")
        XCTAssertEqual(decoded.locationPin?.mapItemIdentifier, "I63802885C8189B2B")
        XCTAssertEqual(decoded.locationPin?.pointOfInterestCategory, "MKPOICategoryPark")
        XCTAssertEqual(decoded.routePoints.count, 2)
        XCTAssertEqual(decoded.routePoints[1].speedMps, 3.0)
    }
}
