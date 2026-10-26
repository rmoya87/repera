import XCTest
@testable import ReperaDomain

/// Finalizar la sesión equivale a dar por hecho lo prescrito; el check
/// manual NO es necesario para datos antiguos ni nuevos.
final class CompletedWODMuscleStimulusTests: XCTestCase {
    private let now = Date()

    private func session(
        isCompleted: Bool,
        kind: RoutineBlockKind = .wod,
        recorded: [LoggedSet] = [],
        finished: Bool = true
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
            phase: finished ? .finished : .counting,
            startedAt: now.addingTimeInterval(-3600),
            finishedAt: finished ? now.addingTimeInterval(-60) : nil
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
            for: workout.exercises[0], in: workout, hardOnly: false
        ), 1)
    }

    func testFinishedUncheckedWorkoutsCountForMuscleAndExerciseProgress() {
        for workout in [
            session(isCompleted: false),
            session(isCompleted: false, kind: .strength)
        ] {
            let entry = workout.exercises[0]
            XCTAssertEqual(StatsEngine.confirmedWorkSets(entry, in: workout).map(\.reps), [5])
            XCTAssertNil(StatsEngine.confirmedWorkSets(entry, in: workout).first?.rir)
            XCTAssertFalse(MuscleLoadEngine.load(
                workouts: [workout], window: .week, now: now
            ).isEmpty)
            XCTAssertFalse(MuscleMapEngine.retainedLoad(
                workouts: [workout], now: now
            ).isEmpty)
            XCTAssertEqual(StatsEngine.history(
                for: entry.exercise.id, workouts: [workout]
            ).timesPerformed, 1)
            XCTAssertTrue(MuscleLoadEngine.load(
                workouts: [workout], window: .week, now: now, hardOnly: true
            ).isEmpty)
        }
    }

    func testUnfinishedPlansWithoutRecordedSetsStillDoNotCount() {
        for workout in [
            session(isCompleted: false, finished: false),
            session(isCompleted: false, kind: .strength, finished: false)
        ] {
            XCTAssertTrue(StatsEngine.confirmedWorkSets(
                workout.exercises[0], in: workout
            ).isEmpty)
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

    func testWarmupOnlyNeverInventsPlannedWorkingSets() {
        let warmup = LoggedSet(reps: 5, weightKg: 20, phase: .warmup)
        let workout = session(isCompleted: true, kind: .strength, recorded: [warmup])
        XCTAssertTrue(StatsEngine.confirmedWorkSets(workout.exercises[0], in: workout).isEmpty)
        XCTAssertTrue(MuscleLoadEngine.load(
            workouts: [workout], window: .week, now: now
        ).isEmpty)
        XCTAssertEqual(workout.totalVolumeKg, 0, accuracy: 0.001)
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
            for: workout.exercises[0], in: workout, hardOnly: false
        ), 0)
        let load = MuscleLoadEngine.load(
            workouts: [workout], window: .week, now: now
        )
        XCTAssertEqual(load["quadriceps"], 0.8, accuracy: 0.00001)
    }
}
