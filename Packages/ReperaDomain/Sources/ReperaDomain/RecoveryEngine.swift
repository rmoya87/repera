import Foundation

/// Cálculo orientativo y determinista. No diagnostica, confirma ovulación,
/// predice fertilidad ni altera resultados deportivos.
public enum RecoveryEngine {
    public enum CyclePhase: String, Sendable, Equatable {
        case menstrual
        case follicular
        case ovulatory
        case luteal
        case unknown
    }

    /// Puntuación SOLO del sueño observado; nunca se añade/resta al score del entreno.
    public static func sleepIndex(hours: Double?, recentAverage: Double?) -> Int? {
        guard let hours, hours.isFinite, hours > 0 else { return nil }
        let baseline = (recentAverage?.isFinite == true && (recentAverage ?? 0) > 0)
            ? recentAverage! : 8
        let target = max(7, min(9, baseline))
        return Int((100 * min(max(0, hours / target), 1)).rounded())
    }

    /// Estima una fase únicamente a partir del historial de menstruaciones.
    /// Requiere al menos tres comienzos de ciclo, dos intervalos válidos y
    /// una regularidad razonable; no usa la fecha para inferir fertilidad.
    public static func cyclePhase(
        flowDays: [Date],
        on date: Date,
        calendar: Calendar = .current
    ) -> CyclePhase {
        let today = calendar.startOfDay(for: date)
        let days = Array(Set(flowDays.map { calendar.startOfDay(for: $0) })).sorted()
        guard let latest = days.last, latest <= today else { return .unknown }
        if days.contains(where: { calendar.isDate($0, inSameDayAs: today) }) {
            return .menstrual
        }
        var starts: [Date] = []
        for day in days {
            if let last = starts.last {
                let elapsed = calendar.dateComponents([.day], from: last, to: day).day ?? 0
                if elapsed <= 10 { continue }
            }
            starts.append(day)
        }
        guard starts.count >= 3, let current = starts.last else { return .unknown }
        let intervals = zip(starts.dropFirst(), starts).map {
            calendar.dateComponents([.day], from: $1, to: $0).day ?? 0
        }
        guard intervals.count >= 2,
              intervals.allSatisfy({ (21...40).contains($0) }),
              (intervals.max() ?? 0) - (intervals.min() ?? 0) <= 7 else { return .unknown }
        let elapsed = calendar.dateComponents([.day], from: current, to: today).day ?? -1
        let meanLength = Double(intervals.reduce(0,+)) / Double(intervals.count)
        guard elapsed >= 0, elapsed < Int(meanLength.rounded()) else { return .unknown }
        let midpoint = Int(meanLength.rounded()) - 14
        if abs(elapsed - midpoint) <= 1 { return .ovulatory }
        return elapsed < midpoint ? .follicular : .luteal
    }
}
