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
        secondaries: [String] = []
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
            secondaries: secondaries
        )
    }
}
