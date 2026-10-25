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
                            reperaMark(isOnYellow: false)
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
                    if !context.state.subtitle.isEmpty {
                        Text(context.state.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.phase == .paused ? "pause.fill" : context.state.symbol)
                    .foregroundStyle(context.state.phase == .paused ? pauseYellow : green)
            } compactTrailing: {
                timer(context.state)
                    .monospacedDigit()
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: true, vertical: false)
            } minimal: {
                Image(systemName: context.state.phase == .paused ? "pause.fill" : context.state.symbol)
                    .foregroundStyle(context.state.phase == .paused ? pauseYellow : green)
            }
            .widgetURL(destination(for: context.attributes))
            .keylineTint(context.state.phase == .paused ? pauseYellow : green)
        }
    }

    /// Símbolo oficial desde el mismo asset del iPhone, incluido en el bundle del widget.
    /// El tint cambia para respetar contraste en la franja de pausa amarilla.
    private func reperaMark(isOnYellow: Bool) -> some View {
        Image("ReperaNativeBarbell")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(isOnYellow ? .black : green)
            .frame(width: 28, height: 25)
            .accessibilityLabel("Repera")
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
                reperaMark(isOnYellow: context.state.phase == .paused)
            }
            .foregroundStyle(context.state.phase == .paused ? .black : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(context.state.phase == .paused ? pauseYellow :
                        context.state.phase == .completed ? green : Color.black)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                lockMetric(value: timer(context.state), title: "Duración")
                lockMetric(value: Text(context.state.primaryValue), title: context.state.primaryLabel)
                lockMetric(value: Text(context.state.secondaryValue), title: context.state.secondaryLabel)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 15)
            .foregroundStyle(.white)
            .background(.black)

            if !context.state.subtitle.isEmpty {
                Text(context.state.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                    .background(.black)
            }
        }
        .background(.black)
    }

    private func timer(_ state: TrainingActivityAttributes.ContentState) -> Text {
        if state.phase == .running {
            return Text(state.timerAnchor, style: .timer)
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
        VStack(spacing: 5) {
            value
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.65)
                .lineLimit(1)
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity)
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
