import Foundation
import GymbroDomain
import Observation
import WatchConnectivity

@Observable
@MainActor
final class GymbroStore: NSObject {
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

    private let store = LocalStore.shared
    private let connectivity = PhoneConnectivity()
    private var watchPushTask: Task<Void, Never>?

    func bumpCatalogEpoch() { catalogEpoch &+= 1 }
    func bumpWorkoutsEpoch() { workoutsEpoch &+= 1; statsCache.invalidate() }
    func bumpSessionEpoch() { sessionEpoch &+= 1 }

    var controller: SessionController? {
        guard let active = state.activeSession else { return nil }
        return SessionController(session: active)
    }

    var nextIsSupersetPartner: Bool {
        controller?.nextIsSupersetPartner ?? false
    }

    override init() {
        // Same idea as HealthDiskCache: paint Gymbro workouts on first frame (not after hydrate).
        if let painted = LaunchWarmup.appStateForFirstPaint() {
            state = painted
            isHydrated = true
            catalogEpoch = 1
            workoutsEpoch = 1
            sessionEpoch = 1
            syncPhase = .awaitingRemote
            LaunchTiming.mark("GymbroStore.init(diskPaint workouts=\(painted.workouts.count))")
        } else {
            state = LocalStore.shared.emptyShellState()
            syncPhase = .loadingLocal
            LaunchTiming.mark("GymbroStore.init(shell)")
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
            if dirty {
                catalogEpoch &+= 1
                // Local only until iCloud recovery completes — never upload seed over undownloaded cloud.
                persistLocalOnly(immediate: true)
            }
            LaunchTiming.span("bootstrap.catalogMerge", from: t0)
            await completeInitialRemoteSync()
        }
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
                  let fresh = seedByName[exercises[i].name]
            else { continue }
            let staleMeta = exercises[i].instructions.isEmpty
                || exercises[i].catalogId == nil
                || exercises[i].detailDescription != fresh.detailDescription
                || exercises[i].instructions != fresh.instructions
            let staleGroup = exercises[i].muscleGroup != fresh.muscleGroup
                || exercises[i].equipment != fresh.equipment
                || exercises[i].sportTag != fresh.sportTag
            guard staleMeta || staleGroup else { continue }
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
        let existing = Set(exercises.map(\.name))
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

    /// After Gymbro workout list changes, refresh Salud activities with the new exclusion set.
    private func scheduleHealthActivitiesResync() {
        let linked = Set(state.workouts.compactMap(\.healthKitWorkoutUUID))
        let sessions = state.workouts
        Task(priority: .utility) { @MainActor in
            let health = HealthKitStore.shared
            guard health.isAuthorized else { return }
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
            StatsEngine.history(for: exerciseId, workouts: state.workouts)
        }
    }

    func cachedLastWorkingSession(for exerciseId: UUID) -> ExerciseLastSession? {
        statsCache.lastSession(exerciseId: exerciseId, revision: state.syncRevision) {
            StatsEngine.lastWorkingSession(for: exerciseId, workouts: state.workouts)
        }
    }

    func cachedLastWorkingWeight(for exerciseId: UUID) -> Double? {
        statsCache.lastWorkingWeight(exerciseId: exerciseId, revision: state.syncRevision) {
            StatsEngine.lastWorkingWeight(exerciseId: exerciseId, workouts: state.workouts)
        }
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
            exercises: Catalog.seed(),
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
        let base = SessionController.from(routine: routine, exercises: state.exercises)
        let applied = ProgressionEngine.applySuggestions(
            to: base,
            routine: routine,
            workouts: state.workouts,
            defaultPolicy: state.settings.defaultProgression,
            incrementKg: state.settings.weightIncrementKg
        )
        progressionReasons = applied.1
        var ctrl = SessionController(session: applied.0)
        ctrl.startOnPhone()
        state.activeSession = ctrl.session
        persist()
        pushActiveToWatch(immediate: true)
        beginHealthTracking(for: ctrl.session)
    }

    /// Sesión freestyle desde OCR de pizarra/TV (sin progresión).
    @discardableResult
    func startSessionFromBoard(
        lines: [BoardImportLine],
        ocrText: String? = nil,
        blocks: [RoutineBlock]? = nil
    ) -> Bool {
        var catalog = state.exercises
        var routine = BoardImportParser.buildRoutine(
            title: "Añadir entreno",
            lines: lines,
            catalog: &catalog,
            ocrText: ocrText
        )
        if let blocks, !blocks.isEmpty {
            routine.blocks = blocks
        }
        for i in routine.blocks.indices {
            routine.blocks[i].deriveEmomRoundsIfNeeded()
        }
        state.exercises = catalog
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
        var catalog = state.exercises
        var imported = BoardImportParser.buildRoutine(
            title: planName,
            lines: lines,
            catalog: &catalog,
            ocrText: ocrText
        )
        state.exercises = catalog
        if let blocks, !blocks.isEmpty {
            imported.blocks = blocks
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
        // Clearing active session only — workout row lands after HK finish (or discard).
        persist()
        pushActiveToWatch(immediate: true)

        if save {
            let volume = session.totalVolumeKg
            let fallbackKcal = HealthKitStore.estimateActiveEnergyKcal(
                durationMinutes: max(1, end.timeIntervalSince(start) / 60),
                volumeKg: volume
            )
            Task {
                let apple = await HealthKitStore.shared.finishWorkout(
                    sessionId: session.id,
                    title: session.title,
                    start: start,
                    end: end,
                    fallbackKcal: fallbackKcal
                )
                session.startedAt = apple.startedAt
                session.finishedAt = apple.finishedAt
                session.appleActiveEnergyKcal = apple.kcal
                session.appleDurationSeconds = apple.durationSeconds
                session.healthKitWorkoutUUID = apple.workoutUUID
                upsertWorkout(session)
                advanceRotationIfNeeded(finishedRoutineId: finishedRoutineId)
                persistWorkouts()
            }
        } else {
            Task { await HealthKitStore.shared.discardLiveTracking() }
        }
    }

    /// Guarda un entreno ya terminado a partir de resultados apuntados (sin seguir la sesión en vivo).
    @discardableResult
    func logFinalResults(
        from routine: Routine,
        exercises: [SessionExercise],
        notes: String? = nil,
        startedAt: Date = Date(),
        finishedAt: Date = Date()
    ) -> WorkoutSession {
        var session = SessionController.from(routine: routine, exercises: state.exercises)
        // Emparejar por posición (mismo orden que el plan).
        for i in session.exercises.indices {
            guard exercises.indices.contains(i) else { continue }
            let draft = exercises[i]
            session.exercises[i].loggedSets = draft.loggedSets
            session.exercises[i].completedReps = draft.loggedSets
                .filter { !$0.isWarmup }
                .reduce(0) { $0 + $1.reps }
            session.exercises[i].isCompleted = !draft.loggedSets.isEmpty
        }
        session.phase = .finished
        let safeStart = startedAt
        let safeEnd = max(finishedAt, startedAt.addingTimeInterval(60))
        session.startedAt = safeStart
        session.finishedAt = safeEnd
        let trimmed = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        session.notes = (trimmed?.isEmpty == false) ? trimmed : nil
        upsertWorkout(session)
        advanceRotationIfNeeded(finishedRoutineId: routine.id)
        persistWorkouts()

        let volume = session.totalVolumeKg
        let fallbackKcal = HealthKitStore.estimateActiveEnergyKcal(
            durationMinutes: max(1, safeEnd.timeIntervalSince(safeStart) / 60),
            volumeKg: volume
        )
        let sessionId = session.id
        let title = session.title
        Task {
            let apple = await HealthKitStore.shared.finishWorkout(
                sessionId: sessionId,
                title: title,
                start: safeStart,
                end: safeEnd,
                fallbackKcal: fallbackKcal
            )
            if var updated = state.workouts.first(where: { $0.id == sessionId }) {
                updated.startedAt = apple.startedAt
                updated.finishedAt = apple.finishedAt
                updated.appleActiveEnergyKcal = apple.kcal
                updated.appleDurationSeconds = apple.durationSeconds
                updated.healthKitWorkoutUUID = apple.workoutUUID
                upsertWorkout(updated)
                persistWorkouts()
            }
        }
        return session
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
            // Misma ruta que Terminar: Apple Salud / Watch mandan kcal y tiempo.
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

    func selectExercise(at index: Int) {
        mutateActive { $0.selectExercise(at: index) }
    }

    func logSet(
        reps: Int,
        weightKg: Double?,
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
        upsertWorkout(session)
        persistWorkouts()

        let volume = session.totalVolumeKg
        let fallbackKcal = HealthKitStore.estimateActiveEnergyKcal(
            durationMinutes: max(1, now.timeIntervalSince(start) / 60),
            volumeKg: volume
        )
        let sessionId = session.id
        let title = session.title
        Task {
            let apple = await HealthKitStore.shared.finishWorkout(
                sessionId: sessionId,
                title: title,
                start: start,
                end: now,
                fallbackKcal: fallbackKcal
            )
            if var updated = state.workouts.first(where: { $0.id == sessionId }) {
                updated.startedAt = apple.startedAt
                updated.finishedAt = apple.finishedAt
                updated.appleActiveEnergyKcal = apple.kcal
                updated.appleDurationSeconds = apple.durationSeconds
                updated.healthKitWorkoutUUID = apple.workoutUUID
                upsertWorkout(updated)
                persistWorkouts()
            }
        }
        return session
    }

    /// Actualiza un entreno ya terminado (detalle / edición desde Inicio).
    func saveWorkout(_ session: WorkoutSession) {
        var draft = session
        if let start = draft.startedAt, let end = draft.finishedAt, end < start {
            draft.finishedAt = start.addingTimeInterval(60)
        }
        upsertWorkout(draft)
        persistWorkouts()
    }

    func removeLastSet() {
        mutateActive { $0.removeLastLoggedSet() }
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
        state.activeSession = session
        if session.phase == .finished {
            upsertWorkout(session)
            state.activeSession = nil
            persistWorkouts()
            pushActiveToWatch(immediate: true)
        } else {
            persist()
            pushActiveToWatch(immediate: true)
        }
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

    private func sendWatchContextNow() {
        connectivity.send(
            session: state.activeSession,
            quickLogHint: quickLogHintPayload(),
            sessionRevision: state.syncRevision
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

    func saveRoutine(_ routine: Routine) {
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
    }

    func deleteRoutine(_ id: UUID) {
        state.routines.removeAll { $0.id == id }
        if var rotation = state.rotation {
            rotation.routineIds.removeAll { $0 == id }
            state.rotation = rotation.routineIds.isEmpty ? nil : rotation
        }
        persist()
    }

    /// Quita todas las asignaciones de días; conserva plantillas de Rutinas y entrenos sueltos.
    func clearWeeklySchedule() {
        for i in state.routines.indices where state.routines[i].scheduledDate == nil {
            state.routines[i].weekday = nil
        }
        state.rotation = nil
        persist()
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
                        supersetGroup: $0.supersetGroup
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

    func addCustomExercise(
        name: String,
        muscleGroup: String,
        equipment: String?,
        targetMuscle: String? = nil,
        secondaryMuscles: [String] = [],
        bodyPart: String? = nil,
        detailDescription: String? = nil,
        instructions: [String] = []
    ) {
        let exercise = Exercise(
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
            blocks: [.strength(title: "Bloque", exercises: [item])],
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
    }

    // MARK: - Body weight

    /// Un pesaje por día calendario: si ya hay uno ese día, lo actualiza.
    func addBodyWeight(_ kg: Double, date: Date = Date(), syncToHealth: Bool = true) {
        let cal = Calendar.current
        if let idx = state.bodyWeights.firstIndex(where: { cal.isDate($0.date, inSameDayAs: date) }) {
            state.bodyWeights[idx].date = date
            state.bodyWeights[idx].weightKg = kg
        } else {
            state.bodyWeights.insert(BodyWeightEntry(date: date, weightKg: kg), at: 0)
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

    /// Colapsa varios pesajes del mismo día dejando el más reciente.
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
                    changed = true
                }
            } else {
                state.bodyWeights.insert(BodyWeightEntry(date: sample.date, weightKg: sample.kg), at: 0)
                changed = true
            }
        }

        if changed {
            state.bodyWeights.sort { $0.date > $1.date }
            persist()
        }

        // Días solo en Gymbro → Salud.
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

extension GymbroStore: PhoneConnectivityDelegate {
    nonisolated func phoneConnectivityDidUpdateReachability(_ reachable: Bool) {
        Task { @MainActor in
            self.isWatchReachable = reachable
        }
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
