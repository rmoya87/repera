import Foundation

public enum FatigueState: String, Sendable {
    case ready
    case recovering
    case fatigued

    public var label: String {
        switch self {
        case .ready: "Listo"
        case .recovering: "Recuperando"
        case .fatigued: "Fatigado"
        }
    }
}

public struct MuscleStatus: Identifiable, Sendable, Equatable {
    public var id: String { name }
    /// BodyMap slug (`chest`, `quadriceps`…) or legacy group label.
    public var name: String
    public var score: Double
    public var state: FatigueState
    public var setsLast7Days: Double

    public init(name: String, score: Double, state: FatigueState, setsLast7Days: Double) {
        self.name = name
        self.score = score
        self.state = state
        self.setsLast7Days = setsLast7Days
    }
}

/// Estímulo muscular orientativo para WODs con un resultado global.
//// No modifica LoggedSet, no atribuye RIR y no se utiliza como récord.
public enum MuscleCompletedWODStimulus {
    /// Los resultados de bloque tienen prioridad sobre cantidades prescritas
    /// cuando no se registraron series individuales.
    public static func usesScoredEstimate(
        for entry: SessionExercise, in workout: WorkoutSession
    ) -> Bool {
        guard workout.phase == .finished || workout.finishedAt != nil,
              entry.blockKind == .wod,
              !entry.exercise.isMobility,
              !entry.loggedSets.contains(where: { !$0.isWarmup && $0.reps > 0 }),
              let id = entry.blockId else { return false }
        return workout.wodResults.contains {
            $0.id == id && (
                ($0.elapsedSeconds ?? 0) > 0 ||
                ($0.roundsCompleted ?? 0) > 0 ||
                ($0.totalReps ?? 0) > 0
            )
        }
    }

    private static func cycleQuantity(_ entry: SessionExercise) -> Int {
        max(0, entry.adaptedReps ?? entry.plannedSets.first?.targetReps ?? 0)
    }

    /// Cantidad estimada de este movimiento; AMRAP distribuye las reps
    /// parciales según el orden original, no las suma a todos los ejercicios.
    private static func quantity(
        for entry: SessionExercise, siblings: [SessionExercise],
        result: WODBlockResult
    ) -> Double {
        let base = cycleQuantity(entry)
        guard base > 0 else { return 0 }
        if result.totalReps != nil || result.roundsCompleted != nil {
            let cycleTotal = max(1, siblings.reduce(0) { $0 + cycleQuantity($1) })
            let partialTotal = max(0, result.totalReps ?? 0)
            let fullRounds = result.roundsCompleted.map { max(0, $0) }
                ?? (partialTotal / cycleTotal)
            let remainder = result.roundsCompleted == nil
                ? partialTotal % cycleTotal : partialTotal
            let before = siblings.prefix(while: { $0.id != entry.id })
                .reduce(0) { $0 + cycleQuantity($1) }
            let partial = min(base, max(0, remainder - before))
            return Double(fullRounds * base + partial)
        }
        // For Time: el tiempo medido corresponde al bloque completado.
        // Una prescripción expandida por rondas no se vuelve a multiplicar.
        let prescribed = entry.plannedSets.reduce(0) { $0 + max(0, $1.targetReps) }
        return Double(max(prescribed, base * max(1, entry.blockRounds ?? 1)))
    }

    private static func normalizedQuantity(_ amount: Double, for entry: SessionExercise) -> Double {
        switch entry.quantityUnit ?? entry.exercise.defaultQuantityUnit {
        case .reps: return amount
        case .calories: return amount * 1.2
        case .meters: return amount / 100
        }
    }

