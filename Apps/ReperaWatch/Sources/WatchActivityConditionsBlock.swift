import ReperaDomain
import SwiftUI

/// Muestra únicamente condiciones realmente disponibles para la actividad.
/// No ocupa altura ni presenta una sección vacía mientras carga o falla Open-Meteo.
struct WatchActivityConditionsBlock: View {
    let conditions: ActivityConditionsSnapshot?
    let loading: Bool

    private let accent = Color(red: 48 / 255, green: 209 / 255, blue: 88 / 255)

    var body: some View {
        Group {
            if let conditions, hasVisibleMetrics(conditions) {
                VStack(alignment: .leading, spacing: 9) {
                    Label("Condiciones", systemImage: "cloud.sun")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if let temp = valid(conditions.temperatureC) {
                        row("thermometer", "Temperatura", String(format: "%.0f °C", temp))
                    }
                    if let wind = valid(conditions.windKmh) {
                        row("wind", "Viento", String(format: "%.0f km/h", wind))
                    }
                    if conditions.family == .water {
                        if let height = valid(conditions.tideHeightMeters) {
                            let trend = conditions.tideTrendLabel.map { " · \($0)" } ?? ""
                            row("water.waves", "Marea", String(format: "%.2f m%@", height, trend))
                        }
                        if let next = conditions.nextTideLabel, !next.isEmpty {
                            row("clock", "Próxima marea", next)
                        }
                        if let waves = valid(conditions.waveHeightMeters) {
                            row("water.waves", "Oleaje", String(format: "%.1f m", waves))
                        }
                    }
                    if conditions.family == .snow {
                        if let snowfall = valid(conditions.snowfallCm), snowfall > 0 {
                            row("snowflake", "Nevada", String(format: "%.1f cm/h", snowfall))
                        }
                        if let depth = valid(conditions.snowDepthMeters), depth > 0 {
                            row("snowflake", "Nieve", String(format: "%.0f cm", depth * 100))
                        }
                    }

                    if let tip = conditions.disclaimer, !tip.isEmpty {
                        Text(tip)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if !conditions.attribution.isEmpty {
                        Text(conditions.attribution)
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(.white.opacity(0.07),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.top, 5)
            }
        }
    }

    private func valid(_ value: Double?) -> Double? {
        guard let value, value.isFinite else { return nil }
        return value
    }

    private func hasVisibleMetrics(_ conditions: ActivityConditionsSnapshot) -> Bool {
        if valid(conditions.temperatureC) != nil || valid(conditions.windKmh) != nil {
            return true
        }
        if conditions.family == .water {
            return valid(conditions.tideHeightMeters) != nil
                || (conditions.nextTideLabel?.isEmpty == false)
                || valid(conditions.waveHeightMeters) != nil
        }
        if conditions.family == .snow {
            return (valid(conditions.snowfallCm) ?? 0) > 0
                || (valid(conditions.snowDepthMeters) ?? 0) > 0
        }
        return false
    }

    private func row(_ symbol: String, _ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 7) {
            Image(systemName: symbol)
                .font(.caption)
                .frame(width: 17)
                .foregroundStyle(accent)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer(minLength: 5)
            Text(value)
                .font(.caption2.weight(.semibold))
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
