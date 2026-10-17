import Charts
import GymbroDomain
import SwiftUI
import UIKit

/// Página completa (desde Progreso global).
struct ExerciseProgressView: View {
    @Environment(GymbroStore.self) private var store
    let exerciseId: UUID

    var body: some View {
        ScrollView {
            ExerciseEvolutionPanel(exerciseId: exerciseId)
                .padding(.horizontal, OG.pad)
                .padding(.top, 0)
                .padding(.bottom, 28)
        }
        .background(OG.bg)
        .ogPinnedTransparentNav(
            store.state.exercises.first { $0.id == exerciseId }?.name ?? "Ejercicio"
        )
    }
}

/// Historial + métricas + gráfica en un solo bloque («Evolución»).
struct ExerciseEvolutionPanel: View {
    @Environment(GymbroStore.self) private var store
    let exerciseId: UUID

    @State private var metric: ExerciseProgressMetric = .topSet
    @State private var range: ProgressRange = .all
    @State private var selectedPoint: ExerciseProgressPoint?
    @State private var editingTope = false
    @State private var topeDraft = ""

    private var history: ExerciseHistorySummary {
        store.cachedHistory(for: exerciseId)
    }

    private var loadPref: ExerciseLoadPreference {
        store.loadPreference(for: exerciseId)
    }

    private var testedOneRMKg: Double? {
        loadPref.testedOneRMKg.flatMap { $0 > 0 ? $0 : nil }
    }

    private var points: [ExerciseProgressPoint] {
        StatsEngine.exerciseProgressSeries(
            exerciseId: exerciseId,
            metric: metric,
            range: range,
            workouts: store.state.workouts
        )
    }

    private var showsOneRMCeiling: Bool {
        testedOneRMKg != nil && (metric == .topSet || metric == .estimatedOneRM)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            OGCardSectionTitle(title: "Evolución")
            OGCard {
                VStack(alignment: .leading, spacing: 14) {
                    summaryTiles

                    Divider().opacity(0.35)

                    Picker("Métrica", selection: $metric) {
                        ForEach(ExerciseProgressMetric.allCases) { m in
                            Text(m.title).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)

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
        .onChange(of: metric) { _, _ in selectedPoint = points.last }
        .onChange(of: range) { _, _ in selectedPoint = points.last }
        .onAppear { selectedPoint = points.last }
    }

    // MARK: - Summary

    private var summaryTiles: some View {
        let h = history
        // Fila de 3 + fila de 2: mismos bordes izq/dcha (mismo spacing, ancho flexible).
        return VStack(alignment: .leading, spacing: 10) {
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
        }
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
                Text(points.isEmpty
                     ? "Entrena este ejercicio para ver la curva."
                     : "Haz al menos 2 sesiones para ver la tendencia.")
                    .font(.system(size: 14))
                    .foregroundStyle(OG.label2)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
            } else {
                Chart {
                    ForEach(points) { pt in
                        LineMark(
                            x: .value("Fecha", pt.date),
                            y: .value("Valor", pt.value)
                        )
                        .foregroundStyle(OG.blue)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Fecha", pt.date),
                            y: .value("Valor", pt.value)
                        )
                        .foregroundStyle(OG.blue)
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
                .frame(height: 180)

                if let tip = selectedPoint ?? points.last {
                    Text(tooltip(for: tip))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(OG.label)
                }
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
            range: .all
        )
        let latest = allSessions.first
        return VStack(alignment: .leading, spacing: 10) {
            if h.hasData {
                VStack(alignment: .leading, spacing: 6) {
                    if let w = h.maxWeightKg, let r = h.repsAtMaxWeight {
                        sessionMetaRow("Mejor serie", "\(r) × \(w.formatted(.number.precision(.fractionLength(0...1)))) kg")
                    }
                    if let tested, let e1 = h.estimatedOneRM, e1 > 0 {
                        let pct = e1 / tested * 100
                        sessionMetaRow("% del tope", "\(pct.formatted(.number.precision(.fractionLength(0...0))))%")
                    }
                    if let date = h.lastDate {
                        let last = [
                            h.lastReps.map { "\($0) reps" },
                            h.lastWeightKg.map { "\($0.formatted(.number.precision(.fractionLength(1)))) kg" },
                        ].compactMap { $0 }.joined(separator: " · ")
                        sessionMetaRow("Última", "\(SpanishDate.short(date))" + (last.isEmpty ? "" : " · \(last)"))
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if allSessions.isEmpty {
                Text("Cuando entrenes este ejercicio, verás aquí el historial.")
                    .font(.system(size: 13))
                    .foregroundStyle(OG.label3)
            } else {
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
    @Environment(GymbroStore.self) private var store
    let exerciseId: UUID

    private var exerciseName: String {
        store.state.exercises.first { $0.id == exerciseId }?.name ?? "Ejercicio"
    }

    private var sessions: [ExerciseSessionSnapshot] {
        StatsEngine.exerciseSessionSnapshots(
            exerciseId: exerciseId,
            workouts: store.state.workouts,
            range: .all
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
    }
}
