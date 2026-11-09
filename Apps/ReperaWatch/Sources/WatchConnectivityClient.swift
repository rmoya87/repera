import Foundation
import ReperaDomain
import WatchConnectivity
import os

protocol WatchConnectivityClientDelegate: AnyObject {
    func watchConnectivityDidReceive(session: WorkoutSession?)
    func watchConnectivityDidReceiveToday(_ today: WorkoutSession?, scheduledDay: Date?)
    func watchConnectivityDidReceiveTodayPlans(_ plans: [WorkoutSession], scheduledDay: Date?)
    func watchConnectivityDidReceiveLive(_ snapshot: WatchLiveActivitySnapshot?)
    func watchConnectivityDidReceiveTerminal(sessionId: UUID, saved: Bool)
    func watchConnectivityDidAcknowledge(sessionId: UUID, healthKitUUID: UUID?)
    func watchConnectivityDidReceiveHubMeta(recentSportIDs: [String], audioMuted: Bool?)
    func watchConnectivityDidReceiveTimerCommand(id: UUID, command: String)
    /// iPhone asked Watch to own HealthKit for this execution (Apple handoff).
    func watchConnectivityDidReceiveWatchOwnedLiveCommand(
        sessionId: UUID, command: String
    )
    func watchConnectivityDidReceiveHandoffStart(
        session: WorkoutSession?, sessionID: UUID, sportID: String?
    )
    func watchConnectivityDidRequestWatchOwnedLiveSnapshot()
    func watchConnectivityDidBecomeReachable()
    func watchConnectivityDidChangeReachability(_ reachable: Bool)
    func watchConnectivityDidChangeOwnerScope(hasOwner: Bool)
}

extension WatchConnectivityClientDelegate {
    func watchConnectivityDidReceiveTodayPlans(_ plans: [WorkoutSession], scheduledDay: Date?) {}
    func watchConnectivityDidReceiveHubMeta(recentSportIDs: [String], audioMuted: Bool?) {}
    func watchConnectivityDidReceiveTimerCommand(id: UUID, command: String) {}
    func watchConnectivityDidReceiveWatchOwnedLiveCommand(
        sessionId: UUID, command: String
    ) {}
    func watchConnectivityDidReceiveHandoffStart(
        session: WorkoutSession?, sessionID: UUID, sportID: String?
    ) {}
    func watchConnectivityDidRequestWatchOwnedLiveSnapshot() {}
    func watchConnectivityDidBecomeReachable() {}
    func watchConnectivityDidChangeReachability(_ reachable: Bool) {}
    func watchConnectivityDidChangeOwnerScope(hasOwner: Bool) {}
}

