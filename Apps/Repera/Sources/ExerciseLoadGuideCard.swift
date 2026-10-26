import ReperaDomain
import SwiftUI

/// Guía compacta en el editor de series: última sesión + carga sugerida para el RIR objetivo.
struct ExerciseLoadGuideCard: View {
    @Environment(ReperaStore.self) private var store

    let exerciseId: UUID
    /// Serie de referencia (normalmente la 1ª del plan).
    var targetReps: Int
    var targetRir: Double?
    var onApplySuggestedKg: (Double) -> Void
    var onApplyLastSession: ((ExerciseLastSession) -> Void)? = nil

    private var history: ExerciseHistorySummary {
        store.cachedHistory(for: exerciseId)
    }

    private var lastSession: ExerciseLastSession? {
        store.cachedLastWorkingSession(for: exerciseId)
    }

    private var loadPref: ExerciseLoadPreference {
        store.loadPreference(for: exerciseId)
    }

    private var increment: Double {
        store.state.settings.weightIncrementKg
    }

    private var effectiveRir: Double {
        targetRir ?? 2
    }

    private var assumedRir: Bool {
        targetRir == nil
    }

    private var suggestion: (kg: Double, source: String)? {
        let reps = max(1, targetReps)
        let tested = loadPref.testedOneRMKg.flatMap { $0 > 0 ? $0 : nil }
        let estimated = history.estimatedOneRM.flatMap { $0 > 0 ? $0 : nil }
        if let oneRM = tested ?? estimated {
            let kg = LoadSuggestion.weightKg(
                oneRM: oneRM,
                reps: reps,
                targetRir: effectiveRir,
                roundTo: increment
            )
            guard kg > 0 else { return nil }
            return (kg, tested != nil ? "1RM" : "e1RM")
        }
        if let last = lastSession?.topSet ?? lastSession?.sets.last,
           let w = last.weightKg, w > 0 {
            let kg = LoadSuggestion.weightKgFromLastSet(
                lastWeightKg: w,
                lastReps: last.reps,
                lastRir: last.rir,
                targetReps: reps,
                targetRir: effectiveRir,
                roundTo: increment
            )
            guard kg > 0 else { return nil }
            return (kg, "última")
        }
        return nil
    }

    var body: some View {
        let last = lastSession
        let suggest = suggestion
        // Sin card propia: el Form ya pone `OG.surface` a ancho de lista (igual que Objetivos).
        Group {
            if last == nil && suggest == nil {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    if let last {
                        lastSessionBlock(last)
                    }
                    if let suggest {
                        if last != nil {
                            Divider().overlay(OG.surface3)
                        }
                        suggestionBlock(suggest)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(OG.accent)
            VStack(alignment: .leading, spacing: 4) {
                Text("Sin historial aún")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(OG.label)
                Text("Tras la primera vez verás aquí pesos y una sugerencia para tu RIR.")
                    .font(.system(size: 13))
                    .foregroundStyle(OG.label2)
            }
        }
    }

    private func lastSessionBlock(_ last: ExerciseLastSession) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("ÚLTIMA VEZ")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(OG.label3)
                Spacer(minLength: 8)
                Text(SpanishDate.short(last.date))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(OG.label2)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(last.sets.enumerated()), id: \.element.id) { index, set in
                    let isTop = set.id == last.topSet?.id
                    HStack(spacing: 10) {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .bold).monospacedDigit())
                            .foregroundStyle(isTop ? OG.onAccent : OG.label3)
                            .frame(width: 22, height: 22)
                            .background(
                                (isTop ? OG.accent : OG.surface2),
                                in: Circle()
                            )
                        Text(set.line)
                            .font(.system(size: 16, weight: isTop ? .semibold : .regular).monospacedDigit())
                            .foregroundStyle(isTop ? OG.label : OG.label2)
                        Spacer(minLength: 0)
                        if isTop {
                            Text("TOP")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(OG.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(OG.accent.opacity(0.15), in: Capsule())
                        }
                    }
                }
            }

            if let onApplyLastSession {
                Button {
                    onApplyLastSession(last)
                } label: {
                    Text("Copiar última sesión")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(OG.label)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(OG.surface2, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func suggestionBlock(_ suggest: (kg: Double, source: String)) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CARGA SUGERIDA")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(OG.label3)

            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(ReperaNumberFormat.decimal(suggest.kg)) kg")
                        .font(.system(size: 36, weight: .bold).monospacedDigit())
                        .foregroundStyle(OG.accent)
                        .contentTransition(.numericText())
                    Text(suggestionCaption(source: suggest.source))
                        .font(.system(size: 12))
                        .foregroundStyle(OG.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Button {
                    onApplySuggestedKg(suggest.kg)
                } label: {
                    Text("Aplicar")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(OG.onAccent)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(OG.accent, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Aplicar \(ReperaNumberFormat.decimal(suggest.kg)) kg a las series")
            }
        }
    }

    private func suggestionCaption(source: String) -> String {
        let rirLabel = assumedRir
            ? "RIR \(ReperaNumberFormat.decimal(effectiveRir)) (asumido)"
            : "RIR \(ReperaNumberFormat.decimal(effectiveRir))"
        return "\(targetReps) reps · \(rirLabel) · \(source)"
    }
}
