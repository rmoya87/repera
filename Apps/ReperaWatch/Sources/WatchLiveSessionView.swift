import CoreLocation
import ReperaDomain
import SwiftUI
import WatchKit

/// Métricas de actividad iniciada en el reloj (GPS outdoor + HealthKit).
/// El título lo muestra el root junto a la hora; métricas en columna.
struct WatchLiveSessionView: View {
    @Environment(WatchSessionHub.self) private var hub
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    let sport: WatchLiveSport
    var onCancelRequest: () -> Void
    @State private var conditions: ActivityConditionsSnapshot?
    @State private var conditionsLoading = false
    @State private var lastConditionsFetch = Date.distantPast

    private var accent: Color { WatchTheme.accent }

    var body: some View {
        WatchSwipeControlSurface {
        // Sin ScrollView: números grandes + Spacers entre filas (no hueco muerto bajo LPM).
        GeometryReader { geo in
            let scale = WatchLiveMetricScale.fit(
                height: geo.size.height,
                luminanceReduced: isLuminanceReduced
            )
            VStack(alignment: .leading, spacing: 0) {
                if hub.watchLivePaused && !isLuminanceReduced {
                    Text("En pausa")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(WatchTheme.warning)
                }

                // Tiempo solo; km/kcal van debajo en outdoor.
                TimelineView(.periodic(from: .now, by: isLuminanceReduced ? 60 : 1)) { _ in
                    Text(timeLabel(hub.watchLiveElapsedSeconds))
                        .font(.system(size: scale.time, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if sport.usesGPS {
                    Spacer(minLength: scale.gap)
                    WatchOutdoorMetricsBlock(
                        lastKmValue: lastKmValue,
                        averageValue: averageOutdoorValue,
                        averageLabel: sport.displaysSpeed ? "media" : "ritmo medio",
                        valueSize: scale.split
                    )
                    Spacer(minLength: scale.gap)
                    WatchOutdoorKmKcalRow(
                        kmValue: distanceValue,
                        kcalValue: String(format: "%.0f", hub.displayedEnergyKcal),
                        valueSize: scale.inline
                    )
                    Spacer(minLength: scale.gap)
                    WatchHeartRateZoneMetric(prominent: false, valueSize: scale.heart)
                } else {
                    Spacer(minLength: scale.gap)
                    WatchHeartRateZoneMetric(prominent: true, valueSize: scale.heart)
                    Spacer(minLength: scale.gap)
                    WatchLiveMetricInline(
                        label: "Kcal",
                        value: String(format: "%.0f", hub.displayedEnergyKcal),
                        valueSize: scale.inline
                    )
                }

                if !isLuminanceReduced, let warning = hub.healthWarning {
                    Text(warning)
                        .font(.caption2)
                        .foregroundStyle(WatchTheme.warning)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .padding(.top, 2)
                }

                if !isLuminanceReduced {
                    WatchActivityConditionsBlock(
                        conditions: conditions,
                        loading: conditionsLoading
                    )
                }
            }
            .padding(.horizontal, 5)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
        } controls: {
            if !isLuminanceReduced {
                WatchSessionControlsGrid(
                    isPaused: hub.watchLivePaused,
                    audioMuted: hub.audioMuted,
                    accent: accent,
                    onPauseResume: { hub.toggleWatchLivePause() },
                    onFinish: { hub.finishWatchLive() },
                    onCancel: onCancelRequest,
                    onToggleAudio: { hub.toggleAudioMuted() }
                )
            }
        }
        .task(id: hub.watchLiveDistanceMeters) {
            guard !isLuminanceReduced else { return }
            await refreshConditionsIfNeeded()
        }
    }

    private func refreshConditionsIfNeeded() async {
        let family = ActivityConditionsSnapshot.family(forLiveSportID: sport.rawValue)
        guard family != .none else { return }
        guard Date().timeIntervalSince(lastConditionsFetch) > 12 * 60 || conditions == nil else {
            return
        }
        guard let point = hub.watchLiveLastCoordinate else { return }
        conditionsLoading = conditions == nil
        lastConditionsFetch = Date()
        let snap = await AppleWeatherConditionsClient.fetch(
            latitude: point.latitude,
            longitude: point.longitude,
            sportID: sport.rawValue
        )
        conditions = snap
        conditionsLoading = false
    }

    private var distanceValue: String {
        let km = hub.watchLiveDistanceMeters / 1000
        guard km > 0 else { return "—" }
        return String(format: "%.2f", km)
    }

    private var lastKmValue: String {
        WatchOutdoorMetricFormat.duration(
            seconds: hub.displayedLastKilometerSeconds
        )
    }

    private var averageOutdoorValue: String {
        if sport.displaysSpeed {
            return WatchOutdoorMetricFormat.averageSpeedKmh(
                meters: hub.watchLiveDistanceMeters,
                elapsedSeconds: hub.watchLiveElapsedSeconds
            )
        }
        return WatchOutdoorMetricFormat.averagePace(
            meters: hub.watchLiveDistanceMeters,
            elapsedSeconds: hub.watchLiveElapsedSeconds
        )
    }

    private func timeLabel(_ total: Int) -> String {
        WatchOutdoorMetricFormat.clock(total)
    }
}

/// Escala de números live según altura útil (labels fijos, no escalan).
struct WatchLiveMetricScale {
    let time: CGFloat
    let split: CGFloat
    let inline: CGFloat
    let heart: CGFloat
    let gap: CGFloat

    static func fit(height: CGFloat, luminanceReduced: Bool) -> WatchLiveMetricScale {
        let h = max(height, 110)
        // Tiempo ~⅓ más grande que la escala base; resto proporcional. Ambient un poco más contenido.
        let time = min(luminanceReduced ? 67 : 77, max(luminanceReduced ? 59 : 69, h * 0.45))
        let split = min(luminanceReduced ? 32 : 38, max(luminanceReduced ? 28 : 34, h * 0.19))
        let inline = min(luminanceReduced ? 28 : 34, max(luminanceReduced ? 24 : 30, h * 0.16))
        let heart = min(luminanceReduced ? 28 : 32, max(luminanceReduced ? 24 : 28, h * 0.15))
        let gap = min(8, max(3, h * 0.03))
        return WatchLiveMetricScale(
            time: time.rounded(),
            split: split.rounded(),
            inline: inline.rounded(),
            heart: heart.rounded(),
            gap: gap.rounded()
        )
    }
}

/// Dos columnas: valor grande + etiqueta a la derecha en dos líneas
/// (misma altura que el número). p. ej. «último / km», «ritmo / medio».
struct WatchOutdoorMetricsBlock: View {
    let lastKmValue: String
    let averageValue: String
    let averageLabel: String
    var centered: Bool = false
    var valueSize: CGFloat = 36

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            WatchOutdoorSplitCell(
                value: lastKmValue, label: "último km", centered: centered, valueSize: valueSize
            )
            WatchOutdoorSplitCell(
                value: averageValue, label: averageLabel, centered: centered, valueSize: valueSize
            )
        }
        .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
    }
}

/// km (izq.) y Kcal (der.) en las mismas columnas que último km / ritmo medio.
struct WatchOutdoorKmKcalRow: View {
    let kmValue: String
    let kcalValue: String
    var centered: Bool = false
    var valueSize: CGFloat = 32

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            WatchLiveMetricInline(label: "km", value: kmValue, valueSize: valueSize)
                .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
            WatchLiveMetricInline(label: "Kcal", value: kcalValue, valueSize: valueSize)
                .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
        }
    }
}

