import Foundation
import Observation

/// Session-scoped rest timer. Wall-clock end date is the source of truth.
/// Survives `WorkoutView` disappear; cancel explicitly when the session ends.
@Observable
@MainActor
final class RestSessionCoordinator {
    private(set) var endDate: Date? {
        didSet { updateScreenAwake() }
    }
    private(set) var totalSeconds: Int = 0
    private(set) var isPaused = false {
        didSet { updateScreenAwake() }
    }
    private(set) var exerciseName: String?
    private var pausedRemaining: TimeInterval = 0
    private var feedbackTask: Task<Void, Never>?
    private var completionTask: Task<Void, Never>?
    private var soundEnabled = true
    private var hapticEnabled = true
    private var notifyToken: UInt64 = 0

    var isActive: Bool {
        if isPaused { return pausedRemaining > 0 }
        guard let endDate else { return false }
        return endDate > Date()
    }

    var remainingSeconds: Int {
        if isPaused {
            return max(0, Int(ceil(pausedRemaining)))
        }
        guard let endDate else { return 0 }
        return max(0, Int(ceil(endDate.timeIntervalSinceNow)))
    }

    private func updateScreenAwake() {
        TimerScreenAwake.setRunning(
            isPaused ? pausedRemaining > 0 : endDate.map { $0 > Date() } == true,
            for: .rest
        )
    }

    /// Al volver de segundo plano, liberar la pantalla si acabó el descanso
    /// mientras iOS suspendía la tarea, y anunciar el final una sola vez.
    func refreshWhenActive() {
        guard !isPaused, let endDate, endDate <= Date() else { return }
        finish(announce: true)
    }

    func start(
        seconds: Int,
        exerciseName: String?,
        sound: Bool,
        haptic: Bool
    ) {
        guard seconds > 0 else { return }
        if !isActive {
            RestLocalNotifier.cancelAll()
        }
        cancelTasks()
        self.soundEnabled = sound
        self.hapticEnabled = haptic
        self.exerciseName = exerciseName
        self.totalSeconds = seconds
        self.isPaused = false
        self.pausedRemaining = 0
        let end = Date().addingTimeInterval(TimeInterval(seconds))
        self.endDate = end
        notifyToken &+= 1
        let token = notifyToken
        Task { await RestLiveActivityCoordinator.shared.start(totalSeconds: seconds, endDate: end, exerciseName: exerciseName) }
        if soundEnabled {
            RestLocalNotifier.schedule(token: token, at: end, exerciseName: exerciseName)
        }
        scheduleCompletion(at: end)
        scheduleFeedback()
        publishRemoteCommands()
    }

    func pause() {
        guard !isPaused, let endDate else { return }
        pausedRemaining = max(0, endDate.timeIntervalSinceNow)
        isPaused = true
        self.endDate = nil
        cancelTasks()
        RestLocalNotifier.cancel(token: notifyToken)
        let remaining = max(0, Int(ceil(pausedRemaining)))
        Task { await RestLiveActivityCoordinator.shared.pause(remainingSeconds: remaining) }
        publishRemoteCommands()
    }

    func resume() {
        guard isPaused, pausedRemaining > 0 else { return }
        let seconds = max(1, Int(ceil(pausedRemaining)))
        isPaused = false
        pausedRemaining = 0
        let end = Date().addingTimeInterval(TimeInterval(seconds))
        endDate = end
        notifyToken &+= 1
        if soundEnabled {
            RestLocalNotifier.schedule(token: notifyToken, at: end, exerciseName: exerciseName)
        }
        scheduleCompletion(at: end)
        scheduleFeedback()
        Task {
            await RestLiveActivityCoordinator.shared.resume(
                totalSeconds: seconds, endDate: end, exerciseName: exerciseName
            )
        }
        publishRemoteCommands()
    }

    func skip() {
        ReperaAnalytics.track(.restTimerSkipped, parameters: [
            "feature_area": "timer",
            "timer_type": "rest",
            "result": "success"
        ])
        finish(announce: false)
    }

    /// Ajusta el temporizador en curso (p. ej. ±15 s en Play).
    func adjustRemaining(by delta: Int) {
        guard delta != 0, isActive else { return }
        if isPaused {
            pausedRemaining = max(0, pausedRemaining + TimeInterval(delta))
            return
        }
        guard let end = endDate else { return }
        let next = end.addingTimeInterval(TimeInterval(delta))
        endDate = max(next, Date())
        totalSeconds = max(totalSeconds, remainingSeconds)
        scheduleCompletion(at: endDate!)
        scheduleFeedback()
        publishRemoteCommands()
    }

    /// Call when the workout session is discarded or finished.
    func endForSessionClose() {
        finish(announce: false)
        RestLocalNotifier.cancelAll()
    }

    func tickFeedbackIfNeeded() {
        let remaining = remainingSeconds
        guard remaining > 0 else { return }
        RestFeedback.tick(
            remaining: remaining,
            sound: soundEnabled,
            haptic: hapticEnabled
        )
    }

    private func finish(announce: Bool) {
        cancelTasks()
        let shouldAnnounce = announce && remainingSeconds <= 1
        endDate = nil
        pausedRemaining = 0
        isPaused = false
        totalSeconds = 0
        RestLocalNotifier.cancel(token: notifyToken)
        Task { await RestLiveActivityCoordinator.shared.end() }
        RestRemoteCommandCenter.clear()
        if shouldAnnounce {
            RestFeedback.restComplete(sound: soundEnabled, haptic: hapticEnabled)
        }
    }

    private func publishRemoteCommands() {
        RestRemoteCommandCenter.publish(
            active: isActive,
            exerciseName: exerciseName,
            remaining: remainingSeconds,
            total: totalSeconds,
            paused: isPaused
        )
    }

    private func scheduleCompletion(at end: Date) {
        completionTask?.cancel()
        completionTask = Task { [weak self] in
            let nanos = UInt64(max(0, end.timeIntervalSinceNow) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanos)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self, !self.isPaused else { return }
                self.finish(announce: true)
            }
        }
    }

    /// Wakes only at the countdown thresholds (3, 2, 1 s left); completion is
    /// owned by `scheduleCompletion`. Pause/resume/start reschedule this task.
    private func scheduleFeedback() {
        feedbackTask?.cancel()
        guard let end = endDate else { return }
        feedbackTask = Task { [weak self] in
            for threshold in [3, 2, 1] {
                // Slightly after the boundary so ceil(remaining) == threshold.
                let wake = end.addingTimeInterval(-Double(threshold) + 0.05)
                let delay = wake.timeIntervalSinceNow
                if delay < -0.5 { continue }
                if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
                guard !Task.isCancelled else { return }
                guard let self, self.endDate == end, !self.isPaused else { return }
                RestFeedback.tick(
                    remaining: self.remainingSeconds,
                    sound: self.soundEnabled,
                    haptic: self.hapticEnabled
                )
            }
        }
    }

    private func cancelTasks() {
        feedbackTask?.cancel()
        feedbackTask = nil
        completionTask?.cancel()
        completionTask = nil
    }
}
