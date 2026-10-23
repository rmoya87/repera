import Foundation

public enum Catalog {
    /// Process-wide seed cache. `@unchecked Sendable` + lock — built once, read many.
    private final class SeedCache: @unchecked Sendable {
        private let lock = NSLock()
        private var value: [Exercise]?

        func getOrCreate(_ build: () -> [Exercise]) -> [Exercise] {
            lock.lock()
            defer { lock.unlock() }
            if let value { return value }
            let built = build()
            value = built
            return built
        }
    }

    private static let cache = SeedCache()

    /// Safe to call from a background task before UI merges touch `seed()`.
    public static func prewarm() {
        _ = seed()
    }

    public static func seed() -> [Exercise] {
        cache.getOrCreate {
            (CatalogEnrichment.rows
                + CatalogHalterofilia.rows
                + CatalogGimnasia.rows
                + CatalogCrossFit.rows
                + CatalogMovilidad.rows).map { row in
                let localized = CatalogSpanish.localize(
                    name: row.name,
                    description: row.description,
                    instructions: row.instructions
                )
                return Exercise(
                    name: row.name,
                    muscleGroup: row.muscleGroup,
                    equipment: row.equipment,
                    isCustom: false,
                    catalogId: row.catalogId,
                    targetMuscle: row.target,
                    secondaryMuscles: row.secondaryMuscles,
                    bodyPart: row.bodyPart,
                    detailDescription: localized.description,
                    instructions: localized.instructions,
                    primaryRegions: row.primaries.isEmpty
                        ? (row.target.map { [$0] } ?? [])
                        : row.primaries,
                    secondaryRegions: row.secondaries,
                    sportTag: row.sportTag
                )
            }
        }
    }

    /// Plan demo solo para tests; la app no lo carga.
    public static func defaultWeekPlan(exercises: [Exercise]) -> [Routine] {
        func ids(_ names: [String]) -> [Exercise] {
            names.compactMap { name in exercises.first { $0.name == name } }
        }

        func sets(_ exercise: Exercise, reps: Int, weight: Double?, count: Int = 3) -> RoutineExercise {
            RoutineExercise(
                exerciseId: exercise.id,
                plannedSets: (0..<count).map { _ in PlannedSet(targetReps: reps, targetWeightKg: weight) }
            )
        }

        let push = ids(["Press banca", "Press militar", "Elevaciones laterales", "Extensión tríceps polea"])
        let pull = ids(["Dominadas", "Remo con barra", "Face pull", "Curl barra"])
        let legs = ids(["Sentadilla", "Peso muerto rumano", "Prensa", "Elevación de gemelos"])

        return [
            Routine(title: "Push", weekday: 1, exercises: push.map { sets($0, reps: 8, weight: 40) }),
            Routine(title: "Pull", weekday: 2, exercises: pull.map { sets($0, reps: 8, weight: 40) }),
            Routine(title: "Legs", weekday: 3, exercises: legs.map { sets($0, reps: 8, weight: 60) }),
            Routine(title: "Push 2", weekday: 5, exercises: push.map { sets($0, reps: 10, weight: 35) }),
            Routine(title: "Pull 2", weekday: 6, exercises: pull.map { sets($0, reps: 10, weight: 35) }),
        ]
    }
}
