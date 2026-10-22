import ReperaDomain
import SwiftUI

/// Banner Repera Pro con las ilustraciones ORIGINALES del catálogo de la app.
/// Los motivos (pesas, movimiento, descanso y evolución) se componen en SwiftUI
/// sin regenerar el personaje ni alterar el alfa de su piel, ojos, cinta o accesorios.
struct ProTeaserCard: View {
    enum Appearance {
        case progress
        case activity
        case recovery
        case evolution

        var imageOnLeft: Bool { self == .activity }

        var pose: ReperaMascotPose {
            switch self {
            case .progress: .hero
            case .activity: .watch
            case .recovery: .welcome
            case .evolution: .permissions
            }
        }
    }

    var title: String
    var bodyText: String
    var cta: String = "Ver con Repera Pro"
    var appearance: Appearance = .evolution
    var action: () -> Void

    /// Ilustración grande que aprovecha la altura de la tarjeta, con escena
    /// independiente por funcionalidad. Los símbolos solo decoran su exterior.
    @ViewBuilder
    private var mascotScene: some View {
        ZStack {
            switch appearance {
            case .progress:
                ReperaMascot(pose: appearance.pose, maxHeight: 214)
                    .frame(width: 198, height: 198)
                    .rotationEffect(.degrees(-7))
                    .offset(x: 25, y: 17)
            case .activity:
                Image(systemName: "wind")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .offset(x: -51, y: -5)
                ReperaMascot(pose: appearance.pose, maxHeight: 209)
                    .frame(width: 197, height: 197)
                    .rotationEffect(.degrees(-17), anchor: .bottom)
                    .offset(x: -14, y: 24)
                Image(systemName: "figure.run")
                    .font(.system(size: 25, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .offset(x: -48, y: -62)
            case .recovery:
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .fill(Color.white.opacity(0.82))
                    .frame(width: 152, height: 39)
                    .rotationEffect(.degrees(-10))
                    .offset(x: 10, y: 65)
                ReperaMascot(pose: appearance.pose, maxHeight: 194)
                    .frame(width: 187, height: 187)
                    .rotationEffect(.degrees(-63))
                    .offset(x: 26, y: 22)
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 33, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.95))
                    .offset(x: -54, y: -72)
            case .evolution:
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 69, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.37))
                    .offset(x: 22, y: -44)
                ReperaMascot(pose: appearance.pose, maxHeight: 208)
                    .frame(width: 197, height: 197)
                    .rotationEffect(.degrees(5))
                    .offset(x: 24, y: 21)
            }
        }
        .frame(width: 148, height: 210)
        .clipped() // La mascota puede ser grande, sin tapar textos ni CTA.
        .accessibilityHidden(true)
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 4) {
                if appearance.imageOnLeft {
                    mascotScene
                }

                VStack(alignment: .leading, spacing: 9) {
                    Text("REPERA PRO")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(Color.black.opacity(0.7))

                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)

                    Text(bodyText)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 5) {
                        Text(cta)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 9)
                    .background(Color.white.opacity(0.83), in: Capsule())
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !appearance.imageOnLeft {
                    mascotScene
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 228, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [OG.accent, Color(red: 0.41, green: 0.91, blue: 0.53)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
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
                cta: "Ver con Repera Pro",
                appearance: .evolution
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
