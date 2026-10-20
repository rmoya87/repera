import ReperaDomain
import SwiftUI

/// Resumen del plan antes de empezar, o gestión de sesión en curso.
/// Top bar: X · Entreno · día debajo · ⋯ (editar / apuntar) · ▶ comenzar.
struct SessionPreviewView: View {
    @Environment(ReperaStore.self) private var store

    var routine: Routine?
    var onClose: () -> Void
    var onStart: () -> Void
    var onContinue: () -> Void
    var onLogResults: (Routine) -> Void
    var onEdit: (Routine) -> Void

    /// Copia de trabajo tras editar; si nil, se usa `routine`.
    @State private var editedSnapshot: Routine?
    @State private var showDeleteConfirm = false

    private var active: WorkoutSession? { store.state.activeSession }

    /// Rutina viva del store (para reflejar ediciones).
    private var liveRoutine: Routine? {
        if let id = editedSnapshot?.id ?? routine?.id,
           let live = store.state.routines.first(where: { $0.id == id }) {
            return live
        }
        return editedSnapshot ?? routine
    }

    private var dayLabel: String {
        let r = liveRoutine
        let day: String
        if let date = r?.scheduledDate {
            day = CalendarHelpers.weekdayName(CalendarHelpers.isoWeekday(for: date))
        } else if let wd = r?.weekday {
            day = CalendarHelpers.weekdayName(wd)
        } else {
            day = CalendarHelpers.weekdayName(CalendarHelpers.isoWeekday(for: Date()))
        }
        if let minutes = r?.normalizedScheduledTimeMinutes {
            return "\(day) · \(SpanishDate.time(minutesFromMidnight: minutes))"
        }
        return day
    }

