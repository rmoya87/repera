import SwiftUI
import WeatherKit

/// Marca oficial de WeatherKit y enlace legal accesible también desde watchOS.
struct AppleWeatherAttributionView: View {
    var compact: Bool = false

    @Environment(\.colorScheme) private var colorScheme
    @State private var attribution: WeatherAttribution?

    private let legalFallback = URL(string: "https://weatherkit.apple.com/legal-attribution.html")!

    var body: some View {
        Link(destination: attribution?.legalPageURL ?? legalFallback) {
            HStack(spacing: 5) {
                if let markURL = colorScheme == .dark
                    ? attribution?.combinedMarkDarkURL : attribution?.combinedMarkLightURL {
                    AsyncImage(url: markURL) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFit()
                        } else {
                            fallbackMark
                        }
                    }
                    .frame(width: compact ? 72 : 86, height: compact ? 15 : 18)
                } else {
                    fallbackMark
                }
                Text("Fuentes legales")
                    .font(.system(size: compact ? 9 : 10))
                    .underline()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(.secondary)
        }
        .accessibilityLabel("Apple Weather. Abrir fuentes legales de WeatherKit")
        .task {
            attribution = try? await WeatherService.shared.attribution
        }
    }

    private var fallbackMark: some View {
        HStack(spacing: 2) {
            Image(systemName: "apple.logo")
            Text("Weather")
        }
        .font(.system(size: compact ? 10 : 11, weight: .medium))
        .fixedSize()
    }
}
