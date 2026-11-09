import Foundation

/// Conservative WOD matching: an identical title is not enough to compare scores.
/// We require the same prescription, ordered movements and explicit RX context.
public struct WODComparisonContext: Sendable, Equatable {
    public var prescribed: RoutineBlock
    public var result: WODBlockResult
    public var isRx: Bool

    public init(prescribed: RoutineBlock, result: WODBlockResult, isRx: Bool) {
        self.prescribed = prescribed
        self.result = result
        self.isRx = isRx
    }
}

public struct WODComparison: Sendable {
    public var previousScore: String
    public var currentScore: String
    /// Positive means improvement, in reps for AMRAP and seconds for For Time.
    public var improvement: Int
    public var unit: String
}

public enum WODComparisonEngine {
    public static func compare(previous: WODComparisonContext,
                               current: WODComparisonContext) -> WODComparison? {
        let a = previous.prescribed
        let b = current.prescribed
        guard a.kind == .wod, b.kind == .wod,
              previous.isRx == current.isRx,
              let format = a.wodFormat, format == b.wodFormat,
              previous.result.format == format, current.result.format == format,
              a.timeCapMinutes == b.timeCapMinutes,
              a.emomIntervalSeconds == b.emomIntervalSeconds,
              a.rounds == b.rounds,
              a.workSeconds == b.workSeconds,
              a.restSeconds == b.restSeconds,
              a.restBetweenRoundsSeconds == b.restBetweenRoundsSeconds,
              a.movements.count == b.movements.count, !a.movements.isEmpty,
              zip(a.movements, b.movements).allSatisfy({ equivalent($0.0, $0.1) }) else {
            return nil
        }
        // Comparing scores from different official templates is unsafe.
        if let templateA = a.wodTemplateId, let templateB = b.wodTemplateId,
           templateA != templateB { return nil }
        switch format {
        case .amrap:
            // The recording UI stores roundsCompleted + *extra* repetitions,
            // not a flattened total. Comparing only extra reps reverses rankings.
            // Only straightforward rep-count WODs can be flattened safely.
            guard a.movements.allSatisfy({
                !$0.isRest && ($0.reps ?? 0) > 0 && $0.repScheme == nil
                    && $0.distanceMeters == nil && $0.calories == nil
            }) else { return nil }
            let repsPerRound = a.movements.reduce(0) { $0 + ($1.reps ?? 0) }
            guard repsPerRound > 0,
                  let previousRounds = previous.result.roundsCompleted,
                  let currentRounds = current.result.roundsCompleted,
                  let previousExtra = previous.result.totalReps,
                  let currentExtra = current.result.totalReps,
                  previousRounds >= 0, currentRounds >= 0,
                  previousExtra >= 0, currentExtra >= 0,
                  previousExtra < repsPerRound, currentExtra < repsPerRound else { return nil }
            let old = previousRounds * repsPerRound + previousExtra
            let new = currentRounds * repsPerRound + currentExtra
            return WODComparison(previousScore: previous.result.summaryLabel,
                                 currentScore: current.result.summaryLabel,
                                 improvement: new - old, unit: "reps")
        case .forTime, .afap, .chipper:
            guard let old = previous.result.elapsedSeconds,
                  let new = current.result.elapsedSeconds,
                  old > 0, new > 0 else { return nil }
            // Without explicit completion evidence, a time-cap result cannot be ranked.
            if let cap = a.timeCapMinutes, (old >= cap * 60 || new >= cap * 60) { return nil }
            return WODComparison(previousScore: previous.result.summaryLabel,
                                 currentScore: current.result.summaryLabel,
                                 improvement: old - new, unit: "segundos")
        default:
            return nil
        }
    }

    private static func equivalent(_ a: WODMovement, _ b: WODMovement) -> Bool {
        // Stable canonical ID when available, exact normalized name otherwise.
        let sameExercise: Bool
        if let idA = a.exerciseId, let idB = b.exerciseId {
            sameExercise = idA == idB
        } else {
            sameExercise = a.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                == b.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        }
        return sameExercise && a.reps == b.reps && a.repScheme == b.repScheme
            && a.distanceMeters == b.distanceMeters && a.calories == b.calories
            && a.weightMaleKg == b.weightMaleKg && a.weightFemaleKg == b.weightFemaleKg
            && a.isRest == b.isRest && a.restSeconds == b.restSeconds
            && a.scaleAlternative == b.scaleAlternative
            && a.explicitPlannedSets == b.explicitPlannedSets
            && a.notes == b.notes
    }
}
