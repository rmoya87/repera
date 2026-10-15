import CoreMotion
import Foundation
import GymbroDomain
import Observation
import WatchConnectivity

@Observable
@MainActor
final class WatchSessionHub: NSObject {
    private(set) var controller: SessionController?
    private let connectivity = WatchConnectivityClient()
    private let motion = CMMotionManager()
    private var repCounter = MotionRepCounter()
    private var motionTimer: Timer?

    func activate() {
        connectivity.delegate = self
        connectivity.activate()
    }

    func confirmCurrent() {
        guard var controller else { return }
        controller.confirmCurrentExercise()
        repCounter.reset()
        self.controller = controller
        startMotion()
        pushToPhone()
    }

    func finishCurrent() {
        stopMotion()
        guard var controller else { return }
        controller.setRepCount(repCounter.count)
        let weight = controller.session.currentExercise?.plannedSets.first?.targetWeightKg
            ?? controller.session.currentExercise?.lastLoggedWeight
        controller.commitWatchRepsAsSet(weightKg: weight)
        _ = controller.finishCurrentExercise()
        self.controller = controller
        pushToPhone()
    }

    func adjustReps(_ delta: Int) {
        repCounter.applyManualDelta(delta)
        guard var controller else { return }
        controller.setRepCount(repCounter.count)
        self.controller = controller
        pushToPhone()
    }

    private func pushToPhone() {
        guard let session = controller?.session else { return }
        connectivity.send(session: session)
    }

    private func startMotion() {
        stopMotion()
        guard motion.isDeviceMotionAvailable else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 50.0
        motion.startDeviceMotionUpdates(using: .xArbitraryZVertical)
        motionTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickMotion()
            }
        }
    }

    private func stopMotion() {
        motionTimer?.invalidate()
        motionTimer = nil
        motion.stopDeviceMotionUpdates()
    }

    private func tickMotion() {
        guard controller?.session.phase == .counting,
              let data = motion.deviceMotion
        else { return }

        let u = data.userAcceleration
        let magnitude = sqrt(u.x * u.x + u.y * u.y + u.z * u.z) + 1.0
        repCounter.ingest(magnitude: magnitude)
        guard var controller else { return }
        if controller.session.currentExercise?.completedReps != repCounter.count {
            controller.setRepCount(repCounter.count)
            self.controller = controller
            pushToPhone()
        }
    }
}

extension WatchSessionHub: WatchConnectivityClientDelegate {
    nonisolated func watchConnectivityDidReceive(session: WorkoutSession?) {
        Task { @MainActor in
            if let session {
                self.controller = SessionController(session: session)
                if session.phase != .counting {
                    self.stopMotion()
                    self.repCounter.reset()
                }
            } else {
                self.stopMotion()
                self.controller = nil
            }
        }
    }
}
