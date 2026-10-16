import Charts
import GymbroDomain
import SwiftUI

/// Cardio: FC mín / media / máx por día desde Salud (tres curvas).
struct ProgressCardioChartCard: View {
    var heartRateDays: [HealthKitStore.DailyHeartRatePoint]
    var range: ProgressTimeRange
    var weekStartsOnMonday: Bool = true

    private var points: [HealthKitStore.DailyHeartRatePoint] {
        heartRateDays.filter {
            range.contains($0.date, weekStartsOnMonday: weekStartsOnMonday)
        }
    }

    private var periodStats: (min: Double, avg: Double, max: Double)? {
        guard !points.isEmpty else { return nil }
        let minV = points.map(\.minBpm).min() ?? 0
        let maxV = points.map(\.maxBpm).max() ?? 0
        let avgV = points.map(\.avgBpm).reduce(0, +) / Double(points.count)
        return (minV, avgV, maxV)
    }

    private var yDomain: ClosedRange<Double> {
        guard let stats = periodStats else { return 60...160 }
        let lo = max(40, stats.min * 0.92)
        let hi = max(lo + 10, stats.max * 1.08)
        return lo...hi
    }

    private var xDomain: ClosedRange<Date> {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let start = range.startDate(now: Date(), weekStartsOnMonday: weekStartsOnMonday)
            ?? points.first?.date
            ?? today
        let end = points.last?.date ?? today
        guard start <= end else { return today...today }
        return start...end
    }

    private var axisValues: [Date] {
        guard points.count > 1 else { return points.map(\.date) }
        let stride: Int = {
            switch range {
            case .today: return 1
            case .week: return 1
            case .month: return max(1, points.count / 5)
            case .days90: return max(1, points.count / 6)
            case .all: return max(1, points.count / 6)
            }
        }()
        var out: [Date] = []
        for (i, p) in points.enumerated() where i % stride == 0 || i == points.count - 1 {
            if out.last != p.date { out.append(p.date) }
        }
        return out
    }

    private var axisFormat: Date.FormatStyle {
        switch range {
        case .today, .week:
            return .dateTime.weekday(.abbreviated)
        default:
            return .dateTime.day().month(.abbreviated)
        }
    }

