import Foundation

/// Unidad de ritmo en metcon (reps, calorías o metros).
public enum PaceUnit: String, Sendable, Hashable {
    case rep
    case calorie
    case meter
}

/// Ritmo de trabajo en WOD (incluye roturas típicas, no unbroken de élite en gym).
public enum MovementPaceKind: String, Sendable, Hashable, CaseIterable {
    case airSquat
    case squatBarbell
    case thruster
    case deadlift
    case clean
    case snatch
    case press
    case pushPress
    case pullUp
    case chestToBar
    case muscleUp
    case pushUp
    case burpee
    case hspu
    case boxJump
    case kettlebellSwing
    case wallBall
    case doubleUnder
    case singleUnder
    case toesToBar
    case sitUp
    case runMeter
    case rowMeter
    case rowCal
    case bikeCal
    case skiCal
    case genericRep
    case genericCal
    case genericMeter

    public var unit: PaceUnit {
        switch self {
        case .runMeter, .rowMeter, .genericMeter: return .meter
        case .rowCal, .bikeCal, .skiCal, .genericCal: return .calorie
        default: return .rep
        }
    }

    /// Segundos por unidad a ritmo **intermedio** de metcon (con roturas reales, no unbroken).
    public var intermediateSecondsPerUnit: Double {
        switch self {
        case .airSquat: return 1.8
        case .squatBarbell: return 3.6
        case .thruster: return 4.2
        case .deadlift: return 3.6
        case .clean: return 3.8
        case .snatch: return 4.5
        case .press: return 3.2
        case .pushPress: return 2.8
        case .pullUp: return 3.5
        case .chestToBar: return 4.0
        case .muscleUp: return 7.5
        case .pushUp: return 3.0
        case .burpee: return 6.0
        case .hspu: return 5.5
        case .boxJump: return 3.2
        case .kettlebellSwing: return 2.6
        case .wallBall: return 3.2
        case .doubleUnder: return 0.7
        case .singleUnder: return 0.45
        case .toesToBar: return 3.6
        case .sitUp: return 2.2
        case .runMeter: return 0.30
        case .rowMeter: return 0.28
        case .rowCal: return 5.0
        case .bikeCal: return 4.2
        case .skiCal: return 4.8
        case .genericRep: return 3.4
        case .genericCal: return 4.8
        case .genericMeter: return 0.28
        }
    }
}

/// Estándares de ritmo por nivel para estimar WODs a medida.
public enum MovementPaceStandards {
    /// Multiplicador sobre el ritmo intermedio (mayor = más lento).
    public static func levelMultiplier(_ level: AthleteLevel) -> Double {
        switch level {
        case .elite: return 0.72
        case .advanced: return 0.88
        case .intermediate: return 1.0
        case .beginner: return 1.55
        }
    }

    /// Transición entre movimientos del mismo round (segundos).
    public static func transitionSeconds(for level: AthleteLevel) -> Double {
        switch level {
        case .elite: return 4
        case .advanced: return 7
        case .intermediate: return 11
        case .beginner: return 18
        }
    }

    public static func secondsPerUnit(_ kind: MovementPaceKind, level: AthleteLevel) -> Double {
        kind.intermediateSecondsPerUnit * levelMultiplier(level)
    }

