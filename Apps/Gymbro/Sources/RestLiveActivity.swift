import ActivityKit
import Foundation
import os

/// Serializes Live Activity start/end on the main actor.
/// End date is fixed at start — the system renders the countdown (no per-second updates).
@MainActor
final class RestLiveActivityCoordinator {
    static let shared = RestLiveActivityCoordinator()

    private var current: Activity<RestActivityAttributes>?
    private let logger = Logger(subsystem: "app.gymbroapp.ios", category: "RestLiveActivity")

    func start(totalSeconds: Int, endDate: Date, exerciseName: String?) async {
        await end()
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard totalSeconds > 0 else { return }

        let attributes = RestActivityAttributes(exerciseName: exerciseName ?? "Descanso")
        let state = RestActivityAttributes.ContentState(endDate: endDate, totalSeconds: totalSeconds)
        do {
            current = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: endDate),
                pushType: nil
            )
        } catch {
            logger.error("Live Activity request failed: \(String(describing: error), privacy: .public)")
            current = nil
        }
    }

    func end() async {
        current = nil
        // End via the system activity list to avoid sending a stored Activity across isolation.
        for activity in Activity<RestActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}

/// Compatibility façade for call sites that still use the old enum name.
enum RestLiveActivity {
    static func start(totalSeconds: Int, exerciseName: String?) {
        let endDate = Date().addingTimeInterval(TimeInterval(totalSeconds))
        Task { @MainActor in
            await RestLiveActivityCoordinator.shared.start(
                totalSeconds: totalSeconds,
                endDate: endDate,
                exerciseName: exerciseName
            )
        }
    }

    static func end() async {
        await RestLiveActivityCoordinator.shared.end()
    }

    static func endDetached() {
        Task { @MainActor in
            await RestLiveActivityCoordinator.shared.end()
        }
    }
}
