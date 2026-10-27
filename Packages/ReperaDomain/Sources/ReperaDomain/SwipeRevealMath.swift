import Foundation

/// Math for Inicio register-card swipe-to-delete (UIKit host).
public enum SwipeRevealMath {
    public static func clampedOffset(
        start: CGFloat, translation: CGFloat, revealWidth: CGFloat,
        allowsLeading: Bool = false
    ) -> CGFloat {
        min(allowsLeading ? revealWidth : 0, max(start + translation, -revealWidth))
    }

    /// `true` si el toque está fuera de la franja inferior de chips.
    public static func shouldBeginSwipe(locationY: CGFloat, viewHeight: CGFloat, chipsBandHeight: CGFloat) -> Bool {
        locationY <= viewHeight - chipsBandHeight
    }

    public static func shouldOpen(projected: CGFloat, current: CGFloat, revealWidth: CGFloat) -> Bool {
        projected < -revealWidth * 0.45 || current < -revealWidth * 0.45
    }

    /// Leading (deslizar a derecha) se habilita solo cuando hay editor permitido.
    /// El borrado trailing conserva su contrato anterior.
    public static func settledOffset(
        projected: CGFloat, current: CGFloat, revealWidth: CGFloat,
        allowsLeading: Bool
    ) -> CGFloat {
        if allowsLeading && (projected > revealWidth * 0.45 || current > revealWidth * 0.45) {
            return revealWidth
        }
        return shouldOpen(projected: projected, current: current, revealWidth: revealWidth)
            ? -revealWidth : 0
    }
}
