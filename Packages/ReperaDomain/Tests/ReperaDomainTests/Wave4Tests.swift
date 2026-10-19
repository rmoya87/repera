import XCTest
@testable import ReperaDomain

final class Wave4Tests: XCTestCase {
    func testWarmupExcludedFromProgression() {
        let bench = Catalog.seed().first { $0.name == "Press banca" }!
        let workout = WorkoutSession(
            title: "W",
            exercises: [
                SessionExercise(
                    exercise: bench,
                    plannedSets: [PlannedSet(targetReps: 8, targetWeightKg: 60)],
                    loggedSets: [
                        LoggedSet(reps: 10, weightKg: 40, phase: .warmup),
                        LoggedSet(reps: 8, weightKg: 60, phase: .work),
                        LoggedSet(reps: 8, weightKg: 60, phase: .work),
                        LoggedSet(reps: 8, weightKg: 60, phase: .work),
                    ],
                    isCompleted: true
                ),
            ],
            phase: .finished,
            finishedAt: Date()
        )
        // Need 3 planned for hitAll with 3 work sets
        var adjusted = workout
        adjusted.exercises[0].plannedSets = Array(repeating: PlannedSet(targetReps: 8, targetWeightKg: 60), count: 3)

        let suggestion = ProgressionEngine.suggest(
            exerciseId: bench.id,
            planned: adjusted.exercises[0].plannedSets,
            policy: .linear,
            workouts: [adjusted],
            incrementKg: 2.5
        )
        XCTAssertEqual(suggestion.weightKg, 62.5)
    }

    func testDropSetVolumeIncludesDrops() {
        let set = LoggedSet(
            reps: 6,
            weightKg: 100,
            kind: .dropset,
            drops: [
                DropSegment(reps: 6, weightKg: 80),
                DropSegment(reps: 6, weightKg: 60),
            ]
        )
        XCTAssertEqual(set.volumeKg, 100 * 6 + 80 * 6 + 60 * 6)
        XCTAssertEqual(set.kind, .dropset)
    }

    func testEffortRIRPEConversion() {
        XCTAssertEqual(Effort.toRIR(value: 8, unit: .rpe), 2)
        XCTAssertEqual(Effort.fromRIR(2, unit: .rpe), 8)
        XCTAssertTrue(Effort.isHard(rir: 2))
        XCTAssertFalse(Effort.isHard(rir: 4))
    }
}
