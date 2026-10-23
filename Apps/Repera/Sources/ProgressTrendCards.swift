import Charts
import ReperaDomain
import SwiftUI

/// Mantiene las dimensiones y el eje de una gráfica sin simular observaciones.
struct ProgressEmptyChart: View {
    var message: String
    var height: CGFloat = 150
    var yRange: ClosedRange<Double> = 0.0...10.0

    var body: some View {
        ZStack {
            Chart {
                RuleMark(y: .value("Base", yRange.lowerBound))
                    .foregroundStyle(Color.clear)
            }
            .chartYScale(domain: yRange)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(
                    position: .leading,
                    values: [yRange.lowerBound, (yRange.lowerBound + yRange.upperBound) / 2, yRange.upperBound]
                ) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.6, dash: [3, 4]))
                        .foregroundStyle(OG.surface3)
                    AxisValueLabel()
                }
            }
            .frame(height: height)
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(OG.label2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Real Apple Health heart-rate zones for the most recent finished workout.
/// The optional 0...10 number describes *intensity*, never quality/performance.
struct ProgressHeartZonesCard: View {
    let workouts: [WorkoutSession]
    var isTeaserPreview: Bool = false
    @State private var zones: HealthKitStore.WorkoutHeartZones?

    private var latest: WorkoutSession? {
        workouts.filter { $0.finishedAt != nil }.max {
            ($0.finishedAt ?? .distantPast) < ($1.finishedAt ?? .distantPast)
        }
    }
    private let colors: [Color] = [OG.blue, OG.accent, OG.orange, OG.red, OG.red]

    var body: some View {
        Group {
            if isTeaserPreview {
                // Misma composición que la tarjeta real, pero con muestras
                // inventadas y una etiqueta inequívoca de ejemplo.
                let previewSeconds: [Double] = [120, 420, 720, 570, 270]
                let total = previewSeconds.reduce(0, +)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        OGCardSectionTitle(title: "Zonas cardíacas · último entreno")
                        Spacer()
                        Text("Ejemplo")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(OG.label2)
                            .accessibilityLabel("Ejemplo, zonas ficticias")
                    }
                    OGCard(padding: 10) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Entrenamiento de ejemplo · 35 min")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(OG.label)
                            GeometryReader { geometry in
                                let usableWidth = max(1.0, geometry.size.width - CGFloat((previewSeconds.count - 1) * 2))
                                HStack(spacing: 2) {
                                    ForEach(previewSeconds.indices, id: \.self) { index in
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(colors[index % colors.count])
                                            .frame(width: usableWidth * CGFloat(previewSeconds[index] / total))
                                    }
                                }
                            }
                            .frame(height: 16)
                            HStack(spacing: 6) {
                                ForEach(previewSeconds.indices, id: \.self) { index in
                                    VStack(spacing: 4) {
                                        Text("Z\(index + 1)")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(colors[index % colors.count])
                                        Text("\(Int((100 * previewSeconds[index] / total).rounded()))%")
                                            .font(.caption2.monospacedDigit())
                                            .foregroundStyle(OG.label2)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            Text("Carga cardiovascular: 7/10 · intensidad, no rendimiento")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(OG.label)
                            Text("Ejemplo · 100% del tiempo cubierto")
                                .font(.caption)
                                .foregroundStyle(OG.label3)
                        }
                    }
                }
                .accessibilityLabel("Ejemplo de zonas cardíacas, datos ficticios.")
            } else if let zones {
                let total = max(1.0, zones.zones.reduce(0) { $0 + $1.seconds })
                VStack(alignment: .leading, spacing: 8) {
                    OGCardSectionTitle(title: "Zonas cardíacas · último entreno")
                    OGCard(padding: 10) {
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
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    OGCardSectionTitle(title: "Zonas cardíacas · último entreno")
                    OGCard {
                        ProgressEmptyChart(
                            message: "Sin zonas cardíacas registradas para el último entreno."
                        )
                    }
                }
            }
        }
        .task(id: latest?.id) {
            guard !isTeaserPreview else { return }
            zones = nil
            guard let latest else { return }
            zones = await HealthKitStore.shared.heartZones(for: latest)
        }
    }
}

/// Cardio: FC mín / media / máx (series ya preparadas).
struct ProgressCardioChartCard: View {
    var prepared: ProgressPreparedCharts
    @State private var selectedDate: Date?

    private var points: [ProgressPreparedCharts.HeartRatePlotPoint] { prepared.heartRate }
    private var selectedPoint: ProgressPreparedCharts.HeartRatePlotPoint? {
        guard let selectedDate else { return nil }
        return points.min { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) }
    }
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
            weekStartsOnMonday: weekStartsOnMonday,
            isTeaserPreview: prepared.isTeaserPreview
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
            OGCard(padding: 10) {
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

                            }
                            if let selectedPoint {
                                RuleMark(x: .value("Día seleccionado", selectedPoint.date))
                                    .foregroundStyle(OG.label2)
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4]))
                                    .annotation(position: .top, alignment: .center) {
                                        Text("\(Int(selectedPoint.avgBpm.rounded())) lpm")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(OG.label)
                                            .padding(5)
                                            .background(OG.surface, in: RoundedRectangle(cornerRadius: 6))
                                    }
                            }
                        }
                        .chartForegroundStyleScale([
                            "Mín": Self.minTint,
                            "Media": Self.avgTint,
                            "Máx": Self.maxTint
                        ])
                        .chartXScale(domain: xDomain)
                        .chartXSelection(value: $selectedDate)
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

                        if let stats = periodStats {
                            HStack(spacing: 8) {
                                cardioStatPill(title: "Mín", value: stats.min, tint: Self.minTint)
                                cardioStatPill(title: "Media", value: stats.avg, tint: Self.avgTint)
                                cardioStatPill(title: "Máx", value: stats.max, tint: Self.maxTint)
                            }
                        }
                    } else {
                        ProgressEmptyChart(
                            message: "Sin ritmo cardíaco de Salud en \(range.title.lowercased()).",
                            height: 140,
                            yRange: 60.0...160.0
                        )
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
    @State private var selectedDate: Date?

    private var points: [ProgressDayPoint] { prepared.calories }
    private var selectedPoint: ProgressDayPoint? {
        guard let selectedDate else { return nil }
        return points.min { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) }
    }
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
            weekStartsOnMonday: weekStartsOnMonday,
            isTeaserPreview: prepared.isTeaserPreview
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
                    Text("Ejemplo · \(Int(total.rounded())) kcal")
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
            OGCard(padding: 10) {
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

                            }
                            if let selectedPoint {
                                RuleMark(x: .value("Día seleccionado", selectedPoint.date))
                                    .foregroundStyle(OG.label2)
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4]))
                                    .annotation(position: .top, alignment: .center) {
                                        Text("\(Int(selectedPoint.value.rounded())) kcal")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(OG.label)
                                            .padding(5)
                                            .background(OG.surface, in: RoundedRectangle(cornerRadius: 6))
                                    }
                            }
                        }
                        .chartXScale(domain: xDomain)
                        .chartXSelection(value: $selectedDate)
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
                    } else {
                        ProgressEmptyChart(
                            message: "Sin kcal de Salud en \(range.title.lowercased()).",
                            height: 140,
                            yRange: 0.0...600.0
                        )
                    }
                }
            }
        }
    }
}

