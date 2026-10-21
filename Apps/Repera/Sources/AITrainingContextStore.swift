import CryptoKit
import Foundation
import ReperaDomain
import Supabase

/// A strictly sporting, low-detail calendar mirror for AI scheduling.
/// The iPhone/iCloud remains authoritative: we never sync private notes,
/// workout locations, routes, HealthKit or raw body measurements.
@MainActor
final class AITrainingContextStore {
    static let shared = AITrainingContextStore()
    private var lastSnapshot: Data?
    private var lastOwner: UUID?
    private var syncing = false
    private var retry = false
    private init() {}

    func clearSession() {
        lastOwner = nil
        lastSnapshot = nil
        retry = false
    }

    private struct Planned: Encodable {
        let reps: Int
        let weightKg: Double?
        let rir: Double?
    }
    private struct Movement: Encodable {
        let name: String
        let catalogKey: String?
        let reps: Int?
        let distanceMeters: Int?
        let calories: Int?
    }
    private struct StrengthExercise: Encodable {
        let name: String
        let catalogKey: String?
        let plannedSets: [Planned]
    }
    private struct Block: Encodable {
        let kind: String
        let title: String
        let wodFormat: String?
        let strengthExercises: [StrengthExercise]
        let movements: [Movement]
        let rounds: Int?
        let timeCapMinutes: Int?
    }
    private struct DayItem: Encodable {
        let routineId: UUID
        let title: String
        let scheduledDate: String?
        let weekday: Int?
        let scheduledTimeMinutes: Int?
        let blocks: [Block]
    }
    private struct Snapshot: Encodable {
        let ownerId: UUID
        let items: [DayItem]
        let horizonStart: String
        let horizonEnd: String
        let updatedAt: Date

        enum CodingKeys: String, CodingKey {
            case items
            case ownerId = "owner_id"
            case horizonStart = "horizon_start"
            case horizonEnd = "horizon_end"
            case updatedAt = "updated_at"
        }
    }

    private func day(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year,.month,.day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    func syncCalendar(store: ReperaStore) async -> Bool {
        guard store.isHydrated, store.didCompleteInitialRemoteSync, !store.isSyncingiCloud,
              BusinessAuthStore.shared.isConnected,
              let client = BusinessAuthStore.shared.apiClient else { return false }
        if syncing { retry = true; return false }
        syncing = true
        defer {
            syncing = false
            if retry {
                retry = false
                Task { [weak self, weak store] in
                    guard let self, let store else { return }
                    _ = await self.syncCalendar(store: store)
                }
            }
        }
        do {
            let session = try await client.auth.session
            guard !session.isExpired, client.auth.currentSession?.user.id == session.user.id else { return false }
            let today = Calendar.current.startOfDay(for: Date())
            let end = Calendar.current.date(byAdding: .day, value: 90, to: today) ?? today
            let catalog = Dictionary(uniqueKeysWithValues: store.state.exercises.map { ($0.id, $0) })
            let items: [DayItem] = store.state.routines.compactMap { routine in
                guard routine.scheduledDate != nil || routine.weekday != nil,
                      routine.scheduledDate == nil || (routine.scheduledDate! >= today && routine.scheduledDate! <= end) else { return nil }
                let blocks = routine.blocks.map { block in
                    let strength: [StrengthExercise] = block.exercises.map { e in
                        let movement = catalog[e.exerciseId]
                        return StrengthExercise(
                            name: movement?.name ?? "Ejercicio sin catálogo",
                            catalogKey: movement?.catalogId,
                            plannedSets: e.plannedSets.map {
                                Planned(reps: $0.targetReps, weightKg: $0.targetWeightKg, rir: $0.targetRir)
                            }
                        )
                    }
                    let moves = block.movements.map { m in
                        let movement = m.exerciseId.flatMap { catalog[$0] }
                        return Movement(name: m.name, catalogKey: movement?.catalogId,
                                        reps: m.reps, distanceMeters: m.distanceMeters, calories: m.calories)
                    }
                    return Block(kind: block.kind.rawValue, title: block.title,
                                 wodFormat: block.wodFormat?.rawValue, strengthExercises: strength,
                                 movements: moves, rounds: block.rounds, timeCapMinutes: block.timeCapMinutes)
                }
                return DayItem(routineId: routine.id, title: routine.title,
                               scheduledDate: routine.scheduledDate.map(day), weekday: routine.weekday,
                               scheduledTimeMinutes: routine.scheduledTimeMinutes, blocks: blocks)
            }
            guard items.count <= 500 else { return false }
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            // Compare contents without updatedAt: subsequent manual syncs do not rewrite identical snapshots.
            let comparable = try encoder.encode(items)
            if lastOwner == session.user.id && lastSnapshot == comparable { return true }
            let snapshot = Snapshot(ownerId: session.user.id, items: items,
                                    horizonStart: day(today), horizonEnd: day(end), updatedAt: Date())
            guard client.auth.currentSession?.user.id == session.user.id else { return false }
            try await client.from("athlete_training_calendar_snapshots")
                .upsert(snapshot, onConflict: "owner_id").execute()
            lastSnapshot = comparable
            lastOwner = session.user.id
            return true
        } catch {
            // Local planning is never blocked by an unavailable AI mirror.
            return false
        }
    }
}
