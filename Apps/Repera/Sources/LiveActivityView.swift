import CoreLocation
import Foundation
import HealthKit
import MapKit
import Observation
import ReperaDomain
import SwiftUI
import UniformTypeIdentifiers

/// El deporte determina qué se mide; no se infiere del nombre del entrenamiento.
enum LiveSport: String, CaseIterable, Identifiable {
    case running, cycling, walking, hiking, trail, mountainBike, gravel
    case crossfit, strength, hiit, hyrox, tennis, padel, surfing, swimming
    case golf, skiing, yoga, mobility, other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .running: "Carrera"
        case .cycling: "Bicicleta"
        case .walking: "Caminata"
        case .hiking: "Senderismo"
        case .trail: "Carrera de montaña"
        case .mountainBike: "Bicicleta de montaña"
        case .gravel: "Bicicleta de gravel"
        case .crossfit: "CrossFit"
        case .strength: "Entrenamiento con pesas"
        case .hiit: "HIIT"
        case .hyrox: "HYROX"
        case .tennis: "Tenis"
        case .padel: "Pádel"
        case .surfing: "Surf"
        case .swimming: "Natación"
        case .golf: "Golf"
        case .skiing: "Esquí alpino"
        case .yoga: "Yoga"
        case .mobility: "Movilidad"
        case .other: "Entrenamiento"
        }
    }

    var symbol: String {
        switch self {
        case .running, .trail: "figure.run"
        case .cycling, .mountainBike, .gravel: "bicycle"
        case .walking: "figure.walk"
        case .hiking: "figure.hiking"
        case .crossfit, .hyrox: "figure.cross.training"
        case .strength: "dumbbell"
        case .hiit: "timer"
        case .tennis: "tennis.racket"
        case .padel: "figure.tennis"
        case .surfing: "water.waves"
        case .swimming: "figure.pool.swim"
        case .golf: "figure.golf"
        case .skiing: "figure.skiing.downhill"
        case .yoga, .mobility: "figure.flexibility"
        case .other: "figure.mixed.cardio"
        }
    }

    var group: String {
        switch self {
        case .running, .trail, .walking, .hiking: "A pie"
        case .cycling, .mountainBike, .gravel: "Ciclismo"
        case .crossfit, .strength, .hiit, .hyrox: "Fuerza y fitness"
        case .tennis, .padel: "Deportes de raqueta"
        case .surfing, .swimming: "Deportes acuáticos"
        default: "Otros deportes"
        }
    }

    var usesGPS: Bool {
        switch self {
        case .running, .cycling, .walking, .hiking, .trail, .mountainBike, .gravel, .surfing, .skiing, .golf:
            true
        default: false
        }
    }

    var isCycling: Bool { self == .cycling || self == .mountainBike || self == .gravel }
    var displaysSpeed: Bool { isCycling || self == .surfing || self == .skiing || self == .golf }

    var healthType: HKWorkoutActivityType {
        switch self {
        case .running, .trail: .running
        case .cycling, .mountainBike, .gravel: .cycling
        case .walking: .walking
        case .hiking: .hiking
        case .crossfit, .hyrox: .crossTraining
        case .strength: .traditionalStrengthTraining
        case .hiit: .highIntensityIntervalTraining
        case .tennis, .padel: .tennis
        case .surfing: .surfingSports
        case .swimming: .swimming
        case .golf: .golf
        case .skiing: .downhillSkiing
        case .yoga: .yoga
        case .mobility: .flexibility
        case .other: .other
        }
    }
}

struct LiveSavedRoute: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var points: [WorkoutRoutePoint]
}

