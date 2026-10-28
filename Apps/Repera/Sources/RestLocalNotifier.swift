import Foundation
import UserNotifications

/// Optional local notification when rest ends while the app is backgrounded.
/// Complements Live Activity; cancelled on skip / pause / session close.
enum RestLocalNotifier {
    private static let idPrefix = "repera.rest.end."

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


/// System-delivered alerts for clock boundaries when iOS suspends the app.
/// They complement, not replace, the foreground three-tone RestFeedback sounds.
/// Notifications honor notification permission, silent mode and Focus.
@MainActor
enum TimerBoundaryNotifier {
    enum Source: String, Hashable {
        case standalone
        case workout
    }

    struct Boundary {
        let afterSeconds: TimeInterval
        let title: String
    }

    private static var pendingIDs: [Source: [String]] = [:]

    static func schedule(_ source: Source, boundaries: [Boundary]) {
        cancel(source)
        let valid = boundaries.filter { $0.afterSeconds > 0.5 }
            .sorted { $0.afterSeconds < $1.afterSeconds }
        guard !valid.isEmpty else { return }
        // iOS limits pending local notifications per application. Leave room
        // for rest alerts and other notifications; always include the last end.
        var selected = Array(valid.prefix(40))
        if let final = valid.last,
           selected.last?.afterSeconds != final.afterSeconds {
            selected.append(final)
        }
        RestLocalNotifier.requestAuthorizationIfNeeded()
        var ids: [String] = []
        for boundary in selected {
            let identifier = "repera.timer.\(source.rawValue).\(UUID().uuidString)"
            let content = UNMutableNotificationContent()
            content.title = boundary.title
            content.body = "Temporizador Repera"
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: max(1, boundary.afterSeconds), repeats: false
            )
            UNUserNotificationCenter.current().add(UNNotificationRequest(
                identifier: identifier, content: content, trigger: trigger
            ))
            ids.append(identifier)
        }
        pendingIDs[source] = ids
    }

    static func cancel(_ source: Source) {
        let ids = pendingIDs.removeValue(forKey: source) ?? []
        guard !ids.isEmpty else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ids
        )
    }
}
