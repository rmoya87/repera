import Foundation

/// Deterministic extraction from text produced by the watchOS dictation
/// keyboard. No unreviewed spoken value is persisted as a workout result.
struct WatchSpokenSet: Equatable {
    var reps: Int?
    var weightKg: Double?

    static func parse(_ raw: String) -> WatchSpokenSet? {
        let normalized = raw.folding(
            options: [.diacriticInsensitive, .caseInsensitive],
            locale: Locale(identifier: "es_ES")
        ).lowercased().replacingOccurrences(of: ",", with: ".")
        let repetitions = numericValue(
            in: normalized,
            pattern: #"\b(\d{1,3})\s*(?:repeticion(?:es)?|repes|reps?|rpt)\b"#
        )
        let weight = numericValue(
            in: normalized,
            pattern: #"\b(\d{1,3}(?:\.\d{1})?)\s*(?:kg|kilos?|kilogramos?)\b"#
        )
        let reps = repetitions.flatMap { $0.rounded() == $0 && (0...500).contains($0) ? Int($0) : nil }
        let kilos = weight.flatMap { (0...500).contains($0) ? $0 : nil }
        guard reps != nil || kilos != nil else { return nil }
        return WatchSpokenSet(reps: reps, weightKg: kilos)
    }

    private static func numericValue(in value: String, pattern: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let text = value as NSString
        let range = NSRange(location: 0, length: text.length)
        guard let match = regex.firstMatch(in: value, range: range),
              match.numberOfRanges > 1 else { return nil }
        return Double(text.substring(with: match.range(at: 1)))
    }
}
