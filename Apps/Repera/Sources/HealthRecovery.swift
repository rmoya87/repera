import Charts
import Foundation
import HealthKit
import Observation
import SwiftUI
import ReperaDomain

/// Solo en el iPhone: nunca forma parte de AppSettings/iCloud ni de los DTO de Supabase.
struct RecoverySleepNight: Identifiable, Sendable, Equatable {
    var date: Date
    var hours: Double
    var deepHours: Double
    var remHours: Double
    var id: Date { date }
}

/// Copia Sendable de los campos de HealthKit: nunca sale un HKSample del callback.
private struct RecoveryCategoryRecord: Sendable {
    let startDate: Date
    let endDate: Date
    let value: Int
    let source: String
    let isCycleStart: Bool?
}

enum CycleEstimate: String, Sendable {
    case menstrual = "Menstruación registrada"
    case follicular = "Fase folicular estimada"
    case ovulatory = "Ovulación aproximada"
    case luteal = "Fase lútea estimada"
    case unknown = "Fase no disponible"
}

@MainActor
@Observable
final class HealthRecoveryStore {
    static let shared = HealthRecoveryStore()
    private let healthStore = HKHealthStore()
    private let sleepKey = "repera.privateHealth.sleepEnabled"
    private let cycleKey = "repera.privateHealth.cycleEnabled"

    var sleepEnabled: Bool {
        didSet {
            UserDefaults.standard.set(sleepEnabled, forKey: sleepKey)
            if !sleepEnabled { nights = [] }
        }
    }
    var cycleEnabled: Bool {
        didSet {
            UserDefaults.standard.set(cycleEnabled, forKey: cycleKey)
            if !cycleEnabled { menstrualDays = []; positiveOvulationTests = [] }
        }
    }
    private(set) var nights: [RecoverySleepNight] = []
    private(set) var menstrualDays: [Date] = []
    private(set) var positiveOvulationTests: [Date] = []
    private(set) var loading = false
    private(set) var errorMessage: String?
    private(set) var lastRefreshed: Date?

    private init() {
        sleepEnabled = UserDefaults.standard.bool(forKey: sleepKey)
        cycleEnabled = UserDefaults.standard.bool(forKey: cycleKey)
    }

    var lastNight: RecoverySleepNight? {
        guard let last = nights.last,
              abs(last.date.timeIntervalSinceNow) <= 48 * 3600 else { return nil }
        return last
    }
    var averageHours: Double? {
        let recent = Array(nights.suffix(14))
        guard !recent.isEmpty else { return nil }
        return recent.reduce(0) { $0 + $1.hours } / Double(recent.count)
    }

    /// Índice informativo de descanso, NO una predicción clínica de recuperación.
    var sleepIndex: Int? {
        RecoveryEngine.sleepIndex(hours: lastNight?.hours, recentAverage: averageHours)
    }

    var cycleEstimate: CycleEstimate {
        guard cycleEnabled else { return .unknown }
        switch RecoveryEngine.cyclePhase(flowDays: menstrualDays, on: Date()) {
        case .menstrual: return .menstrual
        case .follicular: return .follicular
        case .ovulatory: return .ovulatory
        case .luteal: return .luteal
        case .unknown: return .unknown
        }
    }

    var trainingTip: String? {
        if let lastNight, lastNight.hours < 6 {
            return "Has dormido menos de 6 horas. Ajusta el esfuerzo a tus sensaciones y cuida la técnica."
        }
        if cycleEstimate == .menstrual {
            return "Has registrado menstruación. Si tienes molestias, adapta el volumen; no necesitas reducirlo si te encuentras bien."
        }
        if let lastNight, lastNight.hours >= 7 {
            return "Has descansado al menos 7 horas. Mantén tu plan y guía las cargas por tu RIR."
        }
        return nil
    }

    func setSleep(_ enabled: Bool) async {
        sleepEnabled = enabled
        if enabled { await authorizeAndRefresh(types: [HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!]) }
    }

