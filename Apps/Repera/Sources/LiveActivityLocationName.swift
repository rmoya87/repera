import CoreLocation
import Foundation
import MapKit

/// Títulos orientativos: solo ciudad/localidad (sin calle ni portal), editables.
/// Geocodificar únicamente al finalizar evita peticiones GPS/geocoder continuas.
@MainActor
enum LiveActivityLocationName {
    static func format(sport: LiveSport, start: String, end: String? = nil) -> String {
        let activity: String
        switch sport {
        case .walking: activity = "Caminata"
        case .running, .trail: activity = "Carrera"
        default: activity = sport.title
        }
        let noun = start.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !noun.isEmpty else { return sport.title }
        let other = end?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !other.isEmpty && other.caseInsensitiveCompare(noun) != .orderedSame {
            return "\(activity) de \(noun) a \(other)"
        }
        let preposition = sport == .walking || sport == .running || sport == .trail
            || sport == .hiking || sport == .cycling ? "por" : "en"
        return "\(activity) \(preposition) \(noun)"
    }

    static func suggest(sport: LiveSport, start: WorkoutRoutePoint?,
                        end: WorkoutRoutePoint?) async -> String? {
        // Para deportes sin ruta no activar el seguimiento; únicamente una captura
        // puntual si ya se había autorizado la ubicación.
        let coordinate: CLLocation
        if let start {
            coordinate = CLLocation(latitude: start.latitude, longitude: start.longitude)
        } else {
            guard WorkoutLocationTracker.shared.isAuthorized,
                  let pin = await WorkoutLocationTracker.shared.capturePin() else { return nil }
            coordinate = CLLocation(latitude: pin.latitude, longitude: pin.longitude)
        }
        guard let firstCity = await city(at: coordinate) else { return nil }
        var lastCity: String?
        if let end {
            let destination = CLLocation(latitude: end.latitude, longitude: end.longitude)
            if destination.distance(from: coordinate) > 2_000 {
                lastCity = await city(at: destination)
            }
        }
        return format(sport: sport, start: firstCity, end: lastCity)
    }

    private static func city(at location: CLLocation) async -> String? {
        guard let request = MKReverseGeocodingRequest(location: location) else { return nil }
        request.preferredLocale = Locale(identifier: "es_ES")
        let items = try? await request.mapItems
        let place = items?.first?.addressRepresentations?.cityName?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return place?.isEmpty == false ? place : nil
    }
}
