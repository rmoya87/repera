import Foundation
import UserNotifications

/// Optional local notification when rest ends while the app is backgrounded.
/// Complements Live Activity; cancelled on skip / pause / session close.
enum RestLocalNotifier {
    private static let idPrefix = "gymbro.rest.end."

    static func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func schedule(token: UInt64, at endDate: Date, exerciseName: String?) {
        let interval = endDate.timeIntervalSinceNow
        guard interval > 0.5 else { return }
        requestAuthorizationIfNeeded()
        let content = UNMutableNotificationContent()
        content.title = "Descanso terminado"
        if let exerciseName, !exerciseName.isEmpty {
            content.body = "Sigue con \(exerciseName)"
        } else {
            content.body = "¡A entrenar!"
        }
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(idPrefix)\(token)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    static func cancel(token: UInt64) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["\(idPrefix)\(token)"])
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix(idPrefix) }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
}
