import Foundation

/// iCloud Documents is already enabled for Repera (iCloud.com.app.repera).
/// This is a second, route-specific backup: the main workout JSON does not
/// contain imported GPX files or standalone favorite flags.
struct LiveRouteCloudArchive: Codable, Sendable {
    var routes: [LiveSavedRoute]
    var deletedIDs: [UUID]
}

enum LiveRouteCloudRead: Sendable {
    case unavailable
    case ready(LiveRouteCloudArchive)
}

/// File coordination runs off the main actor. Never replace a remote archive
/// while iCloud is signed out or its existing document is still downloading.
actor LiveRouteCloudBackup {
    static let shared = LiveRouteCloudBackup()
    private let containerID = "iCloud.com.app.repera"
    private let filename = "LiveRoutes-v2.json"

    private func cloudURL() -> URL? {
        guard let root = FileManager.default.url(
            forUbiquityContainerIdentifier: containerID
        ) else { return nil }
        return root.appendingPathComponent("Documents", isDirectory: true)
            .appendingPathComponent(filename)
    }

    func read() -> LiveRouteCloudRead {
        guard let url = cloudURL() else { return .unavailable }
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else {
            return .ready(LiveRouteCloudArchive(routes: [], deletedIDs: []))
        }
        // The file exists in iCloud but may not yet have downloaded on a
        // newly installed phone. In that case DO NOT upload the empty library.
        try? fm.startDownloadingUbiquitousItem(at: url)
        var coordinationError: NSError?
        var data: Data?
        NSFileCoordinator(filePresenter: nil).coordinate(
            readingItemAt: url, options: [], error: &coordinationError
        ) { coordinatedURL in
            data = try? Data(contentsOf: coordinatedURL)
        }
        guard coordinationError == nil,
              let data,
              let archive = try? JSONDecoder().decode(LiveRouteCloudArchive.self, from: data)
        else { return .unavailable }
        return .ready(archive)
    }

    @discardableResult
    func write(_ archive: LiveRouteCloudArchive) -> Bool {
        guard let url = cloudURL(),
              let data = try? JSONEncoder().encode(archive) else { return false }
        let fm = FileManager.default
        do {
            try fm.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true
            )
        } catch { return false }
        var coordinationError: NSError?
        var writeError: Error?
        NSFileCoordinator(filePresenter: nil).coordinate(
            writingItemAt: url, options: .forReplacing, error: &coordinationError
        ) { coordinatedURL in
            do {
                try data.write(to: coordinatedURL, options: .atomic)
            } catch {
                writeError = error
            }
        }
        return coordinationError == nil && writeError == nil
    }
}
