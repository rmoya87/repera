@preconcurrency import ActivityKit
import Foundation
import ReperaDomain
import os

/// Un solo coordinador para entrenamiento libre y programado. ActivityKit dibuja el
/// reloj localmente; solo publicamos cambios de estado, ejercicios y métricas.
@MainActor
final class WorkoutLiveActivityCoordinator {
    static let shared = WorkoutLiveActivityCoordinator()

    private let logger = Logger(subsystem: "com.app.repera", category: "WorkoutLiveActivity")
    private var latestStates: [String: TrainingActivityAttributes.ContentState] = [:]
    private var lastWatchCaptureAt: [String: Date] = [:]
    /// Impide que una actualización GPS/Watch encolada resucite una sesión
    /// después de finalizarla o descartarla.
    private var closedSessionIDs: Set<String> = []

    // Persist only Watch transport ordering and closed UUIDs (no HealthKit data).
    private struct WatchDeliveryMark: Codable {
        let capture: Date
        let closed: Bool
        let observed: Date
    }
    private static let watchMarksKey = "repera.watch.liveDeliveryMarks.v1"
    private var watchMarks: [String: WatchDeliveryMark] = {
        // No usar `Self.` aquí: el inicializador de stored property no admite
        // Self covariante. Nombre de tipo explícito (final class).
        guard let data = UserDefaults.standard.data(
            forKey: WorkoutLiveActivityCoordinator.watchMarksKey
        ),
              let marks = try? JSONDecoder().decode(
                [String: WatchDeliveryMark].self, from: data
              ) else { return [:] }
        return marks.filter { Date().timeIntervalSince($0.value.observed) < 172_800 }
    }()

    private func persistWatchMarks() {
        let marks = watchMarks.filter {
            Date().timeIntervalSince($0.value.observed) < 172_800
        }.sorted { $0.value.observed > $1.value.observed }.prefix(200)
        watchMarks = Dictionary(uniqueKeysWithValues: marks.map { ($0.key, $0.value) })
        if let data = try? JSONEncoder().encode(watchMarks) {
            UserDefaults.standard.set(
                data, forKey: WorkoutLiveActivityCoordinator.watchMarksKey
            )
        }
    }

    func mayAcceptWatchOwned(_ snapshot: WatchLiveActivitySnapshot) -> Bool {
        let key = "watch:" + snapshot.id.uuidString
        guard !closedSessionIDs.contains(key),
              WatchOwnedLiveDeliveryPolicy.accepts(snapshot) else { return false }
        guard let mark = watchMarks[key] else { return true }
        return !mark.closed && snapshot.capturedAt > mark.capture
    }

    /// En vivo: métricas GPS verificadas. Pausas descontadas del tiempo activo.
    func updateFree(
        startedAt: Date, sport: LiveSport, phase: TrainingActivityAttributes.ContentState.Phase,
        elapsedSeconds: TimeInterval, distanceMeters: Double, speedKmh: Double?,
        navigation: TrainingActivityAttributes.ContentState.NavigationCue? = nil,
        lastSplit: String? = nil
    ) async {
        // Watch-owned Comenzar is mirrored on the phone, not recorded here.
        // Its watch:UUID ActivityKit notification must never be replaced by a
        // competing free:timestamp notification on foreground refresh/pause.
        guard !LiveActivityRecorder.shared.isWatchOwnedMirror else { return }
        let key = "free:" + String(Int64(startedAt.timeIntervalSince1970 * 1000))
        let elapsed = max(0, Int(elapsedSeconds.rounded(.down)))
        let pace: String
        if let speedKmh, speedKmh > 0.1 {
            if sport.displaysSpeed {
                pace = String(format: "%.1f", speedKmh)
            } else {
                let seconds = Int(3600 / speedKmh)
                pace = String(format: "%d:%02d", seconds / 60, seconds % 60)
            }
        } else {
            pace = sport.displaysSpeed ? "—" : "—:—"
        }
        let isGPS = sport.usesGPS
        let state = TrainingActivityAttributes.ContentState(
            phase: phase, title: sport.title, symbol: sport.symbol,
            subtitle: isGPS ? (lastSplit ?? "") : "Entrenamiento libre",
            timerAnchor: Date().addingTimeInterval(-TimeInterval(elapsed)), elapsedSeconds: elapsed,
            primaryValue: isGPS ? pace : "—",
            primaryLabel: isGPS ? (sport.displaysSpeed ? "Veloc. media" : "Ritmo medio") : "FC (ppm)",
            secondaryValue: isGPS ? String(format: "%.2f", max(0, distanceMeters) / 1000) : "—",
            secondaryLabel: isGPS ? "Distancia (km)" : "Kcal",
            navigation: phase == .completed ? nil : navigation
        )
        await upsert(id: key, isPlanned: false, state: state)
    }

