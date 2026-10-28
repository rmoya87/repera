import Foundation
import ReperaDomain
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

    static let ubiquityContainerID = "iCloud.com.app.repera"

    private let localURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let logger = Logger(subsystem: "com.app.repera", category: "Persistence")

    private var pendingState: AppState?
    private var coalesceTask: Task<Void, Never>?
    private var lastWriteGeneration: UInt64 = 0
    /// Highest syncRevision successfully written to disk.
    private var lastCommittedRevision: Int = -1
    /// Ubiquity container resolution is expensive; cache after first hit.
    private var cachedCloudDocsURL: URL?
    /// Result of `LaunchWarmup` / first `readLocal` — avoids a second disk decode on hydrate.
    /// Also seeded when `LaunchWarmup.loadAppStateSync` already decoded for first paint.
    private var warmedLocalRead: Result<AppState?, PersistenceError>?

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Repera", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        localURL = dir.appendingPathComponent("app_state.json")
        let enc = JSONEncoder()
        // Compact JSON: faster encode and smaller cold-start I/O.
        enc.outputFormatting = [.sortedKeys]
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

    /// Overlap disk decode with first SwiftUI frame (`LaunchWarmup.start`).
    func warmLocalRead() async {
        if warmedLocalRead != nil { return }
        // Prefer state already decoded sync for ReperaStore first paint.
        if let painted = LaunchWarmup.appStateForFirstPaint() {
            warmedLocalRead = .success(painted)
            return
        }
        warmedLocalRead = performReadLocal()
    }

    func readLocal() -> Result<AppState?, PersistenceError> {
        if let warmedLocalRead { return warmedLocalRead }
        let result = performReadLocal()
        warmedLocalRead = result
        return result
    }

    private func performReadLocal() -> Result<AppState?, PersistenceError> {
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
        // Discard stale snapshots that lost the race to a newer revision.
        if state.syncRevision < lastCommittedRevision {
            logger.info(
                "Skip stale local write rev=\(state.syncRevision, privacy: .public) < committed=\(self.lastCommittedRevision, privacy: .public)"
            )
            return
        }
        guard let data = try? encoder.encode(state) else { throw PersistenceError.encodeFailed }
        do {
            try data.write(to: localURL, options: [.atomic])
            lastCommittedRevision = max(lastCommittedRevision, state.syncRevision)
        } catch {
            logger.error("Local write failed: \(String(describing: error), privacy: .public)")
            throw PersistenceError.writeFailed
        }
    }

    /// Coalesce frequent saves; critical path should call `flush` / `writeLocalNow`.
    func scheduleLocalWrite(_ state: AppState, delayNanoseconds: UInt64 = 120_000_000) {
        if let pending = pendingState, state.syncRevision < pending.syncRevision {
            return
        }
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

    /// Elimina el documento iCloud de forma coordinada y el snapshot local.
    /// La operación no considera éxito una copia de iCloud inaccesible.
    func purgeAccountFiles() throws {
        guard iCloudStatus() == .available, let cloudURL = iCloudDocumentsURL() else {
            throw PersistenceError.cloudUnavailable
        }
        coalesceTask?.cancel()
        coalesceTask = nil
        pendingState = nil
        lastWriteGeneration &+= 1
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinationError: NSError?
        var deletionError: Error?
        coordinator.coordinate(writingItemAt: cloudURL, options: .forDeleting, error: &coordinationError) { url in
            do {
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                }
            } catch {
                deletionError = error
            }
        }
        guard coordinationError == nil, deletionError == nil else {
            throw PersistenceError.writeFailed
        }
        do {
            if FileManager.default.fileExists(atPath: localURL.path) {
                try FileManager.default.removeItem(at: localURL)
            }
        } catch {
            throw PersistenceError.writeFailed
        }
        warmedLocalRead = nil
        lastCommittedRevision = -1
    }

    /// Write snapshot then flush any coalesce — single barrier for background / session end.
    func persistAndFlush(_ state: AppState) async throws {
        coalesceTask?.cancel()
        coalesceTask = nil
        pendingState = nil
        try writeLocal(state)
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
        if FileManager.default.ubiquityIdentityToken == nil {
            cachedCloudDocsURL = nil
            return nil
        }
        if let cachedCloudDocsURL { return cachedCloudDocsURL }
        let root = FileManager.default.url(forUbiquityContainerIdentifier: Self.ubiquityContainerID)
            ?? FileManager.default.url(forUbiquityContainerIdentifier: nil)
        guard let root else { return nil }
        let docs = root.appendingPathComponent("Documents", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
        } catch {
            return nil
        }
        let url = docs.appendingPathComponent("app_state.json")
        cachedCloudDocsURL = url
        return url
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
        // NS_TYPED_ENUM — compare explicitly (switch is never exhaustive).
        let status = try? url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
            .ubiquitousItemDownloadingStatus
        if status == .notDownloaded {
            return .notDownloaded
        }
        return .ready
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

    /// Short poll so cold launch is not blocked for seconds on a stub.
    func waitForCloudDownload(
        at url: URL,
        attempts: Int = 6,
        sleepNanos: UInt64 = 80_000_000
    ) async -> CloudReadiness {
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
            // A newer, leaner copy may lack GPS already recorded for exactly
            // the same session on the other device. Keep the winner's other
            // fields but restore measured points before any upload can erase them.
            let reconciled = SyncConflictResolver.restoringMissingWorkoutRoutes(
                in: picked, from: adoptedRemote ? local : cloud
            )
            if reconciled != picked {
                return .reconciledRouteData(reconciled)
            }
            if adoptedRemote {
                // Cloud recovery is asynchronous. A workout may start while
                // downloading: the caller must recheck before replacing local data.
                // Never overwrite the last durable workout from this cloud actor.
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
        case reconciledRouteData(AppState)
        case keptLocal(shouldUpload: Bool)
    }
}

/// MainActor façade used by the app. Heavy I/O runs in `AppStatePersistence`.
@MainActor
final class LocalStore {
    static let shared = LocalStore()

    private let persistence = AppStatePersistence.shared
    /// Chains recover/upload so parallel refresh + persist cannot interleave cloud I/O.
    private var cloudTail: Task<Void, Never>?
    private(set) var accountDeletionLocked = false
    private(set) var iCloudStatus: ICloudStatus = .temporarilyUnavailable
    private(set) var syncPhase: AppSyncPhase = .loadingLocal
    private(set) var lastPersistenceError: PersistenceError?

    /// Stable per-install id used as conflict provenance.
    let deviceId: String

    private init() {
        let key = "repera.deviceWriterId"
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

    /// Resolves ubiquity on the persistence actor (can take ~1s); use from async recovery paths.
    func refreshICloudStatusAsync() async {
        if FileManager.default.ubiquityIdentityToken == nil {
            iCloudStatus = .signedOut
            return
        }
        iCloudStatus = await persistence.iCloudStatus()
    }

    /// Empty shell so SwiftUI can paint before disk/catalog work.
    func emptyShellState() -> AppState {
        AppState(
            exercises: [],
            routines: [],
            workouts: [],
            bodyWeights: [],
            updatedAt: .distantPast,
            syncRevision: 0,
            lastWriterDeviceId: deviceId
        )
    }

    /// Cold start: local only. Prefer `loadLocalOnlyAsync` so first frame is not blocked.
    func loadLocalOnly() -> AppState {
        syncPhase = .loadingLocal
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Repera", isDirectory: true)
            .appendingPathComponent("app_state.json")
        if FileManager.default.fileExists(atPath: url.path),
           let data = try? Data(contentsOf: url),
           let state = try? makeDecoder().decode(AppState.self, from: data) {
            syncPhase = .awaitingRemote
            return state
        }
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

    /// Disk + decode off the critical path. First install returns an empty shell immediately;
    /// call `buildSeedCatalogAsync` afterward so Home can paint before Catalog.seed().
    func loadLocalOnlyAsync() async -> AppState {
        syncPhase = .loadingLocal
        let writerId = deviceId
        await persistence.warmLocalRead()
        let result = await persistence.readLocal()
        switch result {
        case .success(let state):
            if let state {
                syncPhase = .awaitingRemote
                return state
            }
        case .failure:
            break
        }
        syncPhase = .awaitingRemote
        return AppState(
            exercises: [],
            routines: [],
            workouts: [],
            bodyWeights: [],
            updatedAt: .distantPast,
            syncRevision: 0,
            lastWriterDeviceId: writerId
        )
    }

    func buildSeedCatalogAsync() async -> [Exercise] {
        await Task.detached(priority: .userInitiated) {
            Catalog.prewarm()
            return Catalog.seed()
        }.value
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
        guard !accountDeletionLocked else { return }
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

    /// Awaitable barrier: durable local write of this snapshot (drops older revisions).
    func persistAndFlush(_ state: AppState) async {
        lastPersistenceError = nil
        do {
            try await persistence.persistAndFlush(state)
        } catch let error as PersistenceError {
            lastPersistenceError = error
        } catch {
            lastPersistenceError = .writeFailed
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
        await withCloudSerial { [self] in
            self.syncPhase = .awaitingRemote
            let outcome = await self.persistence.recoverRemote(local: local)
            let status = await self.persistence.iCloudStatus()
            self.iCloudStatus = status
            switch outcome {
            case .unavailable(.signedOut):
                self.syncPhase = .offline
            case .unavailable:
                self.syncPhase = .offline
            case .waitingForDownload:
                self.syncPhase = .awaitingRemote
            case .corruptRemote:
                self.syncPhase = .recoveringCorrupt
            case .adoptedRemote, .reconciledRouteData, .keptLocal, .noRemoteDocument:
                self.syncPhase = status == .available ? .ready : .offline
            }
            return outcome
        }
    }

    func pushToiCloudIfSafe(_ state: AppState) async {
        guard !accountDeletionLocked else { return }
        await withCloudSerial { [self] in
            guard !self.accountDeletionLocked else { return }
            let status = await self.persistence.iCloudStatus()
            self.iCloudStatus = status
            guard status == .available, let url = await self.persistence.iCloudDocumentsURL() else { return }
            let readiness = await self.persistence.cloudReadiness(at: url)
            guard readiness != .notDownloaded else {
                self.lastPersistenceError = .cloudNotReady
                await self.persistence.startCloudDownloadIfNeeded(at: url)
                return
            }
            do {
                try await self.persistence.writeCloud(at: url, state: state)
            } catch let error as PersistenceError {
                self.lastPersistenceError = error
            } catch {
                self.lastPersistenceError = .writeFailed
            }
        }
    }

    /// Bloquea escrituras mientras se elimina una cuenta, esperando al final
    /// de cualquier subida anterior antes de retirar los documentos.
    func purgeDeletedAccountDocuments() async throws {
        accountDeletionLocked = true
        let outcome: Result<Bool, PersistenceError> = await withCloudSerial { [self] in
            do {
                try await self.persistence.purgeAccountFiles()
                return .success(true)
            } catch let error as PersistenceError {
                return .failure(error)
            } catch {
                return .failure(.writeFailed)
            }
        }
        switch outcome {
        case .success: return
        case .failure(let error):
            accountDeletionLocked = false
            throw error
        }
    }

    func resumeStorageForNewLogin() {
        accountDeletionLocked = false
    }

    /// FIFO cloud ops: each waits for the previous recover/upload to finish.
    private func withCloudSerial<T: Sendable>(
        _ body: @escaping @MainActor @Sendable () async -> T
    ) async -> T {
        let prior = cloudTail
        let task = Task { @MainActor in
            await prior?.value
            return await body()
        }
        cloudTail = Task { _ = await task.value }
        return await task.value
    }

    /// Download + merge; never uploads when cloud is still a stub.
    func syncFromiCloud(local: AppState) async -> AppState? {
        let outcome = await recoverFromiCloud(local: local)
        switch outcome {
        case .adoptedRemote(let remote), .reconciledRouteData(let remote):
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
