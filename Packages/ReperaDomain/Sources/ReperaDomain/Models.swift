import Foundation

public enum WeightUnit: String, Codable, Sendable, CaseIterable {
    case kg
    case lb
}

public enum WeekStart: String, Codable, Sendable, CaseIterable {
    case monday
    case sunday
}

public struct AppSettings: Codable, Sendable, Equatable {
    public var weightUnit: WeightUnit
    public var weekStartsOn: WeekStart
    public var defaultRestSeconds: Int
    public var bodyWeightGoalKg: Double?
    /// Objetivos optativos. nil = sin fijar (no se inventan progresos).
    public var dailyStepsGoal: Int?
    public var dailyActiveEnergyGoalKcal: Int?
    public var dailyAverageHeartRateGoalBpm: Int?
    public var dailyWorkoutMinutesGoal: Int?
    public var weeklyWorkoutGoal: Int?
    public var defaultProgression: ProgressionPolicy
    public var weightIncrementKg: Double
    public var barbellKg: Double
    public var ownedPlatesKg: [Double]
    public var effortUnit: EffortUnit
    public var scheduleMode: ScheduleMode
    public var restSoundEnabled: Bool
    public var restHapticEnabled: Bool
    /// JPEG del avatar (se sincroniza con iCloud junto al resto del estado).
    public var profileAvatarJPEG: Data?
    public var profileDisplayName: String?

    /// IDs de `CatalogWODs` marcados como favoritos.
    public var favoriteWODTemplateIds: [String]

    public init(
        weightUnit: WeightUnit = .kg,
        weekStartsOn: WeekStart = .monday,
        defaultRestSeconds: Int = 90,
        bodyWeightGoalKg: Double? = nil,
        dailyStepsGoal: Int? = nil,
        dailyActiveEnergyGoalKcal: Int? = nil,
        dailyAverageHeartRateGoalBpm: Int? = nil,
        dailyWorkoutMinutesGoal: Int? = nil,
        weeklyWorkoutGoal: Int? = nil,
        defaultProgression: ProgressionPolicy = .linear,
        weightIncrementKg: Double = 2.5,
        barbellKg: Double = PlateMath.defaultBarKg,
        ownedPlatesKg: [Double] = PlateMath.defaultPlatesKg,
        effortUnit: EffortUnit = .rir,
        scheduleMode: ScheduleMode = .fixedWeek,
        restSoundEnabled: Bool = true,
        restHapticEnabled: Bool = true,
        profileAvatarJPEG: Data? = nil,
        profileDisplayName: String? = nil,
        favoriteWODTemplateIds: [String] = []
    ) {
        self.weightUnit = weightUnit
        self.weekStartsOn = weekStartsOn
        self.defaultRestSeconds = defaultRestSeconds
        self.bodyWeightGoalKg = bodyWeightGoalKg
        self.dailyStepsGoal = dailyStepsGoal
        self.dailyActiveEnergyGoalKcal = dailyActiveEnergyGoalKcal
        self.dailyAverageHeartRateGoalBpm = dailyAverageHeartRateGoalBpm
        self.dailyWorkoutMinutesGoal = dailyWorkoutMinutesGoal
        self.weeklyWorkoutGoal = weeklyWorkoutGoal
        self.defaultProgression = defaultProgression
        self.weightIncrementKg = weightIncrementKg
        self.barbellKg = barbellKg
        self.ownedPlatesKg = ownedPlatesKg
        self.effortUnit = effortUnit
        self.scheduleMode = scheduleMode
        self.restSoundEnabled = restSoundEnabled
        self.restHapticEnabled = restHapticEnabled
        self.profileAvatarJPEG = profileAvatarJPEG
        self.profileDisplayName = profileDisplayName
        self.favoriteWODTemplateIds = favoriteWODTemplateIds
    }

    enum CodingKeys: String, CodingKey {
        case weightUnit, weekStartsOn, defaultRestSeconds, bodyWeightGoalKg
        case dailyStepsGoal, dailyActiveEnergyGoalKcal, dailyAverageHeartRateGoalBpm, dailyWorkoutMinutesGoal, weeklyWorkoutGoal
        case defaultProgression, weightIncrementKg, barbellKg, ownedPlatesKg, effortUnit
        case scheduleMode, restSoundEnabled, restHapticEnabled
        case profileAvatarJPEG, profileDisplayName, favoriteWODTemplateIds
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        weightUnit = try c.decodeIfPresent(WeightUnit.self, forKey: .weightUnit) ?? .kg
        weekStartsOn = try c.decodeIfPresent(WeekStart.self, forKey: .weekStartsOn) ?? .monday
        defaultRestSeconds = try c.decodeIfPresent(Int.self, forKey: .defaultRestSeconds) ?? 90
        bodyWeightGoalKg = try c.decodeIfPresent(Double.self, forKey: .bodyWeightGoalKg)
        dailyStepsGoal = try c.decodeIfPresent(Int.self, forKey: .dailyStepsGoal)
        dailyActiveEnergyGoalKcal = try c.decodeIfPresent(Int.self, forKey: .dailyActiveEnergyGoalKcal)
        dailyAverageHeartRateGoalBpm = try c.decodeIfPresent(Int.self, forKey: .dailyAverageHeartRateGoalBpm)
        dailyWorkoutMinutesGoal = try c.decodeIfPresent(Int.self, forKey: .dailyWorkoutMinutesGoal)
        weeklyWorkoutGoal = try c.decodeIfPresent(Int.self, forKey: .weeklyWorkoutGoal)
        defaultProgression = try c.decodeIfPresent(ProgressionPolicy.self, forKey: .defaultProgression) ?? .linear
        weightIncrementKg = try c.decodeIfPresent(Double.self, forKey: .weightIncrementKg) ?? 2.5
        barbellKg = try c.decodeIfPresent(Double.self, forKey: .barbellKg) ?? PlateMath.defaultBarKg
        ownedPlatesKg = try c.decodeIfPresent([Double].self, forKey: .ownedPlatesKg) ?? PlateMath.defaultPlatesKg
        effortUnit = try c.decodeIfPresent(EffortUnit.self, forKey: .effortUnit) ?? .rir
        scheduleMode = try c.decodeIfPresent(ScheduleMode.self, forKey: .scheduleMode) ?? .fixedWeek
        restSoundEnabled = try c.decodeIfPresent(Bool.self, forKey: .restSoundEnabled) ?? true
        restHapticEnabled = try c.decodeIfPresent(Bool.self, forKey: .restHapticEnabled) ?? true
        profileAvatarJPEG = try c.decodeIfPresent(Data.self, forKey: .profileAvatarJPEG)
        profileDisplayName = try c.decodeIfPresent(String.self, forKey: .profileDisplayName)
        favoriteWODTemplateIds = try c.decodeIfPresent([String].self, forKey: .favoriteWODTemplateIds) ?? []
    }
}

/// Cómo se apuntan series de un ejercicio (UI de peso / tiempo / reps).
/// Unidad de la cantidad apuntada (reps genéricas, calorías de máquina o metros).
public enum ExerciseQuantityUnit: String, Codable, Sendable, Hashable {
    case reps
    case calories
    case meters

    public var shortLabel: String {
        switch self {
        case .reps: return "Reps"
        case .calories: return "Cal"
        case .meters: return "m"
        }
    }
}

/// Campo de carga opcional: lastre (kg) o déficit HSPU (cm).
public enum ExerciseLoadField: String, Codable, Sendable, Hashable {
    case none
    case weightKg
    case deficitCm

    public var stepperTitle: String {
        switch self {
        case .none: return ""
        case .weightKg: return "Peso (kg)"
        case .deficitCm: return "Déficit (cm)"
        }
    }

    public var shortUnit: String {
        switch self {
        case .none: return ""
        case .weightKg: return "kg"
        case .deficitCm: return "cm"
        }
    }
}

public enum ExerciseLoggingStyle: String, Codable, Sendable, Hashable {
    /// Barra, mancuernas, KB con carga: kg + reps. También dominadas con lastre / HSPU con déficit.
    case loadAndReps
    /// Gimnasia / peso corporal: solo reps (sin kg).
    case repsOnly
    /// Comba: veces (dobles) + tiempo de la serie.
    case repsAndTime
    /// Erg / bike / carrera: tiempo + cal o metros (sin kg).
    case machineWork

    public var usesDuration: Bool {
        switch self {
        case .repsAndTime, .machineWork: return true
        case .loadAndReps, .repsOnly: return false
        }
    }

    public var usesLoad: Bool { self == .loadAndReps }

    public var usesRIR: Bool {
        switch self {
        case .loadAndReps, .repsOnly: return true
        case .repsAndTime, .machineWork: return false
        }
    }

    /// Techo del stepper de cantidad (reps / cal / m).
    public var quantityCap: Int {
        switch self {
        case .machineWork: return 100_000
        case .repsAndTime: return 999
        case .repsOnly: return 99
        case .loadAndReps: return 50
        }
    }
}

/// Compatibilidades por movimiento, no por equipamiento: un snatch con barra
/// no se convierte en snatch con mancuerna, y cada ejercicio mantiene su historial.
/// Listas cerradas para no etiquetar como CrossFit toda la musculación de máquinas.
private enum ExerciseDisciplineRules {
    static func normalized(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive],
                     locale: Locale(identifier: "es_ES"))
            .lowercased()
    }

    static let crossFitGeneral: Set<String> = [
        // Básicos de fuerza y acondicionamiento habituales en un box.
        "press banca", "press banca inclinada", "press militar", "remo con barra",
        "peso muerto", "peso muerto rumano", "peso muerto sumo",
        "sentadilla", "sentadilla frontal", "zancadas", "plancha",
        "fondos", "dominadas", "remo invertido", "ab wheel",
        "farmer walk", "remo maquina", "bici estatica",
        "paso lateral con banda"
    ]

    static let crossFitGymnastics: Set<String> = [
        // Peso corporal usado como movimiento gimnástico en un WOD.
        "burpee", "burpee box jump over", "burpee box jump",
        "burpee al cajon", "burpee pull-up", "bar facing burpee",
        "box jump", "salto al cajon", "box jump over",
        "box step-up", "step-up al cajon", "broad jump", "bear crawl",
        "walking lunge", "fondos", "dominadas", "remo invertido",
        "plancha", "ab wheel"
    ]

    static let hyroxAlsoCrossFit: Set<String> = [
        "burpee broad jump", "sandbag lunges"
    ]

    static let cardioNames: Set<String> = [
        "run", "carrera", "cinta / carrera", "running", "shuttle run",
        "ski erg", "skierg", "rowerg", "remo maquina", "remoergometro",
        "air bike", "echo bike", "bici estatica",
        "double-under", "single-under", "triple-under",
        "dobles de comba", "simples de comba", "triples de comba"
    ]
}

