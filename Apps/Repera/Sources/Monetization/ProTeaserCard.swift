import ReperaDomain
import SwiftUI

/// Banner Pro reutilizable: verde Repera, mascota y CTA, sin datos simulados.
/// Lo comparten Progreso, evolución de ejercicios y otros puntos de conversión.
struct ProTeaserCard: View {
    var title: String
    var bodyText: String
    var cta: String = "Ver con Repera Pro"
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 9) {
                    Text("REPERA PRO")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(Color.black.opacity(0.7))

                    Text(title)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)

                    Text(bodyText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 5) {
                        Text(cta)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 9)
                    .background(Color.black.opacity(0.1), in: Capsule())
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ReperaMascot(pose: .hero, maxHeight: 140)
                    .frame(width: 104)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [OG.accent, Color(red: 0.41, green: 0.91, blue: 0.53)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title). \(bodyText). \(cta)")
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
