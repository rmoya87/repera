import AVKit
import ReperaDomain
import SwiftUI

/// Reloj digital estilo LED (rondas en verde + tiempo en rojo), como la referencia.
struct DigitalClockDisplay: View {
    /// Ronda / intervalo actual (nil = ocultar bloque verde).
    var roundNumber: Int?
    /// Segundos a mostrar (restantes o transcurridos).
    var totalSeconds: Int
    var digitHeight: CGFloat = 72

    private var minutes: Int { max(0, totalSeconds) / 60 }
    private var seconds: Int { max(0, totalSeconds) % 60 }

    var body: some View {
        HStack(alignment: .center, spacing: digitHeight * 0.22) {
            if let roundNumber {
                SevenSegmentPair(
                    value: min(99, max(0, roundNumber)),
                    onColor: Color(red: 0.22, green: 1.0, blue: 0.35),
                    digitHeight: digitHeight
                )
            }
            HStack(alignment: .center, spacing: digitHeight * 0.08) {
                SevenSegmentPair(
                    value: min(99, minutes),
                    onColor: Color(red: 1.0, green: 0.22, blue: 0.18),
                    digitHeight: digitHeight
                )
                SevenSegmentColon(onColor: Color(red: 1.0, green: 0.22, blue: 0.18), digitHeight: digitHeight)
                SevenSegmentPair(
                    value: seconds,
                    onColor: Color(red: 1.0, green: 0.22, blue: 0.18),
                    digitHeight: digitHeight
                )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let time = String(format: "%d minutos %d segundos", minutes, seconds)
        if let roundNumber {
            return "Ronda \(roundNumber), \(time)"
        }
        return time
    }
}

private struct SevenSegmentPair: View {
    let value: Int
    let onColor: Color
    let digitHeight: CGFloat

    var body: some View {
        HStack(spacing: digitHeight * 0.08) {
            SevenSegmentDigit(digit: value / 10, onColor: onColor, height: digitHeight)
            SevenSegmentDigit(digit: value % 10, onColor: onColor, height: digitHeight)
        }
    }
}

private struct SevenSegmentColon: View {
    let onColor: Color
    let digitHeight: CGFloat

    var body: some View {
        VStack(spacing: digitHeight * 0.22) {
            Circle().fill(onColor).frame(width: digitHeight * 0.12, height: digitHeight * 0.12)
                .shadow(color: onColor.opacity(0.8), radius: 6)
            Circle().fill(onColor).frame(width: digitHeight * 0.12, height: digitHeight * 0.12)
                .shadow(color: onColor.opacity(0.8), radius: 6)
        }
        .frame(height: digitHeight)
    }
}

/// Dígito 7 segmentos.
private struct SevenSegmentDigit: View {
    let digit: Int
    let onColor: Color
    let height: CGFloat

    private var width: CGFloat { height * 0.58 }
    private var thickness: CGFloat { max(4, height * 0.11) }
    private var offColor: Color { onColor.opacity(0.12) }

    /// a,b,c,d,e,f,g
    private var lit: Set<Character> {
        switch digit {
        case 0: return Set("abcdef")
        case 1: return Set("bc")
        case 2: return Set("abdeg")
        case 3: return Set("abcdg")
        case 4: return Set("bcfg")
        case 5: return Set("acdfg")
        case 6: return Set("acdefg")
        case 7: return Set("abc")
        case 8: return Set("abcdefg")
        case 9: return Set("abcdfg")
        default: return []
        }
    }

    var body: some View {
        ZStack {
            segment("a", horizontal: true)
                .offset(y: -(height - thickness) / 2)
            segment("d", horizontal: true)
                .offset(y: (height - thickness) / 2)
            segment("g", horizontal: true)
            segment("f", horizontal: false)
                .offset(x: -(width - thickness) / 2, y: -(height * 0.22))
            segment("b", horizontal: false)
                .offset(x: (width - thickness) / 2, y: -(height * 0.22))
            segment("e", horizontal: false)
                .offset(x: -(width - thickness) / 2, y: height * 0.22)
            segment("c", horizontal: false)
                .offset(x: (width - thickness) / 2, y: height * 0.22)
        }
        .frame(width: width, height: height)
    }

    private func segment(_ id: Character, horizontal: Bool) -> some View {
        let on = lit.contains(id)
        let color = on ? onColor : offColor
        return RoundedRectangle(cornerRadius: thickness * 0.35, style: .continuous)
            .fill(color)
            .frame(
                width: horizontal ? width * 0.72 : thickness,
                height: horizontal ? thickness : height * 0.38
            )
            .shadow(color: on ? onColor.opacity(0.75) : .clear, radius: on ? 8 : 0)
    }
}

/// Acceso nativo y seguro al enrutamiento de audio del dispositivo.
/// Las APIs públicas de iOS no permiten leer/controlar el Now Playing de
/// Spotify, Podcasts u otras apps. No se fabrican metadatos ni comandos.
private struct SystemAudioRoutePicker: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView(frame: .zero)
        picker.tintColor = .white
        picker.activeTintColor = .systemGreen
        picker.prioritizesVideoDevices = false
        return picker
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

/// Mantiene el acceso a AirPlay/salida nativa sin apropiarse de otra sesión
/// multimedia. La reproducción de terceros sigue en Centro de control.
private struct TimerSystemAudioPanel: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "music.note")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 3) {
                Text("Audio del iPhone")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Reproducción: Centro de control")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(2)
            }
            Spacer(minLength: 2)
            SystemAudioRoutePicker()
                .frame(width: 42, height: 42)
                .accessibilityLabel("Elegir salida de audio AirPlay")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .contain)
    }
}

