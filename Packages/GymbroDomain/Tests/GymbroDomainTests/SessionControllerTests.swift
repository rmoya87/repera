import XCTest
@testable import GymbroDomain

final class SessionControllerTests: XCTestCase {
    func testConfirmAndFinishAdvances() {
        var controller = SessionController(session: SessionController.demoPushPull())
        controller.startOnPhone()
        XCTAssertEqual(controller.session.phase, SessionPhase.ready)
        XCTAssertFalse(controller.session.exercises.isEmpty)

        controller.confirmCurrentExercise()
        XCTAssertEqual(controller.session.phase, SessionPhase.counting)

        controller.setRepCount(8)
        XCTAssertEqual(controller.session.currentExercise?.completedReps, 8)

        let hasNext = controller.finishCurrentExercise()
        XCTAssertTrue(hasNext)
        XCTAssertEqual(controller.session.phase, SessionPhase.ready)
    }

    func testLogSetAndFinishWorkout() {
        var controller = SessionController(session: SessionController.demoPushPull())
        controller.startOnPhone()
        controller.logSet(reps: 8, weightKg: 60)
        XCTAssertEqual(controller.session.currentExercise?.loggedSets.count, 1)
        controller.finishWorkout()
        XCTAssertEqual(controller.session.phase, SessionPhase.finished)
        XCTAssertNotNil(controller.session.finishedAt)
    }

    func testWatchCommitReps() {
        var controller = SessionController(session: SessionController.demoPushPull())
        controller.startOnPhone()
        controller.confirmCurrentExercise()
        controller.setRepCount(12)
        controller.commitWatchRepsAsSet(weightKg: 40)
        XCTAssertEqual(controller.session.currentExercise?.loggedSets.last?.reps, 12)
    }

    func testMotionRepCounterDetectsPeak() {
        var counter = MotionRepCounter(threshold: 1.2, minInterval: 0.1)
        let t0 = Date()
        counter.ingest(magnitude: 1.0, at: t0)
        counter.ingest(magnitude: 1.5, at: t0.addingTimeInterval(0.05))
        counter.ingest(magnitude: 1.1, at: t0.addingTimeInterval(0.1))
        XCTAssertEqual(counter.count, 1)

        counter.applyManualDelta(1)
        XCTAssertEqual(counter.count, 2)
        counter.applyManualDelta(-5)
        XCTAssertEqual(counter.count, 0)
    }

    func testStatsPersonalRecords() {
        var controller = SessionController(session: SessionController.demoPushPull())
        controller.startOnPhone()
        controller.logSet(reps: 5, weightKg: 100)
        controller.finishWorkout()
        let prs = StatsEngine.personalRecords(from: [controller.session])
        XCTAssertFalse(prs.isEmpty)
    }

    func testDefaultWeekPlanLinksExercises() {
        let exercises = Catalog.seed()
        let plan = Catalog.defaultWeekPlan(exercises: exercises)
        XCTAssertFalse(plan.isEmpty)
        for routine in plan {
            for item in routine.exercises {
                XCTAssertTrue(exercises.contains { $0.id == item.exerciseId })
            }
        }
    }
}
