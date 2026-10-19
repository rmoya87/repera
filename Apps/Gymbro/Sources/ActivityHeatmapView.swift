import GymbroDomain
import SwiftUI

enum HeatmapMetric: String, CaseIterable, Identifiable {
    case time
    case volume

    var id: String { rawValue }

    var title: String {
        switch self {
        case .time: return "Tiempo"
        case .volume: return "Volumen"
        }
    }
}

/// Heatmap de actividad. Periodos cortos = franja horizontal; largos = rejilla semanal.
/// Las celdas escalan para ocupar el ancho de la línea temporal.
struct ActivityHeatmapView: View {
    var workouts: [WorkoutSession]
    var external: [ExternalDaySample]
    /// Bumps when workout/external *content* changes without changing `.count`.
    var dataRevision: Int = 0
    /// When set, skip async rebuild and switch instantly between time/volume.
    var preparedTime: HeatmapGrid? = nil
    var preparedVolume: HeatmapGrid? = nil
    var range: ProgressTimeRange = .week
    var weekStartsOnMonday: Bool = true
    var metric: HeatmapMetric = .time
    var onMetricChange: ((HeatmapMetric) -> Void)? = nil

    @State private var grid: HeatmapGrid = .empty
    /// Evita re-scroll horizontal cada vez que el heatmap reaparece en el ScrollView padre.
    @State private var didScrollToEnd = false

    private var preparedGrid: HeatmapGrid? {
        switch metric {
        case .time: return preparedTime
        case .volume: return preparedVolume
        }
    }

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = weekStartsOnMonday ? 2 : 1
        return cal
    }

    private var isStrip: Bool {
        range == .today || range == .week
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Métrica", selection: Binding(
                get: { metric },
                set: { onMetricChange?($0) }
            )) {
                ForEach(HeatmapMetric.allCases) { m in
                    Text(m.title).tag(m)
                }
            }
            .pickerStyle(.segmented)

            GeometryReader { geo in
                let layout = HeatmapLayout.resolve(
                    availableWidth: geo.size.width,
                    columnCount: max(1, grid.columns.count),
                    rowCount: max(1, grid.rowCount),
                    preferStrip: isStrip
                )
                VStack(alignment: .leading, spacing: 4) {
                    if !isStrip {
                        monthLabelsRow(layout: layout)
                    }
                    heatmapScrollable(layout: layout)
                    if isStrip {
                        dayLabelsRow(layout: layout)
                    }
                }
                .frame(width: geo.size.width, alignment: .leading)
            }
            .frame(height: estimatedHeight)

            HStack(spacing: 6) {
                Text(metric == .volume ? "Menos volumen" : "Menos tiempo")
                    .font(.system(size: 11))
                    .foregroundStyle(OG.label3)
                ForEach(0...4, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(BodyMapPalette.fill(level: level))
                        .frame(width: 11, height: 11)
                }
                Text(metric == .volume ? "Más volumen" : "Más tiempo")
                    .font(.system(size: 11))
                    .foregroundStyle(OG.label3)
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear { applyPreparedOrRebuild() }
        .onChange(of: metric) { _, _ in applyPreparedOrRebuild() }
        .onChange(of: dataRevision) { _, _ in applyPreparedOrRebuild() }
        .onChange(of: range) { _, _ in didScrollToEnd = false }
        .task(id: rebuildKey) {
            if preparedGrid != nil {
                applyPreparedOrRebuild()
                return
            }
            let workouts = self.workouts
            let external = self.external
            let metric = self.metric
            let range = self.range
            let cal = calendar
            let built = await Task.detached(priority: .userInitiated) {
                let agg = StatsEngine.dailyActivity(workouts: workouts, external: external, calendar: cal)
                return HeatmapGrid.build(agg: agg, metric: metric, range: range, calendar: cal)
            }.value
            grid = built
        }
    }

    private func applyPreparedOrRebuild() {
        if let preparedGrid {
            grid = preparedGrid
        }
    }

    private var estimatedHeight: CGFloat {
        let layout = HeatmapLayout.resolve(
            availableWidth: 340,
            columnCount: max(1, grid.columns.count),
            rowCount: max(1, grid.rowCount),
            preferStrip: isStrip
        )
        return layout.canvasHeight + (isStrip ? 18 : 16)
    }

    private var rebuildKey: String {
        "\(metric.rawValue)|\(range.rawValue)|\(weekStartsOnMonday)|\(dataRevision)|\(workouts.count)|\(external.count)"
    }

    @ViewBuilder
    private func heatmapScrollable(layout: HeatmapLayout.Metrics) -> some View {
        let canvas = HeatmapCanvas(grid: grid, cell: layout.cell, gap: layout.gap, isStrip: isStrip)
            .frame(width: layout.canvasWidth, height: layout.canvasHeight)

        if layout.needsScroll {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: layout.gap) {
                        if !isStrip { weekDayGutter(layout: layout) }
                        canvas.id("hm-end")
                    }
                }
                .onAppear {
                    guard !didScrollToEnd else { return }
                    didScrollToEnd = true
                    proxy.scrollTo("hm-end", anchor: .trailing)
                }
            }
        } else {
            HStack(alignment: .top, spacing: layout.gap) {
                if !isStrip { weekDayGutter(layout: layout) }
                canvas
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func weekDayGutter(layout: HeatmapLayout.Metrics) -> some View {
        let labels = ["", "L", "", "X", "", "V", ""]
        return VStack(spacing: layout.gap) {
            ForEach(0..<7, id: \.self) { i in
                Text(labels[i])
                    .font(.system(size: 9))
                    .foregroundStyle(OG.label3)
                    .frame(width: layout.labelWidth, height: layout.cell, alignment: .trailing)
            }
        }
    }

    private func monthLabelsRow(layout: HeatmapLayout.Metrics) -> some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: layout.labelWidth + layout.gap, height: 12)
            ForEach(Array(grid.monthLabels.enumerated()), id: \.offset) { _, label in
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(OG.label3)
                    .frame(width: layout.cell + layout.gap, alignment: .leading)
            }
        }
    }

    private func dayLabelsRow(layout: HeatmapLayout.Metrics) -> some View {
        HStack(spacing: layout.gap) {
            ForEach(Array(grid.dayLabels.enumerated()), id: \.offset) { _, label in
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(OG.label3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: layout.cell, alignment: .center)
            }
        }
    }
}

