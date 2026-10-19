import Foundation

/// Familia de movimiento para comparar rendimiento entre ejercicios similares.
public enum MovementFamily: String, Codable, Sendable, Hashable, CaseIterable {
    case squat
    case hinge
    case press
    case pull
    case olympic
    case jumpRope
    case erg
    case other

    public var label: String {
        switch self {
        case .squat: return "Sentadilla"
        case .hinge: return "Bisagra"
        case .press: return "Press"
        case .pull: return "Tirón"
        case .olympic: return "Olímpico"
        case .jumpRope: return "Comba"
        case .erg: return "Erg/cardio"
        case .other: return "Otro"
        }
    }
}

/// Match de historial comparable (mismo estilo de log + familia).
public struct EquivalentSetMatch: Sendable, Hashable {
    public var sets: [LoggedSet]
    /// 1.0 = mismo ejercicio; &lt;1 suaviza la comparación (p. ej. front vs back squat).
    public var transferFactor: Double
    public var referenceName: String
    public var family: MovementFamily

    public init(
        sets: [LoggedSet],
        transferFactor: Double,
        referenceName: String,
        family: MovementFamily
    ) {
        self.sets = sets
        self.transferFactor = transferFactor
        self.referenceName = referenceName
        self.family = family
    }

    /// e1RM histórico ajustado por transfer (prior × factor).
    public func adjustedPriorE1RM() -> Double? {
        let values = sets.compactMap { set -> Double? in
            guard let w = set.weightKg, w > 0, set.reps > 0 else { return nil }
            return PlateMath.epleyOneRM(weightKg: w, reps: set.reps)
        }
        guard let best = values.max(), best > 0 else { return nil }
        return best * transferFactor
    }
}

/// Equivalencias locales (sin ML) para valorar rendimiento entre ejercicios parecidos.
public enum ExerciseEquivalence {
    /// Clasifica por nombre / equipo / estilo.
    public static func family(for exercise: Exercise) -> MovementFamily {
        let n = normalize(exercise.name)
        let eq = normalize(exercise.equipment ?? "")
        let style = exercise.loggingStyle

        if style == .repsAndTime || containsAny(n, ["comba", "jump rope", "double under", "single under", "dobles", "simples"]) {
            return .jumpRope
        }
        if style == .machineWork
            || containsAny(n, ["remo", "row", "ski", "bike", "air bike", "echo", "cinta", "run", "correr", "assault"])
            || containsAny(eq, ["erg", "remo", "bike", "cinta"]) {
            return .erg
        }
        if containsAny(n, ["snatch", "arrancada", "clean and jerk", "clean & jerk", "envión", "two-part"]) {
            return .olympic
        }
        if containsAny(n, ["thruster", "squat", "sentadilla", "front squat", "back squat", "goblet", "overhead squat", "pistol"]) {
            return .squat
        }
        if containsAny(n, ["deadlift", "peso muerto", "rdl", "rumanian", "romanian", "sumo", "good morning", "hip thrust", "swing"]) {
            return .hinge
        }
        // Clean (sin jerk) ≈ hinge/olympic pull — hinge para e1RM de tirón.
        if matchesWord(n, "clean") || n.contains("cargada") {
            return .hinge
        }
        if containsAny(n, ["hspu", "handstand push", "press", "push press", "jerk", "bench", "banca", "fondos", "dip", "shoulder press"]) {
            return .press
        }
        if containsAny(n, ["dominad", "pull-up", "pull up", "pullup", "chin-up", "c2b", "chest to bar", "chest-to-bar", "muscle-up", "muscle up", "toes to bar", "ttb", "remo invertido", "ring row"]) {
            return .pull
        }
        return .other
    }

