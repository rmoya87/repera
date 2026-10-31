import Foundation

/// Filtro global de Progreso (cabecera). Por defecto: últimos 7 días.
public enum ProgressTimeRange: String, CaseIterable, Identifiable, Sendable {
    case today
    case week
    case month
    case days90
    case days180
    case days360

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .today: return "Hoy"
        case .week: return "Últimos 7 días"
        case .month: return "Este mes"
        case .days90: return "90 días"
        case .days180: return "180 días"
        case .days360: return "360 días"
        }
    }

    public var subtitleLabel: String {
        title.lowercased()
    }

    /// Días a pintar en gráficas / heatmap.
    public var chartDayCount: Int {
        switch self {
        case .today: return 1
        case .week: return 7
        case .month: return 31
        case .days90: return 90
        case .days180: return 180
        case .days360: return 360
        }
    }

    /// Inicio inclusivo del rango (siempre acotado).
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
            // Ventana móvil: hoy + 6 días anteriores (no semana calendario lun–dom).
            return cal.date(byAdding: .day, value: -6, to: today)
        case .month:
            let comps = cal.dateComponents([.year, .month], from: today)
            return cal.date(from: comps)
        case .days90:
            return cal.date(byAdding: .day, value: -89, to: today)
        case .days180:
            return cal.date(byAdding: .day, value: -179, to: today)
        case .days360:
            return cal.date(byAdding: .day, value: -359, to: today)
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

    /// Días a pedir a Salud (margen sobre el periodo visible).
    public var healthFetchDayCount: Int {
        switch self {
        // Incluir el tramo equivalente anterior para comparar con Salud.
        case .today: return 7
        case .week: return 16
        case .month: return 70
        case .days90: return 190
        case .days180: return 370
        case .days360: return 730
        }
    }

    /// Periodo comparable: en semana y mes solo los días transcurridos,
    /// nunca todo el periodo anterior si el actual aún no ha concluido.
    /// Los periodos móviles (90/180/360 días) sí comparan ventanas completas.
    public func previousPeriodBounds(
        now: Date = Date(),
        calendar: Calendar = .current,
        weekStartsOnMonday: Bool = true
    ) -> (start: Date, end: Date)? {
        var cal = calendar
        cal.firstWeekday = weekStartsOnMonday ? 2 : 1
        let today = cal.startOfDay(for: now)

        switch self {
        case .today:
            let start = cal.date(byAdding: .day, value: -1, to: today) ?? today
            return (start, today)
        case .week:
            // Misma ventana móvil de 7 días inmediatamente anterior.
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
            let elapsedDays = max(1, cal.dateComponents([.day], from: monthStart, to: today).day.map { $0 + 1 } ?? 1)
            // Si el mes anterior es más corto, se limita a su último día.
            let comparableEnd = cal.date(byAdding: .day, value: elapsedDays, to: prevStart) ?? monthStart
            return (prevStart, min(comparableEnd, monthStart))
        case .days90:
            guard let start = startDate(now: now, calendar: cal, weekStartsOnMonday: weekStartsOnMonday) else {
                return nil
            }
            let prevStart = cal.date(byAdding: .day, value: -90, to: start) ?? start
            return (prevStart, start)
        case .days180:
            guard let start = startDate(now: now, calendar: cal, weekStartsOnMonday: weekStartsOnMonday) else {
                return nil
            }
            let prevStart = cal.date(byAdding: .day, value: -180, to: start) ?? start
            return (prevStart, start)
        case .days360:
            guard let start = startDate(now: now, calendar: cal, weekStartsOnMonday: weekStartsOnMonday) else {
                return nil
            }
            let prevStart = cal.date(byAdding: .day, value: -360, to: start) ?? start
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