    func setCycle(_ enabled: Bool) async {
        cycleEnabled = enabled
        if enabled {
            await authorizeAndRefresh(types: [
                HKObjectType.categoryType(forIdentifier: .menstrualFlow)!,
                HKObjectType.categoryType(forIdentifier: .ovulationTestResult)!
            ])
        }
    }

    private func authorizeAndRefresh(types: Set<HKObjectType>) async {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "Apple Salud no está disponible en este dispositivo."
            return
        }
        do {
            try await healthStore.requestAuthorization(toShare: [], read: types)
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() async {
        guard HKHealthStore.isHealthDataAvailable(), (sleepEnabled || cycleEnabled), !loading else { return }
        loading = true
        defer { loading = false }
        errorMessage = nil
        if sleepEnabled {
            let sleep = await categorySamples(.sleepAnalysis, days: 45)
            nights = Self.combineSleep(sleep)
        }
        if cycleEnabled {
            let menstrual = await categorySamples(.menstrualFlow, days: 230)
            // Apple Salud puede registrar una muestra por día o una única muestra
            // que cubre varios días; expandirla para pintar el calendario completo.
            let calendar = Calendar.current
            menstrualDays = Array(Set(menstrual
                .filter { $0.value != HKCategoryValueMenstrualFlow.none.rawValue }
                .flatMap { record -> [Date] in
                    let start = calendar.startOfDay(for: record.startDate)
                    let lastMoment = max(record.startDate, record.endDate.addingTimeInterval(-1))
                    let end = calendar.startOfDay(for: lastMoment)
                    let span = min(10, max(0, calendar.dateComponents([.day], from: start, to: end).day ?? 0))
                    return (0...span).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
                })).sorted()
            let tests = await categorySamples(.ovulationTestResult, days: 230)
            positiveOvulationTests = tests.filter {
                $0.value == HKCategoryValueOvulationTestResult.luteinizingHormoneSurge.rawValue
            }.map(\.startDate).sorted()
        }
        lastRefreshed = Date()
    }

    private func categorySamples(_ identifier: HKCategoryTypeIdentifier, days: Int) async -> [RecoveryCategoryRecord] {
        guard let type = HKObjectType.categoryType(forIdentifier: identifier) else { return [] }
        let start = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? .distantPast
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: [])
        return await withCheckedContinuation { (continuation: CheckedContinuation<[RecoveryCategoryRecord], Never>) in
            let query = HKSampleQuery(
                sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil
            ) { _, samples, _ in
                let records = (samples as? [HKCategorySample] ?? []).map {
                    RecoveryCategoryRecord(
                        startDate: $0.startDate, endDate: $0.endDate,
                        value: $0.value, source: $0.sourceRevision.source.bundleIdentifier,
                        isCycleStart: $0.metadata?[HKMetadataKeyMenstrualCycleStart] as? Bool
                    )
                }
                continuation.resume(returning: records)
            }
            healthStore.execute(query)
        }
    }

