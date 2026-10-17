import GymbroDomain
import SwiftUI

struct WorkoutView: View {
    @Environment(GymbroStore.self) private var store
    @Environment(\.dismiss) private var dismiss
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
    @State private var showWODClock = false
    @State private var wodSecondsLeft = 0
    @State private var wodElapsed = 0
    @State private var wodIntervalIndex = 0
    @State private var wodTotalIntervals = 0
    @State private var wodIntervalLength = 60
    @State private var wodIsIntervalMode = false
    @State private var wodIsCountingUp = false
    @State private var wodIsRunning = false
    @State private var wodPreCountdown = 0
    @State private var wodHasStarted = false
    @State private var wodTitle = ""
    @State private var wodSubtitle = ""
    @State private var wodClockTimer: Timer?
    @State private var clockExercise: Exercise?
    @State private var showNotes = false
    @State private var notesDraft = ""
    /// Filas editables del ejercicio actual (objetivo por serie + check para registrar).
    @State private var liveSets: [LiveSetRow] = []

    private struct LiveSetRow: Identifiable, Equatable {
        let id: UUID
        var weightKg: Double?
        var reps: Int
        var rir: Double?
        var completed: Bool
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
            if store.restCoordinator.isActive, !showWODClock {
                restDock
                    .padding(.horizontal, OG.pad)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if showWODClock {
                wodFullscreenClock
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .animation(.easeOut(duration: 0.2), value: store.restCoordinator.isActive)
        .animation(.easeOut(duration: 0.25), value: showWODClock)
        .background(OG.bg)
        .ogPinnedTransparentNav(store.state.activeSession?.title ?? "Entreno")
        .toolbar(showWODClock ? .hidden : .automatic, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CloseToolbarButton(action: { closeFlow() }, large: false)
                    .foregroundStyle(OG.label2)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        _ = store.saveActiveSessionAsFavorite()
                    } label: {
                        Label(
                            activeIsFavorite ? "En favoritos" : "Favorito",
                            systemImage: activeIsFavorite ? "star.fill" : "star"
                        )
                    }
                    Button {
                        notesDraft = store.state.activeSession?.notes ?? ""
                        showNotes = true
                    } label: {
                        Label(
                            hasSessionNotes ? "Editar nota" : "Añadir nota",
                            systemImage: hasSessionNotes ? "note.text" : "square.and.pencil"
                        )
                    }
                    Divider()
                    Button(role: .destructive) {
                        stopWODClock()
                        store.endActiveSession(save: false)
                        closeFlow()
                    } label: {
                        Label("Eliminar entreno", systemImage: "trash")
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
                if hasMoreExercises {
                    Button(store.nextIsSupersetPartner ? "Siguiente SS" : "Siguiente") {
                        store.finishCurrentExercise()
                        store.restCoordinator.skip()
                        stopWODClock()
                        if store.state.activeSession == nil {
                            closeFlow()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(OG.accent)
                } else {
                    // Terminar: círculo verde + check blanco.
                    OGToolbarGlassButton(
                        systemName: "checkmark",
                        accessibilityLabel: "Terminar",
                        tint: .white,
                        appliesGlass: true,
                        glassTint: OG.accent
                    ) {
                        stopWODClock()
                        store.endActiveSession(save: true)
                        closeFlow()
                    }
                }
            }
        }
        .sheet(isPresented: $showNotes) {
            workoutNotesSheet
        }
        .onAppear {
            prefill()
            bootstrapQuickLogIfNeeded()
        }
        .onChange(of: store.state.activeSession?.currentIndex) { _, _ in
            prefill()
            stopWODClock()
        }
        .onDisappear {
            // Rest is owned by GymbroStore.restCoordinator — do not stop on view disappear.
            stopWODClock()
        }
    }

    private func closeFlow() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    private var hasSessionNotes: Bool {
        !(store.state.activeSession?.notes?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    private var workoutNotesSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button("Cancelar") { showNotes = false }
                    .foregroundStyle(OG.label2)
                Spacer()
                Text("Notas del entreno")
                    .font(.headline)
                    .foregroundStyle(OG.label)
                Spacer()
                Button("Guardar") {
                    store.updateActiveSessionNotes(notesDraft)
                    showNotes = false
                }
                .fontWeight(.semibold)
                .foregroundStyle(OG.accent)
            }
            .padding(.top, 4)

            Text("Cómo te sentiste, sueño, molestias, PRs…")
                .font(.system(size: 14))
                .foregroundStyle(OG.label2)
            TextEditor(text: $notesDraft)
                .scrollContentBackground(.hidden)
                .padding(12)
                .frame(height: 180)
                .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
                .foregroundStyle(OG.label)
        }
        .padding(.horizontal, OG.pad)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .ogFittedHeight()
        .preferredColorScheme(.dark)
        .ogFittedSheet()
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

    private func content(_ session: WorkoutSession) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let current = session.currentExercise {
                    currentCard(current, session: session)
                    setsBoard(current)
                    if !isQuickLogSession {
                        workoutOptionsCard
                        DisclosureGroup("Opciones avanzadas de serie") {
                            logForm(current)
                                .padding(.top, 8)
                        }
                        .tint(OG.label2)
                        .font(.system(size: 14, weight: .semibold))
                    }
                }
                if !isQuickLogSession {
                    exerciseQueue(session)
                }
            }
            .padding(.horizontal, OG.pad)
            .padding(.top, 0)
            .padding(.bottom, store.restCoordinator.isActive ? 88 : 28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task(id: session.id) {
            while !Task.isCancelled, store.state.activeSession?.id == session.id {
                await HealthKitStore.shared.refreshLiveMetrics()
                try? await Task.sleep(for: .seconds(15))
            }
        }
    }

    /// Notas y ajustes del entreno (visibles en la sesión, no solo en el toolbar).
    private var workoutOptionsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            OGCardSectionTitle(title: "Opciones del entreno")
            Button {
                notesDraft = store.state.activeSession?.notes ?? ""
                showNotes = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: hasSessionNotes ? "note.text" : "square.and.pencil")
                        .foregroundStyle(hasSessionNotes ? OG.accent : OG.label2)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(hasSessionNotes ? "Editar notas" : "Añadir notas")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(OG.label)
                        Text(hasSessionNotes
                             ? (store.state.activeSession?.notes ?? "")
                             : "Cómo te sentiste, sueño, molestias…")
                            .font(.system(size: 12))
                            .foregroundStyle(OG.label2)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(OG.label3)
                }
                .padding(12)
                .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(OG.pad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }

    private func setsBoard(_ current: SessionExercise) -> some View {
        let step = store.state.settings.weightIncrementKg
        return VStack(alignment: .leading, spacing: 12) {
            Text("Series")
                .font(.headline)

            HStack(spacing: 8) {
                Text("#").frame(width: 28)
                Text("PESO (KG)").frame(maxWidth: .infinity)
                Text("REPS").frame(width: 84)
                Text("RIR").frame(width: 48)
                Color.clear.frame(width: 36)
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(OG.label3)

            ForEach(Array(liveSets.enumerated()), id: \.element.id) { index, row in
                liveSetRow(index: index, row: row, step: step, current: current)
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
        .padding(OG.pad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }

    private func liveSetRow(index: Int, row: LiveSetRow, step: Double, current: SessionExercise) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("\(index + 1)")
                    .font(.system(size: 13, weight: .bold).monospacedDigit())
                    .foregroundStyle(OG.label)
                    .frame(width: 28, height: 28)
                    .background(OG.surface2, in: Circle())

                OGRepeatStepper(
                    display: row.weightKg.map { String(format: "%g", $0) } ?? "—",
                    enabled: !row.completed,
                    keyboard: .decimalPad,
                    onMinus: { bumpLiveWeight(at: index, delta: -step) },
                    onPlus: { bumpLiveWeight(at: index, delta: step) },
                    onCommitText: { text in
                        commitLiveWeightText(at: index, text: text)
                    }
                )
                .frame(maxWidth: .infinity)

                OGRepeatStepper(
                    display: "\(row.reps)",
                    enabled: !row.completed,
                    keyboard: .numberPad,
                    onMinus: { bumpLiveReps(at: index, delta: -1) },
                    onPlus: { bumpLiveReps(at: index, delta: 1) },
                    onCommitText: { text in
                        if let value = Int(text), value > 0 {
                            setLiveReps(at: index, reps: min(50, value))
                        }
                    }
                )
                .frame(width: 96)

                Menu {
                    Button("Sin RIR") { setLiveRir(at: index, rir: nil) }
                    ForEach(0...5, id: \.self) { value in
                        Button("\(value)") { setLiveRir(at: index, rir: Double(value)) }
                    }
                } label: {
                    Text(row.rir.map { String(format: "%g", $0) } ?? "RIR")
                        .font(.system(size: 12, weight: .semibold).monospacedDigit())
                        .foregroundStyle(row.rir == nil ? OG.label3 : OG.label)
                        .frame(width: 48, height: 36)
                        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .disabled(row.completed)

                Button {
                    if row.completed {
                        if index == liveSets.count - 1 || index == current.loggedSets.count - 1 {
                            store.removeLastSet()
                            rebuildLiveSets(from: store.state.activeSession?.currentExercise ?? current)
                        }
                    } else {
                        completeLiveSet(at: index, current: current)
                    }
                } label: {
                    Image(systemName: row.completed ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 28))
                        .foregroundStyle(row.completed ? OG.accent : OG.label3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(row.completed ? "Serie hecha" : "Registrar serie")
            }

        }
    }


    private func rebuildLiveSets(from current: SessionExercise) {
        var rows: [LiveSetRow] = []
        let planned = current.plannedSets
        let logged = current.loggedSets
        let total = max(planned.count, logged.count)

        if total == 0 {
            liveSets = [LiveSetRow(id: UUID(), weightKg: nil, reps: 8, rir: nil, completed: false)]
            return
        }

        for i in 0..<total {
            if i < logged.count {
                let s = logged[i]
                rows.append(
                    LiveSetRow(
                        id: s.id,
                        weightKg: s.weightKg,
                        reps: s.reps,
                        rir: s.rir,
                        completed: true
                    )
                )
            } else {
                let p = planned[i]
                rows.append(
                    LiveSetRow(
                        id: p.id,
                        weightKg: p.targetWeightKg,
                        reps: max(1, p.targetReps),
                        rir: p.targetRir,
                        completed: false
                    )
                )
            }
        }
        liveSets = rows
    }

    private func addLiveSet(from current: SessionExercise) {
        let last = liveSets.last
        liveSets.append(
            LiveSetRow(
                id: UUID(),
                weightKg: last?.weightKg ?? current.plannedSets.last?.targetWeightKg,
                reps: last?.reps ?? current.plannedSets.last?.targetReps ?? 8,
                rir: last?.rir ?? current.plannedSets.last?.targetRir,
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

    private func bumpLiveReps(at index: Int, delta: Int) {
        guard liveSets.indices.contains(index), !liveSets[index].completed else { return }
        liveSets[index].reps = min(50, max(1, liveSets[index].reps + delta))
    }

    private func setLiveReps(at index: Int, reps: Int) {
        guard liveSets.indices.contains(index), !liveSets[index].completed else { return }
        liveSets[index].reps = min(50, max(1, reps))
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
        store.logSet(
            reps: row.reps,
            weightKg: row.weightKg,
            phase: .work,
            kind: .straight,
            rir: row.rir,
            toFailure: row.rir == 0,
            drops: [],
            clusters: []
        )
        let rest: Int = {
            if current.supersetGroup != nil {
                return max(30, store.state.settings.defaultRestSeconds / 3)
            }
            return store.state.settings.defaultRestSeconds
        }()
        beginRest(rest)
        if let updated = store.state.activeSession?.currentExercise {
            rebuildLiveSets(from: updated)
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
        let last = StatsEngine.lastWorkingWeight(exerciseId: current.exercise.id, workouts: store.state.workouts)
        let pr = StatsEngine.personalRecords(from: store.state.workouts)
            .first { $0.exerciseName == current.exercise.name }
        return VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text(current.exercise.name)
                    .font(.title2.bold())
                HStack(spacing: 8) {
                    if let label = SessionController.supersetLabel(current.supersetGroup) {
                        Text(label)
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.25), in: Capsule())
                    }
                    Text(exerciseMetaLine(current, target: target))
                        .foregroundStyle(OG.label2)
                }
                if let wod = wodPlanLabel(for: current) {
                    Text(wod)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(OG.accent)
                }
            }

            ExerciseArtView(exercise: current.exercise, showStepCaptions: true)
                .frame(maxWidth: .infinity)
                .clipped()

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
                if session.phase == .ready {
                    Button {
                        store.confirmCurrentOnWatchStyle()
                        startBlockClock(for: current)
                    } label: {
                        Text("Comenzar")
                            .font(.system(size: 18, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 64)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(OG.accent)
                    .controlSize(.large)
                } else if !showWODClock {
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
        return "\(current.exercise.muscleGroup) · \(current.plannedSets.count)×\(target?.targetReps ?? 0) @ \(target?.targetWeightKg.map { String(format: "%g kg", $0) } ?? "—")"
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
        let displaySeconds: Int = {
            if wodPreCountdown > 0 { return wodPreCountdown }
            return wodIsCountingUp ? wodElapsed : wodSecondsLeft
        }()
        let roundDisplay: Int? = wodIsIntervalMode
            ? min(wodIntervalIndex + 1, max(wodTotalIntervals, 1))
            : nil
        return BlockTimerScreen(
            title: wodTitle,
            subtitle: wodPreCountdown > 0 ? "Cuenta atrás" : wodSubtitle,
            exercise: clockExercise,
            roundNumber: roundDisplay,
            totalRounds: wodIsIntervalMode ? wodTotalIntervals : nil,
            displaySeconds: displaySeconds,
            isRunning: wodIsRunning,
            isCountingUp: wodIsCountingUp,
            primaryTitle: wodClockPrimaryTitle,
            onPrimary: handleWODPrimary,
            onClose: { stopWODClock() },
            onSkip: wodIsIntervalMode ? { advanceWODInterval() } : nil
        )
    }

    private var wodClockPrimaryTitle: String {
        if wodPreCountdown > 0 { return "…" }
        if !wodIsRunning { return "Comenzar" }
        return "Pausar"
    }

    private func handleWODPrimary() {
        if wodPreCountdown > 0 { return }
        if wodIsRunning {
            wodClockTimer?.invalidate()
            wodClockTimer = nil
            wodIsRunning = false
        } else {
            // Pre-countdown only on the first start; resume continues immediately.
            if !wodHasStarted {
                wodPreCountdown = 3
                wodHasStarted = true
            }
            wodIsRunning = true
            tickWODClock()
        }
    }

    /// Reloj a pantalla completa para cualquier tipo de bloque (EMOM, AMRAP, fuerza…).
    private func startBlockClock(for current: SessionExercise) {
        stopWODClock()
        clockExercise = current.exercise
        wodTitle = current.exercise.name
        wodElapsed = 0
        wodIsCountingUp = false
        wodIsIntervalMode = false
        wodIsRunning = false
        wodTotalIntervals = 0
        wodIntervalIndex = 0
        wodPreCountdown = 0

        let format = current.wodFormat
        switch format {
        case .emom:
            let interval = max(15, current.blockIntervalSeconds ?? 60)
            let rounds = current.plannedIntervals
                ?? current.blockRounds
                ?? current.blockTimeCapMinutes
                ?? 8
            wodIsIntervalMode = true
            wodIntervalLength = interval
            wodTotalIntervals = max(1, rounds)
            wodSecondsLeft = interval
            wodSubtitle = wodPlanLabel(for: current) ?? "EMOM"
        case .tabata:
            let work = max(5, current.blockWorkSeconds ?? 20)
            let rounds = max(1, current.blockRounds ?? 8)
            wodIsIntervalMode = true
            wodIntervalLength = work
            wodTotalIntervals = rounds * 2
            wodSecondsLeft = work
            wodSubtitle = "Tabata · trabajo"
        case .amrap, .forTime, .chipper, .afap, .deathBy, .maxEffort:
            let mins = current.blockTimeCapMinutes ?? 12
            wodSecondsLeft = max(60, mins * 60)
            wodSubtitle = wodPlanLabel(for: current) ?? format?.displayName ?? "WOD"
        case .ladder, .partner, .buyInCashOut, .roundsForQuality, .circuit:
            if let mins = current.blockTimeCapMinutes, mins > 0 {
                wodSecondsLeft = mins * 60
                wodSubtitle = wodPlanLabel(for: current) ?? format?.displayName ?? "Bloque"
            } else {
                prepareCountUpClock(subtitle: wodPlanLabel(for: current) ?? format?.displayName ?? "Bloque")
                showWODClock = true
                return
            }
        case .strength, .none:
            if let mins = current.blockTimeCapMinutes, mins > 0 {
                wodSecondsLeft = mins * 60
                wodSubtitle = wodPlanLabel(for: current) ?? "Fuerza"
            } else {
                prepareCountUpClock(subtitle: wodPlanLabel(for: current) ?? "Fuerza")
                showWODClock = true
                return
            }
        }

        showWODClock = true
    }

    private func prepareCountUpClock(subtitle: String) {
        wodIsCountingUp = true
        wodIsIntervalMode = false
        wodSecondsLeft = 0
        wodElapsed = 0
        wodSubtitle = subtitle
    }

    private func tickWODClock() {
        wodClockTimer?.invalidate()
        wodClockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                guard showWODClock else { return }
                if wodPreCountdown > 0 {
                    wodPreCountdown -= 1
                    RestFeedback.tick(
                        remaining: wodPreCountdown,
                        sound: store.state.settings.restSoundEnabled,
                        haptic: store.state.settings.restHapticEnabled
                    )
                    if wodPreCountdown == 0 {
                        RestFeedback.intervalBeep(
                            sound: store.state.settings.restSoundEnabled,
                            haptic: store.state.settings.restHapticEnabled
                        )
                    }
                    return
                }
                guard wodIsRunning else { return }
                if wodIsCountingUp {
                    wodElapsed += 1
                    return
                }
                if wodSecondsLeft <= 1 {
                    if wodIsIntervalMode, wodIntervalIndex + 1 < wodTotalIntervals {
                        advanceWODInterval()
                        RestFeedback.intervalBeep(
                            sound: store.state.settings.restSoundEnabled,
                            haptic: store.state.settings.restHapticEnabled
                        )
                    } else {
                        wodSecondsLeft = 0
                        wodIsRunning = false
                        wodClockTimer?.invalidate()
                        wodClockTimer = nil
                        RestFeedback.restComplete(
                            sound: store.state.settings.restSoundEnabled,
                            haptic: store.state.settings.restHapticEnabled
                        )
                    }
                } else {
                    wodSecondsLeft -= 1
                    if wodSecondsLeft <= 3 {
                        RestFeedback.tick(
                            remaining: wodSecondsLeft,
                            sound: store.state.settings.restSoundEnabled,
                            haptic: store.state.settings.restHapticEnabled
                        )
                    }
                }
            }
        }
    }

    private func advanceWODInterval() {
        wodIntervalIndex += 1
        let current = store.state.activeSession?.currentExercise
        if current?.wodFormat == .tabata {
            let isWork = wodIntervalIndex % 2 == 0
            let work = current?.blockWorkSeconds ?? 20
            let rest = current?.blockRestSeconds ?? 10
            wodIntervalLength = isWork ? work : rest
            wodSubtitle = isWork ? "Tabata · trabajo" : "Tabata · descanso"
        }
        wodSecondsLeft = wodIntervalLength
        RestFeedback.intervalBeep(
            sound: store.state.settings.restSoundEnabled,
            haptic: store.state.settings.restHapticEnabled
        )
    }

    private func stopWODClock(keepVisible: Bool = false) {
        wodClockTimer?.invalidate()
        wodClockTimer = nil
        wodIsRunning = false
        if !keepVisible {
            showWODClock = false
            wodSecondsLeft = 0
            wodElapsed = 0
            wodIntervalIndex = 0
            wodTotalIntervals = 0
            wodIsCountingUp = false
            wodPreCountdown = 0
            clockExercise = nil
        }
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
            if current.supersetGroup != nil {
                return max(30, store.state.settings.defaultRestSeconds / 3)
            }
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
                            Button {
                                store.selectExercise(at: index)
                            } label: {
                                HStack(spacing: 12) {
                                    ExerciseThumb(exercise: item.exercise, size: 44)
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 6) {
                                            Text(item.exercise.name)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundStyle(OG.label)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.leading)
                                            if let label = SessionController.supersetLabel(item.supersetGroup) {
                                                Text(label)
                                                    .font(.caption2.bold())
                                                    .foregroundStyle(OG.orange)
                                            }
                                        }
                                        Text(queueRowSubtitle(item))
                                            .font(.system(size: 12))
                                            .foregroundStyle(OG.label3)
                                            .lineLimit(1)
                                    }
                                    Spacer(minLength: 6)
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
                                }
                                .padding(10)
                                .background(
                                    index == session.currentIndex ? OG.surface3 : OG.surface2,
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                )
                            }
                            .buttonStyle(.plain)
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
        let target = item.plannedSets.first
        let weight = target?.targetWeightKg.map { String(format: "%g kg", $0) } ?? "—"
        return "\(item.plannedSets.count)×\(target?.targetReps ?? 0) @ \(weight)"
    }

    private func prefill() {
        guard let current = store.state.activeSession?.currentExercise else {
            liveSets = []
            return
        }
        let suggested = current.lastLoggedWeight
            ?? StatsEngine.lastWorkingWeight(exerciseId: current.exercise.id, workouts: store.state.workouts)
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
