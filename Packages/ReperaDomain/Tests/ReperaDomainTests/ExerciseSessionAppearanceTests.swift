import Foundation
import Testing
@testable import ReperaDomain

@Suite("ExerciseSessionAppearance")
struct ExerciseSessionAppearanceTests {
    @Test func catalogWodComparesGlobalScore() {
        let snatchId = UUID()
        let blockId = UUID()
        let snatch = Exercise(id: snatchId, name: "Arrancada", muscleGroup: "Piernas")
        let session = WorkoutSession(
            title: "Fran",
            exercises: [
                SessionExercise(
                    exercise: snatch,
                    plannedSets: [PlannedSet(targetReps: 21, targetWeightKg: 40)],
                    loggedSets: [],
                    isCompleted: true,
                    blockId: blockId,
                    blockKind: .wod,
                    wodFormat: .forTime
                ),
            ],
            phase: .finished,
            finishedAt: Date(),
            wodResults: [
                WODBlockResult(
                    id: blockId,
                    format: .forTime,
                    elapsedSeconds: 8 * 60 + 30,
                    wodTemplateId: "fran"
                ),
            ]
        )
        let row = StatsEngine.appearance(of: snatchId, in: session, catalog: [snatch])
        #expect(row?.isGlobalWodScore == true)
        #expect(row?.wodTemplateId == "fran")
        #expect(row?.wodScoreLabel == "8:30")
        #expect(row?.setLines.isEmpty == true)
    }

    @Test func freeWodKeepsMovementPrescription() {
        let snatchId = UUID()
        let blockId = UUID()
        let snatch = Exercise(id: snatchId, name: "Arrancada", muscleGroup: "Piernas")
        let session = WorkoutSession(
            title: "RFT libre",
            exercises: [
                SessionExercise(
                    exercise: snatch,
                    plannedSets: [PlannedSet(targetReps: 21, targetWeightKg: 40)],
                    loggedSets: [],
                    isCompleted: true,
                    blockId: blockId,
                    blockKind: .wod,
                    wodFormat: .forTime
                ),
            ],
            phase: .finished,
            finishedAt: Date(),
            wodResults: [
                WODBlockResult(
                    id: blockId,
                    format: .forTime,
                    elapsedSeconds: 9 * 60,
                    wodTemplateId: nil
                ),
            ]
        )
        let row = StatsEngine.appearance(of: snatchId, in: session, catalog: [snatch])
        #expect(row?.isGlobalWodScore == false)
        #expect(row?.prescriptionLine?.contains("21") == true)
        #expect(row?.wodScoreLabel == "9:00")
    }

    @Test func priorCatalogWodMatchesSameTemplateOnly() {
        let id = UUID()
        let ex = Exercise(id: id, name: "Thruster", muscleGroup: "Piernas")
        let blockA = UUID()
        let blockB = UUID()
        let olderFran = WorkoutSession(
            title: "Fran",
            exercises: [
                SessionExercise(
                    exercise: ex,
                    plannedSets: [],
                    loggedSets: [],
                    isCompleted: true,
                    blockId: blockA,
                    blockKind: .wod,
                    wodFormat: .forTime
                ),
            ],
            phase: .finished,
            finishedAt: Date().addingTimeInterval(-86_400),
            wodResults: [
                WODBlockResult(id: blockA, format: .forTime, elapsedSeconds: 7 * 60, wodTemplateId: "fran"),
            ]
        )
        let currentFran = WorkoutSession(
            title: "Fran",
            exercises: [
                SessionExercise(
                    exercise: ex,
                    plannedSets: [],
                    loggedSets: [],
                    isCompleted: true,
                    blockId: blockB,
                    blockKind: .wod,
                    wodFormat: .forTime
                ),
            ],
            phase: .finished,
            finishedAt: Date(),
            wodResults: [
                WODBlockResult(id: blockB, format: .forTime, elapsedSeconds: 6 * 60 + 30, wodTemplateId: "fran"),
            ]
        )
        let prior = StatsEngine.priorAppearances(
            of: id,
            workouts: [olderFran, currentFran],
            catalog: [ex],
            excludingSessionId: currentFran.id,
            limit: 3
        )
        #expect(prior.count == 1)
        #expect(prior.first?.wodScoreLabel == "7:00")
        #expect(prior.first?.isGlobalWodScore == true)
    }
}
