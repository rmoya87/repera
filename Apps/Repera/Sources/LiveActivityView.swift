import AVFoundation
import CoreLocation
import Foundation
import HealthKit
import MapKit
import Observation
import ReperaDomain
import SwiftUI
import UniformTypeIdentifiers
import UIKit
import UserNotifications

/// iCloud Documents is already enabled for Repera (iCloud.com.app.repera).
/// This is a second, route-specific backup: the main workout JSON does not
/// contain imported GPX files or standalone favorite flags.
struct LiveRouteCloudArchive: Codable, Sendable {
    var routes: [LiveSavedRoute]
    var deletedIDs: [UUID]
}

enum LiveRouteCloudRead: Sendable {
    case unavailable
    /// Container is reachable, but has no synchronized route document yet.
    case missing
    case ready(LiveRouteCloudArchive)
}

/// File coordination runs off the main actor. Never replace a remote archive
/// while iCloud is signed out or its existing document is still downloading.
actor LiveRouteCloudBackup {
    static let shared = LiveRouteCloudBackup()
    private let containerID = "iCloud.com.app.repera"
    private let filename = "LiveRoutes-v2.json"

    private func cloudURL() -> URL? {
        guard let root = FileManager.default.url(
            forUbiquityContainerIdentifier: containerID
        ) else { return nil }
        return root.appendingPathComponent("Documents", isDirectory: true)
            .appendingPathComponent(filename)
    }

    func read() -> LiveRouteCloudRead {
        guard let url = cloudURL() else { return .unavailable }
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else {
            return .missing
        }
        // The file exists in iCloud but may not yet have downloaded on a
        // newly installed phone. In that case DO NOT upload the empty library.
        try? fm.startDownloadingUbiquitousItem(at: url)
        var coordinationError: NSError?
        var data: Data?
        NSFileCoordinator(filePresenter: nil).coordinate(
            readingItemAt: url, options: [], error: &coordinationError
        ) { coordinatedURL in
            data = try? Data(contentsOf: coordinatedURL)
        }
        guard coordinationError == nil,
              let data,
              let archive = try? JSONDecoder().decode(LiveRouteCloudArchive.self, from: data)
        else { return .unavailable }
        return .ready(archive)
    }

    @discardableResult
    func write(_ archive: LiveRouteCloudArchive) -> Bool {
        guard let url = cloudURL(),
              let data = try? JSONEncoder().encode(archive) else { return false }
        let fm = FileManager.default
        do {
            try fm.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true
            )
        } catch { return false }
        var coordinationError: NSError?
        var writeError: Error?
        let options: NSFileCoordinator.WritingOptions = fm.fileExists(atPath: url.path)
            ? .forReplacing : []
        NSFileCoordinator(filePresenter: nil).coordinate(
            writingItemAt: url, options: options, error: &coordinationError
        ) { coordinatedURL in
            do {
                try data.write(to: coordinatedURL, options: .atomic)
            } catch {
                writeError = error
            }
        }
        return coordinationError == nil && writeError == nil
    }
}

/// El deporte determina qué se mide; no se infiere del nombre del entrenamiento.
enum LiveSport: String, CaseIterable, Identifiable {
    // Conservar todos los rawValue anteriores: son identificadores persistidos
    // en WorkoutSession, favoritos GPX y las sesiones interrumpidas.
    case running, cycling, walking, hiking, trail, mountainBike, gravel
    case crossfit, strength, hiit, hyrox, tennis, padel, surfing, swimming
    case windsurfing, kitesurfing, kayaking, rowing, canoeing, sailing
    case golf, skiing, iceSkating, snowboarding, crossCountrySkiing
    case soccer, basketball, volleyball
    case climbing, dance, pilates, skateboarding
    case boxing, kickboxing, martialArts, wrestling
    case badminton, pickleball, squash
    case functionalStrength, coreTraining, elliptical, stairClimbing
    case americanFootball, baseball, softball, hockey, lacrosse, rugby
    case yoga, mobility, other

    static let groups = [
        "A pie", "Ciclismo", "Fuerza y fitness", "Deportes de raqueta",
        "Deportes acuáticos", "Deportes de invierno", "Deportes de equipo",
        "Combate", "Cardio y gimnasio", "Otros deportes"
    ]

    var id: String { rawValue }

    /// Mantener también Bicicleta gravel y Otra actividad como opción de
    /// respaldo: ninguna disciplina queda bloqueada por falta de un nombre
    /// específico. Los datos reales siguen procediendo de HealthKit.
    var isSelectable: Bool { true }

    /// Única fuente de verdad para Elegir actividad y Elegir deporte:
    /// orden alfabético localizado dentro de cada sección.
    static let selectableCases = allCases
        .filter(\.isSelectable)
        .sorted {
            let order = $0.title.localizedStandardCompare($1.title)
            return order == .orderedSame ? $0.rawValue < $1.rawValue : order == .orderedAscending
        }

    var title: String {
        switch self {
        case .running: "Carrera"
        case .cycling: "Ciclismo de carretera"
        case .walking: "Caminata"
        case .hiking: "Senderismo"
        case .trail: "Carrera de montaña"
        case .mountainBike: "Ciclismo de montaña"
        case .gravel: "Bicicleta de gravel"
        case .crossfit: "CrossFit"
        case .strength: "Entrenamiento"
        case .hiit: "HIIT"
        case .hyrox: "HYROX"
        case .tennis: "Tenis"
        case .padel: "Pádel"
        case .surfing: "Surf"
        case .swimming: "Natación"
        case .windsurfing: "Windsurf"
        case .kitesurfing: "Kitesurf"
        case .kayaking: "Kayak"
        case .rowing: "Remo"
        case .canoeing: "Piragua"
        case .sailing: "Vela"
        case .golf: "Golf"
        case .skiing: "Esquí alpino"
        case .iceSkating: "Patinaje sobre hielo"
        case .snowboarding: "Snowboard"
        case .crossCountrySkiing: "Esquí de fondo"
        case .soccer: "Fútbol"
        case .basketball: "Baloncesto"
        case .volleyball: "Voleibol"
        case .climbing: "Escalada"
        case .dance: "Baile"
        case .pilates: "Pilates"
        case .skateboarding: "Skateboard"
        case .yoga: "Yoga"
        case .mobility: "Movilidad"
        case .boxing: "Boxeo"
        case .kickboxing: "Kickboxing"
        case .martialArts: "Artes marciales"
        case .wrestling: "Lucha"
        case .badminton: "Bádminton"
        case .pickleball: "Pickleball"
        case .squash: "Squash"
        case .functionalStrength: "Fuerza funcional"
        case .coreTraining: "Core"
        case .elliptical: "Elíptica"
        case .stairClimbing: "Subida de escaleras"
        case .americanFootball: "Fútbol americano"
        case .baseball: "Béisbol"
        case .softball: "Sóftbol"
        case .hockey: "Hockey"
        case .lacrosse: "Lacrosse"
        case .rugby: "Rugby"
        case .other: "Otra actividad"
        }
    }

    var symbol: String {
        switch self {
        case .running, .trail: "figure.run"
        case .cycling: "figure.outdoor.cycle"
        case .mountainBike, .gravel: "bicycle"
        case .walking: "figure.walk"
        case .hiking: "figure.hiking"
        case .crossfit: "figure.cross.training"
        case .hyrox: ExerciseCategorySymbols.discipline("HYROX")
        case .strength: "dumbbell"
        case .hiit: "timer"
        case .tennis: "tennis.racket"
        case .padel: "figure.tennis"
        case .surfing: "surfboard"
        case .swimming: "figure.pool.swim"
        case .windsurfing: "figure.sailing"
        case .kitesurfing: "figure.surfing"
        case .kayaking: "figure.rower"
        case .rowing: "figure.outdoor.rowing"
        case .canoeing: "oar.2.crossed"
        case .sailing: "sailboat"
        case .golf: "figure.golf"
        case .skiing: "figure.skiing.downhill"
        case .iceSkating: "figure.ice.skating"
        case .skateboarding: "figure.skating"
        case .snowboarding: "figure.snowboarding"
        case .crossCountrySkiing: "figure.skiing.crosscountry"
        case .soccer: "soccerball"
        case .basketball: "basketball"
        case .volleyball: "volleyball"
        case .climbing: "figure.climbing"
        case .dance: "figure.dance"
        case .pilates: "figure.pilates"
        case .yoga: "figure.yoga"
        case .mobility: "figure.flexibility"
        case .boxing, .kickboxing: "figure.boxing"
        case .martialArts, .wrestling: "figure.martial.arts"
        case .badminton, .pickleball, .squash: "figure.tennis"
        case .functionalStrength: "dumbbell"
        case .coreTraining: "figure.core.training"
        case .elliptical, .stairClimbing: "figure.mixed.cardio"
        case .americanFootball, .baseball, .softball, .hockey, .lacrosse, .rugby: "sportscourt"
        case .other: "figure.mixed.cardio"
        }
    }

    var group: String {
        switch self {
        case .running, .trail, .walking, .hiking: "A pie"
        case .cycling, .mountainBike, .gravel: "Ciclismo"
        case .crossfit, .strength, .hiit, .hyrox: "Fuerza y fitness"
        case .tennis, .padel, .badminton, .pickleball, .squash: "Deportes de raqueta"
        case .surfing, .swimming, .windsurfing, .kitesurfing,
             .kayaking, .rowing, .canoeing, .sailing: "Deportes acuáticos"
        case .skiing, .iceSkating, .snowboarding, .crossCountrySkiing: "Deportes de invierno"
        case .soccer, .basketball, .volleyball, .americanFootball,
             .baseball, .softball, .hockey, .lacrosse, .rugby: "Deportes de equipo"
        case .boxing, .kickboxing, .martialArts, .wrestling: "Combate"
        case .functionalStrength, .coreTraining, .elliptical, .stairClimbing: "Cardio y gimnasio"
        default: "Otros deportes"
        }
    }

    /// GPS únicamente para modalidades con recorrido exterior verificable.
    /// Ni la piscina, las pistas ni la escalada interior fabrican distancia.
    var usesGPS: Bool {
        switch self {
        case .running, .cycling, .walking, .hiking, .trail, .mountainBike,
             .gravel, .surfing, .windsurfing, .kitesurfing, .kayaking,
             .rowing, .canoeing, .sailing, .golf, .skiing,
             .snowboarding, .crossCountrySkiing, .skateboarding:
            true
        default: false
        }
    }

    var isCycling: Bool { self == .cycling || self == .mountainBike || self == .gravel }
    var isWaterSport: Bool {
        switch self {
        case .surfing, .swimming, .windsurfing, .kitesurfing,
             .kayaking, .rowing, .canoeing, .sailing: true
        default: false
        }
    }

    var displaysSpeed: Bool {
        switch self {
        case .cycling, .mountainBike, .gravel, .surfing, .windsurfing,
             .kitesurfing, .kayaking, .rowing, .canoeing, .sailing,
             .golf, .skiing, .snowboarding, .crossCountrySkiing, .skateboarding:
            true
        default: false
        }
    }

    /// Un salto medio tras un cierre debe ser razonable para el deporte.
    /// No usar el límite más permisivo de picos GPS reales.
    var recoveryMaximumSpeedMps: Double {
        switch self {
        case .walking, .hiking, .golf: 2.8
        case .running, .trail: 7.5
        case .cycling, .mountainBike, .gravel: 20
        case .skiing, .snowboarding, .windsurfing, .kitesurfing: 35
        default: min(12, maxGPSMetersPerSecond)
        }
    }

    /// Solo calcular desnivel cuando la actividad tiene sentido en pendiente.
    var tracksElevation: Bool {
        switch self {
        case .hiking, .trail, .mountainBike, .skiing,
             .snowboarding, .crossCountrySkiing:
            true
        default: false
        }
    }

    /// Evita descartar las muestras auténticas de deportes rápidos como
    /// kitesurf y esquí, manteniendo el filtro de saltos GPS.
    var maxGPSMetersPerSecond: Double {
        switch self {
        case .skiing, .snowboarding: 50
        case .windsurfing, .kitesurfing, .sailing: 42
        case .crossCountrySkiing, .skateboarding: 24
        case .cycling, .mountainBike, .gravel: 22
        default: 12
        }
    }

    /// Las métricas de sensores se muestran únicamente cuando existen datos
    /// reales en Apple Salud, nunca como un contador simulado.
    var metricDescription: String {
        if usesGPS {
            let motion = displaysSpeed ? "velocidad" : "ritmo"
            return tracksElevation
                ? "Tiempo · distancia · \(motion) · desnivel GPS"
                : "Tiempo · distancia · \(motion)"
        }
        return "Tiempo · pulso y calorías si están disponibles"
    }

    var healthType: HKWorkoutActivityType {
        switch self {
        case .running, .trail: .running
        case .cycling, .mountainBike, .gravel: .cycling
        case .walking: .walking
        case .hiking: .hiking
        case .crossfit, .hyrox: .crossTraining
        case .strength: .traditionalStrengthTraining
        case .functionalStrength: .functionalStrengthTraining
        case .coreTraining: .coreTraining
        case .elliptical: .elliptical
        case .stairClimbing: .stairClimbing
        case .hiit: .highIntensityIntervalTraining
        case .tennis, .padel: .tennis
        case .badminton: .badminton
        case .pickleball: .pickleball
        case .squash: .squash
        case .surfing: .surfingSports
        case .windsurfing, .kitesurfing: .surfingSports
        case .swimming: .swimming
        case .kayaking, .canoeing: .paddleSports
        case .rowing: .rowing
        case .sailing: .sailing
        case .golf: .golf
        case .skiing: .downhillSkiing
        case .iceSkating, .skateboarding: .skatingSports
        case .snowboarding: .snowboarding
        case .crossCountrySkiing: .crossCountrySkiing
        case .soccer: .soccer
        case .basketball: .basketball
        case .volleyball: .volleyball
        case .americanFootball: .americanFootball
        case .baseball: .baseball
        case .softball: .softball
        case .hockey: .hockey
        case .lacrosse: .lacrosse
        case .rugby: .rugby
        case .boxing: .boxing
        case .kickboxing: .kickboxing
        case .martialArts: .martialArts
        case .wrestling: .wrestling
        case .climbing: .climbing
        case .dance: .cardioDance
        case .pilates: .pilates
        case .yoga: .yoga
        case .mobility: .flexibility
        case .other: .other
        }
    }
}

struct LiveSavedRoute: Identifiable, Codable, Sendable, Equatable {
    var id: UUID
    var title: String
    var points: [WorkoutRoutePoint]
    /// Nil para GPX importados sin deporte asignado.
    var sportID: String?
    var isFavorite: Bool
    var createdAt: Date
    /// Updated metadata provides a stable conflict order for cloud favorites.
    var modifiedAt: Date

    init(
        id: UUID = UUID(), title: String, points: [WorkoutRoutePoint],
        sportID: String? = nil, isFavorite: Bool = false, createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.points = points
        self.sportID = sportID
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.modifiedAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, points, sportID, isFavorite, createdAt, modifiedAt
    }

    /// Los GPX y las rutas de versiones anteriores carecen de favorito/fecha.
    /// No convertir automáticamente todas las rutas antiguas en favoritas.
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        title = try values.decode(String.self, forKey: .title)
        points = try values.decode([WorkoutRoutePoint].self, forKey: .points)
        sportID = try values.decodeIfPresent(String.self, forKey: .sportID)
        isFavorite = try values.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        createdAt = try values.decodeIfPresent(Date.self, forKey: .createdAt) ?? .distantPast
        modifiedAt = try values.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? createdAt
    }

    var distanceKm: Double {
        guard points.count > 1 else { return 0 }
        let meters = zip(points, points.dropFirst()).reduce(0.0) { sum, pair in
            let a = CLLocation(latitude: pair.0.latitude, longitude: pair.0.longitude)
            let b = CLLocation(latitude: pair.1.latitude, longitude: pair.1.longitude)
            return sum + a.distance(from: b)
        }
        return meters / 1000
    }

    var sportTitle: String {
        sportID.flatMap(LiveSport.init(rawValue:))?.title ?? "Sin deporte"
    }
}

