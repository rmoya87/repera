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
        // Bound memory: keep a handful of range variants.
        if personalRecordsByKey.count > 8 {
            personalRecordsByKey.removeAll(keepingCapacity: true)
            personalRecordsByKey[key] = value
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
        if historyByExercise.count > 64 {
            historyByExercise.removeAll(keepingCapacity: true)
            historyByExercise[exerciseId] = (revision, value)
        }
        lock.unlock()
        return value
    }

    public func invalidate() {
        lock.lock()
        personalRecordsByKey.removeAll(keepingCapacity: true)
        historyByExercise.removeAll(keepingCapacity: true)
        lock.unlock()
    }
}
