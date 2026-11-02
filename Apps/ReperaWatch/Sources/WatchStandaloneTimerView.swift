import ReperaDomain
import SwiftUI
import WatchKit

/// Temporizador libre en Watch (paridad de modos con iPhone).
struct WatchStandaloneTimerView: View {
    @Environment(WatchSessionHub.self) private var hub
    @Environment(\.dismiss) private var dismiss

    @State private var timerId = UUID()
    @State private var modeRaw = "down"
    @State private var durationMinutes = 40
    @State private var rounds = 5
    @State private var workSeconds = 90
    @State private var restSeconds = 30
    @State private var choosingMode = true
    @State private var started = false
    @State private var running = false
    @State private var showDiscardConfirmation = false
    @State private var showingTimerControls = false
    @State private var showingNowPlaying = false
    @State private var showingTimerMetrics = false
    @State private var metricCrown = 0.0
    @FocusState private var metricCrownFocused: Bool
    @State private var remaining = 0
    @State private var elapsed = 0
    @State private var roundIndex = 1
    @State private var inWork = true
    @State private var tick: Timer?
    @State private var finished = false

    private let accent = Color(red: 48 / 255, green: 209 / 255, blue: 88 / 255)

    var body: some View {
        Group {
            if finished {
                summary
            } else if started {
                runningView
            } else if choosingMode {
                modeSelectionView
            } else {
                configView
            }
        }
        .navigationTitle(started && !finished ? "" : "Temporizador")
        .toolbar(started && !finished ? .hidden : .automatic, for: .navigationBar)
        .navigationBarBackButtonHidden(started && !finished)
        .interactiveDismissDisabled(started && !finished)
        .onChange(of: hub.timerRemoteCommand?.token) { _, _ in
            guard let remote = hub.timerRemoteCommand,
                  remote.id == timerId, started, !finished else { return }
            switch remote.command {
            case "pause": if running { togglePause() }
            case "resume": if !running { togglePause() }
            case "finish": finishRun()
            default: break
            }
        }
        .onDisappear {
            tick?.invalidate()
            if started && !finished { publishMirror("discarded") }
        }
    }

    private var modeSelectionView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Elige un temporizador")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .padding(.bottom, 2)

