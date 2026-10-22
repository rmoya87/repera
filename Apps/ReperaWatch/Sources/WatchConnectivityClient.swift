import Foundation
import ReperaDomain
import WatchConnectivity
import os

protocol WatchConnectivityClientDelegate: AnyObject {
    func watchConnectivityDidReceive(session: WorkoutSession?)
    func watchConnectivityDidReceiveToday(_ today: WorkoutSession?)
    func watchConnectivityDidAcknowledge(sessionId: UUID)
}

final class WatchConnectivityClient: NSObject, WCSessionDelegate {
    weak var delegate: WatchConnectivityClientDelegate?
    private let logger = Logger(subsystem: "com.app.repera.watch", category: "WatchConnectivity")
    private let pendingKey = "repera.watch.completedOutbox.v1"
    private var lastInboundSession: Data?
    private var lastInboundToday: Data?

    func activate() {
        guard WCSession.isSupported() else { return }
        let wc = WCSession.default
        wc.delegate = self
        wc.activate()
    }

    /// State snapshots may be coalesced; the Watch itself persists every edit locally.
    func sendCurrent(_ session: WorkoutSession) {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated,
              let data = try? JSONEncoder().encode(session) else { return }
        do {
            try WCSession.default.updateApplicationContext(["session": data])
        } catch {
            logger.error("Watch state context failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Completion must not be lost when the iPhone is unavailable.
    /// Data is kept on disk until watchOS accepts the background transfer.
    func sendFinished(_ session: WorkoutSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        var queued = UserDefaults.standard.array(forKey: pendingKey) as? [Data] ?? []
        if !queued.contains(where: {
            (try? JSONDecoder().decode(WorkoutSession.self, from: $0))?.id == session.id
        }) {
            queued.append(data)
        }
        UserDefaults.standard.set(queued, forKey: pendingKey)
        flushPending()
    }

    private func flushPending() {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated else { return }
        let queued = UserDefaults.standard.array(forKey: pendingKey) as? [Data] ?? []
        guard !queued.isEmpty else { return }
        // transferUserInfo is queued and guaranteed by watchOS; do not require isReachable.
        for data in queued {
            WCSession.default.transferUserInfo(["session": data])
        }
        UserDefaults.standard.removeObject(forKey: pendingKey)
    }

    private func requestToday() {
        guard WCSession.isSupported() else { return }
        let wc = WCSession.default
        guard wc.activationState == .activated, wc.isReachable else { return }
        wc.sendMessage(["action": "requestToday", "actionId": UUID().uuidString],
                       replyHandler: nil) { [weak self] error in
            self?.logger.debug("Day refresh deferred: \(error.localizedDescription, privacy: .public)")
        }
    }

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: (any Error)?) {
        if let error { logger.error("Activation failed: \(error.localizedDescription, privacy: .public)") }
        applyContext(session.receivedApplicationContext)
        flushPending()
        requestToday()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable { requestToday() }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        applyContext(applicationContext)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        applyContext(message)
    }

    private func applyContext(_ payload: [String: Any]) {
        if let ack = payload["completedAck"] as? String,
           let id = UUID(uuidString: ack) {
            delegate?.watchConnectivityDidAcknowledge(sessionId: id)
        }
        if let data = payload["todayWorkout"] as? Data, data != lastInboundToday {
            lastInboundToday = data
            let today = data.isEmpty ? nil : try? JSONDecoder().decode(WorkoutSession.self, from: data)
            delegate?.watchConnectivityDidReceiveToday(today)
        }
        if let data = payload["session"] as? Data, data != lastInboundSession {
            lastInboundSession = data
            let active = data.isEmpty ? nil : try? JSONDecoder().decode(WorkoutSession.self, from: data)
            delegate?.watchConnectivityDidReceive(session: active)
        }
    }
}
