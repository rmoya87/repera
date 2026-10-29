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

/// Subcontenido de Cardio: distribución de zonas del último entreno,
/// basada en Apple Salud. Nunca calcula pulsaciones ni notas ficticias en Pro.
struct ProgressHeartZonesCard: View {
    let workouts: [WorkoutSession]
    var isTeaserPreview: Bool = false
    @State private var zones: HealthKitStore.WorkoutHeartZones?

    private struct ZoneSlice: Identifiable {
        let index: Int
        let seconds: Double
        var id: Int { index }
    }

    private var latest: WorkoutSession? {
        workouts.filter { $0.finishedAt != nil }.max {
            ($0.finishedAt ?? .distantPast) < ($1.finishedAt ?? .distantPast)
        }
    }

    private let colors: [Color] = [OG.blue, OG.accent, OG.orange, OG.red, OG.red]

    var body: some View {
        Group {
            if isTeaserPreview {
                zoneContent(
                    title: "Entrenamiento de ejemplo · 35 min",
                    slices: [120, 420, 720, 570, 270].enumerated().map {
                        ZoneSlice(index: $0.offset + 1, seconds: Double($0.element))
                    },
                    intensity: 7,
                    coverage: nil,
                    isExample: true
                )
            } else if let zones {
                zoneContent(
                    title: zones.title,
                    slices: zones.zones.map {
                        ZoneSlice(index: $0.index, seconds: $0.seconds)
                    },
                    intensity: zones.intensityLoad,
                    coverage: "\(zones.source) · \(Int((zones.coveredFraction * 100).rounded()))% del tiempo cubierto",
                    isExample: false
                )
            } else {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Zonas cardíacas")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(OG.label)
                    Text("Sin zonas registradas en Apple Salud para el último entreno.")
                        .font(.caption)
                        .foregroundStyle(OG.label2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .task(id: latest?.id) {
            guard !isTeaserPreview else { return }
            zones = nil
            guard let latest else { return }
            zones = await HealthKitStore.shared.heartZones(for: latest)
        }
    }

    private func zoneContent(
        title: String,
        slices: [ZoneSlice],
        intensity: Int?,
        coverage: String?,
        isExample: Bool
    ) -> some View {
        let total = max(1.0, slices.reduce(0) { $0 + $1.seconds })
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Zonas cardíacas")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(OG.label)
                Spacer(minLength: 8)
                if isExample {
                    Text("Ejemplo")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(OG.label2)
                }
            }
            Text(title)
                .font(.caption)
                .foregroundStyle(OG.label2)

            // El porcentaje pertenece a su barra, no a una fila separada.
            GeometryReader { geometry in
                let usableWidth = max(0, geometry.size.width - CGFloat(max(0, slices.count - 1) * 2))
                HStack(spacing: 2) {
                    ForEach(slices) { slice in
                        let fraction = max(0, slice.seconds / total)
                        ZStack {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(colors[(max(1, slice.index) - 1) % colors.count])
                            if slice.seconds > 0 {
                                Text("\(Int((100 * fraction).rounded()))%")
                                    .font(.system(size: 10, weight: .bold).monospacedDigit())
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                                    .padding(.horizontal, 1)
                            }
                        }
                        .frame(width: usableWidth * CGFloat(fraction))
                        .accessibilityLabel("Zona \(slice.index), \(Int((100 * fraction).rounded())) por ciento")
                    }
                }
            }
            .frame(height: 28)

            HStack(spacing: 6) {
                ForEach(slices) { slice in
                    Text("Z\(slice.index)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(colors[(max(1, slice.index) - 1) % colors.count])
                        .frame(maxWidth: .infinity)
                }
            }

            if let intensity {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Intensidad cardiovascular")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(OG.label)
                        Text("Carga cardíaca, no nota de rendimiento")
                            .font(.caption)
                            .foregroundStyle(OG.label2)
                    }
                    Spacer(minLength: 0)
                    ZStack {
                        Circle()
                            .stroke(OG.surface3, lineWidth: 5)
                        Circle()
                            .trim(from: 0, to: CGFloat(min(10, max(0, intensity))) / 10)
                            .stroke(OG.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 0) {
                            Text("\(intensity)")
                                .font(.system(size: 22, weight: .bold).monospacedDigit())
                                .foregroundStyle(OG.label)
                            Text("/10")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(OG.label2)
                        }
                    }
                    .frame(width: 58, height: 58)
                    .accessibilityLabel("Intensidad cardiovascular: \(intensity) de 10")
                }
                .padding(12)
                .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                Text("Sin cobertura suficiente para valorar la intensidad cardiovascular.")
                    .font(.caption)
                    .foregroundStyle(OG.label2)
            }

            if let coverage {
                Text(coverage)
                    .font(.caption)
                    .foregroundStyle(OG.label3)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

/// Cardio: FC mín / media / máx (series ya preparadas).
struct ProgressCardioChartCard: View {
    var prepared: ProgressPreparedCharts
    var workouts: [WorkoutSession] = []
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
            OGCard(padding: 10, verticalPadding: 20) {
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
                        .frame(height: 190)
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
                            height: 190,
                            yRange: 60.0...160.0
                        )
                    }
                    Divider().opacity(0.35)
                    // Integrado debajo de los tres tiles FC: nunca otra tarjeta.
                    ProgressHeartZonesCard(
                        workouts: workouts,
                        isTeaserPreview: prepared.isTeaserPreview
                    )
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
    private var dailyAverage: Double? { prepared.caloriesDailyAverage }
    private var previousAverage: Double? { prepared.previousCaloriesDailyAverage }
    private var averageChange: Double? {
        guard let dailyAverage, let previousAverage, previousAverage > 0 else { return nil }
        return (dailyAverage / previousAverage - 1) * 100
    }

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
            OGCard(padding: 10, verticalPadding: 20) {
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
                        .frame(height: 210)
                        .frame(maxWidth: .infinity)
                    } else {
                        ProgressEmptyChart(
                            message: "Sin kcal de Salud en \(range.title.lowercased()).",
                            height: 210,
                            yRange: 0.0...600.0
                        )
                    }
                    HStack(spacing: 8) {
                        calorieStat(
                            title: "Media/día",
                            value: dailyAverage.map { "\(ReperaNumberFormat.integer(Int($0.rounded()))) kcal" } ?? "—"
                        )
                        calorieStat(
                            title: "Periodo ant.",
                            value: previousAverage.map { "\(ReperaNumberFormat.integer(Int($0.rounded()))) kcal" } ?? "—"
                        )
                        calorieStat(
                            title: "Variación",
                            value: averageChange.map {
                                "\($0 >= 0 ? "+" : "")\(Int($0.rounded())) %"
                            } ?? "—"
                        )
                    }
                    .padding(.top, 2)
                }
            }
        }
    }

    private func calorieStat(title: String, value: String) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(OG.label3)
            Text(value)
                .font(.system(size: 14, weight: .semibold).monospacedDigit())
                .foregroundStyle(OG.label)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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
                return "En objetivo (\(ReperaNumberFormat.decimal(goal)) kg)"
            }
            let sign = delta > 0 ? "+" : ""
            return "\(sign)\(ReperaNumberFormat.decimal(delta)) kg vs \(ReperaNumberFormat.decimal(goal))"
        }
        if let latest {
            return "\(ReperaNumberFormat.decimal(latest.weightKg)) kg"
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
            OGCard(padding: 10, verticalPadding: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    if points.isEmpty {
                        ProgressEmptyChart(
                            message: "Sin pesajes en \(range.title.lowercased()). Registra peso en Ajustes.",
                            height: 210,
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
                                        Text("\(ReperaNumberFormat.decimal(selectedPoint.weightKg)) kg")
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
                                        Text(ReperaNumberFormat.decimal(v))
                                            .font(.system(size: 10).monospacedDigit())
                                            .foregroundStyle(OG.label3)
                                    }
                                }
                            }
                        }
                        .frame(height: 210)

                    }
                    // Peso conserva la misma fila de estadísticas que Calorías,
                    // incluso sin objetivo configurado o sin lecturas.
                    HStack(spacing: 8) {
                        weightStat(
                            label: "Actual",
                            value: latest.map {
                                "\(ReperaNumberFormat.decimal($0.weightKg)) kg"
                            } ?? "—"
                        )
                        weightStat(
                            label: "Objetivo",
                            value: goalKg.map {
                                "\(ReperaNumberFormat.decimal($0)) kg"
                            } ?? "—"
                        )
                        weightStat(
                            label: "Δ",
                            value: deltaVsGoal.map {
                                "\($0 > 0 ? "+" : "")\(ReperaNumberFormat.decimal($0)) kg"
                            } ?? "—",
                            valueColor: deltaColor
                        )
                    }
                    .padding(.top, 2)
                }
            }
        }
    }

    private func weightStat(label: String, value: String, valueColor: Color = OG.label) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(OG.label3)
            Text(value)
                .font(.system(size: 14, weight: .semibold).monospacedDigit())
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .center)
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
        let format: Date.FormatStyle
        switch granularity {
        case .month:
            format = .dateTime.month(.abbreviated).year(.twoDigits)
        case .week:
            format = .dateTime.day().month(.abbreviated)
        case .day:
            switch range {
            case .today, .week:
                format = .dateTime.weekday(.abbreviated)
            default:
                format = .dateTime.day().month(.abbreviated)
            }
        }
        return format.locale(SpanishDate.appLocale)
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
