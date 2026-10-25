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
    /// Impide que una actualización GPS/Watch encolada resucite una sesión
    /// después de finalizarla o descartarla.
    private var closedSessionIDs: Set<String> = []

    /// En vivo: métricas GPS verificadas. Pausas descontadas del tiempo activo.
    func updateFree(
        startedAt: Date, sport: LiveSport, phase: TrainingActivityAttributes.ContentState.Phase,
        elapsedSeconds: TimeInterval, distanceMeters: Double, speedKmh: Double?
    ) async {
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
            subtitle: isGPS ? "" : "Entrenamiento libre",
            timerAnchor: Date().addingTimeInterval(-TimeInterval(elapsed)), elapsedSeconds: elapsed,
            primaryValue: isGPS ? pace : "—",
            primaryLabel: isGPS ? (sport.displaysSpeed ? "Veloc. media" : "Ritmo medio") : "FC (ppm)",
            secondaryValue: isGPS ? String(format: "%.2f", max(0, distanceMeters) / 1000) : "—",
            secondaryLabel: isGPS ? "Distancia (km)" : "Kcal"
        )
        await upsert(id: key, isPlanned: false, state: state)
    }

    /// Todos los planes (incluidos OCR, entrenador personal y Apple Watch)
    /// comparten la misma ActivityKit, nunca dependen de WorkoutView visible.
    func updatePlanned(_ session: WorkoutSession?) async {
        guard let session, let start = session.startedAt, session.finishedAt == nil else {
            await endAll(isPlanned: true, dismissal: .immediate)
            return
        }
        let exercise = session.currentExercise
        let total = session.exercises.count
        let progress = total > 0 ? "\(min(total, session.currentIndex + 1))/\(total)" : "—"
        let completedSets = session.exercises.reduce(0) { result, exercise in
            result + exercise.loggedSets.count
        }
        let elapsed = max(0, Int(Date().timeIntervalSince(start)))
        let state = TrainingActivityAttributes.ContentState(
            phase: .running,
            title: session.title.isEmpty ? "Entrenamiento" : session.title,
            symbol: "figure.cross.training",
            subtitle: exercise.map { ($0.blockHeader ?? $0.exercise.name) } ?? "Entrenamiento programado",
            timerAnchor: start, elapsedSeconds: elapsed,
            primaryValue: progress, primaryLabel: "Ejercicio",
            secondaryValue: String(completedSets), secondaryLabel: "Series"
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

    private func upsert(
        id: String,
        isPlanned: Bool,
        state: TrainingActivityAttributes.ContentState
    ) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled,
              !closedSessionIDs.contains(id) else { return }
        if let previous = latestStates[id], previous == state { return }
        latestStates[id] = state

        // No heredar una Live Activity huérfana de otro entrenamiento del mismo tipo.
        for activity in Activity<TrainingActivityAttributes>.activities
        where activity.attributes.isPlanned == isPlanned && activity.attributes.sessionID != id {
            await activity.end(nil, dismissalPolicy: .immediate)
            latestStates.removeValue(forKey: activity.attributes.sessionID)
        }

        if let activity = Activity<TrainingActivityAttributes>.activities.first(where: {
            $0.attributes.sessionID == id
        }) {
            await activity.update(ActivityContent(state: state, staleDate: nil))
            return
        }
        do {
            _ = try Activity.request(
                attributes: TrainingActivityAttributes(sessionID: id, isPlanned: isPlanned),
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            logger.error("Training Live Activity: \(String(describing: error), privacy: .public)")
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
