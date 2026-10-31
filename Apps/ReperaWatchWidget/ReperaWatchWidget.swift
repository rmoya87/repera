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

/// La imagen fuente es EXACTAMENTE AppIcon.png de Repera, sin redibujar el icono.
/// Un PNG opaco se convierte en un disco sólido al teñirse en watchOS: para
/// los formatos accessoryCircular/Corner hay que separar fondo y protagonista.
/// Se deriva la máscara a partir de los píxeles oficiales, no de otra ilustración.
@MainActor
private enum ReperaComplicationArtwork {
    static let subject: UIImage? = makeSubjectMask()

    private static func makeSubjectMask() -> UIImage? {
        guard let image = UIImage(named: "ReperaIcon")?.cgImage else { return nil }
        let side = 160
        let rowBytes = side * 4
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue
            | CGImageAlphaInfo.premultipliedLast.rawValue
        var bytes = [UInt8](repeating: 0, count: side * rowBytes)

        let result: CGImage? = bytes.withUnsafeMutableBytes { raw in
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
            context.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))

            let pixels = raw.bindMemory(to: UInt8.self)
            // Esquina del AppIcon: muestra del fondo verde real, no un verde
            // supuesto. La diferencia cromática rescata cara, ojos y cinta.
            let bgR = Int(pixels[0])
            let bgG = Int(pixels[1])
            let bgB = Int(pixels[2])
            for index in stride(from: 0, to: pixels.count, by: 4) {
                let r = Int(pixels[index])
                let g = Int(pixels[index + 1])
                let b = Int(pixels[index + 2])
                let a = Double(pixels[index + 3]) / 255.0
                let distance = sqrt(Double(
                    (r - bgR) * (r - bgR)
                    + (g - bgG) * (g - bgG)
                    + (b - bgB) * (b - bgB)
                ))
                // Bordes suaves: solo se vuelve transparente el verde que
                // coincide con el fondo. La cinta oscura sigue presente.
                let subjectAlpha = min(1.0, max(0.0, (distance - 16.0) / 48.0)) * a
                let luminance = (0.2126 * Double(r) + 0.7152 * Double(g)
                    + 0.0722 * Double(b)) / 255.0
                // Core Graphics necesita píxeles premultiplicados.
                // WidgetKit desaturated mapea esta luminancia a alfa del grupo
                // primario, dejando ojos y cinta oscuros contra el fondo.
                let value = UInt8((255.0 * luminance * subjectAlpha).rounded())
                pixels[index] = value
                pixels[index + 1] = value
                pixels[index + 2] = value
                pixels[index + 3] = UInt8((255.0 * subjectAlpha).rounded())
            }
            // CGImage no puede retener memoria temporal de withUnsafeMutableBytes.
            let owned = Data(bytes: base, count: raw.count)
            guard let provider = CGDataProvider(data: owned as CFData) else { return nil }
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
        return result.map { UIImage(cgImage: $0) }
    }
}

/// El selector de complicaciones usa el mismo timeline/SwiftUI que la esfera.
/// El color completo solo está permitido cuando watchOS solicita fullColor.
/// En accented, el fondo y la mascota son dos capas tintables independientes:
/// nunca se envía a WidgetKit un único PNG opaco para convertirlo en un disco.
private struct ReperaLogo: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    var diameter: CGFloat = 34

    var body: some View {
        Group {
            if renderingMode == .fullColor {
                Image("ReperaIcon")
                    .resizable()
                    .scaledToFit()
            } else {
                ZStack {
                    // Capa acentuada: fondo circular del icono original.
                    Circle()
                        .fill(Color.white)
                        .widgetAccentable()
                    // Capa primaria: personaje recortado DIGITALMENTE del
                    // mismo AppIcon, con textura real y detalles de luminosidad.
                    if let subject = ReperaComplicationArtwork.subject {
                        Image(uiImage: subject)
                            .resizable()
                            .widgetAccentedRenderingMode(.desaturated)
                            .scaledToFit()
                    } else {
                        // Marca de error explícita si Assets.car no contiene
                        // el recurso; evitar fingir que el disco es el logo.
                        Text("R")
                            .font(.system(size: diameter * 0.55, weight: .bold))
                    }
                }
            }
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
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
        StaticConfiguration(kind: "com.app.repera.watch.complication.brand2", provider: ReperaWatchProvider()) { entry in
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