/// Peso corporal vs objetivo (línea de meta + delta).
struct ProgressWeightChartCard: View {
    var entries: [BodyWeightEntry]
    @State private var selectedDate: Date?
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
    private var selectedPoint: ProgressWeightPoint? {
        guard let selectedDate else { return nil }
        return points.min { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) }
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
            weekStartsOnMonday: weekStartsOnMonday,
            isTeaserPreview: isTeaserPreview
        )
    }

    private var deltaColor: Color { OG.label2 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                OGCardSectionTitle(title: "Peso")
                Spacer(minLength: 8)
                if isTeaserPreview {
                    Text("Ejemplo · \(statusLine)")
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
            OGCard(padding: 10) {
                VStack(alignment: .leading, spacing: 10) {
                    if points.isEmpty {
                        ProgressEmptyChart(
                            message: "Sin pesajes en \(range.title.lowercased()). Registra peso en Ajustes.",
                            height: 168,
                            yRange: yDomain
                        )
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

                            }
                            if let selectedPoint {
                                RuleMark(x: .value("Día seleccionado", selectedPoint.date))
                                    .foregroundStyle(OG.label2)
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4]))
                                    .annotation(position: .top, alignment: .center) {
                                        Text("\(selectedPoint.weightKg.formatted(.number.precision(.fractionLength(1)))) kg")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(OG.label)
                                            .padding(5)
                                            .background(OG.surface, in: RoundedRectangle(cornerRadius: 6))
                                    }
                            }
                        }
                        .chartXScale(domain: xDomain)
                        .chartXSelection(value: $selectedDate)
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
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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
        now: Date = Date(),
        isTeaserPreview: Bool = false
    ) -> ClosedRange<Date> {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        if isTeaserPreview, let first = points.min(), let last = points.max() {
            // Ejemplos = últimos 7 días. Pueden cruzar el inicio de
            // la semana real; añadir espacio a ambos lados del trazado.
            let halfDay: TimeInterval = 12 * 60 * 60
            return first.addingTimeInterval(-halfDay)...last.addingTimeInterval(halfDay)
        }
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
