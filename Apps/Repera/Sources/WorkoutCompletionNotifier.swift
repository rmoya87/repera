import Foundation
import UserNotifications

/// A watch-owned workout has already finished. The notification only offers
/// optional correction of sets; it does not restart the workout or create Health data.
final class WorkoutCompletionNotifier: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let shared = WorkoutCompletionNotifier()
    static let pendingKey = "repera.pendingCompletedWorkoutToOpen"
    static let pendingLiveReviewKey = "repera.pendingWatchLiveReviewToOpen"
    static let openEvent = Notification.Name("repera.openFinishedWorkoutEditor")
    private static let prefix = "repera.completeWorkout."
    private static let liveReviewPrefix = "repera.reviewLive."

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

    /// A Watch-initiated Comenzar finish stays in Review; notification never
    /// claims the activity has been saved or alters its Health measurements.
    func scheduleLiveReview(sessionID: UUID) {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            guard [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus)
            else { return }
            let content = UNMutableNotificationContent()
            content.title = "Actividad lista para revisar"
            content.body = "Abre Comenzar para guardar, editar o descartar la actividad."
            content.userInfo = ["liveReviewSessionID": sessionID.uuidString]
            content.sound = .default
            let request = UNNotificationRequest(
                identifier: Self.liveReviewPrefix + sessionID.uuidString,
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
        // Preserva avisos de descanso, clases y temporizadores en primer plano.
        // El delegado único no debe silenciar las demás notificaciones de Repera.
        completionHandler([.banner, .sound])
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
                ReperaAnalytics.track(.notificationOpened, parameters: [
                    "feature_area": "training",
                    "entry_point": "workout_complete",
                    "result": "success"
                ])
                NotificationCenter.default.post(name: Self.openEvent, object: id)
            }
        } else if let raw = response.notification.request.content.userInfo["liveReviewSessionID"] as? String,
                  let id = UUID(uuidString: raw),
                  response.notification.request.identifier == Self.liveReviewPrefix + id.uuidString {
            UserDefaults.standard.set(id.uuidString, forKey: Self.pendingLiveReviewKey)
            Task { @MainActor in
                NotificationCenter.default.post(
                    name: Notification.Name("repera.openComenzarFromWatch"), object: nil
                )
            }
        } else {
            Task { @MainActor in
                ReperaAnalytics.track(.notificationOpened, parameters: [
                    "feature_area": "reliability",
                    "entry_point": "system",
                    "result": "success"
                ])
            }
        }
        completionHandler()
    }
}