/// Biblioteca offline pequeña de GPX; los recorridos completados se conservan en cada WorkoutSession.
@MainActor
@Observable
final class LiveRoutesStore {
    static let shared = LiveRoutesStore()
    private(set) var routes: [LiveSavedRoute] = []
    private let key = "repera.live.routes.v1"

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([LiveSavedRoute].self, from: data) {
            routes = decoded
        }
    }

    func addGPX(data: Data, name: String) throws {
        let parser = LiveGPXParser()
        let points = try parser.parse(data)
        guard points.count >= 2 else { throw LiveRouteError.empty }
        routes.insert(LiveSavedRoute(title: name, points: points), at: 0)
        // Limitar los GPX locales para no crecer indefinidamente.
        if routes.count > 30 { routes = Array(routes.prefix(30)) }
        persist()
    }

    func remove(_ id: UUID) {
        routes.removeAll { $0.id == id }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(routes) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

private enum LiveRouteError: LocalizedError {
    case empty
    var errorDescription: String? { "El archivo no contiene un recorrido GPX válido." }
}

private final class LiveGPXParser: NSObject, XMLParserDelegate {
    private var points: [WorkoutRoutePoint] = []
    private var dateText = ""
    private var parsingTime = false
    private var activePoint: WorkoutRoutePoint?

    func parse(_ data: Data) throws -> [WorkoutRoutePoint] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        guard parser.parse(), points.count >= 2 else { throw LiveRouteError.empty }
        return points
    }

    func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes: [String: String]) {
        let tag = name.components(separatedBy: ":").last ?? name
        if (tag == "trkpt" || tag == "rtept"),
           let latitude = Double(attributes["lat"] ?? ""),
           let longitude = Double(attributes["lon"] ?? ""),
           (-90...90).contains(latitude), (-180...180).contains(longitude) {
            activePoint = WorkoutRoutePoint(id: points.count, latitude: latitude, longitude: longitude)
        } else if tag == "time", activePoint != nil {
            parsingTime = true
            dateText = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if parsingTime { dateText += string }
    }

    func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?,
                qualifiedName qName: String?) {
        let tag = name.components(separatedBy: ":").last ?? name
        if tag == "time" {
            if let date = ISO8601DateFormatter().date(from: dateText) {
                activePoint?.recordedAt = date
            }
            parsingTime = false
        } else if (tag == "trkpt" || tag == "rtept"), let point = activePoint {
            if points.count < 20_000 { points.append(point) }
            activePoint = nil
        }
    }
}

/// Solo valores Sendable cruzan el callback de CoreLocation al MainActor.
private struct LiveGPSFix: Sendable {
    var latitude: Double
    var longitude: Double
    var altitude: Double
    var accuracy: Double
    var verticalAccuracy: Double
    var speed: Double
    var timestamp: Date
}

private struct LiveSnapshot: Codable {
    var sport: String
    var phase: String
    var startedAt: Date
    var pausedAt: Date?
    var pausedSeconds: TimeInterval
    var recordedDistanceMeters: Double
    var routePoints: [WorkoutRoutePoint]
    var savedAt: Date
    var selectedRouteID: UUID?
}

/// La grabación no depende de que SwiftUI mantenga abierta la pestaña.
@MainActor
@Observable
final class LiveActivityRecorder: NSObject {
    static let shared = LiveActivityRecorder()

    enum Phase: String { case idle, recording, paused, review }
    private(set) var phase: Phase = .idle
    private(set) var sport: LiveSport = .running
    private(set) var startedAt: Date?
    private(set) var finishedAt: Date?
    private(set) var pausedAt: Date?
    private(set) var pausedSeconds: TimeInterval = 0
    private(set) var recordedDistanceMeters: Double = 0
    private(set) var routePoints: [WorkoutRoutePoint] = []
    private(set) var currentCoordinate: CLLocationCoordinate2D?
    private(set) var currentSpeedMps: Double?
    private(set) var gpsMessage: String?
    private(set) var chosenRoute: LiveSavedRoute?
    private var lastPosition: CLLocation?
    private var lastSave = Date.distantPast
    private let manager = CLLocationManager()
    private let snapshotKey = "repera.live.current.v1"

