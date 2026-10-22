import Foundation
import ReperaDomain
import Observation

enum WorkoutClockEndReason: Equatable, Sendable {
    case countdownFinished
    case userFinished
}

/// Session-scoped WOD / block clock. Wall-clock dates are the source of truth —
/// survives `WorkoutView.onDisappear`; only stop on exercise change / session end / explicit close.
@Observable
@MainActor
final class WorkoutClockCoordinator {
    private(set) var isVisible = false
    private(set) var isRunning = false
    private(set) var isCountingUp = false
    private(set) var isIntervalMode = false
    private(set) var hasStarted = false
    private(set) var title = ""
    private(set) var subtitle = ""
    private(set) var exercise: Exercise?
    /// Motivo de fin pendiente de consumir por la UI (AMRAP cap / For Time stop).
    private(set) var pendingEndReason: WorkoutClockEndReason?
    private(set) var pendingElapsedSeconds: Int = 0
    /// Cap original en countdown (para AMRAP al completar).
    private var configuredCapSeconds: Int = 0
    private var countUpCapSeconds: Int?
    private var didNotifyCountUpCap = false

    /// TC en For Time es un límite informativo. El reloj sigue midiendo
    /// el tiempo real si el atleta supera el cap y aún no ha terminado.
    var isOverTimeCap: Bool {
        guard isCountingUp, hasStarted, let cap = countUpCapSeconds else { return false }
        return displaySeconds >= cap
    }

    private(set) var intervalIndex = 0
    private(set) var totalIntervals = 0
    private(set) var intervalLength = 60
    private var tabataWork = 20
    private var tabataRest = 10
    private var isTabata = false
    /// Número mostrado al atleta: una ronda Tabata incluye trabajo y descanso.
    var displayedRound: Int {
        guard isIntervalMode else { return 0 }
        if phaseRoundNumbers.indices.contains(intervalIndex) {
            return phaseRoundNumbers[intervalIndex]
        }
        return isTabata ? intervalIndex / 2 + 1 : intervalIndex + 1
    }
    var displayedRoundsTotal: Int {
        guard isIntervalMode else { return 0 }
        if let explicitRoundsTotal { return explicitRoundsTotal }
        return isTabata ? max(1, totalIntervals / 2) : totalIntervals
    }
    /// Duración real de cada fase (trabajo/descanso), no una longitud constante.
    private var phaseDurations: [Int] = []
    private var phaseSubtitles: [String] = []
    private var phaseRoundNumbers: [Int] = []
    private var explicitRoundsTotal: Int?
    private var allowsEarlyIntervalFinish = false

    /// Absolute end of pre-countdown (nil when not in pre).
    private var preCountdownEnd: Date?
    /// Absolute end of current countdown / interval phase.
    private var phaseEndDate: Date?
    /// Start of count-up (adjusted for pause).
    private var countUpAnchor: Date?
    private var pausedRemaining: TimeInterval = 0
    private var pausedCountUpElapsed: TimeInterval = 0
    private var soundEnabled = true
    private var hapticEnabled = true
    private var lastTickAnnounced: Int = -1
    private var feedbackTask: Task<Void, Never>?

    var isPreCountdown: Bool {
        guard let preCountdownEnd else { return false }
        return preCountdownEnd > Date()
    }

    var preCountdownSeconds: Int {
        guard let preCountdownEnd else { return 0 }
        return WallClockTimer.remainingSeconds(until: preCountdownEnd)
    }

    var displaySeconds: Int {
        displaySeconds(at: Date())
    }

    /// Read-only tick for `TimelineView` — no Observation mutations (catch-up lives in `feedbackTask`).
    func displaySeconds(at now: Date) -> Int {
        if let preCountdownEnd, preCountdownEnd > now {
            return WallClockTimer.remainingSeconds(until: preCountdownEnd, now: now)
        }
        if isCountingUp {
            guard let countUpAnchor else { return Int(pausedCountUpElapsed) }
            return WallClockTimer.elapsedSeconds(since: countUpAnchor, now: now)
        }
        if let phaseEndDate {
            return WallClockTimer.remainingSeconds(until: phaseEndDate, now: now)
        }
        return Int(ceil(pausedRemaining))
    }

