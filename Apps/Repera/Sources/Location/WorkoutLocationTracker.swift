import CoreLocation
import Foundation
import Observation
import ReperaDomain

/// Captura pin al empezar y, si el entreno parece outdoor, una ruta GPS downsampleada.
@MainActor
@Observable
final class WorkoutLocationTracker: NSObject {
    static let shared = WorkoutLocationTracker()

    private(set) var authorizationStatus: CLAuthorizationStatus
    private(set) var lastErrorMessage: String?

    private let manager = CLLocationManager()
    private var routeBuffer: [WorkoutRoutePoint] = []
    private var trackingSessionID: UUID?
    private var lastAccepted: CLLocation?
    private var pointCounter = 0
    private var authContinuations: [CheckedContinuation<Bool, Never>] = []

    private let minDistanceMeters: CLLocationDistance = 8
    private let maxRoutePoints = 400

    private override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = minDistanceMeters
        manager.pausesLocationUpdatesAutomatically = true
        manager.activityType = .fitness
    }

    var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: return true
        default: return false
        }
    }

    func refreshStatus() {
        authorizationStatus = manager.authorizationStatus
    }

    func requestWhenInUse() {
        refreshStatus()
        guard authorizationStatus == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }

    /// Pide el modal del sistema si hace falta y espera la respuesta (p. ej. al dar Play).
    func ensureWhenInUseAuthorized() async -> Bool {
        refreshStatus()
        if isAuthorized { return true }
        switch authorizationStatus {
        case .denied, .restricted:
            return false
        case .notDetermined:
            return await withCheckedContinuation { cont in
                authContinuations.append(cont)
                manager.requestWhenInUseAuthorization()
            }
        default:
            return isAuthorized
        }
    }

    private func finishAuthWaiters() {
        let granted = isAuthorized
        let waiters = authContinuations
        authContinuations.removeAll()
        for cont in waiters {
            cont.resume(returning: granted)
        }
    }

    /// Heurística: carrera / bici / caminata / outdoor en título o nombres de ejercicio.
    static func shouldTrackRoute(for session: WorkoutSession) -> Bool {
        let blob = (
            [session.title] + session.exercises.map(\.exercise.name)
        )
        .joined(separator: " ")
        .folding(options: .diacriticInsensitive, locale: .current)
        .lowercased()

        let keywords = [
            "correr", "carrera", "running", "run",
            "bici", "ciclismo", "cycling", "bike",
            "caminar", "caminata", "walking", "hike", "hiking",
            "trail", "outdoor", "remo outdoor", "ski", "skate",
        ]
        return keywords.contains { blob.contains($0) }
    }

    func capturePin() async -> WorkoutLocationPin? {
        guard isAuthorized else { return nil }
        return await withCheckedContinuation { cont in
            var resumed = false
            let finish: (WorkoutLocationPin?) -> Void = { pin in
                guard !resumed else { return }
                resumed = true
                self.pendingPinContinuation = nil
                cont.resume(returning: pin)
            }
            pendingPinContinuation = finish
            manager.requestLocation()
            // Timeout suave: si no hay fix, no bloqueamos el start de sesión.
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                finish(nil)
            }
        }
    }

    private var pendingPinContinuation: ((WorkoutLocationPin?) -> Void)?

    func startRouteTracking(sessionID: UUID) {
        guard isAuthorized else { return }
        stopRouteTracking()
        trackingSessionID = sessionID
        routeBuffer = []
        pointCounter = 0
        lastAccepted = nil
        manager.startUpdatingLocation()
    }

    @discardableResult
    func stopRouteTracking() -> [WorkoutRoutePoint] {
        manager.stopUpdatingLocation()
        trackingSessionID = nil
        pendingPinContinuation?(nil)
        pendingPinContinuation = nil
        let points = downsample(routeBuffer, maxCount: maxRoutePoints)
        routeBuffer = []
        lastAccepted = nil
        return points
    }

    private func downsample(_ points: [WorkoutRoutePoint], maxCount: Int) -> [WorkoutRoutePoint] {
        guard points.count > maxCount, maxCount > 2 else { return points }
        let step = Double(points.count - 1) / Double(maxCount - 1)
        var result: [WorkoutRoutePoint] = []
        for i in 0..<maxCount {
            let idx = min(points.count - 1, Int((Double(i) * step).rounded()))
            var p = points[idx]
            p.id = i
            result.append(p)
        }
        return result
    }
}

extension WorkoutLocationTracker: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            authorizationStatus = status
            // Evita colgar el Play si el sistema no vuelve a llamar tras notDetermined.
            if status != .notDetermined {
                finishAuthWaiters()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let date = location.timestamp
        let speed = location.speed >= 0 ? location.speed : nil
        Task { @MainActor in
            if let finish = pendingPinContinuation {
                pendingPinContinuation = nil
                finish(WorkoutLocationPin(latitude: lat, longitude: lon, recordedAt: date))
            }

            guard trackingSessionID != nil else { return }
            let candidate = CLLocation(latitude: lat, longitude: lon)
            if let last = lastAccepted,
               candidate.distance(from: last) < minDistanceMeters {
                return
            }
            lastAccepted = candidate
            routeBuffer.append(
                WorkoutRoutePoint(
                    id: pointCounter,
                    latitude: lat,
                    longitude: lon,
                    recordedAt: date,
                    speedMps: speed,
                    altitudeMeters: (0...50).contains(location.verticalAccuracy) ? location.altitude : nil
                )
            )
            pointCounter += 1
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let message = error.localizedDescription
        Task { @MainActor in
            lastErrorMessage = message
            if let finish = pendingPinContinuation {
                pendingPinContinuation = nil
                finish(nil)
            }
        }
    }
}
