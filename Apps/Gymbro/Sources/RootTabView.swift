import GymbroDomain
import SwiftUI

enum WorkoutFlowRoute: Hashable {
    case sessionPreview(routineId: UUID?)
    case logFinalResults(routineId: UUID)
    case editWorkout(routineId: UUID)
    case workout
}

/// Menú principal: Inicio · Diario · + · Progreso · Ejercicios
struct RootTabView: View {
    @Environment(GymbroStore.self) private var store
    @State private var tab: AppTab = .home
    @State private var flowPath: [WorkoutFlowRoute] = []
    @State private var previewRoutine: Routine?

    enum AppTab: Hashable {
        case home, plan, create, stats, exercises
    }

    private var hasActiveWorkout: Bool {
        store.state.activeSession != nil
    }

    var body: some View {
        ZStack {
            TabView(selection: $tab) {
                SwiftUI.Tab("Inicio", systemImage: "house", value: AppTab.home) {
                    HomeView(
                        onOpenWorkout: openWorkout,
                        onStart: openTodayPreview,
                        onStartRoutine: openRoutinePreview,
                        onGoPlan: { tab = .plan },
                        onOpenStartHub: { tab = .create }
                    )
                }

                SwiftUI.Tab("Diario", systemImage: "calendar", value: AppTab.plan) {
                    PlanView()
                }

                SwiftUI.Tab("Crear", systemImage: "plus", value: AppTab.create) {
                    StartHubSheet(
                        onGoPlan: { tab = .plan },
                        onOpenedWorkout: openWorkout
                    )
                }

                SwiftUI.Tab("Progreso", systemImage: "chart.bar", value: AppTab.stats) {
                    StatsView()
                }

                SwiftUI.Tab("Ejercicios", systemImage: "dumbbell", value: AppTab.exercises) {
                    LibraryView(onOpenedWorkout: openWorkout)
                }
            }
            .tabBarMinimizeBehavior(hasActiveWorkout ? .onScrollDown : .never)
            .modifier(ContinueAccessoryModifier(
                session: store.state.activeSession,
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
        .animation(.easeInOut(duration: 0.32), value: flowPath.isEmpty)
        .preferredColorScheme(.dark)
        .tint(OG.accent)
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
                    previewRoutine = routine
                    flowPath.append(.logFinalResults(routineId: routine.id))
                },
                onEdit: { routine in
                    previewRoutine = routine
                    flowPath.append(.editWorkout(routineId: routine.id))
                }
            )
            .navigationBarBackButtonHidden(true)

        case .logFinalResults(let routineId):
            if let routine = resolvePreviewRoutine(id: routineId) {
                LogFinalResultsView(routine: routine, onSaved: { flowPath = [] })
                    .navigationBarBackButtonHidden(true)
            } else {
                Color.clear
                    .onAppear {
                        if !flowPath.isEmpty { flowPath.removeLast() }
                    }
            }

        case .editWorkout(let routineId):
            if let routine = resolvePreviewRoutine(id: routineId) {
                DayEditorView(
                    routine: routine,
                    mode: routine.isOneOff ? .oneOff(isNew: false) : .plan(isNew: false),
                    onClose: {
                        if !flowPath.isEmpty { flowPath.removeLast() }
                    },
                    embedsNavigationStack: false,
                    usesPageCloseHeader: true
                )
                .navigationBarBackButtonHidden(true)
            } else {
                Color.clear
                    .onAppear {
                        if !flowPath.isEmpty { flowPath.removeLast() }
                    }
            }

        case .workout:
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
        if store.state.activeSession != nil {
            previewRoutine = nil
            flowPath = [.sessionPreview(routineId: nil)]
            return
        }
        guard let today = store.routineForToday() else {
            tab = .create
            return
        }
        openRoutinePreview(today)
    }

    private func openRoutinePreview(_ routine: Routine) {
        previewRoutine = routine
        flowPath = [.sessionPreview(routineId: routine.id)]
    }
}

private struct ContinueAccessoryModifier: ViewModifier {
    var session: WorkoutSession?
    var onContinue: () -> Void

    func body(content: Content) -> some View {
        if let session {
            content.tabViewBottomAccessory {
                Button(action: onContinue) {
                    HStack(spacing: 12) {
                        if let current = session.currentExercise {
                            ExerciseThumb(exercise: current.exercise, size: 40)
                        } else {
                            ZStack {
                                Circle().fill(OG.accent.opacity(0.2))
                                Image(systemName: "play.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(OG.accent)
                            }
                            .frame(width: 40, height: 40)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Continuar")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(OG.label2)
                            Text(session.currentExercise?.exercise.name ?? session.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(OG.label)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 8)

                        Text(session.progressLabel)
                            .font(.system(size: 13, weight: .semibold).monospacedDigit())
                            .foregroundStyle(OG.accent)
                    }
                    .padding(.horizontal, OG.pad)
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Continuar \(session.currentExercise?.exercise.name ?? session.title)")
            }
        } else {
            content
        }
    }
}
