import Foundation

/// Formula v10: no numeric score without independent personal history.
/// Three separate indicators; the registration coverage is NEVER fitness points.
public enum VerifiedSessionReviewEngine {
    public static let minimumPriorSessions = 2
    public static let minimumEvidenceCoverage = 0.60
    public static let historyHorizonDays = 180

    private struct Evidence {
        let score: Int
        let weight: Double
        let referenceCount: Int
        let explanation: String
    }

    public static func review(
        session: WorkoutSession,
        history: [WorkoutSession],
        now: Date = Date()
    ) -> SessionReview? {
        guard session.phase == .finished else { return nil }
        let currentDate = session.finishedAt ?? now
        let cutoff = currentDate.addingTimeInterval(-Double(historyHorizonDays) * 86_400)
        let prior = history.filter {
            $0.id != session.id && $0.phase == .finished
                && ($0.finishedAt ?? .distantPast) < currentDate
                && ($0.finishedAt ?? .distantPast) >= cutoff
        }

        let movementEntries = session.exercises.filter {
            $0.loggedSets.contains(where: { !$0.isWarmup && $0.reps > 0 })
        }
        let wodResults = session.wodResults.filter { validScore($0) }
        // Only count actual performance evidence; missing unlogged sets do not
        // become zeros, and the score doesn't increase from tapping checkboxes.
        let possible = movementEntries.count + wodResults.count
        guard possible > 0 else { return nil }

        let movementEvidence = movementEntries.compactMap {
            personalEvidence(entry: $0, prior: prior)
        }
        let wodEvidence = wodResults.compactMap {
            wodEvidence(result: $0, session: session, prior: prior)
        }
        let eligible = movementEvidence + wodEvidence
        guard !eligible.isEmpty else { return nil }

        let coverage = Double(eligible.count) / Double(possible)
        guard coverage >= minimumEvidenceCoverage else { return nil }
        let weighted = eligible.reduce(0.0) { $0 + Double($1.score) * $1.weight }
        let totalWeight = eligible.reduce(0.0) { $0 + $1.weight }
        guard totalWeight > 0 else { return nil }
        let score = min(10, max(1, Int((weighted / totalWeight).rounded())))

        func average(_ values: [Evidence]) -> Int? {
            guard !values.isEmpty else { return nil }
            return Int((values.reduce(0.0) { $0 + Double($1.score) } / Double(values.count)).rounded())
        }
        let personal = average(movementEvidence)
        let wod = average(wodEvidence)
        let registered = session.exercises.filter {
            $0.wodFormat?.resultCapture == .perMovementSets || $0.wodFormat == nil
        }
        let plannedSets = registered.reduce(0) { $0 + $1.plannedSets.count }
        let actualSets = registered.reduce(0) {
            $0 + $1.loggedSets.filter { !$0.isWarmup }.count
        }
        let minReferences = eligible.map(\.referenceCount).min() ?? minimumPriorSessions
        let confidence = minReferences >= 5 && coverage >= 0.80
            ? "Alta" : "En construcción"
        let coveragePercent = Int((coverage * 100).rounded())

        let indicators: [ReviewIndicator] = [
            ReviewIndicator(
                dimension: .personalProgress,
                score: personal,
                detail: personal == nil
                    ? "Faltan dos sesiones previas comparables de cada ejercicio."
                    : movementEvidence.map(\.explanation).joined(separator: " · "),
                referenceSessions: movementEvidence.map(\.referenceCount).min() ?? 0
            ),
            ReviewIndicator(
                dimension: .adherence,
                score: nil,
                detail: plannedSets > 0
                    ? "\(actualSets) de \(plannedSets) series registradas. No mide intensidad ni técnica."
                    : "Sin series programadas evaluables; no suma ni resta puntos.",
                referenceSessions: 0
            ),
            ReviewIndicator(
                dimension: .wodPerformance,
                score: wod,
                detail: wod == nil
                    ? "Faltan dos marcas anteriores del mismo WOD, formato y prescripción."
                    : wodEvidence.map(\.explanation).joined(separator: " · "),
                referenceSessions: wodEvidence.map(\.referenceCount).min() ?? 0
            )
        ]
        return SessionReview(
            overallScore: score,
            level: nil,
            headline: "Rendimiento personal · \(score)/10",
            vsHistorySummary: "\(coveragePercent)% del rendimiento registrado tiene referencias personales comparables.",
            vsStandardSummary: "Nota basada en historial propio; no se comparan ejercicios distintos ni se puntúa el número de series anotadas.",
            keepTips: ["Los valores se comparan solo con sesiones del mismo ejercicio o WOD y esfuerzo comparable."],
            improveTips: ["Con más sesiones independientes aumentará la confianza de esta valoración."],
            movements: [],
            wodTemplateId: nil,
            scoreBasis: .personalHistory,
            indicators: indicators,
            evidenceCoverage: coverage,
            confidenceLabel: confidence
        )
    }

