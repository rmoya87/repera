import CryptoKit
import Foundation
import Observation
import ReperaDomain
import Supabase

/// The user's private completed-workout mirror. It supplements iCloud (the
/// primary personal store), never writes directly into another person's data
/// and never authorizes a trainer to read this table.
@MainActor
@Observable
final class BusinessWorkoutSyncStore {
    static let shared = BusinessWorkoutSyncStore()

    private(set) var isSyncing = false
    private(set) var lastSyncAt: Date?
    private(set) var lastError: String?
    private(set) var mirroredCount = 0
    private(set) var recoveredCount = 0
    private(set) var sharingByCenter: [UUID: Bool] = [:]
    private(set) var updatingSharingCenter: UUID?
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var retryRequested = false

    private init() {}

    private struct MirrorRow: Decodable {
        let id: UUID
        let payload: WorkoutSession?
        let deletedAt: String?

        enum CodingKeys: String, CodingKey {
            case id, payload
            case deletedAt = "deleted_at"
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decode(UUID.self, forKey: .id)
            // Tombstones intentionally store {} and must not invalidate the
            // decoding of otherwise healthy rows.
            payload = try? c.decode(WorkoutSession.self, forKey: .payload)
            deletedAt = try c.decodeIfPresent(String.self, forKey: .deletedAt)
        }
    }

    private struct SharingRow: Decodable {
        let orgId: UUID
        let enabled: Bool
        enum CodingKeys: String, CodingKey {
            case orgId = "org_id"
            case enabled
        }
    }

    private struct SharingUpdate: Encodable {
        let athleteId: UUID
        let orgId: UUID
        let enabled: Bool
        let updatedAt: Date
        enum CodingKeys: String, CodingKey {
            case enabled
            case athleteId = "athlete_id"
            case orgId = "org_id"
            case updatedAt = "updated_at"
        }
    }

    private struct MirrorUpload: Encodable {
        let id: UUID
        let ownerId: UUID
        let title: String
        let startedAt: Date?
        let finishedAt: Date?
        let payload: WorkoutSession
        let updatedAt: Date

        enum CodingKeys: String, CodingKey {
            case id, title, payload
            case ownerId = "owner_id"
            case startedAt = "started_at"
            case finishedAt = "finished_at"
            case updatedAt = "updated_at"
        }
    }

    private struct MirrorTombstone: Encodable {
        let id: UUID
        let ownerId: UUID
        let title = "Entrenamiento eliminado"
        let payload: [String: String] = [:]
        let deletedAt = Date()
        let updatedAt = Date()
        enum CodingKeys: String, CodingKey {
            case id, title, payload
            case ownerId = "owner_id"
            case deletedAt = "deleted_at"
            case updatedAt = "updated_at"
        }
    }

    private func key(_ user: UUID, suffix: String) -> String {
        "repera.supabaseWorkoutMirror.v1.\(user.uuidString).\(suffix)"
    }

    private func fingerprints(_ user: UUID) -> [String: String] {
        UserDefaults.standard.dictionary(forKey: key(user, suffix: "fingerprints")) as? [String: String] ?? [:]
    }

    private func pendingDeletes(_ user: UUID) -> [String] {
        UserDefaults.standard.stringArray(forKey: key(user, suffix: "deleted")) ?? []
    }

    /// Called *before* removing a completed workout from ReperaStore. Pending
    /// tombstones survive airplane mode, crashes and application restarts.
    func noteDeleted(_ id: UUID) {
        guard BusinessAuthStore.shared.isConnected,
              let user = BusinessAuthStore.shared.apiClient?.auth.currentSession?.user.id
        else { return }
        let identifier = id.uuidString
        var pending = pendingDeletes(user)
        if !pending.contains(identifier) { pending.append(identifier) }
        UserDefaults.standard.set(pending, forKey: key(user, suffix: "deleted"))
    }

    func clearSession() {
        generation &+= 1
        lastSyncAt = nil
        lastError = nil
        mirroredCount = 0
        recoveredCount = 0
        sharingByCenter = [:]
        updatingSharingCenter = nil
        // Per-user fingerprints/deletion outbox are intentionally retained.
        // Never carry workout summaries from one Apple identity to another.
    }

