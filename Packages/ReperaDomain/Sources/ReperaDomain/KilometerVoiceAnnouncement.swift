import Foundation

/// Locución de cada kilómetro GPS confirmado, calculada en el instante del cruce.
/// No depende de SwiftUI, del estado de pantalla ni del tiempo transcurrido desde
/// que Core Location entregó la muestra (puede llegar en segundo plano por lotes).
public enum KilometerVoiceAnnouncement {
    public static func message(
        kilometer: Int,
        splitSeconds: TimeInterval,
        elapsedSeconds: TimeInterval
    ) -> String? {
        guard kilometer > 0,
              splitSeconds.isFinite, splitSeconds > 0,
              elapsedSeconds.isFinite, elapsedSeconds > 0,
              elapsedSeconds >= splitSeconds
        else { return nil }

        let segmentSpeed = 3600 / splitSeconds
        guard segmentSpeed.isFinite else { return nil }
        var sentences = [
            "Kilómetro \(kilometer) completado.",
            "Tiempo del tramo: \(spokenDuration(splitSeconds)).",
            "Velocidad media del tramo: \(spokenSpeed(segmentSpeed)) kilómetros por hora."
        ]
        if kilometer > 1 {
            let overallSpeed = Double(kilometer) * 3600 / elapsedSeconds
            if overallSpeed.isFinite {
                sentences.append(
                    "Velocidad media desde el inicio: \(spokenSpeed(overallSpeed)) kilómetros por hora."
                )
            }
        }
        return sentences.joined(separator: " ")
    }

    private static func spokenSpeed(_ kmh: Double) -> String {
        String(format: "%.1f", locale: Locale(identifier: "es_ES"), kmh)
    }

    private static func spokenDuration(_ duration: TimeInterval) -> String {
        let rounded = Int(max(1, duration.rounded()))
        let hours = rounded / 3600
        let minutes = rounded % 3600 / 60
        let seconds = rounded % 60
        var parts: [String] = []
        if hours > 0 { parts.append("\(hours) hora\(hours == 1 ? "" : "s")") }
        if minutes > 0 { parts.append("\(minutes) minuto\(minutes == 1 ? "" : "s")") }
        if seconds > 0 || parts.isEmpty {
            parts.append("\(seconds) segundo\(seconds == 1 ? "" : "s")")
        }
        if parts.count == 1 { return parts[0] }
        return parts.dropLast().joined(separator: ", ") + " y " + (parts.last ?? "")
    }
}
