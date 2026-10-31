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
        private var trailingConstraint: NSLayoutConstraint?
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
                updateNativeRailAlignment(in: window)
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
            let trailing = host.view.trailingAnchor.constraint(
                equalTo: window.trailingAnchor, constant: -26
            )
            trailingConstraint = trailing
            constraints = [
                trailing,
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
            updateNativeRailAlignment(in: window)
            host.view.isHidden = currentActions.isEmpty
            host.view.isUserInteractionEnabled = !currentActions.isEmpty
        }

        /// Preferir el centro real de la UITabBar vertical de iOS.
        /// Si el sistema cambia su clase interna, conservar el centro
        /// de referencia obtenido de las capturas (53 pt desde la derecha).
        private func updateNativeRailAlignment(in window: UIWindow) {
            let centerX = nativeTabRailCenter(in: window)
                ?? (window.bounds.maxX - 53)
            let trailingInset = window.bounds.maxX - centerX - 27
            trailingConstraint?.constant = -trailingInset
        }

        private func nativeTabRailCenter(in window: UIWindow) -> CGFloat? {
            var candidates: [CGRect] = []
            func visit(_ view: UIView) {
                if view is UITabBar, !view.isHidden, view.alpha > 0.05 {
                    let rect = view.convert(view.bounds, to: window)
                    // Las tab bars horizontales ocupan casi toda la anchura.
                    // Solo una barra VERTICAL a la derecha es una referencia.
                    if rect.width >= 38, rect.width <= 150,
                       rect.height > rect.width * 1.6,
                       rect.midX > window.bounds.width * 0.70 {
                        candidates.append(rect)
                    }
                }
                for child in view.subviews { visit(child) }
            }
            visit(window)
            return candidates.min(by: { $0.width < $1.width })?.midX
        }

        func detach() {
            NSLayoutConstraint.deactivate(constraints)
            trailingConstraint = nil
            constraints.removeAll()
            host.view.removeFromSuperview()
            hostWindow = nil
        }
    }
}
