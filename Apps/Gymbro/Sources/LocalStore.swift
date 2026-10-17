import Foundation
import GymbroDomain
import os

enum ICloudStatus: Equatable, Sendable {
    case available
    case signedOut
    case restricted
    case temporarilyUnavailable
}

/// Bootstrap / sync lifecycle visible to the UI.
enum AppSyncPhase: Equatable, Sendable {
    case loadingLocal
    case awaitingRemote
    case ready
    case offline
    case recoveringCorrupt
    case failed(String)
}

enum PersistenceError: Error, Equatable, Sendable {
    case encodeFailed
    case decodeFailed
    case writeFailed
    case cloudNotReady
    case cloudUnavailable
    case corruptDocument
}

/// Off-main encode/decode + atomic file I/O. One actor serializes all writes.
actor AppStatePersistence {
    static let shared = AppStatePersistence()

    static let ubiquityContainerID = "iCloud.app.gymbroapp.ios"

    private let localURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let logger = Logger(subsystem: "app.gymbroapp.ios", category: "Persistence")

    private var pendingState: AppState?
    private var coalesceTask: Task<Void, Never>?
    private var lastWriteGeneration: UInt64 = 0

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Gymbro", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        localURL = dir.appendingPathComponent("app_state.json")
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        encoder = enc
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        decoder = dec
    }

    var localFileURL: URL { localURL }

    func localFileExists() -> Bool {
        FileManager.default.fileExists(atPath: localURL.path)
    }

    func readLocal() -> Result<AppState?, PersistenceError> {
        guard FileManager.default.fileExists(atPath: localURL.path) else { return .success(nil) }
        do {
            let data = try Data(contentsOf: localURL)
            guard !data.isEmpty else { return .failure(.corruptDocument) }
            let state = try decoder.decode(AppState.self, from: data)
            return .success(state)
        } catch {
            logger.error("Local decode failed: \(String(describing: error), privacy: .public)")
            return .failure(.corruptDocument)
        }
    }

    func writeLocal(_ state: AppState) throws {
        guard let data = try? encoder.encode(state) else { throw PersistenceError.encodeFailed }
        do {
            try data.write(to: localURL, options: [.atomic])
        } catch {
            logger.error("Local write failed: \(String(describing: error), privacy: .public)")
            throw PersistenceError.writeFailed
        }
    }

    /// Coalesce frequent saves; critical path should call `flush` / `writeLocalNow`.
    func scheduleLocalWrite(_ state: AppState, delayNanoseconds: UInt64 = 120_000_000) {
        pendingState = state
        lastWriteGeneration &+= 1
        let generation = lastWriteGeneration
        coalesceTask?.cancel()
        coalesceTask = Task {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
            guard !Task.isCancelled, generation == lastWriteGeneration, let pending = pendingState else { return }
            pendingState = nil
            do {
                try writeLocal(pending)
            } catch {
                logger.error("Coalesced local write failed: \(String(describing: error), privacy: .public)")
            }
        }
    }

    func flushPendingLocal() async {
        coalesceTask?.cancel()
        coalesceTask = nil
        if let pending = pendingState {
            pendingState = nil
            try? writeLocal(pending)
        }
    }

    func writeLocalNow(_ state: AppState) throws {
        coalesceTask?.cancel()
        coalesceTask = nil
        pendingState = nil
        try writeLocal(state)
    }

    func iCloudStatus() -> ICloudStatus {
        if FileManager.default.ubiquityIdentityToken == nil {
            return .signedOut
        }
        if iCloudDocumentsURL() != nil {
            return .available
        }
        return .temporarilyUnavailable
    }

    func iCloudDocumentsURL() -> URL? {
        let root = FileManager.default.url(forUbiquityContainerIdentifier: Self.ubiquityContainerID)
            ?? FileManager.default.url(forUbiquityContainerIdentifier: nil)
        guard let root else { return nil }
        let docs = root.appendingPathComponent("Documents", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
        } catch {
            return nil
        }
        return docs.appendingPathComponent("app_state.json")
    }

    /// `.notDownloaded` stubs must not be overwritten.
    func cloudReadiness(at url: URL) -> CloudReadiness {
        var isUbiquitous = false
        if let values = try? url.resourceValues(forKeys: [.isUbiquitousItemKey]),
           values.isUbiquitousItem == true {
            isUbiquitous = true
        }
        guard FileManager.default.fileExists(atPath: url.path) || isUbiquitous else {
            return .absent
        }
        let status = try? url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
            .ubiquitousItemDownloadingStatus
        switch status {
        case .notDownloaded:
            return .notDownloaded
        case .downloaded, .current, .none:
            return .ready
        @unknown default:
            return .ready
        }
    }

    enum CloudReadiness: Equatable, Sendable {
        case absent
        case notDownloaded
        case ready
    }

    func startCloudDownloadIfNeeded(at url: URL) {
        let readiness = cloudReadiness(at: url)
        if readiness == .notDownloaded {
            try? FileManager.default.startDownloadingUbiquitousItem(at: url)
        }
    }

    func waitForCloudDownload(at url: URL, attempts: Int = 24, sleepNanos: UInt64 = 250_000_000) async -> CloudReadiness {
        startCloudDownloadIfNeeded(at: url)
        for _ in 0..<attempts {
            let readiness = cloudReadiness(at: url)
            if readiness != .notDownloaded { return readiness }
            try? await Task.sleep(nanoseconds: sleepNanos)
        }
        return cloudReadiness(at: url)
    }

    func readCloudCoordinated(at url: URL) -> Result<AppState?, PersistenceError> {
        var result: Result<AppState?, PersistenceError> = .success(nil)
        var error: NSError?
        let coordinator = NSFileCoordinator(filePresenter: nil)
        coordinator.coordinate(readingItemAt: url, options: [], error: &error) { readURL in
            guard FileManager.default.fileExists(atPath: readURL.path) else {
                result = .success(nil)
                return
            }
            do {
                let data = try Data(contentsOf: readURL)
                guard !data.isEmpty else {
                    result = .failure(.corruptDocument)
                    return
                }
                let state = try decoder.decode(AppState.self, from: data)
                result = .success(state)
            } catch {
                logger.error("Cloud decode failed: \(String(describing: error), privacy: .public)")
                result = .failure(.corruptDocument)
            }
        }
        if error != nil {
            return .failure(.writeFailed)
        }
        return result
    }

    func writeCloud(at url: URL, state: AppState) throws {
        let readiness = cloudReadiness(at: url)
        if readiness == .notDownloaded {
            throw PersistenceError.cloudNotReady
        }
        guard let data = try? encoder.encode(state) else { throw PersistenceError.encodeFailed }
        var error: NSError?
        var wrote = false
        let coordinator = NSFileCoordinator(filePresenter: nil)
        coordinator.coordinate(writingItemAt: url, options: [.forReplacing], error: &error) { writeURL in
            do {
                try data.write(to: writeURL, options: [.atomic])
                wrote = true
            } catch {
                logger.error("Cloud write failed: \(String(describing: error), privacy: .public)")
            }
        }
        if error != nil || !wrote {
            throw PersistenceError.writeFailed
        }
    }

    func encode(_ state: AppState) -> Data? {
        try? encoder.encode(state)
    }

    func decode(_ data: Data) -> AppState? {
        try? decoder.decode(AppState.self, from: data)
    }

    func seededState(deviceId: String) -> AppState {
        AppState(
            exercises: Catalog.seed(),
            routines: [],
            workouts: [],
            bodyWeights: [],
            updatedAt: Date(),
            syncRevision: 1,
            lastWriterDeviceId: deviceId
        )
    }

    /// Recover remote without uploading a seed over undownloaded cloud.
    func recoverRemote(local: AppState) async -> RecoveryOutcome {
        let status = iCloudStatus()
        guard status == .available, let cloudURL = iCloudDocumentsURL() else {
            return .unavailable(status)
        }

        let readiness = await waitForCloudDownload(at: cloudURL)
        switch readiness {
        case .notDownloaded:
            return .waitingForDownload
        case .absent:
            return .noRemoteDocument
        case .ready:
            break
        }

        switch readCloudCoordinated(at: cloudURL) {
        case .failure(.corruptDocument):
            return .corruptRemote
        case .failure:
            return .waitingForDownload
        case .success(let cloud):
            guard let cloud else { return .noRemoteDocument }
            let picked = SyncConflictResolver.pickNewest(local: local, remote: cloud) ?? local
            let adoptedRemote = (picked.syncRevision == cloud.syncRevision
                && picked.updatedAt == cloud.updatedAt
                && picked.lastWriterDeviceId == cloud.lastWriterDeviceId)
                || SyncConflictResolver.winner(local: local, remote: cloud) == .remote
            if adoptedRemote {
                try? writeLocalNow(picked)
                return .adoptedRemote(picked)
            }
            return .keptLocal(shouldUpload: true)
        }
    }

    enum RecoveryOutcome: Sendable {
        case unavailable(ICloudStatus)
        case waitingForDownload
        case noRemoteDocument
        case corruptRemote
        case adoptedRemote(AppState)
        case keptLocal(shouldUpload: Bool)
    }
}

