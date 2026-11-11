import Foundation
import UserNotifications
import ReperaDomain

/// Native system notifications when an AI connection creates, updates or
/// deletes a workout. Replaces the in-app floating banner; deep links open
/// the concrete session, or Inicio on that day after a delete.
enum AIChangeNotifier {
    static let openEvent = Notification.Name("repera.openAIChangeTarget")
    static let openWorkoutEvent = Notification.Name("repera.openAIWorkoutDetail")
    static let openRoutineEvent = Notification.Name("repera.openAIRoutineDetail")
    static let pendingKey = "repera.pendingAIChangeOpen"
    static let pendingWorkoutKey = "repera.pendingAIChangeWorkout"
    static let pendingRoutineKey = "repera.pendingAIChangeRoutine"
    private static let notifiedKey = "repera.ai.notifiedChangeIds"
    private static let prefix = "repera.ai.change."
    private static let fallbackConnection = "Tu asistente"

    enum Kind: String {
        case create
        case update
        case delete
    }

    struct Target: Equatable {
        var kind: Kind
        var workoutId: UUID?
        var routineId: UUID?
        var day: String?
    }

    static func connectionLabel(_ raw: String?) -> String {
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? fallbackConnection : trimmed
    }

    static func notifyCreate(
        planId: UUID,
        title: String,
        day: String,
        connectionName: String?
    ) {
        guard markNotified(planId) else { return }
        let name = connectionLabel(connectionName)
        schedule(
            id: planId,
            title: "\(name) ha añadido un entreno",
            body: title,
            kind: .create,
            workoutId: nil,
            routineId: planId,
            day: day
        )
    }

    static func notifyPendingChanges(
        _ changes: [AIChangeRequestStore.Change],
        connectionNames: [UUID: String],
        workouts: [WorkoutSession]
    ) {
        for change in changes {
            guard change.operation == "update_workout"
                || change.operation == "delete_workout" else { continue }
            guard markNotified(change.id) else { continue }
            let name = connectionLabel(
                change.tokenId.flatMap { connectionNames[$0] }
            )
            let workoutTitle = change.payload.workoutTitle?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let workout = change.targetId.flatMap { id in
                workouts.first(where: { $0.id == id })
            }
            let day = workout.flatMap { session -> String? in
                guard let date = session.finishedAt ?? session.startedAt else { return nil }
                return Self.dayKey(date)
            }
            if change.operation == "delete_workout" {
                schedule(
                    id: change.id,
                    title: "\(name) pide eliminar un entreno",
                    body: "«\(workoutTitle?.isEmpty == false ? workoutTitle! : "entrenamiento")» · confirma para borrarlo",
                    kind: .delete,
                    workoutId: change.targetId,
                    routineId: nil,
                    day: day
                )
            } else {
                let detail: String
                if let workoutTitle, !workoutTitle.isEmpty {
                    let sets = change.payload.setChanges?.count ?? 0
                    detail = sets > 0
                        ? "\(workoutTitle) · \(sets) series · revisa y aplica"
                        : workoutTitle
                } else {
                    detail = "Revisa y aplica el cambio"
                }
                schedule(
                    id: change.id,
                    title: "\(name) quiere corregir un entreno",
                    body: detail,
                    kind: .update,
                    workoutId: change.targetId,
                    routineId: nil,
                    day: day
                )
            }
        }
    }

    static func takePending() -> Target? {
        guard let data = UserDefaults.standard.data(forKey: pendingKey),
              let raw = try? JSONDecoder().decode(PendingPayload.self, from: data)
        else { return nil }
        UserDefaults.standard.removeObject(forKey: pendingKey)
        guard let kind = Kind(rawValue: raw.kind) else { return nil }
        return Target(
            kind: kind,
            workoutId: raw.workoutId.flatMap(UUID.init(uuidString:)),
            routineId: raw.routineId.flatMap(UUID.init(uuidString:)),
            day: raw.day
        )
    }

