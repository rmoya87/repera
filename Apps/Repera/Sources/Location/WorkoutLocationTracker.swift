import CoreLocation
import Foundation
import Observation
import ReperaDomain
import UIKit

/// A location sample is copied to Sendable scalars before crossing Core Location's
/// nonisolated delegate into the app's main actor.
struct WorkoutGPSFix: Sendable {
    var latitude: Double
    var longitude: Double
    var altitude: Double
    var accuracy: Double
    var verticalAccuracy: Double
    var speed: Double
    var course: Double
    var timestamp: Date

    var location: CLLocation {
        CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: altitude,
            horizontalAccuracy: accuracy,
            verticalAccuracy: verticalAccuracy,
            course: course,
            speed: speed,
            timestamp: timestamp
        )
    }
}

struct WorkoutGPSUpdate: Sendable {
    var fix: WorkoutGPSFix
    var point: WorkoutRoutePoint
    var distanceMeters: Double
}

/// Single owner for the iPhone GPS sensor in BOTH Comenzar and Play.
/// The UI and HealthKit are consumers of these accepted, timestamped fixes.
/// No downsampling occurs here: only rendering is allowed to simplify paths.
@MainActor
@Observable
final class WorkoutLocationTracker: NSObject {
    static let shared = WorkoutLocationTracker()

    private(set) var authorizationStatus: CLAuthorizationStatus
    private(set) var lastErrorMessage: String?
    private(set) var recordedDistanceMeters: Double = 0
    private(set) var routeBuffer: [WorkoutRoutePoint] = []
    private(set) var trackingSessionID: UUID?
    private(set) var currentFix: WorkoutGPSFix?

    @ObservationIgnored private let manager: CLLocationManager
    @ObservationIgnored private var backgroundSession: CLBackgroundActivitySession?
    @ObservationIgnored private var lastAccepted: CLLocation?
    @ObservationIgnored private var segmentBeganAt: Date?
    @ObservationIgnored private var onAccepted: (@MainActor (WorkoutGPSUpdate) -> Void)?
    @ObservationIgnored private var speedLimitMetersPerSecond = 12.0
    @ObservationIgnored private var authContinuations: [CheckedContinuation<Bool, Never>] = []
    @ObservationIgnored private var pendingPinContinuation: ((WorkoutLocationPin?) -> Void)?
    @ObservationIgnored private var lastSavedAt = Date.distantPast
    private let snapshotKey = "repera.gps.shared.v1"

    private struct GPSSnapshot: Codable {
        var id: UUID
        var points: [WorkoutRoutePoint]
        var meters: Double
    }

    private override init() {
        let manager = CLLocationManager()
        authorizationStatus = manager.authorizationStatus
        self.manager = manager
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 3
        manager.pausesLocationUpdatesAutomatically = false
        manager.activityType = .fitness
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse
    }

    func refreshStatus() { authorizationStatus = manager.authorizationStatus }

    func requestWhenInUse() {
        refreshStatus()
        if authorizationStatus == .notDetermined { manager.requestWhenInUseAuthorization() }
    }

    func ensureWhenInUseAuthorized() async -> Bool {
        refreshStatus()
        if isAuthorized { return true }
        switch authorizationStatus {
        case .denied, .restricted: return false
        case .notDetermined:
            return await withCheckedContinuation { cont in
                authContinuations.append(cont)
                manager.requestWhenInUseAuthorization()
            }
        default: return isAuthorized
        }
    }

    private func finishAuthWaiters() {
        let waiters = authContinuations
        authContinuations.removeAll()
        for waiter in waiters { waiter.resume(returning: isAuthorized) }
    }

