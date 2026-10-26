import Foundation

public struct SessionController: Sendable {
    public private(set) var session: WorkoutSession

    public init(session: WorkoutSession) {
        self.session = session
    }

    public mutating func startOnPhone() {
        guard !session.exercises.isEmpty else { return }
        session.phase = .ready
        session.startedAt = session.startedAt ?? Date()
        session.finishedAt = nil
        session.currentIndex = min(session.currentIndex, session.exercises.count - 1)
    }

    public mutating func confirmCurrentExercise() {
        guard session.phase == .ready || session.phase == .counting else { return }
        guard session.currentExercise != nil else { return }
        session.phase = .counting
        session.exercises[session.currentIndex].completedReps = 0
    }

    public mutating func selectExercise(at index: Int) {
        guard session.exercises.indices.contains(index) else { return }
        session.currentIndex = index
        session.phase = .ready
    }

    public mutating func setRepCount(_ count: Int) {
        guard session.phase == .counting else { return }
        guard session.exercises.indices.contains(session.currentIndex) else { return }
        session.exercises[session.currentIndex].completedReps = max(0, count)
    }

    public mutating func adjustReps(_ delta: Int) {
        guard session.phase == .counting else { return }
        guard session.exercises.indices.contains(session.currentIndex) else { return }
        let next = session.exercises[session.currentIndex].completedReps + delta
        session.exercises[session.currentIndex].completedReps = max(0, next)
    }