    /// Clasifica un nombre de ejercicio (ES/EN) al ritmo de catálogo.
    public static func paceKind(forExerciseName name: String) -> MovementPaceKind {
        let n = normalize(name)

        if containsAny(n, ["double under", "dobles", "du ", " du", "comba doble"]) {
            return .doubleUnder
        }
        if containsAny(n, ["single under", "simples", "comba"]) {
            return .singleUnder
        }
        if containsAny(n, ["burpee"]) { return .burpee }
        if containsAny(n, ["muscle-up", "muscle up", "muscleup"]) { return .muscleUp }
        if containsAny(n, ["chest to bar", "chest-to-bar", "c2b", "ctp"]) { return .chestToBar }
        if containsAny(n, ["toes to bar", "toes-to-bar", "ttb", "pies a la barra"]) { return .toesToBar }
        if containsAny(n, ["hspu", "handstand push", "pino flex"]) { return .hspu }
        if containsAny(n, ["wall ball", "wallball", "balon medicinal", "balón medicinal"]) {
            return .wallBall
        }
        if containsAny(n, ["box jump", "salto al cajon", "salto al cajón"]) { return .boxJump }
        if containsAny(n, ["swing", "balanceo"]) { return .kettlebellSwing }
        if containsAny(n, ["sit-up", "sit up", "abdominal", "crunch"]) { return .sitUp }
        if containsAny(n, ["push-up", "push up", "flexion", "flexión", "fondos en suelo"]) {
            return .pushUp
        }
        if containsAny(n, ["thruster"]) { return .thruster }
        if containsAny(n, ["snatch", "arrancada"]) { return .snatch }
        if containsAny(n, ["clean", "cargada"]) && !n.contains("jerk") { return .clean }
        if containsAny(n, ["clean and jerk", "clean & jerk", "envion", "envión"]) { return .clean }
        if containsAny(n, ["deadlift", "peso muerto"]) { return .deadlift }
        if containsAny(n, ["push press"]) { return .pushPress }
        if containsAny(n, ["shoulder press", "press militar", "strict press", "press de hombro"]) {
            return .press
        }
        if containsAny(n, ["air squat", "sentadilla libre", "bodyweight squat", "sentadilla aire"]) {
            return .airSquat
        }
        if containsAny(n, ["squat", "sentadilla", "pistol"]) { return .squatBarbell }
        if containsAny(n, ["dominad", "pull-up", "pull up", "pullup", "chin-up", "chin up"]) {
            return .pullUp
        }

        // Erg / carrera
        if containsAny(n, ["ski", "skierg"]) { return .skiCal }
        if containsAny(n, ["air bike", "echo", "assault", "bike erg", "bici"]) { return .bikeCal }
        if containsAny(n, ["remoerg", "rowerg", "rower", "remo", "row"]) {
            // "Remoergómetro" = máquina (cal); metros solo si la dosis es distancia explícita.
            if n.contains("metro") && !n.contains("remoerg") && !n.contains("ergometro") && !n.contains("ergómetro") {
                return .rowMeter
            }
            if n.contains(" m") || n.hasSuffix("m") && n.contains("500") { return .rowMeter }
            return .rowCal
        }
        if containsAny(n, ["run", "correr", "carrera", "cinta"]) { return .runMeter }

        return .genericRep
    }

    public static func paceKind(for exercise: Exercise) -> MovementPaceKind {
        let fromName = paceKind(forExerciseName: exercise.name)
        if fromName != .genericRep { return fromName }
        switch exercise.loggingStyle {
        case .repsAndTime:
            return containsAny(normalize(exercise.name), ["doble", "double"]) ? .doubleUnder : .singleUnder
        case .machineWork:
            let n = normalize(exercise.name)
            let eq = normalize(exercise.equipment ?? "")
            if containsAny(n, ["ski"]) || containsAny(eq, ["ski"]) { return .skiCal }
            if containsAny(n, ["bike", "bici", "echo", "assault"]) { return .bikeCal }
            if containsAny(n, ["run", "correr", "cinta"]) { return .runMeter }
            if containsAny(n, ["remo", "row"]) { return .rowCal }
            return .genericCal
        case .repsOnly, .loadAndReps:
            return fromName
        }
    }

    // MARK: - Helpers

    private static func normalize(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }

    private static func containsAny(_ haystack: String, _ needles: [String]) -> Bool {
        needles.contains { haystack.contains($0) }
    }
}

/// Línea de prescripción para estimar un WOD.
public struct PacePrescriptionLine: Sendable, Hashable {
    public var name: String
    public var kind: MovementPaceKind
    public var quantity: Double

    public init(name: String, kind: MovementPaceKind, quantity: Double) {
        self.name = name
        self.kind = kind
        self.quantity = quantity
    }
}

/// Estimación de tiempos/rondas esperados por nivel.
public struct WODPaceEstimate: Sendable, Hashable {
    public var expectedSecondsByLevel: [AthleteLevel: Double]
    public var expectedRoundsByLevel: [AthleteLevel: Double]
    public var windowSeconds: Double?
    public var lineCount: Int

    public init(
        expectedSecondsByLevel: [AthleteLevel: Double] = [:],
        expectedRoundsByLevel: [AthleteLevel: Double] = [:],
        windowSeconds: Double? = nil,
        lineCount: Int = 0
    ) {
        self.expectedSecondsByLevel = expectedSecondsByLevel
        self.expectedRoundsByLevel = expectedRoundsByLevel
        self.windowSeconds = windowSeconds
        self.lineCount = lineCount
    }

    public func expectedSeconds(for level: AthleteLevel) -> Double? {
        expectedSecondsByLevel[level]
    }

    public func expectedRounds(for level: AthleteLevel) -> Double? {
        expectedRoundsByLevel[level]
    }
}