/// Biblioteca offline pequeña de GPX; los recorridos completados se conservan en cada WorkoutSession.
@MainActor
@Observable
final class LiveRoutesStore {
    static let shared = LiveRoutesStore()
    private(set) var routes: [LiveSavedRoute] = []
    private(set) var iCloudRouteStatus = "Rutas guardadas localmente · iCloud pendiente"
    @ObservationIgnored private var cloudSyncTask: Task<Void, Never>?
    @ObservationIgnored private var isCloudSynchronizationRunning = false
    @ObservationIgnored private var cloudSyncRequestedAgain = false
    @ObservationIgnored private var hadRouteFileAtLaunch = false
    @ObservationIgnored private var didEditRouteLocally = false

    /// Lo más reciente primero; el orden anterior se conserva al migrar sin fecha.
    var latestRoutes: [LiveSavedRoute] {
        routes.enumerated().sorted { lhs, rhs in
            lhs.element.createdAt == rhs.element.createdAt
                ? lhs.offset < rhs.offset
                : lhs.element.createdAt > rhs.element.createdAt
        }.map { $0.element }
    }

    /// Una ruta repetida vuelve a la parte superior aunque se importara hace meses.
    func recentRoutes(using workouts: [WorkoutSession]) -> [LiveSavedRoute] {
        var lastActivity: [UUID: Date] = [:]
        for workout in workouts where workout.phase == .finished {
            guard let id = workout.liveRouteID else { continue }
            let date = workout.startedAt ?? workout.finishedAt ?? .distantPast
            if date > (lastActivity[id] ?? .distantPast) {
                lastActivity[id] = date
            }
        }
        return routes.enumerated().sorted { lhs, rhs in
            let left = max(lhs.element.createdAt, lastActivity[lhs.element.id] ?? .distantPast)
            let right = max(rhs.element.createdAt, lastActivity[rhs.element.id] ?? .distantPast)
            return left == right ? lhs.offset < rhs.offset : left > right
        }.map { $0.element }
    }

    var favoriteRoutes: [LiveSavedRoute] {
        latestRoutes.filter(\.isFavorite)
    }
    private let legacyKey = "repera.live.routes.v1"
    /// Tombstones: deleting a saved route must not recreate it on cloud sync.
    private let deletedRoutesKey = "repera.live.routes.deleted.v1"
    private var deletedIDs: Set<UUID> {
        Set((UserDefaults.standard.stringArray(forKey: deletedRoutesKey) ?? [])
            .compactMap(UUID.init(uuidString:)))
    }
    /// GPX de miles de puntos no debe almacenarse en UserDefaults (plist en memoria).
    private let storageURL: URL = {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("LiveRoutes.json")
    }()

    private init() {
        hadRouteFileAtLaunch = FileManager.default.fileExists(atPath: storageURL.path)
        if let data = try? Data(contentsOf: storageURL),
           let saved = try? JSONDecoder().decode([LiveSavedRoute].self, from: data) {
            routes = saved
        } else if let oldData = UserDefaults.standard.data(forKey: legacyKey),
                  let previous = try? JSONDecoder().decode([LiveSavedRoute].self, from: oldData) {
            // Migrar rutas anteriores una sola vez sin perder los archivos importados.
            routes = previous
            if (try? persist()) != nil {
                UserDefaults.standard.removeObject(forKey: legacyKey)
            }
        }
    }

    func addGPX(data: Data, name: String) throws {
        let parser = LiveGPXParser()
        let points = try parser.parse(data)
        guard points.count >= 2 else { throw LiveRouteError.empty }
        let previous = routes
        routes.insert(LiveSavedRoute(title: name, points: points), at: 0)
        do {
            try persist()
        } catch {
            routes = previous
            throw error
        }
    }

    /// Crea una ruta favorita estable a partir de una sesión real con GPS.
    func addRecordedRoute(from session: WorkoutSession, favorite: Bool = false) throws -> UUID {
        guard session.routePoints.count >= 2,
              let sportID = session.liveSportID else { throw LiveRouteError.empty }
        let previous = routes
        let favorite = LiveSavedRoute(
            title: session.title, points: session.routePoints, sportID: sportID,
            isFavorite: favorite, createdAt: session.startedAt ?? .now
        )
        routes.insert(favorite, at: 0)
        do {
            try persist()
            return favorite.id
        } catch {
            routes = previous
            throw error
        }
    }

    /// Editar metadatos mantiene el UUID y, por tanto, el histórico de intentos.
    func update(_ id: UUID, title: String, sportID: String?) throws {
        guard let index = routes.firstIndex(where: { $0.id == id }) else { return }
        let cleanName = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { throw LiveRouteError.emptyName }
        let previous = routes
        routes[index].title = cleanName
        routes[index].sportID = sportID
        routes[index].modifiedAt = .now
        do {
            try persist()
        } catch {
            routes = previous
            throw error
        }
    }

    /// La estrella se persiste en el mismo archivo local, sin modificar el GPX.
    func setFavorite(_ id: UUID, _ favorite: Bool) throws {
        guard let index = routes.firstIndex(where: { $0.id == id }) else { return }
        let previous = routes
        routes[index].isFavorite = favorite
        routes[index].modifiedAt = .now
        do {
            try persist()
        } catch {
            routes = previous
            throw error
        }
    }

    /// Recupera favoritos vinculados a sesiones sincronizadas por iCloud, sin
    /// renumerar el identificador del recorrido ni duplicarlo en dispositivos nuevos.
    func recoverFromSessions(_ sessions: [WorkoutSession]) {
        var known = Set(routes.map(\.id)).union(deletedIDs)
        var recovered: [LiveSavedRoute] = []
        for session in sessions.sorted(by: {
            ($0.startedAt ?? .distantPast) < ($1.startedAt ?? .distantPast)
        }) {
            guard let id = session.liveRouteID, !known.contains(id),
                  session.routePoints.count >= 2 else { continue }
            recovered.append(
                LiveSavedRoute(id: id, title: session.title,
                               points: session.routePoints, sportID: session.liveSportID)
            )
            known.insert(id)
        }
        guard !recovered.isEmpty else { return }
        let previous = routes
        routes.append(contentsOf: recovered)
        do {
            try persist(markUserAction: false)
        } catch {
            routes = previous
        }
    }

    func remove(_ id: UUID) throws {
        let previous = routes
        routes.removeAll { $0.id == id }
        do {
            // The tombstone MUST be durable before scheduling an iCloud read.
            // Otherwise that read can reintroduce the deleted route.
            try persist(scheduleCloud: false)
            var deleted = deletedIDs
            deleted.insert(id)
            UserDefaults.standard.set(deleted.map { $0.uuidString }, forKey: deletedRoutesKey)
            didEditRouteLocally = true
            iCloudRouteStatus = "Sincronizando rutas con iCloud…"
            requestICloudSynchronization()
        } catch {
            routes = previous
            throw error
        }
    }

    private func persist(
        scheduleCloud: Bool = true, markUserAction: Bool = true
    ) throws {
        let folder = storageURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: folder, withIntermediateDirectories: true
        )
        let data = try JSONEncoder().encode(routes)
        try data.write(to: storageURL, options: .atomic)
        if scheduleCloud {
            if markUserAction { didEditRouteLocally = true }
            iCloudRouteStatus = "Sincronizando rutas con iCloud…"
            requestICloudSynchronization()
        }
    }

    /// Merge before upload: an iCloud file still downloading must never be
    /// replaced by an empty first-install local library.
    func requestICloudSynchronization() {
        cloudSyncTask?.cancel()
        cloudSyncTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.synchronizeWithICloud()
        }
    }

    func synchronizeWithICloud() async {
        // If a star or a fresh GPS route is saved while another iCloud
        // download is pending, replay once afterward to avoid losing it.
        if isCloudSynchronizationRunning {
            cloudSyncRequestedAgain = true
            return
        }
        isCloudSynchronizationRunning = true
        defer {
            isCloudSynchronizationRunning = false
            if cloudSyncRequestedAgain {
                cloudSyncRequestedAgain = false
                requestICloudSynchronization()
            }
        }
        let read = await LiveRouteCloudBackup.shared.read()
        let remote: LiveRouteCloudArchive
        switch read {
        case .ready(let existing):
            remote = existing
        case .unavailable:
            iCloudRouteStatus = "Rutas guardadas localmente · iCloud pendiente"
            return
        case .missing:
            // A newly installed phone can see the iCloud directory before
            // the route document metadata arrives. Never replace a missing
            // cloud document with an empty first-install local archive.
            guard (!routes.isEmpty || !deletedIDs.isEmpty)
                && (hadRouteFileAtLaunch || didEditRouteLocally) else {
                // Recovering GPS points from the main iCloud workout state
                // on a fresh install is NOT a user-created route archive:
                // do not let it replace imported GPX that is still downloading.
                iCloudRouteStatus = "Esperando rutas de iCloud…"
                return
            }
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            let retry = await LiveRouteCloudBackup.shared.read()
            switch retry {
            case .ready(let existing):
                remote = existing
            case .missing:
                remote = LiveRouteCloudArchive(routes: [], deletedIDs: [])
            case .unavailable:
                iCloudRouteStatus = "Rutas guardadas localmente · iCloud pendiente"
                return
            }
        }

        let erased = deletedIDs.union(remote.deletedIDs)
        var merged: [UUID: LiveSavedRoute] = [:]
        for route in remote.routes + routes where !erased.contains(route.id) {
            if let existing = merged[route.id] {
                if route.modifiedAt > existing.modifiedAt {
                    merged[route.id] = route
                } else if route.modifiedAt == existing.modifiedAt,
                          route.isFavorite && !existing.isFavorite {
                    // Older archives may lack modifiedAt; preserve stars.
                    merged[route.id] = route
                }
            } else {
                merged[route.id] = route
            }
        }
        let newRoutes = merged.values.sorted {
            if $0.createdAt == $1.createdAt {
                return $0.id.uuidString < $1.id.uuidString
            }
            return $0.createdAt > $1.createdAt
        }
        // A route may contain thousands of GPS coordinates. Avoid encoding
        // and writing the entire archive on every foreground switch.
        if newRoutes != routes {
            let previous = routes
            routes = newRoutes
            do {
                try persist(scheduleCloud: false)
            } catch {
                routes = previous
                return
            }
        }
        let oldDeleted = deletedIDs
        if erased != oldDeleted {
            UserDefaults.standard.set(erased.map { $0.uuidString }, forKey: deletedRoutesKey)
        }
        let remoteAlreadyMatches = remote.routes == newRoutes
            && Set(remote.deletedIDs) == erased
        let backedUp: Bool
        if remoteAlreadyMatches {
            backedUp = true
        } else {
            let archive = LiveRouteCloudArchive(
                routes: newRoutes, deletedIDs: Array(erased)
            )
            backedUp = await LiveRouteCloudBackup.shared.write(archive)
        }
        iCloudRouteStatus = backedUp
            ? "Rutas sincronizadas con iCloud"
            : "Rutas guardadas localmente · iCloud pendiente"
    }
}

private enum LiveRouteError: LocalizedError {
    case empty, invalidXML, emptyName