public struct Exercise: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var name: String
    public var muscleGroup: String
    public var equipment: String?
    public var isCustom: Bool
    /// Id openGym / ExerciseDB (texto; sin media licenciada).
    public var catalogId: String?
    public var targetMuscle: String?
    public var secondaryMuscles: [String]
    public var bodyPart: String?
    public var detailDescription: String?
    public var instructions: [String]
    public var primaryRegions: [String]
    public var secondaryRegions: [String]
    public var isFavorite: Bool
    /// Origen deportivo o disciplina (incluye Movilidad); no sustituye el grupo muscular.
    public var sportTag: String?

    public var isMobility: Bool { sportTag == "Movilidad" }

    /// Las posturas se miden por tiempo sostenido; los movimientos dinámicos, por repeticiones y tiempo.
    public var isMobilityHold: Bool {
        guard isMobility else { return false }
        let identifier = catalogId ?? ""
        let holdIds: Set<String> = [
            "mobility-14", "mobility-15", "mobility-16", "mobility-20", "mobility-21",
            "mobility-30", "mobility-31", "mobility-32", "mobility-36", "mobility-38",
            "mobility-39", "mobility-40", "mobility-41", "mobility-42", "mobility-44",
            "mobility-46", "mobility-60", "mobility-61", "mobility-62",             "mobility-67", "mobility-70", "mobility-80"
        ]
        return holdIds.contains(identifier)
    }

    /// Una misma variante pertenece a varias disciplinas, sin duplicar su UUID
    /// ni su historial. `sportTag` sigue siendo el origen guardado en disco/cloud.
    public var disciplineTags: [String] {
        var tags: [String] = []
        func include(_ tag: String) {
            if !tags.contains(tag) { tags.append(tag) }
        }
        if let sportTag, !sportTag.isEmpty { include(sportTag) }

        let normalized = ExerciseDisciplineRules.normalized(name)
        if sportTag == "Halterofilia" || sportTag == "Gimnasia"
            || ExerciseDisciplineRules.crossFitGeneral.contains(normalized)
            || (sportTag == "HYROX" && ExerciseDisciplineRules.hyroxAlsoCrossFit.contains(normalized)) {
            include("CrossFit")
        }
        if sportTag == "Gimnasia" || ExerciseDisciplineRules.crossFitGymnastics.contains(normalized) {
            include("Gimnasia")
        }
        if HyroxExercises.isMovement(named: name) { include("HYROX") }
        if muscleGroup == "Cardio" || ExerciseDisciplineRules.cardioNames.contains(normalized) {
            include("Cardio")
        }
        return tags
    }

    /// Métrica de log según equipo / nombre (comba → veces+tiempo; erg → cal/m; PC → solo reps).
    public var loggingStyle: ExerciseLoggingStyle {
        if isMobility { return .repsAndTime }
        return Self.loggingStyle(name: name, equipment: equipment, targetMuscle: targetMuscle, muscleGroup: muscleGroup)
    }

    /// Lastre (kg), déficit HSPU (cm) o ninguno.
    public var loadField: ExerciseLoadField {
        if isMobility { return .none }
        return Self.loadField(name: name, equipment: equipment, targetMuscle: targetMuscle, muscleGroup: muscleGroup)
    }

    /// Etiqueta de cantidad: «Veces» (comba), Cal/m (máquina) o Reps.
    public var quantityFieldLabel: String {
        if isMobility { return isMobilityHold ? "Postura" : "Reps" }
        return Self.quantityFieldLabel(name: name, equipment: equipment, style: loggingStyle, unit: defaultQuantityUnit)
    }

    /// Unidad por defecto al apuntar (bike/Ski → cal; remoerg/carrera → m).
    public var defaultQuantityUnit: ExerciseQuantityUnit {
        Self.defaultQuantityUnit(name: name, equipment: equipment)
    }

    /// Bike / Ski / remoerg permiten cambiar Cal ↔ m; carrera suele ser solo metros.
    public var allowsCalorieOrDistanceToggle: Bool {
        Self.allowsCalorieOrDistanceToggle(name: name, equipment: equipment)
    }

    public static func loggingStyle(
        name: String,
        equipment: String?,
        targetMuscle: String? = nil,
        muscleGroup: String? = nil
    ) -> ExerciseLoggingStyle {
        let n = normalizeExerciseToken(name)
        let eq = normalizeExerciseToken(equipment ?? "")
        let target = (targetMuscle ?? "").lowercased()
        let group = (muscleGroup ?? "").lowercased()

        if isJumpRope(name: n, equipment: eq) {
            return .repsAndTime
        }

        if isMachineCardio(name: n, equipment: eq) {
            return .machineWork
        }

        // Un burpee con obstáculo o dominada final no se anota como levantamiento.
        if n.contains("burpee") { return .repsOnly }
        // La resistencia de una banda no es una carga expresada en kilogramos.
        if (eq.contains("banda") || eq.contains("goma"))
            && !eq.contains("mancuerna") && !eq.contains("barra") { return .repsOnly }

        // Dominadas / muscle-up / HSPU permiten anotar lastre o déficit.
        if isPullOrMuscleUp(name: n) || isHSPU(name: n) {
            return .loadAndReps
        }

        // Cajón, anillas, barra fija, pared, GHD… son aparatos de apoyo, no
        // carga externa en kg. Un montaje compuesto con KB, DB o barra sí carga.
        let externalLoad = ["kettlebell", "mancuerna", "dumbbell", "barbell", "barra,", "disco",
                            "saco", "lastre", "trineo", "yoke", "polea"].contains { eq.contains($0) }
        let support = ["cajon", "step", "anillas", "barra de dominadas", "barra fija",
                       "cuerda de trepa", "pegboard", "paralelas", "pared", "banco",
                       "rueda abdominal", "ghd", "plataforma elevada"].contains { eq.contains($0) }
        if support && !externalLoad { return .repsOnly }

        if eq.contains("peso corporal")
            || eq.isEmpty && (target.contains("cardiovascular") || group == "cardio") {
            return .repsOnly
        }

        // Nombres típicos sin equipo en ficha custom.
        if n.contains("toes to") || n.contains("burpee") || n.contains("box jump")
            || n.contains("salto al caj") || n.contains("sit-up") || n.contains("air squat")
            || n.contains("pistol") || n.contains("hollow") || n.contains("l-sit")
            || (n.contains("handstand") && !isHSPU(name: n)) {
            return .repsOnly
        }

        return .loadAndReps
    }

    public static func loadField(
        name: String,
        equipment: String? = nil,
        targetMuscle: String? = nil,
        muscleGroup: String? = nil
    ) -> ExerciseLoadField {
        let n = normalizeExerciseToken(name)
        let style = loggingStyle(
            name: name,
            equipment: equipment,
            targetMuscle: targetMuscle,
            muscleGroup: muscleGroup
        )
        guard style == .loadAndReps else { return .none }
        if isHSPU(name: n) { return .deficitCm }
        return .weightKg
    }

    public static func quantityFieldLabel(
        name: String,
        equipment: String? = nil,
        style: ExerciseLoggingStyle? = nil,
        unit: ExerciseQuantityUnit? = nil
    ) -> String {
        let resolved = style ?? loggingStyle(name: name, equipment: equipment)
        switch resolved {
        case .repsAndTime:
            return "Veces"
        case .machineWork:
            return (unit ?? defaultQuantityUnit(name: name, equipment: equipment)).shortLabel
        case .loadAndReps, .repsOnly:
            return (unit ?? defaultQuantityUnit(name: name, equipment: equipment)).shortLabel
        }
    }

    public static func loadStepperTitle(
        name: String,
        equipment: String? = nil,
        targetMuscle: String? = nil,
        muscleGroup: String? = nil
    ) -> String {
        let n = normalizeExerciseToken(name)
        switch loadField(name: name, equipment: equipment, targetMuscle: targetMuscle, muscleGroup: muscleGroup) {
        case .none: return ""
        case .deficitCm: return "Déficit (cm)"
        case .weightKg:
            return isPullOrMuscleUp(name: n) ? "Lastre (kg)" : "Peso (kg)"
        }
    }

    public static func defaultQuantityUnit(name: String, equipment: String? = nil) -> ExerciseQuantityUnit {
        let n = normalizeExerciseToken(name)
        let eq = normalizeExerciseToken(equipment ?? "")
        guard isMachineCardio(name: n, equipment: eq) || isHyroxDistance(name: n) else { return .reps }
        // Carrera / shuttle, trineo y transportes HYROX se miden en metros.
        if isRunLike(name: n) || isHyroxDistance(name: n) || isSled(name: n, equipment: eq) { return .meters }
        if isErgRow(name: n) { return .meters }
        if isBikeOrSki(name: n) { return .calories }
        return .calories
    }

    public static func allowsCalorieOrDistanceToggle(name: String, equipment: String? = nil) -> Bool {
        let n = normalizeExerciseToken(name)
        let eq = normalizeExerciseToken(equipment ?? "")
        guard isMachineCardio(name: n, equipment: eq) else { return false }
        // Carrera casi siempre es distancia; bike/ski/remoerg admiten cal o m en WODs.
        return !isRunLike(name: n)
    }

    private static func normalizeExerciseToken(_ raw: String) -> String {
        raw.lowercased()
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "en_US_POSIX"))
    }

    private static func isJumpRope(name n: String, equipment eq: String) -> Bool {
        eq.contains("comba")
            || (n.contains("doble") && n.contains("comba"))
            || (n.contains("simple") && n.contains("comba"))
            || (n.contains("triple") && n.contains("comba"))
            || n.contains("double under") || n.contains("double-under")
            || n.contains("single under") || n.contains("single-under")
            || n.contains("triple under") || n.contains("triple-under")
            || n.hasPrefix("du ") || n == "du" || n.hasPrefix("su ")
    }

    private static func isPullOrMuscleUp(name n: String) -> Bool {
        n.contains("dominad") || n.contains("pull-up") || n.contains("pull up")
            || n.contains("pullup") || n.contains("chin-up") || n.contains("chin up")
            || n.contains("muscle-up") || n.contains("muscle up") || n.contains("muscleup")
            || n == "mu" || n.hasPrefix("mu ")
    }

    private static func isHSPU(name n: String) -> Bool {
        n.contains("hspu")
            || (n.contains("handstand") && (n.contains("push") || n.contains("press") || n.contains("fond")))
            || n.contains("pino flex") || n.contains("fondos en pino")
    }

    /// Air bike, Echo, SkiErg, remoergómetro, cinta — no remos de fuerza (barra/DB/polea…).
    private static func isHyroxDistance(name n: String) -> Bool {
        n.contains("burpee broad jump") || n.contains("sandbag lunge")
            || n.contains("zancadas con saco") || n == "farmer carry"
            || n == "farmer walk" || n.contains("paseo del granjero")
    }

    private static func isSled(name n: String, equipment eq: String) -> Bool {
        eq.contains("trineo") && (n.contains("sled") || n.contains("trineo"))
    }

    private static func isMachineCardio(name n: String, equipment eq: String) -> Bool {
        if isBikeOrSki(name: n) { return true }
        if isErgRow(name: n) { return true }
        if isRunLike(name: n) { return true }
        // Equipo genérico «Máquina» + cardio en nombre corto poco fiable; no marcar remo de fuerza.
        if isSled(name: n, equipment: eq) { return true }
        return false
    }

    private static func isBikeOrSki(name n: String) -> Bool {
        n.contains("air bike") || n.contains("echo bike") || n.contains("assault")
            || n.contains("fan bike") || n.contains("wattbike")
            || n.contains("bici estatica") || n.contains("bicicleta estatica")
            || n.contains("bikeerg") || n.contains("bike erg")
            || n.contains("skierg") || n.contains("ski erg") || n.contains("ski-erg")
    }

    private static func isErgRow(name n: String) -> Bool {
        if n.contains("rower") || n.contains("concept2") || n.contains("remoerg") {
            return true
        }
        // «Remo máquina» / «Remo» suelto (WOD). Excluir remos de fuerza.
        if n.contains("remo") {
            let strength =
                n.contains("mancuern") || n.contains("barra") || n.contains("sentado")
                || n.contains("menton") || n.contains("invert") || n.contains("anilla")
                || n.contains("polea") || n.contains("landmine") || n.contains("seal")
                || n.contains("pendlay") || n.contains("t-bar") || n.contains("t bar")
            if strength { return false }
            return n == "remo" || n.contains("maquina") || n.contains("erg") || n.hasPrefix("remo ")
        }
        return false
    }

    private static func isRunLike(name n: String) -> Bool {
        n.contains("cinta") || n.contains("carrera") || n.contains("shuttle")
            || n.contains("run ") || n.hasSuffix(" run") || n == "run" || n.contains("running")
    }

    public init(
        id: UUID = UUID(),
        name: String,
        muscleGroup: String,
        equipment: String? = nil,
        isCustom: Bool = false,
        catalogId: String? = nil,
        targetMuscle: String? = nil,
        secondaryMuscles: [String] = [],
        bodyPart: String? = nil,
        detailDescription: String? = nil,
        instructions: [String] = [],
        primaryRegions: [String] = [],
        secondaryRegions: [String] = [],
        isFavorite: Bool = false,
        sportTag: String? = nil
    ) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.equipment = equipment
        self.isCustom = isCustom
        self.catalogId = catalogId
        self.targetMuscle = targetMuscle
        self.secondaryMuscles = secondaryMuscles
        self.bodyPart = bodyPart
        self.detailDescription = detailDescription
        self.instructions = instructions
        self.primaryRegions = primaryRegions
        self.secondaryRegions = secondaryRegions
        self.isFavorite = isFavorite
        self.sportTag = sportTag
    }

    enum CodingKeys: String, CodingKey {
        case id, name, muscleGroup, equipment, isCustom
        case catalogId, targetMuscle, secondaryMuscles, bodyPart
        case detailDescription, instructions, primaryRegions, secondaryRegions, isFavorite
        case sportTag
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        muscleGroup = try c.decode(String.self, forKey: .muscleGroup)
        equipment = try c.decodeIfPresent(String.self, forKey: .equipment)
        isCustom = try c.decodeIfPresent(Bool.self, forKey: .isCustom) ?? false
        catalogId = try c.decodeIfPresent(String.self, forKey: .catalogId)
        targetMuscle = try c.decodeIfPresent(String.self, forKey: .targetMuscle)
        secondaryMuscles = try c.decodeIfPresent([String].self, forKey: .secondaryMuscles) ?? []
        bodyPart = try c.decodeIfPresent(String.self, forKey: .bodyPart)
        detailDescription = try c.decodeIfPresent(String.self, forKey: .detailDescription)
        instructions = try c.decodeIfPresent([String].self, forKey: .instructions) ?? []
        primaryRegions = try c.decodeIfPresent([String].self, forKey: .primaryRegions) ?? []
        secondaryRegions = try c.decodeIfPresent([String].self, forKey: .secondaryRegions) ?? []
        isFavorite = try c.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        sportTag = try c.decodeIfPresent(String.self, forKey: .sportTag)
        // Migración: antiguos grupos deporte → sportTag + músculo principal.
        let legacySports: Set<String> = ["CrossFit", "Halterofilia", "Gimnasia"]
        if sportTag == nil, legacySports.contains(muscleGroup) {
            sportTag = muscleGroup
            muscleGroup = MuscleTaxonomy.libraryMuscleGroup(
                primaries: primaryRegions,
                target: targetMuscle
            )
        }
    }
}

