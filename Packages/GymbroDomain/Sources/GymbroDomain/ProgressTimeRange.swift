import Foundation

/// Filtro global de Progreso (cabecera). Por defecto: esta semana.
public enum ProgressTimeRange: String, CaseIterable, Identifiable, Sendable {
    case today
    case week
    case month
    case days90
    case all

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .today: return "Hoy"
        case .week: return "Esta semana"
        case .month: return "Este mes"
        case .days90: return "90 días"
        case .all: return "Todo"
        }
    }

    public var subtitleLabel: String {
        title.lowercased()
    }

    /// Días a pintar en gráficas / heatmap (cap en “Todo”).
    public var chartDayCount: Int {
        switch self {
        case .today: return 1
        case .week: return 7
        case .month: return 31
        case .days90: return 90
        case .all: return 365
        }
    }

    /// Inicio inclusivo del rango; `nil` = sin límite (Todo).
    public func startDate(
        now: Date = Date(),
        calendar: Calendar = .current,
        weekStartsOnMonday: Bool = true
    ) -> Date? {
        var cal = calendar
        cal.firstWeekday = weekStartsOnMonday ? 2 : 1
        let today = cal.startOfDay(for: now)

        switch self {
        case .today:
            return today
        case .week:
            let weekday = cal.component(.weekday, from: today)
            let delta = (weekday - cal.firstWeekday + 7) % 7
            return cal.date(byAdding: .day, value: -delta, to: today)
        case .month:
            let comps = cal.dateComponents([.year, .month], from: today)
            return cal.date(from: comps)
        case .days90:
            return cal.date(byAdding: .day, value: -89, to: today)
        case .all:
            return nil
        }
    }

    public func contains(
        _ date: Date,
        now: Date = Date(),
        calendar: Calendar = .current,
        weekStartsOnMonday: Bool = true
    ) -> Bool {
        let cal = calendar
        let day = cal.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now)) ?? now
        guard day < end else { return false }
        guard let start = startDate(now: now, calendar: cal, weekStartsOnMonday: weekStartsOnMonday) else {
            return true
        }
        return day >= start
    }

    /// Días a pedir a Salud (mínimo 7; “Todo” acotado a 400).
    public var healthFetchDayCount: Int {
        switch self {
        case .today: return 7
        case .week: return 14
        case .month: return 45
        case .days90: return 100
        case .all: return 400
        }
    }

    /// Ventana del periodo anterior (misma duración, desplazada hacia atrás).
    /// `nil` si el rango es «Todo» (sin comparación).
    public func previousPeriodBounds(
        now: Date = Date(),
        calendar: Calendar = .current,
        weekStartsOnMonday: Bool = true
    ) -> (start: Date, end: Date)? {
        var cal = calendar
        cal.firstWeekday = weekStartsOnMonday ? 2 : 1
        let today = cal.startOfDay(for: now)

        switch self {
        case .all:
            return nil
        case .today:
            let start = cal.date(byAdding: .day, value: -1, to: today) ?? today
            return (start, today)
        case .week:
            guard let weekStart = startDate(now: now, calendar: cal, weekStartsOnMonday: weekStartsOnMonday) else {
                return nil
            }
            let prevStart = cal.date(byAdding: .day, value: -7, to: weekStart) ?? weekStart
            return (prevStart, weekStart)
        case .month:
            guard let monthStart = startDate(now: now, calendar: cal, weekStartsOnMonday: weekStartsOnMonday) else {
                return nil
            }
            let prevStart = cal.date(byAdding: .month, value: -1, to: monthStart) ?? monthStart
            return (prevStart, monthStart)
        case .days90:
            guard let start = startDate(now: now, calendar: cal, weekStartsOnMonday: weekStartsOnMonday) else {
                return nil
            }
            let prevStart = cal.date(byAdding: .day, value: -90, to: start) ?? start
            return (prevStart, start)
        }
    }

    public func containsInPreviousPeriod(
        _ date: Date,
        now: Date = Date(),
        calendar: Calendar = .current,
        weekStartsOnMonday: Bool = true
    ) -> Bool {
        guard let bounds = previousPeriodBounds(
            now: now,
            calendar: calendar,
            weekStartsOnMonday: weekStartsOnMonday
        ) else { return false }
        let day = calendar.startOfDay(for: date)
        return day >= bounds.start && day < bounds.end
    }
}
