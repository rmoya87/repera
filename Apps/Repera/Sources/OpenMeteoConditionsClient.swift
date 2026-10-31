import Foundation
import ReperaDomain

/// Condiciones Open-Meteo (gratis, sin API key): marea/oleaje/nieve.
enum OpenMeteoConditionsClient {
    private static let userAgent = "ReperaiOS/1.0 (activity conditions; +https://repera.app)"

    static func fetch(
        latitude: Double,
        longitude: Double,
        sportID: String?,
        at date: Date = Date()
    ) async -> ActivityConditionsSnapshot? {
        let family = ActivityConditionsSnapshot.family(forLiveSportID: sportID)
        guard family != .none else { return nil }
        var forecastData: Data?
        var marineData: Data?
        if let url = ActivityConditionsLogic.forecastURL(latitude: latitude, longitude: longitude) {
            forecastData = try? await get(url)
        }
        if family == .water,
           let url = ActivityConditionsLogic.marineURL(latitude: latitude, longitude: longitude) {
            marineData = try? await get(url)
        }
        return ActivityConditionsLogic.parse(
            family: family,
            forecastJSON: forecastData,
            marineJSON: marineData,
            at: date
        )
    }

    private static func get(_ url: URL) async throws -> Data {
        var req = URLRequest(url: url)
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 12
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