public struct PlannedSet: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var targetReps: Int
    /// Duración prescrita para movilidad, comba o intervalos (segundos por serie).
    public var targetDurationSeconds: Int?
    public var targetWeightKg: Double?
    /// Porcentaje de 1RM prescrito; nunca convertirlo en kg sin un 1RM real.
    public var targetPercent1RM: Double?
    /// 'Más del X%' no es lo mismo que 'X%' exacto.
    public var targetPercent1RMIsMinimum: Bool
    /// Objetivo de RIR para esta serie (nil = sin definir).
    public var targetRir: Double?

    public init(
        id: UUID = UUID(),
        targetReps: Int,
        targetWeightKg: Double? = nil,
        targetDurationSeconds: Int? = nil,
        targetRir: Double? = nil,
        targetPercent1RM: Double? = nil,
        targetPercent1RMIsMinimum: Bool = false
    ) {
        self.id = id
        self.targetReps = targetReps
        self.targetDurationSeconds = targetDurationSeconds
        self.targetWeightKg = targetWeightKg
        self.targetRir = targetRir
        self.targetPercent1RM = targetPercent1RM
        self.targetPercent1RMIsMinimum = targetPercent1RMIsMinimum
    }

    enum CodingKeys: String, CodingKey {
        case id, targetReps, targetDurationSeconds, targetWeightKg, targetRir, targetPercent1RM, targetPercent1RMIsMinimum
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        targetReps = try c.decode(Int.self, forKey: .targetReps)
        targetDurationSeconds = try c.decodeIfPresent(Int.self, forKey: .targetDurationSeconds)
        targetWeightKg = try c.decodeIfPresent(Double.self, forKey: .targetWeightKg)
        targetRir = try c.decodeIfPresent(Double.self, forKey: .targetRir)
        targetPercent1RM = try c.decodeIfPresent(Double.self, forKey: .targetPercent1RM)
        targetPercent1RMIsMinimum = try c.decodeIfPresent(Bool.self, forKey: .targetPercent1RMIsMinimum) ?? false
    }

    /// Copia con nuevo `id` (para insertar en otra rutina).
    public func duplicatingContent() -> PlannedSet {
        PlannedSet(targetReps: targetReps, targetWeightKg: targetWeightKg, targetDurationSeconds: targetDurationSeconds, targetRir: targetRir, targetPercent1RM: targetPercent1RM, targetPercent1RMIsMinimum: targetPercent1RMIsMinimum)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(targetReps, forKey: .targetReps)
        try c.encodeIfPresent(targetDurationSeconds, forKey: .targetDurationSeconds)
        try c.encodeIfPresent(targetWeightKg, forKey: .targetWeightKg)
        try c.encodeIfPresent(targetRir, forKey: .targetRir)
        try c.encodeIfPresent(targetPercent1RM, forKey: .targetPercent1RM)
        if targetPercent1RMIsMinimum { try c.encode(true, forKey: .targetPercent1RMIsMinimum) }
    }
}

extension [PlannedSet] {
    /// Resumen compacto para listas: `3×8 · 60 kg`, `2×3, 2×1 · 150 kg`, `3 @ 100, 2 @ 110`.
    public var compactSummary: String {
        guard !isEmpty else { return "—" }
        if contains(where: { $0.targetDurationSeconds != nil }) {
            return map { set in
                let seconds = set.targetDurationSeconds.map { "\($0)s" } ?? "—"
                return set.targetReps == 1 ? seconds : "\(set.targetReps) reps · \(seconds)"
            }.joined(separator: ", ")
        }
        if contains(where: { $0.targetPercent1RM != nil }) {
            var groups: [(reps:Int,percent:Double?,isMinimum:Bool,count:Int)] = []
            for set in self {
                if let last=groups.last,last.reps==set.targetReps,last.percent==set.targetPercent1RM,last.isMinimum==set.targetPercent1RMIsMinimum {
                    groups[groups.count-1].count += 1
                } else {
                    groups.append((set.targetReps,set.targetPercent1RM,set.targetPercent1RMIsMinimum,1))
                }
            }
            return groups.map { group in
                let reps=group.count>1 ? "\(group.count)×\(group.reps)" : "\(group.reps)"
                return reps + (group.percent.map { " @ \(group.isMinimum ? ">" : "")\(String(format: "%g", $0))% 1RM" } ?? "")
            }.joined(separator: ", ")
        }
        // (reps, weightKg, count)
        var groups: [(Int, Double?, Int)] = []
        for set in self {
            if let last = groups.last,
               last.0 == set.targetReps,
               PlannedSetSummary.sameWeight(last.1, set.targetWeightKg) {
                groups[groups.count - 1].2 += 1
            } else {
                groups.append((set.targetReps, set.targetWeightKg, 1))
            }
        }

        let allSameWeight = groups.allSatisfy { PlannedSetSummary.sameWeight($0.1, groups[0].1) }
        if allSameWeight {
            let scheme = groups.map { reps, _, count in
                count == 1 ? "\(reps)" : "\(count)×\(reps)"
            }.joined(separator: ", ")
            return "\(scheme) · \(PlannedSetSummary.weightLabel(groups[0].1))"
        }

        return groups.map { reps, weight, count in
            let repsPart = count == 1 ? "\(reps)" : "\(count)×\(reps)"
            return "\(repsPart) @ \(PlannedSetSummary.weightLabel(weight))"
        }.joined(separator: ", ")
    }

    /// Solo el esquema de series/reps (sin peso): `3×8` o `2×3, 2×1`.
    public var compactRepsSummary: String {
        guard !isEmpty else { return "—" }
        var groups: [(Int, Int)] = []
        for set in self {
            if let last = groups.last, last.0 == set.targetReps {
                groups[groups.count - 1].1 += 1
            } else {
                groups.append((set.targetReps, 1))
            }
        }
        return groups.map { reps, count in
            count == 1 ? "\(reps)" : "\(count)×\(reps)"
        }.joined(separator: ", ")
    }
}

private enum PlannedSetSummary {
    static func sameWeight(_ a: Double?, _ b: Double?) -> Bool {
        switch (a, b) {
        case (nil, nil): return true
        case let (x?, y?): return abs(x - y) < 0.05
        default: return false
        }
    }

    static func weightLabel(_ w: Double?) -> String {
        w.map { String(format: "%g kg", $0) } ?? "—"
    }
}

public struct LoggedSet: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    /// Cantidad: reps, calorías o metros según `quantityUnit`.
    public var reps: Int
    public var weightKg: Double?
    /// Déficit de HSPU en cm (no cuenta como volumen).
    public var deficitCm: Int?
    /// Duración de la serie/intervalo (comba, bike, carrera…).
    public var durationSeconds: Int?
    /// Interpreta `reps` como Cal / m cuando el estilo es máquina.
    public var quantityUnit: ExerciseQuantityUnit?
    public var completedAt: Date
    public var phase: SetPhase
    public var kind: SetKind
    /// Always stored as RIR (0 = failure). Convert at the UI with `Effort`.
    public var rir: Double?
    public var toFailure: Bool
    public var drops: [DropSegment]
    public var clusters: [RestPauseCluster]

    public init(
        id: UUID = UUID(),
        reps: Int,
        weightKg: Double? = nil,
        deficitCm: Int? = nil,
        durationSeconds: Int? = nil,
        quantityUnit: ExerciseQuantityUnit? = nil,
        completedAt: Date = Date(),
        phase: SetPhase = .work,
        kind: SetKind = .straight,
        rir: Double? = nil,
        toFailure: Bool = false,
        drops: [DropSegment] = [],
        clusters: [RestPauseCluster] = []
    ) {
        self.id = id
        self.weightKg = weightKg
        self.deficitCm = deficitCm
        self.durationSeconds = durationSeconds
        self.quantityUnit = quantityUnit
        self.completedAt = completedAt
        self.phase = phase
        self.kind = kind
        self.rir = toFailure ? 0 : rir
        self.toFailure = toFailure
        self.drops = drops
        self.clusters = clusters
        if !drops.isEmpty {
            self.kind = .dropset
        } else if !clusters.isEmpty {
            self.kind = .restpause
        }
        // Rest-pause: parent reps is the sum of clusters when provided.
        if self.kind == .restpause, !clusters.isEmpty {
            self.reps = clusters.reduce(0) { $0 + $1.reps }
        } else {
            self.reps = reps
        }
    }

    public var isWarmup: Bool { phase == .warmup }

    public var countsForProgression: Bool { phase == .work }

    public var volumeKg: Double {
        // Cal/metros / déficit cm no aportan volumen en kg.
        if quantityUnit == .calories || quantityUnit == .meters { return 0 }
        if deficitCm != nil { return 0 }
        let main = Double(reps) * (weightKg ?? 0)
        // Drops add volume; rest-pause clusters are a breakdown of `reps` (no double count).
        let extra = drops.reduce(0.0) { $0 + Double($1.reps) * ($1.weightKg ?? 0) }
        return main + extra
    }

    public var isMachineQuantity: Bool {
        quantityUnit == .calories || quantityUnit == .meters
    }

    /// Línea compacta: `80×5`, `10 cm × 8`, `50 veces · 1:00`, `15 cal · 1:00`.
    public var displaySummaryLine: String {
        if let unit = quantityUnit, unit != .reps {
            var parts: [String] = ["\(reps) \(unit.shortLabel)"]
            if let sec = durationSeconds, sec > 0 {
                parts.append(Self.formatClock(sec))
            }
            return parts.joined(separator: " · ")
        }
        if let sec = durationSeconds, sec > 0, weightKg == nil, deficitCm == nil {
            // Comba / intervalos: veces + tiempo.
            return "\(reps) veces · \(Self.formatClock(sec))"
        }
        if let deficit = deficitCm {
            return "\(deficit) cm × \(reps)"
        }
        let w = weightKg.map { String(format: "%g", $0) } ?? "—"
        var line = "\(w)×\(reps)"
        if let sec = durationSeconds, sec > 0 {
            line += " · \(Self.formatClock(sec))"
        }
        // RIR va en columna aparte en el detalle; no repetirlo entre paréntesis.
        return line
    }

    private static func formatClock(_ sec: Int) -> String {
        let m = sec / 60
        let s = sec % 60
        return s == 0 ? "\(m):00" : String(format: "%d:%02d", m, s)
    }

    /// Equivalente en «series duras» para fatiga: erg/cardio escala por minutos.
    public var fatigueSetEquivalent: Double {
        if isWarmup { return 0.25 }
        if isMachineQuantity || durationSeconds != nil && weightKg == nil {
            let minutes = Double(max(durationSeconds ?? 60, 30)) / 60.0
            return min(3.0, max(0.5, minutes))
        }
        if Effort.isHard(rir: rir) { return 1.0 }
        return 0.7
    }

    enum CodingKeys: String, CodingKey {
        case id, reps, weightKg, deficitCm, durationSeconds, quantityUnit
        case completedAt, phase, kind, rir, toFailure, drops, clusters
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        reps = try c.decode(Int.self, forKey: .reps)
        weightKg = try c.decodeIfPresent(Double.self, forKey: .weightKg)
        deficitCm = try c.decodeIfPresent(Int.self, forKey: .deficitCm)
        durationSeconds = try c.decodeIfPresent(Int.self, forKey: .durationSeconds)
        quantityUnit = try c.decodeIfPresent(ExerciseQuantityUnit.self, forKey: .quantityUnit)
        completedAt = try c.decodeIfPresent(Date.self, forKey: .completedAt) ?? Date()
        phase = try c.decodeIfPresent(SetPhase.self, forKey: .phase) ?? .work
        kind = try c.decodeIfPresent(SetKind.self, forKey: .kind) ?? .straight
        rir = try c.decodeIfPresent(Double.self, forKey: .rir)
        toFailure = try c.decodeIfPresent(Bool.self, forKey: .toFailure) ?? false
        drops = try c.decodeIfPresent([DropSegment].self, forKey: .drops) ?? []
        clusters = try c.decodeIfPresent([RestPauseCluster].self, forKey: .clusters) ?? []
        if !drops.isEmpty {
            kind = .dropset
        } else if !clusters.isEmpty {
            kind = .restpause
            reps = clusters.reduce(0) { $0 + $1.reps }
        }
        if toFailure { rir = 0 }
    }
}

