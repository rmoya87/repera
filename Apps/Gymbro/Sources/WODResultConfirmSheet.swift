import GymbroDomain
import SwiftUI

/// Confirmación editable del score tras play (AMRAP reps / For Time tiempo).
struct WODResultConfirmSheet: View {
    var title: String
    var capture: WODResultCapture
    @Binding var totalReps: Int
    @Binding var elapsedSeconds: Int
    @Binding var roundsCompleted: Int
    var onSave: () -> Void
    var onCancel: () -> Void

    private var minutes: Binding<Int> {
        Binding(
            get: { elapsedSeconds / 60 },
            set: { elapsedSeconds = max(0, $0) * 60 + (elapsedSeconds % 60) }
        )
    }

    private var seconds: Binding<Int> {
        Binding(
            get: { elapsedSeconds % 60 },
            set: { elapsedSeconds = (elapsedSeconds / 60) * 60 + min(59, max(0, $0)) }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(OG.label)
                }

                if capture == .totalReps {
                    Section {
                        labeledIntStepper(title: "Rondas", value: $roundsCompleted, range: 0...200, step: 1)
                        labeledIntStepper(title: "Reps", value: $totalReps, range: 0...5000, step: 1)
                    } header: {
                        Text("Resultado")
                    } footer: {
                        Text("AMRAP: rondas completas + reps de la ronda que no terminaste (p. ej. 12 + 5).")
                    }
                } else if capture == .elapsedTime {
                    Section {
                        labeledIntStepper(title: "Minutos", value: minutes, range: 0...180, step: 1)
                        labeledIntStepper(title: "Segundos", value: seconds, range: 0...59, step: 1)
                        Text(DurationText.format(elapsedSeconds))
                            .font(.system(size: 22, weight: .bold).monospacedDigit())
                            .foregroundStyle(OG.accent)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 4)
                    } header: {
                        Text("Tiempo")
                    } footer: {
                        Text("Puedes ajustar el tiempo si paraste el reloj tarde o pronto.")
                    }
                } else {
                    Section {
                        Text("Este formato se apunta por series.")
                            .foregroundStyle(OG.label2)
                    }
                }
            }
            .ogListChrome()
            .navigationTitle("Confirmar resultado")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        onSave()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var canSave: Bool {
        switch capture {
        case .totalReps:
            return totalReps > 0 || roundsCompleted > 0
        case .elapsedTime:
            return elapsedSeconds > 0
        case .perMovementSets:
            return true
        }
    }

    private func labeledIntStepper(
        title: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        step: Int
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(OG.label2)
                .frame(width: 110, alignment: .leading)
            OGRepeatStepper(
                display: "\(value.wrappedValue)",
                keyboard: .numberPad,
                onMinus: { value.wrappedValue = max(range.lowerBound, value.wrappedValue - step) },
                onPlus: { value.wrappedValue = min(range.upperBound, value.wrappedValue + step) },
                onCommitText: { text in
                    if let parsed = Int(text.filter(\.isNumber)) {
                        value.wrappedValue = min(range.upperBound, max(range.lowerBound, parsed))
                    }
                }
            )
        }
    }
}