/// Estima duración / rondas de un WOD a partir de ritmos de catálogo por nivel.
public enum WODPaceEstimator {
    /// Construye líneas desde ejercicios de sesión (bloque WOD).
    public static func prescription(
        fromExercises exercises: [SessionExercise]
    ) -> [PacePrescriptionLine] {
        exercises.compactMap { entry -> PacePrescriptionLine? in
            let kind = MovementPaceStandards.paceKind(for: entry.exercise)
            let qty = prescriptionQuantity(entry: entry, kind: kind)
            guard qty > 0 else { return nil }
            return PacePrescriptionLine(name: entry.exercise.name, kind: kind, quantity: qty)
        }
    }

    /// Desde movimientos de plantilla de catálogo.
    public static func prescription(fromMovements movements: [WODMovement]) -> [PacePrescriptionLine] {
        movements.compactMap { mov -> PacePrescriptionLine? in
            guard !mov.isRest else { return nil }
            let kind = MovementPaceStandards.paceKind(forExerciseName: mov.name)
            let qty: Double
            if let meters = mov.distanceMeters, meters > 0 {
                let meterKind: MovementPaceKind = {
                    switch kind {
                    case .runMeter, .rowMeter, .genericMeter: return kind
                    case .rowCal: return .rowMeter
                    default: return .genericMeter
                    }
                }()
                return PacePrescriptionLine(name: mov.name, kind: meterKind, quantity: Double(meters))
            }
            if let cal = mov.calories, cal > 0 {
                let calKind: MovementPaceKind = {
                    switch kind {
                    case .rowCal, .bikeCal, .skiCal, .genericCal: return kind
                    default: return .genericCal
                    }
                }()
                return PacePrescriptionLine(name: mov.name, kind: calKind, quantity: Double(cal))
            }
            if let scheme = mov.repScheme, !scheme.isEmpty {
                qty = Double(scheme.reduce(0, +))
            } else if let reps = mov.reps, reps > 0 {
                qty = Double(reps)
            } else {
                return nil
            }
            return PacePrescriptionLine(name: mov.name, kind: kind, quantity: qty)
        }
    }

    public static func estimateForTime(
        lines: [PacePrescriptionLine],
        rounds: Int = 1
    ) -> WODPaceEstimate {
        guard !lines.isEmpty else { return WODPaceEstimate() }
        var byLevel: [AthleteLevel: Double] = [:]
        for level in AthleteLevel.allCases {
            var work = 0.0
            for line in lines {
                work += line.quantity * MovementPaceStandards.secondsPerUnit(line.kind, level: level)
            }
            let transitions = Double(max(0, lines.count - 1))
                * MovementPaceStandards.transitionSeconds(for: level)
            var total = (work + transitions) * Double(max(1, rounds))
            total *= fatigueFactor(totalQuantity: lines.reduce(0) { $0 + $1.quantity } * Double(max(1, rounds)))
            byLevel[level] = total
        }
        return WODPaceEstimate(expectedSecondsByLevel: byLevel, lineCount: lines.count)
    }

    public static func estimateAMRAP(
        roundLines: [PacePrescriptionLine],
        windowSeconds: Double
    ) -> WODPaceEstimate {
        guard !roundLines.isEmpty, windowSeconds > 0 else { return WODPaceEstimate() }
        var seconds: [AthleteLevel: Double] = [:]
        var rounds: [AthleteLevel: Double] = [:]
        for level in AthleteLevel.allCases {
            var work = 0.0
            for line in roundLines {
                work += line.quantity * MovementPaceStandards.secondsPerUnit(line.kind, level: level)
            }
            let transitions = Double(max(0, roundLines.count - 1))
                * MovementPaceStandards.transitionSeconds(for: level)
            let cycle = max(15, (work + transitions) * fatigueFactor(totalQuantity: roundLines.reduce(0) { $0 + $1.quantity }))
            seconds[level] = cycle
            rounds[level] = windowSeconds / cycle
        }
        return WODPaceEstimate(
            expectedSecondsByLevel: seconds,
            expectedRoundsByLevel: rounds,
            windowSeconds: windowSeconds,
            lineCount: roundLines.count
        )
    }

