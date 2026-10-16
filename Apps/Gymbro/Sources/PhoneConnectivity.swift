import Foundation
import GymbroDomain
import WatchConnectivity

protocol PhoneConnectivityDelegate: AnyObject {
    func phoneConnectivityDidUpdateReachability(_ reachable: Bool)
    func phoneConnectivityDidReceive(session: WorkoutSession)
    func phoneConnectivityDidReceiveQuickLogRequest(exerciseId: UUID?)
    func phoneConnectivityDidReceiveLogSet(reps: Int, weightKg: Double?)
}

extension PhoneConnectivityDelegate {
    func phoneConnectivityDidReceiveQuickLogRequest(exerciseId: UUID?) {}
    func phoneConnectivityDidReceiveLogSet(reps: Int, weightKg: Double?) {}
}

final class PhoneConnectivity: NSObject, WCSessionDelegate {
    weak var delegate: PhoneConnectivityDelegate?

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func send(session: WorkoutSession?, quickLogHint: (id: UUID, name: String)? = nil) {
        guard WCSession.isSupported() else { return }
        let wc = WCSession.default
        guard wc.activationState == .activated else { return }

        var payload: [String: Any]
        if let session,
           let data = try? JSONEncoder().encode(session) {
            payload = ["session": data]
        } else {
            payload = ["session": Data()]
        }
        if let hint = quickLogHint {
            payload["quickLogExerciseId"] = hint.id.uuidString
            payload["quickLogExerciseName"] = hint.name
        }

        do {
            try wc.updateApplicationContext(payload)
        } catch {}

        if wc.isReachable {
            wc.sendMessage(payload, replyHandler: nil) { _ in }
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        delegate?.phoneConnectivityDidUpdateReachability(session.isReachable)
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        delegate?.phoneConnectivityDidUpdateReachability(session.isReachable)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        decode(applicationContext)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let action = message["action"] as? String {
            handleAction(action, message: message)
            return
        }
        decode(message)
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        if let action = message["action"] as? String {
            handleAction(action, message: message)
            replyHandler(["ok": true])
            return
        }
        decode(message)
        replyHandler(["ok": true])
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif

    private func handleAction(_ action: String, message: [String: Any]) {
        switch action {
        case "quickLog":
            let id = (message["exerciseId"] as? String).flatMap(UUID.init(uuidString:))
            delegate?.phoneConnectivityDidReceiveQuickLogRequest(exerciseId: id)
        case "logSet":
            let reps = message["reps"] as? Int ?? 1
            let weight = message["weightKg"] as? Double
            delegate?.phoneConnectivityDidReceiveLogSet(reps: reps, weightKg: weight)
        default:
            break
        }
    }

    private func decode(_ payload: [String: Any]) {
        guard let data = payload["session"] as? Data, !data.isEmpty,
              let session = try? JSONDecoder().decode(WorkoutSession.self, from: data)
        else { return }
        delegate?.phoneConnectivityDidReceive(session: session)
    }
}
