import ReperaDomain
import SwiftUI
import UIKit

enum WorkoutFlowRoute: Hashable {
    case sessionPreview(routineId: UUID?)
    case logFinalResults(routineId: UUID)
    case editWorkout(routineId: UUID)
    case workout
}

/// Menú principal: Inicio · Diario · Crear|Center · Progreso · Ejercicios.
/// Center solo si el atleta está vinculado a un gimnasio/entrenador (o tiene invitación).
struct RootTabView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(BusinessDataStore.self) private var businessData
    @State private var tab: AppTab = .home
    @State private var planSection: DiarioSection = .schedule
    @State private var showStartHub = false
    @State private var flowPath: [WorkoutFlowRoute] = []
    @State private var previewRoutine: Routine?

    enum AppTab: Hashable {
        case home, plan, center, stats, exercises
    }

    /// Gimnasio/entrenador vinculado o invitación pendiente → pestaña Center; si no, Crear.
    private var showsCenterTab: Bool {
        !businessData.centers.isEmpty || !businessData.invitations.isEmpty
    }

    var body: some View {
        ZStack {
            TabView(selection: $tab) {
                SwiftUI.Tab("Inicio", systemImage: "house", value: AppTab.home) {
                    HomeView(
                        onOpenWorkout: openWorkout,
                        onStart: openTodayPreview,
                        onStartRoutine: openRoutinePreview,
                        onGoPlan: { planSection = .schedule; tab = .plan }
                    )
                }

                SwiftUI.Tab("Diario", systemImage: "calendar", value: AppTab.plan) {
                    PlanView(section: $planSection, onOpenRoutine: openRoutinePreview)
                }

                if showsCenterTab {
                    SwiftUI.Tab("Center", systemImage: "building.2", value: AppTab.center) {
                        CenterView()
                    }
                } else {
                    SwiftUI.Tab("Crear", systemImage: "plus.circle", value: AppTab.center) {
                        StartHubSheet(
                            onGoPlan: { planSection = .schedule; tab = .plan },
                            onOpenedWorkout: openWorkout
                        )
                    }
                }

                SwiftUI.Tab("Progreso", systemImage: "chart.bar", value: AppTab.stats) {
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
                onGoPlan: {
                    showStartHub = false
                    planSection = .schedule
                    tab = .plan
                },
                onOpenedWorkout: {
                    showStartHub = false
                    openWorkout()
                }
            )
            .ogSheetChrome(detents: [.large])
        }
        .animation(.easeInOut(duration: 0.32), value: flowPath.isEmpty)
        .tint(OG.accent)
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
                onLogResults: { routine in
                    // Apuntar comparte exactamente la misma sesión y tabla que ▶ Comenzar.
                    previewRoutine = routine
                    store.startSession(from: routine)
                    openWorkout()
                },
                onEdit: { routine in
                    previewRoutine = routine
                    flowPath.append(.editWorkout(routineId: routine.id))
                }
            )
            .navigationBarBackButtonHidden(true)

        case .logFinalResults(let routineId):
            // Nested route: keep system back gesture into the session preview.
            if let routine = resolvePreviewRoutine(id: routineId) {
                WorkoutManageView(
                    routine: routine,
                    initialMode: .results,
                    onEditSaved: { if !flowPath.isEmpty { flowPath.removeLast() } },
                    onResultsSaved: { flowPath = [.workout] }
                )
            } else {
                Color.clear
                    .onAppear {
                        if !flowPath.isEmpty { flowPath.removeLast() }
                    }
            }

        case .editWorkout(let routineId):
            if let routine = resolvePreviewRoutine(id: routineId) {
                WorkoutManageView(
                    routine: routine,
                    initialMode: .edit,
                    onEditSaved: { if !flowPath.isEmpty { flowPath.removeLast() } },
                    onResultsSaved: { flowPath = [] }
                )
            } else {
                Color.clear
                    .onAppear {
                        if !flowPath.isEmpty { flowPath.removeLast() }
                    }
            }

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
        previewRoutine = routine
        flowPath = [.sessionPreview(routineId: routine.id)]
    }
}


enum WorkoutManageMode: String, CaseIterable, Identifiable {
    case edit
    case results

    var id: String { rawValue }
    var title: String { self == .edit ? "Editar" : "Apuntar" }
}

/// Ambas acciones usan una misma pantalla, sin navegar entre dos flujos diferentes.
private struct WorkoutManageView: View {
    var routine: Routine
    var initialMode: WorkoutManageMode
    var onEditSaved: () -> Void
    var onResultsSaved: () -> Void

    @State private var mode: WorkoutManageMode
    @Environment(ReperaStore.self) private var store

    init(
        routine: Routine,
        initialMode: WorkoutManageMode,
        onEditSaved: @escaping () -> Void,
        onResultsSaved: @escaping () -> Void
    ) {
        self.routine = routine
        self.initialMode = initialMode
        self.onEditSaved = onEditSaved
        self.onResultsSaved = onResultsSaved
        _mode = State(initialValue: initialMode)
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Gestión de entreno", selection: $mode) {
                ForEach(WorkoutManageMode.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, OG.pad)
            .padding(.top, 8)
            .padding(.bottom, 4)

            Group {
                switch mode {
                case .edit:
                    DayEditorView(
                        routine: routine,
                        mode: routine.isOneOff ? .oneOff(isNew: false) : .plan(isNew: false),
                        onClose: onEditSaved,
                        embedsNavigationStack: false,
                        usesPageCloseHeader: true
                    )
                case .results:
                    ProgressView("Preparando registro…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .background(OG.bg)
        .onChange(of: mode) { _, newMode in
            guard newMode == .results else { return }
            store.startSession(from: routine)
            onResultsSaved()
        }
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
