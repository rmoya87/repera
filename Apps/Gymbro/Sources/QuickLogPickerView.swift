import GymbroDomain
import SwiftUI

/// Picker de un ejercicio para log rápido (Crear → Apuntar series).
/// Mismo pipeline rápido que `ExercisePickerView` (índice/ranking off-main).
struct QuickLogPickerView: View {
    @Environment(GymbroStore.self) private var store
    var onOpenedWorkout: () -> Void

    var body: some View {
        ExerciseCatalogSearchList(
            exercises: store.state.exercises,
            prompt: "Buscar ejercicio",
            onPick: { exercise in
                store.startQuickLog(exerciseId: exercise.id)
                onOpenedWorkout()
            },
            header: {
                Text("Ejercicio")
            },
            footer: {
                Text("Un ejercicio, sin montar rutina. Entra directo a apuntar series.")
            }
        )
        .ogPinnedTransparentNav("Apuntar series")
        .preferredColorScheme(.dark)
    }
}
