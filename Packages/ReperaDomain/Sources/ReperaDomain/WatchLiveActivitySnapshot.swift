import Foundation

/// Lightweight ActivityKit mirror shared over WatchConnectivity.
/// GPS geometry and private HealthKit samples never cross this channel.
public struct WatchLiveActivitySnapshot: Codable, Equatable, Sendable {
    public enum Phase: String, Codable, Sendable {
        case recording
        case paused
        case review
    }

    /// Sport = Comenzar on Watch. Planned = plan/class owned by Watch HealthKit.
    public enum Kind: String, Codable, Sendable {
        case sport
        case planned
    }

    public let id: UUID
    public let sportTitle: String
    /// Identificador no localizado del deporte; nil en snapshots anteriores.
    public let sportID: String?
    public let phase: Phase
    public let kind: Kind
    public let elapsedSeconds: TimeInterval
    public let distanceMeters: Double
    public let averageSpeedKmh: Double?
    /// Only aggregate sensor readings published by the Watch for its own UUID.
    /// No raw HealthKit samples are transferred or rewritten by the iPhone.
    public let heartRateBpm: Int?
    public let activeEnergyKcal: Double?
    public let nextTurn: String?
    public let nextTurnMeters: Int?
    public let capturedAt: Date
    /// Condiciones Open-Meteo (marea/nieve); opcionales.
    public let conditions: ActivityConditionsSnapshot?
    /// Optional ActivityKit copy for planned workouts (exercise / sets).
    public let subtitle: String?
    public let symbolName: String?
    public let primaryValue: String?
    public let primaryLabel: String?
    public let secondaryValue: String?
    public let secondaryLabel: String?
    /// Segundos del último km cerrado (nil en snapshots antiguos o sin parcial).
    public let lastKilometerSeconds: TimeInterval?

    public init(
        id: UUID, sportTitle: String, phase: Phase,
        elapsedSeconds: TimeInterval, distanceMeters: Double,
        averageSpeedKmh: Double?, nextTurn: String?,
        nextTurnMeters: Int?, capturedAt: Date,
        heartRateBpm: Int? = nil, activeEnergyKcal: Double? = nil,
        conditions: ActivityConditionsSnapshot? = nil,
        sportID: String? = nil,
        kind: Kind = .sport,
        subtitle: String? = nil,
        symbolName: String? = nil,
        primaryValue: String? = nil,
        primaryLabel: String? = nil,
        secondaryValue: String? = nil,
        secondaryLabel: String? = nil,
        lastKilometerSeconds: TimeInterval? = nil
    ) {
        self.id = id
        self.sportTitle = sportTitle
        self.sportID = sportID
        self.phase = phase
        self.kind = kind
        self.elapsedSeconds = max(0, elapsedSeconds)
        self.distanceMeters = max(0, distanceMeters)
        self.averageSpeedKmh = averageSpeedKmh
        self.heartRateBpm = heartRateBpm
        self.activeEnergyKcal = activeEnergyKcal
        self.nextTurn = nextTurn
        self.nextTurnMeters = nextTurnMeters
        self.capturedAt = capturedAt
        self.conditions = conditions
        self.subtitle = subtitle
        self.symbolName = symbolName
        self.primaryValue = primaryValue
        self.primaryLabel = primaryLabel
        self.secondaryValue = secondaryValue
        self.secondaryLabel = secondaryLabel
        self.lastKilometerSeconds = lastKilometerSeconds.flatMap { $0 > 0 ? $0 : nil }
    }

    enum CodingKeys: String, CodingKey {
        case id, sportTitle, sportID, phase, kind, elapsedSeconds, distanceMeters
        case averageSpeedKmh, heartRateBpm, activeEnergyKcal
        case nextTurn, nextTurnMeters, capturedAt, conditions
        case subtitle, symbolName, primaryValue, primaryLabel
        case secondaryValue, secondaryLabel, lastKilometerSeconds
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        sportTitle = try c.decode(String.self, forKey: .sportTitle)
        sportID = try c.decodeIfPresent(String.self, forKey: .sportID)
        phase = try c.decode(Phase.self, forKey: .phase)
        kind = try c.decodeIfPresent(Kind.self, forKey: .kind) ?? .sport
        elapsedSeconds = max(0, try c.decode(TimeInterval.self, forKey: .elapsedSeconds))
        distanceMeters = max(0, try c.decode(Double.self, forKey: .distanceMeters))
        averageSpeedKmh = try c.decodeIfPresent(Double.self, forKey: .averageSpeedKmh)
        heartRateBpm = try c.decodeIfPresent(Int.self, forKey: .heartRateBpm)
        activeEnergyKcal = try c.decodeIfPresent(Double.self, forKey: .activeEnergyKcal)
        nextTurn = try c.decodeIfPresent(String.self, forKey: .nextTurn)
        nextTurnMeters = try c.decodeIfPresent(Int.self, forKey: .nextTurnMeters)
        capturedAt = try c.decode(Date.self, forKey: .capturedAt)
        conditions = try c.decodeIfPresent(ActivityConditionsSnapshot.self, forKey: .conditions)
        subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle)
        symbolName = try c.decodeIfPresent(String.self, forKey: .symbolName)
        primaryValue = try c.decodeIfPresent(String.self, forKey: .primaryValue)
        primaryLabel = try c.decodeIfPresent(String.self, forKey: .primaryLabel)
        secondaryValue = try c.decodeIfPresent(String.self, forKey: .secondaryValue)
        secondaryLabel = try c.decodeIfPresent(String.self, forKey: .secondaryLabel)
        let rawLastKm = try c.decodeIfPresent(TimeInterval.self, forKey: .lastKilometerSeconds)
        lastKilometerSeconds = rawLastKm.flatMap { $0 > 0 ? $0 : nil }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(sportTitle, forKey: .sportTitle)
        try c.encodeIfPresent(sportID, forKey: .sportID)
        try c.encode(phase, forKey: .phase)
        try c.encode(kind, forKey: .kind)
        try c.encode(elapsedSeconds, forKey: .elapsedSeconds)
        try c.encode(distanceMeters, forKey: .distanceMeters)
        try c.encodeIfPresent(averageSpeedKmh, forKey: .averageSpeedKmh)
        try c.encodeIfPresent(heartRateBpm, forKey: .heartRateBpm)
        try c.encodeIfPresent(activeEnergyKcal, forKey: .activeEnergyKcal)
        try c.encodeIfPresent(nextTurn, forKey: .nextTurn)
        try c.encodeIfPresent(nextTurnMeters, forKey: .nextTurnMeters)
        try c.encode(capturedAt, forKey: .capturedAt)
        try c.encodeIfPresent(conditions, forKey: .conditions)
        try c.encodeIfPresent(subtitle, forKey: .subtitle)
        try c.encodeIfPresent(symbolName, forKey: .symbolName)
        try c.encodeIfPresent(primaryValue, forKey: .primaryValue)
        try c.encodeIfPresent(primaryLabel, forKey: .primaryLabel)
        try c.encodeIfPresent(secondaryValue, forKey: .secondaryValue)
        try c.encodeIfPresent(secondaryLabel, forKey: .secondaryLabel)
        try c.encodeIfPresent(lastKilometerSeconds, forKey: .lastKilometerSeconds)
    }

    /// The phone owns the GPS/elapsed odometer. The watch interpolates display
    /// time only, never recalculates distance or invents GPS points.
    public func displayElapsed(at date: Date) -> TimeInterval {
        elapsedSeconds + (phase == .recording ? max(0, date.timeIntervalSince(capturedAt)) : 0)
    }
}
