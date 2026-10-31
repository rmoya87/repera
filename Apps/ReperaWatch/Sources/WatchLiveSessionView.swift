import CoreLocation
import ReperaDomain
import SwiftUI
import WatchKit

/// Métricas de actividad iniciada en el reloj (GPS outdoor + HealthKit).
/// Título = navigationTitle; métricas en columna; Finalizar vuelve al hub.
struct WatchLiveSessionView: View {
    @Environment(WatchSessionHub.self) private var hub
    let sport: WatchLiveSport

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
                        WatchHeartRateZoneBar(bpm: hub.heartRateBpm)
                    }
                    WatchLiveMetricRow(
                        label: "kcal",
                        value: hub.measuredEnergyKcal.map { String(format: "%.0f", $0) } ?? "—"
                    )
                }

                if let warning = hub.healthWarning {
                    Text(warning)
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }

                HStack(spacing: 10) {
                    Button {
                        hub.toggleWatchLivePause()
                    } label: {
                        Image(systemName: hub.watchLivePaused ? "play.fill" : "pause.fill")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(accent)
                    .accessibilityLabel(hub.watchLivePaused ? "Reanudar" : "Pausar")

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
            }
            .padding(.horizontal, 6)
        }
        .navigationTitle(sport.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Mute: círculo accent del tint del NavigationStack; icono negro (como Pausar/Finalizar).
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