public struct RoutineExercise: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var exerciseId: UUID
    public var plannedSets: [PlannedSet]
    /// Cantidad preferida para máquina / cardio (Cal o metros), independiente del peso.
    public var quantityUnit: ExerciseQuantityUnit?
    public var restSeconds: Int?
    /// Campo histórico conservado para leer rutinas existentes; no activa superseries.
    public var supersetGroup: Int?

    public init(
        id: UUID = UUID(),
        exerciseId: UUID,
        plannedSets: [PlannedSet],
        quantityUnit: ExerciseQuantityUnit? = nil,
        restSeconds: Int? = nil,
        supersetGroup: Int? = nil
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.plannedSets = plannedSets
        self.quantityUnit = quantityUnit
        self.restSeconds = restSeconds
        self.supersetGroup = supersetGroup
    }

    enum CodingKeys: String, CodingKey {
        case id, exerciseId, plannedSets, quantityUnit, restSeconds, supersetGroup
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        exerciseId = try c.decode(UUID.self, forKey: .exerciseId)
        plannedSets = try c.decodeIfPresent([PlannedSet].self, forKey: .plannedSets) ?? []
        quantityUnit = try c.decodeIfPresent(ExerciseQuantityUnit.self, forKey: .quantityUnit)
        restSeconds = try c.decodeIfPresent(Int.self, forKey: .restSeconds)
        supersetGroup = nil // Compatibilidad de lectura, sin restaurar agrupaciones.
    }

    /// Copia con nuevos IDs de ejercicio y series.
    public func duplicatingContent() -> RoutineExercise {
        RoutineExercise(
            exerciseId: exerciseId,
            plannedSets: plannedSets.map { $0.duplicatingContent() },
            quantityUnit: quantityUnit,
            restSeconds: restSeconds,
            supersetGroup: nil
        )
    }
}

public enum RoutineBlockKind: String, Codable, Sendable, Hashable, CaseIterable {
    case strength
    case wod
}

public enum WODFormat: String, Codable, Sendable, Hashable, CaseIterable {
    case amrap
    case emom
    case forTime
    case tabata
    case chipper
    case deathBy
    /// Fuerza / skill / técnica (series×reps).
    case strength
    /// As Fast As Possible.
    case afap
    /// Escalera ascendente/descendente (21-15-9, ladder…).
    case ladder
    /// Partner / You Go I Go.
    case partner
    /// Buy-in + parte media + cash-out.
    case buyInCashOut
    /// Rounds for quality (sin reloj agresivo).
    case roundsForQuality
    /// Circuito / estaciones.
    case circuit
    /// Max effort / find a heavy / max reps.
    case maxEffort

    public var displayName: String {
        switch self {
        case .amrap: return "AMRAP"
        case .emom: return "EMOM / Every X'"
        case .forTime: return "For Time / RFT"
        case .tabata: return "Tabata"
        case .chipper: return "Chipper"
        case .deathBy: return "Muerte por"
        case .strength: return "Fuerza / Skill"
        case .afap: return "AFAP"
        case .ladder: return "Ladder / 21-15-9"
        case .partner: return "Partner / YGIG"
        case .buyInCashOut: return "Buy-in / Cash-out"
        case .roundsForQuality: return "Rounds for Quality"
        case .circuit: return "Circuito"
        case .maxEffort: return "Max effort"
        }
    }

    public var detail: String {
        switch self {
        case .amrap: return "Máximas rondas/reps en un tiempo fijo (AMRAP 12', AMRAP 10 min)."
        case .emom: return "Trabajo al inicio de cada intervalo (EMOM, EVERY 2'×4, E2MOM, ON THE MINUTE)."
        case .forTime: return "Termina lo antes posible: N RFT, FOR TIME, TC (time cap)."
        case .tabata: return "Intervalos fijos clásicos 20\"/10\" × rondas (u otras proporciones)."
        case .chipper: return "Lista larga en una sola pasada, lo más rápido posible."
        case .deathBy: return "Cada minuto sumas 1 rep (u otra progresión) hasta fallar."
        case .strength: return "Bloque de fuerza/técnica: 5×5, 3×8 @RPE, skill."
        case .afap: return "Haz el trabajo lo más rápido posible (sin rondas fijas)."
        case .ladder: return "Escalera: 21-15-9, ascending/descending ladder, pirámide."
        case .partner: return "Dos atletas: You Go I Go, sync, split reps."
        case .buyInCashOut: return "Empieza (buy-in) y/o termina (cash-out) con un trabajo fijo aparte del WOD."
        case .roundsForQuality: return "N rondas priorizando técnica (RFQ / for quality), sin prisa de reloj."
        case .circuit: return "Estaciones o circuito (CIRCUIT, STATIONS, ROTATION)."
        case .maxEffort: return "Buscar máximo: heavy single, max reps, max calories en ventana."
        }
    }

    /// Ejemplos de cabecera en pizarra (para el entrenador / OCR).
    public var boardExamples: [String] {
        switch self {
        case .amrap: return ["AMRAP 12'", "AMRAP 10 MIN", "AS MANY ROUNDS AS POSSIBLE 15'"]
        case .emom: return ["EMOM 8'", "EVERY 2' X 4", "E2MOM 10'", "ON THE MINUTE × 12"]
        case .forTime: return ["4 RFT (TC 12')", "FOR TIME", "3 ROUNDS FOR TIME"]
        case .tabata: return ["TABATA", "TABATA 20/10 × 8"]
        case .chipper: return ["CHIPPER", "FOR COMPLETION"]
        case .deathBy: return ["DEATH BY BURPEES", "MUERTE POR C&J"]
        case .strength: return ["STRENGTH", "SKILL", "TECH", "5x5 BACK SQUAT"]
        case .afap: return ["AFAP", "AS FAST AS POSSIBLE"]
        case .ladder: return ["21-15-9", "ASCENDING LADDER", "DESCENDING LADDER 10→1"]
        case .partner: return ["PARTNER WOD", "YOU GO I GO", "YGIG"]
        case .buyInCashOut: return ["BUY-IN: 500m ROW", "CASH OUT: 50 DU"]
        case .roundsForQuality: return ["3 ROUNDS FOR QUALITY", "RFQ"]
        case .circuit: return ["CIRCUIT", "5 STATIONS", "ROTATION"]
        case .maxEffort: return ["FIND A HEAVY", "MAX REPS 2'", "MAX LOAD"]
        }
    }

    /// Cómo se apunta el resultado del bloque (play / Apuntar).
    public var resultCapture: WODResultCapture {
        switch self {
        case .amrap, .deathBy, .maxEffort:
            return .totalReps
        case .forTime, .chipper, .afap, .ladder, .buyInCashOut:
            return .elapsedTime
        case .emom, .tabata, .circuit, .partner, .roundsForQuality, .strength:
            return .perMovementSets
        }
    }
}

/// Cómo se captura el score de un WOD.
public enum WODResultCapture: String, Codable, Sendable, Hashable {
    case totalReps
    case elapsedTime
    case perMovementSets
}

/// Resultado de un bloque WOD (AMRAP reps, For Time tiempo…).
public struct WODBlockResult: Identifiable, Codable, Sendable, Hashable {
    public var id: UUID
    public var format: WODFormat?
    public var totalReps: Int?
    public var elapsedSeconds: Int?
    public var roundsCompleted: Int?
    public var wodTemplateId: String?

    public init(
        id: UUID,
        format: WODFormat? = nil,
        totalReps: Int? = nil,
        elapsedSeconds: Int? = nil,
        roundsCompleted: Int? = nil,
        wodTemplateId: String? = nil
    ) {
        self.id = id
        self.format = format
        self.totalReps = totalReps
        self.elapsedSeconds = elapsedSeconds
        self.roundsCompleted = roundsCompleted
        self.wodTemplateId = wodTemplateId
    }

    public var summaryLabel: String {
        if let elapsedSeconds {
            let m = elapsedSeconds / 60
            let s = elapsedSeconds % 60
            return String(format: "%d:%02d", m, s)
        }
        if let totalReps {
            if let roundsCompleted {
                return "\(roundsCompleted) rondas + \(totalReps) reps"
            }
            return "\(totalReps) reps"
        }
        if let roundsCompleted {
            return "\(roundsCompleted) rondas"
        }
        return "—"
    }
}

