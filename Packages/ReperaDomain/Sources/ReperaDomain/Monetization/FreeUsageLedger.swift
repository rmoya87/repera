import Foundation

/// Contadores de uso gratuito (separados del JSON deportivo).
public struct FreeUsageState: Codable, Sendable, Equatable, Hashable {
    /// Periodo mensual en calendario gregoriano UTC: `yyyy-MM`.
    public var boardScanPeriodKey: String
    public var boardScansConsumed: Int
    /// Intentos ya contabilizados (anti doble callback).
    public var consumedAttemptIDs: [String]
    public var lastBoardScanConsumedAt: Date?

    public init(
        boardScanPeriodKey: String = "",
        boardScansConsumed: Int = 0,
        consumedAttemptIDs: [String] = [],
        lastBoardScanConsumedAt: Date? = nil
    ) {
        self.boardScanPeriodKey = boardScanPeriodKey
        self.boardScansConsumed = boardScansConsumed
        self.consumedAttemptIDs = consumedAttemptIDs
        self.lastBoardScanConsumedAt = lastBoardScanConsumedAt
    }
}

/// Lógica pura de cuotas mensuales (testeable sin UI ni iCloud).
public enum FreeUsageLedger: Sendable {
    public static let maxTrackedAttemptIDs = 64

    /// Clave de mes natural en UTC (consistente entre husos).
    public static func periodKey(for date: Date = Date(), calendar: Calendar = utcCalendar) -> String {
        let comps = calendar.dateComponents([.year, .month], from: date)
        let year = comps.year ?? 1970
        let month = comps.month ?? 1
        return String(format: "%04d-%02d", year, month)
    }

    public static var utcCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return cal
    }

    /// Asegura que el estado refleja el mes actual; resetea contadores al cambiar de periodo.
    public static func normalized(
        _ state: FreeUsageState,
        now: Date = Date(),
        calendar: Calendar = utcCalendar
    ) -> FreeUsageState {
        let key = periodKey(for: now, calendar: calendar)
        guard state.boardScanPeriodKey == key else {
            return FreeUsageState(boardScanPeriodKey: key)
        }
        return state
    }

    public static func boardScansRemaining(
        in state: FreeUsageState,
        limit: Int = FreePlanLimits.maxBoardScansPerMonth,
        now: Date = Date(),
        calendar: Calendar = utcCalendar
    ) -> Int {
        let current = normalized(state, now: now, calendar: calendar)
        return max(0, limit - current.boardScansConsumed)
    }

    public static func canStartBoardScan(
        state: FreeUsageState,
        isPro: Bool,
        limit: Int = FreePlanLimits.maxBoardScansPerMonth,
        now: Date = Date(),
        calendar: Calendar = utcCalendar
    ) -> Bool {
        if isPro { return true }
        return boardScansRemaining(in: state, limit: limit, now: now, calendar: calendar) > 0
    }

    /// Consume un escaneo exitoso. Idempotente por `attemptID`.
    @discardableResult
    public static func consumeBoardScan(
        state: inout FreeUsageState,
        attemptID: String,
        isPro: Bool,
        limit: Int = FreePlanLimits.maxBoardScansPerMonth,
        now: Date = Date(),
        calendar: Calendar = utcCalendar
    ) -> Bool {
        if isPro { return false }
        state = normalized(state, now: now, calendar: calendar)
        if state.consumedAttemptIDs.contains(attemptID) {
            return false
        }
        guard state.boardScansConsumed < limit else { return false }
        state.boardScansConsumed += 1
        state.consumedAttemptIDs.append(attemptID)
        if state.consumedAttemptIDs.count > maxTrackedAttemptIDs {
            state.consumedAttemptIDs.removeFirst(state.consumedAttemptIDs.count - maxTrackedAttemptIDs)
        }
        state.lastBoardScanConsumedAt = now
        return true
    }
}
