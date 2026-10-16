import GymbroDomain
import SwiftUI

enum StandaloneTimerMode: String, CaseIterable, Identifiable, Codable {
    case up
    case down
    case intervals

    var id: String { rawValue }

    var title: String {
        switch self {
        case .up: "Arriba"
        case .down: "Abajo"
        case .intervals: "Intervalos"
        }
    }
}

struct StandaloneTimerConfig: Equatable, Codable, Hashable {
    var mode: StandaloneTimerMode = .intervals
    var durationMinutes: Int = 40
    var durationSeconds: Int = 0
    var rounds: Int = 5
    var workMinutes: Int = 1
    var workSeconds: Int = 30
    var restMinutes: Int = 0
    var restSeconds: Int = 0
    var countdownBeforeStart: Bool = true

    var durationTotalSeconds: Int { max(1, durationMinutes * 60 + durationSeconds) }
    var workTotalSeconds: Int { max(1, workMinutes * 60 + workSeconds) }
    var restTotalSeconds: Int { max(0, restMinutes * 60 + restSeconds) }

    var shortLabel: String {
        switch mode {
        case .up:
            return "Arriba · \(timeLabel(durationMinutes, durationSeconds))"
        case .down:
            return "Abajo · \(timeLabel(durationMinutes, durationSeconds))"
        case .intervals:
            return "Intervalos · \(rounds)× \(timeLabel(workMinutes, workSeconds))/\(timeLabel(restMinutes, restSeconds))"
        }
    }

    private func timeLabel(_ m: Int, _ s: Int) -> String {
        String(format: "%d:%02d", m, s)
    }

    init(
        mode: StandaloneTimerMode = .intervals,
        durationMinutes: Int = 40,
        durationSeconds: Int = 0,
        rounds: Int = 5,
        workMinutes: Int = 1,
        workSeconds: Int = 30,
        restMinutes: Int = 0,
        restSeconds: Int = 0,
        countdownBeforeStart: Bool = true
    ) {
        self.mode = mode
        self.durationMinutes = durationMinutes
        self.durationSeconds = durationSeconds
        self.rounds = rounds
        self.workMinutes = workMinutes
        self.workSeconds = workSeconds
        self.restMinutes = restMinutes
        self.restSeconds = restSeconds
        self.countdownBeforeStart = countdownBeforeStart
    }

    init(favorite: FavoriteTimer) {
        self.mode = StandaloneTimerMode(rawValue: favorite.modeRaw) ?? .intervals
        self.durationMinutes = favorite.durationMinutes
        self.durationSeconds = favorite.durationSeconds
        self.rounds = favorite.rounds
        self.workMinutes = favorite.workMinutes
        self.workSeconds = favorite.workSeconds
        self.restMinutes = favorite.restMinutes
        self.restSeconds = favorite.restSeconds
        self.countdownBeforeStart = favorite.countdownBeforeStart
    }

    func asFavorite(title: String, id: UUID = UUID()) -> FavoriteTimer {
        FavoriteTimer(
            id: id,
            title: title,
            modeRaw: mode.rawValue,
            durationMinutes: durationMinutes,
            durationSeconds: durationSeconds,
            rounds: rounds,
            workMinutes: workMinutes,
            workSeconds: workSeconds,
            restMinutes: restMinutes,
            restSeconds: restSeconds,
            countdownBeforeStart: countdownBeforeStart
        )
    }
}

/// Temporizador libre (Crear): configuración + reloj LED.
struct StandaloneTimerView: View {
    @Environment(GymbroStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var config: StandaloneTimerConfig
    @State private var showClock = false
    @State private var isRunning = false
    @State private var displaySeconds = 0
    @State private var roundNumber = 1
    @State private var phaseIsWork = true
    @State private var preCountdown = 0
    @State private var timer: Timer?
    @State private var showSaveAlert = false
    @State private var saveTitle = ""
    @State private var editingFavoriteId: UUID?

    var embedsNavigation = true

    init(
        embedsNavigation: Bool = true,
        config: StandaloneTimerConfig = StandaloneTimerConfig(),
        editingFavoriteId: UUID? = nil
    ) {
        self.embedsNavigation = embedsNavigation
        _config = State(initialValue: config)
        _editingFavoriteId = State(initialValue: editingFavoriteId)
        _saveTitle = State(initialValue: "")
    }

    var body: some View {
        Group {
            if embedsNavigation {
                NavigationStack { content }
            } else {
                content
            }
        }
        .fullScreenCover(isPresented: $showClock) {
            clockScreen
                .preferredColorScheme(.dark)
        }
        .alert("Guardar en favoritos", isPresented: $showSaveAlert) {
            TextField("Nombre", text: $saveTitle)
            Button("Guardar") { persistFavorite() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se guardará esta configuración para reutilizarla desde Favoritos.")
        }
        .onDisappear { stopTimer() }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    OGCardSectionTitle(title: "Tipo de temporizador")
                    Picker("Tipo", selection: $config.mode) {
                        ForEach(StandaloneTimerMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 0) {
                    OGCardSectionTitle(title: "Configuración")
                        .padding(.bottom, 10)

                    switch config.mode {
                    case .up, .down:
                        compactTimeRow(
                            title: "Duración",
                            minutes: $config.durationMinutes,
                            seconds: $config.durationSeconds,
                            maxMinutes: 180
                        )
                    case .intervals:
                        compactIntRow(title: "Rondas", value: $config.rounds, range: 1...99)
                        Divider().overlay(OG.surface3)
                        compactTimeRow(
                            title: "Trabajar",
                            minutes: $config.workMinutes,
                            seconds: $config.workSeconds,
                            maxMinutes: 60
                        )
                        Divider().overlay(OG.surface3)
                        compactTimeRow(
                            title: "Descansar",
                            minutes: $config.restMinutes,
                            seconds: $config.restSeconds,
                            maxMinutes: 30
                        )
                    }

                    Divider().overlay(OG.surface3)
                    Toggle(isOn: $config.countdownBeforeStart) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Cuenta atrás")
                                .foregroundStyle(OG.label)
                            Text("Antes de que comience el temporizador")
                                .font(.system(size: 13))
                                .foregroundStyle(OG.label3)
                        }
                    }
                    .tint(OG.accent)
                    .padding(.vertical, 10)
                }
                .padding(14)
                .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))

