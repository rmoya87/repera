import Foundation

/// Competition references are never a representative sample of the general population.
/// No individual lifter data is required by the app; import only aggregate distributions.
public enum StrengthBenchmarkLift: String, Codable, Sendable, CaseIterable {
    case squat
    case benchPress
    case deadlift
    case frontSquat
    case sumoDeadlift
    case powerClean
    case inclineBenchPress
    case overheadPress
    case pushPress
    case snatchPress
    case dip
    case chinUp
    case pullUp
    case pendlayRow
}

public enum StrengthBenchmarkSex: String, Codable, Sendable, Hashable {
    case female
    case male
}

public enum StrengthBenchmarkEquipment: String, Codable, Sendable {
    case raw
    case wraps
    case singlePly
    case multiPly
}

/// Amateur = gym self-report seed / Repera aggregates; Élite = competition meets.
public enum StrengthReferenceFrame: String, Codable, Sendable, CaseIterable, Hashable {
    case amateur
    case elite

    public var allowedSources: Set<String> {
        switch self {
        case .amateur: return ["SymmetricStrength"]
        case .elite: return ["OpenPowerlifting"]
        }
    }
}

public struct StrengthBenchmarkCohort: Codable, Sendable, Equatable {
    public var lift: StrengthBenchmarkLift
    public var sex: StrengthBenchmarkSex
    public var equipment: StrengthBenchmarkEquipment
    public var ageMin: Int
    public var ageMax: Int
    public var bodyWeightMinKg: Double
    public var bodyWeightMaxKg: Double

    public init(lift: StrengthBenchmarkLift, sex: StrengthBenchmarkSex,
                equipment: StrengthBenchmarkEquipment, ageMin: Int, ageMax: Int,
                bodyWeightMinKg: Double, bodyWeightMaxKg: Double) {
        self.lift = lift
        self.sex = sex
        self.equipment = equipment
        self.ageMin = ageMin
        self.ageMax = ageMax
        self.bodyWeightMinKg = bodyWeightMinKg
        self.bodyWeightMaxKg = bodyWeightMaxKg
    }

    public func matches(lift: StrengthBenchmarkLift, sex: StrengthBenchmarkSex,
                        equipment: StrengthBenchmarkEquipment, age: Int,
                        bodyWeightKg: Double) -> Bool {
        self.lift == lift && self.sex == sex && self.equipment == equipment
            && age >= ageMin && age <= ageMax
            && bodyWeightKg >= bodyWeightMinKg && bodyWeightKg < bodyWeightMaxKg
    }
}

/// Percentiles are computed offline from competition results; never inferred from labels.
/// Quantiles are stored as (percentile, lifted kg), sorted by percentile.
public struct StrengthBenchmarkDistribution: Codable, Sendable {
    public var cohort: StrengthBenchmarkCohort
    public var source: String
    public var sourceRevision: String
    public var sampleCount: Int
    public var quantiles: [StrengthBenchmarkQuantile]

    public init(cohort: StrengthBenchmarkCohort, source: String, sourceRevision: String,
                sampleCount: Int, quantiles: [StrengthBenchmarkQuantile]) {
        self.cohort = cohort
        self.source = source
        self.sourceRevision = sourceRevision
        self.sampleCount = sampleCount
        self.quantiles = quantiles
    }
}

public struct StrengthBenchmarkQuantile: Codable, Sendable {
    public var percentile: Double
    public var weightKg: Double

    public init(percentile: Double, weightKg: Double) {
        self.percentile = percentile
        self.weightKg = weightKg
    }
}

public struct StrengthBenchmarkResult: Sendable {
    public var percentile: Double
    public var sampleCount: Int
    public var source: String
    public var sourceRevision: String
    /// True when the reference is restricted to an exact integer age, rather than all ages.
    public var ageSpecific: Bool
    /// Competition rows count meet appearances; gym rows count self-reported marks.
    public var sampleUnit: String {
        source == "SymmetricStrength"
            ? "marcas de gimnasio (autoinforme)"
            : "resultados de competición"
    }
}

public enum StrengthBenchmarkLiftResolver {
    public static func lift(forExerciseName name: String) -> StrengthBenchmarkLift? {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "es_ES"))
            .lowercased()
        switch n {
        case "sentadilla", "sentadilla trasera", "back squat", "barbell back squat":
            return .squat
        case "press banca", "press de banca", "bench press", "barbell bench press":
            return .benchPress
        case "peso muerto", "peso muerto convencional", "deadlift", "conventional deadlift":
            return .deadlift
        case "sentadilla frontal", "front squat", "barbell front squat":
            return .frontSquat
        case "peso muerto sumo", "sumo deadlift":
            return .sumoDeadlift
        case "power clean", "cargada de potencia":
            return .powerClean
        case "press inclinado", "press banca inclinado", "incline bench press", "barbell incline bench press":
            return .inclineBenchPress
        case "press militar", "strict press", "overhead press", "shoulder press", "military press":
            return .overheadPress
        case "push press", "press con impulso":
            return .pushPress
        case "snatch press", "press de arrancada", "snatch grip press":
            return .snatchPress
        case "fondos", "fondos en paralelas", "dip", "dips", "ring dip", "fondos en anillas":
            return .dip
        case "dominadas en supinacion", "dominada en supinacion", "chin-up", "chin up", "chinup":
            return .chinUp
        case "dominadas", "dominada", "pull-up", "pull up", "pullup", "dominadas lastradas":
            return .pullUp
        case "remo pendlay", "pendlay row":
            return .pendlayRow
        default:
            return nil
        }
    }
}

