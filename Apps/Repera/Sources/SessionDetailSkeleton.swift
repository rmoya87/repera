import SwiftUI

/// Placeholder estructural del resumen de sesión mientras hidrata Salud/clima.
/// Evita pintar ejercicios primero y cardio después (reflow).
struct SessionDetailSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(OG.surface2)
                    .frame(width: 160, height: 14)
                    .padding(.top, 4)

                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: 8) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(OG.surface2)
                                .frame(width: 36, height: 12)
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(OG.surface2)
                                .frame(height: 28)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
                    }
                }

                RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous)
                    .fill(OG.surface)
                    .frame(height: 120)
                    .overlay {
                        VStack(alignment: .leading, spacing: 10) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(OG.surface2)
                                .frame(width: 120, height: 12)
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(OG.surface2)
                                .frame(height: 56)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                ForEach(0..<4, id: \.self) { _ in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(OG.surface2)
                            .frame(width: 56, height: 56)
                        VStack(alignment: .leading, spacing: 8) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(OG.surface2)
                                .frame(width: 140, height: 12)
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(OG.surface2)
                                .frame(width: 90, height: 10)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
                }
            }
            .padding(.horizontal, OG.pad)
            .padding(.bottom, 24)
            .opacity(0.85)
        }
        .scrollDisabled(true)
        .background(OG.bg)
        .accessibilityLabel("Cargando resumen del entrenamiento")
        .accessibilityAddTraits(.updatesFrequently)
    }
}