    var primaryTitle: String {
        if isPreCountdown { return "…" }
        if !isRunning { return "Comenzar" }
        return "Pausar"
    }

    /// True cuando el usuario puede marcar fin en count-up (For Time).
    var canFinishByUser: Bool {
        (isCountingUp || (isIntervalMode && allowsEarlyIntervalFinish))
            && hasStarted && !isPreCountdown
    }

    func configure(
        exercise: Exercise,
        title: String,
        subtitle: String,
        countingUp: Bool,
        intervalMode: Bool,
        intervalLength: Int,
        totalIntervals: Int,
        initialCountdown: Int,
        tabataWork: Int? = nil,
        tabataRest: Int? = nil,
        timeCapSeconds: Int? = nil,
        customPhaseDurations: [Int]? = nil,
        customPhaseSubtitles: [String]? = nil,
        customRoundNumbers: [Int]? = nil,
        customRoundsTotal: Int? = nil,
        allowEarlyIntervalFinish: Bool = false,
        sound: Bool,
        haptic: Bool
    ) {
        stop(keepVisible: false)
        clearPendingEnd()
        self.exercise = exercise
        self.title = title
        self.subtitle = subtitle
        self.isCountingUp = countingUp
        self.isIntervalMode = intervalMode
        self.intervalLength = max(1, intervalLength)
        self.totalIntervals = max(0, totalIntervals)
        self.intervalIndex = 0
        self.isTabata = tabataWork != nil
        self.tabataWork = tabataWork ?? 20
        self.tabataRest = tabataRest ?? 10
        self.allowsEarlyIntervalFinish = allowEarlyIntervalFinish
        phaseRoundNumbers = customRoundNumbers ?? []
        explicitRoundsTotal = customRoundsTotal
        if intervalMode {
            if let custom = customPhaseDurations, !custom.isEmpty {
                phaseDurations = custom.map { max(1, $0) }
                phaseSubtitles = customPhaseSubtitles ?? []
            } else if let work = tabataWork, let rest = tabataRest {
                phaseDurations = (0..<max(1, totalIntervals)).map {
                    $0.isMultiple(of: 2) ? max(1, work) : max(1, rest)
                }
                phaseSubtitles = (0..<phaseDurations.count).map {
                    $0.isMultiple(of: 2) ? "Tabata · trabajo" : "Tabata · descanso"
                }
            } else {
                phaseDurations = Array(repeating: max(1, intervalLength), count: max(1, totalIntervals))
                phaseSubtitles = []
            }
            self.totalIntervals = phaseDurations.count
            self.intervalLength = phaseDurations[0]
            if let first = phaseSubtitles.first { self.subtitle = first }
        } else {
            phaseDurations = []
            phaseSubtitles = []
        }
        self.soundEnabled = sound
        self.hapticEnabled = haptic
        self.hasStarted = false
        self.isRunning = false
        countUpCapSeconds = countingUp ? timeCapSeconds.flatMap { $0 > 0 ? $0 : nil } : nil
        didNotifyCountUpCap = false
        if countingUp {
            configuredCapSeconds = countUpCapSeconds ?? 0
        } else if intervalMode {
            configuredCapSeconds = phaseDurations.reduce(0, +)
        } else {
            configuredCapSeconds = max(0, initialCountdown)
        }
        if countingUp {
            pausedCountUpElapsed = 0
            countUpAnchor = nil
        } else {
            pausedRemaining = TimeInterval(max(0, initialCountdown))
            phaseEndDate = nil
        }
        isVisible = true
    }

    /// Termina un cronómetro count-up (For Time) y publica el elapsed.
    func finishByUser() {
        guard canFinishByUser else { return }
        let elapsed: Int
        if isIntervalMode {
            let finishedPhases = phaseDurations.prefix(intervalIndex).reduce(0, +)
            elapsed = finishedPhases + max(0, intervalLength - displaySeconds)
        } else {
            elapsed = max(0, displaySeconds)
        }
        pendingElapsedSeconds = elapsed
        pendingEndReason = .userFinished
        RestFeedback.restComplete(sound: soundEnabled, haptic: hapticEnabled)
        stop(keepVisible: false)
    }