    private static func validScore(_ result: WODBlockResult) -> Bool {
        guard let format = result.format else { return false }
        switch format.resultCapture {
        case .elapsedTime: return (result.elapsedSeconds ?? 0) > 0
        case .totalReps: return (result.roundsCompleted ?? 0) > 0 || (result.totalReps ?? 0) > 0
        case .perMovementSets: return false
        }
    }

    private static func sameExercise(_ a: Exercise, _ b: Exercise) -> Bool {
        // Same catalog identity is necessary but not sufficient: equipment,
        // logging units and execution type must also agree.
        ExerciseEquivalence.matchesCatalogIdentity(a, b)
            && a.loggingStyle == b.loggingStyle
            && a.loadField == b.loadField
            && (a.equipment ?? "").lowercased() == (b.equipment ?? "").lowercased()
    }

    private static func bestComparableSet(
        entry: SessionExercise, reference: LoggedSet?
    ) -> LoggedSet? {
        let sets = entry.loggedSets.filter { !$0.isWarmup && $0.reps > 0 }
        guard !sets.isEmpty else { return nil }
        let matched = sets.filter { set in
            guard let reference else { return true }
            if abs(set.reps - reference.reps) > 2 { return false }
            if let a = set.rir, let b = reference.rir, abs(a - b) > 1.5 { return false }
            return true
        }
        return matched.max {
            (loadMetric($0, style: entry.exercise.loggingStyle) ?? 0)
                < (loadMetric($1, style: entry.exercise.loggingStyle) ?? 0)
        }
    }

    private static func loadMetric(_ set: LoggedSet, style: ExerciseLoggingStyle) -> Double? {
        guard set.reps > 0 else { return nil }
        switch style {
        case .loadAndReps:
            guard let kg = set.weightKg, kg > 0, set.reps <= 12 else { return nil }
            return PlateMath.epleyOneRM(weightKg: kg, reps: set.reps)
        case .repsOnly: return Double(set.reps)
        case .repsAndTime, .machineWork:
            guard let seconds = set.durationSeconds, seconds > 0 else { return nil }
            return Double(set.reps) / Double(seconds)
        }
    }

    private static func personalEvidence(
        entry: SessionExercise,
        prior: [WorkoutSession]
    ) -> Evidence? {
        guard let currentSet = bestComparableSet(entry: entry, reference: nil),
              let currentValue = loadMetric(currentSet, style: entry.exercise.loggingStyle),
              currentValue > 0 else { return nil }

        // One comparable reading per DISTINCT day, not several sets from one
        // session. The reference uses the median of the last 3 days.
        var perDay: [(Date, Double)] = []
        for workout in prior.sorted(by: {
            ($0.finishedAt ?? .distantPast) > ($1.finishedAt ?? .distantPast)
        }) {
            guard let date = workout.finishedAt else { continue }
            let day = Calendar.current.startOfDay(for: date)
            if perDay.contains(where: { $0.0 == day }) { continue }
            let comparable = workout.exercises.filter {
                sameExercise($0.exercise, entry.exercise)
            }.compactMap { candidate -> Double? in
                guard let otherSet = bestComparableSet(entry: candidate, reference: currentSet),
                      let value = loadMetric(otherSet, style: entry.exercise.loggingStyle),
                      value > 0 else { return nil }
                // If the athlete deliberately prescribed lighter work, don't
                // mistake it for deteriorating maximum strength.
                if let currentTarget = entry.plannedSets.first?.targetWeightKg,
                   let priorTarget = candidate.plannedSets.first?.targetWeightKg,
                   currentTarget > 0, priorTarget > 0,
                   currentTarget < priorTarget * 0.90 { return nil }
                return value
            }
            if let best = comparable.max() { perDay.append((day, best)) }
            if perDay.count == 3 { break }
        }
        guard perDay.count >= minimumPriorSessions else { return nil }
        let sortedValues = perDay.map(\.1).sorted()
        let reference = median(sortedValues)
        guard reference > 0 else { return nil }
        let ratio = currentValue / reference
        return Evidence(
            score: points(ratio: ratio), weight: 5,
            referenceCount: perDay.count,
            explanation: "\(entry.exercise.name): \(signedChange(ratio)) respecto a tus \(perDay.count) sesiones comparables"
        )
    }

