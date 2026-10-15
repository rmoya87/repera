import GymbroDomain
import SwiftUI

/// Asigna o quita la rutina de un día de la semana.
struct DayOverrideSheet: View {
    @Environment(GymbroStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var isoWeekday: Int
    var dayLabel: String

    var body: some View {
        NavigationStack {
            List {
                Section("Rutina para \(CalendarHelpers.weekdayName(isoWeekday))") {
                    Button("Día libre (sin rutina)") {
                        if let current = store.state.routines.first(where: { $0.weekday == isoWeekday }) {
                            store.assignRoutine(current.id, toWeekday: nil)
                        }
                        dismiss()
                    }
                    ForEach(store.state.routines) { routine in
                        Button {
                            // Quita el día de quien lo tuviera
                            for r in store.state.routines where r.weekday == isoWeekday && r.id != routine.id {
                                store.assignRoutine(r.id, toWeekday: nil)
                            }
                            store.assignRoutine(routine.id, toWeekday: isoWeekday)
                            dismiss()
                        } label: {
                            HStack {
                                Text(routine.title)
                                Spacer()
                                if routine.weekday == isoWeekday {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(OG.accent)
                                }
                            }
                        }
                    }
                }
                Section {
                    Text("También puedes crear rutinas nuevas en Plan.")
                        .font(.footnote)
                        .foregroundStyle(OG.label2)
                }
            }
            .ogListChrome()
            .navigationTitle(dayLabel)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseToolbarButton { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium])
    }
}
