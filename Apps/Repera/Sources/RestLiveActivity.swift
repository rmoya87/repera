import ActivityKit
import Foundation
import os

/// Serializes Live Activity start/end on the main actor.
/// Generation token prevents a stale `end()` from killing a newer rest session.
/// End via `Activity.activities` to avoid sending a stored `Activity` across isolation.
@MainActor
final class RestLiveActivityCoordinator {
    static let shared = RestLiveActivityCoordinator()

    private var current: Activity<RestActivityAttributes>?
    private var generation: UInt64 = 0
    private let logger = Logger(subsystem: "com.app.repera", category: "RestLiveActivity")

    func start(totalSeconds: Int, endDate: Date, exerciseName: String?) async {
        generation &+= 1
        let gen = generation
        await endAllActivities()
        guard gen == generation else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard totalSeconds > 0 else { return }

        let attributes = RestActivityAttributes(exerciseName: exerciseName ?? "Descanso")
        let state = RestActivityAttributes.ContentState(endDate: endDate, totalSeconds: totalSeconds)
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: endDate),
                pushType: nil
            )
            guard gen == generation else {
                await endAllActivities()
                return
            }
            current = activity
        } catch {
            logger.error("Live Activity request failed: \(String(describing: error), privacy: .public)")
            current = nil
        }
    }

    func end() async {
        generation &+= 1
        current = nil
        await endAllActivities()
    }

    private func endAllActivities() async {
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