    private override init() {
        super.init()
        manager.delegate = self
        manager.activityType = .fitness
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        manager.pausesLocationUpdatesAutomatically = false
        if let data = UserDefaults.standard.data(forKey: snapshotKey),
           let snapshot = try? JSONDecoder().decode(LiveSnapshot.self, from: data),
           let restoredSport = LiveSport(rawValue: snapshot.sport),
           snapshot.phase != Phase.idle.rawValue {
            sport = restoredSport
            startedAt = snapshot.startedAt
            pausedAt = snapshot.pausedAt ?? snapshot.savedAt
            pausedSeconds = snapshot.pausedSeconds
            recordedDistanceMeters = snapshot.recordedDistanceMeters
            routePoints = snapshot.routePoints
            currentCoordinate = routePoints.last.map {
                CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
            }
            chosenRoute = snapshot.selectedRouteID.flatMap { id in
                LiveRoutesStore.shared.routes.first { $0.id == id }
            }
            // Restauración segura: una interrupción no debe inventar tiempo ni distancia.
            phase = .paused
        } else if let savedSport = UserDefaults.standard.string(forKey: "repera.live.lastSport"),
                  let restored = LiveSport(rawValue: savedSport) {
            sport = restored
        }
    }

    var isActive: Bool { phase != .idle }

    func choose(_ selection: LiveSport) {
        guard phase == .idle else { return }
        sport = selection
        chosenRoute = nil
        UserDefaults.standard.set(selection.rawValue, forKey: "repera.live.lastSport")
    }

    func selectRoute(_ route: LiveSavedRoute?) {
        guard phase == .idle else { return }
        chosenRoute = route
    }

    func start() {
        guard phase == .idle else { return }
        startedAt = Date()
        finishedAt = nil
        pausedAt = nil
        pausedSeconds = 0
        recordedDistanceMeters = 0
        routePoints = []
        lastPosition = nil
        currentSpeedMps = nil
        gpsMessage = nil
        phase = .recording
        if sport.usesGPS { startGPS() }
        persistSnapshot()
    }

    private func startGPS() {
        switch manager.authorizationStatus {
        case .notDetermined:
            gpsMessage = "Autoriza la ubicación para registrar tu recorrido."
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.allowsBackgroundLocationUpdates = true
            manager.startUpdatingLocation()
            gpsMessage = nil
        default:
            gpsMessage = "GPS no autorizado. Puedes continuar registrando el tiempo."
        }
    }

    func pause() {
        guard phase == .recording else { return }
        pausedAt = Date()
        phase = .paused
        currentSpeedMps = nil
        persistSnapshot()
    }

    func resume() {
        guard phase == .paused else { return }
        if let pausedAt { pausedSeconds += Date().timeIntervalSince(pausedAt) }
        pausedAt = nil
        lastPosition = nil
        phase = .recording
        if sport.usesGPS { startGPS() }
        persistSnapshot()
    }

    var durationSeconds: TimeInterval { duration(at: Date()) }

    func duration(at date: Date) -> TimeInterval {
        guard let startedAt else { return 0 }
        let end = finishedAt ?? date
        let currentPause = pausedAt.map { max(0, end.timeIntervalSince($0)) } ?? 0
        return max(0, end.timeIntervalSince(startedAt) - pausedSeconds - currentPause)
    }

    var speedKmh: Double? {
        guard sport.usesGPS, phase == .recording, let speed = currentSpeedMps, speed >= 0 else { return nil }
        return speed * 3.6
    }

    var paceSecondsPerKm: Double? {
        guard let speed = currentSpeedMps, speed > 0.5 else { return nil }
        return 1000 / speed
    }

