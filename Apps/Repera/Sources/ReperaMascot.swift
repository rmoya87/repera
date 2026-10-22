import SwiftUI

enum ReperaMascotPose: String {
    /// Saludo (onboarding login).
    case welcome = "MascotWelcome"
    /// Thumbs up (permisos).
    case permissions = "MascotPermissions"
    /// Mancuernas arriba (paywall / hero).
    case hero = "MascotHero"
    /// Mascota con Apple Watch para métricas de actividad.
    case watch = "MascotWatch"
}

/// Mascota Repera para onboarding y pantallas de producto.
struct ReperaMascot: View {
    var pose: ReperaMascotPose
    var maxHeight: CGFloat = 220

    var body: some View {
        Image(pose.rawValue)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: maxHeight)
            .accessibilityHidden(true)
    }
}