    var body: some View {
        List {
            if active == nil, !dayLabel.isEmpty {
                Section {
                    Text(dayLabel)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(OG.label2)
                        .ogListPageHeaderRow()
                }
            }

            if let active {
                Section {
                    Button {
                        onContinue()
                    } label: {
                        activeBanner(active)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .listRowBackground(OG.surface)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        OGSwipeDeleteButton(accessibilityLabel: "Descartar entreno en curso") {
                            store.endActiveSession(save: false)
                            onClose()
                        }
                    }
                } footer: {
                    Text("Toca para continuar · desliza para eliminar (no se guarda)")
                }
            }

            if let routine = liveRoutine {
                Section {
                    if routine.blocks.isEmpty {
                        flatExercises(routine)
                    } else {
                        OGRoutineBlocksList(blocks: routine.blocks)
                    }
                }
            } else if active == nil {
                Section {
                    Text("No hay plan para hoy.")
                        .foregroundStyle(OG.label2)
                }
            }
        }
        .ogListChrome()
        .ogPinnedTransparentNav(active != nil ? "Sesión" : "Entreno")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CloseToolbarButton(action: onClose, large: false)
            }
            if active == nil, liveRoutine != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            if let routine = liveRoutine {
                                onEdit(routine)
                            }
                        } label: {
                            Label("Editar", systemImage: "pencil")
                        }
                        Button {
                            if let routine = liveRoutine {
                                onLogResults(routine)
                            }
                        } label: {
                            Label("Apuntar resultado", systemImage: "square.and.pencil")
                        }
                        Divider()
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Borrar entreno", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(OG.label)
                            .frame(width: 36, height: 36)
                            .contentShape(Circle())
                    }
                    .accessibilityLabel("Más opciones")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    OGToolbarGlassButton(
                        systemName: "play.fill",
                        accessibilityLabel: "Comenzar",
                        tint: OG.accent
                    ) {
                        guard let routine = liveRoutine else { return }
                        store.startSession(from: routine)
                        onStart()
                    }
                }
            }
        }
        .sheet(isPresented: $showDeleteConfirm) {
            OGConfirmSheet(
                title: "¿Borrar entreno?",
                message: deleteConfirmMessage,
                confirmTitle: "Borrar entreno",
                onConfirm: {
                    showDeleteConfirm = false
                    deleteCurrentEntreno()
                },
                onCancel: { showDeleteConfirm = false }
            )
        }
    }

    private var deleteConfirmMessage: String {
        guard let routine = liveRoutine else {
            return "No se puede deshacer."
        }
        return routine.isOneOff
            ? "Se eliminará «\(routine.title)» de este día."
            : "Se quitará «\(routine.title)» de este día. La plantilla seguirá en Rutinas."
    }

    private func deleteCurrentEntreno() {
        guard let routine = liveRoutine else { return }
        if routine.isOneOff {
            store.deleteRoutine(routine.id)
        } else {
            store.assignRoutine(routine.id, toWeekday: nil)
        }
        editedSnapshot = nil
        onClose()
    }

    private func activeBanner(_ session: WorkoutSession) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(OG.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text("Sesión en curso")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(OG.orange)
                Text(session.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(OG.label)
                if let current = session.currentExercise {
                    Text("Ahora: \(current.exercise.name) · \(session.progressLabel)")
                        .font(.system(size: 13))
                        .foregroundStyle(OG.label2)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(OG.label3)
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func flatExercises(_ routine: Routine) -> some View {
        let synthetic = RoutineBlock.strength(title: "Ejercicios", exercises: routine.exercises)
        OGRoutineBlockCard(block: synthetic)
            .ogCardListRow(top: 0, bottom: 8)
    }
}

// MARK: - Apuntar resultado final

struct LogFinalResultsView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var routine: Routine
    var onSaved: () -> Void

    @State private var blocks: [DraftBlock] = []
    @State private var notes = ""
    @State private var startedAt = Date().addingTimeInterval(-60 * 60)
    @State private var finishedAt = Date()
    @State private var locationPin: WorkoutLocationPin?

    private var weightStep: Double { store.state.settings.weightIncrementKg }

    var body: some View {
        List {
            Section {
                Text(routine.title)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(OG.label2)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: -14, leading: 0, bottom: 0, trailing: 0))
                    .listRowSeparator(.hidden)
            }
            .listSectionSpacing(4)

            Section {
                DatePicker(
                    "Inicio",
                    selection: $startedAt,
                    displayedComponents: [.date, .hourAndMinute]
                )
                DatePicker(
                    "Fin",
                    selection: Binding(
                        get: { finishedAt },
                        set: { finishedAt = max($0, startedAt.addingTimeInterval(60)) }
                    ),
                    displayedComponents: [.date, .hourAndMinute]
                )
            } header: {
                Text("Horario")
            } footer: {
                Text(durationFooter)
            }

            ForEach($blocks) { $block in
                switch block.capture {
                case .totalReps:
                    Section {
                        labeledScoreStepper(title: "Rondas", value: $block.roundsCompleted, range: 0...200)
                        labeledScoreStepper(title: "Reps", value: $block.totalReps, range: 0...5000)
                        ForEach(block.exercises.prefix(4)) { draft in
                            exerciseHeaderRow(draft: draft)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    } header: {
                        blockSectionHeader(title: block.title, kindLabel: block.kindLabel)
                    } footer: {
                        Text("AMRAP: rondas completas + reps de la ronda que no terminaste (p. ej. 12 + 5).")
                    }
                case .elapsedTime:
                    Section {
                        HStack(spacing: 12) {
                            Text("Tiempo")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(OG.label2)
                                .frame(width: 88, alignment: .leading)
                            OGRepeatStepper(
                                display: DurationText.format(block.elapsedSeconds),
                                keyboard: .numbersAndPunctuation,
                                onMinus: {
                                    block.elapsedSeconds = max(0, block.elapsedSeconds - 5)
                                },
                                onPlus: {
                                    block.elapsedSeconds = min(180 * 60, block.elapsedSeconds + 5)
                                },
                                onCommitText: { text in
                                    if let parsed = DurationText.parse(text) {
                                        block.elapsedSeconds = min(180 * 60, parsed)
                                    }
                                }
                            )
                        }
                        ForEach(block.exercises.prefix(4)) { draft in
                            exerciseHeaderRow(draft: draft)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    } header: {
                        blockSectionHeader(title: block.title, kindLabel: block.kindLabel)
                    } footer: {
                        Text("For Time / RFT / chipper: tiempo de finalización (m:ss).")
                    }
                case .perMovementSets:
                    ForEach($block.exercises) { $draft in
                        Section {
                            let catalogEx = resolvedCatalogExercise(draft.exercise)
                            exerciseHeaderRow(draft: draft)
                                .listRowInsets(EdgeInsets(top: 14, leading: 16, bottom: 4, trailing: 16))
                                .listRowBackground(OG.surface)
                                .listRowSeparator(.hidden)

                            setColumnHeadersRow(
                                style: catalogEx.loggingStyle,
                                quantityLabel: catalogEx.quantityFieldLabel,
                                quantityUnit: catalogEx.defaultQuantityUnit,
                                exercise: catalogEx
                            )
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 2, trailing: 16))
                            .listRowBackground(OG.surface)
                            .listRowSeparator(.hidden)

                            ForEach($draft.sets) { $set in
                                setStepperRow(
                                    set: $set,
                                    style: catalogEx.loggingStyle,
                                    quantityUnit: catalogEx.defaultQuantityUnit,
                                    allowsUnitToggle: catalogEx.allowsCalorieOrDistanceToggle,
                                    loadField: catalogEx.loadField,
                                    quantityLabel: catalogEx.quantityFieldLabel
                                )
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    .listRowBackground(OG.surface)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        if draft.sets.count > 1 {
                                            OGSwipeDeleteButton {
                                                deleteSet(blockId: block.id, exerciseId: draft.id, setId: set.id)
                                            }
                                        }
                                    }
                            }

                            Button {
                                addSet(blockId: block.id, exerciseId: draft.id)
                            } label: {
                                Label("Añadir serie", systemImage: "plus")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(OG.accent)
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 14, trailing: 16))
                            .listRowBackground(OG.surface)
                            .listRowSeparator(.hidden)
                        } header: {
                            if block.exercises.first?.id == draft.id {
                                blockSectionHeader(title: block.title, kindLabel: block.kindLabel)
                            }
                        }
                    }
                }
            }

            Section {
                WorkoutPlacePickerRow(pin: $locationPin)
            } header: {
                Text("Lugar")
            }

            Section("Notas") {
                TextField("Opcional", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
            }
        }
        .ogListChrome()
        .listSectionSpacing(8)
        .ogPinnedTransparentNav("Resultado final")
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                OGToolbarGlassButton(
                    systemName: "checkmark",
                    accessibilityLabel: "Guardar y terminar",
                    tint: canSave ? OG.accent : OG.label3
                ) {
                    guard canSave else { return }
                    save()
                }
                .opacity(canSave ? 1 : 0.45)
                .disabled(!canSave)
            }
        }
        .onAppear {
            if blocks.isEmpty {
                blocks = Self.makeBlocks(routine: routine, catalog: store.state.exercises)
                seedScheduleDefaults()
            }
            let thumbs = blocks.flatMap { block in
                block.exercises.map { resolvedCatalogExercise($0.exercise) }
            }
            ExerciseArt.prefetchThumbs(for: thumbs, pointSize: 48, limit: 24)
        }
        .onChange(of: startedAt) { _, newStart in
            if finishedAt <= newStart {
                finishedAt = newStart.addingTimeInterval(60 * 60)
            }
        }
    }

    private var durationFooter: String {
        let minutes = max(1, Int(finishedAt.timeIntervalSince(startedAt) / 60))
        return "Duración: \(minutes) min"
    }

    private func seedScheduleDefaults() {
        let day = routine.scheduledDate ?? Date()
        if let planned = routine.scheduledDateTime(on: day) {
            startedAt = planned
            finishedAt = planned.addingTimeInterval(60 * 60)
        } else {
            finishedAt = Date()
            startedAt = finishedAt.addingTimeInterval(-60 * 60)
        }
    }

    private func blockSectionHeader(title: String, kindLabel: String?) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(OG.accent)
                .textCase(nil)
            if let kindLabel {
                Text("·")
                    .foregroundStyle(OG.label3)
                Text(kindLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(OG.label3)
                    .textCase(nil)
            }
        }
    }

    private func exerciseHeaderRow(draft: DraftExercise) -> some View {
        let exercise = resolvedCatalogExercise(draft.exercise)
        return NavigationLink {
            ExerciseDetailView(exerciseId: exercise.id)
        } label: {
            HStack(spacing: 12) {
                ExerciseThumb(exercise: exercise, size: 52)
                Text(exercise.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(OG.label)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
        }
        .accessibilityHint("Ver ficha del ejercicio")
    }

    /// id → catálogo → canónico limpio (quita @RIR / W.S. / DB…) para arte y título.
    private func resolvedCatalogExercise(_ exercise: Exercise, notes: String? = nil) -> Exercise {
        let canonical = CrossFitGlossary.resolveCatalogName(exercise.name, notes: notes)
        if let ex = store.state.exercises.first(where: { $0.id == exercise.id }) {
            return ex
        }
        if let match = store.state.exercises.first(where: {
            $0.name.localizedCaseInsensitiveCompare(exercise.name) == .orderedSame
                || $0.name.localizedCaseInsensitiveCompare(canonical) == .orderedSame
        }) {
            return match
        }
        guard !canonical.isEmpty, canonical != exercise.name else { return exercise }
        return Exercise(
            id: exercise.id,
            name: canonical,
            muscleGroup: exercise.muscleGroup,
            isCustom: exercise.isCustom
        )
    }

    private func labeledScoreStepper(
        title: String,
        value: Binding<Int>,
        range: ClosedRange<Int>
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(OG.label2)
                .frame(width: 88, alignment: .leading)
            OGRepeatStepper(
                display: "\(value.wrappedValue)",
                keyboard: .numberPad,
                onMinus: { value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1) },
                onPlus: { value.wrappedValue = min(range.upperBound, value.wrappedValue + 1) },
                onCommitText: { text in
                    if let parsed = Int(text.filter(\.isNumber)) {
                        value.wrappedValue = min(range.upperBound, max(range.lowerBound, parsed))
                    }
                }
            )
        }
    }

    private func setColumnHeadersRow(
        style: ExerciseLoggingStyle,
        quantityLabel: String,
        quantityUnit: ExerciseQuantityUnit,
        exercise: Exercise
    ) -> some View {
        HStack(spacing: 8) {
            switch style {
            case .loadAndReps:
                columnHeaderLabel(
                    Exercise.loadStepperTitle(
                        name: exercise.name,
                        equipment: exercise.equipment
                    ),
                    flexible: true
                )
                columnHeaderLabel(quantityLabel, flexible: true)
            case .repsAndTime:
                // Veces primero, tiempo después («50 dobles en 1:00»).
                columnHeaderLabel(quantityLabel, flexible: true)
                columnHeaderLabel("Tiempo", flexible: true)
            case .machineWork:
                columnHeaderLabel("Tiempo", flexible: true)
                columnHeaderLabel(quantityUnit.shortLabel, flexible: true)
            case .repsOnly:
                columnHeaderLabel(quantityLabel, flexible: true)
            }

            if style.usesRIR {
                columnHeaderLabel("RIR", width: 48)
            }
        }
    }

    @ViewBuilder
    private func columnHeaderLabel(_ title: String, flexible: Bool = false, width: CGFloat? = nil) -> some View {
        let label = Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(OG.label3)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .multilineTextAlignment(.center)
            .textCase(nil)
        if flexible {
            label.frame(maxWidth: .infinity, alignment: .center)
        } else if let width {
            label.frame(width: width, alignment: .center)
        } else {
            label
        }
    }

    private func setStepperRow(
        set: Binding<DraftSet>,
        style: ExerciseLoggingStyle,
        quantityUnit: ExerciseQuantityUnit = .reps,
        allowsUnitToggle: Bool = false,
        loadField: ExerciseLoadField = .weightKg,
        quantityLabel: String = "Reps"
    ) -> some View {
        let maxReps = style.quantityCap
        let activeUnit = set.wrappedValue.quantityUnit ?? quantityUnit
        let qtyStep: Int = {
            if style == .machineWork, activeUnit == .meters { return 50 }
            if style == .repsAndTime { return 5 }
            return 1
        }()
        return VStack(alignment: .leading, spacing: 8) {
            if style == .machineWork, allowsUnitToggle {
                Picker("Unidad", selection: Binding(
                    get: { set.wrappedValue.quantityUnit ?? quantityUnit },
                    set: { unit in
                        var value = set.wrappedValue
                        value.quantityUnit = unit
                        set.wrappedValue = value
                    }
                )) {
                    Text("Cal").tag(ExerciseQuantityUnit.calories)
                    Text("m").tag(ExerciseQuantityUnit.meters)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            HStack(spacing: 8) {
                switch style {
                case .loadAndReps:
                    if loadField == .deficitCm {
                        OGRepeatStepper(
                            display: set.wrappedValue.deficitCm.map(String.init) ?? "0",
                            keyboard: .numberPad,
                            onMinus: {
                                var value = set.wrappedValue
                                value.deficitCm = max(0, (value.deficitCm ?? 0) - 1)
                                set.wrappedValue = value
                            },
                            onPlus: {
                                var value = set.wrappedValue
                                value.deficitCm = min(60, (value.deficitCm ?? 0) + 1)
                                set.wrappedValue = value
                            },
                            onCommitText: { text in
                                var value = set.wrappedValue
                                if let parsed = Int(text.filter(\.isNumber)) {
                                    value.deficitCm = min(60, max(0, parsed))
                                }
                                set.wrappedValue = value
                            }
                        )
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("Déficit cm")
                    } else {
                        OGRepeatStepper(
                            display: set.wrappedValue.weightKg.map { String(format: "%g", $0) } ?? "—",
                            keyboard: .decimalPad,
                            onMinus: {
                                var value = set.wrappedValue
                                let current = value.weightKg ?? 0
                                let next = max(0, ((current - weightStep) * 10).rounded() / 10)
                                value.weightKg = next > 0 ? next : nil
                                set.wrappedValue = value
                            },
                            onPlus: {
                                var value = set.wrappedValue
                                let current = value.weightKg ?? 0
                                value.weightKg = ((current + weightStep) * 10).rounded() / 10
                                set.wrappedValue = value
                            },
                            onCommitText: { text in
                                var value = set.wrappedValue
                                let normalized = text.replacingOccurrences(of: ",", with: ".")
                                if normalized.isEmpty {
                                    value.weightKg = nil
                                } else if let parsed = Double(normalized) {
                                    value.weightKg = parsed > 0 ? ((parsed * 10).rounded() / 10) : nil
                                }
                                set.wrappedValue = value
                            }
                        )
                        .frame(maxWidth: .infinity)
                    }

                    quantityStepper(
                        set: set,
                        maxReps: maxReps,
                        qtyStep: qtyStep,
                        accessibilityLabel: quantityLabel
                    )
                    .frame(maxWidth: .infinity)

                case .repsAndTime:
                    quantityStepper(
                        set: set,
                        maxReps: maxReps,
                        qtyStep: qtyStep,
                        accessibilityLabel: quantityLabel
                    )
                    .frame(maxWidth: .infinity)

                    durationStepper(set: set)
                        .frame(maxWidth: .infinity)

                case .machineWork:
                    durationStepper(set: set)
                        .frame(maxWidth: .infinity)

                    quantityStepper(
                        set: set,
                        maxReps: maxReps,
                        qtyStep: qtyStep,
                        accessibilityLabel: activeUnit.shortLabel
                    )
                    .frame(maxWidth: .infinity)

                case .repsOnly:
                    quantityStepper(
                        set: set,
                        maxReps: maxReps,
                        qtyStep: qtyStep,
                        accessibilityLabel: quantityLabel
                    )
                    .frame(maxWidth: .infinity)
                }

                if style.usesRIR {
                    Menu {
                        Button("Sin RIR") {
                            var value = set.wrappedValue
                            value.rir = nil
                            set.wrappedValue = value
                        }
                        ForEach(0...5, id: \.self) { rir in
                            Button("\(rir)") {
                                var value = set.wrappedValue
                                value.rir = Double(rir)
                                set.wrappedValue = value
                            }
                        }
                    } label: {
                        Text(set.wrappedValue.rir.map { "\(Int($0.rounded()))" } ?? "RIR")
                            .font(.system(size: 15, weight: .semibold).monospacedDigit())
                            .foregroundStyle(set.wrappedValue.rir == nil ? OG.label3 : OG.label)
                            .frame(width: 56, height: 48)
                            .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
    }

    private func quantityStepper(
        set: Binding<DraftSet>,
        maxReps: Int,
        qtyStep: Int,
        accessibilityLabel: String
    ) -> some View {
        OGRepeatStepper(
            display: "\(set.wrappedValue.reps)",
            keyboard: .numberPad,
            onMinus: {
                var value = set.wrappedValue
                value.reps = max(0, value.reps - qtyStep)
                set.wrappedValue = value
            },
            onPlus: {
                var value = set.wrappedValue
                value.reps = min(maxReps, value.reps + qtyStep)
                set.wrappedValue = value
            },
            onCommitText: { text in
                var value = set.wrappedValue
                if let parsed = Int(text) {
                    value.reps = min(maxReps, max(0, parsed))
                }
                set.wrappedValue = value
            }
        )
        .accessibilityLabel(accessibilityLabel)
    }

    private func durationStepper(set: Binding<DraftSet>) -> some View {
        OGRepeatStepper(
            display: DurationText.format(set.wrappedValue.durationSeconds),
            keyboard: .numbersAndPunctuation,
            onMinus: {
                var value = set.wrappedValue
                value.durationSeconds = max(0, (value.durationSeconds ?? 0) - 5)
                set.wrappedValue = value
            },
            onPlus: {
                var value = set.wrappedValue
                value.durationSeconds = (value.durationSeconds ?? 0) + 5
                set.wrappedValue = value
            },
            onCommitText: { text in
                var value = set.wrappedValue
                value.durationSeconds = DurationText.parse(text)
                set.wrappedValue = value
            }
        )
        .accessibilityLabel("Tiempo")
    }

    private func addSet(blockId: UUID, exerciseId: UUID) {
        guard let bIdx = blocks.firstIndex(where: { $0.id == blockId }),
              let eIdx = blocks[bIdx].exercises.firstIndex(where: { $0.id == exerciseId })
        else { return }
        let last = blocks[bIdx].exercises[eIdx].sets.last
        blocks[bIdx].exercises[eIdx].sets.append(
            DraftSet(
                reps: last?.reps ?? 8,
                weightKg: last?.weightKg,
                deficitCm: last?.deficitCm,
                durationSeconds: last?.durationSeconds,
                quantityUnit: last?.quantityUnit,
                rir: last?.rir
            )
        )
    }

    private func deleteSet(blockId: UUID, exerciseId: UUID, setId: UUID) {
        guard let bIdx = blocks.firstIndex(where: { $0.id == blockId }),
              let eIdx = blocks[bIdx].exercises.firstIndex(where: { $0.id == exerciseId }),
              blocks[bIdx].exercises[eIdx].sets.count > 1,
              let sIdx = blocks[bIdx].exercises[eIdx].sets.firstIndex(where: { $0.id == setId })
        else { return }
        blocks[bIdx].exercises[eIdx].sets.remove(at: sIdx)
    }

    private var canSave: Bool {
        blocks.contains { block in
            switch block.capture {
            case .totalReps:
                return block.totalReps > 0 || block.roundsCompleted > 0
            case .elapsedTime:
                return block.elapsedSeconds > 0
            case .perMovementSets:
                return block.exercises.contains { draft in
                    draft.sets.contains { $0.reps > 0 || ($0.weightKg ?? 0) > 0 }
                }
            }
        }
    }

    private func save() {
        let sessionExercises: [SessionExercise] = blocks.flatMap { block in
            block.exercises.enumerated().map { _, draft in
                let logged: [LoggedSet]
                switch block.capture {
                case .totalReps, .elapsedTime:
                    // Score en `wodResults`; los movimientos solo llevan la prescripción.
                    logged = []
                case .perMovementSets:
                    let catalogEx = resolvedCatalogExercise(draft.exercise)
                    let style = catalogEx.loggingStyle
                    logged = draft.sets.compactMap { set -> LoggedSet? in
                        guard set.reps > 0
                            || (style.usesLoad && (set.weightKg ?? 0) > 0)
                            || (style.usesDuration && (set.durationSeconds ?? 0) > 0)
                        else { return nil }
                        let loadField = catalogEx.loadField
                        return LoggedSet(
                            reps: max(1, set.reps),
                            weightKg: loadField == .weightKg ? set.weightKg : nil,
                            deficitCm: loadField == .deficitCm
                                ? set.deficitCm.flatMap { $0 > 0 ? $0 : nil }
                                : nil,
                            durationSeconds: style.usesDuration ? set.durationSeconds : nil,
                            quantityUnit: style == .machineWork
                                ? (set.quantityUnit ?? catalogEx.defaultQuantityUnit)
                                : nil,
                            rir: style.usesRIR ? set.rir : nil
                        )
                    }
                }
                let scored = (block.capture == .totalReps && (block.totalReps > 0 || block.roundsCompleted > 0))
                    || (block.capture == .elapsedTime && block.elapsedSeconds > 0)
                return SessionExercise(
                    exercise: draft.exercise,
                    plannedSets: draft.plannedSets,
                    loggedSets: logged,
                    isCompleted: !logged.isEmpty || scored,
                    blockId: block.id,
                    blockKind: block.kind,
                    wodFormat: block.wodFormat,
                    blockTimeCapMinutes: block.timeCapMinutes,
                    blockIntervalSeconds: block.intervalSeconds,
                    blockRounds: block.rounds,
                    blockHeader: block.title,
                    blockWorkSeconds: block.workSeconds,
                    blockRestSeconds: block.restSeconds
                )
            }
        }
        let wodResults: [WODBlockResult] = blocks.compactMap { block in
            switch block.capture {
            case .totalReps:
                guard block.totalReps > 0 || block.roundsCompleted > 0 else { return nil }
                return WODBlockResult(
                    id: block.id,
                    format: block.wodFormat,
                    totalReps: block.totalReps > 0 ? block.totalReps : nil,
                    roundsCompleted: block.roundsCompleted > 0 ? block.roundsCompleted : nil,
                    wodTemplateId: block.wodTemplateId
                )
            case .elapsedTime:
                guard block.elapsedSeconds > 0 else { return nil }
                return WODBlockResult(
                    id: block.id,
                    format: block.wodFormat,
                    elapsedSeconds: block.elapsedSeconds,
                    wodTemplateId: block.wodTemplateId
                )
            case .perMovementSets:
                return nil
            }
        }
        var effectiveFinished = finishedAt
        if let timeResult = wodResults.first(where: { $0.elapsedSeconds != nil }),
           let elapsed = timeResult.elapsedSeconds {
            effectiveFinished = startedAt.addingTimeInterval(TimeInterval(elapsed))
        }
        _ = store.logFinalResults(
            from: routine,
            exercises: sessionExercises,
            notes: notes,
            startedAt: startedAt,
            finishedAt: effectiveFinished,
            wodResults: wodResults,
            locationPin: locationPin
        )
        onSaved()
    }

    private static func makeBlocks(routine: Routine, catalog: [Exercise]) -> [DraftBlock] {
        let session = SessionController.from(routine: routine, exercises: catalog)
        var orderedIds: [UUID] = []
        var grouped: [UUID: DraftBlock] = [:]
        let routineBlocksById = Dictionary(uniqueKeysWithValues: routine.blocks.map { ($0.id, $0) })

        for item in session.exercises {
            let blockId = item.blockId ?? UUID()
            let title = item.blockHeader
                ?? (item.blockKind == .wod ? (item.wodFormat?.displayName ?? "WOD") : "Bloque")
            if grouped[blockId] == nil {
                orderedIds.append(blockId)
                let format = item.wodFormat ?? routineBlocksById[blockId]?.wodFormat
                let capture: WODResultCapture
                if item.blockKind == .wod, let format {
                    capture = format.resultCapture
                } else {
                    capture = .perMovementSets
                }
                let defaultElapsed: Int = {
                    if let cap = item.blockTimeCapMinutes, cap > 0 { return cap * 60 }
                    return 10 * 60
                }()
                grouped[blockId] = DraftBlock(
                    id: blockId,
                    title: title,
                    kind: item.blockKind,
                    wodFormat: format,
                    capture: capture,
                    wodTemplateId: routineBlocksById[blockId]?.wodTemplateId,
                    timeCapMinutes: item.blockTimeCapMinutes ?? routineBlocksById[blockId]?.timeCapMinutes,
                    intervalSeconds: item.blockIntervalSeconds ?? routineBlocksById[blockId]?.emomIntervalSeconds,
                    rounds: item.blockRounds ?? routineBlocksById[blockId]?.rounds,
                    workSeconds: item.blockWorkSeconds ?? routineBlocksById[blockId]?.workSeconds,
                    restSeconds: item.blockRestSeconds ?? routineBlocksById[blockId]?.restSeconds,
                    totalReps: 0,
                    elapsedSeconds: defaultElapsed,
                    roundsCompleted: item.blockRounds ?? 0,
                    exercises: []
                )
            }
            let style = item.exercise.loggingStyle
            let unit: ExerciseQuantityUnit? = style == .machineWork ? item.exercise.defaultQuantityUnit : nil
            let defaultQty = style == .machineWork
                ? (unit == .meters ? 500 : 15)
                : 8
            let sets: [DraftSet]
            if item.plannedSets.isEmpty {
                sets = [DraftSet(
                    reps: defaultQty,
                    weightKg: nil,
                    durationSeconds: style.usesDuration ? 60 : nil,
                    quantityUnit: unit,
                    rir: nil
                )]
            } else {
                sets = item.plannedSets.map {
                    DraftSet(
                        reps: $0.targetReps,
                        weightKg: $0.targetWeightKg,
                        durationSeconds: style.usesDuration ? 60 : nil,
                        quantityUnit: unit,
                        rir: $0.targetRir
                    )
                }
            }
            grouped[blockId]?.exercises.append(
                DraftExercise(
                    exercise: item.exercise,
                    plannedSets: item.plannedSets,
                    sets: sets
                )
            )
        }

        return orderedIds.compactMap { grouped[$0] }
    }
}

private struct DraftBlock: Identifiable {
    let id: UUID
    var title: String
    var kind: RoutineBlockKind?
    var wodFormat: WODFormat?
    var capture: WODResultCapture
    var wodTemplateId: String?
    var timeCapMinutes: Int? = nil
    var intervalSeconds: Int? = nil
    var rounds: Int? = nil
    var workSeconds: Int? = nil
    var restSeconds: Int? = nil
    var totalReps: Int
    var elapsedSeconds: Int
    var roundsCompleted: Int
    var exercises: [DraftExercise]

    var kindLabel: String? {
        if let wodFormat { return wodFormat.displayName }
        switch kind {
        case .strength: return "Fuerza"
        case .wod: return "WOD"
        case nil: return nil
        }
    }
}

private struct DraftExercise: Identifiable {
    let id = UUID()
    var exercise: Exercise
    var plannedSets: [PlannedSet]
    var sets: [DraftSet]
}

private struct DraftSet: Identifiable {
    let id = UUID()
    var reps: Int
    var weightKg: Double? = nil
    var deficitCm: Int? = nil
    var durationSeconds: Int? = nil
    var quantityUnit: ExerciseQuantityUnit? = nil
    var rir: Double? = nil
}
