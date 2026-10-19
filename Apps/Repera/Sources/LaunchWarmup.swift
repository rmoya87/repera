import Foundation
import ReperaDomain
import os

/// Kick off cold-start disk / catalog work as early as `ReperaApp.init`, in parallel with
/// SwiftUI's first layout pass. Consumers take a ready result or fall back to sync load.
enum LaunchWarmup {
    private static let logger = Logger(subsystem: "com.app.repera", category: "Launch")
    private static let box = Box()

    /// Prevents scenePhase `.active` from redoing the same Health warm as the launch `.task`.
    static var didFinishLaunchHealthWarm: Bool { box.didFinishHealthWarm }

    static func start() {
        guard box.markStarted() else { return }
        LaunchTiming.mark("LaunchWarmup.start")

        Task.detached(priority: .userInitiated) {
            let t0 = CFAbsoluteTimeGetCurrent()
            Catalog.prewarm()
            LaunchTiming.span("warmup.catalog", from: t0)
        }

        Task.detached(priority: .userInitiated) {
            let t0 = CFAbsoluteTimeGetCurrent()
            let snap = HealthDiskCache.loadFromDisk()
            box.storeHealthSnapshot(snap)
            LaunchTiming.span(
                "warmup.healthDisk\(snap == nil ? ".miss" : ".hit")",
                from: t0
            )
        }

        Task.detached(priority: .userInitiated) {
            let t0 = CFAbsoluteTimeGetCurrent()
            let state = Self.loadAppStateSync()
            box.storeAppState(state)
            LaunchTiming.span(
                "warmup.appState\(state == nil ? ".miss" : ".hit")",
                from: t0
            )
            // Keep actor cache in sync so hydrateFromDisk does not re-decode.
            await AppStatePersistence.shared.warmLocalRead()
        }
    }

    /// Used from `HealthKitStore.init`: reuse warm decode when ready, else load here once.
    static func healthSnapshotForInit() -> HealthDiskCache.Snapshot? {
        if let slot = box.takeHealthSlotIfReady() {
            return slot
        }
        let snap = HealthDiskCache.loadFromDisk()
        box.storeHealthSnapshot(snap)
        return snap
    }

    /// Used from `ReperaStore.init`: same pattern as Salud — workouts on first paint.
    static func appStateForFirstPaint() -> AppState? {
        if let slot = box.takeAppStateIfReady() {
            return slot
        }
        let state = loadAppStateSync()
        box.storeAppState(state)
        return state
    }

    /// Sync decode of `app_state.json` (Application Support), parallel to HealthDiskCache.
    static func loadAppStateSync() -> AppState? {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Repera", isDirectory: true)
            .appendingPathComponent("app_state.json")
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              !data.isEmpty
        else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(AppState.self, from: data)
        } catch {
            logger.error("app_state sync decode failed: \(String(describing: error), privacy: .public)")
            return nil
        }
    }

    static func markLaunchHealthWarmFinished() {
        box.markHealthWarmFinished()
    }

    private final class Box: @unchecked Sendable {
        private let lock = NSLock()
        /// `nil` = warm not finished; `.some(nil)` = miss; `.some(snap)` = hit.
        private var healthSnapshot: HealthDiskCache.Snapshot??
        /// `nil` = warm not finished; `.some(nil)` = miss; `.some(state)` = hit.
        private var appState: AppState??
        private var didStart = false
        private var didFinishHealthWarmFlag = false

        var didFinishHealthWarm: Bool {
            lock.lock()
            defer { lock.unlock() }
            return didFinishHealthWarmFlag
        }

        func markStarted() -> Bool {
            lock.lock()
            defer { lock.unlock() }
            if didStart { return false }
            didStart = true
            return true
        }

        func storeHealthSnapshot(_ snap: HealthDiskCache.Snapshot?) {
            lock.lock()
            healthSnapshot = .some(snap)
            lock.unlock()
        }

        func takeHealthSlotIfReady() -> HealthDiskCache.Snapshot?? {
            lock.lock()
            defer { lock.unlock() }
            return healthSnapshot
        }

        func storeAppState(_ state: AppState?) {
            lock.lock()
            appState = .some(state)
            lock.unlock()
        }

        func takeAppStateIfReady() -> AppState?? {
            lock.lock()
            defer { lock.unlock() }
            return appState
        }

        func markHealthWarmFinished() {
            lock.lock()
            didFinishHealthWarmFlag = true
            lock.unlock()
        }
    }
}
