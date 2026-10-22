import Foundation

/// Puente entre el editor de bloques del plan y una sesión terminada.
/// Los sets registrados son la fuente de verdad: nunca se convierten objetivos
/// pendientes en repeticiones realizadas por el mero hecho de guardar.
public enum CompletedWorkoutEditing {
    public static func routine(from session: WorkoutSession, sourceRoutine: Routine? = nil) -> Routine {
        let sources = session.routineBlocks ?? sourceRoutine?.blocks ?? []
        var remaining = session.exercises
        var blocks: [RoutineBlock] = []

        for source in sources {
            let entries = remaining.filter { $0.blockId == source.id }
            remaining.removeAll { $0.blockId == source.id }
            var block = source
            if source.kind == .strength {
                block.exercises = entries.enumerated().map { index, entry in
                    RoutineExercise(
                        id: entry.id,
                        exerciseId: entry.exercise.id,
                        plannedSets: visibleSets(for: entry),
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
                        movements.append(movement(for: entries[index], original: original))
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
                    wodFormat: entry.wodFormat,
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
                var entry = old ?? SessionExercise(exercise: exercise, plannedSets: sets)
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
                if let old, !old.loggedSets.isEmpty {
                    entry.loggedSets = sets.map { set in
                        if let previous = old.loggedSets.first(where: { $0.id == set.id }) {
                            var edited = previous
                            edited.reps = max(0, set.targetReps)
                            if exercise.loadField == .deficitCm {
                                edited.deficitCm = set.targetWeightKg.map { Int($0.rounded()) }
                                edited.weightKg = nil
                            } else {
                                edited.weightKg = set.targetWeightKg
                            }
                            edited.rir = set.targetRir
                            edited.toFailure = set.targetRir == 0 && previous.toFailure
                            edited.quantityUnit = unit ?? previous.quantityUnit
                            return edited
                        }
                        return LoggedSet(
                            id: set.id,
                            reps: max(0, set.targetReps),
                            weightKg: exercise.loadField == .deficitCm ? nil : set.targetWeightKg,
                            deficitCm: exercise.loadField == .deficitCm
                                ? set.targetWeightKg.map { Int($0.rounded()) } : nil,
                            quantityUnit: unit,
                            completedAt: original.finishedAt ?? Date(),
                            rir: set.targetRir
                        )
                    }
                    entry.completedReps = entry.loggedSets.filter { !$0.isWarmup }
                        .reduce(0) { $0 + $1.reps + $1.drops.reduce(0) { $0 + $1.reps } }
                }
                // Ejercicio añadido: sigue pendiente hasta que existan sets de verdad.
                output.append(entry)
            }
        }
        updated.exercises = output
        updated.currentIndex = output.isEmpty ? 0 : min(original.currentIndex, output.count - 1)
        updated.wodResults = updated.wodResults.compactMap { result in
            guard let block = routine.blocks.first(where: { $0.id == result.id && $0.kind == .wod }),
                  let format = block.wodFormat,
                  format.resultCapture != .perMovementSets,
                  result.format == nil || result.format == format
            else { return nil }
            // Un cambio de formato invalida el score anterior. Los campos de
            // tiempo y de rondas nunca se transforman unos en otros.
            var result = result
            result.format = format
            switch format.resultCapture {
            case .totalReps:
                guard result.totalReps != nil || result.roundsCompleted != nil else { return nil }
                result.elapsedSeconds = nil
                if format != .amrap && format != .deathBy { result.roundsCompleted = nil }
            case .elapsedTime:
                guard result.elapsedSeconds != nil else { return nil }
                result.roundsCompleted = nil
                result.totalReps = nil
            case .perMovementSets:
                return nil
            }
            return result
        }
        // La sesión sigue finalizada; no modifica la plantilla de programación.
        return updated
    }

    private static func visibleSets(for entry: SessionExercise) -> [PlannedSet] {
        guard !entry.loggedSets.isEmpty else { return entry.plannedSets }
        return entry.loggedSets.map {
            PlannedSet(
                id: $0.id,
                targetReps: $0.reps,
                targetWeightKg: $0.deficitCm.map(Double.init) ?? $0.weightKg,
                targetRir: $0.rir
            )
        }
    }

    private static func movement(for entry: SessionExercise, original: WODMovement?) -> WODMovement {
        let sets = visibleSets(for: entry)
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