// MARK: - Layout

private enum HeatmapLayout {
    struct Metrics {
        var cell: CGFloat
        var gap: CGFloat
        var labelWidth: CGFloat
        var columnCount: Int
        var rowCount: Int
        var needsScroll: Bool

        var canvasWidth: CGFloat {
            CGFloat(columnCount) * cell + CGFloat(max(0, columnCount - 1)) * gap
        }

        var canvasHeight: CGFloat {
            CGFloat(rowCount) * cell + CGFloat(max(0, rowCount - 1)) * gap
        }
    }

    static func resolve(
        availableWidth: CGFloat,
        columnCount: Int,
        rowCount: Int,
        preferStrip: Bool
    ) -> Metrics {
        let cols = max(1, columnCount)
        let rows = max(1, rowCount)
        let labelWidth: CGFloat = preferStrip ? 0 : 14
        let gapRatio: CGFloat = preferStrip ? 0.12 : 0.2
        let minCell: CGFloat = preferStrip ? 28 : 11

        let usable = max(40, availableWidth - labelWidth - (preferStrip ? 0 : 4))
        let ideal = usable / (CGFloat(cols) + gapRatio * CGFloat(max(0, cols - 1)))

        if ideal < minCell {
            return Metrics(
                cell: minCell,
                gap: preferStrip ? 4 : 3,
                labelWidth: labelWidth,
                columnCount: cols,
                rowCount: rows,
                needsScroll: true
            )
        }

        let cell = ideal
        return Metrics(
            cell: cell,
            gap: max(2, cell * gapRatio),
            labelWidth: labelWidth,
            columnCount: cols,
            rowCount: rows,
            needsScroll: false
        )
    }
}

private struct HeatmapCanvas: View {
    var grid: HeatmapGrid
    var cell: CGFloat
    var gap: CGFloat
    var isStrip: Bool

    var body: some View {
        Canvas { context, _ in
            let radius = max(2, min(8, cell * 0.2))
            for (colIdx, col) in grid.columns.enumerated() {
                let x = CGFloat(colIdx) * (cell + gap)
                let levels = isStrip ? Array(col.levels.prefix(1)) : col.levels
                for (row, level) in levels.enumerated() {
                    let y = CGFloat(row) * (cell + gap)
                    let rect = CGRect(x: x, y: y, width: cell, height: cell)
                    let path = Path(roundedRect: rect, cornerRadius: radius)
                    var color = BodyMapPalette.fill(level: level)
                    let future = isStrip ? (col.future.first ?? false) : col.future[row]
                    let today = isStrip ? (col.today.first ?? false) : col.today[row]
                    if future { color = color.opacity(0.25) }
                    context.fill(path, with: .color(color))
                    if today {
                        context.stroke(
                            path,
                            with: .color(.white.opacity(0.75)),
                            lineWidth: max(1, cell * 0.05)
                        )
                    }
                }
            }
        }
    }
}

struct HeatmapGrid: Sendable, Equatable {
    static let empty = HeatmapGrid(columns: [], monthLabels: [], dayLabels: [], rowCount: 7)

    struct Column: Sendable, Equatable {
        var levels: [Int]
        var today: [Bool]
        var future: [Bool]
    }

    var columns: [Column]
    var monthLabels: [String]
    var dayLabels: [String]
    var rowCount: Int

