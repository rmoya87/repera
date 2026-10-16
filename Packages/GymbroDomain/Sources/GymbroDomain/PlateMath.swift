import Foundation

public struct PlatePair: Sendable, Equatable, Identifiable {
    public var id: Double { plateKg }
    public var plateKg: Double
    public var countPerSide: Int

    public init(plateKg: Double, countPerSide: Int) {
        self.plateKg = plateKg
        self.countPerSide = countPerSide
    }
}

public struct PlateSolution: Sendable, Equatable {
    public var barKg: Double
    public var targetKg: Double
    public var perSide: [PlatePair]
    public var achievedKg: Double
    public var remainderKg: Double

    public init(barKg: Double, targetKg: Double, perSide: [PlatePair], achievedKg: Double, remainderKg: Double) {
        self.barKg = barKg
        self.targetKg = targetKg
        self.perSide = perSide
        self.achievedKg = achievedKg
        self.remainderKg = remainderKg
    }

    public var summary: String {
        if targetKg <= barKg {
            return "Solo barra (\(format(barKg)) kg)"
        }
        if perSide.isEmpty {
            return "No hay combinación con tus discos (resto \(format(remainderKg)) kg)"
        }
        let parts = perSide.map { "\($0.countPerSide)×\(format($0.plateKg))" }.joined(separator: " + ")
        var text = "Por lado: \(parts) → \(format(achievedKg)) kg"
        if remainderKg > 0.05 {
            text += " (faltan \(format(remainderKg)) kg)"
        }
        return text
    }

    /// Formato compacto tipo «25 + 10 + 1.25 por lado».
    public var perSideCompact: String? {
        compactLabel(mode: .perSide)
    }

    /// Formato compacto según modo de carga.
    public func compactLabel(mode: PlateLoadMode) -> String? {
        guard mode != .off, targetKg > barKg, !perSide.isEmpty else { return nil }
        let parts = perSide.flatMap { pair in
            Array(repeating: format(pair.plateKg), count: pair.countPerSide)
        }
        let plates = parts.joined(separator: " + ")
        switch mode {
        case .perSide: return plates + " por lado"
        case .singleStack: return plates + " en pila"
        case .off: return nil
        }
    }

    private func format(_ value: Double) -> String {
        String(format: "%g", value)
    }
}

/// Cómo se cargan los discos en un ejercicio (ficha / logging).
public enum PlateLoadMode: String, Codable, Sendable, CaseIterable, Equatable {
    case perSide
    case singleStack
    case off

    public var displayName: String {
        switch self {
        case .perSide: return "Por lado"
        case .singleStack: return "Una pila"
        /// Sin línea de discos (peso corporal, máquinas sin discos, etc.).
        case .off: return "Sin discos"
        }
    }
}

public struct ExerciseLoadPreference: Codable, Sendable, Equatable, Hashable {
    public var mode: PlateLoadMode
    /// Peso de máquina/trineo/cinturón antes de discos (0 = solo discos).
    public var baseWeightKg: Double

    public init(mode: PlateLoadMode = .perSide, baseWeightKg: Double = 0) {
        self.mode = mode
        self.baseWeightKg = baseWeightKg
    }
}

public enum PlateMath {
    public static let defaultBarKg = 20.0
    public static let defaultPlatesKg: [Double] = [25, 20, 15, 10, 5, 2.5, 1.25]

    /// Greedy load: largest plates first, same count each side.
    public static func solve(
        targetKg: Double,
        barKg: Double = defaultBarKg,
        availablePlatesKg: [Double] = defaultPlatesKg
    ) -> PlateSolution {
        solve(targetKg: targetKg, baseKg: barKg, mode: .perSide, availablePlatesKg: availablePlatesKg)
    }

    /// Calcula discos según modo: por lado (barra), una pila (máquina/trineo) u off.
    public static func solve(
        targetKg: Double,
        baseKg: Double,
        mode: PlateLoadMode,
        availablePlatesKg: [Double] = defaultPlatesKg
    ) -> PlateSolution {
        let target = max(0, targetKg)
        let base = max(0, baseKg)
        switch mode {
        case .off:
            return PlateSolution(barKg: base, targetKg: target, perSide: [], achievedKg: target, remainderKg: 0)
        case .perSide:
            guard target > base else {
                return PlateSolution(barKg: base, targetKg: target, perSide: [], achievedKg: base, remainderKg: 0)
            }
            var remainingPerSide = (target - base) / 2.0
            var used: [PlatePair] = []
            let plates = availablePlatesKg.filter { $0 > 0 }.sorted(by: >)
            for plate in plates {
                let count = Int(remainingPerSide / plate)
                if count > 0 {
                    used.append(PlatePair(plateKg: plate, countPerSide: count))
                    remainingPerSide -= Double(count) * plate
                }
            }
            let loaded = base + used.reduce(0) { $0 + Double($1.countPerSide) * $1.plateKg * 2 }
            let remainder = max(0, target - loaded)
            return PlateSolution(
                barKg: base,
                targetKg: target,
                perSide: used,
                achievedKg: (loaded * 10).rounded() / 10,
                remainderKg: (remainder * 100).rounded() / 100
            )
        case .singleStack:
            guard target > base else {
                return PlateSolution(barKg: base, targetKg: target, perSide: [], achievedKg: base, remainderKg: 0)
            }
            var remaining = target - base
            var used: [PlatePair] = []
            let plates = availablePlatesKg.filter { $0 > 0 }.sorted(by: >)
            for plate in plates {
                let count = Int(remaining / plate)
                if count > 0 {
                    used.append(PlatePair(plateKg: plate, countPerSide: count))
                    remaining -= Double(count) * plate
                }
            }
            let loaded = base + used.reduce(0) { $0 + Double($1.countPerSide) * $1.plateKg }
            let remainder = max(0, target - loaded)
            return PlateSolution(
                barKg: base,
                targetKg: target,
                perSide: used,
                achievedKg: (loaded * 10).rounded() / 10,
                remainderKg: (remainder * 100).rounded() / 100
            )
        }
    }

    /// Epley: 1RM ≈ peso × (1 + reps/30).
    public static func epleyOneRM(weightKg: Double, reps: Int) -> Double {
        guard weightKg > 0, reps > 0 else { return 0 }
        return weightKg * (1 + Double(reps) / 30.0)
    }
}
