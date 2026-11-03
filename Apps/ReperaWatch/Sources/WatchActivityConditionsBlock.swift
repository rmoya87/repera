import ReperaDomain
import SwiftUI

/// Identifica la procedencia real de cada grupo; nunca atribuye Open-Meteo a Apple.
struct WatchActivityConditionsBlock: View {
    let conditions: ActivityConditionsSnapshot?
    let loading: Bool

    private let accent = Color(red: 48 / 255, green: 209 / 255, blue: 88 / 255)

    private var hasApple: Bool {
        conditions?.airSource == .appleWeather ||
            conditions?.snowfallSource == .appleWeather
    }

    private var hasMarineOrSnowDepth: Bool {
        guard let conditions else { return false }
        return conditions.tideHeightMeters != nil || conditions.nextTideLabel != nil ||
            conditions.waveHeightMeters != nil || conditions.snowDepthMeters != nil
    }

    var body: some View {
        Group {
            if let conditions, hasApple || hasMarineOrSnowDepth {
                VStack(alignment: .leading, spacing: 9) {
                    Label("Condiciones", systemImage: "cloud.sun")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if conditions.airSource == .appleWeather {
                        sourceHeading("Apple Weather")
                        if let temp = valid(conditions.temperatureC) {
                            row("thermometer", "Temperatura", String(format: "%.0f °C", temp))
                        }
                        if let humidity = valid(conditions.humidity) {
                            row("humidity.fill", "Humedad", String(format: "%.0f %%", humidity * 100))
                        }
                        if let wind = valid(conditions.windKmh) {
                            row("wind", "Viento", String(format: "%.0f km/h", wind))
                        }
                    }
                    if conditions.family == .snow,
                       conditions.snowfallSource == .appleWeather,
                       let snowfall = valid(conditions.snowfallCm), snowfall > 0 {
                        if conditions.airSource != .appleWeather {
                            sourceHeading("Apple Weather")
                        }
                        row("snowflake", "Nevada", String(format: "%.1f cm/h", snowfall))
                    }

                    if hasMarineOrSnowDepth {
                        sourceHeading("Open-Meteo")
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
                        if conditions.family == .snow,
                           let depth = valid(conditions.snowDepthMeters), depth > 0 {
                            row("snowflake", "Nieve acumulada", String(format: "%.0f cm", depth * 100))
                        }
                    }

                    if conditions.family == .water {
                        Text("Mareas orientativas; no usar para navegar")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }

                    if hasApple {
                        AppleWeatherAttributionView(compact: true)
                    }
                    if hasMarineOrSnowDepth {
                        HStack(spacing: 3) {
                            Link("Open-Meteo", destination: URL(string: "https://open-meteo.com/")!)
                            Text("·")
                            Link("CC BY 4.0", destination: URL(string: "https://creativecommons.org/licenses/by/4.0/")!)
                        }
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
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

    private func sourceHeading(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.secondary)
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
