import Foundation

/// Sugiere ejercicios alternativos: primero los publicados en Supabase,
/// si no hay, heurística por músculo / target.
public enum ExerciseSubstitutes {
    public static func substitutes(
        for exercise: Exercise,
        in catalog: [Exercise],
        limit: Int = 12
    ) -> [Exercise] {
        if !exercise.catalogAlternatives.isEmpty {
            let byName = Dictionary(
                catalog.filter { !$0.isCustom && !$0.isCatalogArchived }.map {
                    (normalized($0.name), $0)
                },
                uniquingKeysWith: { first, _ in first }
            )
            var resolved: [Exercise] = []
            var seen = Set<UUID>()
            for raw in exercise.catalogAlternatives {
                let key = normalized(raw)
                guard let hit = byName[key] ?? byName[normalized(SportExerciseNames.canonicalName(raw))],
                      hit.id != exercise.id,
                      seen.insert(hit.id).inserted
                else { continue }
                resolved.append(hit)
                if resolved.count >= limit { return resolved }
            }
            if !resolved.isEmpty { return resolved }
        }

        let target = exercise.targetMuscle
        let muscle = exercise.muscleGroup
        let scored: [(Exercise, Int)] = catalog
            .filter { $0.id != exercise.id && !$0.isCatalogArchived }
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

    private static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive],
                     locale: Locale(identifier: "es_ES"))
            .lowercased()
    }
}
