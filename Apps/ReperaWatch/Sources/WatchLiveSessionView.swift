import CoreLocation
import ReperaDomain
import SwiftUI
import WatchKit

/// Métricas de actividad iniciada en el reloj (GPS outdoor + HealthKit).
/// El título lo muestra el root junto a la hora; métricas en columna.
struct WatchLiveSessionView: View {
    @Environment(WatchSessionHub.self) private var hub
    let sport: WatchLiveSport
    var onCancelRequest: () -> Void
    @State private var conditions: ActivityConditionsSnapshot?
    @State private var conditionsLoading = false
    @State private var lastConditionsFetch = Date.distantPast

    private let accent = Color(red: 48 / 255, green: 209 / 255, blue: 88 / 255)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if hub.watchLivePaused {
                    Text("En pausa")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.orange)
                }

                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    Text(timeLabel(hub.watchLiveElapsedSeconds))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.55)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 7) {
                    if sport.usesGPS {
                        WatchLiveMetricRow(label: "km", value: distanceValue)
                        if sport.displaysSpeed {
                            WatchLiveMetricRow(label: "km/h", value: speedValue)
                        } else {
                            WatchLiveMetricRow(label: "Ritmo", value: paceValue)
                        }
                        if sport.tracksElevation {
                            WatchLiveMetricRow(label: "Desnivel", value: elevationValue)
                        }
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("FC")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        WatchHeartRateZoneBar(bpm: hub.heartRateBpm, prominent: !sport.usesGPS)
                    }
                    WatchLiveMetricRow(
                        label: "kcal",
                        value: hub.measuredEnergyKcal.map { String(format: "%.0f", $0) } ?? "—",
                        prominent: !sport.usesGPS
                    )
                }

                if let warning = hub.healthWarning {
                    Text(warning)
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }

                // Condiciones antes de controles: Cancelar/Finalizar quedan al final
                // y no se pueden pulsar accidentalmente durante el scroll.
                WatchActivityConditionsBlock(
                    conditions: conditions,
                    loading: conditionsLoading
                )

                HStack(spacing: 10) {
                    Button {
                        onCancelRequest()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(accent)
                    .accessibilityLabel("Cancelar actividad")

                    Button {
                        hub.finishWatchLive()
                    } label: {
                        Image(systemName: "flag.checkered")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(accent)
                    .accessibilityLabel("Finalizar")
                }
                .padding(.bottom, 4)
            }
            .padding(.horizontal, 6)
        }
        .toolbar {
            // Mute: círculo accent del tint del NavigationStack; icono negro.
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    hub.toggleAudioMuted()
                } label: {
                    Image(systemName: hub.audioMuted
                          ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.black)
                        .frame(width: 30, height: 30)
                        .background(accent, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(hub.audioMuted ? "Activar audio" : "Silenciar audio")
            }
        }
        .task(id: hub.watchLiveDistanceMeters) {
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
        let snap = await OpenMeteoConditionsClient.fetch(
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

    private var paceValue: String {
        let meters = hub.watchLiveDistanceMeters
        let seconds = max(1, hub.watchLiveElapsedSeconds)
        guard meters > 20 else { return "—" }
        let pace = (Double(seconds) / meters) * 1000
        let m = Int(pace) / 60
        let s = Int(pace) % 60
        return String(format: "%d'%02d\"", m, s)
    }

    private var speedValue: String {
        let meters = hub.watchLiveDistanceMeters
        let seconds = max(1, hub.watchLiveElapsedSeconds)
        guard meters > 20 else { return "—" }
        let kmh = (meters / Double(seconds)) * 3.6
        return String(format: "%.1f", kmh)
    }

    private var elevationValue: String {
        let gain = hub.watchLiveElevationGainMeters
        guard gain > 0 else { return "—" }
        return String(format: "+%.0f m", gain)
    }

    private func timeLabel(_ total: Int) -> String {
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}

/// Cinco zonas basadas en porcentaje de FCmáx estimada; no son un diagnóstico.
/// Las muestras provienen exclusivamente de HealthKit.
struct WatchHeartRateZoneBar: View {
    var bpm: Int?
    var estimatedMaxBpm: Double = 190
    var prominent: Bool = false

    private let colors: [Color] = [
        Color(red: 0.25, green: 0.55, blue: 1),
        Color(red: 0.20, green: 0.85, blue: 0.40),
        Color(red: 0.95, green: 0.85, blue: 0.15),
        Color(red: 1, green: 0.55, blue: 0.10),
        Color(red: 0.95, green: 0.20, blue: 0.20)
    ]

    private var zone: Int? {
        guard let bpm, (25...250).contains(bpm), estimatedMaxBpm > 0 else { return nil }
        let ratio = Double(bpm) / estimatedMaxBpm
        if ratio < 0.60 { return 1 }
        if ratio < 0.70 { return 2 }
        if ratio < 0.80 { return 3 }
        if ratio < 0.90 { return 4 }
        return 5
    }

    var body: some View {
        HStack(spacing: 7) {
            Text(bpm.map(String.init) ?? "—")
                .font(.system(size: prominent ? 28 : 19, weight: .bold).monospacedDigit())
                .frame(minWidth: prominent ? 50 : 34, alignment: .leading)
            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { level in
                        Capsule()
                            .fill(colors[level - 1])
                            .opacity(zone == level ? 1 : 0.28)
                            .frame(height: zone == level ? 12 : 8)
                    }
                }
                Text(zone.map { "Zona \($0)/5" } ?? "Sin lectura")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            zone.map { "Frecuencia cardíaca \(bpm ?? 0) pulsaciones, zona \($0) de 5" }
            ?? "Frecuencia cardíaca no disponible"
        )
    }
}

/// Fila de métrica en columna: etiqueta pequeña + valor.
struct WatchLiveMetricRow: View {
    let label: String
    let value: String
    var prominent: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .leading)
            Text(value)
                .font(.system(size: prominent ? 28 : 19, weight: .bold).monospacedDigit())
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }
}
