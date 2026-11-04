import AppIntents
import SwiftUI
import WidgetKit

/// Centro de Control: abrir Repera. El inicio de sensores necesita la app visible.
struct ReperaQuickOpenControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.app.repera.control.open") {
            ControlWidgetButton(action: ReperaOpenControlIntent()) {
                Label("Repera", systemImage: "dumbbell")
            }
        }
        .displayName("Abrir Repera")
        .description("Acceso rápido a tus entrenamientos.")
    }
}
