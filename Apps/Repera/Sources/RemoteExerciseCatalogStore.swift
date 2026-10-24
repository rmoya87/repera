import CryptoKit
import Foundation
import ReperaDomain
import Supabase

/// Catálogo editorial de Supabase con copia independiente del JSON personal/iCloud.
/// Solo se descargan eventos posteriores al cursor; si falta red, se usa la copia local.
@MainActor
final class RemoteExerciseCatalogStore {
    static let shared = RemoteExerciseCatalogStore()

    private struct RemoteEntry: Codable {
        var name: String
        var category: String
        var displayNameEn: String?
        var aliases: [String]?
        var primaryMuscles: [String]?
        var secondaryMuscles: [String]?
        var equipment: [String]?
        var nativeCatalogId: String?
        var description: String?
        var instructions: [String]?
        var bodyPart: String?
        var muscleGroup: String?
        var sportTag: String?
        var isActive: Bool

        enum CodingKeys: String, CodingKey {
            case name, category, aliases, equipment, description, instructions
            case displayNameEn = "display_name_en"
            case primaryMuscles = "primary_muscles"
            case secondaryMuscles = "secondary_muscles"
            case nativeCatalogId = "native_catalog_id"
            case bodyPart = "body_part"
            case muscleGroup = "muscle_group"
            case sportTag = "sport_tag"
            case isActive = "is_active"
        }
    }

    private struct Event: Decodable {
        let id: Int64
        let catalogKey: String
        let operation: String
        let payload: RemoteEntry?

        enum CodingKeys: String, CodingKey {
            case id, operation, payload
            case catalogKey = "catalog_key"
        }
    }

    private struct Version: Decodable { let id: Int64 }

    private struct DiskSnapshot: Codable {
        var revision: Int64 = 0
        var entries: [String: RemoteEntry] = [:]
        /// La clave editorial nunca cambia, aunque se renombre el ejercicio.
        var localIDs: [String: UUID] = [:]
        var tombstones: Set<String> = []
    }

    private var snapshot: DiskSnapshot?
    private var isRefreshing = false
    private var lastProbeAt: Date?
    private(set) var lastErrorMessage: String?
    private(set) var lastSuccessfulSync: Date?

    private let fileURL: URL = {
        let directory = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        )[0].appendingPathComponent("Repera", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("exercise_catalog_remote_v1.json")
    }()

    private init() {}

    private func localSnapshot() -> DiskSnapshot {
        if let snapshot { return snapshot }
        let stored = (try? Data(contentsOf: fileURL))
            .flatMap { try? JSONDecoder().decode(DiskSnapshot.self, from: $0) }
        let resolved = stored ?? DiskSnapshot()
        snapshot = resolved
        return resolved
    }

    /// Reaplicar al restaurar iCloud: el seed empaquetado no puede pisar una corrección remota.
    func restoreCached(to store: ReperaStore) {
        var saved = localSnapshot()
        guard saved.revision > 0 else { return }
        if apply(saved: &saved, to: store) {
            store.bumpCatalogEpoch()
            store.persistLocalOnly(immediate: true)
        }
        snapshot = saved
        save(saved)
    }

    func refresh(store: ReperaStore, force: Bool = false) async {
        guard !isRefreshing, BusinessAuthStore.shared.isConnected,
              let client = BusinessAuthStore.shared.apiClient else { return }
        if !force, let lastProbeAt, Date().timeIntervalSince(lastProbeAt) < 60 { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            // Una sola fila para determinar si hay cambios.
            let versions: [Version] = try await client
                .from("mobile_exercise_catalog_events")
                .select("id")
                .order("id", ascending: false)
                .limit(1)
                .execute().value
            lastProbeAt = Date()
            guard let head = versions.first?.id, head > 0 else { return }
            var working = localSnapshot()
            if working.revision > head { working = DiskSnapshot() }
            guard head > working.revision else {
                lastSuccessfulSync = Date()
                lastErrorMessage = nil
                return
            }

            // Ventana cerrada por `head`: cambios concurrentes se recogerán después.
            while working.revision < head {
                let events: [Event] = try await client
                    .from("mobile_exercise_catalog_events")
                    .select("id,catalog_key,operation,payload")
                    .gt("id", value: String(working.revision))
                    .lte("id", value: String(head))
                    .order("id", ascending: true)
                    .limit(150)
                    .execute().value
                guard !events.isEmpty else {
                    throw CatalogSyncError.incompletePage
                }
                for event in events {
                    guard event.id > working.revision else { continue }
                    switch event.operation {
                    case "upsert":
                        guard let payload = event.payload, !payload.name.isEmpty else {
                            throw CatalogSyncError.invalidEvent
                        }
                        working.entries[event.catalogKey] = payload
                        working.tombstones.remove(event.catalogKey)
                    case "delete":
                        working.tombstones.insert(event.catalogKey)
                        // Se retiene la ficha anterior para los resultados históricos.
                        if var old = working.entries[event.catalogKey] {
                            old.isActive = false
                            working.entries[event.catalogKey] = old
                        }
                    default:
                        throw CatalogSyncError.invalidEvent
                    }
                    working.revision = event.id
                }
            }

            // Guardar el feed completo antes de actualizar la UI: nunca avanzar
            // el cursor solo en memoria y perder actualizaciones tras un cierre.
            try saveThrowing(working)
            snapshot = working
            if apply(saved: &working, to: store) {
                store.bumpCatalogEpoch()
                store.persistLocalOnly(immediate: true)
                store.notifyCatalogChangedForWatch()
            }
            snapshot = working
            try saveThrowing(working)
            lastSuccessfulSync = Date()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
            // No alterar el catálogo ni los entrenamientos cuando falla la red.
        }
    }

