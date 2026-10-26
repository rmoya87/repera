import Foundation

/// Puente entre el editor de bloques del plan y una sesión terminada.
/// Los sets registrados son la fuente de verdad: nunca se convierten objetivos
/// pendientes en repeticiones realizadas por el mero hecho de guardar.
public enum CompletedWorkoutEditing {
    public enum ScoreField: Sendable {
        case reps, rounds, minutes, seconds
    }

    /// Los históricos sin formato solo coinciden con un editor que registre
    /// la misma unidad; nunca usar reps como si fueran segundos o viceversa.
    private static func scoreMatches(_ result: WODBlockResult, format: WODFormat) -> Bool {
        if let recordedFormat = result.format { return recordedFormat == format }
        switch format.resultCapture {
        case .totalReps: return result.totalReps != nil || result.roundsCompleted != nil
        case .elapsedTime: return result.elapsedSeconds != nil
        case .perMovementSets: return false
        }
    }

    /// El editor necesita mostrar también los resultados WOD antiguos que
    /// se representaban como una única serie en el primer movimiento.
    /// Inferir el valor para editar NO escribe ni duplica series.
    public static func editableScore(
        for block: RoutineBlock, in session: WorkoutSession
    ) -> WODBlockResult? {
        guard let format = block.wodFormat,
              format.resultCapture != .perMovementSets else { return nil }
        if let saved = session.wodResults.last(where: {
            $0.id == block.id && scoreMatches($0, format: format)
        }) {
            return saved
        }
        guard format.resultCapture == .totalReps,
              let first = session.exercises.first(where: { $0.blockId == block.id }),
              first.loggedSets.count == 1,
              let set = first.loggedSets.first,
              set.weightKg == nil, set.deficitCm == nil else { return nil }
        return WODBlockResult(
            id: block.id, format: format, totalReps: set.reps,
            roundsCompleted: (format == .amrap || format == .deathBy) ? 0 : nil,
            wodTemplateId: block.wodTemplateId
        )
    }

    public static func scoreValue(
        for block: RoutineBlock, in session: WorkoutSession,
        field: ScoreField
    ) -> Int {
        let result = editableScore(for: block, in: session)
        switch field {
        case .reps: return result?.totalReps ?? 0
        case .rounds: return result?.roundsCompleted ?? 0
        case .minutes: return max(0, result?.elapsedSeconds ?? 0) / 60
        case .seconds: return max(0, result?.elapsedSeconds ?? 0) % 60
        }
    }

    /// Actualizar una marca COMPLETADA sin tocar la prescripción, los sets
    /// registrados, los UUID de Salud o los demás bloques del entrenamiento.
    /// También permite crear el primer resultado de un AMRAP histórico.
    public static func changingScore(
        in session: WorkoutSession, for block: RoutineBlock,
        field: ScoreField, value: Int
    ) -> WorkoutSession {
        guard let format = block.wodFormat,
              format.resultCapture != .perMovementSets else { return session }
        switch field {
        case .reps, .rounds:
            guard format.resultCapture == .totalReps else { return session }
        case .minutes, .seconds:
            guard format.resultCapture == .elapsedTime else { return session }
        }
        var updated = session
        var result = editableScore(for: block, in: session) ?? WODBlockResult(
            id: block.id, format: format,
            totalReps: format.resultCapture == .totalReps ? 0 : nil,
            elapsedSeconds: format.resultCapture == .elapsedTime ? 0 : nil,
            roundsCompleted: (format == .amrap || format == .deathBy) ? 0 : nil,
            wodTemplateId: block.wodTemplateId
        )
        result.format = format
        switch field {
        case .reps:
            result.totalReps = min(5000, max(0, value))
        case .rounds:
            guard format == .amrap || format == .deathBy else { return session }
            result.roundsCompleted = min(200, max(0, value))
        case .minutes:
            let seconds = max(0, result.elapsedSeconds ?? 0)
            result.elapsedSeconds = min(180, max(0, value)) * 60 + seconds % 60
        case .seconds:
            let seconds = max(0, result.elapsedSeconds ?? 0)
            result.elapsedSeconds = seconds / 60 * 60 + min(59, max(0, value))
        }
        // Un score de otro formato es un dato histórico, no se elimina
        // automáticamente al escribir la nueva marca del mismo bloque.
        updated.wodResults.removeAll {
            $0.id == block.id && scoreMatches($0, format: format)
        }
        updated.wodResults.append(result)
        return updated
    }

