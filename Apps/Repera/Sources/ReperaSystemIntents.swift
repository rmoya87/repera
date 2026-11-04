import AppIntents
import Foundation

/// Siri y Atajos sólo navegan a una actividad solicitada. El botón Iniciar
/// dentro de Repera sigue siendo dueño de permisos, GPS y HealthKit.
enum ReperaSystemRoute {
    static let pendingKey = "repera.pendingSystemRoute"
    static let notification = Notification.Name("repera.openSystemRoute")

    static func enqueue(_ route: String) {
        UserDefaults.standard.set(route, forKey: pendingKey)
        NotificationCenter.default.post(name: notification, object: nil)
    }
}

struct ReperaOpenStartIntent: AppIntent {
    static let title: LocalizedStringResource = "Abrir Comenzar en Repera"
    static let description = IntentDescription("Abre la pantalla para elegir e iniciar una actividad.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        ReperaSystemRoute.enqueue("live")
        return .result()
    }
}

struct ReperaOpenWorkoutIntent: AppIntent {
    static let title: LocalizedStringResource = "Ver mi entreno en Repera"
    static let description = IntentDescription("Muestra el entrenamiento activo o el Inicio.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        ReperaSystemRoute.enqueue("workout")
        return .result()
    }
}

struct ReperaAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ReperaOpenStartIntent(),
            phrases: [
                "Abrir Comenzar en \\(.applicationName)",
                "Quiero entrenar con \\(.applicationName)"
            ],
            shortTitle: "Comenzar",
            systemImageName: "figure.run"
        )
        AppShortcut(
            intent: ReperaOpenWorkoutIntent(),
            phrases: [
                "Ver mi entrenamiento en \\(.applicationName)"
            ],
            shortTitle: "Mi entrenamiento",
            systemImageName: "dumbbell"
        )
    }
}
