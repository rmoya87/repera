import Foundation
import ReperaDomain
import WatchConnectivity
import os

protocol WatchConnectivityClientDelegate: AnyObject {
    func watchConnectivityDidReceive(session: WorkoutSession?)
    func watchConnectivityDidReceiveToday(_ today: WorkoutSession?, scheduledDay: Date?)
    func watchConnectivityDidReceiveLive(_ snapshot: WatchLiveActivitySnapshot?)
    func watchConnectivityDidReceiveTerminal(sessionId: UUID, saved: Bool)
    func watchConnectivityDidAcknowledge(sessionId: UUID, healthKitUUID: UUID?)
    func watchConnectivityDidReceiveHubMeta(recentSportIDs: [String], audioMuted: Bool?)
}

extension WatchConnectivityClientDelegate {
    func watchConnectivityDidReceiveHubMeta(recentSportIDs: [String], audioMuted: Bool?) {}
}

final class WatchConnectivityClient: NSObject, WCSessionDelegate {
    weak var delegate: WatchConnectivityClientDelegate?
    private let logger = Logger(subsystem: "com.app.repera.watch", category: "WatchConnectivity")
    private let pendingKey = "repera.watch.completedOutbox.v1"
    private var lastInboundLive: Data?
    private var lastInboundSession: Data?
    private var lastInboundSessionRevision = -1
    private var lastTerminalEvent: String?
    private var lastInboundToday: Data?
    private var lastInboundTodayDay: TimeInterval?

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

    /// Controls a phone-owned Comenzar session without opening a second GPS
    /// or HealthKit workout on the watch. Commands are live-only: if the phone
    /// is offline, no local state is optimistically changed.
    @discardableResult
    func sendLiveCommand(sessionId: UUID, command: String) -> Bool {
        guard ["pause", "resume", "finish"].contains(command),
              WCSession.isSupported(),
              WCSession.default.activationState == .activated,
              WCSession.default.isReachable else { return false }
        WCSession.default.sendMessage([
            "action": "liveCommand",
            "sessionId": sessionId.uuidString,
            "command": command,
            "actionId": UUID().uuidString
        ], replyHandler: nil) { [weak self] error in
            self?.logger.warning("Live watch command failed: \(error.localizedDescription, privacy: .public)")
        }
        return true
    }

    /// Pide al iPhone iniciar Comenzar con el deporte elegido en el hub.
    /// - Returns: `true` si el mensaje se envió (reachable). `onResult(false)` si el
    ///   teléfono rechaza (p. ej. revisión abierta) o falla el envío → el hub cae a local.
    @discardableResult
    func sendStartLive(sportID: String, onResult: ((Bool) -> Void)? = nil) -> Bool {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated,
              WCSession.default.isReachable else { return false }
        WCSession.default.sendMessage([
            "action": "startLive",
            "sportID": sportID,
            "actionId": UUID().uuidString
        ], replyHandler: { reply in
            let ok = (reply["ok"] as? Bool) ?? false
            onResult?(ok)
        }) { [weak self] error in
            self?.logger.warning("startLive failed: \(error.localizedDescription, privacy: .public)")
            onResult?(false)
        }
        return true
    }

