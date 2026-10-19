import Foundation
import ReperaDomain

/// Temporal index for Health ↔ Repera session matching (avoids O(H×G) full scans).
struct ReperaSessionMatchIndex: Sendable {
    struct Window: Sendable {
        var start: Date
        var end: Date
        var duration: TimeInterval
        var healthKitUUID: UUID?
    }

    private let byUUID: Set<UUID>
    private let windows: [Window]
    private let slack: TimeInterval

    init(sessions: [WorkoutSession], slack: TimeInterval = 45 * 60) {
        self.slack = slack
        var uuids = Set<UUID>()
        var windows: [Window] = []
        windows.reserveCapacity(sessions.count)
        for session in sessions {
            if let hk = session.healthKitWorkoutUUID {
                uuids.insert(hk)
            }
            guard let start = session.startedAt else { continue }
            let duration: TimeInterval
            if let apple = session.appleDurationSeconds, apple > 0 {
                duration = apple
            } else if let finished = session.finishedAt {
                duration = max(60, finished.timeIntervalSince(start))
            } else {
                duration = max(60, session.durationMinutes * 60)
            }
            let end = session.finishedAt ?? start.addingTimeInterval(duration)
            windows.append(
                Window(
                    start: start,
                    end: end,
                    duration: max(60, end.timeIntervalSince(start)),
                    healthKitUUID: session.healthKitWorkoutUUID
                )
            )
        }
        windows.sort { $0.start < $1.start }
        self.byUUID = uuids
        self.windows = windows
    }

    /// Same semantics as `HealthKitStore.matchesReperaSession` with indexed candidates.
    func matches(healthStart: Date, healthEnd: Date, healthUUID: UUID) -> Bool {
        if byUUID.contains(healthUUID) { return true }
        guard !windows.isEmpty else { return false }

        let probeStart = healthStart.addingTimeInterval(-slack)
        let probeEnd = healthEnd.addingTimeInterval(slack)
        let lo = lowerBound(probeStart)
        var hits = 0
        var i = lo
        while i < windows.count {
            let w = windows[i]
            if w.start > probeEnd { break }
            defer { i += 1 }
            let overlapStart = max(healthStart, w.start)
            let overlapEnd = min(healthEnd, w.end)
            let overlap = max(0, overlapEnd.timeIntervalSince(overlapStart))
            guard overlap >= w.duration * 0.4 else { continue }
            let looseStart = w.start.addingTimeInterval(-slack)
            let looseEnd = w.end.addingTimeInterval(slack)
            guard healthStart < looseEnd, healthEnd > looseStart else { continue }
            hits += 1
            if hits > 1 { return false }
        }
        return hits == 1
    }

    private func lowerBound(_ date: Date) -> Int {
        var lo = 0
        var hi = windows.count
        while lo < hi {
            let mid = (lo + hi) / 2
            // Expand left by slack so we don't miss early windows.
            if windows[mid].end.addingTimeInterval(slack) < date {
                lo = mid + 1
            } else {
                hi = mid
            }
        }
        return max(0, lo - 1)
    }
}
