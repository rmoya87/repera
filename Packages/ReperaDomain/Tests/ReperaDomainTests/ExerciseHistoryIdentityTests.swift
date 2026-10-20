import Foundation
import Testing
@testable import ReperaDomain

@Suite("Exercise history identity")
struct ExerciseHistoryIdentityTests {
    @Test func historyMatchesOrphanSessionByName() {
        let catalogId = UUID()
        let orphanId = UUID()
        let catalog = Exercise(
            id: catalogId,
            name: "Dominadas",
            muscleGroup: "Espalda",
            equipment: "Peso corporal",
            catalogId: "pull-up"
        )
        let orphan = Exercise(
            id: orphanId,
            name: "Dominadas",
            muscleGroup: "WOD",
            isCustom: true
        )
        let session = WorkoutSession(
            title: "EMOM 12'",
            exercises: [
                SessionExercise(
                    exercise: orphan,
                    plannedSets: [],
                    loggedSets: [
                        LoggedSet(reps: 4, weightKg: 20),
                        LoggedSet(reps: 3, weightKg: 24),
                    ],
                    isCompleted: true
                ),
            ],
            phase: .finished,
            startedAt: Date().addingTimeInterval(-3600),
            finishedAt: Date()
        )

        let byCatalog = StatsEngine.history(
            for: catalogId,
            workouts: [session],
            catalog: [catalog]
        )
        #expect(byCatalog.timesPerformed == 1)
        #expect(byCatalog.maxWeightKg == 24)
        #expect(byCatalog.hasData)

        let byOrphan = StatsEngine.history(
            for: orphanId,
            workouts: [session],
            catalog: [catalog]
        )
        #expect(byOrphan.timesPerformed == 1)
        #expect(byOrphan.hasData)
    }

    @Test func lastSessionFindsOrphanViaCatalogId() {
        let catalog = Exercise(
            id: UUID(),
            name: "HSPU",
            muscleGroup: "Hombros",
            catalogId: "hspu"
        )
        let orphan = Exercise(
            id: UUID(),
            name: "HSPU",
            muscleGroup: "WOD",
            isCustom: true,
            catalogId: "hspu"
        )
        let session = WorkoutSession(
            title: "EMOM",
            exercises: [
                SessionExercise(
                    exercise: orphan,
                    plannedSets: [],
                    loggedSets: [LoggedSet(reps: 5, weightKg: nil, deficitCm: 5)],
                    isCompleted: true
                ),
            ],
            phase: .finished,
            finishedAt: Date()
        )
        let last = StatsEngine.lastWorkingSession(
            for: catalog.id,
            workouts: [session],
            catalog: [catalog]
        )
        #expect(last != nil)
        #expect(last?.sets.count == 1)
    }
}
