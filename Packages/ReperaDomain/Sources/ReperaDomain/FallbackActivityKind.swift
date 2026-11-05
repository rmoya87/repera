import Foundation

/// When a class/session has no exercise plan, Repera still records HealthKit
/// as gym strength training or HIIT — never an ambiguous “other” activity.
public enum FallbackActivityKind: String, Sendable, Codable, CaseIterable {
    /// Indoor gym / traditional strength (`LiveSport.strength`).
    case strength
    /// Interval / metcon-style class (`LiveSport.hiit`).
    case hiit

    /// Prefer HIIT when the title clearly signals intervals; otherwise gym.
    public static func resolving(title: String) -> FallbackActivityKind {
        let folded = title
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
        let hiitHints = [
            "hiit", "h.i.i.t", "tabata", "interval", "metcon",
            "crossfit", "cross fit", "hyrox", "wod", "circuito",
            "circuit", "emom", "amrap", "for time"
        ]
        if hiitHints.contains(where: folded.contains) { return .hiit }
        return .strength
    }

    public var liveSportID: String { rawValue }
}
