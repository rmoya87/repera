import Foundation
import ReperaDomain
import Observation

/// Persistencia local-first de cuotas gratuitas (fuera del JSON deportivo).
/// Sync iCloud best-effort del mismo archivo; no es fuente de verdad de suscripción.
@MainActor
@Observable
final class FreeUsageStore {
    private(set) var state = FreeUsageState()
    private let fileName = "free_usage.json"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    /// Carga fuera del MainActor (disco / ubiquity pueden bloquear).
    func load() async {
        let local = localURL
        let name = fileName
        let result: (state: FreeUsageState?, foundLocal: Bool) = await Task.detached(priority: .utility) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let data = try? Data(contentsOf: local),
               let decoded = try? decoder.decode(FreeUsageState.self, from: data) {
                return (decoded, true)
            }
            if let ubiquity = FileManager.default.url(
                forUbiquityContainerIdentifier: nil
            )?.appendingPathComponent("Documents", isDirectory: true)
                .appendingPathComponent(name),
               let data = try? Data(contentsOf: ubiquity),
               let decoded = try? decoder.decode(FreeUsageState.self, from: data) {
                return (decoded, false)
            }
            return (nil, false)
        }.value

        let next = FreeUsageLedger.normalized(result.state ?? FreeUsageState())
        if next != state {
            state = next
        }
        // Materializa local si venía de iCloud o era primera ejecución.
        if !result.foundLocal {
            persistLocalOnly()
        }
    }

    func persist() {
        state = FreeUsageLedger.normalized(state)
        guard let data = try? encoder.encode(state) else { return }
        try? data.write(to: localURL, options: .atomic)
        let name = fileName
        Task.detached(priority: .utility) {
            guard let ubiquityDir = FileManager.default.url(
                forUbiquityContainerIdentifier: nil
            )?.appendingPathComponent("Documents", isDirectory: true) else { return }
            try? FileManager.default.createDirectory(at: ubiquityDir, withIntermediateDirectories: true)
            let remote = ubiquityDir.appendingPathComponent(name)
            try? data.write(to: remote, options: .atomic)
        }
    }

    @discardableResult
    func consumeBoardScan(attemptID: String, isPro: Bool) -> Bool {
        let consumed = FreeUsageLedger.consumeBoardScan(
            state: &state,
            attemptID: attemptID,
            isPro: isPro
        )
        if consumed { persist() }
        return consumed
    }

    func resetForDebug() {
        #if DEBUG
        state = FreeUsageLedger.normalized(FreeUsageState())
        persist()
        #endif
    }

    private func persistLocalOnly() {
        state = FreeUsageLedger.normalized(state)
        guard let data = try? encoder.encode(state) else { return }
        try? data.write(to: localURL, options: .atomic)
    }

    private var localURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("Repera", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(fileName)
    }
}
