import Foundation

/// Análisis de recorridos GPS realizado exclusivamente en el dispositivo.
/// No se serializa en el espejo de entrenamientos de Supabase.
public enum CardioRouteAnalysis {
    public struct Sample: Sendable, Equatable {
        public var date: Date
        public var latitude: Double
        public var longitude: Double
        public var altitudeMeters: Double?

        public init(date: Date, latitude: Double, longitude: Double, altitudeMeters: Double? = nil) {
            self.date = date
            self.latitude = latitude
            self.longitude = longitude
            self.altitudeMeters = altitudeMeters
        }
    }

    public struct HeartSample: Sendable, Equatable {
        public var date: Date
        public var bpm: Double

        public init(date: Date, bpm: Double) {
            self.date = date
            self.bpm = bpm
        }
    }

    public struct ProfilePoint: Identifiable, Sendable, Equatable {
        public var id: Int
        public var date: Date
        public var distanceKm: Double
        public var altitudeMeters: Double
    }

    public struct Split: Identifiable, Sendable, Equatable {
        public var id: Int { kilometer }
        public var kilometer: Int
        public var seconds: Double
        public var paceSecondsPerKm: Double
        public var speedKmh: Double
        public var averageBpm: Double?
    }

    public struct Result: Sendable, Equatable {
        public var profile: [ProfilePoint]
        public var splits: [Split]
        public var distanceMeters: Double
        public var ascentMeters: Double
        public var descentMeters: Double
    }

    public static func analyze(route: [Sample], heart: [HeartSample] = []) -> Result {
        let samples = route
            .filter {
                $0.latitude.isFinite && $0.longitude.isFinite
                    && (-90...90).contains($0.latitude) && (-180...180).contains($0.longitude)
            }
            .sorted { $0.date < $1.date }

        var profile: [ProfilePoint] = []
        var distance = 0.0
        var ascent = 0.0
        var descent = 0.0
        var crossings: [Date] = []
        var previous: Sample?
        var previousAltitude: Double?
        let hr = heart.filter { $0.bpm.isFinite && (30...240).contains($0.bpm) }
            .sorted { $0.date < $1.date }

        for sample in samples {
            guard let last = previous else {
                previous = sample
                if let altitude = validAltitude(sample.altitudeMeters) {
                    previousAltitude = altitude
                    profile.append(ProfilePoint(id: 0, date: sample.date, distanceKm: 0, altitudeMeters: altitude))
                }
                continue
            }
            let dt = sample.date.timeIntervalSince(last.date)
            // Ignorar puntos duplicados, saltos GPS y velocidades imposibles.
            guard dt > 0 else { continue }
            let meters = haversine(last, sample)
            guard meters.isFinite, meters >= 0, meters / dt <= 35 else { continue }

            let priorDistance = distance
            distance += meters
            while Double(crossings.count + 1) * 1000 <= distance, meters > 0 {
                let goal = Double(crossings.count + 1) * 1000
                let fraction = (goal - priorDistance) / meters
                crossings.append(last.date.addingTimeInterval(dt * fraction))
            }
            if let altitude = validAltitude(sample.altitudeMeters) {
                if let earlier = previousAltitude {
                    // Referencia estable: acumula también ascensos graduales de 1-2 m,
                    // sin sumar oscilaciones insignificantes punto por punto.
                    let delta = altitude - earlier
                    if abs(delta) >= 3, abs(delta) / max(meters, 1) <= 1.5 {
                        if delta > 0 { ascent += delta } else { descent -= delta }
                        previousAltitude = altitude
                    }
                } else {
                    previousAltitude = altitude
                }
                profile.append(ProfilePoint(id: profile.count, date: sample.date,
                                            distanceKm: distance / 1000, altitudeMeters: altitude))
            }
            previous = sample
        }

        var splits: [Split] = []
        if let start = samples.first?.date {
            var splitStart = start
            for (index, end) in crossings.enumerated() {
                let duration = end.timeIntervalSince(splitStart)
                guard duration > 0 else { break }
                let bpm = hr.filter { $0.date >= splitStart && $0.date <= end }.map(\.bpm)
                splits.append(Split(
                    kilometer: index + 1,
                    seconds: duration,
                    paceSecondsPerKm: duration,
                    speedKmh: 3600 / duration,
                    averageBpm: bpm.count >= 2 ? bpm.reduce(0, +) / Double(bpm.count) : nil
                ))
                splitStart = end
            }
        }
        return Result(profile: profile, splits: splits, distanceMeters: distance,
                      ascentMeters: ascent, descentMeters: descent)
    }

    private static func validAltitude(_ meters: Double?) -> Double? {
        guard let meters, meters.isFinite, (-500...9000).contains(meters) else { return nil }
        return meters
    }

    private static func haversine(_ a: Sample, _ b: Sample) -> Double {
        let rad = Double.pi / 180
        let p1 = a.latitude * rad
        let p2 = b.latitude * rad
        let dPhi = (b.latitude - a.latitude) * rad
        let dLon = (b.longitude - a.longitude) * rad
        let h = pow(sin(dPhi / 2), 2) + cos(p1) * cos(p2) * pow(sin(dLon / 2), 2)
        return 6_371_000 * 2 * atan2(sqrt(max(0, h)), sqrt(max(0, 1 - h)))
    }
}
