import ReperaDomain
import SwiftUI

/// Tarjeta discreta Pro (candado + CTA). No simula datos premium.
struct ProTeaserCard: View {
    var title: String
    var bodyText: String
    var cta: String = "Ver con Repera Pro"
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            OGCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(OG.accent)
                            .accessibilityHidden(true)
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(OG.label)
                    }
                    Text(bodyText)
                        .font(.subheadline)
                        .foregroundStyle(OG.label2)
                        .multilineTextAlignment(.leading)
                    Text(cta)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(OG.accent)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title). \(cta)")
    }
}

/// Última sesión + récord + teaser de evolución (Gratis). Sin gráfica ni historial completo.
struct FreeExerciseSummaryCard: View {
    @Environment(ReperaStore.self) private var store
    @Environment(SubscriptionManager.self) private var subscriptions
    let exerciseId: UUID
    var highlightSessionId: UUID? = nil

    private var history: ExerciseHistorySummary {
        store.cachedHistory(for: exerciseId)
    }

    private var lastSession: ExerciseLastSession? {
        store.cachedLastWorkingSession(for: exerciseId)
    }

    /// Si venimos de un entreno, la «última» no debe repetir «Esta sesión».
    private var lastSessionForSummary: ExerciseLastSession? {
        guard let last = lastSession else { return nil }
        if let highlightSessionId, last.sessionId == highlightSessionId {
            return nil
        }
        return last
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !history.hasData, highlightSessionId == nil {
                OGCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sin registros aún")
                            .font(.headline)
                            .foregroundStyle(OG.label)
                        Text("Cuando apuntes series de este ejercicio, verás aquí tu última sesión y tu récord.")
                            .font(.footnote)
                            .foregroundStyle(OG.label2)
                    }
                }
            } else if history.hasData {
                if lastSessionForSummary != nil {
                    lastSessionBlock
                }
                personalRecordBlock
            }

            ProTeaserCard(
                title: "Tu evolución",
                bodyText: "Consulta todas tus marcas, compara tus entrenamientos y descubre cómo has progresado con este ejercicio.",
                cta: "Ver con Repera Pro"
            ) {
                subscriptions.presentPaywall(.exerciseEvolution, feature: .exerciseEvolution)
            }
        }
    }

    @ViewBuilder
    private var lastSessionBlock: some View {
        if let last = lastSessionForSummary {
            VStack(alignment: .leading, spacing: 8) {
                OGCardSectionTitle(title: "Última sesión")
                OGCard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(last.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(OG.label)
                            .padding(.bottom, 4)
                        ForEach(Array(last.sets.enumerated()), id: \.element.id) { index, set in
                            let isMachine = set.quantityUnit == .calories || set.quantityUnit == .meters
                            OGExerciseSetRow(
                                index: index,
                                summaryLine: set.line,
                                rir: set.rir,
                                showsRIR: !isMachine
                            )
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var personalRecordBlock: some View {
        let h = history
        if h.maxWeightKg != nil || h.estimatedOneRM != nil || h.bestReps != nil {
            OGCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Récord personal")
                            .font(.footnote)
                            .foregroundStyle(OG.label2)
                        if let kg = h.maxWeightKg {
                            Text("\(formatKg(kg)) kg")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(OG.label)
                        } else if let reps = h.bestReps {
                            Text("\(reps) reps")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(OG.label)
                        }
                    }
                    Spacer()
                    if let e1 = h.estimatedOneRM {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("e1RM")
                                .font(.footnote)
                                .foregroundStyle(OG.label2)
                            Text("\(formatKg(e1)) kg")
                                .font(.headline)
                                .foregroundStyle(OG.accent)
                        }
                    }
                }
            }
        }
    }

    private func formatKg(_ kg: Double) -> String {
        kg.formatted(.number.precision(.fractionLength(0...1)))
    }
}
