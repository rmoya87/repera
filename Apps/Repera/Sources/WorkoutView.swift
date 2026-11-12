import ReperaDomain
import SwiftUI
import UIKit
import UniformTypeIdentifiers

private struct PlayReplacementTarget: Identifiable, Hashable {
    let id = UUID()
    let blockID: UUID
    let itemID: UUID
}
private struct PendingPlayReplacement {
    let target: PlayReplacementTarget
    let exercise: Exercise
}

struct WorkoutView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Si se presenta fuera de un sheet, cierra el flujo de navegación raíz.
    var onClose: (() -> Void)? = nil
    @State private var repsText = ""
    @State private var weightText = ""
    @State private var setPhase: SetPhase = .work
    @State private var setKind: SetKind = .straight
    @State private var effortValue: Double = 2
    @State private var logEffort = true
    @State private var toFailure = false
    @State private var dropWeightText = ""
    @State private var dropRepsText = ""
    @State private var pendingDrops: [DropSegment] = []
    @State private var clusterRepsText = ""
    @State private var clusterRestText = "15"
    @State private var pendingClusters: [RestPauseCluster] = []
    @State private var editingRoutine: Routine?
    @State private var replacingPlayExercise: PlayReplacementTarget?
    @State private var exerciseDetailID: UUID?
    @State private var pendingPlayReplacement: PendingPlayReplacement?
    @State private var addPlayExerciseToBlock: UUID?
    @State private var selectPlayFormatForBlock: UUID?
    @State private var showPlayWODCatalog = false
    @State private var showPlayBoardScanner = false
    @State private var showPlayRoutinePicker = false
    @State private var showsPlayReorder = false
    @State private var playReorderDraggedToken: String?
    @State private var playReorderError: String?
    @State private var playReorderDraft: Routine?
    @State private var confirmCancelWorkout = false
    @State private var showFinishSummary = false
    @State private var createFreeMovementForBlock: UUID?
    @State private var openedSetID: UUID?
    @State private var undoToast: OGUndoToastState?
    @State private var playBlockDeleteConfirmID: UUID?
    @State private var notesDraft = ""
    @State private var favoriteSaveError: String?
    @State private var isSavingFavorite = false
    /// Flush síncrono del borrador local de `PlayEditableSetsView` (antes de terminar / mutar plan).
    @State private var playSetsFlusher: (() -> Void)?
    @State private var setCompletionPulse = 0
    @State private var restStartedPulse = 0
    @State private var pendingWODConfirm: PendingWODConfirm?
    /// Las marcas de bloque usan filas expandibles normales, igual que los ejercicios.
    @State private var expandedTechniquesExerciseID: UUID?
    @State private var usesAutomaticTimer = false
    @State private var pendingTimerBlockID: UUID?
    @State private var manualRoundSetup: ManualRoundSetup?
    @State private var manualRoundMinutes = 1
    @State private var manualRoundSeconds = 0
    @State private var manualRoundRestMinutes = 0
    @State private var manualRoundRestSeconds = 0
    @State private var confirmedManualRoundStart: ConfirmedManualRoundStart?
    /// EMOM/Tabata: el reloj ha terminado, pero todavía se pueden registrar series.
    @State private var finishedTimedBlockID: UUID?
    /// Mantener el temporizador del bloque al cambiar entre sus movimientos.
    @State private var runningTimerBlockID: UUID?
    @FocusState private var focusedSetField: OGSetFieldID?
    @FocusState private var focusedPlayFormatField: OGSetFieldID?
    @State private var advancedFieldRowID = UUID()
    @FocusState private var advancedFocusedField: OGSetFieldID?

    /// Petición asociada al ejercicio de origen, no al índice seleccionado:
    /// si el usuario cambia de bloque mientras el sheet está abierto, no
    /// se inicia un cronómetro para una prescripción diferente.
    private struct ManualRoundSetup: Identifiable {
        let id = UUID()
        let exerciseID: UUID
        let rounds: Int
    }

    private struct ConfirmedManualRoundStart {
        let exerciseID: UUID
        let durationSeconds: Int
        let restSeconds: Int
        let rounds: Int
    }

    private struct PendingWODConfirm: Identifiable {
        let id = UUID()
        let blockId: UUID
        let format: WODFormat
        let capture: WODResultCapture
        var totalReps: Int
        var elapsedSeconds: Int
        var roundsCompleted: Int
        let wodTemplateId: String?
        let title: String
    }

    var body: some View {
        workoutLifecycleView
    }

    /// Keep the observation modifiers separate from presentation/navigation.
    /// A single generic SwiftUI expression previously forced the compiler to
    /// type-check hundreds of nested builders at once.
    private var workoutLifecycleView: some View {
        workoutDialogsView
        .onAppear {
            // Restore the last recorded exercise and its live countdown after
            // iOS unexpectedly killed the process. No timer reset on reopen.
            if store.workoutClock.hasStarted {
                runningTimerBlockID = store.workoutClock.restoredBlockID
            }
            notesDraft = store.state.activeSession?.notes ?? ""
            prefill()
            bootstrapQuickLogIfNeeded()
            if store.state.activeSession?.phase == .ready {
                store.confirmCurrentOnWatchStyle()
            }
            if store.workoutClock.pendingEndReason != nil {
                presentWODConfirmIfNeeded()
            }
        }
        .onChange(of: store.state.activeSession?.currentIndex) { _, _ in
            // El editor del ejercicio anterior ya hizo flush en onDisappear.
            playSetsFlusher = nil
            prefill()
            let destinationBlock = store.state.activeSession?.currentExercise.flatMap { $0.blockId ?? $0.id }
            if destinationBlock != runningTimerBlockID {
                store.workoutClock.stop()
                store.workoutClock.clearPendingEnd()
                runningTimerBlockID = nil
            }
            if destinationBlock != finishedTimedBlockID {
                finishedTimedBlockID = nil
            }
            if store.state.activeSession?.phase == .ready {
                store.confirmCurrentOnWatchStyle()
            }
            if let blockID = pendingTimerBlockID {
                pendingTimerBlockID = nil
                if let current = store.state.activeSession?.currentExercise,
                   current.blockId == blockID || current.id == blockID {
                    requestBlockClockStart(for: current)
                }
            }
        }
        .onChange(of: store.workoutClock.pendingEndReason) { _, reason in
            guard reason != nil else { return }
            presentWODConfirmIfNeeded()
        }
        .onDisappear {
            playSetsFlusher?()
            // Rest + WOD clocks are owned by ReperaStore — do not stop on view disappear.
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            playSetsFlusher?()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            store.workoutClock.syncFromWallClock()
        }
    }

    private var workoutDialogsView: some View {
        workoutSecondaryNavigationView
        .sheet(isPresented: $showPlayBoardScanner) {
            BoardScanIntoRoutineView { imported in
                mutatePlayRoutine { $0.blocks.append(contentsOf: imported) }
            }
        }
        .sheet(isPresented: $showPlayRoutinePicker) {
            RoutineImportPickerSheet(
                routines: store.favoriteRoutines.filter { !$0.blocks.isEmpty },
                timers: store.state.favoriteTimers,
                onPick: { selected in
                    mutatePlayRoutine { draft in
                        draft.blocks.append(contentsOf: selected.blocks.map { $0.duplicatingContent() })
                    }
                    showPlayRoutinePicker = false
                },
                onPickTimer: { timer in
                    mutatePlayRoutine { $0.blocks.append(timer.asWorkoutBlock()) }
                    showPlayRoutinePicker = false
                },
                onCancel: { showPlayRoutinePicker = false }
            )
        }
        .confirmationDialog("¿Sustituir ejercicio y reiniciar sus series?", isPresented: Binding(
            get: { pendingPlayReplacement != nil },
            set: { if !$0 { pendingPlayReplacement = nil } }
        ), titleVisibility: .visible) {
            Button("Sustituir y reiniciar", role: .destructive) {
                if let pendingPlayReplacement {
                    replacePlayExercise(pendingPlayReplacement.target, with: pendingPlayReplacement.exercise)
                }
                pendingPlayReplacement = nil
            }
            Button("Cancelar", role: .cancel) { pendingPlayReplacement = nil }
        } message: {
            Text("Este ejercicio ya tiene resultados registrados. Al sustituirlo se eliminarán sus series y se empezará desde los valores del ejercicio nuevo.")
        }
        .alert(
            playReorderError != nil ? "No se ha podido mover el ejercicio"
                : "No se ha podido guardar el favorito",
            isPresented: Binding(
                get: { playReorderError != nil || favoriteSaveError != nil },
                set: { if !$0 { playReorderError = nil; favoriteSaveError = nil } }
            )
        ) {
            Button("Aceptar", role: .cancel) {
                playReorderError = nil
                favoriteSaveError = nil
            }
        } message: {
            Text(playReorderError ?? favoriteSaveError ?? "")
        }
        .sheet(isPresented: $confirmCancelWorkout) {
            OGConfirmSheet(
                systemImage: "xmark.circle.fill",
                title: "¿Cancelar entreno?",
                message: "Se descartará la sesión en curso sin guardarla.",
                confirmTitle: "Cancelar entreno",
                onConfirm: {
                    confirmCancelWorkout = false
                    store.workoutClock.stop()
                    store.endActiveSession(save: false)
                    closeFlow()
                },
                onCancel: { confirmCancelWorkout = false }
            )
        }
        .ogUndoToast($undoToast)
        .confirmationDialog(
            "¿Eliminar este bloque?",
            isPresented: Binding(
                get: { playBlockDeleteConfirmID != nil },
                set: { if !$0 { playBlockDeleteConfirmID = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Eliminar bloque", role: .destructive) {
                if let id = playBlockDeleteConfirmID {
                    removePlayBlock(id)
                }
                playBlockDeleteConfirmID = nil
            }
            Button("Cancelar", role: .cancel) {
                playBlockDeleteConfirmID = nil
            }
        } message: {
            Text("Se eliminarán todos los ejercicios del bloque.")
        }
        .sheet(isPresented: $showFinishSummary) {
            if let session = store.state.activeSession {
                OGWorkoutFinishSummarySheet(
                    title: session.title,
                    elapsedSeconds: playElapsedSeconds(session),
                    completedSets: playCompletedSetCount(session),
                    totalSets: playTotalSetCount(session),
                    volumeKg: playLiveVolumeKg(session),
                    warning: nil,
                    onSave: {
                        store.workoutClock.stop()
                        store.endActiveSession(save: true)
                        closeFlow()
                    },
                    onKeepTraining: {}
                )
            }
        }
    }

    private var workoutSecondaryNavigationView: some View {
        workoutPrimaryNavigationView
        .navigationDestination(item: $addPlayExerciseToBlock) { blockID in
            ExercisePickerView(embedsNavigationStack: false) { selected in
                mutatePlayRoutine { routine in
                    guard let index = routine.blocks.firstIndex(where: { $0.id == blockID }) else { return }
                    let quantity = selected.loggingStyle == .machineWork
                        ? (selected.defaultQuantityUnit == .meters ? 500 : 15)
                        : (selected.isMobility ? 8 : 8)
                    if routine.blocks[index].kind == .strength {
                        let sets = (0..<(selected.loggingStyle.usesDuration ? 1 : 3)).map { _ in
                            PlannedSet(targetReps: quantity)
                        }
                        routine.blocks[index].exercises.append(
                            RoutineExercise(exerciseId: selected.id, plannedSets: sets,
                                quantityUnit: selected.defaultQuantityUnit)
                        )
                    } else {
                        routine.blocks[index].movements.append(
                            WODMovement(exerciseId: selected.id, name: selected.name, reps: quantity,
                                explicitPlannedSets: [PlannedSet(targetReps: quantity)])
                        )
                    }
                }
                addPlayExerciseToBlock = nil
            }
        }
        .navigationDestination(item: $createFreeMovementForBlock) { blockID in
            FreeWODMovementCreatePage { movement in
                mutatePlayRoutine { routine in
                    guard let index = routine.blocks.firstIndex(where: { $0.id == blockID }) else { return }
                    if routine.blocks[index].kind == .wod {
                        routine.blocks[index].movements.append(movement)
                    } else {
                        routine.blocks.insert(
                            RoutineBlock(title: movement.name, kind: .wod, movements: [movement]),
                            at: index + 1
                        )
                    }
                }
                createFreeMovementForBlock = nil
            }
        }
        .navigationDestination(item: $selectPlayFormatForBlock) { blockID in
            WODFormatPickerPage { format in
                updatePlayWODFormat(format, for: blockID)
                selectPlayFormatForBlock = nil
            }
        }
        .navigationDestination(isPresented: $showPlayWODCatalog) {
            WODCatalogPickerView(embedsNavigationStack: false) { template in
                mutatePlayRoutine { $0.blocks.append(template.makeBlock()) }
                showPlayWODCatalog = false
            }
        }
        .navigationDestination(isPresented: $showsPlayReorder) {
            playReorderSheet
        }
    }

    private var workoutPrimaryNavigationView: some View {
        workoutToolbarView
        // Edición como destino push en NavigationStack, no hoja modal.
        .navigationDestination(item: $editingRoutine) { draft in
            DayEditorView(
                routine: draft,
                mode: draft.isOneOff ? .oneOff(isNew: false) : .plan(isNew: false),
                onClose: { editingRoutine = nil },
                onApplyDraft: { edited in
                    // Guardar la plantilla original solo si ya existe.
                    // Un escaneo no guardado también puede editarse sin
                    // gastar una plantilla gratuita de la biblioteca.
                    if store.state.routines.contains(where: { $0.id == edited.id }) {
                        _ = store.saveRoutine(edited)
                    }
                    playSetsFlusher?()
                    playSetsFlusher = nil
                    store.refreshActiveSessionPlan(from: edited)
                    store.updateActiveSessionLocation(edited.locationPin)
                    prefill()
                },
                embedsNavigationStack: false,
                usesPageCloseHeader: true
            )
        }
        .navigationDestination(item: $exerciseDetailID) { id in
            ExerciseDetailView(exerciseId: id, highlightSessionId: store.state.activeSession?.id)
        }
        .navigationDestination(item: $replacingPlayExercise) { target in
            ExercisePickerView(embedsNavigationStack: false) { chosen in
                replacingPlayExercise = nil
                let previous = store.state.activeSession?.exercises.first(where: { $0.id == target.itemID })
                let scoredBlock = store.state.activeSession?.wodResults.contains(where: { $0.id == target.blockID }) == true
                if previous?.loggedSets.isEmpty == false || scoredBlock {
                    pendingPlayReplacement = PendingPlayReplacement(target: target, exercise: chosen)
                } else {
                    replacePlayExercise(target, with: chosen)
                }
            }
        }
    }

    private var workoutToolbarView: some View {
        workoutPresentationView
            .toolbar { workoutToolbarContents }
    }

    @ToolbarContentBuilder
    private var workoutToolbarContents: some ToolbarContent {
            ToolbarItem(placement: .topBarLeading) {
                CloseToolbarButton(action: { closeFlow() }, large: false, usesMinimizeGlyph: true)
                    .foregroundStyle(OG.label2)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Añadir bloque", systemImage: "square.stack.3d.up") {
                        mutatePlayRoutine { draft in
                            draft.blocks.append(.strength(title: "Bloque \(draft.blocks.count + 1)"))
                        }
                    }
                    Button("Elegir WOD", systemImage: "list.bullet.rectangle.portrait") {
                        showPlayWODCatalog = true
                    }
                    Button("Escanear pizarra", systemImage: "camera.viewfinder") {
                        showPlayBoardScanner = true
                    }
                    Divider()
                    Button("Reordenar", systemImage: "arrow.up.arrow.down") {
                        beginPlayReorder()
                    }
                    Button {
                        Task { await saveCurrentWorkoutFavorite() }
                    } label: {
                        Label(
                            activeIsFavorite ? "En favoritos" : "Favorito",
                            systemImage: activeIsFavorite ? "star.fill" : "star"
                        )
                    }
                    .disabled(isSavingFavorite)
                    Divider()
                    Button(role: .destructive) {
                        confirmCancelWorkout = true
                    } label: {
                        Label("Cancelar entreno", systemImage: "xmark.circle")
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
    }

    private func presentPlayFinishSummary() {
        playSetsFlusher?()
        store.updateActiveSessionNotes(notesDraft)
        showFinishSummary = true
    }

    private var workoutPresentationView: some View {
        workoutCoreView
        .animation(
            OGMotion.animation(OGMotion.appear, reduceMotion: reduceMotion),
            value: store.restCoordinator.isActive
        )
        .sensoryFeedback(.success, trigger: setCompletionPulse)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: restStartedPulse)
        .background(OG.bg)
        // Morph desde la barra Continuar (Play); sin tick del reloj.
        .ogContinueSessionMatchedGeometry(
            id: OGContinueSessionGeometry.playID,
            reduceMotion: reduceMotion
        )
        // El nombre real del entreno vive en la barra superior (siempre visible).
        .navigationTitle(store.state.activeSession?.title ?? "Entreno")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .ogTransparentNav()
        // Cubrir también status bar y safe areas, sin heredar el fondo claro de Play.
        .fullScreenCover(isPresented: Binding(
            get: { store.workoutClock.isVisible },
            set: { visible in
                if !visible { store.workoutClock.minimize() }
            }
        )) {
            wodFullscreenClock
                .preferredColorScheme(.dark)
                .background(Color.black.ignoresSafeArea())
                .statusBarHidden()
        }
        .sheet(item: $manualRoundSetup, onDismiss: {
            // Presentar fullscreen solo DESPUÉS de cerrarse el sheet de
            // configuración; iOS no puede presentar ambos a la vez.
            guard let selection = confirmedManualRoundStart else { return }
            confirmedManualRoundStart = nil
            guard let current = store.state.activeSession?.currentExercise,
                  current.id == selection.exerciseID else { return }
            startBlockClock(
                for: current,
                manualRoundSeconds: selection.durationSeconds,
                manualRounds: selection.rounds,
                manualRoundRestSeconds: selection.restSeconds
            )
        }) { setup in
            manualRoundDurationSheet(for: setup)
        }
    }

    private var workoutCoreView: some View {
        ZStack(alignment: .bottom) {
            Group {
                if let session = store.state.activeSession {
                    content(session)
                } else {
                    ContentUnavailableView("Sin sesión", systemImage: "pause.circle", description: Text("Vuelve a Inicio para empezar."))
                }
            }
            if !store.workoutClock.isVisible {
                VStack(spacing: 8) {
                    if runningTimerBlockID != nil, store.workoutClock.hasStarted {
                        minimizedTimerDock
                    }
                    if store.restCoordinator.isActive {
                        restDock
                    }
                }
                .padding(.horizontal, OG.pad)
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    /// El fallo al crear una plantilla no equivale a falta de suscripción.
    /// Primero preservar los cambios de Play y comprobar derechos reales.
    private func saveCurrentWorkoutFavorite() async {
        guard !isSavingFavorite else { return }
        isSavingFavorite = true
        defer { isSavingFavorite = false }
        favoriteSaveError = nil
        playSetsFlusher?()
        subscriptions.syncCounts(
            libraryRoutines: store.libraryRoutineCount,
            customExercises: store.customExerciseCount,
            favorites: store.favoriteCount
        )
        store.featureAccess = { [subscriptions] in subscriptions.policy }
        guard store.saveActiveSessionAsFavorite() != nil else {
            // Solo refrescar en caso de denegación comercial, nunca si falta
            // una sesión o hay otro fallo de persistencia.
            if store.lastAccessDenial != nil {
                await subscriptions.refreshEntitlementsForFeatureAction()
                if store.saveActiveSessionAsFavorite() != nil { return }
            }
            if let decision = store.lastAccessDenial, !decision.allowed,
               !subscriptions.policy.isPro, subscriptions.snapshot.status != .unknown {
                subscriptions.presentPaywall(
                    decision.paywallContext, feature: .unlimitedRoutines
                )
            } else {
                favoriteSaveError = subscriptions.snapshot.status == .unknown && !subscriptions.isPro
                    ? "No hemos podido verificar tu suscripción. Comprueba la conexión o utiliza «Restaurar compras» en Ajustes."
                    : "No se ha podido guardar este entrenamiento como favorito. Inténtalo de nuevo."
            }
            return
        }
    }

    private func closeFlow() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    /// Lugar de la sesión real, no de la plantilla de entrenamiento.
    /// Seleccionarlo desde Play se guarda al momento.
    private var activeLocationPin: Binding<WorkoutLocationPin?> {
        Binding(
            get: { store.state.activeSession?.locationPin },
            set: { store.updateActiveSessionLocation($0) }
        )
    }

    private var hasMoreExercises: Bool {
        guard let session = store.state.activeSession else { return false }
        return session.currentIndex + 1 < session.exercises.count
    }

    private var activeIsFavorite: Bool {
        store.activeSessionIsFavorite
    }

    /// Log rápido («Apuntar · …»): UI plana por secciones, sin card envolvente ni Comenzar.
    private var isQuickLogSession: Bool {
        store.state.activeSession?.title.hasPrefix("Apuntar") == true
    }

    private func bootstrapQuickLogIfNeeded() {
        guard isQuickLogSession,
              store.state.activeSession?.phase == .ready
        else { return }
        store.confirmCurrentOnWatchStyle()
    }

    /// Reconstruye un borrador editable incluso para sesiones creadas sin guardar rutina.
    private func routineForEditing() -> Routine? {
        guard let session = store.state.activeSession else { return nil }
        if let id = session.routineId,
           var routine = store.state.routines.first(where: { $0.id == id }) {
            // Play puede haber cambiado número, pesos o reps; el borrador
            // de la sesión es más reciente que la plantilla reutilizable.
            routine.blocks = session.routineBlocks ?? routine.blocks
            routine.locationPin = session.locationPin
            return routine
        }
        if let blocks = session.routineBlocks, !blocks.isEmpty {
            return Routine(id: session.routineId ?? UUID(), title: session.title, blocks: blocks, locationPin: session.locationPin)
        }
        var blocks: [RoutineBlock] = []
        for exercise in session.exercises {
            let id = exercise.blockId ?? exercise.id
            if blocks.last?.id != id {
                blocks.append(RoutineBlock(
                    id: id,
                    title: exercise.blockHeader ?? "Bloque \(blocks.count + 1)",
                    kind: exercise.blockKind ?? .strength,
                    wodFormat: exercise.wodFormat,
                    timeCapMinutes: exercise.blockTimeCapMinutes,
                    timeCapSeconds: exercise.blockTimeCapSeconds,
                    emomIntervalSeconds: exercise.blockIntervalSeconds,
                    rounds: exercise.blockRounds,
                    workSeconds: exercise.blockWorkSeconds,
                    restSeconds: exercise.blockRestSeconds
                ))
            }
            guard let last = blocks.indices.last else { continue }
            if blocks[last].kind == .strength {
                blocks[last].exercises.append(RoutineExercise(
                    exerciseId: exercise.exercise.id,
                    plannedSets: exercise.plannedSets,
                    quantityUnit: exercise.quantityUnit
                ))
            } else {
                blocks[last].movements.append(WODMovement(
                    exerciseId: exercise.exercise.id,
                    name: exercise.exercise.name,
                    reps: exercise.plannedSets.first?.targetReps ?? 8,
                    distanceMeters: exercise.quantityUnit == .meters
                        ? exercise.plannedSets.first?.targetReps : nil,
                    calories: exercise.quantityUnit == .calories
                        ? exercise.plannedSets.first?.targetReps : nil,
                    explicitPlannedSets: exercise.plannedSets
                ))
            }
        }
        return Routine(id: session.routineId ?? UUID(), title: session.title, blocks: blocks, locationPin: session.locationPin)
    }


    private func mutatePlayRoutine(_ operation: (inout Routine) -> Void) {
        playSetsFlusher?()
        guard var draft = routineForEditing() else { return }
        operation(&draft)
        store.refreshActiveSessionPlan(from: draft)
    }

    /// Keep format defaults out of the SwiftUI destination builder so the
    /// type checker only needs to infer a small navigation closure.
    private func updatePlayWODFormat(_ format: WODFormat?, for blockID: UUID) {
        if pendingWODConfirm?.blockId == blockID {
            pendingWODConfirm = nil
        }
        mutatePlayRoutine { routine in
            guard let index = routine.blocks.firstIndex(where: { $0.id == blockID }) else { return }
            routine.blocks[index].wodFormat = format
            guard let format else { return }
            switch format {
            case .tabata:
                routine.blocks[index].workSeconds = routine.blocks[index].workSeconds ?? 20
                routine.blocks[index].restSeconds = routine.blocks[index].restSeconds ?? 10
                routine.blocks[index].rounds = routine.blocks[index].rounds ?? 8
            case .forTime:
                routine.blocks[index].rounds = routine.blocks[index].rounds ?? 4
                routine.blocks[index].timeCapMinutes = routine.blocks[index].timeCapMinutes ?? 12
            case .amrap, .emom:
                routine.blocks[index].timeCapMinutes = routine.blocks[index].timeCapMinutes ?? 12
                if format == .emom {
                    routine.blocks[index].deriveEmomRoundsIfNeeded()
                }
            default:
                break
            }
        }
    }

    /// Edit the ordering as a draft; apply it to the live session on exit
    /// to avoid restarting/reconciling the workout after every drag update.
    private func beginPlayReorder() {
        playSetsFlusher?()
        playReorderDraft = routineForEditing()
        showsPlayReorder = playReorderDraft != nil
    }

    private func editPlayReorderDraft(_ edit: (inout Routine) -> Void) {
        guard var draft = playReorderDraft else { return }
        edit(&draft)
        playReorderDraft = draft
    }

    private func commitPlayReorder() {
        guard let draft = playReorderDraft else { return }
        playReorderDraft = nil
        mutatePlayRoutine { $0.blocks = draft.blocks }
        prefill()
    }

    /// Drag & drop estable de SwiftUI, sin reorderContainer beta.
    /// Se conserva el borrador y solo se confirma al abandonar la página.
    private var playReorderSheet: some View {
        ScrollView {
            if let draft = playReorderDraft {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(draft.blocks.enumerated()), id: \.element.id) { position, block in
                        OGReorderInsertionGap(
                            draggedToken: $playReorderDraggedToken,
                            accepts: { $0.hasPrefix("block:") }
                        ) { token in
                            var moved = false
                            OGMotion.run(OGMotion.reorder, reduceMotion: reduceMotion) { moved = movePlayBlockToken(token, before: block.id) }
                            return moved
                        }
                        playReorderBlockBox(position: position, block: block)
                    }
                    OGReorderInsertionGap(
                        draggedToken: $playReorderDraggedToken,
                        accepts: { $0.hasPrefix("block:") }
                    ) { token in
                        var moved = false
                        OGMotion.run(OGMotion.reorder, reduceMotion: reduceMotion) { moved = movePlayBlockToken(token, before: nil) }
                        return moved
                    }
                }
                .padding(.horizontal, OG.pad)
                .padding(.vertical, 12)
            }
        }
        .background(OG.bg.ignoresSafeArea())
        .navigationTitle("Reordenar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                OGDoneCheckButton { showsPlayReorder = false }
            }
        }
        .onDisappear {
            playReorderDraggedToken = nil
            commitPlayReorder()
        }
    }

    /// Destino al soltar un bloque sobre otra caja (misma regla que DayEditor).
    private func playBlockDropBeforeID(token: String, targetPosition: Int, targetID: UUID) -> UUID? {
        guard token.hasPrefix("block:"),
              let sourceID = UUID(uuidString: String(token.dropFirst(6))),
              let draft = playReorderDraft,
              let sourceIndex = draft.blocks.firstIndex(where: { $0.id == sourceID })
        else { return targetID }
        if sourceIndex < targetPosition {
            return draft.blocks.dropFirst(targetPosition + 1).first?.id
        }
        if sourceIndex > targetPosition {
            return targetID
        }
        return sourceID
    }

    /// Reordena únicamente el borrador; nunca reinicia Salud ni el cronómetro.
    private func movePlayBlockToken(_ token: String, before targetID: UUID?) -> Bool {
        guard token.hasPrefix("block:"),
              let sourceID = UUID(uuidString: String(token.dropFirst(6))),
              sourceID != targetID,
              let draft = playReorderDraft,
              draft.blocks.contains(where: { $0.id == sourceID })
        else { return false }
        var changed = false
        editPlayReorderDraft { draft in
            guard let source = draft.blocks.firstIndex(where: { $0.id == sourceID }) else { return }
            let originalOrder = draft.blocks.map(\.id)
            let moved = draft.blocks.remove(at: source)
            let target = targetID.flatMap { id in
                draft.blocks.firstIndex(where: { $0.id == id })
            } ?? draft.blocks.count
            draft.blocks.insert(moved, at: target)
            changed = draft.blocks.map(\.id) != originalOrder
        }
        return changed
    }

    /// Misma tarjeta y mismas filas del modo crear/editar.
    private func playReorderBlockBox(position: Int, block: RoutineBlock) -> some View {
        let rows = playReorderRows(block)
        return VStack(alignment: .leading, spacing: 0) {
            playReorderBlockHeader(position: position, block: block)
                .contentShape(Rectangle())
                .onDrag {
                    let token = "block:\(block.id.uuidString)"
                    playReorderDraggedToken = token
                    return NSItemProvider(object: token as NSString)
                } preview: {
                    OGReorderDragPreview {
                        playReorderBlockHeader(position: position, block: block)
                    }
                }
                .onDrop(
                    of: [UTType.plainText],
                    delegate: OGReorderDropDelegate(
                        draggedToken: $playReorderDraggedToken,
                        accepts: { $0.hasPrefix("block:") },
                        performMove: { token, _ in
                            let before = playBlockDropBeforeID(
                                token: token, targetPosition: position, targetID: block.id
                            )
                            var moved = false
                            OGMotion.run(OGMotion.reorder, reduceMotion: reduceMotion) { moved = movePlayBlockToken(token, before: before) }
                            return moved
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
                            draggedToken: $playReorderDraggedToken,
                            accepts: { _ in true },
                            performMove: { token, _ in
                                if token.hasPrefix("block:") {
                                    let before = playBlockDropBeforeID(
                                        token: token, targetPosition: position, targetID: block.id
                                    )
                                    var movedBlock = false
                                    OGMotion.run(OGMotion.reorder, reduceMotion: reduceMotion) {
                                        movedBlock = movePlayBlockToken(token, before: before)
                                    }
                                    return movedBlock
                                }
                                var moved = false
                                OGMotion.run(OGMotion.reorder, reduceMotion: reduceMotion) { moved = movePlayReorderToken(token, into: block.id) }
                                return moved
                            }
                        )
                    )
                    .padding(.bottom, 8)
            } else {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    Divider()
                        .overlay(OG.label3.opacity(0.22))
                        .padding(.leading, 14)
                    playReorderRow(
                        name: row.name, blockID: block.id, itemID: row.id, kind: block.kind
                    )
                    .onDrop(
                        of: [UTType.plainText],
                        delegate: OGReorderDropDelegate(
                            draggedToken: $playReorderDraggedToken,
                            accepts: { _ in true },
                            performMove: { token, location in
                                if token.hasPrefix("block:") {
                                    let before = playBlockDropBeforeID(
                                        token: token, targetPosition: position, targetID: block.id
                                    )
                                    var movedBlock = false
                                    OGMotion.run(OGMotion.reorder, reduceMotion: reduceMotion) {
                                        movedBlock = movePlayBlockToken(token, before: before)
                                    }
                                    return movedBlock
                                }
                                let before = location.y > 28 ? rows.dropFirst(index + 1).first?.id : row.id
                                var moved = false
                                OGMotion.run(OGMotion.reorder, reduceMotion: reduceMotion) {
                                    moved = movePlayReorderToken(token, into: block.id, before: before)
                                }
                                return moved
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

    private func playReorderBlockHeader(position: Int, block: RoutineBlock) -> some View {
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

    private func playReorderRows(_ block: RoutineBlock) -> [OGReorderEntry] {
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

    private func movePlayReorderToken(
        _ token: String?, into blockID: UUID, before itemID: UUID? = nil
    ) -> Bool {
        guard let token, !token.hasPrefix("block:") else { return false }
        let parts = token.split(separator: ":")
        guard parts.count == 2,
              let from = UUID(uuidString: String(parts[0])),
              let sourceItem = UUID(uuidString: String(parts[1])),
              !(from == blockID && sourceItem == itemID),
              let draft = playReorderDraft,
              let source = draft.blocks.first(where: { $0.id == from }),
              let target = draft.blocks.first(where: { $0.id == blockID })
        else { return false }
        if source.kind == .strength {
            guard source.exercises.contains(where: { $0.id == sourceItem }) else { return false }
        } else {
            guard let move = source.movements.first(where: { $0.id == sourceItem }),
                  !(move.isRest && target.kind == .strength) else { return false }
        }
        return movePlayReorderItem(sourceItem, from: from, into: blockID, before: itemID)
    }

    private func movePlayReorderItem(
        _ itemID: UUID, from sourceID: UUID, into targetID: UUID, before nextID: UUID? = nil
    ) -> Bool {
        var moved = false
        editPlayReorderDraft { draft in
            guard let from = draft.blocks.firstIndex(where: { $0.id == sourceID }),
                  let to = draft.blocks.firstIndex(where: { $0.id == targetID })
            else { return }
            if draft.blocks[from].kind == .strength {
                guard let index = draft.blocks[from].exercises.firstIndex(where: { $0.id == itemID })
                else { return }
                let item = draft.blocks[from].exercises[index]
                let title = store.state.exercises.first(where: { $0.id == item.exerciseId })?.name ?? "Ejercicio"
                if draft.blocks[to].kind == .strength {
                    draft.blocks[from].exercises.remove(at: index)
                    let destination = nextID.flatMap { id in
                        draft.blocks[to].exercises.firstIndex(where: { $0.id == id })
                    } ?? draft.blocks[to].exercises.count
                    draft.blocks[to].exercises.insert(item, at: destination)
                } else {
                    draft.blocks[from].exercises.remove(at: index)
                    let move = WODMovement(
                        id: item.id, exerciseId: item.exerciseId,
                        name: title, reps: item.plannedSets.first?.targetReps ?? 8,
                        explicitPlannedSets: item.plannedSets
                    )
                    let destination = nextID.flatMap { id in
                        draft.blocks[to].movements.firstIndex(where: { $0.id == id })
                    } ?? draft.blocks[to].movements.count
                    draft.blocks[to].movements.insert(move, at: destination)
                }
            } else {
                guard let index = draft.blocks[from].movements.firstIndex(where: { $0.id == itemID })
                else { return }
                let movement = draft.blocks[from].movements[index]
                if draft.blocks[to].kind == .wod {
                    draft.blocks[from].movements.remove(at: index)
                    let destination = nextID.flatMap { id in
                        draft.blocks[to].movements.firstIndex(where: { $0.id == id })
                    } ?? draft.blocks[to].movements.count
                    draft.blocks[to].movements.insert(movement, at: destination)
                } else {
                    guard !movement.isRest else { return }
                    var catalogID = movement.exerciseId.flatMap { id in
                        store.state.exercises.contains(where: { $0.id == id }) ? id : nil
                    } ?? store.state.exercises.first(where: {
                        $0.name.localizedCaseInsensitiveCompare(movement.name) == .orderedSame
                    })?.id
                    if catalogID == nil {
                        guard store.addCustomExercise(
                            name: movement.name, muscleGroup: "Otros", equipment: nil
                        ) else {
                            playReorderError = "No se pudo añadir el movimiento libre al catálogo para moverlo al bloque de fuerza."
                            return
                        }
                        catalogID = store.state.exercises.last(where: {
                            $0.name.localizedCaseInsensitiveCompare(movement.name) == .orderedSame
                        })?.id
                    }
                    guard let catalogID else {
                        playReorderError = "No se encontró un ejercicio compatible para este bloque."
                        return
                    }
                    let item = RoutineExercise(
                        id: movement.id, exerciseId: catalogID,
                        plannedSets: movement.explicitPlannedSets ?? movement.plannedSetsFromReps,
                        quantityUnit: movement.prescribedQuantityUnit
                    )
                    draft.blocks[from].movements.remove(at: index)
                    let destination = nextID.flatMap { id in
                        draft.blocks[to].exercises.firstIndex(where: { $0.id == id })
                    } ?? draft.blocks[to].exercises.count
                    draft.blocks[to].exercises.insert(item, at: destination)
                }
            }
            moved = true
        }
        return moved
    }

    @ViewBuilder
    private func playReorderThumb(blockID: UUID, itemID: UUID) -> some View {
        if let block = playReorderDraft?.blocks.first(where: { $0.id == blockID }) {
            if block.kind == .strength,
               let item = block.exercises.first(where: { $0.id == itemID }),
               let exercise = store.state.exercises.first(where: { $0.id == item.exerciseId }) {
                ExerciseThumb(exercise: exercise, size: 32)
            } else if block.kind == .wod,
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

    private func playReorderRow(
        name: String, blockID: UUID, itemID: UUID, kind: RoutineBlockKind
    ) -> some View {
        let dragToken = "\(blockID.uuidString):\(itemID.uuidString)"
        return HStack(spacing: 12) {
            playReorderThumb(blockID: blockID, itemID: itemID)
            Text(name)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(OG.label)
            Spacer(minLength: 8)
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(OG.label3)
                .accessibilityLabel("Arrastrar \(name)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onDrag {
            playReorderDraggedToken = dragToken
            return NSItemProvider(object: dragToken as NSString)
        } preview: {
            OGReorderDragPreview(cornerRadius: 12) {
                HStack(spacing: 12) {
                    playReorderThumb(blockID: blockID, itemID: itemID)
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

    private func movePlayBlock(_ blockID: UUID, offset: Int) {
        mutatePlayRoutine { routine in
            guard let old = routine.blocks.firstIndex(where: { $0.id == blockID }),
                  routine.blocks.indices.contains(old + offset) else { return }
            let block = routine.blocks.remove(at: old)
            routine.blocks.insert(block, at: old + offset)
        }
    }

    private func playBlockExerciseCount(_ block: WorkoutBlockEntry, session: WorkoutSession) -> Int {
        block.indexes.count
    }

    @MainActor
    private func presentPlayUndoToast(message: String, undo: @escaping () -> Void) {
        let state = OGUndoToastState(message: message, undo: undo)
        undoToast = state
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            if undoToast?.id == state.id {
                undoToast = nil
            }
        }
    }

    private func removePlayBlock(_ blockID: UUID) {
        mutatePlayRoutine { routine in
            let remaining = routine.blocks.filter { $0.id != blockID }
            // Una sesión activa nunca puede perder su último ejercicio.
            guard remaining.contains(where: { !$0.exercises.isEmpty || !$0.movements.filter({ !$0.isRest }).isEmpty }) else { return }
            routine.blocks = remaining
        }
    }

    private func movePlayExercise(_ blockID: UUID, itemID: UUID, offset: Int) {
        mutatePlayRoutine { routine in
            guard let i = routine.blocks.firstIndex(where: { $0.id == blockID }) else { return }
            if routine.blocks[i].kind == .strength {
                guard let j = routine.blocks[i].exercises.firstIndex(where: { $0.id == itemID }),
                      routine.blocks[i].exercises.indices.contains(j + offset) else { return }
                let item = routine.blocks[i].exercises.remove(at: j)
                routine.blocks[i].exercises.insert(item, at: j + offset)
            } else {
                guard let j = routine.blocks[i].movements.firstIndex(where: { $0.id == itemID }),
                      routine.blocks[i].movements.indices.contains(j + offset) else { return }
                let item = routine.blocks[i].movements.remove(at: j)
                routine.blocks[i].movements.insert(item, at: j + offset)
            }
        }
    }

    private func removePlayExercise(_ blockID: UUID, itemID: UUID) {
        var removedExercise: RoutineExercise?
        var removedMovement: WODMovement?
        var insertAt = 0
        var blockIndex = 0
        mutatePlayRoutine { routine in
            guard let index = routine.blocks.firstIndex(where: { $0.id == blockID }) else { return }
            blockIndex = index
            if routine.blocks[index].kind == .strength {
                guard let exIndex = routine.blocks[index].exercises.firstIndex(where: { $0.id == itemID }) else { return }
                removedExercise = routine.blocks[index].exercises[exIndex]
                insertAt = exIndex
                routine.blocks[index].exercises.remove(at: exIndex)
            } else {
                guard let mvIndex = routine.blocks[index].movements.firstIndex(where: { $0.id == itemID }) else { return }
                removedMovement = routine.blocks[index].movements[mvIndex]
                insertAt = mvIndex
                routine.blocks[index].movements.remove(at: mvIndex)
            }
        }
        if let removed = removedExercise {
            presentPlayUndoToast(message: "Ejercicio eliminado") {
                mutatePlayRoutine { routine in
                    guard routine.blocks.indices.contains(blockIndex) else { return }
                    let at = min(insertAt, routine.blocks[blockIndex].exercises.count)
                    routine.blocks[blockIndex].exercises.insert(removed, at: at)
                }
            }
        } else if let removed = removedMovement {
            presentPlayUndoToast(message: "Ejercicio eliminado") {
                mutatePlayRoutine { routine in
                    guard routine.blocks.indices.contains(blockIndex) else { return }
                    let at = min(insertAt, routine.blocks[blockIndex].movements.count)
                    routine.blocks[blockIndex].movements.insert(removed, at: at)
                }
            }
        }
    }

    private func replacePlayExercise(_ target: PlayReplacementTarget, with selected: Exercise) {
        mutatePlayRoutine { routine in
            guard let blockIndex = routine.blocks.firstIndex(where: { $0.id == target.blockID }) else { return }
            let style = selected.loggingStyle
            let quantity = style == .machineWork
                ? (selected.defaultQuantityUnit == .meters ? 500 : 15)
                : (selected.isMobility ? (selected.isMobilityHold ? 1 : 8)
                    : (style == .repsAndTime ? 50 : 8))
            let duration: Int? = selected.isMobility
                ? (selected.isMobilityHold ? 30 : 60) : nil
            if routine.blocks[blockIndex].kind == .strength {
                guard let j = routine.blocks[blockIndex].exercises.firstIndex(where: { $0.id == target.itemID }) else { return }
                let count = style.usesDuration ? 1 : 3
                let sets = (0..<count).map { _ in
                    PlannedSet(targetReps: quantity, targetDurationSeconds: duration)
                }
                // Nueva identidad: la sesión nunca reutiliza las series realizadas.
                routine.blocks[blockIndex].exercises[j] = RoutineExercise(
                    exerciseId: selected.id, plannedSets: sets,
                    quantityUnit: style == .machineWork || selected.supportsRepsOrMeters
                        ? selected.defaultQuantityUnit : nil
                )
            } else {
                guard let j = routine.blocks[blockIndex].movements.firstIndex(where: { $0.id == target.itemID }) else { return }
                routine.blocks[blockIndex].movements[j] = WODMovement(
                    exerciseId: selected.id, name: selected.name, reps: quantity,
                    explicitPlannedSets: [PlannedSet(targetReps: quantity, targetDurationSeconds: duration)]
                )
            }
        }
    }

    private func insertPlayRest(after blockID: UUID) {
        mutatePlayRoutine { draft in
            guard let index = draft.blocks.firstIndex(where: { $0.id == blockID }) else { return }
            let rest = WODMovement(name: "REST", isRest: true, restSeconds: 60)
            if draft.blocks[index].kind == .wod {
                draft.blocks[index].movements.append(rest)
            } else {
                draft.blocks.insert(
                    RoutineBlock(title: "Descanso", kind: .wod, movements: [rest]),
                    at: index + 1
                )
            }
        }
    }

    private func beginPlayFreeMovement(after blockID: UUID) {
        guard routineForEditing()?.blocks.contains(where: { $0.id == blockID }) == true else { return }
        createFreeMovementForBlock = blockID
    }

    /// Play comparte los controles de bloques/ejercicios y series del editor,
    /// añadiendo el reloj de cada bloque y el registro real de resultados.
    private struct WorkoutBlockEntry: Identifiable {
        let id: UUID
        let title: String
        let format: WODFormat?
        var indexes: [Int]
    }

    private func workoutBlocks(_ session: WorkoutSession) -> [WorkoutBlockEntry] {
        // Un solo pase O(ejercicios): evita compactMap por bloque (O(bloques×ejercicios)).
        var indexesByBlock: [UUID: [Int]] = [:]
        indexesByBlock.reserveCapacity(session.exercises.count)
        for (index, exercise) in session.exercises.enumerated() {
            let id = exercise.blockId ?? exercise.id
            indexesByBlock[id, default: []].append(index)
        }
        if let saved = session.routineBlocks, !saved.isEmpty {
            return saved.map { block in
                WorkoutBlockEntry(
                    id: block.id, title: block.title, format: block.wodFormat,
                    indexes: indexesByBlock[block.id] ?? []
                )
            }
        }
        var blocks: [WorkoutBlockEntry] = []
        var seen: Set<UUID> = []
        for exercise in session.exercises {
            let id = exercise.blockId ?? exercise.id
            guard seen.insert(id).inserted else { continue }
            blocks.append(
                WorkoutBlockEntry(
                    id: id,
                    title: exercise.blockHeader ?? "Bloque \(blocks.count + 1)",
                    format: exercise.wodFormat,
                    indexes: indexesByBlock[id] ?? []
                )
            )
        }
        return blocks
    }

    private func content(_ session: WorkoutSession) -> some View {
        List {
            Section {
                OGPlaySessionProgressHeader(
                    completedSets: playCompletedSetCount(session),
                    totalSets: playTotalSetCount(session),
                    volumeKg: playLiveVolumeKg(session),
                    startedAt: session.startedAt
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            ForEach(workoutBlocks(session)) { block in
                Section {
                    playBlockSectionBody(block, session: session)
                } header: {
                    if workoutBlocks(session).count > 1 {
                        HStack(spacing: 6) {
                            Text("Bloque")
                            if let format = block.format {
                                Text("· \(format.displayName)")
                            } else {
                                Text("· Libre")
                            }
                        }
                        .textCase(nil)
                    }
                }
            }

            Section("Notas del entreno") {
                inlineWorkoutNotes
            }

            Section {
                Button {
                    presentPlayFinishSummary()
                } label: {
                    Label("Terminar entreno", systemImage: "flag.checkered")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(OG.onAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(OG.accent, in: Capsule())
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 16, trailing: 0))
                .accessibilityLabel("Terminar entreno")
            }
        }
        .listStyle(.insetGrouped)
        .ogListChrome()
        .contentMargins(
            .bottom,
            store.restCoordinator.isActive ? 100 : 0,
            for: .scrollContent
        )
        .task(id: session.id) {
            while !Task.isCancelled, store.state.activeSession?.id == session.id {
                await HealthKitStore.shared.refreshLiveMetrics()
                try? await Task.sleep(for: .seconds(15))
            }
        }
    }

    /// Cuerpo de un bloque en Play: partido en helpers para que el type-check termine.
    @ViewBuilder
    private func playBlockSectionBody(
        _ block: WorkoutBlockEntry,
        session: WorkoutSession
    ) -> some View {
        playBlockTitleRow(block, session: session)
        playBlockFormatSettings(block)
            .listRowBackground(OG.surface)
            .listRowSeparator(.hidden)
        if let format = block.format, format.resultCapture != .perMovementSets {
            inlineWODScoreEditor(block, format: format, session: session)
                .listRowBackground(OG.surface)
        }
        playBlockExerciseList(block, session: session)
        playBlockTechniquesRows(block, session: session)
        playBlockFinishedTimerRow(block)
        WorkoutWODInsertActions(
            onExercise: { addPlayExerciseToBlock = block.id },
            onRest: { insertPlayRest(after: block.id) },
            onFreeMovement: { beginPlayFreeMovement(after: block.id) }
        )
    }

    private func playBlockTitleRow(
        _ block: WorkoutBlockEntry,
        session: WorkoutSession
    ) -> some View {
        HStack(spacing: 12) {
            Text(block.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(OG.label)
                .lineLimit(2)
            Spacer(minLength: 8)
            OGToolbarGlassButton(
                systemName: "timer",
                accessibilityLabel: "Temporizador de \(block.title)",
                tint: OG.accent,
                iconSize: 19,
                hitSize: 44,
                appliesGlass: true
            ) {
                openBlockTimer(block, session: session)
            }
            .disabled(block.indexes.isEmpty)
            Menu {
                Button("Reordenar", systemImage: "arrow.up.arrow.down") {
                    beginPlayReorder()
                }
                Button("Añadir ejercicio", systemImage: "plus") {
                    addPlayExerciseToBlock = block.id
                }
                Divider()
                Button("Eliminar bloque", systemImage: "trash", role: .destructive) {
                    if playBlockExerciseCount(block, session: session) > 1 {
                        playBlockDeleteConfirmID = block.id
                    } else {
                        removePlayBlock(block.id)
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(OG.label)
                    .frame(width: 38, height: 38)
                    .glassEffect(.regular.interactive(), in: .circle)
            }
            .accessibilityLabel("Opciones de \(block.title)")
        }
        .listRowBackground(OG.surface)
    }

    /// Filas de ejercicios + series del actual (extraídas para acotar el type-check del List).
    @ViewBuilder
    private func playBlockExerciseList(
        _ block: WorkoutBlockEntry,
        session: WorkoutSession
    ) -> some View {
        let blockResult = session.wodResults.first(where: {
            $0.id == block.id && $0.format == block.format
        })
        ForEach(block.indexes, id: \.self) { index in
            playBlockExerciseRows(
                block: block,
                index: index,
                session: session,
                blockResult: blockResult
            )
        }
    }

    @ViewBuilder
    private func playBlockExerciseRows(
        block: WorkoutBlockEntry,
        index: Int,
        session: WorkoutSession,
        blockResult: WODBlockResult?
    ) -> some View {
        let entry = session.exercises[index]
        let isCurrent = index == session.currentIndex
        HStack(spacing: 4) {
            Button {
                if isCurrent {
                    exerciseDetailID = entry.exercise.id
                } else {
                    store.selectExercise(at: index)
                }
            } label: {
                workoutExerciseRow(
                    entry, isOpen: isCurrent,
                    blockResult: blockResult
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint(
                isCurrent
                    ? "Ver ficha del ejercicio"
                    : "Seleccionar ejercicio para registrar series"
            )
            Menu {
                Button("Seleccionar ejercicio", systemImage: "checkmark.circle") {
                    store.selectExercise(at: index)
                }
                Button("Sustituir ejercicio", systemImage: "arrow.left.arrow.right") {
                    replacingPlayExercise = PlayReplacementTarget(
                        blockID: block.id, itemID: entry.id
                    )
                }
                Button("Reordenar", systemImage: "arrow.up.arrow.down") {
                    beginPlayReorder()
                }
                Button("Eliminar ejercicio", systemImage: "trash", role: .destructive) {
                    removePlayExercise(block.id, itemID: entry.id)
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
        .listRowBackground(OG.surface)
        .listRowSeparator(.hidden, edges: .bottom)

        // Solo el ejercicio actual monta el editor de series (evita N editores vivos).
        if isCurrent {
            PlayEditableSetsView(
                exerciseEntry: entry,
                registerFlusher: { playSetsFlusher = $0 },
                openedSetID: $openedSetID,
                onUndoSetDelete: { message, undo in
                    presentPlayUndoToast(message: message, undo: undo)
                },
                onSetMarkedComplete: {
                    let rest = entry.restSeconds ?? store.state.settings.defaultRestSeconds
                    if shouldStartIndependentRest(for: entry) {
                        beginRest(rest)
                        restStartedPulse += 1
                    }
                    setCompletionPulse += 1
                }
            )
            .id(entry.id)
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(OG.surface)
            .listRowSeparator(.hidden, edges: .top)
        }
    }

    @ViewBuilder
    private func playBlockTechniquesRows(
        _ block: WorkoutBlockEntry,
        session: WorkoutSession
    ) -> some View {
        if block.indexes.contains(session.currentIndex),
           let current = session.currentExercise {
            Button {
                expandedTechniquesExerciseID =
                    expandedTechniquesExerciseID == current.id ? nil : current.id
            } label: {
                HStack(spacing: 8) {
                    Text("Técnicas de serie · dropset / rest-pause")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(OG.label)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .rotationEffect(.degrees(
                            expandedTechniquesExerciseID == current.id ? 180 : 0
                        ))
                        .foregroundStyle(OG.label2)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Técnicas de serie")
            .accessibilityValue(
                expandedTechniquesExerciseID == current.id ? "Desplegadas" : "Plegadas"
            )
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 4, trailing: 16))
            .listRowBackground(OG.surface)
            .listRowSeparator(.hidden)

            if expandedTechniquesExerciseID == current.id {
                logForm(current)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 12, trailing: 16))
                    .listRowBackground(OG.surface)
                    .listRowSeparator(.hidden)
            }
        }
    }

    @ViewBuilder
    private func playBlockFinishedTimerRow(_ block: WorkoutBlockEntry) -> some View {
        if finishedTimedBlockID == block.id,
           block.format?.resultCapture == .perMovementSets {
            HStack(spacing: 12) {
                Label("Temporizador finalizado. Registra las series realizadas.", systemImage: "timer")
                    .font(.footnote)
                    .foregroundStyle(OG.label2)
                Spacer(minLength: 0)
                Button("Finalizar bloque") {
                    finishedTimedBlockID = nil
                    runningTimerBlockID = nil
                    store.finishCurrentTimedBlock()
                    if store.state.activeSession == nil { closeFlow() }
                }
                .font(.footnote.weight(.semibold))
                .buttonStyle(.bordered)
            }
            .listRowBackground(OG.surface)
        }
    }

    private func workoutExerciseRow(
        _ entry: SessionExercise,
        isOpen: Bool,
        blockResult: WODBlockResult?
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ExerciseThumb(exercise: entry.exercise, size: 48)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(store.catalogTitle(for: entry.exercise))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(OG.label)
                Text(entry.plannedSets.compactSummary)
                    .font(.caption)
                    .foregroundStyle(OG.label2)
                if entry.loggedSets.isEmpty,
                   let blockResult,
                   entry.usesBlockScoreResult {
                    Text("Resultado del bloque · \(blockResult.summaryLabel)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(OG.accent)
                }
            }
            Spacer(minLength: 6)
            if entry.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(OG.accent)
            } else if !isOpen {
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(OG.label3)
            }
        }
        .contentShape(Rectangle())
    }

    /// El resultado permanece visible dentro del bloque, sin desplegable.

    /// Formato y parámetros visibles en Play, como en Crear/Editar.
    private enum PlayFormatField: Hashable {
        case duration, capSeconds, interval, rounds, work, rest, roundRest

        var title: String {
            switch self {
            case .duration: return "Tiempo"
            case .capSeconds: return "Segundos"
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

    private func playFormatFields(_ block: RoutineBlock) -> [PlayFormatField] {
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

    private func playFormatBinding(_ field: PlayFormatField, for blockID: UUID) -> Binding<Int> {
        Binding(
            get: {
                guard let block = store.state.activeSession?.routineBlocks?
                    .first(where: { $0.id == blockID })
                    ?? routineForEditing()?.blocks.first(where: { $0.id == blockID })
                else { return 0 }
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
                mutatePlayRoutine { draft in
                    guard let index = draft.blocks.firstIndex(where: { $0.id == blockID }) else { return }
                    switch field {
                    case .duration:
                        draft.blocks[index].timeCapMinutes = value
                        if let exact = draft.blocks[index].timeCapSeconds {
                            draft.blocks[index].timeCapSeconds = value * 60 + exact % 60
                        }
                    case .capSeconds:
                        let minutes = draft.blocks[index].timeCapMinutes ?? 12
                        draft.blocks[index].timeCapSeconds = value == 0 ? nil : minutes * 60 + value
                    case .interval: draft.blocks[index].emomIntervalSeconds = value
                    case .rounds: draft.blocks[index].rounds = value
                    case .work: draft.blocks[index].workSeconds = value
                    case .rest: draft.blocks[index].restSeconds = value
                    case .roundRest: draft.blocks[index].restBetweenRoundsSeconds = value
                    }
                    draft.blocks[index].deriveEmomRoundsIfNeeded()
                }
            }
        )
    }

    @ViewBuilder
    private func playBlockFormatSettings(_ entry: WorkoutBlockEntry) -> some View {
        if let block = store.state.activeSession?.routineBlocks?.first(where: { $0.id == entry.id })
            ?? routineForEditing()?.blocks.first(where: { $0.id == entry.id }) {
            VStack(alignment: .leading, spacing: 20) {
                Divider().padding(.vertical, 5)
                Button {
                    selectPlayFormatForBlock = entry.id
                } label: {
                    HStack(spacing: 10) {
                        Text("Formato").foregroundStyle(OG.label)
                        Spacer()
                        Text(block.wodFormat?.displayName ?? "Sin formato")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(OG.label2)
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(OG.label3)
                    }
                    .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                if let format = block.wodFormat {
                    let fields = playFormatFields(block)
                    if !fields.isEmpty {
                        HStack(alignment: .bottom, spacing: 12) {
                            ForEach(Array(fields.enumerated()), id: \.element) { position, field in
                                OGFormatNumberField(
                                    title: field.title,
                                    unit: field.unit,
                                    value: playFormatBinding(field, for: block.id),
                                    range: field.range,
                                    focus: $focusedPlayFormatField,
                                    fieldID: OGSetFieldID(rowID: block.id, column: position),
                                    nextID: position + 1 < fields.count
                                        ? OGSetFieldID(rowID: block.id, column: position + 1)
                                        : nil
                                )
                            }
                        }
                        .padding(.vertical, 10)
                    }
                    if format == .forTime, block.restBetweenRoundsSeconds != nil {
                        Stepper(
                            "Descanso entre rondas: \(block.restBetweenRoundsSeconds ?? 0) s",
                            value: playFormatBinding(.roundRest, for: block.id),
                            in: 0...600, step: 15
                        )
                        .font(.subheadline)
                    }
                    if format == .partner {
                        Picker("Trabajo en equipo", selection: Binding<WorkoutCollaboration>(
                            get: { block.structure?.collaboration ?? .youGoIGo },
                            set: { mode in
                                mutatePlayRoutine { draft in
                                    guard let index = draft.blocks.firstIndex(where: { $0.id == block.id }) else { return }
                                    var structure = draft.blocks[index].structure ?? WorkoutStructure()
                                    structure.collaboration = mode
                                    draft.blocks[index].structure = structure
                                }
                            }
                        )) {
                            Text("Alternando").tag(WorkoutCollaboration.youGoIGo)
                            Text("Sincronizado").tag(WorkoutCollaboration.synchronized)
                            Text("Repeticiones compartidas").tag(WorkoutCollaboration.sharedReps)
                            Text("Juntos").tag(WorkoutCollaboration.together)
                        }
                        .pickerStyle(.menu)
                    }
                    if let structure = block.structure, !structure.summary.isEmpty {
                        Text(structure.summary)
                            .font(.caption)
                            .foregroundStyle(OG.label2)
                            .lineLimit(2)
                    }
                    if ![WODFormat.amrap, .emom, .tabata, .circuit].contains(format) {
                        Toggle("Límite de tiempo", isOn: Binding(
                            get: { block.timeCapMinutes != nil },
                            set: { enabled in
                                mutatePlayRoutine { draft in
                                    guard let index = draft.blocks.firstIndex(where: { $0.id == block.id }) else { return }
                                    draft.blocks[index].timeCapMinutes = enabled
                                        ? (draft.blocks[index].timeCapMinutes ?? 12) : nil
                                    if !enabled { draft.blocks[index].timeCapSeconds = nil }
                                }
                            }
                        ))
                        .tint(OG.accent)
                    }
                }
                Divider().padding(.vertical, 5)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 10, trailing: 16))
        }
    }

    private func inlineWODScoreEditor(
        _ block: WorkoutBlockEntry,
        format: WODFormat,
        session: WorkoutSession
    ) -> some View {
        let existing = session.wodResults.first(where: { $0.id == block.id && $0.format == format })
        let suggested = pendingWODConfirm?.blockId == block.id
            ? pendingWODConfirm?.elapsedSeconds : nil
        let templateID = session.routineBlocks?
            .first(where: { $0.id == block.id })?.wodTemplateId

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "stopwatch")
                    .foregroundStyle(OG.label2)
                Text("Resultado del bloque")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(OG.label)
                Spacer(minLength: 6)
                Text(existing?.summaryLabel ?? "Sin registrar")
                    .font(.system(size: 13, weight: .medium).monospacedDigit())
                    .foregroundStyle(existing == nil ? OG.label3 : OG.accent)
                    .lineLimit(1)
            }
            WODResultInlineEditor(
                blockId: block.id,
                format: format,
                existing: existing,
                suggestedElapsedSeconds: suggested,
                wodTemplateId: templateID,
                resultMetric: session.routineBlocks?
                    .first(where: { $0.id == block.id })?.structure?.resultMetric
            ) { result in
                store.applyWODResult(result)
                if pendingWODConfirm?.blockId == block.id {
                    pendingWODConfirm = nil
                    store.finishCurrentTimedBlock()
                    if store.state.activeSession == nil { closeFlow() }
                }
            }
            .id("\(block.id.uuidString)-\(format.rawValue)")
        }
        .padding(.vertical, 8)
    }

    private func openBlockTimer(_ block: WorkoutBlockEntry, session: WorkoutSession) {
        if runningTimerBlockID == block.id, store.workoutClock.hasStarted {
            store.workoutClock.showClock()
            return
        }
        guard let firstIndex = block.indexes.first else { return }
        if !block.indexes.contains(session.currentIndex) {
            // El onChange detiene el reloj anterior y después abre el solicitado.
            pendingTimerBlockID = block.id
            store.selectExercise(at: firstIndex)
            return
        }
        guard let current = store.state.activeSession?.currentExercise else { return }
        if store.state.activeSession?.phase == .ready {
            store.confirmCurrentOnWatchStyle()
        }
        requestBlockClockStart(for: current)
    }

    /// Las notas se escriben directamente en Play; guardado silencioso y persistente.
    private var inlineWorkoutNotes: some View {
        ZStack(alignment: .topLeading) {
            if notesDraft.isEmpty {
                Text("Cómo te has sentido, molestias, marcas personales…")
                    .font(.system(size: 15))
                    .foregroundStyle(OG.label3)
                    .padding(.top, 14)
                    .padding(.leading, 5)
                    .allowsHitTesting(false)
            }
            TextEditor(text: $notesDraft)
                .font(.system(size: 15))
                .foregroundStyle(OG.label)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 116)
                .opacity(notesDraft.isEmpty ? 0.82 : 1)
                .accessibilityLabel("Notas del entreno")
        }
        .padding(.vertical, 6)
        .task(id: notesDraft) {
                do {
                    try await Task.sleep(for: .milliseconds(400))
                } catch {
                    return
                }
                guard !Task.isCancelled else { return }
                let saved = store.state.activeSession?.notes ?? ""
                if notesDraft.trimmingCharacters(in: .whitespacesAndNewlines) != saved {
                    store.updateActiveSessionNotes(notesDraft)
                }
            }
        .onDisappear {
            store.updateActiveSessionNotes(notesDraft)
        }
    }

    /// Los controles compactos comparten semántica visual con Comenzar:
    /// amarillo al pausar, verde al continuar, bandera negra al finalizar.
    /// El cristal permite reconocer el reloj sobre el resto de Play.
    private var minimizedTimerDock: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { context in
            let clock = store.workoutClock
            HStack(spacing: 10) {
                Button {
                    clock.showClock()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "timer")
                            .font(.title3.bold())
                            .foregroundStyle(OG.accent)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(clock.isIntervalMode
                                 ? "\(clock.subtitle.contains("Descanso") ? "Descanso · " : "")Ronda \(min(clock.displayedRound, clock.displayedRoundsTotal))/\(clock.displayedRoundsTotal)"
                                 : clock.subtitle)
                                .font(.caption)
                                .foregroundStyle(OG.label2)
                                .lineLimit(1)
                            Text(DurationText.format(clock.displaySeconds(at: context.date)))
                                .font(.system(size: 22, weight: .bold).monospacedDigit())
                                .foregroundStyle(OG.label)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Abrir reloj completo")

                Button {
                    clock.finishByUser()
                } label: {
                    let flag = Image(systemName: "flag.checkered")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                    if colorScheme == .dark {
                        // Igual que Finalizar en Comenzar, visible en fondo negro.
                        flag
                            .background(OG.surface2, in: Circle())
                            .glassEffect(.regular.tint(OG.surface2).interactive(), in: .circle)
                    } else {
                        flag.background(.black, in: Circle())
                    }
                }
                .buttonStyle(.plain)
                .disabled(!clock.canFinishByUser)
                .accessibilityLabel("Terminar temporizador")

                Button {
                    clock.handlePrimary()
                } label: {
                    Image(systemName: clock.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 44, height: 44)
                        .background(clock.isRunning ? OG.yellow : OG.accent, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(clock.primaryTitle + " temporizador")
            }
            .padding(12)
            .background {
                Button { clock.showClock() } label: {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.clear)
                        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityHidden(true)
            }
            .glassEffect(.regular, in: .rect(cornerRadius: 18))
        }
    }

    private var restDock: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            let remaining = store.restCoordinator.remainingSeconds
            HStack(spacing: 14) {
                Image(systemName: "timer")
                    .font(.title2.bold())
                    .foregroundStyle(OG.orange)
                    .symbolEffect(.pulse, options: .repeating, isActive: remaining > 0)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Descanso")
                        .font(.caption)
                        .foregroundStyle(OG.label2)
                    Text(DurationText.format(remaining))
                        .font(.system(size: 28, weight: .bold).monospacedDigit())
                        .foregroundStyle(OG.label)
                        .ogNumericText(value: remaining, reduceMotion: reduceMotion)
                }
                Spacer()
                HStack(spacing: 8) {
                    Button("-15") { store.restCoordinator.adjustRemaining(by: -15) }
                    Button("+15") { store.restCoordinator.adjustRemaining(by: 15) }
                    Button("Saltar") { store.restCoordinator.skip() }
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(OG.accentText)
            }
            .padding(16)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 18))
        }
    }

    private func playElapsedSeconds(_ session: WorkoutSession) -> Int {
        guard let start = session.startedAt else { return 0 }
        return max(0, Int(Date().timeIntervalSince(start)))
    }

    private func playTotalSetCount(_ session: WorkoutSession) -> Int {
        session.exercises.reduce(0) { $0 + max($1.plannedSets.count, 1) }
    }

    private func playCompletedSetCount(_ session: WorkoutSession) -> Int {
        StatsEngine.liveWorkSetCount(in: session)
    }

    private func playLiveVolumeKg(_ session: WorkoutSession) -> Double {
        StatsEngine.liveVolumeKg(in: session)
    }

    private func currentCard(_ current: SessionExercise, session: WorkoutSession) -> some View {
        let target = current.plannedSets.first
        let last = store.cachedLastWorkingWeight(for: current.exercise.id)
        let pr = store.cachedPersonalRecords(
            from: store.state.workouts,
            rangeRaw: "all",
            mondayFirst: store.state.settings.weekStartsOn == .monday
        ).first { $0.exerciseName == current.exercise.name }
        return VStack(alignment: .leading, spacing: 18) {
            RecoveryTrainingTip()
            NavigationLink {
                ExerciseDetailView(exerciseId: current.exercise.id)
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(store.catalogTitle(for: current.exercise))
                        .font(.title2.bold())
                        .foregroundStyle(OG.label)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 8) {
                        Text(exerciseMetaLine(current, target: target))
                            .foregroundStyle(OG.label2)
                    }
                    if let wod = wodPlanLabel(for: current) {
                        Text(wod)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(OG.accent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Ver ficha del ejercicio")

            NavigationLink {
                ExerciseDetailView(exerciseId: current.exercise.id)
            } label: {
                ExerciseArtView(exercise: current.exercise, showStepCaptions: true)
                    .frame(maxWidth: .infinity)
                    .clipped()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Ilustración de \(store.catalogTitle(for: current.exercise))")
            .accessibilityHint("Ver ficha del ejercicio")

            HStack(spacing: 8) {
                metaPill("Último", last.map { "\(ReperaNumberFormat.decimal($0)) kg" } ?? "—")
                metaPill("Mejor", pr.map { "\(ReperaNumberFormat.decimal($0.weightKg)) kg" } ?? "—")
                if let target = current.exercise.targetMuscle {
                    metaPill("Músculo", LocalizedMuscle.es(target))
                }
            }
            .frame(maxWidth: .infinity)

            if let reason = store.progressionReasons[current.exercise.id] {
                Label(reason, systemImage: "arrow.up.right.circle")
                    .font(.caption)
                    .foregroundStyle(OG.label2)
            }
            if !isQuickLogSession {
                Toggle(isOn: $usesAutomaticTimer) {
                    Label("Temporizador automático", systemImage: "timer")
                        .font(.system(size: 15, weight: .medium))
                }
                .tint(OG.accent)
                .accessibilityHint("Desactívalo para apuntar peso y repeticiones manualmente")
                if session.phase == .ready {
                    Button {
                        store.confirmCurrentOnWatchStyle()
                        if usesAutomaticTimer {
                            requestBlockClockStart(for: current)
                        }
                    } label: {
                        Text("Comenzar")
                            .font(.system(size: 18, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 64)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(OG.accent)
                    .controlSize(.large)
                } else if !store.workoutClock.isVisible {
                    Button {
                        requestBlockClockStart(for: current)
                    } label: {
                        Label("Abrir reloj", systemImage: "timer")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 52)
                    }
                    .buttonStyle(.bordered)
                    .tint(OG.accent)
                }
            }
        }
        .padding(isQuickLogSession ? 0 : OG.pad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if !isQuickLogSession {
                RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous)
                    .fill(OG.surface)
            }
        }
    }

    private func exerciseMetaLine(_ current: SessionExercise, target: PlannedSet?) -> String {
        let unit = current.quantityUnit ?? current.exercise.defaultQuantityUnit
        if let format = current.wodFormat {
            let amount = target?.targetReps ?? 0
            let quantity = unit == .reps ? "reps" : unit.shortLabel
            let weight = target?.targetWeightKg.map { "\(ReperaNumberFormat.decimal($0)) kg" } ?? "PC"
            return "\(format.displayName) · \(amount) \(quantity) · \(weight)"
        }
        if current.exercise.supportsRepsOrMeters && unit == .meters {
            let sets = current.plannedSets.map { set in
                let weight = set.targetWeightKg.map { " · \(ReperaNumberFormat.decimal($0)) kg" } ?? ""
                return "\(set.targetReps) m\(weight)"
            }.joined(separator: " / ")
            return "\(current.exercise.muscleGroup) · \(sets)"
        }
        return "\(current.exercise.muscleGroup) · \(current.plannedSets.compactSummary)"
    }

    private func wodPlanLabel(for current: SessionExercise) -> String? {
        if let header = current.blockHeader, !header.isEmpty { return header }
        if current.blockKind == .strength || current.wodFormat == nil || current.wodFormat == .strength {
            return current.queueTimeLabel
        }
        guard let format = current.wodFormat else { return current.queueTimeLabel }
        switch format {
        case .emom:
            let mins = current.blockTimeCapMinutes
                ?? current.plannedIntervals
                ?? current.blockRounds
                ?? 10
            let interval = current.blockIntervalSeconds ?? 60
            if interval == 60 {
                return "EMOM \(mins)'"
            }
            return "Every \(interval)s × \(current.plannedIntervals ?? mins)"
        case .amrap:
            return "AMRAP \(current.blockTimeCapMinutes ?? 12)'"
        case .forTime, .chipper, .afap:
            if let cap = current.blockTimeCapMinutes {
                return "\(format.displayName) · TC \(cap)'"
            }
            return format.displayName
        case .tabata:
            let w = current.blockWorkSeconds ?? 20
            let r = current.blockRestSeconds ?? 10
            return "Tabata \(w)/\(r) ×\(current.blockRounds ?? 8)"
        case .deathBy, .ladder, .partner, .buyInCashOut, .roundsForQuality, .circuit, .maxEffort, .strength:
            if let cap = current.blockTimeCapMinutes {
                return "\(format.displayName) · \(cap)'"
            }
            return format.displayName
        }
    }

    private var wodFullscreenClock: some View {
        let clock = store.workoutClock
        let roundDisplay: Int? = clock.isIntervalMode
            ? min(clock.displayedRound, clock.displayedRoundsTotal)
            : nil
        return TimelineView(.periodic(from: .now, by: 0.25)) { context in
            BlockTimerScreen(
                title: clock.title,
                subtitle: clock.isPreCountdown
                    ? "Cuenta atrás"
                    : (clock.isOverTimeCap ? "TC superado · tiempo real" : clock.subtitle),
                exercise: clock.exercise,
                roundNumber: roundDisplay,
                totalRounds: clock.isIntervalMode ? clock.displayedRoundsTotal : nil,
                displaySeconds: clock.displaySeconds(at: context.date),
                isRunning: clock.isRunning,
                isCountingUp: clock.isCountingUp,
                primaryTitle: clock.primaryTitle,
                onPrimary: { clock.handlePrimary() },
                onClose: { clock.minimize() },
                closeSymbol: "chevron.down",
                closeAccessibilityLabel: "Minimizar reloj",
                onFinish: clock.canFinishByUser ? { clock.finishByUser() } : nil,
                showFinish: clock.canFinishByUser
            )
        }
    }

    /// Al acabar un reloj, abrir el score del bloque si corresponde.
    /// EMOM/Tabata y fuerza NO cierran ni inventan series: el atleta registra
    /// sus intervalos y confirma la finalización posteriormente.
    private func presentWODConfirmIfNeeded() {
        guard let (_, elapsed) = store.workoutClock.consumePendingEnd() else { return }
        guard let current = store.state.activeSession?.currentExercise else { return }
        runningTimerBlockID = nil
        if current.wodFormat?.resultCapture == .perMovementSets
            || current.wodFormat == nil {
            finishedTimedBlockID = current.blockId ?? current.id
            return
        }
        presentScoreEditor(for: current, elapsed: elapsed)
    }

    private func presentScoreEditor(for current: SessionExercise, elapsed: Int? = nil) {
        guard let format = current.wodFormat,
              format.resultCapture != .perMovementSets
        else { return }
        let blockID = current.blockId ?? current.id
        let saved = store.state.activeSession?.wodResults.first(where: { $0.id == blockID })
        let templateID = store.state.activeSession?.routineBlocks?
            .first(where: { $0.id == blockID })?.wodTemplateId
        // El editor de resultado ya está siempre visible dentro del bloque.
        pendingWODConfirm = PendingWODConfirm(
            blockId: blockID,
            format: format,
            capture: format.resultCapture,
            totalReps: saved?.totalReps ?? 0,
            elapsedSeconds: elapsed.map { max(1, $0) } ?? saved?.elapsedSeconds ?? 0,
            roundsCompleted: saved?.roundsCompleted ?? 0,
            wodTemplateId: templateID,
            title: current.blockHeader ?? format.displayName
        )
    }

    /// Solo los bloques libres sin duración propia preguntan los segundos
    /// de cada ronda. Los formatos parametrizados (EMOM, Tabata, circuitos,
    /// AMRAP, For Time…) conservan su semántica sin configuraciones extra.
    private func requestBlockClockStart(for current: SessionExercise) {
        let freeFormat = current.wodFormat == nil || current.wodFormat == .strength
        // RoutineBlock crea emomIntervalSeconds=60 incluso en fuerza libre.
        // Ese 60 heredado NO es una prescripción de tiempo por ronda.
        let hasExplicitInterval = (current.blockIntervalSeconds ?? 0) > 0
            && (current.blockIntervalSeconds != 60 || current.wodFormat == .strength)
        let hasPrescribedDuration = (current.blockTimeCapMinutes ?? 0) > 0
            || hasExplicitInterval
            || (current.blockWorkSeconds ?? 0) > 0
        guard freeFormat && !hasPrescribedDuration else {
            startBlockClock(for: current)
            return
        }
        manualRoundMinutes = 1
        manualRoundSeconds = 0
        let rest = max(0, current.blockRestBetweenRoundsSeconds ?? 0)
        manualRoundRestMinutes = rest / 60
        manualRoundRestSeconds = rest % 60
        manualRoundSetup = ManualRoundSetup(
            exerciseID: current.id,
            rounds: prescribedRoundCount(for: current)
        )
    }

    /// Series por ejercicio agrupadas por ronda; no sumar sets de distintos
    /// ejercicios porque forman la MISMA vuelta al bloque.
    private func prescribedRoundCount(for current: SessionExercise) -> Int {
        let block = current.blockId ?? current.id
        let planned = store.state.activeSession?.exercises
            .filter { ($0.blockId ?? $0.id) == block }
            .map { $0.plannedSets.count }.max() ?? current.plannedSets.count
        return max(1, current.blockRounds ?? planned)
    }

    /// Reutiliza los mismos campos y teclado del temporizador de Crear.
    /// Ni un Stepper ni una altura fija: es una sheet Liquid Glass ajustada
    /// a la geometría de su contenido mediante los modificadores OG.
    private func manualRoundDurationSheet(for setup: ManualRoundSetup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Configurar temporizador")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(OG.label)
                Text("Bloque libre · \(setup.rounds) ronda\(setup.rounds == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(OG.label2)
            }
            .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 0) {
                manualRoundTimeRow(
                    title: "Trabajar por ronda",
                    minutes: $manualRoundMinutes,
                    seconds: $manualRoundSeconds,
                    maxMinutes: 120
                )
                Divider()
                    .overlay(OG.surface3)
                    .padding(.vertical, 6)
                manualRoundTimeRow(
                    title: "Descansar entre rondas",
                    minutes: $manualRoundRestMinutes,
                    seconds: $manualRoundRestSeconds,
                    maxMinutes: 10
                )
            }

            Button {
                guard let current = store.state.activeSession?.currentExercise,
                      current.id == setup.exerciseID else {
                    manualRoundSetup = nil
                    return
                }
                let seconds = manualRoundMinutes * 60 + manualRoundSeconds
                guard seconds > 0 else { return }
                confirmedManualRoundStart = ConfirmedManualRoundStart(
                    exerciseID: current.id,
                    durationSeconds: seconds,
                    restSeconds: manualRoundRestMinutes * 60 + manualRoundRestSeconds,
                    rounds: setup.rounds
                )
                manualRoundSetup = nil
            } label: {
                Text("Iniciar temporizador")
                    .font(.system(size: 17, weight: .bold))
                    // El botón verde siempre lleva negro, también en modo noche.
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(OG.accent, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(manualRoundMinutes == 0 && manualRoundSeconds == 0)
            .opacity(manualRoundMinutes == 0 && manualRoundSeconds == 0 ? 0.5 : 1)
        }
        // Intrinsic vertical size: the sheet must fit these rows, not the
        // other way round. UIKit numeric fields already have exact 48 pt.
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, OG.pad)
        .padding(.top, 12)
        .padding(.bottom, 4)
        .ogFittedHeight()
        .ogFittedSheet()
    }

    /// Mismo layout que el formulario de intervalos de Crear:
    /// dos valores editables, teclado propio, sin botones +/-.
    private func manualRoundTimeRow(
        title: String,
        minutes: Binding<Int>,
        seconds: Binding<Int>,
        maxMinutes: Int
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(OG.label)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            HStack(spacing: 8) {
                TimerNumericInput(label: "MIN", value: minutes, range: 0...maxMinutes)
                    .frame(width: 84, height: 64, alignment: .top)
                    .clipped()
                TimerNumericInput(label: "SEG", value: seconds, range: 0...59)
                    .frame(width: 84, height: 64, alignment: .top)
                    .clipped()
            }
            .frame(width: 176, height: 64, alignment: .top)
        }
        // Cota cerrada para TODA la fila, no solo la UITextField interior.
        // Evita que un campo estirado fuerce un detent de pantalla completa.
        .frame(height: 72, alignment: .center)
        .clipped()
    }

    /// Reloj a pantalla completa para cualquier tipo de bloque (EMOM, AMRAP, fuerza…).
    private func startBlockClock(
        for current: SessionExercise,
        manualRoundSeconds: Int? = nil,
        manualRounds: Int? = nil,
        manualRoundRestSeconds: Int? = nil
    ) {
        // Temporizadores con sonido y vibración activados por defecto.
        let sound = true
        let haptic = true
        let format = current.wodFormat
        let subtitleDefault = wodPlanLabel(for: current)
        if format == .emom || format == .tabata || format == .circuit {
            store.restCoordinator.skip()
        }
        runningTimerBlockID = current.blockId ?? current.id
        finishedTimedBlockID = nil

        switch format {
        case .emom:
            let interval = max(1, current.blockIntervalSeconds ?? 60)
            let intervals = max(1, current.plannedIntervals ?? current.blockRounds ?? 10)
            store.workoutClock.configure(
                exercise: current.exercise,
                title: current.blockHeader ?? current.exercise.name,
                subtitle: subtitleDefault ?? "EMOM",
                countingUp: false,
                intervalMode: true,
                intervalLength: interval,
                totalIntervals: intervals,
                initialCountdown: interval,
                sound: sound,
                haptic: haptic
            )
        case .circuit:
            let interval = max(1, current.blockIntervalSeconds ?? 60)
            let stations = max(1, store.state.activeSession?.exercises.filter {
                $0.blockId == current.blockId
            }.count ?? 1)
            let totalWork = max(1,
                (current.blockTimeCapMinutes ?? 0) > 0
                    ? (current.plannedIntervals ?? stations)
                    : stations * max(1, current.blockRounds ?? 1)
            )
            let rest = max(0, current.blockRestBetweenRoundsSeconds ?? 0)
            var durations: [Int] = []
            var phases: [String] = []
            var roundNumbers: [Int] = []
            for workIndex in 0..<totalWork {
                let round = workIndex / stations + 1
                durations.append(interval)
                phases.append("Circuito · estación \(workIndex % stations + 1)/\(stations)")
                roundNumbers.append(round)
                let isRoundEnd = (workIndex + 1).isMultiple(of: stations)
                if isRoundEnd && workIndex + 1 < totalWork && rest > 0 {
                    durations.append(rest)
                    phases.append("Circuito · descanso entre rondas")
                    roundNumbers.append(round)
                }
            }
            store.workoutClock.configure(
                exercise: current.exercise,
                title: current.blockHeader ?? current.exercise.name,
                subtitle: subtitleDefault ?? "Circuito",
                countingUp: false,
                intervalMode: true,
                intervalLength: interval,
                totalIntervals: durations.count,
                initialCountdown: interval,
                customPhaseDurations: durations,
                customPhaseSubtitles: phases,
                customRoundNumbers: roundNumbers,
                customRoundsTotal: (totalWork + stations - 1) / stations,
                sound: sound,
                haptic: haptic
            )
        case .tabata:
            let work = max(1, current.blockWorkSeconds ?? 20)
            let rest = max(1, current.blockRestSeconds ?? 10)
            let rounds = max(1, current.blockRounds ?? 8)
            store.workoutClock.configure(
                exercise: current.exercise,
                title: current.blockHeader ?? current.exercise.name,
                subtitle: "Tabata · trabajo",
                countingUp: false,
                intervalMode: true,
                intervalLength: work,
                totalIntervals: rounds * 2,
                initialCountdown: work,
                tabataWork: work,
                tabataRest: rest,
                sound: sound,
                haptic: haptic
            )
        case .deathBy:
            // Un intervalo por minuto; la persona termina cuando falla la ronda.
            let interval = max(1, current.blockIntervalSeconds ?? 60)
            let intervals = max(1, current.plannedIntervals ?? current.blockTimeCapMinutes ?? 30)
            store.workoutClock.configure(
                exercise: current.exercise,
                title: current.blockHeader ?? current.exercise.name,
                subtitle: "Death By · siguiente ronda",
                countingUp: false,
                intervalMode: true,
                intervalLength: interval,
                totalIntervals: intervals,
                initialCountdown: interval,
                allowEarlyIntervalFinish: true,
                sound: sound,
                haptic: haptic
            )
        case .amrap:
            // Repeated AMRAP: each work period remains separate from its rest,
            // including on the lock screen and when resuming the same session.
            let structure = store.state.activeSession?.routineBlocks?
                .first(where: { $0.id == current.blockId })?.structure
            if let phase = structure?.phases.first(where: {
                $0.kind == .work && ($0.repeatCount ?? 0) > 1 && ($0.workSeconds ?? 0) > 0
            }) {
                let count = min(100, max(1, phase.repeatCount ?? 1))
                let work = max(1, phase.workSeconds ?? 60)
                let rest = max(0, phase.restSeconds ?? 0)
                var durations: [Int] = []
                var labels: [String] = []
                var rounds: [Int] = []
                for index in 1...count {
                    durations.append(work)
                    labels.append("AMRAP \(index)/\(count) · trabajo")
                    rounds.append(index)
                    if index < count && rest > 0 {
                        durations.append(rest)
                        labels.append("Descanso · AMRAP \(index)/\(count)")
                        rounds.append(index)
                    }
                }
                store.workoutClock.configure(
                    exercise: current.exercise,
                    title: current.blockHeader ?? current.exercise.name,
                    subtitle: "AMRAP por intervalos",
                    countingUp: false,
                    intervalMode: true,
                    intervalLength: work,
                    totalIntervals: durations.count,
                    initialCountdown: work,
                    customPhaseDurations: durations,
                    customPhaseSubtitles: labels,
                    customRoundNumbers: rounds,
                    customRoundsTotal: count,
                    sound: sound,
                    haptic: haptic
                )
            } else {
                let seconds = max(1, current.blockTimeCapSeconds ?? (current.blockTimeCapMinutes ?? 12) * 60)
                store.workoutClock.configure(
                    exercise: current.exercise,
                    title: current.blockHeader ?? current.exercise.name,
                    subtitle: subtitleDefault ?? "AMRAP",
                    countingUp: false,
                    intervalMode: false,
                    intervalLength: seconds,
                    totalIntervals: 0,
                    initialCountdown: seconds,
                    sound: sound,
                    haptic: haptic
                )
            }
        case .maxEffort:
            let seconds = max(1, current.blockTimeCapSeconds ?? (current.blockTimeCapMinutes ?? 12) * 60)
            store.workoutClock.configure(
                exercise: current.exercise,
                title: current.blockHeader ?? current.exercise.name,
                subtitle: subtitleDefault ?? "Max Effort",
                countingUp: false,
                intervalMode: false,
                intervalLength: seconds,
                totalIntervals: 0,
                initialCountdown: seconds,
                sound: sound,
                haptic: haptic
            )
        case .forTime, .chipper, .afap, .ladder, .buyInCashOut:
            // TC es informativo; el cronómetro sigue hasta pulsar Terminar.
            store.workoutClock.configure(
                exercise: current.exercise,
                title: current.blockHeader ?? current.exercise.name,
                subtitle: subtitleDefault ?? format?.displayName ?? "For Time",
                countingUp: true,
                intervalMode: false,
                intervalLength: 0,
                totalIntervals: 0,
                initialCountdown: 0,
                timeCapSeconds: current.blockTimeCapSeconds ?? current.blockTimeCapMinutes.map { max(1, $0) * 60 },
                sound: sound,
                haptic: haptic
            )
        case .partner, .roundsForQuality, .strength, .none:
            // La duración explícita del formato tiene prioridad absoluta:
            // no volver a preguntar ni sustituirla por un valor por defecto.
            let explicitInterval = current.blockIntervalSeconds == 60
                && current.wodFormat == nil
                ? nil : current.blockIntervalSeconds
            if let roundDuration = manualRoundSeconds
                ?? current.blockWorkSeconds ?? explicitInterval,
               roundDuration > 0 {
                let rounds = manualRounds ?? prescribedRoundCount(for: current)
                let rest = max(0, manualRoundRestSeconds
                    ?? current.blockRestBetweenRoundsSeconds ?? 0)
                var phaseDurations: [Int] = []
                var phaseLabels: [String] = []
                var phaseRoundNumbers: [Int] = []
                for round in 1...rounds {
                    phaseDurations.append(roundDuration)
                    phaseLabels.append("Ronda \(round) · trabajo")
                    phaseRoundNumbers.append(round)
                    if round < rounds && rest > 0 {
                        phaseDurations.append(rest)
                        phaseLabels.append("Descanso entre rondas")
                        phaseRoundNumbers.append(round)
                    }
                }
                store.workoutClock.configure(
                    exercise: current.exercise,
                    title: current.blockHeader ?? current.exercise.name,
                    subtitle: current.blockHeader ?? "Ronda de fuerza",
                    countingUp: false,
                    intervalMode: true,
                    intervalLength: roundDuration,
                    totalIntervals: phaseDurations.count,
                    initialCountdown: roundDuration,
                    customPhaseDurations: phaseDurations,
                    customPhaseSubtitles: phaseLabels,
                    customRoundNumbers: phaseRoundNumbers,
                    customRoundsTotal: rounds,
                    allowEarlyIntervalFinish: true,
                    sound: sound,
                    haptic: haptic
                )
            } else if let minutes = current.blockTimeCapMinutes, minutes > 0 {
                let seconds = minutes * 60
                store.workoutClock.configure(
                    exercise: current.exercise,
                    title: current.blockHeader ?? current.exercise.name,
                    subtitle: subtitleDefault ?? format?.displayName ?? "Fuerza",
                    countingUp: false,
                    intervalMode: false,
                    intervalLength: seconds,
                    totalIntervals: 0,
                    initialCountdown: seconds,
                    sound: sound,
                    haptic: haptic
                )
            } else {
                store.workoutClock.configure(
                    exercise: current.exercise,
                    title: current.blockHeader ?? current.exercise.name,
                    subtitle: subtitleDefault ?? format?.displayName ?? "Bloque libre",
                    countingUp: true,
                    intervalMode: false,
                    intervalLength: 0,
                    totalIntervals: 0,
                    initialCountdown: 0,
                    sound: sound,
                    haptic: haptic
                )
            }
        }
        if let sessionID = store.state.activeSession?.id,
           let blockID = runningTimerBlockID {
            store.workoutClock.bindSession(sessionID: sessionID, blockID: blockID)
        }
        store.workoutClock.handlePrimary()
    }

    private func metaPill(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(OG.label3)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(OG.label)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 10))
    }

    private func logForm(_ current: SessionExercise) -> some View {
        let unit = store.state.settings.effortUnit
        return VStack(alignment: .leading, spacing: 18) {
            Text("Calentamiento, drops, rest-pause…")
                .font(.caption)
                .foregroundStyle(OG.label2)

            Picker("Fase", selection: $setPhase) {
                ForEach(SetPhase.allCases, id: \.self) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.segmented)

            Picker("Tipo", selection: $setKind) {
                ForEach(SetKind.allCases, id: \.self) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.segmented)

            HStack(alignment: .bottom, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Peso (\(store.state.settings.weightUnit.label))").font(.caption).foregroundStyle(OG.label2)
                    OGRepeatStepper(
                        display: weightText.isEmpty ? "—" : weightText,
                        keyboard: .decimalPad,
                        onMinus: { bumpWeight(-store.state.settings.weightUnit.displayValue(fromKilograms: store.state.settings.weightIncrementKg)) },
                        onPlus: { bumpWeight(store.state.settings.weightUnit.displayValue(fromKilograms: store.state.settings.weightIncrementKg)) },
                        onCommitText: { text in
                            let normalized = text
                            weightText = normalized
                        }
                    )
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Reps").font(.caption).foregroundStyle(OG.label2)
                    OGRepeatStepper(
                        display: repsText.isEmpty ? "0" : repsText,
                        keyboard: .numberPad,
                        onMinus: { bumpReps(-1) },
                        onPlus: { bumpReps(1) },
                        onCommitText: { text in
                            if let value = Int(text), value >= 0 {
                                repsText = "\(value)"
                            }
                        }
                    )
                }
                .frame(maxWidth: .infinity)

                Button {
                    saveSet(for: current)
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(OG.accent)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Registrar serie")
                .padding(.bottom, 2)
            }
            .buttonStyle(.plain)
            .foregroundStyle(OG.label)

            if setPhase == .work {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Registrar \(unit.displayName)", isOn: $logEffort)
                    if logEffort {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(unit.displayName) \(ReperaNumberFormat.decimal(effortValue, maximumFractionDigits: 0)) · \(Effort.plainLanguage(rir: Effort.toRIR(value: effortValue, unit: unit)))")
                                .font(.caption)
                                .foregroundStyle(OG.label2)
                            Slider(
                                value: $effortValue,
                                in: unit == .rir ? 0...5 : 5...10,
                                step: 1
                            )
                        }
                    }
                    Toggle("Al fallo", isOn: $toFailure)
                }
            }

            if setKind == .dropset {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Drops")
                        .font(.subheadline.bold())
                    ForEach(pendingDrops) { drop in
                        Text("→ \(drop.weightKg.map { ReperaNumberFormat.decimal($0) } ?? "—") kg × \(drop.reps)")
                            .font(.caption.monospacedDigit())
                    }
                    HStack(spacing: 10) {
                        OGNumericTextField(
                            text: $dropWeightText,
                            allowsDecimal: true,
                            autoFocus: false,
                            isFocused: advancedFocusedField == OGSetFieldID(rowID: advancedFieldRowID, column: 0),
                            submitTitle: "Siguiente",
                            focusIdentifier: OGSetFieldID(rowID: advancedFieldRowID, column: 0).accessibilityKey,
                            nextFocusIdentifier: OGSetFieldID(rowID: advancedFieldRowID, column: 1).accessibilityKey,
                            onFocused: { advancedFocusedField = OGSetFieldID(rowID: advancedFieldRowID, column: 0) },
                            onFocusLost: { if advancedFocusedField?.column == 0 { advancedFocusedField = nil } },
                            onCommit: { advancedFocusedField = OGSetFieldID(rowID: advancedFieldRowID, column: 1) }
                        )
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 11))
                        OGNumericTextField(
                            text: $dropRepsText,
                            allowsDecimal: false,
                            autoFocus: false,
                            isFocused: advancedFocusedField == OGSetFieldID(rowID: advancedFieldRowID, column: 1),
                            submitTitle: "✓",
                            focusIdentifier: OGSetFieldID(rowID: advancedFieldRowID, column: 1).accessibilityKey,
                            onFocused: { advancedFocusedField = OGSetFieldID(rowID: advancedFieldRowID, column: 1) },
                            onFocusLost: { if advancedFocusedField?.column == 1 { advancedFocusedField = nil } },
                            onCommit: { advancedFocusedField = nil }
                        )
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 11))

                        Button("Añadir") {
                            let reps = Int(dropRepsText) ?? 0
                            let w = ReperaNumberFormat.parse(dropWeightText)
                            guard reps > 0 else { return }
                            pendingDrops.append(DropSegment(reps: reps, weightKg: w))
                            dropRepsText = ""
                        }
                    }
                }
            }

            if setKind == .restpause {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Clusters (myo / rest-pause)")
                        .font(.subheadline.bold())
                    Text("Las reps totales = suma de clusters. El peso es el de la serie.")
                        .font(.caption2)
                        .foregroundStyle(OG.label2)
                    ForEach(Array(pendingClusters.enumerated()), id: \.element.id) { idx, cluster in
                        Text("\(idx + 1). \(cluster.reps) reps · descanso \(cluster.restSeconds) s")
                            .font(.caption.monospacedDigit())
                    }

                    HStack(alignment: .bottom, spacing: 12) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("REPS")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(OG.label3)
                            OGNumericTextField(
                                text: $clusterRepsText,
                                allowsDecimal: false,
                                autoFocus: false,
                                isFocused: advancedFocusedField == OGSetFieldID(rowID: advancedFieldRowID, column: 2),
                                submitTitle: "✓",
                                onFocused: { advancedFocusedField = OGSetFieldID(rowID: advancedFieldRowID, column: 2) },
                                onFocusLost: { if advancedFocusedField?.column == 2 { advancedFocusedField = nil } },
                                onCommit: { advancedFocusedField = nil }
                            )
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .background(OG.surface2, in: RoundedRectangle(cornerRadius: 11))
                            .accessibilityLabel("Repeticiones del cluster")
                        }
                        .frame(maxWidth: .infinity)

                        VStack(alignment: .leading, spacing: 5) {
                            Text("DESCANSO")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(OG.label3)
                            HStack(spacing: 4) {
                                OGNumericTextField(
                                    text: $clusterRestText,
                                    allowsDecimal: false,
                                    autoFocus: false,
                                    onCommit: {}
                                )
                                .frame(maxWidth: .infinity, minHeight: 46)
                                Text("s")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(OG.label2)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            .padding(.horizontal, 10)
                            .background(OG.surface2, in: RoundedRectangle(cornerRadius: 11))
                            .accessibilityLabel("Descanso del cluster en segundos")
                        }
                        .frame(maxWidth: .infinity)
                    }

                    Button {
                        let reps = Int(clusterRepsText) ?? 0
                        let seconds = Int(clusterRestText) ?? 0
                        guard reps > 0, (5...30).contains(seconds) else { return }
                        pendingClusters.append(RestPauseCluster(reps: reps, restSeconds: seconds))
                        clusterRepsText = ""
                    } label: {
                        Label("Añadir cluster", systemImage: "plus")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(OG.accent)
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled((Int(clusterRepsText) ?? 0) <= 0
                        || !(5...30).contains(Int(clusterRestText) ?? 0))
                }
            }
        }
        // La sección List ya aplica sus márgenes y el fondo blanco.
        // Evitar otra caja con padding lateral que estreche los controles.
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func loggedList(_ current: SessionExercise) -> some View {
        let unit = store.state.settings.effortUnit
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Historial del ejercicio")
                    .font(.headline)
                Spacer()
                Text("\(current.loggedSets.count)")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(OG.label2)
                    .ogNumericText(value: current.loggedSets.count, reduceMotion: reduceMotion)
            }

            if current.loggedSets.isEmpty {
                Text("Aún no has registrado ninguna serie. Ajusta peso/reps y pulsa ✓.")
                    .font(.subheadline)
                    .foregroundStyle(OG.label2)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(current.loggedSets.enumerated()), id: \.element.id) { idx, set in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(setLabel(index: idx + 1, set: set))
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(OG.label)
                                Spacer(minLength: 8)
                                Text("\(set.weightKg.map { ReperaNumberFormat.decimal(store.state.settings.weightUnit.displayValue(fromKilograms: $0)) } ?? "—") \(store.state.settings.weightUnit.label) × \(set.reps)")
                                    .font(.system(size: 15, weight: .medium).monospacedDigit())
                                    .foregroundStyle(OG.accent)
                                    .ogNumericText(
                                        value: "\(set.weightKg.map(String.init(describing:)) ?? "")-\(set.reps)",
                                        reduceMotion: reduceMotion
                                    )
                            }
                            if let effort = Effort.label(rir: set.rir, unit: unit) {
                                Text(effort)
                                    .font(.caption)
                                    .foregroundStyle(OG.label2)
                            }
                            ForEach(set.drops) { drop in
                                Text("Drop \(drop.weightKg.map { ReperaNumberFormat.decimal($0) } ?? "—") × \(drop.reps)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(OG.label2)
                            }
                            if !set.clusters.isEmpty {
                                Text("RP: " + set.clusters.map { "\($0.reps)" }.joined(separator: "+"))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(OG.label2)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .contextMenu {
                            if idx == current.loggedSets.count - 1 {
                                Button("Quitar última serie", role: .destructive) {
                                    store.removeLastSet()
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(OG.pad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }

    private func setLabel(index: Int, set: LoggedSet) -> String {
        var parts = ["Serie \(index)"]
        if set.isWarmup { parts.append("WU") }
        switch set.kind {
        case .dropset: parts.append("Drop")
        case .restpause: parts.append("RP")
        case .straight: break
        }
        if set.toFailure { parts.append("F") }
        return parts.joined(separator: " · ")
    }

    private func saveSet(for current: SessionExercise) {
        let weight = ReperaNumberFormat.parse(weightText).map {
            store.state.settings.weightUnit.kilograms(fromDisplayValue: $0)
        }
        let clusters = setKind == .restpause ? pendingClusters : []
        let drops = setKind == .dropset ? pendingDrops : []
        let reps: Int = {
            if setKind == .restpause, !clusters.isEmpty {
                return clusters.reduce(0) { $0 + $1.reps }
            }
            return Int(repsText) ?? 0
        }()
        guard reps > 0 else { return }
        let unit = store.state.settings.effortUnit
        let rir: Double? = {
            if setPhase == .warmup { return nil }
            if toFailure { return 0 }
            guard logEffort else { return nil }
            return Effort.toRIR(value: effortValue, unit: unit)
        }()
        store.logSet(
            reps: reps,
            weightKg: weight,
            phase: setPhase,
            kind: setKind,
            rir: rir,
            toFailure: toFailure && setPhase == .work,
            drops: drops,
            clusters: clusters
        )
        let rest: Int = {
            if setPhase == .warmup { return 45 }
            if setKind == .dropset { return 20 }
            if setKind == .restpause { return max(45, store.state.settings.defaultRestSeconds / 2) }
            return store.state.settings.defaultRestSeconds
        }()
        if shouldStartIndependentRest(for: current) {
            beginRest(rest)
        }
        pendingDrops = []
        pendingClusters = []
        dropWeightText = ""
        dropRepsText = ""
        clusterRepsText = ""
        if setPhase == .warmup {
            setPhase = .work
        }
        bumpWeightSuggestion(current)
    }

    private struct QueueBlockSection: Identifiable {
        let id: String
        let header: String
        let timeLabel: String?
        let items: [(index: Int, exercise: SessionExercise)]
    }

    private func queueBlocks(for session: WorkoutSession) -> [QueueBlockSection] {
        var sections: [QueueBlockSection] = []
        var currentKey: String?
        var currentHeader = "Plan"
        var currentTime: String?
        var currentItems: [(Int, SessionExercise)] = []

        func flush() {
            guard !currentItems.isEmpty else { return }
            sections.append(
                QueueBlockSection(
                    id: currentKey ?? "block-\(sections.count)",
                    header: currentHeader,
                    timeLabel: currentTime,
                    items: currentItems
                )
            )
            currentItems = []
        }

        for (index, item) in session.exercises.enumerated() {
            // Agrupar ejercicios consecutivos del mismo bloque del plan.
            let groupKey = item.blockId?.uuidString
                ?? "flat-\(item.blockHeader ?? "")-\(item.wodFormat?.rawValue ?? "strength")"
            if currentKey != groupKey {
                flush()
                currentKey = groupKey
                if let header = item.blockHeader, !header.isEmpty {
                    currentHeader = header
                } else if item.blockKind == .strength {
                    currentHeader = "Fuerza"
                } else if let format = item.wodFormat {
                    currentHeader = format.displayName
                } else {
                    currentHeader = "Bloque"
                }
                let showBlockTime = item.blockKind == .wod
                    || (item.wodFormat != nil && item.wodFormat != .strength)
                currentTime = showBlockTime ? item.queueTimeLabel : nil
            }
            currentItems.append((index, item))
        }
        flush()
        return sections
    }

    private func exerciseQueue(_ session: WorkoutSession) -> some View {
        let blocks = queueBlocks(for: session)
        return VStack(alignment: .leading, spacing: 16) {
            Text("Cola del plan")
                .font(.headline)

            ForEach(blocks) { block in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(block.header)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(OG.accent)
                        Spacer(minLength: 8)
                        if let time = block.timeLabel {
                            Text(time)
                                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                                .foregroundStyle(OG.label2)
                        }
                    }

                    VStack(spacing: 8) {
                        ForEach(block.items, id: \.exercise.id) { pair in
                            let index = pair.index
                            let item = pair.exercise
                            HStack(spacing: 10) {
                                Button {
                                    exerciseDetailID = item.exercise.id
                                } label: {
                                    HStack(spacing: 12) {
                                        ExerciseThumb(exercise: item.exercise, size: 48)
                                        VStack(alignment: .leading, spacing: 3) {
                                            HStack(spacing: 6) {
                                                Text(store.catalogTitle(for: item.exercise))
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundStyle(OG.label)
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.leading)
                                            }
                                            Text(queueRowSubtitle(item))
                                                .font(.system(size: 12))
                                                .foregroundStyle(OG.label3)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Ver ficha del ejercicio")

                                Button {
                                    store.selectExercise(at: index)
                                } label: {
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Image(systemName: item.isCompleted
                                              ? "checkmark.circle.fill"
                                              : (index == session.currentIndex ? "circle.inset.filled" : "circle"))
                                            .foregroundStyle(
                                                item.isCompleted || index == session.currentIndex
                                                ? OG.accent : OG.label3
                                            )
                                        Text(item.queueTimeLabel)
                                            .font(.system(size: 11, weight: .semibold).monospacedDigit())
                                            .foregroundStyle(OG.label2)
                                        if item.blockKind != .wod {
                                            Text("\(item.loggedSets.count)/\(max(item.plannedSets.count, 1))")
                                                .font(.system(size: 11).monospacedDigit())
                                                .foregroundStyle(OG.label3)
                                                .ogNumericText(
                                                    value: item.loggedSets.count,
                                                    reduceMotion: reduceMotion
                                                )
                                        }
                                    }
                                    .frame(minWidth: 44)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Seleccionar ejercicio")
                            }
                            .padding(10)
                            .background(
                                index == session.currentIndex ? OG.surface3 : OG.surface2,
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                        }
                    }
                }
                .padding(OG.pad)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func queueRowSubtitle(_ item: SessionExercise) -> String {
        if let format = item.wodFormat, format != .strength, item.blockKind == .wod {
            let reps = item.plannedSets.first?.targetReps
            let weight = item.plannedSets.first?.targetWeightKg
            var parts: [String] = []
            if let reps { parts.append("\(reps) reps") }
            if let weight { parts.append("\(ReperaNumberFormat.decimal(weight)) kg") }
            if parts.isEmpty { return format.displayName }
            return parts.joined(separator: " · ")
        }
        return item.plannedSets.compactSummary
    }

    private func prefill() {
        guard let current = store.state.activeSession?.currentExercise else { return }
        // Fuerza: registro manual y pesos visibles; WOD cronometrado: reloj por defecto.
        usesAutomaticTimer = (current.wodFormat != nil && current.wodFormat != .strength)
            || (current.blockTimeCapMinutes ?? 0) > 0
        // Las series prescritas de una plantilla siempre mandan sobre
        // los últimos kilos anotados. La sugerencia histórica solo se usa
        // cuando el entreno NO tiene series configuradas.
        let hasPrescription = !current.plannedSets.isEmpty
        let suggested = hasPrescription
            ? current.plannedSets.first?.targetWeightKg
            : (current.lastLoggedWeight
                ?? store.cachedLastWorkingWeight(for: current.exercise.id))
        weightText = suggested.map {
            ReperaNumberFormat.decimal(store.state.settings.weightUnit.displayValue(fromKilograms: $0))
        } ?? ""
        repsText = "\(current.plannedSets.first?.targetReps ?? 8)"
    }

    private func bumpWeightSuggestion(_ current: SessionExercise) {
        if weightText.isEmpty {
            weightText = current.lastLoggedWeight.map {
                ReperaNumberFormat.decimal(store.state.settings.weightUnit.displayValue(fromKilograms: $0))
            } ?? weightText
        }
    }

    private func bumpWeight(_ delta: Double) {
        let current = ReperaNumberFormat.parse(weightText) ?? 0
        let next = max(0, current + delta)
        weightText = ReperaNumberFormat.decimal(next)
    }

    private func bumpReps(_ delta: Int) {
        let current = Int(repsText) ?? 0
        repsText = "\(max(0, current + delta))"
    }

    /// En EMOM/Tabata/Circuito el descanso ya lo gestiona el reloj del bloque.
    /// No iniciar el descanso genérico por cada check, que taparía el intervalo real.
    private func shouldStartIndependentRest(for current: SessionExercise) -> Bool {
        current.wodFormat == nil
            || current.wodFormat == .strength
            || current.wodFormat == .roundsForQuality
    }

    private func beginRest(_ seconds: Int) {
        let exerciseName = store.state.activeSession?.currentExercise?.exercise.name
        store.restCoordinator.start(
            seconds: seconds,
            exerciseName: exerciseName,
            sound: true,
            haptic: true
        )
    }
}

// Mantener este editor en WorkoutView: también debe compilar con proyectos
// Xcode ya generados, sin que el usuario tenga que volver a incluir fuentes.
/// Editor del resultado en la propia pantalla Play; comparte el modelo de datos
/// de la edición del entrenamiento y no crea una segunda ruta modal.
struct WODResultInlineEditor: View {
    let blockId: UUID
    let format: WODFormat
    let existing: WODBlockResult?
    let suggestedElapsedSeconds: Int?
    let wodTemplateId: String?
    let resultMetric: WorkoutResultMetric?
    let onSave: (WODBlockResult) -> Void

    @State private var roundsText: String
    @State private var repsText: String
    @State private var timeText: String
    @State private var metricText: String
    @State private var scoreMetric: WorkoutResultMetric
    @State private var hasEditedResult = false
    /// 0 unknown, 1 RX, 2 scaled. A legacy result never defaults to RX.
    @State private var rxSelection: Int
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case rounds, reps, time, metric
    }

    init(
        blockId: UUID,
        format: WODFormat,
        existing: WODBlockResult?,
        suggestedElapsedSeconds: Int? = nil,
        wodTemplateId: String? = nil,
        resultMetric: WorkoutResultMetric? = nil,
        onSave: @escaping (WODBlockResult) -> Void
    ) {
        self.blockId = blockId
        self.format = format
        self.existing = existing
        self.suggestedElapsedSeconds = suggestedElapsedSeconds
        self.wodTemplateId = wodTemplateId
        self.resultMetric = resultMetric
        _scoreMetric = State(initialValue: existing?.measuredMetric ?? resultMetric ?? .totalReps)
        _metricText = State(initialValue: existing?.measuredValue.map(String.init) ?? "")
        self.onSave = onSave
        _rxSelection = State(initialValue: existing?.isRx.map { $0 ? 1 : 2 } ?? 0)
        _roundsText = State(initialValue: String(existing?.roundsCompleted ?? 0))
        _repsText = State(initialValue: String(existing?.totalReps ?? 0))
        _timeText = State(initialValue: DurationText.format(
            existing?.elapsedSeconds ?? suggestedElapsedSeconds ?? 0
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if format == .maxEffort {
                Picker("Tipo de marca", selection: $scoreMetric) {
                    Text("Reps").tag(WorkoutResultMetric.totalReps)
                    Text("Carga (kg)").tag(WorkoutResultMetric.loadKg)
                    Text("Calorías").tag(WorkoutResultMetric.calories)
                    Text("Distancia").tag(WorkoutResultMetric.distanceMeters)
                    Text("Tiempo").tag(WorkoutResultMetric.elapsedSeconds)
                }
                .pickerStyle(.menu)
            }
            if isMeasuredMaxEffort {
                numericField(metricLabel, text: $metricText, field: .metric)
            } else if format == .maxEffort && scoreMetric == .elapsedSeconds {
                numericField("Tiempo · m:ss", text: $timeText, field: .time)
            } else if format.resultCapture == .totalReps {
                if format == .amrap || format == .deathBy {
                    HStack(spacing: 10) {
                        numericField("Rondas completas", text: $roundsText, field: .rounds)
                        numericField("Reps adicionales", text: $repsText, field: .reps)
                    }
                } else {
                    numericField("Repeticiones", text: $repsText, field: .reps)
                }
            } else if format.resultCapture == .elapsedTime {
                numericField("Tiempo · m:ss", text: $timeText, field: .time)
            }

            Picker("Modalidad del resultado", selection: $rxSelection) {
                Text("Sin indicar").tag(0)
                Text("RX").tag(1)
                Text("Escalado").tag(2)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Modalidad del WOD para comparar marcas")
        }
        .onChange(of: rxSelection) { _, _ in hasEditedResult = true }
        .onChange(of: roundsText) { _, _ in hasEditedResult = true }
        .onChange(of: repsText) { _, _ in hasEditedResult = true }
        .onChange(of: timeText) { _, _ in hasEditedResult = true }
        .onChange(of: metricText) { _, _ in hasEditedResult = true }
        .onChange(of: scoreMetric) { _, _ in hasEditedResult = true }
        .task(id: "\(roundsText)|\(repsText)|\(timeText)|\(metricText)|\(scoreMetric.rawValue)|\(rxSelection)") {
            guard hasEditedResult else { return }
            do {
                try await Task.sleep(for: .milliseconds(350))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            saveValidResult()
        }
        .onDisappear {
            // Si el usuario sale antes del debounce, guardar la última edición válida.
            if hasEditedResult { saveValidResult() }
        }
        .onChange(of: suggestedElapsedSeconds) { _, seconds in
            // Reloj For Time: conservar cualquier registro previo y solo
            // proponer el tiempo recién medido cuando no había resultado.
            guard existing?.elapsedSeconds == nil, let seconds, seconds > 0 else { return }
            timeText = DurationText.format(seconds)
        }
    }

    /// Los cambios válidos se persisten sin un segundo check ni botón Guardar.
    private func saveValidResult() {
        guard canSave else { return }
        onSave(WODBlockResult(
            id: blockId,
            format: format,
            totalReps: format.resultCapture == .totalReps && !isMeasuredMaxEffort &&
                !(format == .maxEffort && scoreMetric == .elapsedSeconds)
                ? min(5000, max(0, Int(repsText) ?? 0)) : nil,
            elapsedSeconds: format.resultCapture == .elapsedTime ||
                (format == .maxEffort && scoreMetric == .elapsedSeconds)
                ? min(180 * 60, max(1, DurationText.parse(timeText) ?? 0)) : nil,
            roundsCompleted: format == .amrap || format == .deathBy
                ? min(200, max(0, Int(roundsText) ?? 0)) : nil,
            wodTemplateId: wodTemplateId ?? existing?.wodTemplateId,
            isRx: rxSelection == 0 ? nil : (rxSelection == 1),
            measuredValue: isMeasuredMaxEffort ? parsedMeasurement : nil,
            measuredMetric: isMeasuredMaxEffort ? scoreMetric : nil
        ))
    }

    private func numericField(
        _ label: String,
        text: Binding<String>,
        field: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(OG.label3)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            TextField("0", text: text)
                .keyboardType(field == .time ? .numbersAndPunctuation :
                    field == .metric ? .decimalPad : .numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 21, weight: .medium).monospacedDigit())
                .foregroundStyle(OG.label)
                .focused($focusedField, equals: field)
                .frame(minHeight: 44)
                .background(OG.surface2, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                .accessibilityLabel(label)
        }
        .frame(maxWidth: .infinity)
    }

    private var isMeasuredMaxEffort: Bool {
        format == .maxEffort && [.loadKg, .calories, .distanceMeters].contains(scoreMetric)
    }

    private var metricLabel: String {
        switch scoreMetric {
        case .loadKg: return "Carga máxima (kg)"
        case .calories: return "Calorías máximas"
        case .distanceMeters: return "Distancia (m)"
        default: return "Marca"
        }
    }

    private var parsedMeasurement: Double? {
        Double(metricText.replacingOccurrences(of: ",", with: "."))
    }

    private var canSave: Bool {
        if isMeasuredMaxEffort {
            guard let value = parsedMeasurement, value.isFinite else { return false }
            return value > 0 && value <= 50_000
        }
        if format == .maxEffort && scoreMetric == .elapsedSeconds {
            guard let seconds = DurationText.parse(timeText) else { return false }
            return seconds > 0 && seconds <= 180 * 60
        }
        switch format.resultCapture {
        case .totalReps:
            let reps = Int(repsText) ?? 0
            let rounds = Int(roundsText) ?? 0
            return reps >= 0 && reps <= 5000
                && (format == .amrap || format == .deathBy
                    ? rounds >= 0 && rounds <= 200 && (rounds > 0 || reps > 0)
                    : reps > 0)
        case .elapsedTime:
            guard let seconds = DurationText.parse(timeText) else { return false }
            return seconds > 0 && seconds <= 180 * 60
        case .perMovementSets:
            return false
        }
    }
}


// Swipe de serie en ScrollView: .swipeActions solo funciona en filas List.
// Mantenemos los TextField interactivos y revelamos borrar al deslizar a la izquierda.

private struct PlayEditableSetsView: View {
    @Environment(ReperaStore.self) private var store
    let exerciseEntry: SessionExercise
    var registerFlusher: ((@escaping () -> Void) -> Void)? = nil
    var onUndoSetDelete: ((String, @escaping () -> Void) -> Void)? = nil
    var onSetMarkedComplete: (() -> Void)? = nil

    private struct Row: Identifiable {
        let id: UUID
        var weightKg: Double?
        var deficitCm: Int?
        var durationSeconds: Int?
        var reps: Int
        var rir: Double?
    }

    @State private var rows: [Row]
    @State private var quantityUnit: ExerciseQuantityUnit
    @State private var dirty = false
    @State private var flushTask: Task<Void, Never>?
    @State private var previousSummaryByIndex: [Int: String] = [:]
    @State private var previousSetsByIndex: [Int: ExerciseLastSession.WorkSet] = [:]
    @Binding var openedSetID: UUID?
    @FocusState private var focus: OGSetFieldID?

    init(
        exerciseEntry: SessionExercise,
        registerFlusher: ((@escaping () -> Void) -> Void)? = nil,
        openedSetID: Binding<UUID?>,
        onUndoSetDelete: ((String, @escaping () -> Void) -> Void)? = nil,
        onSetMarkedComplete: (() -> Void)? = nil
    ) {
        self.exerciseEntry = exerciseEntry
        self.registerFlusher = registerFlusher
        self.onUndoSetDelete = onUndoSetDelete
        self.onSetMarkedComplete = onSetMarkedComplete
        _openedSetID = openedSetID
        // Filas desde el 1.er frame: sembrar en onAppear hacía saltar la altura del List.
        _rows = State(initialValue: Self.makeRows(from: exerciseEntry))
        _quantityUnit = State(
            initialValue: exerciseEntry.quantityUnit ?? exerciseEntry.exercise.defaultQuantityUnit
        )
    }

    private static func makeRows(from entry: SessionExercise) -> [Row] {
        let exercise = entry.exercise
        let prescribed = entry.plannedSets
        let recorded = entry.loggedSets
        let prescribedIDs = Set(prescribed.map(\.id))
        let legacyIndexFallback = !recorded.contains(where: { prescribedIDs.contains($0.id) })
        var rows = prescribed.enumerated().map { index, set -> Row in
            let result = recorded.first(where: { $0.id == set.id })
                ?? (legacyIndexFallback && recorded.indices.contains(index) ? recorded[index] : nil)
            return Row(
                id: result?.id ?? set.id,
                weightKg: result?.weightKg ?? set.targetWeightKg,
                deficitCm: result?.deficitCm ?? (exercise.loadField == .deficitCm
                    ? set.targetWeightKg.map { Int($0.rounded()) } : nil),
                durationSeconds: result?.durationSeconds ?? set.targetDurationSeconds,
                reps: result?.reps ?? set.targetReps,
                rir: result?.rir ?? set.targetRir
            )
        }
        if rows.isEmpty {
            rows = recorded.map {
                Row(id: $0.id, weightKg: $0.weightKg, deficitCm: $0.deficitCm,
                    durationSeconds: $0.durationSeconds, reps: $0.reps, rir: $0.rir)
            }
        }
        return rows
    }

    private var exercise: Exercise { exerciseEntry.exercise }
    private var style: ExerciseLoggingStyle { exercise.loggingStyle }
    private var quantityLabel: String {
        style == .machineWork || exercise.supportsRepsOrMeters
            ? quantityUnit.shortLabel : exercise.quantityFieldLabel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if exercise.supportsRepsOrMeters ||
                (style == .machineWork && exercise.allowsCalorieOrDistanceToggle) {
                Picker("Unidad", selection: $quantityUnit) {
                    if exercise.supportsRepsOrMeters {
                        Text("Repeticiones").tag(ExerciseQuantityUnit.reps)
                    } else {
                        Text("Calorías").tag(ExerciseQuantityUnit.calories)
                    }
                    Text("Metros").tag(ExerciseQuantityUnit.meters)
                }
                .pickerStyle(.segmented)
                .onChange(of: quantityUnit) { _, value in
                    let current = store.state.activeSession?.exercises.first(where: { $0.id == exerciseEntry.id })
                    guard value != (current?.quantityUnit ?? exercise.defaultQuantityUnit) else { return }
                    schedulePersist(immediate: true)
                }
            }
            OGSetEntryHeader(
                firstTitle: style == .repsOnly ? quantityLabel
                    : (style == .loadAndReps
                        ? (exercise.loadField == .deficitCm ? "Déficit" : store.state.settings.weightUnit.label.uppercased()) : "Tiempo"),
                secondTitle: style == .repsOnly || exercise.isMobilityHold ? nil : quantityLabel,
                showsConfirmation: false,
                showsRIR: style.usesRIR
            )
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                OGSetSwipeDeleteRow(
                    canDelete: true,
                    setID: row.id,
                    openedSetID: $openedSetID,
                    onDelete: {
                        guard rows.indices.contains(index) else { return }
                        let removed = rows[index]
                        rows.remove(at: index)
                        schedulePersist(immediate: true)
                        onUndoSetDelete?("Serie \(index + 1) eliminada") {
                            let insertAt = min(index, rows.count)
                            rows.insert(removed, at: insertAt)
                            schedulePersist(immediate: true)
                        }
                    }
                ) {
                    rowEditor(index: index, row: row)
                }
            }
            WorkoutInlineAddButton("Añadir serie", systemImage: "plus") {
                guard rows.count < 20 else { return }
                let last = rows.last
                rows.append(Row(
                    id: UUID(), weightKg: last?.weightKg, deficitCm: last?.deficitCm,
                    durationSeconds: last?.durationSeconds, reps: last?.reps ?? 8,
                    rir: last?.rir
                ))
                schedulePersist(immediate: true)
            }
        }
        .padding(.vertical, 6)
        .onAppear {
            hydratePreviousSummariesIfNeeded()
            registerFlusher?({ flushPersist() })
        }
        .onChange(of: focus) { _, newFocus in
            // Al cerrar teclado, volcar el borrador que se aplazó por foco activo.
            if newFocus == nil { flushPersist(pushWatch: false) }
        }
        .onDisappear {
            flushPersist()
            registerFlusher?({})
        }
    }

    private func rowEditor(index: Int, row: Row) -> some View {
        let previousText = previousSummaryByIndex[index] ?? "—"
        let firstValue: String = {
            switch style {
            case .repsOnly: return String(row.reps)
            case .loadAndReps:
                if exercise.loadField == .deficitCm { return row.deficitCm.map(String.init) ?? "0" }
                return row.weightKg.map {
                    ReperaNumberFormat.decimal(store.state.settings.weightUnit.displayValue(fromKilograms: $0))
                } ?? "—"
            case .repsAndTime, .machineWork: return DurationText.format(row.durationSeconds)
            }
        }()
        return OGSetEntryRow(
            rowID: row.id,
            index: index + 1,
            previous: previousText,
            firstValue: firstValue,
            secondValue: style == .repsOnly || exercise.isMobilityHold ? nil : String(row.reps),
            nextEditableRowID: rows.dropFirst(index + 1).first?.id,
            firstAllowsDecimal: style == .loadAndReps && exercise.loadField == .weightKg,
            showsConfirmation: false,
            completed: false,
            isCurrentRow: isCurrentPlayRow(index: index, row: row),
            indexTappable: false,
            onCopyPrevious: { copyPreviousValues(into: index) },
            keypadSetSubtitle: "Serie \(index + 1)",
            rir: row.rir,
            showsRIR: style.usesRIR,
            onRIRChange: { value in
                guard rows.indices.contains(index) else { return }
                rows[index].rir = value
                schedulePersist(immediate: true)
            },
            focus: $focus,
            onFirstCommit: { text in
                guard rows.indices.contains(index) else { return }
                switch style {
                case .repsOnly:
                    if let value = Int(text), value > 0 { rows[index].reps = value }
                case .loadAndReps:
                    if exercise.loadField == .deficitCm {
                        if let value = Int(text) { rows[index].deficitCm = min(60, max(0, value)) }
                    } else {
                        let value = ReperaNumberFormat.parse(text) ?? 0
                        let kg = store.state.settings.weightUnit.kilograms(fromDisplayValue: value)
                        rows[index].weightKg = value > 0 ? ((kg * 10).rounded() / 10) : nil
                    }
                case .repsAndTime, .machineWork:
                    rows[index].durationSeconds = DurationText.parse(text)
                }
                schedulePersist(immediate: false)
            },
            onSecondCommit: { text in
                guard rows.indices.contains(index) else { return }
                if let value = Int(text), value > 0 {
                    rows[index].reps = value
                    schedulePersist(immediate: false)
                }
            },
            onConfirm: {
                maybeStartRestAfterEditing(row: rows[index])
            }
        )
    }

    private func isCurrentPlayRow(index: Int, row: Row) -> Bool {
        // @FocusState proyecta el valor opcional, no un Binding.
        if let focused = focus, focused.rowID == row.id { return true }
        guard let first = rows.indices.first else { return false }
        return first == index
    }

    private func copyPreviousValues(into index: Int) {
        guard rows.indices.contains(index) else { return }
        guard let prev = previousSetsByIndex[index] else { return }
        if let kg = prev.weightKg, kg > 0 {
            rows[index].weightKg = kg
        }
        if prev.reps > 0 {
            rows[index].reps = prev.reps
        }
        if let duration = prev.durationSeconds, duration > 0 {
            rows[index].durationSeconds = duration
        }
        if let rir = prev.rir {
            rows[index].rir = rir
        }
        schedulePersist(immediate: true)
    }

    private func maybeStartRestAfterEditing(row: Row) {
        guard row.reps > 0 else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onSetMarkedComplete?()
    }

    /// Solo textos «Anterior» (misma altura de fila; no reescribe `rows`).
    private func hydratePreviousSummariesIfNeeded() {
        guard previousSummaryByIndex.isEmpty else { return }
        let previous = store.cachedLastWorkingSession(for: exercise.id)?.sets
        var summaries: [Int: String] = [:]
        if let previous {
            for index in previous.indices {
                summaries[index] = OGSetEntryRow.previousText(previous[index])
                previousSetsByIndex[index] = previous[index]
            }
        }
        previousSummaryByIndex = summaries
    }

    /// Teclas → debounce local (sin Watch). Añadir/borrar/confirmar → flush + Watch.
    /// Con foco activo no se escribe al store: invalidar el List puede tirar el teclado.
    private func schedulePersist(immediate: Bool) {
        dirty = true
        flushTask?.cancel()
        if immediate {
            flushPersist(pushWatch: true)
            return
        }
        flushTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            if focus != nil { return }
            flushPersist(pushWatch: false)
        }
    }

    private func flushPersist(pushWatch: Bool = true) {
        flushTask?.cancel()
        flushTask = nil
        guard dirty else { return }
        dirty = false
        persistToStore(pushWatch: pushWatch)
    }

    /// Borrador en `plannedSets` y valores visibles en `loggedSets` (sin checks).
    private func persistToStore(pushWatch: Bool) {
        guard let current = store.state.activeSession?.exercises.first(where: { $0.id == exerciseEntry.id }) else { return }
        let prescribed = current.plannedSets
        let savedByID = Dictionary(uniqueKeysWithValues: current.loggedSets.map { ($0.id, $0) })
        let revised: [PlannedSet] = rows.enumerated().map { index, row in
            let previous = prescribed.first(where: { $0.id == row.id })
                ?? (prescribed.indices.contains(index) ? prescribed[index] : nil)
            let kg = exercise.loadField == .deficitCm ? row.deficitCm.map(Double.init) : row.weightKg
            let changedLoad = kg != previous?.targetWeightKg
            return PlannedSet(
                id: row.id, targetReps: max(1, row.reps), targetWeightKg: kg,
                targetDurationSeconds: row.durationSeconds, targetRir: row.rir,
                targetPercent1RM: changedLoad ? nil : previous?.targetPercent1RM,
                targetPercent1RMIsMinimum: !changedLoad && (previous?.targetPercent1RMIsMinimum ?? false)
            )
        }
        let unit = (style == .machineWork || exercise.supportsRepsOrMeters)
            ? quantityUnit : (current.quantityUnit ?? exercise.defaultQuantityUnit)
        let recorded: [LoggedSet] = rows.compactMap { row in
            guard row.reps > 0 else { return nil }
            var result = savedByID[row.id] ?? LoggedSet(id: row.id, reps: row.reps, quantityUnit: unit)
            result.reps = max(1, row.reps)
            result.weightKg = exercise.loadField == .weightKg ? row.weightKg : nil
            result.deficitCm = exercise.loadField == .deficitCm ? row.deficitCm : nil
            result.durationSeconds = style.usesDuration ? row.durationSeconds : nil
            result.quantityUnit = unit
            result.rir = style.usesRIR ? row.rir : nil
            result.toFailure = style.usesRIR && row.rir == 0
            return result
        }
        store.updateActiveExerciseDraft(
            id: current.id, plannedSets: revised,
            quantityUnit: unit, performedSets: recorded,
            durable: true, pushWatch: pushWatch
        )
    }
}
