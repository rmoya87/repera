import ReperaDomain
import SwiftUI
import UIKit

enum WorkoutFlowRoute: Hashable {
    case sessionPreview(routineId: UUID?)
    case editWorkout(routineId: UUID)
    case exerciseDetail(exerciseId: UUID)
    case workout
}

/// Menú principal: Inicio · Comenzar · + (Clases/Plan) · Progreso · Ejercicios.
struct RootTabView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(BusinessDataStore.self) private var businessData
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var duoRail = OGDuoContextRailStore()
    @State private var lastAvailableSize: CGSize = .zero
    @State private var tab: AppTab = .home
    @State private var showStartHub = false
    @State private var sportFavoriteOpenError: String?
    @State private var homeFocusDay: Date?
    @State private var flowPath: [WorkoutFlowRoute] = []
    @State private var previewRoutine: Routine?
    @State private var pendingResultsEditorID: UUID?
    @State private var pendingInvitationId: UUID?
    @State private var showInvitationSheet = false
    @State private var healthDeletionError: String?

    enum AppTab: Hashable {
        case home, start, plus, stats, exercises
    }

    /// La sección de clases/centro solo existe tras una vinculación real,
    /// nunca por una invitación pendiente o por una cuenta profesional sin cliente.
    private var hasLinkedCenter: Bool { !businessData.athleteCenterIds.isEmpty }

    var body: some View {
        ZStack {
            mainTabView
            flowOverlay
        }
        .onGeometryChange(for: CGSize.self, of: { $0.size }) { _, size in
            updateDuoLayout(availableSize: size)
        }
        .onChange(of: horizontalSizeClass) { _, _ in
            updateDuoLayout(availableSize: lastAvailableSize)
        }
        .onAppear { updateDuoLayout(availableSize: lastAvailableSize) }
        .onChange(of: hasLinkedCenter) { _, linked in
            if !linked && tab == .plus { tab = .home }
        }
        .onReceive(NotificationCenter.default.publisher(
            for: Notification.Name("repera.healthDeletionFailed")
        )) { notification in
            healthDeletionError = notification.object as? String
                ?? "El entrenamiento se eliminó de Repera, pero no de Apple Salud."
        }
        .alert("No se pudo eliminar de Salud", isPresented: Binding(
            get: { healthDeletionError != nil },
            set: { if !$0 { healthDeletionError = nil } }
        )) {
            Button("Aceptar", role: .cancel) { healthDeletionError = nil }
        } message: {
            Text(healthDeletionError ?? "")
        }
        .sheet(isPresented: $showStartHub) { startHubSheet }
        .sheet(isPresented: Binding(
            get: { pendingResultsEditorID != nil },
            set: { if !$0 { pendingResultsEditorID = nil } }
        )) {
            if let id = pendingResultsEditorID,
               let session = store.state.workouts.first(where: { $0.id == id }) {
                NavigationStack {
                    DayEditorView(
                        routine: CompletedWorkoutEditing.routine(
                            from: session,
                            sourceRoutine: session.routineId.flatMap { id in
                                store.state.routines.first(where: { $0.id == id })
                            }
                        ),
                        mode: .session,
                        onClose: { pendingResultsEditorID = nil },
                        onApplyCompleted: { routine, details, recordNewSets in
                            var completed = CompletedWorkoutEditing.applying(
                                routine, to: details, catalog: store.state.exercises,
                                recordNewSetsAsPerformed: recordNewSets
                            )
                            completed.phase = .finished
                            completed.awaitingResultEntry = false
                            store.saveWorkout(completed)
                            pendingResultsEditorID = nil
                        },
                        completedSession: session,
                        embedsNavigationStack: false,
                        usesPageCloseHeader: true
                    )
                }
            }
        }
        .alert(
            "No se ha podido abrir la actividad",
            isPresented: Binding(
                get: { sportFavoriteOpenError != nil },
                set: { if !$0 { sportFavoriteOpenError = nil } }
            )
        ) {
            Button("Aceptar", role: .cancel) { sportFavoriteOpenError = nil }
        } message: {
            Text(sportFavoriteOpenError ?? "")
        }
        .animation(.easeOut(duration: 0.18), value: flowPath.isEmpty)
        .tint(OG.accent)
        .onChange(of: tab) { _, newTab in
            if newTab == .exercises { store.requestExerciseCatalogRefresh() }
            if newTab != .start && LiveActivityRecorder.shared.phase == .idle {
                UserDefaults.standard.removeObject(forKey: "repera.plannedRecordingRoutineID")
            }
        }
        // Never force the editor open merely because an unfinished results form
        // exists. Open only for an explicit notification tap (or the Inicio button).
        .onReceive(NotificationCenter.default.publisher(for: WorkoutCompletionNotifier.openEvent)) { note in
            if let id = note.object as? UUID { openNotifiedCompletedWorkout(id) }
        }
        .task(id: store.isHydrated) {
            if store.isHydrated { openPendingCompletedWorkoutNotification() }
        }
        .onChange(of: store.workoutsEpoch) { _, _ in
            openPendingCompletedWorkoutNotification()
        }
        .task(id: store.isHydrated) {
            await LiveRoutesStore.shared.synchronizeWithICloud()
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.didBecomeActiveNotification
        )) { _ in
            LiveRoutesStore.shared.requestICloudSynchronization()
        }
        .task { restoreActiveSessionOnLaunch() }
        .onOpenURL(perform: handleOpenURL)
        .onReceive(NotificationCenter.default.publisher(for: ReperaSystemRoute.notification)) { _ in
            consumeSystemRoute()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            consumeSystemRoute()
        }
        .task(id: store.isHydrated) {
            if store.isHydrated { consumeSystemRoute() }
        }
        .sheet(isPresented: $showInvitationSheet) {
            InvitationDeepLinkSheet(
                invitationId: pendingInvitationId,
                onDone: {
                    showInvitationSheet = false
                    pendingInvitationId = nil
                }
            )
        }
        .sheet(isPresented: Binding(
            get: { store.pendingSessionReview != nil },
            set: { if !$0 { store.dismissPendingSessionReview() } }
        )) {
            if let review = store.pendingSessionReview {
                SessionReviewSheet(review: review) {
                    store.dismissPendingSessionReview()
                }
            }
        }
        .environment(duoRail)
    }

    private var mainTabView: some View {
        TabView(selection: $tab) {
            SwiftUI.Tab("Inicio", systemImage: "house", value: AppTab.home) {
                HomeView(
                    onOpenWorkout: openWorkout,
                    focusDay: homeFocusDay,
                    onStart: openTodayPreview,
                    onStartRoutine: openRoutinePreview
                )
            }

            SwiftUI.Tab(
                "Comenzar",
                systemImage: tab == .start ? "play.circle.fill" : "play.circle",
                value: AppTab.start
            ) {
                LiveActivityView(
                    onSaved: { date in
                        homeFocusDay = date
                        tab = .home
                        store.requestExerciseCatalogRefresh()
                    },
                    onOpenWorkout: openWorkout
                )
            }

            // No ocupar un hueco con «+» si no hay cliente vinculado.
            // Ajustes → Buscar sigue accesible para encontrar un centro.
            if hasLinkedCenter {
                SwiftUI.Tab(value: AppTab.plus) {
                    PlusHubView(onStartRoutine: openRoutinePreview)
                } label: {
                    Image(systemName: tab == .plus ? "plus.circle.fill" : "plus.circle")
                }
                .accessibilityLabel("Clases y centro")
            }

            SwiftUI.Tab(
                "Progreso",
                systemImage: tab == .stats ? "chart.bar.fill" : "chart.bar",
                value: AppTab.stats
            ) {
                StatsView()
            }

            SwiftUI.Tab("Ejercicios", systemImage: "dumbbell", value: AppTab.exercises) {
                LibraryView(onOpenedWorkout: openWorkout)
            }
        }
        .tabBarMinimizeBehavior(continueModelForCurrentTab != nil ? .onScrollDown : .never)
        .modifier(ContinueAccessoryModifier(
            model: continueModelForCurrentTab,
            onContinue: continueFromAccessory
        ))
        .environment(duoRail)
        .onChange(of: LiveActivityRecorder.shared.phase) { _, phase in
            handleLivePhase(phase)
        }
        .onReceive(NotificationCenter.default.publisher(
            for: Notification.Name("repera.openComenzarFromWatch")
        )) { _ in
            flowPath = []
            tab = .start
        }
        .task(id: LiveActivityRecorder.shared.isActive) {
            store.refreshContinueChrome()
            guard LiveActivityRecorder.shared.isActive else { return }
            while !Task.isCancelled, LiveActivityRecorder.shared.isActive {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                store.refreshContinueChrome()
            }
        }
    }

    @ViewBuilder
    private var flowOverlay: some View {
        if let root = flowPath.first {
            NavigationStack(path: flowTailBinding) {
                flowDestination(root)
                    .navigationDestination(for: WorkoutFlowRoute.self, destination: flowDestination)
            }
            .id(root)
            .transition(.move(edge: .trailing))
            .zIndex(1)
        }
    }

    @ViewBuilder
    private var startHubSheet: some View {
        StartHubSheet(
            onOpenedWorkout: {
                showStartHub = false
                openWorkout()
            },
            onOpenSport: openSportFavorite(_:),
            onSavedTimer: { date in
                homeFocusDay = date
                flowPath = []
                tab = .home
                showStartHub = false
            }
        )
        .ogSheetChrome(detents: [.large])
    }

    private func continueFromAccessory() {
        if store.continueAccessory?.isLiveActivity == true {
            flowPath = []
            tab = .start
        } else {
            previewRoutine = nil
            flowPath = [.sessionPreview(routineId: nil)]
        }
    }

    private func handleLivePhase(_ phase: LiveActivityRecorder.Phase) {
        store.refreshContinueChrome()
        if phase == .recording || phase == .paused
            || (phase == .review && !store.isAutoSavingWatchActivity) {
            flowPath = []
            tab = .start
        }
    }

    private func restoreActiveSessionOnLaunch() {
        if store.state.activeSession != nil {
            flowPath = [.workout]
        } else if LiveActivityRecorder.shared.isActive {
            tab = .start
        }
    }

    private func openSportFavorite(_ sportID: String) {
        guard let sport = LiveSport(rawValue: sportID) else {
            sportFavoriteOpenError = "No se reconoce el deporte de este favorito."
            return
        }
        guard LiveActivityRecorder.shared.phase == .idle,
              !LiveActivityRecorder.shared.isStartCountingDown else {
            sportFavoriteOpenError = "Termina o descarta la actividad actual antes de iniciar otra."
            return
        }
        LiveActivityRecorder.shared.choose(sport)
        showStartHub = false
        flowPath = []
        tab = .start
    }

    private func openNotifiedCompletedWorkout(_ id: UUID) {
        guard store.isHydrated else { return }
        // Una notificación tardía de un resultado ya editado o eliminado
        // nunca debe reabrir un formulario obsoleto.
        guard store.state.workouts.contains(where: {
            $0.id == id && $0.finishedAt != nil && $0.timerDetails == nil &&
                $0.awaitingResultEntry
        }) else {
            UserDefaults.standard.removeObject(forKey: WorkoutCompletionNotifier.pendingKey)
            return
        }
        // A notification targets exactly its finished session, not the currently
        // active plan or the most recent workout on a different day.
        flowPath = []
        tab = .home
        pendingResultsEditorID = id
        UserDefaults.standard.removeObject(forKey: WorkoutCompletionNotifier.pendingKey)
    }

    private func openPendingCompletedWorkoutNotification() {
        guard let raw = UserDefaults.standard.string(forKey: WorkoutCompletionNotifier.pendingKey),
              let id = UUID(uuidString: raw) else { return }
        openNotifiedCompletedWorkout(id)
    }

    /// El App Intent puede ejecutarse antes de completar la hidratación.
    /// Consumir una sola vez y reutilizar el mismo enrutador de deep links.
    private func consumeSystemRoute() {
        guard store.isHydrated,
              let route = UserDefaults.standard.string(forKey: ReperaSystemRoute.pendingKey),
              ["live", "workout"].contains(route),
              let url = URL(string: "repera://\(route)") else { return }
        UserDefaults.standard.removeObject(forKey: ReperaSystemRoute.pendingKey)
        handleOpenURL(url)
    }

    private func handleOpenURL(_ url: URL) {
        guard url.scheme == "repera" else { return }
        switch url.host {
        case "live":
            flowPath = []
            tab = .start
        case "workout":
            if store.hasActiveSession {
                openWorkout()
            } else {
                flowPath = []
                tab = .home
            }
        case "invitation":
            let idString = url.pathComponents.dropFirst().first
                ?? url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if let id = UUID(uuidString: idString) {
                pendingInvitationId = id
                showInvitationSheet = true
                tab = .home
                NotificationCenter.default.post(
                    name: Notification.Name("repera.openSettingsForInvitation"),
                    object: id
                )
            }
        default:
            break
        }
    }

    /// Detecta el espacio completo de la escena, no el viewport interno
    /// de TabView, que puede excluir la barra de pestañas derecha.
    private func updateDuoLayout(availableSize: CGSize) {
        lastAvailableSize = availableSize
        let sceneSize = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .bounds.size ?? availableSize

        let width = max(sceneSize.width, availableSize.width)
        let height = max(sceneSize.height, availableSize.height)
        // La relación de aspecto distingue un Duo abierto (más cuadrado)
        // de un iPhone normal, incluso cuando SwiftUI mide solo el contenido
        // y aunque el sistema marque la size class como compact.
        let ratio = min(width, height) / max(width, height)
        let hasDuoProportions = min(width, height) >= 390 && ratio >= 0.60
        let isRegular = horizontalSizeClass == .regular
        let expanded = hasDuoProportions || isRegular
        guard duoRail.isExpanded != expanded else { return }
        duoRail.isExpanded = expanded
        NSLog(
            "Repera Duo: %@ window=%.0fx%.0f root=%.0fx%.0f ratio=%.2f",
            expanded ? "expanded" : "compact",
            sceneSize.width, sceneSize.height,
            availableSize.width, availableSize.height,
            ratio
        )
    }

    /// Continuar encima del menú: en la pestaña Comenzar solo Play (no Live).
    private var continueModelForCurrentTab: ContinueAccessoryModel? {
        guard let model = store.continueAccessory else { return nil }
        if tab == .start, model.isLiveActivity { return nil }
        return model
    }

    private var flowTailBinding: Binding<[WorkoutFlowRoute]> {
        Binding(
            get: { Array(flowPath.dropFirst()) },
            set: { tail in
                guard let root = flowPath.first else {
                    flowPath = tail
                    return
                }
                flowPath = [root] + tail
            }
        )
    }

    @ViewBuilder
    private func flowDestination(_ route: WorkoutFlowRoute) -> some View {
        switch route {
        case .sessionPreview(let routineId):
            SessionPreviewView(
                routine: resolvePreviewRoutine(id: routineId),
                onClose: { flowPath = [] },
                onStart: openWorkout,
                onRecord: recordPlannedRoutine,
                onContinue: openWorkout,
                onEdit: { routine in
                    previewRoutine = routine
                    flowPath.append(.editWorkout(routineId: routine.id))
                },
                onOpenExercise: { exerciseID in
                    // Un único push por tap; back elimina solo esta ruta.
                    guard flowPath.last == .sessionPreview(routineId: routineId) else { return }
                    flowPath.append(.exerciseDetail(exerciseId: exerciseID))
                }
            )
            .navigationBarBackButtonHidden(true)

        case .editWorkout(let routineId):
            if let routine = resolvePreviewRoutine(id: routineId) {
                DayEditorView(
                    routine: routine,
                    // Una copia planificada se edita SOLO en su día; la
                    // plantilla de Favoritos conserva su ID y se edita
                    // como favorito, no como una planificación nueva.
                    mode: routine.isOneOff
                        ? .oneOff(isNew: false)
                        : (routine.isFavorite ? .favorite(isNew: false) : .plan(isNew: false)),
                    onClose: { if !flowPath.isEmpty { flowPath.removeLast() } },
                    embedsNavigationStack: false,
                    usesPageCloseHeader: true
                )
            } else {
                Color.clear
                    .onAppear {
                        if !flowPath.isEmpty { flowPath.removeLast() }
                    }
            }

        case .exerciseDetail(let exerciseId):
            ExerciseDetailView(exerciseId: exerciseId)
                .navigationBarBackButtonHidden(false)

        case .workout:
            // Full session UI owns dismissal; overlay keeps tab state underneath.
            WorkoutView(onClose: { flowPath = [] })
                .navigationBarBackButtonHidden(true)
        }
    }

    private func resolvePreviewRoutine(id: UUID?) -> Routine? {
        if let id,
           let live = store.state.routines.first(where: { $0.id == id }) {
            return live
        }
        if let previewRoutine { return previewRoutine }
        return store.routineForToday()
    }

    private func recordPlannedRoutine(_ routine: Routine) {
        guard store.state.activeSession == nil,
              !LiveActivityRecorder.shared.isActive else {
            sportFavoriteOpenError = "Finaliza o descarta primero el entrenamiento que está en curso."
            return
        }
        let names = routine.blocks.flatMap { block in
            block.movements.map(\.name) + block.exercises.compactMap { entry in
                store.state.exercises.first(where: { $0.id == entry.exerciseId })?.name
            }
        }.joined(separator: " ").lowercased()
        let sport: LiveSport = names.contains("bicicleta exterior") || names.contains("outdoor cycling")
            ? .cycling : (names.contains("carrera exterior") || names.contains("outdoor running")
                ? .running : (routine.blocks.contains(where: { $0.kind == .wod }) ? .crossfit : .strength))
        UserDefaults.standard.set(routine.id.uuidString, forKey: "repera.plannedRecordingRoutineID")
        LiveActivityRecorder.shared.choose(sport)
        flowPath = []
        tab = .start
        LiveActivityRecorder.shared.beginStartCountdown()
    }

    private func openWorkout() {
        flowPath = [.workout]
    }

    private func openTodayPreview() {
        if store.hasActiveSession {
            previewRoutine = nil
            flowPath = [.sessionPreview(routineId: nil)]
            return
        }
        if LiveActivityRecorder.shared.isActive {
            flowPath = []
            tab = .start
            return
        }
        guard let today = store.routineForToday() else {
            showStartHub = true
            return
        }
        openRoutinePreview(today)
    }

    private func openRoutinePreview(_ routine: Routine) {
        // Entrar en el flujo de registrar un entreno: resolver alias antes
        // del inicio de la sesión sin interferir con su grabación.
        store.requestExerciseCatalogRefresh()
        previewRoutine = routine
        flowPath = [.sessionPreview(routineId: routine.id)]
    }
}



