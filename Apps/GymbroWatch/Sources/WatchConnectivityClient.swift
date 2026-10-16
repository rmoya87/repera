import Foundation
import GymbroDomain
import WatchConnectivity

protocol WatchConnectivityClientDelegate: AnyObject {
    func watchConnectivityDidReceive(session: WorkoutSession?)
    func watchConnectivityDidReceiveQuickLogHint(id: UUID?, name: String?)
}

extension WatchConnectivityClientDelegate {
    func watchConnectivityDidReceiveQuickLogHint(id: UUID?, name: String?) {}
}

final class WatchConnectivityClient: NSObject, WCSessionDelegate {
    weak var delegate: WatchConnectivityClientDelegate?

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func send(session: WorkoutSession) {
        guard WCSession.isSupported() else { return }
        let wc = WCSession.default
        guard wc.activationState == .activated,
              let data = try? JSONEncoder().encode(session)
        else { return }

        let payload: [String: Any] = ["session": data]
        do {
            try wc.updateApplicationContext(payload)
        } catch {}

        if wc.isReachable {
            wc.sendMessage(payload, replyHandler: nil) { _ in }
        }
    }

    func requestQuickLog(exerciseId: UUID?) {
        var payload: [String: Any] = ["action": "quickLog"]
        if let exerciseId {
            payload["exerciseId"] = exerciseId.uuidString
        }
        sendAction(payload)
    }

    func requestLogSet(reps: Int, weightKg: Double?) {
        var payload: [String: Any] = ["action": "logSet", "reps": reps]
        if let weightKg {
            payload["weightKg"] = weightKg
        }
        sendAction(payload)
    }

    private func sendAction(_ payload: [String: Any]) {
        guard WCSession.isSupported() else { return }
        let wc = WCSession.default
        guard wc.activationState == .activated, wc.isReachable else { return }
        wc.sendMessage(payload, replyHandler: nil) { _ in }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        applyContext(session.receivedApplicationContext)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        applyContext(applicationContext)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        applyContext(message)
    }

    private func applyContext(_ payload: [String: Any]) {
        let hintId = (payload["quickLogExerciseId"] as? String).flatMap(UUID.init(uuidString:))
        let hintName = payload["quickLogExerciseName"] as? String
        delegate?.watchConnectivityDidReceiveQuickLogHint(id: hintId, name: hintName)
        delegate?.watchConnectivityDidReceive(session: decode(payload))
    }

    private func decode(_ payload: [String: Any]) -> WorkoutSession? {
        guard let data = payload["session"] as? Data else { return nil }
        if data.isEmpty { return nil }
        return try? JSONDecoder().decode(WorkoutSession.self, from: data)
    }
}
