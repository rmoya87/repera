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

    func recoverIfNeeded(id: UUID, completion: (@MainActor @Sendable (Bool) -> Void)? = nil) {
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
        // HealthKit operations stay on the MainActor. The authorization sheet,
        // builder collection and metadata use Apple's async APIs on watchOS 27.
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await store.requestAuthorization(
                    toShare: [HKObjectType.workoutType()], read: read
                )
            } catch {
                if self.workoutID == id { self.permissionIssue = error.localizedDescription }
                return
            }
            guard self.workoutID == id, !self.finishing else { return }

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
                let liveBuilder = session.associatedWorkoutBuilder()
                liveBuilder.dataSource = HKLiveWorkoutDataSource(
                    healthStore: self.store, workoutConfiguration: config
                )
                session.delegate = self
                liveBuilder.delegate = self
                self.workout = session
                self.builder = liveBuilder
                session.startActivity(with: date)

                // Mirroring is best-effort: a missing or offline iPhone must
                // never delay the native Watch workout or its HealthKit samples.
                Task { @MainActor in
                    do {
                        try await session.startMirroringToCompanionDevice()
                    } catch {
                        // The Watch is the primary recorder. WatchConnectivity
                        // synchronizes the result independently once available.
                    }
                }

                do {
                    try await liveBuilder.beginCollection(at: date)
                    guard self.workoutID == id, self.builder === liveBuilder else { return }
                    self.isRecording = true
                    if let pending = self.pendingBlock {
                        self.beginBlock(id: pending.id, isInterval: pending.isInterval)
                    }

                    // The execution UUID allows later reconciliation on iPhone.
                    // A metadata error must not discard a live sensor recording.
                    do {
                        try await liveBuilder.addMetadata([
                            HKMetadataKeyExternalUUID: id.uuidString
                        ])
                    } catch {
                        if self.workoutID == id {
                            self.permissionIssue = "Salud registra el entreno, pero no pudo enlazarlo: \(error.localizedDescription)"
                        }
                    }
                } catch {
                    guard self.workoutID == id, self.builder === liveBuilder else { return }
                    self.permissionIssue = error.localizedDescription
                    liveBuilder.discardWorkout()
                    session.end()
                    self.workout = nil
                    self.builder = nil
                    self.isRecording = false
                }
            } catch {
                if self.workoutID == id { self.permissionIssue = error.localizedDescription }
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
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await builder.endCollection(at: date)
            } catch {
                self.permissionIssue = error.localizedDescription
                self.finishWith(Result())
                return
            }

            do {
                // A nil workout without an error is valid while the Watch is locked.
                // Repera preserves the pending UUID and reconciles it later.
                let saved = try await builder.finishWorkout()
                let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
                let hrType = HKObjectType.quantityType(forIdentifier: .heartRate)!
                let hrUnit = HKUnit.count().unitDivided(by: .minute())
                let active = saved?.statistics(for: energyType)?.sumQuantity()?.doubleValue(for: .kilocalorie())
                let average = saved?.statistics(for: hrType)?.averageQuantity()?.doubleValue(for: hrUnit)
                self.finishWith(Result(
                    uuid: saved?.uuid,
                    activeEnergyKcal: (active ?? 0) > 0 ? active : nil,
                    durationSeconds: saved?.duration,
                    start: saved?.startDate,
                    end: saved?.endDate,
                    averageHeartRateBpm: average
                ))
            } catch {
                self.permissionIssue = error.localizedDescription
                self.finishWith(Result())
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
