import ReperaDomain
import SwiftUI
import UniformTypeIdentifiers

// El antiguo Diario y sus pestañas se han retirado.
// Se mantienen únicamente los editores de entreno compartidos por Inicio,
// Favoritos, sesiones terminadas e importación de pizarra.

// MARK: - Editor de rutina / día / crear entreno

/// Chrome del editor: página push → volver + check; modal → solo check (swipe para cerrar).
private struct DayEditorChromeModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let usesPageCloseHeader: Bool
    let embedsNavigationStack: Bool
    let canConfirm: Bool
    let confirmTitle: String
    let onConfirm: () -> Void
    var onBack: (() -> Void)? = nil

    func body(content: Content) -> some View {
        if usesPageCloseHeader {
            content
                .ogScrollingTitleNav()
                // Usar solo el chevron nativo de NavigationStack.
                // El botón manual duplicaba el volver en iOS 27.
                .navigationBarBackButtonHidden(false)
                // Siempre blanco de noche y negro de día; el check mantiene
                // su tinte verde explícito, independiente del botón Volver.
                .tint(Color.primary)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        confirmButton
                    }
                }
        } else {
            content
                .ogFixedTopBar(title) { confirmButton }
                .navigationBarBackButtonHidden(embedsNavigationStack)
        }
    }

    @ViewBuilder
    private var confirmButton: some View {
        if usesPageCloseHeader {
            // La toolbar de iOS 27 dibuja el círculo; no aplicar otro glass manual.
            Button(action: onConfirm) {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(OG.onAccent)
            }
            .buttonStyle(.borderedProminent)
            .tint(OG.accent)
            .accessibilityLabel(confirmTitle)
            .opacity(canConfirm ? 1 : 0.4)
            .disabled(!canConfirm)
        } else {
            OGToolbarGlassButton(
                systemName: "checkmark",
                accessibilityLabel: confirmTitle,
                tint: .white,
                appliesGlass: true,
                glassTint: OG.accent,
                action: onConfirm
            )
            .opacity(canConfirm ? 1 : 0.4)
            .disabled(!canConfirm)
        }
    }
}

enum DayEditorMode: Equatable {
    case plan(isNew: Bool)
    /// Entreno suelto de un día concreto (Inicio); no forma parte del plan semanal.
    case oneOff(isNew: Bool)
    case session
    case favorite(isNew: Bool)
}

private struct WorkoutReplacementTarget: Identifiable, Hashable {
    let id = UUID()
    let blockID: UUID
    let itemID: UUID
    let isWOD: Bool
}
private struct PendingWorkoutReplacement {
    let target: WorkoutReplacementTarget
    let exercise: Exercise
}