                Button {
                    prepareAndShowClock()
                } label: {
                    Text("Abrir reloj")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(OG.onAccent)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 52)
                        .background(OG.accent, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, OG.pad)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(OG.bg)
        .navigationTitle("Temporizador")
        .navigationBarTitleDisplayMode(.large)
        .ogTransparentNav()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                OGToolbarGlassButton(
                    systemName: editingFavoriteId == nil ? "star" : "star.fill",
                    accessibilityLabel: editingFavoriteId == nil ? "Guardar en favoritos" : "Actualizar favorito",
                    tint: OG.yellow
                ) {
                    saveTitle = editingFavoriteId.flatMap { id in
                        store.state.favoriteTimers.first { $0.id == id }?.title
                    } ?? defaultFavoriteTitle
                    showSaveAlert = true
                }
            }
        }
    }

    private var defaultFavoriteTitle: String {
        switch config.mode {
        case .up: return "Cronómetro \(String(format: "%d:%02d", config.durationMinutes, config.durationSeconds))"
        case .down: return "Cuenta atrás \(String(format: "%d:%02d", config.durationMinutes, config.durationSeconds))"
        case .intervals: return "Intervalos \(config.rounds)×"
        }
    }

    private func compactIntRow(title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .foregroundStyle(OG.label)
            Spacer(minLength: 8)
            Text("\(value.wrappedValue)")
                .font(.system(size: 17, weight: .semibold).monospacedDigit())
                .foregroundStyle(OG.blue)
                .frame(minWidth: 36, alignment: .trailing)
            minusPlus(
                minusEnabled: value.wrappedValue > range.lowerBound,
                plusEnabled: value.wrappedValue < range.upperBound,
                onMinus: { value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1) },
                onPlus: { value.wrappedValue = min(range.upperBound, value.wrappedValue + 1) }
            )
        }
        .padding(.vertical, 12)
    }

    private func compactTimeRow(
        title: String,
        minutes: Binding<Int>,
        seconds: Binding<Int>,
        maxMinutes: Int
    ) -> some View {
        let total = minutes.wrappedValue * 60 + seconds.wrappedValue
        return HStack(spacing: 12) {
            Text(title)
                .foregroundStyle(OG.label)
            Spacer(minLength: 8)
            Text(String(format: "%d:%02d", minutes.wrappedValue, seconds.wrappedValue))
                .font(.system(size: 17, weight: .semibold).monospacedDigit())
                .foregroundStyle(OG.blue)
                .frame(minWidth: 56, alignment: .trailing)
            minusPlus(
                minusEnabled: total > 0,
                plusEnabled: minutes.wrappedValue < maxMinutes || seconds.wrappedValue < 55,
                onMinus: { bumpTime(minutes: minutes, seconds: seconds, maxMinutes: maxMinutes, delta: -5) },
                onPlus: { bumpTime(minutes: minutes, seconds: seconds, maxMinutes: maxMinutes, delta: 5) }
            )
        }
        .padding(.vertical, 12)
    }

    private func minusPlus(
        minusEnabled: Bool,
        plusEnabled: Bool,
        onMinus: @escaping () -> Void,
        onPlus: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 8) {
            Button(action: onMinus) {
                Image(systemName: "minus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(minusEnabled ? OG.label : OG.label3)
                    .frame(width: 36, height: 36)
                    .background(OG.surface2, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(!minusEnabled)

            Button(action: onPlus) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(plusEnabled ? OG.label : OG.label3)
                    .frame(width: 36, height: 36)
                    .background(OG.surface2, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(!plusEnabled)
        }
    }

    private func bumpTime(minutes: Binding<Int>, seconds: Binding<Int>, maxMinutes: Int, delta: Int) {
        var total = minutes.wrappedValue * 60 + seconds.wrappedValue + delta
        total = max(0, min(maxMinutes * 60 + 59, total))
        minutes.wrappedValue = total / 60
        seconds.wrappedValue = total % 60
    }

    private func persistFavorite() {
        let name = saveTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = name.isEmpty ? defaultFavoriteTitle : name
        if let id = editingFavoriteId {
            store.saveFavoriteTimer(config.asFavorite(title: title, id: id))
        } else {
            let saved = store.saveFavoriteTimer(config.asFavorite(title: title))
            editingFavoriteId = saved.id
        }
    }

    private var clockScreen: some View {
        let skip: (() -> Void)? = config.mode == .intervals
            ? { skipInterval() }
            : nil
        return BlockTimerScreen(
            title: "Temporizador",
            subtitle: clockSubtitle,
            exercise: nil,
            roundNumber: config.mode == .intervals ? roundNumber : nil,
            totalRounds: config.mode == .intervals ? config.rounds : nil,
            displaySeconds: preCountdown > 0 ? preCountdown : displaySeconds,
            isRunning: isRunning,
            isCountingUp: config.mode == .up && preCountdown == 0,
            primaryTitle: primaryButtonTitle,
            onPrimary: { toggleRun() },
            onClose: {
                stopTimer()
                showClock = false
            },
            onSkip: skip
        )
    }

    private var clockSubtitle: String {
        if preCountdown > 0 { return "Cuenta atrás" }
        switch config.mode {
        case .up: return "Arriba"
        case .down: return "Abajo"
        case .intervals:
            return phaseIsWork ? "Trabajar" : "Descansar"
        }
    }

    private var primaryButtonTitle: String {
        if !isRunning { return "Comenzar" }
        if preCountdown > 0 { return "…" }
        return "Parar"
    }

    private func prepareAndShowClock() {
        stopTimer()
        isRunning = false
        phaseIsWork = true
        roundNumber = 1
        switch config.mode {
        case .up:
            displaySeconds = 0
        case .down:
            displaySeconds = config.durationTotalSeconds
        case .intervals:
            displaySeconds = config.workTotalSeconds
        }
        preCountdown = config.countdownBeforeStart ? 3 : 0
        showClock = true
    }

    private func toggleRun() {
        if isRunning {
            stopTimer(keepState: true)
            isRunning = false
        } else {
            isRunning = true
            startTicking()
        }
    }

    private func startTicking() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                tick()
            }
        }
    }

    private func tick() {
        if preCountdown > 0 {
            preCountdown -= 1
            RestFeedback.tick(
                remaining: preCountdown,
                sound: true,
                haptic: true
            )
            if preCountdown == 0 {
                RestFeedback.restComplete(sound: true, haptic: true)
            }
            return
        }
        guard isRunning else { return }

        switch config.mode {
        case .up:
            displaySeconds += 1
            if displaySeconds >= config.durationTotalSeconds {
                displaySeconds = config.durationTotalSeconds
                isRunning = false
                stopTimer(keepState: true)
                RestFeedback.restComplete(sound: true, haptic: true)
            }
        case .down:
            if displaySeconds <= 1 {
                displaySeconds = 0
                isRunning = false
                stopTimer(keepState: true)
                RestFeedback.restComplete(sound: true, haptic: true)
            } else {
                displaySeconds -= 1
                RestFeedback.tick(remaining: displaySeconds, sound: true, haptic: true)
            }
        case .intervals:
            if displaySeconds <= 1 {
                advanceInterval()
            } else {
                displaySeconds -= 1
                RestFeedback.tick(remaining: displaySeconds, sound: true, haptic: true)
            }
        }
    }

    private func advanceInterval() {
        RestFeedback.restComplete(sound: true, haptic: true)
        if phaseIsWork {
            if config.restTotalSeconds > 0 {
                phaseIsWork = false
                displaySeconds = config.restTotalSeconds
            } else {
                finishOrNextRound()
            }
        } else {
            finishOrNextRound()
        }
    }

    private func finishOrNextRound() {
        if roundNumber >= config.rounds {
            displaySeconds = 0
            isRunning = false
            stopTimer(keepState: true)
            RestFeedback.restComplete(sound: true, haptic: true)
            return
        }
        roundNumber += 1
        phaseIsWork = true
        displaySeconds = config.workTotalSeconds
    }

    private func skipInterval() {
        guard config.mode == .intervals else { return }
        advanceInterval()
    }

    private func stopTimer(keepState: Bool = false) {
        timer?.invalidate()
        timer = nil
        if !keepState {
            isRunning = false
            preCountdown = 0
        }
    }
}
