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
            prCountBySessionId = store.cachedPersonalRecordCountsBySession()
        }
        .task {
            await refreshHealthEntries()
        }
    }

    private func sectionTitle(for day: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(day) { return "Hoy" }
        if cal.isDateInYesterday(day) { return "Ayer" }
        return SpanishDate.long(day)
    }

    private func refreshHealthEntries() async {
        guard health.isAuthorized else { return }
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
        let minutes = session.durationMinutes
        let kcal = session.appleActiveEnergyKcal
        let prs = prCountBySessionId[session.id] ?? 0
        let start = session.startedAt ?? session.finishedAt

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                historyLeadingIcon(systemName: "checkmark", tint: OG.accent)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    HStack(spacing: 6) {
                        Text(session.title)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(OG.label)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        if let notes = session.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Image(systemName: "note.text")
                                .font(.caption)
                                .foregroundStyle(OG.accent)
                        }
                    }
                    Spacer(minLength: 4)
                    if let start {
                        Text(SpanishDate.time(start))
                            .font(.system(size: 13, weight: .semibold).monospacedDigit())
                            .foregroundStyle(OG.label2)
                    }
                    historyChevron
                }
            }
            .padding(.trailing, Self.historyRowPad)

            // Carrusel edge-to-edge (trailing 0 en listRowInsets); inset solo en el contenido.
            historyChipsRow {
                if minutes > 0 {
                    historyChip("\(Int(minutes.rounded())) min", icon: "timer")
                }
                if let kcal, kcal > 0 {
                    historyChip("\(Int(kcal.rounded())) kcal", icon: "flame.fill")
                }
                if let review = session.sessionReview {
                    historyChip(review.scoreLabel, icon: review.scoreSymbolName)
                }
                if prs > 0 {
                    historyChip("\(prs) PR", icon: "trophy.fill")
                }
            }
            .padding(.leading, -Self.historyRowPad)
        }
    }

    private func healthHistoryRow(_ activity: HealthKitStore.ExternalActivity) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                historyLeadingIcon(systemName: activity.symbolName, tint: OG.red)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(activity.title)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(OG.label)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 4)
                    Text(SpanishDate.time(activity.start))
                        .font(.system(size: 13, weight: .semibold).monospacedDigit())
                        .foregroundStyle(OG.label2)
                    historyChevron
                }
            }
            .padding(.trailing, Self.historyRowPad)

            historyChipsRow {
                historyChip("Salud", icon: "heart.fill")
                if activity.durationMinutes > 0 {
                    historyChip("\(Int(activity.durationMinutes.rounded())) min", icon: "timer")
                }
                if let kcal = activity.activeEnergyKcal, kcal > 0 {
                    historyChip("\(Int(kcal.rounded())) kcal", icon: "flame.fill")
                }
            }
            .padding(.leading, -Self.historyRowPad)
        }
    }

    private func historyLeadingIcon(systemName: String, tint: Color) -> some View {
        ZStack {
            Circle().fill(tint.opacity(0.22))
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: 44, height: 44)
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

    /// Viewport a todo el ancho de la fila; inset solo en el contenido (inicio).
    @ViewBuilder
    private func historyChipsRow(@ViewBuilder content: () -> some View) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                content()
            }
            .padding(.leading, Self.chipsTitleLeading)
        }
        .contentMargins(.horizontal, 0, for: .scrollContent)
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func historyChip(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundStyle(OG.label2)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(OG.surface3.opacity(0.65), in: Capsule())
    }
}

