import ReperaDomain
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
                        HStack(spacing: 12) {
                            Text("Tiempo")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(OG.label2)
                                .frame(width: 88, alignment: .leading)
                            OGRepeatStepper(
                                display: DurationText.format(elapsedSeconds),
                                keyboard: .numbersAndPunctuation,
                                onMinus: { elapsedSeconds = max(0, elapsedSeconds - 5) },
                                onPlus: { elapsedSeconds = min(180 * 60, elapsedSeconds + 5) },
                                onCommitText: { text in
                                    if let parsed = DurationText.parse(text) {
                                        elapsedSeconds = min(180 * 60, parsed)
                                    }
                                }
                            )
                        }
                    } header: {
                        Text("Resultado")
                    } footer: {
                        Text("Formato m:ss. Puedes ajustar si paraste el reloj tarde o pronto.")
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
        .ogSheetChrome(detents: [.medium, .large])
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
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(OG.label2)
                .frame(width: 88, alignment: .leading)
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
