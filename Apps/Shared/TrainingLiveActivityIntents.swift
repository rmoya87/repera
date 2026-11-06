import AppIntents
import Foundation

/// Commands from Live Activity / Dynamic Island buttons. Never write HealthKit,
/// GPS, or set logs from the extension process — only enqueue for the app UI.
enum TrainingLiveActivityCommand {
    enum Action: String {
        case pause
        case resume
        case openSession
    }

    static let notification = Notification.Name("repera.trainingLiveActivity.command")
    private static let pendingKey = "repera.trainingLiveActivity.pending"

    /// Persist off-main is fine; the notify must reach SwiftUI on the main actor
    /// (`LiveActivityIntent.perform` often runs in a background executor).
    @MainActor
    static func request(_ action: Action) {
        UserDefaults.standard.set(action.rawValue, forKey: pendingKey)
        NotificationCenter.default.post(name: notification, object: nil)
    }

    static func takePending() -> Action? {
        let raw = UserDefaults.standard.string(forKey: pendingKey)
        UserDefaults.standard.removeObject(forKey: pendingKey)
        return raw.flatMap(Action.init(rawValue:))
    }
}

/// Pause an active free workout. The main app owns sensors and applies the action.
struct TrainingPauseLiveActivityIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Pausar entrenamiento"
    static let description = IntentDescription("Pausa el entrenamiento activo en Repera. No guarda resultados.")
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        await TrainingLiveActivityCommand.request(.pause)
        return .result()
    }
}

/// Resume a paused free workout after the athlete confirms on the Live Activity.
struct TrainingResumeLiveActivityIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Reanudar entrenamiento"
    static let description = IntentDescription("Reanuda el entrenamiento pausado en Repera.")
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        await TrainingLiveActivityCommand.request(.resume)
        return .result()
    }
}

/// Open the active session UI so the athlete can confirm a set manually.
/// Dictating or tapping never auto-saves a series from the Live Activity.
struct TrainingOpenSessionLiveActivityIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Abrir sesión"
    static let description = IntentDescription("Abre la sesión en Repera para revisar o confirmar la serie.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        await TrainingLiveActivityCommand.request(.openSession)
        return .result()
    }
}
