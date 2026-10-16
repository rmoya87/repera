import GymbroDomain
import SwiftUI

/// Resumen del plan antes de empezar, o gestión de sesión en curso.
/// Top bar: X · Entreno · día debajo · ⋯ (editar / apuntar) · ▶ comenzar.
struct SessionPreviewView: View {
    @Environment(GymbroStore.self) private var store

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
            Section {
                OGPageHeader(
                    title: active != nil ? "Sesión" : "Entreno",
                    subtitle: active == nil ? dayLabel : nil
                ) {
                    CloseToolbarButton(action: onClose, large: true)
                } trailing: {
                    if active != nil {
                        // Eliminar: swipe en la tarjeta de sesión en curso.
                        EmptyView()
                    } else if liveRoutine != nil {
                        HStack(spacing: 8) {
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
                                    .font(.system(size: OG.toolbarGlassIcon, weight: .semibold))
                                    .foregroundStyle(OG.label)
                                    .frame(width: OG.toolbarGlassSize, height: OG.toolbarGlassSize)
                                    .contentShape(Circle())
                                    .glassEffect(.regular.interactive(), in: .circle)
                            }
                            .accessibilityLabel("Más opciones")

                            OGToolbarGlassButton(
                                systemName: "play.fill",
                                accessibilityLabel: "Comenzar",
                                tint: OG.accent,
                                appliesGlass: true,
                                glassTint: OG.accent
                            ) {
                                guard let routine = liveRoutine else { return }
                                store.startSession(from: routine)
                                onStart()
                            }
                        }
                    }
                }
                .ogListPageHeaderRow()
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
                        Button(role: .destructive) {
                            store.endActiveSession(save: false)
                            onClose()
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                        .tint(OG.red)
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
                        ForEach(routine.blocks) { block in
                            blockCard(block)
                                .ogCardListRow(top: 0, bottom: 8)
                        }
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
        .ogContentTitleNav()
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
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

    private func blockCard(_ block: RoutineBlock) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(block.headerLabel)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(OG.accent)
                Spacer()
                if let cap = block.timeCapMinutes {
                    Text("\(cap)'")
                        .font(.system(size: 13, weight: .semibold).monospacedDigit())
                        .foregroundStyle(OG.label2)
                }
            }

            if block.kind == .strength {
                ForEach(block.exercises) { item in
                    if let ex = store.state.exercises.first(where: { $0.id == item.exerciseId }) {
                        exerciseRow(
                            ex,
                            detail: "\(item.plannedSets.count)×\(item.plannedSets.first?.targetReps ?? 0)"
                        )
                    }
                }
            } else {
                ForEach(block.movements.filter { !$0.isRest }) { move in
                    exerciseRow(resolvedExercise(move), detail: moveDetail(move))
                }
            }
        }
        .padding(OG.pad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }

    private func flatExercises(_ routine: Routine) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(routine.exercises) { item in
                if let ex = store.state.exercises.first(where: { $0.id == item.exerciseId }) {
                    exerciseRow(
                        ex,
                        detail: "\(item.plannedSets.count)×\(item.plannedSets.first?.targetReps ?? 0)"
                    )
                }
            }
        }
        .padding(OG.pad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private func exerciseRow(_ exercise: Exercise, detail: String) -> some View {
        HStack(spacing: 12) {
            ExerciseThumb(exercise: exercise, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(OG.label)
                    .lineLimit(2)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(OG.label3)
            }
            Spacer(minLength: 0)
        }
    }

    private func resolvedExercise(_ move: WODMovement) -> Exercise {
        if let id = move.exerciseId, let ex = store.state.exercises.first(where: { $0.id == id }) {
            return ex
        }
        if let match = store.state.exercises.first(where: {
            $0.name.localizedCaseInsensitiveCompare(move.name) == .orderedSame
        }) {
            return match
        }
        return Exercise(name: move.name, muscleGroup: "WOD", isCustom: true)
    }

    private func moveDetail(_ move: WODMovement) -> String {
        var parts: [String] = []
        if let reps = move.reps { parts.append("\(reps) reps") }
        if let m = move.distanceMeters { parts.append("\(m) m") }
        if let cal = move.calories { parts.append("\(cal) cal") }
        if let w = move.weightMaleKg { parts.append(String(format: "%g kg", w)) }
        return parts.isEmpty ? "Movimiento" : parts.joined(separator: " · ")
    }
}

// MARK: - Apuntar resultado final

