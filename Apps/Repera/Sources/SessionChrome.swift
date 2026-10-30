import Foundation
import ReperaDomain

/// Reloj de Comenzar: MM:SS bajo 1 h; H:MM:SS con hora sin cero a la izquierda.
enum LiveActivityClock {
    static func format(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        if total >= 3600 {
            return String(format: "%d:%02d:%02d", total / 3600, (total / 60) % 60, total % 60)
        }
        return String(format: "%02d:%02d", (total / 60) % 60, total % 60)
    }
}

/// Minimal Equatable snapshot for tab chrome / Watch debounce consumers.
/// TabView observes this instead of the full `WorkoutSession` graph on every set log.
struct ContinueAccessoryModel: Equatable, Sendable {
    var title: String
    var progressLabel: String
    var thumbName: String?
    /// SF Symbol del deporte (solo Comenzar / Live).
    var sportSymbol: String?
    /// `true` = actividad Comenzar (Live); `false` = entreno de fuerza en Play.
    var isLiveActivity: Bool
    /// Ritmo/velocidad y distancia para Continuar comprimido (Live).
    var paceLabel: String?
    var distanceLabel: String?

    init?(session: WorkoutSession?) {
        guard let session else { return nil }
        let current = session.currentExercise
        title = current?.exercise.name ?? session.title
        progressLabel = session.progressLabel
        thumbName = current.flatMap { ExerciseArt.imageName(for: $0.exercise) }
        sportSymbol = nil
        isLiveActivity = false
        paceLabel = nil
        distanceLabel = nil
    }

    /// Continuar una grabación de Comenzar (mapa / GPS).
    @MainActor
    init?(liveRecorder: LiveActivityRecorder) {
        guard liveRecorder.isActive else { return nil }
        title = liveRecorder.sport.title
        let seconds = liveRecorder.duration(at: Date())
        progressLabel = LiveActivityClock.format(seconds)
        thumbName = nil
        sportSymbol = liveRecorder.sport.symbol
        isLiveActivity = true
        if liveRecorder.sport.usesGPS {
            paceLabel = Self.livePaceOrSpeed(liveRecorder)
            let km = liveRecorder.recordedDistanceMeters / 1000
            distanceLabel = "\(ReperaNumberFormat.decimal(km)) km"
        } else {
            paceLabel = nil
            distanceLabel = nil
        }
    }

    @MainActor
    private static func livePaceOrSpeed(_ recorder: LiveActivityRecorder) -> String {
        guard let average = recorder.averageSpeedKmh, average > 0.1 else {
            return recorder.sport.displaysSpeed ? "— km/h" : "—:—"
        }
        if recorder.sport.displaysSpeed {
            return "\(ReperaNumberFormat.decimal(average)) km/h"
        }
        let paceSecs = Int(3600 / average)
        guard paceSecs < 3600 else { return "—:—" }
        return String(format: "%d:%02d /km", paceSecs / 60, paceSecs % 60)
    }
}
