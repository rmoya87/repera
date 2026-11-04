import CoreSpotlight
import Foundation
import ReperaDomain

/// Index only public, curated catalog entries; never index a user's routines,
/// sessions, locations, health information or personally created exercises.
@MainActor
enum ExerciseSpotlightIndexer {
    static let domain = "com.app.repera.public-exercises"
    static let idPrefix = "exercise:"
    private static var lastIndexedSignature: Int?

    static func indexPublicExercises(_ exercises: [Exercise]) {
        let curated = exercises.filter {
            !$0.isCustom && !$0.isCatalogArchived && !$0.name.isEmpty
        }
        guard !curated.isEmpty else { return }

        // Favorite toggles can advance catalogEpoch without changing the
        // public searchable corpus. Coalesce full-catalog reindexing.
        var signature = Hasher()
        for exercise in curated {
            signature.combine(exercise.id)
            signature.combine(exercise.name)
            signature.combine(exercise.searchAliases)
        }
        let nextSignature = signature.finalize()
        guard lastIndexedSignature != nextSignature else { return }
        lastIndexedSignature = nextSignature

        // Public content only. The catalog updates asynchronously and can contain
        // repeated UUIDs after a remote merge: do not index duplicates.
        var known = Set<UUID>()
        let entries: [CSSearchableItem] = curated.compactMap { exercise in
            guard known.insert(exercise.id).inserted else { return nil }
            let attributes = CSSearchableItemAttributeSet(itemContentType: "public.text")
            attributes.title = exercise.name
            attributes.contentDescription = [exercise.muscleGroup, exercise.sportTag]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: " · ")
            attributes.keywords = exercise.searchAliases
            return CSSearchableItem(
                uniqueIdentifier: idPrefix + exercise.id.uuidString.lowercased(),
                domainIdentifier: domain,
                attributeSet: attributes
            )
        }

        // Indexing is a platform background operation; no loading states or
        // write permissions are needed and no data is sent to a Repera server.
        CSSearchableIndex.default().indexSearchableItems(entries) { _ in }
    }

    static func exerciseID(for searchableIdentifier: String) -> UUID? {
        guard searchableIdentifier.hasPrefix(idPrefix) else { return nil }
        return UUID(uuidString: String(searchableIdentifier.dropFirst(idPrefix.count)))
    }
}
