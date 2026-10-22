import Foundation
import XCTest
@testable import ReperaDomain

final class WatchHealthKitContractTests: XCTestCase {
    func testVerifiedWatchMetricsPersistAndOlderWorkoutsStillDecode() throws {
        var session = WorkoutSession(title: "Entreno Watch", exercises: [])
        session.appleActiveEnergyKcal = 340
        session.appleAverageHeartRateBpm = 137
        session.appleDurationSeconds = 2340
        session.appleHealthProvenance = "watchHealthKit"
        session.healthKitWorkoutUUID = UUID()

        let encoded = try JSONEncoder().encode(session)
        let restored = try JSONDecoder().decode(WorkoutSession.self, from: encoded)
        XCTAssertEqual(restored.appleActiveEnergyKcal, 340)
        XCTAssertEqual(restored.appleAverageHeartRateBpm, 137)
        XCTAssertEqual(restored.appleDurationSeconds, 2340)
        XCTAssertEqual(restored.appleHealthProvenance, "watchHealthKit")
        XCTAssertEqual(restored.healthKitWorkoutUUID, session.healthKitWorkoutUUID)

        // Legacy archives do not contain fields introduced by the Watch HealthKit flow.
        var old = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        old.removeValue(forKey: "appleAverageHeartRateBpm")
        old.removeValue(forKey: "appleHealthProvenance")
        let oldData = try JSONSerialization.data(withJSONObject: old)
        let legacy = try JSONDecoder().decode(WorkoutSession.self, from: oldData)
        XCTAssertNil(legacy.appleHealthProvenance)
        XCTAssertNil(legacy.appleAverageHeartRateBpm)
    }

    func testWODResultsAreNotFabricatedAsMovementSets() throws {
        var block = RoutineBlock.wod(format: .amrap, title: "AMRAP 10")
        block.timeCapMinutes = 10
        block.movements = [WODMovement(name: "Burpee", reps: 10)]
        let plan = Routine(title: "CrossFit", blocks: [block])
        var controller = SessionController(
            session: SessionController.from(routine: plan, exercises: [])
        )
        controller.startOnPhone()
        controller.recordWODResult(WODBlockResult(
            id: block.id, format: .amrap,
            totalReps: 8, roundsCompleted: 5
        ))
        _ = controller.finishCurrentBlock()
        XCTAssertEqual(controller.session.wodResults.first?.summaryLabel, "5 rondas + 8 reps")
        XCTAssertTrue(controller.session.exercises.allSatisfy { $0.loggedSets.isEmpty })
        let decoded = try JSONDecoder().decode(
            WorkoutSession.self, from: JSONEncoder().encode(controller.session)
        )
        XCTAssertEqual(decoded.wodResults.count, 1)
    }
}
