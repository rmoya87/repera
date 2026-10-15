import GymbroDomain
import SwiftUI

/// Asigna o quita la rutina de un día de la semana (elige entre plantillas de Diario → Rutinas).
struct DayOverrideSheet: View {
    @Environment(GymbroStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var isoWeekday: Int
    var dayLabel: String
    /// Crear plantilla nueva ya asignada a este día.
    var onCreateNew: (() -> Void)?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    OGPageHeader(title: dayLabel) {
                        CloseToolbarButton { dismiss() }
                    }
                    .ogListPageHeaderRow()
                }
                Section("Rutina para \(CalendarHelpers.weekdayName(isoWeekday))") {
                    Button("Día libre (sin rutina)") {
                        if let current = store.routine(forWeekday: isoWeekday) {
                            store.assignRoutine(current.id, toWeekday: nil)
                        }
                        dismiss()
                    }
                    if let onCreateNew {
                        Button {
                            dismiss()
                            onCreateNew()
                        } label: {
                            Label("Nueva rutina para este día", systemImage: "plus")
                        }
                    }
                    ForEach(store.libraryRoutines) { routine in
                        Button {
                            store.assignRoutine(routine.id, toWeekday: isoWeekday)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(routine.title)
                                    Text(routineSummary(routine))
                                        .font(.caption)
                                        .foregroundStyle(OG.label2)
                                }
                                Spacer()
                                if routine.weekday == isoWeekday {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(OG.accent)
                                }
                            }
                        }
                    }
                }
                if store.libraryRoutines.isEmpty {
                    Section {
                        Text("Crea rutinas en la pestaña Rutinas y asígnalas aquí a cada día.")
                            .font(.footnote)
                            .foregroundStyle(OG.label2)
                    }
                }
            }
            .ogListChrome()
            .ogContentTitleNav()
            .toolbar(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
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