/// Movimiento dentro de un WOD (reps, carga M/F, metros, descanso…).
public struct WODMovement: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var exerciseId: UUID?
    public var name: String
    public var reps: Int?
    /// Esquema de series (ej. 4-4-3-3 → cuatro series con esas reps).
    public var repScheme: [Int]?
    public var distanceMeters: Int?
    public var calories: Int?
    public var weightMaleKg: Double?
    public var weightFemaleKg: Double?
    public var isRest: Bool
    public var restSeconds: Int?
    /// Escala alternativa (ej. "100 SU" cuando el principal es "50 DU").
    public var scaleAlternative: String?
    public var notes: String?
    /// Series editadas a mano (peso/RIR/reps). Si no es nil, manda sobre ola/rondas.
    public var explicitPlannedSets: [PlannedSet]?

    public init(
        id: UUID = UUID(),
        exerciseId: UUID? = nil,
        name: String,
        reps: Int? = nil,
        repScheme: [Int]? = nil,
        distanceMeters: Int? = nil,
        calories: Int? = nil,
        weightMaleKg: Double? = nil,
        weightFemaleKg: Double? = nil,
        isRest: Bool = false,
        restSeconds: Int? = nil,
        scaleAlternative: String? = nil,
        notes: String? = nil,
        explicitPlannedSets: [PlannedSet]? = nil
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.name = name
        self.reps = reps
        self.repScheme = repScheme
        self.distanceMeters = distanceMeters
        self.calories = calories
        self.weightMaleKg = weightMaleKg
        self.weightFemaleKg = weightFemaleKg
        self.isRest = isRest
        self.restSeconds = restSeconds
        self.scaleAlternative = scaleAlternative
        self.notes = notes
        self.explicitPlannedSets = explicitPlannedSets
    }

    enum CodingKeys: String, CodingKey {
        case id, exerciseId, name, reps, repScheme, distanceMeters, calories
        case weightMaleKg, weightFemaleKg, isRest, restSeconds, scaleAlternative, notes
        case explicitPlannedSets
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        exerciseId = try c.decodeIfPresent(UUID.self, forKey: .exerciseId)
        name = try c.decode(String.self, forKey: .name)
        reps = try c.decodeIfPresent(Int.self, forKey: .reps)
        repScheme = try c.decodeIfPresent([Int].self, forKey: .repScheme)
        distanceMeters = try c.decodeIfPresent(Int.self, forKey: .distanceMeters)
        calories = try c.decodeIfPresent(Int.self, forKey: .calories)
        weightMaleKg = try c.decodeIfPresent(Double.self, forKey: .weightMaleKg)
        weightFemaleKg = try c.decodeIfPresent(Double.self, forKey: .weightFemaleKg)
        isRest = try c.decodeIfPresent(Bool.self, forKey: .isRest) ?? false
        restSeconds = try c.decodeIfPresent(Int.self, forKey: .restSeconds)
        scaleAlternative = try c.decodeIfPresent(String.self, forKey: .scaleAlternative)
        notes = try c.decodeIfPresent(String.self, forKey: .notes)
        explicitPlannedSets = try c.decodeIfPresent([PlannedSet].self, forKey: .explicitPlannedSets)
    }

    public var summaryLine: String {
        if isRest {
            let sec = restSeconds ?? 60
            return sec >= 60 ? "\(sec / 60)' REST" : "\(sec)\" REST"
        }
        var parts: [String] = []
        if let scheme = repScheme, scheme.count >= 2 {
            parts.append(scheme.map(String.init).joined(separator: "-"))
        } else if let reps {
            parts.append("\(reps)")
        }
        if let m = distanceMeters { parts.append("\(m)m") }
        if let c = calories { parts.append("\(c) cal") }
        parts.append(name.uppercased())
        if let male = weightMaleKg {
            let female = weightFemaleKg.map { "\($0.formatted(.number.precision(.fractionLength(0))))" } ?? "—"
            parts.append("\(male.formatted(.number.precision(.fractionLength(0))))/\(female)")
        }
        var line = parts.joined(separator: " ")
        if let scaleAlternative, !scaleAlternative.isEmpty {
            line += " / \(scaleAlternative)"
        }
        return line
    }

    /// `5-10` / `6-8` = rango de reps por ronda (no ola de series). `4-3-3-2` / `21-15-9` = ola.
    public var isAscendingRepRange: Bool {
        Self.isAscendingRepRange(repScheme)
    }

    public static func isAscendingRepRange(_ scheme: [Int]?) -> Bool {
        guard let scheme, scheme.count == 2 else { return false }
        let lo = scheme[0], hi = scheme[1]
        return lo < hi && (hi - lo) <= 20
    }

    /// Series planificadas: esquema 4-3-3-2 o una serie con reps / cal / metros.
    public var plannedSetsFromReps: [PlannedSet] {
        let weight = weightMaleKg
        if let scheme = repScheme, !scheme.isEmpty, !isAscendingRepRange {
            return scheme.map { PlannedSet(targetReps: max(1, $0), targetWeightKg: weight) }
        }
        let r: Int
        if let scheme = repScheme, isAscendingRepRange {
            r = scheme[1] // techo del rango (5-10 → 10)
        } else {
            // Cal y metros van enteros al target (no dividir metros/10).
            r = calories ?? distanceMeters ?? reps ?? 10
        }
        return [PlannedSet(targetReps: max(1, r), targetWeightKg: weight)]
    }

    /// Unidad prescrita del movimiento WOD (cal / m / reps).
    public var prescribedQuantityUnit: ExerciseQuantityUnit {
        if calories != nil { return .calories }
        if distanceMeters != nil { return .meters }
        return Exercise.defaultQuantityUnit(name: name)
    }

    /// Expande un set base a `count` series idénticas (EMOM/RFT/Tabata…).
    public func repeatingPlannedSets(count: Int) -> [PlannedSet] {
        let base = plannedSetsFromReps
        guard count > 1, base.count == 1, let template = base.first else { return base }
        return (0..<count).map { _ in
            PlannedSet(targetReps: template.targetReps, targetWeightKg: template.targetWeightKg, targetRir: template.targetRir)
        }
    }

    /// Si la ola tiene menos series que `count`, completa repitiendo el último (p. ej. 4-3-3 → 4-3-3-3).
    public func plannedSetsPadded(to count: Int) -> [PlannedSet] {
        let base = plannedSetsFromReps
        guard count > 0 else { return [] }
        if base.isEmpty {
            return (0..<count).map { _ in PlannedSet(targetReps: reps ?? 10, targetWeightKg: weightMaleKg) }
        }
        if base.count >= count {
            return Array(base.prefix(count))
        }
        guard let last = base.last else { return base }
        let pad = (0..<(count - base.count)).map { _ in
            PlannedSet(
                targetReps: last.targetReps,
                targetWeightKg: last.targetWeightKg,
                targetRir: last.targetRir
            )
        }
        return base + pad
    }

    /// Copia con nuevo `id`.
    public func duplicatingContent() -> WODMovement {
        WODMovement(
            exerciseId: exerciseId,
            name: name,
            reps: reps,
            repScheme: repScheme,
            distanceMeters: distanceMeters,
            calories: calories,
            weightMaleKg: weightMaleKg,
            weightFemaleKg: weightFemaleKg,
            isRest: isRest,
            restSeconds: restSeconds,
            scaleAlternative: scaleAlternative,
            notes: notes,
            explicitPlannedSets: explicitPlannedSets?.map { $0.duplicatingContent() }
        )
    }
}

public struct RoutineBlock: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var title: String
    public var kind: RoutineBlockKind
    /// Bloque de fuerza: series/reps.
    public var exercises: [RoutineExercise]
    /// Bloque WOD: movimientos tipados.
    public var movements: [WODMovement]
    public var wodFormat: WODFormat?
    public var timeCapMinutes: Int?
    public var emomIntervalSeconds: Int?
    public var rounds: Int?
    /// Tabata / intervalos.
    public var workSeconds: Int?
    public var restSeconds: Int?
    /// Descanso entre rondas (RFT).
    public var restBetweenRoundsSeconds: Int?
    public var wodNotes: String?
    /// ID estable del catálogo de benchmarks (`CatalogWODs`), si viene de plantilla.
    public var wodTemplateId: String?

    public init(
        id: UUID = UUID(),
        title: String,
        kind: RoutineBlockKind,
        exercises: [RoutineExercise] = [],
        movements: [WODMovement] = [],
        wodFormat: WODFormat? = nil,
        timeCapMinutes: Int? = nil,
        emomIntervalSeconds: Int? = 60,
        rounds: Int? = nil,
        workSeconds: Int? = nil,
        restSeconds: Int? = nil,
        restBetweenRoundsSeconds: Int? = nil,
        wodNotes: String? = nil,
        wodTemplateId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.kind = kind
        self.exercises = exercises
        self.movements = movements
        self.wodFormat = wodFormat
        self.timeCapMinutes = timeCapMinutes
        self.emomIntervalSeconds = emomIntervalSeconds
        self.rounds = rounds
        self.workSeconds = workSeconds
        self.restSeconds = restSeconds
        self.restBetweenRoundsSeconds = restBetweenRoundsSeconds
        self.wodNotes = wodNotes
        self.wodTemplateId = wodTemplateId
    }

    enum CodingKeys: String, CodingKey {
        case id, title, kind, exercises, movements, wodFormat, timeCapMinutes
        case emomIntervalSeconds, rounds, workSeconds, restSeconds
        case restBetweenRoundsSeconds, wodNotes, wodTemplateId
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        kind = try c.decode(RoutineBlockKind.self, forKey: .kind)
        exercises = try c.decodeIfPresent([RoutineExercise].self, forKey: .exercises) ?? []
        movements = try c.decodeIfPresent([WODMovement].self, forKey: .movements) ?? []
        wodFormat = try c.decodeIfPresent(WODFormat.self, forKey: .wodFormat)
        timeCapMinutes = try c.decodeIfPresent(Int.self, forKey: .timeCapMinutes)
        emomIntervalSeconds = try c.decodeIfPresent(Int.self, forKey: .emomIntervalSeconds)
        rounds = try c.decodeIfPresent(Int.self, forKey: .rounds)
        workSeconds = try c.decodeIfPresent(Int.self, forKey: .workSeconds)
        restSeconds = try c.decodeIfPresent(Int.self, forKey: .restSeconds)
        restBetweenRoundsSeconds = try c.decodeIfPresent(Int.self, forKey: .restBetweenRoundsSeconds)
        wodNotes = try c.decodeIfPresent(String.self, forKey: .wodNotes)
        wodTemplateId = try c.decodeIfPresent(String.self, forKey: .wodTemplateId)
    }

    public static func strength(title: String = "Bloque 1", exercises: [RoutineExercise] = []) -> RoutineBlock {
        RoutineBlock(title: title, kind: .strength, exercises: exercises)
    }

    /// Copia profunda con IDs nuevos (bloque, ejercicios, movimientos y series).
    public func duplicatingContent() -> RoutineBlock {
        RoutineBlock(
            title: title,
            kind: kind,
            exercises: exercises.map { $0.duplicatingContent() },
            movements: movements.map { $0.duplicatingContent() },
            wodFormat: wodFormat,
            timeCapMinutes: timeCapMinutes,
            emomIntervalSeconds: emomIntervalSeconds,
            rounds: rounds,
            workSeconds: workSeconds,
            restSeconds: restSeconds,
            restBetweenRoundsSeconds: restBetweenRoundsSeconds,
            wodNotes: wodNotes,
            wodTemplateId: wodTemplateId
        )
    }

    public static func wod(format: WODFormat, title: String? = nil) -> RoutineBlock {
        let isTabata = format == .tabata
        return RoutineBlock(
            title: title ?? format.displayName,
            kind: .wod,
            wodFormat: format,
            timeCapMinutes: format == .amrap || format == .forTime ? 12 : (isTabata ? 4 : 10),
            emomIntervalSeconds: 60,
            rounds: isTabata ? 8 : nil,
            workSeconds: isTabata ? 20 : nil,
            restSeconds: isTabata ? 10 : nil
        )
    }

    public var headerLabel: String {
        guard kind == .wod, let format = wodFormat else { return title }
        switch format {
        case .amrap:
            return "AMRAP \(timeCapMinutes ?? 12)'"
        case .forTime:
            if let rounds {
                return "\(rounds) RFT (TC \(timeCapMinutes ?? 12)')"
            }
            return "For Time (TC \(timeCapMinutes ?? 12)')"
        case .emom:
            let interval = emomIntervalSeconds ?? 60
            if interval != 60, let rounds {
                let mins = max(1, interval / 60)
                return "Every \(mins)' × \(rounds)"
            }
            return "EMOM \(timeCapMinutes ?? 10)'"
        case .tabata:
            return "Tabata \(workSeconds ?? 20)/\(restSeconds ?? 10) ×\(rounds ?? 8)"
        case .chipper:
            return "Chipper"
        case .deathBy:
            return "Muerte por"
        case .strength:
            return title.isEmpty ? "Fuerza" : title
        case .afap:
            return "AFAP"
        case .ladder:
            return title.isEmpty ? "Ladder" : title
        case .partner:
            return "Partner"
        case .buyInCashOut:
            return title.isEmpty ? "Buy-in / Cash-out" : title
        case .roundsForQuality:
            if let rounds { return "\(rounds) RFQ" }
            return "Rounds for Quality"
        case .circuit:
            return "Circuito"
        case .maxEffort:
            return "Max effort"
        }
    }

    /// Estaciones del circuito (movimientos + rest) para derivar vueltas EMOM.
    public var stationCount: Int {
        max(1, movements.count)
    }

    /// Intervalos de reloj EMOM (minutos del cap ÷ intervalo), no confundir con `rounds` (vueltas).
    public var emomTimerIntervals: Int? {
        guard wodFormat == .emom || wodFormat == .circuit else { return nil }
        let interval = max(1, emomIntervalSeconds ?? 60)
        if let cap = timeCapMinutes, cap > 0 {
            return max(1, (cap * 60) / interval)
        }
        return rounds
    }

    /// Deriva `rounds` en EMOM/circuito multi-estación cuando la cabecera no los fijó.
    public mutating func deriveEmomRoundsIfNeeded() {
        guard wodFormat == .emom || wodFormat == .circuit else { return }
        guard rounds == nil else { return }
        guard let total = emomTimerIntervals, total > 0 else { return }
        let stations = stationCount
        rounds = max(1, total / stations)
    }

    /// Series al apuntar / sesión para un movimiento WOD según formato del bloque.
    public func plannedSets(for movement: WODMovement) -> [PlannedSet] {
        guard !movement.isRest else { return [] }
        // Series editadas (peso/RIR) mandan sobre ola/rondas.
        if let explicit = movement.explicitPlannedSets, !explicit.isEmpty {
            return explicit
        }
        let base = movement.plannedSetsFromReps
        let emomRounds = max(1, rounds ?? 1)

        // Ola explícita (4-3-3-2…). Si hay menos números que rondas EMOM → rellenar con el último.
        if let scheme = movement.repScheme, !scheme.isEmpty, !movement.isAscendingRepRange {
            if wodFormat == .emom || wodFormat == .circuit {
                return movement.plannedSetsPadded(to: emomRounds)
            }
            return base
        }
        guard let format = wodFormat else { return base }

        switch format {
        case .emom, .circuit:
            return movement.repeatingPlannedSets(count: emomRounds)
        case .tabata:
            // Cada ventana de TRABAJO corresponde a una serie del movimiento
            // que toca. Con varios movimientos se alternan las estaciones,
            // no se prescriben 8 series a cada una para un Tabata de 8 rondas.
            let workIntervals = max(1, rounds ?? 8)
            let activeStations = movements.filter { !$0.isRest }
            let stationTotal = max(1, activeStations.count)
            let station = activeStations.firstIndex(where: { $0.id == movement.id }) ?? 0
            let count = max(0, (workIntervals + stationTotal - 1 - station) / stationTotal)
            return count > 0 ? movement.repeatingPlannedSets(count: count) : []
        case .forTime, .roundsForQuality:
            guard let n = rounds, n > 1 else { return base }
            return movement.repeatingPlannedSets(count: n)
        case .ladder:
            return base
        case .chipper, .afap, .buyInCashOut, .amrap, .partner, .deathBy, .maxEffort, .strength:
            return base
        }
    }
}

