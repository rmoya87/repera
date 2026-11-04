import CryptoKit
import Foundation

/// Ficha editorial publicada en el feed `mobile_exercise_catalog_events`.
public struct RemoteExerciseCatalogEntry: Codable, Sendable, Equatable {
    public var name: String
    public var category: String
    public var displayNameEn: String?
    public var aliases: [String]?
    public var primaryMuscles: [String]?
    public var secondaryMuscles: [String]?
    public var equipment: [String]?
    public var equipmentOverride: String?
    public var nativeCatalogId: String?
    public var description: String?
    public var instructions: [String]?
    public var bodyPart: String?
    public var muscleGroup: String?
    public var sportTag: String?
    public var skillLevel: String?
    public var movementPattern: String?
    public var alternatives: [String]?
    public var artKeys: [String]?
    public var isActive: Bool

    public enum CodingKeys: String, CodingKey {
        case name, category, aliases, equipment, description, instructions
        case displayNameEn = "display_name_en"
        case equipmentOverride = "equipment_override"
        case primaryMuscles = "primary_muscles"
        case secondaryMuscles = "secondary_muscles"
        case nativeCatalogId = "native_catalog_id"
        case bodyPart = "body_part"
        case muscleGroup = "muscle_group"
        case sportTag = "sport_tag"
        case skillLevel = "skill_level"
        case movementPattern = "movement_pattern"
        case alternatives
        case artKeys = "art_keys"
        case isActive = "is_active"
    }

    public init(
        name: String,
        category: String,
        displayNameEn: String? = nil,
        aliases: [String]? = nil,
        primaryMuscles: [String]? = nil,
        secondaryMuscles: [String]? = nil,
        equipment: [String]? = nil,
        equipmentOverride: String? = nil,
        nativeCatalogId: String? = nil,
        description: String? = nil,
        instructions: [String]? = nil,
        bodyPart: String? = nil,
        muscleGroup: String? = nil,
        sportTag: String? = nil,
        skillLevel: String? = nil,
        movementPattern: String? = nil,
        alternatives: [String]? = nil,
        artKeys: [String]? = nil,
        isActive: Bool = true
    ) {
        self.name = name
        self.category = category
        self.displayNameEn = displayNameEn
        self.aliases = aliases
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.equipment = equipment
        self.equipmentOverride = equipmentOverride
        self.nativeCatalogId = nativeCatalogId
        self.description = description
        self.instructions = instructions
        self.bodyPart = bodyPart
        self.muscleGroup = muscleGroup
        self.sportTag = sportTag
        self.skillLevel = skillLevel
        self.movementPattern = movementPattern
        self.alternatives = alternatives
        self.artKeys = artKeys
        self.isActive = isActive
    }
}

/// Instantánea de caché local del catálogo remoto (Application Support / filesDir).
public struct RemoteExerciseCatalogSnapshot: Codable, Sendable, Equatable {
    public var revision: Int64
    public var entries: [String: RemoteExerciseCatalogEntry]
    /// La clave editorial nunca cambia, aunque se renombre el ejercicio.
    public var localIDs: [String: UUID]
    public var tombstones: Set<String>

    public init(
        revision: Int64 = 0,
        entries: [String: RemoteExerciseCatalogEntry] = [:],
        localIDs: [String: UUID] = [:],
        tombstones: Set<String> = []
    ) {
        self.revision = revision
        self.entries = entries
        self.localIDs = localIDs
        self.tombstones = tombstones
    }
}

/// Mezcla pura seed/local + feed remoto. Sin I/O ni red.
public enum RemoteExerciseCatalogMerge: Sendable {
    public struct Result: Sendable, Equatable {
        public var snapshot: RemoteExerciseCatalogSnapshot
        public var exercises: [Exercise]
        public var changed: Bool

        public init(
            snapshot: RemoteExerciseCatalogSnapshot,
            exercises: [Exercise],
            changed: Bool
        ) {
            self.snapshot = snapshot
            self.exercises = exercises
            self.changed = changed
        }
    }

