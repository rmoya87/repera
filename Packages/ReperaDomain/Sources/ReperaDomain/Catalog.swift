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
                + CatalogMovilidad.rows
                + CatalogHyrox.rows).map { row in
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

/// Estaciones de HYROX y etiquetas secundarias del catálogo.
///
/// No se generan copias de ejercicios existentes: el movimiento mantiene UUID,
/// deporte de origen e historial aunque pertenezca a CrossFit y a HYROX.
public enum HyroxExercises {
    public static let competitionStations: [String] = [
        "Run", "SkiErg", "Sled push", "Sled pull", "Burpee Broad Jump",
        "Remo máquina", "Farmer carry", "Sandbag Lunges", "Wall ball",
    ]

    private static let matchingNames: Set<String> = Set([
        // Nombre del seed CrossFit y equivalencias históricas en español.
        "Run", "Carrera", "Cinta / carrera", "Running",
        "SkiErg", "Esquí ergómetro",
        "Sled push", "Empuje de trineo",
        "Sled pull", "Arrastre de trineo",
        "Burpee Broad Jump", "Burpee Broad Jumps", "Burpee con salto de longitud", "Burpees con salto de longitud",
        "Remo máquina", "Remoergómetro", "RowErg", "Rowing",
        "Farmer carry", "Farmer walk", "Farmers carry", "Paseo del granjero",
        "Sandbag Lunges", "Sandbag Lunge", "Zancadas con saco",
        "Wall ball", "Wall balls", "Lanzamiento de balón a pared",
    ].map { name in
        name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es_ES"))
            .lowercased()
    })

    public static func isMovement(named name: String) -> Bool {
        let normalized = name.folding(
            options: [.diacriticInsensitive, .caseInsensitive],
            locale: Locale(identifier: "es_ES")
        ).lowercased()
        return matchingNames.contains(normalized)
    }
}

/// Solo se añaden las estaciones ausentes del catálogo existente.
enum CatalogHyrox {
    static let rows: [EnrichedSeed] = [
        CatalogSeedBuilder.sportRow(
            "Burpee Broad Jump", sport: "HYROX", equipment: "Peso corporal",
            target: "cardiovascular system", secondary: ["quadriceps", "glutes", "chest"],
            body: "full body",
            description: "Burpee con salto horizontal continuo, medido en metros para HYROX.",
            instructions: [
                "Colócate detrás de la línea de salida.",
                "Apoya manos y desciende el pecho al suelo.",
                "Recoge los pies y salta hacia delante con ambos pies.",
                "Aterriza con control y continúa hasta completar la distancia.",
            ],
            primaries: ["quadriceps", "gluteal"],
            secondaries: ["chest", "abs"]
        ),
        CatalogSeedBuilder.sportRow(
            "Sandbag Lunges", sport: "HYROX", equipment: "Saco",
            target: "quads", secondary: ["glutes", "hamstrings", "core"],
            body: "upper legs",
            description: "Zancadas caminando con saco sobre los hombros, medidas en metros para HYROX.",
            instructions: [
                "Coloca el saco con seguridad sobre los hombros.",
                "Da una zancada larga y lleva la rodilla posterior al suelo.",
                "Extiende cadera y rodilla antes de dar el siguiente paso.",
                "Alterna las piernas y progresa hasta completar la distancia.",
            ],
            primaries: ["quadriceps", "gluteal"],
            secondaries: ["hamstring", "abs"]
        ),
    ]
}
