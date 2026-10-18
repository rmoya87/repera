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

    public init(
        weightUnit: WeightUnit = .kg,
        weekStartsOn: WeekStart = .monday,
        defaultRestSeconds: Int = 90,
        bodyWeightGoalKg: Double? = nil,
        defaultProgression: ProgressionPolicy = .linear,
        weightIncrementKg: Double = 2.5,
        barbellKg: Double = PlateMath.defaultBarKg,
        ownedPlatesKg: [Double] = PlateMath.defaultPlatesKg,
        effortUnit: EffortUnit = .rir,
        scheduleMode: ScheduleMode = .fixedWeek,
        restSoundEnabled: Bool = true,
        restHapticEnabled: Bool = true,
        profileAvatarJPEG: Data? = nil,
        profileDisplayName: String? = nil
    ) {
        self.weightUnit = weightUnit
        self.weekStartsOn = weekStartsOn
        self.defaultRestSeconds = defaultRestSeconds
        self.bodyWeightGoalKg = bodyWeightGoalKg
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
    }

    enum CodingKeys: String, CodingKey {
        case weightUnit, weekStartsOn, defaultRestSeconds, bodyWeightGoalKg
        case defaultProgression, weightIncrementKg, barbellKg, ownedPlatesKg, effortUnit
        case scheduleMode, restSoundEnabled, restHapticEnabled
        case profileAvatarJPEG, profileDisplayName
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        weightUnit = try c.decodeIfPresent(WeightUnit.self, forKey: .weightUnit) ?? .kg
        weekStartsOn = try c.decodeIfPresent(WeekStart.self, forKey: .weekStartsOn) ?? .monday
        defaultRestSeconds = try c.decodeIfPresent(Int.self, forKey: .defaultRestSeconds) ?? 90
        bodyWeightGoalKg = try c.decodeIfPresent(Double.self, forKey: .bodyWeightGoalKg)
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
    }
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
    /// Origen deportivo (CrossFit, Halterofilia, Gimnasia). Independiente del grupo muscular.
    public var sportTag: String?

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
    public var targetWeightKg: Double?
    /// Objetivo de RIR para esta serie (nil = sin definir).
    public var targetRir: Double?

    public init(
        id: UUID = UUID(),
        targetReps: Int,
        targetWeightKg: Double? = nil,
        targetRir: Double? = nil
    ) {
        self.id = id
        self.targetReps = targetReps
        self.targetWeightKg = targetWeightKg
        self.targetRir = targetRir
    }

    enum CodingKeys: String, CodingKey {
        case id, targetReps, targetWeightKg, targetRir
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        targetReps = try c.decode(Int.self, forKey: .targetReps)
        targetWeightKg = try c.decodeIfPresent(Double.self, forKey: .targetWeightKg)
        targetRir = try c.decodeIfPresent(Double.self, forKey: .targetRir)
    }

    /// Copia con nuevo `id` (para insertar en otra rutina).
    public func duplicatingContent() -> PlannedSet {
        PlannedSet(targetReps: targetReps, targetWeightKg: targetWeightKg, targetRir: targetRir)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(targetReps, forKey: .targetReps)
        try c.encodeIfPresent(targetWeightKg, forKey: .targetWeightKg)
        try c.encodeIfPresent(targetRir, forKey: .targetRir)
    }
}

extension [PlannedSet] {
    /// Resumen compacto para listas: `3×8 · 60 kg`, `2×3, 2×1 · 150 kg`, `3 @ 100, 2 @ 110`.
    public var compactSummary: String {
        guard !isEmpty else { return "—" }
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
    public var reps: Int
    public var weightKg: Double?
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
        let main = Double(reps) * (weightKg ?? 0)
        // Drops add volume; rest-pause clusters are a breakdown of `reps` (no double count).
        let extra = drops.reduce(0.0) { $0 + Double($1.reps) * ($1.weightKg ?? 0) }
        return main + extra
    }

    enum CodingKeys: String, CodingKey {
        case id, reps, weightKg, completedAt, phase, kind, rir, toFailure, drops, clusters
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        reps = try c.decode(Int.self, forKey: .reps)
        weightKg = try c.decodeIfPresent(Double.self, forKey: .weightKg)
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
    public var restSeconds: Int?
    /// Same non-nil value = same superseries.
    public var supersetGroup: Int?

