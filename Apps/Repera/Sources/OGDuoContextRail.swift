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

    /// Cada vista conserva sus acciones aunque un detalle aparezca junto al
    /// catálogo. Con un único owner, el detalle borraba Filtro y Nuevo.
    private var groups: [String: [Action]] = [:]

    func publish(owner: String, actions: [Action]) {
        groups[owner] = actions
    }

    func clear(owner: String) {
        groups.removeValue(forKey: owner)
    }

    func actions(for owner: String) -> [Action] {
        groups[owner] ?? []
    }
}

/// Acciones del mismo lateral donde iOS presenta hora, conexión y menú.
/// La navegación sigue siendo 100 % nativa; este componente no la sustituye.
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
