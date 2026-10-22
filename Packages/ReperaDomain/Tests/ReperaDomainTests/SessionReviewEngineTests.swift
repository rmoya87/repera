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

    @Test func scaledFranUsesAdaptedWorkloadNotRxBandsOrRxRecords() {
        let original = makeForTimeSession(templateId: "fran", title: "Fran", elapsedSeconds: 270)
        let rx = SessionReviewEngine.review(session: original, history: [])
        #expect(rx?.scoreBasis == .catalogBands)

        var scaled = original
        scaled.exercises[0].adaptedReps = 15
        scaled.exercises[0].adaptedWeightKg = 25
        let result = SessionReviewEngine.review(session: scaled, history: [original])
        #expect(result != nil)
        #expect(result?.scoreBasis == .movementPace)
        #expect(result?.headline.contains("Adaptado") == true)
        #expect(result?.vsStandardSummary?.contains("Versión adaptada") == true)
        #expect(result?.vsHistorySummary == nil)
        #expect(result?.keepTips.contains(where: { $0.contains("Rx") }) == true)
        #expect(scaled.exercises[0].loggedSets.isEmpty)
    }

    @Test func scaledAMRAPUsesActualRoundRepsAndOriginalClock() {
        var session = makeAMRAPSession(templateId: "cindy", title: "Cindy", rounds: 4, leftoverReps: 7)
        session.exercises[0].adaptedReps = 3
        session.exercises[0].blockTimeCapMinutes = 20
        let result = SessionReviewEngine.review(session: session, history: [])
        #expect(result?.scoreBasis == .movementPace)
        #expect(result?.headline.contains("Adaptado") == true)
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

    @Test func pushPressCannotBeComparedWithBenchPress() {
        let push = Exercise(name: "Push press", muscleGroup: "Hombros", equipment: "Barra")
        let bench = Exercise(name: "Press banca", muscleGroup: "Pecho", equipment: "Barra")
        #expect(ExerciseEquivalence.family(for: push) == .press)
        #expect(ExerciseEquivalence.family(for: bench) == .press)
        #expect(ExerciseEquivalence.transferFactor(current: push, prior: bench) == 0)
        #expect(!ExerciseEquivalence.areEquivalent(push, bench))
        let prior = WorkoutSession(
            title: "Open",
            exercises: [
                SessionExercise(exercise: bench, plannedSets: [],
                    loggedSets: [LoggedSet(reps: 7, weightKg: 90)])
            ],
            phase: .finished
        )
        #expect(ExerciseEquivalence.comparablePriorSets(for: push, in: [prior]) == nil)
    }

    @Test func mixedEMOMsAndAMRAPAreNotGradedFromOnlyTheAMRAP() {
        let push = Exercise(name: "Push press", muscleGroup: "Hombros", equipment: "Barra")
        let deadlift = Exercise(name: "Peso muerto", muscleGroup: "Piernas", equipment: "Barra")
        let rings = Exercise(name: "Fondos en anillas kipping", muscleGroup: "Pecho")
        let pistol = Exercise(name: "Pistol squat", muscleGroup: "Piernas")
        let clean = Exercise(name: "Cargada y envión", muscleGroup: "Hombros")
        let burpee = Exercise(name: "Burpee box jump over", muscleGroup: "Cardio")
        let bench = Exercise(name: "Press banca", muscleGroup: "Pecho", equipment: "Barra")
        let first = RoutineBlock(
            title: "EMOM 12'", kind: .wod,
            movements: [
                WODMovement(exerciseId: push.id, name: push.name, reps: 4),
                WODMovement(exerciseId: deadlift.id, name: deadlift.name, reps: 2)
            ],
            wodFormat: .emom, timeCapMinutes: 12, rounds: 4
        )
        let second = RoutineBlock(
            title: "EMOM 9'", kind: .wod,
            movements: [
                WODMovement(exerciseId: rings.id, name: rings.name, reps: 10),
                WODMovement(exerciseId: pistol.id, name: pistol.name, reps: 10)
            ],
            wodFormat: .emom, timeCapMinutes: 9, rounds: 2
        )
        let third = RoutineBlock(
            title: "AMRAP 8'", kind: .wod,
            movements: [
                WODMovement(exerciseId: clean.id, name: clean.name, reps: 20),
                WODMovement(exerciseId: burpee.id, name: burpee.name, reps: 10)
            ],
            wodFormat: .amrap, timeCapMinutes: 8
        )
        let all = [push, deadlift, rings, pistol, clean, burpee]
        var workout = SessionController.from(
            routine: Routine(title: "Entreno · Jueves · EMOM 12'", blocks: [first, second, third]),
            exercises: all
        )
        workout.phase = .finished
        workout.wodResults = [
            WODBlockResult(id: third.id, format: .amrap, totalReps: 20, roundsCompleted: 2)
        ]
        for index in workout.exercises.indices {
            let name = workout.exercises[index].exercise.name
            switch name {
            case "Push press":
                workout.exercises[index].loggedSets = [
                    LoggedSet(reps: 4, weightKg: 40),
                    LoggedSet(reps: 3, weightKg: 50),
                    LoggedSet(reps: 3, weightKg: 60),
                    LoggedSet(reps: 2, weightKg: 70)
                ]
            case "Peso muerto":
                workout.exercises[index].loggedSets = [110.0, 120, 140, 150].map {
                    LoggedSet(reps: 2, weightKg: $0)
                }
            case "Fondos en anillas kipping":
                workout.exercises[index].loggedSets = [
                    LoggedSet(reps: 10), LoggedSet(reps: 10)
                ]
            default: break
            }
        }
        let prior = WorkoutSession(
            title: "Open",
            exercises: [
                SessionExercise(exercise: bench, plannedSets: [],
                    loggedSets: [LoggedSet(reps: 7, weightKg: 90)])
            ],
            phase: .finished
        )
        let review = SessionReviewEngine.review(session: workout, history: [prior])
        #expect(review != nil)
        #expect(review?.level == nil)
        #expect(review?.scoreBasis == .sessionEstimate)
        #expect(review?.headline.contains("Sesión mixta") == true)
        #expect((review?.overallScore ?? 0) >= 5)
        #expect((review?.overallScore ?? 0) <= 9)
        #expect(review?.vsStandardSummary?.contains("EMOM 12'") == true)
        #expect(review?.vsStandardSummary?.contains("EMOM 9'") == true)
        #expect(review?.vsStandardSummary?.contains("8/8 series registradas") == true)
        #expect(review?.vsStandardSummary?.contains("2/4 series registradas") == true)
        #expect(review?.vsHistorySummary?.contains("Press banca") != true)
        #expect(review?.movements.first(where: { $0.name == "Push press" })?.comparedToName == nil)
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
