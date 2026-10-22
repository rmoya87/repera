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
                Button("Listo", action: onDismiss)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(OG.accent)
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

/// Una única fuente de verdad para Inicio, Historial y fin de entreno.
/// Jamás vuelve a presentar puntuaciones históricas/heurísticas de la fórmula
/// anterior: un review sin indicadores verificables se considera no evaluado.
struct SessionReviewCard: View {
    let review: SessionReview
    var startsExpanded: Bool = false

    @State private var expanded = false

    private var isVerified: Bool {
        review.scoreBasis == .personalHistory
            && review.indicators.count == ReviewDimension.allCases.count
            && (review.evidenceCoverage ?? 0) >= 0.60
    }

    @ViewBuilder
    var body: some View {
        if isVerified {
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    withAnimation(.snappy(duration: 0.22)) { expanded.toggle() }
                } label: {
                    HStack(alignment: .center, spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("NOTA GLOBAL")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(OG.label3)
                            HStack(alignment: .firstTextBaseline, spacing: 3) {
                                Text("\(review.overallScore)")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                Text("/10")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(OG.label2)
                            }
                            .foregroundStyle(OG.label)
                        }
                        Spacer(minLength: 8)
                        VStack(alignment: .trailing, spacing: 5) {
                            Text("Confianza: \(review.confidenceLabel ?? "En construcción")")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(OG.label2)
                            if let coverage = review.evidenceCoverage {
                                Text("\(Int((coverage * 100).rounded()))% con referencias")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(OG.label3)
                            }
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(OG.label3)
                                .rotationEffect(.degrees(expanded ? 180 : 0))
                        }
                    }
                    .padding(16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Nota global \(review.overallScore) sobre 10, confianza \(review.confidenceLabel ?? "en construcción")")
                .accessibilityHint(expanded ? "Contraer desglose" : "Mostrar los tres indicadores")

                if expanded {
                    VStack(spacing: 8) {
                        ForEach(review.indicators, id: \.dimension) { indicator in
                            indicatorRow(indicator)
                        }

                        Text("Solo se puntúa el rendimiento con al menos dos sesiones anteriores comparables. Las series registradas no aportan puntos; la nota no mide técnica ni esfuerzo percibido.")
                            .font(.system(size: 11))
                            .foregroundStyle(OG.label3)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 5)
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
            .onAppear { if startsExpanded { expanded = true } }
        }
    }

    private func indicatorRow(_ indicator: ReviewIndicator) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: indicator.dimension.symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(OG.accent)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(indicator.dimension.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(OG.label)
                if indicator.score != nil, let tier = indicator.comparisonLevel {
                    Text(tier == 1 ? "Nivel 1 · Referencia idéntica"
                         : tier == 2 ? "Nivel 2 · Mismo ejercicio"
                         : "Nivel 3 · Estímulo comparable")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(tier == 3 ? OG.label3 : OG.accent)
                }
                Text(indicator.detail)
                    .font(.system(size: 12))
                    .foregroundStyle(OG.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            if let score = indicator.score {
                Text("\(score)/10")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(OG.label)
            } else {
                Text(indicator.dimension == .adherence ? "Registro" : "Sin referencia")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(OG.label3)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
