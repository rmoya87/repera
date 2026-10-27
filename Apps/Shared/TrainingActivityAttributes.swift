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

        /// Solo próxima maniobra y calle orientativa: nunca se comparten puntos GPS.
        public struct NavigationCue: Codable, Hashable, Sendable {
            public var instruction: String
            public var street: String?
            public var distanceMeters: Int?
            public var symbol: String
            public var isOffRoute: Bool

            public init(
                instruction: String, street: String? = nil, distanceMeters: Int? = nil,
                symbol: String = "arrow.up", isOffRoute: Bool = false
            ) {
                self.instruction = instruction
                self.street = street
                self.distanceMeters = distanceMeters
                self.symbol = symbol
                self.isOffRoute = isOffRoute
            }
        }

        /// nil para entrenamientos sin ruta; opcional para decodificar estados previos.
        public var navigation: NavigationCue?

        public init(
            phase: Phase, title: String, symbol: String, subtitle: String,
            timerAnchor: Date, elapsedSeconds: Int,
            primaryValue: String, primaryLabel: String,
            secondaryValue: String, secondaryLabel: String,
            navigation: NavigationCue? = nil
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
            self.navigation = navigation
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
