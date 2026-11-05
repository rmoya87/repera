import ReperaDomain
import SwiftUI
import WatchKit

/// Home estilo Deportes: plan → recientes → catálogo.
/// Mute abajo izq., temporizador abajo der.; tocar el centro inicia.
struct WatchHomeHubView: View {
    @Environment(WatchSessionHub.self) private var hub
    @Binding var showTimer: Bool
    var onPlayPlan: () -> Void
    var onRecordPlan: () -> Void
    var onPlaySport: (WatchLiveSport) -> Void

    @State private var crownValue = 0.0
    @State private var pendingPlan: WorkoutSession?
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
        ZStack(alignment: .bottom) {
            // La actividad solo ocupa el área central: no puede interceptar
            // los toques de los controles fijos del borde inferior.
            Button {
                guard let selected else { return }
                switch selected {
                case .plan(let plan):
                    // Overlay opaco propio: confirmationDialog en watchOS
                    // no registra toques de forma fiable (Liquid Glass).
                    pendingPlan = plan
                case .sport:
                    playSelected()
                }
            } label: {
                VStack(spacing: 6) {
                    Spacer(minLength: 0)
                    if let selected {
                        Image(systemName: selected.symbolName)
                            .font(.system(size: 39, weight: .semibold))
                            .foregroundStyle(accent)
                            .accessibilityHidden(true)
                        Text(selected.title)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.68)
                            .lineLimit(2)
                            .padding(.horizontal, 22)
                    } else {
                        ProgressView()
                        Text("Cargando…")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 30)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(selected == nil || pendingPlan != nil)
            .accessibilityLabel(selected.map { "Comenzar \($0.title)" } ?? "Comenzar")
            // Zona reservada para dos botones de 44 pt y el bisel redondeado.
            .padding(.bottom, 58)

            HStack {
                cornerCircleButton(
                    systemName: hub.audioMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                    label: hub.audioMuted ? "Activar audio" : "Silenciar audio"
                ) {
                    hub.toggleAudioMuted()
                }

                Spacer(minLength: 0)

                cornerCircleButton(systemName: "timer", label: "Temporizador") {
                    showTimer = true
                }
            }
            .padding(.horizontal, 12)
            // Mantener los controles junto al bisel físico.
            .offset(y: 10)
            // Sonido y Temporizador siempre tienen prioridad de pulsación.
            .zIndex(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.container, edges: .bottom)
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
        .overlay {
            if let plan = pendingPlan {
                WatchPlanModeOverlay(
                    planTitle: plan.title,
                    onLive: {
                        pendingPlan = nil
                        startPlan(plan, recordOnly: false)
                    },
                    onRecord: {
                        pendingPlan = nil
                        startPlan(plan, recordOnly: true)
                    },
                    onCancel: { pendingPlan = nil }
                )
            }
        }
    }

    private func startPlan(_ plan: WorkoutSession, recordOnly: Bool) {
        hub.setHubCarouselIndex(selectedIndex)
        hub.selectTodayPlan(plan)
        if recordOnly {
            onRecordPlan()
        } else {
            onPlayPlan()
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
                .frame(width: 44, height: 44)
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
        case .plan(let plan):
            startPlan(plan, recordOnly: false)
        case .sport(let sport):
            onPlaySport(sport)
        }
    }
}

/// Selector de modo al tocar un plan en el hub.
/// Vive en este archivo (no un .swift suelto) para que un `.xcodeproj`
/// sin regenerar no pierda el símbolo. No usar `.confirmationDialog`.
private struct WatchPlanModeOverlay: View {
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
