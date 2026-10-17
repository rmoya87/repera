import GymbroDomain
import SwiftUI
import WatchConnectivity

struct WatchSessionView: View {
    @Environment(WatchSessionHub.self) private var hub

    var body: some View {
        Group {
            if let session = hub.controller?.session {
                activeView(session)
            } else {
                idleQuickLogView
            }
        }
    }

    private var idleQuickLogView: some View {
        VStack(spacing: 10) {
            Image(systemName: "list.number")
                .font(.title2)
            Text("Apuntar serie")
                .font(.headline)
            if let name = hub.quickLogName {
                Text(name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Usa el último ejercicio del iPhone")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button {
                hub.startQuickLog()
            } label: {
                Text("Iniciar en iPhone")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            Button {
                hub.logQuickSet()
            } label: {
                Text("+1 serie")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityHint("Envía la serie al iPhone si está conectado")
        }
        .padding()
        .overlay(alignment: .top) {
            if !WCSession.default.isReachable {
                Text("iPhone no alcanzable")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .accessibilityLabel("Conectividad: iPhone no alcanzable")
            }
        }
    }

    @ViewBuilder
    private func activeView(_ session: WorkoutSession) -> some View {
        switch session.phase {
        case .finished:
            VStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.largeTitle)
                Text("Sesión hecha")
                    .font(.headline)
            }
        case .idle, .ready:
            readyView(session)
        case .counting:
            countingView(session)
        }
    }

    private func readyView(_ session: WorkoutSession) -> some View {
        VStack(spacing: 10) {
            Text(session.progressLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(session.currentExercise?.exercise.name ?? "—")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(session.currentExercise?.exercise.muscleGroup ?? "")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Button {
                hub.confirmCurrent()
            } label: {
                Text("Estoy en este")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)

            Button {
                hub.logQuickSet()
            } label: {
                Text("+1 serie")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private func countingView(_ session: WorkoutSession) -> some View {
        let reps = session.currentExercise?.completedReps ?? 0
        return VStack(spacing: 8) {
            Text(session.currentExercise?.exercise.name ?? "—")
                .font(.caption)
                .multilineTextAlignment(.center)
            Text("\(reps)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .focusable(true)
                .digitalCrownRotation(
                    Binding(
                        get: { Double(reps) },
                        set: { newValue in
                            let target = max(0, Int(newValue.rounded()))
                            let delta = target - reps
                            if delta != 0 {
                                hub.adjustReps(delta)
                            }
                        }
                    ),
                    from: 0,
                    through: 99,
                    by: 1,
                    sensitivity: .medium,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true
                )
                .accessibilityLabel("Repeticiones")
                .accessibilityValue("\(reps)")
            Text("reps")
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack {
                Button { hub.adjustReps(-1) } label: {
                    Image(systemName: "minus.circle.fill")
                }
                .accessibilityLabel("Quitar repetición")
                Button { hub.adjustReps(1) } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel("Añadir repetición")
            }
            .font(.title2)

            Button {
                hub.logQuickSet()
            } label: {
                Text("+1 serie")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityHint("Registra una serie con las repeticiones actuales")

            Button {
                hub.finishCurrent()
            } label: {
                Text("Terminé")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .sensoryFeedback(.selection, trigger: reps)
    }
}
