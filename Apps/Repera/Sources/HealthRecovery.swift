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
    private let sleepDecisionKey = "repera.privateHealth.sleepDecisionMade"
    private let cycleDecisionKey = "repera.privateHealth.cycleDecisionMade"

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
    /// El usuario ya aceptó o rechazó el permiso de sueño (no volver a preguntar).
    private(set) var sleepDecisionMade: Bool {
        didSet { UserDefaults.standard.set(sleepDecisionMade, forKey: sleepDecisionKey) }
    }
    private(set) var cycleDecisionMade: Bool {
        didSet { UserDefaults.standard.set(cycleDecisionMade, forKey: cycleDecisionKey) }
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
        sleepDecisionMade = UserDefaults.standard.bool(forKey: sleepDecisionKey)
        cycleDecisionMade = UserDefaults.standard.bool(forKey: cycleDecisionKey)
        // Migración: si ya tenía sueño/ciclo activo, la decisión ya está tomada.
        if sleepEnabled, !sleepDecisionMade { sleepDecisionMade = true }
        if cycleEnabled, !cycleDecisionMade { cycleDecisionMade = true }
    }

    var needsSleepDecision: Bool { !sleepDecisionMade }
    /// Sueño solo se solicita si el usuario lo activó expresamente.
    /// No determinado no implica consentimiento ni un permiso pendiente obligatorio.
    var shouldRequestSleepWithHealth: Bool { sleepEnabled }

    /// Activaciones aún sin aceptar/rechazar (punto rojo en Ajustes).
    var pendingHealthItems: [String] {
        var items: [String] = []
        if !sleepDecisionMade {
            items.append("Analizar descanso (sueño)")
        }
        if !cycleDecisionMade {
            items.append("Seguimiento del ciclo")
        }
        return items
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

    /// Activar sueño vuelve a abrir el panel unificado (entrenos, pulso, energía y sueño).
    func setSleep(_ enabled: Bool) async {
        if enabled {
            await HealthKitStore.shared.requestAccess(includeSleep: true)
        } else {
            sleepDecisionMade = true
            sleepEnabled = false
            nights = []
        }
    }

    /// Se invoca solo al finalizar la solicitud conjunta de Apple Salud.
    /// Salud no revela a terceros si se aceptó la lectura: habilitar no implica tener muestras.
    func acceptSleepFromHealthAuthorization() async {
        sleepDecisionMade = true
        sleepEnabled = true
        await refresh()
    }

    /// Rechazo explícito desde los ajustes de Salud (no vuelve a preguntar).
    func declineSleep() async {
        sleepDecisionMade = true
        sleepEnabled = false
        nights = []
    }

    func setCycle(_ enabled: Bool) async {
        cycleDecisionMade = true
        cycleEnabled = enabled
        if enabled {
            await authorizeAndRefresh(types: [
                HKObjectType.categoryType(forIdentifier: .menstrualFlow)!,
                HKObjectType.categoryType(forIdentifier: .ovulationTestResult)!
            ])
        }
    }

    func declineCycle() {
        cycleDecisionMade = true
        cycleEnabled = false
        menstrualDays = []
        positiveOvulationTests = []
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
            // Hasta ~4 meses: Progreso puede filtrar por periodo largo.
            let sleep = await categorySamples(.sleepAnalysis, days: 120)
            nights = Self.combineSleep(sleep)
        }
        if cycleEnabled {
            let menstrual = await categorySamples(.menstrualFlow, days: 230)
            // Apple Salud puede registrar una muestra por día o una única muestra
            // que cubre varios días; expandirla para pintar el calendario completo.
            let calendar = Calendar.current
            menstrualDays = Array(Set(menstrual
                .filter { $0.value != HKCategoryValueVaginalBleeding.none.rawValue }
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

/// Detalle unificado: conexión HealthKit + sueño/ciclo (antes «Salud y recuperación»).
struct ConnectedHealthSettingsView: View {
    @Environment(HealthKitStore.self) private var health
    @Environment(ReperaStore.self) private var store
    @State private var recovery = HealthRecoveryStore.shared
    @State private var healthBusy = false

    var body: some View {
        Form {
            Section {
                if health.isAuthorized {
                    Label("Apple Salud con permisos activos", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(OG.label)
                    if let kcal = health.activeEnergyTodayKcal {
                        LabeledContent("kcal hoy", value: "\(Int(kcal.rounded()))")
                            .foregroundStyle(OG.label)
                    }
                } else {
                    Button {
                        Task {
                            healthBusy = true
                            defer { healthBusy = false }
                            await health.requestAccess()
                            if health.isAuthorized {
                                await store.syncBodyWeightWithHealth()
                            }
                        }
                    } label: {
                        if healthBusy {
                            ProgressView()
                        } else {
                            Label("Conectar entrenamientos y energía", systemImage: "heart")
                                .foregroundStyle(OG.label)
                        }
                    }
                    .disabled(!health.isAvailable || healthBusy)
                    if let err = health.lastError {
                        Text(err).font(.footnote).foregroundStyle(.red)
                    }
                }
            } header: {
                Text("Apple Salud")
            } footer: {
                Text("Permisos de entrenamientos, ritmo cardíaco y energía activa.")
            }

            Section {
                Toggle("Analizar descanso", isOn: Binding(
                    get: { recovery.sleepEnabled },
                    set: { enabled in
                        Task {
                            healthBusy = true
                            defer { healthBusy = false }
                            await recovery.setSleep(enabled)
                        }
                    }
                ))
                .disabled(healthBusy)

                Toggle("Seguimiento del ciclo", isOn: Binding(
                    get: { recovery.cycleEnabled },
                    set: { enabled in Task { await recovery.setCycle(enabled) } }
                ))

            } header: {
                Text("Recuperación")
            } footer: {
                Text("Sueño y ciclo se leen localmente desde Apple Salud. No se envían a Supabase ni se comparten con entrenadores.")
            }

            Section("Privacidad") {
                Label("Sin sincronización de salud con Supabase", systemImage: "iphone.gen3")
                Label("Sin compartir el ciclo ni el sueño", systemImage: "lock.shield")
                if recovery.loading { ProgressView("Leyendo Apple Salud…") }
                if healthBusy { ProgressView("Solicitando permisos…") }
                if let message = health.lastError { Text(message).foregroundStyle(OG.orange) }
                if let message = recovery.errorMessage { Text(message).foregroundStyle(OG.orange) }
                Button("Actualizar desde Apple Salud") { Task { await recovery.refresh() } }
            }
            Section {
                Text("El sueño es orientativo. Las fases menstruales son estimaciones, no confirman la ovulación ni predicen la fertilidad. Las recomendaciones no sustituyen la valoración profesional.")
                    .font(.footnote).foregroundStyle(OG.label2)
            }
        }
        .ogListChrome()
        .ogPinnedTransparentNav("Salud conectada")
        .task { await recovery.refresh() }
    }

    private func pendingRow(_ title: String) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(OG.red)
                .frame(width: 8, height: 8)
            Text(title)
                .foregroundStyle(OG.label)
            Spacer()
        }
    }
}

/// Compat: redirige al detalle unificado.
struct HealthRecoverySettingsView: View {
    var body: some View {
        ConnectedHealthSettingsView()
    }
}

struct HealthRecoveryProgressView: View {
    var range: ProgressTimeRange = .week
    var weekStartsOnMonday: Bool = true

    @State private var recovery = HealthRecoveryStore.shared
    @Environment(SubscriptionManager.self) private var subscriptions

    private var isPro: Bool { subscriptions.isPro }
    private var hasCycleData: Bool { !recovery.menstrualDays.isEmpty }

    private enum NightSky {
        static let ink = Color(red: 0.07, green: 0.10, blue: 0.22)
        static let deep = Color(red: 0.16, green: 0.24, blue: 0.52)
        static let mid = Color(red: 0.32, green: 0.42, blue: 0.78)
        static let glow = Color(red: 0.55, green: 0.68, blue: 0.95)
        static let rem = Color(red: 0.72, green: 0.82, blue: 1.0)
        /// Icono luna (Inicio + Progreso).
        static let icon = Color(red: 0.30, green: 0.22, blue: 0.58)
    }

    private var nightsInRange: [RecoverySleepNight] {
        recovery.nights.filter {
            range.contains($0.date, weekStartsOnMonday: weekStartsOnMonday)
        }
    }

    /// Si el periodo actual está vacío pero hay noches anteriores, mostrarlas (no mentir con «sin datos»).
    private var displayNights: [RecoverySleepNight] {
        if !nightsInRange.isEmpty { return nightsInRange }
        return Array(recovery.nights.suffix(14))
    }

    private var showingOutsideRange: Bool {
        nightsInRange.isEmpty && !recovery.nights.isEmpty
    }

    private var hasSleepData: Bool { recovery.sleepEnabled && !displayNights.isEmpty }

    private var isSingleNight: Bool { displayNights.count <= 1 || (range == .today && !showingOutsideRange) }

    private var headlineHours: Double? {
        guard !displayNights.isEmpty else { return nil }
        if isSingleNight { return displayNights.last?.hours }
        return displayNights.map(\.hours).reduce(0, +) / Double(displayNights.count)
    }

    private var phaseAverages: (deep: Double, rem: Double, light: Double) {
        guard !displayNights.isEmpty else { return (0, 0, 0) }
        let n = Double(displayNights.count)
        let deep = displayNights.map(\.deepHours).reduce(0, +) / n
        let rem = displayNights.map(\.remHours).reduce(0, +) / n
        let light = displayNights.map { max(0, $0.hours - $0.deepHours - $0.remHours) }.reduce(0, +) / n
        return (deep, rem, light)
    }

    private var periodIndex: Int? {
        RecoveryEngine.sleepIndex(hours: headlineHours, recentAverage: headlineHours)
    }

    private struct IndexedNight: Identifiable {
        let date: Date
        let score: Int
        var id: Date { date }
    }

    /// Misma fórmula de descanso que utiliza el índice principal; no es una
    /// medida clínica de recuperación muscular ni una puntuación deportiva.
    private var scoredNights: [IndexedNight] {
        displayNights.compactMap { night in
            guard let score = RecoveryEngine.sleepIndex(
                hours: night.hours,
                recentAverage: recovery.averageHours
            ) else { return nil }
            return IndexedNight(date: night.date, score: score)
        }.sorted { $0.date < $1.date }
    }

    private var hoursLabel: String {
        if showingOutsideRange {
            return displayNights.count <= 1 ? "Última noche disponible" : "Media · noches recientes"
        }
        return isSingleNight ? "Última noche" : "Media · \(range.subtitleLabel)"
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

    @ViewBuilder
    private var freeRecoveryPreview: some View {
        let sample = Self.teaserNights(for: range, weekStartsOnMonday: weekStartsOnMonday)
        let deep = sample.map(\.deepHours).reduce(0, +) / Double(max(1, sample.count))
        let rem = sample.map(\.remHours).reduce(0, +) / Double(max(1, sample.count))
        let light = sample.map { max(0, $0.hours - $0.deepHours - $0.remHours) }.reduce(0, +) / Double(max(1, sample.count))
        let hours = sample.map(\.hours).reduce(0, +) / Double(max(1, sample.count))
        VStack(alignment: .leading, spacing: 8) {
            OGCardSectionTitle(title: "Sueño · ejemplo")
            sleepNightCard(
                hours: hours,
                hoursCaption: sample.count <= 1 ? "Última noche" : "Media · \(range.subtitleLabel)",
                index: 82,
                deep: deep,
                rem: rem,
                light: light,
                nights: sample,
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
                Text(recovery.sleepEnabled
                     ? "Sin registros de sueño en Apple Salud todavía."
                     : "Activa el análisis de descanso en Ajustes → Salud conectada.")
                    .font(.subheadline)
                    .foregroundStyle(OG.label2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private static func teaserNights(for range: ProgressTimeRange, weekStartsOnMonday: Bool) -> [RecoverySleepNight] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let count = min(14, max(1, range.chartDayCount))
        let start = range.startDate(now: Date(), weekStartsOnMonday: weekStartsOnMonday) ?? today
        return (0..<count).compactMap { offset -> RecoverySleepNight? in
            guard let day = cal.date(byAdding: .day, value: offset, to: start), day <= today else { return nil }
            let t = Double(offset)
            let deep = max(0.6, 1.2 + 0.4 * sin(t * 0.8))
            let rem = max(0.7, 1.4 + 0.35 * cos(t * 1.1))
            let light = max(2.0, 3.2 + 0.5 * cos(t * 0.9))
            return RecoverySleepNight(date: day, hours: deep + rem + light, deepHours: deep, remHours: rem)
        }
    }

    @ViewBuilder
    private var sleepContent: some View {
        OGCardSectionTitle(title: "Sueño")
        let phases = phaseAverages
        let nights = displayNights
        sleepNightCard(
            hours: headlineHours,
            hoursCaption: hoursLabel,
            index: periodIndex,
            deep: phases.deep,
            rem: phases.rem,
            light: phases.light,
            nights: nights,
            caption: {
                if showingOutsideRange {
                    return "Sin noches en \(range.subtitleLabel) · mostrando registros anteriores."
                }
                if isSingleNight {
                    return "Fases estimadas por el dispositivo · una fuente por noche."
                }
                return String(format: "Media de %d noches en %@.", nights.count, range.subtitleLabel)
            }()
        )
        if scoredNights.count >= 2 {
            sleepTrendCard(scoredNights)
        }
    }

    /// Evolución visible únicamente cuando existen al menos dos noches con índice real.
    private func sleepTrendCard(_ values: [IndexedNight]) -> some View {
        let latest = values[values.count - 1].score
        let previous = values[values.count - 2].score
        let delta = latest - previous
        let headline = delta >= 4 ? "Mejora respecto a la noche anterior"
            : delta <= -4 ? "Descanso por debajo de la noche anterior"
            : "Descanso estable respecto a la noche anterior"
        return VStack(alignment: .leading, spacing: 8) {
            OGCardSectionTitle(title: "Evolución del descanso")
            OGCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(headline)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(OG.label)
                        Spacer(minLength: 4)
                        Text("\(latest)/100")
                            .font(.system(size: 17, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(OG.label)
                    }
                    Chart(values) { night in
                        LineMark(
                            x: .value("Noche", night.date),
                            y: .value("Índice de sueño", night.score)
                        )
                        .foregroundStyle(OG.accent)
                        .interpolationMethod(.linear)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        PointMark(
                            x: .value("Noche", night.date),
                            y: .value("Índice de sueño", night.score)
                        )
                        .foregroundStyle(
                            night.score >= 80 ? OG.accent : (night.score >= 60 ? OG.orange : OG.red)
                        )
                        .symbolSize(44)
                    }
                    .chartYScale(domain: 0...100)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [0, 50, 100])
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        }
                    }
                    .frame(height: 160)

                    Text("Índice orientativo calculado con horas de sueño, no una medición directa de recuperación.")
                        .font(.caption)
                        .foregroundStyle(OG.label3)
                }
            }
        }
    }

    private func sleepNightCard(
        hours: Double?,
        hoursCaption: String,
        index: Int?,
        deep: Double,
        rem: Double,
        light: Double,
        nights: [RecoverySleepNight],
        caption: String
    ) -> some View {
        let yLo = max(3.5, (nights.map(\.hours).min() ?? 5) - 0.6)
        let yHi = min(11, (nights.map(\.hours).max() ?? 8) + 0.7)
        let xStart = nights.map(\.date).min() ?? Date()
        let xEnd = nights.map(\.date).max() ?? Date()
        return OGCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(NightSky.glow)
                        .frame(width: 40, height: 40)
                        .background(NightSky.ink, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(hoursCaption)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(OG.label2)
                        HStack(alignment: .firstTextBaseline, spacing: 5) {
                            Text(hours.map { String(format: "%.1f", $0) } ?? "—")
                                .font(.system(size: 28, weight: .semibold, design: .rounded).monospacedDigit())
                                .foregroundStyle(OG.label)
                            Text("h")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(OG.label2)
                        }
                    }
                    Spacer(minLength: 8)
                    if let index {
                        Text("\(index)/100")
                            .font(.system(size: 22, weight: .semibold, design: .rounded).monospacedDigit())
                            .foregroundStyle(OG.label)
                            .accessibilityLabel("Descanso \(index) de 100")
                    }
                }

                if deep + rem + light > 0.2 {
                    phaseDistributionBar(deep: deep, rem: rem, light: light)
                }

                Chart {
                    ForEach(nights) { night in
                        AreaMark(
                            x: .value("Día", night.date),
                            yStart: .value("Base", yLo),
                            yEnd: .value("Horas", night.hours)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [NightSky.mid.opacity(0.5), NightSky.ink.opacity(0.15)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Día", night.date),
                            y: .value("Horas", night.hours)
                        )
                        .foregroundStyle(NightSky.glow)
                        .lineStyle(StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Día", night.date),
                            y: .value("Horas", night.hours)
                        )
                        .symbolSize(nights.count > 10 ? 22 : 36)
                        .foregroundStyle(NightSky.rem)
                    }
                }
                .chartXScale(domain: xStart...xEnd)
                .chartYScale(domain: yLo...yHi)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartLegend(.hidden)
                .chartPlotStyle { $0.clipped() }
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .background(NightSky.ink, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .clipped()

                if nights.count > 1 {
                    HStack {
                        Text(xStart.formatted(.dateTime.day().month(.abbreviated)))
                        Spacer()
                        Text(xEnd.formatted(.dateTime.day().month(.abbreviated)))
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(OG.label3)
                }

                Text(caption)
                    .font(.caption)
                    .foregroundStyle(OG.label3)
            }
        }
    }

    /// Barra de fases con etiquetas encima (sin tiles sueltos).
    private func phaseDistributionBar(deep: Double, rem: Double, light: Double) -> some View {
        let total = max(0.01, deep + rem + light)
        return VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                let w = geo.size.width
                HStack(spacing: 0) {
                    phaseSegment(title: "Profundo", hours: deep, width: w * deep / total, color: NightSky.deep)
                    phaseSegment(title: "REM", hours: rem, width: w * rem / total, color: NightSky.mid)
                    phaseSegment(title: "Ligero", hours: light, width: w * light / total, color: NightSky.glow)
                }
            }
            .frame(height: 36)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Distribución de fases")
    }

    private func phaseSegment(title: String, hours: Double, width: CGFloat, color: Color) -> some View {
        VStack(spacing: 2) {
            if width >= 52 {
                Text(title)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(String(format: "%.1fh", hours))
                    .font(.system(size: 11, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
            } else if width >= 28 {
                Text(String(format: "%.1f", hours))
                    .font(.system(size: 10, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
            }
        }
        .frame(width: width, height: 36)
        .background(color)
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

    /// Mismo `moon.stars.fill` / cielo nocturno que Progreso → Sueño.
    private static let nightInk = Color(red: 0.07, green: 0.10, blue: 0.22)
    private static let nightGlow = Color(red: 0.55, green: 0.68, blue: 0.95)

    private var lastNight: RecoverySleepNight? {
        recovery.sleepEnabled ? recovery.lastNight : nil
    }

    private var hasCycleSnippet: Bool {
        recovery.cycleEnabled && !recovery.menstrualDays.isEmpty
    }

    /// Solo con datos reales; el vacío vive en Progreso → Recuperación.
    private var hasHomeData: Bool { lastNight != nil || hasCycleSnippet }

    var body: some View {
        Group {
            if hasHomeData {
                VStack(alignment: .leading, spacing: 8) {
                    OGCardSectionTitle(title: "Tu estado de hoy")
                    NavigationLink {
                        ConnectedHealthSettingsView()
                    } label: {
                        OGCard {
                            HStack(spacing: 14) {
                                Image(systemName: "moon.stars.fill")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(Self.nightGlow)
                                    .frame(width: 42, height: 42)
                                    .background(Self.nightInk, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                                VStack(alignment: .leading, spacing: 4) {
                                    if let night = lastNight {
                                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                                            Text(String(format: "%.1f h de sueño", night.hours))
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(OG.label)
                                            if let index = recovery.sleepIndex {
                                                Text("· \(index)/100")
                                                    .font(.subheadline.weight(.semibold).monospacedDigit())
                                                    .foregroundStyle(OG.label2)
                                            }
                                        }
                                    }
                                    if hasCycleSnippet {
                                        Text(recovery.cycleEstimate.rawValue)
                                            .font(.footnote)
                                            .foregroundStyle(OG.label2)
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
            }
        }
        .task { await recovery.refresh() }
    }
}
