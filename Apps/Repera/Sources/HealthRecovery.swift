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

    /// Desde la única solicitud de Apple Salud se habilitan las consultas
    /// locales de sueño y ciclo. Esto NO afirma que el permiso de lectura
    /// se haya concedido: HealthKit solo devuelve las muestras autorizadas.
    /// Nunca se fabrican datos ni se incorporan estos datos a Supabase.
    func enableUnifiedHealthAnalysis() async {
        sleepDecisionMade = true
        cycleDecisionMade = true
        sleepEnabled = true
        cycleEnabled = true
        await refresh()
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

/// Local-only, optional HealthKit observations. No values or derived scores
/// are persisted in AppState, iCloud workout documents or Supabase.
/// Sendable values produced by the nonisolated HealthKit query callback.
private struct PhysiologyReading: Sendable {
    let date: Date
    let value: Double
}

private enum PhysiologicalUnit: Sendable {
    case milliseconds, bpm, percent, celsius
}

@MainActor
@Observable
final class HealthPhysiologyStore {
    static let shared = HealthPhysiologyStore()
    private let healthStore = HKHealthStore()

    private(set) var days: [RecoveryEngine.DailyVitals] = []
    private(set) var isLoading = false
    private(set) var lastRefreshed: Date?

    private init() {}

    /// Missing rows are omitted, never interpreted as zero or as accepted
    /// permission. Each HealthKit type is independently optional.
    func refresh() async {
        guard HKHealthStore.isHealthDataAvailable(), !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        let since = Date().addingTimeInterval(-45 * 86_400)
        let hrv = await read(.heartRateVariabilitySDNN, unit: .milliseconds, since: since)
        let rest = await read(.restingHeartRate, unit: .bpm, since: since)
        let breathing = await read(.respiratoryRate, unit: .bpm, since: since)
        let oxygen = await read(.oxygenSaturation, unit: .percent, since: since)
        let wrist = await read(.appleSleepingWristTemperature, unit: .celsius, since: since)
        let hrRecovery = await read(.heartRateRecoveryOneMinute, unit: .bpm, since: since)

        let cal = Calendar.current
        let dates = Set((hrv + rest + breathing + oxygen + wrist + hrRecovery)
            .map { cal.startOfDay(for: $0.date) })

        func median(
            _ samples: [PhysiologyReading], for day: Date,
            valid: ClosedRange<Double>, beforeTrainingMorning: Bool = false
        ) -> Double? {
            let cutoff = cal.date(bySettingHour: 7, minute: 0, second: 0, of: day)
                ?? day.addingTimeInterval(7 * 3600)
            let sorted = samples.compactMap { record -> Double? in
                guard cal.isDate(record.date, inSameDayAs: day),
                      !beforeTrainingMorning || record.date <= cutoff,
                      record.value.isFinite, valid.contains(record.value) else { return nil }
                return record.value
            }.sorted()
            guard !sorted.isEmpty else { return nil }
            let i = sorted.count / 2
            return sorted.count.isMultiple(of: 2) ? (sorted[i-1] + sorted[i]) / 2 : sorted[i]
        }

        days = dates.sorted().map { day in
            // HealthKit oxygen percentages may be stored as ratios (0…1).
            let oxygenValue = median(oxygen, for: day, valid: 0...100)
            return RecoveryEngine.DailyVitals(
                date: day,
                hrvMilliseconds: median(hrv, for: day, valid: 5...300, beforeTrainingMorning: true),
                restingHeartRateBpm: median(rest, for: day, valid: 30...130, beforeTrainingMorning: true),
                respiratoryRateBpm: median(breathing, for: day, valid: 6...40, beforeTrainingMorning: true),
                oxygenSaturationPercent: oxygenValue.map { $0 <= 1 ? $0 * 100 : $0 },
                wristTemperatureCelsius: median(wrist, for: day, valid: 25...42),
                heartRateRecoveryBpm: median(hrRecovery, for: day, valid: 0...100)
            )
        }
        lastRefreshed = Date()
    }

    private func read(
        _ id: HKQuantityTypeIdentifier, unit: PhysiologicalUnit, since: Date
    ) async -> [PhysiologyReading] {
        guard let type = HKObjectType.quantityType(forIdentifier: id) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: since, end: Date())
        return await withCheckedContinuation { (cont: CheckedContinuation<[PhysiologyReading], Never>) in
            let query = HKSampleQuery(
                sampleType: type, predicate: predicate,
                limit: HKObjectQueryNoLimit, sortDescriptors: nil
            ) { _, samples, _ in
                let hkUnit: HKUnit
                switch unit {
                case .milliseconds: hkUnit = .secondUnit(with: .milli)
                case .bpm: hkUnit = .count().unitDivided(by: .minute())
                case .percent: hkUnit = .percent()
                case .celsius: hkUnit = .degreeCelsius()
                }
                let observed = (samples as? [HKQuantitySample] ?? []).map {
                    PhysiologyReading(date: $0.endDate, value: $0.quantity.doubleValue(for: hkUnit))
                }
                cont.resume(returning: observed)
            }
            healthStore.execute(query)
        }
    }
}

