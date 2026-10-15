import Foundation

public enum ProgressionPolicy: String, Codable, Sendable, CaseIterable {
    case off
    case linear
    case doubleProgression = "double"
    case greyskull
    case triple

    public var displayName: String {
        switch self {
        case .off: "Sin progresión"
        case .linear: "Lineal"
        case .doubleProgression: "Doble (rango de reps)"
        case .greyskull: "Greyskull LP"
        case .triple: "Triple progresión"
        }
    }

    public var detail: String {
        switch self {
        case .off:
            "Los objetivos se quedan como los dejas."
        case .linear:
            "Si completas todas las reps, sube el peso. Fallos seguidos → deload."
        case .doubleProgression:
            "Sube reps en el rango; al llegar al tope, sube peso y vuelve al mínimo."
        case .greyskull:
            "Series fijas + última al fallo. Si bates el objetivo en la AMRAP, sube peso (el doble si doblas reps). Un fallo → deload 10%."
        case .triple:
            "Sube reps → luego añade series → luego peso, y reinicia reps/series."
        }
    }
}

public struct ProgressionSuggestion: Sendable, Equatable {
    public var weightKg: Double?
    public var reps: Int
    public var setCount: Int
    public var reason: String

    public init(weightKg: Double?, reps: Int, setCount: Int, reason: String) {
        self.weightKg = weightKg
        self.reps = reps
        self.setCount = setCount
        self.reason = reason
    }
}

public enum ProgressionEngine {
    public static let defaultIncrementKg = 2.5
    public static let deloadFactor = 0.9
    public static let deloadAfterMisses = 3
    public static let doubleRepMin = 6
    public static let doubleRepMax = 12
    public static let tripleMinSets = 3
    public static let tripleMaxSets = 5

    public static func suggest(
        exerciseId: UUID,
        planned: [PlannedSet],
        policy: ProgressionPolicy,
        workouts: [WorkoutSession],
        incrementKg: Double = defaultIncrementKg
    ) -> ProgressionSuggestion {
        let baselineReps = planned.first?.targetReps ?? 8
        let baselineSets = max(planned.count, 1)
        let baselineWeight = planned.first?.targetWeightKg
            ?? lastWorkingWeight(exerciseId: exerciseId, workouts: workouts)

        guard policy != .off else {
            return ProgressionSuggestion(
                weightKg: baselineWeight,
                reps: baselineReps,
                setCount: baselineSets,
                reason: "Progresión desactivada — se mantienen los objetivos del plan."
            )
        }

        let history = recentPerformances(exerciseId: exerciseId, workouts: workouts)
        guard let last = history.first else {
            return ProgressionSuggestion(
                weightKg: baselineWeight,
                reps: baselineReps,
                setCount: max(baselineSets, policy == .greyskull ? 3 : baselineSets),
                reason: "Primera vez con este ejercicio — usa el peso del plan."
            )
        }

        switch policy {
        case .off:
            return ProgressionSuggestion(
                weightKg: baselineWeight,
                reps: baselineReps,
                setCount: baselineSets,
                reason: "Progresión desactivada."
            )
        case .linear:
            return linearSuggest(
                last: last,
                history: history,
                baselineWeight: baselineWeight,
                baselineReps: baselineReps,
                baselineSets: baselineSets,
                incrementKg: incrementKg
            )
        case .doubleProgression:
            return doubleSuggest(
                last: last,
                baselineWeight: baselineWeight,
                baselineSets: baselineSets,
                incrementKg: incrementKg
            )
        case .greyskull:
            return greyskullSuggest(
                last: last,
                baselineWeight: baselineWeight,
                baselineReps: baselineReps,
                baselineSets: max(baselineSets, 3),
                incrementKg: incrementKg
            )
        case .triple:
            return tripleSuggest(
                last: last,
                baselineWeight: baselineWeight,
                baselineReps: baselineReps,
                baselineSets: baselineSets,
                incrementKg: incrementKg
            )
        }
    }

    public static func applySuggestions(
        to session: WorkoutSession,
        routine: Routine,
        workouts: [WorkoutSession],
        defaultPolicy: ProgressionPolicy,
        incrementKg: Double
    ) -> (WorkoutSession, [UUID: String]) {
        var next = session
        var reasons: [UUID: String] = [:]
        let policy = routine.progression == .off ? defaultPolicy : routine.progression

        for i in next.exercises.indices {
            let exerciseId = next.exercises[i].exercise.id
            let planned = next.exercises[i].plannedSets
            let suggestion = suggest(
                exerciseId: exerciseId,
                planned: planned,
                policy: policy,
                workouts: workouts,
                incrementKg: incrementKg
            )
            let setCount = max(suggestion.setCount, 1)
            next.exercises[i].plannedSets = (0..<setCount).map { _ in
                PlannedSet(targetReps: suggestion.reps, targetWeightKg: suggestion.weightKg)
            }
            reasons[exerciseId] = suggestion.reason
        }
        return (next, reasons)
    }

