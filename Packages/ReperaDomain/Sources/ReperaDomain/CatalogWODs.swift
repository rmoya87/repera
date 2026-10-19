import Foundation

/// Plantilla de WOD conocido (benchmarks Girls, Heroes, Opens…).
public struct WODTemplate: Identifiable, Codable, Sendable, Hashable {
    public var id: String
    public var name: String
    public var format: WODFormat
    public var timeCapMinutes: Int?
    public var rounds: Int?
    public var workSeconds: Int?
    public var restSeconds: Int?
    public var emomIntervalSeconds: Int?
    public var movements: [WODMovement]
    public var muscles: [String]
    /// Tiempo medio estimado (minutos) para atletas intermedios.
    public var typicalMinutes: Int?
    /// Bandas principiante → élite (referencia publicada, no ranking social).
    public var scoreBands: WODScoreBands?
    public var notes: String?

    public init(
        id: String,
        name: String,
        format: WODFormat,
        timeCapMinutes: Int? = nil,
        rounds: Int? = nil,
        workSeconds: Int? = nil,
        restSeconds: Int? = nil,
        emomIntervalSeconds: Int? = nil,
        movements: [WODMovement],
        muscles: [String],
        typicalMinutes: Int? = nil,
        scoreBands: WODScoreBands? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.format = format
        self.timeCapMinutes = timeCapMinutes
        self.rounds = rounds
        self.workSeconds = workSeconds
        self.restSeconds = restSeconds
        self.emomIntervalSeconds = emomIntervalSeconds
        self.movements = movements
        self.muscles = muscles
        self.typicalMinutes = typicalMinutes
        self.scoreBands = scoreBands
        self.notes = notes
    }

    public var formatLabel: String { format.displayName }

    public var typicalLabel: String? {
        guard let typicalMinutes else { return nil }
        return "~\(typicalMinutes) min"
    }

    public var musclesLabel: String {
        muscles.joined(separator: " · ")
    }

    /// Bloque de rutina listo para insertar (IDs nuevos).
    public func makeBlock() -> RoutineBlock {
        RoutineBlock(
            title: name,
            kind: .wod,
            movements: movements.map { $0.duplicatingContent() },
            wodFormat: format,
            timeCapMinutes: timeCapMinutes,
            emomIntervalSeconds: emomIntervalSeconds ?? 60,
            rounds: rounds,
            workSeconds: workSeconds,
            restSeconds: restSeconds,
            wodNotes: notes,
            wodTemplateId: id
        )
    }
}

/// Catálogo seed de WODs conocidos (benchmarks CrossFit).
public enum CatalogWODs {
    public static func seed() -> [WODTemplate] {
        all
    }

    public static func template(id: String) -> WODTemplate? {
        all.first { $0.id == id }
    }