    /// Apple Watch owns the actual HealthKit workout. This is only a local
    /// iPhone lock-screen/Dynamic Island mirror of that same UUID; no sensors,
    /// GPS recording, or duplicate workout are started on the phone.
    func updateWatchOwned(_ snapshot: WatchLiveActivitySnapshot) async {
        let id = "watch:" + snapshot.id.uuidString
        guard mayAcceptWatchOwned(snapshot) else { return }
        // Record the attempt so an older capture cannot overtake this one while
        // ActivityKit is in flight. Roll it back if no card was actually created:
        // the same snapshot must be able to retry.
        let previousMark = watchMarks[id]
        lastWatchCaptureAt[id] = snapshot.capturedAt
        watchMarks[id] = WatchDeliveryMark(
            capture: snapshot.capturedAt, closed: snapshot.phase == .review,
            observed: Date()
        )
        persistWatchMarks()
        if snapshot.phase == .review {
            await finishWatchOwned(sessionID: snapshot.id, saved: false)
            return
        }
        guard !closedSessionIDs.contains(id) else { return }
        let elapsed = max(0, Int(snapshot.elapsedSeconds.rounded(.down)))
        let phase: TrainingActivityAttributes.ContentState.Phase =
            snapshot.phase == .paused ? .paused : .running
        let timerAnchor = snapshot.capturedAt.addingTimeInterval(-TimeInterval(elapsed))
        let state: TrainingActivityAttributes.ContentState
        switch snapshot.kind {
        case .planned:
            // Plan/class owned by Watch: same UUID card, no phone pause controls.
            state = TrainingActivityAttributes.ContentState(
                phase: phase,
                title: snapshot.sportTitle.isEmpty ? "Entrenamiento" : snapshot.sportTitle,
                symbol: snapshot.symbolName ?? "figure.cross.training",
                subtitle: snapshot.subtitle ?? "",
                timerAnchor: timerAnchor, elapsedSeconds: elapsed,
                primaryValue: snapshot.primaryValue ?? "—",
                primaryLabel: snapshot.primaryLabel ?? "Ejercicio",
                secondaryValue: snapshot.secondaryValue ?? "—",
                secondaryLabel: snapshot.secondaryLabel ?? "Series"
            )
        case .sport:
            let sport = snapshot.sportID.flatMap(LiveSport.init(rawValue:))
            let isGPS = sport?.usesGPS ?? false
            let pace: String
            if let speed = snapshot.averageSpeedKmh, speed.isFinite, speed > 0.1 {
                if sport?.displaysSpeed == true {
                    pace = String(format: "%.1f", speed)
                } else {
                    let seconds = min(3599, Int(3600 / speed))
                    pace = String(format: "%d:%02d", seconds / 60, seconds % 60)
                }
            } else {
                pace = sport?.displaysSpeed == true ? "—" : "—:—"
            }
            let indoorHeart: String = {
                if let bpm = snapshot.heartRateBpm, (25...250).contains(bpm) {
                    return "\(bpm)"
                }
                return "—"
            }()
            let indoorEnergy: String = {
                if let kcal = snapshot.activeEnergyKcal, kcal.isFinite, kcal >= 0 {
                    return String(format: "%.0f", kcal)
                }
                return "—"
            }()
            state = TrainingActivityAttributes.ContentState(
                phase: phase, title: snapshot.sportTitle,
                symbol: sport?.symbol ?? "figure.run",
                subtitle: "",
                timerAnchor: timerAnchor, elapsedSeconds: elapsed,
                primaryValue: isGPS ? pace : indoorHeart,
                primaryLabel: isGPS
                    ? (sport?.displaysSpeed == true ? "Veloc. media" : "Ritmo medio")
                    : "FC (ppm)",
                secondaryValue: isGPS
                    ? String(format: "%.2f", max(0, snapshot.distanceMeters) / 1000)
                    : indoorEnergy,
                secondaryLabel: isGPS ? "Distancia (km)" : "Kcal"
            )
        }
        // Always watch:UUID so widget hides phone-side controls for Watch-owned work.
        let shown = await upsert(id: id, isPlanned: false, state: state)
        guard shown else {
            rollbackWatchDeliveryMark(
                id: id, capture: snapshot.capturedAt, previous: previousMark
            )
            return
        }
    }

