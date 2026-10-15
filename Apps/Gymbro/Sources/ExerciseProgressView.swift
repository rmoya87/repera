import Charts
import GymbroDomain
import SwiftUI

/// Ficha de progreso de un ejercicio (métricas tipo openGym).
struct ExerciseProgressView: View {
    @Environment(GymbroStore.self) private var store
    let exerciseId: UUID

    @State private var metric: ExerciseProgressMetric = .topSet
    @State private var range: ProgressRange = .all
    @State private var selectedPoint: ExerciseProgressPoint?

    private var exercise: Exercise? {
        store.state.exercises.first { $0.id == exerciseId }
    }

    private var points: [ExerciseProgressPoint] {
        StatsEngine.exerciseProgressSeries(
            exerciseId: exerciseId,
            metric: metric,
            range: range,
            workouts: store.state.workouts
        )
    }

    private var sessions: [ExerciseSessionSnapshot] {
        StatsEngine.exerciseSessionSnapshots(
            exerciseId: exerciseId,
            workouts: store.state.workouts,
            range: range
        )
    }

    private var bestLabel: String {
        switch metric {
        case .topSet:
            let best = points.map(\.value).max()
            return best.map { "Mejor: \($0.formatted(.number.precision(.fractionLength(0...1)))) kg" } ?? "Sin datos"
        case .estimatedOneRM:
            let best = points.map(\.value).max()
            return best.map { "Mejor 1RM est.: \($0.formatted(.number.precision(.fractionLength(0...1)))) kg" } ?? "Sin datos"
        case .effort:
            return "RIR medio por sesión"
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                OGPageHeader(
                    title: exercise?.name ?? "Ejercicio",
                    subtitle: headerSubtitle
                )

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

                chartCard

                if !sessions.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Sesiones")
                            .font(.system(size: 13))
                            .foregroundStyle(OG.label2)
                        ForEach(sessions) { row in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(SpanishDate.short(row.date))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(OG.label)
                                Text(row.setLines.joined(separator: "  "))
                                    .font(.system(size: 12).monospacedDigit())
                                    .foregroundStyle(OG.label2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 4)
                            if row.id != sessions.last?.id {
                                Divider().overlay(OG.surface3)
                            }
                        }
                    }
                    .padding(OG.pad)
                    .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
                }

                Text(footerCaption)
                    .font(.system(size: 12))
                    .foregroundStyle(OG.label3)
            }
            .padding(.horizontal, OG.pad)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(OG.bg)
        .ogContentTitleNav()
    }

    private var headerSubtitle: String? {
        let best = points.map(\.value).max()
        switch metric {
        case .topSet, .estimatedOneRM:
            return best.map { "\($0.formatted(.number.precision(.fractionLength(0...1)))) kg" }
        case .effort:
            return best.map { "RIR medio \($0.formatted(.number.precision(.fractionLength(0...1))))" }
        }
    }

    private var chartCard: some View {
        OGCard {
            VStack(alignment: .leading, spacing: 12) {
                if points.count < 2 {
                    Text(points.isEmpty
                           ? "Entrena este ejercicio para ver la curva."
                           : "Haz al menos 2 sesiones para ver la tendencia.")
                        .font(.system(size: 14))
                        .foregroundStyle(OG.label2)
                        .frame(maxWidth: .infinity, minHeight: 140, alignment: .center)
                } else {
                    Chart(points) { pt in
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
                    .frame(height: 180)

                    if let tip = selectedPoint ?? points.last {
                        Text(tooltip(for: tip))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(OG.label)
                    }
                }

                HStack(spacing: 0) {
                    Text(bestLabel)
                        .font(.system(size: 13))
                        .foregroundStyle(OG.label2)
                    Text(bestHighlight)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(OG.accent)
                }
            }
        }
        .onChange(of: metric) { _, _ in selectedPoint = points.last }
        .onChange(of: range) { _, _ in selectedPoint = points.last }
        .onAppear { selectedPoint = points.last }
    }

    private var bestHighlight: String {
        let best = points.map(\.value).max()
        switch metric {
        case .topSet, .estimatedOneRM:
            return best.map { " \($0.formatted(.number.precision(.fractionLength(0...1)))) kg" } ?? ""
        case .effort:
            return best.map { " \($0.formatted(.number.precision(.fractionLength(0...1))))" } ?? ""
        }
    }

    private var footerCaption: String {
        switch metric {
        case .topSet: return "Mejor peso por sesión"
        case .estimatedOneRM: return "1RM estimado (Epley) por sesión"
        case .effort: return "RIR medio de las series de trabajo"
        }
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
}
