import CryptoKit
import Foundation
import ReperaDomain
import Supabase

/// Catálogo editorial de Supabase con copia independiente del JSON personal/iCloud.
/// Solo se descargan eventos posteriores al cursor; si falta red, se usa la copia local.
@MainActor
final class RemoteExerciseCatalogStore {
    static let shared = RemoteExerciseCatalogStore()

    private struct RemoteEntry: Codable, Sendable {
        var name: String
        var category: String
        var displayNameEn: String?
        var aliases: [String]?
        var primaryMuscles: [String]?
        var secondaryMuscles: [String]?
        var equipment: [String]?
        var equipmentOverride: String?
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
            case equipmentOverride = "equipment_override"
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

    private struct DiskSnapshot: Codable, Sendable {
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

    /// File I/O is isolated on a dedicated actor so initial hydration, encoding
    /// and atomic writes never block SwiftUI's MainActor.
    private actor DiskStorage {
        private let url: URL = {
            let directory = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            )[0].appendingPathComponent("Repera", isDirectory: true)
            return directory.appendingPathComponent("exercise_catalog_remote_v1.json")
        }()

        func read() -> DiskSnapshot {
            guard let data = try? Data(contentsOf: url),
                  let saved = try? JSONDecoder().decode(DiskSnapshot.self, from: data)
            else { return DiskSnapshot() }
            return saved
        }

        func write(_ snapshot: DiskSnapshot) throws {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: url, options: .atomic)
        }
    }

    private let disk = DiskStorage()

    private init() {}

    private func localSnapshot() async -> DiskSnapshot {
        if let snapshot { return snapshot }
        let loaded = await disk.read()
        snapshot = loaded
        return loaded
    }

    /// Reaplicar al restaurar iCloud: el seed empaquetado no puede pisar una corrección remota.
    func restoreCached(to store: ReperaStore) async {
        var saved = await localSnapshot()
        guard saved.revision > 0 else { return }
        let originalIDs = saved.localIDs
        // La revisión remota puede ser la misma, pero los entrenamientos
        // restaurados desde iCloud conservan UUIDs y nombres anteriores.
        // Reconciliar siempre el catálogo cacheado Y sus copias históricas.
        _ = await applyAndRelink(saved: &saved, to: store)
        snapshot = saved
        // Do not rewrite 288 entries on every iCloud restore or app launch.
        if originalIDs != saved.localIDs {
            try? await disk.write(saved)
        }
    }

    /// Called headlessly by native BGAppRefresh, then applied to UI at next foreground.
    func refresh(store: ReperaStore? = nil, force: Bool = false) async {
        guard !isRefreshing, BusinessAuthStore.shared.isConnected,
              let client = BusinessAuthStore.shared.apiClient else { return }
        if !force, let lastProbeAt, Date().timeIntervalSince(lastProbeAt) < 60 {
            // Dos triggers de primer plano en menos de 60 s tampoco deben
            // impedir aplicar el catálogo ya descargado a las sesiones locales.
            if let store { await restoreCached(to: store) }
            return
        }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            try Task.checkCancellation()
            // Una sola fila para determinar si hay cambios.
            let versions: [Version] = try await client
                .from("mobile_exercise_catalog_events")
                .select("id")
                .order("id", ascending: false)
                .limit(1)
                .execute().value
            lastProbeAt = Date()
            guard let head = versions.first?.id, head > 0 else { return }
            var working = await localSnapshot()
            if working.revision > head { working = DiskSnapshot() }
            guard head > working.revision else {
                // Sin eventos nuevos NO significa que el estado local esté
                // enlazado: iCloud o un snapshot antiguo pueden restaurarlo.
                if let store {
                    _ = await applyAndRelink(saved: &working, to: store)
                    snapshot = working
                }
                lastSuccessfulSync = Date()
                lastErrorMessage = nil
                return
            }

            // Ventana cerrada por `head`: cambios concurrentes se recogerán después.
            while working.revision < head {
                try Task.checkCancellation()
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
            try Task.checkCancellation()
            // First write is the crash-consistent cursor checkpoint.
            try await disk.write(working)
            snapshot = working
            let idsBeforeMerge = working.localIDs
            if let store, await applyAndRelink(saved: &working, to: store) {
                store.notifyCatalogChangedForWatch()
            }
            snapshot = working
            // One write normally; a second only if UUID identity was learned.
            if idsBeforeMerge != working.localIDs {
                try await disk.write(working)
            }
            lastSuccessfulSync = Date()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
            // No alterar el catálogo ni los entrenamientos cuando falla la red.
        }
    }

