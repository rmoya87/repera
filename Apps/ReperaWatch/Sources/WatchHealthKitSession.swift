import CoreLocation
import Foundation
import HealthKit
import Observation

/// Only HealthKit measures calories, heart rate and the saved workout's duration.
/// Repera's motion counter is never used for energy or heart-rate calculations.
@Observable
@MainActor
final class WatchHealthKitSession: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    struct Result: Sendable {
        var uuid: UUID? = nil
        var activeEnergyKcal: Double? = nil
        var durationSeconds: TimeInterval? = nil
        var start: Date? = nil
        var end: Date? = nil
        var averageHeartRateBpm: Double? = nil
    }

    private let store = HKHealthStore()
    private var workout: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    /// Ruta GPS outdoor en Salud (mismo bundle Watch). El iPhone no puede
    /// adjuntar `HKWorkoutRoute` a un workout creado por watchkitapp.
    private var routeBuilder: HKWorkoutRouteBuilder?
    private var recordsRoute = false
    /// Metros GPS verificados por el registrador de ruta. No equivale a una
    /// muestra de HealthKit hasta que se asocia al HKWorkout.
    private var recordedRouteDistanceMeters: Double = 0
    private var pendingRouteLocations: [CLLocation] = []
    private var routeInsertTask: Task<Void, Never>?
    private var workoutID: UUID?
    private var lastRecordedBlockID: UUID?
    private var pendingBlock: (id: UUID, isInterval: Bool)?
    private var finishHandler: ((Result) -> Void)?
    var onPauseResumeRequest: (() -> Void)?
    var onPauseStateChanged: ((Bool) -> Void)?
    var onMetricsUpdated: (() -> Void)?
    private var finishing = false
    // An HKWorkoutSession can still report .paused while an asynchronous
    // resume request is in flight. Do not send the same command twice.
    private var pendingStateTransition: HKWorkoutSessionState?
    private(set) var pulseBpm: Int?
    /// Time of the latest real HR sensor event, not the last energy update.
    private(set) var pulseCapturedAt: Date?
    private(set) var kcal: Double?
    private(set) var averageBpm: Double?
    private(set) var permissionIssue: String?
    private(set) var isRecording = false

    enum RecoveryOutcome: Sendable {
        /// Sesión recuperada y enlazada al UUID esperado.
        case recovered
        /// No hay workout activo que recuperar.
        case none
        /// Hay un workout activo que no pertenece a la ejecución esperada:
        /// queda adoptado sin enlazar para que el usuario lo guarde o descarte.
        case mismatch
    }

    /// Workout recuperado sin coincidencia de UUID: la UI debe resolverlo.
    private(set) var hasUnlinkedRecovery = false

    /// - Parameters:
    ///   - id: ejecución de Repera esperada; `nil` cuando no hay estado local
    ///     (cualquier workout recuperado es huérfano).
    ///   - expectedStart: inicio persistido; solo se usa si el workout aún no
    ///     tenía `HKMetadataKeyExternalUUID` (crash antes de `addMetadata`).
    func recoverIfNeeded(
        id: UUID?, expectedStart: Date? = nil,
        completion: (@MainActor @Sendable (RecoveryOutcome) -> Void)? = nil
    ) {
        guard workout == nil, HKHealthStore.isHealthDataAvailable() else {
            let linked = workout != nil && workoutID != nil && workoutID == id
            completion?(workout == nil ? .none : (linked ? .recovered : .mismatch))
            return
        }
        store.recoverActiveWorkoutSession { [weak self] recovered, error in
            Task { @MainActor in
                guard let self, let recovered else {
                    if let error { self?.permissionIssue = error.localizedDescription }
                    completion?(.none)
                    return
                }
                let live = recovered.associatedWorkoutBuilder()
                let external = live.metadata[HKMetadataKeyExternalUUID] as? String
                let matches: Bool
                switch (id, external, expectedStart) {
                case let (id?, external?, _):
                    matches = external == id.uuidString
                case let (.some, nil, start?):
                    matches = abs(recovered.startDate?.timeIntervalSince(start) ?? .infinity) <= 300
                default:
                    matches = false
                }
                self.workoutID = matches ? id : nil
                self.hasUnlinkedRecovery = !matches
                self.workout = recovered
                let outdoor = recovered.workoutConfiguration.locationType == .outdoor
                live.dataSource = Self.makeLiveDataSource(
                    store: self.store,
                    configuration: recovered.workoutConfiguration,
                    outdoor: outdoor
                )
                if outdoor {
                    self.recordsRoute = true
                    self.prepareRouteBuilder(from: live)
                }
                recovered.delegate = self
                live.delegate = self
                self.builder = live
                self.pendingStateTransition = nil
                self.isRecording = true
                self.seedMetricsFromBuilder(live)
                completion?(matches ? .recovered : .mismatch)
            }
        }
    }

    /// Segment boundaries belong to HealthKit, not to guessed heart-rate samples.
    /// Keep the same configuration for intervals as Apple requires.
    func beginBlock(id: UUID, isInterval: Bool) {
        guard !finishing, id != lastRecordedBlockID else { return }
        // Activity transitions are valid only for a running workout.
        // Switching blocks while paused queues the boundary until resume.
        guard isRecording, let session = workout, session.state == .running else {
            pendingBlock = (id, isInterval)
            return
        }
        pendingBlock = nil
        lastRecordedBlockID = id
        let metadata: [String: Any] = [
            "com.app.repera.blockID": id.uuidString,
            "com.app.repera.blockKind": isInterval ? "wod" : "strength"
        ]
        session.beginNewActivity(
            configuration: session.workoutConfiguration,
            date: Date(),
            metadata: metadata
        )
    }

    func start(id: UUID, at date: Date, includesWOD: Bool, includesStrength _: Bool) {
        // Paridad con Comenzar iPhone: WOD/CrossFit → crossTraining;
        // fuerza indoor → traditionalStrengthTraining (no HIIT ni solo
        // functionalStrength, que divergían del teléfono).
        let type: HKWorkoutActivityType = includesWOD
            ? .crossTraining
            : .traditionalStrengthTraining
        startConfigured(id: id, at: date, activityType: type, outdoor: false)
    }

    /// Comenzar iniciado en el reloj: tipo HK del deporte y GPS outdoor si aplica.
    func startLive(
        id: UUID, at date: Date, activityType: HKWorkoutActivityType,
        outdoor: Bool, mirrorsToPhone: Bool = true
    ) {
        startConfigured(id: id, at: date, activityType: activityType, outdoor: outdoor,
                        mirrorsToPhone: mirrorsToPhone)
    }

    private func startConfigured(
        id: UUID, at date: Date, activityType: HKWorkoutActivityType,
        outdoor: Bool, mirrorsToPhone: Bool = true
    ) {
        guard workout == nil, HKHealthStore.isHealthDataAvailable() else {
            permissionIssue = "Salud no disponible o entrenamiento de Salud ya iniciado."
            return
        }
        workoutID = id
        lastRecordedBlockID = nil
        pendingBlock = nil
        finishing = false
        pendingStateTransition = nil
        permissionIssue = nil
        pulseBpm = nil
        pulseCapturedAt = nil
        kcal = nil
        averageBpm = nil
        recordsRoute = outdoor
        recordedRouteDistanceMeters = 0
        routeBuilder = nil
        pendingRouteLocations = []
        routeInsertTask?.cancel()
        routeInsertTask = nil
        onMetricsUpdated?()
        let heart = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        var read: Set<HKObjectType> = [HKObjectType.workoutType(), heart, energy]
        var share: Set<HKSampleType> = [HKObjectType.workoutType()]
        if outdoor {
            read.insert(HKSeriesType.workoutRoute())
            share.insert(HKSeriesType.workoutRoute())
            if let distanceType = Self.routeDistanceType(for: activityType) {
                read.insert(distanceType)
                // Sin compartir distancia, addSamples puede fallar aunque la ruta
                // sea visible en Fitness; se solicita con el resto de permisos.
                share.insert(distanceType)
            }
        }
        // HealthKit operations stay on the MainActor. The authorization sheet,
        // builder collection and metadata use Apple's async APIs on watchOS 27.
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await store.requestAuthorization(toShare: share, read: read)
            } catch {
                if self.workoutID == id { self.permissionIssue = error.localizedDescription }
                return
            }
            guard self.workoutID == id, !self.finishing else { return }

            let config = HKWorkoutConfiguration()
            config.activityType = activityType
            config.locationType = outdoor ? .outdoor : .indoor

            do {
                let session = try HKWorkoutSession(healthStore: self.store, configuration: config)
                let liveBuilder = session.associatedWorkoutBuilder()
                liveBuilder.dataSource = Self.makeLiveDataSource(
                    store: self.store, configuration: config, outdoor: outdoor
                )
                session.delegate = self
                liveBuilder.delegate = self
                self.workout = session
                self.builder = liveBuilder
                session.startActivity(with: date)

                // Mirroring is best-effort: a missing or offline iPhone must
                // never delay the native Watch workout or its HealthKit samples.
                if mirrorsToPhone {
                    Task { @MainActor in
                        do {
                            try await session.startMirroringToCompanionDevice()
                        } catch {
                            // La medición local continúa aunque el teléfono no esté disponible.
                        }
                    }
                }

                do {
                    try await liveBuilder.beginCollection(at: date)
                    guard self.workoutID == id, self.builder === liveBuilder else { return }
                    self.isRecording = true
                    if outdoor {
                        self.prepareRouteBuilder(from: liveBuilder)
                    }
                    if let pending = self.pendingBlock {
                        self.beginBlock(id: pending.id, isInterval: pending.isInterval)
                    }

                    // The execution UUID allows later reconciliation on iPhone.
                    // A metadata error must not discard a live sensor recording.
                    do {
                        try await liveBuilder.addMetadata([
                            HKMetadataKeyExternalUUID: id.uuidString,
                            HKMetadataKeyWorkoutBrandName: "Repera",
                            "ReperaActivityType": String(activityType.rawValue)
                        ])
                    } catch {
                        if self.workoutID == id {
                            self.permissionIssue = "Salud registra el entreno, pero no pudo enlazarlo: \(error.localizedDescription)"
                        }
                    }
                } catch {
                    guard self.workoutID == id, self.builder === liveBuilder else { return }
                    self.permissionIssue = error.localizedDescription
                    liveBuilder.discardWorkout()
                    session.end()
                    self.workout = nil
                    self.builder = nil
                    self.routeBuilder = nil
                    self.recordsRoute = false
                    self.isRecording = false
                }
            } catch {
                if self.workoutID == id { self.permissionIssue = error.localizedDescription }
            }
        }
    }

    /// La distancia GPS ya filtrada por el registrador se utiliza únicamente
    /// cuando HealthKit no capturó su propio acumulado de distancia.
    func updateRecordedRouteDistance(_ meters: Double) {
        guard recordsRoute, meters.isFinite, meters >= 0 else { return }
        recordedRouteDistanceMeters = max(recordedRouteDistanceMeters, meters)
    }

    /// Alimenta el `HKWorkoutRouteBuilder` con fixes GPS del hub (outdoor).
    func appendRouteLocations(_ locations: [CLLocation]) {
        guard recordsRoute, !finishing else { return }
        let accepted = locations.filter {
            $0.horizontalAccuracy >= 0 && $0.horizontalAccuracy < 50
        }
        guard !accepted.isEmpty else { return }
        pendingRouteLocations.append(contentsOf: accepted)
        scheduleRouteDrain()
    }

    private func prepareRouteBuilder(from liveBuilder: HKLiveWorkoutBuilder) {
        if let series = liveBuilder.seriesBuilder(for: HKSeriesType.workoutRoute())
            as? HKWorkoutRouteBuilder {
            routeBuilder = series
        } else {
            routeBuilder = HKWorkoutRouteBuilder(healthStore: store, device: .local())
        }
        scheduleRouteDrain()
    }

    private func scheduleRouteDrain() {
        guard routeBuilder != nil, !pendingRouteLocations.isEmpty else { return }
        guard routeInsertTask == nil else { return }
        routeInsertTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.routeInsertTask = nil }
            while !self.pendingRouteLocations.isEmpty {
                guard let builder = self.routeBuilder else { break }
                let batch = Array(self.pendingRouteLocations.prefix(40))
                self.pendingRouteLocations.removeFirst(batch.count)
                do {
                    try await builder.insertRouteData(batch)
                } catch {
                    // Conservar puntos locales en el hub; no inventar ruta en Salud.
                    break
                }
            }
            if !self.pendingRouteLocations.isEmpty, self.routeBuilder != nil {
                self.scheduleRouteDrain()
            }
        }
    }

    /// Only request state changes that HealthKit can actually perform.
    /// In particular, the builder is already Running after startActivity,
    /// so tapping "Iniciar bloque" must NOT resume it again.
    func pause() {
        guard !finishing, let workout, workout.state == .running,
              pendingStateTransition != .paused else { return }
        pendingStateTransition = .paused
        workout.pause()
    }

    func resume() {
        guard !finishing, let workout, workout.state == .paused,
              pendingStateTransition != .running else { return }
        pendingStateTransition = .running
        workout.resume()
    }

    /// Descarta la sesión HealthKit sin guardar (cancelación desde iPhone o Watch).
    func discard() {
        finishing = false
        finishHandler = nil
        if let liveBuilder = builder {
            liveBuilder.discardWorkout()
        }
        workout?.end()
        workout = nil
        builder = nil
        routeBuilder = nil
        recordsRoute = false
        recordedRouteDistanceMeters = 0
        pendingRouteLocations = []
        routeInsertTask?.cancel()
        routeInsertTask = nil
        workoutID = nil
        lastRecordedBlockID = nil
        pendingBlock = nil
        pendingStateTransition = nil
        isRecording = false
        hasUnlinkedRecovery = false
        pulseBpm = nil
        kcal = nil
        averageBpm = nil
        onMetricsUpdated?()
    }

    func finish(_ callback: @escaping (Result) -> Void) {
        guard !finishing else { return }
        finishing = true
        finishHandler = callback
        guard let workout else {
            finishWith(Result())
            return
        }
        workout.stopActivity(with: Date())
        // Wait for didChangeTo(.stopped) so the final Health samples are included.
    }

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState, date: Date
    ) {
        // HealthKit delegates run off the MainActor. Send only value-type
        // snapshots across the boundary (not the non-Sendable session object).
        let identity = ObjectIdentifier(workoutSession)
        let stateStillMatches = workoutSession.state == toState
        Task { @MainActor in
            guard self.workout.map({ ObjectIdentifier($0) }) == identity else { return }
            if toState == .running || toState == .paused {
                guard stateStillMatches else { return }
            }
            self.pendingStateTransition = nil
            switch toState {
            case .paused:
                self.onPauseStateChanged?(true)
            case .running:
                if let pending = self.pendingBlock {
                    self.beginBlock(id: pending.id, isInterval: pending.isInterval)
                }
                self.onPauseStateChanged?(false)
            case .stopped:
                self.endBuilder(at: date)
            default:
                break
            }
        }
    }

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent
    ) {
        guard event.type == .pauseOrResumeRequest else { return }
        Task { @MainActor in self.onPauseResumeRequest?() }
    }

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession, didFailWithError error: any Error
    ) {
        let message = error.localizedDescription
        Task { @MainActor in
            self.permissionIssue = message
            if self.finishing { self.finishWith(Result()) }
            else {
                self.workout = nil
                self.builder = nil
                self.isRecording = false
            }
        }
    }

    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        let heart = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let unit = HKUnit.count().unitDivided(by: .minute())
        // HKLiveWorkoutBuilder also calls this delegate for energy/distance.
        // Do not treat an old cached HR statistic as a newly collected sample.
        let gotHeartSample = collectedTypes.contains(heart)
        let bpm = gotHeartSample
            ? workoutBuilder.statistics(for: heart)?.mostRecentQuantity()?.doubleValue(for: unit)
            : nil
        let average = gotHeartSample
            ? workoutBuilder.statistics(for: heart)?.averageQuantity()?.doubleValue(for: unit)
            : nil
        let active = workoutBuilder.statistics(for: energy)?.sumQuantity()?.doubleValue(for: .kilocalorie())
        let identity = ObjectIdentifier(workoutBuilder)
        Task { @MainActor in
            guard self.builder.map({ ObjectIdentifier($0) }) == identity else { return }
            if let bpm, bpm.isFinite, (25...250).contains(bpm) {
                self.pulseBpm = Int(bpm.rounded())
                self.pulseCapturedAt = Date()
            }
            if let average, average.isFinite, average > 0 { self.averageBpm = average }
            // Incluir 0: el indicador del Watch debe reflejar la suma real del builder.
            if let active, active.isFinite, active >= 0 { self.kcal = active }
            self.onMetricsUpdated?()
        }
    }

    /// Activa explícitamente FC y energía activa: algunos tipos (p. ej. crossTraining)
    /// no siempre las incluyen por defecto en el data source. Outdoor también
    /// pide distancia para que Fitness muestre km junto a la ruta.
    private static func makeLiveDataSource(
        store: HKHealthStore, configuration: HKWorkoutConfiguration, outdoor: Bool
    ) -> HKLiveWorkoutDataSource {
        let dataSource = HKLiveWorkoutDataSource(
            healthStore: store, workoutConfiguration: configuration
        )
        if let heart = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            dataSource.enableCollection(for: heart, predicate: nil)
        }
        if let energy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            dataSource.enableCollection(for: energy, predicate: nil)
        }
        if outdoor {
            let distanceIDs: [HKQuantityTypeIdentifier] = [
                .distanceWalkingRunning, .distanceCycling, .distanceSwimming,
                .distanceDownhillSnowSports
            ]
            for id in distanceIDs {
                if let distance = HKQuantityType.quantityType(forIdentifier: id) {
                    dataSource.enableCollection(for: distance, predicate: nil)
                }
            }
        }
        return dataSource
    }

    /// Un mapa GPS no implica que Fitness tenga la distancia numérica.
    /// Es esencial un tipo específico para que la actividad tenga ritmo.
    private static func routeDistanceType(for activity: HKWorkoutActivityType) -> HKQuantityType? {
        let identifier: HKQuantityTypeIdentifier
        switch activity {
        case .walking, .running, .hiking:
            identifier = .distanceWalkingRunning
        case .cycling:
            identifier = .distanceCycling
        case .downhillSkiing, .snowboarding, .crossCountrySkiing:
            identifier = .distanceDownhillSnowSports
        case .swimming:
            identifier = .distanceSwimming
        default:
            return nil
        }
        return HKQuantityType.quantityType(forIdentifier: identifier)
    }

    private func seedMetricsFromBuilder(_ liveBuilder: HKLiveWorkoutBuilder) {
        let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let heart = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let hrUnit = HKUnit.count().unitDivided(by: .minute())
        if let active = liveBuilder.statistics(for: energy)?
            .sumQuantity()?.doubleValue(for: .kilocalorie()),
           active.isFinite, active >= 0 {
            kcal = active
        }
        if let average = liveBuilder.statistics(for: heart)?
            .averageQuantity()?.doubleValue(for: hrUnit),
           average.isFinite, average > 0 {
            averageBpm = average
        }
        onMetricsUpdated?()
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    private func endBuilder(at date: Date) {
        guard let builder else { finishWith(Result()); return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            // La ruta se graba como HKWorkoutRoute, pero esa serie NO rellena
            // automáticamente la distancia del HKWorkout. Si el reloj no produjo
            // distancia nativa, adjuntar los metros GPS reales antes de cerrarlo.
            // No sumar ni sustituir un valor válido de los sensores.
            if self.recordsRoute, self.recordedRouteDistanceMeters >= 20,
               let activity = self.workout?.workoutConfiguration.activityType,
               let type = Self.routeDistanceType(for: activity) {
                let native = builder.statistics(for: type)?
                    .sumQuantity()?.doubleValue(for: .meter()) ?? 0
                if native <= 0 {
                    let start = self.workout?.startDate ?? date.addingTimeInterval(-1)
                    let sample = HKQuantitySample(
                        type: type,
                        quantity: HKQuantity(unit: .meter(), doubleValue: self.recordedRouteDistanceMeters),
                        start: min(start, date.addingTimeInterval(-1)),
                        end: date,
                        metadata: ["ReperaDistanceSource": "recordedGPS"]
                    )
                    do {
                        try await builder.addSamples([sample])
                    } catch {
                        self.permissionIssue = "No se pudo incluir la distancia GPS en Salud: \(error.localizedDescription)"
                    }
                }
            }
            do {
                try await builder.endCollection(at: date)
            } catch {
                self.permissionIssue = error.localizedDescription
                self.finishWith(Result())
                return
            }

            do {
                // A nil workout without an error is valid while the Watch is locked.
                // Repera preserves the pending UUID and reconciles it later.
                let saved = try await builder.finishWorkout()
                if let insert = self.routeInsertTask { await insert.value }
                if let saved, let route = self.routeBuilder {
                    do {
                        if !self.pendingRouteLocations.isEmpty {
                            try await route.insertRouteData(self.pendingRouteLocations)
                            self.pendingRouteLocations = []
                        }
                        _ = try await route.finishRoute(with: saved, metadata: nil)
                    } catch {
                        // Ruta local del hub se conserva; Fitness sin mapa si Salud niega.
                    }
                }
                self.routeBuilder = nil
                let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
                let hrType = HKObjectType.quantityType(forIdentifier: .heartRate)!
                let hrUnit = HKUnit.count().unitDivided(by: .minute())
                // Prefer finished/live statistics; then legacy totalEnergyBurned
                // (KVC: property deprecated on watchOS 11 but still populated when
                // statistics are empty); finally the live session accumulator.
                let legacyTotal = (saved?.value(forKey: "totalEnergyBurned") as? HKQuantity)?
                    .doubleValue(for: .kilocalorie())
                // Una estadística 0 provisional no debe ocultar una medición
                // positiva guardada en el valor legacy o en el acumulador vivo.
                let energyCandidates: [Double] = [
                    saved?.statistics(for: energyType)?.sumQuantity()?.doubleValue(for: .kilocalorie()),
                    builder.statistics(for: energyType)?.sumQuantity()?.doubleValue(for: .kilocalorie()),
                    legacyTotal,
                    self.kcal
                ].compactMap { $0 }.filter { $0.isFinite && $0 >= 0 }
                let active = energyCandidates.first(where: { $0 > 0 }) ?? energyCandidates.first
                let average = saved?.statistics(for: hrType)?.averageQuantity()?.doubleValue(for: hrUnit)
                    ?? builder.statistics(for: hrType)?.averageQuantity()?.doubleValue(for: hrUnit)
                    ?? self.averageBpm
                if let active, active.isFinite, active >= 0 { self.kcal = active }
                self.finishWith(Result(
                    uuid: saved?.uuid,
                    activeEnergyKcal: (active ?? 0) > 0 ? active : nil,
                    durationSeconds: saved?.duration,
                    start: saved?.startDate,
                    end: saved?.endDate,
                    averageHeartRateBpm: average
                ))
            } catch {
                self.permissionIssue = error.localizedDescription
                self.finishWith(Result())
            }
        }
    }

    private func finishWith(_ result: Result) {
        workout?.end()
        workout = nil
        builder = nil
        routeBuilder = nil
        recordsRoute = false
        recordedRouteDistanceMeters = 0
        pendingRouteLocations = []
        routeInsertTask?.cancel()
        routeInsertTask = nil
        workoutID = nil
        lastRecordedBlockID = nil
        pendingBlock = nil
        pendingStateTransition = nil
        isRecording = false
        hasUnlinkedRecovery = false
        finishing = false
        let callback = finishHandler
        finishHandler = nil
        callback?(result)
    }
}
