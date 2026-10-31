import SwiftUI
import UIKit

/// El TabView de iOS 27 puede reducir el ancho del contenido al crear su
/// barra vertical de pestañas. Un .overlay del TabView se alinea entonces
/// con el borde del CONTENIDO, no con el lateral físico del iPhone Duo.
///
/// Esta sonda monta un único host transparente en la UIWindow existente:
/// los botones comparten la coordenada X del raíl nativo (no se añade una
/// segunda columna ni se sustituye la navegación de Apple).
struct OGDuoWindowContextActions: UIViewRepresentable {
    let actions: [OGDuoContextRailStore.Action]

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WindowProbe {
        let probe = WindowProbe()
        probe.isUserInteractionEnabled = false
        probe.backgroundColor = .clear
        probe.onWindowChange = { [weak coordinator = context.coordinator] window in
            coordinator?.attach(to: window)
        }
        return probe
    }

    func updateUIView(_ uiView: WindowProbe, context: Context) {
        context.coordinator.update(actions: actions)
        context.coordinator.attach(to: uiView.window)
    }

    static func dismantleUIView(_ uiView: WindowProbe, coordinator: Coordinator) {
        uiView.onWindowChange = nil
        coordinator.detach()
    }

    final class WindowProbe: UIView {
        var onWindowChange: ((UIWindow?) -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            onWindowChange?(window)
        }

        override var intrinsicContentSize: CGSize { .zero }
    }

    @MainActor
    final class Coordinator {
        private let host = UIHostingController(
            rootView: OGDuoContextRail(actions: [])
                .padding(.vertical, 8)
                .background(.regularMaterial, in: Capsule())
        )
        private weak var hostWindow: UIWindow?
        private var constraints: [NSLayoutConstraint] = []
        private var currentActions: [OGDuoContextRailStore.Action] = []

        init() {
            host.view.backgroundColor = .clear
            host.view.isOpaque = false
            host.view.translatesAutoresizingMaskIntoConstraints = false
            host.view.accessibilityIdentifier = "repera-duo-window-context-actions"
        }

        func update(actions: [OGDuoContextRailStore.Action]) {
            currentActions = actions
            host.rootView = OGDuoContextRail(actions: actions)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: Capsule())
            host.view.isHidden = actions.isEmpty
            host.view.isUserInteractionEnabled = !actions.isEmpty
        }

        func attach(to window: UIWindow?) {
            guard let window else {
                detach()
                return
            }
            if hostWindow === window {
                // Una NavigationStack o una sheet puede cambiar el orden Z.
                // Mantener las acciones encima sin modificar el menú nativo.
                if !currentActions.isEmpty {
                    window.bringSubviewToFront(host.view)
                }
                return
            }
            detach()
            hostWindow = window
            window.addSubview(host.view)

            // En las capturas, el centro de los iconos del TabView está a
            // ~53 pt del borde derecho. 54 pt de ancho + 26 pt de margen
            // colocan las acciones EXACTAMENTE en esa misma línea.
            // Empezar debajo del reloj / Wi-Fi (safe area superior).
            constraints = [
                host.view.trailingAnchor.constraint(
                    equalTo: window.trailingAnchor, constant: -26
                ),
                host.view.topAnchor.constraint(
                    equalTo: window.topAnchor,
                    constant: max(120, window.safeAreaInsets.top + 52)
                ),
                host.view.widthAnchor.constraint(equalToConstant: 54),
                host.view.heightAnchor.constraint(
                    lessThanOrEqualTo: window.heightAnchor, multiplier: 0.45
                )
            ]
            NSLayoutConstraint.activate(constraints)
            host.view.isHidden = currentActions.isEmpty
            host.view.isUserInteractionEnabled = !currentActions.isEmpty
        }

        func detach() {
            NSLayoutConstraint.deactivate(constraints)
            constraints.removeAll()
            host.view.removeFromSuperview()
            hostWindow = nil
        }
    }
}