    /// Elige una fuente de etapas por noche y fusiona intervalos para no duplicar
    /// sueño de iPhone + Watch o muestras solapadas.
    private static func combineSleep(_ samples: [RecoveryCategoryRecord]) -> [RecoverySleepNight] {
        struct Segment {
            let start: Date
            let end: Date
            let value: Int
            let source: String
        }
        var grouped: [Date: [Segment]] = [:]
        let stages: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
        ]
        for sample in samples where stages.contains(sample.value) && sample.endDate > sample.startDate {
            let midpoint = sample.startDate.addingTimeInterval(sample.endDate.timeIntervalSince(sample.startDate) / 2)
            let night = Calendar.current.startOfDay(for: midpoint.addingTimeInterval(12 * 3600))
            grouped[night, default: []].append(
                Segment(start: sample.startDate, end: sample.endDate, value: sample.value,
                        source: sample.source)
            )
        }
        func unionSeconds(_ values: [Segment]) -> Double {
            let ordered = values.sorted { $0.start < $1.start }
            var end: Date?
            var total = 0.0
            for part in ordered {
                if let previous = end, previous > part.start {
                    if part.end > previous {
                        total += part.end.timeIntervalSince(previous)
                        end = part.end
                    }
                } else {
                    total += part.end.timeIntervalSince(part.start)
                    end = part.end
                }
            }
            return total
        }
        return grouped.compactMap { night, all in
            let sources = Dictionary(grouping: all, by: \.source)
            guard let segments = sources.values.max(by: {
                let a = $0.filter { $0.value != HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue }.count
                let b = $1.filter { $0.value != HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue }.count
                return a == b ? unionSeconds($0) < unionSeconds($1) : a < b
            }) else { return nil }
            let hours = min(24, unionSeconds(segments) / 3600)
            guard hours >= 0.25 else { return nil }
            return RecoverySleepNight(
                date: night, hours: hours,
                deepHours: unionSeconds(segments.filter { $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue }) / 3600,
                remHours: unionSeconds(segments.filter { $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue }) / 3600
            )
        }.sorted { $0.date < $1.date }
    }
}

struct HealthRecoverySettingsView: View {
    @State private var recovery = HealthRecoveryStore.shared

    var body: some View {
        Form {
            Section {
                Toggle("Analizar descanso", isOn: Binding(
                    get: { recovery.sleepEnabled },
                    set: { enabled in Task { await recovery.setSleep(enabled) } }
                ))
                Toggle("Seguimiento del ciclo", isOn: Binding(
                    get: { recovery.cycleEnabled },
                    set: { enabled in Task { await recovery.setCycle(enabled) } }
                ))
            } footer: {
                Text("Los datos de sueño, menstruación y ovulación permanecen en Apple Salud y en la memoria de este dispositivo. No se envían a Supabase ni se comparten con entrenadores.")
            }
            Section("Privacidad") {
                Label("Sin sincronización de salud con Supabase", systemImage: "iphone.gen3")
                Label("Sin compartir el ciclo ni el sueño", systemImage: "lock.shield")
                if recovery.loading { ProgressView("Leyendo Apple Salud…") }
                if let message = recovery.errorMessage { Text(message).foregroundStyle(OG.orange) }
                Button("Actualizar desde Apple Salud") { Task { await recovery.refresh() } }
            }
            Section {
                Text("El sueño es orientativo. Las fases menstruales son estimaciones, no confirman la ovulación ni predicen la fertilidad. Las recomendaciones no sustituyen la valoración profesional.")
                    .font(.footnote).foregroundStyle(OG.label2)
            }
        }
        .ogListChrome()
        .ogPinnedTransparentNav("Salud y recuperación")
        .task { await recovery.refresh() }
    }
}

struct HealthRecoveryProgressView: View {
    @State private var recovery = HealthRecoveryStore.shared
    @Environment(SubscriptionManager.self) private var subscriptions

    private var isPro: Bool { subscriptions.isPro }
    private var hasSleepData: Bool { recovery.sleepEnabled && !recovery.nights.isEmpty }
    private var hasCycleData: Bool { !recovery.menstrualDays.isEmpty }

    private enum NightSky {
        static let ink = Color(red: 0.07, green: 0.10, blue: 0.22)
        static let deep = Color(red: 0.16, green: 0.24, blue: 0.52)
        static let mid = Color(red: 0.32, green: 0.42, blue: 0.78)
        static let glow = Color(red: 0.55, green: 0.68, blue: 0.95)
        static let rem = Color(red: 0.72, green: 0.82, blue: 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if hasSleepData {
                sleepContent
            } else if !isPro {
                freeRecoveryPreview
            } else {
                softSleepEmpty
            }

            // Solo si hay registros reales (p. ej. no mostrar vacío a quien no usa ciclo).
            if hasCycleData {
                cycleContent
            }

            if !isPro {
                ProTeaserCard(
                    title: "Recuperación completa",
                    bodyText: "Tendencias de sueño, fases y consejos locales con Repera Pro.",
                    cta: "Descubrir Repera Pro"
                ) {
                    subscriptions.presentPaywall(.progress, feature: .advancedProgress)
                }
            }
        }
        .task { await recovery.refresh() }
    }