    func consumePendingEnd() -> (WorkoutClockEndReason, Int)? {
        guard let reason = pendingEndReason else { return nil }
        let elapsed = pendingElapsedSeconds
        clearPendingEnd()
        return (reason, elapsed)
    }

    func clearPendingEnd() {
        pendingEndReason = nil
        pendingElapsedSeconds = 0
    }

    func handlePrimary() {
        if isPreCountdown { return }
        if isRunning {
            pause()
        } else {
            if !hasStarted {
                hasStarted = true
                startPreCountdown(seconds: 3)
            } else {
                resume()
            }
        }
    }

    func skipInterval() {
        guard isIntervalMode, isRunning, !isPreCountdown else { return }
        if intervalIndex + 1 >= totalIntervals {
            finishComplete()
            return
        }
        advanceInterval(announce: true)
        phaseEndDate = nil
        armCurrentInterval(from: Date())
        scheduleFeedback()
    }

    /// Call when returning from background — catch up multiple skipped intervals at once.
    func syncFromWallClock(now: Date = Date()) {
        guard isRunning else { return }
        if let pre = preCountdownEnd {
            if now >= pre {
                preCountdownEnd = nil
                lastTickAnnounced = -1
                RestFeedback.intervalBeep(sound: soundEnabled, haptic: hapticEnabled)
                // El inicio real fue el final de la cuenta previa, no la
                // hora de regreso a la app (que podría ser minutos después).
                beginWorkPhase(from: pre)
                syncFromWallClock(now: now)
            }
            return
        }
        if isCountingUp {
            if let cap = countUpCapSeconds, displaySeconds(at: now) >= cap,
               !didNotifyCountUpCap {
                didNotifyCountUpCap = true
                // Avisar al TC una sola vez, pero nunca fabricar un tiempo
                // final de 14:00: el resultado será el elapsed al pulsar Terminar.
                RestFeedback.intervalBeep(sound: soundEnabled, haptic: hapticEnabled)
            }
            return
        }
        guard let end = phaseEndDate else { return }
        if now < end { return }

        if isIntervalMode {
            // Las fases de Tabata/circuito tienen duraciones distintas.
            // Saltar cada frontera de tiempo real, también tras ir a background,
            // sin repetir la longitud del primer intervalo.
            var boundary = end
            var advanced = false
            while now >= boundary {
                if intervalIndex + 1 >= totalIntervals {
                    finishComplete()
                    return
                }
                advanceInterval(announce: false)
                advanced = true
                boundary = boundary.addingTimeInterval(TimeInterval(intervalLength))
            }
            phaseEndDate = boundary
            if advanced {
                // Un solo aviso al volver de background, no uno por cada fase perdida.
                RestFeedback.intervalBeep(sound: soundEnabled, haptic: hapticEnabled)
            }
            scheduleFeedback()
        } else {
            finishComplete()
        }
    }

    /// Regresar a Play y apuntar series sin detener el reloj ni sus avisos.
    func minimize() {
        isVisible = false
    }

    func showClock() {
        guard hasStarted else { return }
        isVisible = true
    }

    /// Stop without dismissing UI (pause dock).
    func pause() {
        guard isRunning else { return }
        isRunning = false
        cancelFeedback()
        if let preCountdownEnd {
            pausedRemaining = max(0, preCountdownEnd.timeIntervalSinceNow)
            self.preCountdownEnd = nil
            // Treat remaining pre as pause into work arm later via resume → pre again if needed.
            return
        }
        if isCountingUp, let countUpAnchor {
            pausedCountUpElapsed = Date().timeIntervalSince(countUpAnchor)
            self.countUpAnchor = nil
        } else if let phaseEndDate {
            pausedRemaining = max(0, phaseEndDate.timeIntervalSinceNow)
            self.phaseEndDate = nil
        }
    }

