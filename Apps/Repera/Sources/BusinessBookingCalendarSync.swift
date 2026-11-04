import EventKit
import Foundation

/// Optional EventKit mirror of confirmed Center bookings.
/// Complements local −60 min UNUserNotification reminders; never invents events.
@MainActor
enum BusinessBookingCalendarSync {
    private static let prefix = "repera.booking.calendar."
    private static let store = EKEventStore()

    static func clear() {
        Task { await removeAllOwnedEvents() }
    }

    static func reconcile(
        userID: UUID,
        bookings: [BusinessBooking],
        occurrences: [BusinessOccurrence]
    ) async {
        let status = EKEventStore.authorizationStatus(for: .event)
        let allowed: Bool
        if status == .fullAccess || status == .writeOnly {
            allowed = true
        } else if status == .notDetermined {
            allowed = (try? await store.requestWriteOnlyAccessToEvents()) ?? false
        } else {
            return
        }
        guard allowed else { return }

        let occurrencesByID = Dictionary(uniqueKeysWithValues: occurrences.map { ($0.id, $0) })
        let desired: [(id: String, title: String, start: Date, end: Date)] = bookings.compactMap { booking in
            guard booking.status == "booked",
                  let occurrence = occurrencesByID[booking.occurrenceId],
                  occurrence.status == "active",
                  let start = BusinessDataStore.date(occurrence.startsAt) else { return nil }
            let end = BusinessDataStore.date(occurrence.endsAt) ?? start.addingTimeInterval(3600)
            let title = occurrence.title.isEmpty ? "Reserva Repera Center" : occurrence.title
            return (prefix + userID.uuidString + "." + booking.id.uuidString, title, start, end)
        }

        await removeStale(keeping: Set(desired.map(\.id)))
        guard let calendar = store.defaultCalendarForNewEvents else { return }
        for item in desired {
            let existing = findEvent(identifier: item.id)
            let event = existing ?? EKEvent(eventStore: store)
            event.calendar = calendar
            event.title = item.title
            event.startDate = item.start
            event.endDate = item.end
            event.notes = "Creado por Repera. No editar el identificador."
            event.url = URL(string: "repera://today")
            // Stable idempotency via notes tag when calendar item identifier rotates.
            if event.notes?.contains(item.id) != true {
                event.notes = (event.notes ?? "") + "\n" + item.id
            }
            do {
                try store.save(event, span: .thisEvent, commit: false)
            } catch {
                continue
            }
        }
        try? store.commit()
    }

    private static func findEvent(identifier: String) -> EKEvent? {
        let windowStart = Date().addingTimeInterval(-7 * 86400)
        let windowEnd = Date().addingTimeInterval(60 * 86400)
        let predicate = store.predicateForEvents(withStart: windowStart, end: windowEnd, calendars: nil)
        return store.events(matching: predicate).first { ($0.notes ?? "").contains(identifier) }
    }

    private static func removeStale(keeping: Set<String>) async {
        let windowStart = Date().addingTimeInterval(-7 * 86400)
        let windowEnd = Date().addingTimeInterval(60 * 86400)
        let predicate = store.predicateForEvents(withStart: windowStart, end: windowEnd, calendars: nil)
        for event in store.events(matching: predicate) {
            guard let notes = event.notes, notes.contains(prefix) else { continue }
            let stillWanted = keeping.contains { notes.contains($0) }
            if !stillWanted {
                try? store.remove(event, span: .thisEvent, commit: false)
            }
        }
        try? store.commit()
    }

    private static func removeAllOwnedEvents() async {
        await removeStale(keeping: [])
    }
}
