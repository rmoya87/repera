import Foundation

/// Familia de condiciones del medio (marea / nieve / outdoor genérico).
public enum ActivityConditionsFamily: String, Codable, Sendable, Equatable {
    case water
    case snow
    case outdoor
    case none
}

public enum TideTrend: String, Codable, Sendable, Equatable {
    case rising
    case falling
    case slack
}

/// Snapshot gratuito (Open-Meteo) de condiciones; orientativo, no náutico.
public struct ActivityConditionsSnapshot: Codable, Equatable, Sendable {
    public var family: ActivityConditionsFamily
    public var capturedAt: Date
    public var temperatureC: Double?
    public var windKmh: Double?
    public var tideHeightMeters: Double?
    public var tideTrend: TideTrend?
    public var nextTideLabel: String?
    public var waveHeightMeters: Double?
    public var snowfallCm: Double?
    public var snowDepthMeters: Double?
    public var attribution: String
    public var disclaimer: String?

    public init(
        family: ActivityConditionsFamily,
        capturedAt: Date = Date(),
        temperatureC: Double? = nil,
        windKmh: Double? = nil,
        tideHeightMeters: Double? = nil,
        tideTrend: TideTrend? = nil,
        nextTideLabel: String? = nil,
        waveHeightMeters: Double? = nil,
        snowfallCm: Double? = nil,
        snowDepthMeters: Double? = nil,
        attribution: String = "Open-Meteo",
        disclaimer: String? = nil
    ) {
        self.family = family
        self.capturedAt = capturedAt
        self.temperatureC = temperatureC
        self.windKmh = windKmh
        self.tideHeightMeters = tideHeightMeters
        self.tideTrend = tideTrend
        self.nextTideLabel = nextTideLabel
        self.waveHeightMeters = waveHeightMeters
        self.snowfallCm = snowfallCm
        self.snowDepthMeters = snowDepthMeters
        self.attribution = attribution
        self.disclaimer = disclaimer
    }

    public var tideTrendLabel: String? {
        switch tideTrend {
        case .rising: "Subiendo"
        case .falling: "Bajando"
        case .slack: "Estable"
        case nil: nil
        }
    }

    public static func family(forLiveSportID id: String?) -> ActivityConditionsFamily {
        guard let id, !id.isEmpty, id != "companion" else { return .none }
        switch id {
        case "surfing", "windsurfing", "kitesurfing", "kayaking", "rowing",
             "canoeing", "sailing", "swimming":
            return .water
        case "skiing", "snowboarding", "crossCountrySkiing":
            return .snow
        case "running", "trail", "walking", "hiking", "cycling", "mountainBike",
             "gravel", "skateboarding", "golf":
            return .outdoor
        default:
            return .none
        }
    }
}

/// Construcción de URLs y parseo Open-Meteo (sin red).
public enum ActivityConditionsLogic {
    public static func roundCoordinate(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }

    public static func forecastURL(latitude: Double, longitude: Double) -> URL? {
        let lat = roundCoordinate(latitude)
        let lon = roundCoordinate(longitude)
        var c = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        c?.queryItems = [
            .init(name: "latitude", value: "\(lat)"),
            .init(name: "longitude", value: "\(lon)"),
            .init(
                name: "hourly",
                value: "temperature_2m,wind_speed_10m,snowfall,snow_depth"
            ),
            .init(name: "forecast_days", value: "2"),
            .init(name: "timezone", value: "auto"),
            .init(name: "wind_speed_unit", value: "kmh")
        ]
        return c?.url
    }

    public static func marineURL(latitude: Double, longitude: Double) -> URL? {
        let lat = roundCoordinate(latitude)
        let lon = roundCoordinate(longitude)
        var c = URLComponents(string: "https://marine-api.open-meteo.com/v1/marine")
        c?.queryItems = [
            .init(name: "latitude", value: "\(lat)"),
            .init(name: "longitude", value: "\(lon)"),
            .init(name: "hourly", value: "sea_level_height_msl,wave_height"),
            .init(name: "forecast_days", value: "2"),
            .init(name: "timezone", value: "auto")
        ]
        return c?.url
    }

