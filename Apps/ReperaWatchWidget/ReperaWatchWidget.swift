import SwiftUI
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

/// Silueta de la mascota de Repera en trazos vectoriales, sin PNG ni Assets.car.
/// Los ojos y la boca son huecos transparentes auténticos (even-odd):
/// watchOS puede teñir el símbolo sin convertirlo en un círculo macizo.
private struct ReperaMascotFace: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.addEllipse(in: CGRect(x: 0.10 * w, y: 0.24 * h, width: 0.80 * w, height: 0.70 * h))
        path.addEllipse(in: CGRect(x: 0.305 * w, y: 0.515 * h, width: 0.080 * w, height: 0.125 * h))
        path.addEllipse(in: CGRect(x: 0.615 * w, y: 0.515 * h, width: 0.080 * w, height: 0.125 * h))
        path.move(to: CGPoint(x: 0.41 * w, y: 0.68 * h))
        path.addQuadCurve(to: CGPoint(x: 0.59 * w, y: 0.68 * h), control: CGPoint(x: 0.50 * w, y: 0.79 * h))
        path.addLine(to: CGPoint(x: 0.59 * w, y: 0.65 * h))
        path.addQuadCurve(to: CGPoint(x: 0.41 * w, y: 0.65 * h), control: CGPoint(x: 0.50 * w, y: 0.755 * h))
        path.closeSubpath()
        return path
    }
}

/// El icono de la esfera no depende de recursos que Chrono pueda omitir del widget.
/// En esferas teñidas, cara y orejas forman la capa primaria; la cinta es acentuada.
private struct ReperaLogo: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    var diameter: CGFloat = 34

    var body: some View {
        let fullColor = renderingMode == .fullColor
        let faceColor = fullColor ? Color(red: 0.97, green: 0.82, blue: 0.70) : Color.primary
        let bandColor = fullColor ? Color(red: 0.08, green: 0.43, blue: 0.20) : Color.primary

        ZStack {
            Ellipse()
                .fill(faceColor)
                .frame(width: diameter * 0.17, height: diameter * 0.23)
                .rotationEffect(.degrees(-27))
                .offset(x: -diameter * 0.13, y: -diameter * 0.30)
            Ellipse()
                .fill(faceColor)
                .frame(width: diameter * 0.17, height: diameter * 0.23)
                .rotationEffect(.degrees(22))
                .offset(x: diameter * 0.10, y: -diameter * 0.31)
            ReperaMascotFace()
                .fill(faceColor, style: FillStyle(eoFill: true))
            Capsule()
                .fill(bandColor)
                .widgetAccentable()
                .frame(width: diameter * 0.76, height: diameter * 0.095)
                .rotationEffect(.degrees(-5))
                .offset(y: -diameter * 0.12)
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
