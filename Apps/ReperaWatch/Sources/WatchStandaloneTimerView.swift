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
    @State private var running = false
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
            } else if running {
                runningView
            } else {
                configView
            }
        }
        .navigationTitle("Temporizador")
        .onDisappear { tick?.invalidate() }
    }

    private var configView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Picker("Modo", selection: $modeRaw) {
                    Text("Arriba").tag("up")
                    Text("Abajo").tag("down")
                    Text("Intervalos").tag("intervals")
                }
                if modeRaw == "intervals" {
                    stepperRow("Rondas", value: $rounds, range: 1...40)
                    stepperRow("Trabajo s", value: Binding(
                        get: { workSeconds },
                        set: { workSeconds = $0 }
                    ), range: 5...600, step: 5)
                    stepperRow("Descanso s", value: Binding(
                        get: { restSeconds },
                        set: { restSeconds = $0 }
                    ), range: 0...300, step: 5)
                } else {
                    stepperRow("Minutos", value: $durationMinutes, range: 1...180)
                }
                Button {
                    begin()
                } label: {
                    Text("Comenzar")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(.borderedProminent)
                .tint(accent)
                .foregroundStyle(.black)
            }
            .padding(.horizontal, 4)
        }
    }

    private var runningView: some View {
        VStack(spacing: 10) {
            if modeRaw == "intervals" {
                Text(inWork ? "Trabajo · \(roundIndex)/\(rounds)" : "Descanso · \(roundIndex)/\(rounds)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(clockText)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .monospacedDigit()
            HStack {
                Button("Pausa") { togglePause() }
                    .buttonStyle(.bordered)
                Button("Terminar", role: .destructive) { complete(save: false) }
                    .buttonStyle(.bordered)
            }
        }
    }

    private var summary: some View {
        VStack(spacing: 10) {
            Text("Temporizador")
                .font(.headline)
            Text(clockText)
                .font(.title2.monospacedDigit())
            Button("Guardar") { complete(save: true) }
                .buttonStyle(.borderedProminent)
                .tint(accent)
                .foregroundStyle(.black)
            Button("Descartar", role: .destructive) {
                tick?.invalidate()
                dismiss()
            }
        }
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
        HStack {
            Text(title)
            Spacer()
            Button("-") {
                value.wrappedValue = max(range.lowerBound, value.wrappedValue - step)
            }
            Text("\(value.wrappedValue)")
                .monospacedDigit()
                .frame(minWidth: 28)
            Button("+") {
                value.wrappedValue = min(range.upperBound, value.wrappedValue + step)
            }
        }
        .font(.caption)
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