    /// Durable companion HealthKit result; same UUID as the phone-owned GPS session.
    /// The iPhone links the verified Watch workout rather than writing a duplicate.
    func sendLiveHealthResult(sessionID: UUID, kcal: Double?, averageBpm: Double?, workoutUUID: UUID?) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        var message: [String: Any] = ["action": "liveHealthResult", "sessionId": sessionID.uuidString]
        if let kcal { message["kcal"] = kcal }
        if let averageBpm { message["averageBpm"] = averageBpm }
        if let workoutUUID { message["workoutUUID"] = workoutUUID.uuidString }
        WCSession.default.transferUserInfo(message)
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil) { _ in }
        }
    }

    func sendFinishedTimer(_ session: WorkoutSession) {
        sendFinished(session)
    }

    func sendAudioMuted(_ muted: Bool) {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated else { return }
        let payload: [String: Any] = [
            "action": "setAudioMuted",
            "audioMuted": muted,
            "actionId": UUID().uuidString
        ]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil) { _ in }
        } else {
            WCSession.default.transferUserInfo(payload)
        }
    }

    /// Descarte explícito: el iPhone debe limpiar `activeSession` aunque no
    /// haya snapshot activo en el Watch (tras `controller = nil`).
    func sendDiscarded(sessionID: UUID?) {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated else { return }
        var payload: [String: Any] = [
            "session": Data(),
            "discarded": true
        ]
        if let sessionID {
            payload["discardedSessionId"] = sessionID.uuidString
        }
        do {
            try WCSession.default.updateApplicationContext(payload)
        } catch {
            logger.error("Watch discard context failed: \(error.localizedDescription, privacy: .public)")
        }
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil) { [weak self] error in
                self?.logger.debug("Watch discard message deferred: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// Completion must not be lost when the iPhone is unavailable.
    /// Data is kept on disk until watchOS accepts the background transfer.
    func sendFinished(_ session: WorkoutSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        var queued = UserDefaults.standard.array(forKey: pendingKey) as? [Data] ?? []
        // HealthKit can finish AFTER the workout snapshot was first queued.
        // Replace unsent content and enqueue the richer revision with the same ID.
        queued.removeAll {
            (try? JSONDecoder().decode(WorkoutSession.self, from: $0))?.id == session.id
        }
        queued.append(data)
        UserDefaults.standard.set(queued, forKey: pendingKey)
        flushPending()
    }

    private func flushPending() {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated else { return }
        let queued = UserDefaults.standard.array(forKey: pendingKey) as? [Data] ?? []
        guard !queued.isEmpty else { return }
        // watchOS has a durable transfer queue. Do not enqueue identical
        // payloads on every activation, especially after a long offline period.
        // A richer HealthKit revision (different encoded Data) is still sent.
        let inFlight = Set(WCSession.default.outstandingUserInfoTransfers.compactMap {
            $0.userInfo["session"] as? Data
        })
        for data in queued where !inFlight.contains(data) {
            WCSession.default.transferUserInfo(["session": data])
        }
        // Keep a durable outbox until the iPhone acknowledges persistence.
        // watchOS may deliver twice; the iPhone reconciles using workout.id.
    }

    func acknowledge(_ id: UUID) {
        var queued = UserDefaults.standard.array(forKey: pendingKey) as? [Data] ?? []
        queued.removeAll {
            (try? JSONDecoder().decode(WorkoutSession.self, from: $0))?.id == id
        }
        UserDefaults.standard.set(queued, forKey: pendingKey)
    }

    /// Manual sync fetches today's CURRENT plan; never claim an old cached
    /// applicationContext snapshot is the result of a fresh request.
    private var pendingManualRefresh = false

    func refreshToday() {
        guard WCSession.isSupported() else { return }
        let wc = WCSession.default
        guard wc.activationState == .activated else {
            pendingManualRefresh = true
            wc.activate()
            return
        }
        requestToday(deferIfOffline: true)
    }

    private func requestToday(deferIfOffline: Bool = false) {
        guard WCSession.isSupported() else { return }
        let wc = WCSession.default
        guard wc.activationState == .activated else { return }
        let request: [String: Any] = [
            "action": "requestToday", "actionId": UUID().uuidString
        ]
        guard wc.isReachable else {
            if deferIfOffline { wc.transferUserInfo(request) }
            return
        }
        wc.sendMessage(
            request,
            replyHandler: { [weak self] payload in
                self?.applyContext(payload)
            },
            errorHandler: { [weak self] error in
                self?.logger.debug("Day refresh deferred: \(error.localizedDescription, privacy: .public)")
                if WCSession.default.activationState == .activated {
                    // Construct a fresh idempotent request inside the callback;
                    // don't capture a non-Sendable [String: Any] across actors.
                    WCSession.default.transferUserInfo([
                        "action": "requestToday",
                        "actionId": UUID().uuidString
                    ])
                }
            }
        )
    }

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: (any Error)?) {
        if let error { logger.error("Activation failed: \(error.localizedDescription, privacy: .public)") }
        applyContext(session.receivedApplicationContext)
        flushPending()
        let manual = pendingManualRefresh
        pendingManualRefresh = false
        requestToday(deferIfOffline: manual)
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

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        applyContext(userInfo)
    }

    private func applyContext(_ payload: [String: Any]) {
        let recent = payload["recentLiveSportIDs"] as? [String] ?? []
        let muted = payload["audioMuted"] as? Bool
        if !recent.isEmpty || muted != nil {
            delegate?.watchConnectivityDidReceiveHubMeta(recentSportIDs: recent, audioMuted: muted)
        }
        if let data = payload["liveActivity"] as? Data,
           data != lastInboundLive {
            lastInboundLive = data
            let live = data.isEmpty ? nil :
                try? JSONDecoder().decode(WatchLiveActivitySnapshot.self, from: data)
            delegate?.watchConnectivityDidReceiveLive(live)
        }
        if let terminal = payload["sessionTerminalId"] as? String,
           terminal != lastTerminalEvent,
           let id = UUID(uuidString: terminal) {
            lastTerminalEvent = terminal
            delegate?.watchConnectivityDidReceiveTerminal(
                sessionId: id, saved: payload["sessionTerminalSaved"] as? Bool == true
            )
        }

        if let ack = payload["completedAck"] as? String,
           let id = UUID(uuidString: ack) {
            let healthID = (payload["completedAckHealthKitUUID"] as? String)
                .flatMap(UUID.init(uuidString:))
            delegate?.watchConnectivityDidAcknowledge(sessionId: id, healthKitUUID: healthID)
        }
        if let data = payload["todayWorkout"] as? Data {
            let dayStamp = payload["todayDayStart"] as? TimeInterval
            if data != lastInboundToday || dayStamp != lastInboundTodayDay {
                // Same workout bytes may refer to a new calendar day after midnight.
                lastInboundToday = data
                lastInboundTodayDay = dayStamp
                let today = data.isEmpty ? nil : try? JSONDecoder().decode(WorkoutSession.self, from: data)
                delegate?.watchConnectivityDidReceiveToday(
                    today, scheduledDay: dayStamp.map(Date.init(timeIntervalSince1970:))
                )
            }
        }
        if let data = payload["session"] as? Data {
            let revision = payload["sessionRevision"] as? Int ?? -1
            guard revision >= lastInboundSessionRevision else { return }
            if data == lastInboundSession && revision == lastInboundSessionRevision { return }
            lastInboundSessionRevision = revision
            lastInboundSession = data
            let active = data.isEmpty ? nil : try? JSONDecoder().decode(WorkoutSession.self, from: data)
            delegate?.watchConnectivityDidReceive(session: active)
        }
    }
}
