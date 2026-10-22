import CoreLocation
import Foundation
import ReperaDomain
import HealthKit
import Observation

/// Salud de Apple: lectura (Watch/Salud manda) + escritura del entreno.
@MainActor
@Observable
final class HealthKitStore {
    static let shared = HealthKitStore()

    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }
    /// Write access for workouts / active energy (sharingAuthorized).
    var isAuthorized = false
    /// Read access for workouts — distinct from write; empty results ≠ denied.
    var canReadWorkouts = false
    var canWriteWorkouts = false
    var latestWeightKg: Double?
    var latestWeightDate: Date?
    var activeEnergyTodayKcal: Double?
    /// Solo kcal verificadas de entrenos creados por Watch u otra app.
    /// No se usa el valor de la sesión Repera (puede contener estimaciones antiguas).
    private(set) var verifiedWorkoutEnergyKcal: [UUID: Double] = [:]
    var workoutMinutesToday: Double?
    /// Métricas en vivo del entreno actual (desde Salud / Watch).
    var liveActiveEnergyKcal: Double?
    var liveDurationSeconds: TimeInterval?
    var lastError: String?

    struct DayMetrics: Sendable {
        var activeEnergyKcal: Double?
        var workoutMinutes: Double?
    }

    /// Actividad de Apple Salud (Watch u otra app) para mostrar en Inicio.
    struct ExternalActivity: Identifiable, Sendable, Equatable {
        var id: UUID
        var title: String
        var start: Date
        var end: Date
        var durationMinutes: Double
        var activeEnergyKcal: Double?
        var distanceMeters: Double?
        var sourceName: String?
        var activityTypeRaw: UInt

        var activityType: HKWorkoutActivityType {
            HKWorkoutActivityType(rawValue: activityTypeRaw) ?? .other
        }

        var symbolName: String {
            HealthActivityIcons.symbolName(for: activityType)
        }

        /// Carrera, bici, caminar… actividades al aire libre con posible ruta GPS.
        var isOutdoorRouteActivity: Bool {
            HealthActivityIcons.isOutdoor(activityType)
        }
    }

    struct HeartRatePoint: Identifiable, Sendable, Equatable {
        var id: Date { date }
        var date: Date
        var bpm: Double
    }

    /// Mín / media / máx de FC por día (Salud), para la gráfica de Cardio en Progreso.
    struct DailyHeartRatePoint: Identifiable, Sendable, Equatable {
        var id: Date { date }
        var date: Date
        var minBpm: Double
        var avgBpm: Double
        var maxBpm: Double
    }

    /// Energía activa acumulada por día (anillo de Movimiento / Salud).
    struct DailyActiveEnergyPoint: Identifiable, Sendable, Equatable {
        var id: Date { date }
        var date: Date
        var kcal: Double
    }

    struct RoutePoint: Identifiable, Sendable, Equatable {
        var id: Int
        var latitude: Double
        var longitude: Double
        var date: Date
        /// m/s (≥ 0). Nil si no se pudo estimar.
        var speedMps: Double?
        /// Altitud original de CLLocation, cuando su precisión vertical es válida.
        var altitudeMeters: Double? = nil
    }

    /// Detalle ampliado (FC, ruta, etc.) al abrir un entreno de Salud.
    struct ExternalActivityDetail: Sendable, Equatable {
        var activity: ExternalActivity
        var averageHeartRateBpm: Double?
        var maxHeartRateBpm: Double?
        var minHeartRateBpm: Double?
        var heartRateSeries: [HeartRatePoint] = []
        var routePoints: [RoutePoint] = []
        var averageSpeedKmh: Double?
        var maxSpeedKmh: Double?
    }

    /// Métricas de Salud asociadas a un entreno propio de Repera.
    struct SessionHealthExtras: Sendable, Equatable {
        var averageHeartRateBpm: Double?
        var maxHeartRateBpm: Double?
        var minHeartRateBpm: Double?
        var heartRateSeries: [HeartRatePoint] = []
        var routePoints: [RoutePoint] = []
        var averageSpeedKmh: Double?
        var maxSpeedKmh: Double?
        var activeEnergyKcal: Double?
        var sourceName: String?
        var activityTypeRaw: UInt?
        var resolvedWorkoutUUID: UUID?

        var activityType: HKWorkoutActivityType {
            guard let raw = activityTypeRaw else { return .other }
            return HKWorkoutActivityType(rawValue: raw) ?? .other
        }

        var isOutdoorRouteActivity: Bool {
            HealthActivityIcons.isOutdoor(activityType)
        }

        var showRouteMap: Bool {
            routePoints.count >= 2
        }

        var hasVisualContent: Bool {
            !heartRateSeries.isEmpty
                || averageHeartRateBpm != nil
                || showRouteMap
                || (averageSpeedKmh ?? 0) > 0
                || sourceName != nil
                || (activeEnergyKcal ?? 0) > 0
        }

        /// FC, ruta o ritmo: señales que solo vienen de Salud, no del JSON de Repera.
        var hasAuthenticSaludMetrics: Bool {
            !heartRateSeries.isEmpty
                || averageHeartRateBpm != nil
                || showRouteMap
                || (averageSpeedKmh ?? 0) > 0
        }

        /// Origen externo (Watch / otra app). El workout escrito por Repera no cuenta.
        var hasExternalSaludSource: Bool {
            guard let name = sourceName?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else { return false }
            return !name.localizedCaseInsensitiveContains("repera")
        }

        /// Usa la kcal guardada en la sesión (resumen / Inicio) si es válida.
        func preferringEnergy(_ sessionKcal: Double?) -> SessionHealthExtras {
            guard let sessionKcal, sessionKcal > 0 else { return self }
            var copy = self
            copy.activeEnergyKcal = sessionKcal
            return copy
        }
    }

    /// Workout zones come from the actual saved HKWorkout, not estimated from
    /// age or a generic heart-rate maximum. Only durations observed by Health.
    struct WorkoutHeartZones: Sendable, Equatable {
        struct Zone: Identifiable, Sendable, Equatable {
            let index: Int
            let seconds: TimeInterval
            let minimumBpm: Double?
            let maximumBpm: Double?
            var id: Int { index }
        }
        let title: String
        let zones: [Zone]
        let source: String
        let coveredFraction: Double
        let intensityLoad: Int?
    }

    /// Muestra de peso corporal leída de Salud.
    struct BodyMassSample: Identifiable, Sendable, Equatable {
        var id: UUID
        var date: Date
        var kg: Double
    }

    /// Actividades externas recientes (caché para Inicio / Progreso).
    var recentExternalActivities: [ExternalActivity] = []
    /// FC diaria (mín/media/máx) cacheada para Progreso.
    var recentDailyHeartRate: [DailyHeartRatePoint] = []
    /// kcal activas diarias cacheadas para Progreso.
    var recentDailyActiveEnergy: [DailyActiveEnergyPoint] = []
    /// Monotonic bump whenever progressive Health arrays are committed or invalidated.
    private(set) var healthDataRevision: Int = 0

    private var liveBuilder: HKWorkoutBuilder?
    private var trackedSessionId: UUID?
    private var trackedStart: Date?

    private init() {
        // Auth antes que Home: si no, el primer `.task` ve isAuthorized=false y limpia la UI.
        refreshAuthorizationStatus()
        // Cold start: paint Home/Progreso from last snapshot before HealthKit answers.
        // Prefer decode already started in `LaunchWarmup` (overlaps first SwiftUI frame).
        if let snap = LaunchWarmup.healthSnapshotForInit() {
            applyDiskSnapshot(snap)
            ProgressLog.info(
                "HK disk hydrate activities=\(snap.activities.count) hr=\(snap.heartRate.count) kcal=\(snap.activeEnergy.count) age=\(Int(Date().timeIntervalSince(snap.fetchedAt)))s"
            )
        }
    }

    /// Solicita sueño con las métricas generales en un único panel de Apple Salud.
    /// `nil` respeta una negativa explícita previa del usuario a analizar el sueño.
    func requestAccess(includeSleep: Bool? = nil) async {
        guard isAvailable else {
            lastError = "HealthKit no disponible en este dispositivo"
            isAuthorized = false
            return
        }
        var read: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            // Opt-in read scopes; HealthKit may return no samples when declined.
            // Do not use authorizationStatus to infer READ grants.
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateRecoveryOneMinute)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.quantityType(forIdentifier: .appleSleepingWristTemperature)!,
            HKObjectType.workoutType(),
        ]
        read.insert(HKSeriesType.workoutRoute())
        let includeSleepInRequest = includeSleep ?? HealthRecoveryStore.shared.shouldRequestSleepWithHealth
        if includeSleepInRequest, let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            read.insert(sleepType)
        }
        let share: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.workoutType(),
        ]
        do {
            try await store.requestAuthorization(toShare: share, read: read)
            if includeSleepInRequest {
                // HealthKit no permite consultar si se ha concedido la lectura.
                // Se registra la elección de solicitarla, nunca una concesión supuesta.
                await HealthRecoveryStore.shared.acceptSleepFromHealthAuthorization()
            }
            refreshAuthorizationStatus()
            // HealthKit no expone el permiso de lectura: que el usuario deniegue
            // ESCRITURA no impide consultar datos reales si concedió lectura.
            lastError = nil
            await refreshToday()
        } catch {
            lastError = error.localizedDescription
            isAuthorized = false
        }
    }

    /// `requestAuthorization` no falla si el usuario niega: hay que mirar el estado de escritura.
    /// Read status is `sharingDenied` only when explicitly denied; `.notDetermined` ≠ no data.
    func refreshAuthorizationStatus() {
        guard isAvailable else {
            isAuthorized = false
            canReadWorkouts = false
            canWriteWorkouts = false
            return
        }
        let workoutStatus = store.authorizationStatus(for: .workoutType())
        let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let energyStatus = store.authorizationStatus(for: energyType)
        canWriteWorkouts = workoutStatus == .sharingAuthorized
        // HealthKit does not expose a dedicated "read authorized" flag for workouts;
        // treat sharingDenied as no write, and allow read attempts unless unavailable.
        canReadWorkouts = workoutStatus != .sharingDenied
        // Conectado = podemos escribir entrenos o al menos energía activa.
        isAuthorized = canWriteWorkouts || energyStatus == .sharingAuthorized
    }

    func refreshToday() async {
        guard isAvailable else { return }
        async let weight: Void = fetchLatestWeight()
        async let energy: Void = fetchActiveEnergyToday()
        async let minutes: Void = fetchWorkoutMinutesToday()
        _ = await (weight, energy, minutes)
        persistProgressiveCacheToDisk()
    }

    /// kcal + minutos derivados de la caché progresiva (instantáneo; nil si el día no está cubierto).
    func dayMetricsFromCache(for day: Date) -> DayMetrics? {
        guard hasProgressiveCache else { return nil }
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        // Outside coverage window → force live query.
        if let fetched = healthCacheFetchedAt {
            let coverageStart = cal.date(byAdding: .day, value: -healthCacheCoverageDays, to: fetched)
                ?? start
            if start < cal.startOfDay(for: coverageStart) { return nil }
        }
        let kcal = recentDailyActiveEnergy.first { cal.isDate($0.date, inSameDayAs: start) }?.kcal
        let minutes = recentExternalActivities
            .filter { cal.isDate($0.start, inSameDayAs: start) }
            .reduce(0.0) { $0 + $1.durationMinutes }
        if cal.isDateInToday(day) {
            // Prefer live “today” fields when present.
            let todayK = activeEnergyTodayKcal ?? kcal
            let todayM = workoutMinutesToday ?? (minutes > 0 ? minutes : nil)
            return DayMetrics(
                activeEnergyKcal: (todayK ?? 0) > 0 ? todayK : nil,
                workoutMinutes: (todayM ?? 0) > 0 ? todayM : nil
            )
        }
        return DayMetrics(
            activeEnergyKcal: (kcal ?? 0) > 0 ? kcal : nil,
            workoutMinutes: minutes > 0 ? minutes : nil
        )
    }

    /// kcal + minutos de entrenos de Salud para un día concreto (no solo “hoy”).
    func dayMetrics(for day: Date) async -> DayMetrics {
        guard isAvailable else { return DayMetrics() }
        let start = Calendar.current.startOfDay(for: day)
        guard let end = Calendar.current.date(byAdding: .day, value: 1, to: start) else {
            return DayMetrics()
        }
        async let kcal = activeEnergy(from: start, to: end)
        async let minutes = workoutMinutes(from: start, to: end)
        let (k, m) = await (kcal, minutes)
        return DayMetrics(
            activeEnergyKcal: k > 0 ? k : nil,
            workoutMinutes: m > 0 ? m : nil
        )
    }

    /// HKObserverQuery + background delivery (entitlement already on). Marks dirty; refresh on foreground.
    func startObservingHealthChanges() {
        guard isAvailable, !healthObserversStarted else { return }
        healthObserversStarted = true
        let types: [HKSampleType] = [
            .workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        ]
        for type in types {
            let typeId = type.identifier
            let query = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, completionHandler, _ in
                // Call completion on the query queue; hop to MainActor only for state.
                Task { @MainActor in
                    guard let self else { return }
                    self.healthNeedsRefresh = true
                    // Keep progressive arrays for instant UI; only expire freshness so next refresh runs.
                    self.healthCacheFetchedAt = nil
                    self.metricsCacheFetchedAt = nil
                    ProgressLog.info("HK observer dirty \(typeId)")
                }
                completionHandler()
            }
            store.execute(query)
            store.enableBackgroundDelivery(for: type, frequency: .hourly) { _, error in
                if let error {
                    ProgressLog.info("HK backgroundDelivery \(typeId) err=\(error.localizedDescription)")
                }
            }
        }
        ProgressLog.info("HK observers started")
    }

    /// Entrenamientos de Salud en un día, excluyendo UUIDs ya vinculados o solapes con sesiones Repera.
    func externalActivities(
        on day: Date,
        excludingUUIDs: Set<UUID> = [],
        overlappingSessions: [WorkoutSession] = []
    ) async -> [ExternalActivity] {
        let start = Calendar.current.startOfDay(for: day)
        guard let end = Calendar.current.date(byAdding: .day, value: 1, to: start) else { return [] }
        return await externalActivities(
            from: start,
            to: end,
            excludingUUIDs: excludingUUIDs,
            overlappingSessions: overlappingSessions
        )
    }

    /// Entrenamientos de Salud en un rango (para semana, rachas y Progreso).
    func externalActivities(
        from start: Date,
        to end: Date,
        excludingUUIDs: Set<UUID> = [],
        overlappingSessions: [WorkoutSession] = []
    ) async -> [ExternalActivity] {
        guard isAvailable else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let workouts: [HKWorkout] = await withCheckedContinuation { cont in
            let q = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                cont.resume(returning: (samples as? [HKWorkout]) ?? [])
            }
            store.execute(q)
        }
        let index = ReperaSessionMatchIndex(sessions: overlappingSessions)
        // Map off the hot path of MainActor Observation — compactMap is pure.
        return workouts.compactMap { w in
            mapExternalActivity(
                w,
                excludingUUIDs: excludingUUIDs,
                matchIndex: index
            )
        }
    }

    /// Días ya cargados en caché (evita re-fetch al bajar de 180→90→180).
    @ObservationIgnored private var healthCacheDays: Int = 0
    /// Caché antigua agregaba por semana/mes y rompía Hoy/Semana/Mes; solo reutilizamos si es diaria.
    @ObservationIgnored private var healthCacheIsDaily = false
    /// Fingerprint of exclusion / overlap filters used for the last activities fetch.
    @ObservationIgnored private var healthCacheFilterKey: String = ""
    /// Wall-clock of last successful Health cache commit (nil = never / invalidated).
    private(set) var healthCacheFetchedAt: Date?
    /// Requested day window of the last successful fetch.
    private(set) var healthCacheCoverageDays: Int = 0
    /// Serializes overlapping Progress/Home refreshes; only the newest commit wins.
    @ObservationIgnored private var healthRefreshGeneration: UInt64 = 0
    /// Separate TTL for HR/kcal vs activities (session edits don't force FC re-query).
    @ObservationIgnored private var metricsCacheDays: Int = 0
    @ObservationIgnored private var metricsCacheFetchedAt: Date?
    /// Anchored workout query cursor (incremental merges).
    @ObservationIgnored private var workoutQueryAnchor: HKQueryAnchor?
    @ObservationIgnored private var healthObserversStarted = false
    /// Set by HKObserverQuery; cleared after a successful progressive refresh.
    private(set) var healthNeedsRefresh = false

    /// True when cached progressive metrics are fresh enough for the requested window + filter key.
    func isHealthCacheFresh(
        forDays days: Int,
        filterKey: String = "",
        maxAge: TimeInterval = 120
    ) -> Bool {
        guard healthCacheIsDaily,
              healthCacheDays >= days,
              healthCacheFilterKey == filterKey,
              let fetched = healthCacheFetchedAt
        else { return false }
        return Date().timeIntervalSince(fetched) <= maxAge
    }

    /// True when memory has progressive arrays (disk hydrate or prior fetch) usable for instant UI.
    var hasProgressiveCache: Bool {
        healthCacheIsDaily && (!recentExternalActivities.isEmpty
            || !recentDailyHeartRate.isEmpty
            || !recentDailyActiveEnergy.isEmpty)
    }

    func invalidateHealthMetricCache(reason: String = "manual") {
        healthCacheDays = 0
        healthCacheIsDaily = false
        healthCacheFetchedAt = nil
        healthCacheCoverageDays = 0
        healthCacheFilterKey = ""
        metricsCacheDays = 0
        metricsCacheFetchedAt = nil
        workoutQueryAnchor = nil
        healthRefreshGeneration &+= 1
        healthDataRevision &+= 1
        healthNeedsRefresh = true
        ProgressLog.info("health cache invalidate \(reason)")
    }

    /// Repera workouts changed: keep progressive arrays for instant UI, force a coalesced re-fetch
    /// so exclusion / overlap filter matches the new session list (no duplicate Health rows).
    func invalidateExternalActivityFilter(reason: String = "sessions") {
        healthCacheFilterKey = ""
        healthNeedsRefresh = true
        // Do **not** clear `healthCacheIsDaily` / arrays — Home buckets stay paintable.
        ProgressLog.info("health activity filter invalidate \(reason)")
    }

    /// Stable short fingerprint (not `Hasher` — survives relaunch for disk cache).
    nonisolated static func healthFilterKey(
        excludingUUIDs: Set<UUID>,
        overlappingSessions: [WorkoutSession]
    ) -> String {
        var payload = excludingUUIDs.map(\.uuidString).sorted().joined(separator: ",")
        payload += "#"
        let sessions = overlappingSessions
            .map { s -> String in
                let start = s.startedAt?.timeIntervalSince1970 ?? 0
                let end = s.finishedAt?.timeIntervalSince1970 ?? 0
                let hk = s.healthKitWorkoutUUID?.uuidString ?? "-"
                return "\(s.id.uuidString):\(start):\(end):\(hk)"
            }
            .sorted()
            .joined(separator: "|")
        payload += sessions
        return "f\(Self.stableDigest64(payload))"
    }

    nonisolated private static func stableDigest64(_ string: String) -> String {
        var hash: UInt64 = 5381
        for byte in string.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }
        return String(hash, radix: 16)
    }

    /// Coalesce Home/Progreso overlapping refreshes into one fetch with max(days).
    @ObservationIgnored private var coalesceRefreshTask: Task<Void, Never>?
    @ObservationIgnored private var coalesceDays = 0
    @ObservationIgnored private var coalesceExcluding: Set<UUID> = []
    @ObservationIgnored private var coalesceSessions: [WorkoutSession] = []

    /// Refresca actividades + FC/kcal **por día**. Si ya hay caché diaria ≥ `days`, no vuelve a pedir Salud.
    /// La UI promedia a semana/mes solo al pintar (90/180/360).
    /// Publica los tres arrays **en un solo tick** de Observation para no re-renderizar Progreso 3 veces.
    func refreshRecentExternalActivities(
        excludingUUIDs: Set<UUID> = [],
        overlappingSessions: [WorkoutSession] = [],
        days: Int = 180
    ) async {
        let filterKey = Self.healthFilterKey(
            excludingUUIDs: excludingUUIDs,
            overlappingSessions: overlappingSessions
        )
        if !healthNeedsRefresh,
           isHealthCacheFresh(forDays: days, filterKey: filterKey),
           !recentDailyHeartRate.isEmpty || !recentDailyActiveEnergy.isEmpty {
            ProgressLog.healthCacheHit(
                days: days,
                hr: recentDailyHeartRate.count,
                kcal: recentDailyActiveEnergy.count
            )
            return
        }

        coalesceDays = max(coalesceDays, days)
        coalesceExcluding = excludingUUIDs
        coalesceSessions = overlappingSessions

        if let existing = coalesceRefreshTask {
            await existing.value
            let key = Self.healthFilterKey(
                excludingUUIDs: excludingUUIDs,
                overlappingSessions: overlappingSessions
            )
            if !healthNeedsRefresh,
               isHealthCacheFresh(forDays: days, filterKey: key),
               !recentDailyHeartRate.isEmpty || !recentDailyActiveEnergy.isEmpty {
                return
            }
        }

        let task = Task { @MainActor in
            await self.performCoalescedHealthRefresh()
        }
        coalesceRefreshTask = task
        await task.value
        if coalesceRefreshTask == task {
            coalesceRefreshTask = nil
        }
    }

    private func performCoalescedHealthRefresh() async {
        while true {
            let days = max(coalesceDays, 1)
            let excludingUUIDs = coalesceExcluding
            let overlappingSessions = coalesceSessions
            coalesceDays = 0
            let filterKey = Self.healthFilterKey(
                excludingUUIDs: excludingUUIDs,
                overlappingSessions: overlappingSessions
            )
            if !healthNeedsRefresh,
               isHealthCacheFresh(forDays: days, filterKey: filterKey),
               !recentDailyHeartRate.isEmpty || !recentDailyActiveEnergy.isEmpty {
                if coalesceDays > days { continue }
                return
            }

            healthRefreshGeneration &+= 1
            let gen = healthRefreshGeneration
            let t0 = CFAbsoluteTimeGetCurrent()
            ProgressLog.healthFetchStart(days: days)

            let end = Date()
            let start = Calendar.current.date(byAdding: .day, value: -days, to: end) ?? end
            let dayBucket = DateComponents(day: 1)

            var t = CFAbsoluteTimeGetCurrent()
            let activities = await loadExternalActivitiesIncremental(
                from: start,
                to: end,
                excludingUUIDs: excludingUUIDs,
                overlappingSessions: overlappingSessions,
                filterKey: filterKey
            )
            ProgressLog.healthFetchStep("activities", count: activities.count, elapsedMs: (CFAbsoluteTimeGetCurrent() - t) * 1000)

            let metricsFresh = metricsCacheDays >= days
                && metricsCacheFetchedAt.map { Date().timeIntervalSince($0) <= 120 } == true
                && (!recentDailyHeartRate.isEmpty || !recentDailyActiveEnergy.isEmpty)

            let hrPoints: [DailyHeartRatePoint]
            let energyPoints: [DailyActiveEnergyPoint]
            if metricsFresh {
                hrPoints = recentDailyHeartRate
                energyPoints = recentDailyActiveEnergy
                ProgressLog.info("health metrics cache hit days=\(days)")
            } else {
                t = CFAbsoluteTimeGetCurrent()
                async let hr = dailyHeartRateStats(from: start, to: end, interval: dayBucket)
                async let energy = dailyActiveEnergyStats(from: start, to: end, interval: dayBucket)
                let pair = await (hr, energy)
                hrPoints = pair.0
                energyPoints = pair.1
                ProgressLog.healthFetchStep(
                    "hr+kcal",
                    count: hrPoints.count + energyPoints.count,
                    elapsedMs: (CFAbsoluteTimeGetCurrent() - t) * 1000
                )
            }

            // Drop stale overlapping refreshes (Home 180 vs Progress 370).
            guard gen == healthRefreshGeneration else {
                ProgressLog.info("health refresh stale drop gen=\(gen) days=\(days)")
                if coalesceDays > 0 { continue }
                return
            }
            // Never publish a smaller window over a larger one already committed.
            if healthCacheIsDaily, healthCacheDays > days, healthCacheFilterKey == filterKey {
                ProgressLog.info("health refresh skip smaller window \(days)<\(healthCacheDays)")
                if coalesceDays > days { continue }
                return
            }

            recentExternalActivities = activities
            recentDailyHeartRate = hrPoints
            recentDailyActiveEnergy = energyPoints
            // Coverage matches what we actually published (not max of stale races).
            healthCacheDays = days
            healthCacheIsDaily = true
            healthCacheFetchedAt = Date()
            healthCacheCoverageDays = days
            healthCacheFilterKey = filterKey
            if !metricsFresh {
                metricsCacheDays = days
                metricsCacheFetchedAt = Date()
            }
            healthNeedsRefresh = false
            healthDataRevision &+= 1
            persistProgressiveCacheToDisk()

            ProgressLog.healthFetchDone(
                totalMs: (CFAbsoluteTimeGetCurrent() - t0) * 1000,
                activities: activities.count,
                hr: hrPoints.count,
                kcal: energyPoints.count
            )
            if coalesceDays > days { continue }
            return
        }
    }

    /// Prefer anchored merge when we already have a window; fall back to full sample query.
    private func loadExternalActivitiesIncremental(
        from start: Date,
        to end: Date,
        excludingUUIDs: Set<UUID>,
        overlappingSessions: [WorkoutSession],
        filterKey: String
    ) async -> [ExternalActivity] {
        let index = ReperaSessionMatchIndex(sessions: overlappingSessions)
        // Same exclusion fingerprint → safe to merge deltas. Filter-key changes need a full pull
        // (excluded Repera-overlapping workouts are not kept in memory).
        let canMerge = workoutQueryAnchor != nil
            && healthCacheIsDaily
            && healthCacheFilterKey == filterKey
            && !recentExternalActivities.isEmpty

        if canMerge, let anchor = workoutQueryAnchor {
            let delta = await anchoredWorkouts(since: anchor)
            workoutQueryAnchor = delta.anchor ?? workoutQueryAnchor
            if delta.added.isEmpty, delta.deleted.isEmpty {
                return recentExternalActivities
            }
            var byId = Dictionary(
                uniqueKeysWithValues: recentExternalActivities.map { ($0.id, $0) }
            )
            for id in delta.deleted {
                byId.removeValue(forKey: id)
            }
            for w in delta.added {
                guard w.endDate >= start else { continue }
                if let mapped = mapExternalActivity(
                    w,
                    excludingUUIDs: excludingUUIDs,
                    matchIndex: index
                ) {
                    byId[mapped.id] = mapped
                }
            }
            return byId.values
                .filter { $0.start >= start && $0.start <= end }
                .sorted { $0.start > $1.start }
        }

        // Cold / large window: full query + seed anchor for next time.
        let activities = await externalActivities(
            from: start,
            to: end,
            excludingUUIDs: excludingUUIDs,
            overlappingSessions: overlappingSessions
        )
        let seed = await anchoredWorkouts(since: nil)
        workoutQueryAnchor = seed.anchor
        return activities
    }

    private struct AnchoredWorkoutDelta: Sendable {
        var added: [HKWorkout]
        var deleted: [UUID]
        var anchor: HKQueryAnchor?
    }

    private func anchoredWorkouts(since anchor: HKQueryAnchor?) async -> AnchoredWorkoutDelta {
        guard isAvailable else {
            return AnchoredWorkoutDelta(added: [], deleted: [], anchor: anchor)
        }
        return await withCheckedContinuation { cont in
            let q = HKAnchoredObjectQuery(
                type: .workoutType(),
                predicate: nil,
                anchor: anchor,
                limit: HKObjectQueryNoLimit
            ) { _, added, deleted, newAnchor, _ in
                cont.resume(
                    returning: AnchoredWorkoutDelta(
                        added: (added as? [HKWorkout]) ?? [],
                        deleted: (deleted ?? []).map(\.uuid),
                        anchor: newAnchor
                    )
                )
            }
            store.execute(q)
        }
    }

    private func applyDiskSnapshot(_ snap: HealthDiskCache.Snapshot) {
        recentExternalActivities = snap.activities.map {
            ExternalActivity(
                id: $0.id,
                title: $0.title,
                start: $0.start,
                end: $0.end,
                durationMinutes: $0.durationMinutes,
                activeEnergyKcal: $0.activeEnergyKcal,
                distanceMeters: $0.distanceMeters,
                sourceName: $0.sourceName,
                activityTypeRaw: $0.activityTypeRaw
            )
        }
        recentDailyHeartRate = snap.heartRate.map {
            DailyHeartRatePoint(date: $0.date, minBpm: $0.minBpm, avgBpm: $0.avgBpm, maxBpm: $0.maxBpm)
        }
        recentDailyActiveEnergy = snap.activeEnergy.map {
            DailyActiveEnergyPoint(date: $0.date, kcal: $0.kcal)
        }
        healthCacheDays = snap.coverageDays
        healthCacheCoverageDays = snap.coverageDays
        healthCacheIsDaily = snap.isDaily
        healthCacheFetchedAt = snap.fetchedAt
        healthCacheFilterKey = snap.filterKey
        metricsCacheDays = snap.metricsCoverageDays ?? snap.coverageDays
        metricsCacheFetchedAt = snap.metricsFetchedAt ?? snap.fetchedAt
        if let kcal = snap.todayActiveEnergyKcal { activeEnergyTodayKcal = kcal }
        if let minutes = snap.todayWorkoutMinutes { workoutMinutesToday = minutes }
        if let data = snap.workoutAnchor {
            workoutQueryAnchor = try? NSKeyedUnarchiver.unarchivedObject(
                ofClass: HKQueryAnchor.self,
                from: data
            )
        }
        // Stale disk is fine for paint; force a background refresh soon.
        if Date().timeIntervalSince(snap.fetchedAt) > 120 {
            healthNeedsRefresh = true
        }
        healthDataRevision &+= 1
    }

    private func persistProgressiveCacheToDisk() {
        guard healthCacheIsDaily else { return }
        let anchorData: Data? = {
            guard let workoutQueryAnchor else { return nil }
            return try? NSKeyedArchiver.archivedData(
                withRootObject: workoutQueryAnchor,
                requiringSecureCoding: true
            )
        }()
        let snap = HealthDiskCache.Snapshot(
            version: HealthDiskCache.schemaVersion,
            fetchedAt: healthCacheFetchedAt ?? Date(),
            coverageDays: healthCacheCoverageDays,
            filterKey: healthCacheFilterKey,
            isDaily: healthCacheIsDaily,
            activities: recentExternalActivities.map {
                HealthDiskCache.Activity(
                    id: $0.id,
                    title: $0.title,
                    start: $0.start,
                    end: $0.end,
                    durationMinutes: $0.durationMinutes,
                    activeEnergyKcal: $0.activeEnergyKcal,
                    distanceMeters: $0.distanceMeters,
                    sourceName: $0.sourceName,
                    activityTypeRaw: $0.activityTypeRaw
                )
            },
            heartRate: recentDailyHeartRate.map {
                HealthDiskCache.HeartRate(
                    date: $0.date,
                    minBpm: $0.minBpm,
                    avgBpm: $0.avgBpm,
                    maxBpm: $0.maxBpm
                )
            },
            activeEnergy: recentDailyActiveEnergy.map {
                HealthDiskCache.ActiveEnergy(date: $0.date, kcal: $0.kcal)
            },
            workoutAnchor: anchorData,
            todayActiveEnergyKcal: activeEnergyTodayKcal,
            todayWorkoutMinutes: workoutMinutesToday,
            todayFetchedAt: Date(),
            metricsFetchedAt: metricsCacheFetchedAt,
            metricsCoverageDays: metricsCacheDays
        )
        // Disk I/O off the main actor observation tick.
        Task.detached(priority: .utility) {
            HealthDiskCache.save(snap)
        }
    }

    /// FC mín / media / máx (intervalo configurable: día / semana / mes).
    func dailyHeartRateStats(
        from start: Date,
        to end: Date,
        interval: DateComponents = DateComponents(day: 1)
    ) async -> [DailyHeartRatePoint] {
        guard isAvailable,
              let type = HKQuantityType.quantityType(forIdentifier: .heartRate)
        else { return [] }
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: start)
        let unit = HKUnit.count().unitDivided(by: .minute())
        let predicate = HKQuery.predicateForSamples(withStart: dayStart, end: end)
        return await withCheckedContinuation { cont in
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: [.discreteMin, .discreteAverage, .discreteMax],
                anchorDate: dayStart,
                intervalComponents: interval
            )
            query.initialResultsHandler = { _, collection, _ in
                var points: [DailyHeartRatePoint] = []
                collection?.enumerateStatistics(from: dayStart, to: end) { stats, _ in
                    guard
                        let minQ = stats.minimumQuantity()?.doubleValue(for: unit),
                        let avgQ = stats.averageQuantity()?.doubleValue(for: unit),
                        let maxQ = stats.maximumQuantity()?.doubleValue(for: unit),
                        minQ > 0, avgQ > 0, maxQ > 0
                    else { return }
                    points.append(
                        DailyHeartRatePoint(
                            date: cal.startOfDay(for: stats.startDate),
                            minBpm: minQ,
                            avgBpm: avgQ,
                            maxBpm: maxQ
                        )
                    )
                }
                cont.resume(returning: points.sorted { $0.date < $1.date })
            }
            store.execute(query)
        }
    }

    /// Filtrar tanto el bundle actual como posibles fuentes Repera antiguas.
    nonisolated private static func isReperaSource(_ source: HKSource) -> Bool {
        source.bundleIdentifier == Bundle.main.bundleIdentifier
            || source.name.localizedCaseInsensitiveContains("repera")
    }

    /// Descartamos kcal de muestras escritas por Repera: antiguas versiones
    /// guardaban estimaciones que no representan una medición de Apple Salud.
    nonisolated private static func measuredEnergyKcal(_ statistics: HKStatistics?) -> Double {
        guard let statistics else { return 0 }
        let kcal = (statistics.sources ?? []).reduce(0.0) { sum, source in
            guard !isReperaSource(source) else { return sum }
            return sum + (statistics.sumQuantity(for: source)?.doubleValue(for: .kilocalorie()) ?? 0)
        }
        return max(0, kcal)
    }

    /// kcal activas (intervalo configurable).
    func dailyActiveEnergyStats(
        from start: Date,
        to end: Date,
        interval: DateComponents = DateComponents(day: 1)
    ) async -> [DailyActiveEnergyPoint] {
        guard isAvailable,
              let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
        else { return [] }
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: start)
        let predicate = HKQuery.predicateForSamples(withStart: dayStart, end: end)
        return await withCheckedContinuation { cont in
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: [.cumulativeSum, .separateBySource],
                anchorDate: dayStart,
                intervalComponents: interval
            )
            query.initialResultsHandler = { _, collection, _ in
                var points: [DailyActiveEnergyPoint] = []
                collection?.enumerateStatistics(from: dayStart, to: end) { stats, _ in
                    let kcal = Self.measuredEnergyKcal(stats)
                    guard kcal > 0 else { return }
                    points.append(
                        DailyActiveEnergyPoint(
                            date: cal.startOfDay(for: stats.startDate),
                            kcal: kcal
                        )
                    )
                }
                cont.resume(returning: points.sorted { $0.date < $1.date })
            }
            store.execute(query)
        }
    }

    /// Todos los registros de peso en Salud (más reciente primero), no solo el último.
    func fetchAllBodyMassSamples() async -> [BodyMassSample] {
        guard isAvailable,
              let type = HKQuantityType.quantityType(forIdentifier: .bodyMass)
        else { return [] }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                let mapped = (samples as? [HKQuantitySample] ?? []).map { sample in
                    BodyMassSample(
                        id: sample.uuid,
                        date: sample.endDate,
                        kg: sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                    )
                }
                cont.resume(returning: mapped)
            }
            store.execute(q)
        }
    }

    private func mapExternalActivity(
        _ w: HKWorkout,
        excludingUUIDs: Set<UUID>,
        matchIndex: ReperaSessionMatchIndex
    ) -> ExternalActivity? {
        // Un workout propio de Repera no es una actividad externa de Salud.
        // Además, las versiones antiguas podían escribirle kcal calculadas.
        guard !Self.isReperaSource(w.sourceRevision.source) else {
            return nil
        }
        guard !excludingUUIDs.contains(w.uuid) else { return nil }
        if matchIndex.matches(
            healthStart: w.startDate,
            healthEnd: w.endDate,
            healthUUID: w.uuid
        ) {
            return nil
        }
        let kcal: Double? = {
            guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
                  let burned = w.statistics(for: energyType)?.sumQuantity()?.doubleValue(for: .kilocalorie()),
                  burned > 0
            else { return nil }
            return burned
        }()
        let distance = w.totalDistance?.doubleValue(for: .meter())
        return ExternalActivity(
            id: w.uuid,
            title: Self.displayName(for: w.workoutActivityType),
            start: w.startDate,
            end: w.endDate,
            durationMinutes: w.duration / 60.0,
            activeEnergyKcal: kcal,
            distanceMeters: (distance ?? 0) > 0 ? distance : nil,
            sourceName: w.sourceRevision.source.name,
            activityTypeRaw: w.workoutActivityType.rawValue
        )
    }

    /// Carga métricas extra (FC serie + ruta GPS) para la ficha de un entreno de Salud.
    func activityDetail(for activityId: UUID) async -> ExternalActivityDetail? {
        await ensureWorkoutRouteAccess()
        var activity = recentExternalActivities.first(where: { $0.id == activityId })
        if activity == nil {
            let start = Calendar.current.date(byAdding: .day, value: -180, to: Date()) ?? Date()
            activity = await externalActivities(from: start, to: Date())
                .first(where: { $0.id == activityId })
        }
        guard let activity else { return nil }

        let extras = await loadHealthExtras(
            workoutUUID: activity.id,
            start: activity.start,
            end: activity.end
        )

        return ExternalActivityDetail(
            activity: activity,
            averageHeartRateBpm: extras.averageHeartRateBpm,
            maxHeartRateBpm: extras.maxHeartRateBpm,
            minHeartRateBpm: extras.minHeartRateBpm,
            heartRateSeries: extras.heartRateSeries,
            routePoints: extras.routePoints,
            averageSpeedKmh: extras.averageSpeedKmh,
            maxSpeedKmh: extras.maxSpeedKmh
        )
    }

    /// FC + ruta de Salud para un entreno propio (UUID vinculado o solape temporal).
    func sessionHealthExtras(for session: WorkoutSession) async -> SessionHealthExtras? {
        guard isAvailable else { return nil }
        await ensureWorkoutRouteAccess()
        // No usar isAuthorized (estado de escritura) para bloquear lectura.
        guard let start = session.startedAt else { return nil }
        let end: Date = {
            if let finished = session.finishedAt { return finished }
            if let apple = session.appleDurationSeconds, apple > 0 {
                return start.addingTimeInterval(apple)
            }
            return start.addingTimeInterval(max(60, session.durationMinutes * 60))
        }()

        var workoutUUID = session.healthKitWorkoutUUID
        var workout: HKWorkout? = nil
        if let uuid = workoutUUID {
            workout = await fetchWorkout(uuid: uuid)
        }
        if workout == nil {
            workout = await overlappingWorkout(from: start, to: end)
            workoutUUID = workout?.uuid
        }

        let rangeStart = workout?.startDate ?? start
        let rangeEnd = workout?.endDate ?? end
        var extras = await loadHealthExtras(
            workoutUUID: workoutUUID,
            start: rangeStart,
            end: rangeEnd
        )

        // Una estimación antigua de Repera nunca prevalece sobre Apple Salud.
        // Incluso si se escribió como muestra en nuestro HKWorkout, se oculta.
        if let workout,
           Self.isReperaSource(workout.sourceRevision.source) {
            extras.activeEnergyKcal = nil
        } else if let workoutUUID {
            extras.activeEnergyKcal = await externalWorkoutEnergyKcal(uuid: workoutUUID)
        } else {
            extras.activeEnergyKcal = nil
        }
        if extras.sourceName == nil, let workout {
            extras.sourceName = workout.sourceRevision.source.name
        }
        if extras.activityTypeRaw == nil, let workout {
            extras.activityTypeRaw = workout.workoutActivityType.rawValue
        }
        extras.resolvedWorkoutUUID = workoutUUID

        return extras.hasVisualContent || extras.activeEnergyKcal != nil ? extras : nil
    }

    /// Use workout-specific Apple zone boundaries and durations, including
    /// user-defined zones. Nil when there is no actual linked Apple workout.
    func heartZones(for session: WorkoutSession) async -> WorkoutHeartZones? {
        guard isAvailable,
              let heartType = HKObjectType.quantityType(forIdentifier: .heartRate),
              let start = session.startedAt, let finished = session.finishedAt,
              finished > start
        else { return nil }
        let linked: HKWorkout?
        if let id = session.healthKitWorkoutUUID {
            linked = await fetchWorkout(uuid: id)
        } else {
            linked = nil
        }
        // A Repera-authored workout may have no recorded HR zone samples.
        // Look for a separate Apple Watch workout only if it has real zone
        // evidence and an unambiguous overlap with this completed session.
        let workout: HKWorkout?
        if let linked, linked.zoneGroup(for: heartType) != nil {
            workout = linked
        } else {
            workout = await overlappingWorkoutWithZones(from: start, to: finished)
        }
        guard let workout, let group = workout.zoneGroup(for: heartType) else { return nil }
        let bpmUnit = HKUnit.count().unitDivided(by: .minute())
        let zones = group.zoneDurations.map { item in
            WorkoutHeartZones.Zone(
                index: item.zone.index + 1,
                seconds: max(0, item.duration),
                minimumBpm: item.zone.minimum?.doubleValue(for: bpmUnit),
                maximumBpm: item.zone.maximum?.doubleValue(for: bpmUnit)
            )
        }
        let total = zones.reduce(0.0) { $0 + $1.seconds }
        guard total >= 60 else { return nil }
        let full = max(60, workout.endDate.timeIntervalSince(workout.startDate))
        let coveredFraction = min(1, total / full)
        let source: String
        switch group.configuration.source {
        case .system: source = "Zonas personales de Apple"
        case .user: source = "Zonas configuradas en Apple Salud"
        case .app: source = "Zonas definidas para este entreno"
        @unknown default: source = "Zonas registradas en Apple Salud"
        }
        // 0...10 indicates cardiac intensity/load, NEVER performance quality.
        // Suppress it when HealthKit tracked less than 60% of the workout.
        let intensity: Int? = coveredFraction >= 0.60 && zones.count >= 3
            ? min(10, max(0, Int((zones.reduce(0) { sum, zone in
                sum + zone.seconds * Double(zone.index) / Double(max(1, zones.count))
            } / total * 10).rounded())))
            : nil
        return WorkoutHeartZones(
            title: session.title, zones: zones, source: source,
            coveredFraction: coveredFraction, intensityLoad: intensity
        )
    }

    private func overlappingWorkoutWithZones(
        from start: Date, to end: Date
    ) async -> HKWorkout? {
        let duration = max(60, end.timeIntervalSince(start))
        let predicate = HKQuery.predicateForSamples(
            withStart: start.addingTimeInterval(-15 * 60),
            end: end.addingTimeInterval(15 * 60)
        )
        return await withCheckedContinuation { (cont: CheckedContinuation<HKWorkout?, Never>) in
            let query = HKSampleQuery(
                sampleType: .workoutType(), predicate: predicate,
                limit: 50, sortDescriptors: nil
            ) { _, samples, _ in
                guard let type = HKObjectType.quantityType(forIdentifier: .heartRate) else {
                    cont.resume(returning: nil)
                    return
                }
                let matches = (samples as? [HKWorkout] ?? [])
                    .filter { $0.zoneGroup(for: type) != nil }
                    .map { workout -> (HKWorkout, TimeInterval) in
                        let overlap = max(0, min(workout.endDate, end)
                            .timeIntervalSince(max(workout.startDate, start)))
                        return (workout, overlap)
                    }
                    .filter { $0.1 >= duration * 0.40 }
                    .sorted { $0.1 > $1.1 }
                // Never associate an ambiguous HR zone series with a WOD.
                if matches.count > 1 && matches[1].1 >= matches[0].1 * 0.85 {
                    cont.resume(returning: nil)
                } else {
                    cont.resume(returning: matches.first?.0)
                }
            }
            store.execute(query)
        }
    }

    private func loadHealthExtras(
        workoutUUID: UUID?,
        start: Date,
        end: Date
    ) async -> SessionHealthExtras {
        async let hrSeries = heartRateSeries(from: start, to: end)
        async let route = fetchRoutePoints(workoutUUID: workoutUUID, start: start, end: end)
        let (series, points) = await (hrSeries, route)

        let bpmValues = series.map(\.bpm)
        let speeds = points.compactMap(\.speedMps).filter { $0 >= 0 }
        let avgSpeedKmh: Double? = speeds.isEmpty
            ? nil
            : (speeds.reduce(0, +) / Double(speeds.count)) * 3.6
        let maxSpeedKmh: Double? = speeds.max().map { $0 * 3.6 }

        var kcal: Double?
        var source: String?
        var typeRaw: UInt?
        if let workoutUUID, let workout = await fetchWorkout(uuid: workoutUUID) {
            source = workout.sourceRevision.source.name
            typeRaw = workout.workoutActivityType.rawValue
            if let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
               let burned = workout.statistics(for: energyType)?.sumQuantity()?.doubleValue(for: .kilocalorie()),
               burned > 0 {
                kcal = burned
            }
        }

        return SessionHealthExtras(
            averageHeartRateBpm: bpmValues.isEmpty ? nil : bpmValues.reduce(0, +) / Double(bpmValues.count),
            maxHeartRateBpm: bpmValues.max(),
            minHeartRateBpm: bpmValues.min(),
            // Más muestras para obtener FC media fiable en parciales largos,
            // conservando la reducción de puntos en entrenos sin recorrido.
            heartRateSeries: downsample(series, maxCount: points.count >= 2 ? 480 : 120),
            routePoints: downsampleRoute(points, maxCount: 400),
            averageSpeedKmh: avgSpeedKmh,
            maxSpeedKmh: maxSpeedKmh,
            activeEnergyKcal: kcal,
            sourceName: source,
            activityTypeRaw: typeRaw,
            resolvedWorkoutUUID: workoutUUID
        )
    }

    private func heartRateSeries(from start: Date, to end: Date) async -> [HeartRatePoint] {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                let unit = HKUnit.count().unitDivided(by: .minute())
                let points = (samples as? [HKQuantitySample] ?? []).map { sample in
                    HeartRatePoint(
                        date: sample.startDate,
                        bpm: sample.quantity.doubleValue(for: unit)
                    )
                }
                cont.resume(returning: points)
            }
            store.execute(q)
        }
    }

    /// Borra un entreno de Salud **solo si** el sample es de esta app.
    /// - Returns: `true` if deleted or already absent; `false` if foreign / error.
    @discardableResult
    func deleteExternalWorkout(id: UUID) async -> Bool {
        guard isAvailable else { return false }
        guard canWriteWorkouts || isAuthorized else {
            lastError = "Sin permiso de escritura en Salud"
            return false
        }
        guard let workout = await fetchWorkout(uuid: id) else {
            // Idempotent: sample already gone — clear cache only.
            recentExternalActivities.removeAll { $0.id == id }
            return true
        }
        let bundle = Bundle.main.bundleIdentifier
        let sourceBundle = workout.sourceRevision.source.bundleIdentifier
        if let bundle, sourceBundle != bundle {
            lastError = "No se puede borrar un entreno de otra app"
            return false
        }
        do {
            try await store.delete(workout)
            recentExternalActivities.removeAll { $0.id == id }
            invalidateHealthMetricCache(reason: "deleteWorkout")
            lastError = nil
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    /// Vuelve a pedir lectura de rutas (tipos nuevos no se activan solos tras la 1.ª autorización).
    func ensureWorkoutRouteAccess() async {
        guard isAvailable else { return }
        let read: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute(),
        ]
        let share: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.workoutType(),
        ]
        do {
            try await store.requestAuthorization(toShare: share, read: read)
            refreshAuthorizationStatus()
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func fetchRoutePoints(workoutUUID: UUID?, start: Date, end: Date) async -> [RoutePoint] {
        var routes: [HKWorkoutRoute] = []
        if let workoutUUID, let workout = await fetchWorkout(uuid: workoutUUID) {
            routes = await fetchRoutes(for: workout)
        }
        if routes.isEmpty {
            routes = await fetchRoutes(overlappingStart: start, end: end)
        }
        var all: [CLLocation] = []
        for route in routes {
            let locs = await fetchLocations(in: route)
            all.append(contentsOf: locs)
        }
        all.sort { $0.timestamp < $1.timestamp }
        return mapLocationsToRoutePoints(all)
    }

    private func mapLocationsToRoutePoints(_ all: [CLLocation]) -> [RoutePoint] {
        guard !all.isEmpty else { return [] }
        return all.enumerated().map { idx, loc in
            var speed: Double? = loc.speed >= 0 ? loc.speed : nil
            if speed == nil, idx > 0 {
                let prev = all[idx - 1]
                let dt = loc.timestamp.timeIntervalSince(prev.timestamp)
                if dt > 0.5 {
                    speed = loc.distance(from: prev) / dt
                }
            }
            return RoutePoint(
                id: idx,
                latitude: loc.coordinate.latitude,
                longitude: loc.coordinate.longitude,
                date: loc.timestamp,
                speedMps: speed,
                altitudeMeters: (0...50).contains(loc.verticalAccuracy) ? loc.altitude : nil
            )
        }
    }

    private func fetchWorkout(uuid: UUID) async -> HKWorkout? {
        let predicate = HKQuery.predicateForObject(with: uuid)
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: 1,
                sortDescriptors: nil
            ) { _, samples, _ in
                cont.resume(returning: samples?.first as? HKWorkout)
            }
            store.execute(q)
        }
    }

    /// Consulta los UUID enlazados y solo publica las kcal que Salud ha registrado
    /// en un workout externo. Los UUID propios nunca producen chips de calorías.
    func refreshVerifiedWorkoutEnergy(for sessions: [WorkoutSession]) async {
        guard isAvailable else {
            verifiedWorkoutEnergyKcal = [:]
            return
        }
        let uuids = Set(sessions.compactMap(\.healthKitWorkoutUUID))
        var verified: [UUID: Double] = [:]
        for uuid in uuids {
            if Task.isCancelled { return }
            if let kcal = await externalWorkoutEnergyKcal(uuid: uuid) {
                verified[uuid] = kcal
            }
        }
        verifiedWorkoutEnergyKcal = verified
    }

    /// kcal de un workout de Salud **ajeno** (Watch / otra app). `nil` si es nuestro o no hay energía.
    /// Sirve para no tratar como «verdad Apple» las kcal que Repera escribió mal (p. ej. 2 kcal ambiente).
    func externalWorkoutEnergyKcal(uuid: UUID) async -> Double? {
        guard let workout = await fetchWorkout(uuid: uuid) else { return nil }
        if Self.isReperaSource(workout.sourceRevision.source) { return nil }
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
              let burned = workout.statistics(for: energyType)?.sumQuantity()?.doubleValue(for: .kilocalorie()),
              burned > 0
        else { return nil }
        return burned
    }

    private func fetchRoutes(for workout: HKWorkout) async -> [HKWorkoutRoute] {
        let byWorkout = HKQuery.predicateForObjects(from: workout)
        let byDate = HKQuery.predicateForSamples(
            withStart: workout.startDate.addingTimeInterval(-120),
            end: workout.endDate.addingTimeInterval(120)
        )
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [byWorkout, byDate])
        return await queryRoutes(predicate: predicate)
    }

    /// Fallback: rutas cuya ventana temporal solapa el entreno (apps de terceros).
    private func fetchRoutes(overlappingStart start: Date, end: Date) async -> [HKWorkoutRoute] {
        let predicate = HKQuery.predicateForSamples(
            withStart: start.addingTimeInterval(-300),
            end: end.addingTimeInterval(300)
        )
        return await queryRoutes(predicate: predicate)
    }

    private func queryRoutes(predicate: NSPredicate) async -> [HKWorkoutRoute] {
        await withCheckedContinuation { cont in
            let q = HKSampleQuery(
                sampleType: HKSeriesType.workoutRoute(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                cont.resume(returning: (samples as? [HKWorkoutRoute]) ?? [])
            }
            store.execute(q)
        }
    }

    private func fetchLocations(in route: HKWorkoutRoute) async -> [CLLocation] {
        await withCheckedContinuation { cont in
            final class RouteCollectBox: @unchecked Sendable {
                var collected: [CLLocation] = []
                var finished = false
            }
            let box = RouteCollectBox()
            let q = HKWorkoutRouteQuery(route: route) { _, locations, done, error in
                if let locations {
                    box.collected.append(contentsOf: locations)
                }
                if (done || error != nil), !box.finished {
                    box.finished = true
                    cont.resume(returning: box.collected)
                }
            }
            store.execute(q)
        }
    }

    private func downsample(_ series: [HeartRatePoint], maxCount: Int) -> [HeartRatePoint] {
        guard series.count > maxCount, maxCount > 2 else { return series }
        let step = Double(series.count - 1) / Double(maxCount - 1)
        return (0..<maxCount).map { i in
            series[min(series.count - 1, Int((Double(i) * step).rounded()))]
        }
    }

    private func downsampleRoute(_ points: [RoutePoint], maxCount: Int) -> [RoutePoint] {
        guard points.count > maxCount, maxCount > 2 else { return points }
        let step = Double(points.count - 1) / Double(maxCount - 1)
        return (0..<maxCount).enumerated().map { outIdx, _ in
            let src = points[min(points.count - 1, Int((Double(outIdx) * step).rounded()))]
            return RoutePoint(
                id: outIdx,
                latitude: src.latitude,
                longitude: src.longitude,
                date: src.date,
                speedMps: src.speedMps,
                altitudeMeters: src.altitudeMeters
            )
        }
    }


    /// Same Repera session when UUID matches, or a single unambiguous strict overlap.
    /// Ambiguous multi-match (±slack) returns false so callers fall back to interval energy.
    static func matchesReperaSession(
        healthStart: Date,
        healthEnd: Date,
        healthUUID: UUID,
        sessions: [WorkoutSession],
        slack: TimeInterval = 45 * 60
    ) -> Bool {
        if sessions.contains(where: { $0.healthKitWorkoutUUID == healthUUID }) {
            return true
        }
        var hits = 0
        for session in sessions {
            guard let start = session.startedAt else { continue }
            let duration: TimeInterval
            if let apple = session.appleDurationSeconds, apple > 0 {
                duration = apple
            } else if let finished = session.finishedAt {
                duration = max(60, finished.timeIntervalSince(start))
            } else {
                duration = max(60, session.durationMinutes * 60)
            }
            let end = session.finishedAt ?? start.addingTimeInterval(duration)
            let reperaDuration = max(60, end.timeIntervalSince(start))
            let overlapStart = max(healthStart, start)
            let overlapEnd = min(healthEnd, end)
            let overlap = max(0, overlapEnd.timeIntervalSince(overlapStart))
            // Require real overlap ≥ 40% of Repera duration (not mere ±45min proximity).
            guard overlap >= reperaDuration * 0.4 else { continue }
            // Also require the Health sample to land near the session window (±slack).
            let looseStart = start.addingTimeInterval(-slack)
            let looseEnd = end.addingTimeInterval(slack)
            guard healthStart < looseEnd, healthEnd > looseStart else { continue }
            hits += 1
            if hits > 1 { return false }
        }
        return hits == 1
    }

    private static func displayName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .traditionalStrengthTraining: return "Fuerza"
        case .functionalStrengthTraining: return "Fuerza funcional"
        case .highIntensityIntervalTraining: return "HIIT"
        case .running: return "Carrera"
        case .walking: return "Caminar"
        case .cycling: return "Ciclismo"
        case .swimming: return "Natación"
        case .yoga: return "Yoga"
        case .pilates: return "Pilates"
        case .coreTraining: return "Core"
        case .flexibility: return "Movilidad"
        case .cooldown: return "Enfriamiento"
        case .elliptical: return "Elíptica"
        case .rowing: return "Remo"
        case .stairClimbing: return "Escaleras"
        case .hiking: return "Senderismo"
        case .dance: return "Baile"
        case .martialArts: return "Artes marciales"
        case .soccer, .basketball, .tennis, .golf: return "Deporte"
        case .crossTraining: return "Cross-training"
        case .mixedCardio: return "Cardio"
        case .other: return "Actividad"
        default: return "Actividad · Salud"
        }
    }

    /// Escribe peso en Salud (última modificación gana si luego se vuelve a leer).
    func saveBodyMass(kg: Double, date: Date = Date()) async {
        guard isAvailable,
              let type = HKQuantityType.quantityType(forIdentifier: .bodyMass)
        else { return }
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        do {
            try await store.save(sample)
            latestWeightKg = kg
            latestWeightDate = date
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Sesión en vivo (Apple manda)

    /// Arranca un `HKWorkoutBuilder` de fuerza tradicional alineado con el reloj/Salud.
    func beginWorkout(sessionId: UUID, title: String, start: Date = Date()) async {
        guard isAvailable else { return }
        refreshAuthorizationStatus()
        guard canWriteWorkouts || isAuthorized else {
            lastError = "Sin permiso de escritura en Salud"
            return
        }
        trackedSessionId = sessionId
        trackedStart = start
        liveActiveEnergyKcal = 0
        liveDurationSeconds = 0

        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor

        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        do {
            try await builder.beginCollection(at: start)
            liveBuilder = builder
            await refreshLiveMetrics()
        } catch {
            lastError = error.localizedDescription
            liveBuilder = nil
        }
    }

    /// Actualiza calorías/tiempo leyendo Salud (incluye lo que aporta el Apple Watch).
    func refreshLiveMetrics() async {
        guard let start = trackedStart else { return }
        let end = Date()
        liveDurationSeconds = max(0, end.timeIntervalSince(start))
        let apple = await resolveAppleMetrics(from: start, to: end)
        liveActiveEnergyKcal = apple.kcal
        if let secs = apple.durationSeconds, secs > 0 {
            liveDurationSeconds = secs
        }
    }

    /// Resultado de cerrar un entreno alineado con Apple Salud.
    struct WorkoutSyncResult: Sendable {
        var startedAt: Date
        var finishedAt: Date
        var kcal: Double
        var durationSeconds: TimeInterval
        var workoutUUID: UUID?
    }

    /// Finaliza y escribe la sesión en Salud sin inventar muestras de energía.
    /// Solo un HKWorkout externo con kcal registradas puede asignar kcal a Repera.
    func finishWorkout(
        sessionId: UUID,
        title: String,
        start: Date,
        end: Date,
        fallbackKcal: Double? = nil
    ) async -> WorkoutSyncResult {
        let safeEnd = max(end, start.addingTimeInterval(60))
        let apple = await resolveAppleMetrics(from: start, to: safeEnd)
        var resolvedStart = start
        var resolvedEnd = safeEnd
        var duration = max(60, safeEnd.timeIntervalSince(start))
        var verifiedKcal: Double = 0
        var savedUUID: UUID?

        if let existing = apple.existingWorkout {
            if Self.isReperaSource(existing.sourceRevision.source) {
                // Entreno que guardó Repera: sus kcal podrían ser estimaciones.
                savedUUID = existing.uuid
                await discardLocalBuilder()
            } else if let energy = await externalWorkoutEnergyKcal(uuid: existing.uuid) {
                // Medición del propio entrenamiento en Apple Salud / Watch.
                verifiedKcal = energy
                resolvedStart = existing.startDate
                resolvedEnd = existing.endDate
                duration = max(60, existing.duration)
                savedUUID = existing.uuid
                await discardLocalBuilder()
            } else {
                // El workout ajeno no trae kcal: no asumir que la actividad
                // ambiental de ese intervalo pertenece al entreno.
                savedUUID = await saveStrengthWorkout(
                    title: title,
                    start: resolvedStart,
                    end: resolvedEnd,
                    preferBuilder: liveBuilder
                )
            }
        } else {
            savedUUID = await saveStrengthWorkout(
                title: title,
                start: resolvedStart,
                end: resolvedEnd,
                preferBuilder: liveBuilder
            )
        }

        trackedSessionId = nil
        trackedStart = nil
        liveBuilder = nil
        liveActiveEnergyKcal = verifiedKcal > 0 ? verifiedKcal : nil
        liveDurationSeconds = duration
        await refreshToday()
        _ = sessionId
        _ = fallbackKcal // Compatibilidad de llamadas; nunca se utiliza como medición.
        return WorkoutSyncResult(
            startedAt: resolvedStart,
            finishedAt: resolvedEnd,
            kcal: verifiedKcal,
            durationSeconds: duration,
            workoutUUID: savedUUID
        )
    }

    /// Energía de Salud/Watch creíble frente al estimado del entreno.
    /// Descarta samples ambiente (p. ej. 2 kcal de movimiento diario en la misma hora).
    nonisolated static func shouldTrustAppleWorkoutEnergy(
        _ appleKcal: Double,
        sessionEstimate: Double
    ) -> Bool {
        guard appleKcal >= 30 else { return false }
        if sessionEstimate >= 100, appleKcal < sessionEstimate * 0.15 {
            return false
        }
        return true
    }

    /// Estimación local cuando Salud/Watch no aportan kcal (se escribe en HealthKit como complemento).
    /// - MET ≈ 5.5 fuerza con carga, ≈ 7–8 metcon, ≈ 9 comba/bike/cardio puro.
    /// - Fórmula MET estándar: `kcal/min = MET × 3.5 × kg / 200`.
    /// - `metOverride`: p. ej. 8.0 para WOD mixto (EMOM/AMRAP) sin disparar a 9 todo el bloque.
    static func estimateActiveEnergyKcal(
        durationMinutes: Double,
        volumeKg: Double,
        bodyWeightKg: Double? = nil,
        totalReps: Int = 0,
        timedCardioSeconds: Int = 0,
        metOverride: Double? = nil
    ) -> Double {
        let minutes = max(1, durationMinutes)
        let bw = max(40, min(180, bodyWeightKg ?? 75))
        let met: Double
        if let metOverride {
            met = metOverride
        } else if timedCardioSeconds >= 30, volumeKg < 1 {
            met = 9.0
        } else if volumeKg >= 50 {
            met = 5.5
        } else if totalReps > 0 {
            met = 7.0
        } else {
            met = 5.0
        }
        let fromTime = (met * 3.5 * bw / 200.0) * minutes
        let fromVolume = volumeKg * 0.02
        // Solo si el reloj es corto: tope 20 % del tiempo para no inflar WOD largos.
        let rawReps = volumeKg < 1 ? Double(max(0, totalReps)) * 0.08 : 0
        let fromReps = min(rawReps, fromTime * 0.2)
        return max(0, (fromTime + fromVolume + fromReps).rounded())
    }

    func discardLiveTracking() async {
        await discardLocalBuilder()
        trackedSessionId = nil
        trackedStart = nil
        liveActiveEnergyKcal = nil
        liveDurationSeconds = nil
    }

    // MARK: - Métricas Apple (Watch creíble; ambiente no pisa el entreno)

    private struct AppleMetrics {
        var kcal: Double
        var durationSeconds: TimeInterval?
        var existingWorkoutUUID: UUID?
        var existingWorkout: HKWorkout?
    }

    /// Detecta `HKWorkout` en franja similar o suma energía activa del intervalo (puede ser ambiente).
    private func resolveAppleMetrics(from start: Date, to end: Date) async -> AppleMetrics {
        if let workout = await overlappingWorkout(from: start, to: end) {
            var kcal: Double = 0
            if let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
               let burned = workout.statistics(for: energyType)?.sumQuantity()?.doubleValue(for: .kilocalorie()),
               burned > 0 {
                kcal = burned
            } else {
                kcal = await activeEnergy(from: workout.startDate, to: workout.endDate)
            }
            return AppleMetrics(
                kcal: kcal,
                durationSeconds: workout.duration,
                existingWorkoutUUID: workout.uuid,
                existingWorkout: workout
            )
        }
        let kcal = await activeEnergy(from: start, to: end)
        return AppleMetrics(
            kcal: kcal,
            durationSeconds: end.timeIntervalSince(start),
            existingWorkoutUUID: nil,
            existingWorkout: nil
        )
    }

    /// Match Watch/Salud workout only when overlap is unambiguous (≥40% of Repera span).
    private func overlappingWorkout(from start: Date, to end: Date) async -> HKWorkout? {
        let slack: TimeInterval = 45 * 60
        let reperaDuration = max(60, end.timeIntervalSince(start))
        let minOverlap = reperaDuration * 0.4
        let expandedStart = start.addingTimeInterval(-slack)
        let expandedEnd = end.addingTimeInterval(slack)
        let predicate = HKQuery.predicateForSamples(withStart: expandedStart, end: expandedEnd)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { (cont: CheckedContinuation<HKWorkout?, Never>) in
            let q = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: 20,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                let workouts = (samples as? [HKWorkout]) ?? []
                let ranked = workouts
                    .map { w -> (HKWorkout, TimeInterval) in
                        let overlapStart = max(w.startDate, start)
                        let overlapEnd = min(w.endDate, end)
                        let overlap = max(0, overlapEnd.timeIntervalSince(overlapStart))
                        return (w, overlap)
                    }
                    .filter { $0.1 >= minOverlap }
                    .sorted { a, b in
                        let aStrength = Self.isStrengthLike(a.0.workoutActivityType)
                        let bStrength = Self.isStrengthLike(b.0.workoutActivityType)
                        if aStrength != bStrength { return aStrength && !bStrength }
                        return a.1 > b.1
                    }
                // Ambiguous: two strong candidates within 15% of each other → nil.
                if ranked.count >= 2 {
                    let best = ranked[0].1
                    let second = ranked[1].1
                    if second >= best * 0.85 {
                        cont.resume(returning: nil)
                        return
                    }
                }
                cont.resume(returning: ranked.first?.0)
            }
            store.execute(q)
        }
    }

    nonisolated private static func isStrengthLike(_ type: HKWorkoutActivityType) -> Bool {
        switch type {
        case .traditionalStrengthTraining, .functionalStrengthTraining, .highIntensityIntervalTraining,
             .crossTraining, .coreTraining:
            return true
        default:
            return false
        }
    }

    private func activeEnergy(from start: Date, to end: Date) async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0 }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        return await withCheckedContinuation { (cont: CheckedContinuation<Double, Never>) in
            let q = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: [.cumulativeSum, .separateBySource]
            ) { _, stats, _ in
                cont.resume(returning: Self.measuredEnergyKcal(stats))
            }
            store.execute(q)
        }
    }

    private func saveStrengthWorkout(
        title: String,
        start: Date,
        end: Date,
        preferBuilder: HKWorkoutBuilder?
    ) async -> UUID? {
        if let builder = preferBuilder {
            do {
                // El workout queda en Salud, pero no añade kcal estimadas.
                try await builder.endCollection(at: end)
                if let workout = try await builder.finishWorkout() {
                    liveBuilder = nil
                    return workout.uuid
                }
            } catch {
                lastError = error.localizedDescription
                liveBuilder = nil
            }
        }

        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor
        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        do {
            try await builder.beginCollection(at: start)
            try await builder.addMetadata([
                HKMetadataKeyWorkoutBrandName: "Repera",
                "ReperaTitle": title,
            ])
            try await builder.endCollection(at: end)
            return try await builder.finishWorkout()?.uuid
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }

    private func discardLocalBuilder() async {
        guard let builder = liveBuilder else { return }
        liveBuilder = nil
        builder.discardWorkout()
    }

    // MARK: - Today aggregates

    private func fetchLatestWeight() async {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            let q = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                Task { @MainActor in
                    if let sample = samples?.first as? HKQuantitySample {
                        self.latestWeightKg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                        self.latestWeightDate = sample.endDate
                    }
                    cont.resume()
                }
            }
            store.execute(q)
        }
    }

    private func workoutMinutes(from start: Date, to end: Date) async -> Double {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        return await withCheckedContinuation { (cont: CheckedContinuation<Double, Never>) in
            let q = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                let total = (samples as? [HKWorkout])?.reduce(0.0) { $0 + $1.duration } ?? 0
                cont.resume(returning: total / 60.0)
            }
            store.execute(q)
        }
    }

    private func fetchActiveEnergyToday() async {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date())
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: [.cumulativeSum, .separateBySource]) { _, stats, _ in
                let measuredKcal = Self.measuredEnergyKcal(stats)
                Task { @MainActor in
                    self.activeEnergyTodayKcal = measuredKcal > 0 ? measuredKcal : nil
                    cont.resume()
                }
            }
            store.execute(q)
        }
    }

    private func fetchWorkoutMinutesToday() async {
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date())
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            let q = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                Task { @MainActor in
                    let total = (samples as? [HKWorkout])?.reduce(0.0) { $0 + $1.duration } ?? 0
                    self.workoutMinutesToday = total / 60.0
                    cont.resume()
                }
            }
            store.execute(q)
        }
    }
}

