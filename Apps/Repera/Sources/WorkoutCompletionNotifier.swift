import Foundation
import UserNotifications

/// A watch-owned workout has already finished. The notification only offers
/// optional correction of sets; it does not restart the workout or create Health data.
final class WorkoutCompletionNotifier: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let shared = WorkoutCompletionNotifier()
    static let pendingKey = "repera.pendingCompletedWorkoutToOpen"
    static let openEvent = Notification.Name("repera.openFinishedWorkoutEditor")
    private static let prefix = "repera.completeWorkout."

    func install() {
        UNUserNotificationCenter.current().delegate = self
    }

    func schedule(workoutID: UUID) {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                _ = try? await center.requestAuthorization(options: [.alert, .sound])
            }
            let authorized = await center.notificationSettings()
            guard [.authorized, .provisional, .ephemeral].contains(authorized.authorizationStatus)
            else { return }

            let content = UNMutableNotificationContent()
            content.title = "¿Quieres completar tu entrenamiento?"
            content.body = "Toca para revisar y registrar las repeticiones y los pesos."
            content.sound = .default
            content.userInfo = ["workoutId": workoutID.uuidString]
            let request = UNNotificationRequest(
                identifier: Self.prefix + workoutID.uuidString,
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            )
            try? await center.add(request)
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let isWorkout = notification.request.identifier.hasPrefix(Self.prefix)
        completionHandler(isWorkout ? [.banner, .sound] : [])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let raw = response.notification.request.content.userInfo["workoutId"] as? String,
           let id = UUID(uuidString: raw),
           response.notification.request.identifier == Self.prefix + id.uuidString {
            // Keep the exact target through a terminated/background app launch.
            UserDefaults.standard.set(id.uuidString, forKey: Self.pendingKey)
            Task { @MainActor in
                NotificationCenter.default.post(name: Self.openEvent, object: id)
            }
        }
        completionHandler()
    }
}