    var errorDescription: String? {
        switch self {
        case .empty: "Este GPX no contiene al menos dos puntos de recorrido."
        case .invalidXML: "El archivo GPX está dañado o no tiene un formato válido."
        case .emptyName: "La ruta necesita un nombre."
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
/// Un parcial confirmado se calcula con tiempo ACTIVO, descontando pausas.
/// La interpolación sobre el cruce de 1 km evita depender de la frecuencia GPS.
private struct LiveKmSplit: Codable, Identifiable, Sendable {
    let kilometer: Int
    let seconds: TimeInterval
    var id: Int { kilometer }

    var clock: String {
        let total = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

private struct LiveRouteTurn: Sendable {
    let routeIndex: Int
    let metersAlongRoute: Double
    let angleDegrees: Double

    var instruction: String {
        if abs(angleDegrees) > 145 { return "Cambio de sentido" }
        return angleDegrees > 0 ? "Gira a la derecha" : "Gira a la izquierda"
    }

    var symbol: String {
        if abs(angleDegrees) > 145 { return "arrow.uturn.backward" }
        return angleDegrees > 0 ? "arrow.turn.up.right" : "arrow.turn.up.left"
    }
}

/// Guía orientativa de GPX. No se inventan calles ni se usa como motor de
/// navegación vial: se detectan cambios de rumbo en la polilínea importada.
private enum LiveGPXTurnDetection {
    static func distance(_ a: WorkoutRoutePoint, _ b: WorkoutRoutePoint) -> Double {
        CLLocation(latitude: a.latitude, longitude: a.longitude).distance(
            from: CLLocation(latitude: b.latitude, longitude: b.longitude)
        )
    }

    private static func bearing(_ a: WorkoutRoutePoint, _ b: WorkoutRoutePoint) -> Double {
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let delta = (b.longitude - a.longitude) * .pi / 180
        let y = sin(delta) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(delta)
        return atan2(y, x) * 180 / .pi
    }

    static func cumulative(_ points: [WorkoutRoutePoint]) -> [Double] {
        guard !points.isEmpty else { return [] }
        var result = [0.0]
        for index in 1..<points.count {
            result.append(result[index - 1] + distance(points[index - 1], points[index]))
        }
        return result
    }

    static func detect(_ points: [WorkoutRoutePoint], along: [Double]) -> [LiveRouteTurn] {
        guard points.count >= 3, along.count == points.count else { return [] }
        var turns: [LiveRouteTurn] = []
        // Analizar como máximo ~1200 vértices sin perder los cambios fuertes de dirección.
        let step = max(1, points.count / 1200)
        for index in stride(from: 1, to: points.count - 1, by: step) {
            let at = along[index]
            // Analizar el rumbo a ~30 m a ambos lados de un vértice.
            // Los GPX de alta densidad tienen vértices cada 1–5 m y no
            // producirían indicaciones con solo usar los vecinos inmediatos.
            var before = index - 1
            var after = index + 1
            while before > 0 && at - along[before] < 30 { before -= 1 }
            while after < points.count - 1 && along[after] - at < 30 { after += 1 }
            guard at - along[before] >= 20, along[after] - at >= 20 else { continue }
            let oldBearing = bearing(points[before], points[index])
            let newBearing = bearing(points[index], points[after])
            let delta = (newBearing - oldBearing + 540)
                .truncatingRemainder(dividingBy: 360) - 180
            guard abs(delta) >= 52 else { continue }
            let item = LiveRouteTurn(
                routeIndex: index, metersAlongRoute: at, angleDegrees: delta
            )
            if let last = turns.last, at - last.metersAlongRoute < 55 {
                if abs(delta) > abs(last.angleDegrees) { turns[turns.count - 1] = item }
            } else {
                turns.append(item)
            }
        }
        return turns
    }
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
    var kilometerSplits: [LiveKmSplit]?
    var lastKilometerBoundarySeconds: TimeInterval?
    var gpsSessionID: UUID?
    /// Total distance extrapolated over unrecorded gaps, explicitly distinct.
    var estimatedRecoveryMeters: Double?
}

/// La grabación no depende de que SwiftUI mantenga abierta la pestaña.
@MainActor
@Observable
final class LiveActivityRecorder: NSObject {
    static let shared = LiveActivityRecorder()

    enum Phase: String { case idle, recording, paused, review }
    private(set) var phase: Phase = .idle
    /// Cuenta atrás visual/sonora de tres segundos antes de abrir GPS y Salud.
    private(set) var startCountdownRemaining = 0
    @ObservationIgnored private var startCountdownTask: Task<Void, Never>?
    private var startCountdownID = UUID()
    var isStartCountingDown: Bool { startCountdownRemaining > 0 }
    private(set) var sport: LiveSport = .running
    private(set) var startedAt: Date?
    private(set) var finishedAt: Date?
    private(set) var pausedAt: Date?
    private(set) var pausedSeconds: TimeInterval = 0
    private(set) var recordedDistanceMeters: Double = 0
    private(set) var routePoints: [WorkoutRoutePoint] = []
    private(set) var elevationGainMeters: Double = 0
    private(set) var elevationLossMeters: Double = 0
    private var elevationReferenceMeters: Double?
    var hasElevationSamples: Bool { elevationReferenceMeters != nil }
    private(set) var currentCoordinate: CLLocationCoordinate2D?
    private(set) var currentSpeedMps: Double?
    private(set) var currentCourseDegrees: Double?
    private(set) var gpsMessage: String?
    private(set) var chosenRoute: LiveSavedRoute?
    private var kilometerSplits: [LiveKmSplit] = []
    private(set) var latestKilometerReport: String?
    private(set) var upcomingTurn: String?
    private(set) var upcomingTurnInstruction: String?
    private(set) var upcomingTurnMeters: Int?
    private(set) var upcomingTurnSymbol: String = "arrow.up"
    private(set) var followingTurnMeters: Int?
    private(set) var followingTurnSymbol: String?
    private(set) var upcomingTurnStreet: String?
    private var streetNamesByTurn: [Int: String] = [:]
    private var lastStreetTurnIndex: Int?
    @ObservationIgnored private var streetRequest: MKReverseGeocodingRequest?
    /// El widget recibe únicamente la próxima maniobra; no recibe el GPX.
    var navigationCue: TrainingActivityAttributes.ContentState.NavigationCue? {
        guard sport.usesGPS, chosenRoute != nil else { return nil }
        return .init(
            instruction: upcomingTurnInstruction ?? upcomingTurn ??
                (phase == .idle ? "Ruta cargada" : "Esperando ubicación"),
            street: upcomingTurnStreet, distanceMeters: upcomingTurnMeters,
            symbol: upcomingTurnSymbol,
            isOffRoute: upcomingTurn?.hasPrefix("Fuera de ruta") == true
        )
    }
    private var lastKilometerBoundarySeconds: TimeInterval = 0
    private var previousFixActiveSeconds: TimeInterval?
    private var selectedRouteDistance: [Double] = []
    private var selectedRouteTurns: [LiveRouteTurn] = []
    private var announcedTurnIndices: Set<Int> = []
    // Los avisos por voz son opt-out; las notificaciones de segundo plano
    // siguen dependiendo del permiso del usuario.
    private let spokenGuidanceKey = "repera.live.spokenGuidance.enabled"
    @ObservationIgnored private var speechSynthesizer = AVSpeechSynthesizer()
    private var guidanceAudioActive = false
    /// No cerrar AVAudioSession entre dos frases que AVSpeechSynthesizer ha encolado.
    private var pendingGuidanceUtterances: Set<ObjectIdentifier> = []
    private(set) var spokenGuidanceEnabled = true
    private var gpsSessionID = UUID()
    /// Recuperación exclusiva de una grabación interrumpida, no una pausa.
    private var needsInterruptedGPSRecovery = false
    private(set) var estimatedRecoveryMeters: Double = 0
    private var lastSave = Date.distantPast
    private var lastLiveActivityUpdate = Date.distantPast
    private var lastPublishedDistanceMeters: Double = 0
    private let snapshotKey = "repera.live.current.v1"

    private override init() {
        super.init()
        speechSynthesizer.delegate = self
        if UserDefaults.standard.object(forKey: spokenGuidanceKey) != nil {
            spokenGuidanceEnabled = UserDefaults.standard.bool(forKey: spokenGuidanceKey)
        }
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
            estimatedRecoveryMeters = snapshot.estimatedRecoveryMeters ?? 0
            rebuildElevationFromRoute()
            gpsSessionID = snapshot.gpsSessionID ?? UUID()
            // The independent GPS checkpoint may include later fixes than the
            // UI snapshot, especially after a sudden process termination.
            if let gps = WorkoutLocationTracker.shared.restoreForResume(sessionID: gpsSessionID),
               gps.points.count > routePoints.count {
                routePoints = gps.points
                recordedDistanceMeters = max(recordedDistanceMeters, gps.meters)
                rebuildElevationFromRoute()
            }
            kilometerSplits = snapshot.kilometerSplits ?? []
            lastKilometerBoundarySeconds = snapshot.lastKilometerBoundarySeconds ?? 0
            latestKilometerReport = kilometerSplits.last.map {
                "Km \($0.kilometer) · \($0.clock) min/km"
            }
            currentCoordinate = routePoints.last.map {
                CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
            }
            chosenRoute = snapshot.selectedRouteID.flatMap { id in
                LiveRoutesStore.shared.routes.first { $0.id == id }
            }
            prepareRouteNavigation()
            // Si iOS terminó el proceso durante una grabación reciente,
            // recuperar tiempo y GPS; las pausas manuales se mantienen pausadas.
            let age = Date().timeIntervalSince(snapshot.savedAt)
            needsInterruptedGPSRecovery = snapshot.phase == Phase.recording.rawValue
                && age >= 0 && age <= 2 * 60 * 60
            if needsInterruptedGPSRecovery {
                phase = .recording
                pausedAt = nil
                // Reconstruct the missing time of each estimated kilometre
                // between the last authentic fix and the next GPS contact.
                previousFixActiveSeconds = routePoints.last.map {
                    max(0, $0.recordedAt.timeIntervalSince(snapshot.startedAt) - pausedSeconds)
                }
            } else {
                phase = .paused
            }
        } else if let savedSport = UserDefaults.standard.string(forKey: "repera.live.lastSport"),
                  let restored = LiveSport(rawValue: savedSport) {
            sport = restored
        }
        if phase != .idle {
            Task { @MainActor [weak self] in self?.updateLiveActivity() }
        }
    }

    var isActive: Bool { phase != .idle }

    /// Tras relanzar el proceso, restaurar el sensor sin pulsar Iniciar.
    func resumeInterruptedRecordingIfNeeded() {
        guard needsInterruptedGPSRecovery, phase == .recording else { return }
        needsInterruptedGPSRecovery = false
        if sport.usesGPS { startGPS(bridgingInterruption: true) }
        persistSnapshot()
        updateLiveActivity()
    }

    func toggleSpokenGuidance() {
        spokenGuidanceEnabled.toggle()
        UserDefaults.standard.set(spokenGuidanceEnabled, forKey: spokenGuidanceKey)
        if !spokenGuidanceEnabled {
            stopGuidanceAudio()
            // Los avisos visuales son alternativos a la locución, no duplicados.
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, _ in }
        }
    }

    /// La API pública no permite seleccionar las voces privadas de Siri.
    /// Preferir la voz española de mayor calidad instalada en este dispositivo.
    private var preferredGuidanceVoice: AVSpeechSynthesisVoice? {
        let spanish = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == "es-ES" }
        return spanish.first(where: { $0.quality == .premium })
            ?? spanish.first(where: { $0.quality == .enhanced })
            ?? AVSpeechSynthesisVoice(language: "es-ES")
    }

    private func deactivateGuidanceAudio() {
        // didFinish puede llegar entre dos utterances. La sesión sigue activa
        // hasta que todas las locuciones pendientes hayan terminado/cancelado.
        guard pendingGuidanceUtterances.isEmpty, guidanceAudioActive else { return }
        guidanceAudioActive = false
        do {
            try AVAudioSession.sharedInstance().setActive(
                false, options: .notifyOthersOnDeactivation
            )
        } catch {
            NSLog("[Repera] No se pudo liberar el audio de navegación: %@", String(describing: error))
        }
    }

    private func stopGuidanceAudio() {
        // Limpiar ANTES de cancelar; los callbacks didCancel pueden llegar tarde
        // y no deben afectar a una nueva sesión o una nueva cola.
        pendingGuidanceUtterances.removeAll()
        speechSynthesizer.stopSpeaking(at: .immediate)
        deactivateGuidanceAudio()
    }

    private func finishGuidanceUtterance(_ id: ObjectIdentifier) {
        guard pendingGuidanceUtterances.remove(id) != nil else { return }
        deactivateGuidanceAudio()
    }

    /// Core Location sigue entregando cruces de km con iPhone bloqueado.
    /// La categoría playback y UIBackgroundModes(audio + location) permiten
    /// locutar sin depender del ciclo de vida de la vista SwiftUI.
    @discardableResult
    private func speakNavigation(_ message: String) -> Bool {
        guard spokenGuidanceEnabled, !message.isEmpty else { return false }
        // Reconfigurar/activar el audio en cada km o giro puede interrumpir
        // frases que ya estén sonando (especialmente fixes GPS en lote).
        if !guidanceAudioActive {
            let audio = AVAudioSession.sharedInstance()
            do {
                try audio.setCategory(
                    .playback, mode: .spokenAudio,
                    // Preservar el comportamiento elegido: pausar otros audios
                    // mientras suena la indicación, no mezclarlos.
                    options: []
                )
                try audio.setActive(true)
                guidanceAudioActive = true
            } catch {
                NSLog("[Repera] No se pudo activar audio de navegación: %@", String(describing: error))
                return false
            }
        }
        let phrase = AVSpeechUtterance(string: message)
        phrase.voice = preferredGuidanceVoice
        phrase.rate = 0.52
        phrase.pitchMultiplier = 1.0
        phrase.preUtteranceDelay = 0.04
        phrase.volume = 1
        pendingGuidanceUtterances.insert(ObjectIdentifier(phrase))
        speechSynthesizer.speak(phrase)
        return true
    }

    func choose(_ selection: LiveSport) {
        guard phase == .idle, !isStartCountingDown else { return }
        sport = selection
        chosenRoute = nil
        prepareRouteNavigation()
        UserDefaults.standard.set(selection.rawValue, forKey: "repera.live.lastSport")
    }

    func selectRoute(_ route: LiveSavedRoute?) {
        guard phase == .idle, !isStartCountingDown else { return }
        chosenRoute = route
        prepareRouteNavigation()
    }

    private func prepareRouteNavigation() {
        clearStreetCue()
        streetNamesByTurn = [:]
        let points = chosenRoute?.points ?? []
        selectedRouteDistance = LiveGPXTurnDetection.cumulative(points)
        selectedRouteTurns = LiveGPXTurnDetection.detect(
            points, along: selectedRouteDistance
        )
        announcedTurnIndices = []
        upcomingTurn = chosenRoute == nil ? nil : "Ruta cargada"
        upcomingTurnInstruction = nil
        upcomingTurnMeters = nil
        upcomingTurnSymbol = "arrow.up"
        followingTurnMeters = nil
        followingTurnSymbol = nil
        if let coordinate = currentCoordinate, chosenRoute != nil {
            updateUpcomingTurn(position: CLLocation(
                latitude: coordinate.latitude, longitude: coordinate.longitude
            ))
        }
    }

    private func clearStreetCue() {
        streetRequest?.cancel()
        streetRequest = nil
        lastStreetTurnIndex = nil
        upcomingTurnStreet = nil
    }

    /// Consulta una vez por maniobra la vía situada DESPUÉS del giro. Los nombres
    /// proceden de MapKit y pueden faltar (senderos, GPX sin calles o sin red).
    /// Nunca sustituimos la geometría del GPX por una ruta de coche distinta.
    private func resolveStreet(for turn: LiveRouteTurn, on route: LiveSavedRoute) {
        guard lastStreetTurnIndex != turn.routeIndex else { return }
        clearStreetCue()
        lastStreetTurnIndex = turn.routeIndex
        if let cached = streetNamesByTurn[turn.routeIndex] {
            upcomingTurnStreet = cached
            return
        }
        let targetDistance = turn.metersAlongRoute + 25
        let targetIndex = (turn.routeIndex..<route.points.count).first {
            selectedRouteDistance[$0] >= targetDistance
        } ?? min(turn.routeIndex + 1, route.points.count - 1)
        let point = route.points[targetIndex]
        guard let request = MKReverseGeocodingRequest(location: CLLocation(
            latitude: point.latitude, longitude: point.longitude
        )) else { return }
        streetRequest = request
        let routeID = route.id
        let turnIndex = turn.routeIndex
        Task { @MainActor [weak self] in
            let places = try? await request.mapItems
            guard let self, self.chosenRoute?.id == routeID,
                  self.lastStreetTurnIndex == turnIndex,
                  !request.isCancelled else { return }
            self.streetRequest = nil
            guard let street = places?.first?.address?.shortAddress?
                .components(separatedBy: ",").first?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                !street.isEmpty else { return }
            self.streetNamesByTurn[turnIndex] = street
            self.upcomingTurnStreet = street
            if self.phase == .recording || self.phase == .paused {
                self.updateLiveActivity()
            }
        }
    }

    /// Precarga el punto azul sin iniciar ni registrar todavía una sesión.
    func prepareMapLocation() {
        guard phase == .idle, sport.usesGPS else { return }
        Task { @MainActor [weak self] in
            let tracker = WorkoutLocationTracker.shared
            guard await tracker.ensureWhenInUseAuthorized() else {
                self?.gpsMessage = "Activa la ubicación para centrar el mapa."
                return
            }
            if let pin = await tracker.capturePin(), self?.phase == .idle {
                self?.currentCoordinate = CLLocationCoordinate2D(
                    latitude: pin.latitude, longitude: pin.longitude
                )
                self?.gpsMessage = nil
                if self?.chosenRoute != nil {
                    self?.updateUpcomingTurn(position: CLLocation(
                        latitude: pin.latitude, longitude: pin.longitude
                    ))
                }
            }
        }
    }

    /// Los tres pitidos son los del temporizador (RestFeedback.tick).
    /// El tiempo activo y el seguimiento GPS empiezan DESPUÉS de la cuenta.
    /// El UUID evita que una cuenta cancelada reactive la actividad.
    func beginStartCountdown() {
        guard phase == .idle, !isStartCountingDown else { return }
        stopGuidanceAudio()
        let id = UUID()
        startCountdownID = id
        startCountdownRemaining = 3
        RestFeedback.tick(remaining: 3, sound: spokenGuidanceEnabled, haptic: true)
        startCountdownTask = Task { @MainActor [weak self] in
            for second in [2, 1, 0] {
                try? await Task.sleep(for: .seconds(1))
                guard let self, !Task.isCancelled,
                      self.startCountdownID == id, self.phase == .idle else { return }
                self.startCountdownRemaining = second
                if second > 0 {
                    RestFeedback.tick(
                        remaining: second, sound: self.spokenGuidanceEnabled, haptic: true
                    )
                } else {
                    self.startCountdownTask = nil
                    // Mismo aviso de inicio del temporizador al llegar a cero.
                    RestFeedback.restComplete(sound: self.spokenGuidanceEnabled, haptic: true)
                    self.start()
                }
            }
        }
    }

    func cancelStartCountdown() {
        guard isStartCountingDown else { return }
        startCountdownID = UUID()
        startCountdownTask?.cancel()
        startCountdownTask = nil
        startCountdownRemaining = 0
    }

    func start() {
        guard phase == .idle, !isStartCountingDown else { return }
        // Si se inicia otra actividad justo después de guardar, no dejar que
        // el mensaje final anterior tape el nuevo aviso.
        stopGuidanceAudio()
        gpsSessionID = UUID()
        startedAt = Date()
        finishedAt = nil
        pausedAt = nil
        pausedSeconds = 0
        recordedDistanceMeters = 0
        routePoints = []
        estimatedRecoveryMeters = 0
        needsInterruptedGPSRecovery = false
        elevationGainMeters = 0
        elevationLossMeters = 0
        elevationReferenceMeters = nil
        kilometerSplits = []
        latestKilometerReport = nil
        lastKilometerBoundarySeconds = 0
        previousFixActiveSeconds = nil
        announcedTurnIndices = []
        if let coordinate = currentCoordinate, chosenRoute != nil {
            updateUpcomingTurn(position: CLLocation(
                latitude: coordinate.latitude, longitude: coordinate.longitude
            ))
        }
        lastPublishedDistanceMeters = 0
        currentSpeedMps = nil
        currentCourseDegrees = nil
        gpsMessage = nil
        phase = .recording
        let sessionID = gpsSessionID
        let workoutStart = startedAt ?? Date()
        let selectedSport = sport
        Task {
            await HealthKitStore.shared.beginWorkout(
                sessionId: sessionID, title: selectedSport.title, start: workoutStart,
                activityType: selectedSport.healthType,
                locationType: selectedSport.usesGPS ? .outdoor : .indoor
            )
        }
        if sport.usesGPS {
            startGPS()
            Task { await HealthKitStore.shared.ensureWorkoutRouteAccess() }
            if !spokenGuidanceEnabled {
                UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert]
                ) { _, _ in }
            }
        }
        persistSnapshot()
        updateLiveActivity()
        // Sin voz de «Iniciando ...»: la cuenta atrás ya da paso a la sesión.
    }

