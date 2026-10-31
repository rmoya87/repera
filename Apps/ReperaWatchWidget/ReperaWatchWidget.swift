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
        completion(ReperaWatchEntry(date: .now, session: context.isPreview ? nil : ReperaComplicationSharedStore.read()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReperaWatchEntry>) -> Void) {
        completion(Timeline(
            entries: [ReperaWatchEntry(date: .now, session: ReperaComplicationSharedStore.read())],
            policy: .after(.now.addingTimeInterval(60))
        ))
    }
}

/// AppIcon de Repera (sin reinterpretaciones).
/// La imagen tintada procede de sus píxeles reales y se precalcula en un PNG:
/// el selector de esferas nunca ejecuta una máscara de CoreGraphics.
private struct ReperaLogo: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    var diameter: CGFloat = 34

    var body: some View {
        Group {
            if renderingMode == .fullColor {
                Image("ReperaIcon")
                    .resizable()
                    .scaledToFit()
                    .unredacted()
            } else {
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.15))
                        .widgetAccentable()
                    Image("ReperaWatchTintedIcon")
                        .resizable()
                        .widgetAccentedRenderingMode(.desaturated)
                        .scaledToFit()
                        .unredacted()
                }
                .unredacted()
            }
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
        .unredacted()
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
        StaticConfiguration(kind: "com.app.repera.watch.complication.brand5", provider: ReperaWatchProvider()) { entry in
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
