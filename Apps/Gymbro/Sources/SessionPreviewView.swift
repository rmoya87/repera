import GymbroDomain
import SwiftUI

/// Resumen del plan de hoy antes de empezar, o gestión de sesión en curso.
/// Sesión en curso: tocar = continuar · swipe izquierda = cancelar.
struct SessionPreviewView: View {
    @Environment(GymbroStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var routine: Routine?
    var onStart: () -> Void
    var onContinue: () -> Void

    private var active: WorkoutSession? { store.state.activeSession }

    var body: some View {
        NavigationStack {
            List {
                if let active {
                    Section {
                        Button {
                            dismiss()
                            onContinue()
                        } label: {
                            activeBanner(active)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 10, leading: OG.pad, bottom: 10, trailing: OG.pad))
                        .listRowBackground(OG.surface)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                store.endActiveSession(save: false)
                                dismiss()
                            } label: {
                                Label("Cancelar", systemImage: "xmark")
                            }
                            .tint(OG.red)
                        }
                    } footer: {
                        Text("Toca para continuar · desliza a la izquierda para cancelar")
                    }
                }

                if let routine {
                    Section {
                        Text(routine.title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(OG.label)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 8, leading: OG.pad, bottom: 4, trailing: OG.pad))

                        if routine.blocks.isEmpty {
                            flatExercises(routine)
                        } else {
                            ForEach(routine.blocks) { block in
                                blockCard(block)
                                    .listRowInsets(EdgeInsets(top: 6, leading: OG.pad, bottom: 6, trailing: OG.pad))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }
                        }
                    }
                } else if active == nil {
                    Section {
                        Text("No hay plan para hoy.")
                            .foregroundStyle(OG.label2)
                    }
                }
            }
            .ogListChrome()
            .navigationTitle(active != nil ? "Sesión" : "Plan de hoy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseToolbarButton { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if active == nil, let routine {
                    Button {
                        store.startSession(from: routine)
                        dismiss()
                        onStart()
                    } label: {
                        Text("Comenzar")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 52)
                            .background(.white, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, OG.pad)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                    .background(.ultraThinMaterial)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func activeBanner(_ session: WorkoutSession) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(OG.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text("Sesión en curso")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(OG.orange)
                Text(session.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(OG.label)
                if let current = session.currentExercise {
                    Text("Ahora: \(current.exercise.name) · \(session.progressLabel)")
                        .font(.system(size: 13))
                        .foregroundStyle(OG.label2)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(OG.label3)
        }
        .contentShape(Rectangle())
    }

    private func blockCard(_ block: RoutineBlock) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(block.headerLabel)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(OG.accent)
                Spacer()
                if let cap = block.timeCapMinutes {
                    Text("\(cap)'")
                        .font(.system(size: 13, weight: .semibold).monospacedDigit())
                        .foregroundStyle(OG.label2)
                }
            }

            if block.kind == .strength {
                ForEach(block.exercises) { item in
                    if let ex = store.state.exercises.first(where: { $0.id == item.exerciseId }) {
                        exerciseRow(
                            ex,
                            detail: "\(item.plannedSets.count)×\(item.plannedSets.first?.targetReps ?? 0)"
                        )
                    }
                }
            } else {
                ForEach(block.movements.filter { !$0.isRest }) { move in
                    exerciseRow(resolvedExercise(move), detail: moveDetail(move))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }

    private func flatExercises(_ routine: Routine) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(routine.exercises) { item in
                if let ex = store.state.exercises.first(where: { $0.id == item.exerciseId }) {
                    exerciseRow(
                        ex,
                        detail: "\(item.plannedSets.count)×\(item.plannedSets.first?.targetReps ?? 0)"
                    )
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
        .listRowInsets(EdgeInsets(top: 6, leading: OG.pad, bottom: 6, trailing: OG.pad))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private func exerciseRow(_ exercise: Exercise, detail: String) -> some View {
        HStack(spacing: 12) {
            ExerciseThumb(exercise: exercise, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(OG.label)
                    .lineLimit(2)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(OG.label3)
            }
            Spacer(minLength: 0)
        }
    }

    private func resolvedExercise(_ move: WODMovement) -> Exercise {
        if let id = move.exerciseId, let ex = store.state.exercises.first(where: { $0.id == id }) {
            return ex
        }
        if let match = store.state.exercises.first(where: {
            $0.name.localizedCaseInsensitiveCompare(move.name) == .orderedSame
        }) {
            return match
        }
        return Exercise(name: move.name, muscleGroup: "WOD", isCustom: true)
    }

    private func moveDetail(_ move: WODMovement) -> String {
        var parts: [String] = []
        if let reps = move.reps { parts.append("\(reps) reps") }
        if let m = move.distanceMeters { parts.append("\(m) m") }
        if let cal = move.calories { parts.append("\(cal) cal") }
        if let w = move.weightMaleKg { parts.append(String(format: "%g kg", w)) }
        return parts.isEmpty ? "Movimiento" : parts.joined(separator: " · ")
    }
}
