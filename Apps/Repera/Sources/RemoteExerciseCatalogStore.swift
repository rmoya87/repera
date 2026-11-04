import Foundation
import ReperaDomain
import Supabase

/// Catálogo editorial de Supabase con copia independiente del JSON personal/iCloud.
/// Solo se descargan eventos posteriores al cursor; si falta red, se usa la copia local.
@MainActor
final class RemoteExerciseCatalogStore {
    static let shared = RemoteExerciseCatalogStore()

    private struct Event: Decodable {
        let id: Int64
        let catalogKey: String
        let operation: String
        let payload: RemoteExerciseCatalogEntry?

        enum CodingKeys: String, CodingKey {
            case id, operation, payload
            case catalogKey = "catalog_key"
        }
    }

    private struct Version: Decodable { let id: Int64 }

    private struct Bootstrap: Decodable {
        let revision: Int64
        let entries: [String: RemoteExerciseCatalogEntry]
    }

    /// Si el cursor va muy atrás, un RPC con el estado actual es más barato
    /// que rejugar miles de eventos (p. ej. tras un reemit editorial).
    private static let bootstrapLagThreshold: Int64 = 300
    private static let eventPageSize = 500

    private var snapshot: RemoteExerciseCatalogSnapshot?
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

        func read() -> RemoteExerciseCatalogSnapshot {
            guard let data = try? Data(contentsOf: url),
                  let saved = try? JSONDecoder().decode(RemoteExerciseCatalogSnapshot.self, from: data)
            else { return RemoteExerciseCatalogSnapshot() }
            return saved
        }

        func write(_ snapshot: RemoteExerciseCatalogSnapshot) throws {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: url, options: .atomic)
        }
    }

    private let disk = DiskStorage()

    private init() {}

    private func localSnapshot() async -> RemoteExerciseCatalogSnapshot {
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
            if working.revision > head { working = RemoteExerciseCatalogSnapshot() }
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

            let lag = head - working.revision
            if working.revision == 0 || lag > Self.bootstrapLagThreshold {
                try Task.checkCancellation()
                let boot: Bootstrap = try await client
                    .rpc("mobile_exercise_catalog_bootstrap")
                    .execute()
                    .value
                guard boot.revision > 0, !boot.entries.isEmpty else {
                    throw CatalogSyncError.invalidEvent
                }
                let keptIDs = working.localIDs
                var next = RemoteExerciseCatalogSnapshot(
                    revision: min(boot.revision, head),
                    entries: boot.entries,
                    localIDs: keptIDs,
                    tombstones: Set(boot.entries.compactMap { pair in
                        pair.value.isActive ? nil : pair.key
                    })
                )
                // Claves que ya no vienen en el bootstrap: conservar lápida local.
                for key in working.entries.keys where next.entries[key] == nil {
                    next.tombstones.insert(key)
                    if var old = working.entries[key] {
                        old.isActive = false
                        next.entries[key] = old
                    }
                }
                working = next
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
                    .limit(Self.eventPageSize)
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
            // Arte antes del merge UI: evita marcar stems como missing en el primer paint.
            await prefetchRemoteArt(from: working)
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

    private func prefetchRemoteArt(from snapshot: RemoteExerciseCatalogSnapshot) async {
        let stems = snapshot.entries.values.flatMap { $0.artKeys ?? [] }
        guard !stems.isEmpty,
              let urlString = Bundle.main.object(forInfoDictionaryKey: "ReperaSupabaseURL") as? String,
              let url = URL(string: urlString)
        else { return }
        await RemoteExerciseArtCache.shared.prefetch(stems: stems, supabaseURL: url)
    }

    /// Aplicar catálogo y referencias de WOD antiguos es una sola operación
    /// lógica. Las llamadas anteriores actualizaban solo las plantillas,
    /// dejando sin reconciliar SessionExercise.exercise de AMRAP ya terminados.
    @discardableResult
    private func applyAndRelink(saved: inout RemoteExerciseCatalogSnapshot, to store: ReperaStore) async -> Bool {
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
    private func apply(saved: inout RemoteExerciseCatalogSnapshot, to store: ReperaStore) async -> Bool {
        for _ in 0..<3 {
            let revision = store.state.syncRevision
            let epoch = store.catalogEpoch
            let current = store.state.exercises
            let source = saved
            let merged = await Task.detached(priority: .utility) {
                RemoteExerciseCatalogMerge.apply(source: source, current: current)
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
