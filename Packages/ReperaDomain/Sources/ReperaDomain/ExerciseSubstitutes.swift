import Foundation

/// Sugiere ejercicios alternativos del mismo músculo / target.
public enum ExerciseSubstitutes {
    public static func substitutes(
        for exercise: Exercise,
        in catalog: [Exercise],
        limit: Int = 12
    ) -> [Exercise] {
        let target = exercise.targetMuscle
        let muscle = exercise.muscleGroup
        let scored: [(Exercise, Int)] = catalog
            .filter { $0.id != exercise.id }
            .map { candidate in
                var score = 0
                if let target, let other = candidate.targetMuscle, other == target { score += 3 }
                if candidate.muscleGroup == muscle { score += 2 }
                if candidate.equipment == exercise.equipment { score += 1 }
                if candidate.bodyPart == exercise.bodyPart { score += 1 }
                return (candidate, score)
            }
            .filter { $0.1 >= 2 }
            .sorted {
                if $0.1 != $1.1 { return $0.1 > $1.1 }
                return $0.0.name.localizedCaseInsensitiveCompare($1.0.name) == .orderedAscending
            }
        return scored.prefix(limit).map(\.0)
    }
}
