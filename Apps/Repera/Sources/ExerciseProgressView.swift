import Charts
import ReperaDomain
import SwiftUI
import UIKit

/// Página completa (desde Progreso global).
struct ExerciseProgressView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(SubscriptionManager.self) private var subscriptions
    let exerciseId: UUID

    var body: some View {
        ScrollView {
            Group {
                if subscriptions.isPro {
                    ExerciseEvolutionPanel(exerciseId: exerciseId)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        FreeExerciseSummaryCard(exerciseId: exerciseId)
                        freeExerciseEvolutionPreview
                    }
                }
            }
            .padding(.horizontal, OG.pad)
            .padding(.top, 0)
            .padding(.bottom, 28)
            .ogReadableColumn()
        }
        .background(OG.bg.ignoresSafeArea())
        .ogPinnedTransparentNav(
            store.resolvedCatalogExercise(id: exerciseId)?.name ?? "Ejercicio"
        )
        .ogDiaryTransparentNav()
    }

    /// El historial propio es gratuito; la evolución Pro se ilustra sin leer sus marcas.
    private var freeExerciseEvolutionPreview: some View {
        let values: [Double] = [40, 43, 42, 46, 48, 46, 52]
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                OGCardSectionTitle(title: "Evolución")
                Spacer()
                Text("Ejemplo")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(OG.label2)
            }
            OGCard(padding: 10, verticalPadding: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Evolución de carga · datos ficticios")
                        .font(.footnote)
                        .foregroundStyle(OG.label3)
                    Chart {
                        ForEach(0..<values.count, id: \.self) { index in
                            LineMark(
                                x: .value("Sesión", index + 1),
                                y: .value("Peso", values[index])
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(OG.accent)
                            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        }
                    }
                    .chartXScale(domain: 0...8)
                    .chartPlotStyle { $0.clipped() }
                    .frame(height: 205)
                    .allowsHitTesting(false)
                }
            }
        }
        .accessibilityLabel("Ejemplo de evolución del ejercicio, datos ficticios.")
    }
}

/// Historial + métricas + gráfica en un solo bloque («Evolución»).
struct ExerciseEvolutionPanel: View {
    @Environment(ReperaStore.self) private var store
    let exerciseId: UUID
    var highlightSessionId: UUID? = nil

    @State private var metric: ExerciseProgressMetric = .topSet
    @State private var range: ProgressRange = .all
    @State private var selectedChartDate: Date?
    @State private var editingTope = false
    @State private var topeDraft = ""
    @State private var didSeedMetric = false

    private var exercise: Exercise? {
        store.resolvedCatalogExercise(id: exerciseId)
    }

    private var loggingStyle: ExerciseLoggingStyle {
        exercise?.loggingStyle ?? .loadAndReps
    }

    private var availableMetrics: [ExerciseProgressMetric] {
        ExerciseProgressMetric.available(for: loggingStyle)
    }

    private var history: ExerciseHistorySummary {
        store.cachedHistory(for: exerciseId)
    }

    private var loadPref: ExerciseLoadPreference {
        store.loadPreference(for: exerciseId)
    }

    private var testedOneRMKg: Double? {
        loadPref.testedOneRMKg.flatMap { $0 > 0 ? $0 : nil }
    }

    private var isStrengthProgress: Bool {
        loggingStyle == .loadAndReps
    }

    private var points: [ExerciseProgressPoint] {
        StatsEngine.exerciseProgressSeries(
            exerciseId: exerciseId,
            metric: metric,
            range: range,
            workouts: store.state.workouts,
            catalog: store.state.exercises
        )
    }

