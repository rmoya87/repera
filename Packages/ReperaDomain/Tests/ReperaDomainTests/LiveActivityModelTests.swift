import Foundation
import Testing
@testable import ReperaDomain

@Suite("Sesiones En vivo - persistencia y duración")
struct LiveActivityModelTests {
    @Test func runningActivityRoundTripsWithGPSMetrics() throws {
        let start = Date(timeIntervalSince1970: 1_790_000_000)
        let end = start.addingTimeInterval(1_800)
        let route = [
            WorkoutRoutePoint(id: 0, latitude: 40.493, longitude: -3.879, recordedAt: start),
            WorkoutRoutePoint(id: 1, latitude: 40.495, longitude: -3.878, recordedAt: end)
        ]
        let session = WorkoutSession(
            title: "Carrera por el parque",
            exercises: [],
            phase: .finished,
            startedAt: start,
            finishedAt: end,
            routePoints: route,
            liveSportID: "running",
            recordedDistanceMeters: 4_700,
            activeDurationSeconds: 1_620
        )
        let restored = try JSONDecoder().decode(WorkoutSession.self, from: JSONEncoder().encode(session))
        #expect(restored == session)
        #expect(restored.routePoints.count == 2)
        #expect(restored.recordedDistanceMeters == 4_700)
        #expect(restored.durationMinutes == 27)
        #expect(restored.displayDurationMinutes == 27)
        #expect(restored.startedAt == start)
    }

    @Test func indoorActivityDoesNotInventRouteOrEnergy() throws {
        let session = WorkoutSession(
            title: "Pádel",
            exercises: [],
            phase: .finished,
            startedAt: Date(timeIntervalSince1970: 1_790_000_000),
            finishedAt: Date(timeIntervalSince1970: 1_790_003_600),
            liveSportID: "padel",
            activeDurationSeconds: 3_000
        )
        #expect(session.routePoints.isEmpty)
        #expect(session.recordedDistanceMeters == nil)
        #expect(session.appleActiveEnergyKcal == nil)
        #expect(session.appleAverageHeartRateBpm == nil)
        #expect(session.displayDurationMinutes == 50)
    }

    @Test func olderWorkoutsDecodeWithoutLiveFields() throws {
        let session = WorkoutSession(title: "Fuerza", exercises: [], phase: .finished)
        var data = try JSONSerialization.jsonObject(with: JSONEncoder().encode(session)) as! [String: Any]
        data.removeValue(forKey: "liveSportID")
        data.removeValue(forKey: "recordedDistanceMeters")
        data.removeValue(forKey: "activeDurationSeconds")
        let restored = try JSONDecoder().decode(
            WorkoutSession.self, from: JSONSerialization.data(withJSONObject: data)
        )
        #expect(restored.liveSportID == nil)
        #expect(restored.activeDurationSeconds == nil)
        #expect(restored.recordedDistanceMeters == nil)
    }
}
