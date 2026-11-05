import SwiftUI

/// Selector de modo al tocar un plan en el hub.
/// No usar `.confirmationDialog` en watchOS: Liquid Glass traga toques
/// (misma lección que `WatchActivityCancelOverlay`).
struct WatchPlanModeOverlay: View {
    let planTitle: String
    var onLive: () -> Void
    var onRecord: () -> Void
    var onCancel: () -> Void

    private var accent: Color { WatchTheme.accent }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(.container, edges: .all)

            VStack(spacing: 10) {
                Text("Iniciar plan")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(planTitle)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Button(action: onLive) {
                    Text("Entreno guiado")
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(accent)
                .foregroundStyle(.black)

                Button(action: onRecord) {
                    Text("Entreno libre")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 40)
                }
                .buttonStyle(.bordered)
                .tint(.white)

                Button("Cancelar", action: onCancel)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 10)
        }
        .accessibilityElement(children: .contain)
    }
}