    /// Aplicar catálogo y referencias de WOD antiguos es una sola operación
    /// lógica. Las llamadas anteriores actualizaban solo las plantillas,
    /// dejando sin reconciliar SessionExercise.exercise de AMRAP ya terminados.
    @discardableResult
    private func applyAndRelink(saved: inout DiskSnapshot, to store: ReperaStore) async -> Bool {
        let catalogChanged = await apply(saved: &saved, to: store)
        let historyChanged = store.relinkOrphanSessionExercisesToCatalog()
        let plannedChanged = store.relinkScheduledWODMovementsToCatalog()
        guard catalogChanged || historyChanged || plannedChanged else { return false }
        store.bumpCatalogEpoch()
        if historyChanged { store.bumpWorkoutsEpoch() }
        // Escribir localmente, sin sustituir sesiones activas ni sus resultados.
        // Solo cambian referencias y metadatos de ejercicios.
        store.persistLocalOnly(immediate: true)
        return true
    }

    /// Mezcla por clave editorial + UUID persistente + alias original de la clave.
    /// Nunca se reemplazan los UUID históricos ni los favoritos del usuario.
    @discardableResult
    private func apply(saved: inout DiskSnapshot, to store: ReperaStore) async -> Bool {
        for _ in 0..<3 {
            let revision = store.state.syncRevision
            let epoch = store.catalogEpoch
            let current = store.state.exercises
            let source = saved
            let merged = await Task.detached(priority: .utility) {
                Self.merge(source: source, current: current)
            }.value
            // A user can edit favourites during decoding: never commit stale input.
            guard store.state.syncRevision == revision, store.catalogEpoch == epoch else { continue }
            saved = merged.snapshot
            if merged.changed {
                store.state.exercises = merged.exercises
                store.state.updatedAt = Date()
            }
            return merged.changed
        }
        return false
    }

    nonisolated private static func merge(
        source: DiskSnapshot, current: [Exercise]
    ) -> (snapshot: DiskSnapshot, exercises: [Exercise], changed: Bool) {
        var saved = source
        var result = current
        var byID: [UUID: Int] = [:]
        var byName: [String: Int] = [:]
        var byCanonical: [String: Int] = [:]
        var byCatalogID: [String: Int] = [:]
        for (i, ex) in result.enumerated() where !ex.isCustom {
            byID[ex.id] = i
            byName[Self.normalized(ex.name)] = i
            byCanonical[Self.normalized(SportExerciseNames.canonicalName(ex.name))] = i
            if let id = ex.catalogId { byCatalogID[id] = i }
        }

        var changed = false
        for (key, remote) in saved.entries.sorted(by: { $0.key < $1.key }) {
            let originalName = key.hasPrefix("catalog:") ? String(key.dropFirst(8)) : remote.name
            let matchedIndex = saved.localIDs[key].flatMap { byID[$0] }
                ?? remote.nativeCatalogId.flatMap { byCatalogID[$0] }
                ?? byName[Self.normalized(originalName)]
                ?? byCanonical[Self.normalized(SportExerciseNames.canonicalName(originalName))]
                ?? byName[Self.normalized(remote.name)]
            let old = matchedIndex.map { result[$0] }
            let resolvedID = old?.id ?? saved.localIDs[key] ?? Self.stableUUID(for: key)
            saved.localIDs[key] = resolvedID

            let primary = remote.primaryMuscles ?? []
            let secondary = remote.secondaryMuscles ?? []
            let resolvedGroup = remote.muscleGroup
                ?? (primary.isEmpty
                    ? (old?.muscleGroup ?? "Custom")
                    : MuscleTaxonomy.libraryMuscleGroup(primaries: primary, target: primary.first))
            // Conservar textos del seed hasta que se hayan trasladado al servidor.
            // Una descripción publicada reemplaza inmediatamente la embebida.
            let description = remote.description ?? old?.detailDescription
            let instructions = (remote.instructions?.isEmpty == false)
                ? remote.instructions! : (old?.instructions ?? [])
            let equipment = remote.equipmentOverride
                ?? old?.equipment
                ?? (remote.equipment?.isEmpty == false
                    ? remote.equipment!.joined(separator: ", ") : nil)
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
            byCanonical[Self.normalized(SportExerciseNames.canonicalName(remote.name))] = index
            if let id = next.catalogId { byCatalogID[id] = index }
        }
        // Las bajas se conservan en la librería interna; UI/pickers las ocultan,
        // por lo que sesiones, rutinas y PRs antiguos siguen resolviendo el UUID.
        return (saved, result, changed)
    }

    /// UUID reproducible para fichas publicadas tras la instalación del seed;
    /// dos iPhone con la misma cuenta nunca crean dos IDs para la misma clave.
    private nonisolated static func stableUUID(for catalogKey: String) -> UUID {
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