private struct WatchOutdoorSplitCell: View {
    let value: String
    let label: String
    var centered: Bool = false
    var valueSize: CGFloat = 36

    /// «último km» → [último, km]; «ritmo medio» → [ritmo, medio].
    private var labelLines: [String] {
        let parts = label.split(whereSeparator: \.isWhitespace).map(String.init)
        guard parts.count >= 2 else { return [label] }
        return [parts[0], parts.dropFirst().joined(separator: " ")]
    }

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Text(value)
                .font(.system(size: valueSize, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.55)
                .lineLimit(1)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(labelLines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(height: valueSize, alignment: .center)
        }
        .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(value)")
    }
}

enum WatchOutdoorMetricFormat {
    static func clock(_ total: Int) -> String {
        let n = max(0, total)
        let h = n / 3600
        let m = (n % 3600) / 60
        let s = n % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }

    static func duration(seconds: Int?) -> String {
        guard let seconds, seconds > 0 else { return "—" }
        return clock(seconds)
    }

    static func averagePace(meters: Double, elapsedSeconds: Int) -> String {
        guard meters > 20, elapsedSeconds > 0 else { return "—" }
        let pace = (Double(elapsedSeconds) / meters) * 1000
        let whole = Int(pace.rounded())
        return String(format: "%d'%02d\"", whole / 60, whole % 60)
    }

    static func averageSpeedKmh(meters: Double, elapsedSeconds: Int) -> String {
        guard meters > 20, elapsedSeconds > 0 else { return "—" }
        let kmh = (meters / Double(elapsedSeconds)) * 3.6
        return String(format: "%.1f", kmh)
    }