    public static func estimatedSetEquivalent(
        for entry: SessionExercise, in workout: WorkoutSession, hardOnly: Bool
    ) -> Double {
        guard workout.phase == .finished || workout.finishedAt != nil,
              entry.blockKind == .wod || entry.blockId.map({
                  id in workout.wodResults.contains { $0.id == id }
              }) == true,
              !entry.exercise.isMobility,
              !entry.loggedSets.contains(where: { !$0.isWarmup && $0.reps > 0 })
        else { return 0 }

        guard usesScoredEstimate(for: entry, in: workout),
              let id = entry.blockId,
              let result = workout.wodResults.last(where: { $0.id == id }) else {
            // Sin resultado cuantificado: conservar el mínimo prudente,
            // solo en fatiga, nunca inventar esfuerzo intenso.
            return hardOnly ? 0 : 1
        }

        let siblings = workout.exercises.filter {
            $0.blockId == id && $0.blockKind == .wod && !$0.exercise.isMobility
        }
        let movementUnits = normalizedQuantity(
            quantity(for: entry, siblings: siblings, result: result), for: entry
        )
        guard movementUnits > 0 else { return 0 }
        let totalUnits = siblings.reduce(0.0) {
            $0 + normalizedQuantity(
                quantity(for: $1, siblings: siblings, result: result), for: $1
            )
        }
        let blockCount = max(1, Set(workout.exercises.compactMap(\.blockId)).count)
        let sessionMinutes = workout.durationMinutes / Double(blockCount)
        let elapsedMinutes = Double(result.elapsedSeconds ?? 0) / 60
        let capMinutes = Double(entry.blockTimeCapMinutes ?? 0)
        let minutes = max(1.0, min(120.0,
            elapsedMinutes > 0 ? elapsedMinutes :
                (capMinutes > 0 ? capMinutes : max(1, sessionMinutes))
        ))
        let durationFactor = 0.8 + 0.2 * min(2.0, minutes / 15.0)
        let kg = max(0, entry.adaptedWeightKg ?? entry.plannedSets.first?.targetWeightKg ?? 0)
        let loadFactor = 1.0 + min(0.35, kg / 250.0)
        let equivalent = min(12.0, max(0.25, movementUnits / 10.0) * durationFactor * loadFactor)
        if !hardOnly { return equivalent }

        // Esfuerzo metabólico ESTIMADO por densidad global del bloque.
        // Nunca se registra como serie dura real ni como RIR inferido.
        let repetitionsPerMinute = totalUnits / minutes
        let densityFactor = min(0.75, max(0, (repetitionsPerMinute - 5) / 20.0))
        return equivalent * densityFactor
    }
}

/// Fatiga / recuperación por músculo (BodyMap slugs): el estímulo decae con vida media.
public enum MuscleMapEngine {
    /// Half-life hours by BodyMap slug (larger groups recover slower).
    private static let halfLifeHours: [String: Double] = [
        "chest": 30,
        "upper-back": 30,
        "trapezius": 28,
        "lower-back": 36,
        "deltoids": 24,
        "serratus": 24,
        "biceps": 24,
        "triceps": 24,
        "forearm": 20,
        "abs": 24,
        "obliques": 24,
        "gluteal": 48,
        "quadriceps": 48,
        "hamstring": 48,
        "adductors": 40,
        "hip-flexors": 36,
        "calves": 36,
        "tibialis": 24,
    ]