    var body: some View {
        OGCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label {
                        Text("Cardio")
                            .foregroundStyle(OG.label)
                    } icon: {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(OG.red)
                    }
                    .font(.system(size: 15, weight: .semibold))
                    Spacer(minLength: 8)
                    if let stats = periodStats {
                        Text("media \(Int(stats.avg.rounded())) · \(range.title.lowercased())")
                            .font(.system(size: 12, weight: .semibold).monospacedDigit())
                            .foregroundStyle(OG.label2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }

                if !points.isEmpty {
                    Chart {
                        ForEach(points) { point in
                            LineMark(
                                x: .value("Día", point.date),
                                y: .value("lpm", point.minBpm),
                                series: .value("Serie", "Mín")
                            )
                            .foregroundStyle(Self.minTint)
                            .lineStyle(StrokeStyle(lineWidth: 1.75, lineCap: .round, lineJoin: .round))
                            .interpolationMethod(.catmullRom)

                            LineMark(
                                x: .value("Día", point.date),
                                y: .value("lpm", point.avgBpm),
                                series: .value("Serie", "Media")
                            )
                            .foregroundStyle(Self.avgTint)
                            .lineStyle(StrokeStyle(lineWidth: 2.25, lineCap: .round, lineJoin: .round))
                            .interpolationMethod(.catmullRom)

                            LineMark(
                                x: .value("Día", point.date),
                                y: .value("lpm", point.maxBpm),
                                series: .value("Serie", "Máx")
                            )
                            .foregroundStyle(Self.maxTint)
                            .lineStyle(StrokeStyle(lineWidth: 1.75, lineCap: .round, lineJoin: .round))
                            .interpolationMethod(.catmullRom)
                        }
                    }
                    .chartForegroundStyleScale([
                        "Mín": Self.minTint,
                        "Media": Self.avgTint,
                        "Máx": Self.maxTint
                    ])
                    .chartXScale(domain: xDomain)
                    .chartYScale(domain: yDomain)
                    .chartXAxis {
                        AxisMarks(values: axisValues) { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(OG.surface3)
                            AxisValueLabel(format: axisFormat, collisionResolution: .greedy)
                                .foregroundStyle(OG.label3)
                                .font(.system(size: 10))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(OG.surface3)
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("\(Int(v.rounded()))")
                                        .font(.system(size: 10))
                                        .foregroundStyle(OG.label3)
                                }
                            }
                        }
                    }
                    .chartLegend(.hidden)
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                    .clipped()

                    if let stats = periodStats {
                        HStack(spacing: 8) {
                            cardioStatPill(title: "Mín", value: stats.min, tint: Self.minTint)
                            cardioStatPill(title: "Media", value: stats.avg, tint: Self.avgTint)
                            cardioStatPill(title: "Máx", value: stats.max, tint: Self.maxTint)
                        }
                    }
                } else {
                    Text("Sin ritmo cardíaco de Salud en \(range.title.lowercased()).")
                        .font(.system(size: 13))
                        .foregroundStyle(OG.label3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
            }
        }
    }

    private static let minTint = OG.blue
    private static let avgTint = OG.red
    private static let maxTint = OG.orange

    private func cardioStatPill(title: String, value: Double, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(OG.label3)
            Text("\(Int(value.rounded()))")
                .font(.system(size: 18, weight: .semibold).monospacedDigit())
                .foregroundStyle(tint)
            Text("lpm")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(OG.label3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(OG.surface2.opacity(0.85), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

/// Calorías: kcal activas/día desde Salud (anillo de Movimiento + entrenos).
struct ProgressCaloriesChartCard: View {
    var energyDays: [HealthKitStore.DailyActiveEnergyPoint]
    var workouts: [WorkoutSession]
    var external: [ExternalDaySample]
    var range: ProgressTimeRange
    var weekStartsOnMonday: Bool = true

    /// Preferir agregados diarios de Salud; si aún no hay caché, fallback a series Gymbro+entrenos.
    private var points: [ProgressDayPoint] {
        let fromHealth = energyDays.filter {
            range.contains($0.date, weekStartsOnMonday: weekStartsOnMonday)
        }
        if !fromHealth.isEmpty {
            let df = Self.dayKeyFormatter
            let cal = Calendar.current
            let today = cal.startOfDay(for: Date())
            let start = range.startDate(now: Date(), weekStartsOnMonday: weekStartsOnMonday)
                ?? fromHealth.map(\.date).min()
                ?? today
            var buckets: [String: (date: Date, value: Double)] = [:]
            var cursor = start
            while cursor <= today {
                let key = df.string(from: cursor)
                buckets[key] = (cursor, 0)
                guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
                cursor = next
                if buckets.count > 400 { break }
            }
            for day in fromHealth {
                let dayStart = cal.startOfDay(for: day.date)
                let key = df.string(from: dayStart)
                buckets[key] = (dayStart, day.kcal)
            }
            return buckets.values
                .map { ProgressDayPoint(dayKey: df.string(from: $0.date), date: $0.date, value: $0.value) }
                .sorted { $0.date < $1.date }
        }
        return StatsEngine.dailyMetricSeries(
            workouts: workouts,
            external: external,
            metric: .activeEnergyKcal,
            range: range,
            weekStartsOnMonday: weekStartsOnMonday
        )
    }

    private var total: Double { points.reduce(0) { $0 + $1.value } }

    private static let dayKeyFormatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = Calendar.current
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = Calendar.current.timeZone
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    var body: some View {
        ProgressTrendCard(
            title: "Calorías",
            systemImage: "flame.fill",
            tint: OG.orange,
            unitLabel: "kcal",
            summary: total > 0 ? "\(Int(total.rounded())) kcal · \(range.title.lowercased())" : nil,
            points: points,
            range: range,
            weekStartsOnMonday: weekStartsOnMonday,
            emptyText: "Sin kcal de Salud en \(range.title.lowercased())."
        )
    }
}

private struct ProgressTrendCard: View {
    var title: String
    var systemImage: String
    var tint: Color
    var unitLabel: String
    var summary: String?
    var points: [ProgressDayPoint]
    var range: ProgressTimeRange
    var weekStartsOnMonday: Bool
    var emptyText: String

    private var hasData: Bool {
        points.contains { $0.value > 0 }
    }

    private var yMax: Double {
        let peak = points.map(\.value).max() ?? 1
        return max(peak * 1.12, 1)
    }

    private var xDomain: ClosedRange<Date> {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let start = range.startDate(now: Date(), weekStartsOnMonday: weekStartsOnMonday)
            ?? points.first?.date
            ?? today
        let end = points.last?.date ?? today
        guard start <= end else { return today...today }
        return start...end
    }

    private var axisValues: [Date] {
        guard points.count > 1 else { return points.map(\.date) }
        let stride: Int = {
            switch range {
            case .today: return 1
            case .week: return 1
            case .month: return max(1, points.count / 5)
            case .days90: return max(1, points.count / 6)
            case .all: return max(1, points.count / 6)
            }
        }()
        var out: [Date] = []
        for (i, p) in points.enumerated() where i % stride == 0 || i == points.count - 1 {
            if out.last != p.date { out.append(p.date) }
        }
        return out
    }

    var body: some View {
        OGCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label {
                        Text(title)
                            .foregroundStyle(OG.label)
                    } icon: {
                        Image(systemName: systemImage)
                            .foregroundStyle(tint)
                    }
                    .font(.system(size: 15, weight: .semibold))
                    Spacer(minLength: 8)
                    if let summary {
                        Text(summary)
                            .font(.system(size: 12, weight: .semibold).monospacedDigit())
                            .foregroundStyle(OG.label2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }

                if hasData {
                    Chart {
                        ForEach(points) { point in
                            AreaMark(
                                x: .value("Día", point.date),
                                y: .value(unitLabel, point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [tint.opacity(0.32), tint.opacity(0.02)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)

                            LineMark(
                                x: .value("Día", point.date),
                                y: .value(unitLabel, point.value)
                            )
                            .foregroundStyle(tint)
                            .lineStyle(StrokeStyle(lineWidth: 2.25, lineCap: .round, lineJoin: .round))
                            .interpolationMethod(.catmullRom)
                        }
                    }
                    .chartXScale(domain: xDomain)
                    .chartYScale(domain: 0...yMax)
                    .chartXAxis {
                        AxisMarks(values: axisValues) { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(OG.surface3)
                            AxisValueLabel(format: axisFormat, collisionResolution: .greedy)
                                .foregroundStyle(OG.label3)
                                .font(.system(size: 10))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(OG.surface3)
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("\(Int(v.rounded()))")
                                        .font(.system(size: 10))
                                        .foregroundStyle(OG.label3)
                                }
                            }
                        }
                    }
                    .chartLegend(.hidden)
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                    .clipped()
                } else {
                    Text(emptyText)
                        .font(.system(size: 13))
                        .foregroundStyle(OG.label3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
            }
        }
    }

    private var axisFormat: Date.FormatStyle {
        switch range {
        case .today, .week:
            return .dateTime.weekday(.abbreviated)
        default:
            return .dateTime.day().month(.abbreviated)
        }
    }
}

/// Peso corporal vs objetivo (línea de meta + delta).
struct ProgressWeightChartCard: View {
    var entries: [BodyWeightEntry]
    var goalKg: Double?
    var range: ProgressTimeRange
    var weekStartsOnMonday: Bool = true

    private var points: [BodyWeightEntry] {
        entries
            .filter { range.contains($0.date, weekStartsOnMonday: weekStartsOnMonday) }
            .sorted { $0.date < $1.date }
    }

    private var latest: BodyWeightEntry? {
        points.last ?? entries.sorted { $0.date < $1.date }.last
    }

    private var deltaVsGoal: Double? {
        guard let goal = goalKg, let latest else { return nil }
        return latest.weightKg - goal
    }

    private var statusLine: String {
        if let delta = deltaVsGoal, let goal = goalKg {
            if abs(delta) < 0.3 {
                return "En objetivo (\(goal.formatted(.number.precision(.fractionLength(1)))) kg)"
            }
            let sign = delta > 0 ? "+" : ""
            return "\(sign)\(delta.formatted(.number.precision(.fractionLength(1)))) kg vs \(goal.formatted(.number.precision(.fractionLength(1))))"
        }
        if let latest {
            return "\(latest.weightKg.formatted(.number.precision(.fractionLength(1)))) kg · \(range.title.lowercased())"
        }
        return range.title.lowercased()
    }

    private var yDomain: ClosedRange<Double> {
        var values = points.map(\.weightKg)
        if let goal = goalKg { values.append(goal) }
        guard let lo0 = values.min(), let hi0 = values.max() else {
            if let goal = goalKg { return (goal - 2)...(goal + 2) }
            return 60...90
        }
        let pad = max(1, (hi0 - lo0) * 0.12)
        let lo = lo0 - pad
        let hi = max(lo + 2, hi0 + pad)
        return lo...hi
    }

    private var xDomain: ClosedRange<Date> {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let start = range.startDate(now: Date(), weekStartsOnMonday: weekStartsOnMonday)
            ?? points.first?.date
            ?? today
        let end = points.last?.date ?? today
        guard start <= end else { return today...today }
        return start...end
    }

    private var axisValues: [Date] {
        guard points.count > 1 else { return points.map(\.date) }
        let stride: Int = {
            switch range {
            case .today, .week: return 1
            case .month: return max(1, points.count / 5)
            case .days90, .all: return max(1, points.count / 6)
            }
        }()
        var out: [Date] = []
        for (i, p) in points.enumerated() where i % stride == 0 || i == points.count - 1 {
            if out.last != p.date { out.append(p.date) }
        }
        return out
    }

    private var axisFormat: Date.FormatStyle {
        switch range {
        case .today, .week:
            return .dateTime.weekday(.abbreviated)
        default:
            return .dateTime.day().month(.abbreviated)
        }
    }

    private var deltaColor: Color {
        guard let delta = deltaVsGoal else { return OG.label2 }
        if abs(delta) < 0.3 { return OG.accent }
        return OG.yellow
    }

    var body: some View {
        OGCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label {
                        Text("Peso")
                            .foregroundStyle(OG.label)
                    } icon: {
                        Image(systemName: "scalemass.fill")
                            .foregroundStyle(OG.accent)
                    }
                    .font(.system(size: 15, weight: .semibold))
                    Spacer(minLength: 8)
                    Text(statusLine)
                        .font(.system(size: 12, weight: .semibold).monospacedDigit())
                        .foregroundStyle(deltaColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                if points.isEmpty {
                    Text(goalKg == nil
                         ? "Sin pesajes en \(range.title.lowercased()). Registra peso en Ajustes."
                         : "Sin pesajes en \(range.title.lowercased()). Objetivo \(goalKg!.formatted(.number.precision(.fractionLength(1)))) kg.")
                        .font(.system(size: 14))
                        .foregroundStyle(OG.label2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 20)
                } else {
                    Chart {
                        if let goal = goalKg {
                            RuleMark(y: .value("Objetivo", goal))
                                .foregroundStyle(OG.yellow.opacity(0.85))
                                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                                .annotation(position: .top, alignment: .trailing) {
                                    Text("Meta")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(OG.yellow)
                                }
                        }

                        ForEach(points) { entry in
                            LineMark(
                                x: .value("Fecha", entry.date),
                                y: .value("kg", entry.weightKg)
                            )
                            .foregroundStyle(OG.accent)
                            .lineStyle(StrokeStyle(lineWidth: 2.25, lineCap: .round, lineJoin: .round))
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Fecha", entry.date),
                                y: .value("kg", entry.weightKg)
                            )
                            .foregroundStyle(OG.accent)
                            .symbolSize(36)
                        }
                    }
                    .chartXScale(domain: xDomain)
                    .chartYScale(domain: yDomain)
                    .chartXAxis {
                        AxisMarks(values: axisValues) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Color.white.opacity(0.06))
                            AxisValueLabel {
                                if let d = value.as(Date.self) {
                                    Text(d, format: axisFormat)
                                        .font(.system(size: 10))
                                        .foregroundStyle(OG.label3)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Color.white.opacity(0.06))
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text(v.formatted(.number.precision(.fractionLength(0...1))))
                                        .font(.system(size: 10).monospacedDigit())
                                        .foregroundStyle(OG.label3)
                                }
                            }
                        }
                    }
                    .frame(height: 168)

                    if let latest, let goal = goalKg, let delta = deltaVsGoal {
                        HStack(spacing: 12) {
                            weightStat(
                                label: "Actual",
                                value: "\(latest.weightKg.formatted(.number.precision(.fractionLength(1)))) kg"
                            )
                            weightStat(
                                label: "Objetivo",
                                value: "\(goal.formatted(.number.precision(.fractionLength(1)))) kg"
                            )
                            weightStat(
                                label: "Δ",
                                value: {
                                    let sign = delta > 0 ? "+" : ""
                                    return "\(sign)\(delta.formatted(.number.precision(.fractionLength(1)))) kg"
                                }(),
                                valueColor: deltaColor
                            )
                        }
                        .padding(.top, 2)
                    }
                }
            }
        }
    }

    private func weightStat(label: String, value: String, valueColor: Color = OG.label) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(OG.label3)
            Text(value)
                .font(.system(size: 14, weight: .semibold).monospacedDigit())
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