    /// Mapea un tiempo real a nivel + nota usando tiempos esperados por nivel.
    public static func scoreForTime(
        elapsedSeconds: Int,
        estimate: WODPaceEstimate
    ) -> (level: AthleteLevel, score: Int, summary: String)? {
        guard let elite = estimate.expectedSeconds(for: .elite),
              let advanced = estimate.expectedSeconds(for: .advanced),
              let intermediate = estimate.expectedSeconds(for: .intermediate),
              let beginner = estimate.expectedSeconds(for: .beginner),
              elite > 0 else { return nil }

        let t = Double(elapsedSeconds)
        let level: AthleteLevel
        if t <= elite { level = .elite }
        else if t <= advanced { level = .advanced }
        else if t <= intermediate { level = .intermediate }
        else { level = .beginner }

        let score: Int = {
            switch level {
            case .elite:
                let floor = elite * 0.75
                if t <= floor { return 10 }
                let u = (t - floor) / max(1, elite - floor)
                return max(9, min(10, 10 - Int((u * 1.2).rounded())))
            case .advanced:
                let u = (t - elite) / max(1, advanced - elite)
                return max(7, min(9, 9 - Int((u * 2).rounded())))
            case .intermediate:
                let u = (t - advanced) / max(1, intermediate - advanced)
                return max(5, min(7, 7 - Int((u * 2).rounded())))
            case .beginner:
                if t > beginner * 1.25 { return 3 }
                let u = (t - intermediate) / max(1, beginner * 1.25 - intermediate)
                return max(3, min(5, 5 - Int((u * 2).rounded())))
            }
        }()

        let midRef = Int(intermediate.rounded())
        let yours = formatSeconds(elapsedSeconds)
        let ref = formatSeconds(midRef)
        let summary: String = {
            if elapsedSeconds <= midRef {
                return "Hiciste \(yours); un ritmo intermedio suele ir a ~\(ref)."
            }
            return "Hiciste \(yours); el ritmo intermedio de referencia está en ~\(ref)."
        }()
        return (level, score, summary)
    }

    public static func scoreAMRAP(
        rounds: Double,
        estimate: WODPaceEstimate
    ) -> (level: AthleteLevel, score: Int, summary: String)? {
        guard let elite = estimate.expectedRounds(for: .elite),
              let advanced = estimate.expectedRounds(for: .advanced),
              let intermediate = estimate.expectedRounds(for: .intermediate),
              let beginner = estimate.expectedRounds(for: .beginner),
              elite > 0 else { return nil }

        let level: AthleteLevel
        if rounds >= elite { level = .elite }
        else if rounds >= advanced { level = .advanced }
        else if rounds >= intermediate { level = .intermediate }
        else { level = .beginner }

        let score: Int = {
            switch level {
            case .elite:
                if rounds >= elite * 1.15 { return 10 }
                let u = (rounds - elite) / max(0.01, elite * 0.15)
                return max(9, min(10, 9 + Int((u * 1.5).rounded())))
            case .advanced:
                let u = (rounds - advanced) / max(0.01, elite - advanced)
                return max(7, min(9, 7 + Int((u * 2).rounded())))
            case .intermediate:
                let u = (rounds - intermediate) / max(0.01, advanced - intermediate)
                return max(5, min(7, 5 + Int((u * 2).rounded())))
            case .beginner:
                if rounds < beginner * 0.5 { return 3 }
                let u = (rounds - beginner * 0.5) / max(0.01, intermediate - beginner * 0.5)
                return max(3, min(5, 3 + Int((u * 2).rounded())))
            }
        }()

        let midRef = intermediate
        let yours = formatRounds(rounds)
        let ref = formatRounds(midRef)
        let summary: String = {
            if rounds >= midRef {
                return "Completaste \(yours); un ritmo intermedio suele hacer ~\(ref)."
            }
            return "Completaste \(yours); el ritmo intermedio de referencia está en ~\(ref)."
        }()
        return (level, score, summary)
    }

    // MARK: - Private

    private static func prescriptionQuantity(entry: SessionExercise, kind: MovementPaceKind) -> Double {
        let planned = entry.plannedSets
        if kind.unit == .meter {
            // metros a menudo en quantity/reps del plan o en nombre; usar reps como metros si machine.
            let meters = planned.map(\.targetReps).reduce(0, +)
            if meters > 0 { return Double(meters) }
        }
        if kind.unit == .calorie {
            let cals = planned.map(\.targetReps).reduce(0, +)
            if cals > 0 { return Double(cals) }
        }
        let reps = planned.map(\.targetReps).filter { $0 > 0 }.reduce(0, +)
        if reps > 0 { return Double(reps) }
        // Fallback: series logueadas (WOD a veces solo tiene log).
        let logged = entry.loggedSets.filter { !$0.isWarmup }.map(\.reps).filter { $0 > 0 }.reduce(0, +)
        return Double(logged)
    }

    /// Fatiga suave con volumen alto.
    private static func fatigueFactor(totalQuantity: Double) -> Double {
        guard totalQuantity > 40 else { return 1.0 }
        return min(1.4, 1.0 + (totalQuantity - 40) * 0.004)
    }

    private static func formatSeconds(_ total: Int) -> String {
        let m = total / 60
        let s = abs(total) % 60
        return String(format: "%d:%02d", m, s)
    }

    private static func formatRounds(_ value: Double) -> String {
        if abs(value - value.rounded()) < 0.05 {
            return "\(Int(value.rounded()))"
        }
        return String(format: "%.1f", value)
    }
}
