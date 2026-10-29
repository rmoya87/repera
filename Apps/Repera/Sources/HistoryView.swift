import Charts
import CoreLocation
import HealthKit
import ReperaDomain
import MapKit
import SwiftUI

struct HistoryView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(HealthKitStore.self) private var health

    /// Entradas unificadas: Repera + Salud (misma fuente que alimenta la racha de Inicio).
    private enum HistoryEntry: Identifiable {
        case repera(WorkoutSession)
        case health(HealthKitStore.ExternalActivity)

        var id: String {
            switch self {
            case .repera(let s): return "g-\(s.id.uuidString)"
            case .health(let a): return "h-\(a.id.uuidString)"
            }
        }

        var sortDate: Date {
            switch self {
            case .repera(let s):
                return s.timerDetails != nil
                    ? (s.startedAt ?? s.finishedAt ?? .distantPast)
                    : (s.finishedAt ?? s.startedAt ?? .distantPast)
            case .health(let a): return a.start
            }
        }
    }

    private struct DaySection: Identifiable {
        var id: Date
        var title: String
        var entries: [HistoryEntry]
    }

    @State private var prCountBySessionId: [UUID: Int] = [:]
    @State private var didRequestHealthRefresh = false

    /// Solo sesiones terminadas (no planes guardados ni borradores).
    private var finishedWorkouts: [WorkoutSession] {
        store.state.workouts.filter { $0.finishedAt != nil && $0.phase == .finished }
    }

    private var entries: [HistoryEntry] {
        let repera = finishedWorkouts.map { HistoryEntry.repera($0) }
        let healthOnes = health.recentExternalActivities.map { HistoryEntry.health($0) }
        return (repera + healthOnes).sorted { $0.sortDate > $1.sortDate }
    }

    private var daySections: [DaySection] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: entries) { cal.startOfDay(for: $0.sortDate) }
        return grouped.keys.sorted(by: >).map { day in
            DaySection(
                id: day,
                title: sectionTitle(for: day),
                entries: (grouped[day] ?? []).sorted { $0.sortDate > $1.sortDate }
            )
        }
    }

    var body: some View {
        let sections = daySections
        return Group {
            if sections.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        OGScrollablePageTitle("Historial")
                        ContentUnavailableView(
                            "Sin entrenos",
                            systemImage: "tray",
                            description: Text("Las sesiones de Repera y de Apple Salud aparecerán aquí.")
                        )
                        .foregroundStyle(OG.label2)
                        .frame(maxWidth: .infinity, minHeight: 260)
                    }
                    .padding(.horizontal, OG.pad)
                    .padding(.top, 8)
                }
            } else {
                List {
                    OGScrollablePageTitle("Historial").ogScrollingTitleListRow()
                    Section {
                        NavigationLink {
                            LiveSportsCatalogView()
                        } label: {
                            Label("Deportes · evolución y récords", systemImage: "figure.run")
                                .foregroundStyle(OG.label)
                        }
                    }
                    ForEach(sections) { section in
                        Section {
                            ForEach(section.entries) { entry in
                                switch entry {
                                case .repera(let session):
                                    NavigationLink {
                                        WorkoutDetailView(sessionId: session.id)
                                    } label: {
                                        reperaHistoryRow(session)
                                    }
                                    .navigationLinkIndicatorVisibility(.hidden)
                                    .listRowInsets(EdgeInsets(
                                        top: 10,
                                        leading: Self.historyRowPad,
                                        bottom: 10,
                                        trailing: 0
                                    ))
                                case .health(let activity):
                                    NavigationLink {
                                        HealthActivityDetailView(activityId: activity.id)
                                    } label: {
                                        healthHistoryRow(activity)
                                    }
                                    .navigationLinkIndicatorVisibility(.hidden)
                                    .listRowInsets(EdgeInsets(
                                        top: 10,
                                        leading: Self.historyRowPad,
                                        bottom: 10,
                                        trailing: 0
                                    ))
                                }
                            }
                            .onDelete { indexSet in
                                deleteEntries(in: section, at: indexSet)
                            }
                        } header: {
                            Text(section.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(OG.label2)
                                .textCase(nil)
                        }
                    }
                }
                .ogListChrome()
            }
        }
        .background(OG.bg)
        .ogScrollingTitleNav()
        .task(id: store.workoutsEpoch) {
            // No persistir reviews masivamente al abrir: causaba invalidaciones
            // del store y un refresco costoso al regresar de un detalle.
            prCountBySessionId = store.cachedPersonalRecordCountsBySession()
        }
        .task {
            guard !didRequestHealthRefresh else { return }
            didRequestHealthRefresh = true
            await refreshHealthEntries()
            guard !Task.isCancelled else { return }
            await health.refreshVerifiedWorkoutEnergy(for: finishedWorkouts)
        }
    }

    private func sectionTitle(for day: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(day) { return "Hoy" }
        if cal.isDateInYesterday(day) { return "Ayer" }
        return SpanishDate.long(day)
    }

    private func refreshHealthEntries() async {
        guard health.isAvailable else { return }
        let linked = Set(store.state.workouts.compactMap(\.healthKitWorkoutUUID))
        // Mismo horizonte que Progreso/racha (360d) para que Historial cubra las semanas contadas.
        await health.refreshRecentExternalActivities(
            excludingUUIDs: linked,
            overlappingSessions: store.state.workouts,
            days: 360
        )
    }

    private func deleteEntries(in section: DaySection, at indexSet: IndexSet) {
        let doomed = indexSet.map { section.entries[$0] }
        for entry in doomed {
            switch entry {
            case .repera(let session):
                // HealthKit delete is centralized in `ReperaStore.deleteWorkout`.
                store.deleteWorkout(session.id)
            case .health(let activity):
                Task {
                    _ = await HealthKitStore.shared.deleteExternalWorkout(id: activity.id)
                }
            }
        }
    }

    private func reperaHistoryRow(_ session: WorkoutSession) -> some View {
        // La lista ya observa el store; evitar una búsqueda O(n) por fila.
        let live = session
        let prs = prCountBySessionId[live.id] ?? 0
        let start = live.startedAt ?? live.finishedAt
        let day = start.map { Calendar.current.startOfDay(for: $0) } ?? Date()

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                // Historial: icono de fuerza (Inicio usa check).
                OGRegisterLeadingIcon(
                    systemName: session.timerDetails == nil
                        ? "figure.strengthtraining.traditional" : "timer",
                    tint: OG.accent
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(WorkoutListCaption.dayTimeLine(
                        for: day,
                        time: start.map(SpanishDate.time)
                    ))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(OG.label3)
                    .tracking(0.3)
                    HStack(spacing: 6) {
                        Text(live.title)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(OG.label)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        historyChevron
                    }
                }
            }
            .padding(.trailing, Self.historyRowPad)

            // Misma secuencia que Inicio (`WorkoutRegisterChips`).
            OGRegisterChipsRow(leadingInset: Self.chipsTitleLeading) {
                WorkoutRegisterChips.repera(
                    session: live,
                    prCount: prs,
                    verifiedHealthKcal: live.healthKitWorkoutUUID.flatMap {
                        health.verifiedWorkoutEnergyKcal[$0]
                    }
                )
            }
            .padding(.leading, -Self.historyRowPad)
        }
    }

    private func healthHistoryRow(_ activity: HealthKitStore.ExternalActivity) -> some View {
        let day = Calendar.current.startOfDay(for: activity.start)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                OGRegisterLeadingIcon(systemName: activity.symbolName, tint: OG.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text(WorkoutListCaption.dayTimeLine(
                        for: day,
                        time: SpanishDate.time(activity.start)
                    ))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(OG.label3)
                    .tracking(0.3)
                    HStack(spacing: 6) {
                        Text(activity.title)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(OG.label)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        historyChevron
                    }
                }
            }
            .padding(.trailing, Self.historyRowPad)

            OGRegisterChipsRow(leadingInset: Self.chipsTitleLeading) {
                WorkoutRegisterChips.health(activity)
            }
            .padding(.leading, -Self.historyRowPad)
        }
    }

    private var historyChevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(OG.label3)
            .padding(.leading, 2)
    }

    /// Inset leading de la fila; trailing 0 para que el carrusel llegue al borde del cuadrado.
    private static let historyRowPad: CGFloat = 16
    /// Row pad + icono 44 + gap 12 → chips alineados al título en reposo.
    private static let chipsTitleLeading: CGFloat = historyRowPad + 44 + 12
}