    // MARK: - Policies

    private static func linearSuggest(
        last: Performance,
        history: [Performance],
        baselineWeight: Double?,
        baselineReps: Int,
        baselineSets: Int,
        incrementKg: Double
    ) -> ProgressionSuggestion {
        let weight = last.averageWeight ?? baselineWeight ?? 0
        if last.hitAll {
            let next = snap(weight + incrementKg, step: incrementKg)
            return ProgressionSuggestion(
                weightKg: next,
                reps: baselineReps,
                setCount: baselineSets,
                reason: "Hit completo la última vez → +\(format(incrementKg)) kg."
            )
        }

        let missStreak = history.prefix(deloadAfterMisses).prefix(while: { !$0.hitAll }).count
        if missStreak >= deloadAfterMisses {
            let deloaded = snap(weight * deloadFactor, step: incrementKg)
            return ProgressionSuggestion(
                weightKg: deloaded,
                reps: baselineReps,
                setCount: baselineSets,
                reason: "\(missStreak) fallos seguidos → deload \(Int(deloadFactor * 100))%."
            )
        }

        return ProgressionSuggestion(
            weightKg: weight > 0 ? weight : baselineWeight,
            reps: baselineReps,
            setCount: baselineSets,
            reason: "No se completaron todas las reps — se mantiene el peso."
        )
    }

    private static func doubleSuggest(
        last: Performance,
        baselineWeight: Double?,
        baselineSets: Int,
        incrementKg: Double
    ) -> ProgressionSuggestion {
        let weight = last.averageWeight ?? baselineWeight ?? 0
        let lastReps = last.minRepsAcrossSets ?? doubleRepMin

        if last.hitAll && lastReps >= doubleRepMax {
            let next = snap(weight + incrementKg, step: incrementKg)
            return ProgressionSuggestion(
                weightKg: next,
                reps: doubleRepMin,
                setCount: baselineSets,
                reason: "Rango completo (\(doubleRepMax)) → +\(format(incrementKg)) kg y reps a \(doubleRepMin)."
            )
        }

        if last.hitAll {
            let nextReps = min(doubleRepMax, lastReps + 1)
            return ProgressionSuggestion(
                weightKg: weight > 0 ? weight : baselineWeight,
                reps: nextReps,
                setCount: baselineSets,
                reason: "Hit → reps \(lastReps)→\(nextReps) (rango \(doubleRepMin)–\(doubleRepMax))."
            )
        }

        return ProgressionSuggestion(
            weightKg: weight > 0 ? weight : baselineWeight,
            reps: max(doubleRepMin, lastReps),
            setCount: baselineSets,
            reason: "Fallaste el rango — se mantienen peso y reps."
        )
    }

    private static func greyskullSuggest(
        last: Performance,
        baselineWeight: Double?,
        baselineReps: Int,
        baselineSets: Int,
        incrementKg: Double
    ) -> ProgressionSuggestion {
        let weight = last.averageWeight ?? baselineWeight ?? 0
        let sets = max(baselineSets, 3)

        if !last.greyskullStraightHits {
            let deloaded = snap(max(weight, 0) * deloadFactor, step: incrementKg)
            return ProgressionSuggestion(
                weightKg: deloaded,
                reps: baselineReps,
                setCount: sets,
                reason: "Greyskull: fallaste series fijas → deload 10%."
            )
        }

        guard let amrap = last.lastSetReps else {
            return ProgressionSuggestion(
                weightKg: weight > 0 ? weight : baselineWeight,
                reps: baselineReps,
                setCount: sets,
                reason: "Greyskull: sin AMRAP registrada — se mantiene el peso."
            )
        }

        if amrap >= baselineReps * 2 {
            let next = snap(weight + incrementKg * 2, step: incrementKg)
            return ProgressionSuggestion(
                weightKg: next,
                reps: baselineReps,
                setCount: sets,
                reason: "Greyskull: AMRAP \(amrap) (≥2×) → +\(format(incrementKg * 2)) kg."
            )
        }
        if amrap > baselineReps {
            let next = snap(weight + incrementKg, step: incrementKg)
            return ProgressionSuggestion(
                weightKg: next,
                reps: baselineReps,
                setCount: sets,
                reason: "Greyskull: AMRAP \(amrap) > \(baselineReps) → +\(format(incrementKg)) kg."
            )
        }

        return ProgressionSuggestion(
            weightKg: weight > 0 ? weight : baselineWeight,
            reps: baselineReps,
            setCount: sets,
            reason: "Greyskull: AMRAP \(amrap) no superó el objetivo — mismo peso."
        )
    }

