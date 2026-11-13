import ReperaDomain
import SwiftUI

/// Reloj digital estilo LED (rondas en verde + tiempo en rojo), como la referencia.
struct DigitalClockDisplay: View {
    /// Ronda / intervalo actual (nil = ocultar bloque verde).
    var roundNumber: Int?
    /// Segundos a mostrar (restantes o transcurridos).
    var totalSeconds: Int
    var digitHeight: CGFloat = 72
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var minutes: Int { max(0, totalSeconds) / 60 }
    private var seconds: Int { max(0, totalSeconds) % 60 }

    /// Ancho matemático del conjunto de dígitos LED: cada par mide 1,24h;
    /// HH:MM son 2,76h y la ronda añade 1,24h + 0,22h. Este factor
    /// sustituye a 3,05 (solo tiempo), que desbordaba al dibujar intervalos.
    static func widthFactor(hasRound: Bool) -> CGFloat {
        hasRound ? 4.22 : 2.76
    }

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
        // Solo fundido de segmentos; sin movimiento espacial en cada tick.
        .animation(
            OGMotion.animation(OGMotion.highlight, reduceMotion: reduceMotion),
            value: totalSeconds
        )
        .animation(
            OGMotion.animation(OGMotion.highlight, reduceMotion: reduceMotion),
            value: roundNumber
        )
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

/// Fila del listado del bloque en el reloj de Play (imagen | nombre + series/reps).
struct BlockTimerExerciseRow: Identifiable, Equatable {
    let id: UUID
    let exercise: Exercise?
    let name: String
    let detail: String
    var isActive: Bool
}

/// Reloj del bloque para orientación vertical u horizontal.
/// Comparte información de Apple Music con Comenzar y el temporizador libre
/// sin sustituir nunca la sesión Now Playing de la app que reproduce audio.
/// Botones siempre visibles; solo se muestra «Terminar» si el formato lo permite.
struct BlockTimerScreen: View {
    var title: String
    var subtitle: String
    var exercise: Exercise?
    /// Play: listado del bloque. Vacío = temporizador libre (solo reloj).
    var exerciseRows: [BlockTimerExerciseRow] = []
    var roundNumber: Int?
    var totalRounds: Int?
    var displaySeconds: Int
    var isRunning: Bool
    var isCountingUp: Bool
    var primaryTitle: String
    var onPrimary: () -> Void
    var onClose: () -> Void
    /// En Play se minimiza el reloj; el temporizador autónomo sigue cerrándose.
    var closeSymbol: String = "xmark"
    var closeAccessibilityLabel: String = "Cerrar temporizador"
    var onFinish: (() -> Void)? = nil
    var showFinish: Bool = false

    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private var isLandscape: Bool { verticalSizeClass == .compact }
    private var showsExerciseList: Bool { !exerciseRows.isEmpty }
    private var showsLegacyExercise: Bool { !showsExerciseList && exercise != nil }

    var body: some View {
        GeometryReader { geometry in
            let landscape = isLandscape || geometry.size.width > geometry.size.height
            let sideWidth: CGFloat = landscape && (showsExerciseList || showsLegacyExercise)
                ? min(showsExerciseList ? 300 : 260, geometry.size.width * (showsExerciseList ? 0.38 : 0.31))
                : 0
            // Espacio ocupado por safe area interna, margen de columna, HStack
            // y márgenes del cronómetro. En vertical se reserva aire al glow.
            let horizontalInset: CGFloat = landscape
                ? (sideWidth == 0 ? 40 : 94)
                : 44
            let availableClockWidth = max(
                1, geometry.size.width - sideWidth - horizontalInset
            )
            let widthFactor = DigitalClockDisplay.widthFactor(hasRound: roundNumber != nil)
            // Sin un mínimo artificial de 55 pt: con ronda + MM:SS causaba
            // clipping en iPhone estrecho. Cada cifra usa su ancho real.
            let digitHeight = min(
                landscape ? 165 : (showsExerciseList ? 110 : 138),
                availableClockWidth / widthFactor,
                geometry.size.height * (landscape ? 0.36 : (showsExerciseList ? 0.18 : 0.235))
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
                systemName: closeSymbol,
                accessibilityLabel: closeAccessibilityLabel,
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

    /// Listado Play: imagen a la izquierda, nombre y series/reps a la derecha.
    private var exerciseList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(exerciseRows) { row in
                    HStack(alignment: .center, spacing: 12) {
                        if let exercise = row.exercise {
                            ExerciseThumb(exercise: exercise, size: 52)
                        } else {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 52, height: 52)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(row.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                            if !row.detail.isEmpty {
                                Text(row.detail)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(row.isActive ? OG.accent : Color.white.opacity(0.55))
                                    .lineLimit(1)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(row.isActive ? OG.accent.opacity(0.18) : Color.white.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(row.isActive ? OG.accent.opacity(0.7) : Color.clear, lineWidth: 1)
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(row.isActive ? .isSelected : [])
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// El ejercicio acompaña al reloj sin pegarse a los dígitos.
    /// En ambas orientaciones el contenido queda centrado en su espacio.
    private func exerciseDetails(landscape: Bool) -> some View {
        Group {
            if showsExerciseList {
                exerciseList
            } else if let exercise {
                VStack(alignment: .center, spacing: landscape ? 15 : 12) {
                    ExerciseThumb(exercise: exercise, size: landscape ? 112 : 100)
                    Text(exercise.name)
                        .font(.system(size: landscape ? 20 : 21, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func portraitLayout(digitHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            topBar
            Spacer(minLength: 8)
            VStack(spacing: showsExerciseList ? 16 : 38) {
                clockBlock(digitHeight: digitHeight)
                if showsExerciseList || showsLegacyExercise {
                    exerciseDetails(landscape: false)
                        .frame(maxHeight: showsExerciseList ? .infinity : nil)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 12)
            controls(horizontal: false)
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func landscapeLayout(digitHeight: CGFloat, availableWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            topBar
            HStack(alignment: .center, spacing: 22) {
                if showsExerciseList || showsLegacyExercise {
                    exerciseDetails(landscape: true)
                        .frame(width: min(showsExerciseList ? 300 : 260,
                                          availableWidth * (showsExerciseList ? 0.38 : 0.31)))
                        .frame(maxHeight: .infinity, alignment: .center)
                        .padding(.leading, 20)
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
