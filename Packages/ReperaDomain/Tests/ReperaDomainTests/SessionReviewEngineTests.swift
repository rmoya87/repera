import Foundation
import Testing
@testable import ReperaDomain

@Suite("Valoración personal verificable")
struct SessionReviewEngineTests {
    private let today = Date(timeIntervalSince1970: 1_800_000_000)
    private let push = Exercise(name: "Push press", muscleGroup: "Hombros", equipment: "Barra")
    private let bench = Exercise(name: "Press banca", muscleGroup: "Pecho", equipment: "Barra")

    private func strength(
        _ ex: Exercise, kg: Double, reps: Int = 5, daysAgo: Double,
        id: UUID = UUID(), targetKg: Double? = nil
    ) -> WorkoutSession {
        let finish = today.addingTimeInterval(-daysAgo * 86_400)
        return WorkoutSession(
            id: id,
            title: ex.name,
            exercises: [SessionExercise(
                exercise: ex,
                plannedSets: [PlannedSet(targetReps: reps, targetWeightKg: targetKg ?? kg)],
                loggedSets: [LoggedSet(reps: reps, weightKg: kg)]
            )],
            phase: .finished,
            startedAt: finish.addingTimeInterval(-600),
            finishedAt: finish
        )
    }

    private func amrap(
        rounds: Int, partial: Int = 0, reps: Int = 10,
        daysAgo: Double, weight: Double = 0
    ) -> WorkoutSession {
        let ex = Exercise(name: "Burpee box jump over", muscleGroup: "Cardio")
        let block = RoutineBlock(
            title: "AMRAP 8'", kind: .wod,
            movements: [WODMovement(name: ex.name, reps: reps,
                                    weightMaleKg: weight == 0 ? nil : weight)],
            wodFormat: .amrap, timeCapMinutes: 8
        )
        var result = SessionController.from(
            routine: Routine(title: "AMRAP 8'", blocks: [block]), exercises: [ex]
        )
        let finish = today.addingTimeInterval(-daysAgo * 86_400)
        result.phase = .finished
        result.startedAt = finish.addingTimeInterval(-480)
        result.finishedAt = finish
        result.wodResults = [WODBlockResult(id: block.id, format: .amrap,
                                             totalReps: partial, roundsCompleted: rounds)]
        return result
    }

