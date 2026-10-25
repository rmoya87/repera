import ActivityKit
import Foundation

/// Live Activity de sesiones deportivas, independiente del contador de descansos.
/// Los datos son valores ligeros: nunca se envían recorridos GPS ni datos privados.
public struct TrainingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public enum Phase: String, Codable, Hashable, Sendable {
            case running
            case paused
            case completed
        }

        public var phase: Phase
        public var title: String
        public var symbol: String
        public var subtitle: String
        /// Inicio virtual = ahora - tiempo activo; permite que iOS anime el reloj
        /// sin mandar una actualización por segundo.
        public var timerAnchor: Date
        /// Último valor congelado, mostrado en pausa y al finalizar.
        public var elapsedSeconds: Int
        public var primaryValue: String
        public var primaryLabel: String
        public var secondaryValue: String
        public var secondaryLabel: String

        public init(
            phase: Phase, title: String, symbol: String, subtitle: String,
            timerAnchor: Date, elapsedSeconds: Int,
            primaryValue: String, primaryLabel: String,
            secondaryValue: String, secondaryLabel: String
        ) {
            self.phase = phase
            self.title = title
            self.symbol = symbol
            self.subtitle = subtitle
            self.timerAnchor = timerAnchor
            self.elapsedSeconds = max(0, elapsedSeconds)
            self.primaryValue = primaryValue
            self.primaryLabel = primaryLabel
            self.secondaryValue = secondaryValue
            self.secondaryLabel = secondaryLabel
        }
    }

    /// 'free:' y 'planned:' impiden mezclar estados de entrenamientos distintos.
    public var sessionID: String
    public var isPlanned: Bool

    public init(sessionID: String, isPlanned: Bool) {
        self.sessionID = sessionID
        self.isPlanned = isPlanned
    }
}
