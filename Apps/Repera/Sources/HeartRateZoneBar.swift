import SwiftUI

/// Zonas de FC coherentes con Apple Watch (60/70/80/90 % de FCmáx estimada).
/// No se atribuye una zona si Salud no aporta una lectura actual y válida.
struct HeartRateZoneBar: View {
    @Environment(ReperaStore.self) private var store
    var bpm: Int?
    var estimatedMaxBpm: Double = 190

    private var personalMaxBpm: Double {
        Double(store.state.settings.heartRateMaxBpm ?? Int(estimatedMaxBpm))
    }

    private let colors: [Color] = [
        Color(red: 0.25, green: 0.55, blue: 1),
        Color(red: 0.20, green: 0.85, blue: 0.40),
        Color(red: 0.95, green: 0.85, blue: 0.15),
        Color(red: 1, green: 0.55, blue: 0.10),
        Color(red: 0.95, green: 0.20, blue: 0.20)
    ]

    private var zone: Int? {
        guard let bpm, (25...250).contains(bpm),
              personalMaxBpm.isFinite, personalMaxBpm > 0 else { return nil }
        let ratio = Double(bpm) / personalMaxBpm
        if ratio < 0.60 { return 1 }
        if ratio < 0.70 { return 2 }
        if ratio < 0.80 { return 3 }
        if ratio < 0.90 { return 4 }
        return 5
    }

    @ViewBuilder
    var body: some View {
        if let bpm, let zone {
            VStack(alignment: .leading, spacing: 3) {
            GeometryReader { geo in
                let gap: CGFloat = 4
                // Cuatro tramos de una unidad + el tramo activo de tres.
                // Sin muestra todos los tramos ocupan exactamente lo mismo.
                let unit = max(0, (geo.size.width - 4 * gap) / 7)
                HStack(spacing: gap) {
                    ForEach(1...5, id: \.self) { level in
                        let active = zone == level
                        Capsule()
                            .fill(colors[level - 1].opacity(active ? 1 : 0.38))
                            .frame(width: unit * (active ? 3 : 1), height: active ? 42 : 12)
                            .overlay {
                                if active {
                                    VStack(spacing: 0) {
                                        Text("Zona \(level)")
                                        Text("\(bpm) lpm")
                                    }
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(.black)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .accessibilityHidden(true)
                                }
                            }
                            .accessibilityHidden(true)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: 44)

            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Frecuencia cardíaca \(bpm) pulsaciones, zona \(zone) de 5")
        }
    }
}
