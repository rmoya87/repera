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

    private func format(_ value: Double) -> String {
        String(format: "%g", value)
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
        let target = max(0, targetKg)
        let bar = max(0, barKg)
        guard target > bar else {
            return PlateSolution(barKg: bar, targetKg: target, perSide: [], achievedKg: bar, remainderKg: 0)
        }

        var remainingPerSide = (target - bar) / 2.0
        var used: [PlatePair] = []
        let plates = availablePlatesKg.filter { $0 > 0 }.sorted(by: >)

        for plate in plates {
            let count = Int(remainingPerSide / plate)
            if count > 0 {
                used.append(PlatePair(plateKg: plate, countPerSide: count))
                remainingPerSide -= Double(count) * plate
            }
        }

        let loaded = bar + used.reduce(0) { $0 + Double($1.countPerSide) * $1.plateKg * 2 }
        let remainder = max(0, target - loaded)
        return PlateSolution(
            barKg: bar,
            targetKg: target,
            perSide: used,
            achievedKg: (loaded * 10).rounded() / 10,
            remainderKg: (remainder * 100).rounded() / 100
        )
    }
}