struct DayEditorView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(\.dismiss) private var dismiss
    @State var routine: Routine
    var mode: DayEditorMode
    var onSessionStarted: (() -> Void)? = nil
    /// Cierre explícito cuando se presenta como página (push), no modal.
    var onClose: (() -> Void)? = nil
    /// Si no es nil, el check aplica el draft y cierra sin guardar en el store (revisión de pizarra).
    var onApplyDraft: ((Routine) -> Void)? = nil
    /// Edición de una sesión terminada usando exactamente los mismos bloques/reordenación.
    var onApplyCompleted: ((Routine, WorkoutSession) -> Void)? = nil
    var completedSession: WorkoutSession? = nil
    var embedsNavigationStack: Bool = true
    /// Página push (Entreno → Editar): título large + chevron volver; sin X.
    var usesPageCloseHeader: Bool = false
    @State private var pickExerciseForBlock: UUID?
    @State private var pickMovementForBlock: UUID?
    @State private var createFreeMovementForBlock: UUID?
    @State private var showRoutinePicker = false
    @State private var showWODCatalog = false
    @State private var selectFormatForBlock: UUID?
    @State private var saveAsFavorite = false
    @State private var routineSaveError: String?
    @State private var isConfirmingSave = false
    @FocusState private var focusedFormatField: OGSetFieldID?
    @State private var showsReorder = false
    @State private var replacingExercise: WorkoutReplacementTarget?
    @State private var exerciseDetailID: UUID?
    @State private var pendingReplacement: PendingWorkoutReplacement?
    @State private var openedSetID: UUID?
    @State private var completedDetails: WorkoutSession?
    @State private var scaledInputDrafts: [String: String] = [:]

    /// La ruta de Historial abre directamente una sesión finalizada. El diseño
    /// no debe esperar a que onAppear inicialice el estado para saber si muestra
    /// un score global o series: eso enseñaba el formulario de prescripción.
    private var isEditingCompletedWorkout: Bool {
        onApplyCompleted != nil && completedSession != nil
    }

    private var completedWorkoutDraft: WorkoutSession? {
        completedDetails ?? completedSession
    }

    private func ensureCompletedWorkoutDraft() {
        if completedDetails == nil { completedDetails = completedSession }
    }

    var body: some View {
        Group {
            if embedsNavigationStack {
                NavigationStack { editorForm }
            } else {
                editorForm
            }
        }
    }

    /// La fecha no se guarda en la plantilla: solo solicita una copia
    /// del entrenamiento para ese día al confirmar.
    private var planScheduleEnabled: Binding<Bool> {
        Binding(
            get: { routine.scheduledDate != nil },
            set: { enabled in
                routine.scheduledDate = enabled
                    ? (routine.scheduledDate ?? Calendar.current.startOfDay(for: Date()))
                    : nil
            }
        )
    }

    private var planScheduledDate: Binding<Date> {
        Binding(
            get: { routine.scheduledDate ?? Date() },
            set: { routine.scheduledDate = Calendar.current.startOfDay(for: $0) }
        )
    }

    private var editorForm: some View {
        Form {
            if usesPageCloseHeader {
                OGScrollablePageTitle(navTitle).ogScrollingTitleListRow()
            }
            Section {
                TextField(nameFieldPlaceholder, text: $routine.title)
                switch mode {
                case .plan:
                    // Las rutinas reutilizables permanecen en la
                    // biblioteca. Esta fecha opcional crea una COPIA programada.
                    Toggle("Programar también en una fecha", isOn: planScheduleEnabled)
                        .tint(OG.accent)
                    if routine.scheduledDate != nil {
                        DatePicker("Fecha programada", selection: planScheduledDate,
                                   displayedComponents: .date)
                    }
                    scheduledTimeControls
                    Picker("Progresión (fuerza)", selection: $routine.progression) {
                        ForEach(ProgressionPolicy.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }
                case .oneOff:
                    if let date = routine.scheduledDate {
                        Text(SpanishDate.long(date))
                            .foregroundStyle(OG.label2)
                    }
                    scheduledTimeControls
                    Toggle("Favorito", isOn: $routine.isFavorite)
                case .favorite:
                    Toggle("Favorito", isOn: $routine.isFavorite)
                        .disabled(true)
                    Text("Puedes volver a utilizar este entreno desde Añadir entreno → Favoritos.")
                        .font(.footnote)
                        .foregroundStyle(OG.label2)
                    scheduledTimeControls
                case .session:
                    if onApplyDraft == nil {
                        Toggle("Favorito", isOn: $saveAsFavorite)
                    }
                }
            } footer: {
                switch mode {
                case .session:
                    Text(onApplyCompleted != nil
                         ? "Edita los datos registrados sin modificar la rutina programada."
                         : onApplyDraft == nil
                            ? "Empieza la sesión ahora. Puedes añadir entrenos para otros días desde Inicio."
                            : "Los cambios se aplican al revisar la pizarra; aún no se guarda el día.")
                case .favorite:
                    Text("Los favoritos se reutilizan desde Añadir entreno → Favoritos.")
                case .oneOff:
                    EmptyView()
                case .plan:
                    Text("La rutina se guarda para reutilizarla. Si seleccionas una fecha, también se programará una copia en el calendario.")
                }
            }

            if onApplyCompleted != nil {
                Section {
                    DatePicker("Inicio", selection: completedDateBinding(isEnd: false),
                               displayedComponents: [.date, .hourAndMinute])
                        .tint(OG.accent)
                    DatePicker("Fin", selection: completedDateBinding(isEnd: true),
                               displayedComponents: [.date, .hourAndMinute])
                        .tint(OG.accent)
                    if completedDetails?.routePoints.isEmpty == true {
                        WorkoutPlacePickerRow(pin: Binding(
                            get: { completedDetails?.locationPin },
                            set: { completedDetails?.locationPin = $0 }
                        ))
                    }
                    TextField("Notas del entreno", text: Binding(
                        get: { completedDetails?.notes ?? "" },
                        set: { completedDetails?.notes = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(2...5)
                } header: {
                    Text("Datos del entreno realizado")
                }
            }

            if onApplyCompleted == nil {
                Section("Lugar") {
                    WorkoutPlacePickerRow(pin: $routine.locationPin)
                }
            }

            ForEach(Array(routine.blocks.enumerated()), id: \.element.id) { index, block in
                Section {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 10) {
                            TextField("Nombre", text: $routine.blocks[index].title)
                                .font(.system(size: 16, weight: .semibold))
                            Menu {
                                Button {
                                    showsReorder = true
                                } label: {
                                    Label("Reordenar", systemImage: "arrow.up.arrow.down")
                                }
                                Button("Añadir ejercicio", systemImage: "plus") {
                                    if block.kind == .strength {
                                        pickExerciseForBlock = block.id
                                    } else {
                                        pickMovementForBlock = block.id
                                    }
                                }
                                Divider()
                                Button(role: .destructive) {
                                    routine.blocks.removeAll { $0.id == block.id }
                                } label: {
                                    Label("Eliminar bloque", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(OG.label)
                                    .frame(width: 38, height: 38)
                                    .glassEffect(.regular.interactive(), in: .circle)
                            }
                            .accessibilityLabel("Opciones del bloque \(block.title)")
                        }
                        Divider()
                            .overlay(OG.label3.opacity(0.25))
                            .padding(.vertical, 5)
                        formatSettings(index: index)
                        Divider()
                            .overlay(OG.label3.opacity(0.25))
                            .padding(.vertical, 5)
                        completedScoreEditor(for: block)
                    }
                    .listRowSeparator(.hidden)
                    if block.kind == .strength {
                        if isEditingCompletedWorkout,
                           let format = block.wodFormat,
                           format.resultCapture != .perMovementSets {
                            completedStrengthPrescription(index: index)
                        } else {
                            strengthBlock(index: index)
                        }
                    } else {
                        wodBlock(index: index)
                    }
                } header: {
                    Text(block.title)
                }
            }

            Section {
                Button {
                    routine.blocks.append(.strength(title: nextDefaultBlockTitle()))
                } label: {
                    Label("Añadir bloque", systemImage: "square.stack.3d.up")
                }
                Button {
                    showWODCatalog = true
                } label: {
                    Label("Elegir WOD", systemImage: "list.bullet.rectangle.portrait")
                }
                if !importableRoutines.isEmpty {
                    Button {
                        showRoutinePicker = true
                    } label: {
                        Label("Añadir rutina", systemImage: "list.bullet.rectangle")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .ogListChrome()
        .alert(
            saveAsFavorite ? "No se ha podido guardar el favorito" : "No se ha podido guardar el entrenamiento",
            isPresented: Binding(
            get: { routineSaveError != nil },
            set: { if !$0 { routineSaveError = nil } }
        )) {
            Button("Aceptar", role: .cancel) { routineSaveError = nil }
        } message: {
            Text(routineSaveError ?? "")
        }
        .onAppear {
            ensureCompletedWorkoutDraft()
            ensureStrengthPlannedSets()
        }
        .navigationDestination(isPresented: $showsReorder) {
            reorderSheet
        }
        .navigationDestination(item: $exerciseDetailID) { id in
            ExerciseDetailView(exerciseId: id)
        }
        .modifier(DayEditorChromeModifier(
            title: navTitle,
            usesPageCloseHeader: usesPageCloseHeader,
            embedsNavigationStack: embedsNavigationStack,
            canConfirm: canConfirm,
            confirmTitle: confirmTitle,
            onConfirm: confirm,
            onBack: onClose
        ))
        // Pickers de creación: push nativo horizontal con volver en topbar.
        .navigationDestination(item: $pickExerciseForBlock) { blockID in
            ExercisePickerView(embedsNavigationStack: false) { exercise in
                if let idx = routine.blocks.firstIndex(where: { $0.id == blockID }) {
                    let style = exercise.loggingStyle
                    let amount = style == .machineWork
                        ? (exercise.defaultQuantityUnit == .meters ? 500 : 15)
                        : (exercise.isMobility ? (exercise.isMobilityHold ? 1 : 8) : (style == .repsAndTime ? 50 : 8))
                    let count = style.usesDuration ? 1 : 3
                    let sets = (0..<count).map { _ in
                        PlannedSet(targetReps: amount, targetWeightKg: nil,
                            targetDurationSeconds: exercise.isMobility ? (exercise.isMobilityHold ? 30 : 60) : nil)
                    }
                    routine.blocks[idx].exercises.append(
                        RoutineExercise(
                            exerciseId: exercise.id,
                            plannedSets: sets,
                            quantityUnit: style == .machineWork || exercise.supportsRepsOrMeters
                                ? exercise.defaultQuantityUnit : nil
                        )
                    )
                }
                pickExerciseForBlock = nil
            }
        }
        .navigationDestination(item: $pickMovementForBlock) { blockID in
            ExercisePickerView(embedsNavigationStack: false) { exercise in
                if let idx = routine.blocks.firstIndex(where: { $0.id == blockID }) {
                    routine.blocks[idx].movements.append(
                        WODMovement(exerciseId: exercise.id, name: exercise.name, reps: 10)
                    )
                }
                pickMovementForBlock = nil
            }
        }
        .navigationDestination(item: $createFreeMovementForBlock) { blockID in
            FreeWODMovementCreatePage { movement in
                if let idx = routine.blocks.firstIndex(where: { $0.id == blockID }) {
                    routine.blocks[idx].movements.append(movement)
                }
                createFreeMovementForBlock = nil
            }
        }
        .sheet(isPresented: $showRoutinePicker) {
            RoutineImportPickerSheet(
                routines: importableRoutines,
                onPick: { source in
                    routine.blocks.append(contentsOf: source.blocks.map { $0.duplicatingContent() })
                    showRoutinePicker = false
                },
                onCancel: { showRoutinePicker = false }
            )
        }
        .navigationDestination(isPresented: $showWODCatalog) {
            WODCatalogPickerView(embedsNavigationStack: false) { template in
                routine.blocks.append(template.makeBlock())
                if routine.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || routine.title == "Entreno"
                    || routine.title == "Nuevo entreno" {
                    routine.title = template.name
                }
                showWODCatalog = false
            }
        }
        .navigationDestination(item: $selectFormatForBlock) { blockID in
            WODFormatPickerPage { format in
                if let index = routine.blocks.firstIndex(where: { $0.id == blockID }) {
                    setWODFormat(format, at: index)
                }
                selectFormatForBlock = nil
            }
        }
        .navigationDestination(item: $replacingExercise) { target in
            ExercisePickerView(embedsNavigationStack: false) { selected in
                replacingExercise = nil
                let registered = completedWorkoutDraft?.exercises.first(where: { $0.id == target.itemID })
                let scoredBlock = completedWorkoutDraft?.wodResults.contains(where: { $0.id == target.blockID }) == true
                if registered?.loggedSets.isEmpty == false || (target.isWOD && scoredBlock) {
                    pendingReplacement = PendingWorkoutReplacement(target: target, exercise: selected)
                } else {
                    applyExerciseReplacement(target: target, with: selected)
                }
            }
        }
        .confirmationDialog("¿Sustituir ejercicio y reiniciar sus series?", isPresented: Binding(
            get: { pendingReplacement != nil },
            set: { if !$0 { pendingReplacement = nil } }
        ), titleVisibility: .visible) {
            Button("Sustituir y reiniciar", role: .destructive) {
                if let pendingReplacement {
                    applyExerciseReplacement(target: pendingReplacement.target, with: pendingReplacement.exercise)
                }
                pendingReplacement = nil
            }
            Button("Cancelar", role: .cancel) { pendingReplacement = nil }
        } message: {
            Text("Este ejercicio tiene resultados registrados. Al sustituirlo se perderán sus series; los demás ejercicios conservarán las suyas.")
        }
    }

    /// Ordenación únicamente mediante menús de acciones accesibles.
    /// Reordenación nativa con asas de arrastre: bloques y ejercicios.
    private var reorderSheet: some View {
        List {
            Section {
                ForEach(Array(routine.blocks.enumerated()), id: \.element.id) { position, block in
                    HStack(spacing: 12) {
                        Text("\(position + 1)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(OG.accent)
                            .frame(width: 34, height: 34)
                            .background(OG.accent.opacity(0.12), in: Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text(block.title)
                                .font(.system(size: 16, weight: .semibold))
                            Text(block.wodFormat?.displayName ?? (block.kind == .strength ? "Fuerza" : "Libre"))
                                .font(.caption)
                                .foregroundStyle(OG.label2)
                        }
                        Spacer(minLength: 8)
                    }
                    .padding(.vertical, 5)
                }
                .onMove { from, to in
                    withAnimation(.smooth) {
                        routine.blocks.move(fromOffsets: from, toOffset: to)
                    }
                }
            } header: {
                Label("Orden de bloques", systemImage: "square.stack.3d.up")
            }
            ForEach(routine.blocks) { block in
                reorderExercisesSection(for: block)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(OG.bg)
        .environment(\.editMode, .constant(.active))
        .navigationTitle("Reordenar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Listo") { showsReorder = false }
                    .fontWeight(.semibold)
                    .tint(OG.accent)
            }
        }
    }

    @ViewBuilder
    private func reorderExercisesSection(for block: RoutineBlock) -> some View {
        Section {
            if block.kind == .strength {
                ForEach(block.exercises) { exercise in
                    reorderExerciseRow(
                        store.state.exercises.first(where: { $0.id == exercise.exerciseId })?.name ?? "Ejercicio",
                        blockID: block.id, itemID: exercise.id, type: "exercise"
                    )
                }
                .onMove { from, to in
                    guard let index = routine.blocks.firstIndex(where: { $0.id == block.id }) else { return }
                    withAnimation(.smooth) {
                        routine.blocks[index].exercises.move(fromOffsets: from, toOffset: to)
                    }
                }
            } else {
                ForEach(block.movements) { move in
                    reorderExerciseRow(
                        move.isRest ? "Descanso" : move.name,
                        blockID: block.id, itemID: move.id, type: "movement"
                    )
                }
                .onMove { from, to in
                    guard let index = routine.blocks.firstIndex(where: { $0.id == block.id }) else { return }
                    withAnimation(.smooth) {
                        routine.blocks[index].movements.move(fromOffsets: from, toOffset: to)
                    }
                }
            }
        } header: {
            Text(block.title)
        }
    }

    private func reorderExerciseRow(_ name: String, blockID: UUID, itemID: UUID, type: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: type == "movement" ? "figure.strengthtraining.functional" : "dumbbell")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(OG.accent)
                .frame(width: 32, height: 32)
                .background(OG.surface2, in: RoundedRectangle(cornerRadius: 9))
            Text(name)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(OG.label)
            Spacer(minLength: 8)
            Menu {
                if routine.blocks.count > 1 {
                    Menu {
                        ForEach(routine.blocks.filter { $0.id != blockID }) { target in
                            Button(target.title) {
                                withAnimation(.smooth) {
                                    applyReorder(
                                        "\(type):\(blockID.uuidString):\(itemID.uuidString)",
                                        into: target.id, before: nil
                                    )
                                }
                            }
                        }
                    } label: {
                        Label("Mover a otro bloque", systemImage: "arrowshape.turn.up.right")
                    }
                }
                Button("Eliminar ejercicio", systemImage: "trash", role: .destructive) {
                    deleteReorderExercise(type: type, blockID: blockID, itemID: itemID)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(OG.label)
                    .frame(width: 36, height: 36)
                    .glassEffect(.regular.interactive(), in: .circle)
            }
            .accessibilityLabel("Opciones de \(name)")
        }
        .padding(.vertical, 4)
        .listRowBackground(OG.surface)
    }

    private func exerciseOptions(blockID: UUID, itemID: UUID, isWOD: Bool, isRest: Bool = false) -> some View {
        let kind = isWOD ? "movement" : "exercise"
        return Menu {
            if !isRest {
                Button("Sustituir ejercicio", systemImage: "arrow.left.arrow.right") {
                    replacingExercise = WorkoutReplacementTarget(
                        blockID: blockID, itemID: itemID, isWOD: isWOD
                    )
                }
            }
            Button("Reordenar", systemImage: "arrow.up.arrow.down") {
                showsReorder = true
            }
            Divider()
            Button("Eliminar ejercicio", systemImage: "trash", role: .destructive) {
                deleteReorderExercise(type: kind, blockID: blockID, itemID: itemID)
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(OG.label)
                .frame(width: 38, height: 38)
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .accessibilityLabel("Opciones del ejercicio")
    }

    private func applyExerciseReplacement(target: WorkoutReplacementTarget, with selected: Exercise) {
        guard let blockIndex = routine.blocks.firstIndex(where: { $0.id == target.blockID }) else { return }
        let style = selected.loggingStyle
        let quantity = style == .machineWork
            ? (selected.defaultQuantityUnit == .meters ? 500 : 15)
            : (selected.isMobility ? (selected.isMobilityHold ? 1 : 8)
                : (style == .repsAndTime ? 50 : 8))
        let initial = PlannedSet(
            targetReps: quantity,
            targetDurationSeconds: selected.isMobility
                ? (selected.isMobilityHold ? 30 : 60) : nil
        )
        if target.isWOD {
            guard let index = routine.blocks[blockIndex].movements.firstIndex(where: { $0.id == target.itemID }) else { return }
            // Nuevo ID: evita heredar resultados registrados del movimiento anterior.
            routine.blocks[blockIndex].movements[index] = WODMovement(
                exerciseId: selected.id, name: selected.name, reps: quantity,
                explicitPlannedSets: [initial]
            )
        } else {
            guard let index = routine.blocks[blockIndex].exercises.firstIndex(where: { $0.id == target.itemID }) else { return }
            let sets = Array(repeating: 0, count: style.usesDuration ? 1 : 3).map { _ in
                PlannedSet(targetReps: quantity, targetDurationSeconds: initial.targetDurationSeconds)
            }
            routine.blocks[blockIndex].exercises[index] = RoutineExercise(
                exerciseId: selected.id, plannedSets: sets,
                quantityUnit: style == .machineWork || selected.supportsRepsOrMeters
                    ? selected.defaultQuantityUnit : nil
            )
        }
        openedSetID = nil
    }

    private func deleteReorderExercise(type: String, blockID: UUID, itemID: UUID) {
        guard let index = routine.blocks.firstIndex(where: { $0.id == blockID }) else { return }
        withAnimation(.smooth) {
            if type == "exercise" {
                routine.blocks[index].exercises.removeAll { $0.id == itemID }
            } else if type == "movement" {
                routine.blocks[index].movements.removeAll { $0.id == itemID }
            }
        }
    }

    private func reorderBlockToken(_ token: String, before destinationID: UUID?) {
        let parts = token.split(separator: ":")
        guard parts.count == 2,
              parts[0] == "block",
              let sourceID = UUID(uuidString: String(parts[1])),
              let source = routine.blocks.firstIndex(where: { $0.id == sourceID })
        else { return }
        if destinationID == sourceID { return }
        let moved = routine.blocks.remove(at: source)
        let destination = destinationID.flatMap { id in
            routine.blocks.firstIndex(where: { $0.id == id })
        } ?? routine.blocks.count
        routine.blocks.insert(moved, at: destination)
    }

    private func moveExercise(type: String, blockID: UUID, itemID: UUID, offset: Int) {
        guard let blockIndex = routine.blocks.firstIndex(where: { $0.id == blockID }) else { return }
        if type == "exercise" {
            guard let old = routine.blocks[blockIndex].exercises.firstIndex(where: { $0.id == itemID }),
                  routine.blocks[blockIndex].exercises.indices.contains(old + offset) else { return }
            withAnimation(.smooth) {
                let item = routine.blocks[blockIndex].exercises.remove(at: old)
                routine.blocks[blockIndex].exercises.insert(item, at: old + offset)
            }
        } else if type == "movement" {
            guard let old = routine.blocks[blockIndex].movements.firstIndex(where: { $0.id == itemID }),
                  routine.blocks[blockIndex].movements.indices.contains(old + offset) else { return }
            withAnimation(.smooth) {
                let item = routine.blocks[blockIndex].movements.remove(at: old)
                routine.blocks[blockIndex].movements.insert(item, at: old + offset)
            }
        }
    }

    private func moveBlock(_ id: UUID, offset: Int) {
        guard let old = routine.blocks.firstIndex(where: { $0.id == id }),
              routine.blocks.indices.contains(old + offset) else { return }
        withAnimation(.smooth) {
            routine.blocks.move(
                fromOffsets: IndexSet(integer: old),
                toOffset: old + offset + (offset > 0 ? 1 : 0)
            )
        }
    }

    private func applyReorder(_ token: String, into destinationID: UUID, before itemID: UUID?) {
        let parts = token.split(separator: ":").map(String.init)
        guard let targetIndex = routine.blocks.firstIndex(where: { $0.id == destinationID }) else { return }
        if parts.count == 2, parts[0] == "block" {
            reorderBlockToken(token, before: destinationID)
            return
        }
        guard parts.count == 3,
              let sourceBlockID = UUID(uuidString: parts[1]),
              let exerciseID = UUID(uuidString: parts[2]),
              let sourceIndex = routine.blocks.firstIndex(where: { $0.id == sourceBlockID })
        else { return }
        // Soltar una fila en su propio hueco anterior no cambia el orden.
        if sourceBlockID == destinationID && itemID == exerciseID { return }
        let source = routine.blocks[sourceIndex]
        let targetKind = routine.blocks[targetIndex].kind
        if parts[0] == "exercise" {
            guard let item = source.exercises.first(where: { $0.id == exerciseID }) else { return }
            let targetMovement: WODMovement?
            if targetKind == .wod {
                let name = store.state.exercises.first(where: { $0.id == item.exerciseId })?.name ?? "Ejercicio"
                targetMovement = WODMovement(
                    exerciseId: item.exerciseId,
                    name: name,
                    reps: item.plannedSets.first?.targetReps ?? 8,
                    distanceMeters: item.quantityUnit == .meters ? item.plannedSets.first?.targetReps : nil,
                    calories: item.quantityUnit == .calories ? item.plannedSets.first?.targetReps : nil,
                    weightMaleKg: item.plannedSets.first?.targetWeightKg,
                    explicitPlannedSets: item.plannedSets
                )
            } else { targetMovement = nil }
            routine.blocks[sourceIndex].exercises.removeAll { $0.id == exerciseID }
            if targetKind == .strength {
                let position = itemID.flatMap { id in
                    routine.blocks[targetIndex].exercises.firstIndex(where: { $0.id == id })
                } ?? routine.blocks[targetIndex].exercises.count
                routine.blocks[targetIndex].exercises.insert(item, at: position)
            } else if let targetMovement {
                let position = itemID.flatMap { id in
                    routine.blocks[targetIndex].movements.firstIndex(where: { $0.id == id })
                } ?? routine.blocks[targetIndex].movements.count
                routine.blocks[targetIndex].movements.insert(targetMovement, at: position)
            }
        } else if parts[0] == "movement" {
            guard let move = source.movements.first(where: { $0.id == exerciseID }) else { return }
            var targetExercise: RoutineExercise?
            if targetKind == .strength {
                guard !move.isRest else { return }
                var catalogID = move.exerciseId.flatMap { id in
                    store.state.exercises.contains(where: { $0.id == id }) ? id : nil
                } ?? store.state.exercises.first(where: {
                    $0.name.localizedCaseInsensitiveCompare(move.name) == .orderedSame
                })?.id
                if catalogID == nil {
                    guard store.addCustomExercise(name: move.name, muscleGroup: "Otros", equipment: nil) else { return }
                    catalogID = store.state.exercises.last(where: {
                        $0.name.localizedCaseInsensitiveCompare(move.name) == .orderedSame
                    })?.id
                }
                guard let resolvedID = catalogID else { return }
                targetExercise = RoutineExercise(
                    exerciseId: resolvedID,
                    plannedSets: move.explicitPlannedSets ?? move.plannedSetsFromReps,
                    quantityUnit: move.prescribedQuantityUnit
                )
            }
            routine.blocks[sourceIndex].movements.removeAll { $0.id == exerciseID }
            if targetKind == .wod {
                let position = itemID.flatMap { id in
                    routine.blocks[targetIndex].movements.firstIndex(where: { $0.id == id })
                } ?? routine.blocks[targetIndex].movements.count
                routine.blocks[targetIndex].movements.insert(move, at: position)
            } else if let targetExercise {
                let position = itemID.flatMap { id in
                    routine.blocks[targetIndex].exercises.firstIndex(where: { $0.id == id })
                } ?? routine.blocks[targetIndex].exercises.count
                routine.blocks[targetIndex].exercises.insert(targetExercise, at: position)
            }
        }
    }

    /// Nombre por defecto al añadir bloque: «Bloque 1», «Bloque 2», …
    private func nextDefaultBlockTitle() -> String {
        "Bloque \(routine.blocks.count + 1)"
    }

    private var importableRoutines: [Routine] {
        store.libraryRoutines.filter { $0.id != routine.id && !$0.blocks.isEmpty }
    }

    private func closeEditor() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    @ViewBuilder
    private var scheduledTimeControls: some View {
        Toggle("Hora programada", isOn: Binding(
            get: { routine.scheduledTimeMinutes != nil },
            set: { enabled in
                if enabled {
                    if routine.scheduledTimeMinutes == nil {
                        routine.scheduledTimeMinutes = 18 * 60
                    }
                } else {
                    routine.scheduledTimeMinutes = nil
                }
            }
        ))
        if routine.scheduledTimeMinutes != nil {
            DatePicker(
                "Hora",
                selection: Binding(
                    get: {
                        routine.scheduledDateTime(on: routine.scheduledDate ?? Date())
                            ?? Calendar.current.date(
                                bySettingHour: 18,
                                minute: 0,
                                second: 0,
                                of: Date()
                            )
                            ?? Date()
                    },
                    set: { routine.setScheduledTime(from: $0) }
                ),
                displayedComponents: .hourAndMinute
            )
        }
    }

    private var nameFieldPlaceholder: String {
        switch mode {
        case .session, .oneOff: return "Nombre del entreno"
        case .favorite: return "Nombre del favorito"
        case .plan: return "Nombre de la rutina"
        }
    }

    private var navTitle: String {
        if onApplyDraft != nil || onApplyCompleted != nil { return "Editar entreno" }
        switch mode {
        case .session: return "Crear entreno"
        case .oneOff(let isNew): return isNew ? "Crear entreno" : "Editar entreno"
        case .favorite(let isNew): return isNew ? "Nuevo favorito" : "Editar favorito"
        case .plan(let isNew):
            return isNew ? "Nueva rutina" : "Editar rutina"
        }
    }

    private var confirmTitle: String {
        if onApplyCompleted != nil { return "Guardar" }
        if onApplyDraft != nil { return "Listo" }
        switch mode {
        case .session: return "Empezar"
        case .plan, .favorite, .oneOff: return "Guardar"
        }
    }

    private var canConfirm: Bool {
        guard !isConfirmingSave else { return false }
        if onApplyDraft != nil || onApplyCompleted != nil {
            return routine.blocks.contains { block in
                switch block.kind {
                case .strength: return !block.exercises.isEmpty
                case .wod: return !block.movements.isEmpty
                }
            }
        }
        switch mode {
        case .plan, .favorite, .oneOff: return true
        case .session:
            return routine.blocks.contains { block in
                switch block.kind {
                case .strength: return !block.exercises.isEmpty
                case .wod: return !block.movements.isEmpty
                }
            }
        }
    }

    private func confirm() {
        guard !isConfirmingSave else { return }
        isConfirmingSave = true
        Task { @MainActor in
            defer { isConfirmingSave = false }
            await confirmWithVerifiedAccess()
        }
    }

    private func confirmWithVerifiedAccess() async {
        subscriptions.syncCounts(
            libraryRoutines: store.libraryRoutineCount,
            customExercises: store.customExerciseCount
        )
        store.featureAccess = { [subscriptions] in subscriptions.policy }
        if let onApplyCompleted, let completedDetails = completedWorkoutDraft {
            var edited = routine
            for index in edited.blocks.indices { edited.blocks[index].deriveEmomRoundsIfNeeded() }
            if edited.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                edited.title = "Entreno"
            }
            var detailsToSave = completedDetails
            if saveAsFavorite {
                // Editar un histórico no debe crear duplicados si ya tiene
                // una plantilla favorita. Tampoco modifica el plan original.
                let prior = completedDetails.favoriteRoutineId.flatMap { favoriteID in
                    store.state.routines.first(where: { $0.id == favoriteID })
                }
                let favorite = Routine(
                    id: prior?.id ?? UUID(),
                    title: edited.title,
                    blocks: edited.blocks.map { $0.duplicatingContent() },
                    progression: .off,
                    isFavorite: true
                )
                guard await saveRoutineWithVerifiedAccess(favorite) else { return }
                detailsToSave.favoriteRoutineId = favorite.id
            }
            onApplyCompleted(edited, detailsToSave)
            closeEditor()
            return
        }
        if let onApplyDraft {
            var draft = routine
            for i in draft.blocks.indices {
                draft.blocks[i].deriveEmomRoundsIfNeeded()
            }
            if draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                draft.title = "Entreno"
            }
            onApplyDraft(draft)
            closeEditor()
            return
        }
        switch mode {
        case .plan:
            var draft = routine
            let dateToSchedule = draft.scheduledDate
            // Guardar la fuente SIN fecha para que siempre permanezca en
            // La plantilla se mantiene sin fecha; programar crea una copia independiente.
            draft.weekday = nil
            draft.scheduledDate = nil
            if draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                draft.title = "Rutina"
            }
            guard await saveRoutineWithVerifiedAccess(draft) else { return }
            if let dateToSchedule {
                store.assignRoutine(draft.id, toDate: dateToSchedule)
            }
            closeEditor()
        case .oneOff:
            var draft = routine
            draft.weekday = nil
            draft.progression = .off
            if draft.scheduledDate == nil {
                draft.scheduledDate = Calendar.current.startOfDay(for: Date())
            }
            if draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                draft.title = "Entreno"
            }
            let wantsFavorite = draft.isFavorite
            // El plan con fecha y el favorito de la biblioteca tienen IDs
            // independientes. No marcar el calendario como favorito hasta
            // que la nueva plantilla se haya guardado de verdad.
            draft.isFavorite = store.state.routines.first(where: { $0.id == draft.id })?.isFavorite ?? false
            guard await saveRoutineWithVerifiedAccess(draft) else { return }
            guard await setRoutineFavoriteWithVerifiedAccess(
                draft.id, isFavorite: wantsFavorite
            ) else {
                routine.isFavorite = false
                return
            }
            closeEditor()
        case .favorite:
            var draft = routine
            draft.isFavorite = true
            if draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                draft.title = "Favorito"
            }
            guard await saveRoutineWithVerifiedAccess(draft) else { return }
            closeEditor()
        case .session:
            var draft = routine
            draft.progression = .off
            draft.scheduledDate = nil
            draft.weekday = nil
            if draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                draft.title = "Mi entreno"
            }
            draft.isFavorite = saveAsFavorite
            if saveAsFavorite {
                guard await saveRoutineWithVerifiedAccess(draft) else { return }
            }
            store.startSession(from: draft)
            // No cerrar ni navegar si había otra sesión activa o HealthKit
            // impidió comenzar. El ID de origen debe ser el de esta rutina.
            guard store.state.activeSession?.routineId == draft.id else { return }
            closeEditor()
            onSessionStarted?()
        }
    }

    /// Al editar una sesión finalizada se muestra el dato REAL anotado, no las
    /// series prescritas del WOD. Todos los formatos de score tienen edición.
    @ViewBuilder
    private func completedScoreEditor(for block: RoutineBlock) -> some View {
        if isEditingCompletedWorkout,
           let format = block.wodFormat,
           format.resultCapture != .perMovementSets {
            VStack(alignment: .leading, spacing: 10) {
                Text("Resultado del entreno")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(OG.label)

                if let olderScore = completedWorkoutDraft?.wodResults.last(where: {
                    $0.id == block.id && $0.format != nil && $0.format != format
                }) {
                    Text("Se conserva el resultado anterior (\(olderScore.format?.displayName ?? "otro formato"): \(olderScore.summaryLabel)). Puedes registrar también el resultado del formato actual sin perderlo.")
                        .font(.caption)
                        .foregroundStyle(OG.label2)
                }

                // Todos los formatos con score global admiten edición,
                // aunque Salud/Play no hubiera guardado todavía un resultado
                // estructurado (RFT antiguo, AMRAP importado, etc.).
                // El resultado solo se crea cuando el usuario cambia un campo.
                switch format.resultCapture {
                    case .totalReps:
                        if format == .amrap || format == .deathBy {
                            HStack(spacing: 8) {
                                OGFormatNumberField(
                                    title: "Rondas completas", value: completedScoreBinding(block: block, field: .rounds),
                                    range: 0...200, focus: $focusedFormatField,
                                    fieldID: OGSetFieldID(rowID: block.id, column: 10),
                                    nextID: OGSetFieldID(rowID: block.id, column: 11)
                                )
                                OGFormatNumberField(
                                    title: "Reps adicionales", value: completedScoreBinding(block: block, field: .reps),
                                    range: 0...5000, focus: $focusedFormatField,
                                    fieldID: OGSetFieldID(rowID: block.id, column: 11)
                                )
                            }
                            Text("Solo las repeticiones de la ronda incompleta, no las acumuladas.")
                                .font(.caption)
                                .foregroundStyle(OG.label2)
                        } else {
                            OGFormatNumberField(
                                title: "Repeticiones máximas", value: completedScoreBinding(block: block, field: .reps),
                                range: 0...5000, focus: $focusedFormatField,
                                fieldID: OGSetFieldID(rowID: block.id, column: 10)
                            )
                        }
                    case .elapsedTime:
                        HStack(spacing: 8) {
                            OGFormatNumberField(
                                title: "Minutos", unit: "min",
                                value: completedScoreBinding(block: block, field: .minutes),
                                range: 0...180, focus: $focusedFormatField,
                                fieldID: OGSetFieldID(rowID: block.id, column: 10),
                                nextID: OGSetFieldID(rowID: block.id, column: 11)
                            )
                            OGFormatNumberField(
                                title: "Segundos", unit: "s",
                                value: completedScoreBinding(block: block, field: .seconds),
                                range: 0...59, focus: $focusedFormatField,
                                fieldID: OGSetFieldID(rowID: block.id, column: 11)
                            )
                        }
                        Text("Tiempo real empleado (no el time cap).")
                            .font(.caption)
                            .foregroundStyle(OG.label2)
                    case .perMovementSets:
                        EmptyView()
                    }
            }
            .padding(.vertical, 8)
        }
    }

    private func completedScoreBinding(
        block: RoutineBlock, field: CompletedWorkoutEditing.ScoreField
    ) -> Binding<Int> {
        Binding(
            get: {
                guard let session = completedWorkoutDraft else { return 0 }
                return CompletedWorkoutEditing.scoreValue(
                    for: block, in: session, field: field
                )
            },
            set: { value in
                ensureCompletedWorkoutDraft()
                guard let session = completedWorkoutDraft else { return }
                completedDetails = CompletedWorkoutEditing.changingScore(
                    in: session, for: block, field: field, value: value
                )
            }
        )
    }

    private func completedDateBinding(isEnd: Bool) -> Binding<Date> {
        Binding(
            get: {
                if isEnd {
                    return completedDetails?.finishedAt ?? completedDetails?.startedAt ?? Date()
                }
                return completedDetails?.startedAt ?? completedDetails?.finishedAt ?? Date()
            },
            set: { date in
                if isEnd { completedDetails?.finishedAt = date }
                else { completedDetails?.startedAt = date }
            }
        )
    }

    /// No interpretar un estado Gratis antiguo como prueba de que Pro caducó.
    /// Consultar de nuevo las compras verificadas antes de bloquear una rutina.
    @discardableResult
    private func saveRoutineWithVerifiedAccess(_ candidate: Routine) async -> Bool {
        if store.saveRoutine(candidate) { return true }
        if store.lastAccessDenial != nil {
            await subscriptions.refreshEntitlementsForFeatureAction()
            subscriptions.syncCounts(
                libraryRoutines: store.libraryRoutineCount,
                customExercises: store.customExerciseCount
            )
            store.featureAccess = { [subscriptions] in subscriptions.policy }
            if store.saveRoutine(candidate) { return true }
        }
        presentRoutineLimitPaywall()
        return false
    }

    private func setRoutineFavoriteWithVerifiedAccess(
        _ routineID: UUID, isFavorite: Bool
    ) async -> Bool {
        if store.setRoutineFavorite(routineID, isFavorite: isFavorite) { return true }
        if store.lastAccessDenial != nil {
            await subscriptions.refreshEntitlementsForFeatureAction()
            subscriptions.syncCounts(
                libraryRoutines: store.libraryRoutineCount,
                customExercises: store.customExerciseCount
            )
            store.featureAccess = { [subscriptions] in subscriptions.policy }
            if store.setRoutineFavorite(routineID, isFavorite: isFavorite) { return true }
        }
        presentRoutineLimitPaywall()
        return false
    }

    private func presentRoutineLimitPaywall() {
        guard let decision = store.lastAccessDenial, !decision.allowed else {
            routineSaveError = "No se ha podido guardar la plantilla favorita. El entrenamiento original no se ha modificado."
            return
        }
        if subscriptions.snapshot.status == .unknown && !subscriptions.policy.isPro {
            routineSaveError = "No hemos podido verificar tu suscripción. Comprueba la conexión o utiliza «Restaurar compras» en Ajustes."
        } else if subscriptions.policy.isPro {
            routineSaveError = "No se ha podido guardar la plantilla aunque tu acceso Pro está activo. Inténtalo de nuevo."
        } else {
            subscriptions.presentPaywall(
                decision.paywallContext, feature: .unlimitedRoutines
            )
        }
    }

    /// Al editar una sesión terminada la miniatura se alinea al título,
    /// y solo se muestran los campos de resultado realmente modificables.
    @ViewBuilder
    private func completedStrengthPrescription(index: Int) -> some View {
        ForEach(Array(routine.blocks[index].exercises.enumerated()), id: \.element.id) { _, item in
            if let exercise = store.state.exercises.first(where: { $0.id == item.exerciseId })
                ?? completedWorkoutDraft?.exercises.first(where: { $0.exercise.id == item.exerciseId })?.exercise {
                HStack(alignment: .top, spacing: 12) {
                    ExerciseThumb(exercise: exercise, size: 48)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(OG.label)
                        Text(item.plannedSets.compactSummary)
                            .font(.caption)
                            .foregroundStyle(OG.label2)
                        completedWODScalingFields(movementID: item.id, exercise: exercise)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.vertical, 5)
            }
        }
    }

    /// Los valores reales se presentan con los prescritos como valor inicial.
    /// No guardan una adaptación por el mero hecho de abrir el editor.
    @ViewBuilder
    private func completedWODScalingFields(movementID: UUID, exercise: Exercise) -> some View {
        let showsWeight = exercise.loggingStyle == .loadAndReps
            || !completedPrescribedValue(movementID: movementID, weight: true).isEmpty
        HStack(alignment: .top, spacing: 8) {
            completedActualField(
                label: exercise.loggingStyle == .machineWork ? "CANTIDAD REAL" : "REPS REALES",
                value: completedWODScaledValue(movementID: movementID, weight: false),
                allowsDecimal: false,
                name: exercise.name
            )
            if showsWeight && exercise.loadField != .deficitCm {
                completedActualField(
                    label: "KG REALES",
                    value: completedWODScaledValue(movementID: movementID, weight: true),
                    allowsDecimal: true,
                    name: exercise.name
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func completedActualField(
        label: String, value: Binding<String>, allowsDecimal: Bool, name: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(OG.label3)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            OGNumericTextField(text: value, allowsDecimal: allowsDecimal, autoFocus: false, onCommit: {})
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(OG.surface2, in: RoundedRectangle(cornerRadius: 11))
                .accessibilityLabel(label + " · " + name)
        }
        .frame(maxWidth: .infinity)
    }

    private func completedPrescribedValue(movementID: UUID, weight: Bool) -> String {
        for block in routine.blocks {
            if let item = block.exercises.first(where: { $0.id == movementID }) {
                let first = item.plannedSets.first
                if weight {
                    return first?.targetWeightKg.map { ReperaNumberFormat.decimal($0) } ?? ""
                }
                return first.map { String($0.targetReps) } ?? ""
            }
            if let move = block.movements.first(where: { $0.id == movementID }) {
                let first = block.plannedSets(for: move).first
                if weight {
                    return (move.weightMaleKg ?? first?.targetWeightKg).map { ReperaNumberFormat.decimal($0) } ?? ""
                }
                return (first?.targetReps ?? move.reps).map(String.init) ?? ""
            }
        }
        return ""
    }

    private func completedWODScaledValue(movementID: UUID, weight: Bool) -> Binding<String> {
        let key = movementID.uuidString + (weight ? "-kg" : "-reps")
        return Binding(
            get: {
                // Conservar la coma, el punto y los decimales a medio escribir.
                // No volver a formatear desde el modelo al pulsar cada tecla.
                if let draft = scaledInputDrafts[key] { return draft }
                let prescribed = completedPrescribedValue(movementID: movementID, weight: weight)
                guard let entry = completedWorkoutDraft?.exercises.first(where: { $0.id == movementID }) else {
                    return prescribed
                }
                if weight {
                    return entry.adaptedWeightKg.map { ReperaNumberFormat.decimal($0) } ?? prescribed
                }
                return entry.adaptedReps.map(String.init) ?? prescribed
            },
            set: { input in
                scaledInputDrafts[key] = input
                ensureCompletedWorkoutDraft()
                guard let index = completedDetails?.exercises.firstIndex(where: { $0.id == movementID })
                else { return }
                let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
                let prescribed = completedPrescribedValue(movementID: movementID, weight: weight)
                if weight {
                    if cleaned.isEmpty {
                        completedDetails?.exercises[index].adaptedWeightKg = nil
                    } else if let kg = ReperaNumberFormat.parse(cleaned),
                              kg.isFinite, (0...1000).contains(kg) {
                        let rx = ReperaNumberFormat.parse(prescribed)
                        completedDetails?.exercises[index].adaptedWeightKg =
                            rx.map { abs(kg - $0) < 0.05 } == true ? nil : kg
                    }
                } else if cleaned.isEmpty {
                    completedDetails?.exercises[index].adaptedReps = nil
                } else if let reps = Int(cleaned), (0...10000).contains(reps) {
                    completedDetails?.exercises[index].adaptedReps =
                        reps == Int(prescribed) ? nil : reps
                }
            }
        )
    }

    @ViewBuilder
    private func strengthBlock(index: Int) -> some View {
        let weightStep = store.state.settings.weightIncrementKg
        ForEach(Array(routine.blocks[index].exercises.enumerated()), id: \.element.id) { exIndex, item in
            if let ex = store.state.exercises.first(where: { $0.id == item.exerciseId })
                ?? completedDetails?.exercises.first(where: { $0.exercise.id == item.exerciseId })?.exercise {
                HStack(spacing: 4) {
                    NavigationLink {
                        ExerciseDetailView(exerciseId: ex.id)
                    } label: {
                        HStack(spacing: 12) {
                            ExerciseThumb(exercise: ex, size: 48)
                            Text(ex.name)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(OG.label)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .accessibilityHint("Ver ficha del ejercicio")
                    exerciseOptions(blockID: routine.blocks[index].id, itemID: item.id, isWOD: false)
                }
                .listRowSeparator(.hidden, edges: .bottom)

                if ex.supportsRepsOrMeters
                    || (ex.loggingStyle == .machineWork && ex.allowsCalorieOrDistanceToggle) {
                    Picker("Unidad", selection: Binding(
                        get: { routine.blocks[index].exercises[exIndex].quantityUnit ?? ex.defaultQuantityUnit },
                        set: { routine.blocks[index].exercises[exIndex].quantityUnit = $0 }
                    )) {
                        if ex.supportsRepsOrMeters {
                            Text("Repeticiones").tag(ExerciseQuantityUnit.reps)
                        } else {
                            Text("Calorías").tag(ExerciseQuantityUnit.calories)
                        }
                        Text("Metros").tag(ExerciseQuantityUnit.meters)
                    }
                    .pickerStyle(.segmented)
                }

                OGSetEntryHeader(
                    firstTitle: ex.isMobility ? "Tiempo (s)" : (ex.loggingStyle == .loadAndReps
                        ? (ex.loadField == .deficitCm ? "Déficit" : "KG")
                        : (ex.loggingStyle == .machineWork
                            ? (item.quantityUnit ?? ex.defaultQuantityUnit).shortLabel
                            : (ex.supportsRepsOrMeters
                                ? (item.quantityUnit ?? ex.defaultQuantityUnit).shortLabel
                                : ex.quantityFieldLabel))),
                    secondTitle: ex.isMobility ? (ex.isMobilityHold ? nil : "Reps")
                        : (ex.loggingStyle == .loadAndReps
                            ? (ex.supportsRepsOrMeters
                                ? (item.quantityUnit ?? .reps).shortLabel : "Reps") : nil),
                    showsRIR: ex.loggingStyle.usesRIR
                )
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 4, trailing: 16))
                .listRowSeparator(.hidden, edges: .top)

                ForEach(Array(routine.blocks[index].exercises[exIndex].plannedSets.enumerated()), id: \.element.id) { setIndex, plannedSet in
                    OGSetSwipeDeleteRow(
                        canDelete: routine.blocks[index].exercises[exIndex].plannedSets.count > 1,
                        setID: plannedSet.id,
                        openedSetID: $openedSetID,
                        onDelete: { deleteStrengthSet(blockIndex: index, exerciseIndex: exIndex, setIndex: setIndex) }
                    ) {
                    PlannedSetConfigRow(
                        index: setIndex + 1,
                        set: plannedSetBinding(blockIndex: index, exerciseIndex: exIndex, setIndex: setIndex),
                        weightStep: weightStep,
                        exerciseStyle: ex.loggingStyle,
                        quantityCap: ex.supportsRepsOrMeters && item.quantityUnit == .meters ? 100_000 : nil,
                        isMobility: ex.isMobility,
                        isMobilityHold: ex.isMobilityHold,
                        previous: {
                            let sets = store.cachedLastWorkingSession(for: ex.id)?.sets
                            return (sets?.indices.contains(setIndex) == true) ? sets?[setIndex] : nil
                        }()
                    )
                    }
                }

                Button {
                    addStrengthSet(blockIndex: index, exerciseIndex: exIndex)
                } label: {
                    Label("Añadir serie", systemImage: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(OG.accent)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

            }
        }
        Button("Añadir ejercicio") { pickExerciseForBlock = routine.blocks[index].id }
    }

    private func plannedSetBinding(blockIndex: Int, exerciseIndex: Int, setIndex: Int) -> Binding<PlannedSet> {
        Binding(
            get: {
                guard routine.blocks.indices.contains(blockIndex),
                      routine.blocks[blockIndex].exercises.indices.contains(exerciseIndex),
                      routine.blocks[blockIndex].exercises[exerciseIndex].plannedSets.indices.contains(setIndex)
                else {
                    return PlannedSet(targetReps: 8)
                }
                return routine.blocks[blockIndex].exercises[exerciseIndex].plannedSets[setIndex]
            },
            set: { newValue in
                guard routine.blocks.indices.contains(blockIndex),
                      routine.blocks[blockIndex].exercises.indices.contains(exerciseIndex),
                      routine.blocks[blockIndex].exercises[exerciseIndex].plannedSets.indices.contains(setIndex)
                else { return }
                routine.blocks[blockIndex].exercises[exerciseIndex].plannedSets[setIndex] = newValue
            }
        )
    }

    private func ensureStrengthPlannedSets() {
        for blockIndex in routine.blocks.indices where routine.blocks[blockIndex].kind == .strength {
            for exerciseIndex in routine.blocks[blockIndex].exercises.indices
            where routine.blocks[blockIndex].exercises[exerciseIndex].plannedSets.isEmpty {
                routine.blocks[blockIndex].exercises[exerciseIndex].plannedSets = [
                    PlannedSet(targetReps: 8, targetWeightKg: nil)
                ]
            }
        }
    }

    private func addStrengthSet(blockIndex: Int, exerciseIndex: Int) {
        guard routine.blocks.indices.contains(blockIndex),
              routine.blocks[blockIndex].exercises.indices.contains(exerciseIndex) else { return }
        var sets = routine.blocks[blockIndex].exercises[exerciseIndex].plannedSets
        if sets.isEmpty {
            sets = [PlannedSet(targetReps: 8, targetWeightKg: nil)]
        }
        guard sets.count < 12 else { return }
        let last = sets.last
        sets.append(
            PlannedSet(
                targetReps: last?.targetReps ?? 8,
                targetWeightKg: last?.targetWeightKg,
                targetDurationSeconds: last?.targetDurationSeconds,
                targetRir: last?.targetRir
            )
        )
        routine.blocks[blockIndex].exercises[exerciseIndex].plannedSets = sets
    }

    private func deleteStrengthSet(blockIndex: Int, exerciseIndex: Int, setIndex: Int) {
        guard routine.blocks.indices.contains(blockIndex),
              routine.blocks[blockIndex].exercises.indices.contains(exerciseIndex) else { return }
        var sets = routine.blocks[blockIndex].exercises[exerciseIndex].plannedSets
        guard sets.count > 1, sets.indices.contains(setIndex) else { return }
        sets.remove(at: setIndex)
        routine.blocks[blockIndex].exercises[exerciseIndex].plannedSets = sets
    }

    private func applyStrengthExerciseReorder(
        to exercises: inout [RoutineExercise],
        difference: ReorderDifference<UUID, UUID>
    ) {
        let sourceIDs = Set(difference.sources)
        let moved = difference.sources.compactMap { id in exercises.first { $0.id == id } }
        guard !moved.isEmpty else { return }
        exercises.removeAll { sourceIDs.contains($0.id) }
        let insertIndex: Int
        switch difference.destination.position {
        case .before(let anchorID):
            insertIndex = exercises.firstIndex { $0.id == anchorID } ?? exercises.count
        case .end:
            insertIndex = exercises.count
        }
        exercises.insert(contentsOf: moved, at: insertIndex)
    }

    /// Rondas mostradas: EMOM deriva vueltas (cap÷estaciones); RFT default 4.
    private func emomOrRFTRounds(at index: Int) -> Int {
        if let rounds = routine.blocks[index].rounds { return rounds }
        if routine.blocks[index].wodFormat == .emom {
            var block = routine.blocks[index]
            block.deriveEmomRoundsIfNeeded()
            return block.rounds ?? 4
        }
        return 4
    }

    private func setWODFormat(_ format: WODFormat?, at index: Int) {
        routine.blocks[index].wodFormat = format
        guard let format else { return }
        if format == .tabata {
            routine.blocks[index].workSeconds = routine.blocks[index].workSeconds ?? 20
            routine.blocks[index].restSeconds = routine.blocks[index].restSeconds ?? 10
            routine.blocks[index].rounds = routine.blocks[index].rounds ?? 8
        }
        if format == .forTime {
            routine.blocks[index].rounds = routine.blocks[index].rounds ?? 4
            routine.blocks[index].timeCapMinutes = routine.blocks[index].timeCapMinutes ?? 12
        }
        if format == .amrap || format == .emom {
            routine.blocks[index].timeCapMinutes = routine.blocks[index].timeCapMinutes ?? 12
        }
        if format == .emom {
            routine.blocks[index].deriveEmomRoundsIfNeeded()
        }
    }

    private enum BlockNumberField: Int, Hashable {
        case duration, interval, rounds, work, rest, roundRest

        var title: String {
            switch self {
            case .duration: return "Tiempo"
            case .interval: return "Intervalo"
            case .rounds: return "Rondas"
            case .work: return "Trabajo"
            case .rest: return "Descanso"
            case .roundRest: return "Entre rondas"
            }
        }

        var unit: String {
            switch self {
            case .duration: return "min"
            case .rounds: return ""
            case .interval, .work, .rest, .roundRest: return "s"
            }
        }

        var range: ClosedRange<Int> {
            switch self {
            case .duration: return 1...120
            case .rounds: return 1...99
            case .interval: return 15...900
            case .work, .rest: return 1...300
            case .roundRest: return 0...600
            }
        }
    }

    private func fieldsForFormat(_ block: RoutineBlock) -> [BlockNumberField] {
        guard let format = block.wodFormat else { return [] }
        switch format {
        case .tabata: return [.work, .rest, .rounds]
        case .emom, .circuit: return [.duration, .interval]
        case .amrap: return [.duration]
        case .forTime:
            return block.timeCapMinutes == nil ? [.rounds] : [.rounds, .duration, .roundRest]
        case .chipper, .afap, .ladder:
            return block.timeCapMinutes == nil ? [] : [.duration]
        case .deathBy, .roundsForQuality, .partner:
            return block.timeCapMinutes == nil ? [.rounds] : [.rounds, .duration]
        case .buyInCashOut, .maxEffort, .strength:
            return block.timeCapMinutes == nil ? [] : [.duration]
        }
    }

    private func numberBinding(_ field: BlockNumberField, blockIndex: Int) -> Binding<Int> {
        Binding(
            get: {
                guard routine.blocks.indices.contains(blockIndex) else { return 0 }
                let block = routine.blocks[blockIndex]
                switch field {
                case .duration: return block.timeCapMinutes ?? 12
                case .interval: return block.emomIntervalSeconds ?? 60
                case .rounds: return block.rounds ?? 8
                case .work: return block.workSeconds ?? 20
                case .rest: return block.restSeconds ?? 10
                case .roundRest: return block.restBetweenRoundsSeconds ?? 0
                }
            },
            set: { value in
                guard routine.blocks.indices.contains(blockIndex) else { return }
                switch field {
                case .duration: routine.blocks[blockIndex].timeCapMinutes = value
                case .interval: routine.blocks[blockIndex].emomIntervalSeconds = value
                case .rounds: routine.blocks[blockIndex].rounds = value
                case .work: routine.blocks[blockIndex].workSeconds = value
                case .rest: routine.blocks[blockIndex].restSeconds = value
                case .roundRest: routine.blocks[blockIndex].restBetweenRoundsSeconds = value
                }
            }
        )
    }

    /// Los parámetros de un formato se muestran como campos compactos en una sola fila.
    @ViewBuilder
    private func formatSettings(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            Button {
                selectFormatForBlock = routine.blocks[index].id
            } label: {
                HStack(spacing: 10) {
                    Text("Formato")
                        .foregroundStyle(OG.label)
                    Spacer()
                    Text(routine.blocks[index].wodFormat?.displayName ?? "Sin formato")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(OG.label2)
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(OG.label3)
                }
            }
            .buttonStyle(.plain)

            if let format = routine.blocks[index].wodFormat {
                let fields = fieldsForFormat(routine.blocks[index])
                if !fields.isEmpty {
                    HStack(alignment: .bottom, spacing: 12) {
                        ForEach(Array(fields.enumerated()), id: \.element) { position, field in
                            OGFormatNumberField(
                                title: field.title,
                                unit: field.unit,
                                value: numberBinding(field, blockIndex: index),
                                range: field.range,
                                focus: $focusedFormatField,
                                fieldID: OGSetFieldID(rowID: routine.blocks[index].id, column: position),
                                nextID: position + 1 < fields.count
                                    ? OGSetFieldID(rowID: routine.blocks[index].id, column: position + 1)
                                    : nil
                            )
                        }
                    }
                    .padding(.vertical, 10)
                }
                if ![WODFormat.amrap, .emom, .tabata, .circuit].contains(format) {
                    Toggle("Límite de tiempo", isOn: Binding(
                        get: { routine.blocks[index].timeCapMinutes != nil },
                        set: { enabled in
                            routine.blocks[index].timeCapMinutes = enabled
                                ? (routine.blocks[index].timeCapMinutes ?? 12) : nil
                        }
                    ))
                    .tint(OG.accent)
                }
            }
        }

    }

    @ViewBuilder
    private func wodBlock(index: Int) -> some View {
        ForEach(Array(routine.blocks[index].movements.enumerated()), id: \.element.id) { mIndex, move in
            let resolved = resolvedExercise(for: move)
            let hasCatalog = !move.isRest && store.state.exercises.contains(where: { $0.id == resolved.id })
            if !move.isRest, isEditingCompletedWorkout,
               let format = routine.blocks[index].wodFormat,
               format.resultCapture != .perMovementSets {
                HStack(alignment: .top, spacing: 8) {
                    if hasCatalog {
                        NavigationLink {
                            ExerciseDetailView(exerciseId: resolved.id)
                        } label: {
                            ExerciseThumb(exercise: resolved, size: 48)
                        }
                    } else {
                        ExerciseThumb(exercise: resolved, size: 48)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        if hasCatalog {
                            NavigationLink {
                                ExerciseDetailView(exerciseId: resolved.id)
                            } label: {
                                Text(resolved.name)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(OG.label)
                            }
                        } else {
                            Text(resolved.name)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(OG.label)
                        }
                        Text(move.summaryLine)
                            .font(.caption)
                            .foregroundStyle(OG.label2)
                        completedWODScalingFields(movementID: move.id, exercise: resolved)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    exerciseOptions(blockID: routine.blocks[index].id, itemID: move.id, isWOD: true)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.vertical, 5)
            } else {
                HStack(spacing: 4) {
                    Group {
                        if hasCatalog {
                            NavigationLink {
                                ExerciseDetailView(exerciseId: resolved.id)
                            } label: {
                                movementRowLabel(move: move, resolved: resolved, showSummary: false)
                            }
                            .accessibilityHint("Ver ficha del ejercicio")
                        } else {
                            movementRowLabel(move: move, resolved: resolved, showSummary: false)
                        }
                    }
                    exerciseOptions(blockID: routine.blocks[index].id, itemID: move.id, isWOD: true, isRest: move.isRest)
                }
                .listRowSeparator(.hidden, edges: .bottom)
            }

            if move.isRest {
                Stepper(
                    "Segundos: \(routine.blocks[index].movements[mIndex].restSeconds ?? 60)",
                    value: Binding(
                        get: { routine.blocks[index].movements[mIndex].restSeconds ?? 60 },
                        set: { routine.blocks[index].movements[mIndex].restSeconds = $0 }
                    ),
                    in: 15...300,
                    step: 15
                )
            } else if isEditingCompletedWorkout,
                      let format = routine.blocks[index].wodFormat,
                      format.resultCapture != .perMovementSets {
                // Ya se registran los datos reales junto al título y miniatura.
                EmptyView()
            } else {
                if isEditingCompletedWorkout {
                    let logged = completedWorkoutDraft?.exercises.first(where: { $0.id == move.id
                        || ($0.blockId == routine.blocks[index].id
                            && $0.exercise.name.localizedCaseInsensitiveCompare(move.name) == .orderedSame)
                    })?.loggedSets.isEmpty == false
                    Text(logged ? "Series registradas" : "Sin series registradas · prescripción")
                        .font(.caption)
                        .foregroundStyle(OG.label2)
                }
                InlineWODMovementSets(
                    movement: Binding(
                        get: { routine.blocks[index].movements[mIndex] },
                        set: { routine.blocks[index].movements[mIndex] = $0 }
                    ),
                    block: routine.blocks[index],
                    openedSetID: $openedSetID
                )
            }
        }

        Button("Añadir ejercicio al WOD") { pickMovementForBlock = routine.blocks[index].id }
        Button("Añadir descanso") {
            routine.blocks[index].movements.append(
                WODMovement(name: "REST", isRest: true, restSeconds: 60)
            )
        }
        Button("Añadir movimiento libre") {
            createFreeMovementForBlock = routine.blocks[index].id
        }

        TextField("Notas / texto del WOD", text: Binding(
            get: { routine.blocks[index].wodNotes ?? "" },
            set: { routine.blocks[index].wodNotes = $0.isEmpty ? nil : $0 }
        ), axis: .vertical)
        .lineLimit(2...5)
    }

    /// Resuelve el ejercicio del catálogo para miniaturas en bloques WOD (EMOM, AMRAP…).
    private func resolvedExercise(for move: WODMovement) -> Exercise {
        if let match = CrossFitGlossary.catalogExercise(for: move, in: store.state.exercises) {
            return match
        }
        let canonical = CrossFitGlossary.resolveCatalogName(move.name, notes: move.notes)
        // Mantiene una identidad visual coherente incluso si el ejercicio
        // importado todavía no tiene ID en el catálogo del usuario.
        return Exercise(name: canonical, muscleGroup: "WOD", isCustom: true)
    }

    @ViewBuilder
    private func movementRowLabel(move: WODMovement, resolved: Exercise, showSummary: Bool = true) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if move.isRest {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(OG.surface2)
                    Image(systemName: "pause.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(OG.label3)
                }
                .frame(width: 48, height: 48)
            } else {
                ExerciseThumb(exercise: resolved, size: 48)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(move.isRest ? "Descanso" : resolved.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(OG.label)
                if showSummary {
                    Text(move.summaryLine)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

/// El editor WOD inserta las series dentro de una única fila de Form.
/// Cada fila posee su propio desplazamiento limitado y UNA sola papelera.
/// No utilizar .swipeActions aquí: afecta a la fila contenedora completa.
struct OGSetSwipeDeleteRow<Content: View>: View {
    let canDelete: Bool
    let setID: UUID
    @Binding var openedSetID: UUID?
    let onDelete: () -> Void
    @ViewBuilder let content: () -> Content

    private var isRevealed: Bool { openedSetID == setID }
    @State private var activeDrag: CGFloat = 0
    private let revealWidth: CGFloat = 72

    var body: some View {
        ZStack(alignment: .trailing) {
            if canDelete && (isRevealed || activeDrag < -2) {
                Button {
                    withAnimation(.smooth(duration: 0.2)) {
                        openedSetID = nil
                        activeDrag = 0
                    }
                    onDelete()
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(OG.red, in: RoundedRectangle(cornerRadius: 12))
                        .frame(width: revealWidth, alignment: .trailing)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Eliminar serie")
            }

            // Desplazar toda la fila; ocultar el fondo rojo bajo los inputs.
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background { Rectangle().fill(OG.surface) }
                .offset(x: canDelete ? max(-revealWidth, min(0,
                    (isRevealed ? -revealWidth : 0) + activeDrag
                )) : 0)
        }
        .contentShape(Rectangle())
        .clipped()
        .simultaneousGesture(
            DragGesture(minimumDistance: 18)
                .onChanged { value in
                    guard canDelete,
                          abs(value.translation.width) > abs(value.translation.height) * 1.25
                    else { return }
                    activeDrag = value.translation.width
                }
                .onEnded { value in
                    guard canDelete else { return }
                    let projected = (isRevealed ? -revealWidth : 0)
                        + value.predictedEndTranslation.width
                    withAnimation(.smooth(duration: 0.22)) {
                        openedSetID = projected < -revealWidth * 0.4 ? setID : nil
                        activeDrag = 0
                    }
                }
        )
        .onChange(of: canDelete) { _, allowed in
            if !allowed, isRevealed {
                openedSetID = nil
                activeDrag = 0
            }
        }
        .accessibilityAction(named: "Eliminar serie") {
            if canDelete { onDelete() }
        }
    }
}

// MARK: - Inline WOD sets (en la página de crear/editar entreno)

/// Controles de series WOD embebidos (mismo comportamiento que `WODMovementEditor`).
private struct InlineWODMovementSets: View {
    @Environment(ReperaStore.self) private var store
    @Binding var movement: WODMovement
    var block: RoutineBlock
    /// En historial, dibujar las series no reescribe automáticamente la prescripción Rx.
    var preservePrescriptionOnAppear = false

    @State private var draftSets: [PlannedSet] = []
    @State private var didSeedSets = false
    @Binding var openedSetID: UUID?
    @FocusState private var focusedSetField: OGSetFieldID?

    private var weightStep: Double { store.state.settings.weightIncrementKg }

    private var loggingStyle: ExerciseLoggingStyle {
        let catalogName = CrossFitGlossary.resolveCatalogName(movement.name, notes: movement.notes)
        if let match = store.state.exercises.first(where: {
            $0.name.localizedCaseInsensitiveCompare(catalogName) == .orderedSame
        }) {
            return match.loggingStyle
        }
        return Exercise.loggingStyle(name: catalogName, equipment: movement.notes)
    }

    private var isWeightedDistance: Bool {
        Exercise.supportsRepsOrMeters(name: movement.name)
            || Exercise.supportsRepsOrMeters(
                name: CrossFitGlossary.resolveCatalogName(movement.name, notes: movement.notes)
            )
    }

    private var cardioUnitPicker: some View {
        Picker("Unidad", selection: Binding(
            get: { movement.prescribedQuantityUnit },
            set: { unit in
                let amount = draftSets.first?.targetReps ?? 10
                switch unit {
                case .calories:
                    movement.calories = amount
                    movement.distanceMeters = nil
                case .meters:
                    movement.distanceMeters = amount
                    movement.calories = nil
                case .reps:
                    movement.calories = nil
                    movement.distanceMeters = nil
                }
                writeSetsToMovement()
            }
        )) {
            if isWeightedDistance {
                Text("Repeticiones").tag(ExerciseQuantityUnit.reps)
            } else {
                Text("Calorías").tag(ExerciseQuantityUnit.calories)
            }
            Text("Metros").tag(ExerciseQuantityUnit.meters)
        }
        .pickerStyle(.segmented)
    }

    private var resolvedLoadField: ExerciseLoadField {
        let catalogName = CrossFitGlossary.resolveCatalogName(movement.name, notes: movement.notes)
        if let match = store.state.exercises.first(where: {
            $0.name.localizedCaseInsensitiveCompare(catalogName) == .orderedSame
        }) {
            return match.loadField
        }
        return Exercise.loadField(name: catalogName, equipment: movement.notes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if loggingStyle == .machineWork || isWeightedDistance { cardioUnitPicker }
            OGSetEntryHeader(
                firstTitle: loggingStyle == .loadAndReps ? (resolvedLoadField == .deficitCm ? "Déficit" : "KG") : (loggingStyle == .machineWork || isWeightedDistance ? movement.prescribedQuantityUnit.shortLabel : "Reps"),
                secondTitle: loggingStyle == .loadAndReps
                    ? (isWeightedDistance ? movement.prescribedQuantityUnit.shortLabel : "Reps") : nil,
                showsRIR: loggingStyle.usesRIR
            )
            ForEach(Array(draftSets.enumerated()), id: \.element.id) { index, currentSet in
                // Aquí las series viven dentro de una sola fila del Form.
                // .swipeActions no llega a cada serie: un reveal propio por
                // UUID impide que aparezcan varias papeleras a la vez.
                OGSetSwipeDeleteRow(
                    canDelete: draftSets.count > 1,
                    setID: currentSet.id,
                    openedSetID: $openedSetID,
                    onDelete: { removeSet(at: index) }
                ) {
                    setRow(index: index)
                }
                .contextMenu {
                    if draftSets.count > 1 {
                        Button("Eliminar serie", role: .destructive) {
                            removeSet(at: index)
                        }
                    }
                }
            }
            Button {
                addSet()
            } label: {
                Label("Añadir serie", systemImage: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(OG.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .onAppear { seedSetsIfNeeded() }
        .onChange(of: movement.id) { _, _ in
            didSeedSets = false
            seedSetsIfNeeded()
        }
    }

    private func seedSetsIfNeeded() {
        guard !didSeedSets, !movement.isRest else { return }
        didSeedSets = true
        draftSets = block.plannedSets(for: movement)
        if draftSets.isEmpty {
            draftSets = movement.plannedSetsFromReps
        }
        if draftSets.isEmpty {
            draftSets = [PlannedSet(targetReps: movement.reps ?? 10, targetWeightKg: movement.weightMaleKg)]
        }
        if !preservePrescriptionOnAppear {
            writeSetsToMovement()
        }
    }

    @ViewBuilder
    private func setRow(index: Int) -> some View {
        let style = loggingStyle
        let quantityCap = isWeightedDistance && movement.prescribedQuantityUnit == .meters
            ? 100_000 : style.quantityCap
        let catalogName = CrossFitGlossary.resolveCatalogName(movement.name, notes: movement.notes)
        let catalogExercise = store.state.exercises.first {
            $0.name.localizedCaseInsensitiveCompare(catalogName) == .orderedSame
        }
        let oldSets = catalogExercise.flatMap { store.cachedLastWorkingSession(for: $0.id)?.sets }
        let oldSet = (oldSets?.indices.contains(index) == true) ? oldSets?[index] : nil
        VStack(alignment: .leading, spacing: 6) {
            OGSetEntryRow(
                rowID: draftSets[index].id,
                index: index + 1,
                previous: OGSetEntryRow.previousText(oldSet),
                firstValue: style == .loadAndReps
                    ? (draftSets[index].targetWeightKg.map { ReperaNumberFormat.decimal($0) } ?? "0")
                    : "\(draftSets[index].targetReps)",
                secondValue: style == .loadAndReps ? "\(draftSets[index].targetReps)" : nil,
                firstAllowsDecimal: style == .loadAndReps && resolvedLoadField == .weightKg,
                rir: draftSets[index].targetRir,
                showsRIR: style.usesRIR,
                onRIRChange: { value in
                    draftSets[index].targetRir = value
                    writeSetsToMovement()
                },
                focus: $focusedSetField,
                onFirstCommit: { text in
                    if style == .loadAndReps {
                        let normalized = text
                        if let parsed = ReperaNumberFormat.parse(normalized) {
                            let value = resolvedLoadField == .deficitCm
                                ? min(60, max(0, parsed))
                                : max(0, parsed)
                            draftSets[index].targetWeightKg = value > 0 ? ((value * 10).rounded() / 10) : nil
                        } else if normalized.isEmpty {
                            draftSets[index].targetWeightKg = nil
                        }
                    } else if let parsed = Int(text) {
                        draftSets[index].targetReps = min(quantityCap, max(1, parsed))
                    }
                    writeSetsToMovement()
                },
                onSecondCommit: { text in
                    if let parsed = Int(text) {
                        draftSets[index].targetReps = min(quantityCap, max(1, parsed))
                        writeSetsToMovement()
                    }
                }
            )

        }
    }

    private func addSet() {
        guard draftSets.count < 20 else { return }
        let last = draftSets.last
        draftSets.append(
            PlannedSet(
                targetReps: last?.targetReps ?? movement.reps ?? 10,
                targetWeightKg: last?.targetWeightKg ?? movement.weightMaleKg,
                targetRir: last?.targetRir
            )
        )
        writeSetsToMovement()
    }

    private func removeSet(at index: Int) {
        guard draftSets.count > 1, draftSets.indices.contains(index) else { return }
        draftSets.remove(at: index)
        writeSetsToMovement()
    }

    private func writeSetsToMovement() {
        movement.explicitPlannedSets = draftSets
        let repsList = draftSets.map(\.targetReps)
        if isWeightedDistance {
            let unit = movement.prescribedQuantityUnit
            movement.calories = nil
            movement.distanceMeters = unit == .meters ? repsList.first : nil
            movement.reps = unit == .meters ? nil : repsList.first
            movement.repScheme = repsList.count > 1 ? repsList : nil
        } else if loggingStyle == .machineWork {
            let qty = repsList.first
            switch movement.prescribedQuantityUnit {
            case .calories:
                movement.calories = qty
                if movement.distanceMeters == nil { movement.reps = nil }
            case .meters:
                movement.distanceMeters = qty
                if movement.calories == nil { movement.reps = nil }
            case .reps:
                movement.reps = qty
            }
            movement.repScheme = repsList.count > 1 ? repsList : nil
        } else if repsList.count <= 1 {
            movement.repScheme = nil
            movement.reps = repsList.first
        } else {
            movement.repScheme = repsList
            movement.reps = nil
        }
        if let kg = draftSets.compactMap(\.targetWeightKg).first {
            movement.weightMaleKg = kg
        }
    }
}

// MARK: - WOD movement editor

/// Editor de movimiento WOD alineado con Apuntar: series según estilo (kg / tiempo / reps).
struct WODMovementEditor: View {
    @State private var openedSetID: UUID?
    @Environment(ReperaStore.self) private var store
    @Binding var movement: WODMovement
    /// Bloque padre para derivar las mismas series que Empezar/Apuntar.
    var block: RoutineBlock? = nil

    @State private var draftSets: [PlannedSet] = []
    @State private var didSeedSets = false
    @FocusState private var focusedSetField: OGSetFieldID?
    @State private var weightFieldRowID = UUID()
    @State private var maleWeightDraft = ""
    @State private var femaleWeightDraft = ""
    @FocusState private var weightFieldFocus: OGSetFieldID?

    private var weightStep: Double { store.state.settings.weightIncrementKg }

    private var loggingStyle: ExerciseLoggingStyle {
        let catalogName = CrossFitGlossary.resolveCatalogName(movement.name, notes: movement.notes)
        if let match = store.state.exercises.first(where: {
            $0.name.localizedCaseInsensitiveCompare(catalogName) == .orderedSame
        }) {
            return match.loggingStyle
        }
        return Exercise.loggingStyle(name: catalogName, equipment: movement.notes)
    }

    private var isWeightedDistance: Bool {
        Exercise.supportsRepsOrMeters(name: movement.name)
            || Exercise.supportsRepsOrMeters(
                name: CrossFitGlossary.resolveCatalogName(movement.name, notes: movement.notes)
            )
    }

    private var cardioUnitPicker: some View {
        Picker("Unidad", selection: Binding(
            get: { movement.prescribedQuantityUnit },
            set: { unit in
                let amount = draftSets.first?.targetReps ?? 10
                switch unit {
                case .calories:
                    movement.calories = amount
                    movement.distanceMeters = nil
                case .meters:
                    movement.distanceMeters = amount
                    movement.calories = nil
                case .reps:
                    movement.calories = nil
                    movement.distanceMeters = nil
                }
                writeSetsToMovement()
            }
        )) {
            if isWeightedDistance {
                Text("Repeticiones").tag(ExerciseQuantityUnit.reps)
            } else {
                Text("Calorías").tag(ExerciseQuantityUnit.calories)
            }
            Text("Metros").tag(ExerciseQuantityUnit.meters)
        }
        .pickerStyle(.segmented)
    }

    private var resolvedLoadField: ExerciseLoadField {
        let catalogName = CrossFitGlossary.resolveCatalogName(movement.name, notes: movement.notes)
        if let match = store.state.exercises.first(where: {
            $0.name.localizedCaseInsensitiveCompare(catalogName) == .orderedSame
        }) {
            return match.loadField
        }
        return Exercise.loadField(name: catalogName, equipment: movement.notes)
    }

    var body: some View {
        Form {
            OGScrollablePageTitle("Movimiento WOD").ogScrollingTitleListRow()
            Toggle("Es descanso", isOn: $movement.isRest)
            if movement.isRest {
                Stepper("Segundos: \(movement.restSeconds ?? 60)", value: Binding(
                    get: { movement.restSeconds ?? 60 },
                    set: { movement.restSeconds = $0 }
                ), in: 15...300, step: 15)
            } else {
                TextField("Nombre", text: $movement.name)

                Section {
                    if loggingStyle == .machineWork || isWeightedDistance { cardioUnitPicker }
                    OGSetEntryHeader(
                        firstTitle: loggingStyle == .loadAndReps ? (resolvedLoadField == .deficitCm ? "Déficit" : "KG") : (loggingStyle == .machineWork || isWeightedDistance ? movement.prescribedQuantityUnit.shortLabel : (loggingStyle == .repsAndTime ? "Veces" : "Reps")),
                        secondTitle: loggingStyle == .loadAndReps
                    ? (isWeightedDistance ? movement.prescribedQuantityUnit.shortLabel : "Reps") : nil,
                        showsRIR: loggingStyle.usesRIR
                    )
                    ForEach(Array(draftSets.enumerated()), id: \.element.id) { index, current in
                        OGSetSwipeDeleteRow(
                            canDelete: draftSets.count > 1,
                            setID: current.id,
                            openedSetID: $openedSetID,
                            onDelete: { removeSet(at: index) }
                        ) {
                            wodSetRow(index: index)
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                    Button {
                        addSet()
                    } label: {
                        Label("Añadir serie", systemImage: "plus")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(OG.accent)
                    }
                } header: {
                    Text("Series al apuntar")
                } footer: {
                    switch loggingStyle {
                    case .repsAndTime:
                        Text("Comba: veces (dobles) · tiempo de la serie.")
                    case .machineWork:
                        Text("Máquina / carrera: prescribe calorías y/o metros (sin kilos).")
                    case .repsOnly:
                        Text("Solo reps (peso corporal).")
                    case .loadAndReps:
                        if isWeightedDistance {
                            Text("Walking lunge: repeticiones o metros, siempre con peso opcional en kg y RIR.")
                        } else if resolvedLoadField == .deficitCm {
                            Text("HSPU: déficit (cm) · reps. 0 = sin déficit.")
                        } else {
                            Text("Peso/lastre · reps · RIR. Dominadas: lastre 0 = sin lastre.")
                        }
                    }
                }

                if loggingStyle != .machineWork && !isWeightedDistance {
                    Stepper("Metros: \(movement.distanceMeters ?? 0)", value: Binding(
                        get: { movement.distanceMeters ?? 0 },
                        set: { movement.distanceMeters = $0 == 0 ? nil : $0 }
                    ), in: 0...5000, step: 50)
                }
                if loggingStyle == .loadAndReps {
                    HStack(spacing: 8) {
                        Text("Peso H/M (kg)")
                            .font(.system(size: 13, weight: .medium))
                        Spacer(minLength: 4)
                        weightField(text: $maleWeightDraft, column: 0, nextColumn: 1)
                        Text("/").foregroundStyle(OG.label2)
                        weightField(text: $femaleWeightDraft, column: 1, nextColumn: nil)
                    }
                }
                TextField("Escala alternativa (ej. 100 SU)", text: Binding(
                    get: { movement.scaleAlternative ?? "" },
                    set: { movement.scaleAlternative = $0.isEmpty ? nil : $0 }
                ))
                TextField("Notas", text: Binding(
                    get: { movement.notes ?? "" },
                    set: { movement.notes = $0.isEmpty ? nil : $0 }
                ))
            }
            Section("Vista previa") {
                Text(movement.summaryLine)
                    .font(.system(.body, design: .monospaced))
            }
        }
        .ogListChrome()
        .ogScrollingTitleNav()
        .onAppear {
            seedSetsIfNeeded()
            maleWeightDraft = movement.weightMaleKg.map { ReperaNumberFormat.decimal($0) } ?? ""
            femaleWeightDraft = movement.weightFemaleKg.map { ReperaNumberFormat.decimal($0) } ?? ""
        }
    }

    private func weightField(
        text: Binding<String>,
        column: Int,
        nextColumn: Int?
    ) -> some View {
        let id = OGSetFieldID(rowID: weightFieldRowID, column: column)
        return OGNumericTextField(
            text: text,
            allowsDecimal: true,
            fontSize: 16,
            autoFocus: false,
            isFocused: weightFieldFocus == id,
            submitTitle: nextColumn == nil ? "✓" : "Siguiente",
            onFocused: { weightFieldFocus = id },
            onFocusLost: {
                commitWeightDraft(column: column)
                if weightFieldFocus == id { weightFieldFocus = nil }
            },
            onCommit: {
                commitWeightDraft(column: column)
                weightFieldFocus = nextColumn.map {
                    OGSetFieldID(rowID: weightFieldRowID, column: $0)
                }
            }
        )
        .frame(width: 80, height: 44)
        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func commitWeightDraft(column: Int) {
        if column == 0 {
            movement.weightMaleKg = ReperaNumberFormat.parse(maleWeightDraft)
            applyMovementWeightToEmptySets()
        } else {
            movement.weightFemaleKg = ReperaNumberFormat.parse(femaleWeightDraft)
        }
    }

    private func seedSetsIfNeeded() {
        guard !didSeedSets, !movement.isRest else { return }
        didSeedSets = true
        if let block {
            draftSets = block.plannedSets(for: movement)
        } else {
            draftSets = movement.plannedSetsFromReps
        }
        if draftSets.isEmpty {
            draftSets = [PlannedSet(targetReps: movement.reps ?? 10, targetWeightKg: movement.weightMaleKg)]
        }
    }

    private func wodSetRow(index: Int) -> some View {
        let style = loggingStyle
        let quantityCap = isWeightedDistance && movement.prescribedQuantityUnit == .meters
            ? 100_000 : style.quantityCap
        let catalogName = CrossFitGlossary.resolveCatalogName(movement.name, notes: movement.notes)
        let catalogExercise = store.state.exercises.first {
            $0.name.localizedCaseInsensitiveCompare(catalogName) == .orderedSame
        }
        let oldSets = catalogExercise.flatMap { store.cachedLastWorkingSession(for: $0.id)?.sets }
        let oldSet = (oldSets?.indices.contains(index) == true) ? oldSets?[index] : nil
        return VStack(alignment: .leading, spacing: 6) {
            OGSetEntryRow(
                rowID: draftSets[index].id,
                index: index + 1,
                previous: OGSetEntryRow.previousText(oldSet),
                firstValue: style == .loadAndReps
                    ? (draftSets[index].targetWeightKg.map { ReperaNumberFormat.decimal($0) } ?? "0")
                    : "\(draftSets[index].targetReps)",
                secondValue: style == .loadAndReps ? "\(draftSets[index].targetReps)" : nil,
                firstAllowsDecimal: style == .loadAndReps && resolvedLoadField == .weightKg,
                rir: draftSets[index].targetRir,
                showsRIR: style.usesRIR,
                onRIRChange: { value in
                    draftSets[index].targetRir = value
                    writeSetsToMovement()
                },
                focus: $focusedSetField,
                onFirstCommit: { text in
                    if style == .loadAndReps {
                        let normalized = text
                        if let parsed = ReperaNumberFormat.parse(normalized) {
                            let value = resolvedLoadField == .deficitCm
                                ? min(60, max(0, parsed))
                                : max(0, parsed)
                            draftSets[index].targetWeightKg = value > 0 ? ((value * 10).rounded() / 10) : nil
                        } else if normalized.isEmpty {
                            draftSets[index].targetWeightKg = nil
                        }
                    } else if let parsed = Int(text) {
                        draftSets[index].targetReps = min(quantityCap, max(1, parsed))
                    }
                    writeSetsToMovement()
                },
                onSecondCommit: { text in
                    if let parsed = Int(text) {
                        draftSets[index].targetReps = min(quantityCap, max(1, parsed))
                        writeSetsToMovement()
                    }
                }
            )

        }
    }

    private func addSet() {
        guard draftSets.count < 20 else { return }
        let last = draftSets.last
        draftSets.append(
            PlannedSet(
                targetReps: last?.targetReps ?? movement.reps ?? 10,
                targetWeightKg: last?.targetWeightKg ?? movement.weightMaleKg,
                targetRir: last?.targetRir
            )
        )
        writeSetsToMovement()
    }

    private func removeSet(at index: Int) {
        guard draftSets.count > 1, draftSets.indices.contains(index) else { return }
        draftSets.remove(at: index)
        writeSetsToMovement()
    }

    private func applyMovementWeightToEmptySets() {
        guard let kg = movement.weightMaleKg else { return }
        for i in draftSets.indices where draftSets[i].targetWeightKg == nil {
            draftSets[i].targetWeightKg = kg
        }
        writeSetsToMovement()
    }

    /// Persiste series explícitas (reps/peso/RIR) para que Apuntar/Empezar coincidan.
    private func writeSetsToMovement() {
        movement.explicitPlannedSets = draftSets
        let repsList = draftSets.map(\.targetReps)
        if isWeightedDistance {
            let unit = movement.prescribedQuantityUnit
            movement.calories = nil
            movement.distanceMeters = unit == .meters ? repsList.first : nil
            movement.reps = unit == .meters ? nil : repsList.first
            movement.repScheme = repsList.count > 1 ? repsList : nil
        } else if loggingStyle == .machineWork {
            // En erg la cantidad de la 1.ª serie alimenta cal o metros prescritos.
            let qty = repsList.first
            switch movement.prescribedQuantityUnit {
            case .calories:
                movement.calories = qty
                if movement.distanceMeters == nil { movement.reps = nil }
            case .meters:
                movement.distanceMeters = qty
                if movement.calories == nil { movement.reps = nil }
            case .reps:
                movement.reps = qty
            }
            movement.repScheme = repsList.count > 1 ? repsList : nil
        } else if repsList.count <= 1 {
            movement.repScheme = nil
            movement.reps = repsList.first
        } else {
            movement.repScheme = repsList
            movement.reps = nil
        }
        if let kg = draftSets.compactMap(\.targetWeightKg).first {
            movement.weightMaleKg = kg
        }
    }
}

// MARK: - Strength exercise editor + picker

struct RoutineExerciseEditor: View {
    @State private var openedSetID: UUID?
    @Environment(ReperaStore.self) private var store
    var exerciseName: String
    var exerciseId: UUID
    @Binding var item: RoutineExercise

    private var exercise: Exercise? {
        store.state.exercises.first { $0.id == exerciseId }
    }

    private var weightStep: Double { store.state.settings.weightIncrementKg }

    private var referenceSet: PlannedSet {
        item.plannedSets.first ?? PlannedSet(targetReps: 8)
    }

    var body: some View {
        Form {
            OGScrollablePageTitle(exerciseName).ogScrollingTitleListRow()
            if let exercise {
                Section {
                    ExerciseArtView(exercise: exercise, showBadge: false, showStepCaptions: false)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            if exercise?.loggingStyle == .loadAndReps {
                Section {
                    ExerciseLoadGuideCard(
                        exerciseId: exerciseId,
                        targetReps: referenceSet.targetReps,
                        targetRir: referenceSet.targetRir,
                        onApplySuggestedKg: { kg in
                            applySuggestedLoad(kg)
                        },
                        onApplyLastSession: { last in
                            applyLastSession(last)
                        }
                    )
                    .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                    .listRowBackground(OG.surface)
                } header: {
                    Text("Referencia")
                } footer: {
                    Text("Aplicar escala la última sesión al kg sugerido (misma progresión, reps y RIR).")
                }
            }

            Section {
                if let exercise,
                   exercise.supportsRepsOrMeters
                    || (exercise.loggingStyle == .machineWork && exercise.allowsCalorieOrDistanceToggle) {
                    Picker("Unidad", selection: Binding(
                        get: { item.quantityUnit ?? exercise.defaultQuantityUnit },
                        set: { item.quantityUnit = $0 }
                    )) {
                        if exercise.supportsRepsOrMeters {
                            Text("Repeticiones").tag(ExerciseQuantityUnit.reps)
                        } else {
                            Text("Calorías").tag(ExerciseQuantityUnit.calories)
                        }
                        Text("Metros").tag(ExerciseQuantityUnit.meters)
                    }
                    .pickerStyle(.segmented)
                }
                OGSetEntryHeader(
                    firstTitle: exercise?.isMobility == true ? "Tiempo (s)" : (exercise?.loggingStyle == .loadAndReps
                        ? (exercise?.loadField == .deficitCm ? "Déficit" : "KG")
                        : (exercise?.loggingStyle == .machineWork
                            ? (item.quantityUnit ?? exercise?.defaultQuantityUnit ?? .calories).shortLabel
                            : (exercise?.supportsRepsOrMeters == true
                                ? (item.quantityUnit ?? exercise?.defaultQuantityUnit ?? .reps).shortLabel
                                : (exercise?.quantityFieldLabel ?? "Reps")))),
                    secondTitle: exercise?.isMobility == true
                        ? (exercise?.isMobilityHold == true ? nil : "Reps")
                        : (exercise?.loggingStyle == .loadAndReps
                            ? (exercise?.supportsRepsOrMeters == true
                                ? (item.quantityUnit ?? .reps).shortLabel : "Reps") : nil),
                    showsRIR: exercise?.loggingStyle.usesRIR ?? false
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 4, trailing: 16))

                ForEach(Array(item.plannedSets.enumerated()), id: \.element.id) { index, set in
                    OGSetSwipeDeleteRow(
                        canDelete: item.plannedSets.count > 1,
                        setID: set.id,
                        openedSetID: $openedSetID,
                        onDelete: { deleteSet(at: index) }
                    ) {
                    PlannedSetConfigRow(
                        index: index + 1,
                        set: binding(for: index),
                        weightStep: weightStep,
                        exerciseStyle: exercise?.loggingStyle ?? .loadAndReps,
                        quantityCap: exercise?.supportsRepsOrMeters == true && item.quantityUnit == .meters
                            ? 100_000 : nil,
                        isMobility: exercise?.isMobility ?? false,
                        isMobilityHold: exercise?.isMobilityHold ?? false,
                        previous: {
                            let sets = store.cachedLastWorkingSession(for: exerciseId)?.sets
                            return (sets?.indices.contains(index) == true) ? sets?[index] : nil
                        }()
                    )
                    }
                }

                Button {
                    addSet()
                } label: {
                    Label("Añadir serie", systemImage: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(OG.accent)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            } header: {
                Text("Objetivo por serie")
            } footer: {
                Text(exercise?.isMobility == true
                     ? "Objetivo de duración por serie en segundos. Las posturas se registran por tiempo y la movilidad dinámica por repeticiones y tiempo; sin kg ni RIR."
                     : (exercise?.loggingStyle == .machineWork
                     ? "Introduce calorías o metros por serie; el cardio no utiliza kilogramos."
                     : "Cada serie puede tener cantidad, peso y RIR distintos según el movimiento."))
            }

            Section {
                NavigationLink("Ver ficha del ejercicio") {
                    ExerciseDetailView(exerciseId: exerciseId)
                }
            }
        }
        .listStyle(.insetGrouped)
        .ogListChrome()
        .ogScrollingTitleNav()
        .onAppear {
            if item.plannedSets.isEmpty {
                let style = exercise?.loggingStyle ?? .loadAndReps
                let qty = style == .machineWork
                    ? (exercise?.defaultQuantityUnit == .meters ? 500 : 15)
                    : (exercise?.isMobility == true ? (exercise?.isMobilityHold == true ? 1 : 8) : (style == .repsAndTime ? 50 : 8))
                item.plannedSets = [PlannedSet(targetReps: qty, targetWeightKg: nil,
                    targetDurationSeconds: exercise?.isMobility == true ? (exercise?.isMobilityHold == true ? 30 : 60) : nil)]
            }
        }
    }

    /// Escala la última sesión al kg sugerido: misma progresión de pesos, mismas reps y RIR.
    private func applySuggestedLoad(_ kg: Double) {
        guard kg > 0 else { return }
        let step = max(weightStep, 0.5)
        let fallbackRir = referenceSet.targetRir ?? 2

        if let last = store.cachedLastWorkingSession(for: exerciseId),
           !last.sets.isEmpty {
            let anchor = last.topSet?.weightKg
                ?? last.sets.compactMap(\.weightKg).first
            if let anchor, anchor > 0 {
                let ratio = kg / anchor
                item.plannedSets = last.sets.map { set in
                    let scaled: Double? = {
                        guard let w = set.weightKg, w > 0 else { return kg }
                        let raw = w * ratio
                        let rounded = (raw / step).rounded() * step
                        return rounded > 0 ? rounded : nil
                    }()
                    return PlannedSet(
                        targetReps: set.reps,
                        targetWeightKg: scaled,
                        targetRir: set.rir ?? fallbackRir
                    )
                }
            } else {
                item.plannedSets = last.sets.map { set in
                    PlannedSet(
                        targetReps: set.reps,
                        targetWeightKg: kg,
                        targetRir: set.rir ?? fallbackRir
                    )
                }
            }
            return
        }

        for i in item.plannedSets.indices {
            item.plannedSets[i].targetWeightKg = kg
            if item.plannedSets[i].targetRir == nil {
                item.plannedSets[i].targetRir = fallbackRir
            }
        }
    }

    private func applyLastSession(_ last: ExerciseLastSession) {
        guard !last.sets.isEmpty else { return }
        item.plannedSets = last.sets.map { set in
            PlannedSet(
                targetReps: set.reps,
                targetWeightKg: set.weightKg,
                targetRir: set.rir
            )
        }
    }

    private func binding(for index: Int) -> Binding<PlannedSet> {
        Binding(
            get: {
                guard item.plannedSets.indices.contains(index) else {
                    return PlannedSet(targetReps: 8)
                }
                return item.plannedSets[index]
            },
            set: { newValue in
                guard item.plannedSets.indices.contains(index) else { return }
                item.plannedSets[index] = newValue
            }
        )
    }

    private func addSet() {
        guard item.plannedSets.count < 12 else { return }
        let last = item.plannedSets.last
        item.plannedSets.append(
            PlannedSet(
                targetReps: last?.targetReps ?? 8,
                targetWeightKg: last?.targetWeightKg,
                targetDurationSeconds: last?.targetDurationSeconds,
                targetRir: last?.targetRir
            )
        )
    }

    private func deleteSet(at index: Int) {
        guard item.plannedSets.count > 1, item.plannedSets.indices.contains(index) else { return }
        item.plannedSets.remove(at: index)
    }
}

/// Fila de objetivo: peso / reps / RIR. Borrar serie = swipe (sin icono de papelera).
private struct PlannedSetConfigRow: View {
    var index: Int
    @Binding var set: PlannedSet
    var weightStep: Double
    var exerciseStyle: ExerciseLoggingStyle = .loadAndReps
    var quantityCap: Int? = nil
    var isMobility: Bool = false
    var isMobilityHold: Bool = false
    var previous: ExerciseLastSession.WorkSet? = nil
    @FocusState private var focusedSetField: OGSetFieldID?

    var body: some View {
        OGSetEntryRow(
            rowID: set.id,
            index: index,
            previous: OGSetEntryRow.previousText(previous),
            firstValue: isMobility ? "\(set.targetDurationSeconds ?? (isMobilityHold ? 30 : 60))"
                : (exerciseStyle == .loadAndReps
                ? (set.targetWeightKg.map { ReperaNumberFormat.decimal($0) } ?? "0")
                : "\(set.targetReps)"),
            secondValue: isMobility
                ? (isMobilityHold ? nil : "\(set.targetReps)")
                : (exerciseStyle == .loadAndReps ? "\(set.targetReps)" : nil),
            firstAllowsDecimal: exerciseStyle == .loadAndReps,
            rir: set.targetRir,
            showsRIR: exerciseStyle.usesRIR,
            onRIRChange: { set.targetRir = $0 },
            focus: $focusedSetField,
            onFirstCommit: { text in
                if isMobility {
                    if let seconds = Int(text), seconds > 0 { set.targetDurationSeconds = min(3600, seconds) }
                } else if exerciseStyle == .loadAndReps {
                    let normalized = text
                    if normalized.isEmpty {
                        set.targetWeightKg = nil
                    } else if let value = ReperaNumberFormat.parse(normalized) {
                        set.targetWeightKg = value > 0 ? ((value * 10).rounded() / 10) : nil
                    }
                } else if let value = Int(text), value > 0 {
                    set.targetReps = min(quantityCap ?? exerciseStyle.quantityCap, value)
                }
            },
            onSecondCommit: { text in
                if let value = Int(text), value > 0 {
                    set.targetReps = min(quantityCap ?? exerciseStyle.quantityCap, value)
                }
            }
        )
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }
}

struct ExercisePickerView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var embedsNavigationStack = true
    var onPick: (Exercise) -> Void

    var body: some View {
        Group {
            if embedsNavigationStack {
                NavigationStack { pickerContent }
            } else {
                pickerContent
            }
        }
    }

    private var pickerContent: some View {
        ExerciseCatalogSearchList(
            exercises: store.state.exercises,
            prompt: "Buscar ejercicio",
            pageTitle: "Elegir ejercicio"
        ) { exercise in
            onPick(exercise)
            if embedsNavigationStack { dismiss() }
        }
        .ogScrollingTitleNav()
        .toolbar {
            if embedsNavigationStack {
                ToolbarItem(placement: .topBarLeading) {
                    CloseToolbarButton(action: { dismiss() }, large: false)
                }
            }
        }
    }
}

/// Alta de un movimiento libre como página push; se valida antes de añadirlo.
struct FreeWODMovementCreatePage: View {
    @Environment(\.dismiss) private var dismiss
    var onCreate: (WODMovement) -> Void

    @State private var name = ""
    @State private var repsText = "10"
    @State private var maleWeightText = ""
    @State private var femaleWeightText = ""
    @State private var numericGroupID = UUID()
    @FocusState private var numericFocus: OGSetFieldID?

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Form {
            OGScrollablePageTitle("Nuevo movimiento").ogScrollingTitleListRow()
            Section("Movimiento") {
                TextField("Nombre", text: $name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                numericRow("Repeticiones", text: $repsText, column: 0, nextColumn: 1, decimal: false)
            }
            Section("Carga opcional · kg") {
                numericRow("Carga masculina", text: $maleWeightText, column: 1, nextColumn: 2, decimal: true)
                numericRow("Carga femenina", text: $femaleWeightText, column: 2, nextColumn: nil, decimal: true)
            }
        }
        .ogListChrome()
        .ogScrollingTitleNav()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Añadir") {
                    guard let reps = Int(repsText), reps > 0 else { return }
                    let movement = WODMovement(
                        name: trimmedName,
                        reps: reps,
                        weightMaleKg: ReperaNumberFormat.parse(maleWeightText),
                        weightFemaleKg: ReperaNumberFormat.parse(femaleWeightText)
                    )
                    onCreate(movement)
                    dismiss()
                }
                .disabled(trimmedName.isEmpty || (Int(repsText) ?? 0) <= 0)
            }
        }
    }
    private func numericRow(
        _ label: String,
        text: Binding<String>,
        column: Int,
        nextColumn: Int?,
        decimal: Bool
    ) -> some View {
        let field = OGSetFieldID(rowID: numericGroupID, column: column)
        return HStack(spacing: 10) {
            Text(label)
                .foregroundStyle(OG.label)
            Spacer(minLength: 8)
            OGNumericTextField(
                text: text,
                allowsDecimal: decimal,
                fontSize: 17,
                autoFocus: false,
                isFocused: numericFocus == field,
                submitTitle: nextColumn == nil ? "✓" : "Siguiente",
                onFocused: { numericFocus = field },
                onFocusLost: {
                    if numericFocus == field { numericFocus = nil }
                },
                onCommit: {
                    numericFocus = nextColumn.map {
                        OGSetFieldID(rowID: numericGroupID, column: $0)
                    }
                }
            )
            .frame(width: 105, height: 44)
            .padding(.horizontal, 8)
            .background(OG.surface2, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
    }

}

/// Selección del formato como subpágina, nunca confirmationDialog.
struct WODFormatPickerPage: View {
    var onPick: (WODFormat?) -> Void

    var body: some View {
        List {
            OGScrollablePageTitle("Formato del bloque").ogScrollingTitleListRow()
            Button {
                onPick(nil)
            } label: {
                Label("Sin formato · libre", systemImage: "minus.circle")
                    .foregroundStyle(OG.label)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            .buttonStyle(.plain)

            ForEach(WODFormat.allCases, id: \.self) { format in
                Button {
                    onPick(format)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(format.displayName).foregroundStyle(OG.label)
                            Text(format.detail)
                                .font(.caption)
                                .foregroundStyle(OG.label2)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(OG.label3)
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .ogListChrome()
        .ogScrollingTitleNav()
    }
}

// MARK: - Importar bloques de otra rutina

struct RoutineImportPickerSheet: View {
    var routines: [Routine]
    var onPick: (Routine) -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            OGPageHeader(title: "Añadir rutina") {
                CloseToolbarButton(action: onCancel, large: true)
            }

            Text("Se copian los bloques; el título y el día de esta rutina no cambian.")
                .font(.footnote)
                .foregroundStyle(OG.label2)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(routines.enumerated()), id: \.element.id) { index, source in
                    if index > 0 {
                        Divider().opacity(0.35).padding(.leading, 14)
                    }
                    Button {
                        onPick(source)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(source.title)
                                    .foregroundStyle(OG.label)
                                Text(importSubtitle(source))
                                    .font(.caption)
                                    .foregroundStyle(OG.label2)
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(OG.accent)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                }
            }
            .background(OG.surface.opacity(0.55), in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
        }
        .padding(.horizontal, OG.pad)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .ogFittedHeight()
        .ogFittedSheet()
    }

    private func importSubtitle(_ routine: Routine) -> String {
        let strength = routine.blocks.filter { $0.kind == .strength }.flatMap(\.exercises).count
        let wods = routine.blocks.filter { $0.kind == .wod }.count
        var parts: [String] = []
        if strength > 0 { parts.append("\(strength) ej.") }
        if wods > 0 { parts.append("\(wods) WOD") }
        if parts.isEmpty { parts.append("\(routine.blocks.count) bloque\(routine.blocks.count == 1 ? "" : "s")") }
        return parts.joined(separator: " · ")
    }
}


/// Línea de inserción real entre elementos, no sobre la fila arrastrable.
/// La altura táctil sigue siendo suficiente incluso con la línea en reposo.
