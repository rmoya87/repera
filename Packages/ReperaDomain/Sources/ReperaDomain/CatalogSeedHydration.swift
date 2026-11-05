import Foundation

/// Hidrata huecos del catálogo local con el seed empaquetado sin pisar
/// copy editorial / arte / taxonomía ya aplicados desde Supabase.
public enum CatalogSeedHydration: Sendable {
    public struct Result: Sendable, Equatable {
        public var exercises: [Exercise]
        public var changed: Bool

        public init(exercises: [Exercise], changed: Bool) {
            self.exercises = exercises
            self.changed = changed
        }
    }

    /// Enriquecer filas existentes + añadir altas del seed que falten.
    /// Textos, `artKeys`, skill/patrón/alternatives y alias no vacíos se conservan:
    /// la autoridad viva es el feed remoto (o el valor ya hidratado).
    public static func merge(current: [Exercise], seed: [Exercise]) -> Result {
        let seedByName = Dictionary(uniqueKeysWithValues: seed.map { ($0.name, $0) })
        var exercises = current
        var changed = false
        for i in exercises.indices {
            guard !exercises[i].isCustom,
                  let fresh = seedByName[SportExerciseNames.canonicalName(exercises[i].name)]
            else { continue }

            let current = exercises[i]
            let hasLocalDescription = !(current.detailDescription ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let hasLocalInstructions = !current.instructions.isEmpty
            let looksRemoteAuthored = !current.artKeys.isEmpty
                || current.skillLevel != nil
                || !current.catalogAlternatives.isEmpty
                || (hasLocalDescription && current.detailDescription != fresh.detailDescription)
                || (hasLocalInstructions && current.instructions != fresh.instructions)

            let description = hasLocalDescription
                ? current.detailDescription
                : fresh.detailDescription
            let instructions = hasLocalInstructions
                ? current.instructions
                : fresh.instructions

            let muscleGroup: String
            let equipment: String?
            let sportTag: String?
            let targetMuscle: String?
            let secondaryMuscles: [String]
            let bodyPart: String?
            let primaryRegions: [String]
            let secondaryRegions: [String]
            if looksRemoteAuthored {
                muscleGroup = current.muscleGroup
                equipment = current.equipment ?? fresh.equipment
                sportTag = current.sportTag ?? fresh.sportTag
                targetMuscle = current.targetMuscle ?? fresh.targetMuscle
                secondaryMuscles = current.secondaryMuscles.isEmpty
                    ? fresh.secondaryMuscles : current.secondaryMuscles
                bodyPart = current.bodyPart ?? fresh.bodyPart
                primaryRegions = current.primaryRegions.isEmpty
                    ? fresh.primaryRegions : current.primaryRegions
                secondaryRegions = current.secondaryRegions.isEmpty
                    ? fresh.secondaryRegions : current.secondaryRegions
            } else {
                muscleGroup = fresh.muscleGroup
                equipment = fresh.equipment
                sportTag = fresh.sportTag
                targetMuscle = fresh.targetMuscle
                secondaryMuscles = fresh.secondaryMuscles
                bodyPart = fresh.bodyPart
                primaryRegions = fresh.primaryRegions
                secondaryRegions = fresh.secondaryRegions
            }

            let next = Exercise(
                id: current.id,
                name: fresh.name,
                muscleGroup: muscleGroup,
                equipment: equipment,
                isCustom: false,
                catalogId: current.catalogId ?? fresh.catalogId,
                targetMuscle: targetMuscle,
                secondaryMuscles: secondaryMuscles,
                bodyPart: bodyPart,
                detailDescription: description,
                instructions: instructions,
                searchAliases: current.searchAliases,
                primaryRegions: primaryRegions,
                secondaryRegions: secondaryRegions,
                isFavorite: current.isFavorite,
                isCatalogArchived: current.isCatalogArchived,
                sportTag: sportTag,
                skillLevel: current.skillLevel ?? fresh.skillLevel,
                movementPattern: current.movementPattern ?? fresh.movementPattern,
                catalogAlternatives: current.catalogAlternatives.isEmpty
                    ? fresh.catalogAlternatives : current.catalogAlternatives,
                artKeys: current.artKeys.isEmpty ? fresh.artKeys : current.artKeys
            )
            if next != current {
                exercises[i] = next
                changed = true
            }
        }

        let existing = Set(exercises.filter { !$0.isCustom }
            .map { SportExerciseNames.canonicalName($0.name) })
        let missing = seed.filter { !existing.contains($0.name) }
        if !missing.isEmpty {
            exercises.append(contentsOf: missing)
            changed = true
        }
        return Result(exercises: exercises, changed: changed)
    }
}
