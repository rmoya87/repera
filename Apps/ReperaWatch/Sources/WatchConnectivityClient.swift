import Foundation
import ReperaDomain
import WatchConnectivity
import os

protocol WatchConnectivityClientDelegate: AnyObject {
    func watchConnectivityDidReceive(session: WorkoutSession?)
    func watchConnectivityDidReceiveToday(_ today: WorkoutSession?, scheduledDay: Date?)
    func watchConnectivityDidAcknowledge(sessionId: UUID, healthKitUUID: UUID?)
}

final class WatchConnectivityClient: NSObject, WCSessionDelegate {
    weak var delegate: WatchConnectivityClientDelegate?
    private let logger = Logger(subsystem: "com.app.repera.watch", category: "WatchConnectivity")
    private let pendingKey = "repera.watch.completedOutbox.v1"
    private var lastInboundSession: Data?
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
                    WCSession.default.transferUserInfo(request)
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

    private func applyContext(_ payload: [String: Any]) {
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
        if let data = payload["session"] as? Data, data != lastInboundSession {
            lastInboundSession = data
            let active = data.isEmpty ? nil : try? JSONDecoder().decode(WorkoutSession.self, from: data)
            delegate?.watchConnectivityDidReceive(session: active)
        }
    }
}
