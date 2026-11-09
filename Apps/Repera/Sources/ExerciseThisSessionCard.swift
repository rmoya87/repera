import ReperaDomain
import SwiftUI

/// Bloque «Esta sesión» al abrir la ficha desde un entreno terminado.
/// WOD de catálogo → marca global del benchmark; WOD libre / series → movimiento.
struct ExerciseThisSessionCard: View {
    @Environment(ReperaStore.self) private var store
    @Environment(SubscriptionManager.self) private var subscriptions
    let exerciseId: UUID
    let highlightSessionId: UUID
    var highlightExerciseInstanceId: UUID? = nil

    private var thisAppearance: ExerciseSessionAppearance? {
        guard let session = store.state.workouts.first(where: { $0.id == highlightSessionId }) else {
            return nil
        }
        // No mezclar las series de dos bloques diferentes que prescriben
        // el mismo ejercicio: la ficha abierta corresponde a la fila pulsada.
        var scopedSession = session
        if let highlightExerciseInstanceId {
            guard let selected = session.exercises.first(where: { $0.id == highlightExerciseInstanceId })
            else { return nil }
            scopedSession.exercises = [selected]
            // Evitar que el score de otro bloque WOD se cuele por el
            // fallback global del motor de estadísticas.
            scopedSession.wodResults = session.wodResults.filter {
                guard let blockId = selected.blockId else { return false }
                return $0.id == blockId
            }
        }
        return StatsEngine.appearance(
            of: exerciseId,
            in: scopedSession,
            catalog: store.state.exercises
        )
    }

    private var prior: ExerciseSessionAppearance? {
        StatsEngine.priorAppearances(
            of: exerciseId,
            workouts: store.state.workouts,
            catalog: store.state.exercises,
            excludingSessionId: highlightSessionId,
            limit: 1
        ).first
    }

    /// Only compare an explicitly RX/scaled result against the same exact
    /// prescription. Unknown scale and legacy sessions remain incomparable.
    private var verifiedWODComparison: WODComparison? {
        guard let currentSession = store.state.workouts.first(where: { $0.id == highlightSessionId }),
              let currentFinish = currentSession.finishedAt,
              let currentBlocks = currentSession.routineBlocks else { return nil }
        let blockId: UUID?
        if let highlightExerciseInstanceId {
            blockId = currentSession.exercises.first {
                $0.id == highlightExerciseInstanceId
            }?.blockId
        } else {
            blockId = currentSession.wodResults.count == 1
                ? currentSession.wodResults.first?.id : nil
        }
        guard let blockId,
              let currentBlock = currentBlocks.first(where: { $0.id == blockId }),
              let currentResult = currentSession.wodResults.first(where: { $0.id == blockId }),
              let currentRx = currentResult.isRx else { return nil }
        let current = WODComparisonContext(
            prescribed: currentBlock, result: currentResult, isRx: currentRx,
            scalingFingerprint: scalingFingerprint(in: currentSession, blockId: blockId)
        )
        let priorSessions = store.state.workouts
            .filter { $0.id != currentSession.id && $0.finishedAt != nil
                      && ($0.finishedAt ?? .distantPast) < currentFinish }
            .sorted { ($0.finishedAt ?? .distantPast) > ($1.finishedAt ?? .distantPast) }
        for prior in priorSessions {
            guard let priorBlocks = prior.routineBlocks else { continue }
            for priorResult in prior.wodResults {
                guard let priorRx = priorResult.isRx,
                      let block = priorBlocks.first(where: { $0.id == priorResult.id }) else {
                    continue
                }
                let before = WODComparisonContext(
                    prescribed: block, result: priorResult, isRx: priorRx,
                    scalingFingerprint: scalingFingerprint(in: prior, blockId: block.id)
                )
                if let comparison = WODComparisonEngine.compare(previous: before, current: current) {
                    return comparison
                }
            }
        }
        return nil
    }

