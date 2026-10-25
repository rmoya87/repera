import Foundation
import ReperaDomain
import Observation
import WatchConnectivity

@Observable
@MainActor
final class ReperaStore: NSObject {
    var state: AppState
    var isWatchReachable = false
    var iCloudStatus: ICloudStatus = .temporarilyUnavailable
    var syncPhase: AppSyncPhase = .loadingLocal
    var isSyncingiCloud = false
    var lastiCloudSyncMessage: String?
    /// True until the first remote recovery attempt finishes (success, offline, or waiting).
    private(set) var didCompleteInitialRemoteSync = false
    /// Disk/catalog hydrated after first SwiftUI frame (LaunchScreen can dismiss immediately).
    private(set) var isHydrated = false
    /// Blocks remote uploads until recovery knows the cloud document is ready or absent.
    private var allowRemoteUpload = false
    /// exerciseId → progression reason for the active session
    var progressionReasons: [UUID: String] = [:]
    var lastImportSummary: String?
    /// Rest between sets — owned by the store so leaving WorkoutView does not cancel it.
    let restCoordinator = RestSessionCoordinator()
    /// WOD / block clock — wall-clock; survives WorkoutView disappear.
    let workoutClock = WorkoutClockCoordinator()
    /// Expensive StatsEngine results keyed by sync revision.
    let statsCache = DerivedStatsCache()

    /// Fine-grained Observation tokens (views can key `.task(id:)` / onChange without full `state`).
    private(set) var catalogEpoch: UInt64 = 0
    private(set) var workoutsEpoch: UInt64 = 0
    private(set) var sessionEpoch: UInt64 = 0
    /// Tab chrome — Equatable; only publishes when title / progress / thumb / presence change.
    private(set) var hasActiveSession = false
    private(set) var continueAccessory: ContinueAccessoryModel?
    /// Valoración post-entreno pendiente de mostrar (sheet tras Terminar / Apuntar).
    var pendingSessionReview: SessionReview?
    var pendingReviewedSessionId: UUID?

    /// Política comercial inyectada desde `SubscriptionManager` (no persiste en AppState).
    @ObservationIgnored
    var featureAccess: (() -> FeatureAccessPolicy)?

    /// Última denegación al crear rutina/ejercicio (para que la UI muestre paywall).
    private(set) var lastAccessDenial: FeatureAccessDecision?

    private let store = LocalStore.shared
    private let connectivity = PhoneConnectivity()
    private var watchPushTask: Task<Void, Never>?
    @ObservationIgnored private var watchPlanObserver: NSObjectProtocol?
    /// Last durable Watch result acknowledged back to the watch.
    private var lastWatchAcknowledgedSession: UUID?

    func bumpCatalogEpoch() { catalogEpoch &+= 1 }

    /// Reenvía al reloj el contexto de sesión tras una corrección del catálogo.
    func notifyCatalogChangedForWatch() { pushActiveToWatch(immediate: true) }
    func bumpWorkoutsEpoch() { workoutsEpoch &+= 1; statsCache.invalidate() }
    func bumpSessionEpoch() { sessionEpoch &+= 1 }

    var controller: SessionController? {
        guard let active = state.activeSession else { return nil }
        return SessionController(session: active)
    }

    override init() {
        // Same idea as HealthDiskCache: paint Repera workouts on first frame (not after hydrate).
        if let painted = LaunchWarmup.appStateForFirstPaint() {
            state = painted
            isHydrated = true
            catalogEpoch = 1
            workoutsEpoch = 1
            sessionEpoch = 1
            syncPhase = .awaitingRemote
            LaunchTiming.mark("ReperaStore.init(diskPaint workouts=\(painted.workouts.count))")
        } else {
            state = LocalStore.shared.emptyShellState()
            syncPhase = .loadingLocal
            LaunchTiming.mark("ReperaStore.init(shell)")
        }
        super.init()
        publishSessionChrome()
    }

    /// Confirm / refresh local JSON after first frame. If init already painted from disk, this is cheap (warm cache).
    func hydrateFromDisk() async {
        let t0 = CFAbsoluteTimeGetCurrent()
        LaunchTiming.mark("hydrate.start")
        let loaded = await store.loadLocalOnlyAsync()
        let hadPaint = isHydrated
        let changed = !hadPaint
            || loaded.syncRevision != state.syncRevision
            || loaded.workouts.count != state.workouts.count
            || loaded.exercises.count != state.exercises.count
        state = loaded
        iCloudStatus = store.iCloudStatus
        syncPhase = store.syncPhase
        isHydrated = true
        if changed {
            catalogEpoch &+= 1
            workoutsEpoch &+= 1
            sessionEpoch &+= 1
        }
        publishSessionChrome()
        sendWatchContextNow()
        LaunchTiming.span(hadPaint ? "hydrate.disk(confirm)" : "hydrate.disk", from: t0)

        // First install: fill seed in background after Home is already visible.
        if state.exercises.isEmpty {
            Task(priority: .userInitiated) { @MainActor in
                let tSeed = CFAbsoluteTimeGetCurrent()
                let seed = await store.buildSeedCatalogAsync()
                if state.exercises.isEmpty {
                    state.exercises = seed
                    state.updatedAt = Date()
                    catalogEpoch &+= 1
                    persistLocalOnly(immediate: true)
                }
                LaunchTiming.span("hydrate.seed", from: tSeed)
            }
        }
    }

