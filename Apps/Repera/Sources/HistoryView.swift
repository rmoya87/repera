import Charts
import CoreLocation
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
            case .repera(let s): return s.finishedAt ?? s.startedAt ?? .distantPast
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
        Group {
            if daySections.isEmpty {
                ContentUnavailableView(
                    "Sin entrenos",
                    systemImage: "tray",
                    description: Text("Las sesiones de Repera y de Apple Salud aparecerán aquí.")
                )
                .foregroundStyle(OG.label2)
            } else {
                List {
                    ForEach(daySections) { section in
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
        .ogPinnedTransparentNav("Historial")
        .task(id: store.workoutsEpoch) {
            // Misma nota/PR que Inicio: asegurar review y caché de PRs.
            for session in finishedWorkouts where session.sessionReview == nil {
                _ = store.ensureSessionReview(for: session.id)
            }
            prCountBySessionId = store.cachedPersonalRecordCountsBySession()
        }
        .task {
            await refreshHealthEntries()
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
        // Preferir sesión viva del store (nota/PR recién asegurados).
        let live = store.state.workouts.first(where: { $0.id == session.id }) ?? session
        let prs = prCountBySessionId[live.id] ?? 0
        let start = live.startedAt ?? live.finishedAt
        let day = start.map { Calendar.current.startOfDay(for: $0) } ?? Date()

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                // Historial: icono de fuerza (Inicio usa check).
                OGRegisterLeadingIcon(
                    systemName: "figure.strengthtraining.traditional",
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
    @Environment(\.dismiss) private var dismiss

    var sessionId: UUID

    @State private var draft: WorkoutSession?
    @State private var isEditing = false
    @State private var showCompletedEditor = false
    @State private var showDeleteConfirm = false
    @State private var healthExtras: HealthKitStore.SessionHealthExtras?
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
        .task(id: sessionId) {
            loadDraft()
            _ = store.ensureSessionReview(for: sessionId)
            draft = store.state.workouts.first(where: { $0.id == sessionId })
            guard let session = draft else { return }
            healthExtras = await health.sessionHealthExtras(for: session)
            // Afina la nota con FC/kcal de Salud si hay.
            await store.refineSessionReviewWithHealth(sessionId: sessionId)
            draft = store.state.workouts.first(where: { $0.id == sessionId })
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
        if let extras = healthExtras, extras.showRouteMap { return .healthRoute }
        if session.routePoints.count >= 2 { return .ownRoute }
        if session.locationPin != nil { return .pin }
        return .none
    }

    private func displayedRoute(_ session: WorkoutSession) -> [HealthKitStore.RoutePoint] {
        if let route = healthExtras?.routePoints, route.count >= 2 { return route }
        return session.routePoints.map(\.asHealthRoutePoint)
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
        // En detalle (sin editar) el mapa es solo lectura.
        let interactive = isEditing
        switch sessionMapContent(session) {
        case .healthRoute:
            if let extras = healthExtras {
                HealthWorkoutRouteMap(points: extras.routePoints, isInteractive: interactive)
            }
        case .ownRoute:
            HealthWorkoutRouteMap(
                points: session.routePoints.map(\.asHealthRoutePoint),
                isInteractive: interactive
            )
        case .pin:
            if let pin = session.locationPin {
                WorkoutLocationPinMap(pin: pin, isInteractive: interactive)
            }
        case .none:
            EmptyView()
        }
    }

    private var detailList: some View {
        List {
            if let session = draft {
                // Fecha + Tiempo/Kcal/Volumen + nota: un bloque continuo (sin título «Resultado»).
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        if !subtitle.isEmpty {
                            // Gutter interno para que la «M» de Miércoles nunca
                            // se recorte. El offset mantiene idéntica su posición visible:
                            // 8 pt de padding - 6 pt de offset = 2 pt originales.
                            Text(subtitle)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(OG.label2)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.leading, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .offset(x: -6)
                        }
                        summaryCard(session)
                        if let review = session.sessionReview {
                            SessionReviewCard(review: review)
                        }
                    }
                    .ogCardListRow(top: 4, bottom: 4)
                }

                // En edición el picker de lugar lleva su propio preview; no duplicar el mapa.
                if !isEditing, sessionMapContent(session) != .none {
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
                    } header: {
                        Text(sessionMapContent(session) == .pin ? "Ubicación" : "Recorrido")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(OG.accent)
                            .textCase(nil)
                    } footer: {
                        if sessionMapContent(session) == .pin, let name = session.locationPin?.name, !name.isEmpty {
                            Text(name)
                        } else if sessionMapContent(session) != .pin {
                            Text("Colores = velocidad (verde más lento → rojo más rápido).")
                        }
                    }
                }

                // Solo métricas reales de Apple Salud (FC, ruta, ritmo). No mostrar
                // kcal/dispositivo si solo vienen del propio Repera.
                if let extras = displayedMetrics(session) {
                    Section {
                        HealthSessionMetricsCard(
                            extras: extras,
                            includeSourceRows: extras.hasExternalSaludSource
                        )
                            .ogCardListRow()
                    } header: {
                        Text("Entreno")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(OG.accent)
                            .textCase(nil)
                    }

                    if displayedRoute(session).count >= 2 {
                        Section {
                            CardioSplitsView(
                                routePoints: displayedRoute(session),
                                heartRate: extras.heartRateSeries,
                                cycling: extras.activityType == .cycling ||
                                    session.title.localizedCaseInsensitiveContains("bici") ||
                                    session.title.localizedCaseInsensitiveContains("cicl")
                            )
                            .ogCardListRow()
                        } header: {
                            Text("Parciales")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(OG.accent)
                                .textCase(nil)
                        }
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
            if let session = draft {
                DayEditorView(
                    routine: CompletedWorkoutEditing.routine(
                        from: session,
                        sourceRoutine: session.routineId.flatMap { id in
                            store.state.routines.first(where: { $0.id == id })
                        }
                    ),
                    mode: .session,
                    onClose: { showCompletedEditor = false },
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
        .ogPinnedTransparentNav(workoutNavTitle)
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
                        }
                    }
                }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showCompletedEditor = true
                        } label: {
                            Label("Editar", systemImage: "pencil")
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
        // Tres tarjetas estables: no colapsar el resultado a una sola cuando
        // Apple Salud no aporta kcal o la sesión no tiene series con peso.
        // Kcal solo si vienen de una fuente real de Salud, nunca de MET estimados.
        let actualKcal = healthExtras?.hasExternalSaludSource == true
            ? healthExtras?.activeEnergyKcal
            : nil
        let minutes: Double = {
            if let start = session.startedAt {
                let end = session.finishedAt ?? start.addingTimeInterval(60)
                let wall = max(0, end.timeIntervalSince(start) / 60)
                if wall > 0 { return wall }
            }
            return session.durationMinutes
        }()

        let route = displayedRoute(session)
        let distanceMeters: Double? = {
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

        return HStack(spacing: 10) {
            summaryTile(
                title: "Tiempo",
                value: minutes > 0 ? "\(Int(minutes.rounded()))′" : "—",
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
                    value: String(format: "%.2f km", distanceMeters / 1000),
                    icon: "point.bottomleft.forward.to.point.topright.scurvepath",
                    tint: OG.accent
                )
            } else {
                summaryTile(
                    title: "Volumen",
                    value: session.totalVolumeKg > 0
                        ? "\(Int(session.totalVolumeKg.rounded()))"
                        : "—",
                    icon: "scalemass.fill",
                    tint: OG.accent
                )
            }
        }
    }

    private func summaryTile(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(OG.label)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(OG.label3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
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
            let result = blockId.flatMap { id in session.wodResults.first(where: { $0.id == id }) }
            let scoreCapture = sample.usesBlockScoreResult
            let header = sample.displayBlockHeader
            return ExerciseGroup(
                id: key,
                header: header,
                indices: value.indices,
                wodResult: result ?? inferredResult(for: sample, indices: value.indices, session: session),
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
        store.resolvedCatalogExercise(id: exercise.id)?.id ?? exercise.id
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
                if offset > 0 {
                    Divider().overlay(OG.surface3).padding(.leading, 52)
                }
                Button {
                    openExerciseDetail(exercise, sessionId: session.id)
                } label: {
                    HStack(spacing: 12) {
                        ExerciseThumb(exercise: exercise.exercise, size: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.exercise.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(OG.label)
                                .lineLimit(2)
                            Text(exercise.prescriptionSummaryLine)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(OG.label2)
                            if !exercise.loggedSets.isEmpty {
                                Text("Registrado · " + exercise.loggedSets.map(\.displaySummaryLine).joined(separator: " · "))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(OG.accent)
                                    .lineLimit(2)
                            } else if let result {
                                // El AMRAP es global: mostrar su score sin inventar
                                // series individuales ni adjudicar reps incompletas.
                                Text("Resultado del bloque · \(result.summaryLabel)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(OG.accent)
                            }
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
        let catalogExercise = exercise.exercise
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
                    Text(catalogExercise.name)
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
                // En una sesión ya completada, si no se editaron las cantidades,
                // la configuración prevista cuenta como realizada. Conservar
                // las unidades de cada ejercicio (reps, tiempo, kcal o metros).
                Text(isEditing
                     ? "Sin series registradas"
                     : (exercise.prescriptionSummaryLine.isEmpty
                        ? "Sin resultado registrado"
                        : exercise.prescriptionSummaryLine))
                    .font(.system(size: 13))
                    .foregroundStyle(OG.label3)
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
                    }
                }
            }
        }
        .padding(showsOuterPadding ? OG.pad : 0)
    }

    private func editSetColumnHeaders(exercise: Exercise, showsRemove: Bool) -> some View {
        let style = exercise.loggingStyle
        let qty = exercise.quantityFieldLabel
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
            showsRIR: !set.isMachineQuantity
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
        let maxReps = style.quantityCap
        let qtyStep: Int = {
            if style == .machineWork, (set.quantityUnit ?? exercise.defaultQuantityUnit) == .meters {
                return 50
            }
            if style == .repsAndTime { return 5 }
            return 1
        }()
        return HStack(spacing: 8) {
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
                        display: set.weightKg.map { String(format: "%g", $0) } ?? "—",
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
                                let normalized = text.replacingOccurrences(of: ",", with: ".")
                                if normalized.isEmpty {
                                    row.weightKg = nil
                                } else if let parsed = Double(normalized) {
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
                if extras.minHeartRateBpm != nil || extras.maxHeartRateBpm != nil ||
                    extras.averageSpeedKmh != nil || extras.maxSpeedKmh != nil {
                    HealthHeartRateStatRow(stats: extras)
                }
            } else if let average = extras.averageHeartRateBpm {
                Label("Ritmo cardíaco · media \(Int(average.rounded())) lpm", systemImage: "heart.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(OG.red)
                if extras.minHeartRateBpm != nil || extras.maxHeartRateBpm != nil ||
                    extras.averageSpeedKmh != nil || extras.maxSpeedKmh != nil {
                    HealthHeartRateStatRow(stats: extras)
                }
            } else if extras.minHeartRateBpm != nil || extras.maxHeartRateBpm != nil ||
                extras.averageSpeedKmh != nil || extras.maxSpeedKmh != nil {
                HealthHeartRateStatRow(stats: extras)
            }

            if includeSourceRows, extras.sourceName != nil || extras.activeEnergyKcal != nil {
                originRows
            }
        }
        .padding(OG.pad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
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
            .frame(height: 140)

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
            if stats.averageSpeedKmh != nil {
                stat("Vel. media", value: stats.averageSpeedKmh.map { String(format: "%.1f", $0) }, unit: "km/h", tint: OG.blue)
            }
            if stats.maxSpeedKmh != nil {
                stat("Vel. máx", value: stats.maxSpeedKmh.map { String(format: "%.1f", $0) }, unit: "km/h", tint: OG.accent)
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

private struct HealthSpeedStatRow: View {
    var avg: Double
    var max: Double?

    var body: some View {
        HStack(spacing: 8) {
            VStack(spacing: 4) {
                Text("Vel. media")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(OG.label3)
                Text(String(format: "%.1f", avg))
                    .font(.system(size: 18, weight: .semibold).monospacedDigit())
                    .foregroundStyle(OG.blue)
                Text("km/h")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(OG.label3)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(OG.surface2.opacity(0.85), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(spacing: 4) {
                Text("Vel. máx")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(OG.label3)
                Text(max.map { String(format: "%.1f", $0) } ?? "—")
                    .font(.system(size: 18, weight: .semibold).monospacedDigit())
                    .foregroundStyle(OG.accent)
                Text("km/h")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(OG.label3)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(OG.surface2.opacity(0.85), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

/// Ficha de un entreno importado de Apple Salud (mismo lenguaje visual que Entreno).
struct HealthActivityDetailView: View {
    @Environment(HealthKitStore.self) private var health

    var activityId: UUID

    @State private var detail: HealthKitStore.ExternalActivityDetail?

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
    }

    private func detailList(_ detail: HealthKitStore.ExternalActivityDetail) -> some View {
        let activity = detail.activity
        let showRouteMap = detail.routePoints.count >= 2

        return List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(OG.label2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 2)
                    }
                    summaryRow(activity, detail: detail)
                }
                .ogCardListRow(top: 4, bottom: 4)
            }

            if showRouteMap {
                Section {
                    let first = detail.routePoints.first
                    SessionMapWeatherCard(
                        latitude: first?.latitude,
                        longitude: first?.longitude,
                        workoutDate: activity.start
                    ) {
                        HealthWorkoutRouteMap(points: detail.routePoints, isInteractive: false)
                    }
                    .ogCardListRow()
                } header: {
                    sectionHeader("Recorrido")
                } footer: {
                    Text("Colores = velocidad (verde más lento → rojo más rápido).")
                }
            }

            Section {
                // Título/distancia ya van arriba (cabecera + tiles); no duplicar aquí.
                HealthSessionMetricsCard(
                    extras: detail.asSessionExtras,
                    includeSourceRows: false
                )
                .ogCardListRow()
            } header: {
                sectionHeader("Entreno")
            }

            if showRouteMap {
                Section {
                    CardioSplitsView(
                        routePoints: detail.routePoints,
                        heartRate: detail.heartRateSeries,
                        cycling: activity.activityType == .cycling
                    )
                    .ogCardListRow()
                } header: {
                    sectionHeader("Parciales")
                }
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
        .ogPinnedTransparentNav(activity.title)
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
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(OG.label)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(OG.label3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
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
            return String(format: "%.1f km", meters / 1000)
        }
        return "\(Int(meters.rounded())) m"
    }

    private func distanceFullLabel(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.2f km", meters / 1000)
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
            altitudeMeters: altitudeMeters
        )
    }
}

// MARK: - Mapa de recorrido (colores = velocidad)

struct HealthWorkoutRouteMap: View {
    var points: [HealthKitStore.RoutePoint]
    var isInteractive: Bool = true

    private var segments: [SpeedSegment] {
        guard points.count >= 2 else { return [] }
        let speeds = points.compactMap(\.speedMps).filter { $0 >= 0 }
        let minS = speeds.min() ?? 0
        let maxS = max(speeds.max() ?? 1, minS + 0.1)

        var result: [SpeedSegment] = []
        for i in 0..<(points.count - 1) {
            let a = points[i]
            let b = points[i + 1]
            let speed = a.speedMps ?? b.speedMps ?? minS
            result.append(
                SpeedSegment(
                    id: i,
                    start: CLLocationCoordinate2D(latitude: a.latitude, longitude: a.longitude),
                    end: CLLocationCoordinate2D(latitude: b.latitude, longitude: b.longitude),
                    color: Self.speedColor(speed, minSpeed: minS, maxSpeed: maxS)
                )
            )
        }
        return result
    }

    private var cameraPosition: MapCameraPosition {
        guard !points.isEmpty else { return .automatic }
        let lats = points.map(\.latitude)
        let lons = points.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max()
        else { return .automatic }
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let latDelta = Swift.max((maxLat - minLat) * 1.5, 0.008)
        let lonDelta = Swift.max((maxLon - minLon) * 1.5, 0.008)
        return .region(
            MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            )
        )
    }

    private var modes: MapInteractionModes {
        isInteractive ? [.pan, .zoom] : []
    }

    var body: some View {
        Map(initialPosition: cameraPosition, interactionModes: modes) {
            ForEach(segments) { segment in
                MapPolyline(coordinates: [segment.start, segment.end])
                    .stroke(segment.color, lineWidth: 4)
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
                MapCompass()
                MapScaleView()
            }
        }
        .allowsHitTesting(isInteractive)
    }

    private static func speedColor(_ speed: Double, minSpeed: Double, maxSpeed: Double) -> Color {
        let span = Swift.max(maxSpeed - minSpeed, 0.1)
        let t = Swift.min(1, Swift.max(0, (speed - minSpeed) / span))
        // Verde (lento) → amarillo → rojo (rápido)
        if t < 0.5 {
            let u = t * 2
            return Color(
                red: 0.2 + 0.8 * u,
                green: 0.82,
                blue: 0.2 * (1 - u)
            )
        } else {
            let u = (t - 0.5) * 2
            return Color(
                red: 1.0,
                green: 0.82 * (1 - u) + 0.27 * u,
                blue: 0.23 * u
            )
        }
    }

    private struct SpeedSegment: Identifiable {
        var id: Int
        var start: CLLocationCoordinate2D
        var end: CLLocationCoordinate2D
        var color: Color
    }
}