    /// Mezcla por clave editorial + UUID persistente + alias original de la clave.
    /// Nunca se reemplazan los UUID históricos ni los favoritos del usuario.
    /// Campos publicados no vacíos en remoto pisan el seed; null/vacío conserva el local.
    public static func apply(
        source: RemoteExerciseCatalogSnapshot,
        current: [Exercise]
    ) -> Result {
        var saved = source
        var result = current
        var byID: [UUID: Int] = [:]
        var byName: [String: Int] = [:]
        var byCanonical: [String: Int] = [:]
        var byCatalogID: [String: Int] = [:]
        for (i, ex) in result.enumerated() where !ex.isCustom {
            byID[ex.id] = i
            byName[normalized(ex.name)] = i
            byCanonical[normalized(SportExerciseNames.canonicalName(ex.name))] = i
            if let id = ex.catalogId { byCatalogID[id] = i }
        }

        var changed = false
        for (key, remote) in saved.entries.sorted(by: { $0.key < $1.key }) {
            let originalName = key.hasPrefix("catalog:") ? String(key.dropFirst(8)) : remote.name
            let matchedIndex = saved.localIDs[key].flatMap { byID[$0] }
                ?? remote.nativeCatalogId.flatMap { byCatalogID[$0] }
                ?? byName[normalized(originalName)]
                ?? byCanonical[normalized(SportExerciseNames.canonicalName(originalName))]
                ?? byName[normalized(remote.name)]
            let old = matchedIndex.map { result[$0] }
            let resolvedID = old?.id ?? saved.localIDs[key] ?? stableUUID(for: key)
            saved.localIDs[key] = resolvedID

            let primary = remote.primaryMuscles ?? []
            let secondary = remote.secondaryMuscles ?? []
            let resolvedGroup = remote.muscleGroup
                ?? (primary.isEmpty
                    ? (old?.muscleGroup ?? "Custom")
                    : MuscleTaxonomy.libraryMuscleGroup(primaries: primary, target: primary.first))
            // Publicado gana; null/vacío conserva textos del seed/bootstrap.
            let description = remote.description ?? old?.detailDescription
            let instructions = (remote.instructions?.isEmpty == false)
                ? remote.instructions! : (old?.instructions ?? [])
            // override → array remoto no vacío → seed/local.
            let equipment = remote.equipmentOverride
                ?? (remote.equipment?.isEmpty == false
                    ? remote.equipment!.joined(separator: ", ") : nil)
                ?? old?.equipment
            let sport = remote.sportTag
                ?? (remote.category == "Fuerza" ? nil : remote.category)
            let archived = saved.tombstones.contains(key) || !remote.isActive
            let alternatives = (remote.alternatives?.isEmpty == false)
                ? remote.alternatives! : (old?.catalogAlternatives ?? [])
            let artKeys = (remote.artKeys?.isEmpty == false)
                ? remote.artKeys! : (old?.artKeys ?? [])
            let next = Exercise(
                id: resolvedID,
                name: remote.name,
                muscleGroup: resolvedGroup,
                equipment: equipment,
                isCustom: false,
                catalogId: remote.nativeCatalogId ?? old?.catalogId,
                targetMuscle: primary.first ?? old?.targetMuscle,
                secondaryMuscles: secondary.isEmpty ? (old?.secondaryMuscles ?? []) : secondary,
                bodyPart: remote.bodyPart ?? old?.bodyPart,
                detailDescription: description,
                instructions: instructions,
                searchAliases: remote.aliases ?? [],
                primaryRegions: primary.isEmpty ? (old?.primaryRegions ?? []) : primary,
                secondaryRegions: secondary.isEmpty ? (old?.secondaryRegions ?? []) : secondary,
                isFavorite: old?.isFavorite ?? false,
                isCatalogArchived: archived,
                sportTag: sport,
                skillLevel: remote.skillLevel ?? old?.skillLevel,
                movementPattern: remote.movementPattern ?? old?.movementPattern,
                catalogAlternatives: alternatives,
                artKeys: artKeys
            )
            if let matchedIndex {
                if result[matchedIndex] != next {
                    result[matchedIndex] = next
                    changed = true
                }
            } else {
                result.append(next)
                changed = true
            }
            let index = matchedIndex ?? result.count - 1
            byID[resolvedID] = index
            byName[normalized(remote.name)] = index
            byCanonical[normalized(SportExerciseNames.canonicalName(remote.name))] = index
            if let id = next.catalogId { byCatalogID[id] = index }
        }
        return Result(snapshot: saved, exercises: result, changed: changed)
    }

    /// UUID reproducible para fichas publicadas tras la instalación del seed.
    public static func stableUUID(for catalogKey: String) -> UUID {
        var bytes = Array(SHA256.hash(data: Data(
            ("com.app.repera.remote-catalog.v1:" + catalogKey).utf8
        )).prefix(16))
        bytes[6] = (bytes[6] & 0x0f) | 0x50
        bytes[8] = (bytes[8] & 0x3f) | 0x80
        let hex = bytes.map { String(format: "%02x", $0) }.joined()
        return UUID(uuidString:
            "\(hex.prefix(8))-\(hex.dropFirst(8).prefix(4))-\(hex.dropFirst(12).prefix(4))-\(hex.dropFirst(16).prefix(4))-\(hex.dropFirst(20).prefix(12))"
        )!
    }

    public static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive],
                     locale: Locale(identifier: "es_ES"))
            .lowercased()
    }
}
