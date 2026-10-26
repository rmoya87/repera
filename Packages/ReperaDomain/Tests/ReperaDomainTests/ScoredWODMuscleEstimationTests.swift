import XCTest
@testable import ReperaDomain

final class ScoredWODMuscleEstimationTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeWOD(
        reps: Int = 10,
        rounds: Int? = 4,
        partial: Int? = 0,
        elapsed: Int? = nil,
        format: WODFormat = .amrap,
        finished: Bool = true,
        withRecordedSets: Bool = false
    ) -> WorkoutSession {
        let block = UUID()
        let squat = Exercise(name: "Air Squat", muscleGroup: "Piernas")
        let pull = Exercise(name: "Pull Up", muscleGroup: "Espalda")
        let first = SessionExercise(
            exercise: squat, plannedSets: [PlannedSet(targetReps: reps)],
            loggedSets: withRecordedSets ? [LoggedSet(reps: reps)] : [],
            blockId: block, blockKind: .wod, wodFormat: format,
            blockTimeCapMinutes: 12, blockRounds: 4
        )
        let second = SessionExercise(
            exercise: pull, plannedSets: [PlannedSet(targetReps: 10)],
            blockId: block, blockKind: .wod, wodFormat: format,
            blockTimeCapMinutes: 12, blockRounds: 4
        )
        return WorkoutSession(
            title: "WOD test", exercises: [first, second],
            phase: finished ? .finished : .counting,
            startedAt: now.addingTimeInterval(-720),
            finishedAt: finished ? now : nil,
            wodResults: [WODBlockResult(
                id: block, format: format, totalReps: partial,
                elapsedSeconds: elapsed, roundsCompleted: rounds
            )]
        )
    }

    func testMoreRoundsIncreaseFatigueAndEstimatedEffort() {
        let shorter = makeWOD(rounds: 2)
        let longer = makeWOD(rounds: 7)
        let l1 = MuscleCompletedWODStimulus.estimatedSetEquivalent(
            for: shorter.exercises[0], in: shorter, hardOnly: false
        )
        let l2 = MuscleCompletedWODStimulus.estimatedSetEquivalent(
            for: longer.exercises[0], in: longer, hardOnly: false
        )
        XCTAssertGreaterThan(l2, l1)
        let e1 = MuscleCompletedWODStimulus.estimatedSetEquivalent(
            for: shorter.exercises[0], in: shorter, hardOnly: true
        )
        let e2 = MuscleCompletedWODStimulus.estimatedSetEquivalent(
            for: longer.exercises[0], in: longer, hardOnly: true
        )
        XCTAssertGreaterThan(e2, e1)
    }

    func testAMRAPPartialRepsAreOnlyAttributedToReachedMovement() {
        let wod = makeWOD(rounds: 1, partial: 5)
        let first = MuscleCompletedWODStimulus.estimatedSetEquivalent(
            for: wod.exercises[0], in: wod, hardOnly: false
        )
        let second = MuscleCompletedWODStimulus.estimatedSetEquivalent(
            for: wod.exercises[1], in: wod, hardOnly: false
        )
        XCTAssertGreaterThan(first, second)
    }

    func testSlowerForTimeHasLowerEstimatedEffortForSameVolume() {
        let fast = makeWOD(rounds: nil, partial: nil, elapsed: 300, format: .forTime)
        let slow = makeWOD(rounds: nil, partial: nil, elapsed: 1000, format: .forTime)
        let e1 = MuscleCompletedWODStimulus.estimatedSetEquivalent(
            for: fast.exercises[0], in: fast, hardOnly: true
        )
        let e2 = MuscleCompletedWODStimulus.estimatedSetEquivalent(
            for: slow.exercises[0], in: slow, hardOnly: true
        )
        XCTAssertGreaterThan(e1, e2)
    }

    func testLoggedSetsStaySourceOfTruthAndAvoidDoubleCounting() {
        let wod = makeWOD(withRecordedSets: true)
        XCTAssertFalse(MuscleCompletedWODStimulus.usesScoredEstimate(
            for: wod.exercises[0], in: wod
        ))
        XCTAssertEqual(MuscleCompletedWODStimulus.estimatedSetEquivalent(
            for: wod.exercises[0], in: wod, hardOnly: false
        ), 0)
    }

    func testUnfinishedWODDoesNotContributeFatigue() {
        let wod = makeWOD(finished: false)
        XCTAssertEqual(MuscleCompletedWODStimulus.estimatedSetEquivalent(
            for: wod.exercises[0], in: wod, hardOnly: false
        ), 0)
    }

    func testMuscleMapAndPeriodLoadUseScoreRatherThanPrescribedSets() {
        let wod = makeWOD(rounds: 7)
        let estimated = MuscleCompletedWODStimulus.estimatedSetEquivalent(
            for: wod.exercises[0], in: wod, hardOnly: false
        )
        XCTAssertGreaterThan(estimated, 1)
        let load = MuscleLoadEngine.load(workouts: [wod], window: .all, now: now)
        let fatigue = MuscleMapEngine.retainedLoad(workouts: [wod], now: now)
        XCTAssertTrue(load.values.contains { $0 > 0 })
        XCTAssertTrue(fatigue.values.contains { $0 > 0 })
    }
}
