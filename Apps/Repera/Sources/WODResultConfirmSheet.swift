import ReperaDomain
import SwiftUI

/// Score después del reloj: sheet compacto, fondo de modal y altura intrínseca.
struct WODResultConfirmSheet: View {
    var title: String
    var capture: WODResultCapture
    @Binding var totalReps: Int
    @Binding var elapsedSeconds: Int
    @Binding var roundsCompleted: Int
    var onSave: () -> Void
    var onCancel: () -> Void

    @State private var roundsText = ""
    @State private var repsText = ""
    @State private var timeText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Confirmar resultado")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(OG.label)
                    Text(title)
                        .font(.system(size: 14))
                        .foregroundStyle(OG.label2)
                }
                Spacer(minLength: 8)
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(OG.label2)
                        .frame(width: 34, height: 34)
                        .background(OG.surface2, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cancelar")
            }

            if capture == .totalReps {
                HStack(spacing: 12) {
                    numberInput("Rondas", text: $roundsText)
                    numberInput("Repeticiones", text: $repsText)
                }
                Text("Rondas completas y repeticiones de la última ronda.")
                    .font(.footnote)
                    .foregroundStyle(OG.label2)
                    .fixedSize(horizontal: false, vertical: true)
            } else if capture == .elapsedTime {
                numberInput("Tiempo · m:ss", text: $timeText, allowsTime: true)
                Text("Puedes ajustar el tiempo si paraste el reloj tarde o pronto.")
                    .font(.footnote)
                    .foregroundStyle(OG.label2)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Este bloque se registra por series.")
                    .foregroundStyle(OG.label2)
            }

            Button {
                commitDrafts()
                onSave()
            } label: {
                Label("Guardar resultado", systemImage: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(OG.accent, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
            .opacity(canSave ? 1 : 0.5)
        }
        .padding(.horizontal, OG.pad)
        .padding(.top, 28)
        .padding(.bottom, 16)
        .background(OG.bg)
        .onAppear {
            roundsText = String(roundsCompleted)
            repsText = String(totalReps)
            timeText = DurationText.format(elapsedSeconds)
        }
        .onChange(of: roundsText) { _, text in
            if let parsed = Int(text) { roundsCompleted = min(200, max(0, parsed)) }
        }
        .onChange(of: repsText) { _, text in
            if let parsed = Int(text) { totalReps = min(5000, max(0, parsed)) }
        }
        .onChange(of: timeText) { _, text in
            if let parsed = DurationText.parse(text) { elapsedSeconds = min(180 * 60, parsed) }
        }
        .ogFittedHeight()
        .ogFittedSheet()
    }

    private func numberInput(
        _ label: String,
        text: Binding<String>,
        allowsTime: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(OG.label2)
            OGNumericTextField(
                text: text,
                allowsDecimal: allowsTime,
                allowsTimeSeparator: allowsTime,
                autoFocus: false,
                onCommit: { commitDrafts() }
            )
            .frame(height: 48)
            .padding(.horizontal, 12)
            .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(maxWidth: .infinity)
    }

    private func commitDrafts() {
        if let value = Int(roundsText) { roundsCompleted = min(200, max(0, value)) }
        if let value = Int(repsText) { totalReps = min(5000, max(0, value)) }
        if let value = DurationText.parse(timeText) { elapsedSeconds = min(180 * 60, value) }
    }

    private var canSave: Bool {
        switch capture {
        case .totalReps: return totalReps > 0 || roundsCompleted > 0
        case .elapsedTime: return elapsedSeconds > 0
        case .perMovementSets: return true
        }
    }
}
