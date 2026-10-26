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

    func testUnconfirmedAndStrengthPlansDoNotProducePhantomMuscles() {
        for workout in [
            session(isCompleted: false),
            session(isCompleted: true, kind: .strength)
        ] {
            XCTAssertTrue(MuscleLoadEngine.load(
                workouts: [workout], window: .week, now: now
            ).isEmpty)
            XCTAssertTrue(MuscleMapEngine.retainedLoad(
                workouts: [workout], now: now
            ).isEmpty)
        }
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
