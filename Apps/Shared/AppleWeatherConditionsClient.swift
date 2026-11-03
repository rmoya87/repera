import CoreLocation
import Foundation
import ReperaDomain
import WeatherKit

/// iOS + watchOS: WeatherKit es la fuente de temperatura, humedad, viento y nevada.
/// Open-Meteo solo complementa mareas, oleaje y profundidad de nieve.
enum AppleWeatherConditionsClient {
    static func fetch(
        latitude: Double,
        longitude: Double,
        sportID: String?,
        at date: Date = Date()
    ) async -> ActivityConditionsSnapshot? {
        let family = ActivityConditionsSnapshot.family(forLiveSportID: sportID)
        guard family != .none,
              (-90...90).contains(latitude), (-180...180).contains(longitude) else { return nil }

        // El complemento puede fallar sin impedir el tiempo obtenido por WeatherKit.
        async let marineAndSnow = OpenMeteoConditionsClient.fetch(
            latitude: latitude, longitude: longitude, sportID: sportID, at: date
        )
        let location = CLLocation(
            latitude: ActivityConditionsLogic.roundCoordinate(latitude),
            longitude: ActivityConditionsLogic.roundCoordinate(longitude)
        )

        let current = try? await WeatherService.shared.weather(for: location, including: .current)
        var snapshot = await marineAndSnow ?? ActivityConditionsSnapshot(
            family: family, capturedAt: date, attribution: "Apple Weather"
        )

        if let current {
            snapshot.temperatureC = current.temperature.converted(to: .celsius).value
            snapshot.windKmh = current.wind.speed.converted(to: .kilometersPerHour).value
            snapshot.humidity = current.humidity
            snapshot.airSource = .appleWeather
        }

        // WeatherKit ofrece nevada por hora, pero no espesor de nieve en el suelo.
        if family == .snow,
           let forecast = try? await WeatherService.shared.weather(
               for: location, including: .hourly
           ),
           let hour = forecast.forecast.min(by: {
               abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
           }), abs(hour.date.timeIntervalSince(date)) <= 3 * 3600 {
            snapshot.snowfallCm = hour.snowfallAmount.converted(to: .centimeters).value
            snapshot.snowfallSource = .appleWeather
        }

        let hasApple = snapshot.airSource == .appleWeather ||
            snapshot.snowfallSource == .appleWeather
        let hasOpenMeteo = snapshot.tideHeightMeters != nil ||
            snapshot.waveHeightMeters != nil || snapshot.snowDepthMeters != nil
        guard hasApple || hasOpenMeteo else { return nil }

        snapshot.attribution = hasApple && hasOpenMeteo
            ? "Apple Weather + Open-Meteo"
            : (hasApple ? "Apple Weather" : "Open-Meteo")
        return snapshot
    }
}