    /// Outdoor sessions need the same GPS engine as free workouts.
    /// Match COMPLETE words to avoid treating "crunch" as "run", or a
    /// stationary SkiErg / Assault Bike as a GPS sport.
    static func shouldTrackRoute(for session: WorkoutSession) -> Bool {
        if let sport = session.liveSportID.flatMap(LiveSport.init(rawValue:)) {
            return sport.usesGPS
        }
        let blob = ([session.title] + session.exercises.map(\.exercise.name))
            .joined(separator: " ")
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
        let words = Set(blob.split(whereSeparator: {
            !$0.isLetter && !$0.isNumber
        }).map(String.init))
        if words.contains("treadmill") || words.contains("cinta") { return false }
        if words.contains("outdoor") || words.contains("trail") { return true }
        let onFoot: Set<String> = [
            "correr", "carrera", "running", "run", "caminar",
            "caminata", "walking", "walk", "hike", "hiking", "senderismo"
        ]
        if !words.isDisjoint(with: onFoot) { return true }
        let bike: Set<String> = [
            "bici", "bicicleta", "ciclismo", "cycling", "bike", "gravel", "mtb"
        ]
        if !words.isDisjoint(with: bike) {
            // Indoor ergs never start the expensive GPS sensor.
            let indoorBike: Set<String> = [
                "assault", "echo", "erg", "ergometer", "ergometro", "spinning"
            ]
            return words.isDisjoint(with: indoorBike)
        }
        return false
    }