    private func startGPS(bridgingInterruption: Bool = false) {
        let expected = gpsSessionID
        Task { @MainActor [weak self] in
            let tracker = WorkoutLocationTracker.shared
            guard await tracker.ensureWhenInUseAuthorized() else {
                self?.gpsMessage = "GPS no autorizado. Seguimos registrando el tiempo."
                return
            }
            guard let self, self.phase == .recording, self.gpsSessionID == expected else { return }
            let started = tracker.startRouteTracking(
                sessionID: expected, cycling: self.sport.isCycling,
                maxSpeedMetersPerSecond: self.sport.maxGPSMetersPerSecond,
                existingPoints: self.routePoints,
                existingDistanceMeters: self.recordedDistanceMeters,
                bridgeInterruptedGap: bridgingInterruption,
                recoveryMaximumSpeedMps: self.sport.recoveryMaximumSpeedMps,
                onUpdate: { [weak self] update in self?.receive(update) }
            )
            self.gpsMessage = started ? nil : "Otro entrenamiento ya está utilizando el GPS."
            if started { await HealthKitStore.shared.beginRecordedGPSRoute(sessionID: expected) }
        }
    }

    private func stopGPS(clear: Bool = true) {
        _ = WorkoutLocationTracker.shared.stopRouteTracking(
            sessionID: gpsSessionID, clear: clear
        )
    }

    /// Checkpoint al pasar a segundo plano y mientras la vista está activa.
    func checkpoint(force: Bool = false) {
        if isActive && (force || Date().timeIntervalSince(lastSave) >= 10) {
            persistSnapshot()
        }
    }

    /// Reconciliar los valores al reabrir Comenzar sin reiniciar el odómetro.
    /// La fuente es siempre el grabador GPS; HealthKit no genera datos de
    /// localización retroactivos de un entrenamiento libre de iPhone.
    func refreshWhenActive() {
        guard phase != .idle else { return }
        if phase == .recording, sport.usesGPS {
            // Una nueva lectura rompe el posible silencio del proveedor GPS
            // durante el bloqueo. La distancia sigue sumándose SOLO en receive.
            WorkoutLocationTracker.shared.requestFreshLocation()
        }
        updateLiveActivity()
        checkpoint()
    }

    func pause() {
        guard phase == .recording else { return }
        pausedAt = Date()
        phase = .paused
        if sport.usesGPS { stopGPS(clear: false) }
        // Silenciar cualquier locución de GPS pendiente al pausar.
        // La pausa no reproduce voz ni sonido.
        stopGuidanceAudio()
        currentSpeedMps = nil
        persistSnapshot()
        updateLiveActivity()
    }

    func resume() {
        guard phase == .paused else { return }
        // Cancelar indicaciones antiguas: reanudar no emite voz ni sonido.
        stopGuidanceAudio()
        if let pausedAt { pausedSeconds += Date().timeIntervalSince(pausedAt) }
        pausedAt = nil
        previousFixActiveSeconds = nil
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

    /// Mantiene la velocidad media también al pausar y al finalizar.
    /// Recalcular a partir de distancia verificada y tiempo ACTIVO, nunca
    /// reutilizar una lectura de ritmo almacenada en la interfaz.
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
        stopGPS()
        // No perder «finalizado» detrás de otros kilómetros/giros en cola.
        stopGuidanceAudio()
        persistSnapshot()
        updateLiveActivity()
        // Misma señal final del temporizador; no pronunciar «Finalizado».
        RestFeedback.restComplete(sound: spokenGuidanceEnabled, haptic: true)
    }

    func makeSession(title: String, notes: String) -> WorkoutSession? {
        guard phase == .review, let startedAt, let finishedAt else { return nil }
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return WorkoutSession(
            id: gpsSessionID,
            title: cleaned.isEmpty ? sport.title : cleaned,
            exercises: [],
            phase: .finished,
            startedAt: startedAt,
            finishedAt: max(finishedAt, startedAt.addingTimeInterval(1)),
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
            routePoints: routePoints,
            liveSportID: sport.rawValue,
            liveRouteID: chosenRoute?.id,
            recordedDistanceMeters: sport.usesGPS ? recordedDistanceMeters : nil,
            activeDurationSeconds: durationSeconds,
            liveKilometerSplitsSeconds: kilometerSplits.isEmpty ? nil : kilometerSplits.map(\.seconds)
        )
    }

    func discard(saved: Bool = false) {
        cancelStartCountdown()
        if !saved {
            let sessionID = gpsSessionID
            Task {
                HealthKitStore.shared.discardRecordedGPSRoute(sessionID: sessionID)
                await HealthKitStore.shared.discardLiveTracking()
            }
        }
        if let startedAt {
            Task {
                await WorkoutLiveActivityCoordinator.shared.dismissFree(
                    startedAt: startedAt, saved: saved
                )
            }
        }
        stopGPS()
        // El sonido final del temporizador es un SystemSound independiente
        // del sintetizador; podemos liberar la locución al guardar o descartar.
        stopGuidanceAudio()
        phase = .idle
        needsInterruptedGPSRecovery = false
        estimatedRecoveryMeters = 0
        startedAt = nil
        finishedAt = nil
        pausedAt = nil
        routePoints = []
        recordedDistanceMeters = 0
        elevationGainMeters = 0
        elevationLossMeters = 0
        elevationReferenceMeters = nil
        currentSpeedMps = nil
        currentCourseDegrees = nil
        currentCoordinate = nil
        upcomingTurn = nil
        upcomingTurnInstruction = nil
        upcomingTurnMeters = nil
        followingTurnMeters = nil
        followingTurnSymbol = nil
        clearStreetCue()
        kilometerSplits = []
        latestKilometerReport = nil
        previousFixActiveSeconds = nil
        chosenRoute = nil
        UserDefaults.standard.removeObject(forKey: snapshotKey)
    }

    private func persistSnapshot() {
        guard let start = startedAt, phase != .idle else { return }
        let snap = LiveSnapshot(
            sport: sport.rawValue, phase: phase.rawValue,
            startedAt: start, pausedAt: pausedAt, pausedSeconds: pausedSeconds,
            recordedDistanceMeters: recordedDistanceMeters, routePoints: routePoints,
            savedAt: Date(), selectedRouteID: chosenRoute?.id,
            kilometerSplits: kilometerSplits,
            lastKilometerBoundarySeconds: lastKilometerBoundarySeconds,
            gpsSessionID: gpsSessionID,
            estimatedRecoveryMeters: estimatedRecoveryMeters
        )
        if let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: snapshotKey)
            lastSave = Date()
        }
    }

    /// Shared GPS tracker validates accuracy, jumps, gaps and accumulated
    /// distance ONCE. Free training only updates presentation and split state.
    private func receive(_ update: WorkoutGPSUpdate) {
        guard phase == .recording else { return }
        let fix = update.fix
        currentCoordinate = CLLocationCoordinate2D(latitude: fix.latitude, longitude: fix.longitude)
        currentSpeedMps = fix.speed >= 0 ? fix.speed : nil
        if fix.course >= 0, fix.course < 360, fix.speed > 0.8 {
            currentCourseDegrees = fix.course
        }
        let beforeDistance = recordedDistanceMeters
        recordedDistanceMeters = update.distanceMeters
        let activeSeconds = duration(at: fix.timestamp)
        if recordedDistanceMeters > beforeDistance {
            updateKilometerSplits(
                previousDistance: beforeDistance, activeSeconds: activeSeconds
            )
        }
        previousFixActiveSeconds = activeSeconds
        if !update.bridgedPoints.isEmpty {
            routePoints.append(contentsOf: update.bridgedPoints)
            estimatedRecoveryMeters += update.bridgedDistanceMeters
        }
        routePoints.append(update.point)
        if sport.tracksElevation, let altitude = update.point.altitudeMeters,
           let accuracy = update.point.verticalAccuracyMeters, accuracy <= 15 {
            integrateElevation(altitude)
        }
        updateUpcomingTurn(position: fix.location)
        if Date().timeIntervalSince(lastSave) > 10 { persistSnapshot() }
        if Date().timeIntervalSince(lastLiveActivityUpdate) >= 5 {
            updateLiveActivity()
        }
    }

    /// GPS vertical orientativo: umbral de 3 m para amortiguar ruido.
    /// Los resultados se reconstruyen a partir del recorrido al reabrir la app.
    private func integrateElevation(_ altitude: Double) {
        guard altitude.isFinite, (-500...9000).contains(altitude) else { return }
        if let previous = elevationReferenceMeters {
            let delta = altitude - previous
            guard abs(delta) >= 3, abs(delta) <= 120 else { return }
            if delta > 0 { elevationGainMeters += delta }
            else { elevationLossMeters -= delta }
        }
        elevationReferenceMeters = altitude
    }

    private func rebuildElevationFromRoute() {
        elevationGainMeters = 0
        elevationLossMeters = 0
        elevationReferenceMeters = nil
        guard sport.tracksElevation else { return }
        for point in routePoints {
            if let altitude = point.altitudeMeters {
                integrateElevation(altitude)
            }
        }
    }

    /// Parcial activo (no el promedio de la sesión). La distancia restante
    /// se toma del odómetro GPS filtrado, no del kilometraje teórico del GPX.
    var activeKilometer: Int {
        max(1, Int(recordedDistanceMeters / 1000) + 1)
    }

    var activeKilometerMeters: Double {
        max(0, recordedDistanceMeters - Double(activeKilometer - 1) * 1000)
    }

    func currentSplitSeconds(at date: Date) -> TimeInterval {
        max(0, duration(at: date) - lastKilometerBoundarySeconds)
    }

    var currentKilometerPace: String {
        let meters = activeKilometerMeters
        guard meters >= 40 else { return "—:—" }
        let seconds = currentSplitSeconds(at: Date()) * 1000 / meters
        guard seconds.isFinite && seconds > 0 else { return "—:—" }
        let whole = Int(seconds.rounded())
        return String(format: "%d:%02d", whole / 60, whole % 60)
    }

    var currentKilometerMetric: String {
        guard sport.displaysSpeed else { return "\(currentKilometerPace) min/km" }
        let meters = activeKilometerMeters
        let seconds = currentSplitSeconds(at: Date())
        guard meters >= 40, seconds > 0 else { return "— km/h" }
        return "\(ReperaNumberFormat.decimal(meters / seconds * 3.6)) km/h"
    }

    private func updateKilometerSplits(
        previousDistance: Double, activeSeconds: TimeInterval
    ) {
        let priorActive = previousFixActiveSeconds ?? activeSeconds
        let segmentDistance = max(1, recordedDistanceMeters - previousDistance)
        while recordedDistanceMeters >= Double(kilometerSplits.count + 1) * 1000 {
            let km = kilometerSplits.count + 1
            let boundary = Double(km) * 1000
            let fraction = min(1, max(0, (boundary - previousDistance) / segmentDistance))
            let crossingSeconds = priorActive + fraction * max(0, activeSeconds - priorActive)
            let split = LiveKmSplit(
                kilometer: km,
                seconds: max(1, crossingSeconds - lastKilometerBoundarySeconds)
            )
            kilometerSplits.append(split)
            lastKilometerBoundarySeconds = crossingSeconds
            reportKilometer(split, elapsedActiveSeconds: crossingSeconds)
        }
    }

    private func reportKilometer(
        _ split: LiveKmSplit, elapsedActiveSeconds: TimeInterval
    ) {
        let result: String
        if sport.displaysSpeed, split.seconds > 0 {
            result = "\(ReperaNumberFormat.decimal(3600 / split.seconds)) km/h"
        } else {
            result = "\(split.clock) min/km"
        }
        latestKilometerReport = "Km \(split.kilometer) · \(result)"
        if sport.usesGPS,
           let message = KilometerVoiceAnnouncement.message(
               kilometer: split.kilometer,
               splitSeconds: split.seconds,
               elapsedSeconds: elapsedActiveSeconds
           ) {
            // Incluye velocidad media TAMBIÉN en caminata/senderismo, no solo
            // en ciclismo, y usa el instante GPS del cruce, no el reloj al
            // volver a primer plano.
            let didSpeak = speakNavigation(message)
            if spokenGuidanceEnabled && !didSpeak {
                notifyDuringBackground(
                    identifier: "repera.km.\(gpsSessionID.uuidString).\(split.kilometer)",
                    title: "Kilómetro \(split.kilometer) completado",
                    body: latestKilometerReport ?? message,
                    fallbackWhenSpeechFailed: true
                )
            }
        }
        if UIApplication.shared.applicationState == .active {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        // Parciales conserva el informe aunque el sistema haya interrumpido
        // una locución o la app se encuentre en segundo plano.
        persistSnapshot()
    }

    private func updateUpcomingTurn(position: CLLocation) {
        guard let route = chosenRoute, route.points.count >= 2,
              selectedRouteDistance.count == route.points.count
        else {
            upcomingTurn = nil
            upcomingTurnInstruction = nil
            upcomingTurnMeters = nil
            upcomingTurnSymbol = "arrow.up"
            followingTurnMeters = nil
            followingTurnSymbol = nil
            clearStreetCue()
            return
        }
        // Un GPX puede superar 20 000 puntos. Limitar el trabajo GPS a
        // unos 1200 vértices y no usar esta estimación fuera de la ruta.
        let step = max(1, route.points.count / 1200)
        var bestIndex = 0
        var nearestMeters = Double.greatestFiniteMagnitude
        for index in stride(from: 0, to: route.points.count, by: step) {
            let point = route.points[index]
            let d = position.distance(
                from: CLLocation(latitude: point.latitude, longitude: point.longitude)
            )
            if d < nearestMeters {
                nearestMeters = d
                bestIndex = index
            }
        }
        // Refinar el vértice: los puntos saltados en un GPX denso pueden
        // coincidir exactamente con el cruce o el final del recorrido.
        for index in max(0, bestIndex - step)...min(route.points.count - 1, bestIndex + step) {
            let point = route.points[index]
            let d = position.distance(
                from: CLLocation(latitude: point.latitude, longitude: point.longitude)
            )
            if d < nearestMeters {
                nearestMeters = d
                bestIndex = index
            }
        }
        guard nearestMeters < 55 else {
            upcomingTurn = "Fuera de ruta · revisa el mapa"
            upcomingTurnInstruction = phase == .idle
                ? "Acércate al recorrido" : "Fuera de ruta"
            upcomingTurnMeters = nil
            upcomingTurnSymbol = "exclamationmark.triangle.fill"
            followingTurnMeters = nil
            followingTurnSymbol = nil
            clearStreetCue()
            return
        }
        let along = selectedRouteDistance[bestIndex]
        // Mantener el letrero hasta rebasar el giro: antes se ocultaba
        // en los últimos ocho metros, justo cuando más se necesitaba.
        guard let next = selectedRouteTurns.first(where: {
            $0.metersAlongRoute >= along - 12
        }) else {
            upcomingTurn = "Sigue el recorrido"
            upcomingTurnInstruction = (selectedRouteDistance.last ?? 0) - along < 35
                ? "Llegando al final" : "Sigue el recorrido"
            upcomingTurnMeters = nil
            upcomingTurnSymbol = "arrow.up"
            followingTurnMeters = nil
            followingTurnSymbol = nil
            clearStreetCue()
            return
        }
        resolveStreet(for: next, on: route)
        let remaining = max(0, next.metersAlongRoute - along)
        upcomingTurnInstruction = next.instruction
        upcomingTurnMeters = Int((remaining / 10).rounded() * 10)
        upcomingTurnSymbol = next.symbol
        if let following = selectedRouteTurns.first(where: {
            $0.routeIndex > next.routeIndex && $0.metersAlongRoute > next.metersAlongRoute
        }) {
            followingTurnMeters = Int(((following.metersAlongRoute - next.metersAlongRoute) / 10).rounded() * 10)
            followingTurnSymbol = following.symbol
        } else {
            followingTurnMeters = nil
            followingTurnSymbol = nil
        }
        if remaining > 250 {
            upcomingTurn = "Sigue el recorrido"
        } else {
            let meters = Int((remaining / 10).rounded() * 10)
            upcomingTurn = "\(next.instruction) aprox. en \(meters) m"
            if phase == .recording,
               remaining <= (sport.isCycling ? 120 : 70),
               !announcedTurnIndices.contains(next.routeIndex) {
                announcedTurnIndices.insert(next.routeIndex)
                // La guía procede solo de la geometría GPX: no sustituye
                // señalización ni navegación vial oficial.
                let naturalDirection: String
                if abs(next.angleDegrees) > 145 {
                    naturalDirection = "cambia de sentido"
                } else {
                    naturalDirection = next.angleDegrees > 0
                        ? "gira a la derecha" : "gira a la izquierda"
                }
                let spokenTurn = meters <= 20
                    ? "Ahora, \(naturalDirection)."
                    : "En unos \(meters) metros, \(naturalDirection)."
                let didSpeak = speakNavigation(spokenTurn)
                notifyDuringBackground(
                    identifier: "repera.turn.\(startedAt?.timeIntervalSince1970 ?? 0).\(next.routeIndex)",
                    title: "Giro orientativo del GPX",
                    body: upcomingTurn ?? next.instruction,
                    fallbackWhenSpeechFailed: !didSpeak
                )
            }
        }
    }

    private func notifyDuringBackground(
        identifier: String, title: String, body: String,
        fallbackWhenSpeechFailed: Bool = false
    ) {
        // Con voz activa, los kilómetros y giros se anuncian solo por audio;
        // nunca reemplazarlos por una notificación con icono de la app.
        // Si el usuario desactiva la voz, el aviso visual es opcional.
        guard UIApplication.shared.applicationState != .active,
              (!spokenGuidanceEnabled || fallbackWhenSpeechFailed) else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = nil
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: identifier, content: content, trigger: nil),
            withCompletionHandler: nil
        )
    }

    /// Estado compacto: la pantalla bloqueada anima el contador por sí sola.
    private func updateLiveActivity() {
        guard let startedAt, phase != .idle else { return }
        lastLiveActivityUpdate = Date()
        lastPublishedDistanceMeters = recordedDistanceMeters
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
        let navigation = status == .completed ? nil : navigationCue
        Task {
            await WorkoutLiveActivityCoordinator.shared.updateFree(
                startedAt: startedAt, sport: sport, phase: status,
                elapsedSeconds: elapsed, distanceMeters: distance, speedKmh: kmh,
                navigation: navigation
            )
        }
    }
}

