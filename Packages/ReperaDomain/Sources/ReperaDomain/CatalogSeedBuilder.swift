import Foundation

enum CatalogSeedBuilder {
    static func row(
        _ name: String,
        group: String,
        equipment: String?,
        target: String,
        secondary: [String],
        body: String,
        description: String,
        instructions: [String],
        primaries: [String] = [],
        secondaries: [String] = [],
        sportTag: String? = nil
    ) -> EnrichedSeed {
        EnrichedSeed(
            name: name,
            muscleGroup: group,
            equipment: equipment,
            catalogId: nil,
            target: target,
            secondaryMuscles: secondary,
            bodyPart: body,
            description: description,
            instructions: instructions,
            primaries: primaries,
            secondaries: secondaries,
            sportTag: sportTag
        )
    }

    /// CrossFit / Halterofilia / Gimnasia: grupo = músculo principal; `sportTag` solo para filtro Deporte.
    static func sportRow(
        _ name: String,
        sport: String,
        equipment: String?,
        target: String,
        secondary: [String],
        body: String,
        description: String,
        instructions: [String],
        primaries: [String] = [],
        secondaries: [String] = []
    ) -> EnrichedSeed {
        let group = MuscleTaxonomy.libraryMuscleGroup(primaries: primaries, target: target)
        return row(
            SportExerciseNames.displayName(name, sport: sport),
            group: group,
            equipment: equipment,
            target: target,
            secondary: secondary,
            body: body,
            description: description,
            instructions: instructions,
            primaries: primaries,
            secondaries: secondaries,
            sportTag: sport
        )
    }
}
