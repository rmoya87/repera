import ReperaDomain
import SwiftUI
import UIKit

/// Identidad estable del campo para avanzar horizontalmente con la tecla Siguiente.
struct OGSetFieldID: Hashable {
    var rowID: UUID
    var column: Int
}

/// Cabecera compacta compartida por planificación, registro final y sesión en curso.
struct OGSetEntryHeader: View {
    var firstTitle: String
    var secondTitle: String? = nil
    var showsConfirmation = false

    var body: some View {
        HStack(spacing: 6) {
            caption("SERIE").frame(width: 34)
            caption("ANTERIOR").frame(width: 60)
            caption(firstTitle.uppercased()).frame(maxWidth: .infinity)
            if let secondTitle {
                caption(secondTitle.uppercased()).frame(maxWidth: .infinity)
            }
            if showsConfirmation {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(OG.label3)
                    .frame(width: 36)
                    .accessibilityHidden(true)
            }
        }
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(OG.label3)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .multilineTextAlignment(.center)
    }
}

/// Misma retícula para editar objetivos y apuntar series reales. Sin +/-.
struct OGSetEntryRow: View {
    var rowID: UUID
    var index: Int
    var previous: String?
    var firstValue: String
    var secondValue: String? = nil
    var firstAllowsDecimal = true
    var secondAllowsDecimal = false
    var enabled = true
    var showsConfirmation = false
    var completed = false
    var focus: FocusState<OGSetFieldID?>.Binding
    var onFirstCommit: (String) -> Void
    var onSecondCommit: (String) -> Void = { _ in }
    var onConfirm: () -> Void = {}

    var body: some View {
        HStack(spacing: 6) {
            Text("\(index)")
                .font(.system(size: 13, weight: .bold).monospacedDigit())
                .foregroundStyle(OG.label)
                .frame(width: 34, height: 44)
                .background(OG.surface2, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                .accessibilityLabel("Serie \(index)")

            Text(previous ?? "—")
                .font(.system(size: 11, weight: .medium).monospacedDigit())
                .foregroundStyle(previous == nil ? OG.label3 : OG.label2)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .frame(width: 60, height: 44)
                .accessibilityLabel(previous.map { "Anterior: \($0)" } ?? "Sin registro anterior")

            OGSetNumericCell(
                display: firstValue,
                allowsDecimal: firstAllowsDecimal,
                fieldID: OGSetFieldID(rowID: rowID, column: 0),
                nextID: secondValue == nil ? nil : OGSetFieldID(rowID: rowID, column: 1),
                enabled: enabled && !completed,
                focus: focus,
                onCommit: onFirstCommit,
                onLastSubmit: onConfirm
            )
            .frame(maxWidth: .infinity)

            if let secondValue {
                OGSetNumericCell(
                    display: secondValue,
                    allowsDecimal: secondAllowsDecimal,
                    fieldID: OGSetFieldID(rowID: rowID, column: 1),
                    nextID: nil,
                    enabled: enabled && !completed,
                    focus: focus,
                    onCommit: onSecondCommit,
                    onLastSubmit: onConfirm
                )
                .frame(maxWidth: .infinity)
            }

            if showsConfirmation {
                Button(action: onConfirm) {
                    Image(systemName: completed ? "checkmark.circle.fill" : "checkmark")
                        .font(.system(size: completed ? 20 : 17, weight: .bold))
                        .foregroundStyle(completed ? OG.onAccent : OG.accent)
                        .frame(width: 36, height: 44)
                        .background(
                            completed ? OG.accent : OG.surface2,
                            in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(completed ? "Serie completada" : "Completar serie \(index)")
            }
        }
    }

    static func previousText(_ set: ExerciseLastSession.WorkSet?) -> String? {
        guard let set else { return nil }
        if let weight = set.weightKg, weight > 0 {
            return "\(String(format: "%g", weight)) kg"
        }
        if let duration = set.durationSeconds, duration > 0 {
            return DurationText.format(duration)
        }
        return "\(set.reps) rep"
    }
}

/// Campo con el teclado nativo de Repera y retorno contextual Siguiente / Listo.
/// La confirmación consolida el dato antes de mover el foco o marcar la serie.
private struct OGSetNumericCell: View {
    var display: String
    var allowsDecimal: Bool
    var fieldID: OGSetFieldID
    var nextID: OGSetFieldID?
    var enabled: Bool
    var focus: FocusState<OGSetFieldID?>.Binding
    var onCommit: (String) -> Void
    var onLastSubmit: () -> Void

    @State private var draft = ""

    var body: some View {
        TextField("0", text: $draft)
            .font(.system(size: 17, weight: .semibold).monospacedDigit())
            .foregroundStyle(OG.label)
            .multilineTextAlignment(.center)
            .keyboardType(.numbersAndPunctuation)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(nextID == nil ? .done : .next)
            .focused(focus, equals: fieldID)
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(OG.surface2, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .opacity(enabled ? 1 : 0.55)
            .disabled(!enabled)
            .onAppear { draft = normalized(display) }
            .onChange(of: display) { _, newValue in
                if focus.wrappedValue != fieldID {
                    draft = normalized(newValue)
                }
            }
            .onChange(of: focus.wrappedValue) { oldFocus, newFocus in
                if oldFocus == fieldID, newFocus != fieldID {
                    onCommit(draft.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                if newFocus == fieldID {
                    draft = normalized(display)
                    // Al entrar, seleccionar el valor completo para sobrescribirlo
                    // directamente sin tener que borrar manualmente los datos previos.
                    DispatchQueue.main.async {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.selectAll(_:)),
                            to: nil, from: nil, for: nil
                        )
                    }
                }
            }
            .onChange(of: draft) { _, value in
                let valid = value.filter { character in
                    character.isNumber || (allowsDecimal && (character == "." || character == "," || character == ":"))
                }
                if valid != value { draft = valid }
            }
            .onSubmit {
                onCommit(draft.trimmingCharacters(in: .whitespacesAndNewlines))
                if let nextID {
                    focus.wrappedValue = nextID
                } else {
                    focus.wrappedValue = nil
                    onLastSubmit()
                }
            }
    }

    private func normalized(_ value: String) -> String {
        value == "—" ? "" : value
    }
}
