import Foundation

/// Snapshot on-disk of progressive HealthKit arrays so Home/Progreso paint instantly on cold start.
enum HealthDiskCache {
    static let schemaVersion = 2
    private static let fileName = "health-progressive-cache.json"

    struct Snapshot: Codable, Sendable {
        var version: Int
        // HealthKit is device-level; cache contents must not cross Repera logins.
        // Legacy unscoped snapshots are intentionally not reused.
        var ownerScope: String? = nil
        var fetchedAt: Date
        var coverageDays: Int
        var filterKey: String
        var isDaily: Bool
        var activities: [Activity]
        var heartRate: [HeartRate]
        var activeEnergy: [ActiveEnergy]
        /// Archived `HKQueryAnchor` for incremental workout merges.
        var workoutAnchor: Data?
        var todayActiveEnergyKcal: Double?
        var todayWorkoutMinutes: Double?
        var todayFetchedAt: Date?
        var metricsFetchedAt: Date?
        var metricsCoverageDays: Int?
    }

    struct Activity: Codable, Sendable {
        var id: UUID
        var title: String
        var start: Date
        var end: Date
        var durationMinutes: Double
        var activeEnergyKcal: Double?
        var distanceMeters: Double?
        var sourceName: String?
        var activityTypeRaw: UInt
    }

    struct HeartRate: Codable, Sendable {
        var date: Date
        var minBpm: Double
        var avgBpm: Double
        var maxBpm: Double
    }

    struct ActiveEnergy: Codable, Sendable {
        var date: Date
        var kcal: Double
    }

    private static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("Repera", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(fileName)
    }

    /// Apple identity mirror is available without a main-actor hop during warm start.
    private static var activeOwnerScope: String? {
        let defaults = UserDefaults.standard
        if let apple = defaults.string(forKey: AppleAuthStore.ownerScopeDefaultsKey),
           !apple.isEmpty, !defaults.bool(forKey: "repera.apple.credentialInvalid.v1") {
            return "apple:" + apple
        }
        if defaults.bool(forKey: "repera.business.googleSignedIn.v1"),
           let owner = defaults.string(forKey: "repera.business.localOwnerSupabaseUserID.v1"),
           !owner.isEmpty {
            return "supabase:" + owner.lowercased()
        }
        return nil
    }

    /// Decode from disk (safe off-main). Prefer via `LaunchWarmup` so cold start overlaps first frame.
    static func loadFromDisk() -> Snapshot? {
        let url = fileURL
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            let snap = try JSONDecoder().decode(Snapshot.self, from: data)
            guard snap.version == schemaVersion,
                  let owner = activeOwnerScope,
                  snap.ownerScope == owner else { return nil }
            return snap
        } catch {
            return nil
        }
    }

    /// Sync helper for call sites that do not go through `LaunchWarmup`.
    static func loadSync() -> Snapshot? {
        loadFromDisk()
    }

    static func save(_ snapshot: Snapshot) {
        guard let owner = activeOwnerScope else { return }
        let url = fileURL
        do {
            var scoped = snapshot
            scoped.ownerScope = owner
            let data = try JSONEncoder().encode(scoped)
            try data.write(to: url, options: [.atomic, .completeFileProtectionUnlessOpen])
        } catch {
            // Best-effort cache; ignore disk errors.
        }
    }

    static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
