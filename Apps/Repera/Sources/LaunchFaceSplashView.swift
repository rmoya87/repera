import SwiftUI

/// Splash de carga: cara estática de la mascota sobre verde de marca.
struct LaunchFaceSplashView: View {
    var body: some View {
        ZStack {
            Color(red: 48 / 255, green: 209 / 255, blue: 88 / 255)
                .ignoresSafeArea()
            Image("MascotFace")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 48)
                .accessibilityHidden(true)
        }
    }
}
