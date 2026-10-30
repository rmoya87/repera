import ReperaDomain
import SwiftUI
import WatchKit

/// The first screen is always the day's workout, or the currently running session.
struct WatchSessionView: View {
    @Environment(WatchSessionHub.self) private var hub
    @State private var showOutline = false
    @State private var showSetDetails = false
    @State private var confirmLiveFinish = false

    // Exact Repera iOS theme accent (OG.accent, #30D158).
    // Filled accent buttons use OG.onAccent: black.
    private let accent = Color(red: 48 / 255, green: 209 / 255, blue: 88 / 255)

    var body: some View {
        NavigationStack {
            Group {
                if let finished = hub.presentedSummary {
                    finishedView(finished)
                } else if let active = hub.active {
                    if hub.reviewingBlock {
                        blockReviewView(active)
                    } else if active.phase == .counting {
                        runningView(active)
                    } else {
                        readyView(active)
                    }
                } else if let live = hub.liveActivity {
                    liveActivityView(live)
                } else if let today = hub.todaysWorkout {
                    todayView(today)
                } else {
                    emptyView
                }
            }
            .navigationTitle(pageTitle)
            .navigationBarTitleDisplayMode(.automatic)
            .sheet(isPresented: $showOutline) {
                if let workout = hub.active { outlineView(workout) }
            }
            .sheet(isPresented: $showSetDetails) { setDetailsView }
            .confirmationDialog("¿Finalizar actividad?", isPresented: $confirmLiveFinish) {
                Button("Finalizar y revisar en iPhone", role: .destructive) {
                    hub.controlLiveActivity("finish")
                }
                Button("Cancelar", role: .cancel) {}
            }
        }
        .tint(accent)
    }

    /// Native watchOS navigation title sits under the system clock.
    /// Do not repeat it as a heading inside scrolling workout content.
    private var pageTitle: String {
        if hub.presentedSummary != nil { return "Resultado" }
        if hub.reviewingBlock { return hub.current?.displayBlockHeader ?? "Resultado" }
        if let active = hub.active {
            return hub.current?.displayBlockHeader ?? active.title
        }
        if let live = hub.liveActivity { return live.sportTitle }
        return hub.todaysWorkout?.title ?? "Repera"
    }