    /// A failed ActivityKit request must not consume this capture. A newer mark
    /// or a closed session is left untouched.
    private func rollbackWatchDeliveryMark(
        id: String, capture: Date, previous: WatchDeliveryMark?
    ) {
        guard let current = watchMarks[id],
              !current.closed,
              current.capture == capture else { return }
        if let previous {
            watchMarks[id] = previous
            lastWatchCaptureAt[id] = previous.capture
        } else {
            watchMarks.removeValue(forKey: id)
            lastWatchCaptureAt.removeValue(forKey: id)
        }
        persistWatchMarks()
    }

    /// Phone asked the Watch to finish this UUID. Further live snapshots must
    /// not rewind it, but the ActivityKit card stays until the workout is saved.
    func retainWatchOwnedUntilSaved(sessionID: UUID) {
        let id = "watch:" + sessionID.uuidString
        closedSessionIDs.insert(id)
        watchMarks[id] = WatchDeliveryMark(
            capture: max(watchMarks[id]?.capture ?? .distantPast, Date()),
            closed: true,
            observed: Date()
        )
        persistWatchMarks()
    }

    /// Terminal events close the exact Watch UUID. A delayed recording
    /// transfer must never resurrect it. The phone's Home gets the workout
    /// independently from sendFinished/transferUserInfo.
    func finishWatchOwned(sessionID: UUID, saved: Bool) async {
        let id = "watch:" + sessionID.uuidString
        closedSessionIDs.insert(id)
        watchMarks[id] = WatchDeliveryMark(
            capture: max(watchMarks[id]?.capture ?? .distantPast, Date()),
            closed: true, observed: Date()
        )
        persistWatchMarks()
        if saved, var state = latestStates[id] {
            state.phase = .completed
            state.subtitle = "Entrenamiento guardado"
            await finish(id: id, state: state, dismissal: .after(Date().addingTimeInterval(20)))
        } else {
            await finish(id: id, state: nil, dismissal: .immediate)
        }
    }

