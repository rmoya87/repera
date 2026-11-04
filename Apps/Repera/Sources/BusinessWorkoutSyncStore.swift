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
    private(set) var restoredBlockSnapshots = 0
    private(set) var incompleteHistoricalWODCount = 0
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
            // Compatibility with any legacy rows until the cleanup migration runs.
            payload = try? c.decode(WorkoutSession.self, forKey: .payload)
            deletedAt = try c.decodeIfPresent(String.self, forKey: .deletedAt)
        }
    }

    private struct MirrorIndexRow: Decodable {
        let id: UUID
        let deletedAt: String?

        enum CodingKeys: String, CodingKey {
            case id
            case deletedAt = "deleted_at"
        }
    }

    private static let indexPageSize = 1_000

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

    private func key(_ user: UUID, suffix: String) -> String {
        "repera.supabaseWorkoutMirror.v1.\(user.uuidString).\(suffix)"
    }

    private func fingerprints(_ user: UUID) -> [String: String] {
        UserDefaults.standard.dictionary(forKey: key(user, suffix: "fingerprints")) as? [String: String] ?? [:]
    }

    private func pendingDeletes(_ user: UUID) -> [String] {
        UserDefaults.standard.stringArray(forKey: key(user, suffix: "deleted")) ?? []
    }

    /// Only a short-lived pending DELETE request; no archived deleted workout
    /// or permanent deleted-id list is retained after the server confirms it.
    func noteDeleted(_ id: UUID) {
        guard let user = BusinessAuthStore.shared.boundUserForPendingDeletion else { return }
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
        restoredBlockSnapshots = 0
        incompleteHistoricalWODCount = 0
        sharingByCenter = [:]
        updatingSharingCenter = nil
        // Only unfinished network work survives sign-out; never transfer across accounts.
    }

    /// Uploads changed finished sessions; restores only *unknown* remote IDs,
    /// after iCloud recovery completed. Known local deletions are never revived.
    /// True only when the authenticated remote mirror was actually read and updated.
    /// Silent early exits must never appear as a successful manual synchronization.
    @discardableResult
    func sync(store: ReperaStore) async -> Bool {
        // Serializar también la renovación del JWT. Dos guardados simultáneos
        // no deben competir por el mismo refresh token rotatorio de Supabase.
        if isSyncing {
            retryRequested = true
            return false
        }
        isSyncing = true
        restoredBlockSnapshots = 0
        let run = generation
        defer {
            isSyncing = false
            if retryRequested {
                retryRequested = false
                Task { @MainActor in await self.sync(store: store) }
            }
        }
        guard await BusinessAuthStore.shared.ensureUsableSession(),
              let client = BusinessAuthStore.shared.apiClient else {
            lastError = BusinessAuthStore.shared.lastErrorMessage
                ?? "La sesión de Repera no está disponible. Inicia sesión si es necesario."
            return false
        }
        guard store.isHydrated, store.didCompleteInitialRemoteSync, !store.isSyncingiCloud else {
            lastError = "Esperando a que termine la recuperación local/iCloud. Reintenta la sincronización."
            return false
        }

        do {
            let session = try await client.auth.session
            guard !session.isExpired else { return false }
            let user = session.user.id
            let originalUser = BusinessAuthStore.shared.apiClient?.auth.currentSession?.user.id
            guard originalUser == user else { return false }

            // First hard-delete pending removals. Do this BEFORE reading the
            // remote catalogue, otherwise stale rows could be reimported.
            let queued = pendingDeletes(user)
            for id in queued {
                guard run == generation, BusinessAuthStore.shared.isConnected,
                      BusinessAuthStore.shared.apiClient?.auth.currentSession?.user.id == user,
                      let uuid = UUID(uuidString: id) else { return false }
                try await client.from("athlete_workout_mirror")
                    .delete()
                    .eq("owner_id", value: user.uuidString)
                    .eq("id", value: uuid.uuidString)
                    .execute()
                // Persist progress one ID at a time; an interruption never loses
                // an unacknowledged delete. No tombstones are kept after success.
                let remaining = pendingDeletes(user).filter { $0 != id }
                if remaining.isEmpty {
                    UserDefaults.standard.removeObject(forKey: key(user, suffix: "deleted"))
                } else {
                    UserDefaults.standard.set(remaining, forKey: key(user, suffix: "deleted"))
                }
            }
            // Remote existence comes from a payload-free listing paged by the
            // immutable primary key: no row cap, and a row edited mid-scan can
            // never slip behind the cursor and be mistaken for a deletion.
            var existing: [UUID: MirrorIndexRow] = [:]
            var after: UUID?
            while true {
                guard run == generation else { return false }
                var query = client.from("athlete_workout_mirror")
                    .select("id,deleted_at")
                    .eq("owner_id", value: user.uuidString)
                if let after { query = query.gt("id", value: after.uuidString) }
                let page: [MirrorIndexRow] = try await query
                    .order("id", ascending: true)
                    .limit(Self.indexPageSize)
                    .execute().value
                for row in page { existing[row.id] = row }
                // Stop only on an empty page: a server max-rows below the page
                // size must not truncate the listing into false deletions.
                guard let last = page.last?.id else { break }
                after = last
            }

            guard run == generation, BusinessAuthStore.shared.isConnected,
                  BusinessAuthStore.shared.apiClient?.auth.currentSession?.user.id == user
            else { return false }

            var seen = fingerprints(user)
            for id in queued { seen.removeValue(forKey: id) }
            let localById = Dictionary(store.state.workouts.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            let localDigests = localById.mapValues { digest($0) }
            let queuedDeletes = Set(pendingDeletes(user))
            // Payloads are only downloaded where a decision needs them: unseen
            // remote workouts to recover, and local ones whose remote copy is
            // not known to match (first sync on this device or local edits).
            let payloadIDs = existing.values.compactMap { row -> UUID? in
                guard row.deletedAt == nil, !queuedDeletes.contains(row.id.uuidString) else { return nil }
                if let localDigest = localDigests[row.id] {
                    return seen[row.id.uuidString] == localDigest ? nil : row.id
                }
                return seen[row.id.uuidString] == nil ? row.id : nil
            }
            var payloads: [UUID: MirrorRow] = [:]
            for chunk in payloadIDs.chunked(into: 50) {
                guard run == generation else { return false }
                // Use the SDK's Supabase-aware JSON date decoder (handles
                // fractional timestamps that Foundation .iso8601 can reject).
                let rows: [MirrorRow] = try await client.from("athlete_workout_mirror")
                    .select("id,payload,deleted_at")
                    .eq("owner_id", value: user.uuidString)
                    .in("id", values: chunk.map(\.uuidString))
                    .execute().value
                for row in rows { payloads[row.id] = row }
            }
            // Remote WOD structure: downloaded payload, or the local copy when its
            // fingerprint proves it is identical to the mirrored row.
            let remoteWorkouts: [UUID: WorkoutSession] = existing.values.reduce(into: [:]) { result, row in
                guard row.deletedAt == nil else { return }
                if let payload = payloads[row.id]?.payload {
                    result[row.id] = payload
                } else if let local = localById[row.id], seen[row.id.uuidString] == localDigests[row.id] {
                    result[row.id] = local
                }
            }
            // Fingerprints only describe workouts that this device successfully
            // mirrored before. If one is absent remotely, the real row was
            // deleted on another device: discard local copy, never re-upload.
            let remotelyDeletedIDs = Set(store.state.workouts.compactMap { workout -> UUID? in
                let id = workout.id
                return seen[id.uuidString] != nil && existing[id] == nil ? id : nil
            })
            if !remotelyDeletedIDs.isEmpty {
                store.removePreviouslyMirroredWorkoutsMissingRemotely(remotelyDeletedIDs)
                for id in remotelyDeletedIDs { seen.removeValue(forKey: id.uuidString) }
            }
            // Legacy WODs without an original block snapshot cannot support
            // fully calibrated stimulus comparisons. Never invent missing Rx.
            let unstructuredRemoteWODs = Set(remoteWorkouts.compactMap { id, workout -> UUID? in
                guard !workout.wodResults.isEmpty,
                      workout.routineBlocks?.isEmpty != false
                else { return nil }
                return id
            })
            var restoredBlockIDs = Set<UUID>()
            let deletionIDs = queuedDeletes
            var recovered: [WorkoutSession] = []
            let localIds = Set(localById.keys)

            // A second iPhone may have workouts that are not yet in the current
            // iCloud document. Only recover previously unseen, non-deleted IDs.
            for row in payloads.values where row.deletedAt == nil && !localIds.contains(row.id) {
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

            // New local workouts backfill after Apple→Supabase migration.
            // Existing remote records are not overwritten on the first sync
            // from a second device. Subsequent local edits change the hash.
            let pending = store.state.workouts.compactMap { original -> MirrorUpload? in
                guard original.finishedAt != nil,
                      !deletionIDs.contains(original.id.uuidString),
                      existing[original.id]?.deletedAt == nil
                else { return nil }
                let clean = Self.privateMirrorPayload(original)
                let checksum = localDigests[original.id] ?? digest(clean)
                let id = original.id.uuidString
                if existing[original.id] != nil, seen[id] == nil {
                    // First sync on another device must not overwrite an edited
                    // remote workout. The sole safe exception is restoring a
                    // missing original block snapshot when EVERY other mirrored
                    // field agrees with the remote version.
                    guard let remoteWorkout = payloads[original.id]?.payload,
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
                for entry in batch {
                    seen[entry.id.uuidString] = digest(entry.payload)
                    if unstructuredRemoteWODs.contains(entry.id),
                       entry.payload.routineBlocks?.isEmpty == false {
                        restoredBlockIDs.insert(entry.id)
                    }
                }
                UserDefaults.standard.set(seen, forKey: key(user, suffix: "fingerprints"))
            }
            guard run == generation, BusinessAuthStore.shared.isConnected,
                  BusinessAuthStore.shared.apiClient?.auth.currentSession?.user.id == user
            else { return false }
            // Fingerprints are only a cache of live remote rows, not a deletion
            // ledger. Trim obsolete entries to avoid indefinite accumulation.
            let liveIDs = Set(existing.keys.map(\.uuidString)).union(pending.map { $0.id.uuidString })
            seen = seen.filter { liveIDs.contains($0.key) }
            UserDefaults.standard.set(seen, forKey: key(user, suffix: "fingerprints"))
            mirroredCount = Set(existing.values.filter { $0.deletedAt == nil }.map(\.id)).union(pending.map(\.id)).count
            restoredBlockSnapshots = restoredBlockIDs.count
            incompleteHistoricalWODCount = unstructuredRemoteWODs.subtracting(restoredBlockIDs).count
            lastSyncAt = Date()
            lastError = nil
            await refreshSharing()
            return true
        } catch {
            guard run == generation else { return false }
            lastError = "No se han podido sincronizar los entrenamientos. Comprueba tu conexión e inténtalo de nuevo."
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
        value.appleAverageHeartRateBpm = nil
        value.appleHealthProvenance = nil
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