public struct Routine: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var title: String
    /// 1 = Monday … 7 = Sunday (ISO). Plan semanal (Diario) cuando `scheduledDate == nil`.
    public var weekday: Int?
    /// Día concreto (inicio del día). Si no es nil → entreno suelto de ese día (no es plan semanal).
    public var scheduledDate: Date?
    /// Hora del día en minutos desde medianoche (0…1439). Opcional.
    public var scheduledTimeMinutes: Int?
    /// Plantilla habitual reutilizable desde Crear → Favoritos.
    public var isFavorite: Bool
    /// Bloques del entreno (fuerza y/o WOD). Fuente de verdad.
    public var blocks: [RoutineBlock]
    public var progression: ProgressionPolicy

    /// Forma parte del plan semanal de Diario (no es un entreno suelto).
    public var isWeeklyPlan: Bool { scheduledDate == nil && weekday != nil }

    /// Plantilla reutilizable (Diario → Rutinas): no es un entreno suelto por fecha.
    public var isLibraryRoutine: Bool { scheduledDate == nil }

    /// Entreno suelto ligado a un día del calendario.
    public var isOneOff: Bool { scheduledDate != nil }

    /// Hora programada válida (minutos 0…1439).
    public var normalizedScheduledTimeMinutes: Int? {
        guard let m = scheduledTimeMinutes, (0..<24 * 60).contains(m) else { return nil }
        return m
    }

    /// Ejercicios de fuerza aplanados (compat sesión / import).
    public var exercises: [RoutineExercise] {
        get { blocks.filter { $0.kind == .strength }.flatMap(\.exercises) }
        set {
            if let idx = blocks.firstIndex(where: { $0.kind == .strength }) {
                blocks[idx].exercises = newValue
            } else if !newValue.isEmpty {
                blocks.insert(.strength(exercises: newValue), at: 0)
            }
        }
    }

    public init(
        id: UUID = UUID(),
        title: String,
        weekday: Int? = nil,
        scheduledDate: Date? = nil,
        scheduledTimeMinutes: Int? = nil,
        exercises: [RoutineExercise] = [],
        blocks: [RoutineBlock]? = nil,
        progression: ProgressionPolicy = .linear,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.weekday = weekday
        self.scheduledDate = scheduledDate.map { Calendar.current.startOfDay(for: $0) }
        if let scheduledTimeMinutes, (0..<24 * 60).contains(scheduledTimeMinutes) {
            self.scheduledTimeMinutes = scheduledTimeMinutes
        } else {
            self.scheduledTimeMinutes = nil
        }
        self.isFavorite = isFavorite
        if let blocks, !blocks.isEmpty {
            self.blocks = blocks
        } else if !exercises.isEmpty {
            self.blocks = [.strength(exercises: exercises)]
        } else {
            self.blocks = []
        }
        self.progression = progression
    }

    /// Fecha+hora del entreno ese día (si hay hora programada).
    public func scheduledDateTime(on day: Date = Date(), calendar: Calendar = .current) -> Date? {
        guard let minutes = normalizedScheduledTimeMinutes else { return nil }
        let start = calendar.startOfDay(for: day)
        return calendar.date(byAdding: .minute, value: minutes, to: start)
    }

    public mutating func setScheduledTime(from date: Date, calendar: Calendar = .current) {
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        scheduledTimeMinutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }

    enum CodingKeys: String, CodingKey {
        case id, title, weekday, scheduledDate, scheduledTimeMinutes, exercises, blocks, progression, isFavorite
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        weekday = try c.decodeIfPresent(Int.self, forKey: .weekday)
        if let raw = try c.decodeIfPresent(Date.self, forKey: .scheduledDate) {
            scheduledDate = Calendar.current.startOfDay(for: raw)
        } else {
            scheduledDate = nil
        }
        if let minutes = try c.decodeIfPresent(Int.self, forKey: .scheduledTimeMinutes),
           (0..<24 * 60).contains(minutes) {
            scheduledTimeMinutes = minutes
        } else {
            scheduledTimeMinutes = nil
        }
        isFavorite = try c.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        progression = try c.decodeIfPresent(ProgressionPolicy.self, forKey: .progression) ?? .linear
        let legacy = try c.decodeIfPresent([RoutineExercise].self, forKey: .exercises) ?? []
        let decodedBlocks = try c.decodeIfPresent([RoutineBlock].self, forKey: .blocks) ?? []
        if !decodedBlocks.isEmpty {
            blocks = decodedBlocks
        } else if !legacy.isEmpty {
            blocks = [.strength(exercises: legacy)]
        } else {
            blocks = []
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encodeIfPresent(weekday, forKey: .weekday)
        try c.encodeIfPresent(scheduledDate, forKey: .scheduledDate)
        try c.encodeIfPresent(normalizedScheduledTimeMinutes, forKey: .scheduledTimeMinutes)
        try c.encode(isFavorite, forKey: .isFavorite)
        try c.encode(blocks, forKey: .blocks)
        try c.encode(exercises, forKey: .exercises)
        try c.encode(progression, forKey: .progression)
    }
}

