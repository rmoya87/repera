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
    var isSyncingiCloud = false
    var lastiCloudSyncMessage: String?
    /// exerciseId → progression reason for the active session
    var progressionReasons: [UUID: String] = [:]
    var lastImportSummary: String?

    private let store = LocalStore.shared
    private let connectivity = PhoneConnectivity()

    var controller: SessionController? {
        guard let active = state.activeSession else { return nil }
        return SessionController(session: active)
    }

    var nextIsSupersetPartner: Bool {
        controller?.nextIsSupersetPartner ?? false
    }

    override init() {
        state = LocalStore.shared.load()
        super.init()
        iCloudStatus = LocalStore.shared.iCloudStatus
    }

    func bootstrap() {
        connectivity.delegate = self
        connectivity.activate()
        isWatchReachable = WCSession.default.isReachable
        stripSeededDemoPlanIfNeeded()
        enrichCatalogMetadata()
        mergeMissingSeedExercises()
        persist()
        Task { await refreshFromiCloud() }
    }

    /// Sincroniza metadata seed (grupo, instrucciones…) sin pisar custom/favoritos/id.
    private func enrichCatalogMetadata() {
        let seedByName = Dictionary(uniqueKeysWithValues: Catalog.seed().map { ($0.name, $0) })
        var changed = false
        for i in state.exercises.indices {
            guard !state.exercises[i].isCustom,
                  let fresh = seedByName[state.exercises[i].name]
            else { continue }
            let staleMeta = state.exercises[i].instructions.isEmpty
                || state.exercises[i].catalogId == nil
                || state.exercises[i].detailDescription != fresh.detailDescription
                || state.exercises[i].instructions != fresh.instructions
            let staleGroup = state.exercises[i].muscleGroup != fresh.muscleGroup
                || state.exercises[i].equipment != fresh.equipment
            guard staleMeta || staleGroup else { continue }
            let fav = state.exercises[i].isFavorite
            let id = state.exercises[i].id
            state.exercises[i] = Exercise(
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
                isFavorite: fav
            )
            changed = true
        }
        if changed { state.updatedAt = Date() }
    }

    /// Añade ejercicios nuevos del catálogo seed (p. ej. CrossFit) sin duplicar por nombre.
    private func mergeMissingSeedExercises() {
        let existing = Set(state.exercises.map(\.name))
        let missing = Catalog.seed().filter { !existing.contains($0.name) }
        guard !missing.isEmpty else { return }
        state.exercises.append(contentsOf: missing)
        state.updatedAt = Date()
    }

    /// Quita el plan Push/Pull/Legs de demo si el usuario no ha creado nada propio.
    private func stripSeededDemoPlanIfNeeded() {
        let demoTitles: Set<String> = ["Push", "Pull", "Legs", "Push 2", "Pull 2"]
        guard !state.routines.isEmpty,
              state.routines.allSatisfy({ demoTitles.contains($0.title) })
        else { return }
        state.routines = []
        state.updatedAt = Date()
    }

    // MARK: - Persistence

    func persist() {
        state.updatedAt = Date()
        store.save(state)
        iCloudStatus = store.iCloudStatus
    }

    func refreshFromiCloud() async {
        isSyncingiCloud = true
        defer { isSyncingiCloud = false }
        store.refreshICloudStatus()
        iCloudStatus = store.iCloudStatus
        guard iCloudStatus == .available else {
            lastiCloudSyncMessage = iCloudStatus == .signedOut
                ? "Inicia sesión en iCloud"
                : "iCloud no disponible aún"
            return
        }
        // Primero lee remoto (sin pisarlo). Gana el updatedAt más reciente; luego persiste el ganador.
        let localStamp = state.updatedAt
        if let newest = await store.syncFromiCloud() {
            if newest.updatedAt > localStamp {
                state = newest
                stripSeededDemoPlanIfNeeded()
                lastiCloudSyncMessage = "Datos restaurados desde iCloud"
            } else {
                store.save(state)
                lastiCloudSyncMessage = "Copia en iCloud actualizada"
            }
        } else {
            store.save(state)
            lastiCloudSyncMessage = "Copia en iCloud actualizada"
        }
        iCloudStatus = store.iCloudStatus
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
        persist()
        pushActiveToWatch()
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
        pushActiveToWatch()
        beginHealthTracking(for: ctrl.session)
    }

    /// Sesión freestyle desde OCR de pizarra/TV (sin progresión).
    @discardableResult
    func startSessionFromBoard(lines: [BoardImportLine], ocrText: String? = nil) -> Bool {
        var catalog = state.exercises
        let routine = BoardImportParser.buildRoutine(
            title: "Desde pizarra",
            lines: lines,
            catalog: &catalog,
            ocrText: ocrText
        )
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
        pushActiveToWatch()
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
        persist()
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
        state.activeSession = nil
        persist()
        connectivity.send(session: nil)

        if save {
            Task {
                let apple = await HealthKitStore.shared.finishWorkout(
                    sessionId: session.id,
                    title: session.title,
                    start: start,
                    end: end
                )
                session.appleActiveEnergyKcal = apple.kcal
                session.appleDurationSeconds = apple.durationSeconds
                session.healthKitWorkoutUUID = apple.workoutUUID
                session.finishedAt = end
                upsertWorkout(session)
                advanceRotationIfNeeded(finishedRoutineId: finishedRoutineId)
                persist()
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
        session.startedAt = startedAt
        session.finishedAt = finishedAt
        let trimmed = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        session.notes = (trimmed?.isEmpty == false) ? trimmed : nil
        upsertWorkout(session)
        advanceRotationIfNeeded(finishedRoutineId: routine.id)
        persist()
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
        state.workouts.removeAll { $0.id == id }
        persist()
    }

    var coachInsights: [CoachInsight] {
        CoachEngine.insights(state: state)
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
        pushActiveToWatch()
    }

    func applyWatchSession(_ session: WorkoutSession) {
        state.activeSession = session
        if session.phase == .finished {
            upsertWorkout(session)
            state.activeSession = nil
        }
        persist()
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
    }

    private func pushActiveToWatch() {
        connectivity.send(session: state.activeSession)
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
        persist()
    }

    func deleteExercise(_ id: UUID) {
        state.exercises.removeAll { $0.id == id && $0.isCustom }
        persist()
    }

    func toggleFavorite(_ id: UUID) {
        guard let i = state.exercises.firstIndex(where: { $0.id == id }) else { return }
        state.exercises[i].isFavorite.toggle()
        persist()
    }

    func loadPreference(for exerciseId: UUID) -> ExerciseLoadPreference {
        state.exerciseLoadPrefs[exerciseId.uuidString] ?? ExerciseLoadPreference()
    }

    func setLoadPreference(_ pref: ExerciseLoadPreference, for exerciseId: UUID) {
        state.exerciseLoadPrefs[exerciseId.uuidString] = pref
        persist()
    }

    /// Línea de discos bajo una serie, respetando preferencias de la ficha del ejercicio.
    func plateCompactLine(exerciseId: UUID, targetKg: Double) -> String? {
        let pref = loadPreference(for: exerciseId)
        guard pref.mode != .off else { return nil }
        let base: Double = {
            switch pref.mode {
            case .perSide:
                return pref.baseWeightKg > 0 ? pref.baseWeightKg : state.settings.barbellKg
            case .singleStack:
                return pref.baseWeightKg
            case .off:
                return 0
            }
        }()
        let solution = PlateMath.solve(
            targetKg: targetKg,
            baseKg: base,
            mode: pref.mode,
            availablePlatesKg: state.settings.ownedPlatesKg
        )
        return solution.compactLabel(mode: pref.mode)
    }

    func plateSummaryLine(exerciseId: UUID, targetKg: Double) -> String? {
        let pref = loadPreference(for: exerciseId)
        guard pref.mode != .off else { return nil }
        let base: Double = {
            switch pref.mode {
            case .perSide:
                return pref.baseWeightKg > 0 ? pref.baseWeightKg : state.settings.barbellKg
            case .singleStack:
                return pref.baseWeightKg
            case .off:
                return 0
            }
        }()
        let solution = PlateMath.solve(
            targetKg: targetKg,
            baseKg: base,
            mode: pref.mode,
            availablePlatesKg: state.settings.ownedPlatesKg
        )
        if pref.mode == .singleStack, !solution.perSide.isEmpty {
            let parts = solution.perSide.map { "\($0.countPerSide)×\(String(format: "%g", $0.plateKg))" }.joined(separator: " + ")
            return "Pila: \(parts) → \(String(format: "%g", solution.achievedKg)) kg"
        }
        return solution.summary
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

    func addBodyWeight(_ kg: Double, date: Date = Date(), syncToHealth: Bool = true) {
        state.bodyWeights.insert(BodyWeightEntry(date: date, weightKg: kg), at: 0)
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

    /// Si no hay peso en la app, usa Salud; si ambos existen, gana el más reciente y se refleja en el otro.
    func syncBodyWeightWithHealth() async {
        let health = HealthKitStore.shared
        await health.refreshToday()
        let appLatest = state.bodyWeights.max(by: { $0.date < $1.date })
        let hkKg = health.latestWeightKg
        let hkDate = health.latestWeightDate

        switch (appLatest, hkKg, hkDate) {
        case (nil, let kg?, let date?):
            addBodyWeight(kg, date: date, syncToHealth: false)
        case (let app?, let kg?, let date?) where date > app.date:
            addBodyWeight(kg, date: date, syncToHealth: false)
        case (let app?, _, _):
            await health.saveBodyMass(kg: app.weightKg, date: app.date)
        default:
            break
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
}
