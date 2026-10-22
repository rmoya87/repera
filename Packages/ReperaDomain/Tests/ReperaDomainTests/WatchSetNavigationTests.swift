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

    func testFullWatchSetEditKeepsIdentityAndAllMetadata() {
        var ctrl = controller()
        ctrl.logSet(reps: 8, weightKg: 60, rir: 2)
        let before = ctrl.session.exercises[0].loggedSets[0]
        var revised = before
        revised.reps = 10
        revised.weightKg = 62.5
        revised.rir = 1
        revised.durationSeconds = 45
        revised.phase = .warmup
        revised.kind = .dropset
        revised.drops = [DropSegment(reps: 4, weightKg: 40)]
        XCTAssertTrue(ctrl.replaceLoggedSet(at: 0, with: revised))

        let saved = ctrl.session.exercises[0].loggedSets
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved[0].id, before.id)
        XCTAssertEqual(saved[0].completedAt, before.completedAt)
        XCTAssertEqual(saved[0].reps, 10)
        XCTAssertEqual(saved[0].weightKg, 62.5)
        XCTAssertEqual(saved[0].rir, 1)
        XCTAssertEqual(saved[0].durationSeconds, 45)
        XCTAssertEqual(saved[0].phase, .warmup)
        XCTAssertEqual(saved[0].drops.first?.reps, 4)

        let roundtrip = try? JSONDecoder().decode(
            WorkoutSession.self, from: JSONEncoder().encode(ctrl.session))
        XCTAssertEqual(roundtrip?.exercises[0].loggedSets[0], saved[0])
    }

    func testReplaceWatchSetRejectsWrongUUID() {
        var ctrl = controller()
        ctrl.logSet(reps: 8, weightKg: 60)
        let other = LoggedSet(reps: 12, weightKg: 42)
        XCTAssertFalse(ctrl.replaceLoggedSet(at: 0, with: other))
        XCTAssertEqual(ctrl.session.exercises[0].loggedSets[0].reps, 8)
    }

    func testMachineUnitsAndRestPauseRoundTripWithoutConvertingToReps() {
        var ctrl = controller()
        ctrl.logSet(reps: 300, weightKg: nil, durationSeconds: 70, quantityUnit: .meters)
        ctrl.logSet(reps: 11, weightKg: nil, kind: .restpause,
                    clusters: [RestPauseCluster(reps: 8, restSeconds: 15),
                               RestPauseCluster(reps: 3, restSeconds: 10)])
        let encoded = try? JSONEncoder().encode(ctrl.session)
        let decoded = encoded.flatMap { try? JSONDecoder().decode(WorkoutSession.self, from: $0) }
        XCTAssertEqual(decoded?.exercises[0].loggedSets[0].quantityUnit, .meters)
        XCTAssertEqual(decoded?.exercises[0].loggedSets[0].durationSeconds, 70)
        XCTAssertEqual(decoded?.exercises[0].loggedSets[1].clusters.count, 2)
        XCTAssertEqual(decoded?.exercises[0].loggedSets[1].reps, 11)
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
