import ReperaDomain
import SwiftUI
import UIKit

struct WorkoutView: View {
    @Environment(ReperaStore.self) private var store
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
    @State private var clusterRest = 15
    @State private var pendingClusters: [RestPauseCluster] = []
    @State private var editingRoutine: Routine?
    @State private var notesDraft = ""
    /// Filas editables del ejercicio actual (objetivo por serie + check para registrar).
    @State private var liveSets: [LiveSetRow] = []
    /// Unidad Cal/m para erg/bike del ejercicio actual.
    @State private var liveQuantityUnit: ExerciseQuantityUnit = .reps
    @State private var setCompletionPulse = 0
    @State private var restStartedPulse = 0
    @State private var pendingWODConfirm: PendingWODConfirm?
    @State private var usesAutomaticTimer = false
    @State private var pendingTimerBlockID: UUID?
    @FocusState private var focusedSetField: OGSetFieldID?

    private struct LiveSetRow: Identifiable, Equatable {
        let id: UUID
        var weightKg: Double?
        var deficitCm: Int?
        var durationSeconds: Int?
        var reps: Int
        var rir: Double?
        var completed: Bool
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
            if store.restCoordinator.isActive, !store.workoutClock.isVisible {
                restDock
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
                if !visible { store.workoutClock.stop() }
            }
        )) {
            wodFullscreenClock
                .preferredColorScheme(.dark)
                .background(Color.black.ignoresSafeArea())
                .statusBarHidden()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CloseToolbarButton(action: { closeFlow() }, large: false)
                    .foregroundStyle(OG.label2)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        editingRoutine = routineForEditing()
                    } label: {
                        Label("Editar entreno", systemImage: "pencil")
                    }
                    Button {
                        _ = store.saveActiveSessionAsFavorite()
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
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 8) {
                    if let index = store.state.activeSession?.currentIndex, index > 0 {
                        Button {
                            store.selectExercise(at: index - 1)
                        } label: {
                            Label("Anterior", systemImage: "arrow.left")
                        }
                        .accessibilityLabel("Ejercicio anterior")
                        .tint(OG.accent)
                    }
                    if let index = store.state.activeSession?.currentIndex, hasMoreExercises {
                        Button {
                            // Navegar no finaliza ni inventa resultados del ejercicio.
                            store.selectExercise(at: index + 1)
                        } label: {
                            Label("Siguiente", systemImage: "arrow.right")
                        }
                        .accessibilityLabel("Ejercicio siguiente")
                        .tint(OG.accent)
                    } else {
                        Button {
                            store.workoutClock.stop()
                            store.endActiveSession(save: true)
                            closeFlow()
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(OG.accent)
                        .accessibilityLabel("Terminar entreno")
                    }
                }
            }
        }
        // Edición como destino push en NavigationStack, no hoja modal.
        .navigationDestination(item: $editingRoutine) { draft in
            DayEditorView(
                routine: draft,
                mode: draft.isOneOff ? .oneOff(isNew: false) : .plan(isNew: false),
                onClose: {
                    if let saved = store.state.routines.first(where: { $0.id == draft.id }) {
                        store.refreshActiveSessionPlan(from: saved)
                    }
                    editingRoutine = nil
                },
                embedsNavigationStack: false,
                usesPageCloseHeader: true
            )
        }
        .sheet(item: $pendingWODConfirm) { pending in
            WODResultConfirmSheet(
                title: pending.title,
                capture: pending.capture,
                totalReps: Binding(
                    get: { pendingWODConfirm?.totalReps ?? pending.totalReps },
                    set: { pendingWODConfirm?.totalReps = $0 }
                ),
                elapsedSeconds: Binding(
                    get: { pendingWODConfirm?.elapsedSeconds ?? pending.elapsedSeconds },
                    set: { pendingWODConfirm?.elapsedSeconds = $0 }
                ),
                roundsCompleted: Binding(
                    get: { pendingWODConfirm?.roundsCompleted ?? pending.roundsCompleted },
                    set: { pendingWODConfirm?.roundsCompleted = $0 }
                ),
                onSave: {
                    guard let current = pendingWODConfirm else { return }
                    store.applyWODResult(
                        WODBlockResult(
                            id: current.blockId,
                            format: current.format,
                            totalReps: current.capture == .totalReps ? current.totalReps : nil,
                            elapsedSeconds: current.capture == .elapsedTime ? current.elapsedSeconds : nil,
                            roundsCompleted: current.roundsCompleted > 0 ? current.roundsCompleted : nil,
                            wodTemplateId: current.wodTemplateId
                        )
                    )
                    pendingWODConfirm = nil
                    store.finishCurrentTimedBlock()
                    if store.state.activeSession == nil {
                        closeFlow()
                    }
                },
                onCancel: { pendingWODConfirm = nil }
            )
        }
        .onAppear {
            notesDraft = store.state.activeSession?.notes ?? ""
            prefill()
            bootstrapQuickLogIfNeeded()
            if store.state.activeSession?.phase == .ready {
                store.confirmCurrentOnWatchStyle()
            }
        }
        .onChange(of: store.state.activeSession?.currentIndex) { _, _ in
            prefill()
            store.workoutClock.stop()
            store.workoutClock.clearPendingEnd()
            if store.state.activeSession?.phase == .ready {
                store.confirmCurrentOnWatchStyle()
            }
            if let blockID = pendingTimerBlockID {
                pendingTimerBlockID = nil
                if let current = store.state.activeSession?.currentExercise,
                   current.blockId == blockID || current.id == blockID {
                    startBlockClock(for: current)
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

    private var hasMoreExercises: Bool {
        guard let session = store.state.activeSession else { return false }
        return session.currentIndex + 1 < session.exercises.count
    }

    private var activeIsFavorite: Bool {
        guard let rid = store.state.activeSession?.routineId else { return false }
        return store.state.routines.first(where: { $0.id == rid })?.isFavorite == true
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
           let routine = store.state.routines.first(where: { $0.id == id }) {
            return routine
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
                        Button {
                            openBlockTimer(block, session: session)
                        } label: {
                            Image(systemName: "timer")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundStyle(OG.accent)
                                .frame(width: 44, height: 44)
                                .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Temporizador de \(block.title)")
                    }
                    .listRowBackground(OG.surface)

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
                                    workoutExerciseRow(entry, isOpen: true)
                                }
                            } else {
                                // Cerrado: un toque expande sus series (no navega).
                                Button {
                                    store.selectExercise(at: index)
                                } label: {
                                    workoutExerciseRow(entry, isOpen: false)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .listRowBackground(OG.surface)

                        if session.currentIndex == index {
                            setsBoard(entry)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(OG.surface)
                                .listRowSeparator(.hidden)
                        }
                    }

                    if block.indexes.contains(session.currentIndex),
                       let current = session.currentExercise {
                        DisclosureGroup("Técnicas de serie · dropset / rest-pause") {
                            logForm(current)
                                .padding(.top, 8)
                        }
                        .font(.system(size: 13, weight: .medium))
                        .tint(OG.label2)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
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

    private func workoutExerciseRow(_ entry: SessionExercise, isOpen: Bool) -> some View {
        HStack(spacing: 12) {
            ExerciseThumb(exercise: entry.exercise, size: 48)
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.exercise.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(OG.label)
                Text(entry.plannedSets.compactSummary)
                    .font(.caption)
                    .foregroundStyle(OG.label2)
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
            // Sin chevron hacia abajo: la fila abierta lleva a la ficha.
        }
        .contentShape(Rectangle())
    }

    private func openBlockTimer(_ block: WorkoutBlockEntry, session: WorkoutSession) {
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
        startBlockClock(for: current)
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
        let qtyLabel = style == .machineWork ? liveQuantityUnit.shortLabel : current.exercise.quantityFieldLabel
        let loadLabel = current.exercise.loadField == .deficitCm
            ? "Déficit cm"
            : (style == .loadAndReps ? "KG" : "Tiempo")
        return VStack(alignment: .leading, spacing: 12) {
            OGSetEntryHeader(
                firstTitle: style == .repsOnly ? qtyLabel : loadLabel,
                secondTitle: style == .repsOnly ? nil : qtyLabel,
                showsConfirmation: store.state.activeSession?.phase != .ready,
                showsRIR: style.usesRIR
            )

            ForEach(Array(liveSets.enumerated()), id: \.element.id) { index, row in
                liveSetRow(index: index, row: row, current: current)
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
        let qtyLabel = style == .machineWork ? liveQuantityUnit.shortLabel : current.exercise.quantityFieldLabel
        let previous = store.cachedLastWorkingSession(for: current.exercise.id)?.sets
        let previousSet = (previous?.indices.contains(index) == true) ? previous?[index] : nil
        let firstValue: String = {
            switch style {
            case .repsOnly: return "\(row.reps)"
            case .loadAndReps:
                if current.exercise.loadField == .deficitCm {
                    return row.deficitCm.map(String.init) ?? "0"
                }
                return row.weightKg.map { String(format: "%g", $0) } ?? "0"
            case .repsAndTime, .machineWork: return DurationText.format(row.durationSeconds)
            }
        }()

        return VStack(alignment: .leading, spacing: 6) {
            if index == 0, style == .machineWork, current.exercise.allowsCalorieOrDistanceToggle {
                Picker("Unidad", selection: $liveQuantityUnit) {
                    Text("Cal").tag(ExerciseQuantityUnit.calories)
                    Text("Metros").tag(ExerciseQuantityUnit.meters)
                }
                .pickerStyle(.segmented)
                .disabled(row.completed && liveSets.contains(where: \.completed))
            }

            OGSetEntryRow(
                rowID: row.id,
                index: index + 1,
                previous: OGSetEntryRow.previousText(previousSet),
                firstValue: firstValue,
                secondValue: style == .repsOnly ? nil : "\(row.reps)",
                firstAllowsDecimal: style != .repsOnly && current.exercise.loadField == .weightKg,
                showsConfirmation: store.state.activeSession?.phase != .ready,
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
                onConfirm: {
                    guard store.state.activeSession?.phase != .ready else { return }
                    if row.completed {
                        if index == liveSets.count - 1 || index == current.loggedSets.count - 1 {
                            store.removeLastSet()
                            rebuildLiveSets(from: store.state.activeSession?.currentExercise ?? current)
                        }
                    } else {
                        completeLiveSet(at: index, current: current)
                    }
                }
            )
            .accessibilityLabel("Serie \(index + 1), \(qtyLabel)")


        }
        .padding(.vertical, 3)
    }

    private func rebuildLiveSets(from current: SessionExercise) {
        syncLiveQuantityUnit(from: current)
        var rows: [LiveSetRow] = []
        let planned = current.plannedSets
        let logged = current.loggedSets
        let total = max(planned.count, logged.count)
        let style = current.exercise.loggingStyle
        let defaultQty: Int = {
            switch style {
            case .machineWork: return liveQuantityUnit == .meters ? 500 : 15
            case .repsAndTime: return 50
            default: return 8
            }
        }()

        let loadField = current.exercise.loadField
        if total == 0 {
            liveSets = [LiveSetRow(
                id: UUID(),
                weightKg: nil,
                deficitCm: loadField == .deficitCm ? 0 : nil,
                durationSeconds: style.usesDuration ? 60 : nil,
                reps: defaultQty,
                rir: nil,
                completed: false
            )]
            return
        }

        for i in 0..<total {
            if i < logged.count {
                let s = logged[i]
                rows.append(
                    LiveSetRow(
                        id: s.id,
                        weightKg: s.weightKg,
                        deficitCm: s.deficitCm,
                        durationSeconds: s.durationSeconds,
                        reps: s.reps,
                        rir: s.rir,
                        completed: true
                    )
                )
            } else {
                let p = planned[i]
                let plannedDeficit: Int? = {
                    guard loadField == .deficitCm else { return nil }
                    return p.targetWeightKg.map { Int($0.rounded()) } ?? 0
                }()
                rows.append(
                    LiveSetRow(
                        id: p.id,
                        weightKg: loadField == .weightKg ? p.targetWeightKg : nil,
                        deficitCm: plannedDeficit,
                        durationSeconds: style.usesDuration ? 60 : nil,
                        reps: max(1, p.targetReps),
                        rir: p.targetRir,
                        completed: false
                    )
                )
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
                    ? (last?.durationSeconds ?? 60)
                    : nil,
                reps: last?.reps ?? current.plannedSets.last?.targetReps ?? defaultQty,
                rir: style.usesRIR ? (last?.rir ?? current.plannedSets.last?.targetRir) : nil,
                completed: false
            )
        )
    }

    private func bumpLiveWeight(at index: Int, delta: Double) {
        guard liveSets.indices.contains(index), !liveSets[index].completed else { return }
        let current = liveSets[index].weightKg ?? 0
        let next = max(0, ((current + delta) * 10).rounded() / 10)
        liveSets[index].weightKg = next > 0 ? next : nil
    }

    private func bumpLiveDeficit(at index: Int, delta: Int) {
        guard liveSets.indices.contains(index), !liveSets[index].completed else { return }
        let current = liveSets[index].deficitCm ?? 0
        liveSets[index].deficitCm = min(60, max(0, current + delta))
    }

    private func setLiveDeficit(at index: Int, cm: Int) {
        guard liveSets.indices.contains(index), !liveSets[index].completed else { return }
        liveSets[index].deficitCm = cm
    }

    private func commitLiveWeightText(at index: Int, text: String) {
        guard liveSets.indices.contains(index), !liveSets[index].completed else { return }
        let normalized = text.replacingOccurrences(of: ",", with: ".")
        if normalized.isEmpty || normalized == "—" {
            liveSets[index].weightKg = nil
            return
        }
        guard let value = Double(normalized) else { return }
        liveSets[index].weightKg = value > 0 ? ((value * 10).rounded() / 10) : nil
    }

    private func bumpLiveDuration(at index: Int, delta: Int) {
        guard liveSets.indices.contains(index), !liveSets[index].completed else { return }
        let current = liveSets[index].durationSeconds ?? 0
        liveSets[index].durationSeconds = max(0, current + delta)
    }

    private func commitLiveDurationText(at index: Int, text: String) {
        guard liveSets.indices.contains(index), !liveSets[index].completed else { return }
        liveSets[index].durationSeconds = DurationText.parse(text)
    }

    private func bumpLiveReps(at index: Int, delta: Int) {
        guard liveSets.indices.contains(index), !liveSets[index].completed else { return }
        let cap = store.state.activeSession?.currentExercise?.exercise.loggingStyle.quantityCap ?? 50
        liveSets[index].reps = min(cap, max(1, liveSets[index].reps + delta))
    }

    private func setLiveReps(at index: Int, reps: Int) {
        guard liveSets.indices.contains(index), !liveSets[index].completed else { return }
        let cap = store.state.activeSession?.currentExercise?.exercise.loggingStyle.quantityCap ?? 50
        liveSets[index].reps = min(cap, max(1, reps))
    }

    private func setLiveRir(at index: Int, rir: Double?) {
        guard liveSets.indices.contains(index), !liveSets[index].completed else { return }
        liveSets[index].rir = rir
    }

    private func completeLiveSet(at index: Int, current: SessionExercise) {
        guard liveSets.indices.contains(index), !liveSets[index].completed else { return }
        // Solo se puede completar en orden (siguiente pendiente).
        let nextPending = liveSets.firstIndex(where: { !$0.completed })
        guard nextPending == index else { return }
        let row = liveSets[index]
        guard row.reps > 0 else { return }
        let style = current.exercise.loggingStyle
        let loadField = current.exercise.loadField
        let weight: Double? = {
            guard loadField == .weightKg, let w = row.weightKg, w > 0 else { return nil }
            return w
        }()
        let deficit: Int? = {
            guard loadField == .deficitCm, let d = row.deficitCm, d > 0 else { return nil }
            return d
        }()
        store.logSet(
            reps: row.reps,
            weightKg: weight,
            deficitCm: deficit,
            durationSeconds: style.usesDuration ? row.durationSeconds : nil,
            quantityUnit: style == .machineWork ? liveQuantityUnit : nil,
            phase: .work,
            kind: .straight,
            rir: style.usesRIR ? row.rir : nil,
            toFailure: style.usesRIR && row.rir == 0,
            drops: [],
            clusters: []
        )
        setCompletionPulse &+= 1
        beginRest(store.state.settings.defaultRestSeconds)
        restStartedPulse &+= 1
        if let updated = store.state.activeSession?.currentExercise {
            withAnimation(reduceMotion ? nil : .smooth) {
                rebuildLiveSets(from: updated)
            }
            weightText = updated.loggedSets.last?.weightKg.map { String(format: "%g", $0) } ?? weightText
            repsText = "\(updated.loggedSets.last?.reps ?? row.reps)"
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
                metaPill("Último", last.map { String(format: "%g kg", $0) } ?? "—")
                metaPill("Mejor", pr.map { String(format: "%g kg", $0.weightKg) } ?? "—")
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
                            startBlockClock(for: current)
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
                        startBlockClock(for: current)
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
        if let format = current.wodFormat {
            let reps = target?.targetReps ?? 0
            let weight = target?.targetWeightKg.map { String(format: "%g kg", $0) } ?? "PC"
            return "\(format.displayName) · \(reps) reps · \(weight)"
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
            ? min(clock.intervalIndex + 1, max(clock.totalIntervals, 1))
            : nil
        return TimelineView(.periodic(from: .now, by: 0.25)) { context in
            BlockTimerScreen(
                title: clock.title,
                subtitle: clock.isPreCountdown ? "Cuenta atrás" : clock.subtitle,
                exercise: clock.exercise,
                roundNumber: roundDisplay,
                totalRounds: clock.isIntervalMode ? clock.totalIntervals : nil,
                displaySeconds: clock.displaySeconds(at: context.date),
                isRunning: clock.isRunning,
                isCountingUp: clock.isCountingUp,
                primaryTitle: clock.primaryTitle,
                onPrimary: { clock.handlePrimary() },
                onClose: { clock.stop() },
                onSkip: clock.isIntervalMode ? { clock.skipInterval() } : nil,
                onFinish: clock.canFinishByUser ? { clock.finishByUser() } : nil,
                showFinish: clock.canFinishByUser
            )
        }
    }

    private func presentWODConfirmIfNeeded() {
        guard let (reason, elapsed) = store.workoutClock.consumePendingEnd() else { return }
        guard let current = store.state.activeSession?.currentExercise else { return }
        let capture = current.wodFormat?.resultCapture ?? .perMovementSets
        guard capture == .totalReps || capture == .elapsedTime else {
            store.finishCurrentTimedBlock()
            if store.state.activeSession == nil {
                closeFlow()
            }
            return
        }
        guard let format = current.wodFormat else { return }
        let blockId = current.blockId ?? current.id
        let templateId = store.state.activeSession.flatMap { session -> String? in
            guard let rid = session.routineId,
                  let routine = store.state.routines.first(where: { $0.id == rid }),
                  let block = routine.blocks.first(where: { $0.id == blockId })
            else { return nil }
            return block.wodTemplateId
        }
        switch capture {
        case .totalReps:
            pendingWODConfirm = PendingWODConfirm(
                blockId: blockId,
                format: format,
                capture: capture,
                totalReps: 0,
                elapsedSeconds: elapsed,
                roundsCompleted: 0,
                wodTemplateId: templateId,
                title: current.blockHeader ?? format.displayName
            )
        case .elapsedTime:
            pendingWODConfirm = PendingWODConfirm(
                blockId: blockId,
                format: format,
                capture: capture,
                totalReps: 0,
                elapsedSeconds: max(1, elapsed),
                roundsCompleted: current.blockRounds ?? 0,
                wodTemplateId: templateId,
                title: current.blockHeader ?? format.displayName
            )
        case .perMovementSets:
            break
        }
        _ = reason
    }

    /// Reloj a pantalla completa para cualquier tipo de bloque (EMOM, AMRAP, fuerza…).
    private func startBlockClock(for current: SessionExercise) {
        let sound = store.state.settings.restSoundEnabled
        let haptic = store.state.settings.restHapticEnabled
        let format = current.wodFormat
        let subtitleDefault = wodPlanLabel(for: current)

        switch format {
        case .emom, .circuit:
            let interval = max(15, current.blockIntervalSeconds ?? 60)
            let rounds = current.plannedIntervals
                ?? current.blockRounds
                ?? current.blockTimeCapMinutes
                ?? 8
            store.workoutClock.configure(
                exercise: current.exercise,
                title: current.blockHeader ?? current.exercise.name,
                subtitle: subtitleDefault ?? "EMOM",
                countingUp: false,
                intervalMode: true,
                intervalLength: interval,
                totalIntervals: max(1, rounds),
                initialCountdown: interval,
                sound: sound,
                haptic: haptic
            )
        case .tabata:
            let work = max(5, current.blockWorkSeconds ?? 20)
            let rest = max(5, current.blockRestSeconds ?? 10)
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
        case .amrap, .deathBy, .maxEffort:
            let mins = current.blockTimeCapMinutes ?? 12
            let seconds = max(60, mins * 60)
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
        case .forTime, .chipper, .afap, .ladder:
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
        case .partner, .buyInCashOut, .roundsForQuality:
            if let mins = current.blockTimeCapMinutes, mins > 0 {
                let seconds = mins * 60
                store.workoutClock.configure(
                    exercise: current.exercise,
                    title: current.blockHeader ?? current.exercise.name,
                    subtitle: subtitleDefault ?? format?.displayName ?? "Bloque",
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
                    subtitle: subtitleDefault ?? format?.displayName ?? "Bloque",
                    countingUp: true,
                    intervalMode: false,
                    intervalLength: 0,
                    totalIntervals: 0,
                    initialCountdown: 0,
                    sound: sound,
                    haptic: haptic
                )
            }
        case .none:
            store.workoutClock.configure(
                exercise: current.exercise,
                title: current.blockHeader ?? current.exercise.name,
                subtitle: "Cronómetro libre",
                countingUp: true,
                intervalMode: false,
                intervalLength: 0,
                totalIntervals: 0,
                initialCountdown: 0,
                sound: sound,
                haptic: haptic
            )
        case .strength:
            if let mins = current.blockTimeCapMinutes, mins > 0 {
                let seconds = mins * 60
                store.workoutClock.configure(
                    exercise: current.exercise,
                    title: current.blockHeader ?? current.exercise.name,
                    subtitle: subtitleDefault ?? "Fuerza",
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
                    subtitle: subtitleDefault ?? "Fuerza",
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
        // El primer toque en Comenzar inicia también el reloj (cuenta previa nativa).
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
                            let normalized = text.replacingOccurrences(of: ",", with: ".")
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
                            Text("\(unit.displayName) \(effortValue.formatted(.number.precision(.fractionLength(0)))) · \(Effort.plainLanguage(rir: Effort.toRIR(value: effortValue, unit: unit)))")
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
                        Text("→ \(drop.weightKg.map { String(format: "%g", $0) } ?? "—") kg × \(drop.reps)")
                            .font(.caption.monospacedDigit())
                    }
                    HStack(spacing: 10) {
                        TextField("kg drop", text: $dropWeightText)
                            .ogKeyboardDone()
                        TextField("reps", text: $dropRepsText)
                            .ogNumericKeyboard(allowsDecimal: false)

                        Button("Añadir") {
                            let reps = Int(dropRepsText) ?? 0
                            let w = Double(dropWeightText.replacingOccurrences(of: ",", with: "."))
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
                        Text("\(idx + 1). \(cluster.reps) reps · descanso \(cluster.restSeconds)s")
                            .font(.caption.monospacedDigit())
                    }
                    HStack(spacing: 10) {
                        TextField("reps", text: $clusterRepsText)
                            .ogNumericKeyboard(allowsDecimal: false)

                        Stepper("\(clusterRest)s", value: $clusterRest, in: 5...30, step: 5)
                        Button("Añadir") {
                            let reps = Int(clusterRepsText) ?? 0
                            guard reps > 0 else { return }
                            pendingClusters.append(RestPauseCluster(reps: reps, restSeconds: clusterRest))
                            clusterRepsText = ""
                        }
                    }
                }
            }
        }
        .padding(OG.pad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
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
                                Text("Drop \(drop.weightKg.map { String(format: "%g", $0) } ?? "—") × \(drop.reps)")
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
        let weight = Double(weightText.replacingOccurrences(of: ",", with: "."))
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
        beginRest(rest)
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
            if let weight { parts.append(String(format: "%g kg", weight)) }
            if parts.isEmpty { return format.displayName }
            return parts.joined(separator: " · ")
        }
        return item.plannedSets.compactSummary
    }

    private func prefill() {
        guard let current = store.state.activeSession?.currentExercise else {
            liveSets = []
            return
        }
        // Fuerza: registro manual y pesos visibles; WOD cronometrado: reloj por defecto.
        usesAutomaticTimer = (current.wodFormat != nil && current.wodFormat != .strength)
            || (current.blockTimeCapMinutes ?? 0) > 0
        let suggested = current.lastLoggedWeight
            ?? store.cachedLastWorkingWeight(for: current.exercise.id)
            ?? current.plannedSets.first?.targetWeightKg
        weightText = suggested.map { String(format: "%g", $0) } ?? ""
        repsText = "\(current.plannedSets.first?.targetReps ?? 8)"
        rebuildLiveSets(from: current)
        // Si hay peso sugerido y la primera serie pendiente no tiene peso, rellenarla.
        if let suggested,
           let idx = liveSets.firstIndex(where: { !$0.completed }),
           liveSets[idx].weightKg == nil {
            liveSets[idx].weightKg = suggested
        }
    }

    private func bumpWeightSuggestion(_ current: SessionExercise) {
        if weightText.isEmpty {
            weightText = current.lastLoggedWeight.map { String(format: "%g", $0) } ?? weightText
        }
    }

    private func bumpWeight(_ delta: Double) {
        let current = Double(weightText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let next = max(0, current + delta)
        weightText = String(format: "%g", next)
    }

    private func bumpReps(_ delta: Int) {
        let current = Int(repsText) ?? 0
        repsText = "\(max(0, current + delta))"
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