struct LogFinalResultsView: View {
    @Environment(GymbroStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var routine: Routine
    var onSaved: () -> Void

    @State private var blocks: [DraftBlock] = []
    @State private var notes = ""
    @State private var startedAt = Date().addingTimeInterval(-60 * 60)
    @State private var finishedAt = Date()

    private var weightStep: Double { store.state.settings.weightIncrementKg }

    var body: some View {
        List {
            Section {
                OGPageHeader(title: "Resultado final", subtitle: routine.title) {
                    CloseToolbarButton(action: { dismiss() }, large: true)
                } trailing: {
                    OGToolbarGlassButton(
                        systemName: "checkmark",
                        accessibilityLabel: "Guardar y terminar",
                        tint: canSave ? OG.accent : OG.label3,
                        appliesGlass: true
                    ) {
                        guard canSave else { return }
                        save()
                    }
                    .opacity(canSave ? 1 : 0.45)
                    .disabled(!canSave)
                }
                .ogListPageHeaderRow()
            } footer: {
                Text("Inicio y fin sirven para tiempo, kcal y emparejar con Apple Salud. Si coincide la franja, mandan los datos de Salud.")
            }

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
                ForEach($block.exercises) { $draft in
                    Section {
                        exerciseHeaderRow(draft: draft)
                            .listRowInsets(EdgeInsets(top: 14, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(OG.surface)
                            .listRowSeparator(.hidden)

                        ForEach($draft.sets) { $set in
                            setStepperRow(set: $set)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowBackground(OG.surface)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    if draft.sets.count > 1 {
                                        Button(role: .destructive) {
                                            deleteSet(blockId: block.id, exerciseId: draft.id, setId: set.id)
                                        } label: {
                                            Label("Eliminar", systemImage: "trash")
                                        }
                                        .tint(OG.red)
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

            Section("Notas") {
                TextField("Opcional", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
            }
        }
        .ogListChrome()
        .ogContentTitleNav()
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            if blocks.isEmpty {
                blocks = Self.makeBlocks(routine: routine, catalog: store.state.exercises)
                seedScheduleDefaults()
            }
        }
        .onChange(of: startedAt) { _, newStart in
            if finishedAt <= newStart {
                finishedAt = newStart.addingTimeInterval(60 * 60)
            }
        }
        .preferredColorScheme(.dark)
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
        HStack(spacing: 12) {
            ExerciseThumb(exercise: draft.exercise, size: 48)
            Text(draft.exercise.name)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(OG.label)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
    }

    private func setStepperRow(set: Binding<DraftSet>) -> some View {
        HStack(spacing: 8) {
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

            OGRepeatStepper(
                display: "\(set.wrappedValue.reps)",
                keyboard: .numberPad,
                onMinus: {
                    var value = set.wrappedValue
                    value.reps = max(0, value.reps - 1)
                    set.wrappedValue = value
                },
                onPlus: {
                    var value = set.wrappedValue
                    value.reps = min(50, value.reps + 1)
                    set.wrappedValue = value
                },
                onCommitText: { text in
                    var value = set.wrappedValue
                    if let parsed = Int(text) {
                        value.reps = min(50, max(0, parsed))
                    }
                    set.wrappedValue = value
                }
            )
            .frame(width: 88)

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
                Text(set.wrappedValue.rir.map { String(format: "%g", $0) } ?? "RIR")
                    .font(.system(size: 13, weight: .semibold).monospacedDigit())
                    .foregroundStyle(set.wrappedValue.rir == nil ? OG.label3 : OG.label)
                    .frame(width: 48, height: 36)
                    .background(OG.surface2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    private func addSet(blockId: UUID, exerciseId: UUID) {
        guard let bIdx = blocks.firstIndex(where: { $0.id == blockId }),
              let eIdx = blocks[bIdx].exercises.firstIndex(where: { $0.id == exerciseId })
        else { return }
        let last = blocks[bIdx].exercises[eIdx].sets.last
        blocks[bIdx].exercises[eIdx].sets.append(
            DraftSet(reps: last?.reps ?? 8, weightKg: last?.weightKg, rir: last?.rir)
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
            block.exercises.contains { draft in
                draft.sets.contains { $0.reps > 0 || ($0.weightKg ?? 0) > 0 }
            }
        }
    }

    private func save() {
        let sessionExercises: [SessionExercise] = blocks.flatMap { block in
            block.exercises.map { draft in
                let logged = draft.sets.compactMap { set -> LoggedSet? in
                    guard set.reps > 0 || (set.weightKg ?? 0) > 0 else { return nil }
                    return LoggedSet(
                        reps: max(1, set.reps),
                        weightKg: set.weightKg,
                        rir: set.rir
                    )
                }
                return SessionExercise(
                    exercise: draft.exercise,
                    plannedSets: draft.plannedSets,
                    loggedSets: logged,
                    isCompleted: !logged.isEmpty,
                    blockId: block.id,
                    blockKind: block.kind,
                    blockHeader: block.title
                )
            }
        }
        _ = store.logFinalResults(
            from: routine,
            exercises: sessionExercises,
            notes: notes,
            startedAt: startedAt,
            finishedAt: finishedAt
        )
        onSaved()
    }

    private static func makeBlocks(routine: Routine, catalog: [Exercise]) -> [DraftBlock] {
        let session = SessionController.from(routine: routine, exercises: catalog)
        var orderedIds: [UUID] = []
        var grouped: [UUID: DraftBlock] = [:]

        for item in session.exercises {
            let blockId = item.blockId ?? UUID()
            let title = item.blockHeader
                ?? (item.blockKind == .wod ? (item.wodFormat?.displayName ?? "WOD") : "Bloque")
            if grouped[blockId] == nil {
                orderedIds.append(blockId)
                grouped[blockId] = DraftBlock(
                    id: blockId,
                    title: title,
                    kind: item.blockKind,
                    exercises: []
                )
            }
            let sets: [DraftSet]
            if item.plannedSets.isEmpty {
                sets = [DraftSet(reps: 8, weightKg: nil, rir: nil)]
            } else {
                sets = item.plannedSets.map {
                    DraftSet(reps: $0.targetReps, weightKg: $0.targetWeightKg, rir: $0.targetRir)
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

        // Si el plan tiene bloques vacíos, no aparecen en la sesión; no hace falta.
        return orderedIds.compactMap { grouped[$0] }
    }
}

private struct DraftBlock: Identifiable {
    let id: UUID
    var title: String
    var kind: RoutineBlockKind?
    var exercises: [DraftExercise]

    var kindLabel: String? {
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
    var weightKg: Double?
    var rir: Double?
}
