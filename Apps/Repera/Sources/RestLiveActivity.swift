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
                content: .init(state: state, staleDate: nil),
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

    func pause(remainingSeconds: Int) async {
        let remaining = max(0, remainingSeconds)
        for activity in Activity<RestActivityAttributes>.activities where activity.attributes.sourceKey == nil || activity.attributes.sourceKey == "rest" {
            var state = activity.content.state
            state.pausedRemainingSeconds = remaining
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    func resume(totalSeconds: Int, endDate: Date, exerciseName: String?) async {
        let active = Activity<RestActivityAttributes>.activities
        guard let activity = active.first(where: {
            $0.attributes.sourceKey == nil || $0.attributes.sourceKey == "rest"
        }) else {
            await start(totalSeconds: totalSeconds, endDate: endDate, exerciseName: exerciseName)
            return
        }
        let state = RestActivityAttributes.ContentState(
            endDate: endDate, totalSeconds: totalSeconds
        )
        await activity.update(ActivityContent(state: state, staleDate: nil))
        current = activity
    }

    func end() async {
        generation &+= 1
        current = nil
        await endAllActivities()
    }

    private func endAllActivities() async {
        for activity in Activity<RestActivityAttributes>.activities where activity.attributes.sourceKey == nil || activity.attributes.sourceKey == "rest" {
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

 
/// Uses the same ActivityKit widget as rest, but owns the standalone and
/// workout-block clocks independently so the rest timer cannot dismiss them.
@MainActor
final class TimerLiveActivityCoordinator {
    enum Source: String, Hashable {
        case standalone
        case workout
    }

    static let shared = TimerLiveActivityCoordinator()
    private var generations: [Source: UInt64] = [:]
    private let logger = Logger(subsystem: "com.app.repera", category: "TimerLiveActivity")

    func countdown(
        _ source: Source, endDate: Date, totalSeconds: Int, title: String
    ) {
        scheduleUpdate(
            source, title: title,
            state: .init(endDate: endDate, totalSeconds: max(1, totalSeconds))
        )
    }

    func countUp(_ source: Source, anchor: Date, title: String) {
        scheduleUpdate(
            source, title: title,
            state: .init(endDate: anchor, totalSeconds: 0, countUpAnchor: anchor)
        )
    }

    func pause(_ source: Source, value: Int, title: String) {
        generations[source, default: 0] &+= 1
        let token = generations[source, default: 0]
        Task { @MainActor in
            guard self.generations[source] == token else { return }
            for activity in Activity<RestActivityAttributes>.activities
            where activity.attributes.sourceKey == source.rawValue {
                var state = activity.content.state
                state.pausedRemainingSeconds = max(0, value)
                state.countUpAnchor = nil
                await activity.update(.init(state: state, staleDate: nil))
            }
        }
    }

    func end(_ source: Source) {
        generations[source, default: 0] &+= 1
        let token = generations[source, default: 0]
        Task { @MainActor in
            guard self.generations[source] == token else { return }
            for activity in Activity<RestActivityAttributes>.activities
            where activity.attributes.sourceKey == source.rawValue {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    private func scheduleUpdate(
        _ source: Source, title: String, state: RestActivityAttributes.ContentState
    ) {
        generations[source, default: 0] &+= 1
        let token = generations[source, default: 0]
        Task { @MainActor in
            guard self.generations[source] == token,
                  ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            if let activity = Activity<RestActivityAttributes>.activities.first(where: {
                $0.attributes.sourceKey == source.rawValue
            }) {
                await activity.update(.init(state: state, staleDate: nil))
            } else {
                do {
                    _ = try Activity.request(
                        attributes: RestActivityAttributes(
                            exerciseName: title, sourceKey: source.rawValue
                        ),
                        content: .init(state: state, staleDate: nil),
                        pushType: nil
                    )
                } catch {
                    logger.error("Timer Live Activity failed: \\(String(describing: error), privacy: .public)")
                }
            }
        }
    }
}
