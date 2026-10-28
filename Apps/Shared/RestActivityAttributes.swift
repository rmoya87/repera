import ActivityKit
import Foundation

/// Atributos compartidos app + widget para el timer de descanso.
public struct RestActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var endDate: Date
        public var totalSeconds: Int
        /// When paused, render a fixed value instead of advancing an expired deadline.
        public var pausedRemainingSeconds: Int?

        public init(endDate: Date, totalSeconds: Int, pausedRemainingSeconds: Int? = nil) {
            self.endDate = endDate
            self.totalSeconds = totalSeconds
            self.pausedRemainingSeconds = pausedRemainingSeconds
        }
    }

    public var exerciseName: String

    public init(exerciseName: String) {
        self.exerciseName = exerciseName
    }
}
