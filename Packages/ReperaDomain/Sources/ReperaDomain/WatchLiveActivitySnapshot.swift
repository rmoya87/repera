import Foundation

/// Lightweight phone-owned Comenzar state for the companion watch.
/// GPS geometry and private HealthKit samples never cross WatchConnectivity.
public struct WatchLiveActivitySnapshot: Codable, Equatable, Sendable {
    public enum Phase: String, Codable, Sendable {
        case recording
        case paused
        case review
    }

    public let id: UUID
    public let sportTitle: String
    public let phase: Phase
    public let elapsedSeconds: TimeInterval
    public let distanceMeters: Double
    public let averageSpeedKmh: Double?
    public let nextTurn: String?
    public let nextTurnMeters: Int?
    public let capturedAt: Date
    /// Condiciones Open-Meteo (marea/nieve); opcionales.
    public let conditions: ActivityConditionsSnapshot?

    public init(
        id: UUID, sportTitle: String, phase: Phase,
        elapsedSeconds: TimeInterval, distanceMeters: Double,
        averageSpeedKmh: Double?, nextTurn: String?,
        nextTurnMeters: Int?, capturedAt: Date,
        conditions: ActivityConditionsSnapshot? = nil
    ) {
        self.id = id
        self.sportTitle = sportTitle
        self.phase = phase
        self.elapsedSeconds = max(0, elapsedSeconds)
        self.distanceMeters = max(0, distanceMeters)
        self.averageSpeedKmh = averageSpeedKmh
        self.nextTurn = nextTurn
        self.nextTurnMeters = nextTurnMeters
        self.capturedAt = capturedAt
        self.conditions = conditions
    }

    /// The phone owns the GPS/elapsed odometer. The watch interpolates display
    /// time only, never recalculates distance or invents GPS points.
    public func displayElapsed(at date: Date) -> TimeInterval {
        elapsedSeconds + (phase == .recording ? max(0, date.timeIntervalSince(capturedAt)) : 0)
    }
}
