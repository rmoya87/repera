import AudioToolbox
import UIKit

@MainActor
enum RestFeedback {
    static func tick(remaining: Int, sound: Bool, haptic: Bool) {
        guard remaining > 0, remaining <= 3 else { return }
        if haptic {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        if sound {
            // El temporizador y Comenzar comparten los mismos tres pitidos.
            // Hasta ahora tick solo vibraba a pesar de recibir sound: true.
            AudioServicesPlaySystemSound(1057)
        }
    }

    static func restComplete(sound: Bool, haptic: Bool) {
        if haptic {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        if sound {
            AudioServicesPlaySystemSound(1007)
        }
    }

    /// Pitido al cambio de intervalo / minuto (EMOM, Tabata…).
    static func intervalBeep(sound: Bool, haptic: Bool) {
        if haptic {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
        if sound {
            AudioServicesPlaySystemSound(1057)
        }
    }
}
