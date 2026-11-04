import Foundation
import UserNotifications

/// Backup local reminder for an already confirmed booking. A backend push may
/// also exist, but it must have its own idempotency key. This scheduler never
/// sends network requests or stores athlete data outside notification metadata.
/// It only schedules after the signed-in owner has been verified by refresh().
@MainActor
enum BusinessBookingReminderScheduler {
    private static let prefix = "repera.booking.reminder."
    private static var generation = 0

    static func clear() {
        generation &+= 1
        let current = generation
        Task { @MainActor in
            let center = UNUserNotificationCenter.current()
            let pending = await center.pendingNotificationRequests()
            guard current == generation else { return }
            let identifiers = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
            if !identifiers.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: identifiers)
            }
        }
    }

    static func reconcile(
        userID: UUID,
        bookings: [BusinessBooking],
        occurrences: [BusinessOccurrence]
    ) async {
        generation &+= 1
        let current = generation
        let center = UNUserNotificationCenter.current()
        let occurrencesByID = Dictionary(uniqueKeysWithValues: occurrences.map { ($0.id, $0) })
        let now = Date()
        // 64 notifications is an iOS platform limit shared with other apps'
        // Repera notifications. Keep a small near-term budget.
        let upcoming: [(id: String, fire: Date)] = bookings.compactMap { booking in
            guard booking.status == "booked",
                  let occurrence = occurrencesByID[booking.occurrenceId],
                  occurrence.status == "active",
                  let start = BusinessDataStore.date(occurrence.startsAt) else { return nil }
            let fire = start.addingTimeInterval(-3600)
            guard fire > now.addingTimeInterval(10),
                  fire < now.addingTimeInterval(30 * 86400) else { return nil }
            return (prefix + userID.uuidString + "." + booking.id.uuidString, fire)
        }.sorted { $0.fire < $1.fire }.prefix(30).map { $0 }

        let desired = Set(upcoming.map(\.id))
        let pending = await center.pendingNotificationRequests()
        guard generation == current else { return }
        let existing = pending.filter { $0.identifier.hasPrefix(prefix) }
        let stale = existing.map(\.identifier).filter { !desired.contains($0) }
        if !stale.isEmpty { center.removePendingNotificationRequests(withIdentifiers: stale) }

        let settings = await center.notificationSettings()
        guard generation == current else { return }
        guard settings.authorizationStatus == .authorized ||
              settings.authorizationStatus == .provisional ||
              settings.authorizationStatus == .ephemeral else { return }

        // Always replace pending requests for this owner to account for
        // rescheduled sessions. Reconciliation is bounded to 30 items.
        let oldIDs = existing.map(\.identifier).filter { desired.contains($0) }
        if !oldIDs.isEmpty { center.removePendingNotificationRequests(withIdentifiers: oldIDs) }
        for item in upcoming {
            guard generation == current else { return }
            let content = UNMutableNotificationContent()
            content.title = "Tu sesión de Repera comienza en 1 hora"
            content.body = "Consulta tu reserva en Repera."
            content.sound = .default
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: item.fire
            )
            let request = UNNotificationRequest(
                identifier: item.id, content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            )
            try? await center.add(request)
        }
    }
}
