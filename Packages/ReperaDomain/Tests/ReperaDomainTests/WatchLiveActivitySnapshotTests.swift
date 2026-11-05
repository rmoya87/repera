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

    func testWatchOwnedLiveTransitionsArriveBeforeExpiry() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let id = UUID()
        func snapshot(
            _ phase: WatchLiveActivitySnapshot.Phase, age: TimeInterval
        ) -> WatchLiveActivitySnapshot {
            WatchLiveActivitySnapshot(
                id: id, sportTitle: "Caminata", phase: phase,
                elapsedSeconds: 600, distanceMeters: 800,
                averageSpeedKmh: 4.8, nextTurn: nil,
                nextTurnMeters: nil, capturedAt: now.addingTimeInterval(-age),
                sportID: "walking"
            )
        }
        XCTAssertTrue(WatchOwnedLiveDeliveryPolicy.accepts(
            snapshot(.recording, age: 0), now: now
        ))
        XCTAssertTrue(WatchOwnedLiveDeliveryPolicy.accepts(
            snapshot(.paused, age: 30), now: now
        ))
        XCTAssertTrue(WatchOwnedLiveDeliveryPolicy.accepts(
            snapshot(.review, age: 120), now: now
        ))
        XCTAssertFalse(WatchOwnedLiveDeliveryPolicy.accepts(
            snapshot(.recording, age: 91), now: now
        ))
        XCTAssertFalse(WatchOwnedLiveDeliveryPolicy.accepts(
            snapshot(.review, age: 3601), now: now
        ))
        XCTAssertFalse(WatchOwnedLiveDeliveryPolicy.accepts(
            snapshot(.recording, age: -6), now: now
        ))
    }

    func testLateWatchUpdateDoesNotReplaceNewerPauseOrFinish() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let id = UUID()
        let paused = WatchLiveActivitySnapshot(
            id: id, sportTitle: "Caminar", phase: .paused,
            elapsedSeconds: 50, distanceMeters: 60,
            averageSpeedKmh: nil, nextTurn: nil, nextTurnMeters: nil,
            capturedAt: now
        )
        let oldRunning = WatchLiveActivitySnapshot(
            id: id, sportTitle: "Caminar", phase: .recording,
            elapsedSeconds: 45, distanceMeters: 55,
            averageSpeedKmh: nil, nextTurn: nil, nextTurnMeters: nil,
            capturedAt: now.addingTimeInterval(-10)
        )
        XCTAssertTrue(WatchOwnedLiveDeliveryPolicy.isNewer(
            paused, than: oldRunning.capturedAt
        ))
        XCTAssertFalse(WatchOwnedLiveDeliveryPolicy.isNewer(
            oldRunning, than: paused.capturedAt
        ))
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
