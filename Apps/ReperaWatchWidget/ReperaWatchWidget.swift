import SwiftUI
import WidgetKit

private struct ReperaWatchEntry: TimelineEntry {
    let date: Date
}

private struct ReperaWatchProvider: TimelineProvider {
    func placeholder(in context: Context) -> ReperaWatchEntry {
        _ = ReperaComplicationAppIconStore.seedFromBundleIfNeeded()
        return ReperaWatchEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (ReperaWatchEntry) -> Void) {
        _ = ReperaComplicationAppIconStore.seedFromBundleIfNeeded()
        completion(ReperaWatchEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReperaWatchEntry>) -> Void) {
        _ = ReperaComplicationAppIconStore.seedFromBundleIfNeeded()
        completion(
            Timeline(
                entries: [ReperaWatchEntry(date: .now)],
                policy: .after(.now.addingTimeInterval(6 * 60 * 60))
            )
        )
    }
}

/// Logo AppIcon con frame fijo (patrón Cafesito `WatchComplicationPantryThumbnail` /
/// `WatchBrewTimerInactiveMark`). Sin GeometryReader: Chrono deja el slot vacío.
private struct ReperaComplicationAppLogoMark: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    var markDiameter: CGFloat = 36

    var body: some View {
        Group {
            if renderingMode == .fullColor {
                // On full-color faces and in Smart Stack, show the actual app icon.
                Image(ReperaComplicationAppIconStore.assetCatalogImageName)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .clipShape(Circle())
            } else {
                // watchOS deliberately recolors opaque app icons in tinted
                // complications. An opaque PNG becomes a dark solid disc.
                // Use an intentional high-contrast monogram for those faces.
                ZStack {
                    Circle().fill(.primary).widgetAccentable()
                    Text("R")
                        .font(.system(size: markDiameter * 0.64, weight: .black, design: .rounded))
                        .foregroundStyle(.background)
                        .minimumScaleFactor(0.8)
                }
                .accessibilityLabel("Repera")
            }
        }
        .frame(width: markDiameter, height: markDiameter)
        .accessibilityLabel("Repera")
    }
}

private struct ReperaWatchComplication: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            HStack(spacing: 6) {
                ReperaComplicationAppLogoMark(markDiameter: 28)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Repera").font(.headline)
                    Text("Hoy").font(.caption2)
                }
                Spacer(minLength: 0)
            }
        case .accessoryInline:
            Text("Repera")
        case .accessoryCorner:
            ReperaComplicationAppLogoMark(markDiameter: 28)
        default:
            ReperaComplicationAppLogoMark(markDiameter: 36)
        }
    }
}

private struct ReperaWatchWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "com.app.repera.watch.complication",
            provider: ReperaWatchProvider()
        ) { _ in
            ReperaWatchComplication()
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(URL(string: "repera-watch://today"))
        }
        .configurationDisplayName("Repera")
        .description("Abre Repera desde la esfera del Apple Watch.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

@main
struct ReperaWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        ReperaWatchWidget()
    }
}
