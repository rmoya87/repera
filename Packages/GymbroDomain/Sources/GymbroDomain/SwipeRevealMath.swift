import Foundation

/// Math for Inicio register-card swipe-to-delete (UIKit host).
public enum SwipeRevealMath {
    public static func clampedOffset(start: CGFloat, translation: CGFloat, revealWidth: CGFloat) -> CGFloat {
        min(0, max(start + translation, -revealWidth))
    }

    /// `true` si el toque está fuera de la franja inferior de chips.
    public static func shouldBeginSwipe(locationY: CGFloat, viewHeight: CGFloat, chipsBandHeight: CGFloat) -> Bool {
        locationY <= viewHeight - chipsBandHeight
    }

    public static func shouldOpen(projected: CGFloat, current: CGFloat, revealWidth: CGFloat) -> Bool {
        projected < -revealWidth * 0.45 || current < -revealWidth * 0.45
    }
}