    /// Companion screen: iPhone owns GPS, HealthKit and persistence.
    /// The watch displays aggregate metrics and sends validated controls only.
    private func liveActivityView(_ live: WatchLiveActivitySnapshot) -> some View {
        ScrollView {
            VStack(spacing: 9) {
                Text(live.phase == .review ? "Pendiente de guardar en iPhone"
                     : (live.phase == .paused ? "En pausa" : "Actividad en curso"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(timeLabel(Int(live.displayElapsed(at: context.date))))
                        .font(.system(size: 37, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                Text("Tiempo activo").font(.caption2).foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    VStack {
                        Text(ReperaNumberFormat.decimal(live.distanceMeters / 1000))
                            .font(.title3.weight(.bold))
                        Text("km").font(.caption2).foregroundStyle(.secondary)
                    }
                    if let speed = live.averageSpeedKmh {
                        VStack {
                            Text(ReperaNumberFormat.decimal(speed))
                                .font(.title3.weight(.bold))
                            Text("km/h media").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
                if let turn = live.nextTurn, live.phase != .review {
                    Label(turn, systemImage: "arrow.turn.up.right")
                        .font(.caption2)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(.white.opacity(0.08),
                                    in: RoundedRectangle(cornerRadius: 10))
                }
                if live.phase != .review {
                    HStack(spacing: 10) {
                        Button {
                            hub.controlLiveActivity(live.phase == .paused ? "resume" : "pause")
                        } label: {
                            Image(systemName: live.phase == .paused ? "play.fill" : "pause.fill")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.black)
                                .frame(minWidth: 58, minHeight: 52)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(accent)
                        .accessibilityLabel(live.phase == .paused ? "Reanudar" : "Pausar")
                        Button { confirmLiveFinish = true } label: {
                            Image(systemName: "flag.checkered")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.black)
                                .frame(minWidth: 58, minHeight: 52)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(accent)
                        .accessibilityLabel("Finalizar actividad")
                    }
                }
                if let message = hub.liveCommandError {
                    Text(message).font(.caption2).foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, 7)
        }
    }

    private var emptyView: some View {
        GeometryReader { available in
            VStack(spacing: 8) {
                Spacer(minLength: 2)
                Image("MascotWatch")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        maxWidth: min(available.size.width * 0.84, 170),
                        maxHeight: min(available.size.height * 0.62, 170)
                    )
                    .accessibilityHidden(true)
                Text("Sin plan descargado")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 2)
                Button {
                    hub.refreshToday()
                } label: {
                    Label("Sincronizar", systemImage: "arrow.triangle.2.circlepath")
                        .font(.callout.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(.borderedProminent)
                .tint(accent)
                .foregroundStyle(.black)
                .accessibilityHint("Solicita la planificación actual del día al iPhone")
            }
            .frame(maxWidth: .infinity)
            .frame(height: available.size.height)
            .padding(.horizontal, 8)
        }
    }

    private func todayView(_ session: WorkoutSession) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                // The format and time are useful; movement/block counts are not.
                HStack(spacing: 5) {
                    Text(planFormat(session))
                    Spacer(minLength: 4)
                    Label(planDuration(session), systemImage: "timer")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)

                ForEach(blockStarts(in: session), id: \.self) { index in
                    let first = session.exercises[index]
                    Button {
                        hub.startToday()
                        hub.selectBlock(startingAt: index)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(first.displayBlockHeader)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.secondary)
                            }
                            blockExerciseRows(session, startingAt: index)
                        }
                        .padding(9)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.07),
                                    in: RoundedRectangle(cornerRadius: 13))
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Iniciar el entrenamiento directamente por este bloque")
                }

                Button { hub.startToday() } label: {
                    Label("Iniciar entreno", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(accent)
                .foregroundStyle(.black)
                .accessibilityHint("El entrenamiento se registrará en este reloj")
            }
            .padding(.horizontal, 5)
        }
    }

    private func planFormat(_ session: WorkoutSession) -> String {
        let hasStrength = session.exercises.contains { $0.blockKind == .strength }
        let hasWOD = session.exercises.contains { $0.blockKind == .wod }
        if hasStrength && hasWOD { return "Mixto" }
        return session.exercises.first?.wodFormat?.displayName ?? "Fuerza"
    }

    private func planDuration(_ session: WorkoutSession) -> String {
        let cap = session.routineBlocks?.compactMap(\.timeCapMinutes).reduce(0, +) ?? 0
        return cap > 0 ? "\(cap) min" : "Sin límite"
    }

    private func blockStarts(in session: WorkoutSession) -> [Int] {
        var result: [Int] = []
        var last: UUID?
        for index in session.exercises.indices {
            let id = session.exercises[index].blockId
            if result.isEmpty || id == nil || last == nil || id != last {
                result.append(index)
            }
            last = id
        }
        return result
    }

    private func blockMembers(in session: WorkoutSession, startingAt start: Int) -> [Int] {
        guard session.exercises.indices.contains(start) else { return [] }
        guard let blockID = session.exercises[start].blockId else { return [start] }
        return session.exercises.indices.filter {
            $0 >= start && session.exercises[$0].blockId == blockID
        }
    }

    private func exerciseRow(_ exercise: SessionExercise) -> some View {
        HStack(alignment: .center, spacing: 8) {
            WatchExerciseThumb(exercise: exercise.exercise, size: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text(SportExerciseNames.localizedDisplayName(exercise.exercise.name))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(exercise.prescriptionSummaryLine)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 7)
    }

    private func blockExerciseRows(_ session: WorkoutSession, startingAt start: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(blockMembers(in: session, startingAt: start), id: \.self) { index in
                if index != start {
                    Divider().overlay(.gray.opacity(0.3))
                }
                exerciseRow(session.exercises[index])
            }
        }
    }

    private func readyView(_: WorkoutSession) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 9) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(hub.blockExercises) { exercise in
                        if exercise.id != hub.blockExercises.first?.id {
                            Divider().overlay(.gray.opacity(0.3))
                        }
                        exerciseRow(exercise)
                    }
                }
                .padding(.horizontal, 10)
                .background(.white.opacity(0.07),
                            in: RoundedRectangle(cornerRadius: 13))
                if let minutes = hub.current?.blockTimeCapMinutes {
                    Label("\(minutes) min", systemImage: "timer")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Button { hub.play() } label: {
                    Label(hub.currentIsWOD ? "Iniciar bloque" : "Empezar ejercicio",
                          systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(accent)
                .foregroundStyle(.black)
                Button("Resumen") { showOutline = true }
                    .font(.caption)
                    .buttonStyle(.borderedProminent)
                    .tint(accent)
                    .foregroundStyle(.black)
                Button("Descartar entreno", role: .destructive) {
                    hub.discardActiveSession()
                }
                .font(.caption)
            }
            .padding(.horizontal, 5)
        }
    }

    private func runningView(_: WorkoutSession) -> some View {
        ScrollView {
            VStack(spacing: 8) {
                clockControls
                if hub.restRemaining > 0 {
                    if hub.isIntervalClock {
                        // The interval countdown is already the large clock.
                        Button("Saltar descanso") { hub.skipRest() }
                            .buttonStyle(.borderedProminent)
                            .tint(accent)
                            .foregroundStyle(.black)
                            .disabled(hub.isPaused)
                    } else {
                        restView(hub.restRemaining)
                    }
                } else if hub.currentIsWOD && !hub.wodUsesSeries {
                    wodContent
                } else {
                    seriesContent
                }
                HStack(spacing: 8) {
                    Button("Resumen") { showOutline = true }
                        .font(.caption.weight(.medium))
                        .buttonStyle(.borderedProminent)
                        .tint(accent)
                        .foregroundStyle(.black)
                    Spacer(minLength: 0)
                    Button {
                        hub.confirmAndAdvance()
                    } label: {
                        Image(systemName: hub.nextActionIsFinish ? "checkmark" : "arrow.right")
                            .font(.title3.weight(.bold))
                            .frame(minWidth: 48, minHeight: 42)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(accent)
                    .foregroundStyle(.black)
                    .accessibilityLabel(hub.nextActionIsFinish ? "Terminar" : "Siguiente")
                    .accessibilityHint(
                        hub.currentIsWOD && !hub.wodUsesSeries
                            ? "Abrir el resultado del WOD"
                            : "Guardar la serie confirmada y avanzar cuando corresponda"
                    )
                    .disabled(!hub.canConfirmCurrentEntry)
                }
                Button("Descartar entreno", role: .destructive) {
                    hub.discardActiveSession()
                }
                .font(.caption2)
            }
            .padding(.horizontal, 5)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 35).onEnded { drag in
                let horizontal = drag.translation.width
                guard abs(horizontal) > abs(drag.translation.height) * 1.5 else { return }
                hub.swipeSet(horizontal < 0 ? 1 : -1)
            }
        )
    }