extension LiveActivityRecorder: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor [weak self] in self?.finishGuidanceUtterance(id) }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor [weak self] in self?.finishGuidanceUtterance(id) }
    }
}

/// Hoja con búsqueda por nombre; agrupación y SF Symbols coherentes con Repera.
private struct LiveSportPicker: View {
    @Environment(\.dismiss) private var dismiss
    var choose: (LiveSport) -> Void
    @State private var query = ""
    private let groups = LiveSport.groups

    var body: some View {
        NavigationStack {
            List {
                ForEach(groups, id: \.self) { group in
                    let sports = LiveSport.selectableCases.filter {
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
                                    HStack(spacing: 12) {
                                        Image(systemName: sport.symbol)
                                            .font(.title3)
                                            .frame(width: 34)
                                            .foregroundStyle(OG.accent)
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(sport.title)
                                                .font(.body.weight(.medium))
                                                .foregroundStyle(OG.label)
                                            Text(sport.metricDescription)
                                                .font(.caption)
                                                .foregroundStyle(OG.label2)
                                                .lineLimit(2)
                                        }
                                        Spacer(minLength: 4)
                                    }
                                    .padding(.vertical, 3)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "Buscar actividad")
            .navigationTitle("Elegir actividad")
            .navigationBarTitleDisplayMode(.inline)
            .ogTransparentNav()
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
    @Environment(\.colorScheme) private var colorScheme

    @Environment(ReperaStore.self) private var store
    @Environment(HealthKitStore.self) private var health
    @Environment(\.scenePhase) private var scenePhase
    @State private var recorder = LiveActivityRecorder.shared
    @State private var routes = LiveRoutesStore.shared
    @State private var sportPicker = false
    @State private var routePicker = false
    @State private var importing = false
    @State private var importAfterRouteSheet = false
    @State private var showDiscard = false
    /// La persona elige Mapa o Métricas incluso antes de pulsar Play.
    /// Conservar la elección entre sesiones: iniciar/pausar no cambia la pantalla.
    @AppStorage("repera.live.preferredDisplay.metrics") private var showingMetrics = false
    @State private var routeError: String?
    @State private var title = ""
    @State private var notes = ""
    @State private var savedWorkoutID: UUID?
    @State private var isSavingRecordedActivity = false
    @State private var previewHealthExtras: HealthKitStore.SessionHealthExtras?
    @State private var showFullScreenRoute = false
    @State private var fullScreenRoutePoints: [HealthKitStore.RoutePoint] = []
    @Namespace private var routeZoomNamespace
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    /// La cámara visible existe incluso mientras el GPS obtiene su primer punto.
    /// Permite aplicar la inclinación 3D inmediatamente, sin esperar al pin.
    @State private var lastVisibleMapCamera: MapCamera?
    @State private var hasAppliedStored3DCamera = false
    /// Muestra Recentrar únicamente si se ha alejado el mapa de la posición real.
    @State private var mapIsCentered = true
    /// Preferencia persistente del mapa de Comenzar: primera apertura plana (2D).
    /// Un cambio en vertical u horizontal queda guardado para futuras sesiones.
    @AppStorage("repera.live.map.navigation3D.enabled") private var navigationMapEnabled = false

    var onSaved: (Date) -> Void
    var onOpenWorkout: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if recorder.phase == .review {
                    review
                } else if recorder.sport.usesGPS && !showingMetrics {
                    mapView
                } else {
                    metricsView
                }
            }
            .background(OG.bg)
            .toolbar(recorder.phase == .review ? .visible : .hidden, for: .navigationBar)
            .navigationTitle(recorder.phase == .review ? "Guardar entreno" : "Comenzar")
            .navigationBarTitleDisplayMode(.inline)
            .ogTransparentNav()
            .navigationDestination(isPresented: $showFullScreenRoute) {
                WorkoutMapZoomDestination(
                    points: fullScreenRoutePoints,
                    isWaterSport: recorder.sport.isWaterSport,
                    referenceRoutePoints: recorder.routePoints.count >= 2
                        ? (recorder.chosenRoute?.points ?? []) : [],
                    onClose: { showFullScreenRoute = false }
                )
                .navigationTransition(.zoom(
                    sourceID: "live-review-route", in: routeZoomNamespace
                ))
            }
            .sheet(isPresented: $sportPicker) {
                LiveSportPicker { sport in
                    recorder.choose(sport)
                    // La preferencia Mapa/Métricas pertenece al usuario,
                    // no a la actividad que acaba de elegir.
                    position = .userLocation(fallback: .automatic)
                    hasAppliedStored3DCamera = false
                    mapIsCentered = true
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
            .sheet(isPresented: $showDiscard) {
                OGConfirmSheet(
                    systemImage: "trash",
                    title: "¿Descartar entreno?",
                    message: "Perderás el recorrido y los datos que no hayas guardado.",
                    confirmTitle: "Descartar sin guardar",
                    onConfirm: {
                        showDiscard = false
                        recorder.discard()
                        title = ""
                        notes = ""
                        mapIsCentered = true
                    },
                    onCancel: { showDiscard = false }
                )
            }
        }
        .tint(OG.accent)
        .onChange(of: scenePhase) { _, next in
            if next == .active {
                recorder.refreshWhenActive()
                routes.requestICloudSynchronization()
            } else {
                recorder.checkpoint()
            }
        }
        .task(id: store.workoutsEpoch) {
            routes.recoverFromSessions(store.state.workouts)
            await routes.synchronizeWithICloud()
        }
        .onAppear {
            if scenePhase == .active { recorder.refreshWhenActive() }
        }
    }

    private struct LiveColoredMapSegment: Identifiable {
        var id: Int
        var coordinates: [CLLocationCoordinate2D]
        var color: Color
        var isEstimated: Bool
    }

    /// Ruta detallada por velocidad, manteniendo tramos discontinuos cuando
    /// se pierde la señal. Se agrupan colores consecutivos para no crear miles
    /// de overlays en MapKit durante entrenamientos prolongados.
    private var coloredLiveSegments: [LiveColoredMapSegment] {
        let points = recorder.routePoints
        guard points.count >= 2 else { return [] }
        let limit = recorder.sport.isCycling ? 22.0 : 12.0
        var measurements: [(index: Int, start: CLLocationCoordinate2D,
                            end: CLLocationCoordinate2D, speed: Double,
                            isEstimated: Bool)] = []
        for index in 1..<points.count {
            let a = points[index - 1]
            let b = points[index]
            let seconds = b.recordedAt.timeIntervalSince(a.recordedAt)
            guard seconds > 0, seconds <= 30 else { continue }
            let start = CLLocationCoordinate2D(latitude: a.latitude, longitude: a.longitude)
            let end = CLLocationCoordinate2D(latitude: b.latitude, longitude: b.longitude)
            let meters = CLLocation(latitude: a.latitude, longitude: a.longitude)
                .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
            let derived = meters / seconds
            guard derived.isFinite, derived <= limit else { continue }
            let speed = b.speedMps.flatMap { $0 > 0 && $0 <= limit ? $0 : nil } ?? derived
            measurements.append((
                index, start, end, speed,
                a.isEstimated == true || b.isEstimated == true
            ))
        }
        guard !measurements.isEmpty else { return [] }
        let slowest = measurements.map { $0.speed }.min() ?? 0
        let fastest = max(measurements.map { $0.speed }.max() ?? 0, slowest + 0.1)
        var output: [LiveColoredMapSegment] = []
        var previousIndex = -1
        var previousBucket = -1
        for sample in measurements {
            let fraction = min(1, max(0, (sample.speed - slowest) / (fastest - slowest)))
            let bucket = min(5, Int((fraction * 5).rounded()))
            if sample.index == previousIndex + 1, bucket == previousBucket,
               !output.isEmpty,
               output[output.count - 1].isEstimated == sample.isEstimated {
                output[output.count - 1].coordinates.append(sample.end)
            } else {
                output.append(LiveColoredMapSegment(
                    id: sample.index, coordinates: [sample.start, sample.end],
                    color: Self.traceColor(Double(bucket) / 5, water: recorder.sport.isWaterSport),
                    isEstimated: sample.isEstimated
                ))
            }
            previousIndex = sample.index
            previousBucket = bucket
        }
        return output
    }

    /// Ruta terrestre: azul → amarillo → naranja → rojo.
    /// Agua: verde → amarillo → naranja → rojo.
    private static func traceColor(_ fraction: Double, water: Bool) -> Color {
        let t = min(1, max(0, fraction))
        let stops: [(r: Double, g: Double, b: Double)] = [
            water ? (0.08, 0.72, 0.31) : (0.06, 0.39, 0.98),
            (0.98, 0.82, 0.12), (1.0, 0.49, 0.07), (0.92, 0.14, 0.12)
        ]
        let scaled = t * 3
        let index = min(2, Int(scaled))
        let mix = scaled - Double(index)
        let a = stops[index], b = stops[index + 1]
        return Color(
            red: a.r + (b.r - a.r) * mix,
            green: a.g + (b.g - a.g) * mix,
            blue: a.b + (b.b - a.b) * mix
        )
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
                ForEach(coloredLiveSegments) { segment in
                    MapPolyline(coordinates: segment.coordinates)
                        .stroke(segment.color, style: StrokeStyle(
                            lineWidth: 5, lineCap: .round, lineJoin: .round,
                            dash: segment.isEstimated ? [7, 6] : []
                        ))
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
            .mapStyle(.standard(elevation: navigationMapEnabled ? .realistic : .flat))
            .onMapCameraChange(frequency: .continuous) { context in
                // Capturar cámara también antes del primer GPS, sin obligar
                // a seleccionar una coordenada fija como fallback.
                lastVisibleMapCamera = context.camera
                // Si 3D se restauró desde Ajustes/último uso, la posición
                // inicial .userLocation de MapKit se crea plana. Forzar su
                // inclinación una sola vez al obtener la primera cámara.
                if navigationMapEnabled && !hasAppliedStored3DCamera {
                    hasAppliedStored3DCamera = true
                    if let user = recorder.currentCoordinate {
                        center3DMap(on: user)
                    } else {
                        applyNavigationPitch(to: context.camera)
                    }
                }
                guard let user = recorder.currentCoordinate else { return }
                let center = context.camera.centerCoordinate
                let meters = CLLocation(latitude: user.latitude, longitude: user.longitude)
                    .distance(from: CLLocation(latitude: center.latitude, longitude: center.longitude))
                mapIsCentered = meters < 65
            }
            .ignoresSafeArea()

            // Adaptación real al tamaño de la ventana, también para DUO y
            // pantallas plegables: no depender solo de la orientación física.
            GeometryReader { geometry in
                let landscape = geometry.size.width > geometry.size.height
                    && geometry.size.width >= 620
                if landscape {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 12) {
                            if recorder.chosenRoute != nil {
                                navigationDirectionsBanner
                            }
                            mapStatusMessages
                            // Dos anclajes independientes en la MISMA columna:
                            // avisos arriba y métricas al pie, con mapa visible
                            // entre ambos. Spacer requiere una altura explícita
                            // para no dejar las métricas justo bajo el aviso.
                            Spacer(minLength: 12)
                            if recorder.phase == .recording || recorder.phase == .paused {
                                mapMetricStrip
                            }
                        }
                        .frame(
                            width: min(390, max(260, geometry.size.width * 0.42)),
                            height: max(0, geometry.size.height - 10),
                            alignment: .topLeading
                        )
                        Spacer(minLength: 0)
                        mapHeader
                            .frame(width: 44, alignment: .trailing)
                    }
                    .padding(.horizontal, OG.topBarHorizontalInset)
                    .padding(.bottom, 10)

                    if recorder.phase == .idle {
                        VStack {
                            Spacer(minLength: 0)
                            bottomControls
                                .frame(maxWidth: 570)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 14)
                                .padding(.bottom, 10)
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        ZStack(alignment: .topLeading) {
                            mapHeader
                            if recorder.chosenRoute != nil {
                                navigationDirectionsBanner
                                    .padding(.trailing, 64)
                            }
                        }
                        mapStatusMessages
                        Spacer(minLength: 0)
                        // Antes de Play, la barra de selección inferior ya
                        // contiene sus controles. No duplicar aquí los
                        // valores 00:00:00, velocidad y distancia.
                        if recorder.phase == .recording || recorder.phase == .paused {
                            mapMetricStrip
                        }
                        if recorder.phase == .idle {
                            bottomControls
                        }
                    }
                    .padding(.horizontal, OG.topBarHorizontalInset)
                    .padding(.bottom, 10)
                }
            }
            // Apple: el MAPA puede llegar al borde físico, pero su
            // overlay de controles debe seguir la safe area del dispositivo
            // (Dynamic Island, iPad en Split View, rotación). Añadimos solo
            // el aire de la cabecera dentro de esa área, sin coordenadas fijas.
            .safeAreaPadding(.top, OG.topBarTopInset)
        }
        .task {
            recorder.prepareMapLocation()
            if mapIsCentered, let user = recorder.currentCoordinate {
                center3DMap(on: user)
            }
        }
        .onChange(of: recorder.currentCoordinate?.latitude) { _, _ in
            if mapIsCentered, let user = recorder.currentCoordinate { center3DMap(on: user) }
        }
        .onChange(of: recorder.currentCoordinate?.longitude) { _, _ in
            if mapIsCentered, let user = recorder.currentCoordinate { center3DMap(on: user) }
        }
        .onChange(of: recorder.currentCourseDegrees) { _, _ in
            if mapIsCentered, let user = recorder.currentCoordinate { center3DMap(on: user) }
        }
    }

