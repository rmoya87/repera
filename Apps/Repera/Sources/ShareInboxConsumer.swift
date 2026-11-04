import Foundation
import UIKit

/// Drains the App Group share inbox on the main app after hydration.
@MainActor
enum ShareInboxConsumer {
    static let boardImageReady = Notification.Name("repera.shareInbox.boardImage")
    static let gpxImported = Notification.Name("repera.shareInbox.gpx")

    private static var boardImageDataKey = "repera.shareInbox.pendingBoardImage"

    static func pendingBoardImageData() -> Data? {
        let data = UserDefaults.standard.data(forKey: boardImageDataKey)
        UserDefaults.standard.removeObject(forKey: boardImageDataKey)
        return data
    }

    static func drain() {
        while let (item, data) = ReperaShareInbox.takeNext() {
            switch item.kind {
            case .gpx:
                do {
                    try LiveRoutesStore.shared.addGPX(data: data, name: item.fileName)
                    NotificationCenter.default.post(name: gpxImported, object: item.fileName)
                } catch {
                    continue
                }
            case .boardImage:
                UserDefaults.standard.set(data, forKey: boardImageDataKey)
                NotificationCenter.default.post(name: boardImageReady, object: nil)
            }
        }
    }
}
