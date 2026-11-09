import Foundation

/// A strength record is a *recorded* working set, never a prescribed target.
public struct StrengthRepRecord: Sendable {
    public var minimumReps: Int
    public var bestWeightKg: Double
    public var achievedReps: Int
    public var workoutId: UUID
    public var date: Date
}

public enum StrengthRepRecordEngine {
    /// Best actually lifted kg for sets of at least 3, 5 and 10 reps.
    /// These are rep-range records, NOT tested 1RM or e1RM.
    public static func bestSets(
        exerciseId: UUID, workouts: [WorkoutSession],
        targets: [Int] = [3, 5, 10]
    ) -> [StrengthRepRecord] {
        var seen = Set<UUID>()
        var best: [Int: StrengthRepRecord] = [:]
        for session in workouts.sorted(by: {
            ($0.finishedAt ?? .distantPast) < ($1.finishedAt ?? .distantPast)
        }) {
            guard (session.finishedAt != nil || session.phase == .finished),
                  seen.insert(session.id).inserted else { continue }
            let date = session.finishedAt ?? session.startedAt ?? .distantPast
            for entry in session.exercises where entry.exercise.id == exerciseId {
                for set in entry.loggedSets where set.countsForProgression &&
                    set.quantityUnit != .calories && set.quantityUnit != .meters &&
                    set.deficitCm == nil {
                    guard set.reps > 0, let kg = set.weightKg,
                          kg.isFinite && kg > 0 else { continue }
                    for threshold in targets where threshold > 0 && set.reps >= threshold {
                        if let prior = best[threshold], prior.bestWeightKg > kg { continue }
                        best[threshold] = StrengthRepRecord(
                            minimumReps: threshold,
                            bestWeightKg: kg,
                            achievedReps: set.reps,
                            workoutId: session.id,
                            date: date
                        )
                    }
                }
            }
        }
        return targets.compactMap { best[$0] }
    }
}
