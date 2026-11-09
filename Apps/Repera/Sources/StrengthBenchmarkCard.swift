import Charts
import Foundation
import ReperaDomain
import SwiftUI

/// Compact competitive-reference density inside the existing Evolution card.
/// This is a Gaussian-style *illustration* calibrated from competition quantiles;
/// it is NOT a fitted normal distribution, a population ranking, or a verified 1RM.
struct StrengthBenchmarkVisual: View {
    @Environment(ReperaStore.self) private var store
    @Environment(HealthKitStore.self) private var health
    let exercise: Exercise
    let testedOneRMKg: Double?
    let estimatedOneRMKg: Double?
    /// Última marca hecha (e1RM de la última serie con carga), en la misma escala.
    let lastMarkKg: Double?

    @State private var distributions: [StrengthBenchmarkDistribution] = []
    @State private var didLoad = false

    static func lift(for name: String) -> StrengthBenchmarkLift? {
        StrengthBenchmarkLiftResolver.lift(forExerciseName: name)
    }

    private var weightKg: Double? {
        let local = store.state.bodyWeights
            .filter { $0.weightKg.isFinite && $0.weightKg > 0 }
            .max(by: { $0.date < $1.date })
        let measured = health.latestWeightKg.flatMap {
            $0.isFinite && $0 > 0 ? $0 : nil
        }
        if let measured, let date = health.latestWeightDate {
            if let local, local.date > date { return local.weightKg }
            return measured
        }
        return local?.weightKg ?? measured
    }

    private var peakResult: (kg: Double, estimated: Bool)? {
        if let testedOneRMKg, testedOneRMKg.isFinite, testedOneRMKg > 0 {
            return (testedOneRMKg, false)
        }
        if let estimatedOneRMKg, estimatedOneRMKg.isFinite, estimatedOneRMKg > 0 {
            return (estimatedOneRMKg, true)
        }
        return nil
    }

    private var lastResultKg: Double? {
        guard let lastMarkKg, lastMarkKg.isFinite, lastMarkKg > 0 else { return nil }
        return lastMarkKg
    }

    private var marksCoincide: Bool {
        guard let peak = peakResult?.kg, let last = lastResultKg else { return false }
        return abs(peak - last) < 0.51
    }

    private var frame: StrengthReferenceFrame {
        store.state.settings.strengthReferenceFrame
    }

    private var reference: StrengthBenchmarkDistribution? {
        guard let lift = Self.lift(for: exercise.name),
              let sex = store.state.settings.competitionSex,
              let birthYear = store.state.settings.birthYear,
              let weightKg else { return nil }
        let age = Calendar.current.component(.year, from: Date()) - birthYear
        guard age >= 14 && age <= 100 else { return nil }
        let allowed = frame.allowedSources
        let eligible = distributions.filter {
            $0.cohort.matches(lift: lift, sex: sex, equipment: .raw,
                              age: age, bodyWeightKg: weightKg)
                && $0.sampleCount >= StrengthBenchmarkEngine.minimumSampleCount
                && allowed.contains($0.source)
        }
        guard let width = eligible.map({ $0.cohort.ageMax - $0.cohort.ageMin }).min() else {
            return nil
        }
        let matched = eligible.filter {
            $0.cohort.ageMax - $0.cohort.ageMin == width
        }
        return matched.max(by: {
            if $0.sampleCount != $1.sampleCount { return $0.sampleCount < $1.sampleCount }
            return $0.sourceRevision < $1.sourceRevision
        })
    }

    private var percentile: StrengthBenchmarkResult? {
        guard let lift = Self.lift(for: exercise.name),
              let sex = store.state.settings.competitionSex,
              let birthYear = store.state.settings.birthYear,
              let weightKg, let result = peakResult else { return nil }
        return StrengthBenchmarkEngine.compareCompetitionOneRepMax(
            weightKg: result.kg, lift: lift, sex: sex, equipment: .raw,
            age: Calendar.current.component(.year, from: Date()) - birthYear,
            bodyWeightKg: weightKg, distributions: distributions, frame: frame
        )
    }

