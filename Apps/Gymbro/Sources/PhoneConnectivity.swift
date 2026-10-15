import Foundation
import GymbroDomain
import WatchConnectivity

protocol PhoneConnectivityDelegate: AnyObject {
    func phoneConnectivityDidUpdateReachability(_ reachable: Bool)
    func phoneConnectivityDidReceive(session: WorkoutSession)
}

final class PhoneConnectivity: NSObject, WCSessionDelegate {
    weak var delegate: PhoneConnectivityDelegate?

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func send(session: WorkoutSession?) {
        guard WCSession.isSupported() else { return }
        let wc = WCSession.default
        guard wc.activationState == .activated else { return }

        let payload: [String: Any]
        if let session,
           let data = try? JSONEncoder().encode(session) {
            payload = ["session": data]
        } else {
            payload = ["session": Data()]
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
        decode(message)
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif

    private func decode(_ payload: [String: Any]) {
        guard let data = payload["session"] as? Data, !data.isEmpty,
              let session = try? JSONDecoder().decode(WorkoutSession.self, from: data)
        else { return }
        delegate?.phoneConnectivityDidReceive(session: session)
    }
}
