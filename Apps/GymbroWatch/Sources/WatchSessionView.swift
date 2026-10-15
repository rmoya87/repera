import GymbroDomain
import SwiftUI

struct WatchSessionView: View {
    @Environment(WatchSessionHub.self) private var hub

    var body: some View {
        Group {
            if let session = hub.controller?.session {
                activeView(session)
            } else {
                ContentUnavailableView(
                    "Sin sesión",
                    systemImage: "iphone.and.arrow.forward",
                    description: Text("Inicia la sesión en el iPhone.")
                )
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
        }
        .padding()
    }

    private func countingView(_ session: WorkoutSession) -> some View {
        VStack(spacing: 8) {
            Text(session.currentExercise?.exercise.name ?? "—")
                .font(.caption)
                .multilineTextAlignment(.center)
            Text("\(session.currentExercise?.completedReps ?? 0)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text("reps")
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack {
                Button { hub.adjustReps(-1) } label: {
                    Image(systemName: "minus.circle.fill")
                }
                Button { hub.adjustReps(1) } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
            .font(.title2)

            Button {
                hub.finishCurrent()
            } label: {
                Text("Terminé")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