    @ViewBuilder
    private var clockControls: some View {
        HStack(alignment: .center, spacing: 6) {
            VStack(alignment: .leading, spacing: 1) {
                // EMOM, Tabata, Death By and Circuit show ONLY the current
                // interval countdown as the main clock, never total duration.
                Text(timeLabel(hub.primaryClockSeconds))
                    .font(.system(size: 43, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                    .accessibilityLabel(
                        hub.isIntervalClock ? "Tiempo del intervalo"
                            : (hub.clockCountsUp ? "Tiempo transcurrido" : "Tiempo restante")
                    )
                if let descriptor = hub.clockDescriptor {
                    Text(descriptor)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                if hub.isPaused { hub.play() } else { hub.pause() }
            } label: {
                Image(systemName: hub.isPaused ? "play.fill" : "pause.fill")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(width: 70, height: 70)
                    .background(accent, in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(hub.isPaused ? "Reanudar entrenamiento" : "Pausar entrenamiento")
        }
        HStack(spacing: 12) {
            if let pulse = hub.heartRateBpm {
                Label("\(pulse) lpm", systemImage: "heart.fill")
                    .foregroundStyle(.red)
            }
            if let kcal = hub.measuredEnergyKcal {
                Label("\(Int(kcal.rounded())) kcal", systemImage: "flame.fill")
                    .foregroundStyle(.orange)
            }
        }
        .font(.caption2)
        if let warning = hub.healthWarning {
            Label(warning, systemImage: "heart.slash")
                .font(.caption2)
                .foregroundStyle(.orange)
        }
    }

    private var wodContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(hub.blockExercises) { exercise in
                    if exercise.id != hub.blockExercises.first?.id {
                        Divider().overlay(.gray.opacity(0.3))
                    }
                    exerciseRow(exercise)
                }
            }
            .padding(.horizontal, 9)
            .background(.white.opacity(0.07),
                        in: RoundedRectangle(cornerRadius: 13))
            if hub.wodUsesSeries {
                HStack(spacing: 6) {
                    valueStepButton(symbol: "minus", label: "Restar repetición") {
                        hub.adjustReps(-1)
                    }
                    .disabled(hub.isPaused)
                    Text("\(hub.workingReps)")
                        .font(.system(size: 39, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .frame(maxWidth: .infinity)
                    valueStepButton(symbol: "plus", label: "Sumar repetición") {
                        hub.adjustReps(1)
                    }
                    .disabled(hub.isPaused)
                }
            }

        }
    }

    private var seriesContent: some View {
        VStack(spacing: 8) {
            Button {
                // Keep complete logging parity without occupying Play with
                // RIR and advanced fields. Tap the exercise to edit them.
                showSetDetails = true
            } label: {
                HStack(alignment: .center, spacing: 9) {
                    if let exercise = hub.current?.exercise {
                        WatchExerciseThumb(exercise: exercise, size: 53)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(
                            hub.current.map {
                                SportExerciseNames.localizedDisplayName($0.exercise.name)
                            } ?? "Ejercicio"
                        )
                            .font(.caption.weight(.semibold))
                            .fixedSize(horizontal: false, vertical: true)
                        Text(hub.setDraft.phase == .warmup ? "Calentamiento"
                             : "Serie \(hub.displayedSetNumber) de \(max(1, hub.plannedSets))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Editar detalles del ejercicio y serie")
            .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 6) {
                valueStepButton(symbol: "minus", label: "Restar repetición") {
                    hub.adjustReps(-1)
                }
                .disabled(hub.isPaused)
                Text("\(hub.effectiveReps)")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .monospacedDigit()
                    .frame(maxWidth: .infinity)
                    .focusable(true)
                    .digitalCrownRotation(
                        Binding(get: { Double(hub.workingReps) },
                                set: { hub.adjustReps(Int($0.rounded()) - hub.workingReps) }),
                        from: 0, through: 500, by: 1,
                        sensitivity: .medium, isContinuous: false,
                        isHapticFeedbackEnabled: true
                    )
                    .accessibilityLabel("Repeticiones, ajustables con la corona")
                valueStepButton(symbol: "plus", label: "Sumar repetición") {
                    hub.adjustReps(1)
                }
                .disabled(hub.isPaused)
            }

            Text(hub.loggingStyle == .machineWork ? hub.setDraft.unit.shortLabel
                 : (hub.loggingStyle == .repsAndTime ? "Veces" : "Reps"))
                .font(.caption2)
                .foregroundStyle(.secondary)
            exerciseFields
            if hub.currentIsWOD && hub.wodUsesSeries && !hub.isPaused {
                // EMOM and Tabata may have more intervals than exercises.
                // A separate explicit action closes their block score.
                Button("Terminar bloque") { hub.reviewBlock() }
                    .buttonStyle(.borderedProminent)
                    .tint(accent)
                    .foregroundStyle(.black)
                    .font(.caption2)
            }
        }
    }

    /// Reuse iPhone's loggingStyle so irrelevant fields never appear.
    @ViewBuilder
    private var exerciseFields: some View {
        switch hub.loggingStyle {
        case .loadAndReps:
            if hub.current?.exercise.loadField == .deficitCm {
                metricStepper(label: "Déficit (cm)",
                    value: "\(hub.setDraft.deficitCm ?? 0)",
                    down: { hub.adjustDeficit(-1) },
                    up: { hub.adjustDeficit(1) })
            } else {
                metricStepper(label: "Peso kg",
                    value: hub.workingWeightKg.map { ReperaNumberFormat.decimal($0) } ?? "—",
                    down: { hub.adjustWeight(-0.5) },
                    up: { hub.adjustWeight(0.5) })
            }
        case .repsOnly:
            EmptyView()
        case .repsAndTime:
            durationControls
        case .machineWork:
            HStack(spacing: 5) {
                Button {
                    hub.selectUnit(.calories)
                } label: {
                    Label("Cal", systemImage: hub.setDraft.unit == .calories
                          ? "checkmark.circle.fill" : "circle")
                }
                Button {
                    hub.selectUnit(.meters)
                } label: {
                    Label("Metros", systemImage: hub.setDraft.unit == .meters
                          ? "checkmark.circle.fill" : "circle")
                }
            }
            .font(.caption2)
            .buttonStyle(.borderedProminent)
            .tint(accent)
            .foregroundStyle(.black)
            durationControls
        }
    }

    private var rirControls: some View {
        metricStepper(
            label: "RIR",
            value: hub.setDraft.rir.map { ReperaNumberFormat.decimal($0) } ?? "—",
            down: { hub.setRIR(max(0, (hub.setDraft.rir ?? 3) - 1)) },
            up: { hub.setRIR(min(5, (hub.setDraft.rir ?? 1) + 1)) }
        )
    }

    private var durationControls: some View {
        metricStepper(label: "Tiempo serie",
            value: timeLabel(hub.setDraft.durationSeconds ?? 0),
            down: { hub.adjustDuration(-5) },
            up: { hub.adjustDuration(5) })
    }

    /// One identical, glanceable interaction for reps, weight, deficit,
    /// duration, RIR and machine scores. Never rely on gray system buttons.
    private func valueStepButton(symbol: String, label: String,
                                 action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title2.weight(.bold))
                .foregroundStyle(.black)
                .frame(width: 58, height: 62)
                .background(accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func metricStepper(label: String, value: String,
        down: @escaping () -> Void, up: @escaping () -> Void) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                valueStepButton(symbol: "minus", label: "Reducir \(label)", action: down)
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .frame(maxWidth: .infinity)
                valueStepButton(symbol: "plus", label: "Aumentar \(label)", action: up)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .disabled(hub.isPaused && !hub.reviewingBlock)
    }

    private var setDetailsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 9) {
                Text("Detalles de serie").font(.headline)
                if hub.loggingStyle.usesRIR {
                    rirControls
                    Toggle("Al fallo", isOn: Binding(
                        get: { hub.setDraft.toFailure },
                        set: { hub.setToFailure($0) }
                    ))
                    Button("Sin RIR") { hub.setRIR(nil) }
                        .font(.caption2)
                        .buttonStyle(.borderedProminent)
                        .tint(accent)
                        .foregroundStyle(.black)
                }
                if hub.current?.exercise.loadField == .weightKg {
                    metricStepper(
                        label: "Ajuste fino kg",
                        value: hub.workingWeightKg.map { ReperaNumberFormat.decimal($0) } ?? "—",
                        down: { hub.adjustWeight(-0.1) },
                        up: { hub.adjustWeight(0.1) }
                    )
                }
                Picker("Fase", selection: Binding(
                    get: { hub.setDraft.phase },
                    set: { hub.setPhase($0) }
                )) {
                    Text("Trabajo").tag(SetPhase.work)
                    Text("Calentamiento").tag(SetPhase.warmup)
                }
                Picker("Tipo de serie", selection: Binding(
                    get: { hub.setDraft.kind },
                    set: { hub.setKind($0) }
                )) {
                    Text("Normal").tag(SetKind.straight)
                    Text("Drop set").tag(SetKind.dropset)
                    Text("Rest-pause").tag(SetKind.restpause)
                }
                if hub.setDraft.kind == .dropset {
                    ForEach(hub.setDraft.drops) { drop in
                        VStack(alignment: .leading, spacing: 3) {
                            metricStepper(label: "Drop reps", value: "\(drop.reps)",
                                down: { hub.adjustDrop(id: drop.id, reps: -1) },
                                up: { hub.adjustDrop(id: drop.id, reps: 1) })
                            metricStepper(label: "Drop kg",
                                value: drop.weightKg.map { ReperaNumberFormat.decimal($0) } ?? "0",
                                down: { hub.adjustDrop(id: drop.id, weightKg: -0.5) },
                                up: { hub.adjustDrop(id: drop.id, weightKg: 0.5) })
                            Button("Eliminar drop") {
                                hub.removeDrop(id: drop.id)
                            }
                            .font(.caption2)
                            .buttonStyle(.borderedProminent)
                            .tint(accent)
                            .foregroundStyle(.black)
                        }
                    }
                    Button("Añadir drop") { hub.addDrop() }.buttonStyle(.borderedProminent)
                    .tint(accent)
                    .foregroundStyle(.black)
                }
                if hub.setDraft.kind == .restpause {
                    ForEach(hub.setDraft.clusters) { cluster in
                        VStack(alignment: .leading, spacing: 3) {
                            metricStepper(label: "Reps bloque", value: "\(cluster.reps)",
                                down: { hub.adjustCluster(id: cluster.id, reps: -1) },
                                up: { hub.adjustCluster(id: cluster.id, reps: 1) })
                            metricStepper(label: "Pausa (s)", value: "\(cluster.restSeconds)",
                                down: { hub.adjustCluster(id: cluster.id, restSeconds: -5) },
                                up: { hub.adjustCluster(id: cluster.id, restSeconds: 5) })
                            Button("Eliminar bloque") {
                                hub.removeCluster(id: cluster.id)
                            }
                            .font(.caption2)
                            .buttonStyle(.borderedProminent)
                            .tint(accent)
                            .foregroundStyle(.black)
                        }
                    }
                    Button("Añadir bloque") { hub.addCluster() }.buttonStyle(.borderedProminent)
                    .tint(accent)
                    .foregroundStyle(.black)
                }
                Button("Listo") { showSetDetails = false }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                    .tint(accent)
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, 7)
        }
    }

    private func restView(_ seconds: Int) -> some View {
        VStack(spacing: 9) {
            Image(systemName: "hourglass")
                .font(.title3)
                .foregroundStyle(.yellow)
            Text("Descanso")
                .font(.headline)
            Text(timeLabel(seconds))
                .font(.system(size: 37, weight: .bold, design: .rounded))
                .monospacedDigit()
            Button("Saltar descanso") { hub.skipRest() }
                .buttonStyle(.borderedProminent)
                .tint(accent)
                .foregroundStyle(.black)
                .disabled(hub.isPaused)
        }
    }

    private func blockReviewView(_ session: WorkoutSession) -> some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("Resultado del bloque")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                if hub.current?.wodFormat == .amrap ||
                    hub.current?.wodFormat == .deathBy ||
                    hub.current?.wodFormat == .roundsForQuality {
                    scoreStepper(label: "Rondas", value: hub.completedRounds,
                                 down: { hub.adjustRounds(-1) }, up: { hub.adjustRounds(1) })
                }
                if hub.current?.wodFormat?.resultCapture == .totalReps {
                    scoreStepper(
                        label: hub.current?.wodFormat == .amrap
                            ? "Reps adicionales" : "Repeticiones totales",
                        value: hub.remainingRoundReps,
                        down: { hub.adjustExtraReps(-1) },
                        up: { hub.adjustExtraReps(1) }
                    )
                }
                if hub.current?.wodFormat?.resultCapture == .elapsedTime {
                    metricStepper(
                        label: "Tiempo final",
                        value: timeLabel(hub.reviewElapsedSeconds ?? hub.blockElapsed),
                        down: { hub.adjustScoreSeconds(-1) },
                        up: { hub.adjustScoreSeconds(1) }
                    )
                } else {
                    Text("Tiempo: \(timeLabel(hub.blockElapsed))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if hub.current?.wodFormat == .emom || hub.current?.wodFormat == .tabata {
                    Text("Los intervalos se controlan automáticamente. No se inventan repeticiones.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                Button("Terminar") { hub.confirmBlock() }
                    .buttonStyle(.borderedProminent)
                    .tint(accent)
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, 6)
        }
    }

    private func scoreStepper(label: String, value: Int,
                              down: @escaping () -> Void, up: @escaping () -> Void) -> some View {
        metricStepper(label: label, value: "\(value)", down: down, up: up)
    }

    private func outlineView(_ session: WorkoutSession) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Spacer(minLength: 0)
                    Text("Resumen")
                        .font(.headline)
                }
                Text(session.title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                ForEach(blockStarts(in: session), id: \.self) { index in
                    let exercise = session.exercises[index]
                    Button {
                        hub.selectBlock(startingAt: index)
                        showOutline = false
                    } label: {
                        VStack(alignment: .leading, spacing: 7) {
                            HStack(spacing: 6) {
                                Text(exercise.displayBlockHeader)
                                    .font(.caption.weight(.semibold))
                                Spacer(minLength: 3)
                                if session.currentIndex == index {
                                    Image(systemName: "play.circle.fill")
                                        .foregroundStyle(accent)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.secondary)
                            }
                            blockExerciseRows(session, startingAt: index)
                        }
                        .padding(7)
                        .background(.white.opacity(0.07),
                                    in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Ir al bloque sin confirmar los ejercicios omitidos")
                }
                Button {
                    showOutline = false
                    hub.finishFromSummary()
                } label: {
                    Label("Finalizar entrenamiento", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(accent)
                .foregroundStyle(.black)
                .tint(accent)
                .accessibilityHint("Finaliza el entrenamiento guardando lo registrado")
            }
            .padding(.horizontal, 5)
        }
    }

    private func finishedView(_ session: WorkoutSession) -> some View {
        let sets = session.exercises.flatMap(\.loggedSets)
        let reps = sets.reduce(0) { $0 + $1.reps }
        return ScrollView {
            VStack(spacing: 9) {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(accent)
                    Text("¡Bien hecho!")
                        .font(.headline)
                    Spacer(minLength: 0)
                }
                Text(session.title)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
                // Normal HealthKit saves are silent. Surface only real failures.
                if let warning = hub.healthWarning {
                    Label(warning, systemImage: "exclamationmark.triangle")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                statsLine(
                    icon: "clock", label: "Tiempo",
                    value: timeLabel(summaryDurationSeconds(session))
                )
                if let energy = session.appleActiveEnergyKcal {
                    statsLine(icon: "flame.fill", label: "Calorías",
                              value: "\(Int(energy.rounded())) kcal")
                }
                if let bpm = session.appleAverageHeartRateBpm {
                    statsLine(icon: "heart.fill", label: "FC media",
                              value: "\(Int(bpm.rounded())) lpm")
                }
                statsLine(icon: "list.number", label: "Series", value: "\(sets.count)")
                statsLine(icon: "number", label: "Repeticiones", value: "\(reps)")
                statsLine(icon: "scalemass", label: "Volumen",
                          value: "\(Int(session.totalVolumeKg.rounded())) kg")
                ForEach(session.wodResults) { result in
                    statsLine(icon: "timer", label: result.format?.displayName ?? "WOD",
                              value: result.summaryLabel)
                }
                Button("Volver al inicio") { hub.clearSummary() }
                    .buttonStyle(.borderedProminent)
                    .tint(accent)
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, 6)
        }
    }

    private func statsLine(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).frame(width: 16)
                .foregroundStyle(accent)
            Text(label).font(.caption2)
            Spacer(minLength: 2)
            Text(value).font(.caption2.weight(.semibold))
                .monospacedDigit()
        }
    }

    private func timeLabel(_ seconds: Int) -> String {
        let n = max(0, seconds)
        if n >= 3600 {
            return String(format: "%d:%02d:%02d", n / 3600, (n / 60) % 60, n % 60)
        }
        return String(format: "%02d:%02d", n / 60, n % 60)
    }

    /// Prefiere duración HK razonable; evita mm:ss hinchados (p. ej. «5865:52»)
    /// cuando `startedAt` quedó antiguo respecto al cierre real.
    private func summaryDurationSeconds(_ session: WorkoutSession) -> Int {
        let wall: Int = {
            guard let start = session.startedAt, let end = session.finishedAt else { return 0 }
            return max(0, Int(end.timeIntervalSince(start)))
        }()
        let apple = session.appleDurationSeconds.map { max(0, Int($0.rounded())) } ?? 0
        let limit = 12 * 3600
        let plausible = [apple, wall].filter { $0 > 0 && $0 <= limit }
        if let best = plausible.min() { return best }
        if apple > 0 { return apple }
        return wall
    }
}

// Kept in an existing, always-compiled Watch source file: generated Xcode
// projects created before a new helper file must not lose these view types.
/// Offline thumbnails from the same original Repera art library as iPhone.
/// Each image is a 192 px derivative, so Watch never downloads media to render.
enum WatchExerciseArtwork {
    private static let nameMap: [String: String] = [
        "Press banca": "art_press_banca",
        "Press banca inclinada": "art_press_inclinado",
        "Press mancuernas": "art_press_mancuernas",
        "Press banca declinado": "art_press_declinado",
        "Press cerrado": "art_press_cerrado",
        "Aperturas": "art_aperturas",
        "Cruce de poleas": "art_cruce_poleas",
        "Pullover": "art_pullover",
        "Fondos": "art_fondos",
        "Fondos en banco": "art_fondos_banco",
        "Dominadas": "art_dominadas",
        "Remo invertido": "art_remo_invertido",
        "Jalón al pecho": "art_jalon",
        "Remo sentado": "art_remo_sentado",
        "Remo con barra": "art_remo_barra",
        "Remo mancuerna": "art_remo_mancuerna",
        "Peso muerto": "art_peso_muerto",
        "Peso muerto sumo": "art_sumo",
        "Peso muerto rumano": "art_rdl",
        "Buenos días": "art_buenos_dias",
        "Curl femoral": "art_curl_femoral",
        "Sentadilla": "art_sentadilla",
        "Sentadilla frontal": "art_sentadilla_frontal",
        "Hack squat": "art_hack_squat",
        "Prensa": "art_prensa",
        "Extensión de cuádriceps": "art_extension_cuad",
        "Zancadas": "art_zancadas",
        "Zancadas inversas con barra": "art_zancadas",
        "Sentadilla búlgara": "art_bulgara",
        "Paso lateral con banda": "art_paso_banda",
        "Elevación de gemelos": "art_gemelos",
        "Press militar": "art_press_militar",
        "Remo al mentón": "art_remo_menton",
        "Elevaciones laterales": "art_elevaciones_laterales",
        "Elevaciones frontales": "art_elev_frontales",
        "Pájaros": "art_pajaros",
        "Face pull": "art_face_pull",
        "Curl barra": "art_curl_barra",
        "Curl mancuernas": "art_curl_mancuernas",
        "Curl martillo": "art_curl_martillo",
        "Curl predicador": "art_curl_predicador",
        "Extensión tríceps polea": "art_triceps_polea",
        "Press francés": "art_press_frances",
        "Plancha": "art_plancha",
        "Crunch": "art_crunch",
        "Elevación de piernas": "art_elev_piernas",
        "Hip thrust": "art_hip_thrust",
        "Cinta / carrera": "art_cardio",
        "Bici estática": "art_bici",
        "Remo máquina": "art_remo_erg",
        "Farmer walk": "art_farmer",
        "Ab wheel": "art_ab_wheel",
        "Press Arnold": "art_arnold",
        "Cargada": "art_cf_cargada",
        "Cargada de potencia": "art_cf_power_clean",
        "Cargada colgante": "art_cf_hang_clean",
        "Arrancada": "art_cf_arrancada",
        "Arrancada de potencia": "art_cf_power_snatch",
        "Cargada y envión": "art_cf_cj",
        "Cargada y envión con mancuerna": "art_cf_db_clean",
        "Push press": "art_cf_push_press",
        "Push jerk": "art_cf_push_jerk",
        "Split jerk": "art_cf_split_jerk",
        "Overhead squat": "art_cf_ohs",
        "Thruster": "art_cf_thruster",
        "Cluster": "art_cf_cluster",
        "Sumo high pull": "art_cf_sumo_hp",
        "Burpee": "art_cf_burpee",
        "Burpee al cajón": "art_cf_burpee_box",
        "Burpee box jump over": "art_cf_burpee_box",
        "Salto al cajón": "art_cf_box_jump",
        "Step-up al cajón": "art_cf_step_up",
        "Muscle-up barra": "art_cf_mu_bar",
        "Muscle-up anillas": "art_cf_mu_rings",
        "Toes to bar": "art_cf_ttb",
        "Knees to elbows": "art_cf_kte",
        "Chest to bar": "art_cf_ctb",
        "HSPU": "art_cf_hspu",
        "Handstand walk": "art_cf_hsw",
        "Wall walk": "art_cf_wall_walk",
        "Fondos en anillas": "art_cf_ring_dip",
        "Fondos en anillas kipping": "art_cf_ring_dip",
        "Pistol squat": "art_cf_pistol",
        "Rope climb": "art_cf_rope",
        "Hollow rock": "art_cf_hollow",
        "GHD sit-up": "art_cf_ghd",
        "Sit-up": "art_cf_situp",
        "V-up": "art_cf_vup",
        "L-sit": "art_cf_lsit",
        "Swing kettlebell": "art_cf_kb_swing",
        "Swing americano": "art_cf_kb_amer",
        "Snatch kettlebell": "art_cf_kb_snatch",
        "Turkish get-up": "art_cf_tgu",
        "Wall ball": "art_cf_wall_ball",
        "Ball slam": "art_cf_slam",
        "Devil press": "art_cf_devil",
        "Man maker": "art_cf_manmaker",
        "Dobles de comba": "art_cf_du",
        "Simples de comba": "art_cf_su",
        "Air bike": "art_cf_airbike",
        "SkiErg": "art_cf_skierg",
        "Sled push": "art_cf_sled_push",
        "Sled pull": "art_cf_sled_pull",
        "Bear crawl": "art_cf_bear",
        "Broad jump": "art_cf_broad",
        "Walking lunge": "art_cf_walk_lunge",
        "Back rack reverse lunge": "art_zancadas",
        "Front rack lunge": "art_cf_fr_lunge",
        "Bar facing burpee": "art_cf_bfb",
        "Strict press": "art_cf_strict_press",
        "Hang power snatch": "art_cf_hps",
        "Hang power clean": "art_cf_hpc",
        "Arrancada colgante": "art_hl_hang_snatch",
        "Arrancada colgante completa": "art_hl_hang_sq_snatch",
        "Arrancada muscular": "art_hl_muscle_snatch",
        "Arrancada desde bloques": "art_hl_block_snatch",
        "Arrancada con pausa": "art_hl_pause_snatch",
        "Balance de arrancada": "art_hl_snatch_bal",
        "Drop snatch": "art_hl_drop_snatch",
        "Tall snatch": "art_hl_tall_snatch",
        "Arrancada en split": "art_hl_split_snatch",
        "Tirón de arrancada": "art_hl_snatch_pull",
        "Peso muerto agarre arrancada": "art_hl_snatch_dl",
        "Cargada colgante completa": "art_hl_hang_sq_clean",
        "Cargada muscular": "art_hl_muscle_clean",
        "Cargada desde bloques": "art_hl_block_clean",
        "Cargada con pausa": "art_hl_pause_clean",
        "Tall clean": "art_hl_tall_clean",
        "Tirón de cargada": "art_hl_clean_pull",
        "Cargada y press": "art_hl_clean_press",
        "Power jerk": "art_hl_power_jerk",
        "Balance de envión": "art_hl_jerk_bal",
        "Press detrás de nuca": "art_hl_btn_press",
        "Envión detrás de nuca": "art_hl_btn_jerk",
        "Sots press": "art_hl_sots",
        "Sentadilla frontal con pausa": "art_hl_pause_fs",
        "Dominadas estrictas": "art_gy_strict_pu",
        "Dominadas kipping": "art_gy_kip_pu",
        "Dominadas butterfly": "art_gy_bfly_pu",
        "Dominadas supinas": "art_gy_chinup",
        "Dominadas en anillas": "art_gy_ring_pu",
        "Remo en anillas": "art_gy_ring_row",
        "Archer pull-up": "art_gy_archer",
        "Muscle-up estricto barra": "art_gy_strict_mubar",
        "Muscle-up estricto anillas": "art_gy_strict_muring",
        "Pull-over barra": "art_gy_pullover",
        "Toes to bar estrictos": "art_gy_strict_ttb",
        "Toes to rings": "art_gy_ttr",
        "Hip to bar": "art_gy_htb",
        "Kip swing": "art_gy_kip_swing",
        "HSPU deficit": "art_gy_hspu_def",
        "HSPU libre": "art_gy_hspu_free",
        "Pike push-up": "art_gy_pike_pu",
        "Handstand hold": "art_gy_hs_hold",
        "Press to handstand": "art_gy_press_hs",
        "Fondos en paralelas": "art_gy_pb_dip",
        "Soporte en anillas": "art_gy_ring_sup",
        "False grip hang": "art_gy_false_grip",
        "Skin the cat": "art_gy_skin_cat",
        "German hang": "art_gy_german",
        "Front lever tuck": "art_gy_front_lev",
        "Back lever tuck": "art_gy_back_lev",
        "Planche tuck": "art_gy_planche",
        "V-sit": "art_gy_vsit",
        "Hollow hold": "art_gy_hollow_hold",
        "Arch hold": "art_gy_arch",
        "Candlestick": "art_gy_candle",
        "Shrimp squat": "art_gy_shrimp",
        "Cossack squat": "art_gy_cossack",
        "Air squat": "art_gy_air_squat",
        "Jumping squat": "art_gy_jump_squat",
        "Jumping lunge": "art_gy_jump_lunge",
        "GHD back extension": "art_gy_ghd_back",
        "Rope climb legless": "art_gy_rope_ll",
        "Pegboard": "art_gy_pegboard",
        "Thruster mancuernas": "art_cf_thruster_db",
        "Thruster kettlebell": "art_cf_thruster_kb",
        "Ground to overhead": "art_cf_gto",
        "Plate ground to overhead": "art_cf_plate_gto",
        "Burpee pull-up": "art_cf_burpee_pu",
        "Box jump over": "art_cf_bjo",
        "Clean kettlebell": "art_cf_kb_clean",
        "Goblet squat": "art_cf_goblet",
        "Snatch mancuerna": "art_cf_db_snatch",
        "Clean mancuerna": "art_cf_db_clean",
        "Medball clean": "art_cf_mb_clean",
        "Sandbag clean": "art_cf_sb_clean",
        "Sandbag over shoulder": "art_cf_sb_os",
        "Yoke carry": "art_cf_yoke",
        "Triples de comba": "art_cf_tu",
        "Echo bike": "art_cf_echo",
        "Shuttle run": "art_cf_shuttle",
        "Farmer carry": "art_cf_farmer_carry"
    ]

    private static func normalize(_ name: String) -> String {
        name.folding(options: [.diacriticInsensitive, .caseInsensitive],
                     locale: Locale(identifier: "es_ES"))
            .lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func assetName(for exercise: Exercise) -> String? {
        if let exact = nameMap[exercise.name] { return exact }
        let key = normalize(exercise.name)
        if let exact = nameMap.first(where: { normalize($0.key) == key }) {
            return exact.value
        }
        // Structured imports may add prescriptions such as RIR after the name.
        return nameMap.filter { name, _ in
            let canonical = normalize(name)
            return canonical.count > 3 && key.contains(canonical)
        }.max(by: { $0.key.count < $1.key.count })?.value
    }
}

struct WatchExerciseThumb: View {
    let exercise: Exercise
    var size: CGFloat = 43

    var body: some View {
        Group {
            if let name = WatchExerciseArtwork.assetName(for: exercise) {
                Image(name)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.white.opacity(0.05))
            }
        }
        .frame(width: size, height: size)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .accessibilityHidden(true)
    }
}