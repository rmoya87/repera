import SwiftUI

/// Zonas de FC coherentes con Apple Watch (60/70/80/90 % de FCmáx estimada).
/// Sin lectura válida el hueco se reserva (opacity 0) para no mover el layout de métricas.
struct HeartRateZoneBar: View {
    @Environment(ReperaStore.self) private var store
    var bpm: Int?
    var estimatedMaxBpm: Double = 190

    private var personalMaxBpm: Double {
        if let personalized = store.state.settings.heartRateMaxBpm {
            return Double(personalized)
        }
        return estimatedMaxBpm.isFinite && estimatedMaxBpm > 0 ? estimatedMaxBpm : 190
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

    var body: some View {
        let activeZone = zone
        let activeBpm = bpm.flatMap { (25...250).contains($0) ? $0 : nil }
        VStack(alignment: .leading, spacing: 3) {
            GeometryReader { geo in
                let gap: CGFloat = 4
                // Cuatro tramos de una unidad + el tramo activo de tres.
                // Sin muestra todos los tramos ocupan exactamente lo mismo.
                let unit = max(0, (geo.size.width - 4 * gap) / 7)
                HStack(spacing: gap) {
                    ForEach(1...5, id: \.self) { level in
                        let active = activeZone == level
                        Capsule()
                            .fill(colors[level - 1].opacity(active ? 1 : 0.38))
                            .frame(width: unit * (active ? 3 : 1), height: active ? 42 : 12)
                            .overlay {
                                if active, let activeBpm {
                                    VStack(spacing: 0) {
                                        Text("Zona \(level)")
                                        Text("\(activeBpm) lpm")
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
        .opacity(activeZone == nil ? 0 : 1)
        .accessibilityHidden(activeZone == nil)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText(bpm: activeBpm, zone: activeZone))
    }

    private func accessibilityText(bpm: Int?, zone: Int?) -> String {
        guard let bpm, let zone else { return "" }
        return "Frecuencia cardíaca \(bpm) pulsaciones, zona \(zone) de 5"
    }
}
