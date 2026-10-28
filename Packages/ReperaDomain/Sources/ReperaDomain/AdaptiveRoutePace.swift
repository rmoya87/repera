import Foundation

/// Visualización relativa al ritmo de la sesión. No modifica métricas GPS ni de Salud.
public enum AdaptiveRoutePace {
    public enum Mode: Sendable {
        case walking, running, cycling, water, other
        public var minimumSpanMps: Double {
            switch self {
            case .walking: 0.5 / 3.6
            case .running: 1.0 / 3.6
            case .cycling: 2.0 / 3.6
            case .water: 1.2 / 3.6
            case .other: 0.8 / 3.6
            }
        }
    }
    public struct Sample: Sendable {
        public var speedMps: Double
        public var distanceMeters: Double
        public var isEstimated: Bool
        public init(speedMps: Double, distanceMeters: Double, isEstimated: Bool = false) {
            self.speedMps = speedMps
            self.distanceMeters = distanceMeters
            self.isEstimated = isEstimated
        }
    }
    public struct Scale: Sendable {
        public let medianMps: Double
        public let lowMps: Double
        public let highMps: Double
        public let minimumSpanMps: Double
        public let hasMeaningfulVariation: Bool

        /// Centro amarillo = mediana; no fuerza un rojo en trayectos uniformes.
        public func position(for speedMps: Double) -> Double {
            guard speedMps.isFinite else { return 0.5 }
            if !hasMeaningfulVariation {
                return min(0.60, max(0.40,
                    0.5 + (speedMps - medianMps) / (minimumSpanMps * 4)))
            }
            let side = speedMps < medianMps
                ? max(medianMps - lowMps, minimumSpanMps / 2)
                : max(highMps - medianMps, minimumSpanMps / 2)
            return min(1, max(0, 0.5 + 0.5 * (speedMps - medianMps) / side))
        }
    }

    /// Percentiles por metros, no por cantidad de lecturas; excluye datos inferidos.
    public static func scale(samples: [Sample], mode: Mode) -> Scale? {
        let sorted = samples.filter {
            !$0.isEstimated && $0.speedMps.isFinite && $0.speedMps >= 0.2 &&
            $0.speedMps <= 55 && $0.distanceMeters.isFinite && $0.distanceMeters >= 1
        }.sorted { $0.speedMps < $1.speedMps }
        guard !sorted.isEmpty else { return nil }
        let total = sorted.reduce(0.0) { $0 + min(30, $1.distanceMeters) }
        func quantile(_ p: Double) -> Double {
            let target = p * total
            var accumulated = 0.0
            for sample in sorted {
                accumulated += min(30, sample.distanceMeters)
                if accumulated >= target { return sample.speedMps }
            }
            return sorted[sorted.count - 1].speedMps
        }
        let low = quantile(0.1), median = quantile(0.5), high = quantile(0.9)
        return Scale(medianMps: median, lowMps: low, highMps: high,
                     minimumSpanMps: mode.minimumSpanMps,
                     hasMeaningfulVariation: high - low >= mode.minimumSpanMps)
    }

    public static func rgb(position: Double, water: Bool = false)
        -> (red: Double, green: Double, blue: Double) {
        let t = min(1, max(0, position.isFinite ? position : 0.5))
        let stops: [(Double, Double, Double)] = [
            water ? (0.0, 0.85, 0.55) : (0.086, 0.722, 0.361),
            (0.486, 0.824, 0.294),
            (0.902, 0.847, 0.286),
            (1.0, 0.612, 0.137),
            (0.941, 0.235, 0.22)
        ]
        let section = min(3, Int(t * 4))
        let mix = t * 4 - Double(section)
        let a = stops[section], b = stops[section + 1]
        return (a.0 + (b.0 - a.0) * mix,
                a.1 + (b.1 - a.1) * mix,
                a.2 + (b.2 - a.2) * mix)
    }
}