    /// Todos los planes (incluidos OCR, entrenador personal y Apple Watch)
    /// comparten la misma ActivityKit, nunca dependen de WorkoutView visible.
    /// Watch-owned plans use `updateWatchOwned` (`watch:UUID`) instead.
    func updatePlanned(_ session: WorkoutSession?, isPaused: Bool = false) async {
        guard let session, let start = session.startedAt, session.finishedAt == nil else {
            await endAll(isPlanned: true, dismissal: .immediate)
            return
        }
        if session.appleHealthProvenance == "watchHealthKit"
            || session.appleHealthProvenance == "watchHealthKitPending" {
            // Live Activity is driven by durable Watch snapshots for this UUID.
            return
        }
        let exercise = session.currentExercise
        let total = session.exercises.count
        let progress = total > 0 ? "\(min(total, session.currentIndex + 1))/\(total)" : "—"
        let completedSets = session.exercises.reduce(0) { result, exercise in
            result + exercise.loggedSets.count
        }
        let activeElapsed: TimeInterval
        if let active = session.activeDurationSeconds, active > 0 {
            activeElapsed = active
        } else {
            activeElapsed = max(0, Date().timeIntervalSince(start))
        }
        let elapsed = max(0, Int(activeElapsed.rounded(.down)))
        // Outdoor planned workouts use the same verified GPS odometer as Comenzar.
        // Indoor strength/WOD keeps its series/exercise counters unchanged.
        let gps = WorkoutLocationTracker.shared
        let outdoor = WorkoutLocationTracker.shouldTrackRoute(for: session)
            && gps.trackingSessionID == session.id
        let kilometers = gps.recordedDistanceMeters / 1000
        let activeSeconds = max(1, activeElapsed)
        let speedKmh = gps.recordedDistanceMeters / activeSeconds * 3.6
        let isCycling = session.title.localizedCaseInsensitiveContains("bici")
            || session.title.localizedCaseInsensitiveContains("cycling")
        let gpsMetric: String
        if gps.recordedDistanceMeters < 25 {
            gpsMetric = isCycling ? "—" : "—:—"
        } else if isCycling {
            gpsMetric = String(format: "%.1f", speedKmh)
        } else if speedKmh > 0.1 {
            let paceSeconds = min(3599, Int(3600 / speedKmh))
            gpsMetric = String(format: "%d:%02d", paceSeconds / 60, paceSeconds % 60)
        } else {
            gpsMetric = "—:—"
        }
        let phase: TrainingActivityAttributes.ContentState.Phase =
            isPaused ? .paused : .running
        let state = TrainingActivityAttributes.ContentState(
            phase: phase,
            title: session.title.isEmpty ? "Entrenamiento" : session.title,
            symbol: outdoor ? "figure.run" : "figure.cross.training",
            subtitle: exercise.map { ($0.blockHeader ?? $0.exercise.name) }
                ?? "Entrenamiento programado",
            timerAnchor: Date().addingTimeInterval(-TimeInterval(elapsed)),
            elapsedSeconds: elapsed,
            primaryValue: outdoor ? gpsMetric : progress,
            primaryLabel: outdoor ? (isCycling ? "Veloc. media" : "Ritmo medio") : "Ejercicio",
            secondaryValue: outdoor ? String(format: "%.2f", kilometers) : String(completedSets),
            secondaryLabel: outdoor ? "Distancia (km)" : "Series"
        )
        await upsert(id: "planned:\(session.id.uuidString)", isPlanned: true, state: state)
    }

    func completePlanned(_ session: WorkoutSession?, saved: Bool) async {
        guard let session else { return }
        let id = "planned:\(session.id.uuidString)"
        closedSessionIDs.insert(id)
        if saved {
            var state = latestStates[id] ?? TrainingActivityAttributes.ContentState(
                phase: .completed, title: session.title,
                symbol: "figure.cross.training", subtitle: "Entrenamiento completado",
                timerAnchor: session.startedAt ?? Date(),
                elapsedSeconds: Int(session.displayDurationMinutes * 60),
                primaryValue: session.progressLabel, primaryLabel: "Ejercicio",
                secondaryValue: String(session.exercises.reduce(0) { $0 + $1.loggedSets.count }),
                secondaryLabel: "Series"
            )
            state.phase = .completed
            state.elapsedSeconds = max(0, Int((session.finishedAt ?? Date())
                .timeIntervalSince(session.startedAt ?? Date())))
            state.subtitle = "Entrenamiento completado"
            await finish(id: id, state: state, dismissal: .after(Date().addingTimeInterval(20)))
        } else {
            await finish(id: id, state: nil, dismissal: .immediate)
        }
    }

