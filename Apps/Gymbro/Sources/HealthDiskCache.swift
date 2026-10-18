import Foundation

/// Snapshot on-disk of progressive HealthKit arrays so Home/Progreso paint instantly on cold start.
enum HealthDiskCache {
    static let schemaVersion = 1
    private static let fileName = "health-progressive-cache.json"

    struct Snapshot: Codable, Sendable {
        var version: Int
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
        let dir = base.appendingPathComponent("Gymbro", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(fileName)
    }

    /// Decode from disk (safe off-main). Prefer via `LaunchWarmup` so cold start overlaps first frame.
    static func loadFromDisk() -> Snapshot? {
        let url = fileURL
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            let snap = try JSONDecoder().decode(Snapshot.self, from: data)
            guard snap.version == schemaVersion else { return nil }
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
        let url = fileURL
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: url, options: [.atomic])
        } catch {
            // Best-effort cache; ignore disk errors.
        }
    }

    static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
