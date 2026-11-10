import ActivityKit
import SwiftUI
import WidgetKit

struct RestLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestActivityAttributes.self) { context in
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.exerciseName)
                        .font(.caption)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    clockText(context.state)
                        .monospacedDigit()
                        .font(.title3.weight(.semibold))
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.pausedRemainingSeconds != nil ? "En pausa" :
                        (context.attributes.sourceKey == nil ? "Descanso" : "Temporizador"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                RestCompactClock(text: clockText(context.state))
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }

    private func clockText(_ state: RestActivityAttributes.ContentState) -> Text {
        if let paused = state.pausedRemainingSeconds {
            let remaining = max(0, paused)
            return Text(String(format: "%02d:%02d", remaining / 60, remaining % 60))
        }
        if let anchor = state.countUpAnchor {
            return Text(.currentDate, format: .stopwatch(
                startingAt: anchor, maxPrecision: .seconds(1)
            ))
        }
        // Fixed time interval: SwiftUI's system timer updates on the lock screen
        // without requiring the host app to wake up and publish new activity state.
        let start = state.endDate.addingTimeInterval(-TimeInterval(max(1, state.totalSeconds)))
        return Text(timerInterval: start...state.endDate, countsDown: true)
    }

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<RestActivityAttributes>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.pausedRemainingSeconds != nil ? "En pausa" :
                    (context.attributes.sourceKey == nil ? "Descanso" : "Temporizador"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(context.attributes.exerciseName)
                    .font(.headline)
                    .lineLimit(1)
            }
            Spacer()
            clockText(context.state)
                .font(.system(.title, design: .rounded, weight: .bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding()
        .activityBackgroundTint(.black.opacity(0.35))
    }
}

/// `Text(timerInterval:)` se dimensiona para el valor más largo posible:
/// el ancho fijo evita que ocupe toda la isla, pero escala con Dynamic Type.
private struct RestCompactClock: View {
    let text: Text
    @ScaledMetric(relativeTo: .body) private var width: CGFloat = 44

    var body: some View {
        text
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(width: min(width, 64))
    }
}

@main
struct ReperaRestWidgetBundle: WidgetBundle {
    var body: some Widget {
        RestLiveActivityWidget()
        TrainingLiveActivityWidget()
        // Sin widget de pantalla de inicio: solo Live Activities + Control Center.
        ReperaBeginControl()
        ReperaTodayControl()
        ReperaTimerControl()
        ReperaBoardScanControl()
    }
}
