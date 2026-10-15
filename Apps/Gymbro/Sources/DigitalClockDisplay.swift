import GymbroDomain
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

/// Pantalla completa del reloj: imagen del ejercicio, display LED y botón Comenzar / controles.
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
    var onSkip: (() -> Void)?

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isLandscape: Bool { verticalSizeClass == .compact }

    var body: some View {
        GeometryReader { geo in
            let digitH: CGFloat = isLandscape
                ? min(120, geo.size.height * 0.42)
                : min(88, geo.size.width * 0.18)

            ZStack {
                Color.black.ignoresSafeArea()

                if isLandscape {
                    landscapeLayout(digitHeight: digitH, size: geo.size)
                } else {
                    portraitLayout(digitHeight: digitH)
                }
            }
        }
    }

    private func portraitLayout(digitHeight: CGFloat) -> some View {
        VStack(spacing: 20) {
            HStack {
                CloseToolbarButton(action: onClose)
                Spacer()
                if let totalRounds, let roundNumber {
                    Text("\(roundNumber)/\(totalRounds)")
                        .font(.system(size: 15, weight: .semibold).monospacedDigit())
                        .foregroundStyle(OG.label3)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            if let exercise {
                ExerciseThumb(exercise: exercise, size: 72)
                Text(exercise.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            } else if !title.isEmpty {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer(minLength: 8)

            VStack(spacing: 10) {
                DigitalClockDisplay(
                    roundNumber: roundNumber,
                    totalSeconds: displaySeconds,
                    digitHeight: digitHeight
                )
                .padding(.horizontal, 12)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(OG.accent)
                }
            }

            Spacer(minLength: 8)

            controls
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
        }
    }

    private func landscapeLayout(digitHeight: CGFloat, size: CGSize) -> some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                CloseToolbarButton(action: onClose)
                if let exercise {
                    ExerciseThumb(exercise: exercise, size: 64)
                    Text(exercise.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(3)
                }
                Spacer(minLength: 0)
                controls
            }
            .frame(width: min(220, size.width * 0.28), alignment: .leading)
            .padding(.leading, 20)
            .padding(.vertical, 16)

            VStack(spacing: 10) {
                Spacer()
                DigitalClockDisplay(
                    roundNumber: roundNumber,
                    totalSeconds: displaySeconds,
                    digitHeight: digitHeight
                )
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(OG.accent)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.trailing, 16)
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button(action: onPrimary) {
                Text(primaryTitle)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 54)
                    .background(.white, in: Capsule())
            }
            .buttonStyle(.plain)

            if let onSkip, isRunning {
                Button("Saltar", action: onSkip)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(OG.label2)
            }
        }
    }
}