    var offRouteMeters: Double? {
        guard let coordinate = currentCoordinate, let chosenRoute else { return nil }
        let current = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return chosenRoute.points.map {
            current.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude))
        }.min()
    }

    func finish() {
        guard phase == .recording || phase == .paused else { return }
        let now = Date()
        if let pausedAt { pausedSeconds += now.timeIntervalSince(pausedAt) }
        pausedAt = nil
        finishedAt = now
        phase = .review
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
        persistSnapshot()
    }

    func makeSession(title: String, notes: String) -> WorkoutSession? {
        guard phase == .review, let startedAt, let finishedAt else { return nil }
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return WorkoutSession(
            title: cleaned.isEmpty ? sport.title : cleaned,
            exercises: [],
            phase: .finished,
            startedAt: startedAt,
            finishedAt: max(finishedAt, startedAt.addingTimeInterval(1)),
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
            routePoints: routePoints,
            liveSportID: sport.rawValue,
            recordedDistanceMeters: sport.usesGPS ? recordedDistanceMeters : nil,
            activeDurationSeconds: durationSeconds
        )
    }

    func discard() {
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
        phase = .idle
        startedAt = nil
        finishedAt = nil
        pausedAt = nil
        routePoints = []
        recordedDistanceMeters = 0
        currentSpeedMps = nil
        currentCoordinate = nil
        chosenRoute = nil
        lastPosition = nil
        UserDefaults.standard.removeObject(forKey: snapshotKey)
    }

    private func persistSnapshot() {
        guard let start = startedAt, phase != .idle else { return }
        let snap = LiveSnapshot(
            sport: sport.rawValue, phase: phase.rawValue,
            startedAt: start, pausedAt: pausedAt, pausedSeconds: pausedSeconds,
            recordedDistanceMeters: recordedDistanceMeters, routePoints: routePoints,
            savedAt: Date(), selectedRouteID: chosenRoute?.id
        )
        if let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: snapshotKey)
            lastSave = Date()
        }
    }

    private func receive(_ fix: LiveGPSFix) {
        guard sport.usesGPS, phase == .recording, fix.accuracy >= 0,
              fix.accuracy < 45,
              abs(fix.timestamp.timeIntervalSinceNow) < 20
        else { return }
        let position = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: fix.latitude, longitude: fix.longitude),
            altitude: fix.altitude,
            horizontalAccuracy: fix.accuracy,
            verticalAccuracy: fix.verticalAccuracy,
            course: -1,
            speed: fix.speed,
            timestamp: fix.timestamp
        )
        currentCoordinate = position.coordinate
        currentSpeedMps = fix.speed >= 0 ? fix.speed : nil
        if let previous = lastPosition {
            let meters = position.distance(from: previous)
            let seconds = fix.timestamp.timeIntervalSince(previous.timestamp)
            guard seconds > 0, meters >= 4, meters / seconds < 25 else { return }
            recordedDistanceMeters += meters
        }
        lastPosition = position
        let point = WorkoutRoutePoint(
            id: routePoints.count,
            latitude: fix.latitude,
            longitude: fix.longitude,
            recordedAt: fix.timestamp,
            speedMps: fix.speed >= 0 ? fix.speed : nil,
            altitudeMeters: fix.verticalAccuracy >= 0 ? fix.altitude : nil
        )
        routePoints.append(point)
        if Date().timeIntervalSince(lastSave) > 10 { persistSnapshot() }
    }
}

extension LiveActivityRecorder: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            guard let self, self.phase == .recording, self.sport.usesGPS else { return }
            self.startGPS()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let position = locations.last else { return }
        let sample = LiveGPSFix(
            latitude: position.coordinate.latitude, longitude: position.coordinate.longitude,
            altitude: position.altitude, accuracy: position.horizontalAccuracy,
            verticalAccuracy: position.verticalAccuracy,
            speed: position.speed, timestamp: position.timestamp
        )
        Task { @MainActor [weak self] in self?.receive(sample) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let message = error.localizedDescription
        Task { @MainActor [weak self] in self?.gpsMessage = message }
    }
}

/// Hoja con búsqueda por nombre; agrupación y SF Symbols coherentes con Repera.
private struct LiveSportPicker: View {
    @Environment(\.dismiss) private var dismiss
    var choose: (LiveSport) -> Void
    @State private var query = ""
    private let groups = ["A pie", "Ciclismo", "Fuerza y fitness", "Deportes de raqueta", "Deportes acuáticos", "Otros deportes"]

