import ReperaDomain
import SwiftUI

/// Registro rápido sin crear una rutina. Reutiliza los steppers y el teclado
/// numérico de Repera empleados en la edición de entrenamientos programados.
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
    private var weightStep: Double { max(0.25, store.state.settings.weightIncrementKg) }
    private var canSave: Bool {
        rows.contains { $0.reps > 0 && (!isHold || $0.durationSeconds > 0) }
    }

    init(exercise: Exercise) {
        self.exercise = exercise
        _quantityUnit = State(initialValue: exercise.defaultQuantityUnit)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if style == .machineWork && exercise.allowsCalorieOrDistanceToggle {
                        OGCard(padding: 14, verticalPadding: 12) {
                            Picker("Unidad", selection: $quantityUnit) {
                                Text("Cal").tag(ExerciseQuantityUnit.calories)
                                Text("Metros").tag(ExerciseQuantityUnit.meters)
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        OGCardSectionTitle(title: exercise.name)
                        ForEach($rows) { $row in
                            let index = (rows.firstIndex(where: { $0.id == row.id }) ?? 0) + 1
                            setCard($row, index: index)
                        }

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
                        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard))
                        .overlay {
                            RoundedRectangle(cornerRadius: OG.radiusCard)
                                .strokeBorder(OG.surface3.opacity(0.75), lineWidth: 0.7)
                        }
                    }

                    OGCard(padding: 14, verticalPadding: 12) {
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle("Añadir nota", isOn: $includeNotes)
                                .tint(OG.accent)
                            if includeNotes {
                                TextField("Cómo te sentiste, carga…", text: $notes, axis: .vertical)
                                    .lineLimit(2...4)
                                    .padding(10)
                                    .background(OG.surface2, in: RoundedRectangle(cornerRadius: 11))
                            }
                        }
                    }
                    guidance
                }
                .padding(.horizontal, OG.pad)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .ogReadableColumn()
            }
            .scrollDismissesKeyboard(.interactively)
            // El lienzo no es una tarjeta opaca: deja visible Liquid Glass
            // del sheet. Solo los controles y las filas usan OG.surface.
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
        OGCard(padding: 12, verticalPadding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Serie \(index)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(OG.label)
                    Spacer()
                    Button(role: .destructive) {
                        rows.removeAll { $0.id == row.wrappedValue.id }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(OG.label2)
                            .frame(width: 36, height: 32)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Eliminar serie \(index)")
                }
                HStack(alignment: .top, spacing: 8) {
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
                .frame(maxWidth: .infinity)
            }
        }
    }

    /// OGRepeatStepper admite − / + y edición al pulsar el valor mediante
    /// OGNumericTextField: mismo teclado Repera 4×4 que Entreno programado.
    private func loadMetric(_ row: Binding<DraftSet>) -> some View {
        metricColumn(
            title: Exercise.loadStepperTitle(
                name: exercise.name, equipment: exercise.equipment
            )
        ) {
            if loadField == .deficitCm {
                OGRepeatStepper(
                    display: "\(row.wrappedValue.deficitCm)",
                    compact: true,
                    keyboard: .numberPad,
                    onMinus: {
                        row.wrappedValue.deficitCm = max(0, row.wrappedValue.deficitCm - 1)
                    },
                    onPlus: {
                        row.wrappedValue.deficitCm = min(60, row.wrappedValue.deficitCm + 1)
                    },
                    onCommitText: {
                        row.wrappedValue.deficitCm = parseInt($0, cap: 60)
                    }
                )
            } else {
                OGRepeatStepper(
                    display: String(format: "%g", row.wrappedValue.weightKg),
                    compact: true,
                    keyboard: .decimalPad,
                    onMinus: {
                        row.wrappedValue.weightKg = roundWeight(row.wrappedValue.weightKg - weightStep)
                    },
                    onPlus: {
                        row.wrappedValue.weightKg = roundWeight(row.wrappedValue.weightKg + weightStep)
                    },
                    onCommitText: {
                        let number = Double($0.replacingOccurrences(of: ",", with: ".")) ?? 0
                        row.wrappedValue.weightKg = min(1500, max(0, number))
                    }
                )
            }
        }
    }

    private func durationMetric(_ row: Binding<DraftSet>) -> some View {
        metricColumn(title: isMobility ? "Duración (s)" : "Tiempo (s)") {
            OGRepeatStepper(
                display: "\(row.wrappedValue.durationSeconds)",
                compact: true,
                keyboard: .numberPad,
                onMinus: {
                    row.wrappedValue.durationSeconds = max(0, row.wrappedValue.durationSeconds - 5)
                },
                onPlus: {
                    row.wrappedValue.durationSeconds = min(86_400, row.wrappedValue.durationSeconds + 5)
                },
                onCommitText: {
                    row.wrappedValue.durationSeconds = parseInt($0, cap: 86_400)
                }
            )
        }
    }

    private func quantityMetric(_ row: Binding<DraftSet>) -> some View {
        metricColumn(title: quantityLabel) {
            OGRepeatStepper(
                display: "\(row.wrappedValue.reps)",
                compact: true,
                keyboard: .numberPad,
                onMinus: {
                    row.wrappedValue.reps = max(0, row.wrappedValue.reps - quantityStep)
                },
                onPlus: {
                    row.wrappedValue.reps = min(style.quantityCap, row.wrappedValue.reps + quantityStep)
                },
                onCommitText: {
                    row.wrappedValue.reps = parseInt($0, cap: style.quantityCap)
                }
            )
        }
    }

    private func metricColumn<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(OG.label2)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var guidance: some View {
        switch style {
        case .repsAndTime:
            Text(isMobility
                 ? (isHold ? "Registra la duración real de cada mantenimiento." :
                    "Registra repeticiones y segundos de cada secuencia.")
                 : "Comba: repeticiones y tiempo por serie.")
        case .machineWork:
            Text("Registra el tiempo y \(quantityLabel.lowercased()) por serie.")
        case .repsOnly:
            Text("Registra las repeticiones de cada serie.")
        case .loadAndReps:
            Text(loadField == .deficitCm
                 ? "Registra déficit en cm y repeticiones por serie."
                 : "Ajusta peso y repeticiones de cada serie.")
        }
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
