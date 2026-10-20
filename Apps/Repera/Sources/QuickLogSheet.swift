import ReperaDomain
import SwiftUI

/// Modal ligero desde la ficha: apuntar series sin abrir la sesión completa.
struct QuickLogSheet: View {
    @Environment(ReperaStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var exercise: Exercise

    @State private var rows: [DraftSet] = []
    @State private var notes = ""
    @State private var includeNotes = false
    @State private var quantityUnit: ExerciseQuantityUnit

    private struct DraftSet: Identifiable {
        let id = UUID()
        var reps: Int
        var weightKg: Double
        var deficitCm: Int
        var durationSeconds: Int
    }

    private var style: ExerciseLoggingStyle { exercise.loggingStyle }
    private var loadField: ExerciseLoadField { exercise.loadField }

    init(exercise: Exercise) {
        self.exercise = exercise
        _quantityUnit = State(initialValue: exercise.defaultQuantityUnit)
    }

    var body: some View {
        NavigationStack {
            Form {
                if style == .machineWork, exercise.allowsCalorieOrDistanceToggle {
                    Section {
                        Picker("Unidad", selection: $quantityUnit) {
                            Text("Cal").tag(ExerciseQuantityUnit.calories)
                            Text("Metros").tag(ExerciseQuantityUnit.meters)
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Section {
                    ForEach($rows) { $row in
                        HStack(spacing: 12) {
                            switch style {
                            case .loadAndReps:
                                metricColumn(title: Exercise.loadStepperTitle(
                                    name: exercise.name,
                                    equipment: exercise.equipment
                                )) {
                                    if loadField == .deficitCm {
                                        HStack(spacing: 8) {
                                            Button {
                                                row.deficitCm = max(0, row.deficitCm - 1)
                                            } label: {
                                                Image(systemName: "minus.circle.fill")
                                            }
                                            Text("\(row.deficitCm)")
                                                .font(.system(size: 17, weight: .semibold).monospacedDigit())
                                                .frame(minWidth: 36)
                                            Button {
                                                row.deficitCm = min(60, row.deficitCm + 1)
                                            } label: {
                                                Image(systemName: "plus.circle.fill")
                                            }
                                        }
                                        .foregroundStyle(OG.accent)
                                    } else {
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
                                }
                            case .repsAndTime:
                                metricColumn(title: "Tiempo") {
                                    HStack(spacing: 8) {
                                        Button {
                                            row.durationSeconds = max(0, row.durationSeconds - 5)
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                        }
                                        Text(DurationText.format(row.durationSeconds))
                                            .font(.system(size: 17, weight: .semibold).monospacedDigit())
                                            .frame(minWidth: 48)
                                        Button {
                                            row.durationSeconds += 5
                                        } label: {
                                            Image(systemName: "plus.circle.fill")
                                        }
                                    }
                                    .foregroundStyle(OG.accent)
                                }
                            case .machineWork:
                                metricColumn(title: "Tiempo") {
                                    HStack(spacing: 8) {
                                        Button {
                                            row.durationSeconds = max(0, row.durationSeconds - 5)
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                        }
                                        Text(DurationText.format(row.durationSeconds))
                                            .font(.system(size: 17, weight: .semibold).monospacedDigit())
                                            .frame(minWidth: 48)
                                        Button {
                                            row.durationSeconds += 5
                                        } label: {
                                            Image(systemName: "plus.circle.fill")
                                        }
                                    }
                                    .foregroundStyle(OG.accent)
                                }
                            case .repsOnly:
                                EmptyView()
                            }

                            Spacer(minLength: 0)

                            metricColumn(title: quantityLabel, trailing: true) {
                                HStack(spacing: 8) {
                                    Button {
                                        row.reps = max(1, row.reps - quantityStep)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                    }
                                    Text("\(row.reps)")
                                        .font(.system(size: 17, weight: .semibold).monospacedDigit())
                                        .frame(minWidth: 28)
                                    Button {
                                        row.reps = min(style.quantityCap, row.reps + quantityStep)
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
                            weightKg: last?.weightKg ?? defaultWeight,
                            deficitCm: last?.deficitCm ?? 0,
                            durationSeconds: last?.durationSeconds ?? (style == .repsAndTime ? 60 : 60)
                        ))
                    } label: {
                        Label("Añadir serie", systemImage: "plus")
                    }
                } header: {
                    Text(exercise.name)
                } footer: {
                    switch style {
                    case .repsAndTime:
                        Text("Comba: cuántas veces (dobles/simples) en cuánto tiempo. Ej. 50 veces en 1:00.")
                    case .machineWork:
                        Text("Máquina / carrera: tiempo y \(quantityLabel.lowercased()) (sin kilos).")
                    case .repsOnly:
                        Text("Peso corporal: solo repeticiones.")
                    case .loadAndReps:
                        if loadField == .deficitCm {
                            Text("HSPU: déficit en cm (0 = sin déficit) y repeticiones. El lastre no aplica.")
                        } else if Exercise.loadStepperTitle(name: exercise.name, equipment: exercise.equipment)
                            .localizedCaseInsensitiveContains("lastre") {
                            Text("Dominadas / muscle-up: lastre en kg (0 = sin lastre) y repeticiones.")
                        } else {
                            Text("Ajusta peso y reps por serie.")
                        }
                    }
                }

                Section {
                    Toggle("Añadir nota", isOn: $includeNotes)
                    if includeNotes {
                        TextField("Cómo te sentiste, carga…", text: $notes, axis: .vertical)
                            .lineLimit(2...4)
                    }
                }
            }
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
        .ogSheetChrome(detents: [.medium, .large])
    }

    private var quantityLabel: String {
        if style == .machineWork { return quantityUnit.shortLabel }
        return exercise.quantityFieldLabel
    }

    private var quantityStep: Int {
        switch style {
        case .machineWork where quantityUnit == .meters: return 50
        case .machineWork where quantityUnit == .calories: return 1
        case .repsAndTime: return 5
        default: return 1
        }
    }

    private func metricColumn<Content: View>(
        title: String,
        trailing: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: trailing ? .trailing : .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(OG.label3)
            content()
        }
    }

    private var step: Double { store.state.settings.weightIncrementKg }

    private var defaultWeight: Double {
        if loadField == .deficitCm { return 0 }
        return store.cachedHistory(for: exercise.id).lastWeightKg ?? 0
    }

    private var defaultReps: Int {
        if style == .machineWork {
            return quantityUnit == .meters ? 500 : 15
        }
        if style == .repsAndTime {
            return store.cachedHistory(for: exercise.id).lastReps ?? 50
        }
        return store.cachedHistory(for: exercise.id).lastReps ?? 8
    }

    private func seedRows() {
        guard rows.isEmpty else { return }
        rows = (0..<3).map { _ in
            DraftSet(
                reps: defaultReps,
                weightKg: style == .loadAndReps && loadField == .weightKg ? defaultWeight : 0,
                deficitCm: 0,
                durationSeconds: style.usesDuration ? 60 : 0
            )
        }
    }

    private func save() {
        let logged = rows
            .filter { $0.reps > 0 }
            .map { row -> LoggedSet in
                let weight: Double? = {
                    guard style == .loadAndReps, loadField == .weightKg, row.weightKg > 0 else { return nil }
                    return row.weightKg
                }()
                let deficit: Int? = {
                    guard style == .loadAndReps, loadField == .deficitCm, row.deficitCm > 0 else { return nil }
                    return row.deficitCm
                }()
                return LoggedSet(
                    reps: row.reps,
                    weightKg: weight,
                    deficitCm: deficit,
                    durationSeconds: style.usesDuration ? row.durationSeconds : nil,
                    quantityUnit: style == .machineWork ? quantityUnit : nil
                )
            }
        guard !logged.isEmpty else { return }
        let note = includeNotes ? notes : nil
        store.logQuickSets(exerciseId: exercise.id, sets: logged, notes: note)
        dismiss()
    }
}
