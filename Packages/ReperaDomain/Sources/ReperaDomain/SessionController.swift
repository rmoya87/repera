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

    /// True when the next exercise shares the same superseries group.
    public var nextIsSupersetPartner: Bool {
        guard session.exercises.indices.contains(session.currentIndex),
              let group = session.exercises[session.currentIndex].supersetGroup
        else { return false }
        let next = session.currentIndex + 1
        guard session.exercises.indices.contains(next) else { return false }
        return session.exercises[next].supersetGroup == group
    }

    public static func supersetLabel(_ group: Int?) -> String? {
        guard let group, group > 0 else { return nil }
        let letter = Character(UnicodeScalar(65 + ((group - 1) % 26))!)
        return "SS \(letter)"
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
                                exercise: exercise,
                                plannedSets: item.plannedSets,
                                supersetGroup: item.supersetGroup,
                                blockId: block.id,
                                blockKind: .strength,
                                wodFormat: block.wodFormat ?? .strength,
                                blockTimeCapMinutes: block.timeCapMinutes,
                                blockIntervalSeconds: block.emomIntervalSeconds,
                                blockRounds: block.rounds,
                                blockHeader: block.headerLabel,
                                blockWorkSeconds: block.workSeconds,
                                blockRestSeconds: block.restSeconds
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
                                exercise: exercise,
                                plannedSets: resolved.plannedSets(for: move),
                                blockId: resolved.id,
                                blockKind: .wod,
                                wodFormat: resolved.wodFormat,
                                blockTimeCapMinutes: resolved.timeCapMinutes,
                                blockIntervalSeconds: resolved.emomIntervalSeconds,
                                blockRounds: resolved.rounds,
                                blockHeader: resolved.headerLabel,
                                blockWorkSeconds: resolved.workSeconds,
                                blockRestSeconds: resolved.restSeconds
                            )
                        )
                    }
                }
            }
        } else {
            sessionExercises = routine.exercises.compactMap { item in
                guard let exercise = byId[item.exerciseId] else { return nil }
                return SessionExercise(
                    exercise: exercise,
                    plannedSets: item.plannedSets,
                    supersetGroup: item.supersetGroup
                )
            }
        }

        let title: String
        if let wod = routine.blocks.first(where: { $0.kind == .wod }) {
            title = "\(routine.title) · \(wod.headerLabel)"
        } else {
            title = routine.title
        }
        return WorkoutSession(title: title, routineId: routine.id, exercises: sessionExercises)
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