    @ViewBuilder
    private var mapStatusMessages: some View {
        if recorder.estimatedRecoveryMeters > 0 {
            Label(
                "Recorrido recuperado: tramo discontinuo estimado, no GPS real",
                systemImage: "location.north.line"
            )
            .font(.caption.weight(.medium))
            .foregroundStyle(OG.label)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
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
    }

    /// Navegación GPX: indicación visible incluso sin giro inmediato.
    private var navigationDirectionsBanner: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(spacing: 7) {
                Image(systemName: recorder.upcomingTurnSymbol)
                    .font(.system(size: 43, weight: .bold))
                if let distance = recorder.upcomingTurnMeters {
                    Text(navigationDistanceLabel(distance))
                        .font(.system(size: 18, weight: .bold))
                        .monospacedDigit()
                }
            }
            .frame(width: 76)

            VStack(alignment: .leading, spacing: 6) {
                Text(recorder.navigationCue?.instruction ?? "Ruta cargada")
                    .font(.system(size: 21, weight: .bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                if let street = recorder.upcomingTurnStreet {
                    Text("Hacia \(street)")
                        .font(.system(size: 16, weight: .medium))
                        .lineLimit(2)
                }
                if let meters = recorder.followingTurnMeters,
                   let symbol = recorder.followingTurnSymbol {
                    HStack(spacing: 6) {
                        Text("Después")
                        Image(systemName: symbol)
                        Text("\(meters) m").monospacedDigit()
                    }
                    .font(.system(size: 14, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.black)
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.accent,
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(recorder.upcomingTurn ?? "Indicaciones de la ruta")
    }

    private func navigationDistanceLabel(_ meters: Int) -> String {
        meters >= 1_000
            ? String(format: "%.1f km", Double(meters) / 1_000)
            : "\(max(0, meters)) m"
    }

    /// Descartar encima, GPS y Métricas debajo. GPS solo al alejarse del centro.
    private var mapHeader: some View {
        HStack(alignment: .top) {
            Spacer(minLength: 0)
            // Separación táctil de 60 pt entre centros de botones de 44 pt.
            VStack(spacing: 16) {
                if recorder.phase == .recording {
                    sessionMapButton(
                        "pause.fill", label: "Pausar grabación",
                        background: OG.yellow, foreground: .black
                    ) { recorder.pause() }
                } else if recorder.phase == .paused {
                    sessionMapButton(
                        "play.fill", label: "Reanudar grabación",
                        background: OG.accent, foreground: .black
                    ) { recorder.resume() }
                    sessionMapButton(
                        "flag.checkered", label: "Finalizar y guardar",
                        background: .black, foreground: .white
                    ) { finishAndShowSave() }
                }
                mapCircleButton(
                    navigationMapEnabled ? "map" : "view.3d",
                    label: navigationMapEnabled ? "Cambiar a vista 2D" : "Cambiar a vista 3D"
                ) {
                    toggleNavigationMapMode()
                }
                if !mapIsCentered, recorder.currentCoordinate != nil {
                    mapCircleButton("location.fill", label: "Centrar en mi posición") {
                        if let user = recorder.currentCoordinate {
                            mapIsCentered = true
                            center3DMap(on: user)
                        }
                    }
                }
                // Disponible también ANTES de iniciar la actividad:
                // Play conserva la pantalla que haya elegido el usuario.
                if recorder.sport.usesGPS {
                    mapCircleButton("chart.bar.xaxis", label: "Ver métricas") {
                        showingMetrics = true
                    }
                }
                if showGuidanceToggle {
                    mapCircleButton(
                        guidanceSymbol,
                        label: guidanceAccessibilityLabel
                    ) {
                        recorder.toggleSpokenGuidance()
                    }
                }
            }
        }
    }

    /// Al pulsar 3D usar el último encuadre de MapKit si el GPS aún
    /// no ha entregado una posición. Nunca limitarse a cambiar el relieve:
    /// es la inclinación de la cámara lo que hace visible la perspectiva.
    private func toggleNavigationMapMode() {
        navigationMapEnabled.toggle()
        hasAppliedStored3DCamera = true
        mapIsCentered = true
        if let user = recorder.currentCoordinate {
            center3DMap(on: user)
        } else if let camera = lastVisibleMapCamera {
            applyNavigationPitch(to: camera)
        } else {
            // El modo queda guardado y se aplicará al primer encuadre de
            // MapKit o en cuanto llegue la ubicación sin iniciar la sesión.
            hasAppliedStored3DCamera = false
        }
    }

    private func applyNavigationPitch(to camera: MapCamera) {
        position = .camera(MapCamera(
            centerCoordinate: camera.centerCoordinate,
            distance: navigationMapEnabled ? min(camera.distance, 500) : max(camera.distance, 450),
            heading: navigationMapEnabled ? camera.heading : 0,
            pitch: navigationMapEnabled ? 67 : 0
        ))
    }

    /// Cámara inclinada con relieve realista; continúa centrada durante una sesión.
    private func center3DMap(on user: CLLocationCoordinate2D) {
        if !navigationMapEnabled {
            position = .camera(MapCamera(
                centerCoordinate: user,
                distance: recorder.sport.isCycling ? 650 : 450,
                heading: 0,
                pitch: 0
            ))
            return
        }
        // Cámara tipo navegador: rumbo de la marcha, perspectiva baja
        // y un punto de mira por delante para dejar visible la ruta siguiente.
        let heading = recorder.currentCourseDegrees ?? 0
        let lookAheadMeters = recorder.phase == .idle ? 0.0 : 35.0
        let radians = heading * .pi / 180
        let latOffset = cos(radians) * lookAheadMeters / 111_320
        let lonRadians = max(0.1, abs(cos(user.latitude * .pi / 180)))
        let lonOffset = sin(radians) * lookAheadMeters / (111_320 * lonRadians)
        let ahead = CLLocationCoordinate2D(
            latitude: user.latitude + latOffset,
            longitude: user.longitude + lonOffset
        )
        position = .camera(MapCamera(
            centerCoordinate: ahead,
            distance: recorder.sport.isCycling ? 540 : 350,
            heading: heading,
            pitch: 67
        ))
    }

    private func route3DPosition(_ points: [WorkoutRoutePoint]) -> MapCameraPosition {
        let region = routeRegion(points)
        let north = CLLocation(
            latitude: region.center.latitude + region.span.latitudeDelta / 2,
            longitude: region.center.longitude
        )
        let south = CLLocation(
            latitude: region.center.latitude - region.span.latitudeDelta / 2,
            longitude: region.center.longitude
        )
        let span = north.distance(from: south)
        return .camera(MapCamera(
            centerCoordinate: region.center,
            distance: max(900, span * 2.6),
            heading: 0,
            pitch: 55
        ))
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

    /// Acción principal durante una sesión: botón sólido y visible sobre el mapa.
    /// Amarillo = pausa, verde = continuar, negro = finalizar.
    private func sessionMapButton(
        _ symbol: String,
        label: String,
        background: Color,
        foreground: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            let icon = Image(systemName: symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(foreground)
                .frame(width: 44, height: 44)
            if symbol == "flag.checkered" && colorScheme == .dark {
                // El negro puro desaparece sobre el mapa en modo noche.
                // El mismo gris carbón de las superficies vacías mantiene
                // visible el círculo, con Liquid Glass como el resto del topbar.
                icon
                    .background(OG.surface2, in: Circle())
                    .glassEffect(.regular.tint(OG.surface2).interactive(), in: .circle)
            } else {
                // En modo claro Finalizar continúa negro; Play y Pausa
                // conservan sus colores sólidos originales.
                icon
                    .background(background, in: Circle())
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    /// Accent green from outer .tint must not color toolbar symbols in metrics.
    private func metricsCircleButton(
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
        .tint(OG.label)
        .accessibilityLabel(label)
    }

    /// Disponible antes de iniciar para decidir si la primera locución
    /// («Iniciando caminata», etc.) debe reproducirse; persiste en UserDefaults.
    /// Un solo control silencia los avisos de fase, parciales y giros.
    private var showGuidanceToggle: Bool {
        recorder.phase != .review
    }

    private var guidanceSymbol: String {
        recorder.spokenGuidanceEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill"
    }

    private var guidanceAccessibilityLabel: String {
        recorder.spokenGuidanceEnabled
            ? "Desactivar avisos por voz"
            : "Activar avisos por voz"
    }

    /// Panel único: tres métricas arriba, parcial actual integrado debajo.
    private var mapMetricStrip: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            VStack(spacing: 10) {
                HStack(spacing: 5) {
                    smallMetric("Duración", value: formattedTime(recorder.duration(at: timeline.date)), prominent: true)
                    smallMetric(recorder.sport.displaysSpeed ? "Veloc. media" : "Ritmo medio",
                                value: paceOrSpeed)
                    smallMetric("Distancia (km)",
                                value: ReperaNumberFormat.decimal(recorder.recordedDistanceMeters / 1000))
                }
                elevationMetricStrip
                if recorder.sport.usesGPS &&
                   (recorder.phase == .recording || recorder.phase == .paused) {
                    Divider().overlay(OG.label2.opacity(0.18))
                    kilometerSplitSummary
                        .padding(.horizontal, 8)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 14)
            .glassEffect(.regular, in: .rect(cornerRadius: 22))
        }
    }

    @ViewBuilder
    private var elevationMetricStrip: some View {
        if recorder.sport.tracksElevation && recorder.hasElevationSamples {
            Divider().overlay(OG.label2.opacity(0.18))
            HStack {
                Label(
                    "+\(Int(recorder.elevationGainMeters.rounded())) m ascenso",
                    systemImage: "arrow.up.right"
                )
                Spacer()
                Label(
                    "−\(Int(recorder.elevationLossMeters.rounded())) m descenso",
                    systemImage: "arrow.down.right"
                )
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(OG.label2)
            .padding(.horizontal, 10)
        }
    }

    /// Misma fila de parcial en Mapa y Métricas, sin Glass adicional.
    private var kilometerSplitSummary: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Km \(recorder.activeKilometer)")
                    .font(.subheadline.weight(.semibold))
                Text("\(Int(recorder.activeKilometerMeters)) m")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(OG.label2)
                Spacer(minLength: 4)
                Text(recorder.currentKilometerMetric)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            ProgressView(value: min(1000, recorder.activeKilometerMeters), total: 1000)
                .tint(OG.accent)
            if let last = recorder.latestKilometerReport {
                Text("Último parcial: \(last)")
                    .font(.caption)
                    .foregroundStyle(OG.label2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .foregroundStyle(OG.label)
    }

    private var metricsView: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            VStack(spacing: 0) {
                GeometryReader { header in
                    HStack(spacing: 6) {
                        Image(systemName: recorder.sport.symbol)
                            .font(.title2.weight(.medium))
                            .foregroundStyle(OG.accent)
                            .frame(width: 28)
                        Text(recorder.sport.title)
                            .font(.headline)
                            .lineLimit(2)
                            .minimumScaleFactor(0.68)
                            .frame(
                                width: min(126, max(48, header.size.width - 240)),
                                height: 54,
                                alignment: .leading
                            )
                        // Separación flexible ENTRE el deporte y la primera
                        // acción. Audio, Mapa y Pausa/Play van juntos a la
                        // derecha: ningún hueco invisible entre sus botones.
                        Spacer(minLength: 0)
                        metricsTrailingActions
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(height: 68)
                .padding(.horizontal, OG.topBarHorizontalInset)
                .padding(.top, 14)
                if recorder.chosenRoute != nil, recorder.phase != .idle {
                    HStack(spacing: 9) {
                        Image(systemName: recorder.upcomingTurnSymbol)
                            .font(.title2.weight(.bold))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(recorder.navigationCue?.instruction ?? "Sigue el recorrido")
                                .font(.subheadline.weight(.bold))
                            if let street = recorder.upcomingTurnStreet {
                                Text("Hacia \(street)")
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                        }
                        Spacer(minLength: 4)
                        if let meters = recorder.upcomingTurnMeters {
                            Text(navigationDistanceLabel(meters))
                                .font(.subheadline.weight(.bold))
                                .monospacedDigit()
                        }
                    }
                    .foregroundStyle(.black)
                    .padding(12)
                    .background(OG.accent, in: .rect(cornerRadius: 14))
                    .padding(.horizontal, OG.topBarHorizontalInset)
                }

                Spacer(minLength: 16)
                Text(formattedTime(recorder.duration(at: timeline.date)))
                    .font(.system(size: 68, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(OG.label)
                    .minimumScaleFactor(0.6).lineLimit(1)
                Text("Duración")
                    .font(.subheadline).foregroundStyle(OG.label2)
                if recorder.sport.usesGPS, recorder.phase != .idle {
                    // Sin caja propia, manteniendo los márgenes de la vista.
                    kilometerSplitSummary
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                }
                Spacer(minLength: 14)
                Text(recorder.sport.usesGPS ? paceOrSpeed : "—")
                    .font(.system(size: 78, weight: .bold, design: .rounded).monospacedDigit())
                    .minimumScaleFactor(0.55).lineLimit(1)
                    .foregroundStyle(OG.label)
                Text(recorder.sport.usesGPS ?
                    (recorder.sport.displaysSpeed ? "Velocidad media (km/h)" : "Ritmo medio (min/km)") :
                    "Frecuencia cardíaca (lpm)")
                    .font(.subheadline).foregroundStyle(OG.label2)
                Spacer(minLength: 14)
                if recorder.sport.usesGPS {
                    Text(ReperaNumberFormat.decimal(recorder.recordedDistanceMeters / 1000))
                        .font(.system(size: 55, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(OG.label)
                    Text("Distancia (km)").font(.subheadline).foregroundStyle(OG.label2)
                } else {
                    Text("—")
                        .font(.system(size: 55, weight: .semibold, design: .rounded))
                        .foregroundStyle(OG.label)
                    Text("Calorías activas (kcal)")
                        .font(.subheadline).foregroundStyle(OG.label2)
                    Text("El pulso y las calorías se incorporan al finalizar si Apple Salud tiene mediciones reales.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(OG.label2)
                        .padding(.horizontal, 30)
                }
                if recorder.sport.tracksElevation && recorder.hasElevationSamples {
                    HStack {
                        Label(
                            "+\(Int(recorder.elevationGainMeters.rounded())) m",
                            systemImage: "arrow.up.right"
                        )
                        Spacer()
                        Label(
                            "−\(Int(recorder.elevationLossMeters.rounded())) m",
                            systemImage: "arrow.down.right"
                        )
                    }
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(OG.label2)
                    .padding(.horizontal, 28)
                }
                Spacer(minLength: 12)
                if recorder.phase == .idle {
                    // La misma barra inferior que en Mapa antes de iniciar:
                    // actividad, Play y ruta. Alineada al pie dentro del
                    // área segura, sin desplazar las acciones de la cabecera.
                    bottomControls
                        .frame(maxWidth: 570)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 10)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: Int(timeline.date.timeIntervalSince1970 / 15)) { _, _ in
                recorder.checkpoint()
            }
        }
    }

    /// Últimas tres posiciones SIEMPRE fijas contra el margen derecho:
    /// Audio, Mapa y Pausa/Reanudar quedan contiguos con 6 pt de separación.
    /// Finalizar aparece a su izquierda al pausar, sin mover los tres botones.
    private var metricsTrailingActions: some View {
        HStack(spacing: 6) {
            if showGuidanceToggle {
                metricsCircleButton(
                    guidanceSymbol, label: guidanceAccessibilityLabel
                ) {
                    recorder.toggleSpokenGuidance()
                }
            }
            if recorder.sport.usesGPS {
                metricsCircleButton("map", label: "Ver mapa") {
                    showingMetrics = false
                }
            }
            if recorder.phase == .recording {
                sessionMapButton(
                    "pause.fill", label: "Pausar grabación",
                    background: OG.yellow, foreground: .black
                ) { recorder.pause() }
            } else if recorder.phase == .paused {
                // Durante la pausa: Audio · Mapa · Finalizar · Play.
                // Los dos botones de acción quedan juntos en el extremo derecho.
                sessionMapButton(
                    "flag.checkered", label: "Finalizar y guardar",
                    background: .black, foreground: .white
                ) { finishAndShowSave() }
                sessionMapButton(
                    "play.fill", label: "Reanudar grabación",
                    background: OG.accent, foreground: .black
                ) { recorder.resume() }
            }
        }
    }

    /// Solo los selectores laterales son opacos. La barra general puede seguir
    /// usando Liquid Glass, pero las superficies de Actividad/Ruta nunca.
    private var selectionCircleBackground: Color {
        colorScheme == .dark ? .black : .white
    }

    private func selectionCircle(_ symbol: String, foreground: Color) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 25, weight: .medium))
            .foregroundStyle(foreground)
            .frame(width: 58, height: 58)
            .background(selectionCircleBackground, in: Circle())
            .overlay {
                Circle().strokeBorder(
                    OG.label.opacity(colorScheme == .dark ? 0.22 : 0.10),
                    lineWidth: 1
                )
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
                            selectionCircle(recorder.sport.symbol, foreground: OG.accent)
                            Text(recorder.sport.title)
                                .font(.caption2.weight(.medium))
                                .lineLimit(1).minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Elegir actividad: \(recorder.sport.title)")

                    Button {
                        if recorder.isStartCountingDown {
                            recorder.cancelStartCountdown()
                        } else if store.hasActiveSession {
                            onOpenWorkout()
                        } else {
                            recorder.beginStartCountdown()
                        }
                    } label: {
                        VStack(spacing: 7) {
                            Group {
                                if recorder.isStartCountingDown {
                                    Text("\(recorder.startCountdownRemaining)")
                                        .font(.system(size: 30, weight: .bold, design: .rounded))
                                        .monospacedDigit()
                                } else {
                                    Image(systemName: store.hasActiveSession ? "arrow.uturn.forward" : "play.fill")
                                        .font(.system(size: 28, weight: .bold))
                                }
                            }
                            .foregroundStyle(.black)
                            .frame(width: 70, height: 70)
                            .background(OG.accent, in: Circle())
                            Text(recorder.isStartCountingDown ? "Cancelar" :
                                 (store.hasActiveSession ? "Continuar" : "Iniciar"))
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
                                selectionCircle(
                                    "point.topleft.down.curvedto.point.bottomright.up",
                                    foreground: OG.accent
                                )
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

            case .recording, .paused, .review:
                // El registro activo se controla desde la cabecera.
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
                // GPX is spatial data. If entered from Home with a
                // non-GPS sport selected, prepare walking rather than
                // hiding the map and starting a non-GPS workout.
                if !recorder.sport.usesGPS { recorder.choose(.walking) }
                recorder.selectRoute(route)
                position = route3DPosition(route.points)
                mapIsCentered = false
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

    /// Finalizar conduce directamente al editor de guardado (sin confirmación
    /// intermedia). El recorder congela los datos antes de mostrar el detalle.
    private func finishAndShowSave() {
        guard recorder.phase == .recording || recorder.phase == .paused else { return }
        recorder.finish()
        title = recorder.sport.title
        notes = ""
    }

    /// Misma presentación de detalle que Entreno/Historial: mapa y parciales
    /// compartidos, con campos para el nuevo registro (aún sin persistir).
    private var review: some View {
        List {
            if let session = recorder.makeSession(title: title, notes: notes) {
                // Fecha y métricas directamente sobre el fondo, sin contenedor exterior.
                VStack(alignment: .leading, spacing: 10) {
                    Text((session.startedAt ?? Date())
                        .formatted(date: .complete, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(OG.label2)
                    HStack(spacing: 10) {
                        reviewTile(
                            "Tiempo activo",
                            value: formattedTime(recorder.durationSeconds),
                            icon: "clock.fill", tint: OG.blue
                        )
                        if recorder.sport.usesGPS {
                            reviewTile(
                                "Distancia",
                                value: "\(ReperaNumberFormat.decimal((session.recordedDistanceMeters ?? 0) / 1000)) km",
                                icon: "point.bottomleft.forward.to.point.topright.scurvepath",
                                tint: OG.accent
                            )
                        }
                        reviewTile(
                            "Energía",
                            value: previewHealthExtras.flatMap { extras in
                                extras.hasExternalSaludSource ?
                                    extras.activeEnergyKcal.map { "\(Int($0.rounded())) kcal" } : nil
                            } ?? "—",
                            icon: "flame.fill",
                            tint: OG.orange
                        )
                    }
                    if let extras = previewHealthExtras, extras.hasExternalSaludSource,
                       let heartRate = extras.averageHeartRateBpm {
                        Label(
                            "Pulso medio: \(Int(heartRate.rounded())) lpm",
                            systemImage: "heart"
                        )
                        .font(.subheadline)
                        .foregroundStyle(OG.label2)
                    }
                    if recorder.estimatedRecoveryMeters > 0 {
                        Label(
                            "Tramo estimado: aprox. \(Int(recorder.estimatedRecoveryMeters.rounded())) m en línea recta. El tiempo de ese intervalo también es aproximado; no son medidas GPS.",
                            systemImage: "location.north.line"
                        )
                        .font(.caption)
                        .foregroundStyle(OG.label2)
                    }
                    if recorder.sport.tracksElevation && recorder.hasElevationSamples {
                        HStack(spacing: 14) {
                            Label(
                                "+\(Int(recorder.elevationGainMeters.rounded())) m de ascenso",
                                systemImage: "arrow.up.right"
                            )
                            Label(
                                "−\(Int(recorder.elevationLossMeters.rounded())) m de descenso",
                                systemImage: "arrow.down.right"
                            )
                        }
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(OG.label2)
                    }
                }
                .ogCardListRow(top: 4, bottom: 4)

                // Misma plantilla de mapa que el historial, con transición
                // de zoom compartida al modo interactivo a pantalla completa.
                let previewPoints = session.routePoints.count >= 2
                    ? session.routePoints : (recorder.chosenRoute?.points ?? [])
                let isRecordedRoute = session.routePoints.count >= 2
                let route = previewPoints.map { point in
                    HealthKitStore.RoutePoint(
                        id: point.id,
                        latitude: point.latitude,
                        longitude: point.longitude,
                        date: point.recordedAt,
                        speedMps: point.speedMps,
                        altitudeMeters: point.altitudeMeters,
                        isEstimated: point.isEstimated == true
                    )
                }
                if previewPoints.count >= 2 {
                    Section {
                        SessionMapWeatherCard(
                            latitude: route.first?.latitude,
                            longitude: route.first?.longitude,
                            workoutDate: session.startedAt ?? .now
                        ) {
                            WorkoutMapTapTarget(
                                accessibilityLabel: "Abrir recorrido a pantalla completa"
                            ) {
                                fullScreenRoutePoints = route
                                showFullScreenRoute = true
                            } map: {
                                HealthWorkoutRouteMap(
                                    points: route, isInteractive: false,
                                    isWaterSport: recorder.sport.isWaterSport,
                                    referenceRoutePoints: isRecordedRoute
                                        ? (recorder.chosenRoute?.points ?? []) : []
                                )
                                .matchedTransitionSource(
                                    id: "live-review-route", in: routeZoomNamespace
                                )
                            }
                        }
                        .ogCardListRow()
                    }
                } else if recorder.sport.usesGPS {
                    Section {
                        ContentUnavailableView(
                            "Recorrido sin puntos GPS",
                            systemImage: "location.slash",
                            description: Text("La distancia y los parciales se conservan aunque no haya puntos para dibujar el mapa.")
                        )
                        .ogCardListRow()
                    }
                }

                // Un solo Entreno: primero tiles y parciales específicos
                // del deporte y, inmediatamente después, Salud/altitud.
                let hasSportValues = ((session.recordedDistanceMeters ?? 0) > 0
                    && (session.activeDurationSeconds ?? 0) > 0)
                    || !(session.liveKilometerSplitsSeconds ?? []).isEmpty
                let hasHealthValues = previewHealthExtras?.hasAuthenticSaludMetrics == true
                    || previewHealthExtras?.hasExternalSaludSource == true
                if hasSportValues || hasHealthValues {
                    Section {
                        VStack(alignment: .leading, spacing: 14) {
                            if hasSportValues || !recorder.sport.usesGPS {
                                CardioSplitsView(
                                    routePoints: isRecordedRoute ? route : [],
                                    heartRate: previewHealthExtras?.heartRateSeries ?? [],
                                    cycling: recorder.sport.displaysSpeed,
                                    activeKilometerSeconds: session.liveKilometerSplitsSeconds,
                                    totalActiveSeconds: session.activeDurationSeconds,
                                    totalDistanceMeters: session.recordedDistanceMeters,
                                    maxSpeedKmh: previewHealthExtras?.maxSpeedKmh,
                                    healthStats: previewHealthExtras,
                                    sport: recorder.sport,
                                    embedded: true
                                )
                            }
                            if let extras = previewHealthExtras,
                               extras.hasAuthenticSaludMetrics || extras.hasExternalSaludSource {
                                if hasSportValues || !recorder.sport.usesGPS {
                                    Divider().opacity(0.35)
                                }
                                HealthSessionMetricsCard(
                                    extras: extras,
                                    includeSourceRows: extras.hasExternalSaludSource,
                                    embedded: true
                                )
                            }
                        }
                        .padding(OG.pad)
                        .background(OG.surface, in: RoundedRectangle(
                            cornerRadius: OG.radiusCard, style: .continuous
                        ))
                        .ogCardListRow()
                    } header: {
                        Text("Entreno").foregroundStyle(OG.accent).textCase(nil)
                    }
                }

                Section("Detalles de la actividad") {
                    TextField("Nombre", text: $title)
                        .foregroundStyle(OG.label)
                    TextField("Notas (opcional)", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                    if let route = recorder.chosenRoute {
                        Label("Ruta: \(route.title)", systemImage: "star.fill")
                            .foregroundStyle(OG.label2)
                    }
                }
                Section {
                    Button {
                        saveRecordedActivity()
                    } label: {
                        Text("Guardar")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .foregroundStyle(.black)
                            .background(OG.accent, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isSavingRecordedActivity)
                    .ogCardListRow()
                }

                Section {
                    Button(role: .destructive) {
                        showDiscard = true
                    } label: {
                        Text("Descartar")
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(OG.red)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
        }
        .ogListChrome()
        .listSectionSpacing(12)
        .task(id: recorder.phase) {
            guard recorder.phase == .review,
                  let workout = recorder.makeSession(title: title, notes: notes) else {
                previewHealthExtras = nil
                return
            }
            previewHealthExtras = await health.sessionHealthExtras(for: workout)
        }
    }

    private func reviewTile(
        _ label: String, value: String, icon: String, tint: Color
    ) -> some View {
        WorkoutSummaryTile(title: label, value: value, icon: icon, tint: tint)
    }

    private func saveRecordedActivity() {
        guard !isSavingRecordedActivity,
              let draft = recorder.makeSession(title: title, notes: notes),
              savedWorkoutID != draft.id else { return }
        isSavingRecordedActivity = true
        savedWorkoutID = draft.id
        Task { @MainActor in
            var session = draft
            // Consultar Salud también al pulsar Guardar: la lectura asíncrona
            // de la preview quizá todavía no terminó. No crear un segundo
            // HKWorkout si existe otro real de Apple Watch para esta salida.
            let extras: HealthKitStore.SessionHealthExtras?
            if let cached = previewHealthExtras {
                extras = cached
            } else {
                extras = await health.sessionHealthExtras(for: session)
            }
            if let extras, extras.hasExternalSaludSource,
               let matchedUUID = extras.resolvedWorkoutUUID {
                session.healthKitWorkoutUUID = matchedUUID
                session.appleActiveEnergyKcal = extras.activeEnergyKcal.flatMap { $0 > 0 ? $0 : nil }
                session.appleAverageHeartRateBpm = extras.averageHeartRateBpm
                session.appleHealthProvenance = "healthKitExternal"
            }
            if session.liveRouteID == nil && session.routePoints.count >= 2
                && recorder.sport.usesGPS {
                do {
                    session.liveRouteID = try routes.addRecordedRoute(from: session)
                } catch {
                    // Guardar siempre el entreno aunque falle archivar el GPX.
                    routeError = "No se pudo archivar la ruta. La actividad sí se guardará."
                }
            }
            store.saveWorkout(session)
            let day = session.startedAt ?? Date()
            recorder.discard(saved: true)
            title = ""
            notes = ""
            savedWorkoutID = nil
            isSavingRecordedActivity = false
            onSaved(day)
        }
    }

    private var routeSheet: some View {
        LiveRouteLibraryPickerView(
            onClose: { routePicker = false },
            onImport: {
                importAfterRouteSheet = true
                routePicker = false
            },
            onUseRoute: { selected in
                // A route opened from Inicio may not match the currently
                // selected non-GPS sport in Comenzar.
                if let raw = selected.sportID,
                   let sport = LiveSport(rawValue: raw), sport.usesGPS {
                    recorder.choose(sport)
                } else if !recorder.sport.usesGPS {
                    recorder.choose(.walking)
                }
                recorder.selectRoute(selected)
                position = route3DPosition(selected.points)
                mapIsCentered = false
                routePicker = false
            },
            onDeleteRoute: { deletedID in
                if recorder.chosenRoute?.id == deletedID {
                    recorder.selectRoute(nil)
                }
            }
        )
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

    /// La misma métrica media en pantalla, Dynamic Island y bloqueo.
    /// Cambia con cada punto GPS y con la duración activa, sin valores en caché.
    private var paceOrSpeed: String {
        guard let average = recorder.averageSpeedKmh, average > 0.1 else {
            return recorder.sport.displaysSpeed ? "—" : "—:—"
        }
        if recorder.sport.displaysSpeed {
            return ReperaNumberFormat.decimal(average)
        }
        let seconds = Int(3600 / average)
        guard seconds < 3600 else { return "—:—" }
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private func formattedTime(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        return String(format: "%02d:%02d:%02d", total / 3600, (total / 60) % 60, total % 60)
    }

    private func smallMetric(_ label: String, value: String, prominent: Bool = false) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(size: prominent ? 27 : 19,
                              weight: .semibold, design: .rounded).monospacedDigit())
                .lineLimit(1).minimumScaleFactor(0.65)
                .foregroundStyle(OG.label)
            Text(label)
                .font(.caption2).foregroundStyle(OG.label2)
                .lineLimit(1).minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity)
    }
}


/// La miniatura es el trazado GPS real escalado a la celda, sin mapas ni red.
private struct LiveRouteTrace: Shape {
    let points: [WorkoutRoutePoint]

    func path(in rect: CGRect) -> Path {
        let valid = points.filter {
            $0.latitude.isFinite && $0.longitude.isFinite &&
            (-90...90).contains($0.latitude) && (-180...180).contains($0.longitude)
        }
        guard valid.count >= 2 else { return Path() }
        let factor = cos((valid.map(\.latitude).reduce(0, +) / Double(valid.count)) * .pi / 180)
        let positions = valid.map {
            CGPoint(x: CGFloat($0.longitude * factor), y: CGFloat($0.latitude))
        }
        let minX = positions.map(\.x).min() ?? 0
        let maxX = positions.map(\.x).max() ?? 0
        let minY = positions.map(\.y).min() ?? 0
        let maxY = positions.map(\.y).max() ?? 0
        let dx = max(maxX - minX, 0.0000001)
        let dy = max(maxY - minY, 0.0000001)
        let availableWidth = max(1, rect.width - 14)
        let availableHeight = max(1, rect.height - 14)
        let scale = min(availableWidth / dx, availableHeight / dy)
        let offsetX = rect.midX - (minX + maxX) * scale / 2
        let offsetY = rect.midY + (minY + maxY) * scale / 2
        var result = Path()
        // Se simplifica solo para dibujar: la ruta y sus coordenadas no se alteran.
        let strideBy = max(1, positions.count / 900)
        for index in Swift.stride(from: 0, to: positions.count, by: strideBy) {
            let location = CGPoint(
                x: offsetX + positions[index].x * scale,
                y: offsetY - positions[index].y * scale
            )
            if index == 0 { result.move(to: location) }
            else { result.addLine(to: location) }
        }
        if (positions.count - 1) % strideBy != 0, let last = positions.last {
            result.addLine(to: CGPoint(x: offsetX + last.x * scale, y: offsetY - last.y * scale))
        }
        return result
    }
}

/// Biblioteca: cinco últimas rutas, acceso al histórico completo y favoritos explícitos.
private struct LiveRouteLibraryPickerView: View {
    @State private var routes = LiveRoutesStore.shared
    @Environment(ReperaStore.self) private var store

    private var recentRoutes: [LiveSavedRoute] {
        routes.recentRoutes(using: store.state.workouts)
    }

    private var favorites: [LiveSavedRoute] {
        recentRoutes.filter(\.isFavorite)
    }

    var onClose: () -> Void
    var onImport: () -> Void
    var onUseRoute: (LiveSavedRoute) -> Void
    var onDeleteRoute: (UUID) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mis rutas")
                                .font(.system(size: 31, weight: .bold))
                                .foregroundStyle(OG.label)
                            Text(routes.iCloudRouteStatus)
                                .font(.caption)
                                .foregroundStyle(OG.label2)
                        }
                        Spacer()
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(OG.label)
                                .frame(width: 42, height: 42)
                                .glassEffect(.regular.interactive(), in: .circle)
                        }
                        .buttonStyle(.plain)
                        .tint(OG.label)
                        .accessibilityLabel("Cerrar Mis rutas")
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Section("Últimas rutas") {
                    if recentRoutes.isEmpty {
                        ContentUnavailableView(
                            "Todavía no hay rutas",
                            systemImage: "map",
                            description: Text("Graba un recorrido o importa un GPX para empezar.")
                        )
                    } else {
                        ForEach(Array(recentRoutes.prefix(5))) { route in
                            LiveRouteLibraryRow(
                                routeID: route.id,
                                onUseRoute: onUseRoute, onDeleteRoute: onDeleteRoute
                            )
                        }
                        if recentRoutes.count > 5 {
                            NavigationLink {
                                LiveAllRoutesView(
                                    onUseRoute: onUseRoute, onDeleteRoute: onDeleteRoute
                                )
                            } label: {
                                HStack {
                                    Text("Ver más").fontWeight(.semibold)
                                    Spacer()
                                    Text("\(recentRoutes.count) rutas")
                                        .foregroundStyle(OG.label2)
                                }
                            }
                        }
                    }
                }

                Section("Favoritos") {
                    if favorites.isEmpty {
                        Text("Pulsa la estrella de una ruta para añadirla aquí.")
                            .font(.subheadline)
                            .foregroundStyle(OG.label2)
                    } else {
                        ForEach(favorites) { route in
                            LiveRouteLibraryRow(
                                routeID: route.id,
                                onUseRoute: onUseRoute, onDeleteRoute: onDeleteRoute
                            )
                        }
                    }
                }

                Section {
                    Button(action: onImport) {
                        Label("Importar archivo GPX", systemImage: "square.and.arrow.down")
                            .foregroundStyle(OG.label)
                    }
                    .tint(.black)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .ogTransparentNav()
            .task { await routes.synchronizeWithICloud() }
            .refreshable { await routes.synchronizeWithICloud() }
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(OG.accent)
    }
}

private struct LiveAllRoutesView: View {
    @Environment(ReperaStore.self) private var store
    @State private var routes = LiveRoutesStore.shared
    var onUseRoute: (LiveSavedRoute) -> Void
    var onDeleteRoute: (UUID) -> Void

    var body: some View {
        List {
            ForEach(routes.recentRoutes(using: store.state.workouts)) { route in
                LiveRouteLibraryRow(
                    routeID: route.id,
                    onUseRoute: onUseRoute, onDeleteRoute: onDeleteRoute
                )
            }
        }
        .listStyle(.insetGrouped)
        .ogListChrome()
        .navigationTitle("Todas las rutas")
        .navigationBarTitleDisplayMode(.inline)
        .ogTransparentNav()
    }
}

private struct LiveRouteLibraryRow: View {
    @State private var routes = LiveRoutesStore.shared
    let routeID: UUID
    var onUseRoute: (LiveSavedRoute) -> Void
    var onDeleteRoute: (UUID) -> Void

    private var route: LiveSavedRoute? {
        routes.routes.first { $0.id == routeID }
    }

    var body: some View {
        if let route {
            // Link directo en la List: el chevron nativo ocupa el extremo derecho.
            // Los favoritos se gestionan desde la ficha de ruta.
            NavigationLink {
                LiveRouteLibraryDetailView(
                    routeID: routeID,
                    onUseRoute: onUseRoute,
                    onDeleteRoute: onDeleteRoute
                )
            } label: {
                HStack(spacing: 12) {
                    LiveRouteTrace(points: route.points)
                        .stroke(OG.accent, style: StrokeStyle(
                            lineWidth: 2.8, lineCap: .round, lineJoin: .round
                        ))
                        .frame(width: 64, height: 54)
                        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(route.title.isEmpty ? route.sportTitle : route.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(OG.label)
                            .lineLimit(2)
                        Text("\(ReperaNumberFormat.decimal(route.distanceKm)) km · \(route.sportTitle)")
                            .font(.caption)
                            .foregroundStyle(OG.label2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                .padding(.vertical, 5)
            }
        }
    }
}

/// Edición en página propia: el campo es nativo y el deporte navega a otro nivel.
private struct LiveRouteEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var routes = LiveRoutesStore.shared
    @State private var editedTitle = ""
    @State private var editedSportID = ""
    @State private var initialized = false
    @State private var editError: String?
    let routeID: UUID

    private var selectedSportTitle: String {
        LiveSport(rawValue: editedSportID)?.title ?? "Sin asignar"
    }

    var body: some View {
        List {
            Section("Nombre de la ruta") {
                TextField("Por ejemplo, Caminata", text: $editedTitle)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(false)
                    .submitLabel(.done)
                    .font(.body)
                    .padding(.vertical, 6)
                    .foregroundStyle(OG.label)
            }
            Section("Deporte") {
                NavigationLink {
                    LiveRouteSportOptionsView(selectedSportID: $editedSportID)
                } label: {
                    HStack {
                        Text("Tipo de deporte").foregroundStyle(OG.label)
                        Spacer()
                        Text(selectedSportTitle)
                            .foregroundStyle(OG.label2)
                    }
                    .padding(.vertical, 6)
                }
            }
            Section {
                Button {
                    save()
                } label: {
                    Text("Guardar cambios")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(.black)
                        .background(OG.accent, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.insetGrouped)
        .ogListChrome()
        .navigationTitle("Editar ruta")
        .navigationBarTitleDisplayMode(.inline)
        .ogTransparentNav()
        .onAppear {
            guard !initialized,
                  let route = routes.routes.first(where: { $0.id == routeID }) else { return }
            editedTitle = route.title
            editedSportID = route.sportID ?? ""
            initialized = true
        }
        .alert("No se pudo guardar", isPresented: Binding(
            get: { editError != nil },
            set: { if !$0 { editError = nil } }
        )) {
            Button("Aceptar", role: .cancel) { editError = nil }
        } message: { Text(editError ?? "") }
    }

    private func save() {
        do {
            try routes.update(
                routeID, title: editedTitle,
                sportID: editedSportID.isEmpty ? nil : editedSportID
            )
            dismiss()
        } catch {
            editError = error.localizedDescription
        }
    }
}

private struct LiveRouteSportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSportID: String
    @State private var query = ""
    private let groups = LiveSport.groups

    var body: some View {
        List {
            Section {
                Button {
                    selectedSportID = ""
                    dismiss()
                } label: {
                    HStack {
                        Text("Sin asignar")
                        Spacer()
                        if selectedSportID.isEmpty {
                            Image(systemName: "checkmark").foregroundStyle(OG.accent)
                        }
                    }
                    .foregroundStyle(OG.label)
                }
            }
            ForEach(groups, id: \.self) { group in
                let sports = LiveSport.selectableCases.filter {
                    $0.group == group &&
                    (query.isEmpty || $0.title.localizedStandardContains(query))
                }
                if !sports.isEmpty {
                    Section(group) {
                        ForEach(sports) { sport in
                            Button {
                                selectedSportID = sport.rawValue
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: sport.symbol)
                                        .foregroundStyle(OG.accent)
                                        .frame(width: 28)
                                    Text(sport.title)
                                    Spacer()
                                    if selectedSportID == sport.rawValue {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(OG.accent)
                                    }
                                }
                                .foregroundStyle(OG.label)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $query, prompt: "Buscar deporte")
        .listStyle(.insetGrouped)
        .ogListChrome()
        .navigationTitle("Elegir deporte")
        .navigationBarTitleDisplayMode(.inline)
        .ogTransparentNav()
    }
}

/// Ficha de una ruta (GPX importado o una salida grabada) desde «Cargar ruta».
/// Muestra el mapa, estadísticas verificables, edición y eliminación sin tocar
/// las sesiones históricas que pudieran haber recorrido esta ruta.
private struct LiveRouteLibraryDetailView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var routes = LiveRoutesStore.shared
    @State private var position: MapCameraPosition = .automatic
    @State private var deleteConfirmation = false
    @State private var editError: String?

    let routeID: UUID
    let onUseRoute: (LiveSavedRoute) -> Void
    let onDeleteRoute: (UUID) -> Void

    private var route: LiveSavedRoute? {
        routes.routes.first { $0.id == routeID }
    }

    private var attempts: [WorkoutSession] {
        store.state.workouts.filter {
            $0.liveRouteID == routeID && $0.phase == .finished && $0.finishedAt != nil
        }.sorted { ($0.startedAt ?? .distantPast) > ($1.startedAt ?? .distantPast) }
    }

    private var historySport: LiveSport? {
        if let route, let sportID = route.sportID,
           let sport = LiveSport(rawValue: sportID) {
            return sport
        }
        return attempts.compactMap { session in
            session.liveSportID.flatMap(LiveSport.init(rawValue:))
        }.first
    }

    private var distanceMeters: Double {
        guard let route else { return 0 }
        let points = route.points
        guard points.count > 1 else { return 0 }
        return zip(points, points.dropFirst()).reduce(0.0) { result, pair in
            let from = CLLocation(latitude: pair.0.latitude, longitude: pair.0.longitude)
            let to = CLLocation(latitude: pair.1.latitude, longitude: pair.1.longitude)
            return result + from.distance(from: to)
        }
    }

    private var elevationGainMeters: Double? {
        guard let route else { return nil }
        let heights = route.points.compactMap(\.altitudeMeters)
        guard heights.count > 1 else { return nil }
        let gain = zip(heights, heights.dropFirst()).reduce(0.0) { result, pair in
            result + max(0, pair.1 - pair.0)
        }
        return gain
    }

    /// Excluye sesiones truncadas: un intento a media ruta no es un récord.
    private var completeAttempts: [WorkoutSession] {
        attempts.filter { session in
            guard let duration = session.activeDurationSeconds, duration > 0,
                  let recorded = session.recordedDistanceMeters, recorded > 0,
                  distanceMeters > 100 else { return false }
            return recorded >= distanceMeters * 0.8 && recorded <= distanceMeters * 1.2
        }
    }

    private var bestTime: TimeInterval? {
        completeAttempts.compactMap(\.activeDurationSeconds).min()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let route, route.points.count > 1 {
                    Map(position: $position) {
                        MapPolyline(coordinates: route.points.map {
                            CLLocationCoordinate2D(
                                latitude: $0.latitude, longitude: $0.longitude
                            )
                        })
                        .stroke(OG.accent, lineWidth: 5)
                    }
                    .mapControlVisibility(.hidden)
                    .frame(height: 230)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .task(id: route.id) {
                        position = .region(region(for: route.points))
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Recorrido").font(.headline)
                    HStack(spacing: 8) {
                        stat("Distancia", value: "\(ReperaNumberFormat.decimal(distanceMeters / 1000)) km")
                        stat("Repeticiones", value: "\(attempts.count)")
                        stat("Mejor tiempo", value: bestTime.map(clock) ?? "—")
                        stat("Desnivel", value: elevationGainMeters.map { "\(Int($0.rounded())) m" } ?? "—")
                    }
                    if completeAttempts.count < attempts.count {
                        Text("El mejor tiempo solo cuenta recorridos completos de distancia comparable.")
                            .font(.caption)
                            .foregroundStyle(OG.label2)
                    }
                }
                .padding(16)
                .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard))

                if let route {
                    Button {
                        onUseRoute(route)
                    } label: {
                        Label("Repetir esta ruta", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 58)
                            .foregroundStyle(.black)
                            .background(OG.accent, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }

                if let sport = historySport, !attempts.isEmpty {
                    NavigationLink {
                        LiveRouteEvolutionView(routeID: routeID, sport: sport)
                    } label: {
                        Label("Ver evolución de esta ruta", systemImage: "chart.xyaxis.line")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard))
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Gestionar ruta").font(.headline)

                    NavigationLink {
                        LiveRouteEditView(routeID: routeID)
                    } label: {
                        Label("Editar nombre y deporte", systemImage: "pencil")
                    }
                    Divider()
                    Button(role: .destructive) {
                        deleteConfirmation = true
                    } label: {
                        Label("Eliminar ruta guardada", systemImage: "trash")
                    }
                    Text("Eliminarla no borra las actividades que ya has registrado.")
                        .font(.caption).foregroundStyle(OG.label2)
                }
                .foregroundStyle(OG.label)
                .padding(16)
                .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard))

                if !attempts.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Actividades realizadas").font(.headline)
                        ForEach(attempts) { session in
                            NavigationLink {
                                WorkoutDetailView(sessionId: session.id)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text((session.startedAt ?? .now)
                                            .formatted(date: .abbreviated, time: .shortened))
                                            .foregroundStyle(OG.label)
                                        Text("\(ReperaNumberFormat.decimal(max(0, session.recordedDistanceMeters ?? 0) / 1000)) km")
                                            .font(.caption).foregroundStyle(OG.label2)
                                    }
                                    Spacer()
                                    Text(clock(session.activeDurationSeconds ?? 0))
                                        .monospacedDigit().foregroundStyle(OG.label)
                                    Image(systemName: "chevron.right")
                                        .font(.caption).foregroundStyle(OG.label2)
                                }
                                .padding(.vertical, 9)
                            }
                        }
                    }
                    .padding(16)
                    .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard))
                } else {
                    Text("Cuando vuelvas a realizar este recorrido podrás comparar las estadísticas.")
                        .font(.footnote)
                        .foregroundStyle(OG.label2)
                }
            }
            .padding(OG.pad)
        }
        .background(OG.bg.ignoresSafeArea())
        .navigationTitle(route?.title ?? "Ruta")
        .navigationBarTitleDisplayMode(.inline)
        .ogTransparentNav()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let route {
                    Button {
                        do {
                            try routes.setFavorite(routeID, !route.isFavorite)
                        } catch {
                            editError = "No se pudo actualizar el favorito."
                        }
                    } label: {
                        Image(systemName: route.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(route.isFavorite ? OG.yellow : OG.label)
                    }
                    .accessibilityLabel(route.isFavorite ? "Quitar de favoritos" : "Añadir a favoritos")
                }
            }
        }
        .alert("No se pudo modificar la ruta", isPresented: Binding(
            get: { editError != nil }, set: { if !$0 { editError = nil } }
        )) {
            Button("Aceptar", role: .cancel) { editError = nil }
        } message: { Text(editError ?? "") }
        .confirmationDialog("¿Eliminar esta ruta?", isPresented: $deleteConfirmation) {
            Button("Eliminar ruta", role: .destructive) {
                do {
                    try routes.remove(routeID)
                    onDeleteRoute(routeID)
                    dismiss()
                } catch {
                    editError = "No se pudo eliminar la ruta. Comprueba el almacenamiento disponible."
                }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Las actividades guardadas se conservarán en Inicio e Historial.")
        }
    }


    private func stat(_ name: String, value: String) -> some View {
        VStack(alignment: .center, spacing: 5) {
            Text(value)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
            Text(name).font(.caption2).foregroundStyle(OG.label2)
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func clock(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        if total >= 3600 {
            return String(format: "%d:%02d:%02d", total / 3600, total / 60 % 60, total % 60)
        }
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    private func region(for points: [WorkoutRoutePoint]) -> MKCoordinateRegion {
        guard let first = points.first else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 40.4, longitude: -3.7),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        }
        let lat = points.map(\.latitude)
        let lon = points.map(\.longitude)
        let lowLat = lat.min() ?? first.latitude
        let highLat = lat.max() ?? first.latitude
        let lowLon = lon.min() ?? first.longitude
        let highLon = lon.max() ?? first.longitude
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (lowLat + highLat) / 2, longitude: (lowLon + highLon) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max(0.004, (highLat - lowLat) * 1.3),
                longitudeDelta: max(0.004, (highLon - lowLon) * 1.3)
            )
        )
    }
}
