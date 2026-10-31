import ReperaDomain
import SwiftUI
import UIKit

enum WorkoutFlowRoute: Hashable {
    case sessionPreview(routineId: UUID?)
    case editWorkout(routineId: UUID)
    case exerciseDetail(exerciseId: UUID)
    case workout
}

/// Menú principal: Inicio · Comenzar · Progreso · Ejercicios.
/// Las herramientas de Crear y los centros profesionales permanecen en sus secciones, no en el mapa de Comenzar.
struct RootTabView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var duoRail = OGDuoContextRailStore()
    @State private var lastAvailableSize: CGSize = .zero
    @State private var tab: AppTab = .home
    @State private var showStartHub = false
    @State private var sportFavoriteOpenError: String?
    @State private var homeFocusDay: Date?
    @State private var flowPath: [WorkoutFlowRoute] = []
    @State private var previewRoutine: Routine?

    enum AppTab: Hashable {
        case home, start, stats, exercises
    }

    var body: some View {
        ZStack {
            TabView(selection: $tab) {
                SwiftUI.Tab("Inicio", systemImage: "house", value: AppTab.home) {
                    HomeView(
                        onOpenWorkout: openWorkout,
                        focusDay: homeFocusDay,
                        onStart: openTodayPreview,
                        onStartRoutine: openRoutinePreview
                    )
                    .toolbar(duoRail.isExpanded ? .hidden : .visible, for: .tabBar)
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
                            // Un registro de Comenzar guardado también es un
                            // evento de refresco (fuera de la grabación activa).
                            store.requestExerciseCatalogRefresh()
                        },
                        onOpenWorkout: openWorkout
                    )
                    .toolbar(duoRail.isExpanded ? .hidden : .visible, for: .tabBar)
                }

                SwiftUI.Tab(
                    "Progreso",
                    systemImage: tab == .stats ? "chart.bar.fill" : "chart.bar",
                    value: AppTab.stats
                ) {
                    StatsView()
                        .toolbar(duoRail.isExpanded ? .hidden : .visible, for: .tabBar)
                }

                SwiftUI.Tab("Ejercicios", systemImage: "dumbbell", value: AppTab.exercises) {
                    LibraryView(onOpenedWorkout: openWorkout)
                        .toolbar(duoRail.isExpanded ? .hidden : .visible, for: .tabBar)
                }
            }
            // Observe Equatable chrome — not the full `activeSession` graph.
            // En Comenzar no se muestra Continuar de Live (ya estás ahí); sí el de Play.
            .tabBarMinimizeBehavior(continueModelForCurrentTab != nil ? .onScrollDown : .never)
            .modifier(ContinueAccessoryModifier(
                model: continueModelForCurrentTab,
                onContinue: {
                    if store.continueAccessory?.isLiveActivity == true {
                        flowPath = []
                        tab = .start
                    } else {
                        previewRoutine = nil
                        flowPath = [.sessionPreview(routineId: nil)]
                    }
                }
            ))
            // Los hijos publican sus acciones; la posición lateral pertenece al
            // TabView y no al contenido, cuya anchura excluye el menú nativo.
            .environment(duoRail)
            .toolbar(duoRail.isExpanded ? .hidden : .visible, for: .tabBar)
            // No medir TabView: en el Duo la barra nativa puede restarle
            // ancho y hacer que la medición baje de 480 pt.
            // Continuar también cuando hay Comenzar activo (LiveActivityRecorder).
            .onChange(of: LiveActivityRecorder.shared.phase) { _, phase in
                store.refreshContinueChrome()
                // Inicio desde Watch / grabación activa → mostrar Comenzar.
                if phase == .recording || phase == .paused
                    || (phase == .review && !store.isAutoSavingWatchActivity) {
                    // Una finalización en Watch guarda en segundo plano: no
                    // llevar al iPhone a una segunda pantalla de confirmación.
                    flowPath = []
                    tab = .start
                }
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

            if let root = flowPath.first {
                NavigationStack(path: flowTailBinding) {
                    flowDestination(root)
                        .navigationDestination(for: WorkoutFlowRoute.self) { route in
                            flowDestination(route)
                        }
                }
                .id(root)
                .transition(.move(edge: .trailing))
                .zIndex(1)
            }
        }
        // El raíl contextual y la navegación son UNA SOLA columna real.
        // safeAreaInset le reserva ancho exclusivo junto al contenido.
        // No superponer acciones a la toolbar ni al TabView nativo.
        .safeAreaInset(edge: .trailing, spacing: 0) {
            if duoRail.isExpanded {
                duoSidebar
            }
        }
        // Geometría del CONTENEDOR, no de la pestaña con ancho reducido.
        .onGeometryChange(for: CGSize.self, of: { $0.size }) { _, size in
            updateDuoLayout(availableSize: size)
        }
        .onChange(of: horizontalSizeClass) { _, _ in
            updateDuoLayout(availableSize: lastAvailableSize)
        }
        // onGeometryChange puede ejecutarse antes de asociar la UIWindow.
        // Reevaluar una vez ya montada evita quedar fijo en compacto.
        .onAppear {
            updateDuoLayout(availableSize: lastAvailableSize)
        }
        .sheet(isPresented: $showStartHub) {
            // The former Crear tab remains available from Inicio, without losing tools.
            StartHubSheet(
                onOpenedWorkout: {
                    showStartHub = false
                    openWorkout()
                },
                onOpenSport: { sportID in
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
                },
                onSavedTimer: { date in
                    // Misma transición que Comenzar: cerrar Crear, elegir Inicio
                    // y seleccionar el día de inicio del registro recién guardado.
                    homeFocusDay = date
                    flowPath = []
                    tab = .home
                    showStartHub = false
                }
            )
            .ogSheetChrome(detents: [.large])
        }
        .alert("No se ha podido abrir la actividad", isPresented: Binding(
            get: { sportFavoriteOpenError != nil },
            set: { if !$0 { sportFavoriteOpenError = nil } }
        )) {
            Button("Aceptar", role: .cancel) { sportFavoriteOpenError = nil }
        } message: {
            Text(sportFavoriteOpenError ?? "")
        }
        // Push/Pop should feel immediate; the former 320ms overlay animation
        // made switching sections look like an application reload.
        .animation(.easeOut(duration: 0.18), value: flowPath.isEmpty)
        .tint(OG.accent)
        .onChange(of: tab) { _, newTab in
            // Solo al entrar en Ejercicios, no mientras permanece abierta.
            // El refresco es incremental y evita peticiones sucesivas en <60 s.
            if newTab == .exercises { store.requestExerciseCatalogRefresh() }
        }
        .task(id: store.isHydrated) {
            // The route archive contains imported GPX and favorite flags
            // not included in ReperaStore's regular workout iCloud snapshot.
            // Migrate/download it without delaying the first Home frame.
            await LiveRoutesStore.shared.synchronizeWithICloud()
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.didBecomeActiveNotification
        )) { _ in
            LiveRoutesStore.shared.requestICloudSynchronization()
        }
        .task {
            // Nuevo proceso: volver a la pantalla real de grabación.
            // No reabrir Inicio ni iniciar un entrenamiento distinto.
            if store.state.activeSession != nil {
                flowPath = [.workout]
            } else if LiveActivityRecorder.shared.isActive {
                tab = .start
            }
        }
        .onOpenURL { url in
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
            default:
                break
            }
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
        // También para destinos del flujo, sheets y fichas abiertas fuera
        // del TabView (no solo para las cuatro pestañas).
        .environment(duoRail)
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

    /// Navegación y herramientas comparten EXACTAMENTE la misma columna.
    /// La pestaña nativa se oculta solo mientras está abierto el Duo.
    private var duoSidebar: some View {
        VStack(spacing: 0) {
            if !selectedDuoActions.isEmpty {
                OGDuoContextRail(actions: selectedDuoActions)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
            }

            Spacer(minLength: 18)

            VStack(spacing: 6) {
                duoTabButton(.home, symbol: "house", label: "Inicio")
                duoTabButton(.start, symbol: "play.circle.fill", label: "Comenzar")
                duoTabButton(.stats, symbol: "chart.bar.fill", label: "Progreso")
                duoTabButton(.exercises, symbol: "dumbbell", label: "Ejercicios")
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: Capsule())
        }
        .frame(width: 66)
        .frame(maxHeight: .infinity)
        .padding(.leading, 8)
        .padding(.trailing, 10)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(OG.bg.opacity(0.001))
        .accessibilityIdentifier("repera-duo-sidebar")
    }

    private func duoTabButton(
        _ target: AppTab,
        symbol: String,
        label: String
    ) -> some View {
        let isSelected = tab == target
        return Button {
            flowPath = []
            tab = target
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 23, weight: .semibold))
                .foregroundStyle(isSelected ? OG.accent : OG.label)
                .frame(width: 54, height: 54)
                .background {
                    if isSelected {
                        Circle().fill(OG.label.opacity(0.10))
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityIdentifier("repera-duo-tab-\(label)")
    }

    /// Mostrar únicamente los controles de la pestaña visible, aunque SwiftUI
    /// mantenga vivas otras pantallas del TabView por rendimiento.
    private var selectedDuoActions: [OGDuoContextRailStore.Action] {
        guard flowPath.isEmpty else { return [] }
        switch tab {
        case .start:
            return duoRail.owner == "start" ? duoRail.actions : []
        case .stats:
            return duoRail.owner == "stats" ? duoRail.actions : []
        case .exercises:
            return duoRail.owner == "exercises" || duoRail.owner == "exercise-detail"
                ? duoRail.actions : []
        case .home:
            return []
        }
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
