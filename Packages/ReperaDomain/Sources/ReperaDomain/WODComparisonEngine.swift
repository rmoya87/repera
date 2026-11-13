import Foundation

/// Conservative WOD matching: an identical title is not enough to compare scores.
/// We require the same prescription, ordered movements and explicit RX context.
public struct WODComparisonContext: Sendable, Equatable {
    public var prescribed: RoutineBlock
    public var result: WODBlockResult
    public var isRx: Bool
    /// Required and identical between scaled attempts; nil for RX.
    public var scalingFingerprint: String?

    public init(prescribed: RoutineBlock, result: WODBlockResult, isRx: Bool,
                scalingFingerprint: String? = nil) {
        self.prescribed = prescribed
        self.result = result
        self.isRx = isRx
        self.scalingFingerprint = scalingFingerprint
    }
}

public struct WODComparison: Sendable {
    public var previousScore: String
    public var currentScore: String
    /// Positive means improvement, in reps for AMRAP and seconds for For Time.
    public var improvement: Int
    public var unit: String
}

public struct WODPreciseMeasurementComparison: Sendable {
    public var improvement: Double
    public var unit: String
    public var previousScore: String
    public var currentScore: String
}

public enum WODComparisonEngine {
    /// Preserve fractional loads (e.g. 87.5 kg vs 90 kg) without rounding a
    /// half-kilogram difference or inventing an integer result.
    public static func compareMeasurement(
        previous: WODComparisonContext, current: WODComparisonContext
    ) -> WODPreciseMeasurementComparison? {
        guard previous.prescribed.wodFormat == .maxEffort,
              current.prescribed.wodFormat == .maxEffort,
              previous.isRx == current.isRx,
              let earlier = previous.result.measuredValue,
              let later = current.result.measuredValue,
              earlier.isFinite, later.isFinite, earlier > 0, later > 0,
              let metric = previous.result.measuredMetric,
              metric == current.result.measuredMetric,
              [.loadKg, .calories, .distanceMeters].contains(metric),
              equivalentStructure(previous.prescribed.structure,
                                  current.prescribed.structure,
                                  a: previous.prescribed, b: current.prescribed),
              previous.prescribed.movements.count == current.prescribed.movements.count,
              zip(previous.prescribed.movements, current.prescribed.movements)
                .allSatisfy({ equivalent($0.0, $0.1) }),
              previous.prescribed.timeCapSeconds == current.prescribed.timeCapSeconds,
              previous.prescribed.timeCapMinutes == current.prescribed.timeCapMinutes,
              previous.scalingFingerprint == current.scalingFingerprint,
              (previous.isRx || !(previous.scalingFingerprint ?? "").isEmpty)
        else { return nil }
        return WODPreciseMeasurementComparison(
            improvement: later - earlier,
            unit: metric == .loadKg ? "kg" : metric == .calories ? "kcal" : "m",
            previousScore: previous.result.summaryLabel,
            currentScore: current.result.summaryLabel
        )
    }

    public static func compare(previous: WODComparisonContext,
                               current: WODComparisonContext) -> WODComparison? {
        let a = previous.prescribed
        let b = current.prescribed
        guard a.kind == .wod, b.kind == .wod,
              previous.isRx == current.isRx,
              let format = a.wodFormat, format == b.wodFormat,
              previous.result.format == format, current.result.format == format,
              a.timeCapMinutes == b.timeCapMinutes,
              a.timeCapSeconds == b.timeCapSeconds,
              equivalentStructure(a.structure, b.structure, a: a, b: b),
              a.emomIntervalSeconds == b.emomIntervalSeconds,
              a.rounds == b.rounds,
              a.workSeconds == b.workSeconds,
              a.restSeconds == b.restSeconds,
              a.restBetweenRoundsSeconds == b.restBetweenRoundsSeconds,
              a.movements.count == b.movements.count, !a.movements.isEmpty,
              zip(a.movements, b.movements).allSatisfy({ equivalent($0.0, $0.1) }) else {
            return nil
        }
        // Unknown modifications are not equivalent scaled executions.
        if previous.isRx {
            guard previous.scalingFingerprint == nil, current.scalingFingerprint == nil else { return nil }
        } else {
            guard let earlier = previous.scalingFingerprint, !earlier.isEmpty,
                  earlier == current.scalingFingerprint else { return nil }
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
        case .maxEffort:
            guard let metric = previous.result.measuredMetric,
                  metric == current.result.measuredMetric,
                  [.loadKg, .calories, .distanceMeters].contains(metric),
                  let before = previous.result.measuredValue,
                  let after = current.result.measuredValue,
                  before.isFinite, after.isFinite, before > 0, after > 0,
                  // Numeric comparison is exact for whole units; fractionally
                  // precise loads are reported through the typed comparison API.
                  before.rounded() == before, after.rounded() == after,
                  before < Double(Int.max), after < Double(Int.max) else { return nil }
            return WODComparison(
                previousScore: previous.result.summaryLabel,
                currentScore: current.result.summaryLabel,
                improvement: Int(after - before),
                unit: metric == .loadKg ? "kg" : metric == .calories ? "kcal" : "metros"
            )
        case .forTime, .afap, .chipper:
            guard let old = previous.result.elapsedSeconds,
                  let new = current.result.elapsedSeconds,
                  old > 0, new > 0 else { return nil }
            // Without explicit completion evidence, a time-cap result cannot be ranked.
            if let cap = a.effectiveTimeCapSeconds, (old >= cap || new >= cap) { return nil }
            return WODComparison(previousScore: previous.result.summaryLabel,
                                 currentScore: current.result.summaryLabel,
                                 improvement: old - new, unit: "segundos")
        default:
            return nil
        }
    }

    /// UUIDs of independently authored copies are intentionally ignored.
    /// Compare actual work grouping and timings instead of the generated IDs.
    private static func equivalentStructure(_ a: WorkoutStructure?,
                                            _ b: WorkoutStructure?,
                                            a original: RoutineBlock,
                                            b compared: RoutineBlock) -> Bool {
        if a == nil && b == nil { return true }
        guard let a, let b, a.version == b.version,
              a.section == b.section,
              a.collaboration == b.collaboration,
              a.resultMetric == b.resultMetric,
              a.phases.count == b.phases.count else { return false }
        let positionsA = Dictionary(uniqueKeysWithValues:
            original.movements.enumerated().map { ($0.element.id, $0.offset) })
        let positionsB = Dictionary(uniqueKeysWithValues:
            compared.movements.enumerated().map { ($0.element.id, $0.offset) })
        func samePhase(_ p: WorkoutPhase, _ q: WorkoutPhase) -> Bool {
            guard p.kind == q.kind, p.repeatCount == q.repeatCount,
                  p.workSeconds == q.workSeconds, p.restSeconds == q.restSeconds,
                  p.technique == q.technique, p.children.count == q.children.count,
                  p.movementIDs.count == q.movementIDs.count else { return false }
            let groupA = p.movementIDs.compactMap { positionsA[$0] }
            let groupB = q.movementIDs.compactMap { positionsB[$0] }
            guard groupA.count == p.movementIDs.count,
                  groupB.count == q.movementIDs.count,
                  groupA == groupB else { return false }
            return zip(p.children, q.children).allSatisfy { samePhase($0.0, $0.1) }
        }
        return zip(a.phases, b.phases).allSatisfy { samePhase($0.0, $0.1) }
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
