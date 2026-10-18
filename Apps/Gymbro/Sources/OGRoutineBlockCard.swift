import GymbroDomain
import SwiftUI

/// Card de bloque (fuerza o WOD) con miniaturas — misma presentación en preview, revisión y día.
struct OGRoutineBlockCard: View {
    @Environment(GymbroStore.self) private var store

    var block: RoutineBlock
    /// Si true, muestra chevron (navegación / edición).
    var showsChevron: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(blockHeader)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(OG.accent)
                Spacer()
                if let cap = block.timeCapMinutes, block.kind == .wod {
                    Text("\(cap)'")
                        .font(.system(size: 13, weight: .semibold).monospacedDigit())
                        .foregroundStyle(OG.label2)
                }
                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(OG.label3)
                }
            }

            if block.kind == .strength {
                ForEach(block.exercises) { item in
                    exerciseRow(
                        resolvedStrengthExercise(item),
                        detail: item.plannedSets.compactSummary
                    )
                }
            } else {
                ForEach(block.movements.filter { !$0.isRest }) { move in
                    exerciseRow(resolvedWODExercise(move), detail: moveDetail(move))
                }
            }
        }
        .padding(OG.pad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }

    private var blockHeader: String {
        if block.kind == .strength {
            return block.title.isEmpty ? "Fuerza" : block.title
        }
        return block.headerLabel
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

    private func resolvedStrengthExercise(_ item: RoutineExercise) -> Exercise {
        if let ex = store.state.exercises.first(where: { $0.id == item.exerciseId }) {
            return ex
        }
        return Exercise(name: "Ejercicio", muscleGroup: "Custom", isCustom: true)
    }

    private func resolvedWODExercise(_ move: WODMovement) -> Exercise {
        if let id = move.exerciseId, let ex = store.state.exercises.first(where: { $0.id == id }) {
            return ex
        }
        let canonical = CrossFitGlossary.canonicalName(for: move.name)
        if let match = store.state.exercises.first(where: {
            $0.name.localizedCaseInsensitiveCompare(move.name) == .orderedSame
                || $0.name.localizedCaseInsensitiveCompare(canonical) == .orderedSame
        }) {
            return match
        }
        // Nombre limpio → miniatura correcta en preview / revisión / día.
        return Exercise(name: canonical.isEmpty ? move.name : canonical, muscleGroup: "WOD", isCustom: true)
    }

    private func moveDetail(_ move: WODMovement) -> String {
        if let scheme = move.repScheme, !scheme.isEmpty {
            var parts = [scheme.map(String.init).joined(separator: "-")]
            if let eq = move.notes, !eq.isEmpty { parts.append(eq) }
            return parts.joined(separator: " · ")
        }
        var parts: [String] = []
        if let reps = move.reps { parts.append("\(reps) reps") }
        if let m = move.distanceMeters { parts.append("\(m) m") }
        if let cal = move.calories { parts.append("\(cal) cal") }
        if let w = move.weightMaleKg {
            if let f = move.weightFemaleKg {
                parts.append(String(format: "%g/%g kg", w, f))
            } else {
                parts.append(String(format: "%g kg", w))
            }
        }
        if let eq = move.notes, !eq.isEmpty { parts.append(eq) }
        return parts.isEmpty ? "Movimiento" : parts.joined(separator: " · ")
    }
}

/// Lista de cards de bloques en orden (preview / revisión).
struct OGRoutineBlocksList: View {
    var blocks: [RoutineBlock]
    var showsChevron: Bool = false
    var onSelectBlock: ((RoutineBlock) -> Void)? = nil

    var body: some View {
        ForEach(blocks) { block in
            Group {
                if let onSelectBlock {
                    Button {
                        onSelectBlock(block)
                    } label: {
                        OGRoutineBlockCard(block: block, showsChevron: showsChevron)
                    }
                    .buttonStyle(.plain)
                } else {
                    OGRoutineBlockCard(block: block, showsChevron: showsChevron)
                }
            }
            .ogCardListRow(top: 0, bottom: 8)
        }
    }
}
