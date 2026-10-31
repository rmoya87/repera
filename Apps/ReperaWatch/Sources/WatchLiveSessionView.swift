import CoreLocation
import ReperaDomain
import SwiftUI
import WatchKit

/// Métricas de actividad iniciada en el reloj (GPS outdoor + HealthKit).
/// Título = navigationTitle; métricas en columna; Finalizar vuelve al hub.
struct WatchLiveSessionView: View {
    @Environment(WatchSessionHub.self) private var hub
    let sport: WatchLiveSport
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

                // Condiciones antes de controles: al hacer scroll, Pausar/Finalizar
                // quedan al final (nunca «atrapado» solo con Condiciones).
                WatchActivityConditionsBlock(
                    conditions: conditions,
                    loading: conditionsLoading
                )

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
                .padding(.bottom, 4)
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

/// FC a la izquierda + barra de zonas a la derecha (azul→verde→amarillo→naranja→rojo).
/// Escala relativa a una FCmáx estimada (190) cuando no hay perfil de edad.
struct WatchHeartRateZoneBar: View {
    var bpm: Int?
    /// Estimación conservadora si no hay edad del usuario en el Watch.
    var estimatedMaxBpm: Double = 190

    /// Aproximación relativa; no son las zonas personales de Salud.
    private var estimatedZone: Int? {
        guard let bpm, bpm > 0, estimatedMaxBpm > 0 else { return nil }
        let fraction = Double(bpm) / estimatedMaxBpm
        switch fraction {
        case ..<0.60: return 1
        case ..<0.70: return 2
        case ..<0.80: return 3
        case ..<0.90: return 4
        default: return 5
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(bpm.map { "\($0)" } ?? "—")
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(.primary)
                .frame(minWidth: 36, alignment: .leading)
                .accessibilityLabel(bpm.map { "Frecuencia cardíaca \($0)" } ?? "Sin frecuencia cardíaca")
            Text(estimatedZone.map { "Z\($0)" } ?? "—")
                .font(.caption2.weight(.bold).monospacedDigit())
                .foregroundStyle(.secondary)
                .accessibilityLabel(estimatedZone.map { "Zona estimada \($0)" } ?? "Sin zona disponible")

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
