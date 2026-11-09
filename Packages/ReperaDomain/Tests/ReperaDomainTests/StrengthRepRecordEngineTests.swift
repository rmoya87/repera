import XCTest
@testable import ReperaDomain

final class StrengthRepRecordEngineTests: XCTestCase {
    private let exercise = Catalog.seed().first { $0.name == "Sentadilla" }!

    func testUsesOnlyRealWorkSetsFor3To10RepRecords() {
        let session = WorkoutSession(
            title: "Fuerza",
            exercises: [SessionExercise(
                exercise: exercise,
                plannedSets: [PlannedSet(targetReps: 10, targetWeightKg: 150)],
                loggedSets: [
                    LoggedSet(reps: 5, weightKg: 100),
                    LoggedSet(reps: 10, weightKg: 75),
                    LoggedSet(reps: 1, weightKg: 200, phase: .warmup)
                ],
                isCompleted: true
            )],
            phase: .finished, finishedAt: Date()
        )
        let records = StrengthRepRecordEngine.bestSets(
            exerciseId: exercise.id, workouts: [session, session])
        XCTAssertEqual(records.map(\.minimumReps), [3, 5, 10])
        XCTAssertEqual(records.map(\.bestWeightKg), [100, 100, 75])
    }

    func testNeverConvertsPlannedSetsToRecords() {
        let plannedOnly = WorkoutSession(
            title: "Pendiente", exercises: [SessionExercise(
                exercise: exercise,
                plannedSets: [PlannedSet(targetReps: 10, targetWeightKg: 250)]
            )],
            phase: .ready
        )
        XCTAssertTrue(StrengthRepRecordEngine.bestSets(
            exerciseId: exercise.id, workouts: [plannedOnly]).isEmpty)
    }
}
