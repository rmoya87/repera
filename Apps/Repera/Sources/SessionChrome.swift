import Foundation
import ReperaDomain

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

    init?(session: WorkoutSession?) {
        guard let session else { return nil }
        let current = session.currentExercise
        title = current?.exercise.name ?? session.title
        progressLabel = session.progressLabel
        thumbName = current.flatMap { ExerciseArt.imageName(for: $0.exercise) }
        sportSymbol = nil
        isLiveActivity = false
    }

    /// Continuar una grabación de Comenzar (mapa / GPS).
    @MainActor
    init?(liveRecorder: LiveActivityRecorder) {
        guard liveRecorder.isActive else { return nil }
        title = liveRecorder.sport.title
        let seconds = Int(liveRecorder.duration(at: Date()).rounded())
        let m = seconds / 60
        let s = seconds % 60
        progressLabel = String(format: "%d:%02d", m, s)
        thumbName = nil
        sportSymbol = liveRecorder.sport.symbol
        isLiveActivity = true
    }
}
