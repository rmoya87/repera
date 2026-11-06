import ActivityKit
import SwiftUI
import WidgetKit

/// Selección de layout dentro de una View (no dentro del Widget).
private struct TrainingFamilySwitcher<Regular: View, Compact: View>: View {
    @Environment(\.activityFamily) private var activityFamily
    let regular: Regular
    let compact: Compact

    @ViewBuilder
    var body: some View {
        if activityFamily == .small { compact }
        else { regular }
    }
}

/// Pantalla bloqueada y Dynamic Island: mismo lenguaje visual para actividades
/// deportivas y sesiones planificadas de fuerza, CrossFit, HYROX y similares.
struct TrainingLiveActivityWidget: Widget {
    private let green = Color(red: 0.19, green: 0.82, blue: 0.35)
    private let pauseYellow = Color(red: 1, green: 0.79, blue: 0.0)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TrainingActivityAttributes.self) { context in
            TrainingFamilySwitcher(
                regular: lockScreen(context)
                    .widgetURL(destination(for: context.attributes)),
                // watchOS must launch its installed native app, not repera:// on iPhone.
                compact: watchSmartStack(context)
                    .widgetURL(URL(string: "repera-watch://active"))
            )
                .activityBackgroundTint(.black)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 6) {
                        HStack(spacing: 7) {
                            Image(systemName: context.state.symbol)
                                .foregroundStyle(context.state.phase == .paused ? pauseYellow : green)
                            Text(context.state.title)
                                .lineLimit(1)
                                .font(.headline)
                            Spacer(minLength: 4)
                            if context.state.phase == .paused {
                                Image(systemName: "pause.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(pauseYellow)
                                    .accessibilityLabel("En pausa")
                            }
                        }
                        if let cue = context.state.navigation,
                           context.state.phase != .completed {
                            navigationStrip(cue, compact: true)
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            islandMetric(value: timer(context.state), title: "Duración")
                            islandMetric(value: Text(context.state.primaryValue), title: context.state.primaryLabel)
                            islandMetric(value: Text(context.state.secondaryValue), title: context.state.secondaryLabel)
                        }
                    }
                    .padding(.horizontal, 3)
                    .padding(.top, 2)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        if context.state.phase != .completed,
                           context.state.navigation == nil, !context.state.subtitle.isEmpty {
                            if !context.attributes.isPlanned {
                                splitStrip(context.state.subtitle, compact: true)
                            } else {
                                Text(context.state.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        if context.state.phase != .completed {
                            if context.attributes.sessionID.hasPrefix("watch:") {
                                Text("Control desde Apple Watch")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            } else {
                                liveActivityControls(
                                    phase: context.state.phase,
                                    isPlanned: context.attributes.isPlanned
                                )
                            }
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.navigation?.symbol ??
                    (context.state.phase == .paused ? "pause.fill" : context.state.symbol))
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(context.state.phase == .paused ? pauseYellow : green)
                    .frame(width: 26, height: 20, alignment: .center)
                    .accessibilityHidden(true)
            } compactTrailing: {
                // La anchura de .timer es expansiva si se mide sin restricciones.
                // Un ancho compacto explícito impide que el widget reclame
                // espacio extra en la Dynamic Island para duraciones largas.
                Group {
                    if let meters = context.state.navigation?.distanceMeters {
                        Text(distanceLabel(meters))
                    } else {
                        timer(context.state)
                    }
                }
                    .monospacedDigit()
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .frame(width: 44, alignment: .trailing)
            } minimal: {
                Image(systemName: context.state.navigation?.symbol ??
                    (context.state.phase == .paused ? "pause.fill" : context.state.symbol))
                    .foregroundStyle(context.state.phase == .paused ? pauseYellow : green)
            }
            .widgetURL(destination(for: context.attributes))
            .keylineTint(context.state.phase == .paused ? pauseYellow : green)
        }
        .supplementalActivityFamilies([.small])
    }

    /// Live Activity del iPhone adaptada a la Smart Stack del Apple Watch.
    /// Al tocarla, WKSupportsLiveActivityLaunchAttributeTypes abre Repera Watch.
    private func watchSmartStack(_ context: ActivityViewContext<TrainingActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: context.state.phase == .paused ? "pause.fill" : context.state.symbol)
                    .foregroundStyle(context.state.phase == .paused ? pauseYellow : green)
                Text(context.state.title).font(.headline).lineLimit(1)
                Spacer(minLength: 0)
            }
            if let navigation = context.state.navigation, context.state.phase != .completed {
                HStack(spacing: 6) {
                    Image(systemName: navigation.symbol)
                    Text(navigation.instruction).lineLimit(1)
                    if let distance = navigation.distanceMeters {
                        Text(distanceLabel(distance)).monospacedDigit()
                    }
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(green)
            }
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                islandMetric(value: timer(context.state), title: "Tiempo")
                islandMetric(value: Text(context.state.primaryValue), title: context.state.primaryLabel)
                islandMetric(value: Text(context.state.secondaryValue), title: context.state.secondaryLabel)
            }
            if !context.state.subtitle.isEmpty {
                if context.attributes.isPlanned {
                    Text(context.state.subtitle)
                        .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                } else {
                    splitStrip(context.state.subtitle, compact: true)
                }
            }
        }
        .foregroundStyle(.white)
        .padding(12)
        .background(.black)
    }

    @ViewBuilder
    private func lockScreen(_ context: ActivityViewContext<TrainingActivityAttributes>) -> some View {
        let hasNavigation = context.state.navigation != nil && context.state.phase != .completed
        let active = context.state.phase != .completed
        VStack(spacing: 0) {
            // Keep the title inside ActivityKit's limited height (no fixed minimum).
            HStack(spacing: 8) {
                Image(systemName: context.state.phase == .paused ? "pause.circle.fill" : context.state.symbol)
                    .font(.subheadline.weight(.semibold))
                Text(context.state.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }
            .foregroundStyle(context.state.phase == .paused ? pauseYellow : .white)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 5)

            if let cue = context.state.navigation, active {
                navigationStrip(cue, compact: true)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 3)
            }

            HStack(alignment: .center, spacing: 0) {
                lockMetric(value: timer(context.state), title: "Duración")
                lockMetric(value: Text(context.state.primaryValue), title: context.state.primaryLabel)
                lockMetric(value: Text(context.state.secondaryValue), title: context.state.secondaryLabel)
            }
            .padding(.horizontal, 16)
            .padding(.top, hasNavigation ? 5 : 8)
            .padding(.bottom, 7)
            .foregroundStyle(.white)

            // Optional single-line split goes BEFORE actions; omit it when long.
            // Never sacrifice the title, metrics or actions to ActivityKit clipping.
            if active, !hasNavigation, !context.attributes.isPlanned,
               !context.state.subtitle.isEmpty, context.state.subtitle.count <= 36 {
                Text(context.state.subtitle)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
            } else if active, !hasNavigation, context.attributes.isPlanned,
                      !context.state.subtitle.isEmpty {
                Text(context.state.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
            }

            // Last element on the card, with symmetric side and bottom insets.
            if active {
                Group {
                    if context.attributes.sessionID.hasPrefix("watch:") {
                        Text("Control desde Apple Watch")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.75))
                            .frame(maxWidth: .infinity)
                    } else {
                        liveActivityControls(
                            phase: context.state.phase,
                            isPlanned: context.attributes.isPlanned
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 12)
            } else {
                Color.clear.frame(height: 12)
            }
        }
        .background(.black)
    }

    /// One compact line; do not add a second "TRAMO" header or a tall card.
    private func splitStrip(_ text: String, compact: Bool) -> some View {
        Text(text)
            .font(.system(size: compact ? 10 : 11, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.85))
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, compact ? 7 : 10)
            .padding(.vertical, 5)
            .background(.white.opacity(0.07),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    /// Giro/calle para ruta GPX. Se adapta al ancho del bloqueo y la isla
    /// expandida, sin desplazar las tres métricas de la sesión.
    private func navigationStrip(
        _ cue: TrainingActivityAttributes.ContentState.NavigationCue,
        compact: Bool
    ) -> some View {
        HStack(spacing: compact ? 8 : 12) {
            Image(systemName: cue.symbol)
                .font(.system(size: compact ? 22 : 31, weight: .bold))
                .frame(width: compact ? 28 : 38)
            VStack(alignment: .leading, spacing: 3) {
                Text(cue.instruction)
                    .font(.system(size: compact ? 14 : 17, weight: .bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                if let street = cue.street {
                    Text("Hacia \(street)")
                        .font(.system(size: compact ? 11 : 13, weight: .medium))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let distance = cue.distanceMeters {
                Text(distanceLabel(distance))
                    .font(.system(size: compact ? 13 : 17, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .foregroundStyle(.black)
        .padding(.horizontal, compact ? 9 : 12)
        // Menos altura en bloqueo: evita recortar las etiquetas inferiores.
        // La isla expandida mantiene sus márgenes compactos originales.
        .padding(.vertical, 8)
        .background(green, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func distanceLabel(_ meters: Int) -> String {
        meters >= 1_000
            ? String(format: "%.1f km", Double(meters) / 1_000)
            : "\(max(0, meters)) m"
    }

    private func timer(_ state: TrainingActivityAttributes.ContentState) -> Text {
        if state.phase == .running {
            // Stopwatch de iOS 27: segundos reales (00:07, 01:23, …)
            // en lugar del tiempo relativo «menos de un minuto».
            return Text(
                .currentDate,
                format: .stopwatch(startingAt: state.timerAnchor,
                                   maxPrecision: .seconds(1))
            )
        }
        return Text(timeString(state.elapsedSeconds))
    }

    private func timeString(_ total: Int) -> String {
        let seconds = max(total, 0)
        if seconds >= 3600 {
            return String(format: "%d:%02d:%02d", seconds / 3600, (seconds / 60) % 60, seconds % 60)
        }
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func lockMetric(value: Text, title: String) -> some View {
        VStack(alignment: .center, spacing: 3) {
            // El Text dinámico del cronómetro reserva espacio durante su actualización;
            // centrar también SU contenido evita que Duración quede a la izquierda.
            value
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.65)
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func islandMetric(value: Text, title: String) -> some View {
        VStack(spacing: 4) {
            value
                .font(.system(size: 23, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.65)
                .lineLimit(1)
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .minimumScaleFactor(0.65)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func destination(for attributes: TrainingActivityAttributes) -> URL? {
        // A Watch-owned workout has no phone-side pause/resume controller.
        URL(string: attributes.sessionID.hasPrefix("watch:")
            ? "repera://today"
            : (attributes.isPlanned ? "repera://workout" : "repera://live"))
    }

    /// Controls must be the last row. They only enqueue actions for the app,
    /// never create another workout or write HealthKit from the extension.
    @ViewBuilder
    private func liveActivityControls(
        phase: TrainingActivityAttributes.ContentState.Phase,
        isPlanned: Bool
    ) -> some View {
        HStack(spacing: 9) {
            if !isPlanned {
                if phase == .paused {
                    Button(intent: TrainingResumeLiveActivityIntent()) {
                        Label("Reanudar", systemImage: "play.circle.fill")
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                    }
                    .tint(pauseYellow)
                    .foregroundStyle(.black)
                    .buttonStyle(.borderedProminent)
                } else if phase == .running {
                    Button(intent: TrainingPauseLiveActivityIntent()) {
                        Label("Pausar", systemImage: "pause.circle.fill")
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                    }
                    .tint(pauseYellow)
                    .foregroundStyle(.black)
                    .buttonStyle(.borderedProminent)
                }
            }
            Button(intent: TrainingOpenSessionLiveActivityIntent()) {
                Label("Abrir Repera", systemImage: "arrow.up.forward.app")
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .frame(maxWidth: .infinity)
            }
            .tint(green)
            .foregroundStyle(.black)
            .buttonStyle(.borderedProminent)
        }
    }
}
