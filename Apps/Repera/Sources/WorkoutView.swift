import ReperaDomain
import SwiftUI
import UIKit

struct WorkoutView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(\.dismiss) private var dismiss
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
    @State private var notesDraft = ""
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
    @State private var expandedScoreBlocks: Set<UUID> = []
    @State private var expandedTechniquesExerciseID: UUID?
    @State private var usesAutomaticTimer = false
    @State private var pendingTimerBlockID: UUID?
    @State private var manualRoundSetup: ManualRoundSetup?
    @State private var manualRoundMinutes = 1
    @State private var manualRoundSeconds = 0
    /// EMOM/Tabata: el reloj ha terminado, pero todavía se pueden registrar series.
    @State private var finishedTimedBlockID: UUID?
    /// Mantener el temporizador del bloque al cambiar entre sus movimientos.
    @State private var runningTimerBlockID: UUID?
    @FocusState private var focusedSetField: OGSetFieldID?
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
        .sheet(item: $manualRoundSetup) { setup in
            manualRoundDurationSheet(for: setup)
        }
        .toolbar {
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
                        guard store.saveActiveSessionAsFavorite() != nil else {
                            let decision = store.lastAccessDenial
                                ?? subscriptions.canCreateLibraryRoutine(isNew: true)
                            subscriptions.presentPaywall(
                                decision.paywallContext, feature: .unlimitedRoutines
                            )
                            return
                        }
                    } label: {
                        Label(
                            activeIsFavorite ? "En favoritos" : "Favorito",
                            systemImage: activeIsFavorite ? "star.fill" : "star"
                        )
                    }
                    Divider()
                    Button(role: .destructive) {
                        store.workoutClock.stop()
                        store.endActiveSession(save: false)
                        closeFlow()
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
                    prefill()
                },
                embedsNavigationStack: false,
                usesPageCloseHeader: true
            )
        }
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
            return routine
        }
        if let blocks = session.routineBlocks, !blocks.isEmpty {
            return Routine(id: session.routineId ?? UUID(), title: session.title, blocks: blocks)
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
        return Routine(id: session.routineId ?? UUID(), title: session.title, blocks: blocks)
    }

    /// Play comparte la jerarquía visual del editor: un bloque, sus ejercicios
    /// y las series editables. No ofrece controles de creación ni de planificación.
    private struct WorkoutBlockEntry: Identifiable {
        let id: UUID
        let title: String
        let format: WODFormat?
        var indexes: [Int]
    }

    private func workoutBlocks(_ session: WorkoutSession) -> [WorkoutBlockEntry] {
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
                    }
                    .listRowBackground(OG.surface)

                    if let format = block.format, format.resultCapture != .perMovementSets {
                        inlineWODScoreEditor(block, format: format, session: session)
                            .listRowBackground(OG.surface)
                    }

                    ForEach(block.indexes, id: \.self) { index in
                        let entry = session.exercises[index]
                        Group {
                            if session.currentIndex == index {
                                // Ya expandido: tocar miniatura o nombre abre la ficha real.
                                NavigationLink {
                                    ExerciseDetailView(
                                        exerciseId: entry.exercise.id,
                                        highlightSessionId: session.id
                                    )
                                } label: {
                                    workoutExerciseRow(entry, isOpen: true, blockResult: session.wodResults.first(where: { $0.id == block.id }))
                                }
                            } else {
                                // Cerrado: un toque expande sus series (no navega).
                                Button {
                                    store.selectExercise(at: index)
                                } label: {
                                    workoutExerciseRow(entry, isOpen: false, blockResult: session.wodResults.first(where: { $0.id == block.id }))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .listRowBackground(OG.surface)
                        // Sin línea entre el ejercicio abierto y la cabecera de series.
                        .listRowSeparator(
                            session.currentIndex == index ? .hidden : .visible,
                            edges: .bottom
                        )

                        if session.currentIndex == index {
                            setsBoard(entry)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(OG.surface)
                                .listRowSeparator(.hidden)
                        }
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

            Section("Lugar") {
                WorkoutPlacePickerRow(pin: activeLocationPin)
                    .listRowBackground(OG.surface)
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
                Text(entry.exercise.name)
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

    /// Una fila del bloque, sin una tarjeta ni un diseño separado.
    /// Se expande para anotar el score, igual que una fila de ejercicio.
    private func inlineWODScoreEditor(
        _ block: WorkoutBlockEntry,
        format: WODFormat,
        session: WorkoutSession
    ) -> some View {
        let existing = session.wodResults.first(where: { $0.id == block.id })
        let suggested = pendingWODConfirm?.blockId == block.id
            ? pendingWODConfirm?.elapsedSeconds : nil
        let templateID = session.routineBlocks?
            .first(where: { $0.id == block.id })?.wodTemplateId

        return DisclosureGroup(isExpanded: Binding(
            get: { expandedScoreBlocks.contains(block.id) },
            set: { expanded in
                if expanded {
                    expandedScoreBlocks.insert(block.id)
                } else {
                    expandedScoreBlocks.remove(block.id)
                }
            }
        )) {
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
            .id(block.id)
            .padding(.vertical, 8)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "stopwatch")
                    .foregroundStyle(OG.label2)
                    .frame(width: 27)
                Text("Resultado del bloque")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(OG.label)
                Spacer(minLength: 6)
                Text(existing?.summaryLabel ?? "Sin registrar")
                    .font(.system(size: 13, weight: .medium).monospacedDigit())
                    .foregroundStyle(existing == nil ? OG.label3 : OG.accent)
                    .lineLimit(1)
            }
        }
        .tint(OG.label2)
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
            : (style == .loadAndReps ? "KG" : (current.exercise.isMobility ? "Tiempo" : "Tiempo"))
        return VStack(alignment: .leading, spacing: 12) {
            OGSetEntryHeader(
                firstTitle: style == .repsOnly ? qtyLabel : loadLabel,
                secondTitle: style == .repsOnly || current.exercise.isMobilityHold ? nil : qtyLabel,
                showsConfirmation: false,
                showsRIR: style.usesRIR
            )

            ForEach(Array(liveSets.enumerated()), id: \.element.id) { index, row in
                WorkoutSetSwipeDeleteRow(
                    onDelete: { removeLiveSet(at: index, current: current) }
                ) {
                    liveSetRow(index: index, row: row, current: current)
                }
            }

            Button {
                addLiveSet(from: current)
            } label: {
                Label("Añadir serie", systemImage: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(OG.accent)
            }
            .buttonStyle(.plain)
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
                return row.weightKg.map { ReperaNumberFormat.decimal($0) } ?? "—"
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
                completed: false,
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
                onConfirm: { }

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
                    completed: false
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
                    completed: false
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
        liveSets[index].weightKg = value > 0 ? ((value * 10).rounded() / 10) : nil
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

    /// Tarjeta compacta: toda la zona informativa reabre el reloj.
    /// Pausar/Continuar queda junto a Terminar, sin un botón "Ver reloj"
    /// redundante. El tiempo y la ronda siguen a la vista durante el registro.
    private var minimizedTimerDock: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { context in
            let clock = store.workoutClock
            HStack(spacing: 8) {
                Button {
                    clock.showClock()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "timer")
                            .font(.title3.bold())
                            .foregroundStyle(OG.accent)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(clock.isIntervalMode
                                 ? "Ronda \(min(clock.displayedRound, clock.displayedRoundsTotal))/\(clock.displayedRoundsTotal)"
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
                .accessibilityLabel("Ver reloj completo")

                Button {
                    clock.handlePrimary()
                } label: {
                    Image(systemName: clock.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(minWidth: 40, minHeight: 40)
                }
                .buttonStyle(.bordered)
                .tint(OG.label)
                .accessibilityLabel(clock.primaryTitle + " temporizador")

                Button {
                    clock.finishByUser()
                } label: {
                    Text("Terminar")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(minHeight: 40)
                }
                .buttonStyle(.borderedProminent)
                .tint(OG.accent)
                .disabled(!clock.canFinishByUser)
                .accessibilityLabel("Terminar temporizador")
            }
            .padding(12)
            .background(OG.surface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
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
                    Text(current.exercise.name)
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
            .accessibilityLabel("Ilustración de \(current.exercise.name)")
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
        // El resultado se edita dentro de la fila del bloque, sin modal.
        expandedScoreBlocks.insert(blockID)
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
        let hasPrescribedDuration = (current.blockTimeCapMinutes ?? 0) > 0
            || (current.blockIntervalSeconds ?? 0) > 0
            || (current.blockWorkSeconds ?? 0) > 0
        guard freeFormat && !hasPrescribedDuration else {
            startBlockClock(for: current)
            return
        }
        manualRoundMinutes = 1
        manualRoundSeconds = 0
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

    private func manualRoundDurationSheet(for setup: ManualRoundSetup) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Duración de cada ronda")
                .font(.title3.weight(.bold))
                .foregroundStyle(OG.label)
            Text("Bloque libre · \(setup.rounds) ronda\(setup.rounds == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(OG.label2)
            Stepper(value: $manualRoundMinutes, in: 0...120) {
                HStack {
                    Text("Minutos")
                    Spacer()
                    Text("\(manualRoundMinutes)")
                        .monospacedDigit()
                }
            }
            Stepper(value: $manualRoundSeconds, in: 0...55, step: 5) {
                HStack {
                    Text("Segundos")
                    Spacer()
                    Text("\(manualRoundSeconds)")
                        .monospacedDigit()
                }
            }
            Button {
                guard let current = store.state.activeSession?.currentExercise,
                      current.id == setup.exerciseID else {
                    manualRoundSetup = nil
                    return
                }
                let seconds = manualRoundMinutes * 60 + manualRoundSeconds
                guard seconds > 0 else { return }
                manualRoundSetup = nil
                startBlockClock(for: current, manualRoundSeconds: seconds, manualRounds: setup.rounds)
            } label: {
                Text("Iniciar temporizador")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(OG.accent)
            .disabled(manualRoundMinutes == 0 && manualRoundSeconds == 0)
            Spacer(minLength: 0)
        }
        .padding(24)
        .presentationDetents([.height(345)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(26)
        .presentationBackground(OG.surface)
    }

    /// Reloj a pantalla completa para cualquier tipo de bloque (EMOM, AMRAP, fuerza…).
    private func startBlockClock(
        for current: SessionExercise,
        manualRoundSeconds: Int? = nil,
        manualRounds: Int? = nil
    ) {
        let sound = store.state.settings.restSoundEnabled
        let haptic = store.state.settings.restHapticEnabled
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
            if let roundDuration = manualRoundSeconds
                ?? current.blockIntervalSeconds ?? current.blockWorkSeconds,
               roundDuration > 0 {
                let rounds = manualRounds ?? prescribedRoundCount(for: current)
                store.workoutClock.configure(
                    exercise: current.exercise,
                    title: current.blockHeader ?? current.exercise.name,
                    subtitle: current.blockHeader ?? "Ronda de fuerza",
                    countingUp: false,
                    intervalMode: true,
                    intervalLength: roundDuration,
                    totalIntervals: rounds,
                    initialCountdown: roundDuration,
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
                    Text("Peso (kg)").font(.caption).foregroundStyle(OG.label2)
                    OGRepeatStepper(
                        display: weightText.isEmpty ? "—" : weightText,
                        keyboard: .decimalPad,
                        onMinus: { bumpWeight(-store.state.settings.weightIncrementKg) },
                        onPlus: { bumpWeight(store.state.settings.weightIncrementKg) },
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
                                Text("\(set.weightKg?.formatted(.number.precision(.fractionLength(1))) ?? "—") kg × \(set.reps)")
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
        let weight = ReperaNumberFormat.parse(weightText)
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
                                NavigationLink {
                                    ExerciseDetailView(exerciseId: item.exercise.id)
                                } label: {
                                    HStack(spacing: 12) {
                                        ExerciseThumb(exercise: item.exercise, size: 48)
                                        VStack(alignment: .leading, spacing: 3) {
                                            HStack(spacing: 6) {
                                                Text(item.exercise.name)
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
        weightText = suggested.map { ReperaNumberFormat.decimal($0) } ?? ""
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
            weightText = current.lastLoggedWeight.map { ReperaNumberFormat.decimal($0) } ?? weightText
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
            sound: store.state.settings.restSoundEnabled,
            haptic: store.state.settings.restHapticEnabled
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

            HStack {
                Spacer(minLength: 0)
                Button {
                    focusedField = nil
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
                } label: {
                    Label(existing == nil ? "Guardar" : "Actualizar", systemImage: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(canSave ? OG.accent : OG.label3)
                        .frame(minHeight: 44)
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
            }
        }
        .onChange(of: suggestedElapsedSeconds) { _, seconds in
            // Reloj For Time: conservar cualquier registro previo y solo
            // proponer el tiempo recién medido cuando no había resultado.
            guard existing?.elapsedSeconds == nil, let seconds, seconds > 0 else { return }
            timeText = DurationText.format(seconds)
        }
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
private struct WorkoutSetSwipeDeleteRow<Content: View>: View {
    var onDelete: () -> Void
    @ViewBuilder var content: () -> Content
    @State private var deleteRevealed = false

    var body: some View {
        ZStack(alignment: .trailing) {
            Button(role: .destructive) {
                deleteRevealed = false
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 44)
                    .background(OG.red, in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Eliminar serie")
            .opacity(deleteRevealed ? 1 : 0)
            .allowsHitTesting(deleteRevealed)

            content()
                .frame(maxWidth: .infinity)
                // Mismo fondo que la tarjeta: sin franjas negras puras entre series.
                .background(OG.surface)
                .offset(x: deleteRevealed ? -66 : 0)
                .contentShape(Rectangle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 18)
                        .onEnded { value in
                            guard abs(value.translation.width) > abs(value.translation.height) * 1.2 else { return }
                            withAnimation(.smooth(duration: 0.22)) {
                                if value.translation.width < -35 {
                                    deleteRevealed = true
                                } else if value.translation.width > 30 {
                                    deleteRevealed = false
                                }
                            }
                        }
                )
                .accessibilityAction(named: "Eliminar serie") { onDelete() }
        }
        .clipped()
    }
}
