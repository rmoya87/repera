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
    private(set) var selectedSetIndex: Int?
    private(set) var workingWeightKg: Double?
    private(set) var setDraft = WatchSetDraft()
    private(set) var summaryDismissed = false
    private(set) var completedRounds = 0
    private(set) var remainingRoundReps = 0
    private(set) var reviewElapsedSeconds: Int?
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
        var setDraft: WatchSetDraft?
        var selectedSetIndex: Int?
        var summaryDismissed: Bool?
        var completedRounds: Int
        var remainingRoundReps: Int
        var reviewElapsedSeconds: Int?
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
    var presentedSummary: WorkoutSession? { summaryDismissed ? nil : lastFinished }
    var loggingStyle: ExerciseLoggingStyle { current?.exercise.loggingStyle ?? .loadAndReps }
    var effectiveReps: Int {
        if setDraft.kind == .restpause && !setDraft.clusters.isEmpty {
            return setDraft.clusters.reduce(0) { $0 + $1.reps }
        }
        return workingReps
    }
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
    /// Align the Watch's main timer with the equivalent iPhone WOD format.
    var isIntervalClock: Bool {
        switch current?.wodFormat {
        case .emom, .tabata, .circuit, .deathBy: return true
        default: return false
        }
    }

    var clockCountsUp: Bool {
        guard let current else { return true }
        switch current.wodFormat {
        case .forTime, .chipper, .afap, .ladder, .buyInCashOut:
            return true
        case .amrap, .emom, .tabata, .deathBy, .circuit, .maxEffort:
            return false
        case .strength, .partner, .roundsForQuality, .none:
            return (current.blockTimeCapMinutes ?? 0) <= 0
        }
    }

    /// Mirror iPhone circuit phases, including rest between (not after) rounds.
    private var circuitPhases: [(duration: Int, title: String)] {
        guard let current, current.wodFormat == .circuit else { return [] }
        let stations = max(1, blockExercises.count)
        let interval = max(5, current.blockIntervalSeconds ?? 60)
        let workCount = max(1, (current.blockTimeCapMinutes ?? 0) > 0
            ? (current.plannedIntervals ?? stations)
            : stations * max(1, current.blockRounds ?? 1))
        let roundRest = max(0, current.blockRestBetweenRoundsSeconds ?? 0)
        var phases: [(duration: Int, title: String)] = []
        for index in 0..<workCount {
            let round = index / stations + 1
            phases.append((interval, "Estación \(index % stations + 1)/\(stations) · R\(round)"))
            if (index + 1).isMultiple(of: stations), index + 1 < workCount, roundRest > 0 {
                phases.append((roundRest, "Descanso · ronda \(round)"))
            }
        }
        return phases
    }

    private var circuitPhase: (remaining: Int, label: String)? {
        guard current?.wodFormat == .circuit else { return nil }
        var elapsed = blockElapsed
        let phases = circuitPhases
        for phase in phases {
            if elapsed < phase.duration {
                return (remaining: phase.duration - elapsed, label: phase.title)
            }
            elapsed -= phase.duration
        }
        return phases.last.map { (remaining: 0, label: $0.title) }
    }

    var intervalRemaining: Int? {
        guard let current, let format = current.wodFormat, isIntervalClock else { return nil }
        if timeCapSeconds > 0 && blockElapsed >= timeCapSeconds { return 0 }
        switch format {
        case .emom, .deathBy:
            let interval = max(1, current.blockIntervalSeconds ?? 60)
            return interval - blockElapsed % interval
        case .circuit:
            return circuitPhase?.remaining
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
        switch exercise.wodFormat {
        case .emom:
            let intervals = max(1, exercise.plannedIntervals ?? exercise.blockRounds ?? 10)
            return intervals * max(15, exercise.blockIntervalSeconds ?? 60)
        case .deathBy:
            let intervals = max(1, exercise.plannedIntervals ?? exercise.blockTimeCapMinutes ?? 30)
            return intervals * max(15, exercise.blockIntervalSeconds ?? 60)
        case .circuit:
            return circuitPhases.reduce(0) { $0 + $1.duration }
        case .tabata:
            let rounds = max(1, exercise.blockRounds ?? 8)
            let work = max(5, exercise.blockWorkSeconds ?? 20)
            let rest = max(1, exercise.blockRestSeconds ?? 10)
            return rounds * (work + rest)
        case .amrap, .maxEffort:
            return max(60, (exercise.blockTimeCapMinutes ?? 12) * 60)
        case .forTime, .chipper, .afap, .ladder, .buyInCashOut:
            // For Time time caps are informational: the clock keeps counting up.
            return 0
        case .strength, .partner, .roundsForQuality, .none:
            return max(0, exercise.blockTimeCapMinutes ?? 0) * 60
        }
    }

    var timeRemaining: Int? {
        clockCountsUp || timeCapSeconds <= 0 ? nil : max(0, timeCapSeconds - blockElapsed)
    }

    /// Never show the total duration as a second number in interval mode.
    var primaryClockSeconds: Int {
        intervalRemaining ?? timeRemaining ?? blockElapsed
    }

    var intervalsFinished: Bool {
        isIntervalClock && wodUsesSeries && timeCapSeconds > 0
            && blockElapsed >= timeCapSeconds
    }

    var clockDescriptor: String? {
        if intervalsFinished { return "Finalizado" }
        if isIntervalClock { return intervalLabel }
        if !clockCountsUp, timeCapSeconds > 0 {
            return current?.wodFormat?.displayName ?? "Cuenta atrás"
        }
        if clockCountsUp, (current?.blockTimeCapMinutes ?? 0) > 0,
           blockElapsed > (current?.blockTimeCapMinutes ?? 0) * 60 {
            return "TC superado"
        }
        return nil
    }

    var plannedSets: Int { current?.plannedSets.count ?? 0 }
    var completedSets: Int { current?.loggedSets.count ?? 0 }
    var completedWorkingSets: Int {
        current?.loggedSets.filter { $0.phase == .work }.count ?? 0
    }
    var displayedSetNumber: Int {
        if let selectedSetIndex {
            let work = current?.loggedSets.prefix(selectedSetIndex + 1)
                .filter { $0.phase == .work }.count ?? 0
            return max(1, work)
        }
        return min(completedWorkingSets + 1, max(1, plannedSets))
    }
    var isLastWorkoutExercise: Bool {
        guard let active else { return false }
        return active.currentIndex == active.exercises.count - 1
    }
    var hasNextExercise: Bool {
        guard let active else { return false }
        return active.exercises.indices.contains(active.currentIndex + 1)
    }
    var isFinalSet: Bool {
        !currentIsWOD && isLastWorkoutExercise
            && setDraft.phase == .work
            && completedWorkingSets + 1 >= max(1, plannedSets)
            && selectedSetIndex == nil
    }
    /// The single green arrow replaces the redundant textual "Siguiente".
    /// WODs with a global score can open their result form without reps;
    /// individual strength/interval sets must contain an actual quantity.
    var canConfirmCurrentEntry: Bool {
        // Even at zero reps or during a rest, the arrow remains tappable.
        // A skipped or unrecorded set must NEVER become a completed LoggedSet.
        active?.phase == .counting && !isPaused && !reviewingBlock
    }
    var nextActionIsFinish: Bool {
        (isLastWorkoutExercise && effectiveReps == 0)
            || isFinalSet || (currentIsWOD && !wodUsesSeries)
    }
    var blockExercises: [SessionExercise] {
        guard let active, let current else { return [] }
        guard let blockID = current.blockId else { return [current] }
        return active.exercises.filter { $0.blockId == blockID }
    }
    var intervalLabel: String? {
        guard let current, let format = current.wodFormat else { return nil }
        switch format {
        case .emom, .deathBy:
            let interval = max(1, current.blockIntervalSeconds ?? 60)
            let number = blockElapsed / interval + 1
            let maximum = current.plannedIntervals ?? current.blockRounds
            let clamped = maximum.map { min(number, max(1, $0)) } ?? number
            let kind = format == .deathBy ? "Ronda" : "Intervalo"
            if let maximum { return "\(kind) \(clamped)/\(maximum)" }
            return "\(kind) \(clamped)"
        case .circuit:
            return circuitPhase?.label
        case .tabata:
            let work = max(1, current.blockWorkSeconds ?? 20)
            let rest = max(0, current.blockRestSeconds ?? 10)
            let cycle = max(1, work + rest)
            let round = min(blockElapsed / cycle + 1, max(1, current.blockRounds ?? 8))
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

    /// Refresh the prescription without touching an offline workout in progress.
    func refreshToday() {
        connectivity.refreshToday()
    }

    func applicationWillResignActive() {
        tickClock()
        save()
    }

    /// HealthKit sends physical two-button pause requests and state changes.
    /// Repera remains the owner of interval and set timers; both clocks pause together.
    private func applyHealthPauseRequest() {
        guard hasWorkoutInProgress, !reviewingBlock,
              active?.phase == .counting || active?.liveSportID != nil else { return }
        if isPaused { play() } else { pause() }
    }

    private func alignWithHealthState(paused: Bool) {
        guard hasWorkoutInProgress, !reviewingBlock,
              active?.phase == .counting || active?.liveSportID != nil,
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
        summaryDismissed = false
        acknowledgedSessionID = nil
        isPaused = false
        reviewingBlock = false
        restRemaining = 0
        blockElapsed = 0
        sessionElapsed = 0
        workingReps = 0
        selectedSetIndex = nil
        workingWeightKg = next.session.currentExercise?.plannedSets.first?.targetWeightKg
        resetSetDraft()
        completedRounds = 0
        remainingRoundReps = 0
        lastIntervalIndex = 0
        lastClockTick = Date()
        startClock()
        checkpoint()
    }

    /// «Comenzar» comparte el UUID, la persistencia y el transporte offline
    /// de Play, pero no inventa ejercicios/series para deportes sin prescripción.
    private func acceptFreeWorkout(_ remote: WorkoutSession) {
        if remote.phase == .finished {
            if active?.id == remote.id { finishWorkout() }
            return
        }
        guard let type = remote.liveSportID else { return }
        if let active, active.id == remote.id {
            // GPS y rutas son del iPhone; sensores/calorías pertenecen al Watch.
            var merged = active
            merged.recordedDistanceMeters = remote.recordedDistanceMeters
            merged.liveRouteID = remote.liveRouteID
            controller = SessionController(session: merged)
            if remote.phase == .ready && !isPaused { pauseFree() }
            if remote.phase == .counting && isPaused { resumeFree() }
            save()
            return
        }
        guard controller == nil, !awaitingHealthSave,
              lastFinished?.id != remote.id else { return }
        controller = SessionController(session: remote)
        startedOnThisWatch = true
        lastFinished = nil
        summaryDismissed = false
        acknowledgedSessionID = nil
        isPaused = remote.phase == .ready
        restRemaining = 0
        blockElapsed = 0
        sessionElapsed = max(0, Int(remote.activeDurationSeconds ?? 0))
        lastClockTick = isPaused ? nil : Date()
        health.start(
            // HR/calorie recording begins when Watch actually joins, not
            // retroactively at the iPhone's earlier GPS start.
            id: remote.id, at: Date(),
            includesWOD: false, includesStrength: false,
            liveSportID: type, initiallyPaused: isPaused
        )
        startClock()
        checkpoint()
    }

    private func pauseFree() {
        guard var session = active, session.liveSportID != nil, !isPaused else { return }
        tickClock()
        isPaused = true
        lastClockTick = nil
        session.phase = .ready
        session.activeDurationSeconds = Double(sessionElapsed)
        controller = SessionController(session: session)
        if startedOnThisWatch { health.pause() }
        checkpoint()
    }

    private func resumeFree() {
        guard var session = active, session.liveSportID != nil, isPaused else { return }
        isPaused = false
        lastClockTick = Date()
        session.phase = .counting
        controller = SessionController(session: session)
        if startedOnThisWatch { health.resume() }
        checkpoint()
    }

    /// One play per block / standalone exercise. A counting session does not reset.
    func play() {
        if active?.liveSportID != nil { resumeFree(); return }
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
            if startedOnThisWatch { health.resume() }
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
            selectedSetIndex = nil
            workingWeightKg = ctrl.session.currentExercise?.plannedSets.first?.targetWeightKg
            resetSetDraft()
            repCounter.reset()
            lastIntervalIndex = 0
            reviewingBlock = false
            lastClockTick = Date()
            startMotion()
            checkpoint()
        }
    }

    func pause() {
        if active?.liveSportID != nil { pauseFree(); return }
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
        workingWeightKg = max(0, ((workingWeightKg ?? 0) + delta) * 10).rounded() / 10
        save()
    }

    /// Prescribed values are editable drafts, not proof that work was completed.
    /// Warmup sets do not consume the next prescribed working-set target.
    private func resetSetDraft() {
        let ex = current
        let planned = ex?.nextWorkSetPrescription
        workingReps = max(0, planned?.targetReps ?? 0)
        workingWeightKg = ex?.exercise.loadField == .weightKg
            ? planned?.targetWeightKg : nil
        // PlannedSet does not prescribe duration. Only WOD interval metadata
        // may provide an explicit starting duration.
        let plannedDuration: Int?
        if ex?.exercise.loggingStyle.usesDuration == true, ex?.blockKind == .wod {
            plannedDuration = ex?.blockWorkSeconds ?? ex?.blockIntervalSeconds
        } else {
            plannedDuration = nil
        }
        setDraft = WatchSetDraft(
            rir: ex?.exercise.loggingStyle.usesRIR == true ? planned?.targetRir : nil,
            deficitCm: ex?.exercise.loadField == .deficitCm
                ? planned?.targetWeightKg.map { Int($0.rounded()) } : nil,
            durationSeconds: plannedDuration,
            unit: ex?.quantityUnit ?? ex?.exercise.defaultQuantityUnit ?? .reps,
            toFailure: planned?.targetRir == 0
        )
    }

    private func restoreSetDraft(from saved: LoggedSet) {
        setDraft = WatchSetDraft(rir: saved.rir, deficitCm: saved.deficitCm,
            durationSeconds: saved.durationSeconds,
            unit: saved.quantityUnit ?? current?.exercise.defaultQuantityUnit ?? .reps,
            phase: saved.phase, kind: saved.kind,
            toFailure: saved.toFailure, drops: saved.drops, clusters: saved.clusters)
    }

    func setRIR(_ value: Double?) {
        setDraft.rir = value.map { min(5, max(0, $0)) }
        setDraft.toFailure = setDraft.rir == 0
        save()
    }
    func adjustDuration(_ delta: Int) {
        setDraft.durationSeconds = max(0, (setDraft.durationSeconds ?? 0) + delta)
        save()
    }
    func adjustDeficit(_ delta: Int) {
        setDraft.deficitCm = min(60, max(0, (setDraft.deficitCm ?? 0) + delta))
        save()
    }
    func selectUnit(_ unit: ExerciseQuantityUnit) {
        guard current?.exercise.loggingStyle == .machineWork else { return }
        setDraft.unit = unit
        save()
    }
    func setPhase(_ phase: SetPhase) { setDraft.phase = phase; save() }
    func setKind(_ kind: SetKind) {
        setDraft.kind = kind
        if kind != .dropset { setDraft.drops = [] }
        if kind != .restpause { setDraft.clusters = [] }
        save()
    }
    func setToFailure(_ value: Bool) {
        setDraft.toFailure = value
        if value { setDraft.rir = 0 }
        save()
    }
    func addDrop() {
        setDraft.drops.append(DropSegment(reps: max(1, workingReps), weightKg: workingWeightKg))
        setDraft.kind = .dropset
        save()
    }
    func adjustDrop(id: UUID, reps: Int = 0, weightKg: Double = 0) {
        guard let i = setDraft.drops.firstIndex(where: { $0.id == id }) else { return }
        setDraft.drops[i].reps = max(1, setDraft.drops[i].reps + reps)
        if weightKg != 0 {
            setDraft.drops[i].weightKg = max(0, (setDraft.drops[i].weightKg ?? 0) + weightKg)
        }
        save()
    }
    func removeDrop(id: UUID) { setDraft.drops.removeAll { $0.id == id }; save() }
    func addCluster() {
        setDraft.clusters.append(RestPauseCluster(reps: max(1, workingReps)))
        setDraft.kind = .restpause
        save()
    }
    func adjustCluster(id: UUID, reps: Int = 0, restSeconds: Int = 0) {
        guard let i = setDraft.clusters.firstIndex(where: { $0.id == id }) else { return }
        setDraft.clusters[i].reps = max(1, setDraft.clusters[i].reps + reps)
        setDraft.clusters[i].restSeconds = max(0, setDraft.clusters[i].restSeconds + restSeconds)
        save()
    }
    func removeCluster(id: UUID) { setDraft.clusters.removeAll { $0.id == id }; save() }

    private func preparedSet(reps: Int, previous: LoggedSet? = nil) -> LoggedSet {
        let style = loggingStyle
        return LoggedSet(
            id: previous?.id ?? UUID(), reps: reps,
            weightKg: current?.exercise.loadField == .weightKg ? workingWeightKg : nil,
            deficitCm: current?.exercise.loadField == .deficitCm ? setDraft.deficitCm : nil,
            durationSeconds: style.usesDuration ? setDraft.durationSeconds : nil,
            quantityUnit: style == .machineWork ? setDraft.unit : nil,
            completedAt: previous?.completedAt ?? Date(),
            phase: setDraft.phase, kind: setDraft.kind,
            rir: style.usesRIR ? setDraft.rir : nil,
            toFailure: style.usesRIR && setDraft.toFailure,
            drops: setDraft.kind == .dropset ? setDraft.drops : [],
            clusters: setDraft.kind == .restpause ? setDraft.clusters : []
        )
    }

    /// Motion detection is just a suggestion; the athlete confirms the actual set.
    func confirmSet() {
        guard !isPaused, !reviewingBlock, !currentIsWOD,
              var ctrl = controller, ctrl.session.phase == .counting,
              let exercise = ctrl.session.currentExercise else { return }
        let reps = max(0, effectiveReps)
        guard reps > 0 else { return }
        if let selectedSetIndex {
            guard exercise.loggedSets.indices.contains(selectedSetIndex),
                  ctrl.replaceLoggedSet(at: selectedSetIndex,
                    with: preparedSet(reps: reps, previous: exercise.loggedSets[selectedSetIndex]))
            else { return }
            controller = ctrl
            self.selectedSetIndex = nil
            resetSetDraft()
            repCounter.reset()
            if restRemaining == 0 { startMotion() }
            WKInterfaceDevice.current().play(.success)
            checkpoint()
            return
        }
        let set = preparedSet(reps: reps)
        ctrl.logSet(
            reps: set.reps, weightKg: set.weightKg, deficitCm: set.deficitCm,
            durationSeconds: set.durationSeconds, quantityUnit: set.quantityUnit,
            phase: set.phase, kind: set.kind, rir: set.rir,
            toFailure: set.toFailure, drops: set.drops, clusters: set.clusters
        )
        controller = ctrl
        selectedSetIndex = nil
        resetSetDraft()
        repCounter.reset()
        stopMotion()
        if set.phase == .work && completedWorkingSets < plannedSets {
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
        let set = preparedSet(reps: max(0, effectiveReps))
        guard set.reps > 0 else { return }
        ctrl.logSet(reps: set.reps, weightKg: set.weightKg,
            deficitCm: set.deficitCm, durationSeconds: set.durationSeconds,
            quantityUnit: set.quantityUnit, phase: set.phase, kind: set.kind,
            rir: set.rir, toFailure: set.toFailure,
            drops: set.drops, clusters: set.clusters)
        controller = ctrl
        workingReps = 0
        selectedSetIndex = nil
        resetSetDraft()
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
        selectedSetIndex = nil
        workingWeightKg = ctrl.session.currentExercise?.plannedSets.first?.targetWeightKg
        resetSetDraft()
        repCounter.reset()
        if restRemaining == 0 && !isPaused { startMotion() }
        checkpoint()
    }

    /// The primary action commits the displayed set and advances only when
    /// all planned sets for this exercise were genuinely recorded.
    func confirmAndAdvance() {
        guard canConfirmCurrentEntry else { return }
        if restRemaining > 0 {
            // Never show a disabled gray arrow during an automatic rest.
            // Skip the rest on demand and continue with the user's action.
            skipRest()
        }
        if currentIsWOD {
            if wodUsesSeries {
                if effectiveReps > 0 {
                    // One WOD interval remains one saved set; never fabricate it.
                    confirmIntervalSet()
                } else {
                    // The user can move to another WOD movement with zero reps.
                    // The interval result remains unrecorded until confirmed.
                    if hasNextExercise { nextExercise() } else { reviewBlock() }
                }
            } else {
                reviewBlock()
            }
            return
        }
        if effectiveReps == 0 {
            // Arrow means next exercise even if the current set is empty.
            // Do not store a zero-repetition series.
            if hasNextExercise { nextExercise() } else { finishWorkout() }
            return
        }
        let wasReviewingRecordedSet = selectedSetIndex != nil
        let wasWorkingSet = setDraft.phase == .work
        confirmSet()
        // Neither editing a historical set nor adding a warmup may finish
        // the prescribed work sets (resetSetDraft changes the selected phase).
        guard !wasReviewingRecordedSet, wasWorkingSet else { return }
        if completedWorkingSets >= max(1, plannedSets),
           restRemaining == 0 {
            advance()
        }
    }

    /// Swipes browse recorded series. They never log a set or mark it complete.
    /// Beyond the available series, navigate between exercises in this block.
    func swipeSet(_ direction: Int) {
        guard direction == -1 || direction == 1,
              active?.phase == .counting, !reviewingBlock, !isPaused,
              restRemaining == 0 else { return }
        guard !currentIsWOD else {
            if wodUsesSeries && direction > 0 { nextWODMovement() }
            return
        }
        let count = current?.loggedSets.count ?? 0
        let position = selectedSetIndex ?? count
        let next = position + direction
        if next >= 0 && next < count,
           let saved = current?.loggedSets[next] {
            stopMotion() // Reviewing historical sets must not count live motion.
            selectedSetIndex = next
            workingReps = saved.reps
            workingWeightKg = saved.weightKg
            restoreSetDraft(from: saved)
            restRemaining = 0
            checkpoint()
        } else if next == count {
            selectedSetIndex = nil
            workingReps = 0
            repCounter.reset()
            if restRemaining == 0 { startMotion() }
            workingWeightKg = current?.plannedSets.dropFirst(count).first?.targetWeightKg
            resetSetDraft()
            checkpoint()
        } else if (next < 0 || next > count) {
            moveWithinBlock(direction)
        }
    }

    /// Go to the next exercise without manufacturing or confirming a set.
    /// Within a block the workout clock continues; a new block opens prepared.
    func nextExercise() {
        guard let active, active.phase == .counting, !isPaused,
              !reviewingBlock, hasNextExercise else { return }
        let nextIndex = active.currentIndex + 1
        let next = active.exercises[nextIndex]
        let sameBlock = current?.blockId != nil && current?.blockId == next.blockId
        if !sameBlock {
            // Leaving a WOD must not discard an unrecorded AMRAP/For Time
            // score. The athlete enters it once; confirmBlock advances.
            if currentIsWOD {
                reviewBlock()
            } else {
                selectBlock(startingAt: nextIndex)
            }
            return
        }
        tickClock()
        stopMotion()
        var ctrl = SessionController(session: active)
        ctrl.selectExercise(at: nextIndex)
        ctrl.confirmCurrentExercise()
        controller = ctrl
        selectedSetIndex = nil
        workingReps = 0
        workingWeightKg = next.plannedSets.first?.targetWeightKg
        resetSetDraft()
        repCounter.reset()
        restRemaining = 0
        if !isPaused { startMotion() }
        checkpoint()
    }

    /// One explicit finishing action. A WOD score is requested only when it
    /// must be entered, then confirmBlock saves without another dialog.
    func finishFromSummary() {
        guard active != nil else { return }
        if currentIsWOD, active?.phase == .counting {
            reviewBlock()
        } else {
            finishWorkout()
        }
    }

    /// Jumping from Plan completo does not complete skipped exercises or
    /// create fictitious sets; confirmed results from the previous block remain.
    func selectBlock(startingAt index: Int) {
        guard var ctrl = controller, ctrl.session.exercises.indices.contains(index),
              !awaitingHealthSave else { return }
        if ctrl.session.currentIndex == index, ctrl.session.phase == .ready { return }
        tickClock()
        stopMotion()
        if startedOnThisWatch { health.pause() }
        ctrl.selectExercise(at: index)
        controller = ctrl
        isPaused = false
        reviewingBlock = false
        restRemaining = 0
        blockElapsed = 0
        workingReps = 0
        selectedSetIndex = nil
        workingWeightKg = ctrl.session.currentExercise?.plannedSets.first?.targetWeightKg
        resetSetDraft()
        repCounter.reset()
        lastClockTick = Date()
        checkpoint()
    }

    private func moveWithinBlock(_ direction: Int) {
        guard let active, let current,
              active.exercises.indices.contains(active.currentIndex + direction),
              active.exercises[active.currentIndex + direction].blockId == current.blockId else { return }
        let target = active.exercises[active.currentIndex + direction]
        // A nil block ID denotes standalone exercises, not a shared block.
        guard current.blockId != nil else { return }
        var ctrl = SessionController(session: active)
        ctrl.selectExercise(at: active.currentIndex + direction)
        ctrl.confirmCurrentExercise()
        controller = ctrl
        selectedSetIndex = nil
        workingReps = 0
        workingWeightKg = target.plannedSets.first?.targetWeightKg
        resetSetDraft()
        repCounter.reset()
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
        resetSetDraft()
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
        reviewElapsedSeconds = blockElapsed
        lastClockTick = nil
        stopMotion()
        if startedOnThisWatch { health.pause() }
        checkpoint()
    }

    /// Users can correct their actual finishing time before saving For Time.
    func adjustScoreSeconds(_ delta: Int) {
        guard reviewingBlock, current?.wodFormat?.resultCapture == .elapsedTime else { return }
        reviewElapsedSeconds = max(0, (reviewElapsedSeconds ?? blockElapsed) + delta)
        save()
    }

    /// WOD score is global (AMRAP rounds/reps, For Time seconds), not fake sets.
    func confirmBlock() {
        guard reviewingBlock, var ctrl = controller,
              let current = ctrl.session.currentExercise,
              let id = current.blockId else { return }
        let format = current.wodFormat
        let elapsed: Int? = format?.resultCapture == .elapsedTime
            ? (reviewElapsedSeconds ?? blockElapsed) : nil
        let rounds: Int? = (format == .amrap || format == .deathBy)
            ? completedRounds : nil
        let reps: Int? = format?.resultCapture == .totalReps ? remainingRoundReps : nil
        let templateID = ctrl.session.routineBlocks?
            .first(where: { $0.id == id })?.wodTemplateId
        let score = WODBlockResult(id: id, format: format,
                                   totalReps: reps, elapsedSeconds: elapsed,
                                   roundsCompleted: rounds, wodTemplateId: templateID)
        if !wodUsesSeries { ctrl.recordWODResult(score) }
        _ = ctrl.finishCurrentBlock()
        controller = ctrl
        reviewingBlock = false
        reviewElapsedSeconds = nil
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
        if var sport = active, sport.liveSportID != nil, sport.phase != .finished {
            tickClock()
            sport.phase = .finished
            sport.finishedAt = Date()
            sport.activeDurationSeconds = Double(sessionElapsed)
            controller = SessionController(session: sport)
            completeSession()
            return
        }
        guard var ctrl = controller, ctrl.session.phase != .finished,
              !awaitingHealthSave else { return }
        tickClock()
        stopMotion()
        ctrl.finishWorkout()
        controller = ctrl
        completeSession()
    }

    func clearSummary() {
        // Do not block navigation until HealthKit finishes. Retain the finished
        // result for offline transport, late HealthKit metrics and the phone ACK.
        guard lastFinished != nil else { return }
        summaryDismissed = true
        controller = nil
        checkpoint()
    }

    private func completeSession() {
        guard let finished = controller?.session, lastFinished?.id != finished.id else { return }
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
        summaryDismissed = false
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
            isWOD: currentIsWOD,
            timeCapSeconds: clockCountsUp ? 0 : timeCapSeconds
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
            if wodUsesSeries && isIntervalClock {
                // iPhone keeps EMOM/Tabata/Circuit sets editable after the
                // timer ends. Do not start review or manufacture their score.
                if previous < timeCapSeconds {
                    restRemaining = 0
                    WKInterfaceDevice.current().play(.notification)
                    checkpoint()
                }
            } else {
                reviewBlock()
            }
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
              active?.liveSportID == nil, active?.phase == .counting,
              loggingStyle != .machineWork, loggingStyle != .repsAndTime else { return }
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
              active?.liveSportID == nil, active?.phase == .counting,
              loggingStyle != .machineWork, loggingStyle != .repsAndTime,
              selectedSetIndex == nil, let data = motion.deviceMotion else { return }
        let u = data.userAcceleration
        let magnitude = sqrt(u.x * u.x + u.y * u.y + u.z * u.z) + 1.0
        repCounter.ingest(magnitude: magnitude)
        // Never overwrite a prefilled prescription or a manual +/- correction
        // with the zero-based motion estimate.
        if current?.plannedSets.isEmpty != false {
            workingReps = repCounter.count
        }
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
            setDraft: setDraft, selectedSetIndex: selectedSetIndex,
            summaryDismissed: summaryDismissed,
            completedRounds: completedRounds,
            remainingRoundReps: remainingRoundReps,
            reviewElapsedSeconds: reviewElapsedSeconds,
            reviewingBlock: reviewingBlock,
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
        selectedSetIndex = snapshot.selectedSetIndex
        if let draft = snapshot.setDraft {
            setDraft = draft
        } else {
            resetSetDraft()
        }
        summaryDismissed = snapshot.summaryDismissed ?? false
        completedRounds = snapshot.completedRounds
        remainingRoundReps = snapshot.remainingRoundReps
        reviewElapsedSeconds = snapshot.reviewElapsedSeconds
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
            if session.liveSportID != nil {
                self.acceptFreeWorkout(session)
                return
            }
            guard self.controller == nil, self.lastFinished?.id != session.id,
                  session.phase != .finished else { return }
            self.controller = SessionController(session: session)
            self.resetSetDraft()
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

struct WatchSetDraft: Codable, Sendable {
    var rir: Double?
    var deficitCm: Int?
    var durationSeconds: Int?
    var unit: ExerciseQuantityUnit = .reps
    var phase: SetPhase = .work
    var kind: SetKind = .straight
    var toFailure = false
    var drops: [DropSegment] = []
    var clusters: [RestPauseCluster] = []
}