    /// Uploads changed finished sessions; restores only *unknown* remote IDs,
    /// after iCloud recovery completed. Known local deletions are never revived.
    /// True only when the authenticated remote mirror was actually read and updated.
    /// Silent early exits must never appear as a successful manual synchronization.
    @discardableResult
    func sync(store: ReperaStore) async -> Bool {
        guard BusinessAuthStore.shared.isConnected,
              let client = BusinessAuthStore.shared.apiClient else {
            lastError = "No hay una sesión activa de Supabase. Reconecta tu cuenta en Ajustes."
            return false
        }
        guard store.isHydrated, store.didCompleteInitialRemoteSync, !store.isSyncingiCloud else {
            lastError = "Esperando a que termine la recuperación local/iCloud. Reintenta la sincronización."
            return false
        }
        if isSyncing {
            retryRequested = true
            return false
        }
        isSyncing = true
        let run = generation
        defer {
            isSyncing = false
            if retryRequested {
                retryRequested = false
                Task { @MainActor in await self.sync(store: store) }
            }
        }

        do {
            let session = try await client.auth.session
            guard !session.isExpired else { return false }
            let user = session.user.id
            let originalUser = BusinessAuthStore.shared.apiClient?.auth.currentSession?.user.id
            guard originalUser == user else { return false }

            // Workouts are paginated so a long-lived athlete account is not
            // silently truncated at Supabase/PostgREST's default 1,000 rows.
            var remote: [MirrorRow] = []
            var offset = 0
            repeat {
                // Use the SDK's Supabase-aware JSON date decoder (handles
                // fractional timestamps that Foundation .iso8601 can reject).
                let page: [MirrorRow] = try await client.from("athlete_workout_mirror")
                    .select("id,payload,deleted_at")
                    .eq("owner_id", value: user.uuidString)
                    .order("finished_at", ascending: false)
                    .range(from: offset, to: offset + 199)
                    .execute().value
                remote.append(contentsOf: page)
                offset += page.count
                if page.count < 200 { break }
            } while offset < 20_000

            guard run == generation, BusinessAuthStore.shared.isConnected,
                  BusinessAuthStore.shared.apiClient?.auth.currentSession?.user.id == user
            else { return false }

            var seen = fingerprints(user)
            let existing = Dictionary(uniqueKeysWithValues: remote.map { ($0.id, $0) })
            let deletionIDs = Set(pendingDeletes(user))
            var recovered: [WorkoutSession] = []
            let localIds = Set(store.state.workouts.map(\.id))

            // A second iPhone may have workouts that are not yet in the current
            // iCloud document. Only recover previously unseen, non-deleted IDs.
            for row in remote where row.deletedAt == nil && !localIds.contains(row.id) {
                guard !deletionIDs.contains(row.id.uuidString),
                      seen[row.id.uuidString] == nil,
                      let workout = row.payload,
                      workout.id == row.id, workout.finishedAt != nil
                else { continue }
                recovered.append(workout)
                seen[row.id.uuidString] = digest(workout)
            }
            if !recovered.isEmpty {
                recoveredCount = store.mergeRecoveredWorkoutsFromSupabase(recovered)
            }

            // Propagate explicit removals even if the network was offline when
            // the user deleted the workout.
            let tombstones = deletionIDs.compactMap(UUID.init(uuidString:))
                .map { MirrorTombstone(id: $0, ownerId: user) }
            for batch in tombstones.chunked(into: 40) {
                try await client.from("athlete_workout_mirror")
                    .upsert(batch, onConflict: "id").execute()
            }
            if !deletionIDs.isEmpty {
                UserDefaults.standard.set([String](), forKey: key(user, suffix: "deleted"))
                for id in deletionIDs { seen.removeValue(forKey: id) }
            }

            // New local workouts backfill after Apple→Supabase migration.
            // Existing remote records are not overwritten on the first sync
            // from a second device. Subsequent local edits change the hash.
            let pending = store.state.workouts.compactMap { original -> MirrorUpload? in
                guard original.finishedAt != nil,
                      !deletionIDs.contains(original.id.uuidString),
                      existing[original.id]?.deletedAt == nil
                else { return nil }
                let clean = Self.privateMirrorPayload(original)
                let checksum = digest(clean)
                let id = original.id.uuidString
                if let remoteRow = existing[original.id], seen[id] == nil {
                    // First sync on another device must not overwrite an edited
                    // remote workout. The sole safe exception is restoring a
                    // missing original block snapshot when EVERY other mirrored
                    // field agrees with the remote version.
                    guard let remoteWorkout = remoteRow.payload,
                          Self.isSafeBlockSnapshotBackfill(local: clean, remote: remoteWorkout)
                    else {
                        seen[id] = checksum
                        return nil
                    }
                }
                guard existing[original.id] == nil || seen[id] != checksum else { return nil }
                return MirrorUpload(
                    id: original.id, ownerId: user,
                    title: String(original.title.prefix(200)),
                    startedAt: original.startedAt, finishedAt: original.finishedAt,
                    payload: clean, updatedAt: Date()
                )
            }
            for batch in pending.chunked(into: 30) {
                guard run == generation, BusinessAuthStore.shared.isConnected,
                      BusinessAuthStore.shared.apiClient?.auth.currentSession?.user.id == user
                else { return false }
                try await client.from("athlete_workout_mirror")
                    .upsert(batch, onConflict: "id").execute()
                for entry in batch { seen[entry.id.uuidString] = digest(entry.payload) }
                UserDefaults.standard.set(seen, forKey: key(user, suffix: "fingerprints"))
            }
            guard run == generation, BusinessAuthStore.shared.isConnected,
                  BusinessAuthStore.shared.apiClient?.auth.currentSession?.user.id == user
            else { return false }
            UserDefaults.standard.set(seen, forKey: key(user, suffix: "fingerprints"))
            mirroredCount = Set(existing.values.filter { $0.deletedAt == nil }.map(\.id)).union(pending.map(\.id)).count
            lastSyncAt = Date()
            lastError = nil
            await refreshSharing()
            return true
        } catch {
            guard run == generation else { return false }
            lastError = "La sincronización con Supabase está pendiente: \(error.localizedDescription)"
            // Never mark failed uploads as synced; retries keep local files safe.
            return false
        }
    }