    private static func wodEvidence(
        result: WODBlockResult,
        session: WorkoutSession,
        prior: [WorkoutSession]
    ) -> Evidence? {
        guard let currentBlock = session.routineBlocks?.first(where: { $0.id == result.id }),
              let format = result.format,
              let current = wodMetric(result: result, block: currentBlock),
              current > 0 else { return nil }
        let scaled = session.exercises.filter { $0.blockId == result.id }
        var refs: [(Date, Double)] = []
        for workout in prior.sorted(by: {
            ($0.finishedAt ?? .distantPast) > ($1.finishedAt ?? .distantPast)
        }) {
            guard let date = workout.finishedAt else { continue }
            let day = Calendar.current.startOfDay(for: date)
            if refs.contains(where: { $0.0 == day }) { continue }
            guard let previous = workout.wodResults.first(where: { candidate in
                candidate.format == format && validScore(candidate)
                    && workout.routineBlocks?.contains(where: { block in
                        block.id == candidate.id && samePrescription(currentBlock, block)
                    }) == true
            }),
            let pastBlock = workout.routineBlocks?.first(where: { $0.id == previous.id }),
            let value = wodMetric(result: previous, block: pastBlock),
            value > 0 else { continue }
            let previousScaled = workout.exercises.filter { $0.blockId == previous.id }
            guard sameScaling(scaled, previousScaled) else { continue }
            refs.append((day, value))
            if refs.count == 3 { break }
        }
        guard refs.count >= minimumPriorSessions else { return nil }
        let values = refs.map(\.1).sorted()
        let reference = median(values)
        guard reference > 0 else { return nil }
        let ratio = current / reference
        let minutes = Double(max(1, min(90, currentBlock.timeCapMinutes ?? 8)))
        return Evidence(
            score: points(ratio: ratio), weight: minutes,
            referenceCount: refs.count,
            explanation: "\(currentBlock.title): \(signedChange(ratio)) frente a \(refs.count) marcas comparables"
        )
    }

    private static func sameScaling(_ current: [SessionExercise], _ previous: [SessionExercise]) -> Bool {
        let a = current.filter(\.hasWODScaling)
        let b = previous.filter(\.hasWODScaling)
        guard a.count == b.count else { return false }
        return a.allSatisfy { item in
            b.contains { old in
                sameExercise(item.exercise, old.exercise)
                    && item.adaptedReps == old.adaptedReps
                    && abs((item.adaptedWeightKg ?? 0) - (old.adaptedWeightKg ?? 0)) < 0.05
            }
        }
    }

    private static func samePrescription(_ a: RoutineBlock, _ b: RoutineBlock) -> Bool {
        guard a.wodFormat == b.wodFormat,
              a.timeCapMinutes == b.timeCapMinutes,
              a.emomIntervalSeconds == b.emomIntervalSeconds,
              a.rounds == b.rounds,
              a.movements.count == b.movements.count else { return false }
        for (left, right) in zip(a.movements, b.movements) {
            guard ExerciseEquivalence.sameName(left.name, right.name),
                  left.reps == right.reps,
                  left.repScheme == right.repScheme,
                  left.distanceMeters == right.distanceMeters,
                  left.calories == right.calories,
                  abs((left.weightMaleKg ?? 0) - (right.weightMaleKg ?? 0)) < 0.05,
                  abs((left.weightFemaleKg ?? 0) - (right.weightFemaleKg ?? 0)) < 0.05 else {
                return false
            }
        }
        return true
    }

    private static func wodMetric(result: WODBlockResult, block: RoutineBlock) -> Double? {
        guard let format = result.format else { return nil }
        switch format.resultCapture {
        case .elapsedTime:
            guard let seconds = result.elapsedSeconds, seconds > 0 else { return nil }
            return 1.0 / Double(seconds) // Less time = better
        case .totalReps:
            if format == .amrap || format == .deathBy {
                let perRound = block.movements.filter { !$0.isRest }
                    .reduce(0) { $0 + max(0, $1.reps ?? 0) }
                guard perRound > 0 else { return nil }
                return Double(result.roundsCompleted ?? 0)
                    + Double(result.totalReps ?? 0) / Double(perRound)
            }
            return Double(result.totalReps ?? 0)
        case .perMovementSets: return nil
        }
    }

    private static func median(_ sorted: [Double]) -> Double {
        let mid = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[mid - 1] + sorted[mid]) / 2
        }
        return sorted[mid]
    }

    private static func points(ratio: Double) -> Int {
        // Baseline 7/10 for stable performance; logarithmic and bounded.
        // Not a physiological or population-normed score.
        guard ratio.isFinite && ratio > 0 else { return 1 }
        return min(10, max(1, Int((7 + 11 * log(ratio)).rounded())))
    }

    private static func signedChange(_ ratio: Double) -> String {
        let change = Int(((ratio - 1) * 100).rounded())
        return change > 0 ? "+\(change)%" : "\(change)%"
    }
}
