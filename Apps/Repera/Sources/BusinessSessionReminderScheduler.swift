import Foundation
import UserNotifications

/// Avisos locales de reservas propias. No solicita permisos por sorpresa:
/// los permisos los gestiona Ajustes y los envíos remotos siguen siendo otra capa.
@MainActor
enum BusinessSessionReminderScheduler {
    private static let prefix = "repera.booking.reminder."
    private static var generation = 0

    static func synchronize(
        bookings: [BusinessBooking],
        occurrences: [BusinessOccurrence]
    ) async {
        generation &+= 1
        let currentGeneration = generation
        let center = UNUserNotificationCenter.current()
        let active = Dictionary(uniqueKeysWithValues: occurrences.map { ($0.id, $0) })
        let now = Date()
        // Acotar iOS notification slots (máximo 64 pendientes del sistema).
        let upcoming: [(id: String, title: String, date: Date)] = bookings.compactMap { booking in
            guard booking.status == "booked",
                  let occurrence = active[booking.occurrenceId],
                  ["class", "appointment"].contains(occurrence.kind),
                  let start = BusinessDataStore.date(occurrence.startsAt),
                  start.timeIntervalSince(now) > 3_660,
                  start.timeIntervalSince(now) < 60 * 86_400 else { return nil }
            return (
                id: prefix + booking.id.uuidString,
                title: occurrence.title,
                date: start.addingTimeInterval(-3_600)
            )
        }
        .sorted { $0.date < $1.date }
        .prefix(40)
        .map { $0 }

        let pending = await withCheckedContinuation { (resume: CheckedContinuation<[UNNotificationRequest], Never>) in
            center.getPendingNotificationRequests { resume.resume(returning: $0) }
        }
        guard currentGeneration == generation else { return }
        let oldIDs = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        let desired = Set(upcoming.map(\.id))
        center.removePendingNotificationRequests(withIdentifiers: oldIDs.filter { !desired.contains($0) })
        let existing = Set(oldIDs)
        let settings = await center.notificationSettings()
        guard currentGeneration == generation,
              [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus)
        else { return }

        for item in upcoming where !existing.contains(item.id) {
            guard currentGeneration == generation else { return }
            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = "Tu sesión de Repera comienza en una hora."
            content.sound = .default
            content.userInfo = ["reperaBookingReminder": item.id]
            let delay = item.date.timeIntervalSinceNow
            guard delay > 60 else { continue }
            let request = UNNotificationRequest(
                identifier: item.id,
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            )
            try? await center.add(request)
        }
    }

    /// Se llama tras desvincular/cambiar de cuenta; no cancela otros temporizadores.
    static func cancelAll() async {
        generation &+= 1
        let center = UNUserNotificationCenter.current()
        let pending = await withCheckedContinuation { (resume: CheckedContinuation<[UNNotificationRequest], Never>) in
            center.getPendingNotificationRequests { resume.resume(returning: $0) }
        }
        center.removePendingNotificationRequests(
            withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        )
    }
}
