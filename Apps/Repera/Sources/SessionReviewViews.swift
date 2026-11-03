import ReperaDomain
import SwiftUI

/// Resultado al terminar; si no existe un histórico mínimo no hay nota ni
/// sheet. Las marcas y series siguen disponibles normalmente en Historial.
struct SessionReviewSheet: View {
    var review: SessionReview
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Tu rendimiento")
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(OG.label)
                Spacer()
                OGDoneCheckButton(action: onDismiss)
            }
            SessionReviewCard(review: review, startsExpanded: true)
        }
        .padding(.horizontal, OG.pad)
        .padding(.top, 28)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.bg)
        .ogFittedHeight()
        .ogFittedSheet()
    }
}

/// Anillo y métricas siempre visibles, con la misma jerarquía que Recuperación.
/// No hay «Ver cómo se calcula»: las fuentes y su confianza son parte de la tarjeta.
struct SessionReviewCard: View {
    let review: SessionReview
    /// Conservado por compatibilidad con la hoja post-entreno.
    var startsExpanded: Bool = false

    private var isVerified: Bool {
        review.scoreBasis == .personalHistory
            && (review.indicators.count == ReviewDimension.allCases.count
                || (review.indicators.isEmpty && review.vsHistorySummary != nil))
            && (review.evidenceCoverage ?? 0) >= 0.60
    }

    private var evolutionScore: Int? {
        review.indicators.first(where: { $0.dimension == .personalProgress })?.score
            ?? (review.indicators.isEmpty ? review.overallScore : nil)
    }

    private var performanceScore: Int {
        // Un WOD usa su componente verificado; fuerza, GPS y las sesiones
        // comparables sin WOD usan la nota personal global. No se fabrica
        // puntuación para temporizadores sin mediciones deportivas.
        review.indicators.first(where: { $0.dimension == .wodPerformance })?.score
            ?? review.indicators.first(where: { $0.dimension == .personalProgress })?.score
            ?? review.overallScore
    }

    @ViewBuilder
    var body: some View {
        if isVerified {
            VStack(alignment: .leading, spacing: 13) {
                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 9) {
                        metric("Evolución personal", value: evolutionScore.map { "\($0)/10" } ?? "—")
                        metric("Rendimiento", value: "\(performanceScore)/10")
                        if let coverage = review.evidenceCoverage {
                            metric("Cobertura", value: "\(Int((coverage * 100).rounded())) %")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    ZStack {
                        Circle().stroke(OG.surface3, lineWidth: 10)
                        Circle()
                            .trim(from: 0, to: Double(review.overallScore) / 10)
                            .stroke(OG.accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 1) {
                            Text("\(review.overallScore)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(OG.label)
                            Text("de 10")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(OG.label2)
                        }
                    }
                    .frame(width: 112, height: 112)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Puntuación global de rendimiento \(review.overallScore) de 10")
                }
                TrainingScoreConfidenceBar(label: review.confidenceLabel)
                if let summary = review.vsHistorySummary, !summary.isEmpty {
                    Text(summary)
                        .font(.system(size: 11))
                        .foregroundStyle(OG.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
        }
    }

    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(OG.label2)
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(OG.label)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Cuatro tramos semánticos: aprendiendo no equivale a «baja confianza».
/// Solo el tramo observado destaca; el resto mantiene el color atenuado.
struct TrainingScoreConfidenceBar: View {
    let label: String?
    var caption: String = "Confianza"

    private enum Level: CaseIterable {
        case learning, low, medium, high

        var title: String {
            switch self {
            case .learning: "Aprendiendo"
            case .low: "Baja"
            case .medium: "Media"
            case .high: "Alta"
            }
        }

        var color: Color {
            switch self {
            case .learning: OG.label3
            case .low: OG.red
            case .medium: OG.yellow
            case .high: OG.accent
            }
        }
    }

    private var currentLevel: Level {
        let text = (label ?? "").lowercased()
        if text.contains("alta") { return .high }
        if text.contains("media") { return .medium }
        if text.contains("baja") { return .low }
        return .learning
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(caption)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(OG.label2)
            HStack(spacing: 4) {
                ForEach(Level.allCases, id: \.self) { level in
                    let selected = level == currentLevel
                    Text(level.title)
                        .font(.system(size: 10, weight: selected ? .bold : .medium))
                        .foregroundStyle(selected
                            ? (level == .learning ? OG.label : Color.black)
                            : OG.label2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, minHeight: 28)
                        .background(
                            selected ? level.color : level.color.opacity(0.18),
                            in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(selected ? OG.label.opacity(0.45) : .clear, lineWidth: 1)
                        }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(caption): \(label ?? "En construcción")")
    }
}
