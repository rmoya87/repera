import SwiftUI

/// Placeholder estructural del resumen de sesión mientras hidrata Salud/clima.
/// Misma jerarquía que el detalle real (fecha → tiles → review → mapa/métricas → ejercicios).
struct SessionDetailSkeleton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Subtítulo de fecha (ogSessionDateListRow).
                bone(width: 210, height: 13, radius: 5)
                    .padding(.top, 2)

                // Fila de 3 tiles (altura real ~73 + padding).
                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { _ in
                        tileBone
                    }
                }

                // Review / insight card.
                card {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            bone(width: 22, height: 22, radius: 6)
                            bone(width: 128, height: 12, radius: 4)
                            Spacer(minLength: 0)
                        }
                        bone(width: 72, height: 28, radius: 6)
                        bone(height: 10, radius: 4)
                        bone(width: 180, height: 10, radius: 4)
                    }
                }

                // Mapa / métricas cardio (altura tipica de preview).
                card(padding: 0) {
                    VStack(spacing: 0) {
                        bone(height: 180, radius: 0)
                            .clipShape(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: OG.radiusCard,
                                    bottomLeadingRadius: 0,
                                    bottomTrailingRadius: 0,
                                    topTrailingRadius: OG.radiusCard,
                                    style: .continuous
                                )
                            )
                        HStack(spacing: 12) {
                            metricChipBone
                            metricChipBone
                            metricChipBone
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                    }
                }

                // Lista de ejercicios (thumb 44 + título + series).
                card(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(0..<4, id: \.self) { index in
                            if index > 0 {
                                Divider().opacity(0.35)
                            }
                            exerciseRowBone(titleWidth: [148, 120, 162, 110][index])
                        }
                    }
                }
            }
            .padding(.horizontal, OG.pad)
            .padding(.bottom, 28)
            .opacity(boneOpacity)
            .animation(
                reduceMotion
                    ? nil
                    : .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                value: pulse
            )
        }
        .scrollDisabled(true)
        .background(OG.bg)
        .onAppear {
            guard !reduceMotion else { return }
            pulse = true
        }
        .accessibilityLabel("Cargando resumen del entrenamiento")
        .accessibilityAddTraits(.updatesFrequently)
    }

    private var boneOpacity: Double {
        if reduceMotion { return 0.72 }
        return pulse ? 0.92 : 0.48
    }

    private var tileBone: some View {
        VStack(alignment: .center, spacing: 6) {
            HStack(spacing: 6) {
                bone(width: 14, height: 14, radius: 3)
                bone(width: 40, height: 11, radius: 4)
            }
            bone(width: 52, height: 22, radius: 5)
            bone(width: 36, height: 10, radius: 4)
        }
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .frame(height: 73)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }

    private var metricChipBone: some View {
        VStack(alignment: .leading, spacing: 6) {
            bone(width: 44, height: 10, radius: 4)
            bone(width: 36, height: 16, radius: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func exerciseRowBone(titleWidth: CGFloat) -> some View {
        HStack(spacing: 12) {
            bone(width: 44, height: 44, radius: 10)
            VStack(alignment: .leading, spacing: 8) {
                bone(width: titleWidth, height: 13, radius: 4)
                bone(width: titleWidth * 0.62, height: 10, radius: 4)
            }
            Spacer(minLength: 0)
            bone(width: 10, height: 16, radius: 3)
                .opacity(0.55)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func card<Content: View>(
        padding: CGFloat = 14,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }

    private func bone(width: CGFloat? = nil, height: CGFloat, radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(OG.surface2)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }
}