    var body: some View {
        NavigationStack {
            List {
                ForEach(groups, id: \.self) { group in
                    let sports = LiveSport.allCases.filter {
                        $0.group == group && (query.isEmpty ||
                        $0.title.localizedStandardContains(query))
                    }
                    if !sports.isEmpty {
                        Section(group) {
                            ForEach(sports) { sport in
                                Button {
                                    choose(sport)
                                    dismiss()
                                } label: {
                                    Label(sport.title, systemImage: sport.symbol)
                                        .foregroundStyle(OG.label)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "Buscar actividad")
            .navigationTitle("Elegir actividad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .tint(OG.accent)
    }
}

struct LiveActivityView: View {
    @Environment(ReperaStore.self) private var store
    @State private var recorder = LiveActivityRecorder.shared
    @State private var routes = LiveRoutesStore.shared
    @State private var sportPicker = false
    @State private var routePicker = false
    @State private var importing = false
    @State private var showDiscard = false
    @State private var showingFinish = false
    @State private var showingMetrics = false
    @State private var routeError: String?
    @State private var title = ""
    @State private var notes = ""
    @State private var savedWorkoutID: UUID?
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)

    var onSaved: (Date) -> Void
    var onOpenWorkout: () -> Void
    var onOpenCenter: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if recorder.phase == .review {
                    review
                } else {
                    if recorder.sport.usesGPS {
                        Picker("Vista", selection: $showingMetrics) {
                            Text("Mapa").tag(false)
                            Text("Métricas").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                    }

                    if recorder.sport.usesGPS && !showingMetrics {
                        mapView
                    } else {
                        metricsView
                    }
                    bottomControls
                }
            }
            .background(OG.bg)
            .navigationTitle("En vivo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if recorder.phase == .idle {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            sportPicker = true
                        } label: {
                            Label("Deporte", systemImage: "list.bullet")
                        }
                    }
                    if let onOpenCenter {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(action: onOpenCenter) {
                                Label("Mi centro", systemImage: "building.2")
                            }
                        }
                    }
                } else if recorder.phase != .review {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Descartar", systemImage: "xmark") { showDiscard = true }
                            .tint(OG.label2)
                    }
                }
            }
            .sheet(isPresented: $sportPicker) {
                LiveSportPicker(choose: recorder.choose)
            }
            .sheet(isPresented: $routePicker) { routeSheet }
            .fileImporter(isPresented: $importing,
                          allowedContentTypes: [UTType(filenameExtension: "gpx") ?? .xml, .xml]) { result in
                switch result {
                case .success(let url):
                    let access = url.startAccessingSecurityScopedResource()
                    defer { if access { url.stopAccessingSecurityScopedResource() } }
                    do {
                        try routes.addGPX(data: Data(contentsOf: url),
                                          name: url.deletingPathExtension().lastPathComponent)
                        recorder.selectRoute(routes.routes.first)
                    } catch { routeError = error.localizedDescription }
                case .failure(let error): routeError = error.localizedDescription
                }
            }
            .alert("No se pudo importar la ruta", isPresented: Binding(
                get: { routeError != nil }, set: { if !$0 { routeError = nil } }
            )) {
                Button("Aceptar", role: .cancel) { routeError = nil }
            } message: { Text(routeError ?? "") }
            .confirmationDialog("¿Descartar la actividad?", isPresented: $showDiscard) {
                Button("Descartar sin guardar", role: .destructive) {
                    recorder.discard()
                    title = ""
                    notes = ""
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("El recorrido y los datos registrados se perderán.")
            }
            .confirmationDialog("¿Terminar el entrenamiento?", isPresented: $showingFinish) {
                Button("Terminar y revisar") {
                    recorder.finish()
                    title = recorder.sport.title
                }
                Button("Seguir entrenando", role: .cancel) {}
            }
        }
        .tint(OG.accent)
    }

