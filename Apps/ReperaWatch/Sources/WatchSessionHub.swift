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
    private let health = WatchHealthKitSession()
    private var startedOnThisWatch = false
    private var awaitingHealthSave = false
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
        var startedOnThisWatch: Bool?
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
    var heartRateBpm: Int? { health.pulseBpm }
    var measuredEnergyKcal: Double? { health.kcal }
    var healthWarning: String? { health.permissionIssue }
    var healthRecording: Bool { health.isRecording }
    var hasWorkoutInProgress: Bool {
        guard let session = active else { return false }
        return session.phase != .finished
    }
    var current: SessionExercise? { active?.currentExercise }
    var currentIsWOD: Bool { current?.blockKind == .wod && current?.wodFormat != .strength }
    var wodUsesSeries: Bool { current?.wodFormat?.resultCapture == .perMovementSets }
    var intervalRemaining: Int? {
        guard let current, let format = current.wodFormat else { return nil }
        switch format {
        case .emom, .circuit:
            let interval = max(1, current.blockIntervalSeconds ?? 60)
            return interval - blockElapsed % interval
        case .tabata:
            let work = max(1, current.blockWorkSeconds ?? 20)
            let rest = max(0, current.blockRestSeconds ?? 10)
            let position = blockElapsed % max(1, work + rest)
            return position < work ? work - position : work + rest - position
        default: return nil
        }
    }
    var timeCapSeconds: Int {
        guard let exercise = current else { return 0 }
        if let minutes = exercise.blockTimeCapMinutes, minutes > 0 { return minutes * 60 }
        switch exercise.wodFormat {
        case .emom, .circuit:
            let count = exercise.plannedIntervals ?? 0
            return count > 0 ? count * max(1, exercise.blockIntervalSeconds ?? 60) : 0
        case .tabata:
            let rounds = exercise.blockRounds ?? 0
            guard rounds > 0 else { return 0 }
            let work = max(1, exercise.blockWorkSeconds ?? 20)
            let rest = max(0, exercise.blockRestSeconds ?? 10)
            return rounds * work + max(0, rounds - 1) * rest
        default: return 0
        }
    }
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
        health.onPauseResumeRequest = { [weak self] in self?.applyHealthPauseRequest() }
        health.onPauseStateChanged = { [weak self] paused in
            self?.alignWithHealthState(paused: paused)
        }
        connectivity.delegate = self
        connectivity.activate()
        if let active, startedOnThisWatch { health.recoverIfNeeded(id: active.id) }
        if let finished = lastFinished, startedOnThisWatch,
           finished.appleHealthProvenance == "watchHealthKitPending",
           finished.healthKitWorkoutUUID == nil {
            // Recovered workouts must be stopped and saved before the user can
            // discard the summary. A locked Watch can return no HKWorkout UUID.
            awaitingHealthSave = true
            health.recoverIfNeeded(id: finished.id) { [weak self] recovered in
                guard let self else { return }
                if recovered {
                    self.health.finish { [weak self] result in
                        self?.applySavedHealth(result, to: finished.id)
                    }
                } else {
                    self.awaitingHealthSave = false
                    self.save()
                }
            }
        }
        if let finished = lastFinished, acknowledgedSessionID != finished.id {
            connectivity.sendFinished(finished)
        }
        startClock()
        if active?.phase == .counting && !isPaused { startMotion() }
    }

    func recoverHealthSession() {
        if let active, startedOnThisWatch {
            health.recoverIfNeeded(id: active.id)
        }
    }

    func applicationWillResignActive() {
        tickClock()
        save()
    }

    /// HealthKit sends physical two-button pause requests and state changes.
    /// Repera remains the owner of interval and set timers; both clocks pause together.
    private func applyHealthPauseRequest() {
        guard hasWorkoutInProgress, active?.phase == .counting, !reviewingBlock else { return }
        if isPaused { play() } else { pause() }
    }

    private func alignWithHealthState(paused: Bool) {
        guard hasWorkoutInProgress, active?.phase == .counting, !reviewingBlock,
              paused != isPaused else { return }
        if paused { pause() } else { play() }
    }

    func startToday() {
        guard !hasWorkoutInProgress, !awaitingHealthSave,
              let plan = todaysWorkout, !plan.exercises.isEmpty else { return }
        stopMotion()
        // The prescription ID is not the execution ID. Repeating a plan
        // creates a fresh workout, never overwriting a previous result.
        let execution = WorkoutSession(
            title: plan.title, routineId: plan.routineId,
            exercises: plan.exercises, routineBlocks: plan.routineBlocks
        )
        var next = SessionController(session: execution)
        next.startOnPhone()
        controller = next
        startedOnThisWatch = true
        health.start(
            id: next.session.id, at: next.session.startedAt ?? Date(),
            includesWOD: plan.exercises.contains { $0.blockKind == .wod },
            includesStrength: plan.exercises.contains { $0.blockKind == .strength }
        )
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
            if startedOnThisWatch { health.resume() }
            checkpoint()
            return
        }
        if ctrl.session.phase == .ready {
            ctrl.confirmCurrentExercise()
            controller = ctrl
            if startedOnThisWatch, let exercise = ctrl.session.currentExercise {
                health.beginBlock(
                    id: exercise.blockId ?? exercise.id,
                    isInterval: exercise.blockKind == .wod
                )
            }
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
        if startedOnThisWatch { health.pause() }
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
                    quantityUnit: exercise.quantityUnit, rir: nil)
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

    /// EMOM/Tabata/circuit: each performed interval must be confirmed by the athlete.
    /// The timer never manufactures a set or assumes a repetition took place.
    func confirmIntervalSet() {
        guard wodUsesSeries, currentIsWOD, !isPaused, !reviewingBlock,
              var ctrl = controller, ctrl.session.phase == .counting else { return }
        ctrl.logSet(reps: max(0, workingReps), weightKg: workingWeightKg,
                    quantityUnit: ctrl.session.currentExercise?.quantityUnit)
        controller = ctrl
        workingReps = 0
        repCounter.reset()
        stopMotion()
        if let exercise = current {
            if exercise.wodFormat == .tabata {
                restRemaining = max(0, exercise.blockRestSeconds ?? 10)
            } else {
                let length = max(1, exercise.blockIntervalSeconds ?? 60)
                let remainder = blockElapsed % length
                restRemaining = remainder == 0 ? 0 : length - remainder
            }
        }
        if restRemaining == 0 { startMotion() }
        WKInterfaceDevice.current().play(.success)
        checkpoint()
    }

    func nextWODMovement() {
        guard currentIsWOD, wodUsesSeries, !reviewingBlock,
              let session = active, var ctrl = controller,
              let currentID = current?.blockId else { return }
        let members = session.exercises.indices.filter {
            session.exercises[$0].blockId == currentID
        }
        guard members.count > 1, let position = members.firstIndex(of: session.currentIndex) else { return }
        let next = members[(position + 1) % members.count]
        ctrl.selectExercise(at: next)
        ctrl.confirmCurrentExercise()
        controller = ctrl
        workingReps = 0
        workingWeightKg = ctrl.session.currentExercise?.plannedSets.first?.targetWeightKg
        repCounter.reset()
        if restRemaining == 0 && !isPaused { startMotion() }
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
        let previousBlock = ctrl.session.currentExercise?.blockId
        _ = ctrl.finishCurrentExercise()
        let continuesBlock = previousBlock != nil
            && ctrl.session.currentExercise?.blockId == previousBlock
            && ctrl.session.phase == .ready
        if continuesBlock { ctrl.confirmCurrentExercise() }
        controller = ctrl
        if !continuesBlock { blockElapsed = 0 }
        restRemaining = 0
        workingReps = 0
        workingWeightKg = ctrl.session.currentExercise?.plannedSets.first?.targetWeightKg
        repCounter.reset()
        if ctrl.session.phase == .finished { completeSession() }
        else {
            if continuesBlock { startMotion() }
            checkpoint()
        }
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
        if startedOnThisWatch { health.pause() }
        checkpoint()
    }

    /// WOD score is global (AMRAP rounds/reps, For Time seconds), not fake sets.
    func confirmBlock() {
        guard reviewingBlock, var ctrl = controller,
              let current = ctrl.session.currentExercise,
              let id = current.blockId else { return }
        let format = current.wodFormat
        let elapsed: Int? = format?.resultCapture == .elapsedTime ? blockElapsed : nil
        let rounds: Int? = format == .amrap ? completedRounds : nil
        let reps: Int? = format?.resultCapture == .totalReps ? remainingRoundReps : nil
        let score = WODBlockResult(id: id, format: format,
                                   totalReps: reps, elapsedSeconds: elapsed,
                                   roundsCompleted: rounds)
        if !wodUsesSeries { ctrl.recordWODResult(score) }
        _ = ctrl.finishCurrentBlock()
        controller = ctrl
        reviewingBlock = false
        isPaused = false
        if ctrl.session.phase != .finished, startedOnThisWatch { health.resume() }
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
        guard !hasWorkoutInProgress, !awaitingHealthSave else { return }
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
        // Do not label Repera's wall-clock as Apple-measured duration.
        // If the Watch is recording, HealthKit may complete while device is locked.
        if startedOnThisWatch && health.isRecording {
            result.appleHealthProvenance = "watchHealthKitPending"
        }
        lastFinished = result
        controller = nil
        isPaused = false
        reviewingBlock = false
        lastClockTick = nil
        save() // Crash-safe before queuing the transport.
        connectivity.sendFinished(result)
        if startedOnThisWatch {
            awaitingHealthSave = true
            let id = result.id
            health.finish { [weak self] metrics in
                self?.applySavedHealth(metrics, to: id)
            }
        }
        WKInterfaceDevice.current().play(.success)
    }

    private func applySavedHealth(_ metrics: WatchHealthKitSession.Result, to id: UUID) {
        guard var saved = lastFinished, saved.id == id else { return }
        if let uuid = metrics.uuid {
            saved.healthKitWorkoutUUID = uuid
            saved.appleHealthProvenance = "watchHealthKit"
        }
        if let seconds = metrics.durationSeconds { saved.appleDurationSeconds = seconds }
        if let kcal = metrics.activeEnergyKcal { saved.appleActiveEnergyKcal = kcal }
        if let bpm = metrics.averageHeartRateBpm { saved.appleAverageHeartRateBpm = bpm }
        if let start = metrics.start { saved.startedAt = start }
        if let end = metrics.end { saved.finishedAt = end }
        lastFinished = saved
        awaitingHealthSave = false
        acknowledgedSessionID = nil
        save()
        connectivity.sendFinished(saved)
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
        let step = WorkoutClockMath.advance(
            from: lastClockTick, to: Date(),
            sessionElapsed: sessionElapsed, blockElapsed: blockElapsed,
            restRemaining: restRemaining, isCounting: active?.phase == .counting,
            isWOD: currentIsWOD, timeCapSeconds: timeCapSeconds
        )
        let delta = step.advancedSeconds
        guard delta > 0 else { return }
        self.lastClockTick = lastClockTick.addingTimeInterval(Double(delta))
        let previous = blockElapsed
        let wasResting = restRemaining > 0
        let isCounting = active?.phase == .counting
        sessionElapsed = step.sessionElapsed
        blockElapsed = step.blockElapsed
        restRemaining = step.restRemaining

        if step.reachedTimeCap {
            reviewBlock()
            return
        }
        if wasResting, restRemaining == 0 {
            WKInterfaceDevice.current().play(.notification)
            startMotion()
            checkpoint()
        }
        guard isCounting, restRemaining == 0 else { return }
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
        if sessionElapsed % 10 < delta {
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
            clockTick: lastClockTick, acknowledgedSessionID: acknowledgedSessionID,
            startedOnThisWatch: startedOnThisWatch
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
        startedOnThisWatch = snapshot.startedOnThisWatch ?? false
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

    nonisolated func watchConnectivityDidReceiveToday(_ today: WorkoutSession?, scheduledDay: Date?) {
        Task { @MainActor in
            self.todayPlan = today
            self.todayUpdatedAt = scheduledDay
            self.save()
        }
    }

    nonisolated func watchConnectivityDidAcknowledge(sessionId: UUID, healthKitUUID: UUID?) {
        Task { @MainActor in
            // Never acknowledge an older, unverified revision after the Watch
            // attached a newly saved HKWorkout with the same Repera session ID.
            if self.lastFinished?.id == sessionId,
               self.lastFinished?.healthKitWorkoutUUID == healthKitUUID,
               !self.awaitingHealthSave {
                self.acknowledgedSessionID = sessionId
                self.connectivity.acknowledge(sessionId)
                self.save()
            }
        }
    }
}
