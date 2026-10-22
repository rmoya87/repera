import ReperaDomain
import SwiftUI
import WatchKit

/// The first screen is always the day's workout, or the currently running session.
struct WatchSessionView: View {
    @Environment(WatchSessionHub.self) private var hub
    @State private var showNowPlaying = false
    @State private var confirmFinish = false
    @State private var showOutline = false

    private let accent = Color(red: 0.54, green: 0.91, blue: 0.49)

    var body: some View {
        NavigationStack {
            Group {
                if let finished = hub.lastFinished {
                    finishedView(finished)
                } else if let active = hub.active {
                    if hub.reviewingBlock {
                        blockReviewView(active)
                    } else if active.phase == .counting {
                        runningView(active)
                    } else {
                        readyView(active)
                    }
                } else if let today = hub.todaysWorkout {
                    todayView(today)
                } else {
                    emptyView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNowPlaying = true } label: {
                        Image(systemName: "playpause.fill")
                            .font(.caption.weight(.bold))
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(.black)
                    }
                    .tint(accent)
                    .accessibilityLabel("Controlar música o podcast")
                }
            }
            .sheet(isPresented: $showOutline) {
                if let workout = hub.active { outlineView(workout) }
            }
            .sheet(isPresented: $showNowPlaying) {
                // Apple requires the entire Now Playing view to fill its own scene.
                NowPlayingView()
            }
            .confirmationDialog("¿Finalizar el entrenamiento?",
                                isPresented: $confirmFinish) {
                Button("Guardar entrenamiento") { hub.finishWorkout() }
                Button("Continuar", role: .cancel) {}
            } message: {
                Text("Se guardarán las series y los bloques que hayas confirmado.")
            }
        }
        .tint(accent)
    }

    private var emptyView: some View {
        ScrollView {
            VStack(spacing: 10) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                    .foregroundStyle(accent)
                Text("Sin plan descargado")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Text("Si ya programaste un entrenamiento, sincronízalo desde tu iPhone.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button {
                    hub.refreshToday()
                } label: {
                    Label("Sincronizar con iPhone", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption2.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .accessibilityHint("Solicita al iPhone el entrenamiento programado para hoy")
                Text("Abre Repera en el iPhone emparejado si no aparece.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
    }

    private func todayView(_ session: WorkoutSession) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("HOY")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(accent)
                Text(session.title)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
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
                    VStack(alignment: .leading, spacing: 6) {
                        Text(first.displayBlockHeader)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        ForEach(blockMembers(in: session, startingAt: index), id: \.self) { position in
                            exerciseCard(session.exercises[position])
                        }
                    }
                    .padding(9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.07),
                                in: RoundedRectangle(cornerRadius: 13))
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
        let kinds = Set(session.exercises.map { $0.blockKind })
        if kinds.contains(.strength) && kinds.contains(.wod) { return "Mixto" }
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

    private func exerciseCard(_ exercise: SessionExercise) -> some View {
        HStack(alignment: .center, spacing: 8) {
            WatchExerciseThumb(exercise: exercise.exercise, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.exercise.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(exercise.prescriptionSummaryLine)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(7)
        .background(.white.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: 10))
    }

    private func readyView(_ session: WorkoutSession) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 9) {
                Text(hub.current?.displayBlockHeader ?? session.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(session.progressLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ForEach(hub.blockExercises) { exercise in
                    exerciseCard(exercise)
                }
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
                Button("Ver entrenamiento completo") { showOutline = true }
                    .font(.caption)
                    .buttonStyle(.bordered)
                Button("Finalizar entreno") { confirmFinish = true }
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 5)
        }
    }

    private func runningView(_ session: WorkoutSession) -> some View {
        ScrollView {
            VStack(spacing: 8) {
                Text(hub.current?.displayBlockHeader ?? session.title)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                if hub.restRemaining > 0 {
                    restView(hub.restRemaining)
                } else {
                    clockAndProgress
                    if hub.currentIsWOD {
                        wodContent
                    } else {
                        seriesContent
                    }
                }
                Button("Ver plan completo") { showOutline = true }
                    .font(.caption2)
                    .buttonStyle(.borderless)
                if !hub.isFinalSet {
                    HStack(spacing: 8) {
                        Button {
                            if hub.isPaused { hub.play() } else { hub.pause() }
                        } label: {
                            Label(hub.isPaused ? "Seguir" : "Pausa",
                                  systemImage: hub.isPaused ? "play.fill" : "pause.fill")
                        }
                        .buttonStyle(.bordered)
                        Button("Finalizar antes") { confirmFinish = true }
                            .buttonStyle(.bordered)
                            .tint(.red)
                    }
                    .font(.caption2)
                }
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
    private var clockAndProgress: some View {
        let currentTime = hub.timeRemaining ?? hub.blockElapsed
        Text(timeLabel(currentTime))
            .font(.system(size: 35, weight: .bold, design: .rounded))
            .monospacedDigit()
            .minimumScaleFactor(0.7)
            .contentTransition(.numericText())
            .accessibilityLabel(hub.timeRemaining == nil ? "Tiempo transcurrido" : "Tiempo restante")
        if let label = hub.intervalLabel {
            HStack(spacing: 6) {
                Text(label).font(.caption2).foregroundStyle(.secondary)
                Spacer(minLength: 4)
                if let remaining = hub.intervalRemaining {
                    Text(timeLabel(remaining))
                        .font(.caption.weight(.bold))
                        .monospacedDigit()
                }
            }
        }
        if hub.timeCapSeconds > 0 {
            ProgressView(value: Double(min(hub.blockElapsed, hub.timeCapSeconds)),
                         total: Double(hub.timeCapSeconds))
                .tint(accent)
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
        if hub.isPaused {
            Label("En pausa", systemImage: "pause.circle.fill")
                .font(.caption)
                .foregroundStyle(.yellow)
        }
    }

    private var wodContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(hub.blockExercises) { exercise in
                HStack {
                    Text(exercise.exercise.name)
                        .font(.caption2)
                        .lineLimit(2)
                    Spacer(minLength: 4)
                    Text(exercise.prescriptionSummaryLine)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Text("Movimiento estimado: \(hub.workingReps) reps")
                .font(.caption2)
                .foregroundStyle(.secondary)
            if hub.wodUsesSeries && !hub.isPaused {
                HStack(spacing: 5) {
                    Button { hub.adjustReps(-1) } label: {
                        Image(systemName: "minus.circle.fill")
                    }
                    Button { hub.adjustReps(1) } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    Button("Confirmar serie") { hub.confirmIntervalSet() }
                        .buttonStyle(.borderedProminent)
                }
                .font(.caption2)
                if hub.blockExercises.count > 1 {
                    Button("Siguiente movimiento") { hub.nextWODMovement() }
                        .font(.caption2)
                        .buttonStyle(.bordered)
                }
            }
            if !hub.isPaused {
                Button {
                    hub.reviewBlock()
                } label: {
                    Text("Terminar bloque")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var seriesContent: some View {
        VStack(spacing: 7) {
            Text(hub.current?.exercise.name ?? "Ejercicio")
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.center)
            Text("Serie \(min(hub.completedSets + 1, max(1, hub.plannedSets))) / \(max(1, hub.plannedSets))")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(hub.workingReps)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .monospacedDigit()
                .focusable(true)
                .digitalCrownRotation(
                    Binding(get: { Double(hub.workingReps) },
                            set: { hub.adjustReps(Int($0.rounded()) - hub.workingReps) }),
                    from: 0, through: 500, by: 1,
                    sensitivity: .medium, isContinuous: false,
                    isHapticFeedbackEnabled: true
                )
                .accessibilityLabel("Repeticiones estimadas, ajustables con la corona")
            HStack {
                Button { hub.adjustReps(-1) } label: { Image(systemName: "minus.circle.fill") }
                    .accessibilityLabel("Restar repetición")
                Button { hub.adjustReps(1) } label: { Image(systemName: "plus.circle.fill") }
                    .accessibilityLabel("Sumar repetición")
            }
            .buttonStyle(.borderless)
            Text("Estimación · confirma lo realizado")
                .font(.caption2)
                .foregroundStyle(.secondary)
            if let weight = hub.workingWeightKg {
                HStack {
                    Button("-2,5") { hub.adjustWeight(-2.5) }
                    Text("\(weight.formatted()) kg")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                    Button("+2,5") { hub.adjustWeight(2.5) }
                }
                .font(.caption2)
            }
            if !hub.isPaused {
                Button("Confirmar serie") { hub.confirmSet() }
                    .buttonStyle(.borderedProminent)
                    .tint(accent)
                    .foregroundStyle(.black)
                Button(hub.completedSets >= hub.plannedSets ? "Siguiente" : "Saltar al siguiente") {
                    hub.advance()
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
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
                .buttonStyle(.bordered)
                .disabled(hub.isPaused)
        }
    }

    private func blockReviewView(_ session: WorkoutSession) -> some View {
        ScrollView {
            VStack(spacing: 10) {
                Image(systemName: "checkmark.circle")
                    .font(.title2)
                    .foregroundStyle(accent)
                Text("Confirmar bloque")
                    .font(.headline)
                Text(hub.current?.displayBlockHeader ?? "WOD")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if hub.current?.wodFormat == .amrap ||
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
                Text("Tiempo: \(timeLabel(hub.blockElapsed))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if hub.current?.wodFormat == .emom || hub.current?.wodFormat == .tabata {
                    Text("Los intervalos se controlan automáticamente. No se inventan repeticiones.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                Button("Confirmar resultado") { hub.confirmBlock() }
                    .buttonStyle(.borderedProminent)
                    .tint(accent)
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, 6)
        }
    }

    private func scoreStepper(label: String, value: Int,
                              down: @escaping () -> Void, up: @escaping () -> Void) -> some View {
        VStack(spacing: 3) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            HStack {
                Button(action: down) { Image(systemName: "minus.circle.fill") }
                    .buttonStyle(.borderless)
                Text("\(value)")
                    .font(.title2.bold())
                    .monospacedDigit()
                    .frame(maxWidth: .infinity)
                Button(action: up) { Image(systemName: "plus.circle.fill") }
                    .buttonStyle(.borderless)
            }
        }
    }

    private func outlineView(_ session: WorkoutSession) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Plan completo").font(.headline)
                Text(session.title).font(.caption).foregroundStyle(.secondary)
                ForEach(session.exercises.indices, id: \.self) { index in
                    let exercise = session.exercises[index]
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            if exercise.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(accent)
                            } else if session.currentIndex == index {
                                Image(systemName: "play.circle.fill")
                                    .foregroundStyle(accent)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary)
                            }
                            Text(exercise.exercise.name)
                                .font(.caption.weight(.semibold))
                        }
                        Text(exercise.displayBlockHeader)
                            .font(.caption2)
                            .foregroundStyle(accent)
                        Text(exercise.queueTimeLabel)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 9))
                }
                Button("Volver al entrenamiento") { showOutline = false }
                    .buttonStyle(.bordered)
            }
            .padding(.horizontal, 6)
        }
    }

    private func finishedView(_ session: WorkoutSession) -> some View {
        let sets = session.exercises.flatMap(\.loggedSets)
        let reps = sets.reduce(0) { $0 + $1.reps }
        return ScrollView {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.largeTitle)
                    .foregroundStyle(accent)
                Text("¡Bien hecho!")
                    .font(.headline)
                Text(session.title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                statsLine(
                    icon: "clock",
                    label: session.appleDurationSeconds == nil ? "Tiempo registrado" : "Tiempo Salud",
                    value: timeLabel(Int(session.appleDurationSeconds ??
                        session.finishedAt?.timeIntervalSince(session.startedAt ?? Date()) ?? 0))
                )
                if session.healthKitWorkoutUUID != nil {
                    Label("Registrado en Apple Salud", systemImage: "heart.text.square")
                        .font(.caption2)
                        .foregroundStyle(accent)
                } else if session.appleHealthProvenance == "watchHealthKitPending" {
                    Label("Salud pendiente de confirmar", systemImage: "heart.circle")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let energy = session.appleActiveEnergyKcal {
                    statsLine(icon: "flame.fill", label: "Salud",
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
                Label(hub.acknowledgedSessionID == session.id ? "Sincronizado con iPhone" :
                        "Guardado en Watch · pendiente de sincronizar",
                      systemImage: hub.acknowledgedSessionID == session.id ?
                        "checkmark.icloud" : "arrow.triangle.2.circlepath")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Volver al inicio") { hub.clearSummary() }
                    .buttonStyle(.bordered)
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

    private func header(title: String, subtitle: String) -> some View {
        HStack {
            Text(title)
                .font(.caption.weight(.bold))
                .lineLimit(2)
            Spacer(minLength: 3)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func timeLabel(_ seconds: Int) -> String {
        let n = max(0, seconds)
        return String(format: "%02d:%02d", n / 60, n % 60)
    }
}
