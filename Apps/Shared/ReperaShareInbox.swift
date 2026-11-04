import Foundation
import UniformTypeIdentifiers

/// App Group inbox for Share Extension / document opens.
/// The extension only copies bytes; the main app parses GPX / board images after hydration.
enum ReperaShareInbox {
    static let groupID = "group.com.app.repera"
    static let openURLNotification = Notification.Name("repera.shareInbox.ready")

    enum Kind: String, Codable {
        case gpx
        case boardImage
    }

    struct Item: Codable, Equatable {
        var id: UUID
        var kind: Kind
        var fileName: String
        var createdAt: Date
    }

    private static let queueKey = "repera.shareInbox.queue.v1"

    private static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)?
            .appendingPathComponent("ShareInbox", isDirectory: true)
    }

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: groupID)
    }

    static func ensureDirectory() throws {
        guard let url = containerURL else {
            throw NSError(domain: "ReperaShareInbox", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "App Group group.com.app.repera unavailable"
            ])
        }
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    /// Copies inbound data into the shared container. Never parses GPX or runs OCR here.
    @discardableResult
    static func enqueue(data: Data, kind: Kind, fileName: String) throws -> Item {
        try ensureDirectory()
        guard let dir = containerURL else {
            throw NSError(domain: "ReperaShareInbox", code: 1)
        }
        let item = Item(id: UUID(), kind: kind, fileName: fileName, createdAt: Date())
        let dest = dir.appendingPathComponent(item.id.uuidString, isDirectory: false)
        try data.write(to: dest, options: .atomic)
        var queue = loadQueue()
        queue.append(item)
        saveQueue(queue)
        return item
    }

    static func loadQueue() -> [Item] {
        guard let data = defaults?.data(forKey: queueKey),
              let decoded = try? JSONDecoder().decode([Item].self, from: data) else { return [] }
        return decoded
    }

    static func saveQueue(_ items: [Item]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults?.set(data, forKey: queueKey)
    }

    static func takeNext() -> (Item, Data)? {
        var queue = loadQueue()
        guard let item = queue.first, let dir = containerURL else { return nil }
        let url = dir.appendingPathComponent(item.id.uuidString)
        guard let data = try? Data(contentsOf: url) else {
            queue.removeFirst()
            saveQueue(queue)
            try? FileManager.default.removeItem(at: url)
            return takeNext()
        }
        queue.removeFirst()
        saveQueue(queue)
        try? FileManager.default.removeItem(at: url)
        return (item, data)
    }

    static func kind(for typeIdentifier: String, fileName: String) -> Kind? {
        let lower = fileName.lowercased()
        if lower.hasSuffix(".gpx") { return .gpx }
        if UTType(typeIdentifier)?.conforms(to: .xml) == true && lower.hasSuffix(".gpx") {
            return .gpx
        }
        if typeIdentifier == "com.topografixix.gpx" || typeIdentifier.contains("gpx") {
            return .gpx
        }
        if UTType(typeIdentifier)?.conforms(to: .image) == true { return .boardImage }
        if typeIdentifier.hasPrefix("public.image") || typeIdentifier.contains("jpeg")
            || typeIdentifier.contains("png") || typeIdentifier.contains("heic") {
            return .boardImage
        }
        return nil
    }

    static var openAppURL: URL {
        URL(string: "repera://import")!
    }
}
