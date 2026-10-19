import Foundation

/// Nivel frente a bandas de referencia (no ranking social).
public enum AthleteLevel: String, Codable, Sendable, Hashable, CaseIterable {
    case beginner
    case intermediate
    case advanced
    case elite

    public var label: String {
        switch self {
        case .beginner: return "Principiante"
        case .intermediate: return "Intermedio"
        case .advanced: return "Avanzado"
        case .elite: return "Élite"
        }
    }
}

public enum MovementVerdict: String, Codable, Sendable, Hashable {
    case good
    case improve
    case caution

    public var label: String {
        switch self {
        case .good: return "Bien"
        case .improve: return "Mejorable"
        case .caution: return "Cuidado"
        }
    }
}

/// Origen de la nota 1–10 (rendimiento, no ranking social).
public enum ScoreBasis: String, Codable, Sendable, Hashable {
    case catalogBands
    case movementPace
    case typicalTime
    case formatHeuristic
    case equivalentHistory
    case sessionEstimate

    public var blurbLabel: String {
        switch self {
        case .catalogBands: return "vs estándar de catálogo"
        case .movementPace: return "vs ritmos de catálogo por movimiento"
        case .typicalTime: return "vs tiempo típico"
        case .formatHeuristic: return "estimación por formato"
        case .equivalentHistory: return "vs historial en movimientos similares"
        case .sessionEstimate: return "estimación de la sesión"
        }
    }
}

/// Bandas de score publicadas para un WOD de catálogo.
/// Tiempo: umbrales máximos (más rápido = mejor). AMRAP: rondas mínimas (más = mejor).
public struct WODScoreBands: Codable, Sendable, Hashable {
    public var eliteMaxSeconds: Int?
    public var advancedMaxSeconds: Int?
    public var intermediateMaxSeconds: Int?
    /// Por encima de esto (más lento) sigue contando como principiante si terminó.
    public var beginnerMaxSeconds: Int?

    public var eliteMinRounds: Double?
    public var advancedMinRounds: Double?
    public var intermediateMinRounds: Double?
    public var beginnerMinRounds: Double?

    public init(
        eliteMaxSeconds: Int? = nil,
        advancedMaxSeconds: Int? = nil,
        intermediateMaxSeconds: Int? = nil,
        beginnerMaxSeconds: Int? = nil,
        eliteMinRounds: Double? = nil,
        advancedMinRounds: Double? = nil,
        intermediateMinRounds: Double? = nil,
        beginnerMinRounds: Double? = nil
    ) {
        self.eliteMaxSeconds = eliteMaxSeconds
        self.advancedMaxSeconds = advancedMaxSeconds
        self.intermediateMaxSeconds = intermediateMaxSeconds
        self.beginnerMaxSeconds = beginnerMaxSeconds
        self.eliteMinRounds = eliteMinRounds
        self.advancedMinRounds = advancedMinRounds
        self.intermediateMinRounds = intermediateMinRounds
        self.beginnerMinRounds = beginnerMinRounds
    }

    public var hasTimeBands: Bool {
        intermediateMaxSeconds != nil || advancedMaxSeconds != nil || eliteMaxSeconds != nil
    }

    public var hasRoundsBands: Bool {
        intermediateMinRounds != nil || advancedMinRounds != nil || eliteMinRounds != nil
    }
}

public struct MovementReview: Identifiable, Codable, Sendable, Hashable {
    public var id: UUID
    public var exerciseId: UUID?
    public var name: String
    public var verdict: MovementVerdict
    public var detail: String
    /// Nombre del ejercicio histórico usado para comparar (si no es el mismo).
    public var comparedToName: String?
    /// current / prior ajustado; nil si no hay historial comparable.
    public var performanceRatio: Double?

    public init(
        id: UUID = UUID(),
        exerciseId: UUID? = nil,
        name: String,
        verdict: MovementVerdict,
        detail: String,
        comparedToName: String? = nil,
        performanceRatio: Double? = nil
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.name = name
        self.verdict = verdict
        self.detail = detail
        self.comparedToName = comparedToName
        self.performanceRatio = performanceRatio
    }
}

/// Informe post-entreno (WOD + movimientos).
public struct SessionReview: Codable, Sendable, Hashable {
    public var overallScore: Int
    public var level: AthleteLevel?
    public var headline: String
    public var vsHistorySummary: String?
    public var vsStandardSummary: String?
    public var keepTips: [String]
    public var improveTips: [String]
    public var movements: [MovementReview]
    public var wodTemplateId: String?
    public var scoreBasis: ScoreBasis?

    public init(
        overallScore: Int,
        level: AthleteLevel? = nil,
        headline: String,
        vsHistorySummary: String? = nil,
        vsStandardSummary: String? = nil,
        keepTips: [String] = [],
        improveTips: [String] = [],
        movements: [MovementReview] = [],
        wodTemplateId: String? = nil,
        scoreBasis: ScoreBasis? = nil
    ) {
        self.overallScore = min(10, max(1, overallScore))
        self.level = level
        self.headline = headline
        self.vsHistorySummary = vsHistorySummary
        self.vsStandardSummary = vsStandardSummary
        self.keepTips = keepTips
        self.improveTips = improveTips
        self.movements = movements
        self.wodTemplateId = wodTemplateId
        self.scoreBasis = scoreBasis
    }

    public var levelLabel: String? { level?.label }

    public var scoreLabel: String { "\(overallScore)/10" }

    /// SF Symbol descriptivo según la nota.
    public var scoreSymbolName: String { Self.scoreSymbolName(for: overallScore) }

    public static func scoreSymbolName(for score: Int) -> String {
        switch score {
        case 9...10: return "star.fill"
        case 7...8: return "hand.thumbsup.fill"
        case 5...6: return "equal.circle.fill"
        default: return "arrow.down.circle.fill"
        }
    }

    enum CodingKeys: String, CodingKey {
        case overallScore, level, headline, vsHistorySummary, vsStandardSummary
        case keepTips, improveTips, movements, wodTemplateId, scoreBasis
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        overallScore = min(10, max(1, try c.decode(Int.self, forKey: .overallScore)))
        level = try c.decodeIfPresent(AthleteLevel.self, forKey: .level)
        headline = try c.decode(String.self, forKey: .headline)
        vsHistorySummary = try c.decodeIfPresent(String.self, forKey: .vsHistorySummary)
        vsStandardSummary = try c.decodeIfPresent(String.self, forKey: .vsStandardSummary)
        keepTips = try c.decodeIfPresent([String].self, forKey: .keepTips) ?? []
        improveTips = try c.decodeIfPresent([String].self, forKey: .improveTips) ?? []
        movements = try c.decodeIfPresent([MovementReview].self, forKey: .movements) ?? []
        wodTemplateId = try c.decodeIfPresent(String.self, forKey: .wodTemplateId)
        scoreBasis = try c.decodeIfPresent(ScoreBasis.self, forKey: .scoreBasis)
    }
}