    @Test func noScoreOnFirstSessionEvenWithHighLoad() {
        let session = strength(push, kg: 70, daysAgo: 0)
        #expect(SessionReviewEngine.review(session: session, history: []) == nil)
        #expect(SessionReviewEngine.review(session: session, history: [], cardio:
            SessionCardioSample(averageHeartRateBpm: 185)) == nil)
    }

    @Test func aSinglePreviousDayDoesNotQualify() {
        let prior = strength(push, kg: 65, daysAgo: 2)
        let current = strength(push, kg: 70, daysAgo: 0)
        #expect(SessionReviewEngine.review(session: current, history: [prior]) == nil)
    }

    @Test func sameDayRepeatedSetsOrSessionsAreNotIndependentHistory() {
        let day1 = strength(push, kg: 60, daysAgo: 1.2)
        let day1Again = strength(push, kg: 65, daysAgo: 1.1)
        let current = strength(push, kg: 70, daysAgo: 0)
        #expect(SessionReviewEngine.review(
            session: current, history: [day1, day1Again]
        ) == nil)
    }

    @Test func twoIndependentPreviousDaysUnlockThreeIndicatorsAndOverall() throws {
        let pastA = strength(push, kg: 60, daysAgo: 6)
        let pastB = strength(push, kg: 65, daysAgo: 3)
        let current = strength(push, kg: 70, daysAgo: 0)
        let review = try #require(SessionReviewEngine.review(
            session: current, history: [pastA, pastB]))
        #expect(review.scoreBasis == .personalHistory)
        #expect(review.overallScore >= 7)
        #expect(review.level == nil)
        #expect(review.indicators.map(\.dimension) == ReviewDimension.allCases)
        #expect(review.indicators[0].score != nil)
        #expect(review.indicators[0].referenceSessions == 2)
        #expect(review.indicators[1].score == nil) // registro no es nota
        #expect(review.indicators[2].score == nil) // WOD sin referencias
        #expect(review.evidenceCoverage == 1)
        let roundtrip = try JSONDecoder().decode(SessionReview.self, from: JSONEncoder().encode(review))
        #expect(roundtrip.indicators == review.indicators)
        #expect(roundtrip.confidenceLabel == review.confidenceLabel)
    }

    @Test func benchPressNeverUnlocksPushPressScore() {
        let a = strength(bench, kg: 90, reps: 7, daysAgo: 5)
        let b = strength(bench, kg: 95, reps: 7, daysAgo: 3)
        let current = strength(push, kg: 70, reps: 2, daysAgo: 0)
        #expect(SessionReviewEngine.review(session: current, history: [a, b]) == nil)
        #expect(ExerciseEquivalence.transferFactor(current: push, prior: bench) == 0)
    }

    @Test func lighterPrescribedDayMustNotBePunishedAsRegression() {
        let a = strength(push, kg: 90, daysAgo: 6)
        let b = strength(push, kg: 95, daysAgo: 3)
        let deload = strength(push, kg: 60, daysAgo: 0, targetKg: 60)
        #expect(SessionReviewEngine.review(session: deload, history: [a, b]) == nil)
    }

    @Test func twoSameWODPrescriptionsUnlockWODScore() throws {
        let a = amrap(rounds: 2, daysAgo: 7)
        let b = amrap(rounds: 3, daysAgo: 3)
        let current = amrap(rounds: 4, partial: 2, daysAgo: 0)
        let review = try #require(SessionReviewEngine.review(
            session: current, history: [a, b]))
        #expect(review.scoreBasis == .personalHistory)
        #expect(review.indicators[0].score == nil)
        #expect(review.indicators[2].score != nil)
        #expect(review.indicators[2].referenceSessions == 2)
        #expect(review.overallScore > 0)
    }

    @Test func adaptedOrDifferentPrescriptionCannotUnlockWODScore() {
        let a = amrap(rounds: 2, reps: 10, daysAgo: 7)
        let b = amrap(rounds: 3, reps: 12, daysAgo: 3)
        let current = amrap(rounds: 4, reps: 10, daysAgo: 0)
        #expect(SessionReviewEngine.review(session: current, history: [a, b]) == nil)
    }

    @Test func insufficientCoverageHidesGlobalEvenIfOneExerciseQualifies() {
        let a = strength(push, kg: 60, daysAgo: 8)
        let b = strength(push, kg: 65, daysAgo: 4)
        var current = strength(push, kg: 70, daysAgo: 0)
        let ex2 = Exercise(name: "Peso muerto", muscleGroup: "Piernas")
        let ex3 = Exercise(name: "Dominadas", muscleGroup: "Espalda")
        current.exercises += [
            SessionExercise(exercise: ex2, plannedSets: [PlannedSet(targetReps: 5)],
                            loggedSets: [LoggedSet(reps: 5, weightKg: 110)]),
            SessionExercise(exercise: ex3, plannedSets: [PlannedSet(targetReps: 8)],
                            loggedSets: [LoggedSet(reps: 8)])
        ]
        #expect(SessionReviewEngine.review(session: current, history: [a, b]) == nil)
    }

    @Test func oneHistoricallyComparableMovementCannotGradeLargeUnloggedWorkout() {
        let a = strength(push, kg: 60, daysAgo: 8)
        let b = strength(push, kg: 65, daysAgo: 4)
        var current = strength(push, kg: 70, daysAgo: 0)
        let deadlift = Exercise(name: "Peso muerto", muscleGroup: "Piernas")
        let squat = Exercise(name: "Sentadilla", muscleGroup: "Piernas")
        current.exercises += [
            SessionExercise(exercise: deadlift, plannedSets: [PlannedSet(targetReps: 5)]),
            SessionExercise(exercise: squat, plannedSets: [PlannedSet(targetReps: 5)])
        ]
        // These planned movements have no logged sets; they must still count
        // against the coverage gate rather than artificially unlocking 7/10.
        #expect(SessionReviewEngine.review(session: current, history: [a, b]) == nil)
    }

    @Test func samePushPressAcrossEMOMAndStrengthUsesTierTwoWithRIR() throws {
        var a = strength(push, kg: 60, daysAgo: 7)
        var b = strength(push, kg: 65, daysAgo: 3)
        a.exercises[0].wodFormat = .emom
        b.exercises[0].wodFormat = .emom
        a.exercises[0].blockIntervalSeconds = 60
        b.exercises[0].blockIntervalSeconds = 60
        a.exercises[0].loggedSets[0].rir = 2
        b.exercises[0].loggedSets[0].rir = 2
        var current = strength(push, kg: 70, daysAgo: 0)
        current.exercises[0].loggedSets[0].rir = 2
        let score = try #require(SessionReviewEngine.review(
            session: current, history: [a, b]
        ))
        #expect(score.indicators[0].comparisonLevel == 2)
        #expect(score.indicators[0].referenceSessions == 2)
        #expect(score.confidenceLabel?.contains("Media") == true)
    }

    @Test func differentFormatWithoutRIRStillDoesNotFabricateComparison() {
        var a = strength(push, kg: 60, daysAgo: 7)
        var b = strength(push, kg: 65, daysAgo: 3)
        a.exercises[0].wodFormat = .emom
        b.exercises[0].wodFormat = .emom
        let current = strength(push, kg: 70, daysAgo: 0)
        #expect(SessionReviewEngine.review(session: current, history: [a, b]) == nil)
    }

    private func differentFormatForTime(
        exerciseName: String = "Burpee box jump over",
        reps: Int = 12, minutes: Int = 8, daysAgo: Double
    ) -> WorkoutSession {
        let ex = Exercise(name: exerciseName, muscleGroup: "Cardio")
        let block = RoutineBlock(
            title: "3 RFT", kind: .wod,
            movements: [WODMovement(name: ex.name, reps: reps)],
            wodFormat: .forTime, timeCapMinutes: 12, rounds: 3
        )
        var workout = SessionController.from(
            routine: Routine(title: "For Time", blocks: [block]), exercises: [ex]
        )
        let finish = today.addingTimeInterval(-daysAgo * 86_400)
        workout.phase = .finished
        workout.finishedAt = finish
        workout.startedAt = finish.addingTimeInterval(-Double(minutes * 60))
        workout.wodResults = [
            WODBlockResult(id: block.id, format: .forTime, elapsedSeconds: minutes * 60)
        ]
        return workout
    }

    @Test func threePersonalWODDaysPermitCalibratedCrossFormatStimulus() throws {
        let earlier = [
            differentFormatForTime(minutes: 8, daysAgo: 9),
            differentFormatForTime(minutes: 9, daysAgo: 6),
            differentFormatForTime(minutes: 7, daysAgo: 3)
        ]
        let current = amrap(rounds: 4, partial: 0, reps: 10, daysAgo: 0)
        let result = try #require(SessionReviewEngine.review(
            session: current, history: earlier
        ))
        #expect(result.indicators[2].comparisonLevel == 3)
        #expect(result.indicators[2].referenceSessions == 3)
        #expect(result.confidenceLabel?.contains("Baja") == true)
        #expect(result.indicators[2].detail.contains("densidad de reps"))
    }

    @Test func stimulusRequiresThreeDaysAndSameMovementIdentity() {
        let a = differentFormatForTime(minutes: 8, daysAgo: 9)
        let b = differentFormatForTime(minutes: 9, daysAgo: 6)
        let current = amrap(rounds: 4, reps: 10, daysAgo: 0)
        #expect(SessionReviewEngine.review(session: current, history: [a, b]) == nil)
        let c = differentFormatForTime(exerciseName: "Press banca", daysAgo: 3)
        #expect(SessionReviewEngine.review(session: current, history: [a, b, c]) == nil)
    }

    @Test func legacyReviewIndicatorDecodesWithoutComparisonLevel() throws {
        let old = ReviewIndicator(dimension: .personalProgress, score: 7, detail: "Anterior")
        let serialized = try JSONEncoder().encode(old)
        let result = try JSONDecoder().decode(ReviewIndicator.self, from: serialized)
        #expect(result.comparisonLevel == nil)
    }

    @Test func plannedButUnloggedMovementsNeverCreateScores() {
        let current = WorkoutSession(
            title: "Plan", exercises: [
                SessionExercise(exercise: push, plannedSets: [PlannedSet(targetReps: 5)])
            ], phase: .finished,
            startedAt: today.addingTimeInterval(-600), finishedAt: today
        )
        #expect(SessionReviewEngine.review(session: current, history: []) == nil)
    }
}