    public mutating func logSet(
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
        guard session.exercises.indices.contains(session.currentIndex) else { return }
        let set = LoggedSet(
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
        session.exercises[session.currentIndex].loggedSets.append(set)
        if phase == .work {
            session.exercises[session.currentIndex].completedReps += set.reps
            if set.kind == .dropset {
                session.exercises[session.currentIndex].completedReps += set.drops.reduce(0) { $0 + $1.reps }
            }
        }
        if session.phase == .ready {
            session.phase = .counting
        }
    }

    /// Editing a previously confirmed set preserves its identity, timestamp,
    /// metadata and scoring; a swipe alone never creates another set.
    @discardableResult
    public mutating func reviseLoggedSet(at index: Int, reps: Int, weightKg: Double?) -> Bool {
        guard session.exercises.indices.contains(session.currentIndex),
              session.exercises[session.currentIndex].loggedSets.indices.contains(index) else {
            return false
        }
        var revised = session.exercises[session.currentIndex].loggedSets[index]
        revised.reps = max(0, reps)
        revised.weightKg = weightKg
        return replaceLoggedSet(at: index, with: revised)
    }

    /// Edit every iPhone-equivalent field while preserving the original set UUID,
    /// timestamp and order. A Watch edit must never append a second set.
    @discardableResult
    public mutating func replaceLoggedSet(at index: Int, with set: LoggedSet) -> Bool {
        guard session.exercises.indices.contains(session.currentIndex),
              session.exercises[session.currentIndex].loggedSets.indices.contains(index),
              session.exercises[session.currentIndex].loggedSets[index].id == set.id
        else { return false }
        session.exercises[session.currentIndex].loggedSets[index] = set
        let savedSets = session.exercises[session.currentIndex].loggedSets
        session.exercises[session.currentIndex].completedReps =
            savedSets.reduce(into: 0) { count, saved in
                guard saved.phase == .work else { return }
                count += saved.reps
                if saved.kind == .dropset {
                    count += saved.drops.reduce(0) { $0 + $1.reps }
                }
            }
        return true
    }

    public mutating func removeLastLoggedSet() {
        guard session.exercises.indices.contains(session.currentIndex) else { return }
        guard let removed = session.exercises[session.currentIndex].loggedSets.popLast() else { return }
        session.exercises[session.currentIndex].completedReps = max(
            0,
            session.exercises[session.currentIndex].completedReps - removed.reps
        )
    }

    @discardableResult
    public mutating func finishCurrentExercise() -> Bool {
        guard session.phase == .counting || session.phase == .ready else { return false }
        guard session.exercises.indices.contains(session.currentIndex) else { return false }

        session.exercises[session.currentIndex].isCompleted = true
        let nextIndex = session.currentIndex + 1
        if nextIndex < session.exercises.count {
            session.currentIndex = nextIndex
            session.phase = .ready
            return true
        } else {
            finishWorkout()
            return false
        }
    }

    /// Store a confirmed WOD score without manufacturing movement sets.
    public mutating func recordWODResult(_ result: WODBlockResult) {
        session.wodResults.removeAll { $0.id == result.id }
        session.wodResults.append(result)
    }

    /// Al agotar un EMOM/Tabata/cap se termina el bloque de movimientos,
    /// pero no se registran series ficticias ni pesos que el atleta no confirmó.
    @discardableResult
    public mutating func finishCurrentBlock() -> Bool {
        guard session.phase == .counting || session.phase == .ready,
              session.exercises.indices.contains(session.currentIndex) else { return false }

        let start = session.currentIndex
        let blockID = session.exercises[start].blockId
        // The athlete can switch between movements during an interval block.
        // Finish the entire block, including movements before currentIndex.
        if let blockID {
            for i in session.exercises.indices where session.exercises[i].blockId == blockID {
                session.exercises[i].isCompleted = true
            }
        } else {
            session.exercises[start].isCompleted = true
        }
        var end = start + 1
        while end < session.exercises.count &&
              blockID != nil &&
              session.exercises[end].blockId == blockID {
            end += 1
        }

        if end < session.exercises.count {
            session.currentIndex = end
            session.phase = .ready
            return true
        }
        finishWorkout()
        return false
    }

    public mutating func finishWorkout() {
        for i in session.exercises.indices {
            if !session.exercises[i].loggedSets.isEmpty {
                session.exercises[i].isCompleted = true
            }
        }
        session.phase = .finished
        session.finishedAt = Date()
    }

    /// Una serie anotada se guarda en cuanto cambia su valor: no requiere
    /// pulsar un check para contarse en el entrenamiento. Los IDs y fechas
    /// permiten modificarla sin duplicar el registro.
    @discardableResult
    public mutating func replaceRecordedSets(
        exerciseID: UUID, sets: [LoggedSet]
    ) -> Bool {
        guard let index = session.exercises.firstIndex(where: { $0.id == exerciseID }),
              session.exercises[index].loggedSets != sets else { return false }
        session.exercises[index].loggedSets = sets
        session.exercises[index].completedReps = sets
            .filter { $0.phase == .work }
            .reduce(0) { count, set in
                count + set.reps + (set.kind == .dropset
                    ? set.drops.reduce(0) { $0 + $1.reps } : 0)
            }
        return true
    }

    /// Play conserva también las series editadas que todavía no se han
    /// marcado como hechas. Los resultados `loggedSets` siguen siendo la
    /// verdad de las series completadas y no se generan registros ficticios.
    @discardableResult
    public mutating func updateExerciseDraft(
        id: UUID, plannedSets: [PlannedSet], quantityUnit: ExerciseQuantityUnit?
    ) -> Bool {
        // Un borrado por swipe también puede eliminar la última serie.
        // Persistir [] en la sesión y su bloque evita reponer una prescripción
        // que el atleta ha eliminado expresamente.
        guard let index = session.exercises.firstIndex(where: { $0.id == id })
        else { return false }
        let current = session.exercises[index]
        guard current.plannedSets != plannedSets || current.quantityUnit != quantityUnit else { return false }
        session.exercises[index].plannedSets = plannedSets
        session.exercises[index].quantityUnit = quantityUnit

        if var blocks = session.routineBlocks, let blockID = current.blockId,
           let blockIndex = blocks.firstIndex(where: { $0.id == blockID }) {
            if blocks[blockIndex].kind == .strength {
                // Nuevas sesiones: ID de sesión = ID del ítem de la rutina.
                // Sesiones antiguas: utilizar la posición de la ocurrencia para
                // no sobrescribir otro ejercicio repetido en el mismo bloque.
                let matches = blocks[blockIndex].exercises.indices.filter {
                    blocks[blockIndex].exercises[$0].exerciseId == current.exercise.id
                }
                let occurrence = session.exercises.prefix(index).filter {
                    $0.blockId == blockID && $0.exercise.id == current.exercise.id
                }.count
                if let itemIndex = blocks[blockIndex].exercises.firstIndex(where: { $0.id == id })
                    ?? (matches.indices.contains(occurrence) ? matches[occurrence] : nil) {
                    blocks[blockIndex].exercises[itemIndex].plannedSets = plannedSets
                    blocks[blockIndex].exercises[itemIndex].quantityUnit = quantityUnit
                }
            } else {
                let matches = blocks[blockIndex].movements.indices.filter {
                    let item = blocks[blockIndex].movements[$0]
                    return item.exerciseId == current.exercise.id
                        || item.name.localizedCaseInsensitiveCompare(current.exercise.name) == .orderedSame
                }
                let occurrence = session.exercises.prefix(index).filter {
                    $0.blockId == blockID && $0.exercise.name.localizedCaseInsensitiveCompare(current.exercise.name) == .orderedSame
                }.count
                if let itemIndex = blocks[blockIndex].movements.firstIndex(where: { $0.id == id })
                    ?? (matches.indices.contains(occurrence) ? matches[occurrence] : nil) {
                    // Los valores editados pasan a tener prioridad frente a
                    // rondas/repScheme sin cambiar los resultados del WOD.
                    blocks[blockIndex].movements[itemIndex].explicitPlannedSets = plannedSets
                }
            }
            session.routineBlocks = blocks
        }
        return true
    }

    public static func from(routine: Routine, exercises: [Exercise]) -> WorkoutSession {
        let byId = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
        var sessionExercises: [SessionExercise] = []

        // Respetar el orden de bloques (fuerza + WODs) y conservar tiempos de cada bloque.
        if !routine.blocks.isEmpty {
            for block in routine.blocks {
                switch block.kind {
                case .strength:
                    for item in block.exercises {
                        guard let exercise = byId[item.exerciseId] else { continue }
                        sessionExercises.append(
                            SessionExercise(
                                id: item.id,
                                exercise: exercise,
                                plannedSets: item.plannedSets,
                                quantityUnit: item.quantityUnit,
                                restSeconds: item.restSeconds,
                                supersetGroup: nil,
                                blockId: block.id,
                                blockKind: .strength,
                                wodFormat: block.wodFormat,
                                blockTimeCapMinutes: block.timeCapMinutes,
                                blockIntervalSeconds: block.emomIntervalSeconds,
                                blockRounds: block.rounds,
                                blockHeader: block.title,
                                blockWorkSeconds: block.workSeconds,
                                blockRestSeconds: block.restSeconds,
                                blockRestBetweenRoundsSeconds: block.restBetweenRoundsSeconds
                            )
                        )
                    }
                case .wod:
                    var resolved = block
                    resolved.deriveEmomRoundsIfNeeded()
                    for move in resolved.movements where !move.isRest {
                        let exercise: Exercise
                        let canonical = CrossFitGlossary.resolveCatalogName(move.name, notes: move.notes)
                        if let id = move.exerciseId, let ex = byId[id] {
                            exercise = ex
                        } else if let match = byId.values.first(where: {
                            ExerciseEquivalence.sameName($0.name, move.name)
                                || ExerciseEquivalence.sameName($0.name, canonical)
                        }) {
                            exercise = match
                        } else {
                            // Nombre canónico → miniaturas (`ExerciseArt.nameMap`) aunque no esté en catálogo.
                            exercise = Exercise(name: canonical, muscleGroup: "WOD", isCustom: true)
                        }
                        sessionExercises.append(
                            SessionExercise(
                                id: move.id,
                                exercise: exercise,
                                plannedSets: resolved.plannedSets(for: move),
                                quantityUnit: exercise.loggingStyle == .machineWork ? move.prescribedQuantityUnit : nil,
                                blockId: resolved.id,
                                blockKind: .wod,
                                wodFormat: resolved.wodFormat,
                                blockTimeCapMinutes: resolved.timeCapMinutes,
                                blockIntervalSeconds: resolved.emomIntervalSeconds,
                                blockRounds: resolved.rounds,
                                blockHeader: resolved.title,
                                blockWorkSeconds: resolved.workSeconds,
                                blockRestSeconds: resolved.restSeconds,
                                blockRestBetweenRoundsSeconds: resolved.restBetweenRoundsSeconds
                            )
                        )
                    }
                }
            }
        } else {
            sessionExercises = routine.exercises.compactMap { item in
                guard let exercise = byId[item.exerciseId] else { return nil }
                return SessionExercise(
                    id: item.id,
                    exercise: exercise,
                    plannedSets: item.plannedSets,
                    restSeconds: item.restSeconds,
                    supersetGroup: nil
                )
            }
        }

        let title: String
        if let wod = routine.blocks.first(where: { $0.kind == .wod }) {
            title = "\(routine.title) · \(wod.headerLabel)"
        } else {
            title = routine.title
        }
        return WorkoutSession(title: title, routineId: routine.id, exercises: sessionExercises, routineBlocks: routine.blocks)
    }

    /// Commits the current live rep counter as one logged set (Watch flow).
    public mutating func commitWatchRepsAsSet(weightKg: Double?) {
        guard session.exercises.indices.contains(session.currentIndex) else { return }
        let reps = session.exercises[session.currentIndex].completedReps
        guard reps > 0 else { return }
        session.exercises[session.currentIndex].loggedSets.append(
            LoggedSet(reps: reps, weightKg: weightKg)
        )
    }

    public static func demoPushPull() -> WorkoutSession {
        let exercises = Catalog.seed()
        let routine = Catalog.defaultWeekPlan(exercises: exercises).first
            ?? Routine(title: "Sesión", exercises: [])
        return from(routine: routine, exercises: exercises)
    }
}