/// Anonymized bands for opt-in Amateur contributions (no exact age/weight published).
public enum StrengthContributionBands {
    /// Matches FitnessVolt / SymmetricStrength gym class edges used in the seed.
    public static let bodyWeightClasses: [(min: Double, max: Double)] = [
        (0, 59.0001), (59.0001, 66.0001), (66.0001, 74.0001), (74.0001, 83.0001),
        (83.0001, 93.0001), (93.0001, 105.0001), (105.0001, 120.0001), (120, 400)
    ]

    public static func ageBand(age: Int) -> String? {
        guard (14...100).contains(age) else { return nil }
        return "14-100"
    }

    public static func bodyWeightBand(kg: Double) -> String? {
        guard kg.isFinite, kg > 0 else { return nil }
        guard let band = bodyWeightClasses.first(where: { kg >= $0.min && kg < $0.max }) else {
            return nil
        }
        return "\(band.min)-\(band.max)"
    }
}

public enum StrengthBenchmarkEngine {
    public static let minimumSampleCount = 100

    /// Places a numeric 1RM-equivalent against competitive quantiles, never
    /// certifies it as a competition lift. The UI must label estimated e1RM
    /// separately from a personally recorded 1RM; never extrapolate.
    public static func compareCompetitionOneRepMax(
        weightKg: Double,
        lift: StrengthBenchmarkLift,
        sex: StrengthBenchmarkSex,
        equipment: StrengthBenchmarkEquipment,
        age: Int,
        bodyWeightKg: Double,
        distributions: [StrengthBenchmarkDistribution],
        frame: StrengthReferenceFrame = .amateur
    ) -> StrengthBenchmarkResult? {
        guard weightKg.isFinite && weightKg > 0,
              bodyWeightKg.isFinite && bodyWeightKg > 0,
              age >= 14 && age <= 100 else { return nil }
        let allowed = frame.allowedSources
        let eligible = distributions.filter {
            $0.cohort.matches(lift: lift, sex: sex, equipment: equipment,
                              age: age, bodyWeightKg: bodyWeightKg)
        }
        // Prefer the narrowest age band; fail closed on ties (never blend frames).
        let candidates = eligible.filter {
            $0.sampleCount >= minimumSampleCount && allowed.contains($0.source)
                && !$0.sourceRevision.isEmpty && $0.quantiles.count >= 2
        }
        guard let bestRange = candidates.map({ $0.cohort.ageMax - $0.cohort.ageMin }).min() else { return nil }
        let narrow = candidates.filter { $0.cohort.ageMax - $0.cohort.ageMin == bestRange }
        // Prefer larger samples, then newer revision (Repera opt-in can supersede seed).
        guard let reference = narrow.max(by: {
            if $0.sampleCount != $1.sampleCount { return $0.sampleCount < $1.sampleCount }
            return $0.sourceRevision < $1.sourceRevision
        }) else { return nil }
        let points = reference.quantiles.sorted { $0.percentile < $1.percentile }
        guard points.allSatisfy({ $0.percentile.isFinite && $0.weightKg.isFinite
                                  && $0.percentile >= 0 && $0.percentile <= 100
                                  && $0.weightKg > 0 }),
              zip(points, points.dropFirst()).allSatisfy({
                  $0.0.percentile < $0.1.percentile && $0.0.weightKg < $0.1.weightKg
              }) else { return nil }

        // Do not extrapolate beyond observed quantiles.
        guard let first = points.first, let last = points.last,
              weightKg >= first.weightKg, weightKg <= last.weightKg else { return nil }
        for (lower, upper) in zip(points, points.dropFirst()) {
            guard weightKg >= lower.weightKg && weightKg <= upper.weightKg else { continue }
            let fraction = (weightKg - lower.weightKg) / (upper.weightKg - lower.weightKg)
            return StrengthBenchmarkResult(
                percentile: lower.percentile + fraction * (upper.percentile - lower.percentile),
                sampleCount: reference.sampleCount,
                source: reference.source,
                sourceRevision: reference.sourceRevision,
                ageSpecific: reference.cohort.ageMin == reference.cohort.ageMax
            )
        }
        return nil
    }
}
