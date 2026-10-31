import ReperaDomain
import SwiftUI
import WatchKit

/// Home estilo Deportes: plan → recientes → catálogo.
/// Mute abajo izq., temporizador abajo der.; tocar el centro inicia.
struct WatchHomeHubView: View {
    @Environment(WatchSessionHub.self) private var hub
    @Binding var showTimer: Bool
    var onPlayPlan: () -> Void
    var onPlaySport: (WatchLiveSport) -> Void

    @State private var crownValue = 0.0
    @FocusState private var crownFocused: Bool

    private let accent = Color(red: 48 / 255, green: 209 / 255, blue: 88 / 255)

    private var items: [WatchHubItem] {
        hub.hubCarouselItems
    }

    private var selectedIndex: Int {
        hub.resolvedHubCarouselIndex()
    }

    private var selected: WatchHubItem? {
        guard !items.isEmpty else { return nil }
        return items[selectedIndex]
    }

    var body: some View {
        ZStack {
            // Centro: tap = Play (deja márgenes para no tapar las esquinas).
            Button {
                playSelected()
            } label: {
                VStack(spacing: 6) {
                    Spacer(minLength: 0)
                    if let selected {
                        Image(systemName: selected.symbolName)
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(accent)
                            .accessibilityHidden(true)
                        Text(selected.title)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.65)
                            .lineLimit(2)
                            .padding(.horizontal, 28)
                    } else {
                        ProgressView()
                        Text("Cargando…")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 36)
                .padding(.bottom, 40)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(selected == nil)
            .accessibilityLabel(selected.map { "Comenzar \($0.title)" } ?? "Comenzar")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottomLeading) {
            cornerCircleButton(
                systemName: hub.audioMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                label: hub.audioMuted ? "Activar audio" : "Silenciar audio"
            ) {
                hub.toggleAudioMuted()
            }
            .padding(.leading, 2)
            .padding(.bottom, 2)
        }
        .overlay(alignment: .bottomTrailing) {
            cornerCircleButton(systemName: "timer", label: "Temporizador") {
                showTimer = true
            }
            .padding(.trailing, 2)
            .padding(.bottom, 2)
        }
        .focusable(true)
        .focused($crownFocused)
        .digitalCrownRotation(
            $crownValue,
            from: 0,
            through: Double(max(0, items.count - 1)),
            by: 1,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .onAppear {
            crownFocused = true
            syncCrown()
        }
        .onChange(of: crownValue) { _, value in
            let next = Int(value.rounded())
            let clamped = min(max(0, next), max(0, items.count - 1))
            if clamped != selectedIndex {
                hub.setHubCarouselIndex(clamped)
            }
        }
        .onChange(of: items.count) { _, _ in
            syncCrown()
        }
    }

    private func cornerCircleButton(
        systemName: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 36, height: 36)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel(label)
    }

    private func syncCrown() {
        let index = hub.resolvedHubCarouselIndex()
        hub.setHubCarouselIndex(index)
        crownValue = Double(index)
    }

    private func playSelected() {
        guard let selected else { return }
        hub.setHubCarouselIndex(selectedIndex)
        switch selected {
        case .plan:
            onPlayPlan()
        case .sport(let sport):
            onPlaySport(sport)
        }
    }
}
