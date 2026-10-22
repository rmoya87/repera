import CoreMotion
import Foundation
import Observation
import ReperaDomain
import WatchConnectivity
import WatchKit

/// Offline-first workout owner. The phone sends plans, not instructions for every rep.
@Observable
@MainActor
final class WatchSessionHub: NSObject {
    private(set) var controller: SessionController?
    private(set) var todayPlan: WorkoutSession?
    private(set) var lastFinished: WorkoutSession?
    private(set) var isPaused = false
    private(set) var restRemaining = 0
    private(set) var blockElapsed = 0
    private(set) var sessionElapsed = 0
    private(set) var workingReps = 0
    private(set) var workingWeightKg: Double?
    private(set) var completedRounds = 0
    private(set) var remainingRoundReps = 0
    private(set) var reviewingBlock = false
    private(set) var acknowledgedSessionID: UUID?

    private let connectivity = WatchConnectivityClient()
    private let motion = CMMotionManager()
    private var repCounter = MotionRepCounter()
    private var motionTimer: Timer?
    private var clockTimer: Timer?
    private var lastClockTick: Date?
    private var lastIntervalIndex = 0
    private var todayUpdatedAt: Date?
    private let persistenceKey = "repera.watch.offlineState.v1"

    private struct OfflineState: Codable {
        var current: WorkoutSession?
        var today: WorkoutSession?
        var todayUpdatedAt: Date?
        var finished: WorkoutSession?
        var paused: Bool
        var restRemaining: Int
        var blockElapsed: Int
        var sessionElapsed: Int
        var workingReps: Int
        var workingWeightKg: Double?
        var completedRounds: Int
        var remainingRoundReps: Int
        var reviewingBlock: Bool
        var clockTick: Date?
        var acknowledgedSessionID: UUID?
    }

    override init() {
        super.init()
        restore()
    }

    var todaysWorkout: WorkoutSession? {
        guard let todayUpdatedAt, Calendar.current.isDateInToday(todayUpdatedAt) else { return nil }
        return todayPlan
    }

    var active: WorkoutSession? { controller?.session }
    var hasWorkoutInProgress: Bool {
        guard let session = active else { return false }
        return session.phase != .finished
    }
    var current: SessionExercise? { active?.currentExercise }
    var currentIsWOD: Bool { current?.blockKind == .wod && current?.wodFormat != .strength }
    var timeCapSeconds: Int { max(0, (current?.blockTimeCapMinutes ?? 0) * 60) }
    var timeRemaining: Int? { timeCapSeconds > 0 ? max(0, timeCapSeconds - blockElapsed) : nil }
    var plannedSets: Int { current?.plannedSets.count ?? 0 }
    var completedSets: Int { current?.loggedSets.count ?? 0 }
    var blockExercises: [SessionExercise] {
        guard let active, let current else { return [] }
        guard let blockID = current.blockId else { return [current] }
        return active.exercises.filter { $0.blockId == blockID }
    }
    var intervalLabel: String? {
        guard let current, let format = current.wodFormat else { return nil }
        switch format {
        case .emom, .circuit:
            let interval = max(1, current.blockIntervalSeconds ?? 60)
            let currentNumber = blockElapsed / interval + 1
            let maxIntervals = current.plannedIntervals
            if let maxIntervals { return "Intervalo \(min(currentNumber, maxIntervals))/\(maxIntervals)" }
            return "Intervalo \(currentNumber)"
        case .tabata:
            let work = max(1, current.blockWorkSeconds ?? 20)
            let rest = max(0, current.blockRestSeconds ?? 10)
            let cycle = max(1, work + rest)
            let round = blockElapsed / cycle + 1
            let phase = blockElapsed % cycle < work ? "Trabajo" : "Descanso"
            return "\(phase) · ronda \(round)"
        default: return nil
        }
    }

    func activate() {
        connectivity.delegate = self
        connectivity.activate()
        startClock()
        if active?.phase == .counting && !isPaused { startMotion() }
    }

    func applicationWillResignActive() {
        tickClock()
        save()
    }

