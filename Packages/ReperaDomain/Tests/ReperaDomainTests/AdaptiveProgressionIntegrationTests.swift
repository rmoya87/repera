import XCTest
@testable import ReperaDomain

final class AdaptiveProgressionIntegrationTests: XCTestCase {
    private func workout(exercise: Exercise, daysAgo: Double,
                         reps: Int = 8, rir: Double? = 3) -> WorkoutSession {
        WorkoutSession(
            title: "Fuerza",
            exercises: [SessionExercise(
                exercise: exercise,
                plannedSets: Array(repeating: PlannedSet(targetReps: 8, targetWeightKg: 100), count: 3),
                loggedSets: Array(repeating: LoggedSet(reps: reps, weightKg: 100, rir: rir), count: 3),
                isCompleted: true
            )],
            phase: .finished,
            finishedAt: Date().addingTimeInterval(-daysAgo * 86400)
        )
    }

    func testRequiresTwoCompletedSessionsWithRIR() {
        let exercise = Catalog.seed().first { $0.name == "Sentadilla" }!
        let a = workout(exercise: exercise, daysAgo: 4)
        let b = workout(exercise: exercise, daysAgo: 2)
        let planned = a.exercises[0].plannedSets
        let insufficient = ProgressionEngine.suggest(exerciseId: exercise.id, planned: planned,
            policy: .adaptive, workouts: [a], incrementKg: 2.5)
        XCTAssertEqual(insufficient.weightKg, 100)

        let ready = ProgressionEngine.suggest(exerciseId: exercise.id, planned: planned,
            policy: .adaptive, workouts: [a, b], incrementKg: 2.5)
        XCTAssertEqual(ready.weightKg, 102.5)

        let missingEffort = workout(exercise: exercise, daysAgo: 1, rir: nil)
        let blocked = ProgressionEngine.suggest(exerciseId: exercise.id, planned: planned,
            policy: .adaptive, workouts: [a, missingEffort], incrementKg: 2.5)
        XCTAssertEqual(blocked.weightKg, 100)
    }

    func testDuplicatesCannotTriggerIncrease() {
        let exercise = Catalog.seed().first { $0.name == "Sentadilla" }!
        let one = workout(exercise: exercise, daysAgo: 2)
        let suggestion = ProgressionEngine.suggest(
            exerciseId: exercise.id, planned: one.exercises[0].plannedSets,
            policy: .adaptive, workouts: [one, one], incrementKg: 2.5)
        XCTAssertEqual(suggestion.weightKg, 100)
    }

    func testThreeFailuresSuggestDeload() {
        let exercise = Catalog.seed().first { $0.name == "Sentadilla" }!
        let failures = [workout(exercise: exercise, daysAgo: 6, reps: 5),
                        workout(exercise: exercise, daysAgo: 4, reps: 5),
                        workout(exercise: exercise, daysAgo: 2, reps: 5)]
        let suggestion = ProgressionEngine.suggest(
            exerciseId: exercise.id, planned: failures[0].exercises[0].plannedSets,
            policy: .adaptive, workouts: failures, incrementKg: 2.5)
        XCTAssertEqual(suggestion.weightKg, 90)
    }
}
