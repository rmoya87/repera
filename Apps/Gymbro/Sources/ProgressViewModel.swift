import Foundation
import GymbroDomain
import Observation

/// Owns Progress period selection, snapshot cache, and cancellable prep.
@MainActor
@Observable
final class ProgressViewModel {
    private(set) var range: ProgressTimeRange = .week
    private(set) var snapshot: ProgressSnapshot = .empty()
    private(set) var isPreparing = false
    private(set) var lastPrepareReason: String = ""

    @ObservationIgnored private var cache: [ProgressDataKey: ProgressSnapshot] = [:]
    @ObservationIgnored private var prepareTask: Task<Void, Never>?
    @ObservationIgnored private var prepareGeneration: UInt64 = 0
    @ObservationIgnored private let maxCacheEntries = 12

    func setRange(_ newRange: ProgressTimeRange) {
        guard newRange != range else { return }
        range = newRange
        isPreparing = true
    }

    /// Apply cached snapshot for the current range if revisions match.
    @discardableResult
    func applyCacheIfPossible(
        weekStartsOnMonday: Bool,
        syncRevision: Int,
        healthDataRevision: Int,
        bodyWeights: [BodyWeightEntry]
    ) -> Bool {
        let key = ProgressDataKey(
            range: range,
            weekStartsOnMonday: weekStartsOnMonday,
            syncRevision: syncRevision,
            healthDataRevision: healthDataRevision,
            bodyWeightRevision: bodyWeightRevision(bodyWeights)
        )
        if let hit = cache[key] {
            snapshot = hit
            isPreparing = false
            return true
        }
        return false
    }

    func requestPrepare(
        store: GymbroStore,
        health: HealthKitStore,
        reason: String
    ) {
        let monday = store.state.settings.weekStartsOn == .monday
        let key = ProgressDataKey(
            range: range,
            weekStartsOnMonday: monday,
            syncRevision: store.state.syncRevision,
            healthDataRevision: health.healthDataRevision,
            bodyWeightRevision: bodyWeightRevision(store.state.bodyWeights)
        )

        if let cached = cache[key] {
            snapshot = cached
            isPreparing = false
            lastPrepareReason = reason
            ProgressLog.info("progress cache hit key gen reason=\(reason)")
            return
        }

        // Soft hit: same range + revisions already published.
        if snapshot.key == key {
            isPreparing = false
            return
        }

        prepareGeneration &+= 1
        let gen = prepareGeneration
        isPreparing = true
        lastPrepareReason = reason
        ProgressLog.info("progress prepare enqueue \(reason) gen=\(gen) range=\(range.rawValue)")

        let input = ProgressBuildInput(
            key: key,
            range: range,
            weekStartsOnMonday: monday,
            workouts: store.state.workouts,
            exercises: store.state.exercises,
            bodyWeights: store.state.bodyWeights,
            heartRateDays: health.recentDailyHeartRate,
            energyDays: health.recentDailyActiveEnergy,
            externalActivities: health.recentExternalActivities,
            now: Date()
        )

        prepareTask?.cancel()
        // Detached task IS the cancellable unit (no nested orphan Task.detached).
        prepareTask = Task.detached(priority: .userInitiated) { [weak self] in
            let t0 = CFAbsoluteTimeGetCurrent()
            let built = ProgressDataEngine.build(input)
            guard !Task.isCancelled, let built else {
                ProgressLog.info("progress prepare cancelled gen=\(gen)")
                return
            }
            let ms = (CFAbsoluteTimeGetCurrent() - t0) * 1000
            await MainActor.run {
                guard let self else { return }
                guard gen == self.prepareGeneration else {
                    ProgressLog.info("progress prepare stale drop gen=\(gen)")
                    return
                }
                self.cache[key] = built
                self.trimCache()
                self.snapshot = built
                self.isPreparing = false
                ProgressLog.info(
                    "progress prepare done gen=\(gen) range=\(built.range.rawValue) \(String(format: "%.0f", ms))ms"
                )
            }
        }
    }

    func invalidateCache(reason: String) {
        cache.removeAll(keepingCapacity: true)
        ProgressLog.info("progress cache invalidate \(reason)")
    }

    private func bodyWeightRevision(_ entries: [BodyWeightEntry]) -> Int {
        var hasher = Hasher()
        hasher.combine(entries.count)
        if let first = entries.first {
            hasher.combine(first.id)
            hasher.combine(first.date.timeIntervalSince1970)
            hasher.combine(first.weightKg)
        }
        if let last = entries.last {
            hasher.combine(last.id)
            hasher.combine(last.date.timeIntervalSince1970)
            hasher.combine(last.weightKg)
        }
        return hasher.finalize()
    }

    private func trimCache() {
        guard cache.count > maxCacheEntries else { return }
        // Drop oldest by leaving current range + newest insertions (dict order not guaranteed —
        // keep current key and remove arbitrary extras).
        let keep = snapshot.key
        let extras = cache.keys.filter { $0 != keep }
        for key in extras.prefix(cache.count - maxCacheEntries) {
            cache.removeValue(forKey: key)
        }
    }
}