    func startToday() {
        guard let plan = todaysWorkout, !plan.exercises.isEmpty else { return }
        stopMotion()
        var next = SessionController(session: plan)
        next.startOnPhone()
        controller = next
        lastFinished = nil
        acknowledgedSessionID = nil
        isPaused = false
        reviewingBlock = false
        restRemaining = 0
        blockElapsed = 0
        sessionElapsed = 0
        workingReps = 0
        workingWeightKg = next.session.currentExercise?.plannedSets.first?.targetWeightKg
        completedRounds = 0
        remainingRoundReps = 0
        lastIntervalIndex = 0
        lastClockTick = Date()
        startClock()
        checkpoint()
    }

    /// One play per block / standalone exercise. A counting session does not reset.
    func play() {
        guard var ctrl = controller, ctrl.session.phase != .finished else { return }
        if isPaused {
            isPaused = false
            lastClockTick = Date()
            if ctrl.session.phase == .counting && restRemaining == 0 { startMotion() }
            checkpoint()
            return
        }
        if ctrl.session.phase == .ready {
            ctrl.confirmCurrentExercise()
            controller = ctrl
            blockElapsed = 0
            completedRounds = 0
            remainingRoundReps = 0
            restRemaining = 0
            workingReps = 0
            workingWeightKg = ctrl.session.currentExercise?.plannedSets.first?.targetWeightKg
            repCounter.reset()
            lastIntervalIndex = 0
            reviewingBlock = false
            lastClockTick = Date()
            startMotion()
            checkpoint()
        }
    }

    func pause() {
        guard hasWorkoutInProgress, active?.phase == .counting, !isPaused else { return }
        tickClock()
        isPaused = true
        lastClockTick = nil
        stopMotion()
        checkpoint()
    }

    func skipRest() {
        restRemaining = 0
        lastClockTick = Date()
        if !isPaused { startMotion() }
        checkpoint()
    }

    func adjustReps(_ delta: Int) {
        guard active?.phase == .counting, !isPaused, !reviewingBlock else { return }
        workingReps = max(0, workingReps + delta)
        repCounter.applyManualDelta(delta)
        save()
    }

    func adjustWeight(_ delta: Double) {
        guard active?.phase == .counting, !isPaused, !reviewingBlock else { return }
        workingWeightKg = max(0, ((workingWeightKg ?? 0) + delta) * 2).rounded() / 2
        save()
    }

    /// Motion detection is just a suggestion; the athlete confirms the actual set.
    func confirmSet() {
        guard !isPaused, !reviewingBlock, !currentIsWOD,
              var ctrl = controller, ctrl.session.phase == .counting,
              let exercise = ctrl.session.currentExercise else { return }
        let reps = max(0, workingReps)
        let index = exercise.loggedSets.count
        let prescribed = exercise.plannedSets.indices.contains(index)
            ? exercise.plannedSets[index] : exercise.plannedSets.last
        ctrl.logSet(reps: reps, weightKg: workingWeightKg,
                    rir: nil)
        controller = ctrl
        workingReps = 0
        repCounter.reset()
        workingWeightKg = ctrl.session.currentExercise?.plannedSets.dropFirst(index + 1).first?.targetWeightKg
            ?? prescribed?.targetWeightKg
        stopMotion()
        if ctrl.session.currentExercise?.loggedSets.count ?? 0 < plannedSets {
            restRemaining = max(0, exercise.restSeconds ?? exercise.blockRestSeconds ?? 0)
        } else {
            restRemaining = 0
        }
        if restRemaining == 0 { startMotion() }
        WKInterfaceDevice.current().play(.success)
        checkpoint()
    }

    /// "Siguiente" is explicit; never manufacture a missing prescribed set.
    func advance() {
        guard var ctrl = controller, !isPaused, !reviewingBlock,
              ctrl.session.phase != .finished else { return }
        if currentIsWOD {
            reviewBlock()
            return
        }
        stopMotion()
        _ = ctrl.finishCurrentExercise()
        controller = ctrl
        blockElapsed = 0
        restRemaining = 0
        workingReps = 0
        workingWeightKg = ctrl.session.currentExercise?.plannedSets.first?.targetWeightKg
        repCounter.reset()
        if ctrl.session.phase == .finished { completeSession() }
        else { checkpoint() }
    }