public struct SessionExercise: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var exercise: Exercise
    public var plannedSets: [PlannedSet]
    public var quantityUnit: ExerciseQuantityUnit?
    public var loggedSets: [LoggedSet]
    /// Descanso entre series prescrito por el plan, incluso en ejercicios sin bloque.
    public var restSeconds: Int?
    public var completedReps: Int
    /// Cantidad utilizada al adaptar un movimiento de un WOD con score global.
    /// No equivale a series registradas ni sustituye el score de bloque.
    public var adaptedReps: Int?
    /// Carga realmente utilizada al escalar el movimiento (kg).
    public var adaptedWeightKg: Double?
    public var isCompleted: Bool
    public var supersetGroup: Int?
    /// Bloque de origen en el plan (para agrupar la cola).
    public var blockId: UUID?
    public var blockKind: RoutineBlockKind?
    /// Metadatos del bloque WOD de origen (EMOM, AMRAP…).
    public var wodFormat: WODFormat?
    public var blockTimeCapMinutes: Int?
    public var blockIntervalSeconds: Int?
    public var blockRounds: Int?
    public var blockHeader: String?
    public var blockWorkSeconds: Int?
    public var blockRestSeconds: Int?
    /// Descanso explícito entre rondas de un circuito.
    public var blockRestBetweenRoundsSeconds: Int?

    public init(
        id: UUID = UUID(),
        exercise: Exercise,
        plannedSets: [PlannedSet],
        quantityUnit: ExerciseQuantityUnit? = nil,
        loggedSets: [LoggedSet] = [],
        restSeconds: Int? = nil,
        completedReps: Int = 0,
        adaptedReps: Int? = nil,
        adaptedWeightKg: Double? = nil,
        isCompleted: Bool = false,
        supersetGroup: Int? = nil,
        blockId: UUID? = nil,
        blockKind: RoutineBlockKind? = nil,
        wodFormat: WODFormat? = nil,
        blockTimeCapMinutes: Int? = nil,
        blockIntervalSeconds: Int? = nil,
        blockRounds: Int? = nil,
        blockHeader: String? = nil,
        blockWorkSeconds: Int? = nil,
        blockRestSeconds: Int? = nil,
        blockRestBetweenRoundsSeconds: Int? = nil
    ) {
        self.id = id
        self.exercise = exercise
        self.plannedSets = plannedSets
        self.quantityUnit = quantityUnit
        self.loggedSets = loggedSets
        self.restSeconds = restSeconds
        self.completedReps = completedReps
        self.adaptedReps = adaptedReps
        self.adaptedWeightKg = adaptedWeightKg
        self.isCompleted = isCompleted
        self.supersetGroup = supersetGroup
        self.blockId = blockId
        self.blockKind = blockKind
        self.wodFormat = wodFormat
        self.blockTimeCapMinutes = blockTimeCapMinutes
        self.blockIntervalSeconds = blockIntervalSeconds
        self.blockRounds = blockRounds
        self.blockHeader = blockHeader
        self.blockWorkSeconds = blockWorkSeconds
        self.blockRestSeconds = blockRestSeconds
        self.blockRestBetweenRoundsSeconds = blockRestBetweenRoundsSeconds
    }

    /// Prescription to prefill the NEXT editable work set on iPhone/Watch.
    /// Warmups and unconfirmed draft values never consume prescribed work.
    /// Once a prescription is exhausted, reuse its last target as guidance
    /// without fabricating additional completed sets.
    public var nextWorkSetPrescription: PlannedSet? {
        let recordedWorkSets = loggedSets.filter { $0.phase == .work }.count
        return plannedSets.dropFirst(recordedWorkSets).first ?? plannedSets.last
    }

    /// Se puede anotar lo realizado incluso si coincide con lo prescrito.
    public var hasRecordedWODExecution: Bool {
        adaptedReps != nil || adaptedWeightKg != nil
    }

    /// «Scaled» solo cuando la ejecución difiere realmente de la prescripción
    /// corregida. Así, al editar el peso original, la nota se recalcula sobre
    /// la nueva referencia sin etiquetar erróneamente como adaptado un Rx.
    public var hasWODScaling: Bool {
        if let adaptedReps, adaptedReps != plannedSets.first?.targetReps {
            return true
        }
        if let adaptedWeightKg {
            guard let rxKg = plannedSets.first?.targetWeightKg else { return true }
            if abs(adaptedWeightKg - rxKg) >= 0.05 { return true }
        }
        return false
    }

    public var adjustedSummaryLine: String? {
        guard hasRecordedWODExecution else { return nil }
        var values: [String] = []
        if let adaptedReps { values.append("\(adaptedReps) reps") }
        if let adaptedWeightKg {
            values.append("\(adaptedWeightKg.formatted(.number.precision(.fractionLength(0...1)))) kg")
        }
        return (hasWODScaling ? "Adaptado · " : "Realizado · ") + values.joined(separator: " · ")
    }

    public var lastLoggedWeight: Double? {
        loggedSets.last?.weightKg ?? plannedSets.first?.targetWeightKg
    }

    /// Intervalos de reloj (EMOM 12' → 12; EVERY 2'×4 → 4). Preferir timeCap, no `blockRounds` (vueltas).
    public var plannedIntervals: Int? {
        guard let format = wodFormat else { return nil }
        switch format {
        case .emom:
            let interval = max(1, blockIntervalSeconds ?? 60)
            if let cap = blockTimeCapMinutes, cap > 0 {
                return max(1, (cap * 60) / interval)
            }
            if let blockRounds, blockRounds > 0 { return blockRounds }
            return nil
        case .circuit:
            let interval = max(1, blockIntervalSeconds ?? 60)
            if let cap = blockTimeCapMinutes, cap > 0 {
                return max(1, (cap * 60) / interval)
            }
            return blockRounds
        case .amrap, .forTime, .afap, .chipper, .ladder, .tabata, .deathBy,
             .partner, .buyInCashOut, .roundsForQuality, .maxEffort, .strength:
            return blockRounds
        }
    }

    /// Cabecera de bloque regenerada desde el formato (evita cabeceras viejas tipo EMOM en un AMRAP).
    public var displayBlockHeader: String {
        if blockKind == .strength || wodFormat == nil || wodFormat == .strength {
            return blockHeader ?? "Fuerza"
        }
        guard let format = wodFormat else {
            return blockHeader ?? "WOD"
        }
        switch format {
        case .amrap:
            return "AMRAP \(blockTimeCapMinutes ?? 12)'"
        case .emom:
            let mins = blockTimeCapMinutes ?? plannedIntervals ?? blockRounds ?? 10
            let interval = blockIntervalSeconds ?? 60
            if interval != 60 {
                let every = max(1, interval / 60)
                if let rounds = blockRounds ?? plannedIntervals {
                    return "Every \(every)' × \(rounds)"
                }
                return "Every \(every)'"
            }
            return "EMOM \(mins)'"
        case .forTime:
            if let rounds = blockRounds {
                return "\(rounds) RFT (TC \(blockTimeCapMinutes ?? 12)')"
            }
            return "For Time (TC \(blockTimeCapMinutes ?? 12)')"
        case .tabata:
            return "Tabata \(blockWorkSeconds ?? 20)/\(blockRestSeconds ?? 10) ×\(blockRounds ?? 8)"
        case .chipper:
            return "Chipper"
        case .deathBy:
            return "Muerte por"
        case .afap:
            return "AFAP"
        case .ladder:
            return blockHeader?.isEmpty == false ? blockHeader! : "Ladder"
        case .partner:
            return "Partner"
        case .buyInCashOut:
            return blockHeader?.isEmpty == false ? blockHeader! : "Buy-in / Cash-out"
        case .roundsForQuality:
            if let rounds = blockRounds { return "\(rounds) RFQ" }
            return "Rounds for Quality"
        case .circuit:
            return "Circuito"
        case .maxEffort:
            return "Max effort"
        case .strength:
            return blockHeader ?? "Fuerza"
        }
    }

    /// El score del bloque vive en `WorkoutSession.wodResults` (AMRAP / For Time…), no en series por movimiento.
    public var usesBlockScoreResult: Bool {
        switch wodFormat?.resultCapture {
        case .totalReps, .elapsedTime: return true
        default: return false
        }
    }

    /// Línea de prescripción (p. ej. `21 reps`, `15 cal`) para listar movimientos de un WOD con score.
    public var prescriptionSummaryLine: String {
        if let first = plannedSets.first {
            let reps = first.targetReps
            if let kg = first.targetWeightKg, kg > 0 {
                return "\(reps) @ \(kg.formatted(.number.precision(.fractionLength(0...1)))) kg"
            }
            if reps > 0 { return "\(reps) reps" }
        }
        return exercise.name
    }

    /// Etiqueta de tiempo/estructura para la cola (EMOM 8', 4×8, TC 12'…).
    public var queueTimeLabel: String {
        let sets = plannedSets.count
        let reps = plannedSets.first?.targetReps ?? 0
        let setsReps = sets > 0 ? "\(sets)×\(reps)" : nil

        if blockKind == .strength || wodFormat == nil || wodFormat == .strength {
            if let setsReps, let cap = blockTimeCapMinutes { return "\(setsReps) · \(cap)'" }
            return setsReps ?? (blockTimeCapMinutes.map { "\($0)'" } ?? "—")
        }
        return displayBlockHeader
    }

    enum CodingKeys: String, CodingKey {
        case id, exercise, plannedSets, quantityUnit, loggedSets, restSeconds, completedReps, isCompleted, supersetGroup
        case adaptedReps, adaptedWeightKg
        case blockId, blockKind
        case wodFormat, blockTimeCapMinutes, blockIntervalSeconds, blockRounds, blockHeader
        case blockWorkSeconds, blockRestSeconds, blockRestBetweenRoundsSeconds
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        exercise = try c.decode(Exercise.self, forKey: .exercise)
        plannedSets = try c.decodeIfPresent([PlannedSet].self, forKey: .plannedSets) ?? []
        quantityUnit = try c.decodeIfPresent(ExerciseQuantityUnit.self, forKey: .quantityUnit)
        restSeconds = try c.decodeIfPresent(Int.self, forKey: .restSeconds)
        loggedSets = try c.decodeIfPresent([LoggedSet].self, forKey: .loggedSets) ?? []
        completedReps = try c.decodeIfPresent(Int.self, forKey: .completedReps) ?? 0
        adaptedReps = try c.decodeIfPresent(Int.self, forKey: .adaptedReps)
        adaptedWeightKg = try c.decodeIfPresent(Double.self, forKey: .adaptedWeightKg)
        isCompleted = try c.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        supersetGroup = nil // Compatibilidad de lectura, sin restaurar agrupaciones.
        blockId = try c.decodeIfPresent(UUID.self, forKey: .blockId)
        blockKind = try c.decodeIfPresent(RoutineBlockKind.self, forKey: .blockKind)
        wodFormat = try c.decodeIfPresent(WODFormat.self, forKey: .wodFormat)
        blockTimeCapMinutes = try c.decodeIfPresent(Int.self, forKey: .blockTimeCapMinutes)
        blockIntervalSeconds = try c.decodeIfPresent(Int.self, forKey: .blockIntervalSeconds)
        blockRounds = try c.decodeIfPresent(Int.self, forKey: .blockRounds)
        blockHeader = try c.decodeIfPresent(String.self, forKey: .blockHeader)
        blockWorkSeconds = try c.decodeIfPresent(Int.self, forKey: .blockWorkSeconds)
        blockRestSeconds = try c.decodeIfPresent(Int.self, forKey: .blockRestSeconds)
        blockRestBetweenRoundsSeconds = try c.decodeIfPresent(Int.self, forKey: .blockRestBetweenRoundsSeconds)
    }
}

public enum SessionPhase: String, Codable, Sendable, Equatable {
    case idle
    case ready
    case counting
    case finished
}

/// Pin de ubicación de un entreno (gimnasio / punto de inicio).
public struct WorkoutLocationPin: Codable, Sendable, Equatable {
    public var latitude: Double
    public var longitude: Double
    public var recordedAt: Date
    /// Nombre del sitio (Apple Maps / MapKit), si se eligió a mano.
    public var name: String?
    /// `MKMapItem.Identifier` raw value para reconstruir el marcador nativo.
    public var mapItemIdentifier: String?
    /// `MKPointOfInterestCategory.rawValue` para el glyph de Mapas.
    public var pointOfInterestCategory: String?

    public init(
        latitude: Double,
        longitude: Double,
        recordedAt: Date = Date(),
        name: String? = nil,
        mapItemIdentifier: String? = nil,
        pointOfInterestCategory: String? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.recordedAt = recordedAt
        self.name = name
        self.mapItemIdentifier = mapItemIdentifier
        self.pointOfInterestCategory = pointOfInterestCategory
    }
}

/// Punto de ruta GPS grabado por Repera (outdoor).
public struct WorkoutRoutePoint: Codable, Sendable, Equatable, Identifiable {
    public var id: Int
    public var latitude: Double
    public var longitude: Double
    public var recordedAt: Date
    /// m/s (≥ 0). Nil si no se pudo estimar.
    public var speedMps: Double?
    /// Altitud GPS validada, en metros sobre el nivel del mar; optional para rutas antiguas.
    public var altitudeMeters: Double?

    public init(
        id: Int,
        latitude: Double,
        longitude: Double,
        recordedAt: Date = Date(),
        speedMps: Double? = nil,
        altitudeMeters: Double? = nil
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.recordedAt = recordedAt
        self.speedMps = speedMps
        self.altitudeMeters = altitudeMeters
    }
}

