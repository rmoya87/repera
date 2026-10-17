import CoreLocation
import Foundation
import GymbroDomain
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

    /// Métricas de Salud asociadas a un entreno propio de Gymbro.
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

    private init() {}

    func requestAccess() async {
        guard isAvailable else {
            lastError = "HealthKit no disponible en este dispositivo"
            isAuthorized = false
            return
        }
        var read: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.workoutType(),
        ]
        read.insert(HKSeriesType.workoutRoute())
        let share: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.workoutType(),
        ]
        do {
            try await store.requestAuthorization(toShare: share, read: read)
            refreshAuthorizationStatus()
            if isAuthorized {
                lastError = nil
                await refreshToday()
            } else {
                lastError = "Revisa permisos de Gymbro en Ajustes → Salud"
            }
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

    /// Entrenamientos de Salud en un día, excluyendo UUIDs ya vinculados o solapes con sesiones Gymbro.
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
        return workouts.compactMap { w in
            mapExternalActivity(
                w,
                excludingUUIDs: excludingUUIDs,
                overlappingSessions: overlappingSessions
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

    func invalidateHealthMetricCache(reason: String = "manual") {
        healthCacheDays = 0
        healthCacheIsDaily = false
        healthCacheFetchedAt = nil
        healthCacheCoverageDays = 0
        healthCacheFilterKey = ""
        healthDataRevision &+= 1
        ProgressLog.info("health cache invalidate \(reason)")
    }

    nonisolated static func healthFilterKey(
        excludingUUIDs: Set<UUID>,
        overlappingSessions: [WorkoutSession]
    ) -> String {
        let uuidPart = excludingUUIDs.map(\.uuidString).sorted().joined(separator: ",")
        let sessionPart = overlappingSessions
            .map { s -> String in
                let start = s.startedAt?.timeIntervalSince1970 ?? 0
                let end = s.finishedAt?.timeIntervalSince1970 ?? 0
                let hk = s.healthKitWorkoutUUID?.uuidString ?? "-"
                return "\(s.id.uuidString):\(start):\(end):\(hk)"
            }
            .sorted()
            .joined(separator: "|")
        return "\(uuidPart)#\(sessionPart)"
    }

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
        if isHealthCacheFresh(forDays: days, filterKey: filterKey),
           !recentDailyHeartRate.isEmpty || !recentDailyActiveEnergy.isEmpty {
            ProgressLog.healthCacheHit(
                days: days,
                hr: recentDailyHeartRate.count,
                kcal: recentDailyActiveEnergy.count
            )
            return
        }

        let t0 = CFAbsoluteTimeGetCurrent()
        ProgressLog.healthFetchStart(days: days)

        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -days, to: end) ?? end
        let dayBucket = DateComponents(day: 1)

        var t = CFAbsoluteTimeGetCurrent()
        let activities = await externalActivities(
            from: start,
            to: end,
            excludingUUIDs: excludingUUIDs,
            overlappingSessions: overlappingSessions
        )
        ProgressLog.healthFetchStep("activities", count: activities.count, elapsedMs: (CFAbsoluteTimeGetCurrent() - t) * 1000)

        t = CFAbsoluteTimeGetCurrent()
        async let hr = dailyHeartRateStats(from: start, to: end, interval: dayBucket)
        async let energy = dailyActiveEnergyStats(from: start, to: end, interval: dayBucket)
        let (hrPoints, energyPoints) = await (hr, energy)
        ProgressLog.healthFetchStep(
            "hr+kcal",
            count: hrPoints.count + energyPoints.count,
            elapsedMs: (CFAbsoluteTimeGetCurrent() - t) * 1000
        )

        // Un solo commit observable (evita 3 rebuilds de Charts en Progreso).
        recentExternalActivities = activities
        recentDailyHeartRate = hrPoints
        recentDailyActiveEnergy = energyPoints
        healthCacheDays = max(healthCacheDays, days)
        healthCacheIsDaily = true
        healthCacheFetchedAt = Date()
        healthCacheCoverageDays = healthCacheDays
        healthCacheFilterKey = filterKey
        healthDataRevision &+= 1

        ProgressLog.healthFetchDone(
            totalMs: (CFAbsoluteTimeGetCurrent() - t0) * 1000,
            activities: activities.count,
            hr: hrPoints.count,
            kcal: energyPoints.count
        )
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
                options: .cumulativeSum,
                anchorDate: dayStart,
                intervalComponents: interval
            )
            query.initialResultsHandler = { _, collection, _ in
                var points: [DailyActiveEnergyPoint] = []
                collection?.enumerateStatistics(from: dayStart, to: end) { stats, _ in
                    let kcal = stats.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
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
        overlappingSessions: [WorkoutSession]
    ) -> ExternalActivity? {
        guard !excludingUUIDs.contains(w.uuid) else { return nil }
        if Self.matchesGymbroSession(
            healthStart: w.startDate,
            healthEnd: w.endDate,
            healthUUID: w.uuid,
            sessions: overlappingSessions
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
        guard isAuthorized else { return nil }
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

        if extras.activeEnergyKcal == nil {
            extras.activeEnergyKcal = session.appleActiveEnergyKcal
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
            heartRateSeries: downsample(series, maxCount: 120),
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
                speedMps: speed
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
                speedMps: src.speedMps
            )
        }
    }


    /// Same Gymbro session when UUID matches, or a single unambiguous strict overlap.
    /// Ambiguous multi-match (±slack) returns false so callers fall back to interval energy.
    static func matchesGymbroSession(
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
            let gymbroDuration = max(60, end.timeIntervalSince(start))
            let overlapStart = max(healthStart, start)
            let overlapEnd = min(healthEnd, end)
            let overlap = max(0, overlapEnd.timeIntervalSince(overlapStart))
            // Require real overlap ≥ 40% of Gymbro duration (not mere ±45min proximity).
            guard overlap >= gymbroDuration * 0.4 else { continue }
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

    /// Cierra el entreno: si hay franja similar en Salud, manda Apple; si falta algo, lo complementamos y lo enviamos.
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
        var kcal = apple.kcal
        var savedUUID = apple.existingWorkoutUUID

        if let existing = apple.existingWorkout {
            // Misma franja que Watch/Salud → horarios y duración de Apple.
            resolvedStart = existing.startDate
            resolvedEnd = existing.endDate
            duration = max(60, existing.duration)
            if kcal <= 0 {
                // Salud sin kcal: estimamos / usamos fallback y lo escribimos como samples.
                let ours = fallbackKcal ?? Self.estimateActiveEnergyKcal(
                    durationMinutes: duration / 60,
                    volumeKg: 0
                )
                if ours > 0 {
                    kcal = ours
                    await saveActiveEnergySample(kcal: ours, start: resolvedStart, end: resolvedEnd)
                }
            }
            await discardLocalBuilder()
        } else {
            // No hay entreno Apple en la franja → usamos nuestros tiempos y escribimos el workout.
            if kcal <= 0 {
                kcal = fallbackKcal ?? Self.estimateActiveEnergyKcal(
                    durationMinutes: duration / 60,
                    volumeKg: 0
                )
            }
            savedUUID = await saveStrengthWorkout(
                title: title,
                start: resolvedStart,
                end: resolvedEnd,
                activeEnergyKcal: kcal,
                preferBuilder: liveBuilder
            )
        }

        trackedSessionId = nil
        trackedStart = nil
        liveBuilder = nil
        liveActiveEnergyKcal = kcal
        liveDurationSeconds = duration
        await refreshToday()
        return WorkoutSyncResult(
            startedAt: resolvedStart,
            finishedAt: resolvedEnd,
            kcal: kcal,
            durationSeconds: duration,
            workoutUUID: savedUUID
        )
    }

    /// Estimación local cuando Salud no aporta kcal (se envía a HealthKit como complemento).
    static func estimateActiveEnergyKcal(durationMinutes: Double, volumeKg: Double) -> Double {
        max(0, durationMinutes * 7.5 + volumeKg * 0.02)
    }

    func discardLiveTracking() async {
        await discardLocalBuilder()
        trackedSessionId = nil
        trackedStart = nil
        liveActiveEnergyKcal = nil
        liveDurationSeconds = nil
    }

    // MARK: - Apple como fuente de verdad

    private struct AppleMetrics {
        var kcal: Double
        var durationSeconds: TimeInterval?
        var existingWorkoutUUID: UUID?
        var existingWorkout: HKWorkout?
    }

    /// Prioriza un `HKWorkout` del Watch/Salud en franja similar; si no, suma energía activa del intervalo.
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

    /// Match Watch/Salud workout only when overlap is unambiguous (≥40% of Gymbro span).
    private func overlappingWorkout(from start: Date, to end: Date) async -> HKWorkout? {
        let slack: TimeInterval = 45 * 60
        let gymbroDuration = max(60, end.timeIntervalSince(start))
        let minOverlap = gymbroDuration * 0.4
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

    /// Sample suelto de kcal cuando el workout de Salud existe pero no trae energía.
    private func saveActiveEnergySample(kcal: Double, start: Date, end: Date) async {
        guard kcal > 0,
              let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
        else { return }
        let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: kcal)
        let sample = HKCumulativeQuantitySample(
            type: energyType,
            quantity: quantity,
            start: start,
            end: max(end, start.addingTimeInterval(60))
        )
        do {
            try await store.save(sample)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func activeEnergy(from start: Date, to end: Date) async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0 }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        return await withCheckedContinuation { (cont: CheckedContinuation<Double, Never>) in
            let q = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, stats, _ in
                let value = stats?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                cont.resume(returning: value)
            }
            store.execute(q)
        }
    }

    private func saveStrengthWorkout(
        title: String,
        start: Date,
        end: Date,
        activeEnergyKcal: Double,
        preferBuilder: HKWorkoutBuilder?
    ) async -> UUID? {
        if let builder = preferBuilder {
            do {
                if activeEnergyKcal > 0,
                   let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                    let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: activeEnergyKcal)
                    let sample = HKCumulativeQuantitySample(
                        type: energyType,
                        quantity: quantity,
                        start: start,
                        end: end
                    )
                    try await builder.addSamples([sample])
                }
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

        // Fallback: builder nuevo
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor
        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        do {
            try await builder.beginCollection(at: start)
            if activeEnergyKcal > 0,
               let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: activeEnergyKcal)
                let sample = HKCumulativeQuantitySample(
                    type: energyType,
                    quantity: quantity,
                    start: start,
                    end: end
                )
                try await builder.addSamples([sample])
            }
            try await builder.addMetadata([
                HKMetadataKeyWorkoutBrandName: "Gymbro",
                "GymbroTitle": title,
            ])
            try await builder.endCollection(at: end)
            let workout = try await builder.finishWorkout()
            return workout?.uuid
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
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                Task { @MainActor in
                    self.activeEnergyTodayKcal = stats?.sumQuantity()?.doubleValue(for: .kilocalorie())
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