    func bootstrap() {
        if watchPlanObserver == nil {
            watchPlanObserver = NotificationCenter.default.addObserver(
                forName: Notification.Name("repera.professionalPlansChanged"),
                object: nil, queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in self?.pushActiveToWatch(immediate: true) }
            }
        }
        connectivity.delegate = self
        connectivity.activate()
        isWatchReachable = WCSession.default.isReachable
        // Catalog merges + iCloud after hydrate — never on the LaunchScreen path.
        Task(priority: .utility) { @MainActor in
            await Task.yield()
            let t0 = CFAbsoluteTimeGetCurrent()
            let seed = await store.buildSeedCatalogAsync()
            let current = state.exercises
            let merged = await Task.detached(priority: .utility) {
                Self.mergeCatalogOffMain(current: current, seed: seed)
            }.value
            var dirty = false
            dirty = stripSeededDemoPlanIfNeeded() || dirty
            if merged.changed {
                state.exercises = merged.exercises
                state.updatedAt = Date()
                dirty = true
            }
            dirty = dedupeBodyWeightsByDay() || dirty
            dirty = relinkOrphanSessionExercisesToCatalog() || dirty
            if dirty {
                catalogEpoch &+= 1
                // Local only until iCloud recovery completes — never upload seed over undownloaded cloud.
                persistLocalOnly(immediate: true)
            }
            LaunchTiming.span("bootstrap.catalogMerge", from: t0)
            await completeInitialRemoteSync()
            await reconcileWatchHealthMetrics()
            await recalculateStoredSessionKcalIfNeeded()
            refreshSessionReviewsIfNeeded()
        }
    }

    private static let sessionKcalRecalcDefaultsKey = "repera.recalcSessionKcal.v2026_10_22_health_only"

    /// Depura las kcal estimadas de versiones anteriores. Solo conserva valores
    /// corroborados por un HKWorkout externo (Watch / Apple Salud / otra app).
    @MainActor
    private func recalculateStoredSessionKcalIfNeeded() async {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Self.sessionKcalRecalcDefaultsKey) else { return }
        guard !state.workouts.isEmpty else {
            defaults.set(true, forKey: Self.sessionKcalRecalcDefaultsKey)
            return
        }

        var changed = false
        let health = HealthKitStore.shared
        for i in state.workouts.indices {
            var session = state.workouts[i]
            let verified: Double?
            if let uuid = session.healthKitWorkoutUUID {
                let fromHealth = await health.externalWorkoutEnergyKcal(uuid: uuid)
                // Apple Health sync from Watch to iPhone can lag behind WatchConnectivity.
                // Keep real Watch HK measurements while the iPhone awaits its HK sample.
                verified = fromHealth ?? (
                    session.appleHealthProvenance == "watchHealthKit"
                        ? session.appleActiveEnergyKcal : nil
                )
            } else {
                verified = nil
            }

            let start = session.startedAt
                ?? session.finishedAt?.addingTimeInterval(-60 * 60)
                ?? Date().addingTimeInterval(-60 * 60)
            let end = max(
                session.finishedAt ?? start.addingTimeInterval(60),
                start.addingTimeInterval(60)
            )
            let wallSeconds = max(60, end.timeIntervalSince(start))
            let duration = session.appleHealthProvenance == "watchHealthKit"
                ? (session.appleDurationSeconds ?? wallSeconds) : wallSeconds
            if session.appleActiveEnergyKcal != verified
                || abs((session.appleDurationSeconds ?? 0) - duration) >= 1 {
                session.appleActiveEnergyKcal = verified
                session.appleDurationSeconds = duration
                state.workouts[i] = session
                changed = true
            }
        }

        defaults.set(true, forKey: Self.sessionKcalRecalcDefaultsKey)
        if changed {
            state.updatedAt = Date()
            persistWorkouts(immediate: true)
        }
    }

    /// Suma de time caps por bloque (EMOM 12 + EMOM 8 + AMRAP 12 → 32).
    private func programmedWODMinutes(_ session: WorkoutSession) -> Double? {
        var seen = Set<UUID>()
        var sum = 0
        for ex in session.exercises {
            guard let blockId = ex.blockId, seen.insert(blockId).inserted else { continue }
            guard let cap = ex.blockTimeCapMinutes, cap > 0 else { continue }
            sum += cap
        }
        return sum > 0 ? Double(sum) : nil
    }

    /// Enrich + append missing seed rows off the MainActor (string compares over hundreds of exercises).
    nonisolated private static func mergeCatalogOffMain(
        current: [Exercise],
        seed: [Exercise]
    ) -> (exercises: [Exercise], changed: Bool) {
        let seedByName = Dictionary(uniqueKeysWithValues: seed.map { ($0.name, $0) })
        var exercises = current
        var changed = false
        for i in exercises.indices {
            guard !exercises[i].isCustom,
                  let fresh = seedByName[SportExerciseNames.canonicalName(exercises[i].name)]
            else { continue }
            let staleName = exercises[i].name != fresh.name
            let staleMeta = exercises[i].instructions.isEmpty
                || exercises[i].catalogId == nil
                || exercises[i].detailDescription != fresh.detailDescription
                || exercises[i].instructions != fresh.instructions
            let staleGroup = exercises[i].muscleGroup != fresh.muscleGroup
                || exercises[i].equipment != fresh.equipment
                || exercises[i].sportTag != fresh.sportTag
            guard staleName || staleMeta || staleGroup else { continue }
            let fav = exercises[i].isFavorite
            let id = exercises[i].id
            exercises[i] = Exercise(
                id: id,
                name: fresh.name,
                muscleGroup: fresh.muscleGroup,
                equipment: fresh.equipment,
                isCustom: false,
                catalogId: fresh.catalogId,
                targetMuscle: fresh.targetMuscle,
                secondaryMuscles: fresh.secondaryMuscles,
                bodyPart: fresh.bodyPart,
                detailDescription: fresh.detailDescription,
                instructions: fresh.instructions,
                primaryRegions: fresh.primaryRegions,
                secondaryRegions: fresh.secondaryRegions,
                isFavorite: fav,
                sportTag: fresh.sportTag
            )
            changed = true
        }
        let existing = Set(exercises.map { SportExerciseNames.canonicalName($0.name) })
        let missing = seed.filter { !existing.contains($0.name) }
        if !missing.isEmpty {
            exercises.append(contentsOf: missing)
            changed = true
        }
        return (exercises, changed)
    }

    /// Enrich + missing seed in one pass (iCloud adopt path).
    @discardableResult
    private func enrichCatalogMetadata() -> Bool {
        let result = Self.mergeCatalogOffMain(current: state.exercises, seed: Catalog.seed())
        guard result.changed else { return false }
        state.exercises = result.exercises
        state.updatedAt = Date()
        return true
    }

    /// Quita el plan Push/Pull/Legs de demo si el usuario no ha creado nada propio.
    @discardableResult
    private func stripSeededDemoPlanIfNeeded() -> Bool {
        let demoTitles: Set<String> = ["Push", "Pull", "Legs", "Push 2", "Pull 2"]
        guard !state.routines.isEmpty,
              state.routines.allSatisfy({ demoTitles.contains($0.title) })
        else { return false }
        state.routines = []
        state.updatedAt = Date()
        return true
    }

    // MARK: - Persistence

    /// Durable local write. Remote mirror only after initial recovery allows uploads.
    /// - Parameter touchWorkouts: bump Home/Historial epochs + Salud exclusion filter.
    ///   Leave `false` for series logging / settings / plan so Inicio no rebuilds on each set.
    func persist(immediate: Bool = true, touchWorkouts: Bool = false) {
        store.stampForPersist(&state, bumpRevision: true)
        store.persistLocal(state, immediate: immediate)
        iCloudStatus = store.iCloudStatus
        syncPhase = store.syncPhase
        if touchWorkouts {
            workoutsEpoch &+= 1
            statsCache.invalidate()
            HealthKitStore.shared.invalidateExternalActivityFilter(reason: "workouts")
            scheduleHealthActivitiesResync()
        }
        sessionEpoch &+= 1
        if allowRemoteUpload {
            let snapshot = state
            Task { await store.pushToiCloudIfSafe(snapshot) }
        }
    }

    /// Persist + notify Home/Historial/Salud that the finished-workout list changed.
    private func persistWorkouts(immediate: Bool = true) {
        persist(immediate: immediate, touchWorkouts: true)
    }

    /// After Repera workout list changes, refresh Salud activities with the new exclusion set.
    private func scheduleHealthActivitiesResync() {
        let linked = Set(state.workouts.compactMap(\.healthKitWorkoutUUID))
        let sessions = state.workouts
        Task(priority: .utility) { @MainActor in
            let health = HealthKitStore.shared
            guard health.isAvailable else { return }
            await health.refreshRecentExternalActivities(
                excludingUUIDs: linked,
                overlappingSessions: sessions,
                days: 180
            )
        }
    }

    func cachedPersonalRecords(
        from workouts: [WorkoutSession],
        rangeRaw: String,
        mondayFirst: Bool
    ) -> [PersonalRecord] {
        let key = DerivedStatsCache.Key(
            revision: state.syncRevision,
            rangeRaw: rangeRaw,
            mondayFirst: mondayFirst,
            workoutCount: workouts.count
        )
        return statsCache.personalRecords(key: key) {
            StatsEngine.personalRecords(from: workouts)
        }
    }

    func cachedHistory(for exerciseId: UUID) -> ExerciseHistorySummary {
        statsCache.history(exerciseId: exerciseId, revision: state.syncRevision) {
            StatsEngine.history(for: exerciseId, workouts: state.workouts, catalog: state.exercises)
        }
    }

    func cachedLastWorkingSession(for exerciseId: UUID) -> ExerciseLastSession? {
        statsCache.lastSession(exerciseId: exerciseId, revision: state.syncRevision) {
            StatsEngine.lastWorkingSession(
                for: exerciseId,
                workouts: state.workouts,
                catalog: state.exercises
            )
        }
    }

    func cachedLastWorkingWeight(for exerciseId: UUID) -> Double? {
        statsCache.lastWorkingWeight(exerciseId: exerciseId, revision: state.syncRevision) {
            StatsEngine.lastWorkingWeight(
                exerciseId: exerciseId,
                workouts: state.workouts,
                catalog: state.exercises
            )
        }
    }

    /// Resuelve un id de sesión (a veces UUID huérfano de WOD/pizarra) al ejercicio de catálogo.
    func resolvedCatalogExercise(id: UUID) -> Exercise? {
        if let hit = state.exercises.first(where: { $0.id == id }) { return hit }
        guard let snap = state.workouts
            .lazy
            .flatMap(\.exercises)
            .map(\.exercise)
            .first(where: { $0.id == id })
        else { return nil }
        if let match = state.exercises.first(where: {
            ExerciseEquivalence.matchesCatalogIdentity($0, snap)
        }) {
            return match
        }
        return snap
    }

    /// Reescribe en entrenos guardados el Exercise de catálogo cuando el id embebido no está en la librería.
    @discardableResult
    func relinkOrphanSessionExercisesToCatalog() -> Bool {
        var changed = false
        for wi in state.workouts.indices {
            for ei in state.workouts[wi].exercises.indices {
                let snap = state.workouts[wi].exercises[ei].exercise
                if state.exercises.contains(where: { $0.id == snap.id }) { continue }
                guard let match = state.exercises.first(where: {
                    ExerciseEquivalence.matchesCatalogIdentity($0, snap)
                }) else { continue }
                state.workouts[wi].exercises[ei].exercise = match
                changed = true
            }
        }
        if let active = state.activeSession {
            var session = active
            var activeChanged = false
            for ei in session.exercises.indices {
                let snap = session.exercises[ei].exercise
                if state.exercises.contains(where: { $0.id == snap.id }) { continue }
                guard let match = state.exercises.first(where: {
                    ExerciseEquivalence.matchesCatalogIdentity($0, snap)
                }) else { continue }
                session.exercises[ei].exercise = match
                activeChanged = true
            }
            if activeChanged {
                state.activeSession = session
                changed = true
            }
        }
        return changed
    }

    func cachedPersonalRecordCount(in session: WorkoutSession) -> Int {
        cachedPersonalRecordCountsBySession()[session.id] ?? 0
    }

    /// Mapa sesión→nº PRs (un pase; Historial no paga O(n²) por fila).
    func cachedPersonalRecordCountsBySession() -> [UUID: Int] {
        statsCache.personalRecordCountsBySession(revision: state.syncRevision) {
            StatsEngine.personalRecordCountsBySessionId(workouts: state.workouts)
        }
    }

    /// Local disk only — used during bootstrap before remote recovery.
    func persistLocalOnly(immediate: Bool = true) {
        store.stampForPersist(&state, bumpRevision: true)
        store.persistLocal(state, immediate: immediate)
        syncPhase = store.syncPhase
    }

    func completeInitialRemoteSync() async {
        await refreshFromiCloud(isInitial: true)
        await RemoteExerciseCatalogStore.shared.restoreCached(to: self)
        didCompleteInitialRemoteSync = true
    }

    /// Retries cloud stub download without blocking first paint.
    private func scheduleCloudDownloadRetry() {
        Task(priority: .utility) { @MainActor in
            for _ in 0..<10 {
                try? await Task.sleep(nanoseconds: 400_000_000)
                if allowRemoteUpload { return }
                if syncPhase == .ready || syncPhase == .offline || syncPhase == .recoveringCorrupt {
                    return
                }
                await refreshFromiCloud(isInitial: false)
                if allowRemoteUpload || syncPhase == .ready { return }
            }
        }
    }

    func refreshFromiCloud(isInitial: Bool = false) async {
        isSyncingiCloud = true
        defer { isSyncingiCloud = false }
        await store.refreshICloudStatusAsync()
        iCloudStatus = store.iCloudStatus
        syncPhase = .awaitingRemote

        guard iCloudStatus == .available else {
            allowRemoteUpload = iCloudStatus != .temporarilyUnavailable
            syncPhase = iCloudStatus == .signedOut ? .offline : .offline
            lastiCloudSyncMessage = iCloudStatus == .signedOut
                ? "Inicia sesión en iCloud"
                : "iCloud no disponible aún"
            // Offline: keep local; do not invent a remote upload.
            if iCloudStatus == .signedOut {
                allowRemoteUpload = true
            }
            return
        }

        let outcome = await store.recoverFromiCloud(local: state)
        syncPhase = store.syncPhase
        iCloudStatus = store.iCloudStatus

        switch outcome {
        case .adoptedRemote(let remote):
            state = remote
            stripSeededDemoPlanIfNeeded()
            _ = enrichCatalogMetadata()
            _ = relinkOrphanSessionExercisesToCatalog()
            // Metadata merges stay local until the next user edit bumps revision.
            store.persistLocal(state, immediate: true)
            catalogEpoch &+= 1
            workoutsEpoch &+= 1
            publishSessionChrome()
            allowRemoteUpload = true
            lastiCloudSyncMessage = "Datos restaurados desde iCloud"
        case .keptLocal(let shouldUpload):
            allowRemoteUpload = true
            if shouldUpload {
                await store.pushToiCloudIfSafe(state)
                lastiCloudSyncMessage = "Copia en iCloud actualizada"
            } else {
                lastiCloudSyncMessage = "Usando copia local"
            }
        case .noRemoteDocument:
            // True first install (or empty container): safe to upload local seed/catalog.
            allowRemoteUpload = true
            await store.pushToiCloudIfSafe(state)
            lastiCloudSyncMessage = isInitial
                ? "Primera copia subida a iCloud"
                : "Copia en iCloud actualizada"
            syncPhase = .ready
        case .waitingForDownload:
            allowRemoteUpload = false
            lastiCloudSyncMessage = "Descargando datos de iCloud…"
            syncPhase = .awaitingRemote
            if isInitial {
                scheduleCloudDownloadRetry()
            }
        case .corruptRemote:
            allowRemoteUpload = false
            lastiCloudSyncMessage = "Documento iCloud ilegible; no se sobrescribe"
            syncPhase = .recoveringCorrupt
        case .unavailable(let status):
            allowRemoteUpload = status == .signedOut
            iCloudStatus = status
            syncPhase = .offline
            lastiCloudSyncMessage = status == .signedOut
                ? "Inicia sesión en iCloud"
                : "iCloud no disponible aún"
        }
    }

    /// Borra entrenos, rutinas y peso; mantiene el catálogo de ejercicios.
    func resetUserData() {
        state = AppState(
            exercises: state.exercises,
            routines: [],
            workouts: [],
            bodyWeights: [],
            activeSession: nil,
            updatedAt: Date()
        )
        progressionReasons = [:]
        persistWorkouts()
        pushActiveToWatch(immediate: true)
    }

    // MARK: - Plan / today

    func routineForToday(date: Date = Date()) -> Routine? {
        if state.settings.scheduleMode == .rotation {
            return RotationEngine.nextRoutine(state: state)
        }
        return routineForDay(date)
    }

    /// Entreno del día: suelto (fecha) tiene prioridad sobre el plan semanal (weekday).
    func routineForDay(_ date: Date, calendar: Calendar = .current) -> Routine? {
        let dayStart = calendar.startOfDay(for: date)
        if let oneOff = state.routines.first(where: { routine in
            guard let scheduled = routine.scheduledDate else { return false }
            return calendar.isDate(scheduled, inSameDayAs: dayStart)
        }) {
            return oneOff
        }
        let iso = CalendarHelpers.isoWeekday(for: date, calendar: calendar)
        return state.routines.first { $0.scheduledDate == nil && $0.weekday == iso }
    }

    func startTodaySession() {
        guard let routine = routineForToday() else { return }
        startSession(from: routine)
    }

    func startSession(from routine: Routine) {
        guard !HealthKitStore.shared.isWatchWorkoutMirrored else {
            HealthKitStore.shared.lastError = "El Apple Watch ya está registrando un entrenamiento. Termínalo desde el reloj antes de iniciar otro."
            return
        }
        let base = SessionController.from(routine: routine, exercises: state.exercises)
        let allowAdvanced = featureAccess?().canAccess(.advancedStrengthProgression) ?? false
        let session: WorkoutSession
        if allowAdvanced {
            let applied = ProgressionEngine.applySuggestions(
                to: base,
                routine: routine,
                workouts: state.workouts,
                defaultPolicy: state.settings.defaultProgression,
                incrementKg: state.settings.weightIncrementKg
            )
            progressionReasons = applied.1
            session = applied.0
        } else {
            progressionReasons = [:]
            session = base
        }
        var ctrl = SessionController(session: session)
        ctrl.startOnPhone()
        state.activeSession = ctrl.session
        persist()
        pushActiveToWatch(immediate: true)
        beginHealthTracking(for: ctrl.session)
        beginLocationTracking(for: ctrl.session)
    }

    /// Sesión freestyle desde OCR de pizarra/TV (sin progresión).
    @discardableResult
    func startSessionFromBoard(
        lines: [BoardImportLine],
        ocrText: String? = nil,
        blocks: [RoutineBlock]? = nil
    ) -> Bool {
        guard !HealthKitStore.shared.isWatchWorkoutMirrored else {
            HealthKitStore.shared.lastError = "El Apple Watch ya está registrando un entrenamiento. Finalízalo primero desde el reloj."
            return false
        }
        // Si la revisión ya trae bloques (LiteParser), no re-parsear con BoardImportParser (cuelga la UI).
        var routine: Routine
        if let blocks, !blocks.isEmpty {
            routine = Routine(title: "Añadir entreno", weekday: nil, blocks: blocks, progression: .off)
            BoardScanLog.info("startSessionFromBoard: usando \(blocks.count) bloques del draft (sin re-parse)")
        } else {
            var catalog = state.exercises
            routine = BoardImportParser.buildRoutine(
                title: "Añadir entreno",
                lines: lines,
                catalog: &catalog,
                ocrText: ocrText
            )
            state.exercises = catalog
        }
        for i in routine.blocks.indices {
            routine.blocks[i].deriveEmomRoundsIfNeeded()
        }
        let movementCount = routine.blocks.reduce(0) { $0 + $1.movements.filter { !$0.isRest }.count }
        let hasWork = !routine.exercises.isEmpty || movementCount > 0 || routine.blocks.contains { !$0.exercises.isEmpty }
        BoardScanLog.info(
            "startSessionFromBoard: blocks=\(routine.blocks.count) movements=\(movementCount) "
                + "legacyExercises=\(routine.exercises.count) ocrChars=\(ocrText?.count ?? 0)"
        )
        guard hasWork else {
            BoardScanLog.error("startSessionFromBoard: sin trabajo usable — abortado en silencio antes")
            return false
        }
        let session = SessionController.from(routine: routine, exercises: state.exercises)
        BoardScanLog.info("session exercises=\(session.exercises.count)")
        guard !session.exercises.isEmpty else {
            BoardScanLog.error("SessionController.from produjo 0 ejercicios")
            return false
        }
        var ctrl = SessionController(session: session)
        ctrl.startOnPhone()
        progressionReasons = [:]
        state.activeSession = ctrl.session
        persist()
        pushActiveToWatch(immediate: true)
        beginHealthTracking(for: ctrl.session)
        beginLocationTracking(for: ctrl.session)
        return true
    }

    private func beginHealthTracking(for session: WorkoutSession) {
        let start = session.startedAt ?? Date()
        Task {
            await HealthKitStore.shared.beginWorkout(
                sessionId: session.id,
                title: session.title,
                start: start
            )
        }
    }

    private func beginLocationTracking(for session: WorkoutSession) {
        let sessionID = session.id
        let trackRoute = WorkoutLocationTracker.shouldTrackRoute(for: session)
        Task {
            let tracker = WorkoutLocationTracker.shared
            // Si aún no se pidió permiso, el modal del sistema sale aquí (Play / empezar).
            guard await tracker.ensureWhenInUseAuthorized() else { return }
            if let pin = await tracker.capturePin() {
                if var active = state.activeSession, active.id == sessionID,
                   active.locationPin == nil {
                    // Respetar cualquier pin elegido por el usuario, incluso
                    // uno sin nombre ni identificador de MapKit.
                    active.locationPin = pin
                    state.activeSession = active
                    persist()
                }
            }
            if trackRoute {
                tracker.startRouteTracking(sessionID: sessionID)
            }
        }
    }

    /// Guarda el OCR como entreno suelto de un día concreto (no entra en el plan semanal de Diario).
    @discardableResult
    func saveBoardToDay(
        weekday: Int,
        lines: [BoardImportLine],
        ocrText: String?,
        planName: String = "Entreno",
        blocks: [RoutineBlock]? = nil,
        onDate: Date? = nil
    ) -> Routine {
        let calendar = Calendar.current
        let date = calendar.startOfDay(for: onDate ?? Self.dateForISOWeekday(weekday))
        // Draft de revisión ya parseado (LiteParser): no volver a BoardImportParser (freeze en MainActor).
        var imported: Routine
        if let blocks, !blocks.isEmpty {
            imported = Routine(title: planName, weekday: nil, blocks: blocks, progression: .off)
            BoardScanLog.info("saveBoardToDay: usando \(blocks.count) bloques del draft (sin re-parse)")
        } else {
            var catalog = state.exercises
            imported = BoardImportParser.buildRoutine(
                title: planName,
                lines: lines,
                catalog: &catalog,
                ocrText: ocrText
            )
            state.exercises = catalog
        }
        for i in imported.blocks.indices {
            imported.blocks[i].deriveEmomRoundsIfNeeded()
        }
        imported.weekday = nil
        imported.scheduledDate = date
        let day = CalendarHelpers.weekdayName(CalendarHelpers.isoWeekday(for: date))
        imported.title = planName == "Entreno" || planName == "Mi plan"
            ? "Entreno · \(day)"
            : "\(planName) · \(day)"
        imported.isFavorite = false

        if let idx = state.routines.firstIndex(where: {
            guard let scheduled = $0.scheduledDate else { return false }
            return calendar.isDate(scheduled, inSameDayAs: date)
        }) {
            var existing = state.routines[idx]
            existing.blocks.append(contentsOf: imported.blocks)
            if existing.title.isEmpty { existing.title = imported.title }
            existing.scheduledDate = date
            existing.weekday = nil
            saveRoutine(existing)
            return existing
        } else {
            saveRoutine(imported)
            return imported
        }
    }

    /// Próxima fecha del calendario con ese weekday ISO (hoy si coincide).
    private static func dateForISOWeekday(_ iso: Int, from: Date = Date(), calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: from)
        for offset in 0..<7 {
            guard let d = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            if CalendarHelpers.isoWeekday(for: d, calendar: calendar) == iso { return d }
        }
        return start
    }

    func importCSV(_ text: String) -> CSVImportResult {
        let result = WorkoutCSVImporter.parse(csv: text, existingExercises: state.exercises)
        for exercise in result.createdExercises {
            if !state.exercises.contains(where: { $0.id == exercise.id }) {
                state.exercises.append(exercise)
            }
        }
        for workout in result.workouts {
            upsertWorkout(workout)
        }
        lastImportSummary =
            "\(result.source.rawValue): \(result.workouts.count) entrenos, \(result.matchedSets) series"
            + (result.createdExercises.isEmpty ? "" : ", \(result.createdExercises.count) ejercicios nuevos")
        persistWorkouts()
        return result
    }

    func endActiveSession(save: Bool = true) {
        guard var session = state.activeSession else { return }
        let finishedRoutineId = session.routineId
        if session.phase != .finished {
            var ctrl = SessionController(session: session)
            ctrl.finishWorkout()
            session = ctrl.session
        }
        let start = session.startedAt ?? Date()
        let end = session.finishedAt ?? Date()
        restCoordinator.endForSessionClose()
        state.activeSession = nil
        persist()
        pushActiveToWatch(immediate: true)

        if save {
            let routePoints = WorkoutLocationTracker.shared.stopRouteTracking()
            if !routePoints.isEmpty {
                session.routePoints = routePoints
            }
            // Hasta que Apple Salud confirme una medición, las kcal son desconocidas.
            session.appleActiveEnergyKcal = nil
            session.appleDurationSeconds = max(60, end.timeIntervalSince(start))
            attachSessionReview(&session, present: true)
            upsertWorkout(session)
            advanceRotationIfNeeded(finishedRoutineId: finishedRoutineId)
            persistWorkouts()

            let sessionId = session.id
            let title = session.title
            let savedReview = session.sessionReview
            Task {
                let apple = await HealthKitStore.shared.finishWorkout(
                    sessionId: sessionId,
                    title: title,
                    start: start,
                    end: end
                )
                if var updated = state.workouts.first(where: { $0.id == sessionId }) {
                    updated.startedAt = apple.startedAt
                    updated.finishedAt = apple.finishedAt
                    updated.appleActiveEnergyKcal = apple.kcal > 0 ? apple.kcal : nil
                    updated.appleDurationSeconds = apple.durationSeconds
                    updated.healthKitWorkoutUUID = apple.workoutUUID ?? updated.healthKitWorkoutUUID
                    if updated.sessionReview == nil {
                        updated.sessionReview = savedReview
                    }
                    upsertWorkout(updated)
                    persistWorkouts()
                }
                await refineSessionReviewWithHealth(sessionId: sessionId)
            }
        } else {
            _ = WorkoutLocationTracker.shared.stopRouteTracking()
            Task { await HealthKitStore.shared.discardLiveTracking() }
        }
    }

    /// kcal locales cuando Watch/Salud no aportan: MET × peso + volumen (+ reps solo si el tiempo es corto).
    func estimateSessionKcal(_ session: WorkoutSession, start: Date, end: Date) -> Double {
        var durationMin = max(1, end.timeIntervalSince(start) / 60)
        if let wodElapsed = session.wodResults.compactMap(\.elapsedSeconds).max(), wodElapsed > 30 {
            durationMin = max(durationMin, Double(wodElapsed) / 60)
        }
        // WOD multi-bloque: el reloj de pared (apuntar 1 h) no es el trabajo real → time caps (12+8+12=32).
        if let programmed = programmedWODMinutes(session), programmed >= 5 {
            durationMin = min(durationMin, programmed + 5)
            if durationMin < programmed * 0.5 {
                durationMin = programmed
            }
        } else {
            let hasWODScore = session.wodResults.contains {
                ($0.totalReps ?? 0) > 0 || ($0.roundsCompleted ?? 0) > 0 || ($0.elapsedSeconds ?? 0) > 30
            }
            if hasWODScore, durationMin <= 2 {
                let caps = session.exercises.compactMap(\.blockTimeCapMinutes).filter { $0 > 0 }
                if let cap = caps.max() {
                    durationMin = Double(cap)
                }
            }
        }
        let sets = session.exercises.flatMap(\.loggedSets)
        // Tiempo de comba/máquina ya va dentro del EMOM/AMRAP; no sumar encima del reloj.
        let timedCardio = sets.compactMap(\.durationSeconds).reduce(0, +)
        // Solo reps reales (comba/PC); cal/metros no cuentan como «reps» en el boost.
        let totalReps = sets
            .filter { $0.quantityUnit != .calories && $0.quantityUnit != .meters }
            .reduce(0) { $0 + $1.reps }
        let machineDisplayCals = sets
            .filter { $0.quantityUnit == .calories }
            .reduce(0) { $0 + $1.reps }
        let hasMachineWork = sets.contains {
            $0.quantityUnit == .calories || $0.quantityUnit == .meters
        }
        let isMetcon = programmedWODMinutes(session) != nil
            || session.wodResults.isEmpty == false
            || timedCardio >= 30
            || hasMachineWork
        let bw = state.bodyWeights.sorted { $0.date > $1.date }.first?.weightKg
        let estimated = HealthKitStore.estimateActiveEnergyKcal(
            durationMinutes: durationMin,
            volumeKg: session.totalVolumeKg,
            bodyWeightKg: bw,
            // Con duración de bloque fiable, el MET×tiempo basta (evitar 800+ por suma de reps).
            totalReps: durationMin >= 10 ? 0 : totalReps,
            timedCardioSeconds: isMetcon ? max(timedCardio, 30) : timedCardio,
            metOverride: isMetcon ? 8.0 : nil
        )
        // Calorías de consola (bike/Ski/remo) como suelo mínimo del estimado de sesión.
        return max(estimated, Double(machineDisplayCals))
    }

    func toggleWODTemplateFavorite(_ templateId: String) {
        var settings = state.settings
        if let idx = settings.favoriteWODTemplateIds.firstIndex(of: templateId) {
            settings.favoriteWODTemplateIds.remove(at: idx)
        } else {
            settings.favoriteWODTemplateIds.append(templateId)
        }
        updateSettings(settings)
    }

    func isWODTemplateFavorite(_ templateId: String) -> Bool {
        state.settings.favoriteWODTemplateIds.contains(templateId)
    }

    /// Rutina efímera desde plantilla de catálogo (play / apuntar desde Biblioteca).
    func routineFromWODTemplate(_ template: WODTemplate) -> Routine {
        Routine(
            title: template.name,
            weekday: nil,
            blocks: [template.makeBlock()],
            progression: .off
        )
    }

    /// Aplica un score WOD (AMRAP / For Time) a la sesión activa.
    /// El marcador vive en `wodResults`; no se inventan series en el primer movimiento.
    func applyWODResult(_ result: WODBlockResult) {
        guard var session = state.activeSession else { return }
        session.wodResults.removeAll { $0.id == result.id }
        session.wodResults.append(result)
        if result.totalReps != nil || result.elapsedSeconds != nil {
            for i in session.exercises.indices where session.exercises[i].blockId == result.id {
                session.exercises[i].isCompleted = true
            }
        }
        state.activeSession = session
        // Persistir inmediatamente el marcador, incluso cuando el atleta sigue
        // en el mismo bloque y no se llama a finishCurrentTimedBlock().
        persist()
        pushActiveToWatch()
    }

    /// Calcula y opcionalmente presenta la valoración post-entreno.
    func attachSessionReview(
        _ session: inout WorkoutSession,
        present: Bool,
        cardio: SessionCardioSample? = nil
    ) {
        let review = SessionReviewEngine.review(
            session: session,
            history: state.workouts,
            cardio: cardio
        )
        session.sessionReview = review
        if present, let review {
            pendingSessionReview = review
            pendingReviewedSessionId = session.id
        }
    }

    /// Recalcula la nota con métricas de Salud (FC / kcal) cuando ya están disponibles.
    @discardableResult
    func refreshSessionReviewWithCardio(
        sessionId: UUID,
        cardio: SessionCardioSample,
        presentIfPending: Bool = false
    ) -> SessionReview? {
        guard let idx = state.workouts.firstIndex(where: { $0.id == sessionId }) else { return nil }
        var session = state.workouts[idx]
        let show = presentIfPending && pendingReviewedSessionId == sessionId
        attachSessionReview(&session, present: show, cardio: cardio)
        state.workouts[idx] = session
        if show, let review = session.sessionReview {
            pendingSessionReview = review
        }
        persistWorkouts()
        return session.sessionReview
    }

    /// Versión de la fórmula de Resultado; al subir, se recalculan todas las notas.
    private static let sessionReviewFormulaVersion = 11

    /// Recomputa la review con la fórmula actual y la persiste.
    @discardableResult
    func ensureSessionReview(for sessionId: UUID) -> SessionReview? {
        guard let idx = state.workouts.firstIndex(where: { $0.id == sessionId }) else { return nil }
        var session = state.workouts[idx]
        attachSessionReview(&session, present: false)
        state.workouts[idx] = session
        persistWorkouts()
        return session.sessionReview
    }

    /// Recalcula notas de todos los entrenos si la fórmula cambió (p. ej. equivalencias).
    func refreshSessionReviewsIfNeeded() {
        let key = "sessionReviewFormulaVersion"
        let stored = UserDefaults.standard.integer(forKey: key)
        guard stored < Self.sessionReviewFormulaVersion else { return }
        // También elimina notas antiguas calculadas sin suficiente histórico;
        // no volverán a aparecer en Inicio/Historial al actualizar.
        refreshAllSessionReviews()
        UserDefaults.standard.set(Self.sessionReviewFormulaVersion, forKey: key)
    }

    /// Recalcula `sessionReview` de cada entreno con el motor actual.
    func refreshAllSessionReviews() {
        guard !state.workouts.isEmpty else { return }
        for i in state.workouts.indices {
            var session = state.workouts[i]
            attachSessionReview(&session, present: false)
            state.workouts[i] = session
        }
        persistWorkouts()
    }

    func dismissPendingSessionReview() {
        pendingSessionReview = nil
        pendingReviewedSessionId = nil
    }

    private func advanceRotationIfNeeded(finishedRoutineId: UUID?) {
        guard state.settings.scheduleMode == .rotation,
              var rotation = state.rotation,
              let finishedRoutineId,
              rotation.nextRoutineId == finishedRoutineId
        else { return }
        rotation.advance()
        state.rotation = rotation
    }

    func updateRotation(_ rotation: RotationPlan?) {
        state.rotation = rotation
        persist()
    }

    func setScheduleMode(_ mode: ScheduleMode) {
        var s = state.settings
        s.scheduleMode = mode
        if mode == .rotation, state.rotation == nil {
            state.rotation = RotationPlan(
                routineIds: state.routines.map(\.id)
            )
        }
        state.settings = s
        persist()
    }

    // MARK: - Session mutations

    private func mutateActive(_ body: (inout SessionController) -> Void) {
        guard let active = state.activeSession else { return }
        var ctrl = SessionController(session: active)
        body(&ctrl)
        state.activeSession = ctrl.session
        if ctrl.session.phase == .finished {
            // Misma ruta que Terminar (estimado Repera si Salud solo tiene ambiente).
            endActiveSession(save: true)
        } else {
            pushActiveToWatch()
            persist()
        }
    }

    func confirmCurrentOnWatchStyle() {
        mutateActive { $0.confirmCurrentExercise() }
    }

    func finishCurrentExercise() {
        mutateActive { _ = $0.finishCurrentExercise() }
    }

    /// El tiempo concluyó: marcar el bloque realizado sin fabricar pesos/repeticiones.
    func finishCurrentTimedBlock() {
        mutateActive { _ = $0.finishCurrentBlock() }
    }

    func selectExercise(at index: Int) {
        mutateActive { $0.selectExercise(at: index) }
    }

    /// Reaplica una rutina editada durante Play sin perder series ni duración.
    /// Conservar estado por ID de bloque y ejercicio, no por índice (pueden reordenarse).
    func refreshActiveSessionPlan(from routine: Routine) {
        guard var session = state.activeSession else { return }
        let fresh = SessionController.from(routine: routine, exercises: state.exercises)
        guard !fresh.exercises.isEmpty else { return }
        let current = session.currentExercise
        var remaining = session.exercises

        session.routineBlocks = routine.blocks
        session.exercises = fresh.exercises.map { planned in
            var updated = planned
            let oldIndex = remaining.firstIndex(where: { old in
                old.blockId == planned.blockId
                    && (old.exercise.id == planned.exercise.id
                        || old.exercise.name.localizedCaseInsensitiveCompare(planned.exercise.name) == .orderedSame)
            }) ?? remaining.firstIndex(where: { old in
                old.exercise.id == planned.exercise.id
                    || old.exercise.name.localizedCaseInsensitiveCompare(planned.exercise.name) == .orderedSame
            })
            if let oldIndex {
                let old = remaining.remove(at: oldIndex)
                updated.loggedSets = old.loggedSets
                updated.completedReps = old.completedReps
                updated.isCompleted = old.isCompleted
            }
            return updated
        }
        if let current,
           let index = session.exercises.firstIndex(where: {
               $0.blockId == current.blockId
                   && ($0.exercise.id == current.exercise.id
                       || $0.exercise.name.localizedCaseInsensitiveCompare(current.exercise.name) == .orderedSame)
           }) ?? session.exercises.firstIndex(where: {
               $0.exercise.id == current.exercise.id
                   || $0.exercise.name.localizedCaseInsensitiveCompare(current.exercise.name) == .orderedSame
           }) {
            session.currentIndex = index
        } else {
            session.currentIndex = min(session.currentIndex, session.exercises.count - 1)
        }
        // Mantener el ID, las marcas de tiempo, el reloj y las series ya apuntadas.
        state.activeSession = session
        persist()
        pushActiveToWatch(immediate: true)
    }


    func logSet(
        reps: Int,
        weightKg: Double?,
        deficitCm: Int? = nil,
        durationSeconds: Int? = nil,
        quantityUnit: ExerciseQuantityUnit? = nil,
        phase: SetPhase = .work,
        kind: SetKind = .straight,
        rir: Double? = nil,
        toFailure: Bool = false,
        drops: [DropSegment] = [],
        clusters: [RestPauseCluster] = []
    ) {
        mutateActive {
            $0.logSet(
                reps: reps,
                weightKg: weightKg,
                deficitCm: deficitCm,
                durationSeconds: durationSeconds,
                quantityUnit: quantityUnit,
                phase: phase,
                kind: kind,
                rir: rir,
                toFailure: toFailure,
                drops: drops,
                clusters: clusters
            )
        }
    }

    func deleteWorkout(_ id: UUID) {
        // Persist a per-account tombstone before removing from local/iCloud.
        BusinessWorkoutSyncStore.shared.noteDeleted(id)
        let hkUUID = state.workouts.first(where: { $0.id == id })?.healthKitWorkoutUUID
        state.workouts.removeAll { $0.id == id }
        persistWorkouts()
        // También quitar de Salud: si no, reaparece como actividad externa «propia».
        if let hkUUID {
            Task {
                _ = await HealthKitStore.shared.deleteExternalWorkout(id: hkUUID)
            }
        }
    }

    /// Apunte rápido desde ficha: guarda series terminadas sin abrir WorkoutView.
    @discardableResult
    func logQuickSets(
        exerciseId: UUID,
        sets: [LoggedSet],
        notes: String? = nil
    ) -> WorkoutSession? {
        guard let exercise = state.exercises.first(where: { $0.id == exerciseId }),
              !sets.isEmpty
        else { return nil }

        let entry = SessionExercise(
            exercise: exercise,
            plannedSets: sets.map {
                PlannedSet(targetReps: $0.reps, targetWeightKg: $0.weightKg)
            },
            loggedSets: sets,
            completedReps: sets.filter { !$0.isWarmup }.reduce(0) { $0 + $1.reps },
            isCompleted: true
        )
        let now = Date()
        let start = now.addingTimeInterval(-max(60, Double(sets.count) * 90))
        let session = WorkoutSession(
            title: "Apuntar · \(exercise.name)",
            exercises: [entry],
            currentIndex: 0,
            phase: .finished,
            startedAt: start,
            finishedAt: now,
            notes: {
                let t = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
                return (t?.isEmpty == false) ? t : nil
            }()
        )
        var saved = session
        saved.appleActiveEnergyKcal = nil
        saved.appleDurationSeconds = max(60, now.timeIntervalSince(start))
        attachSessionReview(&saved, present: true)
        upsertWorkout(saved)
        persistWorkouts()

        let sessionId = saved.id
        let title = saved.title
        let savedReview = saved.sessionReview
        Task {
            let apple = await HealthKitStore.shared.finishWorkout(
                sessionId: sessionId,
                title: title,
                start: start,
                end: now
            )
            if var updated = state.workouts.first(where: { $0.id == sessionId }) {
                updated.startedAt = apple.startedAt
                updated.finishedAt = apple.finishedAt
                updated.appleActiveEnergyKcal = apple.kcal > 0 ? apple.kcal : nil
                updated.appleDurationSeconds = apple.durationSeconds
                updated.healthKitWorkoutUUID = apple.workoutUUID ?? updated.healthKitWorkoutUUID
                if updated.sessionReview == nil {
                    updated.sessionReview = savedReview
                }
                upsertWorkout(updated)
                persistWorkouts()
            }
            await refineSessionReviewWithHealth(sessionId: sessionId)
        }
        return saved
    }

    /// Tras sync de Salud: relee FC/kcal y afina la nota de Resultado.
    func refineSessionReviewWithHealth(sessionId: UUID) async {
        guard let session = state.workouts.first(where: { $0.id == sessionId }) else { return }
        guard let extras = await HealthKitStore.shared.sessionHealthExtras(for: session) else {
            // Aun sin FC, recalcula con kcal de sesión si hay.
            if session.appleActiveEnergyKcal != nil {
                _ = refreshSessionReviewWithCardio(
                    sessionId: sessionId,
                    cardio: SessionCardioSample(
                        activeEnergyKcal: session.appleActiveEnergyKcal,
                        durationMinutes: max(1, session.displayDurationMinutes)
                    ),
                    presentIfPending: true
                )
            }
            return
        }
        let cardio = SessionCardioSample(
            averageHeartRateBpm: extras.averageHeartRateBpm,
            maxHeartRateBpm: extras.maxHeartRateBpm,
            heartRateBpmSamples: extras.heartRateSeries.map(\.bpm),
            activeEnergyKcal: extras.activeEnergyKcal ?? session.appleActiveEnergyKcal,
            durationMinutes: max(1, session.displayDurationMinutes)
        )
        _ = refreshSessionReviewWithCardio(
            sessionId: sessionId,
            cardio: cardio,
            presentIfPending: true
        )
    }

    /// Actualiza un entreno ya terminado (detalle / edición desde Inicio).
    func saveWorkout(_ session: WorkoutSession) {
        var draft = session
        if let start = draft.startedAt, let end = draft.finishedAt, end < start {
            draft.finishedAt = start.addingTimeInterval(60)
        }
        if draft.phase == .finished {
            // La edición nunca fabrica kcal por tiempo, carga o repeticiones.
            // Un entreno sin vínculo con Salud no tiene calorías verificadas.
            if draft.healthKitWorkoutUUID == nil {
                draft.appleActiveEnergyKcal = nil
            }
            if let start = draft.startedAt, let end = draft.finishedAt, draft.liveSportID == nil {
                draft.appleDurationSeconds = max(60, end.timeIntervalSince(start))
            }
            // La valoración anterior ya no corresponde a series/orden/carga editados.
            attachSessionReview(&draft, present: false)
        }
        upsertWorkout(draft)
        persistWorkouts()
        if draft.phase == .finished {
            Task {
                // Una edición permite reintentar una escritura de Salud pendiente.
                if draft.healthKitWorkoutUUID == nil {
                    _ = await syncWorkoutToHealth(sessionId: draft.id)
                }
                await refineSessionReviewWithHealth(sessionId: draft.id)
            }
        }
    }

    /// Escribe un entrenamiento local terminado en Salud o enlaza un
    /// HKWorkout ya capturado por Apple Watch. No crea sesiones duplicadas
    /// si el identificador de Salud aún no se había sincronizado.
    @discardableResult
    private func syncWorkoutToHealth(sessionId: UUID) async -> Bool {
        guard let session = state.workouts.first(where: { $0.id == sessionId }),
              session.healthKitWorkoutUUID == nil,
              let start = session.startedAt,
              let end = session.finishedAt,
              end >= start else { return false }
        let liveSport = session.liveSportID.flatMap { LiveSport(rawValue: $0) }
        let apple = await HealthKitStore.shared.finishWorkout(
            sessionId: session.id,
            title: session.title,
            start: start,
            end: end,
            activityType: liveSport?.healthType ?? .traditionalStrengthTraining,
            locationType: liveSport?.usesGPS == true ? .outdoor : .indoor
        )
        guard let uuid = apple.workoutUUID,
              var current = state.workouts.first(where: { $0.id == sessionId })
        else { return false }
        guard current.healthKitWorkoutUUID == nil else { return true }
        current.healthKitWorkoutUUID = uuid
        current.startedAt = apple.startedAt
        current.finishedAt = apple.finishedAt
        current.appleDurationSeconds = apple.durationSeconds
        current.appleActiveEnergyKcal = apple.kcal > 0 ? apple.kcal : nil
        upsertWorkout(current)
        persistWorkouts()
        await refineSessionReviewWithHealth(sessionId: sessionId)
        return true
    }

    /// Reintenta sesiones ya finalizadas sin UUID desde Sincronizar ahora.
    /// Devuelve las que siguen pendientes, por ejemplo por permisos de Salud.
    @discardableResult
    func syncMissingWorkoutsToHealth() async -> Int {
        let health = HealthKitStore.shared
        health.refreshAuthorizationStatus()
        let pending = state.workouts.filter {
            $0.finishedAt != nil && $0.startedAt != nil && $0.healthKitWorkoutUUID == nil
        }.map(\.id)
        // La lectura de Apple Watch puede estar permitida aunque se haya
        // denegado escribir. Primero se intenta vincular Salud y solo si no
        // existe una muestra coincidente se requiere permiso de escritura.
        guard health.isAvailable else { return pending.count }
        for id in pending {
            if Task.isCancelled { break }
            _ = await syncWorkoutToHealth(sessionId: id)
        }
        return state.workouts.filter {
            $0.finishedAt != nil && $0.startedAt != nil && $0.healthKitWorkoutUUID == nil
        }.count
    }

    func removeLastSet() {
        mutateActive { $0.removeLastLoggedSet() }
    }

    /// Lugar seleccionado desde Play; persistirlo en la sesión en curso,
    /// sin alterar la rutina ni depender del editor del entrenamiento.
    func updateActiveSessionLocation(_ pin: WorkoutLocationPin?) {
        guard var active = state.activeSession else { return }
        active.locationPin = pin
        state.activeSession = active
        persist()
        pushActiveToWatch(immediate: true)
    }

    /// Notas libres del entreno en curso (persistidas con la sesión).
    func updateActiveSessionNotes(_ notes: String) {
        guard var session = state.activeSession else { return }
        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        session.notes = trimmed.isEmpty ? nil : trimmed
        state.activeSession = session
        persist()
        pushActiveToWatch(immediate: true)
    }

    func applyWatchSession(_ session: WorkoutSession) {
        if session.phase == .finished {
            var changed = false
            if let index = state.workouts.firstIndex(where: { $0.id == session.id }) {
                // An earlier offline transfer may arrive before HealthKit finishes saving.
                // Merge genuine Apple measurements into the SAME workout; never replace
                // confirmed sets or user edits with a stale Watch snapshot.
                var saved = state.workouts[index]
                if let uuid = session.healthKitWorkoutUUID,
                   saved.healthKitWorkoutUUID != uuid {
                    saved.healthKitWorkoutUUID = uuid
                    changed = true
                }
                if let source = session.appleHealthProvenance,
                   (source == "watchHealthKit" || source == "watchHealthKitPending"),
                   saved.appleHealthProvenance != "watchHealthKit",
                   saved.appleHealthProvenance != source {
                    saved.appleHealthProvenance = source
                    changed = true
                } else if session.appleHealthProvenance == "watchHealthKit",
                          saved.appleHealthProvenance != "watchHealthKit" {
                    saved.appleHealthProvenance = "watchHealthKit"
                    changed = true
                }
                if let energy = session.appleActiveEnergyKcal, energy > 0,
                   saved.appleActiveEnergyKcal != energy {
                    saved.appleActiveEnergyKcal = energy
                    changed = true
                }
                if let duration = session.appleDurationSeconds, duration > 0,
                   saved.appleDurationSeconds != duration {
                    saved.appleDurationSeconds = duration
                    changed = true
                }
                if let heartRate = session.appleAverageHeartRateBpm, heartRate > 0,
                   saved.appleAverageHeartRateBpm != heartRate {
                    saved.appleAverageHeartRateBpm = heartRate
                    changed = true
                }
                if changed { upsertWorkout(saved) }
            } else {
                var completed = session
                // No fabricated Health duration: displayDurationMinutes already
                // provides the wall-clock fallback in the UI when HK is unavailable.
                attachSessionReview(&completed, present: false)
                upsertWorkout(completed)
                if state.activeSession?.id == completed.id { state.activeSession = nil }
                changed = true
            }

            if changed { persistWorkouts() }
            let snapshot = state
            let needsSync = changed
            Task { @MainActor in
                await LocalStore.shared.persistAndFlush(snapshot)
                // The acknowledgment means the phone has persisted it, NOT that
                // Supabase has completed or that the Health sample is yet visible.
                guard LocalStore.shared.lastPersistenceError == nil,
                      self.state.workouts.first(where: { $0.id == session.id }) ==
                      snapshot.workouts.first(where: { $0.id == session.id })
                else { return }
                self.lastWatchAcknowledgedSession = session.id
                self.pushActiveToWatch(immediate: true)
                if needsSync && BusinessAuthStore.shared.isConnected {
                    _ = await BusinessWorkoutSyncStore.shared.sync(store: self)
                }
                if needsSync, session.healthKitWorkoutUUID != nil {
                    await HealthKitStore.shared.refreshVerifiedWorkoutEnergy(
                        for: self.state.workouts
                    )
                }
            }
            return
        }
        // Never overwrite another active iPhone workout or resurrect a completed one.
        guard !state.workouts.contains(where: { $0.id == session.id }),
              state.activeSession == nil || state.activeSession?.id == session.id
        else { return }
        state.activeSession = session
        persist()
        pushActiveToWatch(immediate: true)
    }

    /// Reconciles delayed watchOS HealthKit samples without creating duplicate
    /// workouts or accepting energy estimates from Repera's legacy iPhone writer.
    /// Called on foreground and after the initial local/cloud recovery.
    func reconcileWatchHealthMetrics() async {
        guard isHydrated, HealthKitStore.shared.isAvailable else { return }
        let candidates = state.workouts.filter {
            $0.appleHealthProvenance == "watchHealthKitPending"
                || ($0.appleHealthProvenance == "watchHealthKit" &&
                    $0.healthKitWorkoutUUID == nil)
        }
        var changed = false
        for original in candidates.prefix(50) {
            if Task.isCancelled { break }
            guard let actual = await HealthKitStore.shared.verifiedWatchWorkout(
                forReperaSession: original.id
            ), let index = state.workouts.firstIndex(where: { $0.id == original.id })
            else { continue }
            var current = state.workouts[index]
            current.healthKitWorkoutUUID = actual.workoutUUID
            current.appleDurationSeconds = actual.durationSeconds
            current.appleHealthProvenance = "watchHealthKit"
            if actual.kcal > 0 { current.appleActiveEnergyKcal = actual.kcal }
            if current != state.workouts[index] {
                state.workouts[index] = current
                changed = true
            }
        }
        if changed {
            persistWorkouts()
            await LocalStore.shared.persistAndFlush(state)
        }
    }

    /// Merge-only recovery from authenticated Supabase, after iCloud recovery.
    /// Never replaces an existing local workout, active session or local settings.
    @discardableResult
    func mergeRecoveredWorkoutsFromSupabase(_ recovered: [WorkoutSession]) -> Int {
        guard didCompleteInitialRemoteSync, !isSyncingiCloud else { return 0 }
        var known = Set(state.workouts.map(\.id))
        var imported = 0
        for session in recovered where session.finishedAt != nil {
            guard known.insert(session.id).inserted else { continue }
            state.workouts.append(session)
            imported += 1
        }
        if imported > 0 {
            state.workouts.sort {
                ($0.finishedAt ?? $0.startedAt ?? .distantPast) >
                    ($1.finishedAt ?? $1.startedAt ?? .distantPast)
            }
            persistWorkouts()
        }
        return imported
    }

    private func upsertWorkout(_ session: WorkoutSession) {
        if let idx = state.workouts.firstIndex(where: { $0.id == session.id }) {
            state.workouts[idx] = session
        } else {
            state.workouts.insert(session, at: 0)
        }
        state.workouts.sort {
            ($0.finishedAt ?? $0.startedAt ?? .distantPast) > ($1.finishedAt ?? $1.startedAt ?? .distantPast)
        }
        bumpTestedOneRMs(for: session.exercises.map(\.exercise.id))
    }

    /// Si el e1RM del historial supera el 1RM guardado, sube el tope automáticamente.
    private func bumpTestedOneRMs(for exerciseIds: [UUID]) {
        for id in Set(exerciseIds) {
            var pref = loadPreference(for: id)
            guard let tested = pref.testedOneRMKg, tested > 0 else { continue }
            let hist = cachedHistory(for: id)
            guard let e1 = hist.estimatedOneRM, e1 > tested + 0.049 else { continue }
            pref.testedOneRMKg = (e1 * 10).rounded() / 10
            state.exerciseLoadPrefs[id.uuidString] = pref
        }
    }

    /// Publishes Equatable tab chrome; optionally debounces Watch applicationContext.
    /// - Parameter immediate: start / end / Watch inbound — flush now. Set logging uses debounce.
    private func pushActiveToWatch(immediate: Bool = false) {
        publishSessionChrome()
        if immediate {
            watchPushTask?.cancel()
            watchPushTask = nil
            sendWatchContextNow()
            return
        }
        watchPushTask?.cancel()
        watchPushTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 280_000_000)
            guard !Task.isCancelled else { return }
            self.sendWatchContextNow()
        }
    }

    private func publishSessionChrome() {
        let active = state.activeSession
        let nextHas = active != nil
        let nextAccessory = ContinueAccessoryModel(session: active)
        var changed = false
        if hasActiveSession != nextHas {
            hasActiveSession = nextHas
            changed = true
        }
        if continueAccessory != nextAccessory {
            continueAccessory = nextAccessory
            changed = true
        }
        if changed { sessionEpoch &+= 1 }
    }

    private func professionalWorkoutForWatchToday() -> WorkoutSession? {
        let key = BusinessDataStore.localDayKey(Date())
        guard let assigned = BusinessDataStore.shared.trainingSessions.first(where: {
            $0.scheduledDate == key && $0.status == "scheduled" &&
            $0.prescription?.schemaVersion == 1 && $0.prescription?.blocks.isEmpty == false
        }), let prescription = assigned.prescription else { return nil }

        // The coach's immutable prescription can be read offline on Watch,
        // without introducing coach exercises into the athlete's personal catalog.
        var catalog = state.exercises
        var blocks: [RoutineBlock] = []
        func resolvedExercise(_ entry: BusinessPrescriptionEntry) -> Exercise {
            if let key = entry.catalogKey,
               let uuid = UUID(uuidString: key),
               let found = catalog.first(where: { $0.id == uuid }) { return found }
            if let found = catalog.first(where: {
                ExerciseEquivalence.sameName($0.name, entry.name)
            }) { return found }
            let custom = Exercise(name: entry.name, muscleGroup: "Entrenador", isCustom: true)
            catalog.append(custom)
            return custom
        }

        for prescribed in prescription.blocks {
            let isWOD = prescribed.kind == "wod"
            let format: WODFormat? = {
                guard let raw = prescribed.wodFormat else { return nil }
                switch raw.lowercased().replacingOccurrences(of: "_", with: "") {
                case "rft", "fortime": return .forTime
                case "emom", "every": return .emom
                case "amrap": return .amrap
                case "tabata": return .tabata
                case "chipper": return .chipper
                case "circuit": return .circuit
                case "ladder": return .ladder
                case "strength": return .strength
                default: return WODFormat(rawValue: raw)
                }
            }()
            var strength: [RoutineExercise] = []
            var movements: [WODMovement] = []
            for entry in prescribed.entries {
                let exercise = resolvedExercise(entry)
                let sets = entry.plannedSets?.map {
                    PlannedSet(id: $0.id, targetReps: max(0, $0.targetReps),
                               targetWeightKg: $0.targetWeightKg,
                               targetRir: $0.targetRir)
                } ?? []
                if isWOD {
                    movements.append(WODMovement(
                        id: entry.id, exerciseId: exercise.id,
                        name: exercise.name, reps: entry.reps,
                        notes: entry.notes,
                        explicitPlannedSets: sets.isEmpty ? nil : sets
                    ))
                } else {
                    strength.append(RoutineExercise(
                        id: entry.id, exerciseId: exercise.id,
                        plannedSets: sets.isEmpty
                            ? [PlannedSet(targetReps: max(0, entry.reps ?? 0))] : sets
                    ))
                }
            }
            blocks.append(RoutineBlock(
                id: prescribed.id, title: prescribed.title,
                kind: isWOD ? .wod : .strength, exercises: strength,
                movements: movements, wodFormat: format,
                timeCapMinutes: prescribed.timeCapMinutes,
                rounds: prescribed.rounds
            ))
        }
        guard !blocks.isEmpty else { return nil }
        let routine = Routine(
            id: assigned.id, title: assigned.title,
            scheduledDate: Date(), blocks: blocks, progression: .off
        )
        let preview = SessionController.from(routine: routine, exercises: catalog)
        return preview.exercises.isEmpty ? nil : preview
    }

    /// Rebuild from the current store on each explicit Watch request.
    /// Never reply to "Sincronizar" using an old WCSession cached snapshot.
    private func currentWatchWorkoutForToday() -> WorkoutSession? {
        let personal = routineForToday().map {
            SessionController.from(routine: $0, exercises: state.exercises)
        }
        return (personal?.exercises.isEmpty == false ? personal : nil)
            ?? professionalWorkoutForWatchToday()
    }

    private func sendWatchContextNow() {
        let today = currentWatchWorkoutForToday()
        connectivity.send(
            session: state.activeSession,
            today: today,
            quickLogHint: quickLogHintPayload(),
            sessionRevision: state.syncRevision,
            completedAck: lastWatchAcknowledgedSession,
            completedAckHealthKitUUID: lastWatchAcknowledgedSession.flatMap { ackID in
                state.workouts.first(where: { $0.id == ackID })?.healthKitWorkoutUUID
            }
        )
    }

    private func quickLogHintPayload() -> (id: UUID, name: String)? {
        if let current = state.activeSession?.currentExercise {
            return (current.exercise.id, current.exercise.name)
        }
        // Último ejercicio con series en el historial reciente.
        for workout in state.workouts.prefix(20) {
            for entry in workout.exercises.reversed() {
                if entry.loggedSets.contains(where: { !$0.isWarmup && $0.reps > 0 }) {
                    return (entry.exercise.id, entry.exercise.name)
                }
            }
        }
        return state.exercises.first.map { ($0.id, $0.name) }
    }

    /// Watch: inicia log rápido del ejercicio indicado o del hint.
    func handleWatchQuickLogRequest(exerciseId: UUID?) {
        let id = exerciseId
            ?? quickLogHintPayload()?.id
            ?? state.exercises.first?.id
        guard let id else { return }
        if state.activeSession == nil {
            startQuickLog(exerciseId: id, sets: 5, reps: 8)
        }
        pushActiveToWatch(immediate: true)
    }

    /// Watch: registra una serie, flushes durable, returns `syncRevision` for ACK (0 = failed).
    @discardableResult
    func handleWatchLogSet(reps: Int, weightKg: Double?) async -> Int {
        if state.activeSession == nil {
            handleWatchQuickLogRequest(exerciseId: nil)
        }
        guard state.activeSession != nil else { return 0 }
        let weight = weightKg
            ?? state.activeSession?.currentExercise?.lastLoggedWeight
            ?? state.activeSession?.currentExercise?.plannedSets.first?.targetWeightKg
        mutateActive {
            $0.logSet(reps: max(1, reps), weightKg: weight)
        }
        await LocalStore.shared.persistAndFlush(state)
        pushActiveToWatch(immediate: true)
        return state.syncRevision
    }

    // MARK: - Routines

    /// Guarda una rutina. Devuelve `false` si la política freemium bloquea una **nueva** plantilla de biblioteca.
    @discardableResult
    func saveRoutine(_ routine: Routine) -> Bool {
        let isNew = !state.routines.contains { $0.id == routine.id }
        let isLibraryTemplate = routine.scheduledDate == nil
        if isNew && isLibraryTemplate {
            let decision = featureAccess?().canCreateLibraryRoutine(isNew: true)
                ?? FeatureAccessDecision.allow()
            if !decision.allowed {
                lastAccessDenial = decision
                return false
            }
        }
        lastAccessDenial = nil
        var draft = routine
        if let scheduled = draft.scheduledDate {
            draft.scheduledDate = Calendar.current.startOfDay(for: scheduled)
            // Entreno suelto: no pisa el plan semanal; solo otro suelto del mismo día.
            var removeIds: [UUID] = []
            for other in state.routines where other.id != draft.id {
                guard let otherDate = other.scheduledDate else { continue }
                if Calendar.current.isDate(otherDate, inSameDayAs: draft.scheduledDate!) {
                    if other.isFavorite {
                        // favorito suelto → quitar fecha
                        if let i = state.routines.firstIndex(where: { $0.id == other.id }) {
                            state.routines[i].scheduledDate = nil
                        }
                    } else {
                        removeIds.append(other.id)
                    }
                }
            }
            state.routines.removeAll { removeIds.contains($0.id) }
        } else if let day = draft.weekday {
            // Un día del plan → una plantilla. Las demás se desasignan (no se borran).
            for i in state.routines.indices where state.routines[i].id != draft.id
                && state.routines[i].scheduledDate == nil
                && state.routines[i].weekday == day {
                state.routines[i].weekday = nil
            }
        }
        if let idx = state.routines.firstIndex(where: { $0.id == draft.id }) {
            state.routines[idx] = draft
        } else {
            state.routines.append(draft)
        }
        state.routines.sort {
            ($0.weekday ?? 99, $0.scheduledDate ?? .distantFuture, $0.title)
                < ($1.weekday ?? 99, $1.scheduledDate ?? .distantFuture, $1.title)
        }
        persist()
        pushActiveToWatch()
        return true
    }

    func deleteRoutine(_ id: UUID) {
        state.routines.removeAll { $0.id == id }
        if var rotation = state.rotation {
            rotation.routineIds.removeAll { $0 == id }
            state.rotation = rotation.routineIds.isEmpty ? nil : rotation
        }
        persist()
        pushActiveToWatch()
    }

    /// Quita todas las asignaciones de días; conserva plantillas de Rutinas y entrenos sueltos.
    func clearWeeklySchedule() {
        for i in state.routines.indices where state.routines[i].scheduledDate == nil {
            state.routines[i].weekday = nil
        }
        state.rotation = nil
        persist()
        pushActiveToWatch()
    }

    func deleteAllRoutines() {
        // Solo borra el plan semanal; conserva favoritos, plantillas sin día y entrenos sueltos.
        state.routines = state.routines.compactMap { routine in
            if routine.isOneOff { return routine }
            if routine.isFavorite || routine.weekday == nil {
                var keep = routine
                keep.weekday = nil
                return keep
            }
            // Rutina solo del plan (con día, no favorita): se elimina al vaciar el plan antiguo.
            return nil
        }
        state.rotation = nil
        persist()
        pushActiveToWatch()
    }

    /// Días del plan semanal (Diario). Excluye entrenos sueltos.
    var plannedRoutines: [Routine] {
        state.routines
            .filter(\.isWeeklyPlan)
            .sorted { ($0.weekday ?? 99) < ($1.weekday ?? 99) }
    }

    /// Rutinas reutilizables (Diario → Rutinas). Excluye entrenos sueltos por fecha.
    var libraryRoutines: [Routine] {
        state.routines
            .filter(\.isLibraryRoutine)
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    /// Conteo barato para gates freemium (sin sort ni arrays intermedios).
    var libraryRoutineCount: Int {
        state.routines.reduce(into: 0) { if $1.isLibraryRoutine { $0 += 1 } }
    }

    var customExerciseCount: Int {
        state.exercises.reduce(into: 0) { if $1.isCustom { $0 += 1 } }
    }

    /// Plantillas favoritas (habituales).
    var favoriteRoutines: [Routine] {
        state.routines.filter(\.isFavorite).sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    /// Rutina asignada a un día ISO del plan (1 = lunes … 7 = domingo).
    func routine(forWeekday day: Int) -> Routine? {
        state.routines.first { $0.isWeeklyPlan && $0.weekday == day }
    }

    func setRoutineFavorite(_ id: UUID, isFavorite: Bool) {
        guard let i = state.routines.firstIndex(where: { $0.id == id }) else { return }
        state.routines[i].isFavorite = isFavorite
        persist()
    }

    /// Quita de favoritos; la plantilla sigue en Diario → Rutinas.
    func removeFavorite(_ id: UUID) {
        setRoutineFavorite(id, isFavorite: false)
    }

    /// Guarda (o clona) una rutina como favorito reutilizable.
    @discardableResult
    func saveAsFavorite(_ routine: Routine, title: String? = nil) -> Routine {
        if let idx = state.routines.firstIndex(where: { $0.id == routine.id }) {
            state.routines[idx].isFavorite = true
            if let title, !title.isEmpty { state.routines[idx].title = title }
            persist()
            return state.routines[idx]
        }
        let name = (title ?? routine.title).trimmingCharacters(in: .whitespacesAndNewlines)
        let fav = Routine(
            id: UUID(),
            title: name.isEmpty ? "Favorito" : name,
            weekday: nil,
            blocks: routine.blocks,
            progression: routine.progression,
            isFavorite: true
        )
        saveRoutine(fav)
        return fav
    }

    /// Marca la rutina de la sesión activa como favorita, o crea plantilla desde la sesión.
    @discardableResult
    func saveActiveSessionAsFavorite() -> Routine? {
        guard let session = state.activeSession else { return nil }
        let saved: Routine
        if let rid = session.routineId, let existing = state.routines.first(where: { $0.id == rid }) {
            saved = saveAsFavorite(existing)
        } else {
            let template = Self.favoriteTemplate(from: session)
            saveRoutine(template)
            saved = template
        }
        if var active = state.activeSession {
            active.routineId = saved.id
            state.activeSession = active
            persist()
        }
        return saved
    }

    private static func favoriteTemplate(from session: WorkoutSession) -> Routine {
        var order: [UUID] = []
        var groups: [UUID: [SessionExercise]] = [:]
        var meta: [UUID: SessionExercise] = [:]
        for item in session.exercises {
            let key = item.blockId ?? item.id
            if groups[key] == nil {
                order.append(key)
                meta[key] = item
            }
            groups[key, default: []].append(item)
        }
        let blocks: [RoutineBlock] = order.compactMap { key in
            guard let sample = meta[key], let items = groups[key] else { return nil }
            let kind = sample.blockKind ?? (sample.wodFormat == nil || sample.wodFormat == .strength ? .strength : .wod)
            if kind == .strength {
                let exercises = items.map {
                    RoutineExercise(
                        exerciseId: $0.exercise.id,
                        plannedSets: $0.plannedSets.isEmpty
                            ? [PlannedSet(targetReps: 8, targetWeightKg: nil)]
                            : $0.plannedSets,
                        supersetGroup: nil
                    )
                }
                return RoutineBlock(
                    id: sample.blockId ?? UUID(),
                    title: sample.blockHeader ?? "Bloque",
                    kind: .strength,
                    exercises: exercises
                )
            }
            let movements = items.map {
                WODMovement(
                    exerciseId: $0.exercise.id,
                    name: $0.exercise.name,
                    reps: $0.plannedSets.first?.targetReps
                )
            }
            return RoutineBlock(
                id: sample.blockId ?? UUID(),
                title: sample.blockHeader ?? sample.wodFormat?.displayName ?? "WOD",
                kind: .wod,
                movements: movements,
                wodFormat: sample.wodFormat,
                timeCapMinutes: sample.blockTimeCapMinutes,
                emomIntervalSeconds: sample.blockIntervalSeconds,
                rounds: sample.blockRounds,
                workSeconds: sample.blockWorkSeconds,
                restSeconds: sample.blockRestSeconds
            )
        }
        return Routine(
            title: session.title.isEmpty ? "Favorito" : session.title,
            weekday: nil,
            blocks: blocks.isEmpty ? [.strength()] : blocks,
            progression: .off,
            isFavorite: true
        )
    }

    // MARK: - Favorite timers

    @discardableResult
    func saveFavoriteTimer(_ timer: FavoriteTimer) -> FavoriteTimer {
        if let idx = state.favoriteTimers.firstIndex(where: { $0.id == timer.id }) {
            state.favoriteTimers[idx] = timer
        } else {
            state.favoriteTimers.append(timer)
        }
        state.favoriteTimers.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        persist()
        return timer
    }

    func deleteFavoriteTimer(_ id: UUID) {
        state.favoriteTimers.removeAll { $0.id == id }
        persist()
    }

    // MARK: - Exercises

    /// Crea un ejercicio personalizado. Devuelve `false` si se alcanzó el límite gratuito.
    @discardableResult
    func addCustomExercise(
        name: String,
        muscleGroup: String,
        equipment: String?,
        targetMuscle: String? = nil,
        secondaryMuscles: [String] = [],
        bodyPart: String? = nil,
        detailDescription: String? = nil,
        instructions: [String] = [],
        id: UUID = UUID()
    ) -> Bool {
        if state.exercises.contains(where: { $0.id == id && $0.isCustom }) {
            return true // Accepted change awaiting server ACK: idempotent replay.
        }
        let customCount = state.exercises.filter(\.isCustom).count
        var policy = featureAccess?() ?? FeatureAccessPolicy()
        policy.customExerciseCount = customCount
        let decision = policy.canCreateCustomExercise(isNew: true)
        if !decision.allowed {
            lastAccessDenial = decision
            return false
        }
        lastAccessDenial = nil
        let exercise = Exercise(
            id: id,
            name: name,
            muscleGroup: muscleGroup,
            equipment: equipment,
            isCustom: true,
            targetMuscle: targetMuscle,
            secondaryMuscles: secondaryMuscles,
            bodyPart: bodyPart,
            detailDescription: detailDescription,
            instructions: instructions
        )
        state.exercises.append(exercise)
        catalogEpoch &+= 1
        persist()
        return true
    }

    /// Owner-confirmed MCP edit; never mutates a curated catalog exercise.
    @discardableResult
    func updateCustomExercise(
        id: UUID, name: String, muscleGroup: String,
        equipment: String?, targetMuscle: String?, secondaryMuscles: [String]
    ) -> Bool {
        guard let index = state.exercises.firstIndex(where: { $0.id == id && $0.isCustom })
        else { return false }
        var exercise = state.exercises[index]
        exercise.name = name
        exercise.muscleGroup = muscleGroup
        exercise.equipment = equipment
        exercise.targetMuscle = targetMuscle
        exercise.secondaryMuscles = secondaryMuscles
        state.exercises[index] = exercise
        catalogEpoch &+= 1
        persist()
        return true
    }

    func deleteExercise(_ id: UUID) {
        state.exercises.removeAll { $0.id == id && $0.isCustom }
        catalogEpoch &+= 1
        persist()
    }

    func toggleFavorite(_ id: UUID) {
        guard let i = state.exercises.firstIndex(where: { $0.id == id }) else { return }
        state.exercises[i].isFavorite.toggle()
        catalogEpoch &+= 1
        persist()
    }

    func loadPreference(for exerciseId: UUID) -> ExerciseLoadPreference {
        state.exerciseLoadPrefs[exerciseId.uuidString] ?? ExerciseLoadPreference()
    }

    func setLoadPreference(_ pref: ExerciseLoadPreference, for exerciseId: UUID) {
        state.exerciseLoadPrefs[exerciseId.uuidString] = pref
        persist()
    }

    /// Añade el ejercicio al entreno suelto de hoy (Inicio · Entreno del día). No modifica rutinas del plan semanal.
    @discardableResult
    func addExerciseToTodayWorkout(_ exerciseId: UUID, sets: Int = 3, reps: Int = 8) -> Bool {
        guard state.exercises.contains(where: { $0.id == exerciseId }) else { return false }
        let today = Calendar.current.startOfDay(for: Date())
        let item = RoutineExercise(
            exerciseId: exerciseId,
            plannedSets: (0..<sets).map { _ in PlannedSet(targetReps: reps, targetWeightKg: nil) }
        )

        if var existing = state.routines.first(where: { routine in
            guard let scheduled = routine.scheduledDate else { return false }
            return Calendar.current.isDate(scheduled, inSameDayAs: today)
        }) {
            if let idx = existing.blocks.firstIndex(where: { $0.kind == .strength }) {
                if existing.blocks[idx].exercises.contains(where: { $0.exerciseId == exerciseId }) {
                    return true
                }
                existing.blocks[idx].exercises.append(item)
            } else {
                existing.blocks.insert(.strength(exercises: [item]), at: 0)
            }
            saveRoutine(existing)
            return true
        }

        let routine = Routine(
            title: "Entreno del día",
            weekday: nil,
            scheduledDate: today,
            blocks: [.strength(title: "Bloque 1", exercises: [item])],
            progression: .off
        )
        saveRoutine(routine)
        return true
    }

    func startFreestyle(title: String, exerciseIds: [UUID], sets: Int = 3, reps: Int = 8) {
        let items: [RoutineExercise] = exerciseIds.compactMap { eid in
            guard state.exercises.contains(where: { $0.id == eid }) else { return nil }
            return RoutineExercise(
                exerciseId: eid,
                plannedSets: (0..<sets).map { _ in PlannedSet(targetReps: reps, targetWeightKg: nil) }
            )
        }
        guard !items.isEmpty else { return }
        let routine = Routine(title: title, weekday: nil, exercises: items, progression: .off)
        startSession(from: routine)
    }

    /// Log rápido: 1 ejercicio → series → terminar (sin montar rutina completa).
    func startQuickLog(exerciseId: UUID, sets: Int = 3, reps: Int = 8) {
        guard let exercise = state.exercises.first(where: { $0.id == exerciseId }) else { return }
        let hist = cachedHistory(for: exerciseId)
        let weight = hist.lastWeightKg
        let targetReps = hist.lastReps ?? reps
        let items = [
            RoutineExercise(
                exerciseId: exerciseId,
                plannedSets: (0..<sets).map { _ in
                    PlannedSet(targetReps: targetReps, targetWeightKg: weight)
                }
            )
        ]
        let routine = Routine(
            title: "Apuntar · \(exercise.name)",
            weekday: nil,
            exercises: items,
            progression: .off
        )
        startSession(from: routine)
    }

    /// Sustituye el ejercicio actual (o el indicado) por otro del catálogo, conservando series planificadas.
    @discardableResult
    func replaceActiveExercise(at index: Int? = nil, with newExerciseId: UUID) -> Bool {
        guard var session = state.activeSession else { return false }
        guard state.exercises.contains(where: { $0.id == newExerciseId }) else { return false }
        let idx = index ?? session.currentIndex
        guard session.exercises.indices.contains(idx) else { return false }
        guard let catalog = state.exercises.first(where: { $0.id == newExerciseId }) else { return false }
        var entry = session.exercises[idx]
        entry.exercise = catalog
        session.exercises[idx] = entry
        state.activeSession = session
        pushActiveToWatch(immediate: true)
        return true
    }

    /// Copia entrenos sueltos de la semana ISO anterior a la actual (nuevos IDs).
    @discardableResult
    func copyPreviousWeekSchedule() -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let thisWeekStart = ProgressTimeRange.week.startDate(now: today, weekStartsOnMonday: true),
              let prevWeekStart = cal.date(byAdding: .day, value: -7, to: thisWeekStart),
              let thisWeekEnd = cal.date(byAdding: .day, value: 7, to: thisWeekStart)
        else { return 0 }

        let sources = state.routines.filter { routine in
            guard let scheduled = routine.scheduledDate else { return false }
            let day = cal.startOfDay(for: scheduled)
            return day >= prevWeekStart && day < thisWeekStart
        }

        var created = 0
        for source in sources {
            guard let scheduled = source.scheduledDate,
                  let newDate = cal.date(byAdding: .day, value: 7, to: cal.startOfDay(for: scheduled))
            else { continue }
            let day = cal.startOfDay(for: newDate)
            guard day >= thisWeekStart && day < thisWeekEnd else { continue }
            if state.routines.contains(where: {
                guard let s = $0.scheduledDate else { return false }
                return cal.isDate(s, inSameDayAs: day)
            }) { continue }

            let copy = Routine(
                title: source.title,
                weekday: nil,
                scheduledDate: day,
                scheduledTimeMinutes: source.scheduledTimeMinutes,
                blocks: source.blocks.map { $0.duplicatingContent() },
                progression: source.progression,
                isFavorite: false
            )
            saveRoutine(copy)
            created += 1
        }
        return created
    }

    /// Asigna una plantilla a un día del plan (o la desasigna). Un día solo puede tener una rutina.
    func assignRoutine(_ routineId: UUID, toWeekday day: Int?) {
        guard let i = state.routines.firstIndex(where: { $0.id == routineId }) else { return }
        if let day {
            for j in state.routines.indices where state.routines[j].id != routineId
                && state.routines[j].scheduledDate == nil
                && state.routines[j].weekday == day {
                state.routines[j].weekday = nil
            }
            state.routines[i].scheduledDate = nil
            state.routines[i].weekday = day
        } else {
            state.routines[i].weekday = nil
        }
        state.routines.sort {
            ($0.weekday ?? 99, $0.scheduledDate ?? .distantFuture, $0.title)
                < ($1.weekday ?? 99, $1.scheduledDate ?? .distantFuture, $1.title)
        }
        persist()
        pushActiveToWatch()
    }

    // MARK: - Body weight

    /// Un peso por día calendario: si ya hay uno ese día, lo actualiza (origen propio).
    func addBodyWeight(_ kg: Double, date: Date = Date(), syncToHealth: Bool = true) {
        let cal = Calendar.current
        if let idx = state.bodyWeights.firstIndex(where: { cal.isDate($0.date, inSameDayAs: date) }) {
            state.bodyWeights[idx].date = date
            state.bodyWeights[idx].weightKg = kg
            state.bodyWeights[idx].source = .manual
        } else {
            state.bodyWeights.insert(
                BodyWeightEntry(date: date, weightKg: kg, source: .manual),
                at: 0
            )
        }
        state.bodyWeights.sort { $0.date > $1.date }
        persist()
        if syncToHealth {
            Task { await HealthKitStore.shared.saveBodyMass(kg: kg, date: date) }
        }
    }

    func deleteBodyWeight(_ id: UUID) {
        state.bodyWeights.removeAll { $0.id == id }
        persist()
    }

    /// Colapsa varios pesos del mismo día dejando el más reciente.
    @discardableResult
    private func dedupeBodyWeightsByDay() -> Bool {
        let before = state.bodyWeights.count
        let cal = Calendar.current
        var bestByDay: [Date: BodyWeightEntry] = [:]
        for entry in state.bodyWeights {
            let day = cal.startOfDay(for: entry.date)
            if let existing = bestByDay[day] {
                if entry.date > existing.date {
                    bestByDay[day] = entry
                }
            } else {
                bestByDay[day] = entry
            }
        }
        let deduped = bestByDay.values.sorted { $0.date > $1.date }
        guard deduped.count != before else { return false }
        state.bodyWeights = deduped
        return true
    }

    /// Importa pesos de Salud (1 por día) y sube a Salud los días que solo están en la app.
    func syncBodyWeightWithHealth() async {
        let health = HealthKitStore.shared
        let cal = Calendar.current
        await health.refreshToday()
        let samples = await health.fetchAllBodyMassSamples()

        if let newest = samples.first {
            health.latestWeightKg = newest.kg
            health.latestWeightDate = newest.date
        }

        // Salud puede tener varias muestras el mismo día (báscula, Watch…): una por día.
        var healthByDay: [Date: HealthKitStore.BodyMassSample] = [:]
        for sample in samples {
            let day = cal.startOfDay(for: sample.date)
            if let existing = healthByDay[day] {
                if sample.date > existing.date { healthByDay[day] = sample }
            } else {
                healthByDay[day] = sample
            }
        }

        dedupeBodyWeightsByDay()

        var changed = false
        for sample in healthByDay.values {
            if let idx = state.bodyWeights.firstIndex(where: { cal.isDate($0.date, inSameDayAs: sample.date) }) {
                let entry = state.bodyWeights[idx]
                // Si Salud es más reciente (o mismo instante con kg distinto), actualiza local.
                if sample.date > entry.date
                    || (abs(sample.date.timeIntervalSince(entry.date)) < 1
                        && abs(sample.kg - entry.weightKg) >= 0.05)
                {
                    state.bodyWeights[idx].date = sample.date
                    state.bodyWeights[idx].weightKg = sample.kg
                    state.bodyWeights[idx].source = .health
                    changed = true
                }
            } else {
                state.bodyWeights.insert(
                    BodyWeightEntry(date: sample.date, weightKg: sample.kg, source: .health),
                    at: 0
                )
                changed = true
            }
        }

        if changed {
            state.bodyWeights.sort { $0.date > $1.date }
            persist()
        }

        // Días solo en Repera → Salud.
        for entry in state.bodyWeights {
            let day = cal.startOfDay(for: entry.date)
            if healthByDay[day] == nil {
                await health.saveBodyMass(kg: entry.weightKg, date: entry.date)
            }
        }
    }

    // MARK: - Settings

    func updateSettings(_ settings: AppSettings) {
        state.settings = settings
        persist()
    }
}

