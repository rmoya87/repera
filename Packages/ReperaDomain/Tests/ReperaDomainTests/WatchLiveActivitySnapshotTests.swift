import Foundation
import XCTest
@testable import ReperaDomain

final class WatchLiveActivitySnapshotTests: XCTestCase {
    func testPhoneOwnedLiveClockAdvancesOnlyWhileRecording() throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let id = UUID()
        let running = WatchLiveActivitySnapshot(
            id: id, sportTitle: "Caminata", phase: .recording,
            elapsedSeconds: 120, distanceMeters: 490,
            averageSpeedKmh: 4.8, nextTurn: "Gira a la derecha",
            nextTurnMeters: 30, capturedAt: start
        )
        XCTAssertEqual(running.displayElapsed(at: start.addingTimeInterval(20)), 140)
        let paused = WatchLiveActivitySnapshot(
            id: id, sportTitle: "Caminata", phase: .paused,
            elapsedSeconds: 120, distanceMeters: 490,
            averageSpeedKmh: 4.8, nextTurn: nil, nextTurnMeters: nil,
            capturedAt: start
        )
        XCTAssertEqual(paused.displayElapsed(at: start.addingTimeInterval(20)), 120)
        XCTAssertEqual(try JSONDecoder().decode(
            WatchLiveActivitySnapshot.self, from: JSONEncoder().encode(running)
        ), running)
    }

    func testNoInventedGPSOrMedicalMetrics() {
        let snapshot = WatchLiveActivitySnapshot(
            id: UUID(), sportTitle: "Yoga", phase: .recording,
            elapsedSeconds: -1, distanceMeters: -10, averageSpeedKmh: nil,
            nextTurn: nil, nextTurnMeters: nil, capturedAt: Date()
        )
        XCTAssertEqual(snapshot.elapsedSeconds, 0)
        XCTAssertEqual(snapshot.distanceMeters, 0)
        XCTAssertNil(snapshot.averageSpeedKmh)
    }
}