/// Detalle visual de un entreno completado (mismo lenguaje que Entreno / preview).
struct WorkoutDetailView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(HealthKitStore.self) private var health
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var routeZoomNamespace

    var sessionId: UUID

    /// Preload the selected workout before SwiftUI begins the navigation
    /// animation. Callers without a snapshot keep the existing lazy fallback.
    init(sessionId: UUID, initialSession: WorkoutSession? = nil) {
        self.sessionId = sessionId
        _draft = State(initialValue: initialSession)
    }

    @State private var draft: WorkoutSession?
    @State private var didHydrateDetail = false
    @State private var isEditing = false
    @State private var showCompletedEditor = false
    /// Freeze the editor's routine once, when the user taps Editar.
    @State private var preparedCompletedRoutine: Routine?
    @State private var showDeleteConfirm = false
    @State private var favoriteSaveError: String?
    @State private var isSavingFavorite = false
    @State private var healthExtras: HealthKitStore.SessionHealthExtras?
    @State private var showFullScreenRoute = false
    @State private var fullScreenRoutePoints: [HealthKitStore.RoutePoint] = []
    @State private var fullScreenPin: WorkoutLocationPin?
    /// Un solo destino: evita apilar fichas si hay varios links en la misma card.
    @State private var exerciseRoute: DetailExerciseRoute?

    private var weightStep: Double { store.state.settings.weightIncrementKg }

    private struct DetailExerciseRoute: Identifiable, Hashable {
        let id = UUID()
        var exerciseId: UUID
        var sessionId: UUID
        var exerciseInstanceId: UUID
    }

    private var subtitle: String {
        guard let session = draft, let start = session.startedAt else { return "" }
        return SpanishDate.sessionSubtitle(start: start, end: session.finishedAt)
    }

    private var workoutNavTitle: String {
        let name = draft?.title.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "Entreno" : name
    }

    var body: some View {
        Group {
            if draft != nil {
                detailList
            } else {
                ContentUnavailableView("Entreno no encontrado", systemImage: "questionmark")
                    .foregroundStyle(OG.label2)
            }
        }
        .onAppear { loadDraft() }
        .onChange(of: store.catalogEpoch) { _, _ in
            // Si llegan los alias mientras el detalle ya está abierto, usar
            // la sesión reconciliada sin cerrar/recrear la navegación.
            guard !isEditing else { return }
            draft = store.state.workouts.first(where: { $0.id == sessionId })
        }
        .onChange(of: store.workoutsEpoch) { _, _ in
            // Si termina una recuperación mientras el detalle está abierto,
            // actualizar el mapa sin obligar a cerrar y reabrir la pantalla.
            guard !isEditing else { return }
            draft = store.state.workouts.first(where: { $0.id == sessionId })
        }
        .task(id: sessionId) {
            guard !didHydrateDetail else { return }
            // Catalog relinking already runs during bootstrap / cloud recovery.
            // Doing an all-history repair every time the detail opens caused
            // large MainActor work and unnecessary disk/iCloud writes.
            loadDraft()
            guard let session = draft else { return }
            // A push animation needs a stable, already populated tree.
            // Defer store mutations, review calculations and HealthKit work
            // until after the navigation transition, not merely one yield.
            do {
                try await Task.sleep(for: .milliseconds(400))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            if session.timerDetails != nil {
                // Un cronómetro no es una sesión HealthKit: no buscar por
                // solape ni calcular FC, kcal o una nota de rendimiento.
                healthExtras = nil
                didHydrateDetail = true
                return
            }
            if session.sessionReview == nil {
                _ = store.ensureSessionReview(for: sessionId)
                draft = store.state.workouts.first(where: { $0.id == sessionId })
            }
            #if DEBUG
            // Diagnóstico sin datos personales si un WOD histórico todavía
            // muestra el alias antiguo: permite leer los escalares OCR reales,
            // el UUID original y la ficha a la que resuelve la app.
            for entry in session.exercises {
                let raw = entry.exercise.name
                let key = raw.lowercased()
                guard key.contains("bt") || key.contains("t2") || key.contains("ttb")
                    || key.contains("toes") else { continue }
                let scalars = raw.unicodeScalars.map {
                    String(format: "%04X", $0.value)
                }.joined(separator: " ")
                let resolved = store.historicalDisplayExercise(entry.exercise)
                NSLog(
                    "REPERA_ALIAS_DEBUG raw=%@ scalars=%@ savedUUID=%@ matched=%@ matchedUUID=%@",
                    raw, scalars, entry.exercise.id.uuidString,
                    resolved.name, resolved.id.uuidString
                )
            }
            #endif
            let extras = await health.sessionHealthExtras(for: session)
            guard !Task.isCancelled else { return }
            healthExtras = extras
            // Al abrir un recorrido histórico sin coordenadas, consultar
            // iCloud por si el documento completo sigue en descarga.
            if session.routePoints.count < 2,
               (extras?.routePoints.count ?? 0) < 2,
               session.liveSportID.flatMap({ LiveSport(rawValue: $0)?.usesGPS }) == true,
               !store.isSyncingiCloud {
                await store.refreshFromiCloud()
                guard !Task.isCancelled else { return }
                draft = store.state.workouts.first(where: { $0.id == sessionId })
            }
            // Refinar una sola vez por apertura, no en cada vuelta de navegación.
            await store.refineSessionReviewWithHealth(sessionId: sessionId)
            guard !Task.isCancelled else { return }
            draft = store.state.workouts.first(where: { $0.id == sessionId })
            didHydrateDetail = true
        }
        // Push con zoom animado desde la vista previa y retorno a su origen.
        .navigationDestination(isPresented: $showFullScreenRoute) {
            fullScreenRouteDestination
                .navigationTransition(.zoom(sourceID: sessionId, in: routeZoomNamespace))
        }
        .sheet(isPresented: $showDeleteConfirm) {
            if let title = draft?.title {
                OGConfirmSheet(
                    title: "¿Eliminar entreno?",
                    message: "Se borrará «\(title)» de este día. No se puede deshacer.",
                    onConfirm: {
                        store.deleteWorkout(sessionId)
                        showDeleteConfirm = false
                        dismiss()
                    },
                    onCancel: { showDeleteConfirm = false }
                )
            }
        }
        // SwiftUI .alert no permite colorear el fondo del botón nativo.
        // Aviso propio: verde Repera y contraste explícito día/noche.
        .overlay {
            if let favoriteSaveError {
                ZStack {
                    Color.black.opacity(0.38).ignoresSafeArea()
                    VStack(alignment: .leading, spacing: 20) {
                        Text("No se ha podido guardar el favorito")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(OG.label)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(favoriteSaveError)
                            .font(.system(size: 16))
                            .foregroundStyle(OG.label2)
                            .fixedSize(horizontal: false, vertical: true)
                        Button {
                            self.favoriteSaveError = nil
                        } label: {
                            Text("Aceptar")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
                                .frame(maxWidth: .infinity, minHeight: 54)
                                .background(OG.accent, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("favorite-error-accept")
                    }
                    .padding(24)
                    .frame(maxWidth: 400)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .padding(.horizontal, 26)
                    .accessibilityElement(children: .contain)
                }
                .transition(.opacity)
                .zIndex(2)
                .accessibilityIdentifier("favorite-error-overlay")
            }
        }
    }

    /// Mapa completo con pan/zoom; la X cambia contraste con el sistema.
    private var fullScreenRouteDestination: some View {
        WorkoutMapZoomDestination(
            points: fullScreenRoutePoints,
            pin: fullScreenPin,
            isWaterSport: draft?.liveSportID.flatMap {
                LiveSport(rawValue: $0)?.isWaterSport
            } ?? false,
            paceMode: draft?.liveSportID.flatMap { LiveSport(rawValue: $0)?.routePaceMode } ?? .walking,
            referenceRoutePoints: draft.map { referenceRoutePoints($0) } ?? [],
            showsSpeedLegend: true,
            onClose: { showFullScreenRoute = false }
        )
    }

    /// Un problema al guardar o al leer la sesión nunca debe solicitar pago.
    private func toggleHistoricalFavorite() async {
        guard !isSavingFavorite else { return }
        isSavingFavorite = true
        defer { isSavingFavorite = false }
        favoriteSaveError = nil
        subscriptions.syncCounts(
            libraryRoutines: store.libraryRoutineCount,
            customExercises: store.customExerciseCount,
            favorites: store.favoriteCount
        )
        // La suscripción verificada es la fuente de verdad de esta acción.
        // No utilizar una política heredada de un lanzamiento anterior.
        store.featureAccess = { [subscriptions] in subscriptions.policy }
        if store.toggleWorkoutFavorite(sessionId) {
            draft = store.state.workouts.first(where: { $0.id == sessionId })
            return
        }
        if store.lastAccessDenial != nil {
            await subscriptions.refreshEntitlementsForFeatureAction()
            if store.toggleWorkoutFavorite(sessionId) {
                draft = store.state.workouts.first(where: { $0.id == sessionId })
                return
            }
        }
        if let decision = store.lastAccessDenial, !decision.allowed,
           !subscriptions.policy.isPro, subscriptions.snapshot.status != .unknown {
            subscriptions.presentPaywall(
                decision.paywallContext, feature: .unlimitedRoutines
            )
        } else {
            if let explicitError = store.lastFavoriteSaveError {
                favoriteSaveError = explicitError
            } else if store.lastAccessDenial != nil && subscriptions.policy.isPro {
                favoriteSaveError = "Tu acceso Pro está activo, pero esta actividad sigue rechazando el guardado por una restricción de acceso. Actualiza Repera desde TestFlight y vuelve a intentarlo."
            } else if subscriptions.snapshot.status == .unknown && !subscriptions.isPro {
                favoriteSaveError = "No hemos podido verificar tu suscripción. Comprueba la conexión o utiliza «Restaurar compras» en Ajustes."
            } else {
                favoriteSaveError = "No se ha podido guardar esta actividad como favorita. El entrenamiento original no se ha modificado."
            }
        }
    }

    private func loadDraft() {
        if draft == nil {
            draft = store.state.workouts.first(where: { $0.id == sessionId })
        }
    }

    private enum SessionMapKind: Equatable {
        case none
        case healthRoute
        case ownRoute
        case pin
    }

    private func sessionMapContent(_ session: WorkoutSession) -> SessionMapKind {
        let local = session.routePoints
        let healthRoute = healthExtras?.routePoints ?? []
        // Tras un cierre inesperado, Salud puede no tener todavía todos los
        // puntos que sí sobrevivieron en el checkpoint GPS de Repera.
        if local.count >= 2,
           (local.contains(where: { $0.isEstimated == true })
            || local.count >= healthRoute.count) {
            return .ownRoute
        }
        if healthRoute.count >= 2 { return .healthRoute }
        if local.count >= 2 { return .ownRoute }
        if session.locationPin != nil { return .pin }
        return .none
    }

    private func displayedRoute(_ session: WorkoutSession) -> [HealthKitStore.RoutePoint] {
        let local = session.routePoints
        let healthRoute = healthExtras?.routePoints ?? []
        if local.count >= 2,
           (local.contains(where: { $0.isEstimated == true })
            || local.count >= healthRoute.count) {
            return local.map(\.asHealthRoutePoint)
        }
        if healthRoute.count >= 2 { return healthRoute }
        return local.map(\.asHealthRoutePoint)
    }

    /// La ruta importada es una referencia visual: jamás se añade a los
    /// puntos medidos, a la distancia ni a los parciales del entrenamiento.
    private func referenceRoutePoints(_ session: WorkoutSession) -> [WorkoutRoutePoint] {
        guard let routeID = session.liveRouteID else { return [] }
        return LiveRoutesStore.shared.routes.first(where: { $0.id == routeID })?.points ?? []
    }

    private func displayedMetrics(_ session: WorkoutSession) -> HealthKitStore.SessionHealthExtras? {
        var extras = healthExtras ?? .init()
        if extras.routePoints.count < 2 {
            extras.routePoints = displayedRoute(session)
            // Rutas grabadas localmente pueden traer velocidad aunque no exista HKWorkout.
            let speeds = extras.routePoints.compactMap(\.speedMps)
                .filter { $0.isFinite && $0 >= 0 && $0 <= 35 }
            if !speeds.isEmpty {
                extras.averageSpeedKmh = speeds.reduce(0, +) / Double(speeds.count) * 3.6
                extras.maxSpeedKmh = speeds.max().map { $0 * 3.6 }
            }
        }
        return extras.hasAuthenticSaludMetrics ? extras : nil
    }

    private func mapCoordinates(_ session: WorkoutSession) -> (lat: Double, lon: Double)? {
        if let point = displayedRoute(session).first { return (point.latitude, point.longitude) }
        if let pin = session.locationPin { return (pin.latitude, pin.longitude) }
        return nil
    }

    @ViewBuilder
    private func sessionMapView(_ session: WorkoutSession) -> some View {
        // El mapa de vista previa no recibe gestos; una superficie táctil
        // independiente CAPTURA toda la tarjeta del mapa de forma fiable.
        switch sessionMapContent(session) {
        case .healthRoute:
            if healthExtras != nil {
                let route = displayedRoute(session)
                WorkoutMapTapTarget(accessibilityLabel: "Ampliar recorrido") {
                    fullScreenPin = nil
                    fullScreenRoutePoints = route
                    showFullScreenRoute = true
                } map: {
                    HealthWorkoutRouteMap(
                        points: route, isInteractive: false,
                        isWaterSport: session.liveSportID.flatMap {
                            LiveSport(rawValue: $0)?.isWaterSport
                        } ?? false,
                        paceMode: session.liveSportID.flatMap { LiveSport(rawValue: $0)?.routePaceMode } ?? .walking,
                        referenceRoutePoints: referenceRoutePoints(session),
                        showsSpeedLegend: true
                    )
                    .matchedTransitionSource(id: sessionId, in: routeZoomNamespace)
                }
            }
        case .ownRoute:
            WorkoutMapTapTarget(accessibilityLabel: "Ampliar recorrido") {
                fullScreenPin = nil
                fullScreenRoutePoints = session.routePoints.map(\.asHealthRoutePoint)
                showFullScreenRoute = true
            } map: {
                HealthWorkoutRouteMap(
                    points: session.routePoints.map(\.asHealthRoutePoint),
                    isInteractive: false,
                    isWaterSport: session.liveSportID.flatMap {
                        LiveSport(rawValue: $0)?.isWaterSport
                    } ?? false,
                    paceMode: session.liveSportID.flatMap { LiveSport(rawValue: $0)?.routePaceMode } ?? .walking,
                    referenceRoutePoints: referenceRoutePoints(session),
                    showsSpeedLegend: true
                )
                .matchedTransitionSource(id: sessionId, in: routeZoomNamespace)
            }
        case .pin:
            if let pin = session.locationPin {
                WorkoutMapTapTarget(accessibilityLabel: "Ampliar ubicación") {
                    fullScreenRoutePoints = []
                    fullScreenPin = pin
                    showFullScreenRoute = true
                } map: {
                    WorkoutLocationPinMap(pin: pin, isInteractive: false)
                        .matchedTransitionSource(id: sessionId, in: routeZoomNamespace)
                }
            }
        case .none:
            EmptyView()
        }
    }

    private var detailList: some View {
        List {
            OGScrollablePageTitle(workoutNavTitle).ogScrollingTitleListRow()
            if let session = draft {
                // La fecha es cabecera EXTERIOR, no contenido de la primera
                // fila insetGrouped. Evita que las esquinas redondeadas de List
                // recorten la L de «Lunes» mientras deja visibles solo las tiles.
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        summaryCard(session)
                        if let review = session.sessionReview {
                            SessionReviewCard(review: review)
                        }
                    }
                    .ogCardListRow(top: 0, bottom: 2)
                } header: {
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(OG.label2)
                            .textCase(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.leading, 2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                if let timer = session.timerDetails {
                    Section {
                        LabeledContent("Modalidad", value: timer.modeTitle)
                        LabeledContent(
                            "Duración", value: DurationText.format(timer.configuredSeconds)
                        )
                        if timer.modeRaw == "intervals" {
                            LabeledContent("Rondas", value: "\(timer.rounds)")
                            LabeledContent("Trabajo", value: DurationText.format(timer.workSeconds))
                            LabeledContent("Descanso", value: DurationText.format(timer.restSeconds))
                        }
                        LabeledContent(
                            "Cuenta atrás",
                            value: timer.countdownSeconds > 0
                                ? "\(timer.countdownSeconds) s" : "Desactivada"
                        )
                    } header: {
                        Text("Temporizador")
                            .foregroundStyle(OG.accent)
                            .textCase(nil)
                    }
                    if let pin = session.locationPin {
                        // Historial: mapa simple sin chip (el chip es de editor/Play).
                        Section {
                            WorkoutLocationPinMap(pin: pin, isInteractive: false)
                                .frame(height: 180)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
                                .ogCardListRow()
                        } header: {
                            Text("Lugar").textCase(nil)
                        }
                    }
                }

                // El mapa va directamente debajo de la fecha y las tiles.
                if !isEditing, session.timerDetails == nil, sessionMapContent(session) != .none {
                    Section {
                        let coordinate = mapCoordinates(session)
                        SessionMapWeatherCard(
                            latitude: coordinate?.lat,
                            longitude: coordinate?.lon,
                            workoutDate: session.startedAt ?? session.finishedAt ?? Date()
                        ) {
                            sessionMapView(session)
                        }
                        .ogCardListRow()
                        if session.routePoints.contains(where: { $0.isEstimated == true }) {
                            Text("El tramo discontinuo se ha estimado en línea recta tras un cierre inesperado; no es una medición GPS.")
                                .font(.caption)
                                .foregroundStyle(OG.label2)
                                .ogCardListRow()
                        }
                    }
                } else if !isEditing,
                          session.liveSportID.flatMap({ LiveSport(rawValue: $0)?.usesGPS }) == true,
                          (session.recordedDistanceMeters ?? 0) > 0 {
                    // La distancia puede estar disponible antes que las
                    // coordenadas. No dibujar un trazado inventado.
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Recorrido no disponible", systemImage: "map")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(OG.label)
                            Text("La distancia está guardada, pero todavía no están disponibles los puntos del recorrido. Comprueba que iCloud esté activado y sincronizado en tus dispositivos.")
                                .font(.system(size: 13))
                                .foregroundStyle(OG.label2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, minHeight: 124, alignment: .leading)
                        .padding(OG.pad)
                        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
                        .ogCardListRow()
                    }
                }

                // Plantilla única: métricas deportivas + parciales y a
                // continuación gráfica/Salud bajo UN solo título Entreno.
                let sport = session.liveSportID.flatMap(LiveSport.init(rawValue:))
                let extras = displayedMetrics(session)
                let hasTrackedMetrics = displayedRoute(session).count >= 2
                    || !(session.liveKilometerSplitsSeconds ?? []).isEmpty
                    || (session.liveSportID != nil && (session.recordedDistanceMeters ?? 0) > 0
                        && (session.activeDurationSeconds ?? 0) > 0)
                let hasMovement = extras?.stepsCount != nil || extras?.movementDistanceMeters != nil
                if hasTrackedMetrics || extras != nil {
                    Section {
                        VStack(alignment: .leading, spacing: 14) {
                            if hasTrackedMetrics || sport != nil || hasMovement {
                                CardioSplitsView(
                                    routePoints: displayedRoute(session),
                                    heartRate: extras?.heartRateSeries ?? [],
                                    cycling: sport?.displaysSpeed ?? (extras?.activityType == .cycling),
                                    activeKilometerSeconds: session.liveKilometerSplitsSeconds,
                                    totalActiveSeconds: session.activeDurationSeconds ?? session.durationMinutes * 60,
                                    totalDistanceMeters: session.recordedDistanceMeters,
                                    maxSpeedKmh: extras?.maxSpeedKmh,
                                    healthStats: extras,
                                    sport: sport,
                                    embedded: true
                                )
                            }
                            if let extras {
                                if hasTrackedMetrics || sport != nil || hasMovement {
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
                        Text("Entreno")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(OG.accent)
                            .textCase(nil)
                    }
                }

                if isEditing {
                    Section {
                        TextField("Nombre del entreno", text: titleBinding)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(OG.label)
                        DatePicker("Inicio", selection: startedBinding, displayedComponents: [.date, .hourAndMinute])
                            .tint(OG.accent)
                        DatePicker("Fin", selection: finishedBinding, displayedComponents: [.date, .hourAndMinute])
                            .tint(OG.accent)
                    } header: {
                        Text("Editar")
                    }

                    // Ruta de Salud: no se pinta pin manual encima.
                    if healthExtras?.showRouteMap != true {
                        Section {
                            WorkoutPlacePickerRow(pin: locationPinBinding)
                        } header: {
                            Text("Lugar")
                        }
                    }
                }

                ForEach(groupedExercises(session), id: \.id) { group in
                    Section {
                        if group.showsMovementsAsPrescription {
                            wodBlockMovementsCard(
                                session: session,
                                indices: group.indices,
                                result: group.wodResult
                            )
                            .ogCardListRow()
                        } else if isEditing {
                            if let result = group.wodResult {
                                wodResultCard(result)
                                    .ogCardListRow()
                            }
                            ForEach(group.indices, id: \.self) { exIndex in
                                if session.exercises.indices.contains(exIndex) {
                                    exerciseCard(
                                        exIndex: exIndex,
                                        exercise: session.exercises[exIndex],
                                        hideScoreArtifact: group.wodResult,
                                        highlightSessionId: session.id
                                    )
                                    .ogCardListRow()
                                }
                            }
                        } else {
                            // Resultado + ejercicios del bloque en una card, separados por línea.
                            wodBlockExercisesCard(
                                session: session,
                                indices: group.indices,
                                hideScoreArtifact: group.wodResult,
                                result: group.wodResult
                            )
                            .ogCardListRow()
                        }
                        ForEach(Array(group.historicalResults.enumerated()), id: \.offset) { _, previous in
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Resultado de formato anterior")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(OG.label2)
                                wodResultCard(previous)
                            }
                            .ogCardListRow()
                        }
                    } header: {
                        blockSectionHeader(group.header)
                    }
                }

                if isEditing || !(session.notes ?? "").isEmpty {
                    Section {
                        notesCard
                            .ogCardListRow()
                    }
                }
            }
        }
        .ogListChrome()
        .listSectionSpacing(12)
        .navigationDestination(isPresented: $showCompletedEditor) {
            if let session = draft, let preparedCompletedRoutine {
                DayEditorView(
                    routine: preparedCompletedRoutine,
                    mode: .session,
                    onClose: {
                        // Keep the prepared model during the native pop animation:
                        // clearing it immediately would replace the destination with EmptyView.
                        showCompletedEditor = false
                    },
                    onApplyCompleted: { routine, details in
                        let updated = CompletedWorkoutEditing.applying(
                            routine, to: details, catalog: store.state.exercises
                        )
                        store.saveWorkout(updated)
                        draft = store.state.workouts.first(where: { $0.id == sessionId })
                        Task {
                            await store.refineSessionReviewWithHealth(sessionId: sessionId)
                            draft = store.state.workouts.first(where: { $0.id == sessionId })
                            if let draft { healthExtras = await health.sessionHealthExtras(for: draft) }
                        }
                    },
                    completedSession: session,
                    embedsNavigationStack: false,
                    usesPageCloseHeader: true
                )
            }
        }
        .navigationDestination(item: $exerciseRoute) { route in
            ExerciseDetailView(
                exerciseId: route.exerciseId,
                highlightSessionId: route.sessionId,
                highlightExerciseInstanceId: route.exerciseInstanceId
            )
        }
        .ogScrollingTitleNav()
        .navigationBarBackButtonHidden(isEditing)
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .topBarLeading) {
                    CloseToolbarButton(action: cancelEditing, large: false)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    OGToolbarGlassButton(
                        systemName: "checkmark",
                        accessibilityLabel: "Guardar",
                        tint: OG.accent
                    ) {
                        if let draft {
                            store.saveWorkout(draft)
                            isEditing = false
                            // Fecha y hora pueden cambiar la ventana de Salud;
                            // resolver de nuevo por UUID estable sin reciclar
                            // FC/recorrido de la vista anterior.
                            Task {
                                guard let saved = store.state.workouts.first(where: { $0.id == sessionId })
                                else { return }
                                healthExtras = await health.sessionHealthExtras(for: saved)
                                self.draft = store.state.workouts.first(where: { $0.id == sessionId })
                            }
                        }
                    }
                }
            } else {
                if draft?.timerDetails == nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await toggleHistoricalFavorite() }
                    } label: {
                        Image(systemName: store.isWorkoutFavorite(sessionId) ? "star.fill" : "star")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(store.isWorkoutFavorite(sessionId) ? OG.yellow : OG.label)
                    }
                    .accessibilityLabel(store.isWorkoutFavorite(sessionId) ? "Quitar de favoritos" : "Guardar en favoritos")
                    .disabled(isSavingFavorite)
                }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if draft?.timerDetails == nil {
                        Button {
                            guard let session = draft else { return }
                            preparedCompletedRoutine = CompletedWorkoutEditing.routine(
                                from: session,
                                sourceRoutine: session.routineId.flatMap { id in
                                    store.state.routines.first(where: { $0.id == id })
                                }
                            )
                            showCompletedEditor = true
                        } label: {
                            Label("Editar", systemImage: "pencil")
                        }
                        }
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(OG.label)
                            .frame(width: 36, height: 36)
                            .contentShape(Circle())
                    }
                    .accessibilityLabel("Más opciones")
                }
            }
        }
    }

    private func cancelEditing() {
        draft = store.state.workouts.first(where: { $0.id == sessionId })
        isEditing = false
    }

    private func summaryCard(_ session: WorkoutSession) -> some View {
        if let timer = session.timerDetails {
            return AnyView(HStack(spacing: 10) {
                summaryTile(
                    title: "Tiempo",
                    value: DurationText.format(timer.configuredSeconds),
                    icon: "clock.fill", tint: OG.blue
                )
                summaryTile(
                    title: "Modalidad", value: timer.modeTitle,
                    icon: "timer", tint: OG.accent
                )
                if timer.modeRaw == "intervals" {
                    summaryTile(
                        title: "Rondas", value: "\(timer.rounds)",
                        icon: "repeat", tint: OG.orange
                    )
                }
            })
        }
        // Tres tarjetas estables: no colapsar el resultado a una sola cuando
        // Apple Salud no aporta kcal o la sesión no tiene series con peso.
        // Kcal solo si vienen de una fuente real de Salud, nunca de MET estimados.
        let actualKcal = healthExtras?.hasExternalSaludSource == true
            ? healthExtras?.activeEnergyKcal
            : nil
        let minutes: Double = {
            if session.liveSportID != nil { return session.durationMinutes }
            if let start = session.startedAt {
                let end = session.finishedAt ?? start.addingTimeInterval(60)
                let wall = max(0, end.timeIntervalSince(start) / 60)
                if wall > 0 { return wall }
            }
            return session.durationMinutes
        }()

        let route = displayedRoute(session)
        let distanceMeters: Double? = {
            if let recorded = session.recordedDistanceMeters, recorded > 0 { return recorded }
            guard route.count >= 2 else { return nil }
            let samples = route.map {
                CardioRouteAnalysis.Sample(
                    date: $0.date, latitude: $0.latitude,
                    longitude: $0.longitude, altitudeMeters: $0.altitudeMeters
                )
            }
            let meters = CardioRouteAnalysis.analyze(route: samples).distanceMeters
            return meters > 0 ? meters : nil
        }()

        return AnyView(HStack(spacing: 10) {
            summaryTile(
                title: "Tiempo",
                value: session.timerDetails.map { DurationText.format($0.configuredSeconds) }
                    ?? (minutes > 0 ? "\(Int(minutes.rounded()))′" : "—"),
                icon: "clock.fill",
                tint: OG.blue
            )
            summaryTile(
                title: "Kcal",
                value: actualKcal.flatMap { $0 > 0 ? "\(Int($0.rounded()))" : nil } ?? "—",
                icon: "flame.fill",
                tint: OG.orange
            )
            if let distanceMeters {
                summaryTile(
                    title: "Distancia",
                    value: "\(ReperaNumberFormat.decimal(distanceMeters / 1000)) km",
                    icon: "point.bottomleft.forward.to.point.topright.scurvepath",
                    tint: OG.accent
                )
            } else {
                summaryTile(
                    title: "Volumen",
                    value: session.totalVolumeKg > 0
                        ? ReperaNumberFormat.integer(Int(session.totalVolumeKg.rounded()))
                        : "—",
                    icon: "scalemass.fill",
                    tint: OG.accent
                )
            }
        })
    }

    private func summaryTile(title: String, value: String, icon: String, tint: Color) -> some View {
        WorkoutSummaryTile(title: title, value: value, icon: icon, tint: tint)
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Notas")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(OG.accent)
            if isEditing {
                TextField("Cómo te sentiste, molestias…", text: notesBinding, axis: .vertical)
                    .lineLimit(2...5)
                    .foregroundStyle(OG.label)
            } else if let notes = draft?.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 15))
                    .foregroundStyle(OG.label2)
            }
        }
        .padding(OG.pad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }

    private struct ExerciseGroup: Identifiable {
        var id: String
        var header: String
        var indices: [Int]
        var wodResult: WODBlockResult?
        var historicalResults: [WODBlockResult]
        /// AMRAP / For Time: lista de movimientos + score, no series inventadas.
        var showsMovementsAsPrescription: Bool
    }

    private func groupedExercises(_ session: WorkoutSession) -> [ExerciseGroup] {
        var order: [String] = []
        var map: [String: (sample: SessionExercise, indices: [Int])] = [:]
        for (idx, ex) in session.exercises.enumerated() {
            let key = ex.blockId?.uuidString ?? "solo-\(idx)"
            if map[key] == nil {
                order.append(key)
                map[key] = (ex, [])
            }
            map[key]?.indices.append(idx)
        }
        return order.compactMap { key in
            guard let value = map[key] else { return nil }
            let sample = value.sample
            let blockId = sample.blockId
            let savedResults = session.wodResults.filter { $0.id == blockId }
            // El score del formato vigente tiene prioridad. Otras marcas
            // del mismo bloque conservan su formato y se muestran aparte.
            let result = savedResults.last(where: { $0.format == sample.wodFormat })
                ?? savedResults.last
            let historical = savedResults.filter {
                $0.format != result?.format
            }
            let scoreCapture = sample.usesBlockScoreResult
            let header = sample.displayBlockHeader
            return ExerciseGroup(
                id: key,
                header: header,
                indices: value.indices,
                wodResult: result ?? inferredResult(for: sample, indices: value.indices, session: session),
                historicalResults: historical,
                showsMovementsAsPrescription: scoreCapture && !isEditing
            )
        }
    }

    /// Entrenos antiguos: el score AMRAP se metió como 1 serie en el 1.er movimiento.
    private func inferredResult(
        for sample: SessionExercise,
        indices: [Int],
        session: WorkoutSession
    ) -> WODBlockResult? {
        guard sample.usesBlockScoreResult else { return nil }
        guard let blockId = sample.blockId else { return nil }
        if session.wodResults.contains(where: { $0.id == blockId }) { return nil }
        switch sample.wodFormat?.resultCapture {
        case .totalReps:
            guard let firstIdx = indices.first,
                  session.exercises.indices.contains(firstIdx),
                  let only = session.exercises[firstIdx].loggedSets.first,
                  session.exercises[firstIdx].loggedSets.count == 1,
                  only.weightKg == nil
            else { return nil }
            return WODBlockResult(
                id: blockId,
                format: sample.wodFormat,
                totalReps: only.reps
            )
        case .elapsedTime:
            return nil
        default:
            return nil
        }
    }

    private func blockSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(OG.accent)
            .textCase(nil)
    }

    private func wodResultCard(_ result: WODBlockResult) -> some View {
        wodResultHeader(result)
            .padding(OG.pad)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }

    private func wodResultHeader(_ result: WODBlockResult) -> some View {
        HStack(spacing: 12) {
            Image(systemName: result.elapsedSeconds != nil ? "stopwatch.fill" : "number.circle.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(OG.accent)
                .frame(width: 40, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                Text("Resultado")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(OG.label3)
                Text(result.summaryLabel)
                    .font(.system(size: 22, weight: .bold).monospacedDigit())
                    .foregroundStyle(OG.label)
            }
            Spacer(minLength: 0)
            if let format = result.format {
                Text(format.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(OG.label2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(OG.surface2, in: Capsule())
            }
        }
        .padding(.vertical, 4)
    }

    private func detailExerciseId(for exercise: Exercise) -> UUID {
        store.historicalDisplayExercise(exercise).id
    }

    private var detailRowChevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(OG.label3)
    }

    /// AMRAP / RFT / chipper: resultado + movimientos en una card, separados por línea.
    private func wodBlockMovementsCard(
        session: WorkoutSession,
        indices: [Int],
        result: WODBlockResult?
    ) -> some View {
        let rows = indices.compactMap { idx -> (Int, SessionExercise)? in
            guard session.exercises.indices.contains(idx) else { return nil }
            return (idx, session.exercises[idx])
        }
        return VStack(alignment: .leading, spacing: 0) {
            if let result {
                wodResultHeader(result)
                    .padding(.vertical, 8)
                if !rows.isEmpty {
                    Divider().overlay(OG.surface3).padding(.leading, 52)
                }
            }
            ForEach(Array(rows.enumerated()), id: \.element.0) { offset, pair in
                let exercise = pair.1
                let display = store.historicalDisplayExercise(exercise.exercise)
                if offset > 0 {
                    Divider().overlay(OG.surface3).padding(.leading, 52)
                }
                Button {
                    openExerciseDetail(exercise, sessionId: session.id)
                } label: {
                    HStack(spacing: 12) {
                        ExerciseThumb(exercise: display, size: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(SportExerciseNames.localizedDisplayName(display.name))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(OG.label)
                                .lineLimit(2)
                            Text(exercise.prescriptionSummaryLine)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(OG.label2)
                            if let adapted = exercise.adjustedSummaryLine {
                                Text(adapted)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(OG.accent)
                            }
                        }
                        Spacer(minLength: 0)
                        detailRowChevron
                    }
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Ver ficha del ejercicio")
            }
        }
        .padding(.horizontal, OG.pad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }

    /// EMOM / series: resultado (si hay) + ejercicios del bloque en una card.
    private func wodBlockExercisesCard(
        session: WorkoutSession,
        indices: [Int],
        hideScoreArtifact: WODBlockResult?,
        result: WODBlockResult?
    ) -> some View {
        let rows = indices.compactMap { idx -> (Int, SessionExercise)? in
            guard session.exercises.indices.contains(idx) else { return nil }
            return (idx, session.exercises[idx])
        }
        return VStack(alignment: .leading, spacing: 0) {
            if let result {
                wodResultHeader(result)
                    .padding(.vertical, 8)
                if !rows.isEmpty {
                    Divider().overlay(OG.surface3).padding(.leading, 52)
                }
            }
            ForEach(Array(rows.enumerated()), id: \.element.0) { offset, pair in
                let exIndex = pair.0
                let exercise = pair.1
                if offset > 0 {
                    Divider().overlay(OG.surface3).padding(.leading, 60)
                }
                exerciseBlockContent(
                    exIndex: exIndex,
                    exercise: exercise,
                    hideScoreArtifact: hideScoreArtifact,
                    highlightSessionId: session.id,
                    showsOuterPadding: false
                )
                .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, OG.pad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }

    private func openExerciseDetail(_ exercise: SessionExercise, sessionId: UUID) {
        exerciseRoute = DetailExerciseRoute(
            exerciseId: detailExerciseId(for: exercise.exercise),
            sessionId: sessionId,
            exerciseInstanceId: exercise.id
        )
    }

    private func exerciseCard(
        exIndex: Int,
        exercise: SessionExercise,
        hideScoreArtifact: WODBlockResult? = nil,
        highlightSessionId: UUID? = nil
    ) -> some View {
        exerciseBlockContent(
            exIndex: exIndex,
            exercise: exercise,
            hideScoreArtifact: hideScoreArtifact,
            highlightSessionId: highlightSessionId,
            showsOuterPadding: true
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }

    private func exerciseBlockContent(
        exIndex: Int,
        exercise: SessionExercise,
        hideScoreArtifact: WODBlockResult?,
        highlightSessionId: UUID?,
        showsOuterPadding: Bool
    ) -> some View {
        let visibleSets = visibleLoggedSets(for: exercise, hideScoreArtifact: hideScoreArtifact)
        let catalogExercise = store.historicalDisplayExercise(exercise.exercise)
        return VStack(alignment: .leading, spacing: 12) {
            Button {
                if let highlightSessionId {
                    openExerciseDetail(exercise, sessionId: highlightSessionId)
                } else if let session = draft {
                    openExerciseDetail(exercise, sessionId: session.id)
                }
            } label: {
                HStack(spacing: 12) {
                    ExerciseThumb(exercise: catalogExercise, size: 48)
                    Text(SportExerciseNames.localizedDisplayName(catalogExercise.name))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(OG.label)
                        .lineLimit(2)
                    Spacer(minLength: 0)
                    detailRowChevron
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Ver ficha del ejercicio")

            if visibleSets.isEmpty {
                if !isEditing && !exercise.plannedSets.isEmpty {
                    // Sesión finalizada sin registros individuales: mostrar TODAS
                    // las series programadas como ejecutadas, no solo la primera.
                    ForEach(Array(exercise.plannedSets.enumerated()), id: \.element.id) { index, planned in
                        HStack(spacing: 14) {
                            Text("S\(index + 1)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(OG.label2)
                                .frame(width: 34, alignment: .leading)
                            Text(plannedSetSummary(planned, exercise: exercise))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(OG.label)
                        }
                        .padding(.leading, 60)
                    }
                } else {
                    Text(isEditing ? "Sin series registradas" : "Sin resultado registrado")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(OG.label)
                        .padding(.leading, 60)
                }
            } else {
                if isEditing {
                    editSetColumnHeaders(
                        exercise: catalogExercise,
                        showsRemove: exercise.loggedSets.count > 1
                    )
                }
                ForEach(Array(visibleSets.enumerated()), id: \.element.id) { setIndex, set in
                    if isEditing {
                        if let realIndex = exercise.loggedSets.firstIndex(where: { $0.id == set.id }) {
                            editableSetRow(
                                exIndex: exIndex,
                                setIndex: realIndex,
                                set: set,
                                exercise: catalogExercise
                            )
                        }
                    } else {
                        readOnlySetRow(setIndex: setIndex, set: set)
                            .padding(.leading, 60) // Alinear S1/S2 y valores con el título, no con la miniatura
                    }
                }
            }
        }
        .padding(showsOuterPadding ? OG.pad : 0)
    }

    private func plannedSetSummary(_ planned: PlannedSet, exercise: SessionExercise) -> String {
        let unit = exercise.quantityUnit ?? exercise.exercise.defaultQuantityUnit
        if unit != .reps {
            let kg = planned.targetWeightKg.map { " · \(ReperaNumberFormat.decimal($0)) kg" } ?? ""
            return "\(planned.targetReps) \(unit.shortLabel)\(kg)"
        }
        if let kg = planned.targetWeightKg, kg > 0 {
            return "\(planned.targetReps) @ \(ReperaNumberFormat.decimal(kg)) kg"
        }
        return "\(planned.targetReps) reps"
    }

    private func editSetColumnHeaders(exercise: Exercise, showsRemove: Bool) -> some View {
        let style = exercise.loggingStyle
        let qty = exercise.supportsRepsOrMeters ? "Reps / m" : exercise.quantityFieldLabel
        return HStack(spacing: 8) {
            Color.clear.frame(width: 28)
            switch style {
            case .loadAndReps:
                editColumnHeader(
                    Exercise.loadStepperTitle(
                        name: exercise.name,
                        equipment: exercise.equipment,
                        targetMuscle: exercise.targetMuscle,
                        muscleGroup: exercise.muscleGroup
                    ),
                    flexible: true
                )
                editColumnHeader(qty, width: 110)
            case .repsAndTime:
                editColumnHeader(qty, flexible: true)
                editColumnHeader("Tiempo", flexible: true)
            case .machineWork:
                editColumnHeader("Tiempo", flexible: true)
                editColumnHeader(qty, flexible: true)
            case .repsOnly:
                editColumnHeader(qty, flexible: true)
            }
            if style.usesRIR {
                editColumnHeader("RIR", width: 56)
            }
            if showsRemove {
                Color.clear.frame(width: 28)
            }
        }
    }

    @ViewBuilder
    private func editColumnHeader(_ title: String, flexible: Bool = false, width: CGFloat? = nil) -> some View {
        let label = Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(OG.label3)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .multilineTextAlignment(.center)
            .textCase(nil)
        if flexible {
            label.frame(maxWidth: .infinity, alignment: .center)
        } else if let width {
            label.frame(width: width, alignment: .center)
        } else {
            label
        }
    }

    private func visibleLoggedSets(
        for exercise: SessionExercise,
        hideScoreArtifact: WODBlockResult?
    ) -> [LoggedSet] {
        // Las series efectivamente guardadas siempre deben mostrarse en el
        // detalle. Antes se ocultaba una serie si sus reps coincidían con el
        // score del bloque; esa coincidencia también ocurre con series reales.
        // El resultado agregado se presenta por separado en la cabecera.
        return exercise.loggedSets
    }

    private func readOnlySetRow(setIndex: Int, set: LoggedSet) -> some View {
        OGExerciseSetRow(
            index: setIndex,
            summaryLine: set.displaySummaryLine,
            rir: set.rir,
            showsRIR: !set.isMachineQuantity || set.weightKg != nil
        )
    }

    private func editableSetRow(
        exIndex: Int,
        setIndex: Int,
        set: LoggedSet,
        exercise: Exercise
    ) -> some View {
        let style = exercise.loggingStyle
        let loadField = exercise.loadField
        let unit = set.quantityUnit ?? exercise.defaultQuantityUnit
        let maxReps = exercise.supportsRepsOrMeters && unit == .meters
            ? 100_000 : style.quantityCap
        let qtyStep: Int = {
            if style == .machineWork, unit == .meters {
                return 50
            }
            if style == .repsAndTime { return 5 }
            return 1
        }()
        return VStack(alignment: .leading, spacing: 8) {
            if exercise.supportsRepsOrMeters {
                Picker("Unidad de la serie", selection: Binding(
                    get: { unit },
                    set: { selected in
                        // Solo al editar explícitamente: no convertir ni
                        // reetiquetar registros históricos automáticamente.
                        mutateSet(exIndex: exIndex, setIndex: setIndex) {
                            $0.quantityUnit = selected
                        }
                    }
                )) {
                    Text("Repeticiones").tag(ExerciseQuantityUnit.reps)
                    Text("Metros").tag(ExerciseQuantityUnit.meters)
                }
                .pickerStyle(.segmented)
            }
            HStack(spacing: 8) {
            Text("S\(setIndex + 1)")
                .font(.system(size: 12, weight: .bold).monospacedDigit())
                .foregroundStyle(OG.label3)
                .frame(width: 28, alignment: .leading)

            switch style {
            case .loadAndReps:
                if loadField == .deficitCm {
                    OGRepeatStepper(
                        display: set.deficitCm.map(String.init) ?? "0",
                        keyboard: .numberPad,
                        onMinus: {
                            mutateSet(exIndex: exIndex, setIndex: setIndex) {
                                $0.deficitCm = max(0, ($0.deficitCm ?? 0) - 1)
                            }
                        },
                        onPlus: {
                            mutateSet(exIndex: exIndex, setIndex: setIndex) {
                                $0.deficitCm = min(60, ($0.deficitCm ?? 0) + 1)
                            }
                        },
                        onCommitText: { text in
                            mutateSet(exIndex: exIndex, setIndex: setIndex) { row in
                                if let parsed = Int(text.filter(\.isNumber)) {
                                    row.deficitCm = min(60, max(0, parsed))
                                }
                            }
                        }
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    OGRepeatStepper(
                        display: set.weightKg.map { ReperaNumberFormat.decimal($0) } ?? "—",
                        keyboard: .decimalPad,
                        onMinus: {
                            mutateSet(exIndex: exIndex, setIndex: setIndex) { row in
                                let current = row.weightKg ?? 0
                                let next = max(0, ((current - weightStep) * 10).rounded() / 10)
                                row.weightKg = next > 0 ? next : nil
                            }
                        },
                        onPlus: {
                            mutateSet(exIndex: exIndex, setIndex: setIndex) { row in
                                let current = row.weightKg ?? 0
                                row.weightKg = ((current + weightStep) * 10).rounded() / 10
                            }
                        },
                        onCommitText: { text in
                            mutateSet(exIndex: exIndex, setIndex: setIndex) { row in
                                let normalized = text
                                if normalized.isEmpty {
                                    row.weightKg = nil
                                } else if let parsed = ReperaNumberFormat.parse(normalized) {
                                    row.weightKg = parsed > 0 ? ((parsed * 10).rounded() / 10) : nil
                                }
                            }
                        }
                    )
                    .frame(maxWidth: .infinity)
                }

                OGRepeatStepper(
                    display: "\(set.reps)",
                    keyboard: .numberPad,
                    onMinus: {
                        mutateSet(exIndex: exIndex, setIndex: setIndex) {
                            $0.reps = max(0, $0.reps - qtyStep)
                        }
                    },
                    onPlus: {
                        mutateSet(exIndex: exIndex, setIndex: setIndex) {
                            $0.reps = min(maxReps, $0.reps + qtyStep)
                        }
                    },
                    onCommitText: { text in
                        mutateSet(exIndex: exIndex, setIndex: setIndex) { row in
                            if let parsed = Int(text) {
                                row.reps = min(maxReps, max(0, parsed))
                            }
                        }
                    }
                )
                .frame(width: 110)

            case .repsAndTime:
                OGRepeatStepper(
                    display: "\(set.reps)",
                    keyboard: .numberPad,
                    onMinus: {
                        mutateSet(exIndex: exIndex, setIndex: setIndex) {
                            $0.reps = max(0, $0.reps - qtyStep)
                        }
                    },
                    onPlus: {
                        mutateSet(exIndex: exIndex, setIndex: setIndex) {
                            $0.reps = min(maxReps, $0.reps + qtyStep)
                        }
                    },
                    onCommitText: { text in
                        mutateSet(exIndex: exIndex, setIndex: setIndex) { row in
                            if let parsed = Int(text) {
                                row.reps = min(maxReps, max(0, parsed))
                            }
                        }
                    }
                )
                .frame(maxWidth: .infinity)

                editableDurationStepper(exIndex: exIndex, setIndex: setIndex, set: set)
                    .frame(maxWidth: .infinity)

            case .machineWork:
                editableDurationStepper(exIndex: exIndex, setIndex: setIndex, set: set)
                    .frame(maxWidth: .infinity)

                OGRepeatStepper(
                    display: "\(set.reps)",
                    keyboard: .numberPad,
                    onMinus: {
                        mutateSet(exIndex: exIndex, setIndex: setIndex) {
                            $0.reps = max(0, $0.reps - qtyStep)
                        }
                    },
                    onPlus: {
                        mutateSet(exIndex: exIndex, setIndex: setIndex) {
                            $0.reps = min(maxReps, $0.reps + qtyStep)
                        }
                    },
                    onCommitText: { text in
                        mutateSet(exIndex: exIndex, setIndex: setIndex) { row in
                            if let parsed = Int(text) {
                                row.reps = min(maxReps, max(0, parsed))
                            }
                        }
                    }
                )
                .frame(maxWidth: .infinity)

            case .repsOnly:
                OGRepeatStepper(
                    display: "\(set.reps)",
                    keyboard: .numberPad,
                    onMinus: {
                        mutateSet(exIndex: exIndex, setIndex: setIndex) {
                            $0.reps = max(0, $0.reps - 1)
                        }
                    },
                    onPlus: {
                        mutateSet(exIndex: exIndex, setIndex: setIndex) {
                            $0.reps = min(maxReps, $0.reps + 1)
                        }
                    },
                    onCommitText: { text in
                        mutateSet(exIndex: exIndex, setIndex: setIndex) { row in
                            if let parsed = Int(text) {
                                row.reps = min(maxReps, max(0, parsed))
                            }
                        }
                    }
                )
                .frame(maxWidth: .infinity)
            }

            if style.usesRIR {
                Menu {
                    Button("Sin RIR") {
                        mutateSet(exIndex: exIndex, setIndex: setIndex) { $0.rir = nil }
                    }
                    ForEach(0...5, id: \.self) { rir in
                        Button("\(rir)") {
                            mutateSet(exIndex: exIndex, setIndex: setIndex) {
                                $0.rir = Double(rir)
                            }
                        }
                    }
                } label: {
                    Text(set.rir.map { "\(Int($0.rounded()))" } ?? "RIR")
                        .font(.system(size: 15, weight: .semibold).monospacedDigit())
                        .foregroundStyle(set.rir == nil ? OG.label3 : OG.label)
                        .frame(width: 56, height: 48)
                        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            if exerciseSetCount(exIndex) > 1 {
                Button {
                    removeSet(exIndex: exIndex, setIndex: setIndex)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(OG.label)
                }
                .buttonStyle(.plain)
                .frame(width: 28)
            }
            }
        }
    }

    private func editableDurationStepper(exIndex: Int, setIndex: Int, set: LoggedSet) -> some View {
        let seconds = set.durationSeconds ?? 0
        let display: String = {
            let m = seconds / 60
            let s = seconds % 60
            return s == 0 ? "\(m):00" : String(format: "%d:%02d", m, s)
        }()
        return OGRepeatStepper(
            display: display,
            keyboard: .numbersAndPunctuation,
            onMinus: {
                mutateSet(exIndex: exIndex, setIndex: setIndex) {
                    $0.durationSeconds = max(0, ($0.durationSeconds ?? 0) - 15)
                }
            },
            onPlus: {
                mutateSet(exIndex: exIndex, setIndex: setIndex) {
                    $0.durationSeconds = min(3600, ($0.durationSeconds ?? 0) + 15)
                }
            },
            onCommitText: { text in
                mutateSet(exIndex: exIndex, setIndex: setIndex) { row in
                    row.durationSeconds = parseDurationText(text)
                }
            }
        )
    }

    private func parseDurationText(_ text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        if trimmed.contains(":") {
            let parts = trimmed.split(separator: ":")
            guard parts.count == 2,
                  let m = Int(parts[0]),
                  let s = Int(parts[1]) else { return nil }
            return max(0, m * 60 + s)
        }
        if let sec = Int(trimmed.filter(\.isNumber)) {
            return max(0, sec)
        }
        return nil
    }

    private func exerciseSetCount(_ exIndex: Int) -> Int {
        guard let draft, draft.exercises.indices.contains(exIndex) else { return 0 }
        return draft.exercises[exIndex].loggedSets.count
    }

    private func mutateSet(exIndex: Int, setIndex: Int, _ body: (inout LoggedSet) -> Void) {
        guard var next = draft,
              next.exercises.indices.contains(exIndex),
              next.exercises[exIndex].loggedSets.indices.contains(setIndex)
        else { return }
        body(&next.exercises[exIndex].loggedSets[setIndex])
        draft = next
    }

    private func removeSet(exIndex: Int, setIndex: Int) {
        guard var next = draft,
              next.exercises.indices.contains(exIndex),
              next.exercises[exIndex].loggedSets.indices.contains(setIndex),
              next.exercises[exIndex].loggedSets.count > 1
        else { return }
        next.exercises[exIndex].loggedSets.remove(at: setIndex)
        draft = next
    }

    private var titleBinding: Binding<String> {
        Binding(
            get: { draft?.title ?? "" },
            set: { draft?.title = $0 }
        )
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { draft?.notes ?? "" },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                draft?.notes = trimmed.isEmpty ? nil : trimmed
            }
        )
    }

    private var startedBinding: Binding<Date> {
        Binding(
            get: { draft?.startedAt ?? Date() },
            set: { draft?.startedAt = $0 }
        )
    }

    private var finishedBinding: Binding<Date> {
        Binding(
            get: { draft?.finishedAt ?? Date() },
            set: { draft?.finishedAt = $0 }
        )
    }

    private var locationPinBinding: Binding<WorkoutLocationPin?> {
        Binding(
            get: { draft?.locationPin },
            set: { draft?.locationPin = $0 }
        )
    }
}

extension HealthKitStore.ExternalActivityDetail {
    var asSessionExtras: HealthKitStore.SessionHealthExtras {
        HealthKitStore.SessionHealthExtras(
            averageHeartRateBpm: averageHeartRateBpm,
            maxHeartRateBpm: maxHeartRateBpm,
            minHeartRateBpm: minHeartRateBpm,
            heartRateSeries: heartRateSeries,
            routePoints: routePoints,
            averageSpeedKmh: averageSpeedKmh,
            maxSpeedKmh: maxSpeedKmh,
            stepsCount: stepsCount,
            movementDistanceMeters: movementDistanceMeters,
            movementDistanceLabel: movementDistanceLabel,
            movementUsesTimeWindow: movementUsesTimeWindow,
            activeEnergyKcal: activity.activeEnergyKcal,
            sourceName: activity.sourceName,
            activityTypeRaw: activity.activityTypeRaw,
            resolvedWorkoutUUID: activity.id
        )
    }
}

/// Panel visual de métricas de Salud (FC, velocidad) reutilizable en Entreno propio y Salud.
struct HealthSessionMetricsCard: View {
    var extras: HealthKitStore.SessionHealthExtras
    var headline: String? = nil
    var symbolName: String? = nil
    var headlineSubtitle: String? = nil
    /// Si false, dispositivo/kcal van en otro bloque (ficha Salud).
    var includeSourceRows: Bool = true
    var embedded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let headline {
                HStack(spacing: 10) {
                    if let symbolName {
                        Image(systemName: symbolName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(OG.red)
                            .frame(width: 36, height: 36)
                            .background(OG.red.opacity(0.18), in: Circle())
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(headline)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(OG.label)
                        if let headlineSubtitle {
                            Text(headlineSubtitle)
                                .font(.system(size: 13))
                                .foregroundStyle(OG.label2)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }

            if extras.routePoints.count >= 2 {
                // Tiles de FC/velocidad o altitud viven dentro del selector Cardio/Altitud.
                CardioAltitudeChart(extras: extras)
            } else if !extras.heartRateSeries.isEmpty {
                HealthHeartRateChart(series: extras.heartRateSeries, stats: extras)
                if extras.minHeartRateBpm != nil || extras.maxHeartRateBpm != nil {
                    HealthHeartRateStatRow(stats: extras)
                }
            } else if let average = extras.averageHeartRateBpm {
                Label("Ritmo cardíaco · media \(Int(average.rounded())) lpm", systemImage: "heart.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(OG.red)
                if extras.minHeartRateBpm != nil || extras.maxHeartRateBpm != nil {
                    HealthHeartRateStatRow(stats: extras)
                }
            } else if extras.minHeartRateBpm != nil || extras.maxHeartRateBpm != nil {
                HealthHeartRateStatRow(stats: extras)
            }

            if includeSourceRows, extras.sourceName != nil || extras.activeEnergyKcal != nil {
                originRows
            }
        }
        .padding(embedded ? 0 : OG.pad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if !embedded {
                RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous)
                    .fill(OG.surface)
            }
        }
    }

    private var originRows: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let kcal = extras.activeEnergyKcal, kcal > 0 {
                metricLine(icon: "flame.fill", tint: OG.orange, title: "Energía activa", value: "\(Int(kcal.rounded())) kcal")
            }
            if let source = extras.sourceName, !source.isEmpty {
                if extras.activeEnergyKcal != nil {
                    Divider().overlay(OG.surface3).padding(.leading, 40)
                }
                metricLine(icon: "applewatch", tint: OG.blue, title: "Dispositivo", value: source)
            }
        }
    }

    private func metricLine(icon: String, tint: Color, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 28)
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(OG.label2)
            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(OG.label)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 8)
    }
}

private struct HealthHeartRateChart: View {
    var series: [HealthKitStore.HeartRatePoint]
    var stats: HealthKitStore.SessionHealthExtras

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Ritmo cardíaco", systemImage: "heart.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(OG.red)
                Spacer()
                if let avg = stats.averageHeartRateBpm {
                    Text("media \(Int(avg.rounded()))")
                        .font(.system(size: 12, weight: .semibold).monospacedDigit())
                        .foregroundStyle(OG.label2)
                }
            }

            Chart(series) { point in
                AreaMark(
                    x: .value("Tiempo", point.date),
                    y: .value("lpm", point.bpm)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [OG.red.opacity(0.35), OG.red.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Tiempo", point.date),
                    y: .value("lpm", point.bpm)
                )
                .foregroundStyle(OG.red)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(OG.surface3)
                    AxisValueLabel(format: .dateTime.hour().minute())
                        .foregroundStyle(OG.label3)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(OG.surface3)
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(Int(v))")
                                .foregroundStyle(OG.label3)
                        }
                    }
                }
            }
            .frame(height: 170)

        }
    }
}

private struct HealthHeartRateStatRow: View {
    var stats: HealthKitStore.SessionHealthExtras

    var body: some View {
        HStack(spacing: 7) {
            if stats.minHeartRateBpm != nil {
                stat("Mín", value: stats.minHeartRateBpm.map { "\(Int($0.rounded()))" }, unit: "lpm", tint: OG.label2)
            }
            if stats.maxHeartRateBpm != nil {
                stat("Máx", value: stats.maxHeartRateBpm.map { "\(Int($0.rounded()))" }, unit: "lpm", tint: OG.red)
            }
        }
    }

    private func stat(_ title: String, value: String?, unit: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(OG.label3)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(value ?? "—")
                .font(.system(size: 17, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(tint)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(unit).font(.system(size: 10)).foregroundStyle(OG.label3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(OG.surface2.opacity(0.85),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

/// Superficie de toque independiente de MapKit. El mapa de vista previa
/// permanece inmóvil, pero el botón transparente ocupa TODO su rectángulo.
struct WorkoutMapTapTarget<MapPreview: View>: View {
    var accessibilityLabel: String
    var action: () -> Void
    @ViewBuilder var map: () -> MapPreview

    var body: some View {
        map()
            .allowsHitTesting(false)
            .overlay {
                Button(action: action) {
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityLabel)
                .accessibilityAddTraits(.isButton)
            }
    }
}

/// Único destino de mapa para entrenamiento, Comenzar y actividades de Salud.
/// Comparte los controles y la apariencia; recibe ruta real o ubicación.
struct WorkoutMapZoomDestination: View {
    @Environment(\.colorScheme) private var colorScheme
    var points: [HealthKitStore.RoutePoint]
    var pin: WorkoutLocationPin? = nil
    var isWaterSport: Bool = false
    var paceMode: AdaptiveRoutePace.Mode = .walking
    var referenceRoutePoints: [WorkoutRoutePoint] = []
    /// Solo los recorridos ya guardados muestran su escala de color.
    var showsSpeedLegend: Bool = false
    var onClose: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let pin {
                    WorkoutLocationPinMap(pin: pin, isInteractive: true)
                } else {
                    HealthWorkoutRouteMap(
                        points: points, isInteractive: true,
                        isWaterSport: isWaterSport, paceMode: paceMode,
                        referenceRoutePoints: referenceRoutePoints,
                        showsSpeedLegend: showsSpeedLegend
                    )
                }
            }
            .ignoresSafeArea()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
                    .glassEffect(.regular, in: .circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cerrar mapa")
            .padding(.trailing, 16)
            .padding(.top, 10)
        }
        .toolbar(.hidden, for: .navigationBar)
        .background(OG.bg)
    }
}

/// Ficha de un entreno importado de Apple Salud (mismo lenguaje visual que Entreno).
struct HealthActivityDetailView: View {
    @Environment(HealthKitStore.self) private var health
    @Namespace private var routeZoomNamespace

    var activityId: UUID

    @State private var detail: HealthKitStore.ExternalActivityDetail?
    @State private var showFullScreenRoute = false

    private var subtitle: String {
        guard let activity = detail?.activity else { return "" }
        return SpanishDate.sessionSubtitle(start: activity.start, end: activity.end)
    }

    var body: some View {
        Group {
            if let detail {
                detailList(detail)
            } else {
                ProgressView()
                    .tint(OG.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(OG.bg)
        .task {
            detail = await health.activityDetail(for: activityId)
        }
        .navigationDestination(isPresented: $showFullScreenRoute) {
            WorkoutMapZoomDestination(
                points: detail?.routePoints ?? [],
                paceMode: detail.map { AdaptiveRoutePace.Mode.forHealth($0.activity.activityType) } ?? .walking,
                showsSpeedLegend: true,
                onClose: { showFullScreenRoute = false }
            )
            .navigationTransition(.zoom(sourceID: activityId, in: routeZoomNamespace))
        }
    }

    private func detailList(_ detail: HealthKitStore.ExternalActivityDetail) -> some View {
        let activity = detail.activity
        let showRouteMap = detail.routePoints.count >= 2

        return List {
            OGScrollablePageTitle(activity.title).ogScrollingTitleListRow()
            Section {
                summaryRow(activity, detail: detail)
                    .ogCardListRow(top: 0, bottom: 2)
            } header: {
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(OG.label2)
                        .textCase(nil)
                        .padding(.leading, 2)
                }
            }

            if showRouteMap {
                Section {
                    let first = detail.routePoints.first
                    SessionMapWeatherCard(
                        latitude: first?.latitude,
                        longitude: first?.longitude,
                        workoutDate: activity.start
                    ) {
                        WorkoutMapTapTarget(accessibilityLabel: "Ampliar recorrido") {
                            showFullScreenRoute = true
                        } map: {
                            HealthWorkoutRouteMap(
                                points: detail.routePoints,
                                isInteractive: false,
                                paceMode: .forHealth(activity.activityType),
                                showsSpeedLegend: true
                            )
                            .matchedTransitionSource(id: activityId, in: routeZoomNamespace)
                        }
                    }
                    .ogCardListRow()
                }
            }

            // Igual que las sesiones Repera: deportes, parciales y Salud en
            // una sola tarjeta y bajo una sola cabecera.
            Section {
                VStack(alignment: .leading, spacing: 14) {
                    CardioSplitsView(
                        routePoints: detail.routePoints,
                        heartRate: detail.heartRateSeries,
                        cycling: activity.activityType == .cycling,
                        totalActiveSeconds: activity.durationMinutes * 60,
                        totalDistanceMeters: activity.distanceMeters,
                        maxSpeedKmh: detail.maxSpeedKmh,
                        healthStats: detail.asSessionExtras,
                        embedded: true
                    )
                    Divider().opacity(0.35)
                    HealthSessionMetricsCard(
                        extras: detail.asSessionExtras,
                        includeSourceRows: false,
                        embedded: true
                    )
                }
                .padding(OG.pad)
                .background(OG.surface, in: RoundedRectangle(
                    cornerRadius: OG.radiusCard, style: .continuous
                ))
                .ogCardListRow()
            } header: {
                sectionHeader("Entreno")
            }

            Section {
                originCard(activity)
                    .ogCardListRow()
            } header: {
                sectionHeader("Origen")
            }
        }
        .ogListChrome()
        .listSectionSpacing(12)
        .ogScrollingTitleNav()
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(OG.accent)
            .textCase(nil)
    }

    private func summaryRow(
        _ activity: HealthKitStore.ExternalActivity,
        detail: HealthKitStore.ExternalActivityDetail
    ) -> some View {
        HStack(spacing: 10) {
            summaryTile(
                title: "Tiempo",
                value: activity.durationMinutes > 0
                    ? "\(Int(activity.durationMinutes.rounded()))′"
                    : "—",
                icon: "clock.fill",
                tint: OG.blue
            )
            summaryTile(
                title: "Kcal",
                value: activity.activeEnergyKcal.map { "\(Int($0.rounded()))" } ?? "—",
                icon: "flame.fill",
                tint: OG.orange
            )
            if let distance = activity.distanceMeters, distance > 0 {
                summaryTile(
                    title: "Distancia",
                    value: distanceLabel(distance),
                    icon: "point.bottomleft.forward.to.point.topright.scurvepath",
                    tint: OG.accent
                )
            }
        }
    }

    private func summaryTile(title: String, value: String, icon: String, tint: Color) -> some View {
        WorkoutSummaryTile(title: title, value: value, icon: icon, tint: tint)
    }

    private func originCard(_ activity: HealthKitStore.ExternalActivity) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            originRow(icon: "heart.fill", tint: OG.red, title: "Origen", value: "Salud")
            if let source = activity.sourceName, !source.isEmpty {
                Divider().overlay(OG.surface3).padding(.leading, 52)
                originRow(icon: "applewatch", tint: OG.blue, title: "Dispositivo", value: source)
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }

    private func originRow(icon: String, tint: Color, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(OG.label2)
            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(OG.label)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, OG.pad)
        .padding(.vertical, 12)
    }

    private func distanceLabel(_ meters: Double) -> String {
        if meters >= 1000 {
            return "\(ReperaNumberFormat.decimal(meters / 1000)) km"
        }
        return "\(Int(meters.rounded())) m"
    }

    private func distanceFullLabel(_ meters: Double) -> String {
        if meters >= 1000 {
            return "\(ReperaNumberFormat.decimal(meters / 1000)) km"
        }
        return "\(Int(meters.rounded())) m"
    }
}

// MARK: - Pin de ubicación

struct WorkoutLocationPinMap: View {
    var pin: WorkoutLocationPin
    /// En detalle normal el mapa no se mueve; al editar/abrir sheet sí.
    var isInteractive: Bool = true

    @State private var mapItem: MKMapItem?
    @State private var cameraPosition: MapCameraPosition = .automatic

    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
    }

    private var fallbackItem: MKMapItem {
        let item = MKMapItem(
            location: CLLocation(latitude: pin.latitude, longitude: pin.longitude),
            address: nil
        )
        item.name = pin.name ?? "Lugar del entreno"
        return item
    }

    private var modes: MapInteractionModes {
        isInteractive ? [.pan, .zoom] : []
    }

    var body: some View {
        Map(position: $cameraPosition, interactionModes: modes) {
            Marker(item: mapItem ?? fallbackItem)
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .all, showsTraffic: false))
        .mapControls {
            if isInteractive {
                MapCompass()
                MapScaleView()
            }
        }
        .allowsHitTesting(isInteractive)
        .task(id: pin.mapItemIdentifier ?? "\(pin.latitude),\(pin.longitude)") {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                )
            )
            mapItem = await resolveMapItem(for: pin) ?? fallbackItem
        }
    }

    private func resolveMapItem(for pin: WorkoutLocationPin) async -> MKMapItem? {
        guard let raw = pin.mapItemIdentifier,
              let identifier = MKMapItem.Identifier(rawValue: raw)
        else { return nil }
        do {
            return try await MKMapItemRequest(mapItemIdentifier: identifier).mapItem
        } catch {
            return nil
        }
    }
}

private extension WorkoutRoutePoint {
    var asHealthRoutePoint: HealthKitStore.RoutePoint {
        HealthKitStore.RoutePoint(
            id: id,
            latitude: latitude,
            longitude: longitude,
            date: recordedAt,
            speedMps: speedMps,
            altitudeMeters: altitudeMeters,
            isEstimated: isEstimated == true
        )
    }
}

// MARK: - Mapa de recorrido (colores = velocidad)

struct HealthWorkoutRouteMap: View {
    var points: [HealthKitStore.RoutePoint]
    var isInteractive: Bool = true
    var isWaterSport: Bool = false
    var paceMode: AdaptiveRoutePace.Mode = .walking
    /// Trazado GPX cargado por el usuario, solo para reparar huecos de pantalla.
    var referenceRoutePoints: [WorkoutRoutePoint] = []
    var showsSpeedLegend: Bool = false

    // MapKit overlays are expensive: cache the route geometry between SwiftUI
    // updates (including continuous GPS changes from another active session).
    @State private var cachedRuns: [SpeedRun] = []
    @State private var cachedScale: AdaptiveRoutePace.Scale?
    private var routeCacheKey: String {
        "\(points.count)-\(points.first?.date.timeIntervalSince1970 ?? 0)-\(points.last?.date.timeIntervalSince1970 ?? 0)-\(points.isEmpty ? 0 : points[points.count / 2].date.timeIntervalSince1970)-\(referenceRoutePoints.count)-\(referenceRoutePoints.first?.latitude ?? 0)-\(referenceRoutePoints.last?.longitude ?? 0)-\(isWaterSport)-\(String(describing: paceMode))"
    }

    /// Mantiene el trazado GPS original; los enlaces de una interrupción
    /// solo existen en la capa de presentación, nunca en Salud o en los datos.
    private var routeStyle: (runs: [SpeedRun], scale: AdaptiveRoutePace.Scale?) {
        guard points.count >= 2 else { return ([], nil) }
        var legs: [SpeedLeg?] = []
        legs.reserveCapacity(points.count - 1)

        for index in 0..<(points.count - 1) {
            let first = points[index], last = points[index + 1]
            guard Self.valid(first.latitude, first.longitude),
                  Self.valid(last.latitude, last.longitude) else {
                legs.append(nil)
                continue
            }
            let start = CLLocationCoordinate2D(latitude: first.latitude, longitude: first.longitude)
            let end = CLLocationCoordinate2D(latitude: last.latitude, longitude: last.longitude)
            let meters = CLLocation(latitude: start.latitude, longitude: start.longitude)
                .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))
            let seconds = last.date.timeIntervalSince(first.date)
            guard meters.isFinite, seconds.isFinite, seconds > 0 else {
                legs.append(nil)
                continue
            }
            // Puntos casi inmóviles no cortan la ruta ni crean falsos segmentos.
            // Conservar puntos casi inmóviles: descartarlos abría huecos en el dibujo
            // aunque pertenecieran al mismo recorrido real.
            if meters < 0.5 {
                legs.append(SpeedLeg(
                    index: index, start: start, end: end, distance: meters,
                    speed: max(0.2, min(25, last.speedMps ?? first.speedMps ?? 0.2)),
                    isEstimated: first.isEstimated || last.isEstimated
                ))
                continue
            }
            let speedFromGPS = meters / seconds
            if seconds <= 45, speedFromGPS.isFinite, speedFromGPS <= 25 {
                let measured = last.speedMps ?? first.speedMps
                let speed = (measured?.isFinite == true
                             && (0.2...25).contains(measured ?? 0))
                    ? (measured ?? speedFromGPS) : speedFromGPS
                legs.append(SpeedLeg(
                    index: index, start: start, end: end,
                    distance: meters, speed: max(0.2, speed),
                    isEstimated: first.isEstimated || last.isEstimated
                ))
                continue
            }
            // Un salto temporal no es una segunda actividad. Si es compatible
            // con el tiempo y las posiciones, usar el GPX cargado como guía.
            // Si no hay GPX, solo enlazar huecos cortos y plausibles.
            if let bridge = visualBridge(
                from: first, to: last, index: index, seconds: seconds, directMeters: meters
            ) {
                legs.append(contentsOf: bridge.map { Optional($0) })
            } else {
                legs.append(nil)
            }
        }

        let scale = AdaptiveRoutePace.scale(samples: legs.compactMap { leg in
            guard let leg else { return nil }
            return AdaptiveRoutePace.Sample(speedMps: leg.speed,
                                            distanceMeters: leg.distance,
                                            isEstimated: leg.isEstimated)
        }, mode: paceMode)
        var groups: [[SpeedLeg]] = []
        var current: [SpeedLeg] = []
        for leg in legs {
            if let leg {
                if let previous = current.last,
                   previous.isEstimated != leg.isEstimated {
                    groups.append(current)
                    current.removeAll(keepingCapacity: true)
                }
                current.append(leg)
            } else if !current.isEmpty {
                groups.append(current)
                current.removeAll(keepingCapacity: true)
            }
        }
        if !current.isEmpty { groups.append(current) }
        return (groups.map { Self.makeRun($0, scale: scale, water: isWaterSport) }, scale)
    }

    /// Enlaza un corte de GPS sin inventar distancia registrada. Cuando se
    /// había importado una ruta se usa su geometría, no una cuerda recta.
    private func visualBridge(
        from first: HealthKitStore.RoutePoint,
        to last: HealthKitStore.RoutePoint,
        index: Int,
        seconds: TimeInterval,
        directMeters: CLLocationDistance
    ) -> [SpeedLeg]? {
        guard seconds > 0, seconds <= 2 * 60 * 60,
              directMeters >= 0.5, directMeters.isFinite else { return nil }

        let start = CLLocationCoordinate2D(latitude: first.latitude, longitude: first.longitude)
        let end = CLLocationCoordinate2D(latitude: last.latitude, longitude: last.longitude)
        let route = referenceBridge(from: start, to: end, seconds: seconds)
        // Sin trayecto de referencia no trazar un salto largo ni un teletransporte.
        guard route != nil || (directMeters <= 350 && directMeters / seconds <= 6)
        else { return nil }
        let coordinates = route ?? [start, end]
        let portions = zip(coordinates, coordinates.dropFirst()).compactMap { pair
            -> (CLLocationCoordinate2D, CLLocationCoordinate2D, Double)? in
            let distance = CLLocation(latitude: pair.0.latitude, longitude: pair.0.longitude)
                .distance(from: CLLocation(latitude: pair.1.latitude, longitude: pair.1.longitude))
            guard distance.isFinite, distance >= 0.1 else { return nil }
            return (pair.0, pair.1, distance)
        }
        let total = portions.reduce(0.0) { $0 + $1.2 }
        guard total > 0, total / seconds <= 25 else { return nil }
        let measured = [first.speedMps, last.speedMps].compactMap { value -> Double? in
            guard let value, value.isFinite, (0.2...25).contains(value) else { return nil }
            return value
        }
        let speed = measured.isEmpty
            ? max(0.2, min(25, total / seconds))
            : measured.reduce(0, +) / Double(measured.count)
        return portions.map {
            SpeedLeg(index: index, start: $0.0, end: $0.1,
                     distance: $0.2, speed: speed, isEstimated: true)
        }
    }

    /// Ajuste prudente al GPX previamente seleccionado para este mismo entreno.
    /// Nunca se incorporan puntos de la ruta prevista al historial medido.
    private func referenceBridge(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        seconds: TimeInterval
    ) -> [CLLocationCoordinate2D]? {
        let route = referenceRoutePoints
        guard route.count >= 3 else { return nil }
        let fromLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let toLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
        var fromIndex = -1, toIndex = -1
        var fromDistance = Double.greatestFiniteMagnitude
        var toDistance = Double.greatestFiniteMagnitude
        // GPX grandes: buscar sobre una muestra acotada, incluyendo el final.
        let strideSize = max(1, route.count / 1_400)
        var candidateIndices = Array(Swift.stride(from: 0, to: route.count, by: strideSize))
        if candidateIndices.last != route.count - 1 { candidateIndices.append(route.count - 1) }
        for index in candidateIndices {
            let point = route[index]
            guard Self.valid(point.latitude, point.longitude) else { continue }
            let location = CLLocation(latitude: point.latitude, longitude: point.longitude)
            let a = fromLocation.distance(from: location)
            let b = toLocation.distance(from: location)
            if a < fromDistance { fromDistance = a; fromIndex = index }
            if b < toDistance { toDistance = b; toIndex = index }
        }
        guard fromDistance <= 50, toDistance <= 50,
              fromIndex >= 0, toIndex >= 0, abs(toIndex - fromIndex) >= 2
        else { return nil }
        let direction = fromIndex < toIndex ? 1 : -1
        let count = abs(toIndex - fromIndex)
        let sampleStep = max(1, Int(ceil(Double(count) / 100)))
        var coordinates = [start]
        var offset = sampleStep
        while offset < count {
            let point = route[fromIndex + direction * offset]
            coordinates.append(.init(latitude: point.latitude, longitude: point.longitude))
            offset += sampleStep
        }
        coordinates.append(end)
        let distance = zip(coordinates, coordinates.dropFirst()).reduce(0.0) { sum, pair in
            sum + CLLocation(latitude: pair.0.latitude, longitude: pair.0.longitude)
                .distance(from: CLLocation(latitude: pair.1.latitude, longitude: pair.1.longitude))
        }
        guard distance.isFinite, distance > 0, distance <= 6_000,
              distance / seconds <= 25 else { return nil }
        return coordinates
    }

    private static func valid(_ latitude: Double, _ longitude: Double) -> Bool {
        latitude.isFinite && longitude.isFinite
            && (-90...90).contains(latitude) && (-180...180).contains(longitude)
    }

    private static func makeRun(
        _ legs: [SpeedLeg], scale: AdaptiveRoutePace.Scale?, water: Bool
    ) -> SpeedRun {
        let originals = [legs[0].start] + legs.map(\.end)
        let coordinates = softenCorners(originals, legs: legs)

        // Suavizado mínimo: conservar los cambios reales de intensidad.
        // Un promedio de 5 muestras borraba los contrastes en recorridos cortos.
        let velocities: [Double] = legs.indices.map { index in
            let lower = max(0, index - 1)
            let upper = min(legs.count - 1, index + 1)
            var total = 0.0
            var weightSum = 0.0
            for neighbor in lower...upper {
                let weight = neighbor == index ? 2.0 : 1.0
                total += legs[neighbor].speed * weight
                weightSum += weight
            }
            return total / weightSum
        }

        var lengths = [Double](repeating: 0, count: coordinates.count)
        for index in legs.indices {
            let a = coordinates[index], b = coordinates[index + 1]
            lengths[index + 1] = lengths[index] + CLLocation(
                latitude: a.latitude, longitude: a.longitude
            ).distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
        }
        let totalLength = max(0.001, lengths[lengths.count - 1])

        // Puntos de parada equidistantes sobre el camino real, con límite de
        // complejidad para rutas largas. MapPolyline interpola entre ellos.
        let step = max(1, Int(ceil(Double(coordinates.count - 1) / 256)))
        var coreStops: [Gradient.Stop] = []
        var edgeStops: [Gradient.Stop] = []
        var haloStops: [Gradient.Stop] = []
        var index = 0
        while index < coordinates.count {
            let speed: Double
            if index == 0 {
                speed = velocities[0]
            } else if index == coordinates.count - 1 {
                speed = velocities[velocities.count - 1]
            } else {
                speed = (velocities[index - 1] + velocities[index]) / 2
            }
            let rgb = AdaptiveRoutePace.rgb(
                position: scale?.position(for: speed) ?? 0.5, water: water)
            let color = Color(red: rgb.red, green: rgb.green, blue: rgb.blue)
            let offset = lengths[index] / totalLength
            if coreStops.isEmpty || offset > coreStops[coreStops.count - 1].location {
                coreStops.append(.init(color: color, location: offset))
                edgeStops.append(.init(color: color.opacity(0.75), location: offset))
                haloStops.append(.init(color: color.opacity(0.23), location: offset))
            }
            if index == coordinates.count - 1 { break }
            index = min(index + step, coordinates.count - 1)
        }

        // Cap vertices sent to MapKit, not the recorded GPS data.
        // Three stacked native overlays per full-resolution point may cause a
        // memory-pressure termination when a past map opens mid-workout.
        let maxVertices = 450
        let renderStride = max(1, Int(ceil(Double(coordinates.count - 1) / Double(maxVertices - 1))))
        var renderedCoordinates: [CLLocationCoordinate2D] = []
        renderedCoordinates.reserveCapacity(min(maxVertices, coordinates.count))
        var renderIndex = 0
        while renderIndex < coordinates.count {
            renderedCoordinates.append(coordinates[renderIndex])
            if renderIndex == coordinates.count - 1 { break }
            renderIndex = min(renderIndex + renderStride, coordinates.count - 1)
        }

        return SpeedRun(
            id: legs[0].index, coordinates: renderedCoordinates,
            isEstimated: legs[0].isEstimated,
            halo: Gradient(stops: haloStops),
            edge: Gradient(stops: edgeStops),
            core: Gradient(stops: coreStops)
        )
    }

    /// Atenúa el ruido de pequeños giros sin modificar los GPS originales,
    /// los parciales, las distancias ni los extremos de cada tramo válido.
    private static func softenCorners(
        _ points: [CLLocationCoordinate2D], legs: [SpeedLeg]
    ) -> [CLLocationCoordinate2D] {
        guard points.count > 2 else { return points }
        var result = points
        for index in 1..<(points.count - 1) {
            guard legs[index - 1].distance < 30, legs[index].distance < 30 else { continue }
            let before = points[index - 1], middle = points[index], after = points[index + 1]
            let candidate = CLLocationCoordinate2D(
                latitude: before.latitude * 0.15 + middle.latitude * 0.70 + after.latitude * 0.15,
                longitude: before.longitude * 0.15 + middle.longitude * 0.70 + after.longitude * 0.15
            )
            let shift = CLLocation(latitude: middle.latitude, longitude: middle.longitude)
                .distance(from: CLLocation(latitude: candidate.latitude, longitude: candidate.longitude))
            let fraction = min(1, 3 / max(0.001, shift))
            result[index] = CLLocationCoordinate2D(
                latitude: middle.latitude + (candidate.latitude - middle.latitude) * fraction,
                longitude: middle.longitude + (candidate.longitude - middle.longitude) * fraction
            )
        }
        return result
    }

    private struct SpeedLeg {
        var index: Int
        var start: CLLocationCoordinate2D
        var end: CLLocationCoordinate2D
        var distance: Double
        var speed: Double
        var isEstimated: Bool
    }

    private struct SpeedRun: Identifiable {
        var id: Int
        var coordinates: [CLLocationCoordinate2D]
        var isEstimated: Bool
        var halo: Gradient
        var edge: Gradient
        var core: Gradient
    }

    private var cameraPosition: MapCameraPosition {
        guard !points.isEmpty else { return .automatic }
        let lats = points.map(\.latitude)
        let lons = points.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max()
        else { return .automatic }
        let latitudeRange = maxLat - minLat
        let longitudeRange = maxLon - minLon
        // En una tarjeta muy ancha/baja MapKit reajusta la región y puede
        // acercar el punto más septentrional al borde superior, cortando
        // unos píxeles del halo de velocidad. Conceder más aire vertical
        // solo a la vista previa, sin alterar geometría ni datos GPS.
        let preview = !isInteractive
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2 + (preview ? latitudeRange * 0.05 : 0),
            longitude: (minLon + maxLon) / 2
        )
        let latDelta = Swift.max(latitudeRange * (preview ? 2.15 : 1.65), 0.008)
        let lonDelta = Swift.max(longitudeRange * (preview ? 1.85 : 1.65), 0.008)
        return .region(
            MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            )
        )
    }

    private var modes: MapInteractionModes {
        isInteractive ? [.pan, .zoom, .rotate] : []
    }

    /// Capa oscura entre teselas y ruta: resalta los tonos vivos de velocidad.
    private var routeBackdrop: [CLLocationCoordinate2D] {
        guard let minLat = points.map(\.latitude).min(),
              let maxLat = points.map(\.latitude).max(),
              let minLon = points.map(\.longitude).min(),
              let maxLon = points.map(\.longitude).max()
        else { return [] }
        let latPad = max(0.06, (maxLat - minLat) * 4)
        let lonPad = max(0.06, (maxLon - minLon) * 4)
        return [
            .init(latitude: minLat - latPad, longitude: minLon - lonPad),
            .init(latitude: minLat - latPad, longitude: maxLon + lonPad),
            .init(latitude: maxLat + latPad, longitude: maxLon + lonPad),
            .init(latitude: maxLat + latPad, longitude: minLon - lonPad)
        ]
    }


    /// Misma paleta y centro amarillo que los segmentos del trazado;
    /// sin curva exponencial que desplazaba el color hacia el rojo.
    private var speedLegendStops: [Gradient.Stop] {
        (0...24).map { index in
            let position = Double(index) / 24.0
            let rgb = AdaptiveRoutePace.rgb(position: position, water: isWaterSport)
            return Gradient.Stop(color: Color(red: rgb.red, green: rgb.green, blue: rgb.blue),
                                 location: position)
        }
    }

    private var speedLegend: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(LinearGradient(
                    stops: speedLegendStops,
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(width: 196, height: 7)

            HStack(spacing: 3) {
                Text(cachedScale.map { ReperaNumberFormat.decimal($0.lowMps * 3.6) } ?? "Mín.")
                Spacer(minLength: 2)
                Text(cachedScale.map {
                    "Media " + ReperaNumberFormat.decimal($0.medianMps * 3.6) + " km/h"
                } ?? "Media —")
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 2)
                Text(cachedScale.map { ReperaNumberFormat.decimal($0.highMps * 3.6) } ?? "Máx.")
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(OG.label)
        }
        .frame(width: 196)
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(.regularMaterial, in: RoundedRectangle(
            cornerRadius: 10, style: .continuous
        ))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(cachedScale.map {
            "Velocidad mínima \(ReperaNumberFormat.decimal($0.lowMps * 3.6)), media \(ReperaNumberFormat.decimal($0.medianMps * 3.6)) y máxima \(ReperaNumberFormat.decimal($0.highMps * 3.6)) kilómetros por hora"
        } ?? "Colores del recorrido: de menor a mayor velocidad")
        .allowsHitTesting(false)
    }

    var body: some View {
        Map(initialPosition: cameraPosition, interactionModes: modes) {
            if !routeBackdrop.isEmpty {
                MapPolygon(coordinates: routeBackdrop)
                    .foregroundStyle(Color.black.opacity(0.33))
                    .mapOverlayLevel(level: .aboveRoads)
            }
            ForEach(cachedRuns) { run in
                // El mapa pequeño no puede tener el mismo grosor que el zoom.
                // Los enlaces inferidos se dibujan discontinuos en las 3 capas.
                let dash: [CGFloat] = run.isEstimated ? [4, 4] : []
                MapPolyline(coordinates: run.coordinates)
                    .stroke(run.halo, style: StrokeStyle(
                        lineWidth: 4,
                        lineCap: .round, lineJoin: .round, dash: dash
                    ))
                    .mapOverlayLevel(level: .aboveLabels)
                MapPolyline(coordinates: run.coordinates)
                    .stroke(run.edge, style: StrokeStyle(
                        lineWidth: 2.25,
                        lineCap: .round, lineJoin: .round, dash: dash
                    ))
                    .mapOverlayLevel(level: .aboveLabels)
                MapPolyline(coordinates: run.coordinates)
                    .stroke(run.core, style: StrokeStyle(
                        lineWidth: 1.4,
                        lineCap: .round, lineJoin: .round, dash: dash
                    ))
                    .mapOverlayLevel(level: .aboveLabels)
            }
            if let start = points.first {
                Annotation("Inicio", coordinate: CLLocationCoordinate2D(
                    latitude: start.latitude,
                    longitude: start.longitude
                )) {
                    Circle()
                        .fill(OG.accent)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                }
            }
            if let end = points.last, points.count > 1 {
                Annotation("Fin", coordinate: CLLocationCoordinate2D(
                    latitude: end.latitude,
                    longitude: end.longitude
                )) {
                    Circle()
                        .fill(OG.red)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll, showsTraffic: false))
        .mapControls {
            if isInteractive {
                // La X ocupa arriba a la derecha.
                MapScaleView()
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if showsSpeedLegend && !cachedRuns.isEmpty {
                speedLegend
                    // Pegada al borde inferior derecho del mapa pequeño sin
                    // tapar la atribución (situada al lado izquierdo).
                    // En pantalla completa se respeta el indicador de inicio.
                    .padding(.trailing, 12)
                    .padding(.bottom, isInteractive ? 34 : 8)
            }
        }
        .allowsHitTesting(isInteractive)
        .task(id: routeCacheKey) {
            // Rebuild only for a different route; never on unrelated tab/store
            // invalidations while a workout is recording in the background.
            let style = routeStyle
            cachedRuns = style.runs
            cachedScale = style.scale
        }
    }

}

private extension AdaptiveRoutePace.Mode {
    static func forHealth(_ activity: HKWorkoutActivityType) -> Self {
        switch activity {
        case .walking, .hiking, .golf: .walking
        case .running: .running
        case .cycling: .cycling
        case .surfingSports, .paddleSports, .sailing, .rowing, .swimming: .water
        default: .other
        }
    }
}