    /// Independent, revocable consent to let a linked center's authorized
    /// coach/manager read exercise results. Default is OFF for every center.
    func refreshSharing() async {
        guard BusinessAuthStore.shared.isConnected,
              let client = BusinessAuthStore.shared.apiClient else {
            sharingByCenter = [:]
            return
        }
        do {
            let session = try await client.auth.session
            guard !session.isExpired else { return }
            let userID = session.user.id
            let rows: [SharingRow] = try await client
                .from("athlete_workout_sharing")
                .select("org_id,enabled")
                .eq("athlete_id", value: userID.uuidString)
                .execute().value
            guard BusinessAuthStore.shared.isConnected,
                  BusinessAuthStore.shared.apiClient?.auth.currentSession?.user.id == userID
            else { return }
            sharingByCenter = Dictionary(uniqueKeysWithValues: rows.map { ($0.orgId, $0.enabled) })
        } catch {
            lastError = "No se ha podido comprobar con quién compartes tus resultados."
        }
    }

    func setSharing(_ enabled: Bool, for orgId: UUID) async {
        guard updatingSharingCenter == nil,
              BusinessAuthStore.shared.isConnected,
              let client = BusinessAuthStore.shared.apiClient else { return }
        updatingSharingCenter = orgId
        defer { updatingSharingCenter = nil }
        do {
            let session = try await client.auth.session
            guard !session.isExpired,
                  BusinessDataStore.shared.athleteCenterIds.contains(orgId)
            else { throw WorkoutConsentError.notLinked }
            let userID = session.user.id
            let update = SharingUpdate(athleteId: userID, orgId: orgId,
                                       enabled: enabled, updatedAt: Date())
            try await client.from("athlete_workout_sharing")
                .upsert(update, onConflict: "athlete_id,org_id").execute()
            guard BusinessAuthStore.shared.isConnected,
                  BusinessAuthStore.shared.apiClient?.auth.currentSession?.user.id == userID
            else { return }
            sharingByCenter[orgId] = enabled
            lastError = nil
        } catch {
            lastError = "No se ha podido cambiar el permiso de compartir resultados: \(error.localizedDescription)"
        }
    }

    private enum WorkoutConsentError: LocalizedError {
        case notLinked
        var errorDescription: String? {
            "Debes estar vinculado y activo en el centro para compartir tus resultados."
        }
    }

    /// Supabase sólo recibe planificación, ejercicio, series y resultados.
    /// No se exportan GPS, notas subjetivas ni mediciones de Apple Salud.
    private static func privateMirrorPayload(_ source: WorkoutSession) -> WorkoutSession {
        var value = source
        value.notes = nil
        value.sessionReview = nil
        value.locationPin = nil
        value.routePoints = []
        value.healthKitWorkoutUUID = nil
        value.appleActiveEnergyKcal = nil
        value.appleDurationSeconds = nil
        return value
    }

    /// Repairs legacy mirrors without changing a single performed set, WOD
    /// result, date or other field. A current routine is NOT a trustworthy
    /// historical snapshot: only blocks already saved in the local workout
    /// itself may be sent back to Supabase.
    private static func isSafeBlockSnapshotBackfill(
        local: WorkoutSession, remote: WorkoutSession
    ) -> Bool {
        SyncConflictResolver.canRestoreMissingBlockSnapshot(
            local: local, remote: privateMirrorPayload(remote)
        )
    }

    private func digest(_ workout: WorkoutSession) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        guard let bytes = try? encoder.encode(Self.privateMirrorPayload(workout)) else {
            return ""
        }
        return SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size)
            .map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}
