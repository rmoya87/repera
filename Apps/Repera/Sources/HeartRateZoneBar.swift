import SwiftUI

/// Barra de zonas FC (azul→verde→amarillo→naranja→rojo). Solo la barra;
/// el LPM se pinta sobre la franja actual (paridad visual Watch, sin columna izquierda).
struct HeartRateZoneBar: View {
    var bpm: Int?
    /// Estimación conservadora si no hay edad del usuario.
    var estimatedMaxBpm: Double = 190

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.25, green: 0.55, blue: 1.0),
                                Color(red: 0.20, green: 0.85, blue: 0.40),
                                Color(red: 0.95, green: 0.85, blue: 0.15),
                                Color(red: 1.0, green: 0.55, blue: 0.10),
                                Color(red: 0.95, green: 0.20, blue: 0.20)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(0.92)

                if let bpm, let fraction {
                    Text("\(bpm)")
                        .font(.system(size: 11, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.black)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.95)))
                        .shadow(color: .black.opacity(0.22), radius: 1.5, y: 0.5)
                        .position(
                            x: markerX(width: geo.size.width, fraction: fraction),
                            y: geo.size.height / 2
                        )
                        .accessibilityHidden(true)
                }
            }
        }
        .frame(height: 22)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(bpm.map { "Frecuencia cardíaca \($0) lpm" } ?? "Sin frecuencia cardíaca")
    }

    /// 0…1 dentro de un rango útil ~90…FCmáx (debajo de 90 se pega al inicio).
    private var fraction: CGFloat? {
        guard let bpm, estimatedMaxBpm > 100 else { return nil }
        let floor = 90.0
        let clamped = min(estimatedMaxBpm, max(floor, Double(bpm)))
        return CGFloat((clamped - floor) / (estimatedMaxBpm - floor))
    }

    private func markerX(width: CGFloat, fraction: CGFloat) -> CGFloat {
        let inset: CGFloat = 18
        let usable = max(0, width - inset * 2)
        return inset + usable * fraction
    }
}
