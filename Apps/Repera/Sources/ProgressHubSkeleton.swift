import SwiftUI

/// Placeholder estructural del hub Progreso mientras prepara el snapshot.
/// Misma jerarquía: héroe → glance 2×2 → insight de periodo (sin spinner «Cargando»).
struct ProgressHubSkeleton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            card {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        bone(width: 22, height: 22, radius: 6)
                        bone(width: 140, height: 13, radius: 4)
                        Spacer(minLength: 0)
                    }
                    bone(width: 96, height: 36, radius: 8)
                    bone(height: 11, radius: 4)
                    bone(width: 200, height: 11, radius: 4)
                    bone(height: 56, radius: 10)
                }
            }

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                ForEach(0..<4, id: \.self) { index in
                    glanceBone(titleWidth: [72, 88, 64, 80][index])
                }
            }

            card {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        bone(width: 20, height: 20, radius: 5)
                        bone(width: 120, height: 12, radius: 4)
                        Spacer(minLength: 0)
                    }
                    bone(width: 84, height: 28, radius: 6)
                    bone(height: 72, radius: 10)
                }
            }
        }
        .opacity(boneOpacity)
        .animation(
            reduceMotion
                ? nil
                : .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
            value: pulse
        )
        .onAppear {
            guard !reduceMotion else { return }
            pulse = true
        }
        .accessibilityLabel("Preparando progreso")
        .accessibilityAddTraits(.updatesFrequently)
    }

    private var boneOpacity: Double {
        if reduceMotion { return 0.72 }
        return pulse ? 0.92 : 0.48
    }

    private func glanceBone(titleWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            bone(width: titleWidth, height: 11, radius: 4)
            bone(width: 56, height: 22, radius: 5)
            bone(width: 44, height: 10, radius: 4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(14)
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