    /// Factor de transferencia al comparar `current` con un set histórico de `prior`.
    public static func transferFactor(current: Exercise, prior: Exercise) -> Double {
        if current.id == prior.id { return 1.0 }
        if namesEqual(current.name, prior.name) { return 1.0 }

        let cf = family(for: current)
        let pf = family(for: prior)
        guard cf == pf, cf != .other else { return 0 }

        let cn = normalize(current.name)
        let pn = normalize(prior.name)

        // Variantes conocidas dentro de la familia.
        if cf == .squat {
            if (cn.contains("front") && pn.contains("back")) || (cn.contains("back") && pn.contains("front")) {
                return 0.92
            }
            if cn.contains("goblet") || pn.contains("goblet") { return 0.88 }
            if cn.contains("thruster") || pn.contains("thruster") { return 0.9 }
            return 0.95
        }
        if cf == .hinge {
            if cn.contains("sumo") != pn.contains("sumo") { return 0.93 }
            if cn.contains("rdl") || pn.contains("rdl") || cn.contains("rumani") || pn.contains("rumani") {
                return 0.9
            }
            return 0.95
        }
        if cf == .press {
            if (cn.contains("hspu") || cn.contains("handstand")) != (pn.contains("hspu") || pn.contains("handstand")) {
                return 0 // déficit vs press de barra no comparable
            }
            if cn.contains("push press") != pn.contains("push press") { return 0.92 }
            return 0.95
        }
        if cf == .pull {
            if (cn.contains("muscle") || pn.contains("muscle")) && !(cn.contains("muscle") && pn.contains("muscle")) {
                return 0.85
            }
            return 0.95
        }
        if cf == .olympic { return 0.9 }
        if cf == .jumpRope || cf == .erg { return 0.95 }
        return 0.9
    }

    public static func areEquivalent(_ a: Exercise, _ b: Exercise) -> Bool {
        if a.id == b.id { return true }
        if namesEqual(a.name, b.name) { return true }
        guard a.loggingStyle == b.loggingStyle else { return false }
        guard a.loadField == b.loadField else { return false }
        let fa = family(for: a)
        let fb = family(for: b)
        guard fa == fb, fa != .other else { return false }
        return transferFactor(current: a, prior: b) > 0
    }

    /// Historial comparable: id → nombre → familia+estilo+loadField.
    public static func comparablePriorSets(
        for exercise: Exercise,
        in priorSessions: [WorkoutSession]
    ) -> EquivalentSetMatch? {
        var exact: [(String, [LoggedSet])] = []
        var equivalent: [(Exercise, [LoggedSet], Double)] = []

        for session in priorSessions {
            for entry in session.exercises {
                let sets = entry.loggedSets.filter {
                    !$0.isWarmup && ($0.reps > 0 || ($0.durationSeconds ?? 0) > 0)
                }
                guard !sets.isEmpty else { continue }

                if entry.exercise.id == exercise.id || namesEqual(entry.exercise.name, exercise.name) {
                    exact.append((entry.exercise.name, sets))
                    continue
                }
                guard entry.exercise.loggingStyle == exercise.loggingStyle else { continue }
                guard entry.exercise.loadField == exercise.loadField else { continue }
                let factor = transferFactor(current: exercise, prior: entry.exercise)
                guard factor > 0 else { continue }
                let fa = family(for: exercise)
                let fb = family(for: entry.exercise)
                guard fa == fb, fa != .other else { continue }
                equivalent.append((entry.exercise, sets, factor))
            }
        }

        if !exact.isEmpty {
            let name = exact[0].0
            let merged = exact.flatMap(\.1)
            return EquivalentSetMatch(
                sets: merged,
                transferFactor: 1.0,
                referenceName: name,
                family: family(for: exercise)
            )
        }

        guard !equivalent.isEmpty else { return nil }
        // Preferir el factor más alto (más similar) y más volumen de sets.
        let best = equivalent.max { a, b in
            if a.2 != b.2 { return a.2 < b.2 }
            return a.1.count < b.1.count
        }!
        let sameFamily = equivalent.filter { abs($0.2 - best.2) < 0.001 }
        let merged = sameFamily.flatMap(\.1)
        return EquivalentSetMatch(
            sets: merged,
            transferFactor: best.2,
            referenceName: best.0.name,
            family: family(for: exercise)
        )
    }

    // MARK: - Helpers

    private static func normalize(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func namesEqual(_ a: String, _ b: String) -> Bool {
        normalize(a) == normalize(b)
    }

    private static func containsAny(_ haystack: String, _ needles: [String]) -> Bool {
        needles.contains { haystack.contains($0) }
    }

    private static func matchesWord(_ haystack: String, _ word: String) -> Bool {
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
        return haystack.range(of: pattern, options: .regularExpression) != nil
    }
}
