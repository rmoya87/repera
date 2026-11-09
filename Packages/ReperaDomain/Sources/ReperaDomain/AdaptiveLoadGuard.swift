import Foundation

/// Optional safety gate over existing ProgressionEngine policies.
/// This never modifies a plan or creates a new session on its own.
public enum AdaptiveLoadDecision: String, Sendable {
    case increase
    case maintain
    case deload
    case insufficientData
}

public struct AdaptiveLoadObservation: Sendable {
    public var completed: Bool
    public var rir: Double?
    public var relativeE1RMChange: Double?
    public var hoursSincePreviousSession: Double?

    public init(completed: Bool, rir: Double?, relativeE1RMChange: Double?,
                hoursSincePreviousSession: Double?) {
        self.completed = completed
        self.rir = rir
        self.relativeE1RMChange = relativeE1RMChange
        self.hoursSincePreviousSession = hoursSincePreviousSession
    }
}

public struct AdaptiveLoadAdvice: Sendable {
    public var decision: AdaptiveLoadDecision
    public var reason: String
}

public enum AdaptiveLoadGuard {
    /// Requires 2-4 observations; no unlimited automatic load increases.
    /// The caller must provide completed sessions only, newest first, deduplicated by UUID.
    public static func evaluate(recent: [AdaptiveLoadObservation],
                                recoveryReady: Bool? = nil) -> AdaptiveLoadAdvice {
        let sample = Array(recent.prefix(4))
        guard sample.count >= 2 else {
            return .init(decision: .insufficientData, reason: "Faltan sesiones comparables.")
        }
        guard sample.allSatisfy({ observation in
            (observation.rir == nil || (observation.rir!.isFinite && observation.rir! >= 0 && observation.rir! <= 10))
                && (observation.relativeE1RMChange == nil || observation.relativeE1RMChange!.isFinite)
                && (observation.hoursSincePreviousSession == nil || (observation.hoursSincePreviousSession!.isFinite && observation.hoursSincePreviousSession! >= 0))
        }) else {
            return .init(decision: .insufficientData, reason: "Métricas incompletas o inválidas.")
        }
        if sample.prefix(3).count == 3 && sample.prefix(3).allSatisfy({ !$0.completed }) {
            return .init(decision: .deload, reason: "Tres sesiones seguidas sin completar el objetivo.")
        }
        if recoveryReady == false {
            return .init(decision: .maintain, reason: "Recuperación insuficiente: mantener la carga.")
        }
        guard sample.prefix(2).allSatisfy(\.completed) else {
            return .init(decision: .maintain, reason: "Consolidar los objetivos antes de subir.")
        }
        guard sample.prefix(2).allSatisfy({ ($0.rir ?? -1) >= 2 }) else {
            return .init(decision: .maintain, reason: "Sin margen RIR suficiente para progresar.")
        }
        if sample.contains(where: { ($0.hoursSincePreviousSession ?? 72) < 24 }) {
            return .init(decision: .maintain, reason: "Sesiones demasiado próximas para sugerir aumento.")
        }
        if sample.prefix(2).contains(where: { ($0.relativeE1RMChange ?? 0) < -0.05 }) {
            return .init(decision: .maintain, reason: "Tendencia de fuerza descendente.")
        }
        return .init(decision: .increase, reason: "Dos sesiones completadas con al menos 2 RIR.")
    }
}