/// SF Symbols por tipo de actividad de Salud (fuera del MainActor).
enum HealthActivityIcons {
    static func isOutdoor(_ type: HKWorkoutActivityType) -> Bool {
        switch type {
        case .running, .cycling, .hiking, .walking,
             .wheelchairRunPace, .handCycling,
             .downhillSkiing, .snowboarding,
             .paddleSports, .rowing, .skatingSports:
            return true
        default:
            return false
        }
    }

    static func symbolName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .traditionalStrengthTraining, .functionalStrengthTraining:
            return "figure.strengthtraining.traditional"
        case .highIntensityIntervalTraining:
            return "figure.highintensity.intervaltraining"
        case .running:
            return "figure.run"
        case .walking:
            return "figure.walk"
        case .cycling:
            return "figure.outdoor.cycle"
        case .swimming:
            return "figure.pool.swim"
        case .yoga:
            return "figure.yoga"
        case .pilates:
            return "figure.pilates"
        case .coreTraining:
            return "figure.core.training"
        case .flexibility:
            return "figure.flexibility"
        case .cooldown:
            return "figure.cooldown"
        case .elliptical:
            return "figure.elliptical"
        case .rowing:
            return "figure.rower"
        case .stairClimbing:
            return "figure.stair.stepper"
        case .hiking:
            return "figure.hiking"
        case .dance:
            return "figure.dance"
        case .martialArts:
            return "figure.martial.arts"
        case .soccer:
            return "figure.soccer"
        case .basketball:
            return "figure.basketball"
        case .tennis:
            return "figure.tennis"
        case .golf:
            return "figure.golf"
        case .crossTraining:
            return "figure.cross.training"
        case .mixedCardio, .other:
            return "figure.mixed.cardio"
        default:
            return "figure.mixed.cardio"
        }
    }
}
