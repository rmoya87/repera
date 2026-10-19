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

    func testRoundTripLocationPinAndRoute() throws {
        var session = WorkoutSession(title: "Run", exercises: [])
        session.locationPin = WorkoutLocationPin(latitude: 40.4, longitude: -3.7)
        session.routePoints = [
            WorkoutRoutePoint(id: 0, latitude: 40.4, longitude: -3.7, speedMps: 2.5),
            WorkoutRoutePoint(id: 1, latitude: 40.41, longitude: -3.71, speedMps: 3.0),
        ]
        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(WorkoutSession.self, from: data)
        XCTAssertEqual(decoded.locationPin?.latitude, 40.4)
        XCTAssertEqual(decoded.routePoints.count, 2)
        XCTAssertEqual(decoded.routePoints[1].speedMps, 3.0)
    }
}
