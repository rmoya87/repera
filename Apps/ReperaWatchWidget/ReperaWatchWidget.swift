import CoreGraphics
import Foundation
import SwiftUI
import UIKit
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

/// La única fuente visual de la complicación es el AppIcon oficial de Repera.
/// "ReperaIcon" contiene exactamente los mismos bytes que el AppIcon de Watch.
/// Las esferas .accented no admiten mantener el verde ni el tono de piel original,
/// así que calculamos la silueta *desde los píxeles oficiales* (no un dibujo nuevo).
@MainActor
private enum ReperaOfficialWatchIcon {
    static let tintedImage: UIImage? = makeTintedImage()

    private static func makeTintedImage() -> UIImage? {
        guard let original = UIImage(named: "ReperaIcon")?.cgImage else { return nil }
        // Chrono puede renderizar muchas previews. Crear la máscara una sola vez
        // a tamaño reducido, en memoria, sin lanzar I/O al construir la timeline.
        let side = 256
        let bytesPerRow = side * 4
        var bitmap = [UInt8](repeating: 0, count: side * bytesPerRow)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue |
            CGImageAlphaInfo.premultipliedLast.rawValue

        let output: CGImage? = bitmap.withUnsafeMutableBytes { buffer in
            guard let address = buffer.baseAddress,
                  let context = CGContext(
                    data: address,
                    width: side,
                    height: side,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space: colorSpace,
                    bitmapInfo: bitmapInfo
                  ) else { return nil }
            context.interpolationQuality = .high
            context.draw(original, in: CGRect(x: 0, y: 0, width: side, height: side))

            let rgba = buffer.bindMemory(to: UInt8.self)
            for index in stride(from: 0, to: rgba.count, by: 4) {
                let red = Int(rgba[index])
                let green = Int(rgba[index + 1])
                let blue = Int(rgba[index + 2])
                let sourceAlpha = Double(rgba[index + 3]) / 255

                // Retira el fondo verde (y la cinta verde) del *mismo icono*.
                // Un margen suave mantiene los píxeles antialiasados.
                let greenExcess = green - max(red, blue)
                let background = min(1.0, max(0.0, Double(greenExcess - 18) / 24))
                // Los ojos y la sonrisa oscuros son huecos, no manchas blancas.
                let detail = min(1.0, max(0.0, Double(max(red, green, blue) - 45) / 50))
                let alpha = UInt8(
                    (255 * sourceAlpha * (1 - background) * detail).rounded()
                )
                // Blanco premultiplicado: watchOS escoge el color de la esfera.
                rgba[index] = alpha
                rgba[index + 1] = alpha
                rgba[index + 2] = alpha
                rgba[index + 3] = alpha
            }

            // Copia los bytes: la imagen no debe referenciar el buffer temporal
            // cuando WidgetKit la dibuje fuera del proceso de la extensión.
            let data = Data(bytes: address, count: buffer.count)
            guard let provider = CGDataProvider(data: data as CFData) else { return nil }
            return CGImage(
                width: side,
                height: side,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
                provider: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
            )
        }
        guard let output else { return nil }
        return UIImage(cgImage: output)
    }
}

/// Mismo AppIcon de la app del Watch, sin redibujar la mascota.
/// En modo a color se muestra el PNG oficial intacto; en modo teñido se
/// conserva su silueta original y se cede el color a watchOS.
private struct ReperaLogo: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    var diameter: CGFloat = 34

    var body: some View {
        Group {
            if renderingMode == .fullColor {
                Image("ReperaIcon")
                    .resizable()
                    .scaledToFit()
            } else if let tinted = ReperaOfficialWatchIcon.tintedImage {
                Image(uiImage: tinted)
                    .resizable()
                    .widgetAccentedRenderingMode(.accented)
                    .scaledToFit()
            } else {
                // Si falla la conversión, sigue siendo la imagen oficial,
                // nunca una recreación geométrica del personaje.
                Image("ReperaIcon")
                    .resizable()
                    .widgetAccentedRenderingMode(.desaturated)
                    .scaledToFit()
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
        StaticConfiguration(kind: "com.app.repera.watch.complication", provider: ReperaWatchProvider()) { entry in
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
