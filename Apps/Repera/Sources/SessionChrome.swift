import Foundation
import ReperaDomain

/// Minimal Equatable snapshot for tab chrome / Watch debounce consumers.
/// TabView observes this instead of the full `WorkoutSession` graph on every set log.
struct ContinueAccessoryModel: Equatable, Sendable {
    var title: String
    var progressLabel: String
    var thumbName: String?

    init?(session: WorkoutSession?) {
        guard let session else { return nil }
        let current = session.currentExercise
        title = current?.exercise.name ?? session.title
        progressLabel = session.progressLabel
        thumbName = current.flatMap { ExerciseArt.imageName(for: $0.exercise) }
    }
}
