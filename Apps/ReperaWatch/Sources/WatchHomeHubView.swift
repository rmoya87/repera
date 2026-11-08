import ReperaDomain
import SwiftUI
import WatchKit

/// Home estilo Deportes: plan → recientes → catálogo.
/// Mute abajo izq., temporizador abajo der.; tocar el centro inicia.
struct WatchHomeHubView: View {
    @Environment(WatchSessionHub.self) private var hub
    @Binding var showTimer: Bool
    /// Elige modo (guiado/libre) fuera de esta vista: el overlay vive en
    /// `WatchSessionView` para no destruirse al mutar el hub al arrancar.
    var onRequestPlanMode: (WorkoutSession) -> Void
    var onPlaySport: (WatchLiveSport) -> Void
    /// True mientras el selector de modo está visible (bloquea toques del hub).
    var planModePickerVisible: Bool = false

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
        ZStack(alignment: .bottom) {
            // La actividad solo ocupa el área central: no puede interceptar
            // los toques de los controles fijos del borde inferior.
            Button {
                guard let selected else { return }
                switch selected {
                case .plan(let plan):
                    // Overlay en WatchSessionView (no aquí): si el selector
                    // vive en el hub, al arrancar se desmonta a mitad del toque.
                    crownFocused = false
                    onRequestPlanMode(plan)
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
            .disabled(selected == nil || planModePickerVisible)
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
            // Subir los círculos sobre el bisel redondo: un offset positivo
            // hacia abajo los cortaba a medias (glass incompleto).
            .padding(.bottom, 8)
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
            crownFocused = false
            onRequestPlanMode(plan)
        case .sport(let sport):
            onPlaySport(sport)
        }
    }
}

/// Selector de modo al tocar un plan en el hub.
/// Mismo patrón que `WatchActivityCancelOverlay`: fondo opaco + botones plain
/// Cuenta atrás 3-2-1 a pantalla completa; toque = saltar e iniciar.
struct WatchStartCountdownOverlay: View {
    let remaining: Int
    var onSkip: () -> Void

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(.container, edges: .all)
                .contentShape(Rectangle())
                .onTapGesture(perform: onSkip)

            Text("\(max(remaining, 1))")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .ignoresSafeArea(.container, edges: .all)
        .accessibilityLabel("Cuenta atrás \(max(remaining, 1))")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Toca para empezar ya")
        .accessibilityAction(named: "Empezar ya", onSkip)
    }
}

/// (no `.borderedProminent` / `.confirmationDialog`). Vive junto a
/// `WatchHomeHubView` para no depender de un `.swift` nuevo en el pbxproj.
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
                    .minimumScaleFactor(0.8)
                    .lineLimit(2)

                Text(planTitle)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: onLive) {
                    Text("Entreno guiado")
                        .font(.callout.weight(.bold))
                        .frame(maxWidth: .infinity, minHeight: 42)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.black)
                .background(accent, in: Capsule())
                .contentShape(Capsule())

                Button(action: onRecord) {
                    Text("Entreno libre")
                        .font(.callout.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 42)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(Color.white.opacity(0.18), in: Capsule())
                .contentShape(Capsule())

                Button(action: onCancel) {
                    Text("Cancelar")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .ignoresSafeArea(.container, edges: .all)
        .accessibilityElement(children: .contain)
    }
}