    private func save(_ snapshot: DiskSnapshot) {
        try? saveThrowing(snapshot)
    }

    private func saveThrowing(_ snapshot: DiskSnapshot) throws {
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: fileURL, options: [.atomic])
    }

    /// Mezcla por clave editorial + UUID persistente + alias original de la clave.
    /// Nunca se reemplazan los UUID históricos ni los favoritos del usuario.
    @discardableResult
    private func apply(saved: inout DiskSnapshot, to store: ReperaStore) -> Bool {
        var result = store.state.exercises
        var byID: [UUID: Int] = [:]
        var byName: [String: Int] = [:]
        var byCatalogID: [String: Int] = [:]
        for (i, ex) in result.enumerated() where !ex.isCustom {
            byID[ex.id] = i
            byName[Self.normalized(ex.name)] = i
            if let id = ex.catalogId { byCatalogID[id] = i }
        }

        var changed = false
        for (key, remote) in saved.entries.sorted(by: { $0.key < $1.key }) {
            let originalName = key.hasPrefix("catalog:") ? String(key.dropFirst(8)) : remote.name
            let matchedIndex = saved.localIDs[key].flatMap { byID[$0] }
                ?? remote.nativeCatalogId.flatMap { byCatalogID[$0] }
                ?? byName[Self.normalized(originalName)]
                ?? byName[Self.normalized(remote.name)]
            let old = matchedIndex.map { result[$0] }
            let resolvedID = old?.id ?? saved.localIDs[key] ?? UUID()
            saved.localIDs[key] = resolvedID

            let primary = remote.primaryMuscles ?? []
            let secondary = remote.secondaryMuscles ?? []
            let resolvedGroup = remote.muscleGroup
                ?? old?.muscleGroup
                ?? MuscleTaxonomy.libraryMuscleGroup(primaries: primary, target: primary.first)
            // Conservar textos del seed hasta que se hayan trasladado al servidor.
            // Una descripción publicada reemplaza inmediatamente la embebida.
            let description = remote.description ?? old?.detailDescription
            let instructions = (remote.instructions?.isEmpty == false)
                ? remote.instructions! : (old?.instructions ?? [])
            let equipment = (remote.equipment?.isEmpty == false)
                ? remote.equipment!.joined(separator: ", ") : old?.equipment
            let sport = remote.sportTag
                ?? (remote.category == "Fuerza" ? nil : remote.category)
            let archived = saved.tombstones.contains(key) || !remote.isActive
            let next = Exercise(
                id: resolvedID,
                name: remote.name,
                muscleGroup: resolvedGroup,
                equipment: equipment,
                isCustom: false,
                catalogId: remote.nativeCatalogId ?? old?.catalogId,
                targetMuscle: old?.targetMuscle ?? primary.first,
                secondaryMuscles: old?.secondaryMuscles.isEmpty == false ? old!.secondaryMuscles : secondary,
                bodyPart: remote.bodyPart ?? old?.bodyPart,
                detailDescription: description,
                instructions: instructions,
                primaryRegions: primary.isEmpty ? (old?.primaryRegions ?? []) : primary,
                secondaryRegions: secondary.isEmpty ? (old?.secondaryRegions ?? []) : secondary,
                isFavorite: old?.isFavorite ?? false,
                isCatalogArchived: archived,
                sportTag: sport
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
            byName[Self.normalized(remote.name)] = index
            if let id = next.catalogId { byCatalogID[id] = index }
        }
        // Las bajas se conservan en la librería interna; UI/pickers las ocultan,
        // por lo que sesiones, rutinas y PRs antiguos siguen resolviendo el UUID.
        if changed {
            store.state.exercises = result
            store.state.updatedAt = Date()
        }
        return changed
    }

    private nonisolated static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive],
                     locale: Locale(identifier: "es_ES"))
            .lowercased()
    }

    private enum CatalogSyncError: LocalizedError {
        case incompletePage, invalidEvent
        var errorDescription: String? {
            switch self {
            case .incompletePage: return "Faltan eventos del catálogo remoto."
            case .invalidEvent: return "Evento inválido en el catálogo remoto."
            }
        }
    }
}
