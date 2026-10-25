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
                                Label("Pausa", systemImage: "pause.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(pauseYellow)
                            }
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            islandMetric(value: timer(context.state), title: "Duración")
                            islandMetric(value: Text(context.state.primaryValue), title: context.state.primaryLabel)
                            islandMetric(value: Text(context.state.secondaryValue), title: context.state.secondaryLabel)
                        }
                    }
                    .padding(.horizontal, 7)
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
                    .font(.caption2.weight(.semibold))
                    .frame(minWidth: 38)
            } minimal: {
                Image(systemName: context.state.phase == .paused ? "pause.fill" : context.state.symbol)
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
                Text("REPERA")
                    .font(.caption2.weight(.bold))
                    .tracking(1.0)
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

    @ViewBuilder
    private func timer(_ state: TrainingActivityAttributes.ContentState) -> some View {
        if state.phase == .running {
            Text(state.timerAnchor, style: .timer)
                .monospacedDigit()
        } else {
            Text(timeString(state.elapsedSeconds))
                .monospacedDigit()
        }
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
