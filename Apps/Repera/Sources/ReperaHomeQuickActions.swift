import UIKit

/// Home Screen Quick Actions (long-press app icon). Same four destinations as
/// Android launcher shortcuts — navigation only; never starts sensors/HealthKit.
enum ReperaHomeQuickActions {
    static let todayType = "com.app.repera.quick.today"
    static let liveType = "com.app.repera.quick.live"
    static let timerType = "com.app.repera.quick.timer"
    static let exercisesType = "com.app.repera.quick.exercises"

    @discardableResult
    static func enqueue(_ item: UIApplicationShortcutItem) -> Bool {
        let destination: ReperaSystemCommand.Destination?
        switch item.type {
        case todayType: destination = .today
        case liveType: destination = .live
        case timerType: destination = .tools
        case exercisesType: destination = .exercises
        default: destination = nil
        }
        guard let destination else { return false }
        Task { @MainActor in
            ReperaSystemCommand.request(destination)
        }
        return true
    }
}

/// Delivers static Quick Actions on cold and warm launch without owning the
/// SwiftUI window (leave `window` nil).
final class ReperaAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        if let shortcutItem = options.shortcutItem {
            ReperaHomeQuickActions.enqueue(shortcutItem)
        }
        let configuration = UISceneConfiguration(
            name: nil,
            sessionRole: connectingSceneSession.role
        )
        configuration.delegateClass = ReperaSceneDelegate.self
        return configuration
    }

    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(ReperaHomeQuickActions.enqueue(shortcutItem))
    }
}

final class ReperaSceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(ReperaHomeQuickActions.enqueue(shortcutItem))
    }
}
