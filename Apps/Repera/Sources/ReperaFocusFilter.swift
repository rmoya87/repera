import AppIntents
import Foundation

/// Focus Filter: while Workout / Do Not Disturb Focus is active, optionally
/// mute Center chrome and prefer session / rest surfaces.
struct ReperaFocusFilterIntent: SetFocusFilterIntent {
    static let title: LocalizedStringResource = "Repera"
    static let description = IntentDescription(
        "Durante un Focus, silencia Center y prioriza la sesión o el descanso."
    )

    @Parameter(title: "Silenciar Center", default: true)
    var silenceCenter: Bool

    @Parameter(title: "Mostrar solo sesión / descanso", default: true)
    var sessionOnly: Bool

    func perform() async throws -> some IntentResult {
        ReperaFocusPreferences.apply(silenceCenter: silenceCenter, sessionOnly: sessionOnly)
        return .result()
    }
}

enum ReperaFocusPreferences {
    private static let silenceKey = "repera.focus.silenceCenter"
    private static let sessionKey = "repera.focus.sessionOnly"
    static let didChange = Notification.Name("repera.focus.didChange")

    static var silenceCenter: Bool {
        UserDefaults.standard.object(forKey: silenceKey) as? Bool ?? false
    }

    static var sessionOnly: Bool {
        UserDefaults.standard.object(forKey: sessionKey) as? Bool ?? false
    }

    static func apply(silenceCenter: Bool, sessionOnly: Bool) {
        UserDefaults.standard.set(silenceCenter, forKey: silenceKey)
        UserDefaults.standard.set(sessionOnly, forKey: sessionKey)
        NotificationCenter.default.post(name: didChange, object: nil)
    }
}
