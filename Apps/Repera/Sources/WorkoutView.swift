import ReperaDomain
import SwiftUI
import UIKit

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
    @State private var showPlayRoutinePicker = false
    @State private var showsPlayReorder = false
    @State private var playReorderError: String?
    @State private var playReorderDraft: Routine?
    @State private var confirmCancelWorkout = false
    @State private var createFreeMovementForBlock: UUID?
    @State private var openedSetID: UUID?
    @State private var notesDraft = ""
    @State private var favoriteSaveError: String?
    @State private var isSavingFavorite = false
    /// Filas editables: escribir es guardar; no hay check de confirmación por serie.
    @State private var liveSets: [LiveSetRow] = []
    /// Los borradores pertenecen al ejercicio, no a la fila que se reutiliza al navegar.
    @State private var liveExerciseID: UUID?
    @State private var liveSessionID: UUID?
    @State private var liveDraftsByExercise: [UUID: [LiveSetRow]] = [:]
    /// No convertir las sugerencias precargadas en modificaciones del usuario.
    @State private var editedLiveExerciseIDs: Set<UUID> = []
    /// Unidad Cal/m para erg/bike del ejercicio actual.
    @State private var liveQuantityUnit: ExerciseQuantityUnit = .reps
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

    private struct LiveSetRow: Identifiable, Equatable {
        let id: UUID
        var weightKg: Double?
        var deficitCm: Int?
        var durationSeconds: Int?
        var reps: Int
        var rir: Double?
        var completed: Bool
    }

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
            persistActiveLiveDraft()
            cacheLiveSets()
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
        .onChange(of: store.state.activeSession?.currentExercise?.plannedSets) { _, _ in
            if let current = store.state.activeSession?.currentExercise {
                rebuildLiveSets(from: current)
            }
        }
        .onChange(of: store.state.activeSession?.currentExercise?.quantityUnit) { _, _ in
            if let current = store.state.activeSession?.currentExercise {
                syncLiveQuantityUnit(from: current)
            }
        }
        .onChange(of: store.workoutClock.pendingEndReason) { _, reason in
            guard reason != nil else { return }
            presentWODConfirmIfNeeded()
        }
        .onDisappear {
            // Rest + WOD clocks are owned by ReperaStore — do not stop on view disappear.
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            store.workoutClock.syncFromWallClock()
        }
    }

    private var workoutDialogsView: some View {
        workoutSecondaryNavigationView
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
                    liveDraftsByExercise = [:]
                    editedLiveExerciseIDs = []
                    liveExerciseID = nil
                    liveSets = []
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
                CloseToolbarButton(action: { closeFlow() }, large: false)
                    .foregroundStyle(OG.label2)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        persistActiveLiveDraft()
                        editingRoutine = routineForEditing()
                    } label: {
                        Label("Editar entreno", systemImage: "pencil")
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
            // iOS 27 agrupa acciones contiguas en una única cápsula.
            // Las flechas son neutras e independientes del check verde.
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            if let index = store.state.activeSession?.currentIndex, index > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.selectExercise(at: index - 1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .accessibilityLabel("Ejercicio anterior")
                    .tint(OG.label)
                }
            }
            if let index = store.state.activeSession?.currentIndex, hasMoreExercises {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Navegar no finaliza ni inventa resultados del ejercicio.
                        store.selectExercise(at: index + 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .accessibilityLabel("Ejercicio siguiente")
                    .tint(OG.label)
                }
            } else {
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        persistActiveLiveDraft()
                        store.updateActiveSessionNotes(notesDraft)
                        store.workoutClock.stop()
                        store.endActiveSession(save: true)
                        closeFlow()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(OG.onAccent)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(OG.accent)
                    .accessibilityLabel("Terminar entreno")
                }
            }
    }

    private var workoutPresentationView: some View {
        workoutCoreView
        .animation(reduceMotion ? nil : .snappy, value: store.restCoordinator.isActive)
        .sensoryFeedback(.success, trigger: setCompletionPulse)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: restStartedPulse)
        .background(OG.bg)
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
        persistActiveLiveDraft()
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
        persistActiveLiveDraft()
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
        persistActiveLiveDraft()
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

    private var playReorderSheet: some View {
        ScrollView {
            if let draft = playReorderDraft {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(draft.blocks.enumerated()), id: \.element.id) { position, block in
                        Color.clear.frame(height: 10)
                        playReorderBlockBox(position: position, block: block)
                    }
                    Color.clear.frame(height: 10)
                }
                .reorderContainer(for: OGReorderEntry.self, in: String.self) { difference in
                    withAnimation(.smooth) {
                        applyNativePlayReorder(difference)
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
                Button("Listo") { showsPlayReorder = false }
                    .fontWeight(.semibold)
                    .tint(OG.accent)
            }
        }
        .onDisappear(perform: commitPlayReorder)
    }

    private func applyNativePlayReorder(_ difference: ReorderDifference<UUID, String>) {
        guard let draft = playReorderDraft else { return }
        let before: UUID?
        switch difference.destination.position {
        case .before(let anchor): before = anchor
        case .end: before = nil
        }
        if difference.destination.collectionID == "blocks" {
            let sourceIDs = Set(difference.sources)
            let moved = draft.blocks.filter { sourceIDs.contains($0.id) }
            guard !moved.isEmpty else { return }
            editPlayReorderDraft { draft in
                draft.blocks.removeAll { sourceIDs.contains($0.id) }
                let destination = before.flatMap { anchor in
                    draft.blocks.firstIndex(where: { $0.id == anchor })
                } ?? draft.blocks.count
                draft.blocks.insert(contentsOf: moved, at: destination)
            }
            return
        }
        guard let targetID = UUID(uuidString: difference.destination.collectionID),
              draft.blocks.contains(where: { $0.id == targetID }) else { return }
        for id in difference.sources {
            guard let current = playReorderDraft,
                  let source = current.blocks.first(where: {
                      $0.exercises.contains(where: { $0.id == id })
                          || $0.movements.contains(where: { $0.id == id })
                  }) else { continue }
            _ = movePlayReorderToken("\(source.id.uuidString):\(id.uuidString)",
                                     into: targetID, before: before)
        }
    }

    /// Una caja por bloque: cabecera + ejercicios con divider (mismo UI).
    private func playReorderBlockBox(position: Int, block: RoutineBlock) -> some View {
        let rows = playReorderRows(block)
        return VStack(alignment: .leading, spacing: 0) {
            ForEach([OGReorderEntry(id: block.id, name: block.title, type: "block")]) { _ in
                playReorderBlockHeader(position: position, block: block)
                    .contentShape(Rectangle())
            }
            .reorderable(collectionID: "blocks")

            // La sesión activa comparte el mismo destino identificable para
            // bloques vacíos: el hueco es ancho y recibe drops reales.
            ForEach(rows.isEmpty ? [OGReorderEntry.emptyDropTarget(for: block.id)] : rows) { row in
                if row.type == "emptyDropTarget" {
                    Text("Soltar ejercicio")
                        .font(.caption)
                        .foregroundStyle(OG.label3)
                        .frame(maxWidth: .infinity, minHeight: 104)
                        .contentShape(Rectangle())
                        .padding(.bottom, 8)
                } else {
                    VStack(spacing: 0) {
                        Divider()
                            .overlay(OG.label3.opacity(0.22))
                            .padding(.leading, 14)
                        playReorderRow(
                            name: row.name, blockID: block.id, itemID: row.id, kind: block.kind
                        )
                    }
                }
            }
            .reorderable(collectionID: block.id.uuidString)
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
                Text(block.wodFormat?.displayName ?? (block.kind == .strength ? "Fuerza" : "Libre"))
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
                    name: SportExerciseNames.localizedDisplayName(raw),
                    type: "exercise"
                )
            }
        }
        return block.movements.map {
            OGReorderEntry(
                id: $0.id,
                name: $0.isRest ? "Descanso" : SportExerciseNames.localizedDisplayName($0.name),
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
        movePlayReorderItem(sourceItem, from: from, into: blockID, before: itemID)
        return true
    }

    private func movePlayReorderItem(
        _ itemID: UUID, from sourceID: UUID, into targetID: UUID, before nextID: UUID? = nil
    ) {
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
        }
    }

    private func playReorderRow(
        name: String, blockID: UUID, itemID: UUID, kind: RoutineBlockKind
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: kind == .strength ? "dumbbell" : "figure.strengthtraining.functional")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(OG.accent)
                .frame(width: 32, height: 32)
                .background(OG.surface2, in: RoundedRectangle(cornerRadius: 9))
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
    }

    private func movePlayBlock(_ blockID: UUID, offset: Int) {
        mutatePlayRoutine { routine in
            guard let old = routine.blocks.firstIndex(where: { $0.id == blockID }),
                  routine.blocks.indices.contains(old + offset) else { return }
            let block = routine.blocks.remove(at: old)
            routine.blocks.insert(block, at: old + offset)
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
        mutatePlayRoutine { routine in
            guard let index = routine.blocks.firstIndex(where: { $0.id == blockID }) else { return }
            if routine.blocks[index].kind == .strength {
                routine.blocks[index].exercises.removeAll { $0.id == itemID }
            } else {
                routine.blocks[index].movements.removeAll { $0.id == itemID }
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
        if let saved = session.routineBlocks, !saved.isEmpty {
            return saved.map { block in
                WorkoutBlockEntry(
                    id: block.id, title: block.title, format: block.wodFormat,
                    indexes: session.exercises.enumerated().compactMap { index, item in
                        item.blockId == block.id ? index : nil
                    }
                )
            }
        }
        var blocks: [WorkoutBlockEntry] = []
        for (index, exercise) in session.exercises.enumerated() {
            let id = exercise.blockId ?? exercise.id
            if let lastIndex = blocks.indices.last, blocks[lastIndex].id == id {
                blocks[lastIndex].indexes.append(index)
            } else {
                blocks.append(
                    WorkoutBlockEntry(
                        id: id,
                        title: exercise.blockHeader ?? "Bloque \(blocks.count + 1)",
                        format: exercise.wodFormat,
                        indexes: [index]
                    )
                )
            }
        }
        return blocks
    }

    private func content(_ session: WorkoutSession) -> some View {
        List {
            ForEach(workoutBlocks(session)) { block in
                Section {
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
                                removePlayBlock(block.id)
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

                    playBlockFormatSettings(block)
                        .listRowBackground(OG.surface)
                        .listRowSeparator(.hidden)
                    if let format = block.format, format.resultCapture != .perMovementSets {
                        inlineWODScoreEditor(block, format: format, session: session)
                            .listRowBackground(OG.surface)
                    }

                    ForEach(block.indexes, id: \.self) { index in
                        let entry = session.exercises[index]
                        HStack(spacing: 4) {
                            Button {
                                exerciseDetailID = entry.exercise.id
                            } label: {
                                workoutExerciseRow(
                                    entry, isOpen: true,
                                    blockResult: session.wodResults.first(where: { $0.id == block.id && $0.format == block.format })
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Ver ficha del ejercicio")
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

                        PlayEditableSetsView(exerciseEntry: entry, openedSetID: $openedSetID)
                            .id(entry.id)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(OG.surface)
                            .listRowSeparator(.hidden)
                    }

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

                    WorkoutWODInsertActions(
                        onExercise: { addPlayExerciseToBlock = block.id },
                        onRest: { insertPlayRest(after: block.id) },
                        onFreeMovement: { beginPlayFreeMovement(after: block.id) }
                    )
                } header: {
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

            Section {
                Button("Añadir bloque", systemImage: "square.stack.3d.up") {
                    mutatePlayRoutine { draft in
                        draft.blocks.append(.strength(title: "Bloque \(draft.blocks.count + 1)"))
                    }
                }
                Button("Elegir WOD", systemImage: "list.bullet.rectangle.portrait") {
                    showPlayWODCatalog = true
                }
                if store.favoriteRoutines.contains(where: { !$0.blocks.isEmpty })
                    || !store.state.favoriteTimers.isEmpty {
                    Button("Añadir favorito", systemImage: "star") {
                        showPlayRoutinePicker = true
                    }
                }
            }

            Section {
                // Mapa a bleed (clear + insets 0); sin lugar → tarjeta blanca «Añadir lugar».
                let hasChosenPlace = store.state.activeSession?.locationPin?.hasChosenPlace == true
                WorkoutPlacePickerRow(pin: activeLocationPin)
                    .listRowInsets(hasChosenPlace ? EdgeInsets() : EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    .listRowBackground(hasChosenPlace ? Color.clear : OG.surface)
            } header: {
                Text("Lugar")
            }

            Section("Notas del entreno") {
                inlineWorkoutNotes
            }
        }
        .listStyle(.insetGrouped)
        .ogListChrome()
        .task(id: session.id) {
            while !Task.isCancelled, store.state.activeSession?.id == session.id {
                await HealthKitStore.shared.refreshLiveMetrics()
                try? await Task.sleep(for: .seconds(15))
            }
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
                Text(SportExerciseNames.localizedDisplayName(entry.exercise.name))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(OG.label)
                Text(entry.plannedSets.compactSummary)
                    .font(.caption)
                    .foregroundStyle(OG.label2)
                if !entry.loggedSets.isEmpty {
                    Text("Registrado · " + entry.loggedSets.map(\.displaySummaryLine).joined(separator: " · "))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(OG.accent)
                        .lineLimit(2)
                } else if let blockResult, entry.usesBlockScoreResult {
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

    private func playFormatFields(_ block: RoutineBlock) -> [PlayFormatField] {
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

    private func playFormatBinding(_ field: PlayFormatField, for blockID: UUID) -> Binding<Int> {
        Binding(
            get: {
                guard let block = store.state.activeSession?.routineBlocks?
                    .first(where: { $0.id == blockID })
                    ?? routineForEditing()?.blocks.first(where: { $0.id == blockID })
                else { return 0 }
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
                mutatePlayRoutine { draft in
                    guard let index = draft.blocks.firstIndex(where: { $0.id == blockID }) else { return }
                    switch field {
                    case .duration: draft.blocks[index].timeCapMinutes = value
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
                    if ![WODFormat.amrap, .emom, .tabata, .circuit].contains(format) {
                        Toggle("Límite de tiempo", isOn: Binding(
                            get: { block.timeCapMinutes != nil },
                            set: { enabled in
                                mutatePlayRoutine { draft in
                                    guard let index = draft.blocks.firstIndex(where: { $0.id == block.id }) else { return }
                                    draft.blocks[index].timeCapMinutes = enabled
                                        ? (draft.blocks[index].timeCapMinutes ?? 12) : nil
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
                wodTemplateId: templateID
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

    private func setsBoard(_ current: SessionExercise) -> some View {
        let style = current.exercise.loggingStyle
        let qtyLabel = style == .machineWork || current.exercise.supportsRepsOrMeters
            ? liveQuantityUnit.shortLabel : current.exercise.quantityFieldLabel
        let loadLabel = current.exercise.loadField == .deficitCm
            ? "Déficit cm"
            : (style == .loadAndReps ? store.state.settings.weightUnit.label.uppercased() : "Tiempo")
        return VStack(alignment: .leading, spacing: 12) {
            OGSetEntryHeader(
                firstTitle: style == .repsOnly ? qtyLabel : loadLabel,
                secondTitle: style == .repsOnly || current.exercise.isMobilityHold ? nil : qtyLabel,
                showsConfirmation: false,
                showsRIR: style.usesRIR
            )

            ForEach(Array(liveSets.enumerated()), id: \.element.id) { index, row in
                OGSetSwipeDeleteRow(
                    canDelete: true, setID: row.id, openedSetID: $openedSetID,
                    onDelete: { removeLiveSet(at: index, current: current) }
                ) {
                    liveSetRow(index: index, row: row, current: current)
                }
            }

            WorkoutInlineAddButton("Serie", systemImage: "plus.circle.fill") {
                addLiveSet(from: current)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func liveSetRow(index: Int, row: LiveSetRow, current: SessionExercise) -> some View {
        let style = current.exercise.loggingStyle
        let qtyLabel = style == .machineWork || current.exercise.supportsRepsOrMeters
            ? liveQuantityUnit.shortLabel : current.exercise.quantityFieldLabel
        let previous = store.cachedLastWorkingSession(for: current.exercise.id)?.sets
        let previousSet = (previous?.indices.contains(index) == true) ? previous?[index] : nil
        let firstValue: String = {
            switch style {
            case .repsOnly: return "\(row.reps)"
            case .loadAndReps:
                if current.exercise.loadField == .deficitCm {
                    return row.deficitCm.map(String.init) ?? "0"
                }
                return row.weightKg.map {
                    ReperaNumberFormat.decimal(store.state.settings.weightUnit.displayValue(fromKilograms: $0))
                } ?? "—"
            case .repsAndTime, .machineWork: return DurationText.format(row.durationSeconds)
            }
        }()

        return VStack(alignment: .leading, spacing: 6) {
            if index == 0,
               current.exercise.supportsRepsOrMeters
                   || (style == .machineWork && current.exercise.allowsCalorieOrDistanceToggle) {
                Picker("Unidad", selection: Binding(
                    get: { liveQuantityUnit },
                    set: { newValue in
                        liveQuantityUnit = newValue
                        noteLiveDraftEdited()
                    }
                )) {
                    if current.exercise.supportsRepsOrMeters {
                        Text("Repeticiones").tag(ExerciseQuantityUnit.reps)
                    } else {
                        Text("Cal").tag(ExerciseQuantityUnit.calories)
                    }
                    Text("Metros").tag(ExerciseQuantityUnit.meters)
                }
                .pickerStyle(.segmented)

            }

            OGSetEntryRow(
                rowID: row.id,
                index: index + 1,
                previous: OGSetEntryRow.previousText(previousSet),
                firstValue: firstValue,
                secondValue: style == .repsOnly || current.exercise.isMobilityHold ? nil : "\(row.reps)",
                nextEditableRowID: liveSets.dropFirst(index + 1).first?.id,
                firstAllowsDecimal: style != .repsOnly && current.exercise.loadField == .weightKg,
                showsConfirmation: false,
                completed: row.completed,
                rir: row.rir,
                showsRIR: style.usesRIR,
                onRIRChange: { setLiveRir(at: index, rir: $0) },
                focus: $focusedSetField,
                onFirstCommit: { text in
                    switch style {
                    case .repsOnly:
                        if let value = Int(text), value > 0 { setLiveReps(at: index, reps: value) }
                    case .loadAndReps:
                        if current.exercise.loadField == .deficitCm {
                            if let value = Int(text) { setLiveDeficit(at: index, cm: min(60, max(0, value))) }
                        } else {
                            commitLiveWeightText(at: index, text: text)
                        }
                    case .repsAndTime, .machineWork:
                        commitLiveDurationText(at: index, text: text)
                    }
                },
                onSecondCommit: { text in
                    if let value = Int(text), value > 0 { setLiveReps(at: index, reps: value) }
                },
                onConfirm: { toggleLiveSetCompleted(at: index, current: current) }

            )
            .accessibilityLabel("Serie \(index + 1), \(qtyLabel)")


        }
        .padding(.vertical, 3)
    }

    private func cacheLiveSets() {
        guard let liveExerciseID else { return }
        liveDraftsByExercise[liveExerciseID] = liveSets
    }

    /// Prescripción inicial editable. Tras la primera interacción, los valores
    /// de esas filas son el resultado registrado; se pueden corregir sin check.
    private func noteLiveDraftEdited() {
        guard let id = liveExerciseID else { return }
        editedLiveExerciseIDs.insert(id)
        persistActiveLiveDraft()
    }

    private func persistActiveLiveDraft() {
        guard let id = liveExerciseID, editedLiveExerciseIDs.contains(id),
              liveSessionID == store.state.activeSession?.id,
              let entry = store.state.activeSession?.exercises.first(where: { $0.id == id }) else { return }
        let existing = entry.plannedSets
        let revised: [PlannedSet] = liveSets.enumerated().map { index, row in
            let previous = existing.indices.contains(index) ? existing[index] : nil
            let kg = entry.exercise.loadField == .deficitCm
                ? row.deficitCm.map(Double.init) : row.weightKg
            let changedAbsoluteLoad = entry.exercise.loadField == .weightKg
                && kg != previous?.targetWeightKg
            return PlannedSet(
                // La identidad de una serie pendiente sobrevive incluso
                // cuando se elimina la anterior o se reordena el ejercicio.
                id: row.completed ? (previous?.id ?? row.id) : row.id,
                targetReps: max(1, row.reps),
                targetWeightKg: kg,
                targetDurationSeconds: row.durationSeconds,
                targetRir: row.rir,
                // Escribir kg reales deja de ser una prescripción porcentual.
                targetPercent1RM: changedAbsoluteLoad ? nil : previous?.targetPercent1RM,
                targetPercent1RMIsMinimum: !changedAbsoluteLoad
                    && (previous?.targetPercent1RMIsMinimum ?? false)
            )
        }
        let existingByID = Dictionary(
            uniqueKeysWithValues: entry.loggedSets.map { ($0.id, $0) }
        )
        let style = entry.exercise.loggingStyle
        let recorded: [LoggedSet] = liveSets.compactMap { row in
            guard row.reps > 0 else { return nil }
            let recordedWeight = entry.exercise.loadField == .weightKg ? row.weightKg : nil
            let recordedDeficit = entry.exercise.loadField == .deficitCm ? row.deficitCm : nil
            let unit = style == .machineWork || entry.exercise.supportsRepsOrMeters
                ? liveQuantityUnit : (entry.quantityUnit ?? entry.exercise.defaultQuantityUnit)
            var result = existingByID[row.id] ?? LoggedSet(
                id: row.id, reps: row.reps, quantityUnit: unit
            )
            result.reps = row.reps
            result.weightKg = recordedWeight
            result.deficitCm = recordedDeficit
            result.durationSeconds = style.usesDuration ? row.durationSeconds : nil
            result.quantityUnit = unit
            result.rir = style.usesRIR ? row.rir : nil
            result.toFailure = style.usesRIR && row.rir == 0
            return result
        }
        store.updateActiveExerciseDraft(
            id: id, plannedSets: revised,
            quantityUnit: style == .machineWork || entry.exercise.supportsRepsOrMeters
                ? liveQuantityUnit : entry.quantityUnit,
            performedSets: recorded
        )
    }

    private func removeLiveSet(at index: Int, current: SessionExercise) {
        // El usuario corrige o elimina la serie sin un check previo.
        // Al persistir se sustituyen también los resultados reales por ID.
        guard liveSets.indices.contains(index) else { return }
        liveSets.remove(at: index)
        liveDraftsByExercise[current.id] = liveSets
        noteLiveDraftEdited()
    }

    private func rebuildLiveSets(from current: SessionExercise) {
        // Los observers de currentIndex/plannedSets pueden ejecutarse en distinto
        // orden. Guardar aquí la tabla anterior antes de sustituir su identidad.
        if let liveExerciseID, liveExerciseID != current.id {
            cacheLiveSets()
        }
        syncLiveQuantityUnit(from: current)
        // Reconciliar los registros confirmados con los borradores aún editables.
        // Una reconstrucción (check, cambio de plan, navegación) nunca debe
        // volver a copiar el objetivo y borrar lo que el usuario ya escribió.
        let retained: [LiveSetRow] = liveExerciseID == current.id
            ? liveSets
            : (liveDraftsByExercise[current.id] ?? [])
        liveExerciseID = current.id

        var rows: [LiveSetRow] = []
        let planned = current.plannedSets
        let logged = current.loggedSets
        let total = max(planned.count, max(logged.count, retained.count))
        let style = current.exercise.loggingStyle
        let defaultQty: Int = {
            switch style {
            case .machineWork: return liveQuantityUnit == .meters ? 500 : 15
            case .repsAndTime: return current.exercise.isMobility ? (current.exercise.isMobilityHold ? 1 : 8) : 50
            default: return 8
            }
        }()

        let loadField = current.exercise.loadField
        for i in 0..<total {
            if i < logged.count {
                let set = logged[i]
                rows.append(LiveSetRow(
                    id: set.id,
                    weightKg: set.weightKg,
                    deficitCm: set.deficitCm,
                    durationSeconds: set.durationSeconds,
                    reps: set.reps,
                    rir: set.rir,
                    completed: true
                ))
            } else if i < retained.count {
                // Incluye la serie recién desmarcada: conserva sus valores
                // registrados, pero pasa a estado editable.
                let old = retained[i]
                rows.append(LiveSetRow(
                    id: i < planned.count ? planned[i].id : old.id,
                    weightKg: old.weightKg,
                    deficitCm: old.deficitCm,
                    durationSeconds: old.durationSeconds,
                    reps: old.reps,
                    rir: old.rir,
                    completed: old.completed
                ))
            } else if i < planned.count {
                let plannedSet = planned[i]
                rows.append(LiveSetRow(
                    id: plannedSet.id,
                    weightKg: loadField == .weightKg ? plannedSet.targetWeightKg : nil,
                    deficitCm: loadField == .deficitCm
                        ? plannedSet.targetWeightKg.map { Int($0.rounded()) } ?? 0 : nil,
                    durationSeconds: style.usesDuration
                        ? (plannedSet.targetDurationSeconds ?? (current.exercise.isMobilityHold ? 30 : 60)) : nil,
                    reps: current.exercise.isMobilityHold ? 1 : max(1, plannedSet.targetReps),
                    rir: plannedSet.targetRir,
                    completed: false
                ))
            } else {
                rows.append(LiveSetRow(
                    id: UUID(),
                    weightKg: nil,
                    deficitCm: loadField == .deficitCm ? 0 : nil,
                    durationSeconds: style.usesDuration ? (current.exercise.isMobilityHold ? 30 : 60) : nil,
                    reps: defaultQty,
                    rir: nil,
                    completed: false
                ))
            }
        }
        liveSets = rows
    }

    private func syncLiveQuantityUnit(from current: SessionExercise) {
        if let configured = current.quantityUnit {
            liveQuantityUnit = configured
        } else if let unit = current.loggedSets.compactMap(\.quantityUnit).last {
            liveQuantityUnit = unit
        } else {
            liveQuantityUnit = current.exercise.defaultQuantityUnit
        }
    }

    private func addLiveSet(from current: SessionExercise) {
        let last = liveSets.last
        let style = current.exercise.loggingStyle
        let defaultQty: Int = {
            switch style {
            case .machineWork: return liveQuantityUnit == .meters ? 500 : 15
            case .repsAndTime: return 50
            default: return 8
            }
        }()
        let loadField = current.exercise.loadField
        liveSets.append(
            LiveSetRow(
                id: UUID(),
                weightKg: loadField == .weightKg
                    ? (last?.weightKg ?? current.plannedSets.last?.targetWeightKg)
                    : nil,
                deficitCm: loadField == .deficitCm
                    ? (last?.deficitCm ?? current.plannedSets.last?.targetWeightKg.map { Int($0.rounded()) } ?? 0)
                    : nil,
                durationSeconds: style.usesDuration
                    ? (last?.durationSeconds ?? current.plannedSets.last?.targetDurationSeconds ?? (current.exercise.isMobilityHold ? 30 : 60))
                    : nil,
                reps: current.exercise.isMobilityHold ? 1 : (last?.reps ?? current.plannedSets.last?.targetReps ?? defaultQty),
                rir: style.usesRIR ? (last?.rir ?? current.plannedSets.last?.targetRir) : nil,
                completed: false
            )
        )
        noteLiveDraftEdited()
    }

    private func bumpLiveWeight(at index: Int, delta: Double) {
        guard liveSets.indices.contains(index), !liveSets[index].completed else { return }
        let current = liveSets[index].weightKg ?? 0
        let next = max(0, ((current + delta) * 10).rounded() / 10)
        liveSets[index].weightKg = next > 0 ? next : nil
        noteLiveDraftEdited()
    }

    private func bumpLiveDeficit(at index: Int, delta: Int) {
        guard liveSets.indices.contains(index), !liveSets[index].completed else { return }
        let current = liveSets[index].deficitCm ?? 0
        liveSets[index].deficitCm = min(60, max(0, current + delta))
        noteLiveDraftEdited()
    }

    private func setLiveDeficit(at index: Int, cm: Int) {
        guard liveSets.indices.contains(index), !liveSets[index].completed else { return }
        liveSets[index].deficitCm = cm
        noteLiveDraftEdited()
    }

    private func commitLiveWeightText(at index: Int, text: String) {
        guard liveSets.indices.contains(index), !liveSets[index].completed else { return }
        let normalized = text
        if normalized.isEmpty || normalized == "—" {
            liveSets[index].weightKg = nil
            noteLiveDraftEdited()
            return
        }
        guard let value = ReperaNumberFormat.parse(normalized) else { return }
        let kg = store.state.settings.weightUnit.kilograms(fromDisplayValue: value)
        liveSets[index].weightKg = value > 0 ? ((kg * 10).rounded() / 10) : nil
        noteLiveDraftEdited()
    }

    private func bumpLiveDuration(at index: Int, delta: Int) {
        guard liveSets.indices.contains(index), !liveSets[index].completed else { return }
        let current = liveSets[index].durationSeconds ?? 0
        liveSets[index].durationSeconds = max(0, current + delta)
        noteLiveDraftEdited()
    }

    private func commitLiveDurationText(at index: Int, text: String) {
        guard liveSets.indices.contains(index), !liveSets[index].completed else { return }
        liveSets[index].durationSeconds = DurationText.parse(text)
        noteLiveDraftEdited()
    }

    private func bumpLiveReps(at index: Int, delta: Int) {
        guard liveSets.indices.contains(index), !liveSets[index].completed else { return }
        let current = store.state.activeSession?.currentExercise?.exercise
        let cap = current?.supportsWeightedRepsOrMeters == true && liveQuantityUnit == .meters
            ? 100_000 : (current?.loggingStyle.quantityCap ?? 50)
        liveSets[index].reps = min(cap, max(1, liveSets[index].reps + delta))
        noteLiveDraftEdited()
    }

    private func setLiveReps(at index: Int, reps: Int) {
        guard liveSets.indices.contains(index), !liveSets[index].completed else { return }
        let current = store.state.activeSession?.currentExercise?.exercise
        let cap = current?.supportsWeightedRepsOrMeters == true && liveQuantityUnit == .meters
            ? 100_000 : (current?.loggingStyle.quantityCap ?? 50)
        liveSets[index].reps = min(cap, max(1, reps))
        noteLiveDraftEdited()
    }

    private func setLiveRir(at index: Int, rir: Double?) {
        guard liveSets.indices.contains(index), !liveSets[index].completed else { return }
        liveSets[index].rir = rir
        noteLiveDraftEdited()
    }

    /// Tocar el número de serie marca/desmarca hecha (háptico + descanso al completar).
    private func toggleLiveSetCompleted(at index: Int, current: SessionExercise) {
        guard liveSets.indices.contains(index) else { return }
        let markingDone = !liveSets[index].completed
        liveSets[index].completed = markingDone
        noteLiveDraftEdited()
        focusedSetField = nil
        guard markingDone else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        if shouldStartIndependentRest(for: current) {
            let rest = store.state.settings.defaultRestSeconds
            if rest > 0 { beginRest(rest) }
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
                    Text("\(remaining)s")
                        .font(.system(size: 28, weight: .bold).monospacedDigit())
                        .foregroundStyle(OG.label)
                        .contentTransition(.numericText())
                }
                Spacer()
                Button("Saltar") {
                    store.restCoordinator.skip()
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(OG.accent)
            }
            .padding(16)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 18))
        }
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
                    Text(SportExerciseNames.localizedDisplayName(current.exercise.name))
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
            .accessibilityLabel("Ilustración de \(SportExerciseNames.localizedDisplayName(current.exercise.name))")
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
        case .amrap, .maxEffort:
            let seconds = max(60, (current.blockTimeCapMinutes ?? 12) * 60)
            store.workoutClock.configure(
                exercise: current.exercise,
                title: current.blockHeader ?? current.exercise.name,
                subtitle: subtitleDefault ?? format?.displayName ?? "WOD",
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
                timeCapSeconds: current.blockTimeCapMinutes.map { max(1, $0) * 60 },
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
        if let updated = store.state.activeSession?.currentExercise {
            rebuildLiveSets(from: updated)
        }
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
                                                Text(SportExerciseNames.localizedDisplayName(item.exercise.name))
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
        if liveSessionID != store.state.activeSession?.id {
            liveSessionID = store.state.activeSession?.id
            liveExerciseID = nil
            liveSets = []
            liveDraftsByExercise = [:]
            editedLiveExerciseIDs = []
        }
        guard let current = store.state.activeSession?.currentExercise else {
            liveExerciseID = nil
            liveSets = []
            return
        }
        let hasUserDraft = liveExerciseID == current.id && !liveSets.isEmpty
            || liveDraftsByExercise[current.id] != nil
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
        rebuildLiveSets(from: current)
        // No rellenar un peso dejado vacío deliberadamente en una plantilla:
        // cada fila mantiene su targetWeightKg, incluso si varía por serie.
        if let suggested, !hasPrescription, !hasUserDraft,
           let idx = liveSets.firstIndex(where: { !$0.completed }),
           liveSets[idx].weightKg == nil {
            liveSets[idx].weightKg = suggested
        }
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
    let onSave: (WODBlockResult) -> Void

    @State private var roundsText: String
    @State private var repsText: String
    @State private var timeText: String
    @State private var hasEditedResult = false
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case rounds, reps, time
    }

    init(
        blockId: UUID,
        format: WODFormat,
        existing: WODBlockResult?,
        suggestedElapsedSeconds: Int? = nil,
        wodTemplateId: String? = nil,
        onSave: @escaping (WODBlockResult) -> Void
    ) {
        self.blockId = blockId
        self.format = format
        self.existing = existing
        self.suggestedElapsedSeconds = suggestedElapsedSeconds
        self.wodTemplateId = wodTemplateId
        self.onSave = onSave
        _roundsText = State(initialValue: String(existing?.roundsCompleted ?? 0))
        _repsText = State(initialValue: String(existing?.totalReps ?? 0))
        _timeText = State(initialValue: DurationText.format(
            existing?.elapsedSeconds ?? suggestedElapsedSeconds ?? 0
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if format.resultCapture == .totalReps {
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

        }
        .onChange(of: roundsText) { _, _ in hasEditedResult = true }
        .onChange(of: repsText) { _, _ in hasEditedResult = true }
        .onChange(of: timeText) { _, _ in hasEditedResult = true }
        .task(id: "\(roundsText)|\(repsText)|\(timeText)") {
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
            totalReps: format.resultCapture == .totalReps
                ? min(5000, max(0, Int(repsText) ?? 0)) : nil,
            elapsedSeconds: format.resultCapture == .elapsedTime
                ? min(180 * 60, max(1, DurationText.parse(timeText) ?? 0)) : nil,
            roundsCompleted: format == .amrap || format == .deathBy
                ? min(200, max(0, Int(roundsText) ?? 0)) : nil,
            wodTemplateId: wodTemplateId ?? existing?.wodTemplateId
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
                .keyboardType(field == .time ? .numbersAndPunctuation : .numberPad)
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

    private var canSave: Bool {
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

    private struct Row: Identifiable {
        let id: UUID
        var weightKg: Double?
        var deficitCm: Int?
        var durationSeconds: Int?
        var reps: Int
        var rir: Double?
        var completed: Bool
    }

    @State private var rows: [Row] = []
    @State private var quantityUnit: ExerciseQuantityUnit = .reps
    @Binding var openedSetID: UUID?
    @FocusState private var focus: OGSetFieldID?

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
                    persist()
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
                        rows.remove(at: index)
                        persist()
                    }
                ) {
                    rowEditor(index: index, row: row)
                }
            }
            WorkoutInlineAddButton("Serie", systemImage: "plus.circle.fill") {
                guard rows.count < 20 else { return }
                let last = rows.last
                rows.append(Row(
                    id: UUID(), weightKg: last?.weightKg, deficitCm: last?.deficitCm,
                    durationSeconds: last?.durationSeconds, reps: last?.reps ?? 8,
                    rir: last?.rir, completed: false
                ))
                persist()
            }
        }
        .padding(.vertical, 6)
        .onAppear(perform: seedIfNeeded)
    }

    private func rowEditor(index: Int, row: Row) -> some View {
        let previous = store.cachedLastWorkingSession(for: exercise.id)?.sets
        let previousSet = (previous?.indices.contains(index) == true) ? previous?[index] : nil
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
            previous: OGSetEntryRow.previousText(previousSet),
            firstValue: firstValue,
            secondValue: style == .repsOnly || exercise.isMobilityHold ? nil : String(row.reps),
            nextEditableRowID: rows.dropFirst(index + 1).first?.id,
            firstAllowsDecimal: style == .loadAndReps && exercise.loadField == .weightKg,
            showsConfirmation: false,
            completed: row.completed,
            rir: row.rir,
            showsRIR: style.usesRIR,
            onRIRChange: { value in
                guard rows.indices.contains(index), !rows[index].completed else { return }
                rows[index].rir = value
                persist()
            },
            focus: $focus,
            onFirstCommit: { text in
                guard rows.indices.contains(index), !rows[index].completed else { return }
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
                persist()
            },
            onSecondCommit: { text in
                guard rows.indices.contains(index), !rows[index].completed else { return }
                if let value = Int(text), value > 0 { rows[index].reps = value; persist() }
            },
            onConfirm: {
                guard rows.indices.contains(index) else { return }
                rows[index].completed.toggle()
                if rows[index].completed {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                focus = nil
                persist()
            }
        )
    }

    private func seedIfNeeded() {
        guard rows.isEmpty else { return }
        quantityUnit = exerciseEntry.quantityUnit ?? exercise.defaultQuantityUnit
        let prescribed = exerciseEntry.plannedSets
        let recorded = exerciseEntry.loggedSets
        let prescribedIDs = Set(prescribed.map(\.id))
        let legacyIndexFallback = !recorded.contains(where: { prescribedIDs.contains($0.id) })
        rows = prescribed.enumerated().map { index, set in
            let result = recorded.first(where: { $0.id == set.id })
                ?? (legacyIndexFallback && recorded.indices.contains(index) ? recorded[index] : nil)
            return Row(
                id: result?.id ?? set.id,
                weightKg: result?.weightKg ?? set.targetWeightKg,
                deficitCm: result?.deficitCm ?? (exercise.loadField == .deficitCm
                    ? set.targetWeightKg.map { Int($0.rounded()) } : nil),
                durationSeconds: result?.durationSeconds ?? set.targetDurationSeconds,
                reps: result?.reps ?? set.targetReps,
                rir: result?.rir ?? set.targetRir,
                completed: result != nil
            )
        }
        if rows.isEmpty {
            rows = recorded.map {
                Row(id: $0.id, weightKg: $0.weightKg, deficitCm: $0.deficitCm,
                    durationSeconds: $0.durationSeconds, reps: $0.reps, rir: $0.rir,
                    completed: true)
            }
        }
    }

    /// Series editadas no marcadas → `plannedSets` (no se pierden al salir).
    /// Solo las marcadas hechas van a `loggedSets` (tap del índice / onConfirm).
    private func persist() {
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
        // No inventar loggedSets de filas sin marcar: seedIfNeeded las trataría
        // como hechas. Los kg/reps editados ya van en `revised` → plannedSets.
        let recorded: [LoggedSet] = rows.compactMap { row in
            guard row.completed, row.reps > 0 else { return nil }
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
            quantityUnit: unit, performedSets: recorded
        )
    }
}
