import ActivityKit
import Foundation

/// Atributos compartidos app + widget para el timer de descanso.
public struct RestActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var endDate: Date
        public var totalSeconds: Int

        public init(endDate: Date, totalSeconds: Int) {
            self.endDate = endDate
            self.totalSeconds = totalSeconds
        }
    }

    public var exerciseName: String

    public init(exerciseName: String) {
        self.exerciseName = exerciseName
    }
}
