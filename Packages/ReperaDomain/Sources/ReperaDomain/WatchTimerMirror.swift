import Foundation

/// Temporizador autónomo del reloj, reflejado en Inicio del teléfono.
/// El reloj es la única fuente del tiempo y de las transiciones de estado.
public struct WatchTimerMirror: Codable, Equatable, Sendable {
    public let id: UUID
    public let modeRaw: String
    public let configuredSeconds: Int
    public let elapsedSeconds: Int
    public let round: Int
    public let phase: String
    public let updatedAt: Date

    public init(id: UUID, modeRaw: String, configuredSeconds: Int,
                elapsedSeconds: Int, round: Int, phase: String, updatedAt: Date = .now) {
        self.id = id
        self.modeRaw = modeRaw
        self.configuredSeconds = max(1, configuredSeconds)
        self.elapsedSeconds = max(0, elapsedSeconds)
        self.round = max(1, round)
        self.phase = phase
        self.updatedAt = updatedAt
    }

    public var isActive: Bool { phase == "running" || phase == "paused" }
    public var isRunning: Bool { phase == "running" }
    public var modeTitle: String {
        switch modeRaw {
        case "down": "Cuenta atrás"
        case "intervals": "Intervalos"
        default: "Cronómetro"
        }
    }

    /// No extrapolar indefinidamente si se pierde la conexión.
    public func displayedSeconds(at now: Date) -> Int {
        let estimated = elapsedSeconds + (isRunning
            ? min(15, max(0, Int(now.timeIntervalSince(updatedAt)))) : 0)
        return min(configuredSeconds, max(0, estimated))
    }
}
