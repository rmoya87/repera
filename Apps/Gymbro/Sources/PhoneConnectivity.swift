import Foundation
import GymbroDomain
import WatchConnectivity
import os

protocol PhoneConnectivityDelegate: AnyObject {
    func phoneConnectivityDidUpdateReachability(_ reachable: Bool)
    func phoneConnectivityDidReceive(session: WorkoutSession)
    func phoneConnectivityDidReceiveQuickLogRequest(exerciseId: UUID?)
    func phoneConnectivityDidReceiveLogSet(reps: Int, weightKg: Double?, actionId: UUID)
}

extension PhoneConnectivityDelegate {
    func phoneConnectivityDidReceiveQuickLogRequest(exerciseId: UUID?) {}
    func phoneConnectivityDidReceiveLogSet(reps: Int, weightKg: Double?, actionId: UUID) {}
}

final class PhoneConnectivity: NSObject, WCSessionDelegate {
    weak var delegate: PhoneConnectivityDelegate?
    private let logger = Logger(subsystem: "app.gymbroapp.ios", category: "WatchConnectivity")
    private var processedActionIds: Set<UUID> = []
    private let processedLimit = 64

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    /// Latest-state sync via application context. Reachable message is optional hint only.
    func send(session: WorkoutSession?, quickLogHint: (id: UUID, name: String)? = nil) {
        guard WCSession.isSupported() else { return }
        let wc = WCSession.default
        guard wc.activationState == .activated else { return }

        var payload: [String: Any]
        if let session,
           let data = try? JSONEncoder().encode(session) {
            payload = ["session": data, "stateRevision": session.updatedStamp]
        } else {
            payload = ["session": Data()]
        }
        if let hint = quickLogHint {
            payload["quickLogExerciseId"] = hint.id.uuidString
            payload["quickLogExerciseName"] = hint.name
        }

        do {
            try wc.updateApplicationContext(payload)
        } catch {
            logger.error("updateApplicationContext failed: \(error.localizedDescription, privacy: .public)")
        }

        // Do not duplicate full session over sendMessage — Watch applies context only.
        // Keep a lightweight ping when reachable so the Watch knows the phone is live.
        if wc.isReachable {
            wc.sendMessage(["ping": true], replyHandler: nil) { error in
                self.logger.debug("ping failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        if let error {
            logger.error("WCSession activation error: \(error.localizedDescription, privacy: .public)")
        }
        delegate?.phoneConnectivityDidUpdateReachability(session.isReachable)
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        delegate?.phoneConnectivityDidUpdateReachability(session.isReachable)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        decode(applicationContext)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if message["ping"] as? Bool == true { return }
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
        if message["ping"] as? Bool == true {
            replyHandler(["ok": true])
            return
        }
        if let action = message["action"] as? String {
            let ok = handleAction(action, message: message)
            replyHandler(["ok": ok])
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

    @discardableResult
    private func handleAction(_ action: String, message: [String: Any]) -> Bool {
        switch action {
        case "quickLog":
            let id = (message["exerciseId"] as? String).flatMap(UUID.init(uuidString:))
            delegate?.phoneConnectivityDidReceiveQuickLogRequest(exerciseId: id)
            return true
        case "logSet":
            let actionId = (message["actionId"] as? String).flatMap(UUID.init(uuidString:)) ?? UUID()
            if processedActionIds.contains(actionId) {
                logger.info("Ignoring duplicate logSet \(actionId.uuidString, privacy: .public)")
                return true
            }
            remember(actionId)
            let reps = message["reps"] as? Int ?? 1
            let weight = message["weightKg"] as? Double
            delegate?.phoneConnectivityDidReceiveLogSet(reps: reps, weightKg: weight, actionId: actionId)
            return true
        default:
            logger.warning("Unknown Watch action \(action, privacy: .public)")
            return false
        }
    }

    private func remember(_ id: UUID) {
        processedActionIds.insert(id)
        if processedActionIds.count > processedLimit {
            processedActionIds.removeAll(keepingCapacity: true)
            processedActionIds.insert(id)
        }
    }

    private func decode(_ payload: [String: Any]) {
        guard let data = payload["session"] as? Data, !data.isEmpty,
              let session = try? JSONDecoder().decode(WorkoutSession.self, from: data)
        else { return }
        delegate?.phoneConnectivityDidReceive(session: session)
    }
}

private extension WorkoutSession {
    /// Coarse stamp for Watch payload without requiring AppState revision.
    var updatedStamp: TimeInterval {
        (finishedAt ?? startedAt ?? Date()).timeIntervalSince1970
    }
}
