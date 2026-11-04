import AppIntents
import Foundation

/// Navigation-only system entry points. App Intents never create a HealthKit
/// workout or mutate workout results outside the authenticated Repera UI.
@MainActor
enum ReperaSystemCommand {
    enum Destination: String {
        case today, live, tools, exercises
    }

    static let notification = Notification.Name("repera.systemCommand")
    private static let pendingExerciseKey = "repera.systemCommand.exercise"
    private static let pendingKey = "repera.systemCommand.pending"

    static func request(_ destination: Destination) {
        UserDefaults.standard.set(destination.rawValue, forKey: pendingKey)
        NotificationCenter.default.post(name: notification, object: nil)
    }

    static func requestExercise(identifier: String) {
        guard let exercise = ExerciseSpotlightIndexer.exerciseID(for: identifier) else { return }
        UserDefaults.standard.set(exercise.uuidString, forKey: pendingExerciseKey)
        NotificationCenter.default.post(name: notification, object: nil)
    }

    static func takePendingExercise() -> UUID? {
        let raw = UserDefaults.standard.string(forKey: pendingExerciseKey)
        UserDefaults.standard.removeObject(forKey: pendingExerciseKey)
        return raw.flatMap(UUID.init(uuidString:))
    }

    static func takePending() -> Destination? {
        let raw = UserDefaults.standard.string(forKey: pendingKey)
        guard let raw, let destination = Destination(rawValue: raw) else {
            UserDefaults.standard.removeObject(forKey: pendingKey)
            return nil
        }
        UserDefaults.standard.removeObject(forKey: pendingKey)
        return destination
    }
}

struct ReperaTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "Entrenamiento de hoy"
    static var description = IntentDescription("Abre la sesión prevista en Repera para revisarla antes de comenzar.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        ReperaSystemCommand.request(.today)
        return .result()
    }
}

struct ReperaLiveIntent: AppIntent {
    static var title: LocalizedStringResource = "Comenzar actividad en Repera"
    static var description = IntentDescription("Abre Comenzar; Repera solicita confirmación antes de activar sensores.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        ReperaSystemCommand.request(.live)
        return .result()
    }
}

struct ReperaToolsIntent: AppIntent {
    static var title: LocalizedStringResource = "Abrir temporizador de Repera"
    static var description = IntentDescription("Abre las herramientas de entrenamiento donde se encuentra el temporizador.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        ReperaSystemCommand.request(.tools)
        return .result()
    }
}

struct ReperaExerciseLibraryIntent: AppIntent {
    static var title: LocalizedStringResource = "Buscar ejercicios en Repera"
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        ReperaSystemCommand.request(.exercises)
        return .result()
    }
}

struct ReperaAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ReperaTodayIntent(),
            phrases: [
                "Mi entrenamiento de hoy en \(.applicationName)",
                "Abrir mi entrenamiento en \(.applicationName)"
            ],
            shortTitle: "Entreno de hoy",
            systemImageName: "dumbbell"
        )
        AppShortcut(
            intent: ReperaLiveIntent(),
            phrases: [
                "Comenzar una actividad en \(.applicationName)",
                "Abrir Comenzar en \(.applicationName)"
            ],
            shortTitle: "Comenzar",
            systemImageName: "figure.run"
        )
        AppShortcut(
            intent: ReperaToolsIntent(),
            phrases: [
                "Abrir temporizador de \(.applicationName)"
            ],
            shortTitle: "Temporizador",
            systemImageName: "timer"
        )
        AppShortcut(
            intent: ReperaExerciseLibraryIntent(),
            phrases: [
                "Buscar ejercicios en \(.applicationName)"
            ],
            shortTitle: "Ejercicios",
            systemImageName: "magnifyingglass"
        )
    }
}