    private var showsOneRMCeiling: Bool {
        isStrengthProgress && testedOneRMKg != nil && (metric == .topSet || metric == .estimatedOneRM)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            OGCardSectionTitle(title: "Evolución")
            OGCard(padding: 10, verticalPadding: 20) {
                VStack(alignment: .leading, spacing: 14) {
                    summaryTiles

                    Divider().opacity(0.35)

                    metricPicker

                    Picker("Rango", selection: $range) {
                        ForEach(ProgressRange.allCases) { r in
                            Text(r.title).tag(r)
                        }
                    }
                    .pickerStyle(.segmented)

                    chartBlock
                    sessionsBlock
                }
            }
        }
        .onAppear {
            seedMetricIfNeeded()
        }
    }

    @ViewBuilder
    private var metricPicker: some View {
        if loggingStyle == .machineWork {
            Picker("Métrica", selection: $metric) {
                ForEach(availableMetrics) { m in
                    Text(m.title).tag(m)
                }
            }
            .pickerStyle(.menu)
        } else {
            Picker("Métrica", selection: $metric) {
                ForEach(availableMetrics) { m in
                    Text(m.title).tag(m)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func seedMetricIfNeeded() {
        guard !didSeedMetric else { return }
        didSeedMetric = true
        if loggingStyle == .machineWork {
            let h = history
            if h.bestMeters != nil {
                metric = .bestMeters
            } else if h.bestCalories != nil {
                metric = .bestCalories
            } else {
                metric = exercise?.defaultQuantityUnit == .meters ? .bestMeters : .bestCalories
            }
        } else if !availableMetrics.contains(metric), let first = availableMetrics.first {
            metric = first
        }
    }

    // MARK: - Summary

    private var summaryTiles: some View {
        let h = history
        return VStack(alignment: .leading, spacing: 10) {
            if isStrengthProgress {
                HStack(spacing: 10) {
                    topeOneRMTile
                    evoTile(
                        "Máx.",
                        h.maxWeightKg.map { "\($0.formatted(.number.precision(.fractionLength(0)))) kg" } ?? "—"
                    )
                    evoTile(
                        "e1RM",
                        h.estimatedOneRM.map { "\($0.formatted(.number.precision(.fractionLength(0)))) kg" } ?? "—"
                    )
                }
                HStack(spacing: 10) {
                    evoTile("Reps máx.", h.bestReps.map(String.init) ?? "—")
                    evoTile("Veces", h.hasData ? "\(h.timesPerformed)" : "—")
                }
                if !h.hasData, testedOneRMKg == nil {
                    Text("Pulsa Tope 1RM para fijar tu máxima, o entrena para ver la curva.")
                        .font(.system(size: 12))
                        .foregroundStyle(OG.label3)
                }
            } else {
                HStack(spacing: 10) {
                    if loggingStyle == .machineWork {
                        evoTile("Cal máx.", h.bestCalories.map { "\($0)" } ?? "—")
                        evoTile("m máx.", h.bestMeters.map { "\($0)" } ?? "—")
                    } else {
                        evoTile("Reps máx.", h.bestReps.map(String.init) ?? "—")
                        evoTile(
                            "Tiempo",
                            h.bestDurationSeconds.map(formatDuration) ?? "—"
                        )
                    }
                    evoTile("Veces", h.hasData ? "\(h.timesPerformed)" : "—")
                }
                if loggingStyle == .machineWork || loggingStyle == .repsAndTime {
                    HStack(spacing: 10) {
                        evoTile(
                            "Mejor tiempo",
                            h.bestDurationSeconds.map(formatDuration) ?? "—"
                        )
                        evoTile("Última", h.lastQuantityLabel ?? "—")
                    }
                }
             }
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return s == 0 ? "\(m):00" : String(format: "%d:%02d", m, s)
    }

    /// Tope editable: toque → teclado; también sube solo si el e1RM lo supera.
    private var topeOneRMTile: some View {
        VStack(alignment: .leading, spacing: 4) {
            Group {
                if editingTope {
                    OGNumericTextField(
                        text: $topeDraft,
                        allowsDecimal: true,
                        textAlignment: .left,
                        fontSize: 18,
                        textColor: UIColor(OG.accent),
                        onCommit: { commitTopeEdit() }
                    )
                } else {
                    Text(testedOneRMKg.map { String(format: "%g", $0) } ?? "—")
                        .font(.system(size: 18, weight: .semibold).monospacedDigit())
                        .foregroundStyle(OG.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture { beginTopeEdit() }
                }
            }
            .frame(minHeight: 22)

            Text("Tope 1RM")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(OG.accent.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(OG.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityLabel("Tope 1RM")
        .accessibilityHint("Pulsa para editar tu máxima")
        .accessibilityAddTraits(.isButton)
    }

    private func beginTopeEdit() {
        topeDraft = testedOneRMKg.map { String(format: "%g", $0) } ?? ""
        editingTope = true
    }

    private func commitTopeEdit() {
        guard editingTope else { return }
        var pref = loadPref
        let trimmed = topeDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "—" {
            pref.testedOneRMKg = nil
        } else if let v = Double(trimmed.replacingOccurrences(of: ",", with: ".")), v > 0 {
            pref.testedOneRMKg = (v * 10).rounded() / 10
        }
        store.setLoadPreference(pref, for: exerciseId)
        editingTope = false
    }

    private func evoTile(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(OG.label)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(OG.label3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Chart

    @ViewBuilder
    private var chartBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            if points.count < 2 {
                ProgressEmptyChart(
                    message: points.isEmpty
                        ? "Aún no hay datos para este periodo."
                        : "Haz al menos 2 sesiones para ver la tendencia.",
                    height: 220,
                    yRange: chartYDomain
                )
            } else {
                Chart {
                    ForEach(points) { pt in
                        LineMark(
                            x: .value("Fecha", pt.date),
                            y: .value("Valor", pt.value)
                        )
                        .foregroundStyle(OG.blue)
                        .interpolationMethod(.catmullRom)

                    }

                    if let selectedChartDate,
                       let selected = points.min(by: {
                           abs($0.date.timeIntervalSince(selectedChartDate)) < abs($1.date.timeIntervalSince(selectedChartDate))
                       }) {
                        RuleMark(x: .value("Fecha seleccionada", selected.date))
                            .foregroundStyle(OG.label2)
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4]))
                            .annotation(position: .top) {
                                Text(tooltip(for: selected))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(OG.label)
                                    .padding(5)
                                    .background(OG.surface, in: RoundedRectangle(cornerRadius: 6))
                            }
                    }

                    if let tested = testedOneRMKg, showsOneRMCeiling {
                        RuleMark(y: .value("Tope 1RM", tested))
                            .foregroundStyle(OG.accent.opacity(0.85))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("1RM \(tested.formatted(.number.precision(.fractionLength(0...1))))")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(OG.accent)
                                    .padding(.horizontal, 4)
                            }
                    }
                }
                .chartXSelection(value: $selectedChartDate)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(OG.surface3)
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(OG.surface3)
                        AxisValueLabel()
                    }
                }
                .chartYScale(domain: chartYDomain)
                .frame(height: 220)


            }
        }
        .padding(12)
        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var chartYDomain: ClosedRange<Double> {
        let values = points.map(\.value)
        var lo = values.min() ?? 0
        var hi = values.max() ?? 1
        if let tested = testedOneRMKg, showsOneRMCeiling {
            hi = max(hi, tested)
            lo = min(lo, tested * 0.5)
        }
        if hi <= lo { hi = lo + 1 }
        let pad = max((hi - lo) * 0.08, 1)
        return max(0, lo - pad)...(hi + pad)
    }

    private func tooltip(for point: ExerciseProgressPoint) -> String {
        var parts: [String] = [SpanishDate.short(point.date)]
        switch metric {
        case .topSet:
            if let w = point.weightKg {
                parts.append("\(w.formatted(.number.precision(.fractionLength(0...1)))) kg")
            }
        case .estimatedOneRM:
            parts.append("~\(point.value.formatted(.number.precision(.fractionLength(0...1)))) kg")
        case .effort:
            parts.append("RIR \(point.value.formatted(.number.precision(.fractionLength(0...1))))")
        case .bestQuantity, .totalQuantity, .bestMeters, .bestCalories, .totalMeters, .totalCalories:
            let qty = Int(point.value.rounded())
            switch point.quantityUnit {
            case .calories: parts.append("\(qty) cal")
            case .meters: parts.append("\(qty) m")
            case .reps, .none: parts.append("\(qty)")
            }
            if let sec = point.durationSeconds, sec > 0 {
                parts.append(formatDuration(sec))
            }
        case .duration:
            parts.append(formatDuration(Int(point.value.rounded())))
        }
        if let rir = point.rir, metric != .effort {
            parts.append("RIR \(String(format: "%g", rir))")
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Resumen + acceso a historial completo

    private var sessionsBlock: some View {
        let h = history
        let tested = testedOneRMKg
        let allSessions = StatsEngine.exerciseSessionSnapshots(
            exerciseId: exerciseId,
            workouts: store.state.workouts,
            range: .all,
            catalog: store.state.exercises
        )
        let latest = allSessions.first
        return VStack(alignment: .leading, spacing: 10) {
            if h.hasData {
                VStack(alignment: .leading, spacing: 6) {
                    if isStrengthProgress, let w = h.maxWeightKg, let r = h.repsAtMaxWeight {
                        sessionMetaRow("Mejor serie", "\(r) × \(w.formatted(.number.precision(.fractionLength(0...1)))) kg")
                    }
                    if !isStrengthProgress, let cal = h.bestCalories {
                        sessionMetaRow("Mejor cal", "\(cal)")
                    }
                    if !isStrengthProgress, let meters = h.bestMeters {
                        sessionMetaRow("Mejor distancia", "\(meters) m")
                    }
                    if isStrengthProgress, let tested, let e1 = h.estimatedOneRM, e1 > 0 {
                        let pct = e1 / tested * 100
                        sessionMetaRow("% del tope", "\(pct.formatted(.number.precision(.fractionLength(0...0))))%")
                    }
                    if let date = h.lastDate {
                        let lastBits: [String?] = [
                            h.lastQuantityLabel,
                            h.lastWeightKg.map { "\($0.formatted(.number.precision(.fractionLength(1)))) kg" },
                            h.lastDurationSeconds.map(formatDuration),
                        ]
                        let last = lastBits.compactMap { $0 }.joined(separator: " · ")
                        sessionMetaRow("Última", "\(SpanishDate.short(date))" + (last.isEmpty ? "" : " · \(last)"))
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if !allSessions.isEmpty {
                NavigationLink {
                    ExerciseHistoryView(exerciseId: exerciseId)
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Historial")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(OG.label)
                            if let latest {
                                Text("\(SpanishDate.short(latest.date)) · \(latest.setLines.joined(separator: "  "))")
                                    .font(.system(size: 12).monospacedDigit())
                                    .foregroundStyle(OG.label2)
                                    .lineLimit(2)
                            } else {
                                Text("\(allSessions.count) sesiones")
                                    .font(.system(size: 12))
                                    .foregroundStyle(OG.label2)
                            }
                        }
                        Spacer(minLength: 8)
                        Text("\(allSessions.count)")
                            .font(.system(size: 13, weight: .semibold).monospacedDigit())
                            .foregroundStyle(OG.label3)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(OG.label3)
                    }
                    .padding(14)
                    .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sessionMetaRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(OG.label2)
            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 14, weight: .medium).monospacedDigit())
                .foregroundStyle(OG.label)
                .multilineTextAlignment(.trailing)
        }
    }
}

/// Historial completo de un ejercicio (todas las sesiones con series).
struct ExerciseHistoryView: View {
    @Environment(ReperaStore.self) private var store
    let exerciseId: UUID

    private var exerciseName: String {
        store.resolvedCatalogExercise(id: exerciseId)?.name ?? "Ejercicio"
    }

    private var sessions: [ExerciseSessionSnapshot] {
        StatsEngine.exerciseSessionSnapshots(
            exerciseId: exerciseId,
            workouts: store.state.workouts,
            range: .all,
            catalog: store.state.exercises
        )
    }

    var body: some View {
        Group {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "Sin historial",
                    systemImage: "tray",
                    description: Text("Las series de este ejercicio aparecerán aquí.")
                )
                .foregroundStyle(OG.label2)
            } else {
                List {
                    ForEach(sessions) { row in
                        NavigationLink {
                            WorkoutDetailView(sessionId: row.id)
                        } label: {
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(OG.accent.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        Image(systemName: "figure.strengthtraining.traditional")
                                            .foregroundStyle(OG.accent)
                                    }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(SpanishDate.short(row.date))
                                        .font(.headline)
                                        .foregroundStyle(OG.label)
                                    Text(row.setLines.joined(separator: "  "))
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(OG.label2)
                                        .lineLimit(3)
                                }

                                Spacer(minLength: 8)

                                if let top = row.topWeightKg {
                                    Text("\(top.formatted(.number.precision(.fractionLength(0...1)))) kg")
                                        .font(.system(size: 13, weight: .semibold).monospacedDigit())
                                        .foregroundStyle(OG.accent)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .ogListChrome()
            }
        }
        .background(OG.bg)
        .ogPinnedTransparentNav(exerciseName)
        .ogDiaryTransparentNav()
    }
}