    public static func routine(from session: WorkoutSession, sourceRoutine: Routine? = nil) -> Routine {
        let sources = session.routineBlocks ?? sourceRoutine?.blocks ?? []
        var remaining = session.exercises
        var blocks: [RoutineBlock] = []

        for source in sources {
            let entries = remaining.filter { $0.blockId == source.id }
            remaining.removeAll { $0.blockId == source.id }
            var block = source
            // Algunos escaneos/históricos conservaron la marca global pero
            // no el formato del bloque en su snapshot editable. Recuperarlo
            // del resultado registrado evita perder el tiempo RFT o AMRAP
            // solo por abrir y volver a guardar el editor.
            if block.wodFormat == nil,
               let recordedFormat = session.wodResults.first(where: { $0.id == source.id })?.format,
               recordedFormat.resultCapture != .perMovementSets {
                block.wodFormat = recordedFormat
            }
            if source.kind == .strength {
                block.exercises = entries.enumerated().map { index, entry in
                    RoutineExercise(
                        id: entry.id,
                        exerciseId: entry.exercise.id,
                        plannedSets: block.wodFormat?.resultCapture == .totalReps
                            || block.wodFormat?.resultCapture == .elapsedTime
                            ? (source.exercises.indices.contains(index)
                                ? source.exercises[index].plannedSets : entry.plannedSets)
                            : visibleSets(for: entry),
                        quantityUnit: entry.quantityUnit,
                        restSeconds: source.exercises.indices.contains(index) ? source.exercises[index].restSeconds : nil
                    )
                }
                block.movements = []
            } else {
                var index = 0
                var movements: [WODMovement] = []
                for original in source.movements {
                    if original.isRest {
                        movements.append(original)
                    } else if entries.indices.contains(index) {
                        movements.append(movement(
                            for: entries[index], original: original,
                            preservePrescription: block.wodFormat?.resultCapture != .perMovementSets
                                && block.wodFormat != nil
                        ))
                        index += 1
                    }
                }
                for entry in entries.dropFirst(index) {
                    movements.append(movement(for: entry, original: nil))
                }
                block.movements = movements
                block.exercises = []
            }
            blocks.append(block)
        }

        // Históricos anteriores al snapshot (o ejercicios sin bloque).
        for entry in remaining {
            let blockID = entry.blockId ?? entry.id
            let kind = entry.blockKind ?? .strength
            if let index = blocks.firstIndex(where: { $0.id == blockID }) {
                if kind == .strength {
                    blocks[index].exercises.append(RoutineExercise(
                        id: entry.id, exerciseId: entry.exercise.id,
                        plannedSets: visibleSets(for: entry),
                        quantityUnit: entry.quantityUnit
                    ))
                } else {
                    blocks[index].movements.append(movement(for: entry, original: nil))
                }
            } else {
                var block = RoutineBlock(
                    id: blockID,
                    title: entry.blockHeader ?? "Bloque \(blocks.count + 1)",
                    kind: kind,
                    wodFormat: entry.wodFormat ?? session.wodResults.first(where: { $0.id == blockID })?.format,
                    timeCapMinutes: entry.blockTimeCapMinutes,
                    emomIntervalSeconds: entry.blockIntervalSeconds,
                    rounds: entry.blockRounds,
                    workSeconds: entry.blockWorkSeconds,
                    restSeconds: entry.blockRestSeconds,
                    restBetweenRoundsSeconds: entry.blockRestBetweenRoundsSeconds
                )
                if kind == .strength {
                    block.exercises = [RoutineExercise(
                        id: entry.id, exerciseId: entry.exercise.id,
                        plannedSets: visibleSets(for: entry),
                        quantityUnit: entry.quantityUnit
                    )]
                } else {
                    block.movements = [movement(for: entry, original: nil)]
                }
                blocks.append(block)
            }
        }
        return Routine(id: session.routineId ?? session.id, title: session.title, blocks: blocks)
    }

