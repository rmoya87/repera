import Foundation

public enum EffortUnit: String, Codable, Sendable, CaseIterable {
    case rir
    case rpe

    public var displayName: String {
        switch self {
        case .rir: "RIR"
        case .rpe: "RPE"
        }
    }
}

public enum SetPhase: String, Codable, Sendable, CaseIterable {
    case work
    case warmup

    public var displayName: String {
        switch self {
        case .work: "Trabajo"
        case .warmup: "Calentamiento"
        }
    }
}

public enum SetKind: String, Codable, Sendable, CaseIterable {
    case straight
    case dropset
    case restpause

    public var displayName: String {
        switch self {
        case .straight: "Normal"
        case .dropset: "Drop set"
        case .restpause: "Rest-pause"
        }
    }
}

public struct DropSegment: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var reps: Int
    public var weightKg: Double?

    public init(id: UUID = UUID(), reps: Int, weightKg: Double? = nil) {
        self.id = id
        self.reps = reps
        self.weightKg = weightKg
    }
}

/// Burst inside a rest-pause / myo-rep set. `reps` on the parent set is the total.
public struct RestPauseCluster: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var reps: Int
    public var restSeconds: Int

    public init(id: UUID = UUID(), reps: Int, restSeconds: Int = 15) {
        self.id = id
        self.reps = reps
        self.restSeconds = restSeconds
    }
}

public enum Effort {
    /// Hard set threshold: RIR ≤ 2 (≈ RPE ≥ 8).
    public static let hardRIR = 2.0

    public static func toRIR(value: Double, unit: EffortUnit) -> Double {
        switch unit {
        case .rir: value
        case .rpe: max(0, 10 - value)
        }
    }

    public static func fromRIR(_ rir: Double, unit: EffortUnit) -> Double {
        switch unit {
        case .rir: rir
        case .rpe: max(0, 10 - rir)
        }
    }

    public static func label(rir: Double?, unit: EffortUnit) -> String? {
        guard let rir else { return nil }
        let display = fromRIR(rir, unit: unit)
        switch unit {
        case .rir:
            return "RIR \(display.formatted(.number.precision(.fractionLength(0...1))))"
        case .rpe:
            return "RPE \(display.formatted(.number.precision(.fractionLength(0...1))))"
        }
    }

    public static func isHard(rir: Double?) -> Bool {
        guard let rir else { return false }
        return rir <= hardRIR
    }

    public static func plainLanguage(rir: Double) -> String {
        switch rir {
        case ...0: "Fallo / sin reps en reserva"
        case ...1: "Muy duro (1 en reserva)"
        case ...2: "Duro (cerca del fallo)"
        case ...4: "Moderado"
        default: "Holgado"
        }
    }
}
