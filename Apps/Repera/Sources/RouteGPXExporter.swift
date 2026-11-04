import Foundation

/// User-initiated export of the original recorded route. No network calls,
/// interpolation, reverse geocoding or replacement of GPS sensor samples.
enum RouteGPXExporter {
    static func export(points: [HealthKitStore.RoutePoint]) throws -> URL? {
        let valid = points.filter {
            $0.isEstimated == false &&
            $0.latitude.isFinite && $0.longitude.isFinite &&
            (-90...90).contains($0.latitude) && (-180...180).contains($0.longitude)
        }.sorted { $0.date < $1.date }
        guard valid.count >= 2 else { return nil }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let coordinateLocale = Locale(identifier: "en_US_POSIX")
        func number(_ value: Double) -> String {
            String(format: "%.7f", locale: coordinateLocale, value)
        }
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<gpx version=\"1.1\" creator=\"Repera\" xmlns=\"http://www.topografix.com/GPX/1/1\">\n"
        xml += "  <trk><name>Recorrido Repera</name><trkseg>\n"
        var lastTime: Date?
        for sample in valid {
            // Gaps are separate track segments; never draw an invented line.
            if let lastTime, sample.date.timeIntervalSince(lastTime) > 30 {
                xml += "  </trkseg><trkseg>\n"
            }
            lastTime = sample.date
            xml += "    <trkpt lat=\"\(number(sample.latitude))\" lon=\"\(number(sample.longitude))\">"
            if let altitude = sample.altitudeMeters, altitude.isFinite {
                xml += "<ele>\(number(altitude))</ele>"
            }
            xml += "<time>\(dateFormatter.string(from: sample.date))</time></trkpt>\n"
        }
        xml += "  </trkseg></trk>\n</gpx>\n"
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("repera-route-\(UUID().uuidString).gpx")
        try Data(xml.utf8).write(to: file, options: [.atomic, .completeFileProtection])
        return file
    }
}