public struct WorkoutSession: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var title: String
    public var routineId: UUID?
    public var exercises: [SessionExercise]
    public var currentIndex: Int
    public var phase: SessionPhase
    public var startedAt: Date?
    public var finishedAt: Date?
    /// Notas libres del entreno (cómo te sentiste, sueño, etc.).
    public var notes: String?
    /// Calorías según Apple Salud / Watch (fuente de verdad).
    public var appleActiveEnergyKcal: Double?
    /// FC media únicamente desde los sensores de HealthKit (no estimada por Repera).
    public var appleAverageHeartRateBpm: Double?
    /// Procedencia verificable de métricas obtenidas al guardar un HKWorkout.
    /// nil en sesiones históricas sin prueba de origen.
    public var appleHealthProvenance: String?
    /// Duración según Apple Salud / Watch (segundos).
    public var appleDurationSeconds: TimeInterval?
    /// UUID del `HKWorkout` guardado en Salud (si aplica).
    public var healthKitWorkoutUUID: UUID?
    /// Scores de bloques WOD (AMRAP reps, For Time tiempo…).
    public var wodResults: [WODBlockResult]
    /// Snapshot de la estructura ejecutada (incluye descansos WOD y orden),
    /// independiente de cambios posteriores en la plantilla.
    public var routineBlocks: [RoutineBlock]?
    /// Valoración post-entreno (histórico + bandas de catálogo).
    public var sessionReview: SessionReview?
    /// Ubicación al empezar (pin del gym / sitio).
    public var locationPin: WorkoutLocationPin?
    /// Ruta GPS propia (outdoor); independiente de la ruta de Salud.
    public var routePoints: [WorkoutRoutePoint]

    public init(
        id: UUID = UUID(),
        title: String,
        routineId: UUID? = nil,
        exercises: [SessionExercise],
        currentIndex: Int = 0,
        phase: SessionPhase = .idle,
        startedAt: Date? = nil,
        finishedAt: Date? = nil,
        notes: String? = nil,
        appleActiveEnergyKcal: Double? = nil,
        appleAverageHeartRateBpm: Double? = nil,
        appleHealthProvenance: String? = nil,
        appleDurationSeconds: TimeInterval? = nil,
        healthKitWorkoutUUID: UUID? = nil,
        wodResults: [WODBlockResult] = [],
        routineBlocks: [RoutineBlock]? = nil,
        sessionReview: SessionReview? = nil,
        locationPin: WorkoutLocationPin? = nil,
        routePoints: [WorkoutRoutePoint] = []
    ) {
        self.id = id
        self.title = title
        self.routineId = routineId
        self.exercises = exercises
        self.currentIndex = currentIndex
        self.phase = phase
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.notes = notes
        self.appleActiveEnergyKcal = appleActiveEnergyKcal
        self.appleAverageHeartRateBpm = appleAverageHeartRateBpm
        self.appleHealthProvenance = appleHealthProvenance
        self.appleDurationSeconds = appleDurationSeconds
        self.healthKitWorkoutUUID = healthKitWorkoutUUID
        self.wodResults = wodResults
        self.routineBlocks = routineBlocks
        self.sessionReview = sessionReview
        self.locationPin = locationPin
        self.routePoints = routePoints
    }

    enum CodingKeys: String, CodingKey {
        case id, title, routineId, exercises, currentIndex, phase
        case startedAt, finishedAt, notes
        case appleActiveEnergyKcal, appleAverageHeartRateBpm, appleHealthProvenance, appleDurationSeconds, healthKitWorkoutUUID
        case wodResults, routineBlocks, sessionReview
        case locationPin, routePoints
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        routineId = try c.decodeIfPresent(UUID.self, forKey: .routineId)
        exercises = try c.decode([SessionExercise].self, forKey: .exercises)
        currentIndex = try c.decodeIfPresent(Int.self, forKey: .currentIndex) ?? 0
        phase = try c.decodeIfPresent(SessionPhase.self, forKey: .phase) ?? .idle
        startedAt = try c.decodeIfPresent(Date.self, forKey: .startedAt)
        finishedAt = try c.decodeIfPresent(Date.self, forKey: .finishedAt)
        notes = try c.decodeIfPresent(String.self, forKey: .notes)
        appleActiveEnergyKcal = try c.decodeIfPresent(Double.self, forKey: .appleActiveEnergyKcal)
        appleAverageHeartRateBpm = try c.decodeIfPresent(Double.self, forKey: .appleAverageHeartRateBpm)
        appleHealthProvenance = try c.decodeIfPresent(String.self, forKey: .appleHealthProvenance)
        appleDurationSeconds = try c.decodeIfPresent(TimeInterval.self, forKey: .appleDurationSeconds)
        healthKitWorkoutUUID = try c.decodeIfPresent(UUID.self, forKey: .healthKitWorkoutUUID)
        wodResults = try c.decodeIfPresent([WODBlockResult].self, forKey: .wodResults) ?? []
        routineBlocks = try c.decodeIfPresent([RoutineBlock].self, forKey: .routineBlocks)
        sessionReview = try c.decodeIfPresent(SessionReview.self, forKey: .sessionReview)
        locationPin = try c.decodeIfPresent(WorkoutLocationPin.self, forKey: .locationPin)
        routePoints = try c.decodeIfPresent([WorkoutRoutePoint].self, forKey: .routePoints) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encodeIfPresent(routineId, forKey: .routineId)
        try c.encode(exercises, forKey: .exercises)
        try c.encode(currentIndex, forKey: .currentIndex)
        try c.encode(phase, forKey: .phase)
        try c.encodeIfPresent(startedAt, forKey: .startedAt)
        try c.encodeIfPresent(finishedAt, forKey: .finishedAt)
        try c.encodeIfPresent(notes, forKey: .notes)
        try c.encodeIfPresent(appleActiveEnergyKcal, forKey: .appleActiveEnergyKcal)
        try c.encodeIfPresent(appleAverageHeartRateBpm, forKey: .appleAverageHeartRateBpm)
        try c.encodeIfPresent(appleHealthProvenance, forKey: .appleHealthProvenance)
        try c.encodeIfPresent(appleDurationSeconds, forKey: .appleDurationSeconds)
        try c.encodeIfPresent(healthKitWorkoutUUID, forKey: .healthKitWorkoutUUID)
        try c.encode(wodResults, forKey: .wodResults)
        try c.encodeIfPresent(routineBlocks, forKey: .routineBlocks)
        try c.encodeIfPresent(sessionReview, forKey: .sessionReview)
        try c.encodeIfPresent(locationPin, forKey: .locationPin)
        try c.encode(routePoints, forKey: .routePoints)
    }

    public var currentExercise: SessionExercise? {
        guard exercises.indices.contains(currentIndex) else { return nil }
        return exercises[currentIndex]
    }

    public var progressLabel: String {
        guard !exercises.isEmpty else { return "0/0" }
        return "\(min(currentIndex + 1, exercises.count))/\(exercises.count)"
    }

    public var totalVolumeKg: Double {
        exercises.reduce(0) { partial, ex in
            partial + ex.loggedSets.reduce(0) { $0 + $1.volumeKg }
        }
    }

    /// Minutos del entreno: prioriza Apple Salud / Watch.
    public var durationMinutes: Double {
        if let apple = appleDurationSeconds, apple > 0 {
            return apple / 60
        }
        guard let start = startedAt else { return 0 }
        let end = finishedAt ?? Date()
        return max(0, end.timeIntervalSince(start) / 60)
    }

    /// Minutos del chip en listas (Inicio / Historial): reloj de pared inicio→fin.
    /// No usa el time-cap ni la duración de Salud (esos van a kcal / detalle).
    public var displayDurationMinutes: Double {
        if let start = startedAt {
            let end = finishedAt ?? start.addingTimeInterval(60)
            let wall = max(0, end.timeIntervalSince(start) / 60)
            if wall > 0 { return wall }
        }
        return durationMinutes
    }
}

/// Origen del valor de peso corporal.
public enum BodyWeightSource: String, Codable, Sendable, Hashable {
    case manual
    case health

    public var displayName: String {
        switch self {
        case .manual: return "Propio"
        case .health: return "Salud"
        }
    }
}

public struct BodyWeightEntry: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var date: Date
    public var weightKg: Double
    /// `.manual` = apuntado en Repera; `.health` = importado de Apple Salud.
    public var source: BodyWeightSource

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        weightKg: Double,
        source: BodyWeightSource = .manual
    ) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
        self.source = source
    }

    private enum CodingKeys: String, CodingKey {
        case id, date, weightKg, source
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        date = try c.decode(Date.self, forKey: .date)
        weightKg = try c.decode(Double.self, forKey: .weightKg)
        source = try c.decodeIfPresent(BodyWeightSource.self, forKey: .source) ?? .manual
    }
}

public struct PersonalRecord: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var exerciseId: UUID
    public var exerciseName: String
    public var weightKg: Double
    public var reps: Int
    public var date: Date

    public init(
        id: UUID = UUID(),
        exerciseId: UUID,
        exerciseName: String,
        weightKg: Double,
        reps: Int,
        date: Date
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.weightKg = weightKg
        self.reps = reps
        self.date = date
    }

    public var estimatedOneRM: Double {
        PlateMath.epleyOneRM(weightKg: weightKg, reps: reps)
    }
}

/// Temporizador guardado en favoritos (configuración reutilizable).
public struct FavoriteTimer: Identifiable, Codable, Sendable, Hashable, Equatable {
    public let id: UUID
    public var title: String
    /// `up` | `down` | `intervals`
    public var modeRaw: String
    public var durationMinutes: Int
    public var durationSeconds: Int
    public var rounds: Int
    public var workMinutes: Int
    public var workSeconds: Int
    public var restMinutes: Int
    public var restSeconds: Int
    public var countdownBeforeStart: Bool

    public init(
        id: UUID = UUID(),
        title: String,
        modeRaw: String,
        durationMinutes: Int = 40,
        durationSeconds: Int = 0,
        rounds: Int = 5,
        workMinutes: Int = 1,
        workSeconds: Int = 30,
        restMinutes: Int = 0,
        restSeconds: Int = 0,
        countdownBeforeStart: Bool = true
    ) {
        self.id = id
        self.title = title
        self.modeRaw = modeRaw
        self.durationMinutes = durationMinutes
        self.durationSeconds = durationSeconds
        self.rounds = rounds
        self.workMinutes = workMinutes
        self.workSeconds = workSeconds
        self.restMinutes = restMinutes
        self.restSeconds = restSeconds
        self.countdownBeforeStart = countdownBeforeStart
    }
}

public struct AppState: Codable, Sendable, Equatable {
    public var settings: AppSettings
    public var exercises: [Exercise]
    public var routines: [Routine]
    public var workouts: [WorkoutSession]
    public var bodyWeights: [BodyWeightEntry]
    public var activeSession: WorkoutSession?
    public var rotation: RotationPlan?
    public var favoriteTimers: [FavoriteTimer]
    /// Preferencias de carga de discos por ejercicio (`exerciseId.uuidString`).
    public var exerciseLoadPrefs: [String: ExerciseLoadPreference]
    /// Wall-clock stamp for display / coarse ordering.
    public var updatedAt: Date
    /// Monotonic per-writer revision for conflict resolution (preferred over `updatedAt` alone).
    public var syncRevision: Int
    /// Stable device/install id of the last successful persist writer.
    public var lastWriterDeviceId: String

    public init(
        settings: AppSettings = AppSettings(),
        exercises: [Exercise] = Catalog.seed(),
        routines: [Routine] = [],
        workouts: [WorkoutSession] = [],
        bodyWeights: [BodyWeightEntry] = [],
        activeSession: WorkoutSession? = nil,
        rotation: RotationPlan? = nil,
        favoriteTimers: [FavoriteTimer] = [],
        exerciseLoadPrefs: [String: ExerciseLoadPreference] = [:],
        updatedAt: Date = Date(),
        syncRevision: Int = 0,
        lastWriterDeviceId: String = ""
    ) {
        self.settings = settings
        self.exercises = exercises
        self.routines = routines
        self.workouts = workouts
        self.bodyWeights = bodyWeights
        self.activeSession = activeSession
        self.rotation = rotation
        self.favoriteTimers = favoriteTimers
        self.exerciseLoadPrefs = exerciseLoadPrefs
        self.updatedAt = updatedAt
        self.syncRevision = syncRevision
        self.lastWriterDeviceId = lastWriterDeviceId
    }

    enum CodingKeys: String, CodingKey {
        case settings, exercises, routines, workouts, bodyWeights, activeSession, rotation, favoriteTimers
        case exerciseLoadPrefs, updatedAt, syncRevision, lastWriterDeviceId
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        settings = try c.decodeIfPresent(AppSettings.self, forKey: .settings) ?? AppSettings()
        exercises = try c.decodeIfPresent([Exercise].self, forKey: .exercises) ?? Catalog.seed()
        routines = try c.decodeIfPresent([Routine].self, forKey: .routines) ?? []
        workouts = try c.decodeIfPresent([WorkoutSession].self, forKey: .workouts) ?? []
        bodyWeights = try c.decodeIfPresent([BodyWeightEntry].self, forKey: .bodyWeights) ?? []
        activeSession = try c.decodeIfPresent(WorkoutSession.self, forKey: .activeSession)
        rotation = try c.decodeIfPresent(RotationPlan.self, forKey: .rotation)
        favoriteTimers = try c.decodeIfPresent([FavoriteTimer].self, forKey: .favoriteTimers) ?? []
        exerciseLoadPrefs = try c.decodeIfPresent([String: ExerciseLoadPreference].self, forKey: .exerciseLoadPrefs) ?? [:]
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? .distantPast
        syncRevision = try c.decodeIfPresent(Int.self, forKey: .syncRevision) ?? 0
        lastWriterDeviceId = try c.decodeIfPresent(String.self, forKey: .lastWriterDeviceId) ?? ""
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(settings, forKey: .settings)
        try c.encode(exercises, forKey: .exercises)
        try c.encode(routines, forKey: .routines)
        try c.encode(workouts, forKey: .workouts)
        try c.encode(bodyWeights, forKey: .bodyWeights)
        try c.encodeIfPresent(activeSession, forKey: .activeSession)
        try c.encodeIfPresent(rotation, forKey: .rotation)
        try c.encode(favoriteTimers, forKey: .favoriteTimers)
        try c.encode(exerciseLoadPrefs, forKey: .exerciseLoadPrefs)
        try c.encode(updatedAt, forKey: .updatedAt)
        try c.encode(syncRevision, forKey: .syncRevision)
        try c.encode(lastWriterDeviceId, forKey: .lastWriterDeviceId)
    }
}
