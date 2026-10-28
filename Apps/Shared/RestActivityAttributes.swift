import ActivityKit
import Foundation

/// Atributos compartidos app + widget para el timer de descanso.
public struct RestActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var endDate: Date
        public var totalSeconds: Int
        /// When paused, render a fixed value instead of advancing an expired deadline.
        public var pausedRemainingSeconds: Int?
        /// Optional anchor for stopwatch-style timers (count-up).
        public var countUpAnchor: Date?

        public init(endDate: Date, totalSeconds: Int, pausedRemainingSeconds: Int? = nil, countUpAnchor: Date? = nil) {
            self.endDate = endDate
            self.totalSeconds = totalSeconds
            self.pausedRemainingSeconds = pausedRemainingSeconds
            self.countUpAnchor = countUpAnchor
        }
    }

    public var exerciseName: String
    /// "rest" for rest sessions, "standalone" or "workout" for other clocks.
    public var sourceKey: String?

    public init(exerciseName: String, sourceKey: String? = nil) {
        self.exerciseName = exerciseName
        self.sourceKey = sourceKey
    }
}
