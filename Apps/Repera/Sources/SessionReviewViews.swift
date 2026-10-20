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

/// Card compacta: nota + nivel (subtítulo) + texto; tips al desplegar.
struct SessionReviewCard: View {
    var review: SessionReview
    var startsExpanded: Bool = false

    @State private var expanded = false

    private var hasDetails: Bool {
        !review.keepTips.isEmpty
            || !review.improveTips.isEmpty
            || !review.movements.isEmpty
    }

    /// Texto bajo la nota, sin repetir el nivel (ese va como subtítulo).
    private var blurb: String {
        var sentences: [String] = []
        if let standard = review.vsStandardSummary?.trimmingCharacters(in: .whitespacesAndNewlines),
           !standard.isEmpty {
            sentences.append(standard.hasSuffix(".") ? standard : standard + ".")
        }
        if let history = review.vsHistorySummary?.trimmingCharacters(in: .whitespacesAndNewlines),
           !history.isEmpty,
           standardOmits(history) {
            sentences.append(history.hasSuffix(".") ? history : history + ".")
        } else if sentences.isEmpty {
            if !review.movements.isEmpty {
                sentences.append("Según cómo te fueron los movimientos.")
            } else if review.scoreBasis != nil {
                sentences.append("Nota orientativa de esta sesión.")
            }
        }
        return sentences.joined(separator: " ")
    }

    private func standardOmits(_ history: String) -> Bool {
        guard let standard = review.vsStandardSummary else { return true }
        return !standard.contains(history) && !history.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RecoveryTrainingTip()
                .padding(.horizontal, 12)
                .padding(.top, 12)
            Button {
                guard hasDetails else { return }
                withAnimation(.snappy(duration: 0.22)) {
                    expanded.toggle()
                }
            } label: {
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(review.scoreLabel)
                            .font(.system(size: 28, weight: .semibold).monospacedDigit())
                            .foregroundStyle(OG.label)
                        if let level = review.levelLabel {
                            Text(level)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(OG.label2)
                        }
                    }
                    .frame(minWidth: 56, alignment: .leading)

                    Text(blurb)
                        .font(.system(size: 15))
                        .foregroundStyle(OG.label2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)

                    if hasDetails {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(OG.label3)
                            .rotationEffect(.degrees(expanded ? 180 : 0))
                            .padding(.top, 8)
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

                    Text("El nivel compara tu marca con referencias de catálogo, no con otros usuarios.")
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
