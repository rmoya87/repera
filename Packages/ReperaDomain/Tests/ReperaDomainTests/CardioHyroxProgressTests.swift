import Foundation
import Testing
@testable import ReperaDomain

@Suite("Cardio & HYROX progress")
struct CardioHyroxProgressTests {
    private func session(
        exercise: Exercise,
        date: Date,
        sets: [LoggedSet]
    ) -> WorkoutSession {
        WorkoutSession(
            title: "Cardio",
            exercises: [
                SessionExercise(
                    exercise: exercise,
                    plannedSets: [],
                    loggedSets: sets,
                    isCompleted: true
                ),
            ],
            phase: .finished,
            startedAt: date.addingTimeInterval(-1800),
            finishedAt: date
        )
    }

    @Test func cardioRecordSeparatesMetresCaloriesAndReps() {
        let exercise = Exercise(name: "Remo máquina", muscleGroup: "Cardio", equipment: "Máquina")
        let first = session(
            exercise: exercise,
            date: Date(timeIntervalSince1970: 1_780_000_000),
            sets: [
                LoggedSet(reps: 1000, durationSeconds: 300, quantityUnit: .meters),
                LoggedSet(reps: 30, durationSeconds: 60, quantityUnit: .calories),
            ]
        )
        let second = session(
            exercise: exercise,
            date: Date(timeIntervalSince1970: 1_780_086_400),
            sets: [
                LoggedSet(reps: 1200, durationSeconds: 360, quantityUnit: .meters),
                LoggedSet(reps: 40, durationSeconds: 80, quantityUnit: .calories),
            ]
        )
        let workouts = [second, first]
        let history = StatsEngine.history(for: exercise.id, workouts: workouts, catalog: [exercise])
        #expect(history.bestMeters == 1200)
        #expect(history.bestCalories == 40)
        #expect(history.bestReps == nil)
        #expect(history.timesPerformed == 2)
        #expect(history.estimatedOneRM == nil)

        let meters = StatsEngine.exerciseProgressSeries(
            exerciseId: exercise.id, metric: .bestMeters, range: .all,
            workouts: workouts, catalog: [exercise]
        )
        let calories = StatsEngine.exerciseProgressSeries(
            exerciseId: exercise.id, metric: .bestCalories, range: .all,
            workouts: workouts, catalog: [exercise]
        )
        #expect(meters.map(\.value) == [1000, 1200])
        #expect(calories.map(\.value) == [30, 40])
        #expect(meters.allSatisfy { $0.quantityUnit == .meters })
        #expect(calories.allSatisfy { $0.quantityUnit == .calories })
    }

    @Test func hyroxLoadedDistanceDoesNotCalculateOneRepMax() {
        let exercise = Exercise(name: "Sandbag Lunges", muscleGroup: "Piernas", equipment: "Saco")
        #expect(exercise.defaultQuantityUnit == .meters)
        #expect(exercise.quantityFieldLabel == "m")
        #expect(exercise.loadField == .weightKg)
        let workout = session(
            exercise: exercise,
            date: Date(timeIntervalSince1970: 1_780_000_000),
            sets: [LoggedSet(reps: 100, weightKg: 20, quantityUnit: .meters)]
        )
        let history = StatsEngine.history(for: exercise.id, workouts: [workout], catalog: [exercise])
        #expect(history.bestMeters == 100)
        #expect(history.estimatedOneRM == nil)
        #expect(history.maxWeightKg == nil)
        let points = StatsEngine.exerciseProgressSeries(
            exerciseId: exercise.id, metric: .bestMeters, range: .all,
            workouts: [workout], catalog: [exercise]
        )
        #expect(points.map(\.value) == [100])
        #expect(points.first?.weightKg == 20)
    }

    @Test func sledAndBurpeeDistancesUseMetres() {
        #expect(Exercise.defaultQuantityUnit(name: "Sled push", equipment: "Trineo") == .meters)
        #expect(Exercise.defaultQuantityUnit(name: "Sled pull", equipment: "Trineo") == .meters)
        #expect(Exercise.defaultQuantityUnit(name: "Burpee Broad Jump", equipment: "Peso corporal") == .meters)
        #expect(ExerciseProgressMetric.available(for: .machineWork).contains(.bestMeters))
        #expect(ExerciseProgressMetric.available(for: .machineWork).contains(.bestCalories))
        #expect(!ExerciseProgressMetric.available(for: .loadAndReps).contains(.bestMeters))
    }
}
