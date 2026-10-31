import ReperaDomain
import SwiftUI

/// Segunda zona del scroll en live: marea / nieve / viento (Open-Meteo).
struct WatchActivityConditionsBlock: View {
    let conditions: ActivityConditionsSnapshot?
    let loading: Bool

    private let accent = Color(red: 48 / 255, green: 209 / 255, blue: 88 / 255)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Condiciones")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            if loading && conditions == nil {
                ProgressView()
                    .scaleEffect(0.8)
            } else if let conditions {
                if let temp = conditions.temperatureC {
                    row("thermometer", "Temp", String(format: "%.0f °C", temp))
                }
                if let wind = conditions.windKmh {
                    row("wind", "Viento", String(format: "%.0f km/h", wind))
                }
                if conditions.family == .water {
                    if let h = conditions.tideHeightMeters {
                        let trend = conditions.tideTrendLabel.map { " · \($0)" } ?? ""
                        row("water.waves", "Marea", String(format: "%.2f m%@", h, trend))
                    }
                    if let next = conditions.nextTideLabel {
                        row("clock", "Próxima", next)
                    }
                    if let wave = conditions.waveHeightMeters {
                        row("water.waves", "Oleaje", String(format: "%.1f m", wave))
                    }
                }
                if conditions.family == .snow {
                    if let snow = conditions.snowfallCm, snow > 0 {
                        row("snowflake", "Nevada", String(format: "%.1f cm/h", snow))
                    }
                    if let depth = conditions.snowDepthMeters, depth > 0 {
                        row("snowflake", "Nieve", String(format: "%.0f cm", depth * 100))
                    }
                }
                if let tip = conditions.disclaimer {
                    Text(tip)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(conditions.attribution)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            } else {
                Text("Sin datos de condiciones")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private func row(_ symbol: String, _ label: String, _ value: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .frame(width: 16)
                .foregroundStyle(accent)
            Text(label).font(.caption2)
            Spacer(minLength: 2)
            Text(value)
                .font(.caption2.weight(.semibold))
                .monospacedDigit()
        }
    }
}