    private static func tripleSuggest(
        last: Performance,
        baselineWeight: Double?,
        baselineReps: Int,
        baselineSets: Int,
        incrementKg: Double
    ) -> ProgressionSuggestion {
        let weight = last.averageWeight ?? baselineWeight ?? 0
        let reps = last.minRepsAcrossSets ?? max(baselineReps, doubleRepMin)
        let sets = max(last.setCount, baselineSets, tripleMinSets)

        if !last.hitAll {
            return ProgressionSuggestion(
                weightKg: weight > 0 ? weight : baselineWeight,
                reps: max(doubleRepMin, min(reps, doubleRepMax)),
                setCount: min(sets, tripleMaxSets),
                reason: "Triple: no hit — se mantienen reps/series/peso."
            )
        }

        if reps < doubleRepMax {
            return ProgressionSuggestion(
                weightKg: weight > 0 ? weight : baselineWeight,
                reps: reps + 1,
                setCount: min(sets, tripleMaxSets),
                reason: "Triple: hit → reps \(reps)→\(reps + 1)."
            )
        }

        if sets < tripleMaxSets {
            return ProgressionSuggestion(
                weightKg: weight > 0 ? weight : baselineWeight,
                reps: doubleRepMax,
                setCount: sets + 1,
                reason: "Triple: tope de reps → +1 serie (\(sets)→\(sets + 1))."
            )
        }

        let next = snap(weight + incrementKg, step: incrementKg)
        return ProgressionSuggestion(
            weightKg: next,
            reps: doubleRepMin,
            setCount: tripleMinSets,
            reason: "Triple: tope series+reps → +\(format(incrementKg)) kg y reinicio \(tripleMinSets)×\(doubleRepMin)."
        )
    }

    // MARK: - History

    private struct Performance {
        var hitAll: Bool
        var averageWeight: Double?
        var minRepsAcrossSets: Int?
        var lastSetReps: Int?
        var setCount: Int
        var greyskullStraightHits: Bool
    }

    private static func recentPerformances(exerciseId: UUID, workouts: [WorkoutSession]) -> [Performance] {
        workouts
            .sorted { ($0.finishedAt ?? $0.startedAt ?? .distantPast) > ($1.finishedAt ?? $1.startedAt ?? .distantPast) }
            .compactMap { workout -> Performance? in
                guard let entry = workout.exercises.first(where: { $0.exercise.id == exerciseId })
                else { return nil }
                let workSets = entry.loggedSets.filter(\.countsForProgression)
                guard !workSets.isEmpty else { return nil }
                let target = entry.plannedSets.first?.targetReps ?? workSets.map(\.reps).max() ?? 0
                let setCountTarget = max(entry.plannedSets.count, 1)
                let hitSets = workSets.filter { $0.reps >= target }
                let hitAll = hitSets.count >= setCountTarget && workSets.count >= setCountTarget
                let weights = workSets.compactMap(\.weightKg).filter { $0 > 0 }
                let avg = weights.isEmpty ? nil : weights.reduce(0, +) / Double(weights.count)
                let minReps = workSets.map(\.reps).min()
                let lastReps = workSets.last?.reps
                let straight: Bool = {
                    guard workSets.count >= 2 else {
                        return workSets.first.map { $0.reps >= target } ?? false
                    }
                    let fixed = workSets.dropLast()
                    return fixed.allSatisfy { $0.reps >= target }
                }()
                return Performance(
                    hitAll: hitAll,
                    averageWeight: avg,
                    minRepsAcrossSets: minReps,
                    lastSetReps: lastReps,
                    setCount: workSets.count,
                    greyskullStraightHits: straight
                )
            }
    }

    private static func lastWorkingWeight(exerciseId: UUID, workouts: [WorkoutSession]) -> Double? {
        StatsEngine.lastWorkingWeight(exerciseId: exerciseId, workouts: workouts)
    }

    private static func snap(_ value: Double, step: Double) -> Double {
        guard step > 0 else { return (value * 10).rounded() / 10 }
        return (value / step).rounded() * step
    }

    private static func format(_ value: Double) -> String {
        String(format: "%g", value)
    }
}