    static func build(
        agg: [String: DayActivityContribution],
        metric: HeatmapMetric,
        range: ProgressTimeRange,
        calendar: Calendar,
        now: Date = Date()
    ) -> HeatmapGrid {
        switch range {
        case .today, .week:
            return buildStrip(agg: agg, metric: metric, range: range, calendar: calendar, now: now)
        case .month, .days90, .days180, .days360:
            return buildWeekGrid(agg: agg, metric: metric, range: range, calendar: calendar, now: now)
        }
    }

    /// Una fila de días (hoy / semana) — se estira a lo ancho.
    private static func buildStrip(
        agg: [String: DayActivityContribution],
        metric: HeatmapMetric,
        range: ProgressTimeRange,
        calendar: Calendar,
        now: Date
    ) -> HeatmapGrid {
        let values: [Double] = agg.values.map { metric == .time ? $0.minutes : $0.volumeKg }
        let thresholds = StatsEngine.heatmapThresholds(values: values)
        let df = DateFormatter()
        df.calendar = calendar
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        let dayFmt = DateFormatter()
        dayFmt.locale = Locale(identifier: "es_ES")
        dayFmt.dateFormat = "EEE"

        let today = calendar.startOfDay(for: now)
        guard let start = range.startDate(now: now, calendar: calendar) ?? Optional(today) else {
            return .empty
        }

        var columns: [Column] = []
        var dayLabels: [String] = []
        var cursor = start
        while cursor <= today {
            let key = df.string(from: cursor)
            let row = agg[key]
            let value = metric == .time ? (row?.minutes ?? 0) : (row?.volumeKg ?? 0)
            let level = StatsEngine.heatmapLevel(
                value: value,
                hasActivity: row != nil,
                thresholds: thresholds
            )
            columns.append(Column(
                levels: [level],
                today: [calendar.isDate(cursor, inSameDayAs: today)],
                future: [cursor > today]
            ))
            dayLabels.append(dayFmt.string(from: cursor).replacingOccurrences(of: ".", with: ""))
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
            if columns.count > 14 { break }
        }
        return HeatmapGrid(columns: columns, monthLabels: [], dayLabels: dayLabels, rowCount: 1)
    }

    private static func buildWeekGrid(
        agg: [String: DayActivityContribution],
        metric: HeatmapMetric,
        range: ProgressTimeRange,
        calendar: Calendar,
        now: Date
    ) -> HeatmapGrid {
        let values: [Double] = agg.values.map { metric == .time ? $0.minutes : $0.volumeKg }
        let thresholds = StatsEngine.heatmapThresholds(values: values)
        let df = DateFormatter()
        df.calendar = calendar
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        let monthFmt = DateFormatter()
        monthFmt.locale = Locale(identifier: "es_ES")
        monthFmt.dateFormat = "MMM"

        let today = calendar.startOfDay(for: now)
        let weekday = calendar.component(.weekday, from: today)
        let first = calendar.firstWeekday
        let offsetInWeek = (weekday - first + 7) % 7
        guard let endOfWeek = calendar.date(byAdding: .day, value: -offsetInWeek, to: today) else {
            return .empty
        }

        let weeksBack: Int = {
            switch range {
            case .today, .week: return 0
            case .month: return 4
            case .days90: return 13
            case .days180: return 26
            case .days360: return 52
            }
        }()

        guard let start = calendar.date(byAdding: .day, value: -weeksBack * 7, to: endOfWeek) else {
            return .empty
        }

        var columns: [Column] = []
        var monthLabels: [String] = []
        var lastMonth = -1

        for wk in 0...weeksBack {
            guard let colStart = calendar.date(byAdding: .day, value: wk * 7, to: start) else { continue }
            let mo = calendar.component(.month, from: colStart)
            let day = calendar.component(.day, from: colStart)
            let showM = mo != lastMonth && day <= 7 && wk < weeksBack
            monthLabels.append(showM ? monthFmt.string(from: colStart) : "")
            if day <= 7 { lastMonth = mo }

            var levels: [Int] = []
            var todays: [Bool] = []
            var futures: [Bool] = []
            for d in 0..<7 {
                guard let dayDate = calendar.date(byAdding: .day, value: d, to: colStart) else {
                    levels.append(0); todays.append(false); futures.append(true)
                    continue
                }
                let inRange = range.contains(dayDate, now: now, calendar: calendar)
                let key = df.string(from: dayDate)
                let row = inRange ? agg[key] : nil
                let value = metric == .time ? (row?.minutes ?? 0) : (row?.volumeKg ?? 0)
                levels.append(StatsEngine.heatmapLevel(
                    value: value,
                    hasActivity: row != nil,
                    thresholds: thresholds
                ))
                todays.append(calendar.isDate(dayDate, inSameDayAs: today))
                futures.append(dayDate > today || !inRange)
            }
            columns.append(Column(levels: levels, today: todays, future: futures))
        }
        return HeatmapGrid(columns: columns, monthLabels: monthLabels, dayLabels: [], rowCount: 7)
    }
}