                modeButton("down", title: "Cuenta atrás", subtitle: "Desde un tiempo", symbol: "timer")
                modeButton("up", title: "Cronómetro", subtitle: "Tiempo ascendente", symbol: "stopwatch")
                modeButton("intervals", title: "Intervalos", subtitle: "Trabajo y descanso", symbol: "repeat")
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
        }
        .scrollIndicators(.hidden)
    }

    private func modeButton(_ mode: String, title: String, subtitle: String, symbol: String) -> some View {
        Button {
            modeRaw = mode
            choosingMode = false
            WKInterfaceDevice.current().play(.click)
        } label: {
            HStack(spacing: 9) {
                Image(systemName: symbol)
                    .font(.system(size: 19, weight: .semibold))
                    .frame(width: 23)
                    .foregroundStyle(accent)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text(subtitle)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
    }

    private var modeTitle: String {
        switch modeRaw {
        case "up": return "Cronómetro"
        case "intervals": return "Intervalos"
        default: return "Cuenta atrás"
        }
    }

    private var configView: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text(modeTitle)
                    .font(.title3.weight(.bold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                if modeRaw == "intervals" {
                    stepperRow("Rondas", value: $rounds, range: 1...40)
                    stepperRow("Trabajo · s", value: $workSeconds, range: 5...600, step: 5)
                    stepperRow("Descanso · s", value: $restSeconds, range: 0...300, step: 5)
                } else {
                    stepperRow("Minutos", value: $durationMinutes, range: 1...180)
                }

                Button(action: begin) {
                    Label("Comenzar", systemImage: "play.fill")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 46)
                }
                .buttonStyle(.borderedProminent)
                .tint(accent)
                .foregroundStyle(.black)
                .accessibilityHint("Inicia \(modeTitle.lowercased())")
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
        }
        .scrollIndicators(.hidden)
        .simultaneousGesture(
            DragGesture(minimumDistance: 35).onEnded { drag in
                let dx = drag.translation.width
                if dx > 55 && dx > abs(drag.translation.height) * 1.4 {
                    choosingMode = true
                }
            }
        )
    }

    // iPhone DigitalClockDisplay: tiempo #FF382E, rondas #38FF59, fondo negro.
    private let timerRed = Color(red: 1, green: 0.22, blue: 0.18)
    private let timerRoundGreen = Color(red: 0.22, green: 1, blue: 0.35)

    private var runningView: some View {
        Group {
            if showingNowPlaying {
                // UI original de watchOS: el propio sistema gestiona fuente y volumen.
                NowPlayingView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(.container, edges: .all)
                    .toolbar(.hidden, for: .navigationBar)
            } else {
                runningTimerDisplay
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 35).onEnded { drag in
                let dx = drag.translation.width
                guard abs(dx) > abs(drag.translation.height) * 1.4 else { return }
                if dx < -55 {
                    if showingNowPlaying {
                        showingNowPlaying = false
                    } else {
                        showingTimerControls = true
                        showingTimerMetrics = false
                    }
                } else if dx > 55 {
                    if showingTimerControls {
                        showingTimerControls = false
                    } else {
                        showingNowPlaying = true
                    }
                }
            }
        )
        .confirmationDialog(
            "¿Finalizar el temporizador?",
            isPresented: $showDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button("Finalizar") { finishRun() }
        } message: {
            Text("Podrás guardar o descartar el tiempo registrado.")
        }
    }

    private var runningTimerDisplay: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if showingTimerControls {
                HStack(spacing: 8) {
                    timerActionButton(
                        running ? "Pausar" : "Reanudar",
                        symbol: running ? "pause.fill" : "play.fill",
                        destructive: false
                    ) { togglePause() }
                    timerActionButton(
                        "Finalizar",
                        symbol: "flag.checkered",
                        destructive: false
                    ) { showDiscardConfirmation = true }
                }
                .padding(.horizontal, 8)
            } else if showingTimerMetrics {
                VStack(spacing: 10) {
                    Text("Métricas")
                        .font(.headline)
                    timerMetric("Transcurrido", seconds: elapsed)
                    if modeRaw != "up" {
                        timerMetric("Restante", seconds: max(0, configuredTotalSeconds - elapsed))
                    }
                    if modeRaw == "intervals" {
                        HStack {
                            Text("Ronda").foregroundStyle(.secondary)
                            Spacer()
                            Text("\(roundIndex)/\(rounds)")
                                .foregroundStyle(timerRoundGreen)
                                .monospacedDigit()
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                }
                .padding(.horizontal, 12)
            } else {
                VStack(spacing: 9) {
                    if modeRaw != "intervals" {
                        Text(modeTitle.uppercased())
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(accent)
                            .lineLimit(1)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        if modeRaw == "intervals" {
                            Text("\(roundIndex)")
                                .font(.system(size: 26, weight: .heavy, design: .rounded))
                                .foregroundStyle(timerRoundGreen)
                                .monospacedDigit()
                                .accessibilityLabel("Ronda \(roundIndex) de \(rounds)")
                                .layoutPriority(1)
                        }
                        Text(clockText)
                            .font(.system(
                                size: modeRaw == "intervals" ? 33 : 48,
                                weight: .heavy, design: .monospaced
                            ))
                            .foregroundStyle(timerRed)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                            .shadow(color: timerRed.opacity(0.5), radius: 5)
                            .accessibilityLabel("Tiempo \(clockText)")
                            .layoutPriority(1)
                        if modeRaw == "intervals" {
                            Text(inWork ? "TRABAJAR" : "DESCANSAR")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(accent)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    if !running {
                        Text("En pausa")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.yellow)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 4)
            }
        }
        .focusable(true)
        .focused($metricCrownFocused)
        .digitalCrownRotation(
            $metricCrown,
            from: 0,
            through: 1,
            by: 1,
            sensitivity: .low,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .onAppear { metricCrownFocused = true }
        .onChange(of: metricCrown) { _, value in
            showingTimerMetrics = value >= 0.5
            if showingTimerMetrics { showingTimerControls = false }
        }
    }

    private var configuredTotalSeconds: Int {
        if modeRaw == "intervals" {
            return rounds * (workSeconds + restSeconds)
        }
        return durationMinutes * 60
    }

    private func timerMetric(_ label: String, seconds: Int) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(String(format: "%d:%02d", max(0, seconds) / 60, max(0, seconds) % 60))
                .foregroundStyle(timerRed)
                .monospacedDigit()
        }
        .font(.subheadline.weight(.semibold))
    }

    private func timerActionButton(
        _ title: String,
        symbol: String,
        destructive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .bold))
                    .accessibilityHidden(true)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(destructive ? Color.red : accent)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var summary: some View {
        ScrollView {
            VStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(accent)
                    .accessibilityHidden(true)
                Text("Temporizador completado")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(String(format: "%d:%02d", elapsed / 60, elapsed % 60))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.8)
                Text(modeTitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Guardar") { complete(save: true) }
                    .buttonStyle(.borderedProminent)
                    .tint(accent)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                Button("Descartar", role: .destructive) {
                    complete(save: false)
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
        }
        .scrollIndicators(.hidden)
    }

    private var clockText: String {
        let total = modeRaw == "up" ? elapsed : remaining
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    private func stepperRow(
        _ title: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        step: Int = 1
    ) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                stepperButton("minus", label: "Reducir \(title)", disabled: value.wrappedValue <= range.lowerBound) {
                    value.wrappedValue = max(range.lowerBound, value.wrappedValue - step)
                }
                Spacer(minLength: 0)
                Text("\(value.wrappedValue)")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(minWidth: 30)
                    .accessibilityLabel("\(title): \(value.wrappedValue)")
                Spacer(minLength: 0)
                stepperButton("plus", label: "Aumentar \(title)", disabled: value.wrappedValue >= range.upperBound) {
                    value.wrappedValue = min(range.upperBound, value.wrappedValue + step)
                }
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 8)
    }

    private func stepperButton(
        _ symbol: String,
        label: String,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)

        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
        .accessibilityLabel(label)
    }

    private func begin() {
        if !hub.audioMuted {
            WKInterfaceDevice.current().play(.start)
        }
        timerId = UUID()
        elapsed = 0
        roundIndex = 1
        inWork = true
        remaining = modeRaw == "intervals" ? workSeconds : durationMinutes * 60
        if modeRaw == "up" { remaining = 0 }
        started = true
        showingTimerControls = false
        showingNowPlaying = false
        showingTimerMetrics = false
        metricCrown = 0
        running = true
        finished = false
        startTick()
        publishMirror("running")
    }

    private func startTick() {
        tick?.invalidate()
        tick = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                tickOnce()
            }
        }
    }

    private func tickOnce() {
        guard running else { return }
        defer { if elapsed % 3 == 0 && !finished { publishMirror("running") } }
        switch modeRaw {
        case "up":
            elapsed += 1
            if elapsed >= durationMinutes * 60 { finishRun() }
        case "down":
            remaining -= 1
            elapsed += 1
            if remaining <= 0 { finishRun() }
        default:
            remaining -= 1
            elapsed += 1
            if remaining <= 0 {
                if inWork {
                    if restSeconds > 0 {
                        inWork = false
                        remaining = restSeconds
                    } else if roundIndex >= rounds {
                        finishRun()
                    } else {
                        roundIndex += 1
                        remaining = workSeconds
                    }
                } else if roundIndex >= rounds {
                    finishRun()
                } else {
                    roundIndex += 1
                    inWork = true
                    remaining = workSeconds
                }
            }
        }
    }

    private func togglePause() {
        running.toggle()
        if running { startTick() } else { tick?.invalidate() }
        publishMirror(running ? "running" : "paused")
    }

    private func finishRun() {
        tick?.invalidate()
        running = false
        finished = true
        publishMirror("finished")
        if !hub.audioMuted {
            WKInterfaceDevice.current().play(.success)
        } else {
            WKInterfaceDevice.current().play(.click)
        }
    }

    private func publishMirror(_ phase: String) {
        guard started else { return }
        hub.publishTimerMirror(WatchTimerMirror(
            id: timerId,
            modeRaw: modeRaw,
            configuredSeconds: configuredTotalSeconds,
            elapsedSeconds: elapsed,
            round: roundIndex,
            phase: phase
        ))
    }

    private func complete(save: Bool) {
        tick?.invalidate()
        publishMirror(save ? "finished" : "discarded")
        if save {
            let details = TimerCompletionDetails(
                modeRaw: modeRaw,
                configuredSeconds: max(1, modeRaw == "intervals"
                    ? rounds * (workSeconds + restSeconds) : durationMinutes * 60),
                rounds: modeRaw == "intervals" ? rounds : 1,
                workSeconds: modeRaw == "intervals" ? workSeconds : durationMinutes * 60,
                restSeconds: modeRaw == "intervals" ? restSeconds : 0,
                countdownSeconds: elapsed
            )
            hub.saveStandaloneTimer(id: timerId, details: details, elapsedSeconds: elapsed)
        }
        dismiss()
    }
}
