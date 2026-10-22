import Charts
import ReperaDomain
import SwiftUI

/// Real Apple Health heart-rate zones for the most recent finished workout.
/// The optional 0...10 number describes *intensity*, never quality/performance.
struct ProgressHeartZonesCard: View {
    let workouts: [WorkoutSession]
    @State private var zones: HealthKitStore.WorkoutHeartZones?

    private var latest: WorkoutSession? {
        workouts.filter { $0.finishedAt != nil }.max {
            ($0.finishedAt ?? .distantPast) < ($1.finishedAt ?? .distantPast)
        }
    }
    private let colors: [Color] = [OG.blue, OG.accent, OG.orange, OG.red, OG.red]

    var body: some View {
        Group {
            if let zones {
                let total = max(1.0, zones.zones.reduce(0) { $0 + $1.seconds })
                VStack(alignment: .leading, spacing: 8) {
                    OGCardSectionTitle(title: "Zonas cardíacas · último entreno")
                    OGCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(zones.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(OG.label)
                            GeometryReader { geometry in
                                let usableWidth = max(1.0, geometry.size.width - CGFloat(max(0, zones.zones.count - 1) * 2))
                                HStack(spacing: 2) {
                                    ForEach(zones.zones) { zone in
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(colors[(zone.index - 1) % colors.count])
                                            .frame(width: usableWidth * CGFloat(zone.seconds / total))
                                    }
                                }
                            }
                            .frame(height: 16)
                            HStack(spacing: 6) {
                                ForEach(zones.zones) { zone in
                                    VStack(spacing: 4) {
                                        Text("Z\(zone.index)")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(colors[(zone.index - 1) % colors.count])
                                        Text("\(Int((100 * zone.seconds / total).rounded()))%")
                                            .font(.caption2.monospacedDigit())
                                            .foregroundStyle(OG.label2)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            if let intensity = zones.intensityLoad {
                                Text("Carga cardiovascular: \(intensity)/10 · intensidad, no rendimiento")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(OG.label)
                            } else {
                                Text("Cobertura cardíaca insuficiente para estimar la intensidad.")
                                    .font(.caption).foregroundStyle(OG.label3)
                            }
                            Text("\(zones.source) · \(Int((zones.coveredFraction * 100).rounded()))% del tiempo cubierto. La nota v11 no cambia por el pulso.")
                                .font(.caption).foregroundStyle(OG.label3)
                        }
                    }
                }
            }
        }
        .task(id: latest?.id) {
            zones = nil
            guard let latest else { return }
            zones = await HealthKitStore.shared.heartZones(for: latest)
        }
    }
}

/// Cardio: FC mín / media / máx (series ya preparadas).
struct ProgressCardioChartCard: View {
    var prepared: ProgressPreparedCharts

    private var points: [ProgressPreparedCharts.HeartRatePlotPoint] { prepared.heartRate }
    private var granularity: ProgressSeriesGranularity { prepared.granularity }
    private var range: ProgressTimeRange { prepared.range }
    private var weekStartsOnMonday: Bool { prepared.weekStartsOnMonday }

    private var periodStats: (min: Double, avg: Double, max: Double)? {
        guard !points.isEmpty else { return nil }
        let minV = points.map(\.minBpm).min() ?? 0
        let maxV = points.map(\.maxBpm).max() ?? 0
        let avgV = points.map(\.avgBpm).reduce(0, +) / Double(points.count)
        return (minV, avgV, maxV)
    }

    private var yDomain: ClosedRange<Double> {
        guard let stats = periodStats else { return 60...160 }
        // Margen extra: catmullRom puede salirse del min/max de los puntos.
        let lo = max(40, stats.min - (prepared.isTeaserPreview ? 18 : 12))
        let hi = max(lo + 24, stats.max + (prepared.isTeaserPreview ? 22 : 14))
        return lo...hi
    }

    private var lineInterpolation: InterpolationMethod {
        // Preview free: catmullRom para curvas visibles (dominio Y ya va holgado + clip).
        .catmullRom
    }

    private var xDomain: ClosedRange<Date> {
        ProgressChartAxis.xDomain(
            points: points.map(\.date),
            range: range,
            weekStartsOnMonday: weekStartsOnMonday
        )
    }

    private var axisValues: [Date] {
        ProgressChartAxis.tickDates(points.map(\.date), range: range, granularity: granularity)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                OGCardSectionTitle(title: "Cardio")
                Spacer(minLength: 8)
                if prepared.isTeaserPreview {
                    Text("Ejemplo")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(OG.label2)
                        .accessibilityLabel("Ejemplo, datos ficticios")
                } else if let stats = periodStats {
                    Text("Media \(Int(stats.avg.rounded())) lpm")
                        .font(.system(size: 12, weight: .semibold).monospacedDigit())
                        .foregroundStyle(OG.label2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
            OGCard {
                VStack(alignment: .leading, spacing: 10) {
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
                                .interpolationMethod(lineInterpolation)

                                LineMark(
                                    x: .value("Día", point.date),
                                    y: .value("lpm", point.avgBpm),
                                    series: .value("Serie", "Media")
                                )
                                .foregroundStyle(Self.avgTint)
                                .lineStyle(StrokeStyle(lineWidth: 2.25, lineCap: .round, lineJoin: .round))
                                .interpolationMethod(lineInterpolation)

                                LineMark(
                                    x: .value("Día", point.date),
                                    y: .value("lpm", point.maxBpm),
                                    series: .value("Serie", "Máx")
                                )
                                .foregroundStyle(Self.maxTint)
                                .lineStyle(StrokeStyle(lineWidth: 1.75, lineCap: .round, lineJoin: .round))
                                .interpolationMethod(lineInterpolation)

                                if prepared.isTeaserPreview || points.count <= 4 {
                                    PointMark(
                                        x: .value("Día", point.date),
                                        y: .value("lpm", point.avgBpm)
                                    )
                                    .foregroundStyle(Self.avgTint)
                                    .symbolSize(prepared.isTeaserPreview ? 28 : (points.count == 1 ? 64 : 36))
                                }
                            }
                        }
                        .chartForegroundStyleScale([
                            "Mín": Self.minTint,
                            "Media": Self.avgTint,
                            "Máx": Self.maxTint
                        ])
                        .chartXScale(domain: xDomain)
                        .chartYScale(domain: yDomain)
                        .chartPlotStyle { $0.clipped() }
                        .chartXAxis {
                            AxisMarks(values: axisValues) { _ in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(OG.surface3)
                                AxisValueLabel(
                                    format: ProgressChartAxis.labelFormat(range: range, granularity: granularity),
                                    collisionResolution: .greedy
                                )
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

                        if !prepared.isTeaserPreview, let stats = periodStats {
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

/// Calorías: series ya preparadas.
struct ProgressCaloriesChartCard: View {
    var prepared: ProgressPreparedCharts

    private var points: [ProgressDayPoint] { prepared.calories }
    private var range: ProgressTimeRange { prepared.range }
    private var granularity: ProgressSeriesGranularity { prepared.granularity }
    private var weekStartsOnMonday: Bool { prepared.weekStartsOnMonday }
    private var total: Double { prepared.caloriesTotal }

    private var hasData: Bool { points.contains { $0.value > 0 } }

    private var yMax: Double {
        let peak = points.map(\.value).max() ?? 1
        let pad = prepared.isTeaserPreview ? 1.28 : 1.18
        return max(peak * pad, 1)
    }

    private var calorieInterpolation: InterpolationMethod { .catmullRom }

    private var xDomain: ClosedRange<Date> {
        ProgressChartAxis.xDomain(
            points: points.map(\.date),
            range: range,
            weekStartsOnMonday: weekStartsOnMonday
        )
    }

    private var axisValues: [Date] {
        ProgressChartAxis.tickDates(points.map(\.date), range: range, granularity: granularity)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                OGCardSectionTitle(title: "Calorías")
                Spacer(minLength: 8)
                if prepared.isTeaserPreview {
                    Text("Ejemplo")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(OG.label2)
                        .accessibilityLabel("Ejemplo, datos ficticios")
                } else if total > 0 {
                    Text("\(Int(total.rounded())) kcal")
                        .font(.system(size: 12, weight: .semibold).monospacedDigit())
                        .foregroundStyle(OG.label2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
            OGCard {
                VStack(alignment: .leading, spacing: 10) {
                    if hasData {
                        Chart {
                            ForEach(points) { point in
                                AreaMark(
                                    x: .value("Día", point.date),
                                    y: .value("kcal", point.value)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [OG.orange.opacity(0.32), OG.orange.opacity(0.02)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .interpolationMethod(calorieInterpolation)

                                LineMark(
                                    x: .value("Día", point.date),
                                    y: .value("kcal", point.value)
                                )
                                .foregroundStyle(OG.orange)
                                .lineStyle(StrokeStyle(lineWidth: 2.25, lineCap: .round, lineJoin: .round))
                                .interpolationMethod(calorieInterpolation)

                                if prepared.isTeaserPreview || points.count <= 4 {
                                    PointMark(
                                        x: .value("Día", point.date),
                                        y: .value("kcal", point.value)
                                    )
                                    .foregroundStyle(OG.orange)
                                    .symbolSize(prepared.isTeaserPreview ? 28 : (points.count == 1 ? 64 : 36))
                                }
                            }
                        }
                        .chartXScale(domain: xDomain)
                        .chartYScale(domain: 0...yMax)
                        .chartPlotStyle { $0.clipped() }
                        .chartXAxis {
                            AxisMarks(values: axisValues) { _ in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(OG.surface3)
                                AxisValueLabel(
                                    format: ProgressChartAxis.labelFormat(range: range, granularity: granularity),
                                    collisionResolution: .greedy
                                )
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
                        Text("Sin kcal de Salud en \(range.title.lowercased()).")
                            .font(.system(size: 13))
                            .foregroundStyle(OG.label3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                    }
                }
            }
        }
    }
}

/// Peso corporal vs objetivo (línea de meta + delta).
struct ProgressWeightChartCard: View {
    var entries: [BodyWeightEntry]
    var goalKg: Double?
    var range: ProgressTimeRange
    var weekStartsOnMonday: Bool = true
    /// Prepared stable points from ProgressSnapshot (preferred).
    var preparedPoints: [ProgressWeightPoint]? = nil
    /// Preview free: misma suavidad que cardio/kcal.
    var isTeaserPreview: Bool = false

    private var rawPoints: [BodyWeightEntry] {
        let start = range.startDate(now: Date(), weekStartsOnMonday: weekStartsOnMonday)
            ?? .distantPast
        let end = Calendar.current.date(
            byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())
        ) ?? Date()
        return entries
            .filter { $0.date >= start && $0.date < end }
            .sorted { $0.date < $1.date }
    }

    private var granularity: ProgressSeriesGranularity {
        ProgressSeriesGranularity.forChart(range: range)
    }

    private var points: [ProgressWeightPoint] {
        if let preparedPoints { return preparedPoints }
        let raw = rawPoints
        let mapped = ProgressDataEngine.buildWeightPoints(
            entries: raw,
            range: range,
            weekStartsOnMonday: weekStartsOnMonday
        )
        return mapped
    }

    private var latest: ProgressWeightPoint? { points.last }

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
            return "\(latest.weightKg.formatted(.number.precision(.fractionLength(1)))) kg"
        }
        return ""
    }

    private var yDomain: ClosedRange<Double> {
        var values = points.map(\.weightKg)
        if let goal = goalKg { values.append(goal) }
        guard let lo0 = values.min(), let hi0 = values.max() else {
            if let goal = goalKg { return (goal - 2)...(goal + 2) }
            return 60...90
        }
        let factor = isTeaserPreview ? 0.35 : 0.22
        let pad = max(isTeaserPreview ? 1.6 : 1.2, (hi0 - lo0) * factor)
        return (lo0 - pad)...max(lo0 - pad + 2, hi0 + pad)
    }

    private var xDomain: ClosedRange<Date> {
        ProgressChartAxis.xDomain(
            points: points.map(\.date),
            range: range,
            weekStartsOnMonday: weekStartsOnMonday
        )
    }

    private var deltaColor: Color { OG.label2 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                OGCardSectionTitle(title: "Peso")
                Spacer(minLength: 8)
                if isTeaserPreview {
                    Text("Ejemplo")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(OG.label2)
                        .accessibilityLabel("Ejemplo, datos ficticios")
                } else if !statusLine.isEmpty {
                    Text(statusLine)
                        .font(.system(size: 12, weight: .semibold).monospacedDigit())
                        .foregroundStyle(OG.label2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            OGCard {
                VStack(alignment: .leading, spacing: 10) {
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
                                .symbolSize(isTeaserPreview || points.count <= 8 ? 32 : 18)
                            }
                        }
                        .chartXScale(domain: xDomain)
                        .chartYScale(domain: yDomain)
                        .chartPlotStyle { $0.clipped() }
                        .chartXAxis {
                            AxisMarks(
                                values: ProgressChartAxis.tickDates(
                                    points.map(\.date),
                                    range: range,
                                    granularity: granularity
                                )
                            ) { _ in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(OG.surface3)
                                AxisValueLabel(
                                    format: ProgressChartAxis.labelFormat(range: range, granularity: granularity),
                                    collisionResolution: .greedy
                                )
                                .foregroundStyle(OG.label3)
                                .font(.system(size: 10))
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(OG.surface3)
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

/// Eje X / leyendas compartidas entre cards de Progreso.
enum ProgressChartAxis {
    static func rangeCaption(range: ProgressTimeRange, granularity: ProgressSeriesGranularity) -> String {
        switch granularity {
        case .day:
            return range.title.lowercased()
        case .week:
            return "\(range.title.lowercased()) · media sem."
        case .month:
            return "\(range.title.lowercased()) · media mens."
        }
    }

    /// Dominio X = periodo elegido; 1 punto → padding para que Chart pinte.
    static func xDomain(
        points: [Date],
        range: ProgressTimeRange,
        weekStartsOnMonday: Bool,
        now: Date = Date()
    ) -> ClosedRange<Date> {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        let start = range.startDate(now: now, weekStartsOnMonday: weekStartsOnMonday)
            ?? points.min()
            ?? today
        let end = today
        if start == end || points.count <= 1 {
            return start.addingTimeInterval(-12 * 3600)...end.addingTimeInterval(12 * 3600)
        }
        return start...end
    }

    static func labelFormat(range: ProgressTimeRange, granularity: ProgressSeriesGranularity) -> Date.FormatStyle {
        switch granularity {
        case .month:
            return .dateTime.month(.abbreviated).year(.twoDigits)
        case .week:
            return .dateTime.day().month(.abbreviated)
        case .day:
            switch range {
            case .today, .week:
                return .dateTime.weekday(.abbreviated)
            default:
                return .dateTime.day().month(.abbreviated)
            }
        }
    }

    static func tickDates(
        _ dates: [Date],
        range: ProgressTimeRange,
        granularity: ProgressSeriesGranularity
    ) -> [Date] {
        guard dates.count > 1 else { return dates }
        let stride: Int = {
            switch granularity {
            case .month:
                return max(1, dates.count / 6)
            case .week:
                return max(1, dates.count / 6)
            case .day:
                switch range {
                case .today: return 1
                case .week: return 1
                case .month: return max(1, dates.count / 6)
                default: return max(1, dates.count / 6)
                }
            }
        }()
        var out: [Date] = []
        for (i, d) in dates.enumerated() where i % stride == 0 || i == dates.count - 1 {
            if out.last != d { out.append(d) }
        }
        return out
    }
}
