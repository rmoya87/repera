import Foundation
import ReperaDomain
import WatchConnectivity
import os

protocol PhoneConnectivityDelegate: AnyObject {
    func phoneConnectivityDidUpdateReachability(_ reachable: Bool)
    func phoneConnectivityDidReceive(session: WorkoutSession)
    /// Watch descartó el entreno en curso: limpiar activeSession sin guardar.
    func phoneConnectivityDidReceiveLiveCommand(sessionId: UUID, command: String)
    func phoneConnectivityDidReceiveLiveHealth(sessionId: UUID, kcal: Double?, averageBpm: Double?, workoutUUID: UUID?)
    /// - Returns: `true` si el iPhone arrancó Comenzar; `false` si está ocupado.
    func phoneConnectivityDidReceiveStartLive(sportID: String) async -> Bool
    func phoneConnectivityDidReceiveAudioMuted(_ muted: Bool)
    func phoneConnectivityDidReceiveDiscard(sessionId: UUID?)
    func phoneConnectivityDidRequestToday()
    /// An explicit request replies with today's CURRENT prescription.
    func phoneConnectivityLatestWorkoutForToday() async -> WorkoutSession?
    func phoneConnectivityDidReceiveQuickLogRequest(exerciseId: UUID?)
    /// Persist then ACK. Returns sessionRevision after durable write (0 on failure).
    func phoneConnectivityDidReceiveLogSet(
        reps: Int,
        weightKg: Double?,
        actionId: UUID
    ) async -> Int
}

extension PhoneConnectivityDelegate {
    func phoneConnectivityDidReceiveLiveCommand(sessionId: UUID, command: String) {}
    func phoneConnectivityDidReceiveLiveHealth(sessionId: UUID, kcal: Double?, averageBpm: Double?, workoutUUID: UUID?) {}
    func phoneConnectivityDidReceiveStartLive(sportID: String) async -> Bool { false }
    func phoneConnectivityDidReceiveAudioMuted(_ muted: Bool) {}
    func phoneConnectivityDidReceiveDiscard(sessionId: UUID?) {}
    func phoneConnectivityDidRequestToday() {}
    func phoneConnectivityLatestWorkoutForToday() async -> WorkoutSession? { nil }
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
    func send(
        session: WorkoutSession?,
        today: WorkoutSession? = nil,
        quickLogHint: (id: UUID, name: String)? = nil,
        sessionRevision: Int = 0,
        completedAck: UUID? = nil,
        completedAckHealthKitUUID: UUID? = nil,
        live: WatchLiveActivitySnapshot? = nil,
        recentLiveSportIDs: [String] = [],
        audioMuted: Bool = false
    ) {
        guard WCSession.isSupported() else { return }
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
        payload["liveActivity"] = live.flatMap { try? JSONEncoder().encode($0) } ?? Data()
        payload["recentLiveSportIDs"] = recentLiveSportIDs
        payload["audioMuted"] = audioMuted
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

    /// A missing active snapshot is NOT an instruction to discard a watch-owned
    /// workout. A terminal command is scoped to the exact session UUID.
    func sendTerminalEvent(sessionID: UUID, saved: Bool) {
        guard WCSession.isSupported() else { return }
        let payload: [String: Any] = [
            "sessionTerminalId": sessionID.uuidString,
            "sessionTerminalSaved": saved
        ]
        latestPayloadLock.withLock {
            if latestPayload == nil { latestPayload = ["session": Data()] }
            latestPayload?.merge(payload) { _, new in new }
        }
        let wc = WCSession.default
        guard wc.activationState == .activated else { return }
        wc.transferUserInfo(payload)
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

    /// Completed workouts and queued manual sync requests use background delivery.
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        if let action = userInfo["action"] as? String {
            nonisolated(unsafe) let snapshot = userInfo
            Task { [self] in
                _ = await self.handleAction(action, message: snapshot)
            }
            return
        }
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
        case "liveCommand":
            guard let raw = message["sessionId"] as? String,
                  let id = UUID(uuidString: raw),
                  let command = message["command"] as? String,
                  ["pause", "resume", "finish"].contains(command) else {
                return ["ok": false]
            }
            delegate?.phoneConnectivityDidReceiveLiveCommand(sessionId: id, command: command)
            return ["ok": true]
        case "startLive":
            guard let sportID = message["sportID"] as? String, !sportID.isEmpty else {
                return ["ok": false]
            }
            let started = await (delegate?.phoneConnectivityDidReceiveStartLive(sportID: sportID) ?? false)
            return ["ok": started]
        case "liveHealthResult":
            guard let raw = message["sessionId"] as? String,
                  let id = UUID(uuidString: raw) else { return ["ok": false] }
            delegate?.phoneConnectivityDidReceiveLiveHealth(
                sessionId: id, kcal: message["kcal"] as? Double,
                averageBpm: message["averageBpm"] as? Double,
                workoutUUID: (message["workoutUUID"] as? String).flatMap(UUID.init(uuidString:))
            )
            return ["ok": true]
        case "setAudioMuted":
            let muted = message["audioMuted"] as? Bool ?? false
            delegate?.phoneConnectivityDidReceiveAudioMuted(muted)
            return ["ok": true]
        case "requestToday":
            // The iPhone resolves its current date-specific plan BEFORE replying,
            // rather than returning an outdated applicationContext payload.
            // Returning empty Data is intentional only when there is no plan.
            guard let delegate else {
                return ["ok": false]
            }
            let today = await delegate.phoneConnectivityLatestWorkoutForToday()
            let data = today.flatMap { try? JSONEncoder().encode($0) } ?? Data()
            delegate.phoneConnectivityDidRequestToday()
            // El contexto completo (recents, audio, live) se publica en sendWatchContextNow.
            return [
                "ok": true,
                "todayWorkout": data,
                "todayDayStart": Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
            ]
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
            let reps = message["reps"] as? Int ?? 1
            let weight = message["weightKg"] as? Double
            let revision = await delegate?.phoneConnectivityDidReceiveLogSet(
                reps: reps,
                weightKg: weight,
                actionId: actionId
            ) ?? 0
            // An unsuccessful durable write is NOT an acknowledged action. Retrying
            // with the same UUID must still be allowed after a transient error.
            if revision > 0 { remember(actionId) }
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
        if payload["discarded"] as? Bool == true
            || ((payload["session"] as? Data)?.isEmpty == true
                && payload["discardedSessionId"] != nil) {
            let id = (payload["discardedSessionId"] as? String).flatMap(UUID.init(uuidString:))
            delegate?.phoneConnectivityDidReceiveDiscard(sessionId: id)
            return
        }
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
