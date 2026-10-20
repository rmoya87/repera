import ReperaDomain
import SwiftUI

/// Sheet tras terminar / apuntar un entreno.
struct SessionReviewSheet: View {
    var review: SessionReview
    var onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                SessionReviewCard(review: review)
                    .padding(.horizontal, OG.pad)
                    .padding(.bottom, 28)
            }
            .background(OG.bg)
            .navigationTitle("Resultado")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo", action: onDismiss)
                        .fontWeight(.semibold)
                }
            }
        }
        .ogSheetChrome(detents: [.medium, .large])
    }
}

/// Card compacta: nota + texto; tips y ejercicios al desplegar.
struct SessionReviewCard: View {
    var review: SessionReview
    var startsExpanded: Bool = false

    @State private var expanded = false

    private var hasDetails: Bool {
        !review.keepTips.isEmpty
            || !review.improveTips.isEmpty
            || !review.movements.isEmpty
    }

    /// Texto corto: nivel + en qué se basa (esperado vs tú / tu historial), sin jerga técnica.
    private var blurb: String {
        var parts: [String] = []
        if let level = review.levelLabel {
            parts.append(level)
        }
        if let standard = review.vsStandardSummary {
            parts.append(standard.replacingOccurrences(of: "Referencia ", with: ""))
        }
        if let history = review.vsHistorySummary {
            // Evitar duplicar si el estándar ya lo incluye.
            if standardOmits(history) {
                parts.append(history)
            }
        } else if parts.count <= 1 {
            if let basis = review.scoreBasis {
                parts.append(basis.blurbLabel)
            } else if !review.movements.isEmpty {
                parts.append("Según movimientos de la sesión.")
            } else {
                parts.append("Valoración de la sesión.")
            }
        }
        return parts.joined(separator: " · ")
    }

    private func standardOmits(_ history: String) -> Bool {
        guard let standard = review.vsStandardSummary else { return true }
        return !standard.contains(history) && !history.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                guard hasDetails else { return }
                withAnimation(.snappy(duration: 0.22)) {
                    expanded.toggle()
                }
            } label: {
                HStack(alignment: .center, spacing: 14) {
                    Text(review.scoreLabel)
                        .font(.system(size: 28, weight: .semibold).monospacedDigit())
                        .foregroundStyle(OG.label)
                        .frame(minWidth: 56, alignment: .leading)

                    Text(blurb)
                        .font(.system(size: 15))
                        .foregroundStyle(OG.label2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if hasDetails {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(OG.label3)
                            .rotationEffect(.degrees(expanded ? 180 : 0))
                    }
                }
                .padding(14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!hasDetails)
            .accessibilityLabel("Resultado \(review.scoreLabel)")
            .accessibilityHint(hasDetails ? (expanded ? "Ocultar detalle" : "Mostrar detalle") : "")

            if expanded {
                VStack(alignment: .leading, spacing: 14) {
                    Divider().overlay(OG.surface3)

                    if !review.keepTips.isEmpty {
                        tipGroup(title: "Mantener", tips: review.keepTips)
                    }
                    if !review.improveTips.isEmpty {
                        tipGroup(title: "Mejorar", tips: review.improveTips)
                    }

                    if !review.movements.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ejercicios")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(OG.label3)
                            ForEach(review.movements) { movement in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(movement.name) · \(movement.verdict.label)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(OG.label)
                                    Text(movement.detail)
                                        .font(.system(size: 13))
                                        .foregroundStyle(OG.label2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    Text("Niveles según bandas de catálogo, no ranking de usuarios.")
                        .font(.system(size: 11))
                        .foregroundStyle(OG.label3)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
        .onAppear {
            if startsExpanded { expanded = true }
        }
    }

    private func tipGroup(title: String, tips: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(OG.label3)
            ForEach(Array(tips.enumerated()), id: \.offset) { _, tip in
                Text(tip)
                    .font(.system(size: 14))
                    .foregroundStyle(OG.label)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
