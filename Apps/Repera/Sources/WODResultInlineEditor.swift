import ReperaDomain
import SwiftUI

/// Editor del resultado en la propia pantalla Play; comparte el modelo de datos
/// de la edición del entrenamiento y no crea una segunda ruta modal.
struct WODResultInlineEditor: View {
    let blockId: UUID
    let format: WODFormat
    let existing: WODBlockResult?
    let suggestedElapsedSeconds: Int?
    let wodTemplateId: String?
    let onSave: (WODBlockResult) -> Void

    @State private var roundsText: String
    @State private var repsText: String
    @State private var timeText: String
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case rounds, reps, time
    }

    init(
        blockId: UUID,
        format: WODFormat,
        existing: WODBlockResult?,
        suggestedElapsedSeconds: Int? = nil,
        wodTemplateId: String? = nil,
        onSave: @escaping (WODBlockResult) -> Void
    ) {
        self.blockId = blockId
        self.format = format
        self.existing = existing
        self.suggestedElapsedSeconds = suggestedElapsedSeconds
        self.wodTemplateId = wodTemplateId
        self.onSave = onSave
        _roundsText = State(initialValue: String(existing?.roundsCompleted ?? 0))
        _repsText = State(initialValue: String(existing?.totalReps ?? 0))
        _timeText = State(initialValue: DurationText.format(
            existing?.elapsedSeconds ?? suggestedElapsedSeconds ?? 0
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if format.resultCapture == .totalReps {
                if format == .amrap || format == .deathBy {
                    HStack(spacing: 10) {
                        numericField("Rondas completas", text: $roundsText, field: .rounds)
                        numericField("Reps adicionales", text: $repsText, field: .reps)
                    }
                } else {
                    numericField("Repeticiones", text: $repsText, field: .reps)
                }
            } else if format.resultCapture == .elapsedTime {
                numericField("Tiempo · m:ss", text: $timeText, field: .time)
            }

            Button {
                focusedField = nil
                guard canSave else { return }
                onSave(WODBlockResult(
                    id: blockId,
                    format: format,
                    totalReps: format.resultCapture == .totalReps
                        ? min(5000, max(0, Int(repsText) ?? 0)) : nil,
                    elapsedSeconds: format.resultCapture == .elapsedTime
                        ? min(180 * 60, max(1, DurationText.parse(timeText) ?? 0)) : nil,
                    roundsCompleted: format == .amrap || format == .deathBy
                        ? min(200, max(0, Int(roundsText) ?? 0)) : nil,
                    wodTemplateId: wodTemplateId ?? existing?.wodTemplateId
                ))
            } label: {
                Label(existing == nil ? "Guardar resultado" : "Actualizar resultado",
                      systemImage: "checkmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(OG.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
            .opacity(canSave ? 1 : 0.5)
        }
        .onChange(of: suggestedElapsedSeconds) { _, seconds in
            // Reloj For Time: conservar cualquier registro previo y solo
            // proponer el tiempo recién medido cuando no había resultado.
            guard existing?.elapsedSeconds == nil, let seconds, seconds > 0 else { return }
            timeText = DurationText.format(seconds)
        }
    }

    private func numericField(
        _ label: String,
        text: Binding<String>,
        field: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(OG.label3)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            TextField("0", text: text)
                .keyboardType(field == .time ? .numbersAndPunctuation : .numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 21, weight: .medium).monospacedDigit())
                .foregroundStyle(OG.label)
                .focused($focusedField, equals: field)
                .frame(minHeight: 48)
                .background(OG.surface3, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityLabel(label)
        }
        .frame(maxWidth: .infinity)
    }

    private var canSave: Bool {
        switch format.resultCapture {
        case .totalReps:
            let reps = Int(repsText) ?? 0
            let rounds = Int(roundsText) ?? 0
            return reps >= 0 && reps <= 5000
                && (format == .amrap || format == .deathBy
                    ? rounds >= 0 && rounds <= 200 && (rounds > 0 || reps > 0)
                    : reps > 0)
        case .elapsedTime:
            guard let seconds = DurationText.parse(timeText) else { return false }
            return seconds > 0 && seconds <= 180 * 60
        case .perMovementSets:
            return false
        }
    }
}
