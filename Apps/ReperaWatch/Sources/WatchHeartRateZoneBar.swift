import SwiftUI

/// FC a la izquierda + barra de zonas a la derecha (azul→verde→amarillo→naranja→rojo).
/// Escala relativa a una FCmáx estimada (190) cuando no hay perfil de edad.
struct WatchHeartRateZoneBar: View {
    var bpm: Int?
    /// Estimación conservadora si no hay edad del usuario en el Watch.
    var estimatedMaxBpm: Double = 190

    var body: some View {
        HStack(spacing: 8) {
            Text(bpm.map { "\($0)" } ?? "—")
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(.primary)
                .frame(minWidth: 36, alignment: .leading)
                .accessibilityLabel(bpm.map { "Frecuencia cardíaca \($0)" } ?? "Sin frecuencia cardíaca")

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
                        .opacity(0.9)

                    // Marcador de posición actual en la barra.
                    if let fraction {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                            .shadow(color: .black.opacity(0.45), radius: 1, y: 0.5)
                            .offset(x: max(0, min(geo.size.width - 10, geo.size.width * fraction - 5)))
                    }
                }
            }
            .frame(height: 10)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }

    /// 0…1 dentro de un rango útil ~90…FCmáx (debajo de 90 se pega al inicio).
    private var fraction: CGFloat? {
        guard let bpm, estimatedMaxBpm > 100 else { return nil }
        let floor = 90.0
        let clamped = min(estimatedMaxBpm, max(floor, Double(bpm)))
        return CGFloat((clamped - floor) / (estimatedMaxBpm - floor))
    }
}

/// Fila de métrica en columna: etiqueta pequeña + valor.
struct WatchLiveMetricRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .leading)
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }
}