/// MainActor façade used by the app. Heavy I/O runs in `AppStatePersistence`.
@MainActor
final class LocalStore {
    static let shared = LocalStore()

    private let persistence = AppStatePersistence.shared
    private(set) var iCloudStatus: ICloudStatus = .temporarilyUnavailable
    private(set) var syncPhase: AppSyncPhase = .loadingLocal
    private(set) var lastPersistenceError: PersistenceError?

    /// Stable per-install id used as conflict provenance.
    let deviceId: String

    private init() {
        let key = "gymbro.deviceWriterId"
        if let existing = UserDefaults.standard.string(forKey: key), !existing.isEmpty {
            deviceId = existing
        } else {
            let id = UUID().uuidString
            UserDefaults.standard.set(id, forKey: key)
            deviceId = id
        }
        refreshICloudStatus()
    }

    func refreshICloudStatus() {
        // Ubiquity token is cheap; URL creation may hit disk — keep sync for UI badges.
        if FileManager.default.ubiquityIdentityToken == nil {
            iCloudStatus = .signedOut
            return
        }
        iCloudStatus = .temporarilyUnavailable
        Task {
            let status = await persistence.iCloudStatus()
            await MainActor.run {
                self.iCloudStatus = status
            }
        }
    }

    /// Cold start: local only. Never reads undownloaded iCloud stubs.
    func loadLocalOnly() -> AppState {
        syncPhase = .loadingLocal
        // Synchronous bridge for `GymbroStore.init` — actor hop via semaphore avoided;
        // use a dedicated sync helper that only touches the local path.
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Gymbro", isDirectory: true)
            .appendingPathComponent("app_state.json")
        if FileManager.default.fileExists(atPath: url.path),
           let data = try? Data(contentsOf: url),
           let state = try? makeDecoder().decode(AppState.self, from: data) {
            syncPhase = .awaitingRemote
            return state
        }
        // First launch / empty disk: seed in memory only (no remote write yet).
        syncPhase = .awaitingRemote
        return AppState(
            exercises: Catalog.seed(),
            routines: [],
            workouts: [],
            bodyWeights: [],
            updatedAt: .distantPast,
            syncRevision: 0,
            lastWriterDeviceId: deviceId
        )
    }

