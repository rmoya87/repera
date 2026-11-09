import Foundation
import ReperaDomain
import Supabase

/// Cuantiles de fuerza alojados en Supabase (copia propia OPL + SymmetricStrength).
/// Sin llamadas a terceros en runtime. El JSON del bundle solo arranca offline.
@MainActor
final class StrengthBenchmarkRemoteStore {
    static let shared = StrengthBenchmarkRemoteStore()

    private struct Bootstrap: Decodable {
        let revision: Int64
        let distributions: [RemoteRow]
    }

    private struct Delta: Decodable {
        let revision: Int64
        let events: [RemoteEvent]
    }

    private struct RemoteEvent: Decodable {
        let id: Int64
        let operation: String
        let payload: RemoteRow?
    }

    private struct RemoteRow: Decodable {
        let id: Int64?
        let cohort: StrengthBenchmarkCohort
        let source: String
        let sourceRevision: String
        let sampleCount: Int
        let quantiles: [StrengthBenchmarkQuantile]
        let isActive: Bool?

        var distribution: StrengthBenchmarkDistribution? {
            guard isActive != false,
                  sampleCount > 0,
                  !source.isEmpty,
                  !sourceRevision.isEmpty,
                  quantiles.count >= 2 else { return nil }
            return StrengthBenchmarkDistribution(
                cohort: cohort,
                source: source,
                sourceRevision: sourceRevision,
                sampleCount: sampleCount,
                quantiles: quantiles
            )
        }
    }

    private struct Cache: Codable {
        var revision: Int64
        var rows: [StrengthBenchmarkDistribution]
    }

    private struct Head: Decodable { let id: Int64 }

    private var memory: Cache?
    private var isRefreshing = false
    private var lastProbeAt: Date?

    private actor Disk {
        private let url: URL = {
            let dir = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            )[0].appendingPathComponent("Repera", isDirectory: true)
            return dir.appendingPathComponent("strength_benchmarks_remote_v1.json")
        }()

        func read() -> Cache? {
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? JSONDecoder().decode(Cache.self, from: data)
        }

        func write(_ cache: Cache) throws {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            try JSONEncoder().encode(cache).write(to: url, options: .atomic)
        }
    }

    private let disk = Disk()
    private init() {}

    /// Prefer remote/cache; bundle only when nothing else is available (offline first launch).
    func currentDistributions() async -> [StrengthBenchmarkDistribution] {
        if let memory, !memory.rows.isEmpty { return memory.rows }
        if let saved = await disk.read(), !saved.rows.isEmpty {
            memory = saved
            return saved.rows
        }
        return Self.bundleSeed()
    }

    func refresh(force: Bool = false) async {
        guard !isRefreshing,
              BusinessAuthStore.shared.isConnected,
              let client = BusinessAuthStore.shared.apiClient else { return }
        if !force, let lastProbeAt, Date().timeIntervalSince(lastProbeAt) < 60 { return }
        isRefreshing = true
        lastProbeAt = Date()
        defer { isRefreshing = false }

        var working = memory ?? (await disk.read()) ?? Cache(revision: 0, rows: [])
        if working.rows.isEmpty {
            working.rows = Self.bundleSeed()
        }

        do {
            let headRows: [Head] = try await client
                .from("strength_benchmark_events")
                .select("id")
                .order("id", ascending: false)
                .limit(1)
                .execute()
                .value
            let head = headRows.first?.id ?? 0
            if working.revision == head, !working.rows.isEmpty {
                memory = working
                try? await disk.write(working)
                return
            }

            let lag = head - working.revision
            if working.revision == 0 || working.rows.isEmpty || lag > 200 {
                let boot: Bootstrap = try await client
                    .rpc("strength_benchmark_bootstrap")
                    .execute()
                    .value
                let rows = boot.distributions.compactMap(\.distribution)
                guard !rows.isEmpty else { return }
                working = Cache(revision: boot.revision, rows: rows)
            } else {
                let delta: Delta = try await client
                    .rpc("strength_benchmark_delta", params: ["p_after_revision": working.revision])
                    .execute()
                    .value
                var byKey = Dictionary(
                    uniqueKeysWithValues: working.rows.map { (Self.key($0), $0) }
                )
                for event in delta.events.sorted(by: { $0.id < $1.id }) {
                    switch event.operation {
                    case "upsert":
                        if let row = event.payload?.distribution {
                            byKey[Self.key(row)] = row
                        }
                    case "delete":
                        if let payload = event.payload {
                            byKey.removeValue(forKey: Self.key(payload))
                        }
                    default:
                        break
                    }
                }
                working = Cache(revision: delta.revision, rows: Array(byKey.values))
            }
            memory = working
            try await disk.write(working)
        } catch {
            memory = working
        }
    }

    private static func key(_ row: StrengthBenchmarkDistribution) -> String {
        let c = row.cohort
        return [
            c.lift.rawValue, c.sex.rawValue, c.equipment.rawValue,
            "\(c.ageMin)", "\(c.ageMax)",
            "\(c.bodyWeightMinKg)", "\(c.bodyWeightMaxKg)",
            row.source, row.sourceRevision
        ].joined(separator: "|")
    }

    private static func key(_ row: RemoteRow) -> String {
        guard let dist = row.distribution else {
            let c = row.cohort
            return [
                c.lift.rawValue, c.sex.rawValue, c.equipment.rawValue,
                "\(c.ageMin)", "\(c.ageMax)",
                "\(c.bodyWeightMinKg)", "\(c.bodyWeightMaxKg)",
                row.source, row.sourceRevision
            ].joined(separator: "|")
        }
        return key(dist)
    }

    private static func bundleSeed() -> [StrengthBenchmarkDistribution] {
        guard let url = Bundle.main.url(forResource: "strength_benchmarks", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rows = try? JSONDecoder().decode([StrengthBenchmarkDistribution].self, from: data)
        else { return [] }
        return rows
    }
}