    func adjustRounds(_ delta: Int) {
        completedRounds = max(0, completedRounds + delta)
        save()
    }

    func adjustExtraReps(_ delta: Int) {
        remainingRoundReps = max(0, remainingRoundReps + delta)
        save()
    }

    func reviewBlock() {
        guard currentIsWOD, controller != nil else { return }
        tickClock()
        isPaused = true
        reviewingBlock = true
        lastClockTick = nil
        stopMotion()
        checkpoint()
    }

    /// WOD score is global (AMRAP rounds/reps, For Time seconds), not fake sets.
    func confirmBlock() {
        guard reviewingBlock, var ctrl = controller,
              let current = ctrl.session.currentExercise,
              let id = current.blockId else { return }
        let format = current.wodFormat
        let elapsed: Int? = (format == .forTime || format == .afap || format == .chipper)
            ? blockElapsed : nil
        let rounds: Int? = (format == .amrap || format == .roundsForQuality)
            ? completedRounds : nil
        let reps: Int? = format == .amrap ? remainingRoundReps : nil
        let score = WODBlockResult(id: id, format: format,
                                   totalReps: reps, elapsedSeconds: elapsed,
                                   roundsCompleted: rounds)
        ctrl.recordWODResult(score)
        _ = ctrl.finishCurrentBlock()
        controller = ctrl
        reviewingBlock = false
        isPaused = false
        blockElapsed = 0
        restRemaining = 0
        workingReps = 0
        repCounter.reset()
        lastClockTick = Date()
        if ctrl.session.phase == .finished { completeSession() }
        else { checkpoint() }
    }

    /// The final action is explicit and saves the already-confirmed results.
    func finishWorkout() {
        guard var ctrl = controller else { return }
        tickClock()
        stopMotion()
        ctrl.finishWorkout()
        controller = ctrl
        completeSession()
    }

    func clearSummary() {
        guard !hasWorkoutInProgress else { return }
        lastFinished = nil
        controller = nil
        acknowledgedSessionID = nil
        checkpoint()
    }

    private func completeSession() {
        guard let finished = controller?.session else { return }
        stopMotion()
        stopClock()
        var result = finished
        if result.phase != .finished {
            var ctrl = SessionController(session: result)
            ctrl.finishWorkout()
            result = ctrl.session
        }
        result.appleDurationSeconds = TimeInterval(max(0, sessionElapsed))
        lastFinished = result
        controller = nil
        isPaused = false
        reviewingBlock = false
        lastClockTick = nil
        save() // Crash-safe before queuing the transport.
        connectivity.sendFinished(result)
        WKInterfaceDevice.current().play(.success)
    }

