import ReperaDomain
import SwiftUI
import UIKit

/// Único punto de validación de los enlaces `repera://` (widgets, Live Activity,
/// invitaciones). Cualquier esquema, host o ruta no reconocidos se ignoran.
enum ReperaDeepLink: Equatable {
    case live
    case workout
    case today
    case tools
    case exercises
    case boardScan
    case shareImport
    case invitation(UUID)

    static let scheme = "repera"

    init?(url: URL) {
        guard url.scheme?.lowercased() == Self.scheme,
              url.user == nil, url.password == nil, url.port == nil,
              let host = url.host(percentEncoded: false)?.lowercased() else { return nil }
        let path = url.pathComponents.filter { $0 != "/" }
        switch (host, path.count) {
        case ("live", 0): self = .live
        case ("workout", 0): self = .workout
        case ("today", 0): self = .today
        case ("tools", 0): self = .tools
        case ("exercises", 0): self = .exercises
        case ("board", 0), ("boardscan", 0): self = .boardScan
        case ("import", 0): self = .shareImport
        case ("invitation", 1):
            guard let id = UUID(uuidString: path[0]) else { return nil }
            self = .invitation(id)
        default:
            return nil
        }
    }
}

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
    @State private var showBoardScanFromSystem = false
    @State private var pendingSharedBoardImage: Data?

    enum AppTab: Hashable {
        case home, start, plus, stats, exercises
    }

    /// La sección de clases/centro solo existe tras una vinculación real,
    /// nunca por una invitación pendiente o por una cuenta profesional sin cliente.
    private var hasLinkedCenter: Bool { !businessData.athleteCenterIds.isEmpty }

    /// Focus Filter can silence Center chrome while a Focus mode is active.
    private var showsCenterTab: Bool {
        hasLinkedCenter && !ReperaFocusPreferences.silenceCenter
    }

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
        .onAppear {
            updateDuoLayout(availableSize: lastAvailableSize)
            let initialScreen: String = switch tab {
            case .home: "home"
            case .start: "start"
            case .plus: "center"
            case .stats: "progress"
            case .exercises: "exercises"
            }
            ReperaAnalytics.track(.screenView, parameters: ["screen_name": initialScreen])
        }
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
            let screen: String = switch newTab {
            case .home: "home"
            case .start: "start"
            case .plus: "center"
            case .stats: "progress"
            case .exercises: "exercises"
            }
            ReperaAnalytics.track(.screenView, parameters: ["screen_name": screen])
            ReperaAnalytics.track(.uiInteraction, parameters: [
                "feature_area": "home",
                "interaction_type": "selection",
                "component_id": "tab_bar",
                "action_name": "select",
                "screen_name": screen,
                "result": "success"
            ])
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
        .task {
            restoreActiveSessionOnLaunch()
            openPendingWatchLiveReviewNotification()
            openPendingSystemCommand()
            LiveActivityPushTokenStore.startObservingIfNeeded()
            drainShareInboxIfReady()
        }
        .onReceive(NotificationCenter.default.publisher(for: .reperaRestRemote)) { note in
            guard let action = note.object as? RestRemoteAction else { return }
            switch action {
            case .pause: store.restCoordinator.pause()
            case .resume: store.restCoordinator.resume()
            case .skip: store.restCoordinator.skip()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: ShareInboxConsumer.boardImageReady)) { _ in
            openBoardScanFromShare()
        }
        .onReceive(NotificationCenter.default.publisher(for: ReperaFocusPreferences.didChange)) { _ in
            if ReperaFocusPreferences.silenceCenter, tab == .plus {
                tab = store.hasActiveSession ? .start : .home
            }
        }
        .sheet(isPresented: $showBoardScanFromSystem) {
            BoardScanIntoRoutineView { _ in
                showBoardScanFromSystem = false
                pendingSharedBoardImage = nil
            }
        }
        .task(id: store.isHydrated) {
            if store.isHydrated {
                openPendingSystemCommand()
                applyPendingLiveActivityCommand()
                drainShareInboxIfReady()
            }
        }
        .task(id: store.catalogEpoch) {
            guard store.isHydrated, !store.state.exercises.isEmpty else { return }
            ExerciseSpotlightIndexer.indexPublicExercises(store.state.exercises)
            // Spotlight may wake a freshly installed app before its catalog is
            // hydrated. Consume its pending target only once the catalog exists.
            openPendingSystemCommand()
        }
        .onReceive(NotificationCenter.default.publisher(for: ReperaSystemCommand.notification)) { _ in
            openPendingSystemCommand()
        }
        .onReceive(NotificationCenter.default.publisher(for: TrainingLiveActivityCommand.notification)) { _ in
            applyPendingLiveActivityCommand()
        }
        .onOpenURL(perform: handleOpenURL)
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
            // Focus Filter puede silenciar Center sin romper Ajustes → Buscar.
            if showsCenterTab {
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
            if LiveActivityRecorder.shared.phase == .review {
                UserDefaults.standard.removeObject(
                    forKey: WorkoutCompletionNotifier.pendingLiveReviewKey
                )
            }
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

    private func openPendingWatchLiveReviewNotification() {
        guard let raw = UserDefaults.standard.string(
            forKey: WorkoutCompletionNotifier.pendingLiveReviewKey
        ), let id = UUID(uuidString: raw) else { return }
        defer {
            UserDefaults.standard.removeObject(
                forKey: WorkoutCompletionNotifier.pendingLiveReviewKey
            )
        }
        guard LiveActivityRecorder.shared.sessionID == id,
              LiveActivityRecorder.shared.phase == .review else { return }
        flowPath = []
        tab = .start
    }

    private func openPendingSystemCommand() {
        guard store.isHydrated else { return }
        if !store.state.exercises.isEmpty,
           let exerciseID = ReperaSystemCommand.takePendingExercise(),
           store.state.exercises.contains(where: {
               $0.id == exerciseID && !$0.isCustom && !$0.isCatalogArchived
           }) {
            flowPath = [.exerciseDetail(exerciseId: exerciseID)]
            tab = .exercises
            return
        }
        guard let destination = ReperaSystemCommand.takePending() else { return }
        switch destination {
        case .today:
            flowPath = []
            tab = .home
            openTodayPreview()
        case .live:
            flowPath = []
            tab = .start
        case .tools:
            flowPath = []
            tab = .home
            showStartHub = true
        case .exercises:
            flowPath = []
            tab = .exercises
        case .boardScan:
            openBoardScanFromSystem()
        }
    }

    private func drainShareInboxIfReady() {
        guard store.isHydrated else { return }
        ShareInboxConsumer.drain()
    }

    /// “Abrir con Repera” / Files document handoff (GPX or board image).
    private func ingestOpenedDocument(_ url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else { return }
        let name = url.lastPathComponent
        let ext = url.pathExtension.lowercased()
        let kind: ReperaShareInbox.Kind? =
            if name.lowercased().hasSuffix(".gpx") || ext == "gpx" { .gpx }
            else if ["jpg", "jpeg", "png", "heic", "webp"].contains(ext) { .boardImage }
            else { ReperaShareInbox.kind(for: "public.data", fileName: name) }
        guard let kind else { return }
        _ = try? ReperaShareInbox.enqueue(data: data, kind: kind, fileName: name)
        if store.isHydrated {
            drainShareInboxIfReady()
            if kind == .boardImage { openBoardScanFromShare() }
            else { tab = .start }
        }
    }

    private func openBoardScanFromSystem() {
        flowPath = []
        tab = .home
        showBoardScanFromSystem = true
    }

    private func openBoardScanFromShare() {
        pendingSharedBoardImage = ShareInboxConsumer.pendingBoardImageData()
        openBoardScanFromSystem()
    }

    /// Applies Live Activity / Dynamic Island actions after identity hydration.
    /// Pause/resume never invent GPS samples; openSession never auto-confirms sets.
    private func applyPendingLiveActivityCommand() {
        guard store.isHydrated else { return }
        guard let action = TrainingLiveActivityCommand.takePending() else { return }
        switch action {
        case .pause:
            LiveActivityRecorder.shared.pause()
            flowPath = []
            tab = .start
        case .resume:
            LiveActivityRecorder.shared.resume()
            flowPath = []
            tab = .start
        case .openSession:
            flowPath = []
            if store.hasActiveSession {
                openWorkout()
            } else {
                tab = .start
            }
        }
    }

    private func handleOpenURL(_ url: URL) {
        if url.isFileURL {
            ingestOpenedDocument(url)
            return
        }
        guard let link = ReperaDeepLink(url: url) else { return }
        switch link {
        case .live:
            flowPath = []
            tab = .start
        case .workout:
            if store.hasActiveSession {
                openWorkout()
            } else {
                flowPath = []
                tab = .home
            }
        case .today:
            flowPath = []
            tab = .home
            openTodayPreview()
        case .tools:
            flowPath = []
            tab = .home
            showStartHub = true
        case .exercises:
            flowPath = []
            tab = .exercises
        case .boardScan:
            openBoardScanFromSystem()
        case .shareImport:
            drainShareInboxIfReady()
        case .invitation(let id):
            pendingInvitationId = id
            showInvitationSheet = true
            tab = .home
            NotificationCenter.default.post(
                name: Notification.Name("repera.openSettingsForInvitation"),
                object: id
            )
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
                        .font((isInline ? Font.caption2 : .caption).weight(.medium))
                        .foregroundStyle(OG.label2)
                    Text(model.title)
                        .ogFont(isInline ? 14 : 16, weight: .semibold, relativeTo: .subheadline)
                        .foregroundStyle(OG.label)
                        .lineLimit(1)
                }
                Spacer(minLength: 6)
                if model.isLiveActivity,
                   model.paceLabel != nil || model.distanceLabel != nil {
                    // Mismas métricas en expandido y comprimido: duración + ritmo + distancia.
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(model.progressLabel)
                            .font((isInline ? Font.caption : .footnote).weight(.semibold).monospacedDigit())
                        HStack(spacing: 6) {
                            if let pace = model.paceLabel {
                                Text(pace)
                            }
                            if let distance = model.distanceLabel {
                                Text(distance)
                            }
                        }
                        .font((isInline ? Font.caption2 : .caption).weight(.semibold).monospacedDigit())
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(OG.orange)
                } else {
                    Text(model.progressLabel)
                        .font((isInline ? Font.caption : .footnote).weight(.semibold).monospacedDigit())
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
        // El accesorio de la barra de pestañas tiene alto fijo del sistema.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
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
/// Nunca se queda «buscando»: tras refrescar distingue sesión, red y validez.
private struct InvitationDeepLinkSheet: View {
    let invitationId: UUID?
    var onDone: () -> Void
    @Environment(BusinessDataStore.self) private var business
    @Environment(BusinessAuthStore.self) private var auth
    @State private var phase: Phase = .loading
    @State private var preview: BusinessInvitationPreview?
    @State private var actionError: String?

    private enum Phase: Equatable {
        case loading
        case found
        case signedOut
        case unreachable
        case unavailable(Unavailability)
    }

    private enum Unavailability: Equatable {
        case notFound, expired, alreadyAccepted, cancelled
    }

    private var invitation: BusinessInvitation? {
        guard let invitationId else { return nil }
        return business.invitations.first { $0.id == invitationId }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            OGPageHeader(title: "Invitación") {
                CloseToolbarButton(action: onDone)
            }
            content
        }
        .padding(.horizontal, OG.pad)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ogFittedHeight()
        .ogFittedSheet()
        .task(id: invitationId) { await lookUp() }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .loading:
            HStack(spacing: 12) {
                ProgressView().tint(OG.accent)
                Text("Buscando invitación…")
                    .foregroundStyle(OG.label2)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        case .found:
            if let invitation {
                foundContent(invitation)
            }
        case .signedOut:
            stateMessage(
                title: "Inicia sesión para continuar",
                systemImage: "person.crop.circle.badge.exclamationmark",
                message: "Entra en Repera con el correo al que llegó la invitación. Después podrás aceptarla."
            )
            primaryButton("Iniciar sesión") {
                onDone()
                NotificationCenter.default.post(
                    name: Notification.Name("repera.openSettingsForInvitation"),
                    object: invitationId
                )
            }
            secondaryButton("Reintentar") { Task { await lookUp() } }
        case .unreachable:
            stateMessage(
                title: "No se ha podido comprobar la invitación",
                systemImage: "wifi.exclamationmark",
                message: "Revisa tu conexión a internet e inténtalo de nuevo."
            )
            primaryButton("Reintentar") { Task { await lookUp() } }
            secondaryButton("Cerrar", action: onDone)
        case .unavailable(let reason):
            stateMessage(
                title: reason == .alreadyAccepted ? "Invitación ya aceptada" : "Invitación no disponible",
                systemImage: reason == .alreadyAccepted ? "checkmark.circle" : "envelope.badge",
                message: Self.message(for: reason)
            )
            primaryButton("Cerrar", action: onDone)
            if reason == .notFound {
                secondaryButton("Reintentar") { Task { await lookUp() } }
            }
        }
    }

    @ViewBuilder
    private func foundContent(_ invitation: BusinessInvitation) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(preview?.organizationName ?? "Centro o entrenador")
                .font(.title2.weight(.bold))
                .foregroundStyle(OG.label)
            if let preview {
                Text(preview.kindLabel)
                    .font(.subheadline)
                    .foregroundStyle(OG.label2)
                if let tagline = preview.organizationTagline, !tagline.isEmpty {
                    Text(tagline)
                        .font(.subheadline)
                        .foregroundStyle(OG.label2)
                }
            }
            if let expires = BusinessDataStore.date(invitation.expiresAt) {
                Text("Caduca el \(SpanishDate.format(expires, date: .abbreviated, time: .omitted))")
                    .font(.footnote)
                    .foregroundStyle(OG.label3)
            }
        }
        Text("Al aceptar verás este centro en Ajustes, con tus clases, bonos y mensajes asociados. Tu historial personal no se comparte.")
            .font(.subheadline)
            .foregroundStyle(OG.label2)
            .fixedSize(horizontal: false, vertical: true)
        if let actionError {
            Label(actionError, systemImage: "exclamationmark.triangle.fill")
                .font(.footnote)
                .foregroundStyle(OG.red)
                .fixedSize(horizontal: false, vertical: true)
        }
        primaryButton(business.isSubmitting ? "Aceptando…" : "Aceptar vinculación") {
            Task { await accept(invitation) }
        }
        .disabled(business.isSubmitting)
        Button(role: .destructive) {
            Task { await decline(invitation) }
        } label: {
            Text("Rechazar")
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .disabled(business.isSubmitting)
    }

    private func stateMessage(title: String, systemImage: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(OG.label)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(OG.label2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.borderedProminent)
        .tint(OG.accent)
        .foregroundStyle(.black)
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .tint(OG.label)
    }

    private static func message(for reason: Unavailability) -> String {
        switch reason {
        case .expired:
            "Esta invitación ha caducado. Pide a tu centro o entrenador que te envíe un enlace nuevo."
        case .alreadyAccepted:
            "Ya estás vinculado con este centro. Lo encontrarás en Ajustes."
        case .cancelled:
            "El centro ha cancelado esta invitación. Si es un error, pídele un enlace nuevo."
        case .notFound:
            "No encontramos esta invitación en tu cuenta. Puede haber caducado o estar dirigida a otro correo."
        }
    }

    private func lookUp() async {
        phase = .loading
        actionError = nil
        guard let invitationId else {
            phase = .unavailable(.notFound)
            return
        }
        if !auth.isConnected {
            await auth.restoreSession()
            if !auth.isConnected {
                _ = auth.connectFromCachedSessionIfPossible()
            }
        }
        guard auth.isConnected else {
            phase = .signedOut
            return
        }
        // `refresh()` no espera a otra carga en curso (p. ej. la del arranque).
        var waited = 0
        while business.isLoading && waited < 75 && !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(200))
            waited += 1
        }
        await business.refresh()
        guard !Task.isCancelled else { return }
        guard auth.isConnected else {
            phase = .signedOut
            return
        }
        guard let invitation else {
            phase = business.errorMessage == nil ? .unavailable(.notFound) : .unreachable
            return
        }
        if invitation.acceptedAt != nil {
            phase = .unavailable(.alreadyAccepted)
        } else if invitation.cancelledAt != nil {
            phase = .unavailable(.cancelled)
        } else if let expires = BusinessDataStore.date(invitation.expiresAt), expires <= Date() {
            phase = .unavailable(.expired)
        } else {
            preview = await business.loadInvitationPreview(id: invitationId)
            phase = .found
        }
    }

    private func accept(_ invitation: BusinessInvitation) async {
        actionError = nil
        await business.accept(invitation)
        if let message = business.errorMessage, message.hasPrefix("No se ha podido aceptar") {
            actionError = message
        } else {
            onDone()
        }
    }

    private func decline(_ invitation: BusinessInvitation) async {
        actionError = nil
        await business.decline(invitation)
        if business.invitations.contains(where: { $0.id == invitation.id }) {
            actionError = business.errorMessage ?? "No se ha podido rechazar la invitación. Inténtalo de nuevo."
        } else {
            onDone()
        }
    }
}
