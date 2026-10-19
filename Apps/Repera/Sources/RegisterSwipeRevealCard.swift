import ReperaDomain
import SwiftUI
import UIKit

/// Card de registro Inicio.
/// Swipe vía UIKit (`transform` + pan): desactiva `UIScrollView` de chips durante el pan
/// y no recrea el hosting a mitad del gesto → sin temblor.
struct RegisterSwipeRevealCard<Title: View, Chips: View>: View {
    var onOpen: () -> Void
    var onDelete: () -> Void
    var deleteAccessibilityLabel: String
    private let title: () -> Title
    private let chips: () -> Chips

    private let revealWidth: CGFloat = 72
    private let chipsBandHeight: CGFloat = 48

    init(
        onOpen: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        deleteAccessibilityLabel: String = "Eliminar",
        @ViewBuilder title: @escaping () -> Title,
        @ViewBuilder chips: @escaping () -> Chips
    ) {
        self.onOpen = onOpen
        self.onDelete = onDelete
        self.deleteAccessibilityLabel = deleteAccessibilityLabel
        self.title = title
        self.chips = chips
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            deleteControl

            SmoothSwipeCardHost(
                revealWidth: revealWidth,
                chipsBandHeight: chipsBandHeight,
                onOpen: onOpen
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    title()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    chips()
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var deleteControl: some View {
        Button(action: onDelete) {
            Image(systemName: "trash.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(OG.red))
        }
        .buttonStyle(.plain)
        .padding(.trailing, 8)
        .accessibilityLabel(deleteAccessibilityLabel)
    }
}

// MARK: - Scroll lock

@MainActor
private enum SwipeCardScrollLock {
    /// Desactiva / reactiva todos los `UIScrollView` bajo `root` (carrusel de chips).
    static func setScrollEnabled(_ enabled: Bool, in root: UIView) {
        var queue: [UIView] = [root]
        while !queue.isEmpty {
            let view = queue.removeFirst()
            if let scroll = view as? UIScrollView {
                scroll.isScrollEnabled = enabled
                scroll.panGestureRecognizer.isEnabled = enabled
                if !enabled {
                    scroll.setContentOffset(scroll.contentOffset, animated: false)
                }
            }
            queue.append(contentsOf: view.subviews)
        }
    }
}

// MARK: - UIKit host

private struct SmoothSwipeCardHost<Content: View>: UIViewRepresentable {
    var revealWidth: CGFloat
    var chipsBandHeight: CGFloat
    var onOpen: () -> Void
    @ViewBuilder var content: () -> Content

    func makeCoordinator() -> Coordinator {
        Coordinator(revealWidth: revealWidth, chipsBandHeight: chipsBandHeight, onOpen: onOpen)
    }

    func makeUIView(context: Context) -> SwipeCardContainerView {
        let container = SwipeCardContainerView()
        let host = context.coordinator.ensureHost(content: content())
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: container.topAnchor),
            host.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            host.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.delegate = context.coordinator
        pan.cancelsTouchesInView = true
        pan.delaysTouchesBegan = false
        pan.delaysTouchesEnded = false
        container.addGestureRecognizer(pan)
        context.coordinator.pan = pan
        context.coordinator.cardView = host.view

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        tap.cancelsTouchesInView = false
        tap.require(toFail: pan)
        container.addGestureRecognizer(tap)

        return container
    }

    func updateUIView(_ uiView: SwipeCardContainerView, context: Context) {
        context.coordinator.revealWidth = revealWidth
        context.coordinator.chipsBandHeight = chipsBandHeight
        context.coordinator.onOpen = onOpen
        // Crítico: no recrear el árbol SwiftUI a mitad del swipe (causa temblor).
        guard !context.coordinator.isDragging else { return }
        context.coordinator.updateContent(content())
        uiView.setNeedsInvalidateIntrinsicContentSize()
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: SwipeCardContainerView,
        context: Context
    ) -> CGSize? {
        let width = proposal.width ?? uiView.bounds.width
        guard width.isFinite, width > 0 else { return nil }
        let fitted = context.coordinator.host?.sizeThatFits(
            in: CGSize(width: width, height: UIView.layoutFittingExpandedSize.height)
        ) ?? .zero
        return CGSize(width: width, height: max(fitted.height, 1))
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var revealWidth: CGFloat
        var chipsBandHeight: CGFloat
        var onOpen: () -> Void

        var host: UIHostingController<Content>?
        weak var cardView: UIView?
        var pan: UIPanGestureRecognizer?
        private(set) var isDragging = false

        private var startX: CGFloat = 0
        private var currentX: CGFloat = 0
        private var lockedHorizontal: Bool?

        init(revealWidth: CGFloat, chipsBandHeight: CGFloat, onOpen: @escaping () -> Void) {
            self.revealWidth = revealWidth
            self.chipsBandHeight = chipsBandHeight
            self.onOpen = onOpen
        }

        func ensureHost(content: Content) -> UIHostingController<Content> {
            if let host {
                host.rootView = content
                return host
            }
            let created = UIHostingController(rootView: content)
            created.safeAreaRegions = []
            host = created
            return created
        }

        func updateContent(_ content: Content) {
            host?.rootView = content
        }

        @objc func handleTap() {
            if abs(currentX) > 1 {
                settle(to: 0)
            } else {
                onOpen()
            }
        }

        @objc func handlePan(_ pan: UIPanGestureRecognizer) {
            guard let view = pan.view else { return }
            let translation = pan.translation(in: view)

            switch pan.state {
            case .began:
                isDragging = true
                startX = currentX
                lockedHorizontal = nil
                if let root = host?.view {
                    MainActor.assumeIsolated {
                        SwipeCardScrollLock.setScrollEnabled(false, in: root)
                    }
                }

            case .changed:
                if lockedHorizontal == nil {
                    let dx = abs(translation.x)
                    let dy = abs(translation.y)
                    guard dx > 3 || dy > 3 else { return }
                    lockedHorizontal = dx >= dy
                    if lockedHorizontal == false {
                        endDragRestoringScroll(settleTo: startX)
                        pan.isEnabled = false
                        pan.isEnabled = true
                        return
                    }
                }
                guard lockedHorizontal == true else { return }
                let next = SwipeRevealMath.clampedOffset(
                    start: startX,
                    translation: translation.x,
                    revealWidth: revealWidth
                )
                applyX(next, animated: false)

            case .ended, .cancelled, .failed:
                let wasHorizontal = lockedHorizontal == true
                lockedHorizontal = nil
                defer {
                    isDragging = false
                    if let root = host?.view {
                        MainActor.assumeIsolated {
                            SwipeCardScrollLock.setScrollEnabled(true, in: root)
                        }
                    }
                }
                guard wasHorizontal else {
                    settle(to: 0)
                    return
                }
                let velocityX = pan.velocity(in: view).x
                let projected = currentX + velocityX * 0.18
                let open = SwipeRevealMath.shouldOpen(
                    projected: projected,
                    current: currentX,
                    revealWidth: revealWidth
                )
                settle(to: open ? -revealWidth : 0)

            default:
                break
            }
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard gestureRecognizer === pan, let view = gestureRecognizer.view else { return true }
            let loc = gestureRecognizer.location(in: view)
            return SwipeRevealMath.shouldBeginSwipe(
                locationY: loc.y,
                viewHeight: view.bounds.height,
                chipsBandHeight: chipsBandHeight
            )
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            false
        }

        private func endDragRestoringScroll(settleTo x: CGFloat) {
            lockedHorizontal = nil
            isDragging = false
            if let root = host?.view {
                MainActor.assumeIsolated {
                    SwipeCardScrollLock.setScrollEnabled(true, in: root)
                }
            }
            settle(to: x)
        }

        private func applyX(_ x: CGFloat, animated: Bool) {
            currentX = x
            let transform = CGAffineTransform(translationX: x, y: 0)
            guard let cardView else { return }
            if animated {
                UIView.animate(
                    withDuration: 0.28,
                    delay: 0,
                    usingSpringWithDamping: 0.86,
                    initialSpringVelocity: 0.15,
                    options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseOut]
                ) {
                    cardView.transform = transform
                }
            } else {
                cardView.layer.removeAllAnimations()
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                cardView.transform = transform
                CATransaction.commit()
            }
        }

        private func settle(to x: CGFloat) {
            applyX(x, animated: true)
        }
    }
}

private final class SwipeCardContainerView: UIView {
    private var lastFittedHeight: CGFloat = 0

    func setNeedsInvalidateIntrinsicContentSize() {
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        guard let host = subviews.first else {
            return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
        }
        let width = bounds.width > 1 ? bounds.width : (superview?.bounds.width ?? 320)
        let size = host.systemLayoutSizeFitting(
            CGSize(width: width, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        lastFittedHeight = max(size.height, 1)
        return CGSize(width: UIView.noIntrinsicMetric, height: lastFittedHeight)
    }
}
