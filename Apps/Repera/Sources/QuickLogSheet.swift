import ReperaDomain
import SwiftUI

/// Registro rápido sin crear una rutina. Campos numéricos adaptados al ejercicio
/// y eliminación de series por swipe nativo, igual que otros registros.
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
    private var isMobility: Bool { exercise.isMobility }
    private var isHold: Bool { exercise.isMobilityHold }
    private var canSave: Bool {
        rows.contains { $0.reps > 0 && (!isHold || $0.durationSeconds > 0) }
    }

    init(exercise: Exercise) {
        self.exercise = exercise
        _quantityUnit = State(initialValue: exercise.defaultQuantityUnit)
    }

    var body: some View {
        NavigationStack {
            List {
                if style == .machineWork && exercise.allowsCalorieOrDistanceToggle {
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
                        let index = (rows.firstIndex(where: { $0.id == row.id }) ?? 0) + 1
                        setCard($row, index: index)
                            .listRowInsets(EdgeInsets(
                                top: 5, leading: OG.pad, bottom: 5, trailing: OG.pad
                            ))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                OGSwipeDeleteButton(
                                    systemImage: "trash",
                                    accessibilityLabel: "Eliminar serie \(index)"
                                ) {
                                    rows.removeAll { $0.id == row.id }
                                }
                            }
                    }
                } header: {
                    OGCardSectionTitle(title: exercise.name)
                        .textCase(nil)
                }

                Section {
                    Button {
                        let last = rows.last
                        rows.append(DraftSet(
                            reps: last?.reps ?? defaultReps,
                            weightKg: last?.weightKg ?? defaultWeight,
                            deficitCm: last?.deficitCm ?? 0,
                            durationSeconds: last?.durationSeconds ?? defaultDurationSeconds
                        ))
                    } label: {
                        Label("Añadir serie", systemImage: "plus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(OG.label)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                }

                Section {
                    Toggle("Añadir nota", isOn: $includeNotes)
                        .tint(OG.accent)
                    if includeNotes {
                        TextField("Cómo te sentiste, carga…", text: $notes, axis: .vertical)
                            .lineLimit(2...4)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background(Color.clear)
            .navigationTitle("Apuntar ejercicio")
            .navigationBarTitleDisplayMode(.inline)
            .ogDiaryTransparentNav()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseToolbarButton(action: { dismiss() }, large: false)
                }
                ToolbarItem(placement: .confirmationAction) {
                    OGToolbarGlassButton(
                        systemName: "checkmark",
                        accessibilityLabel: "Guardar ejercicio",
                        tint: OG.accent,
                        appliesGlass: false
                    ) {
                        save()
                    }
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.4)
                }
            }
            .onAppear { seedRows() }
        }
        .ogSheetChrome(detents: [.medium, .large])
    }

    private func setCard(_ row: Binding<DraftSet>, index: Int) -> some View {
        OGCard(padding: 14, verticalPadding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    // El número identificador precede al título de la serie.
                    Text("\(index)")
                        .font(.system(size: 15, weight: .semibold).monospacedDigit())
                        .foregroundStyle(OG.label)
                        .frame(width: 32, height: 32)
                        .background(OG.surface2, in: Circle())
                    Text("Serie")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(OG.label)
                    Spacer(minLength: 0)
                }

                // Cada estilo solo solicita valores que tienen sentido para él.
                if style == .loadAndReps {
                    loadMetric(row)
                }
                if style == .repsAndTime || style == .machineWork {
                    durationMetric(row)
                }
                if !isHold {
                    quantityMetric(row)
                }
            }
        }
    }

    private func loadMetric(_ row: Binding<DraftSet>) -> some View {
        if loadField == .deficitCm {
            metricRow("Déficit (cm)", value: "\(row.wrappedValue.deficitCm)") {
                row.wrappedValue.deficitCm = parseInt($0, cap: 60)
            }
        } else {
            metricRow(
                Exercise.loadStepperTitle(name: exercise.name, equipment: exercise.equipment),
                value: ReperaNumberFormat.decimal(row.wrappedValue.weightKg),
                allowsDecimal: true
            ) {
                let value = ReperaNumberFormat.parse($0) ?? 0
                row.wrappedValue.weightKg = roundWeight(value)
            }
        }
    }

    private func durationMetric(_ row: Binding<DraftSet>) -> some View {
        metricRow(isMobility ? "Duración (s)" : "Tiempo (s)",
                  value: "\(row.wrappedValue.durationSeconds)") {
            row.wrappedValue.durationSeconds = parseInt($0, cap: 86_400)
        }
    }

    private func quantityMetric(_ row: Binding<DraftSet>) -> some View {
        metricRow(quantityLabel, value: "\(row.wrappedValue.reps)") {
            row.wrappedValue.reps = parseInt($0, cap: style.quantityCap)
        }
    }

    private func metricRow(
        _ title: String,
        value: String,
        allowsDecimal: Bool = false,
        onUpdate: @escaping (String) -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(OG.label2)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 6)
            QuickLogNumberField(
                display: value,
                allowsDecimal: allowsDecimal,
                onUpdate: onUpdate
            )
            .frame(width: 120)
        }
        .frame(minHeight: 46)
    }

    private var quantityLabel: String {
        if style == .machineWork { return quantityUnit.shortLabel }
        return exercise.quantityFieldLabel
    }

    private var defaultWeight: Double {
        if loadField == .deficitCm { return 0 }
        return store.cachedHistory(for: exercise.id).lastWeightKg ?? 0
    }

    private var defaultReps: Int {
        if style == .machineWork { return quantityUnit == .meters ? 500 : 15 }
        if isHold { return 1 }
        if isMobility { return store.cachedHistory(for: exercise.id).lastReps ?? 8 }
        if style == .repsAndTime { return store.cachedHistory(for: exercise.id).lastReps ?? 50 }
        return store.cachedHistory(for: exercise.id).lastReps ?? 8
    }

    private var defaultDurationSeconds: Int {
        store.cachedHistory(for: exercise.id).lastDurationSeconds ?? (isHold ? 30 : 60)
    }

    private func parseInt(_ text: String, cap: Int) -> Int {
        min(cap, max(0, Int(text) ?? 0))
    }

    private func roundWeight(_ weight: Double) -> Double {
        min(1500, max(0, (weight * 100).rounded() / 100))
    }

    private func seedRows() {
        guard rows.isEmpty else { return }
        rows = (0..<3).map { _ in
            DraftSet(
                reps: defaultReps,
                weightKg: style == .loadAndReps && loadField == .weightKg ? defaultWeight : 0,
                deficitCm: 0,
                durationSeconds: style.usesDuration ? defaultDurationSeconds : 0
            )
        }
    }

    private func save() {
        let logged = rows
            .filter { $0.reps > 0 && (!isHold || $0.durationSeconds > 0) }
            .map { row -> LoggedSet in
                let weight: Double? = {
                    guard style == .loadAndReps, loadField == .weightKg,
                          row.weightKg > 0 else { return nil }
                    return row.weightKg
                }()
                let deficit: Int? = {
                    guard style == .loadAndReps, loadField == .deficitCm,
                          row.deficitCm > 0 else { return nil }
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
        store.logQuickSets(
            exerciseId: exercise.id,
            sets: logged,
            notes: includeNotes ? notes : nil
        )
        dismiss()
    }
}

/// Campo independiente para evitar que el modelo reintroduzca el cero en cada
/// tecla. Los cambios se guardan también antes de cerrar el teclado Repera 4×4.
private struct QuickLogNumberField: View {
    let display: String
    var allowsDecimal: Bool = false
    var onUpdate: (String) -> Void

    @State private var draft: String
    @State private var isEditing = false

    init(display: String, allowsDecimal: Bool = false, onUpdate: @escaping (String) -> Void) {
        self.display = display
        self.allowsDecimal = allowsDecimal
        self.onUpdate = onUpdate
        _draft = State(initialValue: display)
    }

    var body: some View {
        OGNumericTextField(
            text: $draft,
            allowsDecimal: allowsDecimal,
            textAlignment: .center,
            fontSize: 19,
            autoFocus: false,
            onFocused: { isEditing = true },
            onFocusLost: { commit() },
            onCommit: { commit() }
        )
        .frame(height: 44)
        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .onChange(of: draft) { _, updated in
            onUpdate(updated)
        }
        .onChange(of: display) { _, updated in
            if !isEditing && draft != updated {
                draft = updated
            }
        }
    }

    private func commit() {
        onUpdate(draft)
        isEditing = false
    }
}
