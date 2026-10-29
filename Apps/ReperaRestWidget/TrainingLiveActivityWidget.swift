import ActivityKit
import SwiftUI
import WidgetKit

/// Pantalla bloqueada y Dynamic Island: mismo lenguaje visual para actividades
/// deportivas y sesiones planificadas de fuerza, CrossFit, HYROX y similares.
struct TrainingLiveActivityWidget: Widget {
    private let green = Color(red: 0.19, green: 0.82, blue: 0.35)
    private let pauseYellow = Color(red: 1, green: 0.79, blue: 0.0)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TrainingActivityAttributes.self) { context in
            lockScreen(context)
                .widgetURL(destination(for: context.attributes))
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
                    if context.state.phase != .completed,
                       context.state.navigation == nil, !context.state.subtitle.isEmpty {
                        Text(context.state.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
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
    }

    @ViewBuilder
    private func lockScreen(_ context: ActivityViewContext<TrainingActivityAttributes>) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: context.state.phase == .paused ? "pause.fill" : context.state.symbol)
                    .font(.subheadline.weight(.bold))
                Text(context.state.phase == .paused ? "En pausa" :
                     context.state.phase == .completed ? "Finalizado" : context.state.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer(minLength: 6)
            }
            .foregroundStyle(context.state.phase == .paused ? .black : .white)
            .padding(.horizontal, 16)
            // La fila se centra en altura, también cuando hay indicaciones de ruta.
            // minHeight respeta textos más grandes sin recortar el título.
            .frame(
                minHeight: context.state.navigation != nil && context.state.phase != .completed ? 56 : 52,
                alignment: .center
            )
            .background(context.state.phase == .paused ? pauseYellow :
                        context.state.phase == .completed ? green : Color.black)

            if let cue = context.state.navigation,
               context.state.phase != .completed {
                navigationStrip(cue, compact: false)
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
            }

            HStack(alignment: .center, spacing: 0) {
                lockMetric(value: timer(context.state), title: "Duración")
                lockMetric(value: Text(context.state.primaryValue), title: context.state.primaryLabel)
                lockMetric(value: Text(context.state.secondaryValue), title: context.state.secondaryLabel)
            }
            .padding(.horizontal, 14)
            .padding(.top, 16)
            .padding(.bottom, 21)
            .foregroundStyle(.white)
            .background(.black)

            if context.state.phase != .completed, !context.state.subtitle.isEmpty {
                Text(context.state.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                    .background(.black)
            }
        }
        .background(.black)
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
        .padding(.vertical, compact ? 8 : 11)
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
        VStack(alignment: .center, spacing: 5) {
            // El Text dinámico del cronómetro reserva espacio durante su actualización;
            // centrar también SU contenido evita que Duración quede a la izquierda.
            value
                .font(.system(size: 25, weight: .bold, design: .rounded))
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
        URL(string: attributes.isPlanned ? "repera://workout" : "repera://live")
    }
}