final class WatchConnectivityClient: NSObject, WCSessionDelegate {
    weak var delegate: WatchConnectivityClientDelegate?
    private let logger = Logger(subsystem: "com.app.repera.watch", category: "WatchConnectivity")
    /// Clave antigua de UserDefaults; la cola vive ahora en un fichero protegido.
    private let pendingKey = "repera.watch.completedOutbox.v1"
    private let pendingFile = "completedOutbox.v1.json"
    private let pendingLiveCancelKey = "repera.watch.pendingLiveCancels.v1"
    private let pendingOwnersKey = "repera.watch.completedOutboxOwners.v1"
    private let pendingCancelOwnersKey = "repera.watch.pendingCancelOwners.v1"
    private let ownerKey = "repera.watch.ownerScope.v1"
    private var currentOwnerScope: String? {
        UserDefaults.standard.string(forKey: ownerKey)
    }
    var hasOwnerScope: Bool { currentOwnerScope?.isEmpty == false }
    var isReachable: Bool {
        WCSession.isSupported() && WCSession.default.activationState == .activated
            && WCSession.default.isReachable
    }
    private var lastInboundLive: Data?
    private var lastInboundSession: Data?
    private var lastInboundSessionRevision = -1
    private var lastTerminalEvent: String?
    private var lastInboundToday: Data?
    private var lastInboundTodayDay: TimeInterval?
    private var lastInboundTodayPlans: Data?
    private var lastInboundTodayPlansDay: TimeInterval?
    private var lastMirrorMessageAt = Date.distantPast
    private var lastMirrorPhase: String?
    private var lastMirrorID: UUID?
    /// Los delegados de WCSession llegan en una cola propia; la cola y los ACK
    /// pendientes de fichero se modifican también desde el hub (MainActor).
    private let outboxLock = NSLock()
    /// ACK del iPhone recibido mientras la ruta aún viaja como fichero.
    private var acknowledgedAwaitingFile: Set<UUID> = []

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
        guard let owner = currentOwnerScope else { return }
        do {
            try WCSession.default.updateApplicationContext(["session": data, "ownerScope": owner])
        } catch {
            logger.error("Watch state context failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// A Watch-owned workout must announce its own live phase to the paired
    /// iPhone: otherwise HealthKit runs on Watch but no ActivityKit UI starts.
    /// Transitions are durable; periodic GPS/elapsed updates are best effort.
    /// This never starts a second workout or forwards raw HealthKit samples.
    func sendWatchOwnedLive(_ snapshot: WatchLiveActivitySnapshot, durable: Bool) {
        guard WCSession.isSupported(),
              let owner = currentOwnerScope, !owner.isEmpty,
              let data = try? JSONEncoder().encode(snapshot),
              WatchTransportLimits.accepts(data) else { return }
        let wc = WCSession.default
        guard wc.activationState == .activated else { return }
        let payload: [String: Any] = [
            "ownerScope": owner,
            "watchOwnedLiveActivity": data
        ]
        if durable {
            // watchOS delivers userInfo after reconnect; the phone checks UUID,
            // phase, order and capture age before creating an ActivityKit card.
            wc.transferUserInfo(payload)
        }
        if wc.isReachable {
            wc.sendMessage(payload, replyHandler: nil) { [weak self] error in
                self?.logger.debug("Watch live UI update deferred: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// Controls a phone-owned Comenzar session without opening a second GPS
    /// or HealthKit workout on the watch. Commands are live-only: if the phone
    /// is offline, no local state is optimistically changed.
    @discardableResult
    func sendLiveCommand(
        sessionId: UUID, command: String, onResult: ((Bool) -> Void)? = nil
    ) -> Bool {
        guard ["pause", "resume", "finish", "cancel"].contains(command),
              WCSession.isSupported(),
              WCSession.default.activationState == .activated,
              let owner = currentOwnerScope else { return false }
        let message: [String: Any] = [
            "ownerScope": owner,
            "action": "liveCommand",
            "sessionId": sessionId.uuidString,
            "command": command,
            "actionId": UUID().uuidString
        ]
        let wc = WCSession.default
        // Durable even when the phone mirror is visible via applicationContext
        // but sendMessage is briefly unreachable (classic “lo veo pero no pausa”).
        wc.transferUserInfo(message)
        if wc.isReachable {
            wc.sendMessage(message, replyHandler: { reply in
                onResult?((reply["ok"] as? Bool) == true)
            }) { [weak self] error in
                self?.logger.warning(
                    "Live watch command deferred: \(error.localizedDescription, privacy: .public)"
                )
                // transferUserInfo already queued — do not block pause/finish UI.
                onResult?(true)
            }
        } else {
            onResult?(true)
        }
        return true
    }

    /// Muestra puntual de FC de HealthKit para la sesión Comenzar del iPhone.
    /// Solo viaja si el teléfono está accesible; no se persiste ni se duplica un workout.
    @discardableResult
    func sendLiveHeartRate(sessionId: UUID, bpm: Int, capturedAt: Date = Date()) -> Bool {
        guard (25...250).contains(bpm),
              WCSession.isSupported(),
              WCSession.default.activationState == .activated,
              WCSession.default.isReachable,
              let owner = currentOwnerScope else { return false }
        WCSession.default.sendMessage([
            "ownerScope": owner,
            "action": "liveHeartRate",
            "sessionId": sessionId.uuidString,
            "bpm": bpm,
            "capturedAt": capturedAt.timeIntervalSince1970
        ], replyHandler: nil) { [weak self] error in
            self?.logger.debug("Watch HR deferred: \(error.localizedDescription, privacy: .public)")
        }
        return true
    }

    /// Encola cancelaciones por UUID: transferUserInfo entrega en segundo plano
    /// aunque el iPhone no esté accesible cuando se pulse Confirmar.
    /// La misma orden se envía por sendMessage para respuesta inmediata.
    /// Las dos copias son seguras: el iPhone comprueba sessionId.
    /// La orden queda retenida hasta que el iPhone responde o publica un
    /// estado posterior sin esa sesión (`confirmLiveCancellations`).
    @discardableResult
    func enqueueLiveCancellation(sessionId: UUID) -> Bool {
        guard WCSession.isSupported(), let owner = currentOwnerScope else { return false }
        var owners = UserDefaults.standard.dictionary(forKey: pendingCancelOwnersKey) as? [String: String] ?? [:]
        owners[sessionId.uuidString] = owner
        UserDefaults.standard.set(owners, forKey: pendingCancelOwnersKey)
        var ids = UserDefaults.standard.stringArray(forKey: pendingLiveCancelKey) ?? []
        if !ids.contains(sessionId.uuidString) {
            ids.append(sessionId.uuidString)
            UserDefaults.standard.set(Array(ids.suffix(20)), forKey: pendingLiveCancelKey)
        }
        let wc = WCSession.default
        if wc.activationState == .activated {
            flushPendingLiveCancellations()
        } else {
            wc.activate()
        }
        return true
    }

    private func flushPendingLiveCancellations() {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated else { return }
        let wc = WCSession.default
        let pending = UserDefaults.standard.stringArray(forKey: pendingLiveCancelKey) ?? []
        let owners = UserDefaults.standard.dictionary(forKey: pendingCancelOwnersKey) as? [String: String] ?? [:]
        guard let owner = currentOwnerScope, !pending.isEmpty else { return }
        // watchOS conserva la cola duradera: no apilar copias en cada activación.
        let inFlight = Set(wc.outstandingUserInfoTransfers.compactMap { transfer -> String? in
            guard transfer.userInfo["command"] as? String == "cancel" else { return nil }
            return transfer.userInfo["sessionId"] as? String
        })
        for rawID in pending {
            guard let sessionID = UUID(uuidString: rawID), owners[rawID] == owner else { continue }
            let message: [String: Any] = [
                "ownerScope": owner,
                "action": "liveCommand",
                "sessionId": sessionID.uuidString,
                "command": "cancel",
                "actionId": UUID().uuidString
            ]
            // La transferencia queda retenida por watchOS incluso al cerrar Repera.
            if !inFlight.contains(rawID) {
                wc.transferUserInfo(message)
            }
            if wc.isReachable {
                wc.sendMessage(message, replyHandler: { [weak self] _ in
                    // Cualquier respuesta es definitiva: aplicada o la sesión ya no está activa.
                    self?.confirmLiveCancellations(except: nil, only: sessionID)
                }) { [weak self] error in
                    self?.logger.debug("Live cancel deferred: \(error.localizedDescription, privacy: .public)")
                }
            }
        }
    }

    /// Retira cancelaciones confirmadas. `except` = sesión que el iPhone sigue
    /// mostrando como activa; `only` limita la confirmación a un UUID.
    private func confirmLiveCancellations(except activeID: UUID?, only: UUID? = nil) {
        let defaults = UserDefaults.standard
        let pending = defaults.stringArray(forKey: pendingLiveCancelKey) ?? []
        guard !pending.isEmpty else { return }
        let retained = pending.filter { raw in
            if let only { return raw != only.uuidString }
            return raw == activeID?.uuidString
        }
        guard retained.count != pending.count else { return }
        defaults.set(retained, forKey: pendingLiveCancelKey)
        var owners = defaults.dictionary(forKey: pendingCancelOwnersKey) as? [String: String] ?? [:]
        for raw in pending where !retained.contains(raw) { owners.removeValue(forKey: raw) }
        defaults.set(owners, forKey: pendingCancelOwnersKey)
    }

    /// Pide al iPhone iniciar Comenzar con el deporte elegido en el hub.
    /// - Returns: `true` si el mensaje se envió (reachable). `onResult(false)` si el
    ///   teléfono rechaza (p. ej. revisión abierta) o falla el envío → el hub cae a local.
    @discardableResult
    func sendStartLive(sportID: String, onResult: ((Bool) -> Void)? = nil) -> Bool {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated,
              WCSession.default.isReachable,
              let owner = currentOwnerScope else { return false }
        WCSession.default.sendMessage([
            "ownerScope": owner,
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

    /// El estado viaja por applicationContext (último valor, sobrevive a desconexiones).
    /// sendMessage solo para eventos discretos (inicio, pausa, fin, descarte) o,
    /// como mucho, cada 15 s mientras corre.
    func sendTimerMirror(_ mirror: WatchTimerMirror) {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated,
              let data = try? JSONEncoder().encode(mirror),
              let owner = currentOwnerScope else { return }
        let payload: [String: Any] = ["timerMirror": data, "ownerScope": owner]
        do {
            try WCSession.default.updateApplicationContext(payload)
        } catch {
            logger.debug("Watch timer context deferred: \(error.localizedDescription, privacy: .public)")
        }
        let now = Date()
        let discrete = mirror.id != lastMirrorID || mirror.phase != lastMirrorPhase
        lastMirrorID = mirror.id
        lastMirrorPhase = mirror.phase
        guard WCSession.default.isReachable,
              discrete || now.timeIntervalSince(lastMirrorMessageAt) >= 15 else { return }
        lastMirrorMessageAt = now
        WCSession.default.sendMessage(payload, replyHandler: nil) { _ in }
    }

    func sendFinishedTimer(_ session: WorkoutSession) {
        sendFinished(session)
    }

    func sendAudioMuted(_ muted: Bool) {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated else { return }
        guard let owner = currentOwnerScope else { return }
        let payload: [String: Any] = [
            "ownerScope": owner,
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
        guard let owner = currentOwnerScope else { return }
        var payload: [String: Any] = [
            "session": Data(),
            "discarded": true,
            "ownerScope": owner
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

    // MARK: - Cola durable de entrenos terminados

    private func loadOutbox() -> [Data] {
        if let legacy = UserDefaults.standard.array(forKey: pendingKey) as? [Data] {
            if let encoded = try? JSONEncoder().encode(legacy),
               WatchProtectedFileStore.write(encoded, to: pendingFile) {
                UserDefaults.standard.removeObject(forKey: pendingKey)
            }
            return legacy
        }
        guard let data = WatchProtectedFileStore.read(pendingFile) else { return [] }
        return (try? JSONDecoder().decode([Data].self, from: data)) ?? []
    }

    private func saveOutbox(_ queued: [Data]) {
        WatchProtectedFileStore.write(
            queued.isEmpty ? nil : try? JSONEncoder().encode(queued), to: pendingFile
        )
    }

    /// Completion must not be lost when the iPhone is unavailable.
    /// Data is kept on disk until watchOS accepts the background transfer.
    func sendFinished(_ session: WorkoutSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        outboxLock.withLock {
            var queued = loadOutbox()
            // HealthKit can finish AFTER the workout snapshot was first queued.
            // Replace unsent content and enqueue the richer revision with the same ID.
            queued.removeAll {
                (try? JSONDecoder().decode(WorkoutSession.self, from: $0))?.id == session.id
            }
            queued.append(data)
            saveOutbox(queued)
            acknowledgedAwaitingFile.remove(session.id)
        }
        // Never silently relabel an offline completion after a login switch.
        if let owner = currentOwnerScope {
            var owners = UserDefaults.standard.dictionary(forKey: pendingOwnersKey) as? [String: String] ?? [:]
            owners[session.id.uuidString] = owner
            UserDefaults.standard.set(owners, forKey: pendingOwnersKey)
        }
        flushPending()
    }

    private func flushPending() {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated else { return }
        let queued = outboxLock.withLock { loadOutbox() }
        guard !queued.isEmpty, let currentOwnerScope else { return }
        let owners = UserDefaults.standard.dictionary(forKey: pendingOwnersKey) as? [String: String] ?? [:]
        // watchOS has a durable transfer queue. Do not enqueue identical
        // payloads on every activation, especially after a long offline period.
        // A richer HealthKit revision (different encoded Data) is still sent.
        let wc = WCSession.default
        let inFlight = Set(wc.outstandingUserInfoTransfers.compactMap {
            $0.userInfo["session"] as? Data
        })
        let filesInFlight = Set(wc.outstandingFileTransfers.compactMap {
            $0.file.metadata?["transferKey"] as? String
        })
        for data in queued {
            guard let session = try? JSONDecoder().decode(WorkoutSession.self, from: data),
                  owners[session.id.uuidString] == currentOwnerScope else { continue }
            var userInfo: [String: Any] = ["ownerScope": currentOwnerScope]
            if data.count > WatchTransportLimits.inlineFinishedSessionBytes,
               !session.routePoints.isEmpty,
               WatchTransportLimits.acceptsFile(byteCount: data.count) {
                // Ruta grande: fichero completo + la misma sesión sin ruta en userInfo
                // (un iPhone antiguo guarda el entreno aunque no lea el fichero).
                var light = session
                light.routePoints = []
                guard let lightData = try? JSONEncoder().encode(light) else { continue }
                userInfo["session"] = lightData
                userInfo["routeViaFile"] = true
                let transferKey = "\(session.id.uuidString)-\(data.count)"
                if !filesInFlight.contains(transferKey) {
                    transferSessionFile(data, sessionID: session.id, owner: currentOwnerScope, key: transferKey)
                }
            } else {
                userInfo["session"] = data
            }
            if let payload = userInfo["session"] as? Data, !inFlight.contains(payload) {
                wc.transferUserInfo(userInfo)
            }
        }
        // Keep a durable outbox until the iPhone acknowledges persistence.
        // watchOS may deliver twice; the iPhone reconciles using workout.id.
    }

    private func transferSessionFile(_ data: Data, sessionID: UUID, owner: String, key: String) {
        guard let url = WatchProtectedFileStore.directory("Outbox")?
            .appendingPathComponent("\(key).json") else { return }
        do {
            try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            logger.error("Watch route file could not be staged")
            return
        }
        WCSession.default.transferFile(url, metadata: [
            "kind": "finishedSession",
            "sessionId": sessionID.uuidString,
            "ownerScope": owner,
            "byteCount": data.count,
            "transferKey": key
        ])
    }

    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: (any Error)?) {
        let url = fileTransfer.file.fileURL
        let sessionID = (fileTransfer.file.metadata?["sessionId"] as? String).flatMap(UUID.init(uuidString:))
        if error != nil {
            logger.warning("Watch route file transfer failed; it will be retried")
        }
        try? FileManager.default.removeItem(at: url)
        guard error == nil, let sessionID else { return }
        let wasAcknowledged = outboxLock.withLock { acknowledgedAwaitingFile.remove(sessionID) != nil }
        if wasAcknowledged { removeFromOutbox(sessionID) }
    }

    func acknowledge(_ id: UUID) {
        let fileInFlight = WCSession.isSupported() && WCSession.default.outstandingFileTransfers.contains {
            $0.file.metadata?["sessionId"] as? String == id.uuidString
        }
        if fileInFlight {
            _ = outboxLock.withLock { acknowledgedAwaitingFile.insert(id) }
            return
        }
        removeFromOutbox(id)
    }

    private func removeFromOutbox(_ id: UUID) {
        outboxLock.withLock {
            var queued = loadOutbox()
            queued.removeAll {
                (try? JSONDecoder().decode(WorkoutSession.self, from: $0))?.id == id
            }
            saveOutbox(queued)
        }
        var owners = UserDefaults.standard.dictionary(forKey: pendingOwnersKey) as? [String: String] ?? [:]
        owners.removeValue(forKey: id.uuidString)
        UserDefaults.standard.set(owners, forKey: pendingOwnersKey)
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

    /// Product metrics only: phone hosts Firebase; Watch never links Analytics SDKs.
    func enqueueAnalyticsEvent(
        _ event: String,
        featureArea: String = "reliability",
        result: String = "success",
        actionName: String? = nil
    ) {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated,
              let owner = currentOwnerScope else { return }
        var payload: [String: Any] = [
            "ownerScope": owner,
            "action": "analyticsEvent",
            "event": event,
            "feature_area": featureArea,
            "result": result,
            "actionId": UUID().uuidString
        ]
        if let actionName { payload["action_name"] = actionName }
        let wc = WCSession.default
        if wc.isReachable {
            wc.sendMessage(payload, replyHandler: { _ in }, errorHandler: { [payload] _ in
                WCSession.default.transferUserInfo(payload)
            })
        } else {
            wc.transferUserInfo(payload)
        }
    }

    private func requestToday(deferIfOffline: Bool = false) {
        guard WCSession.isSupported() else { return }
        let wc = WCSession.default
        guard wc.activationState == .activated,
              let owner = currentOwnerScope else { return }
        let request: [String: Any] = [
            "ownerScope": owner,
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
                        "ownerScope": owner,
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
        // The replayed context may predate a cancel: it never confirms cancellations.
        applyContext(session.receivedApplicationContext, acceptsOwnerTransition: true,
                     confirmsCancellations: false)
        flushPending()
        flushPendingLiveCancellations()
        let manual = pendingManualRefresh
        pendingManualRefresh = false
        requestToday(deferIfOffline: manual)
        delegate?.watchConnectivityDidChangeReachability(session.isReachable)
        if session.isReachable { delegate?.watchConnectivityDidBecomeReachable() }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        delegate?.watchConnectivityDidChangeReachability(session.isReachable)
        if session.isReachable {
            requestToday()
            flushPendingLiveCancellations()
            delegate?.watchConnectivityDidBecomeReachable()
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        applyContext(applicationContext, acceptsOwnerTransition: true)
        flushPending()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        applyContext(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        applyContext(userInfo)
    }

    /// Rechaza datos sobredimensionados antes de `JSONDecoder`; no registra el contenido.
    private func boundedData(_ payload: [String: Any], _ key: String) -> Data? {
        guard let data = payload[key] as? Data else { return nil }
        guard WatchTransportLimits.accepts(data) else {
            logger.error("Ignoring oversized WatchConnectivity field")
            return nil
        }
        return data
    }

    private func applyContext(
        _ payload: [String: Any],
        acceptsOwnerTransition: Bool = false,
        confirmsCancellations: Bool = true
    ) {
        // Only the iPhone's latest application context may replace account scope.
        // Buffered user-info transfers from an older identity must not do it.
        if acceptsOwnerTransition,
           let incoming = payload["ownerScope"] as? String,
           !incoming.isEmpty, incoming != currentOwnerScope {
            UserDefaults.standard.set(incoming, forKey: ownerKey)
            lastInboundSessionRevision = -1
            lastInboundSession = nil
            lastInboundToday = nil
            lastInboundTodayPlans = nil
            lastInboundLive = nil
            delegate?.watchConnectivityDidChangeOwnerScope(hasOwner: true)
        }
        if let incoming = payload["ownerScope"] as? String,
           incoming != currentOwnerScope { return }
        if payload["action"] as? String == "requestWatchOwnedLiveSnapshot" {
            // The scope was validated above. A read-only request must never
            // start or mutate an HKWorkoutSession.
            delegate?.watchConnectivityDidRequestWatchOwnedLiveSnapshot()
            return
        }
        if payload["action"] as? String == "watchOwnedLiveCommand" {
            guard let scope = payload["ownerScope"] as? String, !scope.isEmpty,
                  scope == currentOwnerScope,
                  let rawID = payload["sessionId"] as? String,
                  let id = UUID(uuidString: rawID),
                  let command = payload["command"] as? String,
                  ["pause", "resume", "finish"].contains(command) else {
                logger.warning("Ignoring unscoped or invalid Watch-owned command")
                return
            }
            delegate?.watchConnectivityDidReceiveWatchOwnedLiveCommand(
                sessionId: id, command: command
            )
            return
        }
        if payload["action"] as? String == "timerCommand" {
            // Órdenes que alteran estado: exigir el ámbito de cuenta. Las builds de
            // iPhone anteriores no lo enviaban; se rechazan (función no crítica).
            guard let scope = payload["ownerScope"] as? String, !scope.isEmpty,
                  scope == currentOwnerScope,
                  let rawID = payload["timerId"] as? String,
                  let id = UUID(uuidString: rawID),
                  let command = payload["command"] as? String,
                  ["pause", "resume", "finish"].contains(command) else {
                logger.warning("Ignoring unscoped or invalid timer command")
                return
            }
            delegate?.watchConnectivityDidReceiveTimerCommand(id: id, command: command)
            return
        }
        if payload["action"] as? String == "handoffStart" {
            guard let scope = payload["ownerScope"] as? String, !scope.isEmpty,
                  scope == currentOwnerScope,
                  let rawID = payload["handoffSessionId"] as? String,
                  let sessionID = UUID(uuidString: rawID) else {
                logger.warning("Ignoring unscoped or invalid Watch handoff")
                return
            }
            let sportID = payload["sportID"] as? String
            let session: WorkoutSession?
            if let data = boundedData(payload, "handoffSession") {
                session = try? JSONDecoder().decode(WorkoutSession.self, from: data)
            } else {
                session = nil
            }
            delegate?.watchConnectivityDidReceiveHandoffStart(
                session: session, sessionID: sessionID, sportID: sportID
            )
            return
        }
        let recent = payload["recentLiveSportIDs"] as? [String] ?? []
        let muted = payload["audioMuted"] as? Bool
        if !recent.isEmpty || muted != nil {
            delegate?.watchConnectivityDidReceiveHubMeta(recentSportIDs: recent, audioMuted: muted)
        }
        if let data = boundedData(payload, "liveActivity") {
            let live = data.isEmpty ? nil :
                try? JSONDecoder().decode(WatchLiveActivitySnapshot.self, from: data)
            if confirmsCancellations, data.isEmpty || live != nil {
                confirmLiveCancellations(except: live?.id)
            }
            if data != lastInboundLive {
                lastInboundLive = data
                delegate?.watchConnectivityDidReceiveLive(live)
            }
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
        if let maxBpm = payload["maxHeartRateBpm"] as? Int,
           (120...230).contains(maxBpm) {
            UserDefaults.standard.set(maxBpm, forKey: "repera.watch.heartRate.maxBpm")
        }
        if let data = boundedData(payload, "todayWorkout") {
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
        if let data = boundedData(payload, "todayWorkouts") {
            let dayStamp = payload["todayDayStart"] as? TimeInterval
            if data != lastInboundTodayPlans ||
               dayStamp != lastInboundTodayPlansDay {
                lastInboundTodayPlans = data
                lastInboundTodayPlansDay = dayStamp
                let plans = (try? JSONDecoder().decode([WorkoutSession].self, from: data)) ?? []
                delegate?.watchConnectivityDidReceiveTodayPlans(
                    plans, scheduledDay: dayStamp.map(Date.init(timeIntervalSince1970:))
                )
            }
        }
        if let data = boundedData(payload, "session") {
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