    /// Mantiene IDs, tiempos, ruta, HealthKit y técnicas registradas de los ejercicios
    /// que sobreviven al editor, incluso tras moverlos a otro bloque.
    public static func applying(
        _ routine: Routine,
        to original: WorkoutSession,
        catalog: [Exercise]
    ) -> WorkoutSession {
        var updated = original
        updated.title = routine.title
        updated.routineBlocks = routine.blocks
        var unused = original.exercises
        var output: [SessionExercise] = []

        for block in routine.blocks {
            let items: [(UUID, UUID?, String?, [PlannedSet], ExerciseQuantityUnit?)] =
                block.kind == .strength
                ? block.exercises.map { ($0.id, Optional($0.exerciseId), nil, $0.plannedSets, $0.quantityUnit) }
                : block.movements.filter { !$0.isRest }.map {
                    ($0.id, $0.exerciseId, $0.name, block.plannedSets(for: $0), $0.prescribedQuantityUnit)
                }
            for (itemID, exerciseID, name, sets, unit) in items {
                // ID de la sesión antes que nombre: distingue ejercicios repetidos y arrastres.
                let foundIndex = unused.firstIndex(where: { $0.id == itemID })
                    ?? unused.firstIndex(where: {
                        $0.blockId == block.id && (exerciseID == $0.exercise.id ||
                            (name != nil && $0.exercise.name.localizedCaseInsensitiveCompare(name!) == .orderedSame))
                    })
                let old = foundIndex.map { unused.remove(at: $0) }
                let exercise = exerciseID.flatMap { id in catalog.first(where: { $0.id == id }) }
                    ?? old?.exercise
                    ?? Exercise(name: name ?? "Ejercicio", muscleGroup: "Otros", isCustom: true)
                var entry = old ?? SessionExercise(id: itemID, exercise: exercise, plannedSets: sets)
                entry.exercise = exercise
                entry.plannedSets = sets
                entry.quantityUnit = unit
                entry.blockId = block.id
                entry.blockKind = block.kind
                entry.blockHeader = block.title
                entry.wodFormat = block.wodFormat
                entry.blockTimeCapMinutes = block.timeCapMinutes
                entry.blockIntervalSeconds = block.emomIntervalSeconds
                entry.blockRounds = block.rounds
                entry.blockWorkSeconds = block.workSeconds
                entry.blockRestSeconds = block.restSeconds
                entry.blockRestBetweenRoundsSeconds = block.restBetweenRoundsSeconds
                entry.supersetGroup = nil
                // Los sets completados no se reconstruyen al editar la
                // prescripción de un WOD con resultado GLOBAL. Son dos hechos
                // diferentes y ambos deben persistir sin contaminarse.
                if let old, !old.loggedSets.isEmpty,
                   block.wodFormat == nil || block.wodFormat?.resultCapture == .perMovementSets {
                    // El editor mezcla series realizadas y pendientes. Solo los
                    // UUID ya registrados representan resultados: una serie nueva
                    // o aún sin confirmar NO puede convertirse en LoggedSet.
                    entry.loggedSets = sets.compactMap { set -> LoggedSet? in
                        guard let previous = old.loggedSets.first(where: { $0.id == set.id }) else {
                            return nil
                        }
                        var edited = previous
                        edited.reps = max(0, set.targetReps)
                        if exercise.loadField == .deficitCm {
                            edited.deficitCm = set.targetWeightKg.map { Int($0.rounded()) }
                            edited.weightKg = nil
                        } else {
                            edited.weightKg = set.targetWeightKg
                            edited.deficitCm = nil
                        }
                        edited.durationSeconds = set.targetDurationSeconds
                        edited.rir = set.targetRir
                        edited.toFailure = set.targetRir == 0 && previous.toFailure
                        edited.quantityUnit = unit ?? previous.quantityUnit
                        return edited
                    }
                    entry.completedReps = entry.loggedSets.filter { $0.phase == .work }
                        .reduce(0) { $0 + $1.reps + $1.drops.reduce(0) { $0 + $1.reps } }
                }
                // Ejercicio añadido: sigue pendiente hasta que existan sets de verdad.
                output.append(entry)
            }
        }
        updated.exercises = output
        updated.currentIndex = output.isEmpty ? 0 : min(original.currentIndex, output.count - 1)
        updated.wodResults = updated.wodResults.compactMap { saved in
            // Cambiar el formato de un bloque NO debe borrar un resultado real.
            // Puede convivir una marca AMRAP antigua con otra RFT posterior;
            // cada una mantiene su formato original y sus unidades.
            guard let block = routine.blocks.first(where: { $0.id == saved.id }) else {
                // Borrar el bloque es una acción explícita: se borra su resultado.
                return nil
            }
            guard let currentFormat = block.wodFormat else { return saved }
            var result = saved
            if result.format == nil {
                // Históricos sin formato: recuperar el formato de la sesión.
                result.format = original.routineBlocks?
                    .first(where: { $0.id == saved.id })?.wodFormat
                    ?? original.exercises.first(where: { $0.blockId == saved.id })?.wodFormat
            }
            if let recordedFormat = result.format, recordedFormat != currentFormat {
                return result
            }
            // Sin formato fiable, conservar el valor aunque su tipo de score
            // ya no corresponda al nuevo formato. Jamás convertir segundos a reps.
            if currentFormat.resultCapture == .elapsedTime && result.elapsedSeconds == nil {
                return result
            }
            if currentFormat.resultCapture == .totalReps &&
                result.totalReps == nil && result.roundsCompleted == nil {
                return result
            }
            if currentFormat.resultCapture == .perMovementSets { return result }
            result.format = currentFormat
            return result
        }
        // La sesión sigue finalizada; no modifica la plantilla de programación.
        return updated
    }

