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
                    Text(timerInterval: Date()...context.state.endDate, countsDown: true)
                        .monospacedDigit()
                        .font(.title3.weight(.semibold))
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("Descanso")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                Text(timerInterval: Date()...context.state.endDate, countsDown: true)
                    .monospacedDigit()
                    .frame(width: 44)
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<RestActivityAttributes>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Descanso")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(context.attributes.exerciseName)
                    .font(.headline)
                    .lineLimit(1)
            }
            Spacer()
            Text(timerInterval: Date()...context.state.endDate, countsDown: true)
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