    private struct BellPoint: Identifiable {
        let id: Int
        let kg: Double
        let height: Double
    }

    private var bell: [BellPoint] {
        Self.bellPoints(from: reference)
    }

    /// Faint illustrative curve when demographics/marks are incomplete.
    private var placeholderBell: [BellPoint] {
        if !bell.isEmpty { return bell }
        let median = 180.0
        let sigma = 45.0
        return (0...48).map { i in
            let x = median - 3 * sigma + (6 * sigma) * Double(i) / 48
            let z = (x - median) / sigma
            return BellPoint(id: i, kg: x, height: exp(-0.5 * z * z))
        }
    }

    private static func bellPoints(from reference: StrengthBenchmarkDistribution?) -> [BellPoint] {
        guard let reference else { return [] }
        let q = reference.quantiles
        guard let p25 = q.first(where: { abs($0.percentile - 25) < 1 }),
              let p50 = q.first(where: { abs($0.percentile - 50) < 1 }),
              let p75 = q.first(where: { abs($0.percentile - 75) < 1 }) else { return [] }
        let sigma = (p75.weightKg - p25.weightKg) / 1.349
        guard sigma.isFinite && sigma > 0 else { return [] }
        let low = max(0, p50.weightKg - 3 * sigma)
        let high = p50.weightKg + 3 * sigma
        return (0...64).map { i in
            let x = low + (high - low) * Double(i) / 64
            let z = (x - p50.weightKg) / sigma
            return BellPoint(id: i, kg: x, height: exp(-0.5 * z * z))
        }
    }

    private func markerHeight(at kg: Double) -> Double {
        guard let median = reference?.quantiles.first(where: {
            abs($0.percentile - 50) < 1
        })?.weightKg, let low = reference?.quantiles.first(where: {
            abs($0.percentile - 25) < 1
        })?.weightKg, let high = reference?.quantiles.first(where: {
            abs($0.percentile - 75) < 1
        })?.weightKg else { return 0 }
        let sigma = (high - low) / 1.349
        guard sigma > 0 else { return 0 }
        let z = (kg - median) / sigma
        return exp(-0.5 * z * z)
    }

