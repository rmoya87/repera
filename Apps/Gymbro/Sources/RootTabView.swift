import GymbroDomain
import SwiftUI

/// Menú principal: Inicio · Diario · + · Progreso · Ejercicios
struct RootTabView: View {
    @Environment(GymbroStore.self) private var store
    @State private var tab: AppTab = .home
    @State private var goWorkout = false
    @State private var showSessionPreview = false
    @State private var previewRoutine: Routine?

    enum AppTab: Hashable {
        case home, plan, create, stats, exercises
    }

    var body: some View {
        TabView(selection: $tab) {
            SwiftUI.Tab("Inicio", systemImage: "house", value: AppTab.home) {
                HomeView(
                    onOpenWorkout: { goWorkout = true },
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
                    onOpenedWorkout: { goWorkout = true }
                )
            }

            SwiftUI.Tab("Progreso", systemImage: "chart.bar", value: AppTab.stats) {
                StatsView()
            }

            SwiftUI.Tab("Ejercicios", systemImage: "dumbbell", value: AppTab.exercises) {
                LibraryView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .modifier(ContinueAccessoryModifier(
            session: store.state.activeSession,
            onContinue: {
                previewRoutine = nil
                showSessionPreview = true
            }
        ))
        .sheet(isPresented: $showSessionPreview, onDismiss: { previewRoutine = nil }) {
            SessionPreviewView(
                routine: previewRoutine ?? store.routineForToday(),
                onStart: { goWorkout = true },
                onContinue: { goWorkout = true }
            )
            .presentationDetents([.large])
        }
        .fullScreenCover(isPresented: $goWorkout) {
            NavigationStack {
                WorkoutView()
            }
            .preferredColorScheme(.dark)
        }
        .preferredColorScheme(.dark)
        .tint(OG.accent)
    }

    private func openTodayPreview() {
        if store.state.activeSession != nil {
            previewRoutine = nil
            showSessionPreview = true
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
        showSessionPreview = true
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
                    .padding(.leading, OG.pad)
                    .padding(.trailing, OG.pad)
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
