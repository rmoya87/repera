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
                            .font(.caption)
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
        VStack(spacing: 12) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.title2)
                .foregroundStyle(accent)
            Text("Sin entreno hoy")
                .font(.headline)
            Text("Programa el entrenamiento en Repera para tenerlo aquí sin usar el iPhone.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("Al conectar, se descargará automáticamente.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
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
                summaryChips(session)
                if let blocks = session.routineBlocks, !blocks.isEmpty {
                    ForEach(0..<blocks.count, id: \.self) { index in
                        let block = blocks[index]
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(index + 1). \(block.title)")
                                .font(.caption.weight(.semibold))
                            Text(block.kind == .strength ? "Fuerza" : (block.wodFormat?.displayName ?? "WOD"))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            if let cap = block.timeCapMinutes {
                                Text("\(cap) min")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    }
                } else {
                    ForEach(session.exercises) { exercise in
                        Text("• \(exercise.exercise.name) · \(exercise.queueTimeLabel)")
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                Button {
                    hub.startToday()
                } label: {
                    Label("Iniciar entreno", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(accent)
                .foregroundStyle(.black)
                .accessibilityHint("El entrenamiento se registrará en este reloj")
            }
            .padding(.horizontal, 6)
        }
    }

    private func summaryChips(_ session: WorkoutSession) -> some View {
        HStack(spacing: 8) {
            Label("\(session.exercises.count)", systemImage: "figure.strengthtraining.traditional")
            if let blocks = session.routineBlocks, !blocks.isEmpty {
                Label("\(blocks.count)", systemImage: "square.stack.3d.up")
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }

    private func readyView(_ session: WorkoutSession) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 9) {
                header(title: "Preparado", subtitle: session.progressLabel)
                Text(hub.current?.displayBlockHeader ?? "Ejercicio")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
                ForEach(hub.blockExercises) { exercise in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.exercise.name)
                            .font(.subheadline.weight(.semibold))
                        Text(exercise.prescriptionSummaryLine)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 3)
                }
                if let minutes = hub.current?.blockTimeCapMinutes {
                    Label("\(minutes) min", systemImage: "timer")
                        .font(.caption)
                }
                Button {
                    hub.play()
                } label: {
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
            .padding(.horizontal, 6)
        }
    }

    private func runningView(_ session: WorkoutSession) -> some View {
        ScrollView {
            VStack(spacing: 8) {
                header(title: hub.current?.displayBlockHeader ?? "Entrenamiento",
                       subtitle: session.progressLabel)
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
                HStack(spacing: 8) {
                    Button {
                        if hub.isPaused { hub.play() } else { hub.pause() }
                    } label: {
                        Label(hub.isPaused ? "Seguir" : "Pausa",
                              systemImage: hub.isPaused ? "play.fill" : "pause.fill")
                    }
                    .buttonStyle(.bordered)
                    Button("Terminar") { confirmFinish = true }
                        .buttonStyle(.bordered)
                        .tint(.red)
                }
                .font(.caption)
            }
            .padding(.horizontal, 5)
        }
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
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        if hub.timeCapSeconds > 0 {
            ProgressView(value: Double(min(hub.blockElapsed, hub.timeCapSeconds)),
                         total: Double(hub.timeCapSeconds))
                .tint(accent)
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
                if hub.current?.wodFormat == .amrap {
                    scoreStepper(label: "Reps adicionales", value: hub.remainingRoundReps,
                                 down: { hub.adjustExtraReps(-1) }, up: { hub.adjustExtraReps(1) })
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
                statsLine(icon: "clock", label: "Duración",
                          value: timeLabel(Int(session.appleDurationSeconds ?? 0)))
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
