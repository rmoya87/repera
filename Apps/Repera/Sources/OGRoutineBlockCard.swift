import ReperaDomain
import SwiftUI

/// Card de bloque (fuerza o WOD) con miniaturas — misma presentación en preview, revisión y día.
struct OGRoutineBlockCard: View {
    @Environment(ReperaStore.self) private var store

    var block: RoutineBlock
    /// Si true, muestra chevron (navegación / edición).
    var showsChevron: Bool = false
    var opensExerciseDetail: Bool = false
    /// Destino único administrado por el NavigationStack padre.
    var onOpenExercise: ((UUID) -> Void)? = nil

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
                    linkedExerciseRow(
                        resolvedStrengthExercise(item),
                        detail: item.plannedSets.compactSummary
                    )
                }
            } else {
                ForEach(block.movements) { move in
                    if move.isRest {
                        HStack(spacing: 8) {
                            Image(systemName: "pause.circle")
                            Text("Descanso")
                            Spacer(minLength: 0)
                            Text(restDetail(move))
                                .monospacedDigit()
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(OG.label3)
                        .padding(.leading, 56)
                    } else {
                        linkedExerciseRow(resolvedWODExercise(move), detail: moveDetail(move))
                    }
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

    @ViewBuilder
    private func linkedExerciseRow(_ exercise: Exercise, detail: String) -> some View {
        if opensExerciseDetail,
           let catalog = store.resolvedCatalogExercise(id: exercise.id) {
            if let onOpenExercise {
                // En una card con varias filas, varios NavigationLink podían
                // activarse de golpe. El padre abre SOLO el ejercicio pulsado.
                Button {
                    onOpenExercise(catalog.id)
                } label: {
                    HStack(spacing: 8) {
                        exerciseRow(exercise, detail: detail)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(OG.label3)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Abrir ficha del ejercicio")
            } else {
                NavigationLink {
                    ExerciseDetailView(exerciseId: catalog.id)
                } label: {
                    exerciseRow(exercise, detail: detail)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Abrir ficha del ejercicio")
            }
        } else {
            exerciseRow(exercise, detail: detail)
        }
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
        if let match = CrossFitGlossary.catalogExercise(for: move, in: store.state.exercises),
           !match.isCustom, !match.isCatalogArchived {
            return match
        }
        // Una ficha provisional «BTt»/«T2B» no debe eclipsar el nombre
        // canónico mientras se rehidrata el catálogo oficial.
        let canonical = CrossFitGlossary.resolveCatalogName(move.name, notes: move.notes)
        // Nombre limpio → miniatura correcta en preview / revisión / día.
        return Exercise(name: canonical.isEmpty ? move.name : canonical, muscleGroup: "WOD", isCustom: true)
    }

    private func restDetail(_ move: WODMovement) -> String {
        let seconds = move.restSeconds ?? 60
        return seconds % 60 == 0 ? "\(seconds / 60) min" : "\(seconds) s"
    }

    private func moveDetail(_ move: WODMovement) -> String {
        if let scheme = move.repScheme, !scheme.isEmpty {
            var parts = [scheme.map(String.init).joined(separator: "-")]
            if let eq = move.notes, !eq.isEmpty { parts.append(eq) }
            return parts.joined(separator: " · ")
        }
        // 5-10 / 6-10 son rangos prescritos, no «10 reps · 5-10».
        var noteParts = (move.notes ?? "").components(separatedBy: " · ")
            .filter { !$0.isEmpty }
        let rangeIndex = noteParts.firstIndex {
            $0.range(of: #"^\d+\s*[-–]\s*\d+$"#, options: .regularExpression) != nil
        }
        var parts: [String] = []
        if let reps = move.reps {
            if let rangeIndex {
                let range = noteParts.remove(at: rangeIndex)
                parts.append("\(range) reps")
            } else {
                parts.append("\(reps) reps")
            }
        }
        if let m = move.distanceMeters { parts.append("\(m) m") }
        if let cal = move.calories { parts.append("\(cal) cal") }
        if let w = move.weightMaleKg {
            if let f = move.weightFemaleKg {
                parts.append("\(ReperaNumberFormat.decimal(w))/\(ReperaNumberFormat.decimal(f)) kg")
            } else {
                parts.append("\(ReperaNumberFormat.decimal(w)) kg")
            }
        }
        parts.append(contentsOf: noteParts)
        return parts.isEmpty ? "Movimiento" : parts.joined(separator: " · ")
    }
}

/// Lista de cards de bloques en orden (preview / revisión).
struct OGRoutineBlocksList: View {
    var blocks: [RoutineBlock]
    var showsChevron: Bool = false
    var onSelectBlock: ((RoutineBlock) -> Void)? = nil
    var opensExerciseDetail: Bool = false
    var onOpenExercise: ((UUID) -> Void)? = nil

    var body: some View {
        ForEach(blocks) { block in
            Group {
                if let onSelectBlock {
                    Button {
                        onSelectBlock(block)
                    } label: {
                        OGRoutineBlockCard(block: block, showsChevron: showsChevron,
                                           opensExerciseDetail: opensExerciseDetail,
                                           onOpenExercise: onOpenExercise)
                    }
                    .buttonStyle(.plain)
                } else {
                    OGRoutineBlockCard(block: block, showsChevron: showsChevron,
                                       opensExerciseDetail: opensExerciseDetail,
                                       onOpenExercise: onOpenExercise)
                }
            }
            .ogCardListRow(top: 0, bottom: 8)
        }
    }
}