    public static func search(_ query: String) -> [WODTemplate] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return all }
        return all.filter {
            $0.name.lowercased().contains(q)
                || $0.format.displayName.lowercased().contains(q)
                || $0.muscles.contains { $0.lowercased().contains(q) }
        }
    }

    private static func m(_ name: String, reps: Int? = nil, meters: Int? = nil, calories: Int? = nil, male: Double? = nil, female: Double? = nil, notes: String? = nil) -> WODMovement {
        WODMovement(
            name: name,
            reps: reps,
            distanceMeters: meters,
            calories: calories,
            weightMaleKg: male,
            weightFemaleKg: female,
            notes: notes
        )
    }

    private static let all: [WODTemplate] = [
        // MARK: Girls
        WODTemplate(
            id: "fran",
            name: "Fran",
            format: .forTime,
            timeCapMinutes: 10,
            movements: [
                m("Thruster", reps: 21, male: 43, female: 29),
                m("Dominadas", reps: 21),
                m("Thruster", reps: 15, male: 43, female: 29),
                m("Dominadas", reps: 15),
                m("Thruster", reps: 9, male: 43, female: 29),
                m("Dominadas", reps: 9),
            ],
            muscles: ["Piernas", "Hombros", "Espalda"],
            typicalMinutes: 5,
            scoreBands: WODScoreBands(
                eliteMaxSeconds: 3 * 60,
                advancedMaxSeconds: 5 * 60,
                intermediateMaxSeconds: 8 * 60,
                beginnerMaxSeconds: 10 * 60
            ),
            notes: "21-15-9 thrusters + pull-ups"
        ),
        WODTemplate(
            id: "cindy",
            name: "Cindy",
            format: .amrap,
            timeCapMinutes: 20,
            movements: [
                m("Dominadas", reps: 5),
                m("Flexiones", reps: 10),
                m("Air squat", reps: 15),
            ],
            muscles: ["Espalda", "Pecho", "Piernas"],
            typicalMinutes: 20,
            scoreBands: WODScoreBands(
                eliteMinRounds: 20,
                advancedMinRounds: 15,
                intermediateMinRounds: 10,
                beginnerMinRounds: 6
            ),
            notes: "AMRAP 20'"
        ),
        WODTemplate(
            id: "helen",
            name: "Helen",
            format: .forTime,
            timeCapMinutes: 15,
            rounds: 3,
            movements: [
                m("Cinta / carrera", meters: 400),
                m("Swing kettlebell", reps: 21, male: 24, female: 16),
                m("Dominadas", reps: 12),
            ],
            muscles: ["Cardio", "Core", "Espalda"],
            typicalMinutes: 10,
            scoreBands: WODScoreBands(
                eliteMaxSeconds: 8 * 60,
                advancedMaxSeconds: 10 * 60,
                intermediateMaxSeconds: 13 * 60,
                beginnerMaxSeconds: 15 * 60
            ),
            notes: "3 RFT"
        ),
        WODTemplate(
            id: "grace",
            name: "Grace",
            format: .forTime,
            timeCapMinutes: 10,
            movements: [
                m("Cargada y envión", reps: 30, male: 61, female: 43),
            ],
            muscles: ["Piernas", "Hombros", "Espalda"],
            typicalMinutes: 3,
            scoreBands: WODScoreBands(
                eliteMaxSeconds: 90,
                advancedMaxSeconds: 3 * 60,
                intermediateMaxSeconds: 5 * 60,
                beginnerMaxSeconds: 10 * 60
            ),
            notes: "30 clean & jerk"
        ),
        WODTemplate(
            id: "isabel",
            name: "Isabel",
            format: .forTime,
            timeCapMinutes: 10,
            movements: [
                m("Arrancada", reps: 30, male: 61, female: 43),
            ],
            muscles: ["Piernas", "Hombros", "Espalda"],
            typicalMinutes: 3,
            scoreBands: WODScoreBands(
                eliteMaxSeconds: 90,
                advancedMaxSeconds: 3 * 60,
                intermediateMaxSeconds: 5 * 60,
                beginnerMaxSeconds: 10 * 60
            ),
            notes: "30 snatches"
        ),
        WODTemplate(
            id: "annie",
            name: "Annie",
            format: .forTime,
            timeCapMinutes: 12,
            movements: [
                m("Dobles de comba", reps: 50),
                m("Sit-up", reps: 50),
                m("Dobles de comba", reps: 40),
                m("Sit-up", reps: 40),
                m("Dobles de comba", reps: 30),
                m("Sit-up", reps: 30),
                m("Dobles de comba", reps: 20),
                m("Sit-up", reps: 20),
                m("Dobles de comba", reps: 10),
                m("Sit-up", reps: 10),
            ],
            muscles: ["Cardio", "Core"],
            typicalMinutes: 8,
            scoreBands: WODScoreBands(
                eliteMaxSeconds: 5 * 60,
                advancedMaxSeconds: 7 * 60,
                intermediateMaxSeconds: 10 * 60,
                beginnerMaxSeconds: 12 * 60
            ),
            notes: "50-40-30-20-10 DU + sit-ups"
        ),
        WODTemplate(
            id: "karen",
            name: "Karen",
            format: .forTime,
            timeCapMinutes: 15,
            movements: [
                m("Wall ball", reps: 150, male: 9, female: 6),
            ],
            muscles: ["Piernas", "Hombros", "Core"],
            typicalMinutes: 8,
            scoreBands: WODScoreBands(
                eliteMaxSeconds: 5 * 60,
                advancedMaxSeconds: 7 * 60,
                intermediateMaxSeconds: 10 * 60,
                beginnerMaxSeconds: 15 * 60
            ),
            notes: "150 wall balls"
        ),
        WODTemplate(
            id: "diane",
            name: "Diane",
            format: .forTime,
            timeCapMinutes: 12,
            movements: [
                m("Peso muerto", reps: 21, male: 102, female: 70),
                m("HSPU", reps: 21),
                m("Peso muerto", reps: 15, male: 102, female: 70),
                m("HSPU", reps: 15),
                m("Peso muerto", reps: 9, male: 102, female: 70),
                m("HSPU", reps: 9),
            ],
            muscles: ["Espalda", "Hombros", "Core"],
            typicalMinutes: 6,
            scoreBands: WODScoreBands(
                eliteMaxSeconds: 4 * 60,
                advancedMaxSeconds: 6 * 60,
                intermediateMaxSeconds: 9 * 60,
                beginnerMaxSeconds: 12 * 60
            ),
            notes: "21-15-9 deadlift + HSPU"
        ),
        WODTemplate(
            id: "chelsea",
            name: "Chelsea",
            format: .emom,
            timeCapMinutes: 30,
            emomIntervalSeconds: 60,
            movements: [
                m("Dominadas", reps: 5),
                m("Flexiones", reps: 10),
                m("Air squat", reps: 15),
            ],
            muscles: ["Espalda", "Pecho", "Piernas"],
            typicalMinutes: 30,
            notes: "EMOM 30' · 5/10/15"
        ),
        WODTemplate(
            id: "barbara",
            name: "Barbara",
            format: .forTime,
            timeCapMinutes: 40,
            rounds: 5,
            movements: [
                m("Dominadas", reps: 20),
                m("Flexiones", reps: 30),
                m("Sit-up", reps: 40),
                m("Air squat", reps: 50),
            ],
            muscles: ["Espalda", "Pecho", "Core", "Piernas"],
            typicalMinutes: 30,
            notes: "5 rounds · 3' rest entre rondas"
        ),
        WODTemplate(
            id: "angie",
            name: "Angie",
            format: .forTime,
            timeCapMinutes: 30,
            movements: [
                m("Dominadas", reps: 100),
                m("Flexiones", reps: 100),
                m("Sit-up", reps: 100),
                m("Air squat", reps: 100),
            ],
            muscles: ["Espalda", "Pecho", "Core", "Piernas"],
            typicalMinutes: 20,
            notes: "100 de cada"
        ),
        WODTemplate(
            id: "nancy",
            name: "Nancy",
            format: .forTime,
            timeCapMinutes: 20,
            rounds: 5,
            movements: [
                m("Cinta / carrera", meters: 400),
                m("Overhead squat", reps: 15, male: 43, female: 29),
            ],
            muscles: ["Cardio", "Piernas", "Hombros"],
            typicalMinutes: 14,
            notes: "5 RFT"
        ),
        WODTemplate(
            id: "jackie",
            name: "Jackie",
            format: .forTime,
            timeCapMinutes: 15,
            movements: [
                m("Remo", meters: 1000),
                m("Thruster", reps: 50, male: 20, female: 15),
                m("Dominadas", reps: 30),
            ],
            muscles: ["Cardio", "Piernas", "Espalda"],
            typicalMinutes: 10,
            notes: "1000m row + 50 thrusters + 30 pull-ups"
        ),
        WODTemplate(
            id: "linda",
            name: "Linda",
            format: .forTime,
            timeCapMinutes: 30,
            movements: [
                m("Peso muerto", reps: 10, male: nil, female: nil, notes: "1.5× BW"),
                m("Press banca", reps: 10, notes: "BW"),
                m("Cargada", reps: 10, notes: "0.75× BW"),
                m("Peso muerto", reps: 9, notes: "1.5× BW"),
                m("Press banca", reps: 9, notes: "BW"),
                m("Cargada", reps: 9, notes: "0.75× BW"),
            ],
            muscles: ["Espalda", "Pecho", "Piernas"],
            typicalMinutes: 20,
            notes: "10-9-…-1 DL / bench / clean"
        ),
        WODTemplate(
            id: "mary",
            name: "Mary",
            format: .amrap,
            timeCapMinutes: 20,
            movements: [
                m("HSPU", reps: 5),
                m("Pistol squat", reps: 10),
                m("Dominadas", reps: 15),
            ],
            muscles: ["Hombros", "Piernas", "Espalda"],
            typicalMinutes: 20
        ),
        WODTemplate(
            id: "amanda",
            name: "Amanda",
            format: .forTime,
            timeCapMinutes: 12,
            movements: [
                m("Muscle-up anillas", reps: 9),
                m("Arrancada", reps: 9, male: 61, female: 43),
                m("Muscle-up anillas", reps: 7),
                m("Arrancada", reps: 7, male: 61, female: 43),
                m("Muscle-up anillas", reps: 5),
                m("Arrancada", reps: 5, male: 61, female: 43),
            ],
            muscles: ["Espalda", "Hombros", "Piernas"],
            typicalMinutes: 7,
            notes: "9-7-5 muscle-up + snatch"
        ),
        WODTemplate(
            id: "kelly",
            name: "Kelly",
            format: .forTime,
            timeCapMinutes: 30,
            rounds: 5,
            movements: [
                m("Cinta / carrera", meters: 400),
                m("Salto al cajón", reps: 30),
                m("Wall ball", reps: 30, male: 9, female: 6),
            ],
            muscles: ["Cardio", "Piernas", "Hombros"],
            typicalMinutes: 22,
            notes: "5 RFT"
        ),
        WODTemplate(
            id: "elizabeth",
            name: "Elizabeth",
            format: .forTime,
            timeCapMinutes: 12,
            movements: [
                m("Cargada", reps: 21, male: 61, female: 43),
                m("Fondos en anillas", reps: 21),
                m("Cargada", reps: 15, male: 61, female: 43),
                m("Fondos en anillas", reps: 15),
                m("Cargada", reps: 9, male: 61, female: 43),
                m("Fondos en anillas", reps: 9),
            ],
            muscles: ["Piernas", "Pecho", "Tríceps"],
            typicalMinutes: 7,
            notes: "21-15-9 clean + ring dips"
        ),

        // MARK: Heroes / classics
        WODTemplate(
            id: "murph",
            name: "Murph",
            format: .forTime,
            timeCapMinutes: 60,
            movements: [
                m("Cinta / carrera", meters: 1600),
                m("Dominadas", reps: 100),
                m("Flexiones", reps: 200),
                m("Air squat", reps: 300),
                m("Cinta / carrera", meters: 1600),
            ],
            muscles: ["Cardio", "Espalda", "Pecho", "Piernas"],
            typicalMinutes: 45,
            scoreBands: WODScoreBands(
                eliteMaxSeconds: 35 * 60,
                advancedMaxSeconds: 45 * 60,
                intermediateMaxSeconds: 55 * 60,
                beginnerMaxSeconds: 60 * 60
            ),
            notes: "Chaleco 9/6 kg opcional · partición 20 rondas 5/10/15"
        ),
        WODTemplate(
            id: "dt",
            name: "DT",
            format: .forTime,
            timeCapMinutes: 15,
            rounds: 5,
            movements: [
                m("Peso muerto", reps: 12, male: 70, female: 48),
                m("Hang power clean", reps: 9, male: 70, female: 48),
                m("Push jerk", reps: 6, male: 70, female: 48),
            ],
            muscles: ["Espalda", "Piernas", "Hombros"],
            typicalMinutes: 8,
            scoreBands: WODScoreBands(
                eliteMaxSeconds: 5 * 60,
                advancedMaxSeconds: 7 * 60,
                intermediateMaxSeconds: 10 * 60,
                beginnerMaxSeconds: 15 * 60
            ),
            notes: "5 RFT · 155/105 lb"
        ),
        WODTemplate(
            id: "fight-gone-bad",
            name: "Fight Gone Bad",
            format: .amrap,
            timeCapMinutes: 17,
            rounds: 3,
            movements: [
                m("Wall ball", reps: nil, male: 9, female: 6, notes: "1' max"),
                m("Sumo deadlift high pull", reps: nil, male: 34, female: 25, notes: "1' max"),
                m("Salto al cajón", reps: nil, notes: "1' max"),
                m("Push press", reps: nil, male: 34, female: 25, notes: "1' max"),
                m("Remo", calories: nil, notes: "1' max cal"),
            ],
            muscles: ["Full body", "Cardio"],
            typicalMinutes: 17,
            notes: "3 rondas · 1' por estación + 1' rest · score = total reps"
        ),
        WODTemplate(
            id: "randy",
            name: "Randy",
            format: .forTime,
            timeCapMinutes: 10,
            movements: [
                m("Arrancada de potencia", reps: 75, male: 34, female: 25),
            ],
            muscles: ["Piernas", "Hombros", "Espalda"],
            typicalMinutes: 5,
            notes: "75 power snatches"
        ),
        WODTemplate(
            id: "nate",
            name: "Nate",
            format: .amrap,
            timeCapMinutes: 20,
            movements: [
                m("Muscle-up anillas", reps: 2),
                m("HSPU", reps: 4),
                m("Swing kettlebell", reps: 8, male: 32, female: 24),
            ],
            muscles: ["Espalda", "Hombros", "Core"],
            typicalMinutes: 20
        ),
        WODTemplate(
            id: "tommy-v",
            name: "Tommy V",
            format: .forTime,
            timeCapMinutes: 25,
            movements: [
                m("Thruster", reps: 21, male: 52, female: 34),
                m("Toes to bar", reps: 12),
                m("Thruster", reps: 15, male: 52, female: 34),
                m("Toes to bar", reps: 9),
                m("Thruster", reps: 9, male: 52, female: 34),
                m("Toes to bar", reps: 6),
            ],
            muscles: ["Piernas", "Hombros", "Core"],
            typicalMinutes: 12
        ),

        // MARK: Popular / Open-style
        WODTemplate(
            id: "open-12-3",
            name: "Open 12.3",
            format: .amrap,
            timeCapMinutes: 18,
            movements: [
                m("Salto al cajón", reps: 15),
                m("Push press", reps: 12, male: 52, female: 34),
                m("Toes to bar", reps: 9),
            ],
            muscles: ["Piernas", "Hombros", "Core"],
            typicalMinutes: 18
        ),
        WODTemplate(
            id: "open-13-4",
            name: "Open 13.4",
            format: .amrap,
            timeCapMinutes: 7,
            movements: [
                m("Cargada", reps: 3, male: 102, female: 70),
                m("Toes to bar", reps: 3),
            ],
            muscles: ["Espalda", "Core", "Piernas"],
            typicalMinutes: 7,
            notes: "Escalera +3 cada ronda"
        ),
        WODTemplate(
            id: "open-14-5",
            name: "Open 14.5",
            format: .forTime,
            timeCapMinutes: 20,
            movements: [
                m("Thruster", reps: 21, male: 43, female: 29),
                m("Bar facing burpee", reps: 21),
                m("Thruster", reps: 18, male: 43, female: 29),
                m("Bar facing burpee", reps: 18),
                m("Thruster", reps: 15, male: 43, female: 29),
                m("Bar facing burpee", reps: 15),
                m("Thruster", reps: 12, male: 43, female: 29),
                m("Bar facing burpee", reps: 12),
                m("Thruster", reps: 9, male: 43, female: 29),
                m("Bar facing burpee", reps: 9),
                m("Thruster", reps: 6, male: 43, female: 29),
                m("Bar facing burpee", reps: 6),
                m("Thruster", reps: 3, male: 43, female: 29),
                m("Bar facing burpee", reps: 3),
            ],
            muscles: ["Piernas", "Hombros", "Cardio"],
            typicalMinutes: 12,
            notes: "21-18-15-12-9-6-3"
        ),
        WODTemplate(
            id: "chipper-classic",
            name: "Chipper clásico",
            format: .chipper,
            timeCapMinutes: 25,
            movements: [
                m("Cinta / carrera", meters: 800),
                m("Thruster", reps: 40, male: 43, female: 29),
                m("Dominadas", reps: 30),
                m("Sit-up", reps: 50),
                m("Dobles de comba", reps: 100),
            ],
            muscles: ["Full body", "Cardio"],
            typicalMinutes: 18
        ),
        WODTemplate(
            id: "tabata-something",
            name: "Tabata Something Else",
            format: .tabata,
            timeCapMinutes: 16,
            rounds: 8,
            workSeconds: 20,
            restSeconds: 10,
            movements: [
                m("Dominadas", notes: "4' Tabata"),
                m("Flexiones", notes: "4' Tabata"),
                m("Sit-up", notes: "4' Tabata"),
                m("Air squat", notes: "4' Tabata"),
            ],
            muscles: ["Espalda", "Pecho", "Core", "Piernas"],
            typicalMinutes: 16,
            notes: "Score = peor ronda de cada movimiento, sumadas"
        ),
        WODTemplate(
            id: "death-by-burpees",
            name: "Death by Burpees",
            format: .deathBy,
            timeCapMinutes: 20,
            movements: [
                m("Burpee", reps: 1, notes: "Min 1: 1 · Min 2: 2 · …"),
            ],
            muscles: ["Cardio", "Pecho", "Piernas"],
            typicalMinutes: 12,
            notes: "Hasta fallar el minuto"
        ),
        WODTemplate(
            id: "21-15-9-thruster-bjo",
            name: "21-15-9 Thruster + BJO",
            format: .ladder,
            timeCapMinutes: 12,
            movements: [
                m("Thruster", reps: 21, male: 43, female: 29),
                m("Box jump over", reps: 21),
                m("Thruster", reps: 15, male: 43, female: 29),
                m("Box jump over", reps: 15),
                m("Thruster", reps: 9, male: 43, female: 29),
                m("Box jump over", reps: 9),
            ],
            muscles: ["Piernas", "Hombros", "Cardio"],
            typicalMinutes: 7
        ),
    ]
}
