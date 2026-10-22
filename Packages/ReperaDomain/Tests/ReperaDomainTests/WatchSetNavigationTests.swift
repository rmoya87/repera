import Foundation
import XCTest
@testable import ReperaDomain

final class WatchSetNavigationTests: XCTestCase {
    private func controller() -> SessionController {
        let squat = Exercise(name: "Sentadilla", muscleGroup: "Piernas")
        let press = Exercise(name: "Press militar", muscleGroup: "Hombros")
        let session = WorkoutSession(
            title: "Entreno de prueba",
            exercises: [
                SessionExercise(exercise: squat, plannedSets: [
                    PlannedSet(targetReps: 8), PlannedSet(targetReps: 8)
                ]),
                SessionExercise(exercise: press, plannedSets: [
                    PlannedSet(targetReps: 5)
                ])
            ]
        )
        var ctrl = SessionController(session: session)
        ctrl.startOnPhone()
        ctrl.confirmCurrentExercise()
        return ctrl
    }

    func testRevisingEarlierWatchSetPreservesIDAndDoesNotAppend() {
        var ctrl = controller()
        ctrl.logSet(reps: 8, weightKg: 40)
        ctrl.logSet(reps: 6, weightKg: 42.5)
        let savedID = ctrl.session.exercises[0].loggedSets[0].id

        XCTAssertTrue(ctrl.reviseLoggedSet(at: 0, reps: 10, weightKg: 45))
        let saved = ctrl.session.exercises[0].loggedSets
        XCTAssertEqual(saved.count, 2)
        XCTAssertEqual(saved[0].id, savedID)
        XCTAssertEqual(saved[0].reps, 10)
        XCTAssertEqual(saved[0].weightKg, 45)
        XCTAssertEqual(saved[1].reps, 6)
    }

    func testInvalidSetCannotCreatePhantomEntry() {
        var ctrl = controller()
        XCTAssertFalse(ctrl.reviseLoggedSet(at: 0, reps: 30, weightKg: nil))
        XCTAssertTrue(ctrl.session.exercises[0].loggedSets.isEmpty)
    }

    func testJumpBetweenExercisesDoesNotFinishSkippedExercises() {
        var ctrl = controller()
        ctrl.selectExercise(at: 1)
        XCTAssertEqual(ctrl.session.currentIndex, 1)
        XCTAssertEqual(ctrl.session.phase, .ready)
        XCTAssertFalse(ctrl.session.exercises[0].isCompleted)
        XCTAssertTrue(ctrl.session.exercises[0].loggedSets.isEmpty)
    }

    func testCompletingLastExerciseFinishesOnlyOnce() {
        var ctrl = controller()
        ctrl.logSet(reps: 8, weightKg: 40)
        XCTAssertTrue(ctrl.finishCurrentExercise())
        ctrl.confirmCurrentExercise()
        ctrl.logSet(reps: 5, weightKg: 20)
        XCTAssertFalse(ctrl.finishCurrentExercise())
        XCTAssertEqual(ctrl.session.phase, .finished)
        XCTAssertEqual(ctrl.session.exercises[1].loggedSets.count, 1)
    }
}
