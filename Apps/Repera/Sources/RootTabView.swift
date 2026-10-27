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
                }

                SwiftUI.Tab("Comenzar", systemImage: "livephoto.play", value: AppTab.start) {
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
                }

                SwiftUI.Tab("Progreso", systemImage: "gauge", value: AppTab.stats) {
                    StatsView()
                }

                SwiftUI.Tab("Ejercicios", systemImage: "dumbbell", value: AppTab.exercises) {
                    LibraryView(onOpenedWorkout: openWorkout)
                }
            }
            // Observe Equatable chrome — not the full `activeSession` graph.
            .tabBarMinimizeBehavior(store.hasActiveSession ? .onScrollDown : .never)
            .modifier(ContinueAccessoryModifier(
                model: store.continueAccessory,
                onContinue: {
                    previewRoutine = nil
                    flowPath = [.sessionPreview(routineId: nil)]
                }
            ))

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
                Button(action: onContinue) {
                    HStack(spacing: 12) {
                        ContinueAccessoryThumb(name: model.thumbName)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Continuar")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(OG.label2)
                            Text(model.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(OG.label)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 8)

                        Text(model.progressLabel)
                            .font(.system(size: 13, weight: .semibold).monospacedDigit())
                            .foregroundStyle(OG.accent)
                    }
                    .padding(.horizontal, OG.pad)
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Continuar \(model.title)")
            }
        } else {
            content
        }
    }
}

private struct ContinueAccessoryThumb: View {
    var name: String?
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                ZStack {
                    Circle().fill(OG.accent.opacity(0.2))
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(OG.accent)
                }
                .frame(width: 40, height: 40)
            }
        }
        .task(id: name) {
            guard let name else {
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
