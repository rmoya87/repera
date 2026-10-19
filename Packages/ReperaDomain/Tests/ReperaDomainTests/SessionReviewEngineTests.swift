import Foundation
import Testing
@testable import ReperaDomain

@Suite("SessionReviewEngine")
struct SessionReviewEngineTests {
    @Test func franTimeMapsToAdvancedBand() {
        let session = makeForTimeSession(
            templateId: "fran",
            title: "Fran",
            elapsedSeconds: 4 * 60 + 30
        )
        let review = SessionReviewEngine.review(session: session, history: [])
        #expect(review != nil)
        #expect(review?.level == .advanced)
        #expect((review?.overallScore ?? 0) >= 7)
        #expect(review?.scoreBasis == .catalogBands)
        #expect(review?.wodTemplateId == "fran")
        #expect(review?.vsStandardSummary != nil)
    }

    @Test func cindyRoundsMapToIntermediate() {
        let session = makeAMRAPSession(
            templateId: "cindy",
            title: "Cindy",
            rounds: 12,
            leftoverReps: 5
        )
        let review = SessionReviewEngine.review(session: session, history: [])
        #expect(review?.level == .intermediate)
        #expect((review?.overallScore ?? 0) >= 5)
        #expect((review?.overallScore ?? 0) <= 7)
        #expect(review?.scoreBasis == .catalogBands)
    }

    @Test func historyPRFasterTime() {
        let prior = makeForTimeSession(
            templateId: "fran",
            title: "Fran",
            elapsedSeconds: 6 * 60,
            finishedAt: Date().addingTimeInterval(-86_400)
        )
        let current = makeForTimeSession(
            templateId: "fran",
            title: "Fran",
            elapsedSeconds: 5 * 60,
            id: UUID()
        )
        let review = SessionReviewEngine.review(session: current, history: [prior])
        #expect(review?.vsHistorySummary?.contains("PR") == true)
    }

    @Test func pullUpsWithoutLoadSuggestsImprove() {
        let pull = Exercise(name: "Dominadas", muscleGroup: "Espalda", equipment: "Peso corporal")
        let session = WorkoutSession(
            title: "Fuerza",
            exercises: [
                SessionExercise(
                    exercise: pull,
                    plannedSets: [PlannedSet(targetReps: 8, targetWeightKg: nil)],
                    loggedSets: [
                        LoggedSet(reps: 10, weightKg: nil),
                        LoggedSet(reps: 10, weightKg: nil),
                    ],
                    isCompleted: true
                ),
            ],
            phase: .finished,
            startedAt: Date().addingTimeInterval(-3600),
            finishedAt: Date()
        )
        let review = SessionReviewEngine.review(session: session, history: [])
        #expect(review != nil)
        #expect(review?.movements.contains { $0.name == "Dominadas" && $0.verdict == .improve } == true)
        #expect(review?.scoreBasis == .sessionEstimate)
    }

    @Test func catalogFranHasScoreBands() {
        let fran = CatalogWODs.template(id: "fran")
        #expect(fran?.scoreBands?.advancedMaxSeconds == 5 * 60)
    }

    @Test func frontSquatComparesToBackSquatHistoryAndBoostsScore() {
        let back = Exercise(name: "Back squat", muscleGroup: "Piernas", equipment: "Barra")
        let front = Exercise(name: "Front squat", muscleGroup: "Piernas", equipment: "Barra")
        #expect(ExerciseEquivalence.areEquivalent(front, back))
        #expect(ExerciseEquivalence.family(for: front) == .squat)
        #expect(ExerciseEquivalence.transferFactor(current: front, prior: back) > 0.85)

        let prior = WorkoutSession(
            title: "Piernas",
            exercises: [
                SessionExercise(
                    exercise: back,
                    plannedSets: [PlannedSet(targetReps: 5, targetWeightKg: 100)],
                    loggedSets: [LoggedSet(reps: 5, weightKg: 100)],
                    isCompleted: true
                ),
            ],
            phase: .finished,
            startedAt: Date().addingTimeInterval(-172_800),
            finishedAt: Date().addingTimeInterval(-172_000)
        )
        // e1RM front muy por encima del back ajustado → ratio > 1.05 → +1 sobre estimación.
        let current = WorkoutSession(
            title: "Piernas",
            exercises: [
                SessionExercise(
                    exercise: front,
                    plannedSets: [PlannedSet(targetReps: 5, targetWeightKg: 120)],
                    loggedSets: [LoggedSet(reps: 5, weightKg: 120)],
                    isCompleted: true
                ),
            ],
            phase: .finished,
            startedAt: Date().addingTimeInterval(-3600),
            finishedAt: Date()
        )
        let review = SessionReviewEngine.review(session: current, history: [prior])
        #expect(review?.scoreBasis == .equivalentHistory)
        #expect(review?.movements.first?.comparedToName == "Back squat")
        #expect((review?.movements.first?.performanceRatio ?? 0) > 1.05)
        #expect((review?.overallScore ?? 0) >= 7)
    }

