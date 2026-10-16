import ActivityKit
import Foundation

/// Gestiona la Live Activity del descanso entre series.
/// Sin `@MainActor`: `Activity.update/end` son `@concurrent` y chocan con aislamiento estricto.
enum RestLiveActivity {
    private nonisolated(unsafe) static var current: Activity<RestActivityAttributes>?
    private nonisolated(unsafe) static var lastTotalSeconds: Int = 0

    static func start(totalSeconds: Int, exerciseName: String?) {
        endDetached()
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard totalSeconds > 0 else { return }

        let attributes = RestActivityAttributes(exerciseName: exerciseName ?? "Descanso")
        let endDate = Date().addingTimeInterval(TimeInterval(totalSeconds))
        let state = RestActivityAttributes.ContentState(endDate: endDate, totalSeconds: totalSeconds)
        lastTotalSeconds = totalSeconds

        do {
            current = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: endDate),
                pushType: nil
            )
        } catch {
            current = nil
        }
    }

    static func update(remaining: Int) async {
        guard let activity = current else { return }
        let endDate = Date().addingTimeInterval(TimeInterval(max(0, remaining)))
        let state = RestActivityAttributes.ContentState(
            endDate: endDate,
            totalSeconds: lastTotalSeconds
        )
        await activity.update(.init(state: state, staleDate: endDate))
    }

    static func end() async {
        let activity = current
        current = nil
        if let activity {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        for other in Activity<RestActivityAttributes>.activities {
            await other.end(nil, dismissalPolicy: .immediate)
        }
    }

    static func endDetached() {
        let activity = current
        current = nil
        if let activity {
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