    /// Último km cerrado, o proyección del km en curso (≥40 m).
    static func lastKilometerSeconds(
        completedSeconds: Int?,
        meters: Double,
        elapsedSeconds: Int,
        completedKilometers: Int,
        boundaryElapsedSeconds: Int
    ) -> Int? {
        if let completedSeconds, completedSeconds > 0 { return completedSeconds }
        let metersInKm = meters - Double(completedKilometers) * 1000
        let elapsedInKm = elapsedSeconds - boundaryElapsedSeconds
        guard metersInKm >= 40, elapsedInKm > 0 else { return nil }
        return max(1, Int((Double(elapsedInKm) / metersInKm * 1000).rounded()))
    }
}


/// Fixed-size heart-rate area shared by planned, recording and free live workouts.
/// No FC title. Always On: same zone bar, attenuated, slow cadence.
struct WatchHeartRateZoneMetric: View {
    @Environment(WatchSessionHub.self) private var hub
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    var prominent: Bool = false
    var valueSize: CGFloat? = nil

    var body: some View {
        TimelineView(.periodic(from: .now, by: isLuminanceReduced ? 60 : 1)) { context in
            WatchHeartRateZoneBar(
                bpm: hub.heartRateBpm(at: context.date),
                prominent: prominent && !isLuminanceReduced,
                attenuated: isLuminanceReduced,
                valueSize: valueSize
            )
        }
    }
}

/// Cinco zonas basadas en porcentaje de FCmáx estimada; no son un diagnóstico.
/// Layout: bpm · LPM · barras. Sin texto «Zona N/5».
struct WatchHeartRateZoneBar: View {
    @AppStorage("repera.watch.heartRate.maxBpm") private var personalMaxBpm = 190
    var bpm: Int?
    var estimatedMaxBpm: Double? = nil
    var prominent: Bool = false
    /// Always On / luminance reduced: keep the bar, dim it, never remove it.
    var attenuated: Bool = false
    var centered: Bool = false
    /// Tamaño del número; el label «LPM» no escala.
    var valueSize: CGFloat? = nil

    private let colors: [Color] = [
        Color(red: 0.25, green: 0.55, blue: 1),
        Color(red: 0.20, green: 0.85, blue: 0.40),
        Color(red: 0.95, green: 0.85, blue: 0.15),
        Color(red: 1, green: 0.55, blue: 0.10),
        Color(red: 0.95, green: 0.20, blue: 0.20)
    ]

    private var bpmSize: CGFloat {
        valueSize ?? (prominent ? 30 : 26)
    }

    private var zone: Int? {
        let maxBpm = estimatedMaxBpm ?? Double(personalMaxBpm)
        guard let bpm, (25...250).contains(bpm), maxBpm > 0 else { return nil }
        let ratio = Double(bpm) / maxBpm
        if ratio < 0.60 { return 1 }
        if ratio < 0.70 { return 2 }
        if ratio < 0.80 { return 3 }
        if ratio < 0.90 { return 4 }
        return 5
    }

    private var accessibilityDescription: String {
        guard let bpm, let zone else {
            return "Esperando la primera lectura de frecuencia cardíaca"
        }
        return "Frecuencia cardíaca \(bpm) pulsaciones por minuto, zona \(zone) de 5"
    }

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(bpm.map(String.init) ?? "—")
                    .font(.system(size: bpmSize, weight: .bold).monospacedDigit())
                Text("LPM")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { level in
                    Capsule()
                        .fill(colors[level - 1])
                        .opacity(zone == level ? (attenuated ? 0.72 : 1) : (attenuated ? 0.10 : 0.16))
                        .frame(height: zone == level ? (attenuated ? 10 : 12) : 8)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
        .opacity(attenuated ? 0.72 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }
}

/// Valor + etiqueta pegados, alineados a la izquierda (Watch rectangular).
struct WatchLiveMetricInline: View {
    let label: String
    let value: String
    var prominent: Bool = false
    /// Si se pasa, fija el número; el label (caption2) no cambia.
    var valueSize: CGFloat? = nil

    private var resolvedValueSize: CGFloat {
        valueSize ?? (prominent ? 28 : 22)
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value)
                .font(.system(size: resolvedValueSize, weight: .bold).monospacedDigit())
                .minimumScaleFactor(0.65)
                .lineLimit(1)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }
}

/// Alias de compatibilidad con filas legacy (mismo layout inline).
struct WatchLiveMetricRow: View {
    let label: String
    let value: String
    var prominent: Bool = false

    var body: some View {
        WatchLiveMetricInline(label: label, value: value, prominent: prominent)
    }
}
