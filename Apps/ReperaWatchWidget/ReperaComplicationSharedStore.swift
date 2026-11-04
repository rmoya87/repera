import Foundation

/// Estado de lectura para WidgetKit. El widget no arranca sensores ni rutas.
/// Solo lo que la esfera muestra; se borra al terminar o al cerrar sesión.
struct ReperaComplicationSnapshot: Codable, Equatable {
    var sessionID: String
    var title: String
    var capturedAt: Date
    /// Tiempo en `capturedAt`; en pausa es el valor congelado que se muestra.
    var elapsedSeconds: Int
    /// Mientras corre, el widget dibuja `Text(timerAnchor, style: .timer)` y no
    /// necesita recargas por segundo. `nil` en pausa.
    var timerAnchor: Date?
    var distanceMeters: Double?
    var heartRateBpm: Int?
    var energyKcal: Double?
    var paused: Bool
    /// Descanso restante (s) para Smart Stack / rectangular; no inventa series.
    var restRemainingSeconds: Int? = nil
    /// Próxima reserva Center (−60 min window) si el hub la conoce.
    var nextBookingLabel: String? = nil

    /// Métricas de sensor antiguas no se presentan como actuales.
    static let metricsFreshness: TimeInterval = 10 * 60

    var elapsedLabel: String {
        let seconds = max(0, elapsedSeconds)
        if seconds >= 3600 {
            return String(format: "%d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
        }
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    var distanceLabel: String? {
        guard let distanceMeters, distanceMeters.isFinite, distanceMeters >= 0 else { return nil }
        return String(format: "%.2f km", distanceMeters / 1000)
    }

    func metricsAreFresh(at date: Date) -> Bool {
        date.timeIntervalSince(capturedAt) <= Self.metricsFreshness
    }
}

/// App Group deliberado: WidgetKit corre en otro proceso/sandbox.
enum ReperaComplicationSharedStore {
    static let groupID = "group.com.app.repera.watch"
    private static let key = "com.app.repera.watch.complication.v3"
    private static let legacyKeys = ["com.app.repera.watch.complication.v2"]

    static func read() -> ReperaComplicationSnapshot? {
        guard let data = UserDefaults(suiteName: groupID)?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(ReperaComplicationSnapshot.self, from: data)
    }

    @discardableResult
    static func write(_ value: ReperaComplicationSnapshot?) -> Bool {
        guard let store = UserDefaults(suiteName: groupID) else { return false }
        legacyKeys.forEach(store.removeObject(forKey:))
        if let value, let data = try? JSONEncoder().encode(value) {
            store.set(data, forKey: key)
        } else {
            store.removeObject(forKey: key)
        }
        return true
    }
}
