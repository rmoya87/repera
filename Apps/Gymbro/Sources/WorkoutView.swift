import GymbroDomain
import SwiftUI

struct WorkoutView: View {
    @Environment(GymbroStore.self) private var store
    @Environment(\.dismiss) private var dismiss
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
    @State private var restRemaining = 0
    @State private var restTimer: Timer?
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
    @State private var wodTitle = ""
    @State private var wodSubtitle = ""
    @State private var wodClockTimer: Timer?
    @State private var clockExercise: Exercise?

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if let session = store.state.activeSession {
                    content(session)
                } else {
                    ContentUnavailableView("Sin sesión", systemImage: "pause.circle", description: Text("Vuelve a Inicio para empezar."))
                }
            }
            if restRemaining > 0, !showWODClock {
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
        .animation(.easeOut(duration: 0.2), value: restRemaining)
        .animation(.easeOut(duration: 0.25), value: showWODClock)
        .background(OG.bg)
        .navigationTitle(store.state.activeSession?.title ?? "Sesión")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(OG.bg, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(showWODClock ? .hidden : .automatic, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CloseToolbarButton { dismiss() }
                    .foregroundStyle(OG.label2)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    _ = store.saveActiveSessionAsFavorite()
                } label: {
                    Image(systemName: activeIsFavorite ? "star.fill" : "star")
                        .foregroundStyle(activeIsFavorite ? OG.yellow : OG.label2)
                }
                .accessibilityLabel("Guardar en favoritos")
            }
            ToolbarItem(placement: .topBarTrailing) {
                if hasMoreExercises {
                    Button(store.nextIsSupersetPartner ? "Siguiente SS" : "Siguiente") {
                        store.finishCurrentExercise()
                        stopRest()
                        stopWODClock()
                        if store.state.activeSession == nil {
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(OG.accent)
                } else {
                    Button("Terminar") {
                        stopWODClock()
                        store.endActiveSession(save: true)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(OG.accent)
                }
            }
        }
        .onAppear { prefill() }
        .onChange(of: store.state.activeSession?.currentIndex) { _, _ in
            prefill()
            stopWODClock()
        }
        .onDisappear {
            stopRest()
            stopWODClock()
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

    private func content(_ session: WorkoutSession) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let current = session.currentExercise {
                    currentCard(current, session: session)
                    logForm(current)
                    loggedList(current)
                }
                exerciseQueue(session)
            }
            .padding(.horizontal, OG.pad)
            .padding(.vertical, 12)
            .padding(.bottom, restRemaining > 0 ? 88 : 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task(id: session.id) {
            while !Task.isCancelled, store.state.activeSession?.id == session.id {
                await HealthKitStore.shared.refreshLiveMetrics()
                try? await Task.sleep(for: .seconds(15))
            }
        }
    }

    private var restDock: some View {
        HStack(spacing: 14) {
            Image(systemName: "timer")
                .font(.title2.bold())
                .foregroundStyle(OG.orange)
                .symbolEffect(.pulse, options: .repeating, isActive: restRemaining > 0)
            VStack(alignment: .leading, spacing: 2) {
                Text("Descanso")
                    .font(.caption)
                    .foregroundStyle(OG.label2)
                Text("\(restRemaining)s")
                    .font(.system(size: 28, weight: .bold).monospacedDigit())
                    .foregroundStyle(OG.label)
            }
            Spacer()
            Button("Saltar") {
                stopRest(announce: false)
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(OG.accent)
        }
        .padding(16)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 18))
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
            if let weight = target?.targetWeightKg ?? Double(weightText.replacingOccurrences(of: ",", with: ".")),
               weight > 0 {
                let solution = PlateMath.solve(
                    targetKg: weight,
                    barKg: store.state.settings.barbellKg,
                    availablePlatesKg: store.state.settings.ownedPlatesKg
                )
                Label(solution.summary, systemImage: "circle.grid.cross")
                    .font(.caption)
                    .foregroundStyle(OG.label2)
            }
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
        .padding(OG.pad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
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
            wodPreCountdown = 3
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
            Text("Registrar serie")
                .font(.headline)

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
                    HStack(spacing: 8) {
                        Button {
                            bumpWeight(-store.state.settings.weightIncrementKg)
                        } label: {
                            Image(systemName: "minus")
                                .frame(width: 40, height: 40)
                                .background(OG.surface2, in: Circle())
                        }
                        TextField("0", text: $weightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .font(.title3.monospacedDigit())
                            .frame(minWidth: 48)
                        Button {
                            bumpWeight(store.state.settings.weightIncrementKg)
                        } label: {
                            Image(systemName: "plus")
                                .frame(width: 40, height: 40)
                                .background(OG.surface2, in: Circle())
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Reps").font(.caption).foregroundStyle(OG.label2)
                    HStack(spacing: 8) {
                        Button {
                            bumpReps(-1)
                        } label: {
                            Image(systemName: "minus")
                                .frame(width: 40, height: 40)
                                .background(OG.surface2, in: Circle())
                        }
                        TextField("0", text: $repsText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.title3.monospacedDigit())
                            .frame(minWidth: 36)
                        Button {
                            bumpReps(1)
                        } label: {
                            Image(systemName: "plus")
                                .frame(width: 40, height: 40)
                                .background(OG.surface2, in: Circle())
                        }
                    }
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
                            .keyboardType(.decimalPad)
                        TextField("reps", text: $dropRepsText)
                            .keyboardType(.numberPad)
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
                            .keyboardType(.numberPad)
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
        startRest(rest)
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
        guard let current = store.state.activeSession?.currentExercise else { return }
        let suggested = current.lastLoggedWeight
            ?? StatsEngine.lastWorkingWeight(exerciseId: current.exercise.id, workouts: store.state.workouts)
            ?? current.plannedSets.first?.targetWeightKg
        weightText = suggested.map { String(format: "%g", $0) } ?? ""
        repsText = "\(current.plannedSets.first?.targetReps ?? 8)"
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

    private func startRest(_ seconds: Int) {
        stopRest(announce: false)
        restRemaining = seconds
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if restRemaining <= 1 {
                    stopRest(announce: true)
                } else {
                    restRemaining -= 1
                    RestFeedback.tick(
                        remaining: restRemaining,
                        sound: store.state.settings.restSoundEnabled,
                        haptic: store.state.settings.restHapticEnabled
                    )
                }
            }
        }
    }

    private func stopRest(announce: Bool = false) {
        restTimer?.invalidate()
        restTimer = nil
        if announce && restRemaining <= 1 {
            RestFeedback.restComplete(
                sound: store.state.settings.restSoundEnabled,
                haptic: store.state.settings.restHapticEnabled
            )
        }
        restRemaining = 0
    }
}
