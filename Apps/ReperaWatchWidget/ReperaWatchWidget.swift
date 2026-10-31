import CoreGraphics
import Foundation
import SwiftUI
import WatchKit
import WidgetKit

private struct ReperaWatchEntry: TimelineEntry {
    let date: Date
    let session: ReperaComplicationSnapshot?
}

private struct ReperaWatchProvider: TimelineProvider {
    func placeholder(in context: Context) -> ReperaWatchEntry {
        ReperaWatchEntry(date: .now, session: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (ReperaWatchEntry) -> Void) {
        completion(ReperaWatchEntry(date: .now, session: ReperaComplicationSharedStore.read()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReperaWatchEntry>) -> Void) {
        completion(Timeline(
            entries: [ReperaWatchEntry(date: .now, session: ReperaComplicationSharedStore.read())],
            policy: .after(.now.addingTimeInterval(60))
        ))
    }
}

/// Glifo monocromático de la cara ORIGINAL de Repera para las esferas de watchOS.
/// La imagen oficial tiene un fondo verde totalmente opaco: una complicación
/// circular NO debe enviar dicho fondo a WidgetKit (se convierte en un disco).
/// Recortamos la cara y generamos una imagen blanca con alfa real; los ojos,
/// la sonrisa y la cinta se representan como huecos transparentes.
/// El color lo decide watchOS según la esfera. AppIcon permanece intacto.
@MainActor
private enum ReperaComplicationArtwork {
    static let face: UIImage? = makeFaceTemplate()

    private static func makeFaceTemplate() -> UIImage? {
        guard let original = UIImage(named: "ReperaIcon")?.cgImage else { return nil }

        // La cara ocupa aproximadamente el 70 % central del AppIcon oficial.
        // Quitar el margen verde aumenta la legibilidad en los ~28–36 pt
        // disponibles, manteniendo una zona segura para el recorte circular.
        let sourceSide = CGFloat(min(original.width, original.height))
        let sourceInset = sourceSide * 0.155
        let crop = CGRect(
            x: CGFloat(original.width) / 2 - sourceSide / 2 + sourceInset,
            y: CGFloat(original.height) / 2 - sourceSide / 2 + sourceInset,
            width: sourceSide - 2 * sourceInset,
            height: sourceSide - 2 * sourceInset
        )
        guard let source = original.cropping(to: crop.integral) else { return nil }

        let side = 192
        let rowBytes = side * 4
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue
            | CGImageAlphaInfo.premultipliedLast.rawValue
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bytes = [UInt8](repeating: 0, count: side * rowBytes)

        let output: CGImage? = bytes.withUnsafeMutableBytes { raw in
            guard let base = raw.baseAddress,
                  let context = CGContext(
                    data: base,
                    width: side,
                    height: side,
                    bitsPerComponent: 8,
                    bytesPerRow: rowBytes,
                    space: colorSpace,
                    bitmapInfo: bitmapInfo
                  ) else { return nil }

            context.interpolationQuality = .high
            context.draw(source, in: CGRect(x: 0, y: 0, width: side, height: side))
            let pixels = raw.bindMemory(to: UInt8.self)

            for index in stride(from: 0, to: pixels.count, by: 4) {
                let red = Double(pixels[index])
                let green = Double(pixels[index + 1])
                let blue = Double(pixels[index + 2])
                let originalAlpha = Double(pixels[index + 3]) / 255.0

                // El fondo (verde) y la cinta (verde oscuro) NO son cara.
                // El personaje original es crema/cálido, por eso R > G.
                // Los ojos y la sonrisa son oscuros y deben ser huecos,
                // no una segunda capa negra que se convierta en un disco.
                let warmth = max(0, min(1, (red - green - 2) / 16))
                let luminance = (0.2126 * red + 0.7152 * green
                    + 0.0722 * blue) / 255.0
                let lightFace = max(0, min(1, (luminance - 0.33) / 0.28))
                let opacity = min(warmth, lightFace) * originalAlpha
                let alpha = UInt8((255 * opacity).rounded())

                // Blanco premultiplicado con alfa. WidgetKit utiliza el alfa
                // como plantilla al tintar; jamás incluir píxeles opacos del
                // fondo verde ni un círculo artificial detrás de la mascota.
                pixels[index] = alpha
                pixels[index + 1] = alpha
                pixels[index + 2] = alpha
                pixels[index + 3] = alpha
            }

            // CGImage debe poseer sus bytes tras salir del cierre.
            let owned = Data(bytes: base, count: raw.count)
            guard let provider = CGDataProvider(data: owned as CFData) else {
                return nil
            }
            return CGImage(
                width: side,
                height: side,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: rowBytes,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
                provider: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
            )
        }
        return output.map { UIImage(cgImage: $0) }
    }
}

/// La selección de complicaciones y la esfera usan exactamente la misma vista.
/// Solo las familias y esferas que permiten fullColor reciben el AppIcon original;
/// para accented/vibrant se muestra exclusivamente la cara como glifo de alfa.
private struct ReperaLogo: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    var diameter: CGFloat = 34

    var body: some View {
        Group {
            if renderingMode == .fullColor {
                Image("ReperaIcon")
                    .resizable()
                    .scaledToFit()
            } else if let face = ReperaComplicationArtwork.face {
                Image(uiImage: face)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(.primary)
                    .scaledToFit()
            } else {
                // Fallo de empaquetado visible; nunca fingir un icono válido.
                Text("R")
                    .font(.system(size: diameter * 0.55, weight: .bold))
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityLabel("Repera")
    }
}

private struct ReperaWatchComplication: View {
    @Environment(\.widgetFamily) private var family
    let entry: ReperaWatchEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular:
                if let live = entry.session {
                    HStack(alignment: .center, spacing: 6) {
                        ReperaLogo(diameter: 26)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Image(systemName: live.paused ? "pause.fill" : "figure.walk")
                                    .widgetAccentable()
                                Text(live.title).font(.caption.weight(.semibold)).lineLimit(1)
                            }
                            HStack(spacing: 6) {
                                Text(live.elapsedLabel).monospacedDigit()
                                if let distance = live.distanceLabel { Text(distance) }
                            }.font(.caption2).lineLimit(1)
                            HStack(spacing: 6) {
                                if let bpm = live.heartRateBpm {
                                    Label("\(bpm)", systemImage: "heart.fill").widgetAccentable()
                                }
                                if let kcal = live.energyKcal {
                                    Label("\(Int(kcal.rounded()))", systemImage: "flame.fill")
                                }
                            }.font(.caption2).lineLimit(1)
                        }
                    }
                } else {
                    HStack(spacing: 6) {
                        ReperaLogo(diameter: 28)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Repera").font(.headline)
                            Text("Iniciar actividad").font(.caption2)
                        }
                        Spacer(minLength: 0)
                    }
                }
            case .accessoryCircular:
                // La complicación circular es el acceso directo a Repera, incluso
                // durante una sesión. Las métricas se muestran en rectangular.
                ReperaLogo(diameter: 36)
            case .accessoryInline:
                if let live = entry.session {
                    Text("\(live.paused ? "⏸" : "▶") \(live.title) · \(live.elapsedLabel)")
                } else {
                    Text("Repera")
                }
            case .accessoryCorner:
                ReperaLogo(diameter: 28)
            default:
                ReperaLogo(diameter: 34)
            }
        }
        .widgetURL(URL(string: entry.session == nil
            ? "repera-watch://today" : "repera-watch://active"))
    }
}

private struct ReperaWatchWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.app.repera.watch.complication.brand3", provider: ReperaWatchProvider()) { entry in
            ReperaWatchComplication(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Repera")
        .description("Actividad del reloj: duración, distancia, pulso y calorías cuando hay datos.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryRectangular, .accessoryInline])
    }
}

@main
struct ReperaWatchWidgetBundle: WidgetBundle {
    var body: some Widget { ReperaWatchWidget() }
}
