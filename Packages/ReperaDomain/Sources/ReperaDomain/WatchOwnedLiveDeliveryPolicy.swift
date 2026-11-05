import Foundation

/// Delivery of WatchConnectivity userInfo is asynchronous. Only fresh,
// account-scoped snapshots may create or refresh a phone Live Activity.
/// Terminal events have a wider window so they can close an existing card.
/// The caller must independently validate owner scope and session UUID.
public enum WatchOwnedLiveDeliveryPolicy {
    public static func accepts(
        _ snapshot: WatchLiveActivitySnapshot,
        now: Date = Date()
    ) -> Bool {
        let age = now.timeIntervalSince(snapshot.capturedAt)
        guard age.isFinite, age >= -5 else { return false }
        switch snapshot.phase {
        case .recording, .paused:
            return age <= 90
        case .review:
            return age <= 3600
        }
    }

    /// Ignore an out-of-order phase/sensor payload for the same workout.
    public static func isNewer(
        _ snapshot: WatchLiveActivitySnapshot,
        than lastAcceptedCapture: Date?
    ) -> Bool {
        guard let lastAcceptedCapture else { return true }
        return snapshot.capturedAt >= lastAcceptedCapture
    }
}