    /// Preview free sin empujar a «Configurar Salud».
    @ViewBuilder
    private var freeRecoveryPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            OGCardSectionTitle(title: "Sueño · ejemplo")
            sleepNightCard(
                hours: 7.4,
                index: 82,
                deep: 1.6,
                rem: 1.9,
                light: 3.9,
                nights: Self.teaserNights,
                caption: "Así se vería tu descanso con datos de Apple Salud."
            )
            .opacity(0.9)
            .allowsHitTesting(false)
        }
    }

    private var softSleepEmpty: some View {
        VStack(alignment: .leading, spacing: 8) {
            OGCardSectionTitle(title: "Sueño")
            OGCard {
                Text("Sin noches recientes en Apple Salud. Cuando haya registros, verás horas y fases aquí.")
                    .font(.subheadline)
                    .foregroundStyle(OG.label2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private static var teaserNights: [RecoverySleepNight] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<10).reversed().compactMap { offset -> RecoverySleepNight? in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let t = Double(9 - offset)
            let hours = 6.4 + 1.1 * sin(t * 0.7) + 0.35 * cos(t * 1.4)
            let deep = max(0.6, 1.2 + 0.4 * sin(t))
            let rem = max(0.7, 1.4 + 0.35 * cos(t * 1.2))
            let light = max(2.0, hours - deep - rem)
            return RecoverySleepNight(date: day, hours: hours, deepHours: deep, remHours: rem)
        }
    }

    @ViewBuilder
    private var sleepContent: some View {
        OGCardSectionTitle(title: "Sueño")
        let last = recovery.lastNight
        let light = last.map { max(0, $0.hours - $0.deepHours - $0.remHours) } ?? 0
        sleepNightCard(
            hours: last?.hours,
            index: recovery.sleepIndex,
            deep: last?.deepHours ?? 0,
            rem: last?.remHours ?? 0,
            light: light,
            nights: Array(recovery.nights.suffix(14)),
            caption: recovery.averageHours.map { String(format: "Media reciente %.1f h · una fuente por noche", $0) }
                ?? "Las fases las estima el dispositivo."
        )
    }

    private func sleepNightCard(
        hours: Double?,
        index: Int?,
        deep: Double,
        rem: Double,
        light: Double,
        nights: [RecoverySleepNight],
        caption: String
    ) -> some View {
        let yLo = max(3.5, (nights.map(\.hours).min() ?? 5) - 0.8)
        let yHi = min(11, (nights.map(\.hours).max() ?? 8) + 0.9)
        return OGCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(NightSky.glow)
                        .frame(width: 40, height: 40)
                        .background(NightSky.ink.opacity(0.9), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Última noche")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(OG.label2)
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(hours.map { String(format: "%.1f" , $0) } ?? "—")
                                .font(.system(size: 28, weight: .semibold, design: .rounded).monospacedDigit())
                                .foregroundStyle(OG.label)
                            Text("h")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(OG.label2)
                        }
                    }
                    Spacer(minLength: 0)
                    if let index {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Descanso")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(OG.label3)
                            Text("\(index)")
                                .font(.system(size: 22, weight: .semibold, design: .rounded).monospacedDigit())
                                .foregroundStyle(OG.label)
                            Text("/100")
                                .font(.caption2)
                                .foregroundStyle(OG.label3)
                        }
                    }
                }

                if deep + rem + light > 0.2 {
                    HStack(spacing: 8) {
                        phaseChip(title: "Profundo", hours: deep, color: NightSky.deep)
                        phaseChip(title: "REM", hours: rem, color: NightSky.mid)
                        phaseChip(title: "Ligero", hours: light, color: NightSky.glow)
                    }
                    phaseStackBar(deep: deep, rem: rem, light: light)
                }

                Chart {
                    ForEach(nights) { night in
                        AreaMark(
                            x: .value("Día", night.date, unit: .day),
                            y: .value("Horas", night.hours)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [NightSky.mid.opacity(0.45), NightSky.ink.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.cardinal(tension: 0.7))

                        LineMark(
                            x: .value("Día", night.date, unit: .day),
                            y: .value("Horas", night.hours)
                        )
                        .foregroundStyle(NightSky.glow)
                        .lineStyle(StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.cardinal(tension: 0.7))

                        PointMark(
                            x: .value("Día", night.date, unit: .day),
                            y: .value("Horas", night.hours)
                        )
                        .symbolSize(42)
                        .foregroundStyle(NightSky.rem)
                    }
                    RuleMark(y: .value("Referencia", 7))
                        .foregroundStyle(NightSky.glow.opacity(0.35))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
                .chartYScale(domain: yLo...yHi)
                .chartPlotStyle { plot in
                    plot
                        .background(NightSky.ink.opacity(0.55), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .clipped()
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                            .foregroundStyle(NightSky.mid.opacity(0.35))
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(String(format: "%.0fh", v))
                                    .font(.system(size: 10).monospacedDigit())
                                    .foregroundStyle(OG.label3)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            .foregroundStyle(OG.label3)
                            .font(.system(size: 10))
                    }
                }
                .frame(height: 168)
                .clipped()

                Text(caption)
                    .font(.caption)
                    .foregroundStyle(OG.label3)
            }
        }
    }

    private func phaseChip(title: String, hours: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(OG.label2)
            Text(String(format: "%.1f h", hours))
                .font(.system(size: 14, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(OG.label)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(color)
                .frame(height: 3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(OG.surface2.opacity(0.9), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func phaseStackBar(deep: Double, rem: Double, light: Double) -> some View {
        let total = max(0.01, deep + rem + light)
        return GeometryReader { geo in
            HStack(spacing: 2) {
                Capsule().fill(NightSky.deep).frame(width: geo.size.width * deep / total)
                Capsule().fill(NightSky.mid).frame(width: geo.size.width * rem / total)
                Capsule().fill(NightSky.glow).frame(width: geo.size.width * light / total)
            }
        }
        .frame(height: 8)
        .clipShape(Capsule())
        .accessibilityLabel("Fases de sueño")
    }

    @ViewBuilder
    private var cycleContent: some View {
        OGCardSectionTitle(title: "Ciclo menstrual")
        OGCard {
            VStack(alignment: .leading, spacing: 14) {
                Label(recovery.cycleEstimate.rawValue, systemImage: "calendar.badge.clock")
                    .font(.headline).foregroundStyle(OG.label)
                Chart(recovery.menstrualDays.suffix(90), id: \.self) { day in
                    PointMark(x: .value("Fecha", day), y: .value("Menstruación", 1))
                        .symbolSize(75)
                        .foregroundStyle(OG.orange)
                }
                .chartYScale(domain: 0...2)
                .chartYAxis(.hidden)
                .frame(height: 105)
                Text("Registros de menstruación de los últimos 90 días")
                    .font(.caption).foregroundStyle(OG.label2)
                Divider().opacity(0.3)
                Text("Calendario de las últimas seis semanas")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(OG.label)
                cycleCalendar
                if !recovery.positiveOvulationTests.isEmpty {
                    Label("Pruebas de ovulación positivas registradas: \(recovery.positiveOvulationTests.count)", systemImage: "checkmark.circle")
                        .font(.footnote).foregroundStyle(OG.label2)
                }
                Text("Fase aproximada solo si hay suficientes ciclos compatibles. Nunca equivale a una ovulación confirmada ni debe utilizarse para anticoncepción.")
                    .font(.caption).foregroundStyle(OG.label3)
            }
        }
    }

    private var cycleCalendar: some View {
        let calendar = Calendar.current
        let currentWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start
            ?? calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .weekOfYear, value: -5, to: currentWeek) ?? currentWeek
        let days = (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
        let weekdays = (0..<7).map { offset in
            let first = calendar.firstWeekday
            return calendar.veryShortStandaloneWeekdaySymbols[(first - 1 + offset) % 7]
        }
        return VStack(spacing: 9) {
            HStack(spacing: 4) {
                ForEach(weekdays.indices, id: \.self) { index in
                    Text(weekdays[index].uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(OG.label3)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 5) {
                ForEach(days, id: \.self) { day in
                    let period = recovery.menstrualDays.contains { calendar.isDate($0, inSameDayAs: day) }
                    let today = calendar.isDateInToday(day)
                    Text(day.formatted(.dateTime.day()))
                        .font(.system(size: 12, weight: today ? .bold : .medium, design: .rounded))
                        .foregroundStyle(period ? OG.orange : OG.label)
                        .frame(maxWidth: .infinity, minHeight: 30)
                        .background(
                            period ? OG.orange.opacity(0.17) : (today ? OG.accent.opacity(0.10) : OG.surface2),
                            in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                        )
                        .accessibilityLabel(day.formatted(date: .abbreviated, time: .omitted)
                            + (period ? ", menstruación registrada" : ""))
                }
            }
            Label("Días registrados de menstruación", systemImage: "circle.fill")
                .font(.caption).foregroundStyle(OG.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

}

struct RecoveryTrainingTip: View {
    @State private var recovery = HealthRecoveryStore.shared

    var body: some View {
        Group {
            if let tip = recovery.trainingTip {
                HStack(alignment: .top, spacing: 10) {
                Image(systemName: "moon.stars.fill").foregroundStyle(OG.accent)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text("Tu contexto de hoy").font(.subheadline.weight(.semibold)).foregroundStyle(OG.label)
                        Spacer(minLength: 0)
                        if let index = recovery.sleepIndex {
                            Text("Sueño \(index)/100")
                                .font(.caption.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(OG.accent)
                        }
                    }
                    Text(tip).font(.footnote).foregroundStyle(OG.label2)
                    Text("El descanso no modifica la nota del entrenamiento.")
                        .font(.caption2)
                        .foregroundStyle(OG.label3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
                .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard))
            }
        }
        .task { await recovery.refresh() }
    }
}

struct RecoveryHomeCard: View {
    @State private var recovery = HealthRecoveryStore.shared

    var body: some View {
        if recovery.sleepEnabled || recovery.cycleEnabled {
            VStack(alignment: .leading, spacing: 8) {
                OGCardSectionTitle(title: "Tu estado de hoy")
                NavigationLink {
                    HealthRecoverySettingsView()
                } label: {
                    OGCard {
                        HStack(spacing: 14) {
                            Image(systemName: "moon.stars.fill")
                                .font(.title2)
                                .foregroundStyle(OG.accent)
                                .frame(width: 42, height: 42)
                                .background(OG.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
                            VStack(alignment: .leading, spacing: 4) {
                                if recovery.sleepEnabled {
                                    Text(recovery.lastNight.map { String(format: "%.1f h de sueño", $0.hours) }
                                        ?? "Sueño: esperando datos de Apple Salud")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(OG.label)
                                }
                                if recovery.cycleEnabled {
                                    Text(recovery.cycleEstimate.rawValue)
                                        .font(.footnote)
                                        .foregroundStyle(OG.label2)
                                }
                                if let index = recovery.sleepIndex {
                                    Text("Índice orientativo de sueño · \(index)/100")
                                        .font(.caption)
                                        .foregroundStyle(OG.label3)
                                }
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(OG.label3)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .task { await recovery.refresh() }
        }
    }
}
