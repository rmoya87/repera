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
    case empty, invalidXML

    var errorDescription: String? {
        switch self {
        case .empty: "Este GPX no contiene al menos dos puntos de recorrido."
        case .invalidXML: "El archivo GPX está dañado o no tiene un formato válido."
        }
    }
}

private final class LiveGPXParser: NSObject, XMLParserDelegate {
    private var points: [WorkoutRoutePoint] = []
    private var dateText = ""
    private var parsingTime = false
    private var activePoint: WorkoutRoutePoint?

    func parse(_ data: Data) throws -> [WorkoutRoutePoint] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        guard parser.parse() else { throw LiveRouteError.invalidXML }
        guard points.count >= 2 else { throw LiveRouteError.empty }
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
    private var lastLiveActivityUpdate = Date.distantPast
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
        if phase != .idle {
            Task { @MainActor [weak self] in self?.updateLiveActivity() }
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
        updateLiveActivity()
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

    /// Checkpoint al pasar a segundo plano y mientras la vista está activa.
    func checkpoint() {
        if isActive && Date().timeIntervalSince(lastSave) >= 10 { persistSnapshot() }
    }

    func pause() {
        guard phase == .recording else { return }
        pausedAt = Date()
        phase = .paused
        currentSpeedMps = nil
        persistSnapshot()
        updateLiveActivity()
    }

    func resume() {
        guard phase == .paused else { return }
        if let pausedAt { pausedSeconds += Date().timeIntervalSince(pausedAt) }
        pausedAt = nil
        lastPosition = nil
        phase = .recording
        if sport.usesGPS { startGPS() }
        persistSnapshot()
        updateLiveActivity()
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

    /// Mantiene la velocidad media también al pausar y al finalizar;
    /// no utiliza la última velocidad instantánea como media.
    var averageSpeedKmh: Double? {
        guard sport.usesGPS, routePoints.count >= 2, durationSeconds > 0 else { return nil }
        return max(0, recordedDistanceMeters / durationSeconds * 3.6)
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
        updateLiveActivity()
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

    func discard(saved: Bool = false) {
        if let startedAt {
            Task {
                await WorkoutLiveActivityCoordinator.shared.dismissFree(
                    startedAt: startedAt, saved: saved
                )
            }
        }
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
        if Date().timeIntervalSince(lastLiveActivityUpdate) >= 15 {
            updateLiveActivity()
        }
    }

    /// Estado compacto: la pantalla bloqueada anima el contador por sí sola.
    private func updateLiveActivity() {
        guard let startedAt, phase != .idle else { return }
        lastLiveActivityUpdate = Date()
        let status: TrainingActivityAttributes.ContentState.Phase
        switch phase {
        case .recording: status = .running
        case .paused: status = .paused
        case .review: status = .completed
        case .idle: return
        }
        let sport = sport
        let elapsed = durationSeconds
        let distance = recordedDistanceMeters
        let kmh = averageSpeedKmh
        Task {
            await WorkoutLiveActivityCoordinator.shared.updateFree(
                startedAt: startedAt, sport: sport, phase: status,
                elapsedSeconds: elapsed, distanceMeters: distance, speedKmh: kmh
            )
        }
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
        let code = (error as? CLError)?.code
        // CoreLocation puede emitir locationUnknown al adquirir señal; no es un fallo
        // persistente y no debe mostrar "The operation couldn't be completed".
        if code == .locationUnknown { return }
        let message: String
        if code == .denied {
            message = "Activa la ubicación para registrar el recorrido."
        } else if code == .network {
            message = "La ubicación no está disponible. Seguimos registrando el tiempo."
        } else {
            message = "GPS temporalmente no disponible. Seguimos registrando el tiempo."
        }
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
    @Environment(\.scenePhase) private var scenePhase
    @State private var recorder = LiveActivityRecorder.shared
    @State private var routes = LiveRoutesStore.shared
    @State private var sportPicker = false
    @State private var routePicker = false
    @State private var importing = false
    @State private var importAfterRouteSheet = false
    @State private var showDiscard = false
    @State private var showingFinish = false
    /// Vista inicial: mapa para exteriores. Al iniciar, métricas a primer plano.
    /// El botón flotante permite volver al mapa sin pestañas ni controles segmentados.
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
            Group {
                if recorder.phase == .review {
                    review
                } else if recorder.sport.usesGPS && !showingMetrics {
                    mapView
                } else {
                    VStack(spacing: 0) {
                        metricsView
                        bottomControls
                            .padding(.horizontal, 14)
                            .padding(.bottom, 12)
                    }
                }
            }
            .background(OG.bg)
            .toolbar(recorder.phase == .review ? .visible : .hidden, for: .navigationBar)
            .navigationTitle(recorder.phase == .review ? "Guardar actividad" : "En vivo")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $sportPicker) {
                LiveSportPicker { sport in
                    recorder.choose(sport)
                    showingMetrics = false
                    position = .userLocation(fallback: .automatic)
                }
            }
            // Nunca abrir fileImporter mientras se está cerrando otra sheet.
            .sheet(isPresented: $routePicker, onDismiss: {
                if importAfterRouteSheet {
                    importAfterRouteSheet = false
                    importing = true
                }
            }) {
                routeSheet
            }
            // .data cubre archivos .gpx cuya UTI no esté registrada en el dispositivo.
            .fileImporter(isPresented: $importing, allowedContentTypes: [.xml, .data]) { result in
                importResult(result)
            }
            .alert("No se pudo cargar la ruta", isPresented: Binding(
                get: { routeError != nil }, set: { if !$0 { routeError = nil } }
            )) {
                Button("Aceptar", role: .cancel) { routeError = nil }
            } message: {
                Text(routeError ?? "")
            }
            .confirmationDialog("¿Descartar la actividad?", isPresented: $showDiscard) {
                Button("Descartar sin guardar", role: .destructive) {
                    recorder.discard()
                    title = ""
                    notes = ""
                    showingMetrics = false
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
        .onChange(of: scenePhase) { _, next in
            if next != .active { recorder.checkpoint() }
        }
    }

    /// Canvas edge-to-edge; únicamente las capas de interacción reciben material.
    /// Tab bar principal permanece nativa y aparece superpuesta al mapa.
    private var mapView: some View {
        ZStack {
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
                        Circle()
                            .fill(OG.accent)
                            .frame(width: 16, height: 16)
                            .padding(5)
                            .background(.white, in: Circle())
                            .shadow(radius: 2)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea()

            VStack(spacing: 12) {
                mapHeader

                if let offRoute = recorder.offRouteMeters, offRoute > 60 {
                    Label("Fuera del recorrido · \(Int(offRoute)) m", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .glassEffect(.regular, in: .capsule)
                }
                if let gpsMessage = recorder.gpsMessage, recorder.phase == .idle {
                    Text(gpsMessage)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(OG.label)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .glassEffect(.regular, in: .capsule)
                }
                Spacer(minLength: 0)
                mapMetricStrip
                bottomControls
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 10)
        }
        .onChange(of: recorder.routePoints.count) { _, _ in
            guard recorder.phase == .recording,
                  let coordinate = recorder.currentCoordinate else { return }
            position = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            ))
        }
    }

    private var mapHeader: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: recorder.phase == .paused ? "pause.fill" : "location.fill")
                    .foregroundStyle(recorder.phase == .paused ? OG.orange : OG.accent)
                VStack(alignment: .leading, spacing: 1) {
                    Text(recorder.phase == .paused ? "En pausa" : "En vivo")
                        .font(.subheadline.weight(.bold))
                    if let route = recorder.chosenRoute {
                        Text(route.title)
                            .font(.caption2)
                            .lineLimit(1)
                    } else {
                        Text(recorder.sport.title)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassEffect(.regular, in: .capsule)

            Spacer(minLength: 0)

            if recorder.phase == .idle, let onOpenCenter {
                mapCircleButton("building.2", label: "Mi centro", action: onOpenCenter)
            }
            mapCircleButton("location.north.line.fill", label: "Centrar mapa") {
                position = .userLocation(fallback: .automatic)
            }
            if recorder.phase == .recording || recorder.phase == .paused {
                mapCircleButton("arrow.up.left.and.arrow.down.right", label: "Ver métricas") {
                    showingMetrics = true
                }
                mapCircleButton("xmark", label: "Descartar actividad") {
                    showDiscard = true
                }
            }
        }
    }

    private func mapCircleButton(
        _ symbol: String, label: String, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(OG.label)
                .frame(width: 44, height: 44)
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var mapMetricStrip: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            HStack(spacing: 5) {
                smallMetric("Duración", value: formattedTime(recorder.duration(at: timeline.date)))
                smallMetric(recorder.sport.displaysSpeed ? "Velocidad" : "Ritmo",
                            value: paceOrSpeed)
                smallMetric("Distancia (km)",
                            value: String(format: "%.2f", recorder.recordedDistanceMeters / 1000))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 14)
            .glassEffect(.regular, in: .rect(cornerRadius: 22))
        }
    }

    private var metricsView: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: recorder.sport.symbol)
                        .font(.title2.weight(.medium))
                        .foregroundStyle(OG.accent)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(recorder.sport.title).font(.headline)
                        if recorder.phase == .paused {
                            Text("En pausa").font(.caption.weight(.semibold))
                                .foregroundStyle(OG.orange)
                        } else {
                            Text(recorder.phase == .recording ? "Grabando actividad" : "Preparado")
                                .font(.caption).foregroundStyle(OG.label2)
                        }
                    }
                    Spacer()
                    if recorder.sport.usesGPS {
                        Button {
                            showingMetrics = false
                        } label: {
                            Label("Mapa", systemImage: "map")
                                .labelStyle(.iconOnly)
                                .font(.title3.weight(.medium))
                                .frame(width: 44, height: 44)
                                .glassEffect(.regular.interactive(), in: .circle)
                        }
                        .accessibilityLabel("Ver mapa")
                    }
                    if recorder.phase != .idle {
                        Button {
                            showDiscard = true
                        } label: {
                            Image(systemName: "xmark")
                                .frame(width: 44, height: 44)
                                .glassEffect(.regular.interactive(), in: .circle)
                        }
                        .accessibilityLabel("Descartar actividad")
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)

                Spacer(minLength: 16)
                Text(formattedTime(recorder.duration(at: timeline.date)))
                    .font(.system(size: 46, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(OG.label)
                    .minimumScaleFactor(0.6).lineLimit(1)
                Text("Duración")
                    .font(.subheadline).foregroundStyle(OG.label2)
                Spacer(minLength: 14)
                Text(recorder.sport.usesGPS ? paceOrSpeed :
                     recorder.phase == .idle ? "Listo" : "En vivo")
                    .font(.system(size: 78, weight: .bold, design: .rounded).monospacedDigit())
                    .minimumScaleFactor(0.55).lineLimit(1)
                    .foregroundStyle(OG.label)
                Text(recorder.sport.usesGPS ?
                    (recorder.sport.displaysSpeed ? "Velocidad (km/h)" : "Ritmo (min/km)") :
                    recorder.sport.title)
                    .font(.subheadline).foregroundStyle(OG.label2)
                Spacer(minLength: 14)
                if recorder.sport.usesGPS {
                    Text(String(format: "%.2f", recorder.recordedDistanceMeters / 1000))
                        .font(.system(size: 55, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(OG.label)
                    Text("Distancia (km)").font(.subheadline).foregroundStyle(OG.label2)
                } else {
                    Text("Las pulsaciones y las calorías aparecen cuando Apple Salud facilita mediciones reales.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(OG.label2)
                        .padding(.horizontal, 38)
                }
                Spacer(minLength: 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: Int(timeline.date.timeIntervalSince1970 / 15)) { _, _ in
                recorder.checkpoint()
            }
        }
    }

    /// La misma base inferior para exterior e interior. Al aire libre, una caja
    /// adicional con las métricas flota justo encima; dentro no es necesaria.
    private var bottomControls: some View {
        Group {
            switch recorder.phase {
            case .idle:
                HStack(alignment: .center, spacing: 12) {
                    Button {
                        sportPicker = true
                    } label: {
                        VStack(spacing: 7) {
                            Image(systemName: recorder.sport.symbol)
                                .font(.system(size: 25, weight: .medium))
                                .foregroundStyle(OG.accent)
                                .frame(width: 58, height: 58)
                                .glassEffect(.regular.interactive(), in: .circle)
                            Text(recorder.sport.title)
                                .font(.caption2.weight(.medium))
                                .lineLimit(1).minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Elegir actividad: \(recorder.sport.title)")

                    Button {
                        if store.hasActiveSession {
                            onOpenWorkout()
                        } else {
                            recorder.start()
                            showingMetrics = recorder.sport.usesGPS
                        }
                    } label: {
                        VStack(spacing: 7) {
                            Image(systemName: store.hasActiveSession ? "arrow.uturn.forward" : "play.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.black)
                                .frame(width: 70, height: 70)
                                .background(OG.accent, in: Circle())
                            Text(store.hasActiveSession ? "Continuar" : "Iniciar")
                                .font(.caption.weight(.bold))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)

                    if recorder.sport.usesGPS {
                        Button {
                            routePicker = true
                        } label: {
                            VStack(spacing: 7) {
                                Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                                    .font(.system(size: 23, weight: .medium))
                                    .foregroundStyle(OG.label)
                                    .frame(width: 58, height: 58)
                                    .glassEffect(.regular.interactive(), in: .circle)
                                Text(recorder.chosenRoute == nil ? "Cargar ruta" : "Ruta elegida")
                                    .font(.caption2.weight(.medium))
                                    .lineLimit(1).minimumScaleFactor(0.7)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear.frame(maxWidth: .infinity).frame(height: 60)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 12)
                .glassEffect(.regular, in: .rect(cornerRadius: 28))

            case .recording:
                Button {
                    recorder.pause()
                } label: {
                    Label("Pausar", systemImage: "pause.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .foregroundStyle(.black)
                        .background(OG.accent, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(12)
                .glassEffect(.regular, in: .rect(cornerRadius: 28))

            case .paused:
                HStack(spacing: 10) {
                    Button {
                        recorder.resume()
                    } label: {
                        Label("Reanudar", systemImage: "play.fill")
                            .font(.subheadline.weight(.bold))
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .foregroundStyle(.black)
                            .background(OG.accent, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    Button {
                        showingFinish = true
                    } label: {
                        Label("Finalizar", systemImage: "flag.checkered")
                            .font(.subheadline.weight(.bold))
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .foregroundStyle(.white)
                            .background(Color.black, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .glassEffect(.regular, in: .rect(cornerRadius: 28))
            case .review:
                EmptyView()
            }
        }
        .foregroundStyle(OG.label)
    }

    private func importResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let fileExtension = url.pathExtension.lowercased()
            guard fileExtension == "gpx" || fileExtension == "xml" else {
                routeError = "Selecciona un recorrido en formato GPX."
                return
            }
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            do {
                let data = try Data(contentsOf: url)
                try routes.addGPX(data: data, name: url.deletingPathExtension().lastPathComponent)
                guard let route = routes.routes.first else { return }
                recorder.selectRoute(route)
                position = .region(routeRegion(route.points))
            } catch let error as LiveRouteError {
                routeError = error.localizedDescription
            } catch {
                routeError = "No se puede leer este archivo. Descárgalo en Archivos o exporta de nuevo la ruta como GPX."
            }
        case .failure(let error):
            // Cerrar el selector de Archivos no es un fallo de la aplicación.
            guard (error as NSError).code != NSUserCancelledError else { return }
            routeError = "No se pudo abrir el archivo. Comprueba que está descargado en Archivos."
        }
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
                    recorder.discard(saved: true)
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
                        importAfterRouteSheet = true
                        routePicker = false
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
            Text(value)
                .font(.system(size: 19, weight: .semibold, design: .rounded).monospacedDigit())
                .lineLimit(1).minimumScaleFactor(0.65)
                .foregroundStyle(OG.label)
            Text(label)
                .font(.caption2).foregroundStyle(OG.label2)
                .lineLimit(1).minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity)
    }
}
