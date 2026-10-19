import Foundation
import ReperaDomain
import WatchConnectivity
import os

protocol WatchConnectivityClientDelegate: AnyObject {
    func watchConnectivityDidReceive(session: WorkoutSession?)
    func watchConnectivityDidReceiveQuickLogHint(id: UUID?, name: String?)
}

extension WatchConnectivityClientDelegate {
    func watchConnectivityDidReceiveQuickLogHint(id: UUID?, name: String?) {}
}

final class WatchConnectivityClient: NSObject, WCSessionDelegate {
    weak var delegate: WatchConnectivityClientDelegate?
    private let logger = Logger(subsystem: "com.app.repera.watch", category: "WatchConnectivity")
    private var lastAppliedSessionData: Data?
    private var pendingLogSets: [[String: Any]] = []

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    /// State sync only — application context. Avoids double-apply with sendMessage.
    func send(session: WorkoutSession) {
        guard WCSession.isSupported() else { return }
        let wc = WCSession.default
        guard wc.activationState == .activated,
              let data = try? JSONEncoder().encode(session)
        else { return }

        let payload: [String: Any] = ["session": data]
        do {
            try wc.updateApplicationContext(payload)
        } catch {
            logger.error("updateApplicationContext failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func requestQuickLog(exerciseId: UUID?) {
        var payload: [String: Any] = ["action": "quickLog", "actionId": UUID().uuidString]
        if let exerciseId {
            payload["exerciseId"] = exerciseId.uuidString
        }
        sendAction(payload)
    }

    func requestLogSet(reps: Int, weightKg: Double?) {
        var payload: [String: Any] = [
            "action": "logSet",
            "actionId": UUID().uuidString,
            "reps": reps,
        ]
        if let weightKg {
            payload["weightKg"] = weightKg
        }
        sendAction(payload)
    }

    private func sendAction(_ payload: [String: Any]) {
        guard WCSession.isSupported() else {
            queuePending(payload)
            return
        }
        let wc = WCSession.default
        guard wc.activationState == .activated else {
            queuePending(payload)
            return
        }
        guard wc.isReachable else {
            queuePending(payload)
            logger.info("Phone unreachable — queued local action")
            return
        }
        let expectedActionId = payload["actionId"] as? String
        wc.sendMessage(payload, replyHandler: { reply in
            guard (reply["ok"] as? Bool) == true else {
                self.logger.error("Action rejected by phone")
                self.queuePending(payload)
                return
            }
            if let expectedActionId,
               let acked = reply["actionId"] as? String,
               acked != expectedActionId {
                self.logger.error("ACK actionId mismatch")
                self.queuePending(payload)
                return
            }
            // sessionRevision > 0 confirms durable persist; 0 on duplicate ACK is OK.
            if let rev = reply["sessionRevision"] as? Int {
                self.logger.info("Phone ACK sessionRevision=\(rev, privacy: .public)")
            }
        }, errorHandler: { error in
            self.logger.error("sendMessage failed: \(error.localizedDescription, privacy: .public)")
            self.queuePending(payload)
        })
    }

    private func queuePending(_ payload: [String: Any]) {
        pendingLogSets.append(payload)
        if pendingLogSets.count > 20 {
            pendingLogSets.removeFirst(pendingLogSets.count - 20)
        }
    }

    private func flushPendingIfPossible() {
        guard WCSession.isSupported() else { return }
        let wc = WCSession.default
        guard wc.activationState == .activated, wc.isReachable, !pendingLogSets.isEmpty else { return }
        let queued = pendingLogSets
        pendingLogSets = []
        for payload in queued {
            sendAction(payload)
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        if let error {
            logger.error("activation error: \(error.localizedDescription, privacy: .public)")
        }
        applyContext(session.receivedApplicationContext)
        flushPendingIfPossible()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            flushPendingIfPossible()
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        applyContext(applicationContext)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if message["ping"] as? Bool == true { return }
        // Ignore full session over message — state arrives via application context.
        if message["session"] != nil { return }
        applyContext(message)
    }

    private func applyContext(_ payload: [String: Any]) {
        let hintId = (payload["quickLogExerciseId"] as? String).flatMap(UUID.init(uuidString:))
        let hintName = payload["quickLogExerciseName"] as? String
        delegate?.watchConnectivityDidReceiveQuickLogHint(id: hintId, name: hintName)

        guard let data = payload["session"] as? Data else { return }
        if data == lastAppliedSessionData { return }
        lastAppliedSessionData = data
        if data.isEmpty {
            delegate?.watchConnectivityDidReceive(session: nil)
            return
        }
        let session = try? JSONDecoder().decode(WorkoutSession.self, from: data)
        delegate?.watchConnectivityDidReceive(session: session)
    }
}