    private var mapView: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .top) {
                Map(position: $position) {
                    if let route = recorder.chosenRoute, route.points.count > 1 {
                        MapPolyline(coordinates: route.points.map {
                            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                        })
                        .stroke(OG.blue, lineWidth: 5)
                    }
                    if recorder.routePoints.count > 1 {
                        MapPolyline(coordinates: recorder.routePoints.map {
                            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                        })
                        .stroke(OG.accent, lineWidth: 5)
                    }
                    if let current = recorder.currentCoordinate {
                        Annotation("Tú", coordinate: current) {
                            Circle().fill(OG.accent)
                                .frame(width: 16, height: 16)
                                .padding(5)
                                .background(.white, in: Circle())
                                .shadow(radius: 2)
                        }
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }
                .mapStyle(.standard(elevation: .realistic))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                if let offRoute = recorder.offRouteMeters, offRoute > 60 {
                    Label("Fuera del recorrido · \(Int(offRoute)) m", systemImage: "exclamationmark.triangle")
                        .font(.caption.weight(.semibold))
                        .padding(10)
                        .background(.regularMaterial, in: Capsule())
                        .padding(12)
                }
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 12)

            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                HStack(spacing: 6) {
                    smallMetric("Tiempo", value: formattedTime(recorder.duration(at: timeline.date)))
                    smallMetric("Distancia", value: String(format: "%.2f km", recorder.recordedDistanceMeters / 1000))
                    smallMetric(recorder.sport.displaysSpeed ? "km/h" : "min/km",
                                value: paceOrSpeed)
                }
                .padding(.horizontal, 12)
            }
            if let message = recorder.gpsMessage {
                Text(message).font(.caption).foregroundStyle(OG.label2).padding(.horizontal, 16)
            }
        }
        .onChange(of: recorder.currentCoordinate?.latitude) { _, _ in
            guard recorder.phase == .recording, let point = recorder.currentCoordinate else { return }
            position = .region(MKCoordinateRegion(
                center: point, span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            ))
        }
    }

    private var metricsView: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            VStack(spacing: 25) {
                Spacer(minLength: 12)
                Text(formattedTime(recorder.duration(at: timeline.date)))
                    .font(.system(size: 39, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(OG.label)
                Text("DURACIÓN").font(.caption.weight(.medium)).foregroundStyle(OG.label2)
                Spacer(minLength: 16)
                Text(recorder.sport.usesGPS ? paceOrSpeed : recorder.phase == .idle ? "Listo" : "En vivo")
                    .font(.system(size: 69, weight: .bold, design: .rounded).monospacedDigit())
                    .minimumScaleFactor(0.65)
                    .foregroundStyle(OG.label)
                Text(recorder.sport.usesGPS ?
                     (recorder.sport.displaysSpeed ? "Velocidad (km/h)" : "Ritmo (min/km)") : recorder.sport.title)
                    .font(.subheadline).foregroundStyle(OG.label2)
                if recorder.sport.usesGPS {
                    Text(String(format: "%.2f", recorder.recordedDistanceMeters / 1000))
                        .font(.system(size: 48, weight: .semibold, design: .rounded).monospacedDigit())
                    Text("Distancia (km)").font(.subheadline).foregroundStyle(OG.label2)
                } else {
                    Text("Los datos de pulsaciones y calorías se muestran cuando Apple Salud dispone de mediciones reales.")
                        .font(.caption).multilineTextAlignment(.center)
                        .foregroundStyle(OG.label2).padding(.horizontal, 32)
                }
                Spacer(minLength: 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var bottomControls: some View {
        VStack(spacing: 12) {
            if recorder.phase == .idle {
                HStack {
                    Button { sportPicker = true } label: {
                        Label(recorder.sport.title, systemImage: recorder.sport.symbol)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if recorder.sport.usesGPS {
                        Button { routePicker = true } label: {
                            Label(recorder.chosenRoute?.title ?? "Cargar ruta", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                                .lineLimit(1)
                        }
                    }
                }
                .font(.subheadline.weight(.medium))
                .padding(.bottom, 7)

                if store.hasActiveSession {
                    Button(action: onOpenWorkout) {
                        Label("Continuar entrenamiento en curso", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(OG.accent)
                } else {
                    Button { recorder.start() } label: {
                        Label("Iniciar actividad", systemImage: "play.fill")
                            .frame(maxWidth: .infinity).font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(OG.accent)
                }
            } else if recorder.phase == .recording {
                Button { recorder.pause() } label: {
                    Label("Pausar", systemImage: "pause.fill")
                        .frame(maxWidth: .infinity).font(.headline)
                }
                .buttonStyle(.borderedProminent).tint(OG.accent)
            } else if recorder.phase == .paused {
                HStack(spacing: 12) {
                    Button { recorder.resume() } label: {
                        Label("Reanudar", systemImage: "play.fill").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent).tint(OG.accent)
                    Button { showingFinish = true } label: {
                        Label("Finalizar", systemImage: "flag.checkered").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent).tint(OG.label)
                }
            }
        }
        .controlSize(.large)
        .foregroundStyle(.black)
        .padding(16)
        .background(OG.surface)
    }

    private var review: some View {
        Form {
            Section("Resumen") {
                LabeledContent("Deporte", value: recorder.sport.title)
                LabeledContent("Tiempo activo", value: formattedTime(recorder.durationSeconds))
                if recorder.sport.usesGPS {
                    LabeledContent("Distancia", value: String(format: "%.2f km", recorder.recordedDistanceMeters / 1000))
                }
            }
            Section("Actividad") {
                TextField("Título", text: $title)
                TextField("Notas (opcional)", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
            }
            Section {
                Button {
                    guard let session = recorder.makeSession(title: title, notes: notes) else { return }
                    guard savedWorkoutID != session.id else { return }
                    savedWorkoutID = session.id
                    store.saveWorkout(session)
                    let date = session.startedAt ?? Date()
                    recorder.discard()
                    title = ""
                    notes = ""
                    savedWorkoutID = nil
                    onSaved(date)
                } label: {
                    Text("Guardar actividad")
                        .frame(maxWidth: .infinity)
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent).tint(OG.accent)
                .foregroundStyle(.black)
            }
            Section {
                Button("Descartar actividad", role: .destructive) { showDiscard = true }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private var routeSheet: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        routePicker = false
                        importing = true
                    } label: { Label("Importar archivo GPX", systemImage: "square.and.arrow.down") }
                    Button("Sin ruta", systemImage: "xmark.circle") {
                        recorder.selectRoute(nil)
                        routePicker = false
                    }
                }
                Section("Rutas guardadas") {
                    if routes.routes.isEmpty {
                        ContentUnavailableView("Sin rutas guardadas", systemImage: "map",
                                               description: Text("Importa un GPX para seguirlo mientras entrenas."))
                    } else {
                        ForEach(routes.routes) { route in
                            Button {
                                recorder.selectRoute(route)
                                routePicker = false
                                position = .region(routeRegion(route.points))
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(route.title).foregroundStyle(OG.label)
                                    Text("\(route.points.count) puntos")
                                        .font(.caption).foregroundStyle(OG.label2)
                                }
                            }
                        }
                        .onDelete { offsets in
                            for index in offsets { routes.remove(routes.routes[index].id) }
                        }
                    }
                }
            }
            .navigationTitle("Mis rutas")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { routePicker = false }
                }
            }
        }
        .tint(OG.accent)
    }

    private func routeRegion(_ points: [WorkoutRoutePoint]) -> MKCoordinateRegion {
        guard let first = points.first else {
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40.4, longitude: -3.7),
                                      span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
        }
        let lat = points.map(\.latitude)
        let lon = points.map(\.longitude)
        let minLat = lat.min() ?? first.latitude, maxLat = lat.max() ?? first.latitude
        let minLon = lon.min() ?? first.longitude, maxLon = lon.max() ?? first.longitude
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2,
                                           longitude: (minLon + maxLon) / 2),
            span: MKCoordinateSpan(latitudeDelta: max(0.004, (maxLat - minLat) * 1.3),
                                   longitudeDelta: max(0.004, (maxLon - minLon) * 1.3))
        )
    }

    private var paceOrSpeed: String {
        if recorder.sport.displaysSpeed {
            return recorder.speedKmh.map { String(format: "%.1f", $0) } ?? "—"
        }
        guard let seconds = recorder.paceSecondsPerKm, seconds < 3600 else { return "—:—" }
        return String(format: "%d:%02d", Int(seconds) / 60, Int(seconds) % 60)
    }

    private func formattedTime(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        return String(format: "%02d:%02d:%02d", total / 3600, (total / 60) % 60, total % 60)
    }

    private func smallMetric(_ label: String, value: String) -> some View {
        VStack(spacing: 5) {
            Text(value).font(.system(size: 20, weight: .semibold, design: .rounded).monospacedDigit())
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(label).font(.caption2).foregroundStyle(OG.label2)
        }
        .frame(maxWidth: .infinity).padding(12)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: 12))
    }
}