    private func scalingFingerprint(in session: WorkoutSession, blockId: UUID) -> String? {
        let modifications = session.exercises.filter { $0.blockId == blockId }
            .compactMap { entry -> String? in
                guard entry.adaptedReps != nil || entry.adaptedWeightKg != nil else { return nil }
                // String.init as a function ref is ambiguous for Double? and can
                // collapse the whole View body into "Failed to produce diagnostic".
                let reps = entry.adaptedReps.map { String($0) } ?? ""
                let kg = entry.adaptedWeightKg.map { String($0) } ?? ""
                return "\(entry.exercise.id.uuidString)|\(reps)|\(kg)"
            }
        return modifications.isEmpty ? nil : modifications.joined(separator: ";")
    }

    var body: some View {
        if let thisAppearance {
            VStack(alignment: .leading, spacing: 8) {
                OGCardSectionTitle(title: sectionTitle(for: thisAppearance))
                OGCard {
                    VStack(alignment: .leading, spacing: 10) {
                        appearanceBlock(thisAppearance, emphasizeDate: true)

                        if subscriptions.isPro, let comparison = verifiedWODComparison {
                            Divider().opacity(0.35)
                            HStack(spacing: 8) {
                                Image(systemName: comparison.improvement > 0 ? "arrow.up.right" :
                                    (comparison.improvement < 0 ? "arrow.down.right" : "equal"))
                                    .foregroundStyle(OG.accent)
                                Text(comparison.improvement == 0 ? "Misma marca" :
                                     "\(comparison.improvement > 0 ? "+" : "")\(comparison.improvement) \(comparison.unit) frente al WOD comparable anterior")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(OG.label)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .accessibilityElement(children: .combine)
                        }

                        if let prior {
                            Divider().opacity(0.35)
                            Text(priorLabel(for: thisAppearance))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(OG.label3)
                                .tracking(0.3)
                            appearanceBlock(prior, emphasizeDate: false)
                        } else if thisAppearance.isGlobalWodScore {
                            Text("Sin intentos previos de este WOD para comparar.")
                                .font(.footnote)
                                .foregroundStyle(OG.label3)
                        } else if thisAppearance.setLines.isEmpty {
                            Text("Sin marcas previas de este movimiento para comparar.")
                                .font(.footnote)
                                .foregroundStyle(OG.label3)
                        }
                    }
                }
            }
        }
    }

    private func sectionTitle(for row: ExerciseSessionAppearance) -> String {
        if row.isGlobalWodScore, let name = row.wodTemplateName, !name.isEmpty {
            return "Esta sesión · \(name)"
        }
        return "Esta sesión"
    }

    private func priorLabel(for row: ExerciseSessionAppearance) -> String {
        row.isGlobalWodScore ? "Intento anterior" : "Anterior"
    }

    @ViewBuilder
    private func appearanceBlock(
        _ row: ExerciseSessionAppearance,
        emphasizeDate: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(row.date.formatted(date: .abbreviated, time: .omitted))
                    .font(emphasizeDate ? .subheadline.weight(.semibold) : .footnote.weight(.semibold))
                    .foregroundStyle(OG.label)
                Spacer(minLength: 8)
                if let score = row.wodScoreLabel {
                    Text(score)
                        .font(.system(size: 15, weight: .bold).monospacedDigit())
                        .foregroundStyle(OG.accent)
                }
            }
            if row.isGlobalWodScore {
                if let format = row.wodFormatName {
                    Text(format)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(OG.label3)
                }
            } else {
                if let format = row.wodFormatName {
                    Text(format)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(OG.label3)
                } else if !row.sessionTitle.isEmpty {
                    Text(row.sessionTitle)
                        .font(.caption)
                        .foregroundStyle(OG.label3)
                        .lineLimit(1)
                }
                if let prescription = row.prescriptionLine {
                    Text(prescription)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(OG.label)
                }
                ForEach(Array(row.setLines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.footnote)
                        .foregroundStyle(OG.label2)
                }
            }
        }
    }
}
