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
    /// Siempre ocultar el back nativo: el editor aporta un único chevron
    /// (dirty → confirmación Descartar). Si no, iOS 26 muestra dos Volver.
    var hideNativeBack: Bool = true

    func body(content: Content) -> some View {
        if usesPageCloseHeader {
            content
                .ogScrollingTitleNav()
                .navigationBarBackButtonHidden(true)
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
                .navigationBarBackButtonHidden(embedsNavigationStack || hideNativeBack)
        }
    }

    @ViewBuilder
    private var confirmButton: some View {
        // Siempre el mismo ✓ verde (toolbar o cabecera fija): Liquid Glass
        // no debe dejar un círculo transparente con check gris.
        OGDoneCheckButton(
            accessibilityLabel: confirmTitle,
            enabled: canConfirm,
            action: onConfirm
        )
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State var routine: Routine
    var mode: DayEditorMode
    var onSessionStarted: (() -> Void)? = nil
    /// Cierre explícito cuando se presenta como página (push), no modal.
    var onClose: (() -> Void)? = nil
    /// Si no es nil, el check aplica el draft y cierra sin guardar en el store (revisión de pizarra).
    var onApplyDraft: ((Routine) -> Void)? = nil
    /// Edición de una sesión terminada usando exactamente los mismos bloques/reordenación.
    var onApplyCompleted: ((Routine, WorkoutSession, Bool) -> Void)? = nil
    var completedSession: WorkoutSession? = nil
    /// Salud puede tener la ruta aunque aún no esté en el snapshot local.
    var completedHasHealthRoute: Bool = false
    var embedsNavigationStack: Bool = true
    /// Página push (Entreno → Editar): título large + chevron volver; sin X.
    var usesPageCloseHeader: Bool = false
    @State private var pickExerciseForBlock: UUID?
    @State private var pickMovementForBlock: UUID?
    @State private var createFreeMovementForBlock: UUID?
    @State private var showRoutinePicker = false
    @State private var showWODCatalog = false
    @State private var showBoardScanner = false
    /// El OCR es prescripción hasta que el usuario confirme lo realmente hecho.
    @State private var recordNewSetsAsPerformed = false
    @State private var selectFormatForBlock: UUID?
    @State private var saveAsFavorite = false
    @State private var routineSaveError: String?
    @State private var isConfirmingSave = false
    @FocusState private var focusedFormatField: OGSetFieldID?
    @State private var showsReorder = false
    @State private var reorderDraggedToken: String?
    @State private var replacingExercise: WorkoutReplacementTarget?
    @State private var exerciseDetailID: UUID?
    @State private var pendingReplacement: PendingWorkoutReplacement?
    @State private var openedSetID: UUID?
    @State private var completedDetails: WorkoutSession?
    /// No sobrescribir la elección o eliminación manual con una sugerencia tardía.
    @State private var completedPlaceEdited = false
    @State private var scaledInputDrafts: [String: String] = [:]
    /// Catálogo indexado; se reconstruye solo si cambia el seed del listado.
    @State private var exercisesById: [UUID: Exercise] = [:]
    @State private var exercisesByIdSeed: Int = -1
    /// Paridad Android `expandedEntryId`: solo un ejercicio/movimiento monta
    /// la retícula de series. Montar todas en el Form bloquea «Editar» segundos.
    @State private var expandedEntryID: UUID?
    @State private var baselineRoutine: Routine
    @State private var showDiscardConfirm = false
    @State private var undoToast: OGUndoToastState?
    @State private var blockDeleteConfirmID: UUID?

    init(
        routine: Routine,
        mode: DayEditorMode,
        onSessionStarted: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil,
        onApplyDraft: ((Routine) -> Void)? = nil,
        onApplyCompleted: ((Routine, WorkoutSession, Bool) -> Void)? = nil,
        completedSession: WorkoutSession? = nil,
        completedHasHealthRoute: Bool = false,
        embedsNavigationStack: Bool = true,
        usesPageCloseHeader: Bool = false
    ) {
        // Series por defecto antes del 1.er layout: si se rellenan en onAppear,
        // el Form salta de altura al entrar.
        let normalized = Self.withStrengthPlannedSets(routine)
        _routine = State(initialValue: normalized)
        _baselineRoutine = State(initialValue: normalized)
        _expandedEntryID = State(initialValue: Self.firstExpandableEntryID(in: normalized))
        self.mode = mode
        self.onSessionStarted = onSessionStarted
        self.onClose = onClose
        self.onApplyDraft = onApplyDraft
        self.onApplyCompleted = onApplyCompleted
        self.completedSession = completedSession
        self.completedHasHealthRoute = completedHasHealthRoute
        self.embedsNavigationStack = embedsNavigationStack
        self.usesPageCloseHeader = usesPageCloseHeader
    }

    private static func firstExpandableEntryID(in routine: Routine) -> UUID? {
        for block in routine.blocks {
            if block.kind == .strength, let first = block.exercises.first {
                return first.id
            }
            if let first = block.movements.first(where: { !$0.isRest }) {
                return first.id
            }
        }
        return nil
    }

    private static func withStrengthPlannedSets(_ routine: Routine) -> Routine {
        var copy = routine
        for blockIndex in copy.blocks.indices where copy.blocks[blockIndex].kind == .strength {
            for exerciseIndex in copy.blocks[blockIndex].exercises.indices
            where copy.blocks[blockIndex].exercises[exerciseIndex].plannedSets.isEmpty {
                copy.blocks[blockIndex].exercises[exerciseIndex].plannedSets = [
                    PlannedSet(targetReps: 8, targetWeightKg: nil)
                ]
            }
        }
        return copy
    }

    /// Catálogo usable en el primer frame (sin esperar `onAppear`).
    private var resolvedExerciseCatalog: [UUID: Exercise] {
        if !exercisesById.isEmpty { return exercisesById }
        return Dictionary(uniqueKeysWithValues: store.state.exercises.map { ($0.id, $0) })
    }

    /// La ruta de Historial abre directamente una sesión finalizada. El diseño
    /// no debe esperar a que onAppear inicialice el estado para saber si muestra
    /// un score global o series: eso enseñaba el formulario de prescripción.
    private var isEditingCompletedWorkout: Bool {
        onApplyCompleted != nil && completedSession != nil
    }

    private var completedWorkoutDraft: WorkoutSession? {
        completedDetails ?? completedSession
    }

    /// Una ruta grabada es el registro del reloj/GPS, no un lugar editable.
    private var completedHasRecordedRoute: Bool {
        (completedWorkoutDraft?.routePoints.count ?? 0) >= 2 || completedHasHealthRoute
    }

    private var isEditorDirty: Bool {
        routine != baselineRoutine
    }

    private func discardEditorChanges() {
        routine = baselineRoutine
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    @MainActor
    private func presentUndoToast(message: String, undo: @escaping () -> Void) {
        let state = OGUndoToastState(message: message, undo: undo)
        undoToast = state
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            if undoToast?.id == state.id {
                undoToast = nil
            }
        }
    }

    private func refreshExercisesByIdIfNeeded() {
        let exercises = store.state.exercises
        var hasher = Hasher()
        hasher.combine(exercises.count)
        hasher.combine(exercises.first?.id)
        hasher.combine(exercises.last?.id)
        let seed = hasher.finalize()
        guard seed != exercisesByIdSeed else { return }
        exercisesByIdSeed = seed
        exercisesById = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
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
                Section {
                    OGScrollablePageTitle(navTitle).ogScrollingTitleListRow()
                }
                .listSectionSpacing(0)
            }
            // Una sola caja meta: título + fecha/hora/duración + lugar + notas + favorito
            // (crear / editar / play / histórico). Sin «Datos del entreno realizado» ni
            // el pie «Edita los datos…».
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
                    oneOffDateTimeDurationRow
                    Toggle("Favorito", isOn: $routine.isFavorite)
                        .tint(OG.accent)
                case .favorite:
                    Toggle("Favorito", isOn: $routine.isFavorite)
                        .disabled(true)
                        .tint(OG.accent)
                    Text("Puedes volver a utilizar este entreno desde Añadir entreno → Favoritos.")
                        .font(.footnote)
                        .foregroundStyle(OG.label2)
                    scheduledTimeControls
                case .session:
                    if onApplyCompleted != nil {
                        completedDateTimeDurationRow
                        if completedWorkoutDraft?.liveSportID != nil
                            || completedWorkoutDraft?.awaitingResultEntry == true {
                            Toggle("Registrar nuevas series como realizadas", isOn: $recordNewSetsAsPerformed)
                                .tint(OG.accent)
                            Text("Comprueba las repeticiones, pesos y RIR. Solo al activarlo, las series añadidas se reflejan como resultados reales en Progreso. Las calorías y el pulso registrados no se suman otra vez.")
                                .font(.footnote)
                                .foregroundStyle(OG.label2)
                        }
                        TextField("Notas del entreno", text: Binding(
                            get: { completedDetails?.notes ?? "" },
                            set: { completedDetails?.notes = $0.isEmpty ? nil : $0 }
                        ), axis: .vertical)
                        .lineLimit(2...5)
                        if onApplyDraft == nil {
                            Toggle("Favorito", isOn: $saveAsFavorite)
                                .tint(OG.accent)
                        }
                    } else {
                        if onApplyDraft == nil {
                            Toggle("Favorito", isOn: $saveAsFavorite)
                                .tint(OG.accent)
                        }
                    }
                }
            } footer: {
                switch mode {
                case .session:
                    // Sin pie entre meta unificada; solo aviso al revisar pizarra.
                    if onApplyCompleted != nil || onApplyDraft == nil {
                        EmptyView()
                    } else {
                        Text("Los cambios se aplican al revisar la pizarra; aún no se guarda el día.")
                    }
                case .favorite:
                    Text("Los favoritos se reutilizan desde Añadir entreno → Favoritos.")
                case .oneOff:
                    EmptyView()
                case .plan:
                    Text("La rutina se guarda para reutilizarla. Si seleccionas una fecha, también se programará una copia en el calendario.")
                }
            }

            // Lugar solo en entrenos ya hechos y editables (sin ruta GPS).
            // Crear / editar no empezado / plantillas / Play: sin «Añadir lugar».
            if isEditingCompletedWorkout && !completedHasRecordedRoute {
                Section {
                    editorCompletedPlaceRow
                } header: {
                    Text("Lugar")
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
                                    if nonRestItemCount(in: block) > 1 {
                                        blockDeleteConfirmID = block.id
                                    } else {
                                        routine.blocks.removeAll { $0.id == block.id }
                                    }
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
                        WorkoutStructureEditorView(block: $routine.blocks[index])
                        Divider()
                            .overlay(OG.label3.opacity(0.25))
                            .padding(.vertical, 5)
                        completedScoreEditor(for: block)
                    }
                    .listRowSeparator(.hidden)
                    if block.kind == .strength {
                        // Misma retícula que Crear (añadir/editar series). El score de
                        // formato WOD vive en completedScoreEditor de la cabecera;
                        // no sustituir el editor de series por solo «reps/kg reales».
                        strengthBlock(index: index)
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
                        .foregroundStyle(OG.label)
                }
                Button {
                    showWODCatalog = true
                } label: {
                    Label("Elegir WOD", systemImage: "list.bullet.rectangle.portrait")
                        .foregroundStyle(OG.label)
                }
                if !importableRoutines.isEmpty || !store.state.favoriteTimers.isEmpty {
                    Button {
                        showRoutinePicker = true
                    } label: {
                        Label("Añadir favorito", systemImage: "star")
                        .foregroundStyle(OG.label)
                    }
                }
                Button {
                    showBoardScanner = true
                } label: {
                    Label("Escanear pizarra", systemImage: "camera.viewfinder")
                        .foregroundStyle(OG.label)
                }
            }
        }
        .listStyle(.insetGrouped)
        .ogListChrome()
        .toolbar(.hidden, for: .tabBar)
        // Un solo Volver: siempre custom (dirty → Descartar; limpio → cerrar).
        // Si se deja el nativo + chevron propio, iOS 26 Liquid Glass muestra dos.
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    if isEditorDirty {
                        showDiscardConfirm = true
                    } else if let onClose {
                        onClose()
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "chevron.backward")
                        .fontWeight(.semibold)
                }
                .accessibilityLabel("Volver")
            }
        }
        .ogDiscardChangesConfirm(isPresented: $showDiscardConfirm, onDiscard: discardEditorChanges)
        .ogUndoToast($undoToast)
        .confirmationDialog(
            "¿Eliminar este bloque?",
            isPresented: Binding(
                get: { blockDeleteConfirmID != nil },
                set: { if !$0 { blockDeleteConfirmID = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Eliminar bloque", role: .destructive) {
                if let id = blockDeleteConfirmID {
                    routine.blocks.removeAll { $0.id == id }
                }
                blockDeleteConfirmID = nil
            }
            Button("Cancelar", role: .cancel) {
                blockDeleteConfirmID = nil
            }
        } message: {
            Text("Se eliminarán todos los ejercicios del bloque.")
        }
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
            refreshExercisesByIdIfNeeded()
            ensureCompletedWorkoutDraft()
            ensureStrengthPlannedSets()
        }
        .onChange(of: store.state.exercises.count) { _, _ in
            refreshExercisesByIdIfNeeded()
        }
        .task(id: completedSession?.id) {
            await hydrateCompletedWorkoutPlace()
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
            onBack: onClose,
            hideNativeBack: true
        ))
        // Pickers de creación: push nativo horizontal con volver en topbar.
        .navigationDestination(item: $pickExerciseForBlock) { blockID in
            ExercisePickerView(
                embedsNavigationStack: false,
                allowsMultipleSelection: true
            ) { exercises in
                if let idx = routine.blocks.firstIndex(where: { $0.id == blockID }) {
                    var lastEntryID: UUID?
                    for exercise in exercises {
                        let style = exercise.loggingStyle
                        let amount = style == .machineWork
                            ? (exercise.defaultQuantityUnit == .meters ? 500 : 15)
                            : (exercise.isMobility ? (exercise.isMobilityHold ? 1 : 8) : (style == .repsAndTime ? 50 : 8))
                        let count = style.usesDuration ? 1 : 3
                        let sets = (0..<count).map { _ in
                            PlannedSet(targetReps: amount, targetWeightKg: nil,
                                targetDurationSeconds: exercise.isMobility ? (exercise.isMobilityHold ? 30 : 60) : nil)
                        }
                        let entry = RoutineExercise(
                            exerciseId: exercise.id,
                            plannedSets: sets,
                            quantityUnit: style == .machineWork || exercise.supportsRepsOrMeters
                                ? exercise.defaultQuantityUnit : nil
                        )
                        routine.blocks[idx].exercises.append(entry)
                        lastEntryID = entry.id
                    }
                    expandedEntryID = lastEntryID
                }
                pickExerciseForBlock = nil
            }
        }
        .navigationDestination(item: $pickMovementForBlock) { blockID in
            ExercisePickerView(embedsNavigationStack: false) { exercise in
                if let idx = routine.blocks.firstIndex(where: { $0.id == blockID }) {
                    let movement = WODMovement(exerciseId: exercise.id, name: exercise.name, reps: 10)
                    routine.blocks[idx].movements.append(movement)
                    expandedEntryID = movement.id
                }
                pickMovementForBlock = nil
            }
        }
        .navigationDestination(item: $createFreeMovementForBlock) { blockID in
            FreeWODMovementCreatePage { movement in
                if let idx = routine.blocks.firstIndex(where: { $0.id == blockID }) {
                    if routine.blocks[idx].kind == .wod {
                        routine.blocks[idx].movements.append(movement)
                    } else {
                        routine.blocks.insert(
                            RoutineBlock(title: movement.name, kind: .wod, movements: [movement]),
                            at: idx + 1
                        )
                    }
                }
                createFreeMovementForBlock = nil
            }
        }
        .sheet(isPresented: $showBoardScanner) {
            BoardScanIntoRoutineView { imported in
                routine.blocks.append(contentsOf: imported)
            }
        }
        .sheet(isPresented: $showRoutinePicker) {
            RoutineImportPickerSheet(
                routines: importableRoutines,
                timers: store.state.favoriteTimers,
                onPick: { source in
                    routine.blocks.append(contentsOf: source.blocks.map { $0.duplicatingContent() })
                    showRoutinePicker = false
                },
                onPickTimer: { timer in
                    routine.blocks.append(timer.asWorkoutBlock())
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

    /// SwiftUI nativo: el usuario arrastra la cabecera del bloque o una fila
    /// de ejercicio. Los IDs/colecciones permiten mover entre bloques sin
    /// mezclar un bloque completo con los ejercicios de otro.
    /// Drag & drop estable de SwiftUI: las zonas son vistas reales, sin
    /// reorderContainer beta (crash de identificadores en algunas jerarquías).
    /// No se cambia el aspecto de las tarjetas.
    private var reorderSheet: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(routine.blocks.enumerated()), id: \.element.id) { position, block in
                    OGReorderInsertionGap(
                        draggedToken: $reorderDraggedToken,
                        accepts: { $0.hasPrefix("block:") }
                    ) { token in
                        OGMotion.run(OGMotion.reorder, reduceMotion: reduceMotion) { reorderBlockToken(token, before: block.id) }
                    }
                    reorderBlockBox(position: position, block: block)
                }
                OGReorderInsertionGap(
                    draggedToken: $reorderDraggedToken,
                    accepts: { $0.hasPrefix("block:") }
                ) { token in
                    OGMotion.run(OGMotion.reorder, reduceMotion: reduceMotion) { reorderBlockToken(token, before: nil) }
                }
            }
            .padding(.horizontal, OG.pad)
            .padding(.vertical, 12)
        }
        .background(OG.bg.ignoresSafeArea())
        .navigationTitle("Reordenar")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { reorderDraggedToken = nil }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                OGDoneCheckButton { showsReorder = false }
            }
        }
    }

    /// Caja única estilo card de bloque: mismos textos, filas y esquinas.
    /// Las filas reciben drops en toda su altura; la mitad inferior inserta
    /// después de la fila, la superior antes. Una caja vacía tiene 104 pt.
    private func reorderBlockBox(position: Int, block: RoutineBlock) -> some View {
        let rows = reorderRows(for: block)
        return VStack(alignment: .leading, spacing: 0) {
            reorderBlockHeader(position: position, block: block)
                .contentShape(Rectangle())
                .onDrag {
                    let token = "block:\(block.id.uuidString)"
                    reorderDraggedToken = token
                    return NSItemProvider(object: token as NSString)
                } preview: {
                    OGReorderDragPreview {
                        reorderBlockHeader(position: position, block: block)
                    }
                }
                .onDrop(
                    of: [UTType.plainText],
                    delegate: OGReorderDropDelegate(
                        draggedToken: $reorderDraggedToken,
                        accepts: { $0.hasPrefix("block:") },
                        performMove: { token, _ in
                            let before = blockDropBeforeID(
                                token: token, targetPosition: position, targetID: block.id
                            )
                            var changed = false
                            OGMotion.run(OGMotion.reorder, reduceMotion: reduceMotion) { changed = reorderBlockToken(token, before: before) }
                            return changed
                        }
                    )
                )

            if rows.isEmpty {
                Text("Soltar ejercicio")
                    .font(.caption)
                    .foregroundStyle(OG.label3)
                    .frame(maxWidth: .infinity, minHeight: 104)
                    .contentShape(Rectangle())
                    .onDrop(
                        of: [UTType.plainText],
                        delegate: OGReorderDropDelegate(
                            draggedToken: $reorderDraggedToken,
                            accepts: { _ in true },
                            performMove: { token, _ in
                                if token.hasPrefix("block:") {
                                    let before = blockDropBeforeID(
                                        token: token, targetPosition: position, targetID: block.id
                                    )
                                    var movedBlock = false
                                    OGMotion.run(OGMotion.reorder, reduceMotion: reduceMotion) {
                                        movedBlock = reorderBlockToken(token, before: before)
                                    }
                                    return movedBlock
                                }
                                var changed = false
                                OGMotion.run(OGMotion.reorder, reduceMotion: reduceMotion) {
                                    changed = applyReorder(token, into: block.id, before: nil)
                                }
                                return changed
                            }
                        )
                    )
                    .padding(.bottom, 8)
            } else {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    Divider()
                        .overlay(OG.label3.opacity(0.22))
                        .padding(.leading, 14)
                    reorderExerciseRow(
                        row.name, blockID: block.id, itemID: row.id, type: row.type
                    )
                    .onDrop(
                        of: [UTType.plainText],
                        delegate: OGReorderDropDelegate(
                            draggedToken: $reorderDraggedToken,
                            accepts: { _ in true },
                            performMove: { token, location in
                                if token.hasPrefix("block:") {
                                    let before = blockDropBeforeID(
                                        token: token, targetPosition: position, targetID: block.id
                                    )
                                    var movedBlock = false
                                    OGMotion.run(OGMotion.reorder, reduceMotion: reduceMotion) {
                                        movedBlock = reorderBlockToken(token, before: before)
                                    }
                                    return movedBlock
                                }
                                // Mitad superior: antes. Mitad inferior: después.
                                let before = location.y > 28 ? rows.dropFirst(index + 1).first?.id : row.id
                                var changed = false
                                OGMotion.run(OGMotion.reorder, reduceMotion: reduceMotion) {
                                    changed = applyReorder(token, into: block.id, before: before)
                                }
                                return changed
                            }
                        )
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous)
                .stroke(OG.surface3.opacity(0.75), lineWidth: 0.7)
        )
    }

    private func reorderBlockHeader(position: Int, block: RoutineBlock) -> some View {
        HStack(spacing: 12) {
            Text("\(position + 1)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(OG.accent)
                .frame(width: 34, height: 34)
                .background(OG.accent.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(block.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(OG.label)
                Text(block.wodFormat?.displayName ?? "Sin formato")
                    .font(.caption)
                    .foregroundStyle(OG.label2)
            }
            Spacer(minLength: 8)
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(OG.label3)
                .accessibilityLabel("Arrastrar bloque \(block.title)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func reorderRows(for block: RoutineBlock) -> [OGReorderEntry] {
        if block.kind == .strength {
            return block.exercises.map { item in
                let raw = store.state.exercises.first(where: { $0.id == item.exerciseId })?.name ?? "Ejercicio"
                return OGReorderEntry(
                    id: item.id,
                    name: raw,
                    type: "exercise"
                )
            }
        }
        return block.movements.map {
            OGReorderEntry(
                id: $0.id,
                name: $0.isRest ? "Descanso" : store.catalogTitle(for: $0),
                type: "movement"
            )
        }
    }

    @ViewBuilder
    private func reorderExerciseThumb(blockID: UUID, itemID: UUID, type: String) -> some View {
        if let block = routine.blocks.first(where: { $0.id == blockID }) {
            if type == "exercise",
               let item = block.exercises.first(where: { $0.id == itemID }),
               let exercise = store.state.exercises.first(where: { $0.id == item.exerciseId }) {
                ExerciseThumb(exercise: exercise, size: 32)
            } else if type == "movement",
                      let movement = block.movements.first(where: { $0.id == itemID }) {
                if movement.isRest {
                    Image(systemName: "pause.circle")
                        .foregroundStyle(OG.label3)
                        .frame(width: 32, height: 32)
                        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 9))
                } else if let id = movement.exerciseId,
                          let exercise = store.state.exercises.first(where: { $0.id == id }) {
                    ExerciseThumb(exercise: exercise, size: 32)
                } else {
                    ExerciseThumb(name: movement.name, size: 32)
                }
            } else {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(OG.label3)
                    .frame(width: 32, height: 32)
                    .background(OG.surface2, in: RoundedRectangle(cornerRadius: 9))
            }
        }
    }

    private func reorderExerciseRow(_ name: String, blockID: UUID, itemID: UUID, type: String) -> some View {
        let dragToken = "\(type):\(blockID.uuidString):\(itemID.uuidString)"
        return HStack(spacing: 12) {
            reorderExerciseThumb(blockID: blockID, itemID: itemID, type: type)
            Text(name)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(OG.label)
            Spacer(minLength: 8)
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(OG.label3)
                .accessibilityLabel("Arrastrar \(name)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onDrag {
            reorderDraggedToken = dragToken
            return NSItemProvider(object: dragToken as NSString)
        } preview: {
            OGReorderDragPreview(cornerRadius: 12) {
                HStack(spacing: 12) {
                    reorderExerciseThumb(blockID: blockID, itemID: itemID, type: type)
                    Text(name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(OG.label)
                    Spacer(minLength: 8)
                    Image(systemName: "line.3.horizontal")
                        .foregroundStyle(OG.label3)
                }
                .padding(12)
            }
        }
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

    private func nonRestItemCount(in block: RoutineBlock) -> Int {
        if block.kind == .strength {
            return block.exercises.count
        }
        return block.movements.filter { !$0.isRest }.count
    }

    private func deleteReorderExercise(type: String, blockID: UUID, itemID: UUID) {
        guard let index = routine.blocks.firstIndex(where: { $0.id == blockID }) else { return }
        if type == "exercise" {
            guard let exIndex = routine.blocks[index].exercises.firstIndex(where: { $0.id == itemID }) else { return }
            let removed = routine.blocks[index].exercises[exIndex]
            let insertAt = exIndex
            OGMotion.run(OGMotion.reorder, reduceMotion: reduceMotion) {
                routine.blocks[index].exercises.remove(at: exIndex)
            }
            presentUndoToast(message: "Ejercicio eliminado") {
                guard routine.blocks.indices.contains(index) else { return }
                let at = min(insertAt, routine.blocks[index].exercises.count)
                routine.blocks[index].exercises.insert(removed, at: at)
            }
        } else if type == "movement" {
            guard let mvIndex = routine.blocks[index].movements.firstIndex(where: { $0.id == itemID }) else { return }
            let removed = routine.blocks[index].movements[mvIndex]
            let insertAt = mvIndex
            OGMotion.run(OGMotion.reorder, reduceMotion: reduceMotion) {
                routine.blocks[index].movements.remove(at: mvIndex)
            }
            presentUndoToast(message: "Ejercicio eliminado") {
                guard routine.blocks.indices.contains(index) else { return }
                let at = min(insertAt, routine.blocks[index].movements.count)
                routine.blocks[index].movements.insert(removed, at: at)
            }
        }
    }

    /// Destino al soltar un bloque sobre otra caja: hacia abajo → después del
    /// objetivo; hacia arriba → antes. Evita el no-op de «before: target» cuando
    /// el bloque 1 ya está delante del 2.
    private func blockDropBeforeID(token: String, targetPosition: Int, targetID: UUID) -> UUID? {
        let parts = token.split(separator: ":")
        guard parts.count == 2,
              parts[0] == "block",
              let sourceID = UUID(uuidString: String(parts[1])),
              let sourceIndex = routine.blocks.firstIndex(where: { $0.id == sourceID })
        else { return targetID }
        if sourceIndex < targetPosition {
            return routine.blocks.dropFirst(targetPosition + 1).first?.id
        }
        if sourceIndex > targetPosition {
            return targetID
        }
        return sourceID
    }

    private func reorderBlockToken(_ token: String, before destinationID: UUID?) -> Bool {
        let parts = token.split(separator: ":")
        guard parts.count == 2,
              parts[0] == "block",
              let sourceID = UUID(uuidString: String(parts[1])),
              let source = routine.blocks.firstIndex(where: { $0.id == sourceID })
        else { return false }
        if destinationID == sourceID { return false }
        let originalOrder = routine.blocks.map(\.id)
        let moved = routine.blocks.remove(at: source)
        let destination = destinationID.flatMap { id in
            routine.blocks.firstIndex(where: { $0.id == id })
        } ?? routine.blocks.count
        routine.blocks.insert(moved, at: destination)
        return routine.blocks.map(\.id) != originalOrder
    }

    private func moveExercise(type: String, blockID: UUID, itemID: UUID, offset: Int) {
        guard let blockIndex = routine.blocks.firstIndex(where: { $0.id == blockID }) else { return }
        if type == "exercise" {
            guard let old = routine.blocks[blockIndex].exercises.firstIndex(where: { $0.id == itemID }),
                  routine.blocks[blockIndex].exercises.indices.contains(old + offset) else { return }
            OGMotion.run(OGMotion.reorder, reduceMotion: reduceMotion) {
                let item = routine.blocks[blockIndex].exercises.remove(at: old)
                routine.blocks[blockIndex].exercises.insert(item, at: old + offset)
            }
        } else if type == "movement" {
            guard let old = routine.blocks[blockIndex].movements.firstIndex(where: { $0.id == itemID }),
                  routine.blocks[blockIndex].movements.indices.contains(old + offset) else { return }
            OGMotion.run(OGMotion.reorder, reduceMotion: reduceMotion) {
                let item = routine.blocks[blockIndex].movements.remove(at: old)
                routine.blocks[blockIndex].movements.insert(item, at: old + offset)
            }
        }
    }

    private func moveBlock(_ id: UUID, offset: Int) {
        guard let old = routine.blocks.firstIndex(where: { $0.id == id }),
              routine.blocks.indices.contains(old + offset) else { return }
        OGMotion.run(OGMotion.reorder, reduceMotion: reduceMotion) {
            routine.blocks.move(
                fromOffsets: IndexSet(integer: old),
                toOffset: old + offset + (offset > 0 ? 1 : 0)
            )
        }
    }

    private func applyReorder(_ token: String, into destinationID: UUID, before itemID: UUID?) -> Bool {
        let parts = token.split(separator: ":").map(String.init)
        guard let targetIndex = routine.blocks.firstIndex(where: { $0.id == destinationID }) else { return false }
        if parts.count == 2, parts[0] == "block" {
            return reorderBlockToken(token, before: destinationID)
        }
        guard parts.count == 3,
              let sourceBlockID = UUID(uuidString: parts[1]),
              let exerciseID = UUID(uuidString: parts[2]),
              let sourceIndex = routine.blocks.firstIndex(where: { $0.id == sourceBlockID })
        else { return false }
        // Soltar una fila en su propio hueco anterior no cambia el orden.
        if sourceBlockID == destinationID && itemID == exerciseID { return false }
        let source = routine.blocks[sourceIndex]
        let targetKind = routine.blocks[targetIndex].kind
        if parts[0] == "exercise" {
            guard let item = source.exercises.first(where: { $0.id == exerciseID }) else { return false }
            let targetMovement: WODMovement?
            if targetKind == .wod {
                let name = store.state.exercises.first(where: { $0.id == item.exerciseId })?.name ?? "Ejercicio"
                targetMovement = WODMovement(
                    id: item.id,
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
            guard let move = source.movements.first(where: { $0.id == exerciseID }) else { return false }
            var targetExercise: RoutineExercise?
            if targetKind == .strength {
                guard !move.isRest else { return false }
                var catalogID = move.exerciseId.flatMap { id in
                    store.state.exercises.contains(where: { $0.id == id }) ? id : nil
                } ?? store.state.exercises.first(where: {
                    $0.name.localizedCaseInsensitiveCompare(move.name) == .orderedSame
                })?.id
                if catalogID == nil {
                    guard store.addCustomExercise(name: move.name, muscleGroup: "Otros", equipment: nil) else { return false }
                    catalogID = store.state.exercises.last(where: {
                        $0.name.localizedCaseInsensitiveCompare(move.name) == .orderedSame
                    })?.id
                }
                guard let resolvedID = catalogID else { return false }
                targetExercise = RoutineExercise(
                    id: move.id,
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
        } else {
            return false
        }
        return true
    }

    /// Nombre por defecto al añadir bloque: «Bloque 1», «Bloque 2», …
    private func nextDefaultBlockTitle() -> String {
        "Bloque \(routine.blocks.count + 1)"
    }

    private var importableRoutines: [Routine] {
        store.favoriteRoutines.filter {
            $0.id != routine.id && !$0.blocks.isEmpty
        }
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

    @ViewBuilder
    private var editorCompletedPlaceRow: some View {
        let hasPlace = completedWorkoutDraft?.locationPin != nil
        WorkoutPlacePickerRow(
            pin: Binding(
                get: { completedWorkoutDraft?.locationPin },
                set: { newValue in
                    completedPlaceEdited = true
                    ensureCompletedWorkoutDraft()
                    completedDetails?.locationPin = newValue
                }
            ),
            showsExistingAnonymousPin: true
        )
        .listRowInsets(
            hasPlace
            ? EdgeInsets()
            : EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        )
        .listRowBackground(hasPlace ? Color.clear : OG.surface)
    }

    /// Usa la posición guardada durante el entrenamiento, nunca el GPS actual
    /// al abrir un histórico: editar un entreno antiguo no debe reubicarlo.
    private func hydrateCompletedWorkoutPlace() async {
        guard isEditingCompletedWorkout, !completedHasRecordedRoute,
              let session = completedSession else { return }
        let stored = store.state.workouts.first(where: { $0.id == session.id }) ?? session
        guard !completedPlaceEdited, !completedHasRecordedRoute,
              completedWorkoutDraft?.locationPin?.hasChosenPlace != true else { return }

        // El guardado del fin de sesión puede completar el pin mientras se
        // abre este editor; recuperar el más reciente sin tocar otros campos.
        if let savedPin = stored.locationPin {
            ensureCompletedWorkoutDraft()
            if completedDetails?.locationPin?.hasChosenPlace != true {
                completedDetails?.locationPin = savedPin
            }
        }
        let pin = completedWorkoutDraft?.locationPin ?? stored.locationPin
        // Sin coordenadas del entrenamiento NO usar la localización presente:
        // podría tratarse de un entreno de hace meses.
        guard pin != nil || !stored.routePoints.isEmpty else { return }
        let sport = stored.liveSportID.flatMap(LiveSport.init(rawValue:))
            ?? (stored.routineBlocks?.contains(where: { $0.kind == .wod }) == true
                ? .crossfit : .strength)
        let suggested = await SportNearbyPlaceSuggester.suggestForSession(
            sport: sport,
            routePoints: stored.routePoints,
            existingPin: pin
        )
        guard !Task.isCancelled, !completedPlaceEdited, !completedHasRecordedRoute,
              completedWorkoutDraft?.locationPin?.hasChosenPlace != true,
              let suggested else { return }
        ensureCompletedWorkoutDraft()
        completedDetails?.locationPin = suggested
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
        // Un deporte registrado (caminata, carrera, etc.) no necesita bloques
        // de ejercicios para editar su fecha, duración o notas.
        if onApplyCompleted != nil {
            return completedWorkoutDraft != nil
                && !routine.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        if onApplyDraft != nil {
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
            customExercises: store.customExerciseCount,
            favorites: store.favoriteCount
        )
        store.featureAccess = { [subscriptions] in subscriptions.policy }
        if let onApplyCompleted, let completedDetails = completedWorkoutDraft {
            var edited = routine
            for index in edited.blocks.indices { edited.blocks[index].deriveEmomRoundsIfNeeded() }
            if edited.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                edited.title = "Entreno"
            }
            var detailsToSave = completedDetails
            if completedHasRecordedRoute {
                // Protección adicional: ni un borrador antiguo ni una selección
                // tardía pueden cambiar la localización de una ruta GPS.
                detailsToSave.locationPin = store.state.workouts.first(where: {
                    $0.id == completedDetails.id
                })?.locationPin ?? completedSession?.locationPin
            }
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
                    isFavorite: true,
                    locationPin: detailsToSave.locationPin
                )
                guard await saveRoutineWithVerifiedAccess(favorite) else { return }
                detailsToSave.favoriteRoutineId = favorite.id
            }
            onApplyCompleted(edited, detailsToSave, recordNewSetsAsPerformed)
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
                if isEnd {
                    completedDetails?.finishedAt = date
                    completedDetails?.userEditedDuration = true
                } else {
                    let previousStart = completedDetails?.startedAt
                    let previousEnd = completedDetails?.finishedAt
                    let preservedSeconds: TimeInterval = {
                        guard let previousStart, let previousEnd else { return 60 * 45 }
                        return max(60, previousEnd.timeIntervalSince(previousStart))
                    }()
                    completedDetails?.startedAt = date
                    completedDetails?.finishedAt = date.addingTimeInterval(preservedSeconds)
                    // Cambiar solamente la hora de inicio también modifica
                    // qué muestras de Salud corresponden al entrenamiento.
                    completedDetails?.userEditedDuration = true
                }
            }
        )
    }

    private var completedDurationMinutes: Int {
        let start = completedDetails?.startedAt ?? Date()
        let end = completedDetails?.finishedAt ?? start.addingTimeInterval(45 * 60)
        return max(1, Int(round(end.timeIntervalSince(start) / 60)))
    }

    private var completedDurationMinutesBinding: Binding<Int> {
        Binding(
            get: { completedDurationMinutes },
            set: { minutes in
                ensureCompletedWorkoutDraft()
                let start = completedDetails?.startedAt ?? Date()
                completedDetails?.startedAt = start
                completedDetails?.finishedAt = start.addingTimeInterval(TimeInterval(max(1, minutes) * 60))
                completedDetails?.userEditedDuration = true
            }
        )
    }

    /// One-off: fecha y hora en controles separados (misma fila).
    private var oneOffDateTimeBinding: Binding<Date> {
        Binding(
            get: {
                routine.scheduledDateTime(on: routine.scheduledDate ?? Date())
                    ?? Calendar.current.date(
                        bySettingHour: 18, minute: 0, second: 0,
                        of: routine.scheduledDate ?? Date()
                    )
                    ?? Date()
            },
            set: { date in
                routine.scheduledDate = Calendar.current.startOfDay(for: date)
                routine.setScheduledTime(from: date)
            }
        )
    }

    @ViewBuilder
    private var oneOffDateTimeDurationRow: some View {
        dateTimeDurationRow(
            date: oneOffDateTimeBinding,
            durationDisplay: "\(routine.plannedDurationMinutes ?? 45) min",
            onDurationMinus: {
                routine.plannedDurationMinutes = max(1, (routine.plannedDurationMinutes ?? 45) - 5)
            },
            onDurationPlus: {
                routine.plannedDurationMinutes = min(600, (routine.plannedDurationMinutes ?? 45) + 5)
            },
            onDurationCommit: { text in
                let digits = text.filter(\.isNumber)
                if let v = Int(digits) {
                    routine.plannedDurationMinutes = min(600, max(1, v))
                }
            }
        )
    }

    @ViewBuilder
    private var completedDateTimeDurationRow: some View {
        dateTimeDurationRow(
            date: completedDateBinding(isEnd: false),
            durationDisplay: "\(completedDurationMinutes) min",
            onDurationMinus: {
                completedDurationMinutesBinding.wrappedValue =
                    max(1, completedDurationMinutes - 1)
            },
            onDurationPlus: {
                completedDurationMinutesBinding.wrappedValue =
                    min(600, completedDurationMinutes + 1)
            },
            onDurationCommit: { text in
                let digits = text.filter(\.isNumber)
                if let v = Int(digits) {
                    completedDurationMinutesBinding.wrappedValue = min(600, max(1, v))
                }
            }
        )
    }

    /// Fecha / Hora / Duración en un único cuadro surface2 (como inputs de
    /// ejercicio); tap → picker de fecha, hora o teclado numérico.
    private func dateTimeDurationRow(
        date: Binding<Date>,
        durationDisplay: String,
        onDurationMinus: @escaping () -> Void,
        onDurationPlus: @escaping () -> Void,
        onDurationCommit: @escaping (String) -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: 0) {
            MetaDateTimeCell(
                caption: "Fecha",
                text: Self.metaDayFormatter.string(from: date.wrappedValue),
                components: .date,
                date: date
            )
            .layoutPriority(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            metaCellDivider
            MetaDateTimeCell(
                caption: "Hora",
                text: Self.metaTimeFormatter.string(from: date.wrappedValue),
                components: .hourAndMinute,
                date: date
            )
            .frame(width: 76, alignment: .leading)
            metaCellDivider
            MetaDurationCell(
                caption: "Duración",
                display: durationDisplay,
                onCommitText: onDurationCommit
            )
        }
        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        // API de steppers conservada por call sites; el campo usa teclado.
        .onAppear { _ = onDurationMinus; _ = onDurationPlus }
        .accessibilityElement(children: .contain)
        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
    }

    private var metaCellDivider: some View {
        Rectangle()
            .fill(OG.surface3.opacity(0.85))
            .frame(width: 1)
            .padding(.vertical, 10)
    }

    private static let metaDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "dd/MM/yyyy"
        return f
    }()

    private static let metaTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "HH:mm"
        return f
    }()
}

/// Celda dentro del cuadro único: caption + valor; tap abre DatePicker.
private struct MetaDateTimeCell: View {
    var caption: String
    var text: String
    var components: DatePickerComponents
    @Binding var date: Date
    @State private var open = false

    var body: some View {
        Button { open = true } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(OG.label2)
                Text(text)
                    .font(.system(size: 16, weight: .semibold).monospacedDigit())
                    .foregroundStyle(OG.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $open) {
            NavigationStack {
                Group {
                    if components == .date {
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                    } else {
                        DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                    }
                }
                .labelsHidden()
                .tint(OG.accent)
                .padding()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Listo") { open = false }
                    }
                }
                .navigationTitle(components == .date ? "Fecha" : "Hora")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents(components == .date ? [.medium, .large] : [.height(280)])
            .ogSheetCorners()
        }
    }
}

/// Celda de duración dentro del mismo cuadro; tap → teclado numérico Repera.
private struct MetaDurationCell: View {
    var caption: String
    var display: String
    var onCommitText: (String) -> Void
    @State private var editing = false
    @State private var draft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(caption)
                .font(.caption)
                .foregroundStyle(OG.label2)
            Group {
                if editing {
                    OGNumericTextField(
                        text: $draft,
                        allowsDecimal: false,
                        textAlignment: .left,
                        fontSize: 16,
                        autoFocus: true,
                        onFocusLost: { commit() },
                        onCommit: { commit() }
                    )
                    .onChange(of: draft) { _, value in
                        onCommitText(value.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                } else {
                    Text(display)
                        .font(.system(size: 16, weight: .semibold).monospacedDigit())
                        .foregroundStyle(OG.label)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            draft = display.filter(\.isNumber)
                            editing = true
                        }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 22, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
    }

    private func commit() {
        onCommitText(draft.trimmingCharacters(in: .whitespacesAndNewlines))
        editing = false
    }
}

extension DayEditorView {
    /// No interpretar un estado Gratis antiguo como prueba de que Pro caducó.
    /// Consultar de nuevo las compras verificadas antes de bloquear una rutina.
    @discardableResult
    private func saveRoutineWithVerifiedAccess(_ candidate: Routine) async -> Bool {
        if store.saveRoutine(candidate) { return true }
        if store.lastAccessDenial != nil {
            await subscriptions.refreshEntitlementsForFeatureAction()
            subscriptions.syncCounts(
            libraryRoutines: store.libraryRoutineCount,
            customExercises: store.customExerciseCount,
            favorites: store.favoriteCount
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
            customExercises: store.customExerciseCount,
            favorites: store.favoriteCount
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
        let weightUnitLabel = store.state.settings.weightUnit.label.uppercased()
        let catalog = resolvedExerciseCatalog
        ForEach(Array(routine.blocks[index].exercises.enumerated()), id: \.element.id) { exIndex, item in
            if let ex = catalog[item.exerciseId]
                ?? completedDetails?.exercises.first(where: { $0.exercise.id == item.exerciseId })?.exercise {
                let isExpanded = expandedEntryID == item.id
                HStack(spacing: 4) {
                    Button {
                        if isExpanded {
                            exerciseDetailID = ex.id
                        } else {
                            expandedEntryID = item.id
                        }
                    } label: {
                        HStack(spacing: 12) {
                            ExerciseThumb(exercise: ex, size: 48)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ex.name)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(OG.label)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                if !isExpanded {
                                    Text(item.plannedSets.compactSummary)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(OG.label2)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(isExpanded ? "Ver ficha del ejercicio" : "Editar series")
                    exerciseOptions(blockID: routine.blocks[index].id, itemID: item.id, isWOD: false)
                }
                .listRowSeparator(.hidden, edges: .bottom)

                if isExpanded {
                    // Identidad sin IDs/conteo de series: si van en `.id`, «Añadir serie»
                    // remonta el isolator y parece que no añade. Los valores viven en `item`.
                    let previousTexts = previousSetTexts(for: ex.id, setCount: item.plannedSets.count)
                    let setsIdentity = StrengthExerciseSetsIdentity(
                        itemID: item.id,
                        exerciseID: ex.id,
                        loggingStyle: ex.loggingStyle,
                        quantityUnit: item.quantityUnit,
                        weightStep: weightStep,
                        weightUnitLabel: weightUnitLabel
                    )
                    StrengthExerciseSetsIsolator(
                        identity: setsIdentity,
                        item: item,
                        previousTexts: previousTexts,
                        exercise: ex,
                        openedSetID: $openedSetID,
                        quantityUnit: Binding(
                            get: { routine.blocks[index].exercises[exIndex].quantityUnit ?? ex.defaultQuantityUnit },
                            set: { routine.blocks[index].exercises[exIndex].quantityUnit = $0 }
                        ),
                        setBinding: { setIndex in
                            plannedSetBinding(blockIndex: index, exerciseIndex: exIndex, setIndex: setIndex)
                        },
                        onDeleteSet: { setIndex in
                            deleteStrengthSet(blockIndex: index, exerciseIndex: exIndex, setIndex: setIndex)
                        },
                        onAddSet: {
                            addStrengthSet(blockIndex: index, exerciseIndex: exIndex)
                        }
                    )
                    .id(setsIdentity)
                }
            }
        }
        WorkoutWODInsertActions(
            onExercise: { pickExerciseForBlock = routine.blocks[index].id },
            onRest: { insertRest(after: routine.blocks[index].id) },
            onFreeMovement: { beginFreeMovement(after: routine.blocks[index].id) }
        )
    }

    /// Fuerza no contiene movimientos REST: crear un bloque WOD a continuación
    /// conserva todos los ejercicios, series y resultados del bloque de fuerza.
    private func insertRest(after blockID: UUID) {
        guard let index = routine.blocks.firstIndex(where: { $0.id == blockID }) else { return }
        let rest = WODMovement(name: "REST", isRest: true, restSeconds: 60)
        if routine.blocks[index].kind == .wod {
            routine.blocks[index].movements.append(rest)
        } else {
            routine.blocks.insert(
                RoutineBlock(title: "Descanso", kind: .wod, movements: [rest]),
                at: index + 1
            )
        }
    }

    private func beginFreeMovement(after blockID: UUID) {
        guard routine.blocks.contains(where: { $0.id == blockID }) else { return }
        // No insertar un bloque vacío si se cancela el editor.
        createFreeMovementForBlock = blockID
    }

    /// Textos «Anterior» precargados una vez por ejercicio (no por fila de serie).
    private func previousSetTexts(for exerciseId: UUID, setCount: Int) -> [String?] {
        let sets = store.cachedLastWorkingSession(for: exerciseId)?.sets
        guard setCount > 0 else { return [] }
        return (0..<setCount).map { index in
            guard let sets, sets.indices.contains(index) else { return nil }
            return OGSetEntryRow.previousText(sets[index])
        }
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
        let removed = sets[setIndex]
        sets.remove(at: setIndex)
        routine.blocks[blockIndex].exercises[exerciseIndex].plannedSets = sets
        let message = "Serie \(setIndex + 1) eliminada"
        presentUndoToast(message: message) {
            guard routine.blocks.indices.contains(blockIndex),
                  routine.blocks[blockIndex].exercises.indices.contains(exerciseIndex) else { return }
            var restored = routine.blocks[blockIndex].exercises[exerciseIndex].plannedSets
            let insertAt = min(setIndex, restored.count)
            restored.insert(removed, at: insertAt)
            routine.blocks[blockIndex].exercises[exerciseIndex].plannedSets = restored
        }
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
        case duration, capSeconds, interval, rounds, work, rest, roundRest

        var title: String {
            switch self {
            case .duration: return "Tiempo"
            case .capSeconds: return "Segundos"
            case .interval: return "Intervalo"
            case .rounds: return "Rondas"
            case .work: return "Trabajo"
            case .rest: return "Descanso"
            // For Time: minutos + segundos del time cap (no «rondas» otra vez).
            case .roundRest: return "Entre rondas"
            }
        }

        var unit: String {
            switch self {
            case .duration: return "min"
            case .rounds: return ""
            case .interval, .work, .rest, .roundRest, .capSeconds: return "s"
            }
        }

        var range: ClosedRange<Int> {
            switch self {
            case .duration: return 1...120
            case .capSeconds: return 0...59
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
            return block.timeCapMinutes == nil ? [.rounds] : [.rounds, .duration, .capSeconds]
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
                case .capSeconds: return (block.timeCapSeconds ?? 0) % 60
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
                case .duration:
                    routine.blocks[blockIndex].timeCapMinutes = value
                    if let precise = routine.blocks[blockIndex].timeCapSeconds {
                        routine.blocks[blockIndex].timeCapSeconds = value * 60 + precise % 60
                    }
                case .capSeconds:
                    let minutes = routine.blocks[blockIndex].timeCapMinutes ?? 12
                    routine.blocks[blockIndex].timeCapSeconds = value == 0 ? nil : minutes * 60 + value
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
                if format == .forTime, routine.blocks[index].restBetweenRoundsSeconds != nil {
                    Stepper(
                        "Descanso entre rondas: \(routine.blocks[index].restBetweenRoundsSeconds ?? 0) s",
                        value: numberBinding(.roundRest, blockIndex: index),
                        in: 0...600, step: 15
                    )
                    .font(.subheadline)
                }
                if format == .partner {
                    Picker("Trabajo en equipo", selection: Binding<WorkoutCollaboration>(
                        get: { routine.blocks[index].structure?.collaboration ?? .youGoIGo },
                        set: { mode in
                            var structure = routine.blocks[index].structure ?? WorkoutStructure()
                            structure.collaboration = mode
                            routine.blocks[index].structure = structure
                        }
                    )) {
                        Text("Alternando").tag(WorkoutCollaboration.youGoIGo)
                        Text("Sincronizado").tag(WorkoutCollaboration.synchronized)
                        Text("Repeticiones compartidas").tag(WorkoutCollaboration.sharedReps)
                        Text("Juntos").tag(WorkoutCollaboration.together)
                    }
                    .pickerStyle(.menu)
                }
                if format == .maxEffort {
                    Picker("Medida del resultado", selection: Binding<WorkoutResultMetric>(
                        get: { routine.blocks[index].structure?.resultMetric ?? .totalReps },
                        set: { metric in
                            var structure = routine.blocks[index].structure ?? WorkoutStructure()
                            structure.resultMetric = metric
                            routine.blocks[index].structure = structure
                        }
                    )) {
                        Text("Repeticiones").tag(WorkoutResultMetric.totalReps)
                        Text("Carga (kg)").tag(WorkoutResultMetric.loadKg)
                        Text("Calorías").tag(WorkoutResultMetric.calories)
                        Text("Distancia (m)").tag(WorkoutResultMetric.distanceMeters)
                        Text("Tiempo").tag(WorkoutResultMetric.elapsedSeconds)
                    }
                    .pickerStyle(.menu)
                }
                if let structure = routine.blocks[index].structure,
                   !structure.summary.isEmpty {
                    Text(structure.summary)
                        .font(.caption)
                        .foregroundStyle(OG.label2)
                        .lineLimit(2)
                }
                if ![WODFormat.amrap, .emom, .tabata, .circuit].contains(format) {
                    Toggle("Límite de tiempo", isOn: Binding(
                        get: { routine.blocks[index].timeCapMinutes != nil },
                        set: { enabled in
                            routine.blocks[index].timeCapMinutes = enabled
                                ? (routine.blocks[index].timeCapMinutes ?? 12) : nil
                            if !enabled { routine.blocks[index].timeCapSeconds = nil }
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
                        Button {
                            exerciseDetailID = resolved.id
                        } label: {
                            ExerciseThumb(exercise: resolved, size: 48)
                        }
                        .buttonStyle(.plain)
                    } else {
                        ExerciseThumb(exercise: resolved, size: 48)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        if hasCatalog {
                            Button {
                                exerciseDetailID = resolved.id
                            } label: {
                                Text(resolved.name)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(OG.label)
                            }
                            .buttonStyle(.plain)
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
                            Button {
                                if expandedEntryID == move.id {
                                    exerciseDetailID = resolved.id
                                } else {
                                    expandedEntryID = move.id
                                }
                            } label: {
                                movementRowLabel(move: move, resolved: resolved, showSummary: false)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint(
                                expandedEntryID == move.id
                                    ? "Ver ficha del ejercicio" : "Editar series"
                            )
                        } else if move.isRest {
                            movementRowLabel(move: move, resolved: resolved, showSummary: false)
                        } else {
                            Button {
                                expandedEntryID = move.id
                            } label: {
                                movementRowLabel(move: move, resolved: resolved, showSummary: false)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Editar series")
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
            } else if expandedEntryID == move.id {
                InlineWODMovementSets(
                    movement: Binding(
                        get: { routine.blocks[index].movements[mIndex] },
                        set: { routine.blocks[index].movements[mIndex] = $0 }
                    ),
                    block: routine.blocks[index],
                    openedSetID: $openedSetID,
                    onUndoSetDelete: { message, undo in
                        presentUndoToast(message: message, undo: undo)
                    }
                )
                .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden, edges: .top)
            } else if !move.isRest {
                Button {
                    expandedEntryID = move.id
                } label: {
                    HStack {
                        Text(move.summaryLine)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(OG.label2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(OG.label3)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Editar series de \(move.name)")
                .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden, edges: .top)
            }
        }

        WorkoutWODInsertActions(
            onExercise: { pickMovementForBlock = routine.blocks[index].id },
            onRest: { insertRest(after: routine.blocks[index].id) },
            onFreeMovement: { beginFreeMovement(after: routine.blocks[index].id) }
        )

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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isRevealed: Bool { openedSetID == setID }
    @State private var activeDrag: CGFloat = 0
    private let revealWidth: CGFloat = 72

    var body: some View {
        ZStack(alignment: .trailing) {
            if canDelete && (isRevealed || activeDrag < -2) {
                Button {
                    OGMotion.run(OGMotion.appear, reduceMotion: reduceMotion) {
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

            // La fila completa tapa la papelera y se recorta dentro
            // de sus bordes: nunca debe asomar por el input RIR.
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(OG.surface, in: RoundedRectangle(cornerRadius: 12))
                .offset(x: canDelete ? max(-revealWidth, min(0,
                    (isRevealed ? -revealWidth : 0) + activeDrag
                )) : 0)
        }
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                    OGMotion.run(OGMotion.appear, reduceMotion: reduceMotion) {
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
    var onUndoSetDelete: ((String, @escaping () -> Void) -> Void)? = nil

    @State private var draftSets: [PlannedSet]
    @State private var didSeedSets: Bool
    @State private var previousTexts: [String?] = []
    @Binding var openedSetID: UUID?
    @FocusState private var focusedSetField: OGSetFieldID?

    init(
        movement: Binding<WODMovement>,
        block: RoutineBlock,
        preservePrescriptionOnAppear: Bool = false,
        openedSetID: Binding<UUID?>,
        onUndoSetDelete: ((String, @escaping () -> Void) -> Void)? = nil
    ) {
        _movement = movement
        self.block = block
        self.preservePrescriptionOnAppear = preservePrescriptionOnAppear
        self.onUndoSetDelete = onUndoSetDelete
        _openedSetID = openedSetID
        // Altura estable desde el 1.er frame (no sembrar en onAppear).
        let seeded = Self.initialDraftSets(movement: movement.wrappedValue, block: block)
        _draftSets = State(initialValue: seeded)
        _didSeedSets = State(initialValue: !movement.wrappedValue.isRest)
    }

    private static func initialDraftSets(movement: WODMovement, block: RoutineBlock) -> [PlannedSet] {
        guard !movement.isRest else { return [] }
        var sets = block.plannedSets(for: movement)
        if sets.isEmpty { sets = movement.plannedSetsFromReps }
        if sets.isEmpty {
            sets = [PlannedSet(targetReps: movement.reps ?? 10, targetWeightKg: movement.weightMaleKg)]
        }
        return sets
    }

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
                firstTitle: loggingStyle == .loadAndReps ? (resolvedLoadField == .deficitCm ? "Déficit" : store.state.settings.weightUnit.label.uppercased()) : (loggingStyle == .machineWork || isWeightedDistance ? movement.prescribedQuantityUnit.shortLabel : "Reps"),
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
            WorkoutInlineAddButton("Serie", systemImage: "plus.circle.fill") {
                addSet()
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            refreshPreviousTexts()
            if !preservePrescriptionOnAppear, didSeedSets {
                writeSetsToMovement()
            }
        }
        .onChange(of: movement.id) { _, _ in
            didSeedSets = false
            seedSetsIfNeeded()
        }
    }

    private func seedSetsIfNeeded() {
        guard !didSeedSets, !movement.isRest else { return }
        didSeedSets = true
        draftSets = Self.initialDraftSets(movement: movement, block: block)
        refreshPreviousTexts()
        if !preservePrescriptionOnAppear {
            writeSetsToMovement()
        }
    }

    private func refreshPreviousTexts() {
        let catalogName = CrossFitGlossary.resolveCatalogName(movement.name, notes: movement.notes)
        let catalogId = store.state.exercises.first {
            $0.name.localizedCaseInsensitiveCompare(catalogName) == .orderedSame
        }?.id
        let oldSets = catalogId.flatMap { store.cachedLastWorkingSession(for: $0)?.sets }
        previousTexts = draftSets.indices.map { index in
            guard let oldSets, oldSets.indices.contains(index) else { return nil }
            return OGSetEntryRow.previousText(oldSets[index])
        }
    }

    @ViewBuilder
    private func setRow(index: Int) -> some View {
        let style = loggingStyle
        let quantityCap = isWeightedDistance && movement.prescribedQuantityUnit == .meters
            ? 100_000 : style.quantityCap
        VStack(alignment: .leading, spacing: 6) {
            OGSetEntryRow(
                rowID: draftSets[index].id,
                index: index + 1,
                previous: previousTexts.indices.contains(index) ? previousTexts[index] : nil,
                firstValue: style == .loadAndReps
                    ? (draftSets[index].targetWeightKg.map {
                        ReperaNumberFormat.decimal(store.state.settings.weightUnit.displayValue(fromKilograms: $0))
                    } ?? "0")
                    : "\(draftSets[index].targetReps)",
                secondValue: style == .loadAndReps ? "\(draftSets[index].targetReps)" : nil,
                firstAllowsDecimal: style == .loadAndReps && resolvedLoadField == .weightKg,
                indexTappable: false,
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
                            let kg = store.state.settings.weightUnit.kilograms(fromDisplayValue: value)
                            draftSets[index].targetWeightKg = value > 0 ? ((kg * 10).rounded() / 10) : nil
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
        let removed = draftSets[index]
        draftSets.remove(at: index)
        writeSetsToMovement()
        onUndoSetDelete?("Serie \(index + 1) eliminada") { [removed] in
            let insertAt = min(index, draftSets.count)
            draftSets.insert(removed, at: insertAt)
            writeSetsToMovement()
        }
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
    @State private var undoToast: OGUndoToastState?
    @Environment(ReperaStore.self) private var store
    @Binding var movement: WODMovement
    /// Bloque padre para derivar las mismas series que Empezar/Apuntar.
    var block: RoutineBlock? = nil

    @State private var draftSets: [PlannedSet] = []
    @State private var didSeedSets = false
    @State private var previousTexts: [String?] = []
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
            Section {
                OGScrollablePageTitle("Movimiento WOD").ogScrollingTitleListRow()
            }
            .listSectionSpacing(0)
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
                        firstTitle: loggingStyle == .loadAndReps ? (resolvedLoadField == .deficitCm ? "Déficit" : store.state.settings.weightUnit.label.uppercased()) : (loggingStyle == .machineWork || isWeightedDistance ? movement.prescribedQuantityUnit.shortLabel : (loggingStyle == .repsAndTime ? "Veces" : "Reps")),
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
                    WorkoutInlineAddButton("Serie", systemImage: "plus.circle.fill") {
                        addSet()
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
                            Text("Walking lunge: repeticiones o metros, con peso opcional y \(store.state.settings.effortUnit.displayName).")
                        } else if resolvedLoadField == .deficitCm {
                            Text("HSPU: déficit (cm) · reps. 0 = sin déficit.")
                        } else {
                            Text("Peso/lastre · reps · \(store.state.settings.effortUnit.displayName). Dominadas: lastre 0 = sin lastre.")
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
        .ogUndoToast($undoToast)
        .onAppear {
            seedSetsIfNeeded()
            maleWeightDraft = movement.weightMaleKg.map { ReperaNumberFormat.decimal($0) } ?? ""
            femaleWeightDraft = movement.weightFemaleKg.map { ReperaNumberFormat.decimal($0) } ?? ""
        }
    }

    @MainActor
    private func presentUndoToast(message: String, undo: @escaping () -> Void) {
        let state = OGUndoToastState(message: message, undo: undo)
        undoToast = state
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            if undoToast?.id == state.id {
                undoToast = nil
            }
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
        let catalogName = CrossFitGlossary.resolveCatalogName(movement.name, notes: movement.notes)
        let catalogId = store.state.exercises.first {
            $0.name.localizedCaseInsensitiveCompare(catalogName) == .orderedSame
        }?.id
        let oldSets = catalogId.flatMap { store.cachedLastWorkingSession(for: $0)?.sets }
        previousTexts = draftSets.indices.map { index in
            guard let oldSets, oldSets.indices.contains(index) else { return nil }
            return OGSetEntryRow.previousText(oldSets[index])
        }
    }

    private func wodSetRow(index: Int) -> some View {
        let style = loggingStyle
        let quantityCap = isWeightedDistance && movement.prescribedQuantityUnit == .meters
            ? 100_000 : style.quantityCap
        return VStack(alignment: .leading, spacing: 6) {
            OGSetEntryRow(
                rowID: draftSets[index].id,
                index: index + 1,
                previous: previousTexts.indices.contains(index) ? previousTexts[index] : nil,
                firstValue: style == .loadAndReps
                    ? (draftSets[index].targetWeightKg.map {
                        ReperaNumberFormat.decimal(store.state.settings.weightUnit.displayValue(fromKilograms: $0))
                    } ?? "0")
                    : "\(draftSets[index].targetReps)",
                secondValue: style == .loadAndReps ? "\(draftSets[index].targetReps)" : nil,
                firstAllowsDecimal: style == .loadAndReps && resolvedLoadField == .weightKg,
                indexTappable: false,
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
                            let kg = store.state.settings.weightUnit.kilograms(fromDisplayValue: value)
                            draftSets[index].targetWeightKg = value > 0 ? ((kg * 10).rounded() / 10) : nil
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
        let removed = draftSets[index]
        draftSets.remove(at: index)
        writeSetsToMovement()
        presentUndoToast(message: "Serie \(index + 1) eliminada") {
            let insertAt = min(index, draftSets.count)
            draftSets.insert(removed, at: insertAt)
            writeSetsToMovement()
        }
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
    @State private var previousTexts: [String?] = []
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
            Section {
                OGScrollablePageTitle((exercise?.name ?? exerciseName))
                    .ogScrollingTitleListRow()
            }
            .listSectionSpacing(0)
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
                    Text("Aplicar escala la última sesión al kg sugerido (misma progresión, reps y \(store.state.settings.effortUnit.displayName)).")
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
                        ? (exercise?.loadField == .deficitCm ? "Déficit" : store.state.settings.weightUnit.label.uppercased())
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
                        previousText: previousTexts.indices.contains(index) ? previousTexts[index] : nil
                    )
                    }
                }

                WorkoutInlineAddButton("Serie", systemImage: "plus.circle.fill") {
                    addSet()
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            } header: {
                Text("Objetivo por serie")
            } footer: {
                Text(exercise?.isMobility == true
                     ? "Objetivo de duración por serie en segundos. Las posturas se registran por tiempo y la movilidad dinámica por repeticiones y tiempo; sin kg ni RIR."
                     : (exercise?.loggingStyle == .machineWork
                     ? "Introduce calorías o metros por serie; el cardio no utiliza kilogramos."
                     : "Cada serie puede tener cantidad, peso y \(store.state.settings.effortUnit.displayName) distintos según el movimiento."))
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
            let lastSets = store.cachedLastWorkingSession(for: exerciseId)?.sets
            previousTexts = item.plannedSets.indices.map { index in
                guard let lastSets, lastSets.indices.contains(index) else { return nil }
                return OGSetEntryRow.previousText(lastSets[index])
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

/// Identidad estructural (Sendable) para `.id` del isolator de series.
/// Solo ítem/ejercicio/unidad/estilo. **Sin** lista de series ni previousTexts:
/// añadir/borrar serie no debe remontar (si no, «Añadir serie» parece roto).
/// No poner `Equatable` en el `View`: en Swift 6 cruza con el aislamiento MainActor de View.
private struct StrengthExerciseSetsIdentity: Hashable {
    let itemID: UUID
    let exerciseID: UUID
    let loggingStyle: ExerciseLoggingStyle
    let quantityUnit: ExerciseQuantityUnit?
    let weightStep: Double
    let weightUnitLabel: String
}

/// Series de un ejercicio de fuerza; se remonta solo si cambia [StrengthExerciseSetsIdentity].
/// `item` / `previousTexts` aportan valores vivos; no forman parte del `.id`.
private struct StrengthExerciseSetsIsolator: View {
    let identity: StrengthExerciseSetsIdentity
    let item: RoutineExercise
    let previousTexts: [String?]
    let exercise: Exercise
    @Binding var openedSetID: UUID?
    var quantityUnit: Binding<ExerciseQuantityUnit>
    var setBinding: (Int) -> Binding<PlannedSet>
    var onDeleteSet: (Int) -> Void
    var onAddSet: () -> Void

    private var weightStep: Double { identity.weightStep }
    private var weightUnitLabel: String { identity.weightUnitLabel }

    var body: some View {
        let ex = exercise
        if ex.supportsRepsOrMeters
            || (ex.loggingStyle == .machineWork && ex.allowsCalorieOrDistanceToggle) {
            Picker("Unidad", selection: quantityUnit) {
                if ex.supportsRepsOrMeters {
                    Text("Repeticiones").tag(ExerciseQuantityUnit.reps)
                } else {
                    Text("Calorías").tag(ExerciseQuantityUnit.calories)
                }
                Text("Metros").tag(ExerciseQuantityUnit.meters)
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
        }

        OGSetEntryHeader(
            firstTitle: ex.isMobility ? "Tiempo (s)" : (ex.loggingStyle == .loadAndReps
                ? (ex.loadField == .deficitCm ? "Déficit" : weightUnitLabel)
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
        .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 4, trailing: 16))
        .listRowSeparator(.hidden, edges: .top)

        ForEach(Array(item.plannedSets.enumerated()), id: \.element.id) { setIndex, plannedSet in
            OGSetSwipeDeleteRow(
                canDelete: item.plannedSets.count > 1,
                setID: plannedSet.id,
                openedSetID: $openedSetID,
                onDelete: { onDeleteSet(setIndex) }
            ) {
                PlannedSetConfigRow(
                    index: setIndex + 1,
                    set: setBinding(setIndex),
                    weightStep: weightStep,
                    exerciseStyle: ex.loggingStyle,
                    quantityCap: ex.supportsRepsOrMeters && item.quantityUnit == .meters ? 100_000 : nil,
                    isMobility: ex.isMobility,
                    isMobilityHold: ex.isMobilityHold,
                    previousText: previousTexts.indices.contains(setIndex) ? previousTexts[setIndex] : nil
                )
            }
        }

        WorkoutInlineAddButton("Serie", systemImage: "plus.circle.fill", action: onAddSet)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }
}

/// Fila de objetivo: peso / reps / RIR. Borrar serie = swipe (sin icono de papelera).
private struct PlannedSetConfigRow: View {
    @Environment(ReperaStore.self) private var store
    var index: Int
    @Binding var set: PlannedSet
    var weightStep: Double
    var exerciseStyle: ExerciseLoggingStyle = .loadAndReps
    var quantityCap: Int? = nil
    var isMobility: Bool = false
    var isMobilityHold: Bool = false
    var previousText: String? = nil
    @FocusState private var focusedSetField: OGSetFieldID?

    var body: some View {
        OGSetEntryRow(
            rowID: set.id,
            index: index,
            previous: previousText,
            firstValue: isMobility ? "\(set.targetDurationSeconds ?? (isMobilityHold ? 30 : 60))"
                : (exerciseStyle == .loadAndReps
                ? (set.targetWeightKg.map { ReperaNumberFormat.decimal(store.state.settings.weightUnit.displayValue(fromKilograms: $0)) } ?? "0")
                : "\(set.targetReps)"),
            secondValue: isMobility
                ? (isMobilityHold ? nil : "\(set.targetReps)")
                : (exerciseStyle == .loadAndReps ? "\(set.targetReps)" : nil),
            firstAllowsDecimal: exerciseStyle == .loadAndReps,
            indexTappable: false,
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
                        let kg = store.state.settings.weightUnit.kilograms(fromDisplayValue: value)
                        set.targetWeightKg = value > 0 ? ((kg * 10).rounded() / 10) : nil
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
    var allowsMultipleSelection = false
    var onPick: ((Exercise) -> Void)? = nil
    var onPickMany: (([Exercise]) -> Void)? = nil

    init(
        embedsNavigationStack: Bool = true,
        allowsMultipleSelection: Bool = false,
        onPick: @escaping (Exercise) -> Void
    ) {
        self.embedsNavigationStack = embedsNavigationStack
        self.allowsMultipleSelection = allowsMultipleSelection
        self.onPick = onPick
        self.onPickMany = nil
    }

    init(
        embedsNavigationStack: Bool = true,
        allowsMultipleSelection: Bool = true,
        onPickMany: @escaping ([Exercise]) -> Void
    ) {
        self.embedsNavigationStack = embedsNavigationStack
        self.allowsMultipleSelection = allowsMultipleSelection
        self.onPick = nil
        self.onPickMany = onPickMany
    }

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
        Group {
            if allowsMultipleSelection {
                ExerciseCatalogSearchList(
                    exercises: store.state.exercises,
                    prompt: "Buscar ejercicio",
                    pageTitle: "Elegir ejercicio",
                    selectionMode: .multiple
                ) { picked in
                    onPickMany?(picked)
                    if embedsNavigationStack { dismiss() }
                }
            } else {
                ExerciseCatalogSearchList(
                    exercises: store.state.exercises,
                    prompt: "Buscar ejercicio",
                    pageTitle: "Elegir ejercicio"
                ) { exercise in
                    onPick?(exercise)
                    if embedsNavigationStack { dismiss() }
                }
            }
        }
        .ogScrollingTitleNav()
        .toolbar(.hidden, for: .tabBar)
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
            Section {
                OGScrollablePageTitle("Nuevo movimiento").ogScrollingTitleListRow()
            }
            .listSectionSpacing(0)
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
            // Título en sección propia: row suelto se absorbe y pisa el primer ítem;
            // con Section aparte + fondo claro, «Sin formato» conserva esquinas superiores.
            Section {
                OGScrollablePageTitle("Formato del bloque").ogScrollingTitleListRow()
            }
            .listSectionSpacing(0)
            Section {
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
        }
        .ogListChrome()
        .ogScrollingTitleNav()
    }
}

// MARK: - Importar bloques de otra rutina

struct RoutineImportPickerSheet: View {
    var routines: [Routine]
    var timers: [FavoriteTimer]
    var onPick: (Routine) -> Void
    var onPickTimer: (FavoriteTimer) -> Void
    var onCancel: () -> Void

    private var favoriteCount: Int { routines.count + timers.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            OGPageHeader(title: "Añadir favorito") {
                CloseToolbarButton(action: onCancel, large: true)
            }
            Group {
                if favoriteCount > 6 {
                    ScrollView { favoritesList }
                        .frame(maxHeight: 440)
                } else {
                    favoritesList
                }
            }
        }
        .padding(.horizontal, OG.pad)
        .padding(.top, 14)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        // El detent se mide con el contenido real; sin altura fija cuando
        // hay pocos favoritos y scroll solo para listas largas.
        .ogFittedHeight()
        .ogFittedSheet()
    }

    private var favoritesList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(routines.enumerated()), id: \.element.id) { index, source in
                if index > 0 {
                    Divider().padding(.leading, 58)
                }
                Button { onPick(source) } label: {
                    favoriteRow(
                        title: source.title,
                        subtitle: importSubtitle(source),
                        systemImage: "dumbbell"
                    )
                }
                .buttonStyle(.plain)
            }
            if !timers.isEmpty {
                if !routines.isEmpty { Divider() }
                Text("Temporizadores")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(OG.label2)
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                ForEach(Array(timers.enumerated()), id: \.element.id) { index, timer in
                    if index > 0 {
                        Divider().padding(.leading, 58)
                    }
                    Button { onPickTimer(timer) } label: {
                        favoriteRow(
                            title: timer.title,
                            subtitle: timer.modeRaw == "intervals" ? "\(timer.rounds) rondas" :
                                (timer.modeRaw == "up" ? "Cronómetro" :
                                    "Cuenta atrás · \(timer.durationMinutes)m \(timer.durationSeconds)s"),
                            systemImage: "timer"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }

    private func favoriteRow(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(OG.accent)
                .frame(width: 36, height: 36)
                .background(OG.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(OG.label)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(OG.label2)
            }
            Spacer(minLength: 8)
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(OG.accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func importSubtitle(_ routine: Routine) -> String {
        let strength = routine.blocks.filter { $0.kind == .strength }.flatMap(\.exercises).count
        let wods = routine.blocks.filter { $0.kind == .wod }.count
        var parts: [String] = []
        if strength > 0 { parts.append("\(strength) ej.") }
        if wods > 0 { parts.append("\(wods) WOD") }
        if parts.isEmpty { parts.append("\(routine.blocks.count) bloques") }
        return parts.joined(separator: " · ")
    }
}

/// Traslada la configuración de un temporizador favorito a un bloque WOD
/// manteniendo la duración real en segundos para intervalos y cuenta atrás.
extension FavoriteTimer {
    func asWorkoutBlock() -> RoutineBlock {
        let totalSeconds = max(1, durationMinutes * 60 + durationSeconds)
        let format: WODFormat
        let cap: Int?
        let roundsValue: Int?
        let work: Int?
        let rest: Int?
        switch modeRaw {
        case "intervals":
            format = .tabata
            cap = nil
            roundsValue = max(1, rounds)
            work = max(1, workMinutes * 60 + workSeconds)
            rest = max(0, restMinutes * 60 + restSeconds)
        case "up":
            format = .forTime
            cap = nil
            roundsValue = 1
            work = nil
            rest = nil
        default:
            format = .tabata
            cap = nil
            roundsValue = 1
            work = totalSeconds
            rest = 0
        }
        return RoutineBlock(
            title: title,
            kind: .wod,
            movements: [WODMovement(name: title, reps: 1)],
            wodFormat: format,
            timeCapMinutes: cap,
            rounds: roundsValue,
            workSeconds: work,
            restSeconds: rest,
            wodNotes: "Temporizador favorito · \(title)"
        )
    }
}

/// Línea de inserción real entre elementos, no sobre la fila arrastrable.
/// La altura táctil sigue siendo suficiente incluso con la línea en reposo.

/// Mismo tratamiento visual para las acciones de inserción de Crear/Editar y Play.
/// Acciones compactas: un botón principal y dos accesos secundarios.
struct WorkoutWODInsertActions: View {
    let onExercise: () -> Void
    let onRest: () -> Void
    let onFreeMovement: () -> Void

    var body: some View {
        VStack(spacing: 9) {
            WorkoutInlineAddButton("Ejercicio", systemImage: "plus.circle.fill", filled: true, action: onExercise)
            HStack(spacing: 9) {
                WorkoutInlineAddButton("Descanso", systemImage: "pause.circle", filled: true, action: onRest)
                WorkoutInlineAddButton("Movimiento libre", systemImage: "plus.circle.fill", filled: true, action: onFreeMovement)
            }
        }
        .padding(.vertical, 8)
        .listRowSeparator(.hidden)
    }
}

struct WorkoutInlineAddButton: View {
    let title: String
    let systemImage: String
    let filled: Bool
    let action: () -> Void

    init(_ title: String, systemImage: String, filled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.filled = filled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 19, height: 20)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.88)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(OG.accent)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .center)
            .background {
                if filled {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black)
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(OG.accent.opacity(0.35), lineWidth: 1)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Añadir \(title.lowercased())")
        .listRowSeparator(.hidden)
    }
}
