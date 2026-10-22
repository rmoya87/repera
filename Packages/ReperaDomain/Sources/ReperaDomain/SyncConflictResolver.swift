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
