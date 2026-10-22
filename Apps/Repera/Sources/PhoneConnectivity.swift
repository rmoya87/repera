import Foundation
import ReperaDomain
import WatchConnectivity
import os

protocol PhoneConnectivityDelegate: AnyObject {
    func phoneConnectivityDidUpdateReachability(_ reachable: Bool)
    func phoneConnectivityDidReceive(session: WorkoutSession)
    func phoneConnectivityDidRequestToday()
    func phoneConnectivityDidReceiveQuickLogRequest(exerciseId: UUID?)
    /// Persist then ACK. Returns sessionRevision after durable write (0 on failure).
    func phoneConnectivityDidReceiveLogSet(
        reps: Int,
        weightKg: Double?,
        actionId: UUID
    ) async -> Int
}

extension PhoneConnectivityDelegate {
    func phoneConnectivityDidRequestToday() {}
    func phoneConnectivityDidReceiveQuickLogRequest(exerciseId: UUID?) {}
    func phoneConnectivityDidReceiveLogSet(
        reps: Int,
        weightKg: Double?,
        actionId: UUID
    ) async -> Int { 0 }
}

final class PhoneConnectivity: NSObject, WCSessionDelegate, @unchecked Sendable {
    weak var delegate: PhoneConnectivityDelegate?
    private let logger = Logger(subsystem: "com.app.repera", category: "WatchConnectivity")
    private var processedActionIds: Set<UUID> = []
    private let processedLimit = 64
    // Cache plans created before WatchConnectivity activation completes.
    private let latestPayloadLock = NSLock()
    private var latestPayload: [String: Any]?

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    /// Latest-state sync via application context. Reachable message is optional hint only.
    func send(session: WorkoutSession?, today: WorkoutSession? = nil, quickLogHint: (id: UUID, name: String)? = nil, sessionRevision: Int = 0, completedAck: UUID? = nil, completedAckHealthKitUUID: UUID? = nil) {
        guard WCSession.isSupported() else { return }
        let wc = WCSession.default
        var payload: [String: Any]
        if let session,
           let data = try? JSONEncoder().encode(session) {
            payload = [
                "session": data,
                "stateRevision": session.updatedStamp,
                "sessionRevision": sessionRevision,
            ]
        } else {
            payload = ["session": Data(), "sessionRevision": sessionRevision]
        }
        if let today, let dayData = try? JSONEncoder().encode(today) {
            payload["todayWorkout"] = dayData
        } else {
            payload["todayWorkout"] = Data()
        }
        if let completedAck { payload["completedAck"] = completedAck.uuidString }
        if let completedAckHealthKitUUID {
            payload["completedAckHealthKitUUID"] = completedAckHealthKitUUID.uuidString
        }
        // Absolute source day, not the day when a stale context is received.
        payload["todayDayStart"] = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        if let hint = quickLogHint {
            payload["quickLogExerciseId"] = hint.id.uuidString
            payload["quickLogExerciseName"] = hint.name
        }

        latestPayloadLock.withLock { latestPayload = payload }
        publishLatestContext()
    }

    /// Reliable latest state while offline; immediate state for a reachable Watch.
    private func publishLatestContext() {
        guard WCSession.isSupported(),
              let payload = latestPayloadLock.withLock({ latestPayload }) else { return }
        let wc = WCSession.default
        guard wc.activationState == .activated else { return }
        do {
            try wc.updateApplicationContext(payload)
        } catch {
            logger.error("updateApplicationContext failed: \(error.localizedDescription, privacy: .public)")
        }
        if wc.isReachable {
            wc.sendMessage(payload, replyHandler: nil) { [weak self] error in
                self?.logger.debug("Watch live update deferred: \(error.localizedDescription, privacy: .public)")
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
        publishLatestContext()
        delegate?.phoneConnectivityDidUpdateReachability(session.isReachable)
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        delegate?.phoneConnectivityDidUpdateReachability(session.isReachable)
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        decode(applicationContext)
    }

    /// Completed sessions are delivered in the background, even if the phone app is not active.
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        decode(userInfo)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if message["ping"] as? Bool == true { return }
        if let action = message["action"] as? String {
            nonisolated(unsafe) let snapshot = message
            Task { [self] in
                _ = await self.handleAction(action, message: snapshot)
            }
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
            nonisolated(unsafe) let snapshot = message
            nonisolated(unsafe) let reply = replyHandler
            Task { [self] in
                let payload = await self.handleAction(action, message: snapshot)
                reply(payload)
            }
            return
        }
        decode(message)
        replyHandler(["ok": true])
    }

    @discardableResult
    private func handleAction(_ action: String, message: [String: Any]) async -> [String: Any] {
        switch action {
        case "requestToday":
            // Reply with the last cached state, then republish the freshest plan.
            delegate?.phoneConnectivityDidRequestToday()
            return latestPayloadLock.withLock { latestPayload } ?? ["ok": true]
        case "quickLog":
            let id = (message["exerciseId"] as? String).flatMap(UUID.init(uuidString:))
            delegate?.phoneConnectivityDidReceiveQuickLogRequest(exerciseId: id)
            return ["ok": true]
        case "logSet":
            let actionId = (message["actionId"] as? String).flatMap(UUID.init(uuidString:)) ?? UUID()
            if processedActionIds.contains(actionId) {
                logger.info("Ignoring duplicate logSet \(actionId.uuidString, privacy: .public)")
                // Duplicate: ACK without re-mutating; revision 0 means "already applied".
                return ["ok": true, "actionId": actionId.uuidString, "sessionRevision": 0]
            }
            remember(actionId)
            let reps = message["reps"] as? Int ?? 1
            let weight = message["weightKg"] as? Double
            let revision = await delegate?.phoneConnectivityDidReceiveLogSet(
                reps: reps,
                weightKg: weight,
                actionId: actionId
            ) ?? 0
            return [
                "ok": revision > 0,
                "actionId": actionId.uuidString,
                "sessionRevision": revision,
            ]
        default:
            logger.warning("Unknown Watch action \(action, privacy: .public)")
            return ["ok": false]
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
