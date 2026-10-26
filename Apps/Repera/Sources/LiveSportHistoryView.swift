import Charts
import CoreLocation
import MapKit
import ReperaDomain
import SwiftUI

/// Los deportes no son ejercicios del catálogo: su fuente de verdad son las sesiones En vivo.
struct LiveSportsCatalogView: View {
    @Environment(ReperaStore.self) private var store
    var query: String = ""

    private var sessions: [WorkoutSession] {
        store.state.workouts.filter {
            $0.phase == .finished && $0.finishedAt != nil && $0.liveSportID != nil
        }
    }

    private var visibleSports: [LiveSport] {
        LiveSport.allCases.filter { sport in
            (query.isEmpty || sport.title.localizedStandardContains(query)) &&
            sessions.contains(where: { $0.liveSportID == sport.rawValue })
        }
    }

    var body: some View {
        List {
            if visibleSports.isEmpty {
                ContentUnavailableView(
                    "Sin actividades deportivas",
                    systemImage: "figure.run",
                    description: Text("Las actividades guardadas desde En vivo aparecerán aquí, con sus recorridos y su evolución.")
                )
            } else {
                Section("Deportes registrados") {
                    ForEach(visibleSports) { sport in
                        let related = sessions.filter { $0.liveSportID == sport.rawValue }
                        NavigationLink {
                            LiveSportHistoryView(sport: sport)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: sport.symbol)
                                    .font(.title2)
                                    .foregroundStyle(OG.accent)
                                    .frame(width: 46, height: 46)
                                    .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(sport.title).font(.body.weight(.semibold))
                                    Text(activitySummary(for: sport, sessions: related))
                                        .font(.caption).foregroundStyle(OG.label2)
                                }
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .ogListChrome()
    }

    private func activitySummary(for sport: LiveSport, sessions: [WorkoutSession]) -> String {
        if sport.usesGPS {
            let kilometers = sessions.reduce(0) {
                $0 + max(0, $1.recordedDistanceMeters ?? 0)
            } / 1000
            return "\(sessions.count) actividades · \(ReperaNumberFormat.decimal(kilometers)) km"
        }
        let totalSeconds = sessions.reduce(0) { $0 + max(0, $1.activeDurationSeconds ?? 0) }
        return "\(sessions.count) actividades · \(LiveSportStatsFormat.duration(totalSeconds))"
    }
}

private enum LiveRouteMetric: String, CaseIterable, Identifiable {
    case duration = "Tiempo"
    case pace = "Ritmo / velocidad"
    case distance = "Distancia"

    var id: String { rawValue }
}

struct LiveSportHistoryView: View {
    @Environment(ReperaStore.self) private var store
    @State private var savedRoutes = LiveRoutesStore.shared
    @State private var favoriteError: String?
    let sport: LiveSport

    private var sessions: [WorkoutSession] {
        store.state.workouts.filter {
            $0.liveSportID == sport.rawValue && $0.phase == .finished && $0.finishedAt != nil
        }.sorted { ($0.startedAt ?? .distantPast) > ($1.startedAt ?? .distantPast) }
    }

    private var relatedRoutes: [LiveSavedRoute] {
        let ids = Set(sessions.compactMap(\.liveRouteID))
        return savedRoutes.favoriteRoutes.filter {
            $0.sportID == sport.rawValue || ids.contains($0.id)
        }
    }

    private var totalDuration: Double {
        sessions.reduce(0) { $0 + max(0, $1.activeDurationSeconds ?? 0) }
    }

    private var totalKm: Double {
        sessions.reduce(0) { $0 + max(0, $1.recordedDistanceMeters ?? 0) } / 1000
    }

    private var measuredEnergyKcal: Double? {
        let values = sessions.compactMap(\.appleActiveEnergyKcal).filter { $0 > 0 }
        return values.isEmpty ? nil : values.reduce(0, +)
    }

    private var measuredHeartRateBpm: Double? {
        let values = sessions.compactMap(\.appleAverageHeartRateBpm).filter { $0 > 0 }
        return values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
    }

    /// Marcas deportivas: no mezclar distancia/ritmo con récords de fuerza (e1RM).
    private var longestDistanceMeters: Double? {
        sessions.compactMap(\.recordedDistanceMeters).filter { $0 > 0 }.max()
    }

    private var longestActiveSeconds: Double? {
        sessions.compactMap(\.activeDurationSeconds).filter { $0 > 0 }.max()
    }

    private var fastestRecordedKilometerSeconds: Double? {
        sessions.flatMap { $0.liveKilometerSplitsSeconds ?? [] }
            .filter { $0.isFinite && $0 > 0 }.min()
    }

    var body: some View {
        List {
            Section("Resumen") {
                HStack(spacing: 8) {
                    tile("Actividades", value: "\(sessions.count)")
                    tile("Tiempo", value: LiveSportStatsFormat.duration(totalDuration))
                    if sport.usesGPS {
                        tile("Distancia", value: "\(ReperaNumberFormat.decimal(totalKm)) km")
                    } else if let kcal = measuredEnergyKcal {
                        tile("Energía medida", value: "\(Int(kcal.rounded())) kcal")
                    } else if let heart = measuredHeartRateBpm {
                        tile("Pulso medio", value: "\(Int(heart.rounded())) lpm")
                    }
                }
                .padding(.vertical, 8)
                if let heart = measuredHeartRateBpm, sport.usesGPS || measuredEnergyKcal != nil {
                    Label(
                        "Pulso medio medido: \(Int(heart.rounded())) lpm",
                        systemImage: "heart"
                    )
                    .font(.caption)
                    .foregroundStyle(OG.label2)
                }
            }

            if !sessions.isEmpty {
                Section("Mejores marcas · \(sport.title)") {
                    HStack(spacing: 8) {
                        if let distance = longestDistanceMeters, sport.usesGPS {
                            tile("Mayor distancia", value: "\(ReperaNumberFormat.decimal(distance / 1000)) km")
                        }
                        if let seconds = fastestRecordedKilometerSeconds, sport.usesGPS {
                            tile("Mejor km", value: LiveSportStatsFormat.duration(seconds))
                        }
                        if let seconds = longestActiveSeconds {
                            tile("Mayor duración", value: LiveSportStatsFormat.duration(seconds))
                        }
                    }
                    .padding(.vertical, 8)
                    Text("Marcas basadas en actividades guardadas de este deporte. No representan récords de fuerza.")
                        .font(.caption)
                        .foregroundStyle(OG.label2)
                }
            }

            if sport.usesGPS && !relatedRoutes.isEmpty {
                Section("Rutas favoritas · evolución") {
                    ForEach(relatedRoutes) { route in
                        let attempts = sessions.filter { $0.liveRouteID == route.id }
                        NavigationLink {
                            LiveRouteEvolutionView(routeID: route.id, sport: sport)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(OG.yellow)
                                    .frame(width: 30)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(route.title).font(.body.weight(.medium))
                                    Text("\(attempts.count) veces realizada")
                                        .font(.caption).foregroundStyle(OG.label2)
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            }

            Section(sport.usesGPS ? "Recorridos realizados" : "Actividades realizadas") {
                ForEach(sessions) { session in
                    NavigationLink {
                        WorkoutDetailView(sessionId: session.id)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: sport.symbol)
                                .foregroundStyle(OG.accent)
                                .frame(width: 30)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(session.title).font(.subheadline.weight(.semibold))
                                Text((session.startedAt ?? session.finishedAt ?? .now)
                                    .formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption).foregroundStyle(OG.label2)
                                HStack(spacing: 12) {
                                    Text(LiveSportStatsFormat.duration(session.activeDurationSeconds ?? 0))
                                    if let distance = session.recordedDistanceMeters, distance > 0 {
                                        Text("\(ReperaNumberFormat.decimal(distance / 1000)) km")
                                    }
                                    if let heartRate = session.appleAverageHeartRateBpm,
                                       heartRate > 0 {
                                        Text("\(Int(heartRate.rounded())) lpm")
                                    }
                                    if let kcal = session.appleActiveEnergyKcal, kcal > 0 {
                                        Text("\(Int(kcal.rounded())) kcal")
                                    }
                                    if isFavorite(session) {
                                        Image(systemName: "star.fill").foregroundStyle(OG.yellow)
                                    }
                                }
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(OG.label2)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 3)
                    }
                    .swipeActions(edge: .trailing) {
                        if sport.usesGPS && session.routePoints.count >= 2 &&
                            !isFavorite(session) {
                            Button {
                                saveAsFavorite(session)
                            } label: {
                                Label("Guardar ruta", systemImage: "star")
                            }
                            .tint(OG.yellow)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .ogListChrome()
        .ogPinnedTransparentNav(sport.title)
        .alert("No se pudo guardar la ruta", isPresented: Binding(
            get: { favoriteError != nil },
            set: { if !$0 { favoriteError = nil } }
        )) {
            Button("Aceptar", role: .cancel) { favoriteError = nil }
        } message: { Text(favoriteError ?? "") }
    }

    private func isFavorite(_ session: WorkoutSession) -> Bool {
        guard let id = session.liveRouteID else { return false }
        return savedRoutes.routes.contains { $0.id == id && $0.isFavorite }
    }

    private func saveAsFavorite(_ session: WorkoutSession) {
        do {
            if let routeID = session.liveRouteID,
               savedRoutes.routes.contains(where: { $0.id == routeID }) {
                try savedRoutes.setFavorite(routeID, true)
            } else {
                let routeID = try savedRoutes.addRecordedRoute(from: session, favorite: true)
                var updated = session
                updated.liveRouteID = routeID
                store.saveWorkout(updated)
            }
        } catch {
            favoriteError = "Comprueba el almacenamiento disponible e inténtalo de nuevo."
        }
    }

    private func tile(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(value)
                .font(.system(size: 19, weight: .semibold, design: .rounded).monospacedDigit())
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(label).font(.caption2).foregroundStyle(OG.label2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LiveRouteAttempt: Identifiable {
    var id: UUID
    var date: Date
    var duration: Double
    var distanceKm: Double
    var value: Double
}

struct LiveRouteEvolutionView: View {
    @Environment(ReperaStore.self) private var store
    @State private var savedRoutes = LiveRoutesStore.shared
    @State private var metric: LiveRouteMetric = .duration
    @State private var position: MapCameraPosition = .automatic
    let routeID: UUID
    let sport: LiveSport

    private var route: LiveSavedRoute? {
        savedRoutes.routes.first { $0.id == routeID }
    }

    private var attempts: [WorkoutSession] {
        store.state.workouts.filter {
            $0.liveRouteID == routeID && $0.liveSportID == sport.rawValue &&
            $0.phase == .finished && $0.finishedAt != nil
        }.sorted { ($0.startedAt ?? .distantPast) < ($1.startedAt ?? .distantPast) }
    }

    /// Solo comparar tiempos completos, con distancia GPS dentro del 20 % del recorrido.
    /// No convertir una salida cortada a mitad en un récord personal.
    private var eligibleAttempts: [WorkoutSession] {
        let plannedKm = plannedDistanceKm
        guard plannedKm > 0.2 else { return attempts.filter { ($0.recordedDistanceMeters ?? 0) > 0 } }
        return attempts.filter {
            let actualKm = max(0, $0.recordedDistanceMeters ?? 0) / 1000
            return actualKm >= plannedKm * 0.8 && actualKm <= plannedKm * 1.2
        }
    }

    private var plannedDistanceKm: Double {
        guard let route else { return 0 }
        let points = route.points
        guard points.count > 1 else { return 0 }
        return zip(points, points.dropFirst()).reduce(0.0) { total, pair in
            let from = CLLocation(latitude: pair.0.latitude, longitude: pair.0.longitude)
            let to = CLLocation(latitude: pair.1.latitude, longitude: pair.1.longitude)
            return total + from.distance(from: to)
        } / 1000
    }

    private var chartAttempts: [LiveRouteAttempt] {
        eligibleAttempts.compactMap { session in
            guard let date = session.startedAt,
                  let duration = session.activeDurationSeconds, duration > 0,
                  let meters = session.recordedDistanceMeters, meters > 0 else { return nil }
            let km = meters / 1000
            let value: Double
            switch metric {
            case .duration: value = duration / 60
            case .pace: value = sport.displaysSpeed ? km / (duration / 3600) : duration / 60 / km
            case .distance: value = km
            }
            guard value.isFinite else { return nil }
            return LiveRouteAttempt(
                id: session.id, date: date, duration: duration, distanceKm: km, value: value
            )
        }
    }

    private var fastest: WorkoutSession? {
        eligibleAttempts.filter { ($0.activeDurationSeconds ?? 0) > 0 }
            .min { ($0.activeDurationSeconds ?? .greatestFiniteMagnitude) <
                ($1.activeDurationSeconds ?? .greatestFiniteMagnitude) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let route, route.points.count >= 2 {
                    Map(position: $position) {
                        MapPolyline(coordinates: route.points.map {
                            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                        })
                        .stroke(OG.accent, lineWidth: 5)
                    }
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: OG.radiusLG))
                    .task { position = .region(region(for: route.points)) }
                }

                OGCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Evolución del recorrido")
                            .font(.headline)
                        HStack(spacing: 8) {
                            summary("Veces", value: "\(attempts.count)")
                            summary("Mejor tiempo", value: fastest
                                .map { LiveSportStatsFormat.duration($0.activeDurationSeconds ?? 0) } ?? "—")
                            summary("Distancia", value: plannedDistanceKm > 0
                                ? "\(ReperaNumberFormat.decimal(plannedDistanceKm)) km" : "—")
                        }
                        if attempts.count != eligibleAttempts.count {
                            Text("Los intentos con un recorrido incompleto no cuentan para el mejor tiempo.")
                                .font(.caption).foregroundStyle(OG.label2)
                        }

                        Picker("Métrica", selection: $metric) {
                            ForEach(LiveRouteMetric.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.menu)

                        if chartAttempts.count >= 2 {
                            Chart(chartAttempts) { attempt in
                                LineMark(
                                    x: .value("Fecha", attempt.date),
                                    y: .value("Resultado", attempt.value)
                                )
                                .foregroundStyle(OG.accent)
                                .interpolationMethod(.catmullRom)
                                PointMark(
                                    x: .value("Fecha", attempt.date),
                                    y: .value("Resultado", attempt.value)
                                )
                                .foregroundStyle(OG.accent)
                            }
                            .chartYAxisLabel(metric == .duration ? "min" :
                                metric == .distance ? "km" :
                                sport.displaysSpeed ? "km/h" : "min/km")
                            .frame(height: 215)
                        } else {
                            ContentUnavailableView(
                                "Sin evolución todavía",
                                systemImage: "chart.xyaxis.line",
                                description: Text("Repite esta ruta para comparar tus tiempos, ritmo y distancia.")
                            )
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Sesiones en esta ruta").font(.headline)
                    ForEach(attempts.reversed()) { session in
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
                                Text(LiveSportStatsFormat.duration(session.activeDurationSeconds ?? 0))
                                    .monospacedDigit().foregroundStyle(OG.label)
                                Image(systemName: "chevron.right").font(.caption)
                                    .foregroundStyle(OG.label2)
                            }
                            .padding(14)
                            .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(OG.pad)
            .ogReadableColumn()
        }
        .background(OG.bg.ignoresSafeArea())
        .ogPinnedTransparentNav(route?.title ?? "Evolución de ruta")
    }

    private func summary(_ name: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.system(size: 15, weight: .semibold, design: .rounded))
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
            Text(name).font(.caption2).foregroundStyle(OG.label2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func region(for points: [WorkoutRoutePoint]) -> MKCoordinateRegion {
        let lats = points.map(\.latitude), lons = points.map(\.longitude)
        let latLow = lats.min() ?? 40.4, latHigh = lats.max() ?? 40.4
        let lonLow = lons.min() ?? -3.7, lonHigh = lons.max() ?? -3.7
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (latLow + latHigh) / 2, longitude: (lonLow + lonHigh) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max(0.004, (latHigh - latLow) * 1.3),
                longitudeDelta: max(0.004, (lonHigh - lonLow) * 1.3)
            )
        )
    }
}

private enum LiveSportStatsFormat {
    static func duration(_ seconds: Double) -> String {
        let s = max(0, Int(seconds))
        if s >= 3600 {
            return String(format: "%d:%02d:%02d", s / 3600, (s / 60) % 60, s % 60)
        }
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
}