    static func handleNotificationResponse(
        _ response: UNNotificationResponse
    ) -> Bool {
        let info = response.notification.request.content.userInfo
        guard let kindRaw = info["aiChangeKind"] as? String,
              let kind = Kind(rawValue: kindRaw) else { return false }
        let payload = PendingPayload(
            kind: kind.rawValue,
            workoutId: info["workoutId"] as? String,
            routineId: info["routineId"] as? String,
            day: info["day"] as? String
        )
        if let data = try? JSONEncoder().encode(payload) {
            UserDefaults.standard.set(data, forKey: pendingKey)
        }
        let target = Target(
            kind: kind,
            workoutId: payload.workoutId.flatMap(UUID.init(uuidString:)),
            routineId: payload.routineId.flatMap(UUID.init(uuidString:)),
            day: payload.day
        )
        Task { @MainActor in
            NotificationCenter.default.post(name: openEvent, object: target)
        }
        return true
    }

    static func clearNotifiedCache() {
        UserDefaults.standard.removeObject(forKey: notifiedKey)
        UserDefaults.standard.removeObject(forKey: pendingKey)
        UserDefaults.standard.removeObject(forKey: pendingWorkoutKey)
        UserDefaults.standard.removeObject(forKey: pendingRoutineKey)
    }

    static func queueOpenWorkout(_ id: UUID) {
        UserDefaults.standard.set(id.uuidString, forKey: pendingWorkoutKey)
        NotificationCenter.default.post(name: openWorkoutEvent, object: id)
    }

    static func queueOpenRoutine(_ id: UUID) {
        UserDefaults.standard.set(id.uuidString, forKey: pendingRoutineKey)
        NotificationCenter.default.post(name: openRoutineEvent, object: id)
    }

    static func takePendingWorkout() -> UUID? {
        guard let raw = UserDefaults.standard.string(forKey: pendingWorkoutKey),
              let id = UUID(uuidString: raw) else { return nil }
        UserDefaults.standard.removeObject(forKey: pendingWorkoutKey)
        return id
    }

    static func takePendingRoutine() -> UUID? {
        guard let raw = UserDefaults.standard.string(forKey: pendingRoutineKey),
              let id = UUID(uuidString: raw) else { return nil }
        UserDefaults.standard.removeObject(forKey: pendingRoutineKey)
        return id
    }

    static func dayKey(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            parts.year ?? 0, parts.month ?? 0, parts.day ?? 0
        )
    }

    static func parseDay(_ value: String) -> Date? {
        let parts = value.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return Calendar.current.date(
            from: DateComponents(year: parts[0], month: parts[1], day: parts[2])
        ).map { Calendar.current.startOfDay(for: $0) }
    }

    private struct PendingPayload: Codable {
        var kind: String
        var workoutId: String?
        var routineId: String?
        var day: String?
    }

    private static func markNotified(_ id: UUID) -> Bool {
        var seen = Set(UserDefaults.standard.stringArray(forKey: notifiedKey) ?? [])
        let key = id.uuidString.lowercased()
        if seen.contains(key) { return false }
        seen.insert(key)
        if seen.count > 400 {
            seen = Set(seen.suffix(300))
        }
        UserDefaults.standard.set(Array(seen), forKey: notifiedKey)
        return true
    }

    private static func schedule(
        id: UUID,
        title: String,
        body: String,
        kind: Kind,
        workoutId: UUID?,
        routineId: UUID?,
        day: String?
    ) {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                _ = try? await center.requestAuthorization(options: [.alert, .sound])
            }
            let authorized = await center.notificationSettings()
            guard [.authorized, .provisional, .ephemeral]
                .contains(authorized.authorizationStatus) else { return }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            var info: [String: String] = ["aiChangeKind": kind.rawValue]
            if let workoutId { info["workoutId"] = workoutId.uuidString }
            if let routineId { info["routineId"] = routineId.uuidString }
            if let day { info["day"] = day }
            content.userInfo = info
            let request = UNNotificationRequest(
                identifier: prefix + id.uuidString,
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
            )
            try? await center.add(request)
        }
    }
}
