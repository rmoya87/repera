import Foundation
import GymbroDomain

enum ICloudStatus: Equatable {
    case available
    case signedOut
    case restricted
    case temporarilyUnavailable
}

/// Persistencia local + espejo en iCloud Documents.
/// Tras desinstalar/reinstalar, al iniciar sesión con la misma Apple ID se recupera el JSON.
@MainActor
final class LocalStore {
    static let shared = LocalStore()

    static let ubiquityContainerID = "iCloud.app.gymbroapp.ios"

    private let localURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private(set) var iCloudStatus: ICloudStatus = .temporarilyUnavailable

    private init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Gymbro", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        localURL = dir.appendingPathComponent("app_state.json")
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        refreshICloudStatus()
    }

    func refreshICloudStatus() {
        if FileManager.default.ubiquityIdentityToken == nil {
            iCloudStatus = .signedOut
            return
        }
        if iCloudDocumentsURL() != nil {
            iCloudStatus = .available
        } else {
            iCloudStatus = .temporarilyUnavailable
        }
    }

    func load() -> AppState {
        refreshICloudStatus()
        let local = readState(from: localURL)
        let cloud = readCoordinated(from: iCloudDocumentsURL())
        return pickNewest(local: local, cloud: cloud) ?? seededState()
    }

    /// Relee iCloud (descarga si hace falta) y devuelve el estado más reciente.
    func syncFromiCloud() async -> AppState? {
        refreshICloudStatus()
        guard iCloudStatus == .available, let cloudURL = iCloudDocumentsURL() else {
            return readState(from: localURL)
        }

        // Pide descarga si el fichero es stub de iCloud.
        let values = try? cloudURL.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
        if values?.ubiquitousItemDownloadingStatus == .notDownloaded {
            try? FileManager.default.startDownloadingUbiquitousItem(at: cloudURL)
            // Espera breve a que llegue (reinstall cold start).
            for _ in 0..<20 {
                try? await Task.sleep(nanoseconds: 250_000_000)
                let status = try? cloudURL.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
                    .ubiquitousItemDownloadingStatus
                if status == .current || status == nil {
                    break
                }
            }
        }

        let local = readState(from: localURL)
        let cloud = readCoordinated(from: cloudURL)
        let newest = pickNewest(local: local, cloud: cloud)
        if let newest {
            writeLocal(newest)
        }
        return newest
    }

    func save(_ state: AppState) {
        writeLocal(state)
        writeICloud(state)
        refreshICloudStatus()
    }

    func exportJSON(_ state: AppState) -> Data? {
        try? encoder.encode(state)
    }

    func importJSON(_ data: Data) -> AppState? {
        try? decoder.decode(AppState.self, from: data)
    }

    // MARK: - Private

    private func iCloudDocumentsURL() -> URL? {
        // Contenedor explícito; si el provisioning aún no lo tiene, prueba el por defecto.
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

    private func seededState() -> AppState {
        // Solo catálogo de ejercicios. Sin rutinas ni entrenos inventados.
        AppState(
            exercises: Catalog.seed(),
            routines: [],
            workouts: [],
            bodyWeights: [],
            updatedAt: Date()
        )
    }

    private func pickNewest(local: AppState?, cloud: AppState?) -> AppState? {
        switch (local, cloud) {
        case let (l?, c?):
            return l.updatedAt >= c.updatedAt ? l : c
        case let (l?, nil):
            return l
        case let (nil, c?):
            return c
        case (nil, nil):
            return nil
        }
    }

    private func writeLocal(_ state: AppState) {
        guard let data = try? encoder.encode(state) else { return }
        try? data.write(to: localURL, options: [.atomic])
    }

    private func writeICloud(_ state: AppState) {
        guard let url = iCloudDocumentsURL(), let data = try? encoder.encode(state) else { return }
        coordinateWrite(to: url, data: data)
    }

    private func readState(from url: URL?) -> AppState? {
        guard let url, FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let state = try? decoder.decode(AppState.self, from: data)
        else { return nil }
        return state
    }

    private func readCoordinated(from url: URL?) -> AppState? {
        guard let url else { return nil }
        var result: AppState?
        var error: NSError?
        let coordinator = NSFileCoordinator(filePresenter: nil)
        coordinator.coordinate(readingItemAt: url, options: [], error: &error) { readURL in
            result = readState(from: readURL)
        }
        return result
    }

    private func coordinateWrite(to url: URL, data: Data) {
        var error: NSError?
        let coordinator = NSFileCoordinator(filePresenter: nil)
        coordinator.coordinate(writingItemAt: url, options: [.forReplacing], error: &error) { writeURL in
            try? data.write(to: writeURL, options: [.atomic])
        }
    }
}