    /// Estímulo retenido ahora (0…~1.5+). Más alto = más fatiga residual.
    public static func retainedLoad(
        workouts: [WorkoutSession],
        external: [ExternalMuscleStimulus] = [],
        hardOnly: Bool = false,
        now: Date = Date()
    ) -> [String: Double] {
        var stimulus: [String: Double] = [:]

        for workout in workouts {
            let when = workout.finishedAt ?? workout.startedAt ?? now
            let ageHours = now.timeIntervalSince(when) / 3600
            guard ageHours >= 0, ageHours < 30 * 24 else { continue }

            for entry in workout.exercises {
                // La movilidad no representa volumen de fuerza ni fatiga muscular.
                guard entry.exercise.sportTag != "Movilidad" else { continue }
                let scored = MuscleCompletedWODStimulus.usesScoredEstimate(for: entry, in: workout)
                let workSets = scored ? [] : StatsEngine.confirmedWorkSets(entry, in: workout)
                let hardSets = workSets.reduce(0.0) { partial, set in
                    guard set.reps > 0 else { return partial }
                    if hardOnly {
                        // Solo fuerza «dura» (RIR); cardio/máquina no entra en este filtro.
                        if set.isWarmup || set.isMachineQuantity { return partial }
                        if set.weightKg == nil, set.durationSeconds != nil { return partial }
                        return Effort.isHard(rir: set.rir) ? partial + 1.0 : partial
                    }
                    return partial + set.fatigueSetEquivalent
                }
                // Algunos EMOM/AMRAP guardan resultado y check del movimiento
                // sin series individuales. Reconocer la finalización confirmada
                // con un equivalente conservador, jamás como «serie dura».
                let completedWOD = MuscleCompletedWODStimulus.estimatedSetEquivalent(
                    for: entry, in: workout, hardOnly: hardOnly
                )
                let recordedOrEstimated = scored
                    ? completedWOD
                    : (hardSets > 0 ? hardSets : completedWOD * 0.7)
                guard recordedOrEstimated > 0 else { continue }
                let capped = min(recordedOrEstimated, 12)
                let weights = MuscleTaxonomy.muscleWeights(for: entry.exercise)
                for (slug, w) in weights {
                    let hl = halfLifeHours[slug] ?? 30
                    let retained = capped * w * pow(0.5, ageHours / hl)
                    stimulus[slug, default: 0] += retained
                }
            }
        }

        for sample in external {
            let ageHours = now.timeIntervalSince(sample.date) / 3600
            guard ageHours >= 0, ageHours < 30 * 24 else { continue }
            for (slug, w) in sample.load where w > 0 {
                let hl = halfLifeHours[slug] ?? 30
                // External loads are already “set-equivalent” units.
                stimulus[slug, default: 0] += w * pow(0.5, ageHours / hl)
            }
        }

        // Normalize: ~8 hard-set·weight units ≈ score 1.0
        var scores: [String: Double] = [:]
        for slug in MuscleTaxonomy.muscles {
            let raw = (stimulus[slug] ?? 0) / 8.0
            if raw > 0 {
                scores[slug] = min(1.5, raw)
            }
        }
        return scores
    }

    /// Niveles absolutos para el mapa (misma leyenda siempre):
    /// 0 sin estímulo · 1 listo · 2 suave · 3 recuperando · 4 fatigado.
    public static func levels(ofScores scores: [String: Double]) -> [String: Int] {
        var out: [String: Int] = [:]
        for slug in MuscleTaxonomy.muscles {
            out[slug] = level(forScore: scores[slug] ?? 0)
        }
        return out
    }

    public static func level(forScore score: Double) -> Int {
        if score <= 0 { return 0 }
        if score < 0.25 { return 1 }
        if score < 0.5 { return 2 }
        if score < 0.85 { return 3 }
        return 4
    }

    public static func state(forScore score: Double) -> FatigueState {
        if score < 0.25 { return .ready }
        if score <= 0.5 { return .recovering }
        return .fatigued
    }

    /// API de tests / listados: un `MuscleStatus` por slug con estímulo.
    public static func statuses(
        from workouts: [WorkoutSession],
        external: [ExternalMuscleStimulus] = [],
        hardOnly: Bool = false,
        now: Date = Date()
    ) -> [MuscleStatus] {
        let scores = retainedLoad(
            workouts: workouts,
            external: external,
            hardOnly: hardOnly,
            now: now
        )
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        var weekly: [String: Double] = [:]
        for workout in workouts {
            let when = workout.finishedAt ?? workout.startedAt ?? now
            guard when >= weekAgo else { continue }
            for entry in workout.exercises {
                guard entry.exercise.sportTag != "Movilidad" else { continue }
                let scored = MuscleCompletedWODStimulus.usesScoredEstimate(for: entry, in: workout)
                let sets = scored ? 0 : StatsEngine.confirmedWorkSets(entry, in: workout).count
                let completedWOD = MuscleCompletedWODStimulus.estimatedSetEquivalent(
                    for: entry, in: workout, hardOnly: hardOnly
                )
                let countedSets = scored ? completedWOD : (sets > 0 ? Double(sets) : completedWOD)
                guard countedSets > 0 else { continue }
                for (slug, w) in MuscleTaxonomy.muscleWeights(for: entry.exercise) {
                    weekly[slug, default: 0] += w * countedSets
                }
            }
        }
        return MuscleTaxonomy.muscles.compactMap { slug in
            let score = scores[slug] ?? 0
            guard score > 0 || (weekly[slug] ?? 0) > 0 else { return nil }
            return MuscleStatus(
                name: slug,
                score: score,
                state: state(forScore: score),
                setsLast7Days: weekly[slug] ?? 0
            )
        }
        .sorted { $0.score > $1.score }
    }
}
