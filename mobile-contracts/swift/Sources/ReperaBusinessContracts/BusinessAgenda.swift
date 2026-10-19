import Foundation

/// Repera Business wire contract shared by Swift and Kotlin clients.
/// This is an ADDITIVE agenda overlay: it never replaces the athlete's LocalStore or iCloud JSON.
public struct BusinessAgendaEvent: Codable, Sendable, Hashable, Identifiable {
    public enum Kind: String, Codable, Sendable { case training, `class` }
    public let id: String
    public let kind: Kind
    public let date: String // yyyy-MM-dd in organization's timezone; not a UTC timestamp
    public let title: String
    public let source: String
    public let assignmentId: String?
    public let bookingId: String?
    public let exerciseText: String?
    public let deepLink: String

    enum CodingKeys: String, CodingKey {
        case id, kind, date, title, source
        case assignmentId = "assignment_id", bookingId = "booking_id"
        case exerciseText = "exercise_text", deepLink = "deep_link"
    }

    public init(id: String, kind: Kind, date: String, title: String, source: String = "professional",
                assignmentId: String? = nil, bookingId: String? = nil,
                exerciseText: String? = nil, deepLink: String) {
        self.id=id;self.kind=kind;self.date=date;self.title=title;self.source=source
        self.assignmentId=assignmentId;self.bookingId=bookingId;self.exerciseText=exerciseText;self.deepLink=deepLink
    }
    /// External URLs cannot be injected into Repera deep-link navigation.
    public var isValidLink: Bool {
        let allowed=["repera://diary/","repera://classes/","repera://today/","repera://passes/"]
        return allowed.contains(where: { deepLink.hasPrefix($0) }) && !deepLink.contains("?") && !deepLink.contains("#")
    }
}

public struct BusinessAgendaResponse: Codable, Sendable {
    public let schemaVersion: Int
    public let orgId: String
    public let clientId: String
    public let events: [BusinessAgendaEvent]
    public let cursor: String?

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version", orgId = "org_id", clientId = "client_id", events, cursor
    }
}

public enum BusinessAgendaMerger {
    /// Professional activities can be multiple per day; do not collapse into one local Routine.
    /// De-duplicates only identical provider IDs; unrelated personal workouts remain outside this list.
    public static func merge(existing: [BusinessAgendaEvent], incoming: [BusinessAgendaEvent]) -> [BusinessAgendaEvent] {
        var map = Dictionary(uniqueKeysWithValues: existing.filter(\.isValidLink).map { ($0.id, $0) })
        for item in incoming where item.isValidLink { map[item.id] = item }
        return map.values.sorted { ($0.date, $0.kind.rawValue, $0.id) < ($1.date, $1.kind.rawValue, $1.id) }
    }
}