extension ReperaStore: PhoneConnectivityDelegate {
    nonisolated func phoneConnectivityDidUpdateReachability(_ reachable: Bool) {
        Task { @MainActor in
            self.isWatchReachable = reachable
            self.sendWatchContextNow()
        }
    }

    nonisolated func phoneConnectivityDidRequestToday() {
        Task { @MainActor in self.sendWatchContextNow() }
    }

    nonisolated func phoneConnectivityLatestWorkoutForToday() async -> WorkoutSession? {
        await MainActor.run { self.currentWatchWorkoutForToday() }
    }

    nonisolated func phoneConnectivityDidReceive(session: WorkoutSession) {
        Task { @MainActor in
            self.applyWatchSession(session)
        }
    }

    nonisolated func phoneConnectivityDidReceiveQuickLogRequest(exerciseId: UUID?) {
        Task { @MainActor in
            self.handleWatchQuickLogRequest(exerciseId: exerciseId)
        }
    }

    nonisolated func phoneConnectivityDidReceiveLogSet(
        reps: Int,
        weightKg: Double?,
        actionId: UUID
    ) async -> Int {
        // actionId already deduped in PhoneConnectivity.
        _ = actionId
        return await handleWatchLogSet(reps: reps, weightKg: weightKg)
    }
}