    private static func visibleSets(for entry: SessionExercise) -> [PlannedSet] {
        guard !entry.loggedSets.isEmpty else { return entry.plannedSets }
        // En Play se pueden completar solo algunas series y añadir otras.
        // Presentar las realizadas con su UUID original para editarlas,
        // conservando detrás las pendientes con sus valores y metadatos Rx.
        // Los LoggedSet históricos tienen UUID distinto del PlannedSet:
        // su correspondencia se realiza por la posición registrada, no por
        // la identidad de una prescripción que ya pudo ser modificada.
        var visible = entry.plannedSets
        for (index, performed) in entry.loggedSets.enumerated() {
            let set = PlannedSet(
                id: performed.id,
                targetReps: performed.reps,
                targetWeightKg: performed.deficitCm.map(Double.init) ?? performed.weightKg,
                targetDurationSeconds: performed.durationSeconds,
                targetRir: performed.rir
            )
            if visible.indices.contains(index) {
                visible[index] = set
            } else {
                visible.append(set)
            }
        }
        return visible
    }

    private static func movement(
        for entry: SessionExercise,
        original: WODMovement?,
        preservePrescription: Bool = false
    ) -> WODMovement {
        let sets = preservePrescription
            ? (original?.explicitPlannedSets ?? entry.plannedSets)
            : visibleSets(for: entry)
        return WODMovement(
            id: entry.id,
            exerciseId: entry.exercise.id,
            name: entry.exercise.name,
            reps: sets.first?.targetReps,
            repScheme: sets.count > 1 ? sets.map(\.targetReps) : nil,
            distanceMeters: entry.quantityUnit == .meters ? sets.first?.targetReps : nil,
            calories: entry.quantityUnit == .calories ? sets.first?.targetReps : nil,
            weightMaleKg: original?.weightMaleKg ?? sets.first?.targetWeightKg,
            weightFemaleKg: original?.weightFemaleKg,
            scaleAlternative: original?.scaleAlternative,
            notes: original?.notes,
            explicitPlannedSets: sets
        )
    }
}
