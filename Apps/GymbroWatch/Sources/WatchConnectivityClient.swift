import Foundation
import GymbroDomain
import WatchConnectivity

protocol WatchConnectivityClientDelegate: AnyObject {
    func watchConnectivityDidReceive(session: WorkoutSession?)
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

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        if let contextSession = decode(session.receivedApplicationContext) {
            delegate?.watchConnectivityDidReceive(session: contextSession)
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        delegate?.watchConnectivityDidReceive(session: decode(applicationContext))
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        delegate?.watchConnectivityDidReceive(session: decode(message))
    }

    private func decode(_ payload: [String: Any]) -> WorkoutSession? {
        guard let data = payload["session"] as? Data else { return nil }
        if data.isEmpty { return nil }
        return try? JSONDecoder().decode(WorkoutSession.self, from: data)
    }
}