    private func startClock() {
        guard clockTimer == nil else { return }
        clockTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tickClock() }
        }
    }

    private func stopClock() {
        clockTimer?.invalidate()
        clockTimer = nil
    }

    private func tickClock() {
        guard hasWorkoutInProgress, !isPaused, let lastClockTick else { return }
        let now = Date()
        let delta = max(0, min(3600, Int(now.timeIntervalSince(lastClockTick))))
        guard delta > 0 else { return }
        self.lastClockTick = lastClockTick.addingTimeInterval(Double(delta))
        sessionElapsed += delta
        if restRemaining > 0 {
            restRemaining = max(0, restRemaining - delta)
            if restRemaining == 0 {
                WKInterfaceDevice.current().play(.notification)
                startMotion()
                checkpoint()
            }
            return
        }
        guard active?.phase == .counting else { return }
        let previous = blockElapsed
        blockElapsed += delta
        if let current, let interval = current.blockIntervalSeconds, interval > 0,
           blockElapsed / interval > previous / interval {
            WKInterfaceDevice.current().play(.click)
        }
        if current?.wodFormat == .tabata, let current {
            let cycle = max(1, (current.blockWorkSeconds ?? 20) + (current.blockRestSeconds ?? 10))
            let oldPosition = previous % cycle
            let newPosition = blockElapsed % cycle
            let work = current.blockWorkSeconds ?? 20
            if previous / cycle < blockElapsed / cycle ||
               (oldPosition < work && newPosition >= work) {
                WKInterfaceDevice.current().play(.click)
            }
        }
        if let timeRemaining, timeRemaining == 0, currentIsWOD {
            reviewBlock()
        } else if sessionElapsed % 10 < delta {
            save()
        }
    }

    private func startMotion() {
        stopMotion()
        guard !isPaused, restRemaining == 0, motion.isDeviceMotionAvailable,
              active?.phase == .counting else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 25.0
        motion.startDeviceMotionUpdates(using: .xArbitraryZVertical)
        motionTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tickMotion() }
        }
    }

    private func stopMotion() {
        motionTimer?.invalidate()
        motionTimer = nil
        motion.stopDeviceMotionUpdates()
    }

    private func tickMotion() {
        guard !isPaused, !reviewingBlock, restRemaining == 0,
              active?.phase == .counting, let data = motion.deviceMotion else { return }
        let u = data.userAcceleration
        let magnitude = sqrt(u.x * u.x + u.y * u.y + u.z * u.z) + 1.0
        repCounter.ingest(magnitude: magnitude)
        workingReps = repCounter.count
    }

    private func checkpoint() {
        save()
        if let current = active { connectivity.sendCurrent(current) }
    }

    private func save() {
        let snapshot = OfflineState(
            current: active, today: todayPlan, todayUpdatedAt: todayUpdatedAt,
            finished: lastFinished, paused: isPaused, restRemaining: restRemaining,
            blockElapsed: blockElapsed, sessionElapsed: sessionElapsed,
            workingReps: workingReps, workingWeightKg: workingWeightKg,
            completedRounds: completedRounds,
            remainingRoundReps: remainingRoundReps, reviewingBlock: reviewingBlock,
            clockTick: lastClockTick, acknowledgedSessionID: acknowledgedSessionID
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }

    private func restore() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey),
              let snapshot = try? JSONDecoder().decode(OfflineState.self, from: data) else { return }
        controller = snapshot.current.map(SessionController.init(session:))
        todayPlan = snapshot.today
        todayUpdatedAt = snapshot.todayUpdatedAt
        lastFinished = snapshot.finished
        isPaused = snapshot.paused
        restRemaining = snapshot.restRemaining
        blockElapsed = snapshot.blockElapsed
        sessionElapsed = snapshot.sessionElapsed
        workingReps = snapshot.workingReps
        workingWeightKg = snapshot.workingWeightKg
        completedRounds = snapshot.completedRounds
        remainingRoundReps = snapshot.remainingRoundReps
        reviewingBlock = snapshot.reviewingBlock
        lastClockTick = snapshot.clockTick
        acknowledgedSessionID = snapshot.acknowledgedSessionID
    }
}

extension WatchSessionHub: WatchConnectivityClientDelegate {
    nonisolated func watchConnectivityDidReceive(session: WorkoutSession?) {
        Task { @MainActor in
            guard let session else { return } // Nil from phone cannot erase offline edits.
            guard self.controller == nil, self.lastFinished?.id != session.id,
                  session.phase != .finished else { return }
            self.controller = SessionController(session: session)
            self.lastClockTick = Date()
            self.startClock()
            self.save()
        }
    }

    nonisolated func watchConnectivityDidReceiveToday(_ today: WorkoutSession?) {
        Task { @MainActor in
            self.todayPlan = today
            self.todayUpdatedAt = Date()
            self.save()
        }
    }

    nonisolated func watchConnectivityDidAcknowledge(sessionId: UUID) {
        Task { @MainActor in
            if self.lastFinished?.id == sessionId {
                self.acknowledgedSessionID = sessionId
                self.save()
            }
        }
    }
}