/// Reloj del bloque para orientación vertical u horizontal.
/// Botones siempre visibles; solo se muestra «Terminar» si el formato lo permite.
struct BlockTimerScreen: View {
    var title: String
    var subtitle: String
    var exercise: Exercise?
    var roundNumber: Int?
    var totalRounds: Int?
    var displaySeconds: Int
    var isRunning: Bool
    var isCountingUp: Bool
    var primaryTitle: String
    var onPrimary: () -> Void
    var onClose: () -> Void
    var onFinish: (() -> Void)? = nil
    var showFinish: Bool = false

    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private var isLandscape: Bool { verticalSizeClass == .compact }

    var body: some View {
        GeometryReader { geometry in
            let landscape = isLandscape || geometry.size.width > geometry.size.height
            let sideWidth = landscape && exercise != nil
                ? min(260, geometry.size.width * 0.31)
                : 0
            let availableClockWidth = landscape
                ? geometry.size.width - sideWidth - (exercise == nil ? 48 : 66)
                : geometry.size.width - 32
            // Dos pares LED + separador ocupan aproximadamente 2,9x su alto.
            // Aprovechar ancho Y alto; no dejar el reloj pequeño en retrato.
            let digitHeight = min(
                landscape ? 165 : 138,
                max(55, availableClockWidth / 3.05),
                geometry.size.height * (landscape ? 0.36 : 0.235)
            )

            ZStack {
                Color.black.ignoresSafeArea()
                if landscape {
                    landscapeLayout(digitHeight: digitHeight, availableWidth: geometry.size.width)
                } else {
                    portraitLayout(digitHeight: digitHeight)
                }
            }
        }
    }

    private var topBar: some View {
        HStack(alignment: .center, spacing: 12) {
            OGToolbarGlassButton(
                systemName: "xmark",
                accessibilityLabel: "Cerrar temporizador",
                tint: .white,
                appliesGlass: true,
                action: onClose
            )
            if !title.isEmpty {
                Text(title)
                    .font(.system(size: isLandscape ? 25 : 28, weight: .bold))
                    .foregroundStyle(.white)
                    .tracking(-0.4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var exerciseDetails: some View {
        Group {
            if let exercise {
                VStack(alignment: isLandscape ? .leading : .center, spacing: 10) {
                    ExerciseThumb(exercise: exercise, size: isLandscape ? 72 : 66)
                    Text(exercise.name)
                        .font(.system(size: isLandscape ? 17 : 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(isLandscape ? .leading : .center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: isLandscape ? .leading : .center)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func portraitLayout(digitHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            topBar
            Spacer(minLength: 8)
            VStack(spacing: 22) {
                clockBlock(digitHeight: digitHeight)
                // El movimiento aparece DESPUÉS del reloj, no en el encabezado.
                if exercise != nil {
                    exerciseDetails
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            Spacer(minLength: 10)
            TimerSystemAudioPanel()
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            controls(horizontal: false)
                .padding(.horizontal, 24)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func landscapeLayout(digitHeight: CGFloat, availableWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            topBar
            HStack(alignment: .top, spacing: 22) {
                if exercise != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        exerciseDetails
                        Spacer(minLength: 8)
                        TimerSystemAudioPanel()
                    }
                    .frame(width: min(260, availableWidth * 0.31), alignment: .leading)
                    .padding(.leading, 20)
                    .padding(.bottom, 12)
                }
                VStack(spacing: 14) {
                    Spacer(minLength: 0)
                    clockBlock(digitHeight: digitHeight)
                    // Pausar/Continuar + Terminar en UNA fila bajo el reloj.
                    controls(horizontal: true)
                        .frame(maxWidth: 500)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
    }

    private func clockBlock(digitHeight: CGFloat) -> some View {
        VStack(spacing: 8) {
            DigitalClockDisplay(
                roundNumber: roundNumber,
                totalSeconds: displaySeconds,
                digitHeight: digitHeight
            )
            .frame(maxWidth: .infinity)
            if !subtitle.isEmpty || (totalRounds != nil && roundNumber != nil) {
                HStack(spacing: 8) {
                    if let totalRounds, let roundNumber {
                        Text("\(roundNumber)/\(totalRounds)")
                            .font(.system(size: 14, weight: .semibold).monospacedDigit())
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(OG.accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var pauseOrResumeButton: some View {
        Button(action: onPrimary) {
            Text(primaryTitle)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(.white, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(primaryTitle + " temporizador")
    }

    private var finishButton: some View {
        Group {
            if showFinish, let onFinish {
                Button(action: onFinish) {
                    Text("Terminar")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(OG.accent, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Terminar bloque")
            }
        }
    }

    private func controls(horizontal: Bool) -> some View {
        Group {
            if horizontal {
                HStack(spacing: 12) {
                    pauseOrResumeButton
                    finishButton
                }
            } else {
                VStack(spacing: 12) {
                    pauseOrResumeButton
                    finishButton
                }
            }
        }
    }
}
