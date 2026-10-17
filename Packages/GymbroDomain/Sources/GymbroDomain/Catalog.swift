import Foundation

public enum Catalog {
    /// Built once per process — `seed()` used to rebuild hundreds of exercises on every call.
    private static let cachedSeed: [Exercise] = {
        (CatalogEnrichment.rows
            + CatalogHalterofilia.rows
            + CatalogGimnasia.rows
            + CatalogCrossFit.rows).map { row in
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
                primaryRegions: row.primaries.isEmpty ? [row.muscleGroup.lowercased()] : row.primaries,
                secondaryRegions: row.secondaries,
                sportTag: row.sportTag
            )
        }
    }()

    public static func seed() -> [Exercise] { cachedSeed }

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
