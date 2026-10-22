import Foundation
import XCTest
@testable import ReperaDomain

final class WatchWorkoutDomainTests: XCTestCase {
    func testStandaloneExerciseKeepsRestAndUnitAfterSerialization() throws {
        let exercise = Exercise(name: "Remo", muscleGroup: "Espalda")
        let routine = Routine(title: "Remo", exercises: [
            RoutineExercise(
                exerciseId: exercise.id,
                plannedSets: [PlannedSet(targetReps: 10), PlannedSet(targetReps: 10)],
                quantityUnit: .meters,
                restSeconds: 90
            )
        ])
        let session = SessionController.from(routine: routine, exercises: [exercise])
        XCTAssertEqual(session.currentExercise?.restSeconds, 90)
        XCTAssertEqual(session.currentExercise?.quantityUnit, .meters)
        let restored = try JSONDecoder().decode(
            WorkoutSession.self, from: JSONEncoder().encode(session)
        )
        XCTAssertEqual(restored.currentExercise?.restSeconds, 90)
        XCTAssertEqual(restored.currentExercise?.quantityUnit, .meters)
    }

    func testRecordWODResultReplacesSameBlockWithoutCreatingSets() {
        var block = RoutineBlock.wod(format: .amrap, title: "AMRAP")
        block.movements = [WODMovement(name: "Burpee", reps: 10)]
        var controller = SessionController(session: SessionController.from(
            routine: Routine(title: "WOD", blocks: [block]), exercises: []
        ))
        controller.startOnPhone()
        controller.recordWODResult(WODBlockResult(
            id: block.id, format: .amrap, totalReps: 5, roundsCompleted: 4
        ))
        controller.recordWODResult(WODBlockResult(
            id: block.id, format: .amrap, totalReps: 7, roundsCompleted: 4
        ))
        XCTAssertEqual(controller.session.wodResults.count, 1)
        XCTAssertEqual(controller.session.wodResults[0].totalReps, 7)
        XCTAssertTrue(controller.session.exercises.allSatisfy { $0.loggedSets.isEmpty })
    }
}