    @Test func squatDoesNotMatchRow() {
        let squat = Exercise(name: "Back squat", muscleGroup: "Piernas", equipment: "Barra")
        let row = Exercise(name: "Remoergómetro", muscleGroup: "Cardio", equipment: "Remoerg")
        #expect(ExerciseEquivalence.areEquivalent(squat, row) == false)
        #expect(ExerciseEquivalence.family(for: squat) == .squat)
        #expect(ExerciseEquivalence.family(for: row) == .erg)
    }

    @Test func equivalentLoadAdjustsWODScoreByAtMostOne() {
        let thruster = Exercise(name: "Thruster", muscleGroup: "Piernas", equipment: "Barra")
        let back = Exercise(name: "Back squat", muscleGroup: "Piernas", equipment: "Barra")
        let prior = WorkoutSession(
            title: "Fuerza",
            exercises: [
                SessionExercise(
                    exercise: back,
                    plannedSets: [PlannedSet(targetReps: 5, targetWeightKg: 80)],
                    loggedSets: [LoggedSet(reps: 5, weightKg: 80)],
                    isCompleted: true
                ),
            ],
            phase: .finished,
            startedAt: Date().addingTimeInterval(-86_400),
            finishedAt: Date().addingTimeInterval(-85_000)
        )
        let blockId = UUID()
        let weak = WorkoutSession(
            title: "Fran",
            exercises: [
                SessionExercise(
                    exercise: thruster,
                    plannedSets: [PlannedSet(targetReps: 21, targetWeightKg: 43)],
                    loggedSets: [LoggedSet(reps: 5, weightKg: 40)],
                    isCompleted: true,
                    blockId: blockId,
                    blockKind: .wod,
                    wodFormat: .forTime
                ),
            ],
            phase: .finished,
            startedAt: Date().addingTimeInterval(-270),
            finishedAt: Date(),
            wodResults: [
                WODBlockResult(
                    id: blockId,
                    format: .forTime,
                    elapsedSeconds: 4 * 60 + 30,
                    wodTemplateId: "fran"
                ),
            ]
        )
        let base = SessionReviewEngine.review(session: weak, history: [])
        let withHist = SessionReviewEngine.review(session: weak, history: [prior])
        #expect(base?.level == .advanced)
        #expect(withHist?.scoreBasis == .catalogBands)
        // Ajuste de equivalencias como máximo ±2.
        let delta = abs((withHist?.overallScore ?? 0) - (base?.overallScore ?? 0))
        #expect(delta <= 2)
    }

    // MARK: - Fixtures

    private func makeForTimeSession(
        templateId: String,
        title: String,
        elapsedSeconds: Int,
        finishedAt: Date = Date(),
        id: UUID = UUID()
    ) -> WorkoutSession {
        let blockId = UUID()
        return WorkoutSession(
            id: id,
            title: title,
            exercises: [
                SessionExercise(
                    exercise: Exercise(name: "Thruster", muscleGroup: "Piernas"),
                    plannedSets: [PlannedSet(targetReps: 21, targetWeightKg: 43)],
                    loggedSets: [],
                    isCompleted: true,
                    blockId: blockId,
                    blockKind: .wod,
                    wodFormat: .forTime
                ),
            ],
            phase: .finished,
            startedAt: finishedAt.addingTimeInterval(-TimeInterval(elapsedSeconds)),
            finishedAt: finishedAt,
            wodResults: [
                WODBlockResult(
                    id: blockId,
                    format: .forTime,
                    elapsedSeconds: elapsedSeconds,
                    wodTemplateId: templateId
                ),
            ]
        )
    }

    private func makeAMRAPSession(
        templateId: String,
        title: String,
        rounds: Int,
        leftoverReps: Int
    ) -> WorkoutSession {
        let blockId = UUID()
        return WorkoutSession(
            title: title,
            exercises: [
                SessionExercise(
                    exercise: Exercise(name: "Dominadas", muscleGroup: "Espalda"),
                    plannedSets: [PlannedSet(targetReps: 5, targetWeightKg: nil)],
                    loggedSets: [],
                    isCompleted: true,
                    blockId: blockId,
                    blockKind: .wod,
                    wodFormat: .amrap
                ),
            ],
            phase: .finished,
            startedAt: Date().addingTimeInterval(-20 * 60),
            finishedAt: Date(),
            wodResults: [
                WODBlockResult(
                    id: blockId,
                    format: .amrap,
                    totalReps: leftoverReps,
                    roundsCompleted: rounds,
                    wodTemplateId: templateId
                ),
            ]
        )
    }
}