private struct ContinueAccessoryModifier: ViewModifier {
    var model: ContinueAccessoryModel?
    var onContinue: () -> Void

    func body(content: Content) -> some View {
        if let model {
            content.tabViewBottomAccessory {
                ContinueAccessoryContent(model: model, onContinue: onContinue)
            }
        } else {
            content
        }
    }
}

/// Expanded (arriba) e inline (derecha del menú): mismos campos; toda el área clicable.
private struct ContinueAccessoryContent: View {
    var model: ContinueAccessoryModel
    var onContinue: () -> Void
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    private var isInline: Bool { placement == .inline }

    var body: some View {
        Button(action: onContinue) {
            HStack(spacing: isInline ? 10 : 12) {
                ContinueAccessoryThumb(
                    name: model.thumbName,
                    sportSymbol: model.sportSymbol,
                    isLiveActivity: model.isLiveActivity,
                    compact: isInline
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text("Continuar")
                        .font(.system(size: isInline ? 11 : 12, weight: .medium))
                        .foregroundStyle(OG.label2)
                    Text(model.title)
                        .font(.system(size: isInline ? 14 : 16, weight: .semibold))
                        .foregroundStyle(OG.label)
                        .lineLimit(1)
                }
                Spacer(minLength: 6)
                if model.isLiveActivity,
                   model.paceLabel != nil || model.distanceLabel != nil {
                    // Mismas métricas en expandido y comprimido: duración + ritmo + distancia.
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(model.progressLabel)
                            .font(.system(size: isInline ? 12 : 13, weight: .semibold).monospacedDigit())
                        HStack(spacing: 6) {
                            if let pace = model.paceLabel {
                                Text(pace)
                            }
                            if let distance = model.distanceLabel {
                                Text(distance)
                            }
                        }
                        .font(.system(size: isInline ? 11 : 12, weight: .semibold).monospacedDigit())
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(OG.orange)
                } else {
                    Text(model.progressLabel)
                        .font(.system(size: isInline ? 12 : 13, weight: .semibold).monospacedDigit())
                        .foregroundStyle(model.isLiveActivity ? OG.orange : OG.accent)
                }
            }
            .padding(.horizontal, isInline ? 10 : OG.pad)
            .padding(.vertical, isInline ? 6 : 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .accessibilityLabel("Continuar \(model.title)")
    }
}

private struct ContinueAccessoryThumb: View {
    var name: String?
    var sportSymbol: String? = nil
    var isLiveActivity: Bool = false
    var compact: Bool = false
    @State private var image: UIImage?

    private var size: CGFloat { compact ? 36 : 40 }

    var body: some View {
        Group {
            if let image, !isLiveActivity {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else if isLiveActivity {
                ZStack {
                    Circle().fill(OG.orange)
                    Image(systemName: sportSymbol ?? "figure.run")
                        .font(.system(size: compact ? 15 : 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: size, height: size)
            } else {
                ZStack {
                    Circle().fill(OG.accent.opacity(0.2))
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(OG.accent)
                }
                .frame(width: size, height: size)
            }
        }
        .task(id: name) {
            guard let name, !isLiveActivity else {
                image = nil
                return
            }
            if let hit = ThumbMemoryCache.shared.image(for: "\(name)#120") {
                image = hit
                return
            }
            image = await ThumbImageLoader.shared.load(named: name, maxPixel: 120)
        }
    }
}

/// Aceptar / rechazar invitación abierta por `repera://invitation/{id}`.
private struct InvitationDeepLinkSheet: View {
    let invitationId: UUID?
    var onDone: () -> Void
    @Environment(BusinessDataStore.self) private var business
    @Environment(BusinessAuthStore.self) private var auth
    @State private var status = ""
    @State private var preview: BusinessInvitationPreview?

    private var invitation: BusinessInvitation? {
        guard let invitationId else { return nil }
        return business.invitations.first { $0.id == invitationId }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                if !auth.isConnected {
                    Text("Inicia sesión en Repera con el correo de la invitación para aceptar la vinculación.")
                        .foregroundStyle(OG.label2)
                } else if let invitation {
                    Text(preview?.organizationName ?? "Centro o entrenador")
                        .font(.title2.weight(.bold))
                    if let preview {
                        Text(preview.kindLabel)
                            .foregroundStyle(OG.label2)
                        if let tagline = preview.organizationTagline, !tagline.isEmpty {
                            Text(tagline)
                                .font(.subheadline)
                                .foregroundStyle(OG.label2)
                        }
                    }
                    Text("Al aceptar verás este centro en Ajustes, con tus clases, bonos y mensajes asociados.")
                        .font(.subheadline)
                        .foregroundStyle(OG.label2)
                    HStack(spacing: 12) {
                        Button("Aceptar vinculación") {
                            Task {
                                await business.accept(invitation)
                                status = "Vinculación aceptada. Abriendo Ajustes…"
                                onDone()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(OG.accent)
                        .disabled(business.isSubmitting)
                        Button("Rechazar", role: .destructive) {
                            Task {
                                await business.decline(invitation)
                                status = "Invitación rechazada."
                                onDone()
                            }
                        }
                        .disabled(business.isSubmitting)
                    }
                } else {
                    Text("Buscando invitación…")
                        .foregroundStyle(OG.label2)
                    Text("Si no aparece, inicia sesión con el correo invitado o pide un enlace nuevo.")
                        .font(.footnote)
                        .foregroundStyle(OG.label2)
                }
                if !status.isEmpty {
                    Text(status).foregroundStyle(OG.accent)
                }
                Spacer()
            }
            .padding(OG.pad)
            .navigationTitle("Aceptar centro")
            .navigationBarTitleDisplayMode(.inline)
            .task(id: invitationId) {
                guard let invitationId else { return }
                await business.refresh()
                preview = await business.loadInvitationPreview(id: invitationId)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar", action: onDone)
                }
            }
            .task {
                if auth.isConnected {
                    await business.refresh()
                }
            }
        }
        .ogSheetChrome(detents: [.medium])
    }
}
