import GymbroDomain
import SwiftUI

/// Modal ligero desde la ficha: apuntar series sin abrir la sesión completa.
struct QuickLogSheet: View {
    @Environment(GymbroStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var exercise: Exercise

    @State private var rows: [DraftSet] = []
    @State private var notes = ""
    @State private var includeNotes = false

    private struct DraftSet: Identifiable {
        let id = UUID()
        var reps: Int
        var weightKg: Double
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach($rows) { $row in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Peso (kg)")
                                    .font(.caption)
                                    .foregroundStyle(OG.label3)
                                HStack(spacing: 8) {
                                    Button {
                                        row.weightKg = max(0, ((row.weightKg - step) * 100).rounded() / 100)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                    }
                                    Text(String(format: "%g", row.weightKg))
                                        .font(.system(size: 17, weight: .semibold).monospacedDigit())
                                        .frame(minWidth: 48)
                                    Button {
                                        row.weightKg = ((row.weightKg + step) * 100).rounded() / 100
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                    }
                                }
                                .foregroundStyle(OG.accent)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Reps")
                                    .font(.caption)
                                    .foregroundStyle(OG.label3)
                                HStack(spacing: 8) {
                                    Button {
                                        row.reps = max(1, row.reps - 1)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                    }
                                    Text("\(row.reps)")
                                        .font(.system(size: 17, weight: .semibold).monospacedDigit())
                                        .frame(minWidth: 28)
                                    Button {
                                        row.reps = min(99, row.reps + 1)
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                    }
                                }
                                .foregroundStyle(OG.accent)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { rows.remove(atOffsets: $0) }

                    Button {
                        let last = rows.last
                        rows.append(DraftSet(
                            reps: last?.reps ?? defaultReps,
                            weightKg: last?.weightKg ?? defaultWeight
                        ))
                    } label: {
                        Label("Añadir serie", systemImage: "plus")
                    }
                } header: {
                    Text(exercise.name)
                }

                Section {
                    Toggle("Añadir nota", isOn: $includeNotes)
                    if includeNotes {
                        TextField("Cómo te sentiste, carga…", text: $notes, axis: .vertical)
                            .lineLimit(2...4)
                    }
                }
            }
            // Fondo transparente para que se vea el liquid glass del sheet.
            .scrollContentBackground(.hidden)
            .listRowBackground(Color.clear)
            .tint(OG.accent)
            .navigationTitle("Apuntar series")
            .navigationBarTitleDisplayMode(.inline)
            .ogTransparentNav()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseToolbarButton(action: { dismiss() }, large: false)
                }
                ToolbarItem(placement: .confirmationAction) {
                    // Mismo estilo topbar: SF Symbol sin `.circle` (iOS ya pone el cristal).
                    OGToolbarGlassButton(
                        systemName: "checkmark",
                        accessibilityLabel: "Guardar",
                        tint: OG.accent,
                        appliesGlass: false
                    ) {
                        save()
                    }
                    .disabled(rows.isEmpty || rows.allSatisfy { $0.reps <= 0 })
                    .opacity(rows.isEmpty || rows.allSatisfy { $0.reps <= 0 } ? 0.4 : 1)
                }
            }
            .onAppear { seedRows() }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .ogSheetCorners()
    }

    private var step: Double { store.state.settings.weightIncrementKg }

    private var defaultWeight: Double {
        StatsEngine.history(for: exercise.id, workouts: store.state.workouts).lastWeightKg ?? 20
    }

    private var defaultReps: Int {
        StatsEngine.history(for: exercise.id, workouts: store.state.workouts).lastReps ?? 8
    }

    private func seedRows() {
        guard rows.isEmpty else { return }
        rows = (0..<3).map { _ in
            DraftSet(reps: defaultReps, weightKg: defaultWeight)
        }
    }

    private func save() {
        let logged = rows
            .filter { $0.reps > 0 }
            .map { LoggedSet(reps: $0.reps, weightKg: $0.weightKg > 0 ? $0.weightKg : nil) }
        guard !logged.isEmpty else { return }
        let note = includeNotes ? notes : nil
        store.logQuickSets(exerciseId: exercise.id, sets: logged, notes: note)
        dismiss()
    }
}