    var body: some View {
        if Self.lift(for: exercise.name) != nil {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("Rendimiento")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(OG.label)
                    Spacer()
                    if let value = percentile {
                        Text("P\(Int(value.percentile.rounded()))")
                            .font(.title3.weight(.bold).monospacedDigit())
                            .foregroundStyle(OG.accent)
                    }
                }
                if let peak = peakResult, bell.count > 2 {
                    filledBellChart(peak: peak)
                } else {
                    emptyBellVisual
                }
            }
            .padding(.vertical, 4)
            .task {
                guard !didLoad else { return }
                await StrengthBenchmarkRemoteStore.shared.refresh()
                distributions = await StrengthBenchmarkRemoteStore.shared.currentDistributions()
                didLoad = true
            }
        }
    }

    @ViewBuilder
    private func filledBellChart(peak: (kg: Double, estimated: Bool)) -> some View {
        let last = lastResultKg
        let coincide = marksCoincide
        Chart {
            ForEach(bell) { pt in
                AreaMark(
                    x: .value("Peso", pt.kg),
                    yStart: .value("Base", 0.0),
                    yEnd: .value("Densidad orientativa", pt.height)
                )
                .foregroundStyle(OG.accent.opacity(0.13))
                .interpolationMethod(.catmullRom)
                LineMark(
                    x: .value("Peso", pt.kg),
                    y: .value("Densidad orientativa", pt.height)
                )
                .foregroundStyle(OG.accent.opacity(0.45))
                .interpolationMethod(.catmullRom)
            }

            if coincide || last == nil {
                markSeries(
                    kg: peak.kg,
                    color: OG.accent,
                    label: weightLabel(peak.kg)
                )
            } else if let last {
                markSeries(
                    kg: peak.kg,
                    color: OG.accent,
                    label: weightLabel(peak.kg)
                )
                markSeries(
                    kg: last,
                    color: OG.blue,
                    label: weightLabel(last)
                )
            }
        }
        .chartYScale(domain: 0...1.18)
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisValueLabel()
            }
        }
        .frame(height: 126)
        .accessibilityLabel(accessibilityText(peak: peak, last: last, coincide: coincide))
    }

    @ChartContentBuilder
    private func markSeries(kg: Double, color: Color, label: String) -> some ChartContent {
        RuleMark(x: .value("Marca", kg))
            .foregroundStyle(color)
            .lineStyle(StrokeStyle(lineWidth: 2))
        PointMark(
            x: .value("Marca", kg),
            y: .value("Posición", markerHeight(at: kg))
        )
        .foregroundStyle(color)
        .symbolSize(85)
        .annotation(position: .top, spacing: 4) {
            Text(label)
                .font(.caption2.weight(.bold).monospacedDigit())
                .foregroundStyle(color)
        }
    }

    private func weightLabel(_ kg: Double) -> String {
        "\(ReperaNumberFormat.decimal(kg, maximumFractionDigits: kg.rounded() == kg ? 0 : 1)) kg"
    }

    private func accessibilityText(
        peak: (kg: Double, estimated: Bool),
        last: Double?,
        coincide: Bool
    ) -> String {
        let peakText = "Tu \(peak.estimated ? "e1RM estimado" : "1RM probado") máximo: \(Int(peak.kg.rounded())) kilogramos"
        if coincide || last == nil {
            return "Curva ilustrativa de referencia \(frame == .elite ? "de competición" : "de gimnasio"). \(peakText)."
        }
        return "Curva ilustrativa de referencia \(frame == .elite ? "de competición" : "de gimnasio"). \(peakText). Última marca: \(Int(last!.rounded())) kilogramos."
    }

    private var emptyBellVisual: some View {
        VStack(alignment: .leading, spacing: 8) {
            Chart {
                ForEach(placeholderBell) { pt in
                    AreaMark(
                        x: .value("Peso", pt.kg),
                        yStart: .value("Base", 0.0),
                        yEnd: .value("Densidad orientativa", pt.height)
                    )
                    .foregroundStyle(OG.label3.opacity(0.12))
                    .interpolationMethod(.catmullRom)
                    LineMark(
                        x: .value("Peso", pt.kg),
                        y: .value("Densidad orientativa", pt.height)
                    )
                    .foregroundStyle(OG.label3.opacity(0.35))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYScale(domain: 0...1.08)
            .chartYAxis(.hidden)
            .chartXAxis(.hidden)
            .frame(height: 88)
            .accessibilityHidden(true)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: emptyIconName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(OG.accent)
                    .frame(width: 22, alignment: .center)
                    .accessibilityHidden(true)
                Text(missingState)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(OG.label2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(missingState)
        }
    }

    private var emptyIconName: String {
        if !didLoad { return "hourglass" }
        if peakResult == nil { return "chart.line.uptrend.xyaxis" }
        if store.state.settings.birthYear == nil || store.state.settings.competitionSex == nil {
            return "person.crop.circle.badge.questionmark"
        }
        if weightKg == nil { return "scalemass" }
        return "chart.bar.xaxis"
    }

    private var missingState: String {
        if !didLoad { return "Preparando referencia…" }
        if peakResult == nil { return "Sin series suficientes para estimar tu marca." }
        if store.state.settings.birthYear == nil || store.state.settings.competitionSex == nil {
            return "Configura género y año de nacimiento en Ajustes · Entrenamiento."
        }
        if weightKg == nil { return "Registra tu peso corporal en Progreso." }
        return "Sin referencia suficiente para esta categoría."
    }
}
