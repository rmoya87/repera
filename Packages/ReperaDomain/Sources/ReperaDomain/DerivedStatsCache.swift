import Foundation

/// In-memory cache of expensive StatsEngine results, invalidated by a caller-supplied revision.
public final class DerivedStatsCache: @unchecked Sendable {
    public struct Key: Hashable, Sendable {
        public var revision: Int
        public var rangeRaw: String
        public var mondayFirst: Bool
        public var workoutCount: Int

        public init(revision: Int, rangeRaw: String, mondayFirst: Bool, workoutCount: Int) {
            self.revision = revision
            self.rangeRaw = rangeRaw
            self.mondayFirst = mondayFirst
            self.workoutCount = workoutCount
        }
    }

    private let lock = NSLock()
    private var personalRecordsByKey: [Key: [PersonalRecord]] = [:]
    private var historyByExercise: [UUID: (revision: Int, summary: ExerciseHistorySummary)] = [:]
    private var lastSessionByExercise: [UUID: (revision: Int, session: ExerciseLastSession?)] = [:]
    private var lastWeightByExercise: [UUID: (revision: Int, kg: Double?)] = [:]
    private var prCountBySession: [UUID: (revision: Int, count: Int)] = [:]
    /// Full session→PR map built once per revision (Historial).
    private var prCountsMapRevision: Int = -1
    private var prCountsBySessionId: [UUID: Int] = [:]

    public init() {}

    public func personalRecords(key: Key, compute: () -> [PersonalRecord]) -> [PersonalRecord] {
        lock.lock()
        if let hit = personalRecordsByKey[key] {
            lock.unlock()
            return hit
        }
        lock.unlock()
        let value = compute()
        lock.lock()
        personalRecordsByKey[key] = value
        if personalRecordsByKey.count > 8 {
            let keep = value
            personalRecordsByKey.removeAll(keepingCapacity: true)
            personalRecordsByKey[key] = keep
        }
        lock.unlock()
        return value
    }

    public func history(
        exerciseId: UUID,
        revision: Int,
        compute: () -> ExerciseHistorySummary
    ) -> ExerciseHistorySummary {
        lock.lock()
        if let hit = historyByExercise[exerciseId], hit.revision == revision {
            lock.unlock()
            return hit.summary
        }
        lock.unlock()
        let value = compute()
        lock.lock()
        historyByExercise[exerciseId] = (revision, value)
        if historyByExercise.count > 128 {
            evictOldestHalf(&historyByExercise)
            historyByExercise[exerciseId] = (revision, value)
        }
        lock.unlock()
        return value
    }

    public func lastSession(
        exerciseId: UUID,
        revision: Int,
        compute: () -> ExerciseLastSession?
    ) -> ExerciseLastSession? {
        lock.lock()
        if let hit = lastSessionByExercise[exerciseId], hit.revision == revision {
            lock.unlock()
            return hit.session
        }
        lock.unlock()
        let value = compute()
        lock.lock()
        lastSessionByExercise[exerciseId] = (revision, value)
        if lastSessionByExercise.count > 128 {
            evictOldestHalf(&lastSessionByExercise)
            lastSessionByExercise[exerciseId] = (revision, value)
        }
        lock.unlock()
        return value
    }

    public func lastWorkingWeight(
        exerciseId: UUID,
        revision: Int,
        compute: () -> Double?
    ) -> Double? {
        lock.lock()
        if let hit = lastWeightByExercise[exerciseId], hit.revision == revision {
            lock.unlock()
            return hit.kg
        }
        lock.unlock()
        let value = compute()
        lock.lock()
        lastWeightByExercise[exerciseId] = (revision, value)
        if lastWeightByExercise.count > 128 {
            evictOldestHalf(&lastWeightByExercise)
            lastWeightByExercise[exerciseId] = (revision, value)
        }
        lock.unlock()
        return value
    }

    public func personalRecordCount(
        sessionId: UUID,
        revision: Int,
        compute: () -> Int
    ) -> Int {
        lock.lock()
        if let hit = prCountBySession[sessionId], hit.revision == revision {
            lock.unlock()
            return hit.count
        }
        lock.unlock()
        let value = compute()
        lock.lock()
        prCountBySession[sessionId] = (revision, value)
        if prCountBySession.count > 200 {
            evictOldestHalf(&prCountBySession)
            prCountBySession[sessionId] = (revision, value)
        }
        lock.unlock()
        return value
    }

    public func personalRecordCountsBySession(
        revision: Int,
        compute: () -> [UUID: Int]
    ) -> [UUID: Int] {
        lock.lock()
        if prCountsMapRevision == revision {
            let hit = prCountsBySessionId
            lock.unlock()
            return hit
        }
        lock.unlock()
        let value = compute()
        lock.lock()
        prCountsMapRevision = revision
        prCountsBySessionId = value
        lock.unlock()
        return value
    }

    /// Drop ~half of entries (dict order is unspecified — fine for soft bound).
    private func evictOldestHalf<V>(_ dict: inout [UUID: V]) {
        let drop = max(1, dict.count / 2)
        for key in dict.keys.prefix(drop) {
            dict.removeValue(forKey: key)
        }
    }

    public func invalidate() {
        lock.lock()
        personalRecordsByKey.removeAll(keepingCapacity: true)
        historyByExercise.removeAll(keepingCapacity: true)
        lastSessionByExercise.removeAll(keepingCapacity: true)
        lastWeightByExercise.removeAll(keepingCapacity: true)
        prCountBySession.removeAll(keepingCapacity: true)
        prCountsMapRevision = -1
        prCountsBySessionId.removeAll(keepingCapacity: true)
        lock.unlock()
    }
}
