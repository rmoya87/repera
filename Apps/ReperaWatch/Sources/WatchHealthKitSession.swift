import Foundation
import HealthKit
import Observation

/// Only HealthKit measures calories, heart rate and the saved workout's duration.
/// Repera's motion counter is never used for energy or heart-rate calculations.
@Observable
@MainActor
final class WatchHealthKitSession: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    struct Result: Sendable {
        var uuid: UUID? = nil
        var activeEnergyKcal: Double? = nil
        var durationSeconds: TimeInterval? = nil
        var start: Date? = nil
        var end: Date? = nil
        var averageHeartRateBpm: Double? = nil
    }

    private let store = HKHealthStore()
    private var workout: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var workoutID: UUID?
    private var lastRecordedBlockID: UUID?
    private var pendingBlock: (id: UUID, isInterval: Bool)?
    private var finishHandler: ((Result) -> Void)?
    var onPauseResumeRequest: (() -> Void)?
    var onPauseStateChanged: ((Bool) -> Void)?
    private var finishing = false
    private(set) var pulseBpm: Int?
    private(set) var kcal: Double?
    private(set) var averageBpm: Double?
    private(set) var permissionIssue: String?
    private(set) var isRecording = false

    func recoverIfNeeded(id: UUID, completion: ((Bool) -> Void)? = nil) {
        guard workout == nil, HKHealthStore.isHealthDataAvailable() else {
            completion?(workout != nil)
            return
        }
        store.recoverActiveWorkoutSession { [weak self] recovered, error in
            Task { @MainActor in
                guard let self, let recovered else {
                    if let error { self?.permissionIssue = error.localizedDescription }
                    completion?(false)
                    return
                }
                self.workoutID = id
                self.workout = recovered
                let live = recovered.associatedWorkoutBuilder()
                live.dataSource = HKLiveWorkoutDataSource(
                    healthStore: self.store,
                    workoutConfiguration: recovered.workoutConfiguration
                )
                recovered.delegate = self
                live.delegate = self
                self.builder = live
                self.isRecording = true
                completion?(true)
            }
        }
    }

    /// Segment boundaries belong to HealthKit, not to guessed heart-rate samples.
    /// Keep the same configuration for intervals as Apple requires.
    func beginBlock(id: UUID, isInterval: Bool) {
        guard !finishing, id != lastRecordedBlockID else { return }
        guard isRecording, let session = workout else {
            pendingBlock = (id, isInterval)
            return
        }
        pendingBlock = nil
        lastRecordedBlockID = id
        let metadata: [String: Any] = [
            "com.app.repera.blockID": id.uuidString,
            "com.app.repera.blockKind": isInterval ? "wod" : "strength"
        ]
        session.beginNewActivity(
            configuration: session.workoutConfiguration,
            date: Date(),
            metadata: metadata
        )
    }

    func start(id: UUID, at date: Date, includesWOD: Bool, includesStrength: Bool) {
        guard workout == nil, HKHealthStore.isHealthDataAvailable() else {
            permissionIssue = "Salud no disponible o entrenamiento de Salud ya iniciado."
            return
        }
        workoutID = id
        lastRecordedBlockID = nil
        pendingBlock = nil
        finishing = false
        permissionIssue = nil
        let heart = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let read: Set<HKObjectType> = [HKObjectType.workoutType(), heart, energy]
        store.requestAuthorization(toShare: [HKObjectType.workoutType()], read: read) { [weak self] success, error in
            Task { @MainActor in
                guard let self, self.workoutID == id, !self.finishing else { return }
                guard success, error == nil else {
                    self.permissionIssue = error?.localizedDescription ?? "No se autorizó HealthKit."
                    return
                }
                let config = HKWorkoutConfiguration()
                if includesWOD && includesStrength {
                    config.activityType = .crossTraining
                } else if includesWOD {
                    config.activityType = .highIntensityIntervalTraining
                } else {
                    config.activityType = .functionalStrengthTraining
                }
                config.locationType = .indoor
                do {
                    let session = try HKWorkoutSession(healthStore: self.store, configuration: config)
                    let builder = session.associatedWorkoutBuilder()
                    builder.dataSource = HKLiveWorkoutDataSource(
                        healthStore: self.store, workoutConfiguration: config
                    )
                    session.delegate = self
                    builder.delegate = self
                    self.workout = session
                    self.builder = builder
                    session.startActivity(with: date)
                    // Mirroring is optional; a disconnected iPhone must never block
                    // the Watch's local HealthKit collection or offline results.
                    session.startMirroringToCompanionDevice { _, _ in }
                    builder.beginCollection(withStart: date) { [weak self] ok, err in
                        if ok {
                            // Matches HealthKit's independent sample UUID to Repera's
                            // stable workout ID, even if Health returns no sample while locked.
                            builder.addMetadata([HKMetadataKeyExternalUUID: id.uuidString]) { _, _ in }
                        }
                        Task { @MainActor in
                            guard let self, self.workoutID == id else { return }
                            self.isRecording = ok
                            if ok, let pending = self.pendingBlock {
                                self.beginBlock(id: pending.id, isInterval: pending.isInterval)
                            }
                            if !ok {
                                self.permissionIssue = err?.localizedDescription ?? "No se inició la recogida de Salud."
                                self.builder?.discardWorkout()
                                self.workout?.end()
                                self.workout = nil
                                self.builder = nil
                            }
                        }
                    }
                } catch {
                    self.permissionIssue = error.localizedDescription
                }
            }
        }
    }

    func pause() { workout?.pause() }
    func resume() { workout?.resume() }

    func finish(_ callback: @escaping (Result) -> Void) {
        guard !finishing else { return }
        finishing = true
        finishHandler = callback
        guard let workout else {
            finishWith(Result())
            return
        }
        workout.stopActivity(with: Date())
        // Wait for didChangeTo(.stopped) so the final Health samples are included.
    }

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState, date: Date
    ) {
        Task { @MainActor in
            switch toState {
            case .paused:
                self.onPauseStateChanged?(true)
            case .running:
                self.onPauseStateChanged?(false)
            case .stopped:
                self.endBuilder(at: date)
            default:
                break
            }
        }
    }

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent
    ) {
        guard event.type == .pauseOrResumeRequest else { return }
        Task { @MainActor in self.onPauseResumeRequest?() }
    }

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession, didFailWithError error: any Error
    ) {
        let message = error.localizedDescription
        Task { @MainActor in
            self.permissionIssue = message
            if self.finishing { self.finishWith(Result()) }
            else {
                self.workout = nil
                self.builder = nil
                self.isRecording = false
            }
        }
    }

    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        let heart = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let unit = HKUnit.count().unitDivided(by: .minute())
        let bpm = workoutBuilder.statistics(for: heart)?.mostRecentQuantity()?.doubleValue(for: unit)
        let average = workoutBuilder.statistics(for: heart)?.averageQuantity()?.doubleValue(for: unit)
        let active = workoutBuilder.statistics(for: energy)?.sumQuantity()?.doubleValue(for: .kilocalorie())
        Task { @MainActor in
            if let bpm, bpm.isFinite, bpm > 0 { self.pulseBpm = Int(bpm.rounded()) }
            if let average, average.isFinite, average > 0 { self.averageBpm = average }
            if let active, active.isFinite, active > 0 { self.kcal = active }
        }
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    private func endBuilder(at date: Date) {
        guard let builder else { finishWith(Result()); return }
        builder.endCollection(withEnd: date) { [weak self] success, error in
            guard success else {
                Task { @MainActor in
                    self?.permissionIssue = error?.localizedDescription ?? "No se cerró la recogida de Salud."
                    self?.finishWith(Result())
                }
                return
            }
            builder.finishWorkout { [weak self] saved, error in
                let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
                let hrType = HKObjectType.quantityType(forIdentifier: .heartRate)!
                let hrUnit = HKUnit.count().unitDivided(by: .minute())
                let active = saved?.statistics(for: energyType)?.sumQuantity()?.doubleValue(for: .kilocalorie())
                let average = saved?.statistics(for: hrType)?.averageQuantity()?.doubleValue(for: hrUnit)
                let result = Result(
                    uuid: saved?.uuid,
                    activeEnergyKcal: (active ?? 0) > 0 ? active : nil,
                    durationSeconds: saved?.duration,
                    start: saved?.startDate,
                    end: saved?.endDate,
                    averageHeartRateBpm: average
                )
                Task { @MainActor in
                    if let error { self?.permissionIssue = error.localizedDescription }
                    self?.finishWith(result)
                }
            }
        }
    }

    private func finishWith(_ result: Result) {
        workout?.end()
        workout = nil
        builder = nil
        workoutID = nil
        lastRecordedBlockID = nil
        pendingBlock = nil
        isRecording = false
        finishing = false
        let callback = finishHandler
        finishHandler = nil
        callback?(result)
    }
}
