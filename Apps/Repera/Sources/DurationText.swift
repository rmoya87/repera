import Foundation

/// Formato `m:ss` / parseo para series de comba, bike, etc.
enum DurationText {
    static func format(_ seconds: Int?) -> String {
        let s = max(0, seconds ?? 0)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    /// Acepta `m:ss`, `mm:ss` o segundos sueltos.
    static func parse(_ text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "—" else { return nil }
        if trimmed.contains(":") {
            let parts = trimmed.split(separator: ":", omittingEmptySubsequences: false)
            guard parts.count == 2,
                  let m = Int(parts[0].filter(\.isNumber)),
                  let s = Int(parts[1].filter(\.isNumber))
            else { return nil }
            return max(0, m * 60 + min(59, s))
        }
        let digits = trimmed.filter { $0.isNumber || $0 == "," || $0 == "." }
        guard let value = Int(digits) else { return nil }
        return max(0, value)
    }
}