    public init(
        id: UUID = UUID(),
        exerciseId: UUID,
        plannedSets: [PlannedSet],
        restSeconds: Int? = nil,
        supersetGroup: Int? = nil
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.plannedSets = plannedSets
        self.restSeconds = restSeconds
        self.supersetGroup = supersetGroup
    }

    enum CodingKeys: String, CodingKey {
        case id, exerciseId, plannedSets, restSeconds, supersetGroup
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        exerciseId = try c.decode(UUID.self, forKey: .exerciseId)
        plannedSets = try c.decodeIfPresent([PlannedSet].self, forKey: .plannedSets) ?? []
        restSeconds = try c.decodeIfPresent(Int.self, forKey: .restSeconds)
        supersetGroup = try c.decodeIfPresent(Int.self, forKey: .supersetGroup)
    }

    /// Copia con nuevos IDs de ejercicio y series.
    public func duplicatingContent() -> RoutineExercise {
        RoutineExercise(
            exerciseId: exerciseId,
            plannedSets: plannedSets.map { $0.duplicatingContent() },
            restSeconds: restSeconds,
            supersetGroup: supersetGroup
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
    /// Fuerza / skill / técnica / superseries (series×reps).
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
        case .strength: return "Bloque de fuerza/técnica: 5×5, 3×8 @RPE, superseries, skill."
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
        case .strength: return ["STRENGTH", "SKILL", "TECH", "5x5 BACK SQUAT", "SUPERSET"]
        case .afap: return ["AFAP", "AS FAST AS POSSIBLE"]
        case .ladder: return ["21-15-9", "ASCENDING LADDER", "DESCENDING LADDER 10→1"]
        case .partner: return ["PARTNER WOD", "YOU GO I GO", "YGIG"]
        case .buyInCashOut: return ["BUY-IN: 500m ROW", "CASH OUT: 50 DU"]
        case .roundsForQuality: return ["3 ROUNDS FOR QUALITY", "RFQ"]
        case .circuit: return ["CIRCUIT", "5 STATIONS", "ROTATION"]
        case .maxEffort: return ["FIND A HEAVY", "MAX REPS 2'", "MAX LOAD"]
        }
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

    /// Series planificadas: esquema 4-3-3-2 o una serie con `reps` (rangos 5-10 → reps altas).
    public var plannedSetsFromReps: [PlannedSet] {
        let weight = weightMaleKg
        if let scheme = repScheme, !scheme.isEmpty, !isAscendingRepRange {
            return scheme.map { PlannedSet(targetReps: max(1, $0), targetWeightKg: weight) }
        }
        let r: Int
        if let scheme = repScheme, isAscendingRepRange {
            r = scheme[1] // techo del rango (5-10 → 10)
        } else {
            r = reps ?? (distanceMeters.map { max(1, $0 / 10) } ?? 10)
        }
        return [PlannedSet(targetReps: max(1, r), targetWeightKg: weight)]
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
        wodNotes: String? = nil
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
    }

    enum CodingKeys: String, CodingKey {
        case id, title, kind, exercises, movements, wodFormat, timeCapMinutes
        case emomIntervalSeconds, rounds, workSeconds, restSeconds
        case restBetweenRoundsSeconds, wodNotes
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
    }

    public static func strength(title: String = "Bloque", exercises: [RoutineExercise] = []) -> RoutineBlock {
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
            wodNotes: wodNotes
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
            rounds: isTabata ? 8 : (format == .forTime ? 4 : nil),
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
            let n = max(1, rounds ?? 8)
            return movement.repeatingPlannedSets(count: n)
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
    public var loggedSets: [LoggedSet]
    public var completedReps: Int
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

    public init(
        id: UUID = UUID(),
        exercise: Exercise,
        plannedSets: [PlannedSet],
        loggedSets: [LoggedSet] = [],
        completedReps: Int = 0,
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
        blockRestSeconds: Int? = nil
    ) {
        self.id = id
        self.exercise = exercise
        self.plannedSets = plannedSets
        self.loggedSets = loggedSets
        self.completedReps = completedReps
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

    /// Etiqueta de tiempo/estructura para la cola (EMOM 8', 4×8, TC 12'…).
    public var queueTimeLabel: String {
        let sets = plannedSets.count
        let reps = plannedSets.first?.targetReps ?? 0
        let setsReps = sets > 0 ? "\(sets)×\(reps)" : nil

        if blockKind == .strength || wodFormat == nil || wodFormat == .strength {
            if let setsReps, let cap = blockTimeCapMinutes { return "\(setsReps) · \(cap)'" }
            return setsReps ?? (blockTimeCapMinutes.map { "\($0)'" } ?? "—")
        }
        if let header = blockHeader, !header.isEmpty { return header }
        if let format = wodFormat {
            switch format {
            case .emom:
                let mins = blockTimeCapMinutes ?? plannedIntervals ?? blockRounds ?? 10
                let interval = blockIntervalSeconds ?? 60
                return interval == 60 ? "EMOM \(mins)'" : "Every \(interval)s"
            case .amrap:
                return "AMRAP \(blockTimeCapMinutes ?? 12)'"
            case .tabata:
                let w = blockWorkSeconds ?? 20
                let r = blockRestSeconds ?? 10
                return "Tabata \(w)/\(r)"
            case .forTime, .chipper, .afap, .deathBy, .ladder, .partner,
                 .buyInCashOut, .roundsForQuality, .circuit, .maxEffort, .strength:
                if let cap = blockTimeCapMinutes { return "TC \(cap)'" }
                if let rounds = blockRounds { return "\(rounds) rondas" }
                return format.displayName
            }
        }
        return setsReps ?? "—"
    }

    enum CodingKeys: String, CodingKey {
        case id, exercise, plannedSets, loggedSets, completedReps, isCompleted, supersetGroup
        case blockId, blockKind
        case wodFormat, blockTimeCapMinutes, blockIntervalSeconds, blockRounds, blockHeader
        case blockWorkSeconds, blockRestSeconds
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        exercise = try c.decode(Exercise.self, forKey: .exercise)
        plannedSets = try c.decodeIfPresent([PlannedSet].self, forKey: .plannedSets) ?? []
        loggedSets = try c.decodeIfPresent([LoggedSet].self, forKey: .loggedSets) ?? []
        completedReps = try c.decodeIfPresent(Int.self, forKey: .completedReps) ?? 0
        isCompleted = try c.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        supersetGroup = try c.decodeIfPresent(Int.self, forKey: .supersetGroup)
        blockId = try c.decodeIfPresent(UUID.self, forKey: .blockId)
        blockKind = try c.decodeIfPresent(RoutineBlockKind.self, forKey: .blockKind)
        wodFormat = try c.decodeIfPresent(WODFormat.self, forKey: .wodFormat)
        blockTimeCapMinutes = try c.decodeIfPresent(Int.self, forKey: .blockTimeCapMinutes)
        blockIntervalSeconds = try c.decodeIfPresent(Int.self, forKey: .blockIntervalSeconds)
        blockRounds = try c.decodeIfPresent(Int.self, forKey: .blockRounds)
        blockHeader = try c.decodeIfPresent(String.self, forKey: .blockHeader)
        blockWorkSeconds = try c.decodeIfPresent(Int.self, forKey: .blockWorkSeconds)
        blockRestSeconds = try c.decodeIfPresent(Int.self, forKey: .blockRestSeconds)
    }
}

public enum SessionPhase: String, Codable, Sendable, Equatable {
    case idle
    case ready
    case counting
    case finished
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
    /// Duración según Apple Salud / Watch (segundos).
    public var appleDurationSeconds: TimeInterval?
    /// UUID del `HKWorkout` guardado en Salud (si aplica).
    public var healthKitWorkoutUUID: UUID?

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
        appleDurationSeconds: TimeInterval? = nil,
        healthKitWorkoutUUID: UUID? = nil
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
        self.appleDurationSeconds = appleDurationSeconds
        self.healthKitWorkoutUUID = healthKitWorkoutUUID
    }

    enum CodingKeys: String, CodingKey {
        case id, title, routineId, exercises, currentIndex, phase
        case startedAt, finishedAt, notes
        case appleActiveEnergyKcal, appleDurationSeconds, healthKitWorkoutUUID
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
        appleDurationSeconds = try c.decodeIfPresent(TimeInterval.self, forKey: .appleDurationSeconds)
        healthKitWorkoutUUID = try c.decodeIfPresent(UUID.self, forKey: .healthKitWorkoutUUID)
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
        try c.encodeIfPresent(appleDurationSeconds, forKey: .appleDurationSeconds)
        try c.encodeIfPresent(healthKitWorkoutUUID, forKey: .healthKitWorkoutUUID)
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
}

public struct BodyWeightEntry: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var date: Date
    public var weightKg: Double

    public init(id: UUID = UUID(), date: Date = Date(), weightKg: Double) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
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