/// Detalle unificado: conexión HealthKit + sueño/ciclo (antes «Salud y recuperación»).
struct ConnectedHealthSettingsView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(HealthKitStore.self) private var health
    @Environment(ReperaStore.self) private var store
    @State private var recovery = HealthRecoveryStore.shared
    @State private var healthBusy = false
    @State private var showHealthPermissionsHelp = false

    /// One entrypoint for Apple's entire permission request. HealthKit can
    /// only show undecided types; previously chosen access is edited in
    /// Settings > Salud > Acceso de datos y dispositivos.
    private func manageHealthPermissions() async {
        guard !healthBusy else { return }
        healthBusy = true
        defer { healthBusy = false }

        await health.requestAccess(includeAllOptional: true)
        guard health.lastError == nil else { return }
        if health.isAuthorized {
            await store.syncBodyWeightWithHealth()
        }
        await recovery.refresh()
        await HealthPhysiologyStore.shared.refresh()
        if health.permissionManagementRequiresSettings {
            showHealthPermissionsHelp = true
        }
    }

    var body: some View {
        Form {
            Section {
                Button {
                    Task { await manageHealthPermissions() }
                } label: {
                    HStack(spacing: 12) {
                        Label("Apple Salud", systemImage: "heart.text.square")
                            .foregroundStyle(OG.label)
                        Spacer(minLength: 8)
                        if healthBusy {
                            ProgressView()
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(OG.label3)
                        }
                    }
                }
                .disabled(!health.isAvailable || healthBusy)

                if let kcal = health.activeEnergyTodayKcal {
                    LabeledContent("kcal hoy", value: "\(Int(kcal.rounded()))")
                        .foregroundStyle(OG.label)
                }

            }

            Section("Privacidad") {
                Label("Tus datos de salud solo en tu móvil", systemImage: "iphone.gen3")
                Label("Sin compartir el ciclo ni el sueño", systemImage: "lock.shield")
                if recovery.loading { ProgressView("Leyendo Apple Salud…") }
                if healthBusy { ProgressView("Solicitando permisos…") }
                if let message = health.lastError { Text(message).foregroundStyle(OG.orange) }
                if let message = recovery.errorMessage { Text(message).foregroundStyle(OG.orange) }
            }
        }
        .ogListChrome()
        .ogPinnedTransparentNav("Salud conectada")
        .alert("Permisos de Apple Salud", isPresented: $showHealthPermissionsHelp) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text("Para cambiar permisos que ya has aceptado o rechazado: Ajustes → Salud → Acceso de datos y dispositivos → Repera.")
        }
        .task {
            // Leer datos auténticos al entrar; no hace falta un botón manual.
            await health.refreshToday()
            await recovery.refresh()
            await HealthPhysiologyStore.shared.refresh()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            // Actualizar si se vuelve desde Salud/Ajustes tras cambiar permisos.
            Task {
                await health.refreshToday()
                await recovery.refresh()
                await HealthPhysiologyStore.shared.refresh()
            }
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
    /// El contenedor Progreso conoce el ancho de pantalla. No recalcularlo
    /// al entrar en Recuperación: ese segundo cambio hacía parpadear la cuadrícula.
    var usesExpandedLayout = false

    @State private var recovery = HealthRecoveryStore.shared
    @State private var physiology = HealthPhysiologyStore.shared
    @State private var recoveryPoints: [TrainingRecoveryPoint] = []
    @State private var selectedRecoveryDate: Date?
    @State private var selectedSleepDate: Date?
    @State private var selectedVitalDate: Date?
    @State private var selectedPhysiologyDate: Date?
    @State private var currentReadiness: RecoveryEngine.TrainingReadiness?
    @State private var currentSleepHours: Double?
    @Environment(HealthKitStore.self) private var health
    @State private var appliedRecoveryKey: String = ""
    @Environment(ReperaStore.self) private var store
    @Environment(SubscriptionManager.self) private var subscriptions

    private var isPro: Bool { subscriptions.isPro }
    /// La superficie de cada columna en DUO determina la altura real de
    /// las gráficas: nunca se rellena una tarjeta con padding blanco.
    private let primaryChartHeight: CGFloat = 220
    @State private var recoveryGridWidth: CGFloat = 0
    private var duoColumnWidth: CGFloat? {
        guard usesExpandedLayout, recoveryGridWidth > 0 else { return nil }
        return (recoveryGridWidth - 16) / 2
    }
    private var readinessChartHeight: CGFloat {
        guard let width = duoColumnWidth else { return primaryChartHeight }
        // Un tercio menos alto que la antigua tarjeta casi cuadrada.
        // Se reduce de verdad también la gráfica; no se deja relleno vacío.
        return max(205, min(270, (width - OG.pad * 2) * (2.0 / 3.0)))
    }
    private var sleepChartHeight: CGFloat {
        guard let width = duoColumnWidth else { return primaryChartHeight }
        return max(220, width - 150)
    }
    private var physiologyChartHeight: CGFloat {
        guard let width = duoColumnWidth else { return 128 }
        let additionalVitals = physiology.days.last.map {
            $0.oxygenSaturationPercent != nil || $0.wristTemperatureCelsius != nil
                || $0.heartRateRecoveryBpm != nil
        } ?? false
        return max(128, width - (additionalVitals ? 330 : 265))
    }

    private struct TrainingRecoveryPoint: Identifiable, Sendable {
        let date: Date
        let score: Double
        var id: Date { date }
    }

    private var trainingRecoveryRefreshKey: String {
        "\(range.rawValue)|\(weekStartsOnMonday)|\(store.workoutsEpoch)|\(recovery.lastRefreshed?.timeIntervalSince1970 ?? 0)|\(recovery.sleepEnabled)|\(physiology.lastRefreshed?.timeIntervalSince1970 ?? 0)|\(health.healthDataRevision)"
    }

    /// Evolución de las mañanas registradas y estado actual tras la actividad
    /// de hoy. No se proyecta una nota futura usando sueño supuesto.
    private func prepareTrainingRecovery() async {
        let key = trainingRecoveryRefreshKey
        guard recovery.sleepEnabled else {
            recoveryPoints = []
            currentReadiness = nil
            currentSleepHours = nil
            appliedRecoveryKey = key
            return
        }
        let nights = recovery.nights
        let vitalHistory = physiology.days
        let workouts = store.state.workouts.filter { $0.finishedAt != nil }
        // HealthKit ya excluye UUID y solapes con entrenamientos Repera.
        let external = health.recentExternalActivities.map { activity in
            RecoveryEngine.ObservedActivity(
                // Contar la carga cuando el HKWorkout terminó, no al
                // empezar: un entreno 06:00–08:00 no puede influir a las 07:00.
                date: activity.end, durationMinutes: activity.durationMinutes,
                isCardio: HealthMuscleMapper.isCardio(activity.activityType)
            )
        }
        let averageHours = recovery.averageHours
        let selectedRange = range
        let mondayFirst = weekStartsOnMonday
        let now = Date()
        let result = await Task.detached(priority: .userInitiated) {
            let calendar = Calendar.current
            let points: [TrainingRecoveryPoint] = nights.compactMap { night in
                guard selectedRange.contains(night.date, now: now, weekStartsOnMonday: mondayFirst),
                      let morning = calendar.date(
                        bySettingHour: 7, minute: 0, second: 0, of: night.date
                      ), morning <= now,
                      let value = RecoveryEngine.trainingReadiness(
                        at: morning, sleepHours: night.hours,
                        recentAverageSleepHours: averageHours,
                        workouts: workouts, vitalHistory: vitalHistory,
                        observedActivities: external
                      ) else { return nil }
                return TrainingRecoveryPoint(date: night.date, score: value.score)
            }
            let todayNight = nights.last {
                calendar.isDate($0.date, inSameDayAs: now)
            }
            let current = todayNight.flatMap { night in
                RecoveryEngine.trainingReadiness(
                    at: now, sleepHours: night.hours,
                    recentAverageSleepHours: averageHours,
                    workouts: workouts, vitalHistory: vitalHistory,
                    observedActivities: external
                )
            }
            return (points.sorted { $0.date < $1.date }, current, todayNight?.hours)
        }.value
        guard !Task.isCancelled, key == trainingRecoveryRefreshKey else { return }
        recoveryPoints = result.0
        currentReadiness = result.1
        currentSleepHours = result.2
        appliedRecoveryKey = key
    }
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

    private var hoursLabel: String {
        if showingOutsideRange {
            return displayNights.count <= 1 ? "Última noche disponible" : "Media · noches recientes"
        }
        return isSingleNight ? "Última noche" : "Media · \(range.subtitleLabel)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if usesExpandedLayout {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16, alignment: .top),
                    GridItem(.flexible(), spacing: 16, alignment: .top)
                ], alignment: .leading, spacing: 16) {
                    recoveryCards
                }
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    recoveryCards
                }
            }
            // Fuera de LazyVGrid para ocupar TODAS las columnas. Un único
            // banner común en versión gratuita, sin medias tarjetas.
            if !isPro {
                recoveryUpsellBanner
            }
        }
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width }) { _, width in
            if abs(recoveryGridWidth - width) > 1 { recoveryGridWidth = width }
        }
        // Las lecturas de Salud ya se han cargado: no reiniciar todas las
        // tarjetas al entrar y salir de la pestaña Recuperación.
        .task {
            if recovery.lastRefreshed == nil { await recovery.refresh() }
            if physiology.lastRefreshed == nil { await physiology.refresh() }
        }
        .task(id: trainingRecoveryRefreshKey) {
            await prepareTrainingRecovery()
        }
    }

    @ViewBuilder
    private var recoveryCards: some View {
        trainingRecoveryCard
        if isPro {
            // Reservar siempre la misma celda. Al actualizar Apple Salud no
            // desaparece la gráfica ni se recolocan las tarjetas de sueño.
            if recoveryPoints.count >= 2 {
                trainingRecoveryTrendCard
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    OGCardSectionTitle(title: "Evolución de recuperación")
                    OGCard {
                        ProgressEmptyChart(
                            message: "Aún no hay suficientes registros para ver la recuperación.",
                            height: primaryChartHeight
                        )
                        .frame(height: readinessChartHeight)
                    }
                }
            }
        } else {
            recoveryTrendPreview
        }

        if hasSleepData {
            sleepContent
        } else {
            softSleepEmpty
        }
        if isPro {
            physiologyContent
        } else {
            physiologyPreview
        }
        if hasCycleData {
            cycleContent
        }
    }

    private var recoveryUpsellBanner: some View {
        ProTeaserCard(
            title: "Recuperación completa",
            bodyText: "Consulta cómo evolucionan tu descanso y tu preparación para entrenar.",
            cta: "Descubrir Repera Pro",
            appearance: .recovery
        ) {
            subscriptions.presentPaywall(.progress, feature: .advancedProgress)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Muestras Pro independientes de Apple Salud, siempre rotuladas como ficticias.
    private var recoveryTrendPreview: some View {
        let scores: [Double] = [5, 6, 7, 6, 8, 7, 9]
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                OGCardSectionTitle(title: "Evolución de recuperación")
                Spacer()
                Text("Ejemplo")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(OG.label2)
            }
            OGCard(padding: 10, verticalPadding: OG.pad) {
                Chart {
                    ForEach(0..<scores.count, id: \.self) { index in
                        LineMark(
                            x: .value("Día", index + 1),
                            y: .value("Recuperación", scores[index])
                        )
                        .foregroundStyle(OG.accent)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    }
                }
                .chartXScale(domain: 0...8)
                .chartYScale(domain: 0.0...10.0)
                .chartPlotStyle { $0.clipped() }
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0.0, 5.0, 10.0])
                }
                .frame(height: readinessChartHeight)
                .allowsHitTesting(false)
            }
        }
        .accessibilityLabel("Ejemplo de evolución de recuperación, datos ficticios.")
    }

    private var physiologyPreview: some View {
        let hrv: [Double] = [46, 51, 48, 55, 53, 62, 58]
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                OGCardSectionTitle(title: "Constantes fisiológicas")
                Spacer()
                Text("Ejemplo")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(OG.label2)
            }
            OGCard(padding: 10, verticalPadding: OG.pad) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Variabilidad cardíaca (VFC)")
                            .font(.subheadline)
                            .foregroundStyle(OG.label2)
                        Spacer()
                        Text("\(Int(hrv.last ?? 0)) ms")
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .foregroundStyle(OG.label2)
                    }
                    Chart {
                        ForEach(0..<hrv.count, id: \.self) { index in
                            LineMark(
                                x: .value("Día", index + 1),
                                y: .value("VFC", hrv[index])
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(OG.accent)
                        }
                    }
                    .chartXScale(domain: 0...8)
                    .chartPlotStyle { $0.clipped() }
                    .frame(height: physiologyChartHeight)
                    Divider().opacity(0.25)
                    HStack(alignment: .top, spacing: 10) {
                        physiologyPreviewBars("Pulso en reposo", unit: "lpm", values: [66, 63, 65, 61, 60, 62, 58])
                        physiologyPreviewBars("Respiración", unit: "rpm", values: [16, 15, 15, 14, 16, 14, 13])
                    }
                }
                .allowsHitTesting(false)
            }
        }
        .accessibilityLabel("Ejemplo de constantes fisiológicas, datos ficticios.")
    }

    private func physiologyPreviewBars(_ title: String, unit: String, values: [Double]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(OG.label2)
            Text("\(Int(values.last ?? 0)) \(unit)")
                .font(.system(size: 17, weight: .semibold).monospacedDigit())
                .foregroundStyle(OG.label)
            Chart {
                ForEach(0..<values.count, id: \.self) { index in
                    BarMark(
                        x: .value("Día", index + 1),
                        y: .value(title, values[index])
                    )
                    .foregroundStyle(OG.accent.opacity(0.8))
                    .cornerRadius(3)
                }
            }
            .chartXScale(domain: 0...8)
            .chartPlotStyle { $0.clipped() }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 98)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12))
    }

    private var softSleepEmpty: some View {
        VStack(alignment: .leading, spacing: 8) {
            OGCardSectionTitle(title: "Sueño")
            OGCard {
                ProgressEmptyChart(
                    message: recovery.sleepEnabled
                        ? "Sin registros de sueño en Apple Salud todavía."
                        : "Activa el análisis de descanso en Ajustes → Salud conectada.",
                    height: sleepChartHeight,
                    yRange: 0.0...10.0
                )
            }
        }
    }

    /// Título y gráfica son UNA sola celda del grid, no dos celdas contiguas.
    /// De otro modo «Sueño» se dibuja a la izquierda y la gráfica a la derecha,
    /// desplazando el resto de secciones a la siguiente fila.
    private var sleepContent: some View {
        let phases = phaseAverages
        let nights = displayNights
        return VStack(alignment: .leading, spacing: 8) {
            OGCardSectionTitle(title: "Sueño")
            sleepNightCard(
                hours: headlineHours,
                hoursCaption: hoursLabel,
                deep: phases.deep,
                rem: phases.rem,
                light: phases.light,
                nights: nights
            )
        }
    }

    private struct VitalPlot: Identifiable {
        let date: Date
        let value: Double
        var id: Date { date }
    }

    /// VFC conserva la evolución, sin marcadores estáticos.
    private func vitalChart(
        _ title: String, unit: String,
        keyPath: KeyPath<RecoveryEngine.DailyVitals, Double?>
    ) -> some View {
        let values = vitalValues(keyPath)
        return VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(title).font(.subheadline.weight(.medium)).foregroundStyle(OG.label)
                Spacer()
                if let last = values.last {
                    Text(String(format: "%.0f %@", last.value, unit))
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(OG.label2)
                }
            }
            if values.count >= 2 {
                Chart {
                    ForEach(values) { sample in
                        LineMark(x: .value("Día", sample.date), y: .value(title, sample.value))
                            .interpolationMethod(.linear)
                            .foregroundStyle(OG.accent)
                    }
                    if let selectedVitalDate,
                       let selected = values.min(by: {
                           abs($0.date.timeIntervalSince(selectedVitalDate)) < abs($1.date.timeIntervalSince(selectedVitalDate))
                       }) {
                        RuleMark(x: .value("Día seleccionado", selected.date))
                            .foregroundStyle(OG.label2)
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4]))
                            .annotation(position: .top) {
                                Text(String(format: "%.0f %@", selected.value, unit))
                                    .font(.caption.weight(.semibold))
                                    .padding(5)
                                    .background(OG.surface, in: RoundedRectangle(cornerRadius: 6))
                            }
                    }
                }
                .chartXSelection(value: $selectedVitalDate)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 3)) {
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    }
                }
                .frame(height: physiologyChartHeight)
                .accessibilityLabel("Tendencia: \(title)")
            } else {
                ProgressEmptyChart(
                    message: values.isEmpty
                        ? "Sin mediciones en este periodo."
                        : "Una medición; aún no hay tendencia.",
                    height: physiologyChartHeight,
                    yRange: 0.0...100.0
                )
            }
        }
    }

    private func vitalValues(_ keyPath: KeyPath<RecoveryEngine.DailyVitals, Double?>) -> [VitalPlot] {
        physiology.days.filter {
            range.contains($0.date, weekStartsOnMonday: weekStartsOnMonday)
        }.compactMap { sample in
            guard let value = sample[keyPath: keyPath] else { return nil }
            return VitalPlot(date: sample.date, value: value)
        }
    }

    /// Dos minigráficas de barras: mismo bloque, escalas independientes
    /// para no equiparar lpm y respiraciones/min.
    private func vitalBarTile(
        _ title: String, unit: String,
        keyPath: KeyPath<RecoveryEngine.DailyVitals, Double?>
    ) -> some View {
        let values = vitalValues(keyPath)
        let selected = selectedPhysiologyDate.flatMap { date in
            values.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
        }
        return VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 12, weight: .medium)).foregroundStyle(OG.label2)
            Text(values.last.map { String(format: "%.0f %@", $0.value, unit) } ?? "—")
                .font(.system(size: 17, weight: .semibold).monospacedDigit())
                .foregroundStyle(OG.label)
            if !values.isEmpty {
                Chart {
                    ForEach(values) { sample in
                        BarMark(x: .value("Día", sample.date, unit: .day),
                                y: .value(title, sample.value))
                            .foregroundStyle(OG.accent.opacity(0.8))
                            .cornerRadius(3)
                    }
                    if let selected {
                        RuleMark(x: .value("Día seleccionado", selected.date))
                            .foregroundStyle(OG.label2)
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4]))
                            .annotation(position: .top) {
                                Text(String(format: "%.0f %@", selected.value, unit))
                                    .font(.caption2.weight(.semibold))
                            }
                    }
                }
                .chartXSelection(value: $selectedPhysiologyDate)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 98)
            } else {
                ProgressEmptyChart(
                    message: "Sin datos",
                    height: 98,
                    yRange: 0.0...100.0
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12))
    }

    private func vitalValueTile(_ label: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(OG.label2)
            Text(value)
                .font(.system(size: 19, weight: .semibold).monospacedDigit())
                .foregroundStyle(OG.label)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12))
    }

    private var physiologyContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            OGCardSectionTitle(title: "Constantes fisiológicas")
            OGCard(padding: 10, verticalPadding: OG.pad) {
                VStack(alignment: .leading, spacing: 14) {
                    vitalChart("Variabilidad cardíaca (VFC)", unit: "ms", keyPath: \.hrvMilliseconds)
                    Divider().opacity(0.25)
                    HStack(alignment: .top, spacing: 10) {
                        vitalBarTile("Pulso en reposo", unit: "lpm", keyPath: \.restingHeartRateBpm)
                        vitalBarTile("Respiración", unit: "resp/min", keyPath: \.respiratoryRateBpm)
                    }
                    if let latest = physiology.days.last {
                        HStack(alignment: .top, spacing: 10) {
                            if let oxygen = latest.oxygenSaturationPercent {
                                vitalValueTile("Oxígeno en sangre", value: String(format: "%.0f%%", oxygen), icon: "lungs")
                            }
                            if let wrist = latest.wristTemperatureCelsius {
                                vitalValueTile("T nocturna", value: String(format: "%.1f °C", wrist), icon: "thermometer.medium")
                            }
                        }
                        if let recovery = latest.heartRateRecoveryBpm {
                            vitalValueTile("Recuperación cardíaca 1 min", value: "\(Int(recovery.rounded())) lpm", icon: "heart")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Preparación para entrenar (sin duplicar sueño)

    private func readinessColor(_ score: Double) -> Color {
        score >= 8 ? OG.accent : (score >= 6 ? OG.yellow : OG.red)
    }

    private func readinessRecommendation(
        _ advice: RecoveryEngine.TrainingReadinessAdvice
    ) -> String {
        switch advice {
        case .usual: return "Entrena con normalidad"
        case .moderate: return "Reduce la intensidad"
        case .rest: return "Prioriza el descanso"
        }
    }

    private var currentCardiacReadings: String {
        guard let day = physiology.days.last(where: {
            Calendar.current.isDate($0.date, inSameDayAs: Date())
        }) else { return "Sin datos" }
        let hrv = day.hrvMilliseconds.map { "\(Int($0.rounded())) ms" }
        let resting = day.restingHeartRateBpm.map { "\(Int($0.rounded())) lpm" }
        let summary = [hrv, resting].compactMap { $0 }.joined(separator: " · ")
        return summary.isEmpty ? "Sin datos" : summary
    }

    private func readinessFactor(
        _ title: String, icon: String, value: String
    ) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(OG.label2)
                .frame(width: 22, alignment: .center)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(OG.label2)
                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(OG.label)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
    }

    private var trainingRecoveryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            OGCardSectionTitle(title: "Preparación para entrenar")
            OGCard {
                Group {
                if appliedRecoveryKey != trainingRecoveryRefreshKey && currentReadiness == nil {
                    HStack(spacing: 10) {
                        ProgressView().tint(OG.accent)
                        Text("Calculando recuperación…")
                            .foregroundStyle(OG.label2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: readinessChartHeight, alignment: .center)
                } else if let readiness = currentReadiness {
                    let tint = readinessColor(readiness.score)
                    VStack(alignment: .leading, spacing: usesExpandedLayout ? 9 : 16) {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Label(
                                    readinessRecommendation(readiness.advice),
                                    systemImage: readiness.score >= 8
                                        ? "figure.run"
                                        : (readiness.score >= 6 ? "figure.walk" : "bed.double")
                                )
                                .labelStyle(.titleAndIcon)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(tint)
                                .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 8)
                            ZStack {
                                Circle()
                                    .stroke(OG.surface3, lineWidth: 9)
                                Circle()
                                    .trim(from: 0, to: CGFloat(readiness.score / 10))
                                    .stroke(tint, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                VStack(spacing: 1) {
                                    Text("\(Int(readiness.score.rounded()))")
                                        .font(.system(size: 29, weight: .bold, design: .rounded))
                                        .foregroundStyle(OG.label)
                                    Text("de 10")
                                        .font(.system(size: 11))
                                        .foregroundStyle(OG.label2)
                                }
                            }
                            .frame(
                                width: usesExpandedLayout ? 76 : 95,
                                height: usesExpandedLayout ? 76 : 95
                            )
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Preparación \(Int(readiness.score.rounded())) de 10")
                        }

                        Divider().opacity(0.25)

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), alignment: .leading),
                                GridItem(.flexible(), alignment: .leading)
                            ],
                            alignment: .leading,
                            spacing: usesExpandedLayout ? 8 : 16
                        ) {
                            readinessFactor(
                                "Sueño", icon: "moon",
                                value: currentSleepHours.map {
                                    String(format: "%.1f h", $0)
                                } ?? "Sin datos"
                            )
                            readinessFactor(
                                "Carga reciente", icon: "dumbbell",
                                value: readiness.fatiguePenalty >= 2.3 ? "Alta"
                                    : (readiness.fatiguePenalty >= 1.1 ? "Moderada" : "Baja")
                            )
                            readinessFactor(
                                "VFC · pulso", icon: "heart", value: currentCardiacReadings
                            )
                            readinessFactor(
                                "Cardio en Salud", icon: "waveform.path.ecg",
                                value: readiness.cardioMinutes48h.map {
                                    "\(Int($0.rounded())) min"
                                } ?? "Sin datos"
                            )
                        }
                    }
                    .frame(minHeight: readinessChartHeight, alignment: .center)
                } else {
                    ProgressEmptyChart(
                        message: "Necesitamos datos de sueño y entrenamientos recientes",
                        height: readinessChartHeight
                    )
                }
                }
            }
        }
    }

    /// Una sola tendencia de disposición, no otra gráfica de sueño.
    /// El degradado sigue el eje 0–10: rojo al faltar recuperación,
    /// amarillo en la zona intermedia y verde en recuperación alta.
    private var trainingRecoveryTrendCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            OGCardSectionTitle(title: "Evolución de recuperación")
            OGCard(padding: 10, verticalPadding: OG.pad) {
                Chart {
                    ForEach(recoveryPoints) { point in
                    LineMark(
                        x: .value("Día", point.date),
                        y: .value("Recuperación", point.score)
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(
                        LinearGradient(
                            stops: [
                                .init(color: OG.red, location: 0),
                                .init(color: OG.red, location: 0.40),
                                .init(color: OG.yellow, location: 0.60),
                                .init(color: OG.yellow, location: 0.72),
                                .init(color: OG.accent, location: 0.84),
                                .init(color: OG.accent, location: 1)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .alignsMarkStylesWithPlotArea()

                }
                if let selectedRecoveryDate,
                   let selected = recoveryPoints.min(by: {
                       abs($0.date.timeIntervalSince(selectedRecoveryDate)) < abs($1.date.timeIntervalSince(selectedRecoveryDate))
                   }) {
                    RuleMark(x: .value("Día seleccionado", selected.date))
                        .foregroundStyle(OG.label2)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4]))
                        .annotation(position: .top) {
                            Text("\(Int(selected.score.rounded()))/10 · \(selected.date.formatted(.dateTime.day().month(.abbreviated)))")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(OG.label)
                                .padding(5)
                                .background(OG.surface, in: RoundedRectangle(cornerRadius: 6))
                        }
                }
                }
                .chartXSelection(value: $selectedRecoveryDate)
                .chartYScale(domain: 0.0...10.0)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0.0, 5.0, 10.0])
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    }
                }
                .chartPlotStyle { $0.clipped() }
                .frame(height: readinessChartHeight)
                .accessibilityLabel("Evolución de preparación para entrenar")
            }
        }
    }

    private func sleepNightCard(
        hours: Double?,
        hoursCaption: String,
        deep: Double,
        rem: Double,
        light: Double,
        nights: [RecoverySleepNight]
    ) -> some View {
        let yLo = max(3.5, (nights.map(\.hours).min() ?? 5) - 0.6)
        let yHi = min(11, (nights.map(\.hours).max() ?? 8) + 0.7)
        let xStart = nights.map(\.date).min() ?? Date()
        let xEnd = nights.map(\.date).max() ?? Date()
        return OGCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "moon.stars")
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

                    }
                    if let selectedSleepDate,
                       let selected = nights.min(by: {
                           abs($0.date.timeIntervalSince(selectedSleepDate)) < abs($1.date.timeIntervalSince(selectedSleepDate))
                       }) {
                        RuleMark(x: .value("Día seleccionado", selected.date))
                            .foregroundStyle(NightSky.glow)
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4]))
                            .annotation(position: .top) {
                                Text(String(format: "%.1f h", selected.hours))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(5)
                                    .background(NightSky.ink, in: RoundedRectangle(cornerRadius: 6))
                            }
                    }
                }
                .chartXSelection(value: $selectedSleepDate)
                .chartXScale(domain: xStart...xEnd)
                .chartYScale(domain: yLo...yHi)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartLegend(.hidden)
                .chartPlotStyle { $0.clipped() }
                .frame(height: sleepChartHeight)
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
                .frame(height: 128)
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
            Label("Días registrados de menstruación", systemImage: "circle")
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
                Image(systemName: "moon.stars").foregroundStyle(OG.accent)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text("Tu contexto de hoy").font(.subheadline.weight(.semibold)).foregroundStyle(OG.label)
                        Spacer(minLength: 0)
                        if let index = recovery.sleepIndex {
                            Text("Sueño \(Int((Double(index) / 10.0).rounded()))/10")
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
                                Image(systemName: "moon.stars")
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
                                                Text("· \(Int((Double(index) / 10.0).rounded()))/10")
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
