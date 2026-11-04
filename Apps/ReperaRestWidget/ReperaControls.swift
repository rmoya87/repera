import AppIntents
import SwiftUI
import WidgetKit

/// System-owned controls: the app scene validates hydration and identity.
/// Never create workout sessions or ask for HealthKit authorization here.
struct ReperaBeginControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.app.repera.control.begin") {
            ControlWidgetButton(action: ReperaControlOpenIntent(target: .live)) {
                Label("Comenzar Repera", systemImage: "play.circle.fill")
            }
        }
        .displayName("Comenzar Repera")
        .description("Abrir la pantalla Comenzar, sin iniciar sensores automáticamente.")
    }
}

struct ReperaTodayControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.app.repera.control.today") {
            ControlWidgetButton(action: ReperaControlOpenIntent(target: .today)) {
                Label("Entreno de hoy", systemImage: "calendar")
            }
        }
        .displayName("Entreno de hoy")
        .description("Consultar el entrenamiento programado de hoy.")
    }
}

struct ReperaTimerControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.app.repera.control.timer") {
            ControlWidgetButton(action: ReperaControlOpenIntent(target: .tools)) {
                Label("Temporizador Repera", systemImage: "timer")
            }
        }
        .displayName("Temporizador")
        .description("Abrir las herramientas de entrenamiento.")
    }
}

struct ReperaBoardScanControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.app.repera.control.boardScan") {
            ControlWidgetButton(action: ReperaControlOpenIntent(target: .boardScan)) {
                Label("Escanear pizarra", systemImage: "text.viewfinder")
            }
        }
        .displayName("Escanear pizarra")
        .description("Abrir el escáner OCR de pizarra. No inicia sensores.")
    }
}