    func dismissFree(startedAt: Date, saved: Bool) async {
        let id = "free:" + String(Int64(startedAt.timeIntervalSince1970 * 1000))
        closedSessionIDs.insert(id)
        if saved, var state = latestStates[id] {
            state.phase = .completed
            state.subtitle = "Actividad finalizada"
            await finish(id: id, state: state, dismissal: .after(Date().addingTimeInterval(20)))
        } else {
            await finish(id: id, state: nil, dismissal: .immediate)
        }
    }

    @discardableResult
    private func upsert(
        id: String,
        isPlanned: Bool,
        state: TrainingActivityAttributes.ContentState
    ) async -> Bool {
        guard ActivityAuthorizationInfo().areActivitiesEnabled,
              !closedSessionIDs.contains(id) else { return false }
        // A cached attempt is not proof ActivityKit actually created a card.
        // Retry even identical Watch snapshots if the previous request failed.
        let exists = activityExists(id)
        if let previous = latestStates[id], previous == state, exists { return true }
        latestStates[id] = state

        // No heredar una Live Activity huérfana de otro entrenamiento del mismo tipo.
        for activity in Activity<TrainingActivityAttributes>.activities
        where activity.attributes.isPlanned == isPlanned && activity.attributes.sessionID != id {
            await activity.end(nil, dismissalPolicy: .immediate)
            latestStates.removeValue(forKey: activity.attributes.sessionID)
        }

        // An awaited ActivityKit operation may interleave with a Watch finish
        // or a newer snapshot; neither should resurrect an older state.
        guard !closedSessionIDs.contains(id), latestStates[id] == state else {
            return activityExists(id)
        }
        if let activity = Activity<TrainingActivityAttributes>.activities.first(where: {
            $0.attributes.sessionID == id
        }) {
            await activity.update(ActivityContent(state: state, staleDate: nil))
            return true
        }
        do {
            // `.token` enables remote updates / push-to-start once APNs is wired.
            // Tokens are observed in LiveActivityPushTokenStore; never invent metrics here.
            _ = try Activity.request(
                attributes: TrainingActivityAttributes(sessionID: id, isPlanned: isPlanned),
                content: ActivityContent(state: state, staleDate: nil),
                pushType: .token
            )
            LiveActivityPushTokenStore.startObservingIfNeeded()
            return true
        } catch {
            // Local-only activities do not require an APNs push token. If the
            // remote-update variant is rejected by provisioning, still show
            // the local ActivityKit notification while this app can start it.
            do {
                _ = try Activity.request(
                    attributes: TrainingActivityAttributes(sessionID: id, isPlanned: isPlanned),
                    content: ActivityContent(state: state, staleDate: nil),
                    pushType: nil
                )
                return true
            } catch {
                // Only the failed attempt is forgotten. A newer snapshot that
                // replaced `latestStates` during the request must stay cached.
                if latestStates[id] == state {
                    latestStates.removeValue(forKey: id)
                }
                logger.error("Training Live Activity: \(String(describing: error), privacy: .public)")
                return activityExists(id)
            }
        }
    }

    private func activityExists(_ id: String) -> Bool {
        Activity<TrainingActivityAttributes>.activities.contains {
            $0.attributes.sessionID == id
        }
    }

    private func finish(
        id: String, state: TrainingActivityAttributes.ContentState?,
        dismissal: ActivityUIDismissalPolicy
    ) async {
        latestStates.removeValue(forKey: id)
        for activity in Activity<TrainingActivityAttributes>.activities
        where activity.attributes.sessionID == id {
            let finalContent = state.map { ActivityContent(state: $0, staleDate: nil) }
            await activity.end(finalContent, dismissalPolicy: dismissal)
        }
    }

    private func endAll(isPlanned: Bool, dismissal: ActivityUIDismissalPolicy) async {
        for activity in Activity<TrainingActivityAttributes>.activities
        where activity.attributes.isPlanned == isPlanned {
            latestStates.removeValue(forKey: activity.attributes.sessionID)
            await activity.end(nil, dismissalPolicy: dismissal)
        }
    }
}
