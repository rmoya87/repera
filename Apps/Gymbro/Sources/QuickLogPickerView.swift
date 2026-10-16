import GymbroDomain
import SwiftUI

/// Picker de un ejercicio para log rápido (Crear → Apuntar series).
/// Mismo lenguaje de lista/sección que Crear / Favoritos (sin card envolvente).
struct QuickLogPickerView: View {
    @Environment(GymbroStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var onOpenedWorkout: () -> Void

    @State private var query = ""

    var body: some View {
        List {
            Section {
                OGBackPageHeader(title: "Apuntar series", onBack: { dismiss() })
                    .ogListPageHeaderRow()
            }

            Section {
                ForEach(filtered) { exercise in
                    Button {
                        store.startQuickLog(exerciseId: exercise.id)
                        onOpenedWorkout()
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name)
                                    .foregroundStyle(OG.label)
                                Text(subtitle(exercise))
                                    .font(.caption)
                                    .foregroundStyle(OG.label2)
                            }
                        } icon: {
                            ExerciseThumb(exercise: exercise)
                        }
                    }
                }
            } header: {
                Text("Ejercicio")
            } footer: {
                Text("Un ejercicio, sin montar rutina. Entra directo a apuntar series.")
            }
        }
        .ogListChrome()
        .searchable(text: $query, prompt: "Buscar ejercicio")
        .ogContentTitleNav()
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
    }

    private func subtitle(_ exercise: Exercise) -> String {
        var parts: [String] = [exercise.muscleGroup]
        let hist = StatsEngine.history(for: exercise.id, workouts: store.state.workouts)
        if let w = hist.lastWeightKg {
            parts.append("últ. \(w.formatted(.number.precision(.fractionLength(0...1)))) kg")
        }
        return parts.joined(separator: " · ")
    }

    private var filtered: [Exercise] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let base = store.state.exercises
        if q.isEmpty { return base }
        return base.filter {
            $0.name.lowercased().contains(q) || $0.muscleGroup.lowercased().contains(q)
        }
    }
}
