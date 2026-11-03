import Foundation

/// Resolves which `AppState` document wins between local and remote copies.
/// Prefers `syncRevision` + writer provenance; falls back to `updatedAt` for legacy docs.
public enum SyncConflictResolver: Sendable {
    public enum Winner: Sendable, Equatable {
        case local
        case remote
        case equal
    }

    public static func winner(local: AppState, remote: AppState) -> Winner {
        if local.syncRevision != remote.syncRevision {
            return local.syncRevision > remote.syncRevision ? .local : .remote
        }
        // Same revision: prefer newer wall clock, then stable writer id for determinism.
        if local.updatedAt != remote.updatedAt {
            return local.updatedAt > remote.updatedAt ? .local : .remote
        }
        if local.lastWriterDeviceId != remote.lastWriterDeviceId {
            // Deterministic tie-break so both devices converge.
            return local.lastWriterDeviceId > remote.lastWriterDeviceId ? .local : .remote
        }
        return .equal
    }

    /// Only the original blocks persisted in the completed local session may
    /// enrich a legacy cloud mirror. Every other field must match exactly, so
    /// neither stale devices nor edited routines can replace workout results.
    public static func canRestoreMissingBlockSnapshot(
        local: WorkoutSession, remote: WorkoutSession
    ) -> Bool {
        guard let blocks = local.routineBlocks, !blocks.isEmpty,
              remote.routineBlocks?.isEmpty != false
        else { return false }

        var candidate = remote
        candidate.routineBlocks = blocks
        return candidate == local
    }

    /// A deletion on either device survives a stale or higher-revision cloud snapshot.
    /// Keep historical recorded data only for entries that the athlete has not removed.
    public static func reconcilingDeletionTombstones(
        in preferred: AppState, from other: AppState
    ) -> AppState {
        var result = preferred
        result.deletedWorkoutIDs.formUnion(other.deletedWorkoutIDs)
        result.deletedExerciseIDs.formUnion(other.deletedExerciseIDs)
        for (workoutID, ids) in other.deletedWorkoutExerciseIDs {
            result.deletedWorkoutExerciseIDs[workoutID, default: []].formUnion(ids)
        }

        result.exercises.removeAll { result.deletedExerciseIDs.contains($0.id) }
        result.workouts.removeAll { result.deletedWorkoutIDs.contains($0.id) }
        for index in result.workouts.indices {
            let key = result.workouts[index].id.uuidString
            guard let deleted = result.deletedWorkoutExerciseIDs[key], !deleted.isEmpty
            else { continue }
            result.workouts[index].exercises.removeAll { deleted.contains($0.id) }
            if var blocks = result.workouts[index].routineBlocks {
                for blockIndex in blocks.indices {
                    blocks[blockIndex].exercises.removeAll { deleted.contains($0.id) }
                    blocks[blockIndex].movements.removeAll { deleted.contains($0.id) }
                }
                result.workouts[index].routineBlocks = blocks
            }
        }
        return result
    }

    /// Preserve genuine GPS captured in the complete personal iCloud document
    /// when a newer copy of the same workout only contains summary fields.
    /// Never create sessions, resurrect deleted IDs or infer coordinates.
    /// A missing route is the only reason to adopt points from the other copy.
    public static func restoringMissingWorkoutRoutes(
        in preferred: AppState, from other: AppState
    ) -> AppState {
        var restored = preferred
        let otherByID = Dictionary(other.workouts.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for i in restored.workouts.indices {
            let id = restored.workouts[i].id
            guard let original = otherByID[id] else { continue }
            if restored.workouts[i].routePoints.count < 2, original.routePoints.count >= 2 {
                restored.workouts[i].routePoints = original.routePoints
            }
            if restored.workouts[i].locationPin == nil, let pin = original.locationPin {
                restored.workouts[i].locationPin = pin
            }
        }
        return restored
    }

    public static func pickNewest(local: AppState?, remote: AppState?) -> AppState? {
        switch (local, remote) {
        case let (l?, r?):
            switch winner(local: l, remote: r) {
            case .local, .equal: return l
            case .remote: return r
            }
        case let (l?, nil):
            return l
        case let (nil, r?):
            return r
        case (nil, nil):
            return nil
        }
    }
}
