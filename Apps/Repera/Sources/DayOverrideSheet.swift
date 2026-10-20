import ReperaDomain
import SwiftUI

/// Asigna o quita la rutina de un día de la semana (elige entre plantillas de Diario → Rutinas).
struct DayOverrideSheet: View {
    @Environment(ReperaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var isoWeekday: Int
    var dayLabel: String
    /// Crear plantilla nueva ya asignada a este día.
    var onCreateNew: (() -> Void)?

    private var routines: [Routine] { store.libraryRoutines }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                OGPageHeader(title: dayLabel) {
                    if let onCreateNew {
                        OGToolbarGlassButton(
                            systemName: "plus",
                            accessibilityLabel: "Nueva rutina",
                            tint: .white,
                            appliesGlass: true,
                            glassTint: OG.accent
                        ) {
                            dismiss()
                            onCreateNew()
                        }
                    }
                }
                .padding(.top, 4)

                if routines.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sin rutinas guardadas")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(OG.label)
                        Text("Pulsa + para crear una rutina para este día, o créala en Diario → Rutinas.")
                            .font(.footnote)
                            .foregroundStyle(OG.label2)
                    }
                    .padding(.horizontal, 4)
                } else {
                    Text("Rutinas")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(OG.label2)
                        .textCase(.uppercase)
                        .padding(.horizontal, 4)

                    VStack(spacing: 0) {
                        ForEach(Array(routines.enumerated()), id: \.element.id) { index, routine in
                            if index > 0 {
                                Divider().opacity(0.35).padding(.leading, 14)
                            }
                            Button {
                                store.assignRoutine(routine.id, toWeekday: isoWeekday)
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(routine.title)
                                            .foregroundStyle(OG.label)
                                        Text(routineSummary(routine))
                                            .font(.caption)
                                            .foregroundStyle(OG.label2)
                                    }
                                    Spacer()
                                    if routine.weekday == isoWeekday {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.white)
                                            .frame(width: 28, height: 28)
                                            .background(OG.accent, in: Circle())
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .contentShape(Rectangle())
                            }
                        }
                    }
                    .background(OG.surface.opacity(0.55), in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
                }

                VStack(spacing: 0) {
                    Button {
                        if let current = store.routine(forWeekday: isoWeekday) {
                            store.assignRoutine(current.id, toWeekday: nil)
                        }
                        dismiss()
                    } label: {
                        Label("Día libre (sin rutina)", systemImage: "moon.fill")
                            .foregroundStyle(OG.label2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                    }
                }
                .background(OG.surface.opacity(0.4), in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
            }
            .padding(.horizontal, OG.pad)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .ogFittedHeight()
        }
        .ogFittedSheet()
    }

    private func routineSummary(_ routine: Routine) -> String {
        let strength = routine.blocks.filter { $0.kind == .strength }.flatMap(\.exercises).count
        let wods = routine.blocks.filter { $0.kind == .wod }.count
        var parts: [String] = []
        if strength > 0 { parts.append("\(strength) ej.") }
        if wods > 0 { parts.append("\(wods) WOD") }
        if parts.isEmpty { parts.append("Vacía") }
        return parts.joined(separator: " · ")
    }
}
