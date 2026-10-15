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

public enum MuscleMapEngine {
    /// Half-life hours by Gymbro muscle group labels.
    private static let halfLifeHours: [String: Double] = [
        "Pecho": 30,
        "Espalda": 30,
        "Hombros": 24,
        "Bíceps": 24,
        "Tríceps": 24,
        "Piernas": 48,
        "Isquios": 48,
        "Glúteos": 48,
        "Gemelos": 48,
        "Core": 24,
        "Cardio": 12,
    ]

    public static func statuses(
        from workouts: [WorkoutSession],
        now: Date = Date()
    ) -> [MuscleStatus] {
        var stimulus: [String: Double] = [:]
        var weekly: [String: Double] = [:]
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now

        for workout in workouts {
            let when = workout.finishedAt ?? workout.startedAt ?? now
            let ageHours = now.timeIntervalSince(when) / 3600
            guard ageHours >= 0, ageHours < 30 * 24 else { continue }

            for entry in workout.exercises {
                let muscle = entry.exercise.muscleGroup
                // Warm-ups count less; hard work sets (low RIR) count fully.
                let hardSets = entry.loggedSets.reduce(0.0) { partial, set in
                    guard set.reps > 0 else { return partial }
                    if set.isWarmup { return partial + 0.25 }
                    if Effort.isHard(rir: set.rir) { return partial + 1.0 }
                    return partial + 0.7
                }
                guard hardSets > 0 else { continue }
                let capped = min(hardSets, 12)
                let hl = halfLifeHours[muscle] ?? 30
                let retained = capped * pow(0.5, ageHours / hl)
                stimulus[muscle, default: 0] += retained
                if when >= weekAgo {
                    weekly[muscle, default: 0] += capped
                }
            }
        }

        let names = Set(stimulus.keys).union(weekly.keys).union(Set(halfLifeHours.keys))
        return names.sorted().map { name in
            // Normalize: ~8 hard-set units ≈ score 1.0
            let raw = (stimulus[name] ?? 0) / 8.0
            let score = min(1.5, raw)
            let state: FatigueState
            if score < 0.25 {
                state = .ready
            } else if score <= 0.5 {
                state = .recovering
            } else {
                state = .fatigued
            }
            return MuscleStatus(
                name: name,
                score: score,
                state: state,
                setsLast7Days: weekly[name] ?? 0
            )
        }
        .sorted { $0.score > $1.score }
    }
}