/// Detalle visual de un entreno completado (mismo lenguaje que Entreno / preview).
struct WorkoutDetailView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(HealthKitStore.self) private var health
    @Environment(\.dismiss) private var dismiss

    var sessionId: UUID

    @State private var draft: WorkoutSession?
    @State private var isEditing = false
    @State private var showDeleteConfirm = false
    @State private var healthExtras: HealthKitStore.SessionHealthExtras?

    private var weightStep: Double { store.state.settings.weightIncrementKg }

    private var subtitle: String {
        guard let session = draft, let start = session.startedAt else { return "" }
        return SpanishDate.sessionSubtitle(start: start, end: session.finishedAt)
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

    @ViewBuilder
    private func sessionMapView(_ session: WorkoutSession) -> some View {
        switch sessionMapContent(session) {
        case .healthRoute:
            if let extras = healthExtras {
                HealthWorkoutRouteMap(points: extras.routePoints)
            }
        case .ownRoute:
            HealthWorkoutRouteMap(points: session.routePoints.map(\.asHealthRoutePoint))
        case .pin:
            if let pin = session.locationPin {
                WorkoutLocationPinMap(pin: pin)
            }
        case .none:
            EmptyView()
        }
    }

    private var detailList: some View {
        List {
            if !subtitle.isEmpty {
                Section {
                    Text(subtitle)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(OG.label2)
                        .ogListPageHeaderRow()
                }
            }

            if let session = draft {
                Section {
                    summaryCard(session)
                        .ogCardListRow()
                }

                if let review = session.sessionReview {
                    Section {
                        SessionReviewCard(review: review)
                            .ogCardListRow()
                    } header: {
                        Text("Resultado")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(OG.accent)
                            .textCase(nil)
                    }
                }

                if sessionMapContent(session) != .none {
                    Section {
                        sessionMapView(session)
                            .frame(height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
                            .ogCardListRow()
                    } header: {
                        Text(sessionMapContent(session) == .pin ? "Ubicación" : "Recorrido")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(OG.accent)
                            .textCase(nil)
                    } footer: {
                        if sessionMapContent(session) != .pin {
                            Text("Colores = velocidad (verde más lento → rojo más rápido).")
                        }
                    }
                }

                if let extras = healthExtras, extras.hasVisualContent {
                    Section {
                        HealthSessionMetricsCard(
                            extras: extras.preferringEnergy(session.appleActiveEnergyKcal)
                        )
                            .ogCardListRow()
                    } header: {
                        Text("Salud")
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
                }

                ForEach(groupedExercises(session), id: \.id) { group in
                    Section {
                        if let result = group.wodResult {
                            wodResultCard(result)
                                .ogCardListRow()
                        }
                        if group.showsMovementsAsPrescription {
                            wodMovementsCard(session: session, indices: group.indices)
                                .ogCardListRow()
                        } else {
                            ForEach(group.indices, id: \.self) { exIndex in
                                if session.exercises.indices.contains(exIndex) {
                                    exerciseCard(
                                        exIndex: exIndex,
                                        exercise: session.exercises[exIndex],
                                        hideScoreArtifact: group.wodResult
                                    )
                                    .ogCardListRow()
                                }
                            }
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
        .listSectionSpacing(18)
        .ogPinnedTransparentNav("Entreno")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if !isEditing {
                        Button {
                            isEditing = true
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
            if isEditing {
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
            }
        }
    }

    private func summaryCard(_ session: WorkoutSession) -> some View {
        // Misma fuente que Inicio: kcal guardadas en la sesión (estimación o Apple sync).
        // `healthExtras` a veces trae energía ambiente / sample viejo y pisa el valor correcto.
        let kcal = session.appleActiveEnergyKcal ?? healthExtras?.activeEnergyKcal
        let minutes: Double = {
            if let start = session.startedAt {
                let end = session.finishedAt ?? start.addingTimeInterval(60)
                let wall = max(0, end.timeIntervalSince(start) / 60)
                if wall > 0 { return wall }
            }
            return session.durationMinutes
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
                value: kcal.map { "\(Int($0.rounded()))" } ?? "—",
                icon: "flame.fill",
                tint: OG.orange
            )
            if let hr = healthExtras?.averageHeartRateBpm, session.totalVolumeKg <= 0 {
                summaryTile(
                    title: "FC media",
                    value: "\(Int(hr.rounded()))",
                    icon: "heart.fill",
                    tint: OG.red
                )
            } else {
                summaryTile(
                    title: "Volumen",
                    value: "\(Int(session.totalVolumeKg))",
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
        HStack(spacing: 12) {
            Image(systemName: result.elapsedSeconds != nil ? "stopwatch.fill" : "number.circle.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(OG.accent)
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
        .padding(OG.pad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }

    private func wodMovementsCard(session: WorkoutSession, indices: [Int]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Movimientos")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(OG.label3)
            ForEach(indices, id: \.self) { exIndex in
                if session.exercises.indices.contains(exIndex) {
                    let exercise = session.exercises[exIndex]
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
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(OG.pad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }

    private func exerciseCard(
        exIndex: Int,
        exercise: SessionExercise,
        hideScoreArtifact: WODBlockResult? = nil
    ) -> some View {
        let visibleSets = visibleLoggedSets(for: exercise, hideScoreArtifact: hideScoreArtifact)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ExerciseThumb(exercise: exercise.exercise, size: 48)
                Text(exercise.exercise.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(OG.label)
                    .lineLimit(2)
                Spacer(minLength: 0)
            }

            if visibleSets.isEmpty {
                Text(isEditing ? "Sin series" : (exercise.usesBlockScoreResult ? exercise.prescriptionSummaryLine : "Sin series"))
                    .font(.system(size: 13))
                    .foregroundStyle(OG.label3)
            } else {
                ForEach(Array(visibleSets.enumerated()), id: \.element.id) { setIndex, set in
                    if isEditing {
                        if let realIndex = exercise.loggedSets.firstIndex(where: { $0.id == set.id }) {
                            editableSetRow(exIndex: exIndex, setIndex: realIndex, set: set)
                        }
                    } else {
                        readOnlySetRow(setIndex: setIndex, set: set)
                    }
                }
            }
        }
        .padding(OG.pad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }

    private func visibleLoggedSets(
        for exercise: SessionExercise,
        hideScoreArtifact: WODBlockResult?
    ) -> [LoggedSet] {
        guard let result = hideScoreArtifact,
              let total = result.totalReps,
              exercise.loggedSets.count == 1,
              let only = exercise.loggedSets.first,
              only.weightKg == nil,
              only.reps == total
        else { return exercise.loggedSets }
        return []
    }

    private func readOnlySetRow(setIndex: Int, set: LoggedSet) -> some View {
        HStack(spacing: 10) {
            Text("S\(setIndex + 1)")
                .font(.system(size: 12, weight: .bold).monospacedDigit())
                .foregroundStyle(OG.label3)
                .frame(width: 28, alignment: .leading)
            Text(set.displaySummaryLine)
                .font(.system(size: 15, weight: .medium).monospacedDigit())
                .foregroundStyle(OG.label)
            Spacer(minLength: 0)
            if let rir = set.rir, !set.isMachineQuantity {
                Text("RIR \(rir)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(OG.label3)
            }
        }
        .padding(.vertical, 4)
    }

    private func editableSetRow(exIndex: Int, setIndex: Int, set: LoggedSet) -> some View {
        HStack(spacing: 8) {
            Text("S\(setIndex + 1)")
                .font(.system(size: 12, weight: .bold).monospacedDigit())
                .foregroundStyle(OG.label3)
                .frame(width: 28, alignment: .leading)

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

            OGRepeatStepper(
                display: "\(set.reps)",
                keyboard: .numberPad,
                onMinus: {
                    mutateSet(exIndex: exIndex, setIndex: setIndex) { $0.reps = max(0, $0.reps - 1) }
                },
                onPlus: {
                    mutateSet(exIndex: exIndex, setIndex: setIndex) { $0.reps += 1 }
                },
                onCommitText: { text in
                    mutateSet(exIndex: exIndex, setIndex: setIndex) { row in
                        if let parsed = Int(text) {
                            row.reps = max(0, parsed)
                        }
                    }
                }
            )
            .frame(width: 110)

            if exerciseSetCount(exIndex) > 1 {
                Button {
                    removeSet(exIndex: exIndex, setIndex: setIndex)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(OG.red.opacity(0.9))
                }
                .buttonStyle(.plain)
            }
        }
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

            if !extras.heartRateSeries.isEmpty {
                HealthHeartRateChart(series: extras.heartRateSeries, stats: extras)
            } else if extras.averageHeartRateBpm != nil {
                HealthHeartRateStatRow(stats: extras)
            }

            if let avg = extras.averageSpeedKmh, avg > 0 {
                HealthSpeedStatRow(avg: avg, max: extras.maxSpeedKmh)
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

            HealthHeartRateStatRow(stats: stats)
        }
    }
}

private struct HealthHeartRateStatRow: View {
    var stats: HealthKitStore.SessionHealthExtras

    var body: some View {
        HStack(spacing: 8) {
            hrPill(title: "Mín", value: stats.minHeartRateBpm, tint: OG.label2)
            hrPill(title: "Media", value: stats.averageHeartRateBpm, tint: OG.red)
            hrPill(title: "Máx", value: stats.maxHeartRateBpm, tint: OG.orange)
        }
    }

    private func hrPill(title: String, value: Double?, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(OG.label3)
            Text(value.map { "\(Int($0.rounded()))" } ?? "—")
                .font(.system(size: 18, weight: .semibold).monospacedDigit())
                .foregroundStyle(tint)
            Text("lpm")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(OG.label3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(OG.surface2.opacity(0.85), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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
            if !subtitle.isEmpty {
                Section {
                    Text(subtitle)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(OG.label2)
                        .ogListPageHeaderRow()
                }
            }

            Section {
                summaryRow(activity, detail: detail)
                    .ogCardListRow()
            }

            if showRouteMap {
                Section {
                    HealthWorkoutRouteMap(points: detail.routePoints)
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
                        .ogCardListRow()
                } header: {
                    sectionHeader("Recorrido")
                } footer: {
                    Text("Colores = velocidad (verde más lento → rojo más rápido).")
                }
            }

            Section {
                HealthSessionMetricsCard(
                    extras: detail.asSessionExtras,
                    headline: activity.title,
                    symbolName: activity.symbolName,
                    headlineSubtitle: activity.distanceMeters.flatMap { $0 > 0 ? distanceFullLabel($0) : nil },
                    includeSourceRows: false
                )
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
        .listSectionSpacing(18)
        .ogPinnedTransparentNav("Entreno")
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
            } else {
                summaryTile(
                    title: "FC media",
                    value: detail.averageHeartRateBpm.map { "\(Int($0.rounded()))" } ?? "—",
                    icon: "heart.fill",
                    tint: OG.red
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

    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
    }

    var body: some View {
        Map(
            initialPosition: .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            ),
            interactionModes: [.pan, .zoom]
        ) {
            Annotation("Entreno", coordinate: coordinate) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(OG.accent)
                    .shadow(radius: 2)
            }
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll, showsTraffic: false))
        .mapControls {
            MapCompass()
            MapScaleView()
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
            speedMps: speedMps
        )
    }
}

// MARK: - Mapa de recorrido (colores = velocidad)

struct HealthWorkoutRouteMap: View {
    var points: [HealthKitStore.RoutePoint]

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

    var body: some View {
        Map(initialPosition: cameraPosition, interactionModes: [.pan, .zoom]) {
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
            MapCompass()
            MapScaleView()
        }
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
