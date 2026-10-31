import Observation
import SwiftUI

/// Acciones contextuales de las secciones principales cuando el sistema
/// presenta la navegación en un raíl vertical (iPhone Duo desplegado/iPad).
/// El raíl se dibuja en el nivel del TabView: las vistas hijas reciben un
/// ancho menor que la ventana y no pueden alinearlo con la navegación nativa.
@MainActor
@Observable
final class OGDuoContextRailStore {
    struct Action: Identifiable {
        let id: String
        let systemName: String
        let accessibilityLabel: String
        var tint: Color = OG.label
        var fill: Color? = nil
        let handler: () -> Void
    }

    var isExpanded = false
    private(set) var owner: String?
    private(set) var actions: [Action] = []

    func publish(owner: String, actions: [Action]) {
        self.owner = owner
        self.actions = actions
    }

    func clear(owner: String) {
        guard self.owner == owner else { return }
        self.owner = nil
        actions = []
    }
}

/// Se sitúa sobre el menú nativo de pestañas, en la MISMA coordenada horizontal.
/// No sustituye ni replica el TabView: solo muestra acciones de la pantalla actual.
struct OGDuoContextRail: View {
    let actions: [OGDuoContextRailStore.Action]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(actions) { action in
                Button(action: action.handler) {
                    Image(systemName: action.systemName)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(action.tint)
                        .frame(width: OG.toolbarGlassSize, height: OG.toolbarGlassSize)
                        .background {
                            if let fill = action.fill {
                                Circle().fill(fill)
                            }
                        }
                        .glassEffect(.regular.interactive(), in: .circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(action.accessibilityLabel)
            }
        }
        .frame(width: 54)
        .accessibilityElement(children: .contain)
    }
}
