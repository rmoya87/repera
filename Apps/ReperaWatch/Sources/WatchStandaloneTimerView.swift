import ReperaDomain
import SwiftUI
import WatchKit

/// Temporizador libre en Watch (paridad de modos con iPhone).
struct WatchStandaloneTimerView: View {
    @Environment(WatchSessionHub.self) private var hub
    @Environment(\.dismiss) private var dismiss

    @State private var modeRaw = "down"
    @State private var durationMinutes = 40
    @State private var rounds = 5
    @State private var workSeconds = 90
    @State private var restSeconds = 30
    @State private var choosingMode = true
    @State private var started = false
    @State private var running = false
    @State private var showDiscardConfirmation = false
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
        .navigationTitle("Temporizador")
        .onDisappear { tick?.invalidate() }
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
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
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
                Button {
                    choosingMode = true
                } label: {
                    Label("Cambiar tipo", systemImage: "chevron.left")
                        .font(.footnote.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .foregroundStyle(accent)

                Text(modeTitle)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
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
    }

    private var runningView: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text(modeRaw == "intervals"
                     ? "\(inWork ? "Trabajo" : "Descanso") · \(roundIndex)/\(rounds)"
                     : modeTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(inWork ? Color.primary : accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)

                if !running {
                    Text("En pausa")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.yellow)
                }

                Text(clockText)
                    .font(.system(size: 39, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Tiempo \(clockText)")

                HStack(spacing: 8) {
                    timerActionButton(
                        running ? "Pausar" : "Reanudar",
                        symbol: running ? "pause.fill" : "play.fill",
                        destructive: false
                    ) { togglePause() }
                    timerActionButton("Terminar", symbol: "xmark", destructive: true) {
                        showDiscardConfirmation = true
                    }
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 10)
        }
        .scrollIndicators(.hidden)
        .confirmationDialog(
            "¿Descartar el temporizador?",
            isPresented: $showDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button("Descartar", role: .destructive) { complete(save: false) }
        } message: {
            Text("El tiempo registrado no se guardará.")
        }
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
                    .font(.system(size: 12, weight: .semibold))
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
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
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
                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
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
        elapsed = 0
        roundIndex = 1
        inWork = true
        remaining = modeRaw == "intervals" ? workSeconds : durationMinutes * 60
        if modeRaw == "up" { remaining = 0 }
        started = true
        running = true
        finished = false
        startTick()
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
    }

    private func finishRun() {
        tick?.invalidate()
        running = false
        finished = true
        if !hub.audioMuted {
            WKInterfaceDevice.current().play(.success)
        } else {
            WKInterfaceDevice.current().play(.click)
        }
    }

    private func complete(save: Bool) {
        tick?.invalidate()
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
            hub.saveStandaloneTimer(details: details, elapsedSeconds: elapsed)
        }
        dismiss()
    }
}