    func resume() {
        guard !isRunning else { return }
        isRunning = true
        let now = Date()
        if isCountingUp {
            countUpAnchor = now.addingTimeInterval(-pausedCountUpElapsed)
            scheduleFeedback()
            return
        }
        if pausedRemaining > 0 {
            phaseEndDate = now.addingTimeInterval(pausedRemaining)
            pausedRemaining = 0
            scheduleFeedback()
        } else {
            beginWorkPhase(from: now)
        }
    }

    func stop(keepVisible: Bool = false) {
        cancelFeedback()
        isRunning = false
        preCountdownEnd = nil
        phaseEndDate = nil
        countUpAnchor = nil
        pausedRemaining = 0
        pausedCountUpElapsed = 0
        lastTickAnnounced = -1
        if !keepVisible {
            isVisible = false
            hasStarted = false
            intervalIndex = 0
            totalIntervals = 0
            isCountingUp = false
            isIntervalMode = false
            isTabata = false
            phaseDurations = []
            phaseSubtitles = []
            phaseRoundNumbers = []
            explicitRoundsTotal = nil
            allowsEarlyIntervalFinish = false
            configuredCapSeconds = 0
            countUpCapSeconds = nil
            exercise = nil
            title = ""
            subtitle = ""
        }
    }

    // MARK: - Private

    private func startPreCountdown(seconds: Int) {
        isRunning = true
        preCountdownEnd = Date().addingTimeInterval(TimeInterval(seconds))
        scheduleFeedback()
    }

    private func beginWorkPhase(from now: Date) {
        if isCountingUp {
            countUpAnchor = now.addingTimeInterval(-pausedCountUpElapsed)
            scheduleFeedback()
            return
        }
        armCurrentInterval(from: now)
        scheduleFeedback()
    }

    private func armCurrentInterval(from now: Date) {
        if isIntervalMode {
            phaseEndDate = now.addingTimeInterval(TimeInterval(intervalLength))
        } else if pausedRemaining > 0 {
            phaseEndDate = now.addingTimeInterval(pausedRemaining)
            pausedRemaining = 0
        } else if let existing = phaseEndDate, existing > now {
            // keep
        } else {
            // Initial countdown length was stored in pausedRemaining at configure.
            let seconds = max(1, Int(ceil(pausedRemaining > 0 ? pausedRemaining : TimeInterval(intervalLength))))
            phaseEndDate = now.addingTimeInterval(TimeInterval(seconds))
            pausedRemaining = 0
        }
    }

    private func advanceInterval(announce: Bool) {
        intervalIndex += 1
        if phaseDurations.indices.contains(intervalIndex) {
            intervalLength = phaseDurations[intervalIndex]
        }
        if phaseSubtitles.indices.contains(intervalIndex) {
            subtitle = phaseSubtitles[intervalIndex]
        } else if isTabata {
            subtitle = intervalIndex.isMultiple(of: 2) ? "Tabata · trabajo" : "Tabata · descanso"
        }
        if announce {
            RestFeedback.intervalBeep(sound: soundEnabled, haptic: hapticEnabled)
        }
    }

    private func finishComplete() {
        cancelFeedback()
        isRunning = false
        phaseEndDate = nil
        pausedRemaining = 0
        // También EMOM y Tabata deben emitir fin y cerrar el reloj;
        // las series no se inventan: las completa el modelo de sesión.
        pendingElapsedSeconds = configuredCapSeconds
        pendingEndReason = .countdownFinished
        RestFeedback.restComplete(sound: soundEnabled, haptic: hapticEnabled)
        isVisible = false
    }

    private func scheduleFeedback() {
        cancelFeedback()
        lastTickAnnounced = -1
        feedbackTask = Task { @MainActor in
            while !Task.isCancelled, isRunning {
                syncFromWallClock()
                let remaining = displaySeconds
                if isPreCountdown || (!isCountingUp && remaining <= 3 && remaining > 0) {
                    if remaining != lastTickAnnounced {
                        lastTickAnnounced = remaining
                        RestFeedback.tick(
                            remaining: remaining,
                            sound: soundEnabled,
                            haptic: hapticEnabled
                        )
                    }
                }
                if !isRunning { break }
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
        }
    }

    private func cancelFeedback() {
        feedbackTask?.cancel()
        feedbackTask = nil
    }
}
