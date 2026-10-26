import XCTest
@testable import ReperaDomain

/// WOD acabado ≠ series de fuerza inventadas. El check confirmado únicamente
/// aporta un estímulo muscular conservador cuando no existen LoggedSet reales.
final class CompletedWODMuscleStimulusTests: XCTestCase {
    private let now = Date()

    private func session(
        isCompleted: Bool,
        kind: RoutineBlockKind = .wod,
        recorded: [LoggedSet] = []
    ) -> WorkoutSession {
        let clean = Exercise(name: "Power Clean", muscleGroup: "Piernas")
        let entry = SessionExercise(
            exercise: clean,
            plannedSets: [PlannedSet(targetReps: 5)],
            loggedSets: recorded,
            isCompleted: isCompleted,
            blockKind: kind,
            wodFormat: .emom
        )
        return WorkoutSession(
            title: "EMOM real",
            exercises: [entry],
            phase: .finished,
            startedAt: now.addingTimeInterval(-3600),
            finishedAt: now.addingTimeInterval(-60)
        )
    }

    func testConfirmedWODWithoutLoggedSetsPaintsMuscles() {
        let workout = session(isCompleted: true)
        let load = MuscleLoadEngine.load(
            workouts: [workout], window: .week, now: now
        )
        let fatigue = MuscleMapEngine.retainedLoad(workouts: [workout], now: now)
        XCTAssertFalse(load.isEmpty)
        XCTAssertTrue(load.values.contains { $0 > 0 })
        XCTAssertTrue(fatigue.values.contains { $0 > 0 })
        XCTAssertEqual(MuscleCompletedWODStimulus.estimatedSetEquivalent(
            for: workout.exercises[0], hardOnly: false
        ), 1)
    }

    func testUnconfirmedPlansDoNotProducePhantomMuscles() {
        for workout in [
            session(isCompleted: false),
            session(isCompleted: false, kind: .strength)
        ] {
            XCTAssertTrue(MuscleLoadEngine.load(
                workouts: [workout], window: .week, now: now
            ).isEmpty)
            XCTAssertTrue(MuscleMapEngine.retainedLoad(
                workouts: [workout], now: now
            ).isEmpty)
        }
    }

    func testFinishedConfirmedStrengthWithoutManualSetCheckCountsInProgress() {
        let workout = session(isCompleted: true, kind: .strength)
        XCTAssertTrue(workout.exercises[0].loggedSets.isEmpty)
        let sets = StatsEngine.confirmedWorkSets(workout.exercises[0], in: workout)
        XCTAssertEqual(sets.count, 1)
        XCTAssertEqual(sets[0].reps, 5)
        // El RIR prescrito no se debe presentar como esfuerzo real.
        XCTAssertNil(sets[0].rir)

        let load = MuscleLoadEngine.load(workouts: [workout], window: .week, now: now)
        let fatigue = MuscleMapEngine.retainedLoad(workouts: [workout], now: now)
        XCTAssertFalse(load.isEmpty)
        XCTAssertFalse(fatigue.isEmpty)
        XCTAssertTrue(MuscleLoadEngine.load(
            workouts: [workout], window: .week, now: now, hardOnly: true
        ).isEmpty)
    }

    func testEditedRecordedSetsBeatPrescriptionAndCalculateVolume() {
        var workout = session(isCompleted: false, kind: .strength, recorded: [
            LoggedSet(reps: 7, weightKg: 55, rir: 2),
            LoggedSet(reps: 4, weightKg: 60, rir: 1)
        ])
        workout.exercises[0].plannedSets = [PlannedSet(targetReps: 5, targetWeightKg: 40)]
        XCTAssertEqual(
            StatsEngine.confirmedWorkSets(workout.exercises[0], in: workout).map(\.reps),
            [7, 4]
        )
        XCTAssertEqual(workout.totalVolumeKg, 625, accuracy: 0.001)
        XCTAssertEqual(StatsEngine.totalSets(in: workout), 2)
    }

    func testEstimatedWODNeverCountsAsHardSetsWithoutRIR() {
        let workout = session(isCompleted: true)
        XCTAssertTrue(MuscleLoadEngine.load(
            workouts: [workout], window: .week, now: now, hardOnly: true
        ).isEmpty)
        XCTAssertTrue(MuscleMapEngine.retainedLoad(
            workouts: [workout], hardOnly: true, now: now
        ).isEmpty)
    }

    func testRecordedSetsRemainSourceOfTruthWithoutDoubleCount() {
        let workout = session(isCompleted: true, recorded: [
            LoggedSet(reps: 5, rir: 2),
            LoggedSet(reps: 5, rir: 2)
        ])
        XCTAssertEqual(MuscleCompletedWODStimulus.estimatedSetEquivalent(
            for: workout.exercises[0], hardOnly: false
        ), 0)
        let load = MuscleLoadEngine.load(
            workouts: [workout], window: .week, now: now
        )
        XCTAssertEqual(load["quadriceps"], 0.8, accuracy: 0.00001)
    }
}