    func capturePin() async -> WorkoutLocationPin? {
        guard isAuthorized else { return nil }
        if let currentFix, Date().timeIntervalSince(currentFix.timestamp) < 10 {
            return WorkoutLocationPin(
                latitude: currentFix.latitude, longitude: currentFix.longitude,
                recordedAt: currentFix.timestamp
            )
        }
        return await withCheckedContinuation { cont in
            // Replacing a previous pending pin never leaves a hanging continuation.
            pendingPinContinuation?(nil)
            var resolved = false
            let finish: (WorkoutLocationPin?) -> Void = { [weak self] pin in
                guard !resolved else { return }
                resolved = true
                self?.pendingPinContinuation = nil
                cont.resume(returning: pin)
            }
            pendingPinContinuation = finish
            if trackingSessionID == nil { manager.requestLocation() }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(4))
                finish(nil)
            }
        }
    }

    func requestFreshLocation() {
        if isAuthorized { manager.requestLocation() }
    }

    /// An existing session is never replaced by another id; both UI entrypoints
    /// must share the same active sensor owner, not create competing streams.
    @discardableResult
    func startRouteTracking(
        sessionID: UUID,
        cycling: Bool = false,
        maxSpeedMetersPerSecond: Double? = nil,
        existingPoints: [WorkoutRoutePoint] = [],
        existingDistanceMeters: Double = 0,
        onUpdate: (@MainActor (WorkoutGPSUpdate) -> Void)? = nil
    ) -> Bool {
        guard isAuthorized else { return false }
        if let trackingSessionID, trackingSessionID != sessionID { return false }
        self.trackingSessionID = sessionID
        self.onAccepted = onUpdate
        if segmentBeganAt == nil {
            let restored = readSnapshot(for: sessionID)
            routeBuffer = existingPoints.isEmpty ? (restored?.points ?? []) : existingPoints
            recordedDistanceMeters = max(existingDistanceMeters, restored?.meters ?? 0)
            lastAccepted = nil // Never connect across pause, crash or service restart.
            segmentBeganAt = Date()
        }
        manager.distanceFilter = cycling ? 5 : 3
        speedLimitMetersPerSecond = max(1, maxSpeedMetersPerSecond ?? (cycling ? 22.0 : 12.0))
        let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] ?? []
        let appExecutable = Bundle.main.bundleURL.pathExtension == "app"
        let testing = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        if modes.contains("location") && appExecutable && !testing {
            manager.allowsBackgroundLocationUpdates = true
            manager.showsBackgroundLocationIndicator = true
            if backgroundSession == nil { backgroundSession = CLBackgroundActivitySession() }
        } else {
            lastErrorMessage = "El paquete iOS no tiene habilitado GPS en segundo plano."
        }
        manager.startUpdatingLocation()
        return true
    }

    /// Stop on pause or completion; retain points for an explicit resume.
    /// Does not accidentally tear down the other workout owner's GPS.
    @discardableResult
    func stopRouteTracking(sessionID: UUID? = nil, clear: Bool = true) -> [WorkoutRoutePoint] {
        if let sessionID, trackingSessionID != sessionID { return [] }
        manager.stopUpdatingLocation()
        if manager.allowsBackgroundLocationUpdates {
            manager.allowsBackgroundLocationUpdates = false
        }
        backgroundSession?.invalidate()
        backgroundSession = nil
        lastAccepted = nil
        segmentBeganAt = nil
        onAccepted = nil
        let result = routeBuffer
        if clear {
            trackingSessionID = nil
            routeBuffer = []
            recordedDistanceMeters = 0
            UserDefaults.standard.removeObject(forKey: snapshotKey)
        } else {
            saveSnapshot()
        }
        return result
    }

    func restoreForResume(sessionID: UUID) -> (points: [WorkoutRoutePoint], meters: Double)? {
        guard let snapshot = readSnapshot(for: sessionID) else { return nil }
        return (snapshot.points, snapshot.meters)
    }

    private func readSnapshot(for sessionID: UUID) -> GPSSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(GPSSnapshot.self, from: data),
              snapshot.id == sessionID else { return nil }
        return snapshot
    }

    private func saveSnapshot() {
        guard let id = trackingSessionID else { return }
        if let data = try? JSONEncoder().encode(GPSSnapshot(
            id: id, points: routeBuffer, meters: recordedDistanceMeters
        )) {
            UserDefaults.standard.set(data, forKey: snapshotKey)
            lastSavedAt = Date()
        }
    }

    private func accept(_ fix: WorkoutGPSFix) {
        guard fix.timestamp <= Date().addingTimeInterval(10),
              fix.accuracy >= 0, fix.accuracy <= 35 else { return }
        currentFix = fix
        if let pin = pendingPinContinuation {
            pin(WorkoutLocationPin(
                latitude: fix.latitude, longitude: fix.longitude, recordedAt: fix.timestamp
            ))
        }
        guard let id = trackingSessionID,
              let segmentBeganAt, fix.timestamp >= segmentBeganAt.addingTimeInterval(-3)
        else { return }
        let position = fix.location
        var delta: CLLocationDistance = 0
        if let previous = lastAccepted {
            let seconds = position.timestamp.timeIntervalSince(previous.timestamp)
            guard seconds > 0 else { return }
            let meters = position.distance(from: previous)
            let limit = speedLimitMetersPerSecond
            if seconds <= 30, meters / seconds <= limit {
                let jitter = max(3.0, min(7.0, max(fix.accuracy, previous.horizontalAccuracy) * 0.4))
                if meters < jitter { return }
                delta = meters
            }
            // A gap or implausible jump starts a new segment but adds 0 m.
        }
        recordedDistanceMeters += delta
        let point = WorkoutRoutePoint(
            id: routeBuffer.count, latitude: fix.latitude,
            longitude: fix.longitude, recordedAt: fix.timestamp,
            speedMps: fix.speed >= 0 ? fix.speed : nil,
            altitudeMeters: (0...50).contains(fix.verticalAccuracy) ? fix.altitude : nil,
            horizontalAccuracyMeters: fix.accuracy,
            verticalAccuracyMeters: (0...50).contains(fix.verticalAccuracy) ? fix.verticalAccuracy : nil
        )
        lastAccepted = position
        routeBuffer.append(point)
        onAccepted?(WorkoutGPSUpdate(fix: fix, point: point, distanceMeters: recordedDistanceMeters))
        // Store the original accuracy in HealthKit, never substitute 15 m.
        HealthKitStore.shared.appendRecordedRouteLocation(sessionID: id, location: position)
        if Date().timeIntervalSince(lastSavedAt) > 10 { saveSnapshot() }
    }
}

extension WorkoutLocationTracker: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.authorizationStatus = status
            if status != .notDetermined { self.finishAuthWaiters() }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let fixes = locations.map { location in
            WorkoutGPSFix(
                latitude: location.coordinate.latitude, longitude: location.coordinate.longitude,
                altitude: location.altitude, accuracy: location.horizontalAccuracy,
                verticalAccuracy: location.verticalAccuracy, speed: location.speed,
                course: location.course, timestamp: location.timestamp
            )
        }
        Task { @MainActor [weak self] in
            for fix in fixes { self?.accept(fix) }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let code = (error as? CLError)?.code
        if code == .locationUnknown { return }
        let message = error.localizedDescription
        Task { @MainActor [weak self] in
            self?.lastErrorMessage = message
            self?.pendingPinContinuation?(nil)
        }
    }
}