    public static func parse(
        family: ActivityConditionsFamily,
        forecastJSON: Data?,
        marineJSON: Data?,
        at date: Date = Date()
    ) -> ActivityConditionsSnapshot? {
        guard family != .none else { return nil }
        var snap = ActivityConditionsSnapshot(
            family: family,
            capturedAt: date,
            disclaimer: family == .water
                ? "No usar para navegar"
                : nil
        )
        if let forecastJSON,
           let root = try? JSONSerialization.jsonObject(with: forecastJSON) as? [String: Any],
           let hourly = root["hourly"] as? [String: Any],
           let times = hourly["time"] as? [String] {
            let idx = closestIndex(times: times, to: date)
            if let idx {
                snap.temperatureC = doubleAt(hourly["temperature_2m"], idx)
                snap.windKmh = doubleAt(hourly["wind_speed_10m"], idx)
                    ?? doubleAt(hourly["windspeed_10m"], idx)
                if family == .snow {
                    // Open-Meteo snowfall = cm en la hora; snow_depth = m.
                    snap.snowfallCm = doubleAt(hourly["snowfall"], idx)
                    snap.snowDepthMeters = doubleAt(hourly["snow_depth"], idx)
                }
            }
        }
        if family == .water, let marineJSON,
           let root = try? JSONSerialization.jsonObject(with: marineJSON) as? [String: Any],
           let hourly = root["hourly"] as? [String: Any],
           let times = hourly["time"] as? [String] {
            let levels = doubles(hourly["sea_level_height_msl"])
            let waves = doubles(hourly["wave_height"])
            if let idx = closestIndex(times: times, to: date) {
                snap.tideHeightMeters = levels.indices.contains(idx) ? levels[idx] : nil
                snap.waveHeightMeters = waves.indices.contains(idx) ? waves[idx] : nil
                let prev = idx > 0 ? levels[idx - 1] : nil
                if let cur = snap.tideHeightMeters, let prev {
                    let delta = cur - prev
                    if abs(delta) < 0.02 {
                        snap.tideTrend = .slack
                    } else {
                        snap.tideTrend = delta > 0 ? .rising : .falling
                    }
                }
                snap.nextTideLabel = nextExtremumLabel(
                    levels: levels, times: times, from: idx
                )
            }
        }
        let hasAny = snap.temperatureC != nil || snap.windKmh != nil
            || snap.tideHeightMeters != nil || snap.waveHeightMeters != nil
            || snap.snowfallCm != nil || snap.snowDepthMeters != nil
        return hasAny ? snap : nil
    }

    private static func closestIndex(times: [String], to date: Date) -> Int? {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone.current
        fmt.dateFormat = "yyyy-MM-dd'T'HH:mm"
        var best: (Int, TimeInterval)?
        for (i, raw) in times.enumerated() {
            let trimmed = raw.count >= 16 ? String(raw.prefix(16)) : raw
            guard let t = fmt.date(from: trimmed) else { continue }
            let d = abs(t.timeIntervalSince(date))
            if best == nil || d < best!.1 { best = (i, d) }
        }
        guard let best, best.1 <= 3 * 3600 else { return nil }
        return best.0
    }

    private static func doubleAt(_ any: Any?, _ idx: Int) -> Double? {
        guard let arr = any as? [Any], arr.indices.contains(idx) else { return nil }
        if let d = arr[idx] as? Double { return d }
        if let n = arr[idx] as? NSNumber { return n.doubleValue }
        return nil
    }

    private static func doubles(_ any: Any?) -> [Double?] {
        guard let arr = any as? [Any] else { return [] }
        return arr.map {
            if $0 is NSNull { return nil }
            if let d = $0 as? Double { return d }
            if let n = $0 as? NSNumber { return n.doubleValue }
            return nil
        }
    }

    private static func nextExtremumLabel(
        levels: [Double?], times: [String], from idx: Int
    ) -> String? {
        guard let cur = levels[idx] else { return nil }
        var i = idx + 1
        while i + 1 < levels.count {
            guard let a = levels[i - 1], let b = levels[i], let c = levels[i + 1] else {
                i += 1
                continue
            }
            let isMax = b >= a && b >= c
            let isMin = b <= a && b <= c
            if isMax || isMin {
                let kind = isMax ? "Pleamar" : "Bajamar"
                let clock = String(times[i].suffix(5))
                return "\(kind) ~\(clock)"
            }
            i += 1
        }
        _ = cur
        return nil
    }
}
