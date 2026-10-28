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
                    Text(context.state.pausedRemainingSeconds == nil ? "Descanso" : "En pausa")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                clockText(context.state)
                    .monospacedDigit()
                    .frame(width: 44)
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
        // Fixed time interval: SwiftUI's system timer updates on the lock screen
        // without requiring the host app to wake up and publish new activity state.
        let start = state.endDate.addingTimeInterval(-TimeInterval(max(1, state.totalSeconds)))
        return Text(timerInterval: start...state.endDate, countsDown: true)
    }

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<RestActivityAttributes>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.pausedRemainingSeconds == nil ? "Descanso" : "En pausa")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(context.attributes.exerciseName)
                    .font(.headline)
                    .lineLimit(1)
            }
            Spacer()
            clockText(context.state)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
        .padding()
        .activityBackgroundTint(.black.opacity(0.35))
    }
}

@main
struct ReperaRestWidgetBundle: WidgetBundle {
    var body: some Widget {
        RestLiveActivityWidget()
        TrainingLiveActivityWidget()
    }
}