    /// Legacy entry used by older call sites — prefer `loadLocalOnly` + `recoverFromiCloud`.
    func load() -> AppState {
        loadLocalOnly()
    }

    func stampForPersist(_ state: inout AppState, bumpRevision: Bool) {
        state.updatedAt = Date()
        state.lastWriterDeviceId = deviceId
        if bumpRevision {
            state.syncRevision = max(state.syncRevision, 0) + 1
        }
    }

    /// Local durable write (coalesced). Does **not** touch iCloud.
    func persistLocal(_ state: AppState, immediate: Bool = false) {
        lastPersistenceError = nil
        Task {
            do {
                if immediate {
                    try await persistence.writeLocalNow(state)
                } else {
                    await persistence.scheduleLocalWrite(state)
                }
            } catch let error as PersistenceError {
                await MainActor.run { self.lastPersistenceError = error }
            } catch {
                await MainActor.run { self.lastPersistenceError = .writeFailed }
            }
        }
    }

    /// Local + remote when cloud is ready. Skips remote if stub not downloaded.
    func save(_ state: AppState) {
        persistLocal(state, immediate: true)
        Task { await self.pushToiCloudIfSafe(state) }
        refreshICloudStatus()
    }

    func flush() async {
        await persistence.flushPendingLocal()
    }

    func recoverFromiCloud(local: AppState) async -> AppStatePersistence.RecoveryOutcome {
        syncPhase = .awaitingRemote
        let outcome = await persistence.recoverRemote(local: local)
        let status = await persistence.iCloudStatus()
        iCloudStatus = status
        switch outcome {
        case .unavailable(.signedOut):
            syncPhase = .offline
        case .unavailable:
            syncPhase = .offline
        case .waitingForDownload:
            syncPhase = .awaitingRemote
        case .corruptRemote:
            syncPhase = .recoveringCorrupt
        case .adoptedRemote, .keptLocal, .noRemoteDocument:
            syncPhase = status == .available ? .ready : .offline
        }
        return outcome
    }

    func pushToiCloudIfSafe(_ state: AppState) async {
        let status = await persistence.iCloudStatus()
        iCloudStatus = status
        guard status == .available, let url = await persistence.iCloudDocumentsURL() else { return }
        let readiness = await persistence.cloudReadiness(at: url)
        guard readiness != .notDownloaded else {
            lastPersistenceError = .cloudNotReady
            await persistence.startCloudDownloadIfNeeded(at: url)
            return
        }
        do {
            try await persistence.writeCloud(at: url, state: state)
        } catch let error as PersistenceError {
            lastPersistenceError = error
        } catch {
            lastPersistenceError = .writeFailed
        }
    }

    /// Download + merge; never uploads when cloud is still a stub.
    func syncFromiCloud(local: AppState) async -> AppState? {
        let outcome = await recoverFromiCloud(local: local)
        switch outcome {
        case .adoptedRemote(let remote):
            return remote
        case .keptLocal(let shouldUpload):
            if shouldUpload {
                await pushToiCloudIfSafe(local)
            }
            return local
        case .noRemoteDocument:
            await pushToiCloudIfSafe(local)
            return local
        case .waitingForDownload, .corruptRemote, .unavailable:
            return nil
        }
    }

    func exportJSON(_ state: AppState) -> Data? {
        // Encode on caller; small enough. Prefer actor for large docs later.
        try? makeEncoder().encode(state)
    }

    func importJSON(_ data: Data) -> AppState? {
        try? makeDecoder().decode(AppState.self, from: data)
    }

    private func makeEncoder() -> JSONEncoder {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        return enc
    }

    private func makeDecoder() -> JSONDecoder {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return dec
    }
}
