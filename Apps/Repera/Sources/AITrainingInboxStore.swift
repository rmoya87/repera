import Foundation
import Observation
import ReperaDomain
import Supabase

/// The app's local-first importer for AI-authored plans. The server only writes
/// pending JSON plans; this actor translates them to exactly the same
/// ReperaDomain Routine/Block/Movement models that Diario and Inicio use.
@MainActor
@Observable
final class AITrainingInboxStore {
    static let shared = AITrainingInboxStore()
    private(set) var lastError: String?
    private(set) var importedCount = 0
    private(set) var conflicts: [String] = []
    private(set) var pendingCount = 0
    private(set) var isSyncing = false
    /// A small in-app banner informs the athlete as a new plan is imported.
    private(set) var lastImportedTitle: String?

    // The subscription belongs to the signed-in athlete, never to a service token.
    // Observation ignores networking internals while tracking visible state.
    @ObservationIgnored private var realtimeTask: Task<Void, Never>?
    @ObservationIgnored private var subscribedUserID: UUID?
    @ObservationIgnored private var realtimeGeneration = UUID()
    @ObservationIgnored private var retrySyncAfterCurrent = false

    private init() {}

    func dismissArrival() {
        lastImportedTitle = nil
    }

    /// Starts a single foreground-only, owner-filtered Realtime stream.
    /// Register before subscribing, then fetch pending plans to close the race
    /// between the previous sync and the websocket becoming active.
    func startRealtime(store: ReperaStore) {
        guard BusinessAuthStore.shared.isConnected,
              let client = BusinessAuthStore.shared.apiClient,
              let session = client.auth.currentSession, !session.isExpired,
              store.isHydrated, store.didCompleteInitialRemoteSync, !store.isSyncingiCloud else { return }

        let userID = session.user.id
        if realtimeTask != nil && subscribedUserID == userID { return }
        stopRealtime()
        subscribedUserID = userID
        let connectionID = UUID()
        realtimeGeneration = connectionID
        realtimeTask = Task { [weak self, weak store] in
            guard let self, let store else { return }
            // Random topic prevents a channel from a recently cancelled task
            // being inadvertently reused during account changes.
            let channel = client.realtimeV2.channel("ai-plans-\(UUID().uuidString)")
            let changes = channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "ai_training_plans",
                filter: .eq("owner_id", value: userID.uuidString.lowercased())
            )
            do {
                try await channel.subscribeWithError()
                if !Task.isCancelled, self.realtimeGeneration == connectionID,
                   self.subscribedUserID == userID,
                   BusinessAuthStore.shared.apiClient?.auth.currentSession?.user.id == userID {
                    _ = await self.sync(store: store)
                }
                for await _ in changes {
                    guard !Task.isCancelled,
                          self.realtimeGeneration == connectionID,
                          self.subscribedUserID == userID,
                          BusinessAuthStore.shared.isConnected,
                          BusinessAuthStore.shared.apiClient?.auth.currentSession?.user.id == userID
                    else { break }
                    _ = await self.sync(store: store)
                }
            } catch {
                if !Task.isCancelled, self.realtimeGeneration == connectionID {
                    self.lastError = "Recepción inmediata no disponible. Los planes se recuperarán al abrir Repera o al sincronizar."
                }
            }
            await client.realtimeV2.removeChannel(channel)
            if self.realtimeGeneration == connectionID {
                self.realtimeTask = nil
            }
        }
    }

    /// Always close the old user's channel on logout and when backgrounded.
    func stopRealtime() {
        realtimeTask?.cancel()
        realtimeTask = nil
        subscribedUserID = nil
        realtimeGeneration = UUID()
    }

    func clearSession() {
        stopRealtime()
        lastImportedTitle = nil
        retrySyncAfterCurrent = false
        lastError = nil
        importedCount = 0
        pendingCount = 0
        conflicts = []
    }

    private struct PlanRow: Decodable {
        let id: UUID
        let title: String
        let scheduledDate: String
        let scheduledTimeMinutes: Int?
        let payload: Payload

        enum CodingKeys: String, CodingKey {
            case id, title, payload
            case scheduledDate = "scheduled_date"
            case scheduledTimeMinutes = "scheduled_time_minutes"
        }
    }

    private struct Payload: Decodable {
        let schemaVersion: Int
        let blocks: [InputBlock]
    }
    private struct InputSet: Decodable {
        let reps: Int
        let weightKg: Double?
        let rir: Double?
        let percent1RM: Double?
        let percent1RMIsMinimum: Bool?
    }
    private struct InputExercise: Decodable {
        let name: String
        let catalogKey: String?
        let plannedSets: [InputSet]
        let restSeconds: Int?
    }
    private struct InputMovement: Decodable {
        let name: String
        let catalogKey: String?
        let reps: Int?
        let repScheme: [Int]?
        let distanceMeters: Int?
        let calories: Int?
        let weightMaleKg: Double?
        let weightFemaleKg: Double?
        let isRest: Bool?
        let restSeconds: Int?
        let scaleAlternative: String?
        let explicitPlannedSets: [InputSet]?
    }
    private struct InputBlock: Decodable {
        let title: String
        let kind: String
        let exercises: [InputExercise]
        let movements: [InputMovement]
        let wodFormat: String?
        let timeCapMinutes: Int?
        let emomIntervalSeconds: Int?
        let rounds: Int?
        let workSeconds: Int?
        let restSeconds: Int?
        let restBetweenRoundsSeconds: Int?
        let wodNotes: String?
    }
    private enum ImportError: LocalizedError {
        case invalidDate, invalidPayload
        var errorDescription: String? {
            switch self {
            case .invalidDate: "La fecha de la planificación no es válida."
            case .invalidPayload: "El entrenamiento recibido no cumple el formato Repera."
            }
        }
    }

    /// One deferred plan per calendar day; a conflicting user-written plan is
    /// never silently replaced. Pending plans can be retried after editing the day.
    func sync(store: ReperaStore) async -> Bool {
        if isSyncing {
            retrySyncAfterCurrent = true
            return false
        }
        guard store.isHydrated, store.didCompleteInitialRemoteSync, !store.isSyncingiCloud,
              BusinessAuthStore.shared.isConnected,
              let client = BusinessAuthStore.shared.apiClient else { return false }
        isSyncing = true
        defer {
            isSyncing = false
            if retrySyncAfterCurrent {
                retrySyncAfterCurrent = false
                Task { [weak self, weak store] in
                    guard let self, let store else { return }
                    _ = await self.sync(store: store)
                }
            }
        }
        do {
            let session = try await client.auth.session
            guard !session.isExpired else { return false }
            let uid = session.user.id
            let rows: [PlanRow] = try await client.from("ai_training_plans")
                .select("id,title,scheduled_date,scheduled_time_minutes,payload")
                .eq("owner_id", value: uid.uuidString)
                .eq("status", value: "pending")
                .order("scheduled_date")
                .limit(200)
                .execute().value
            guard BusinessAuthStore.shared.apiClient?.auth.currentSession?.user.id == uid else { return false }
            var imported = 0
            var reasons: [String] = []
            for row in rows {
                guard BusinessAuthStore.shared.isConnected,
                      client.auth.currentSession?.user.id == uid else { return false }
                do {
                    let date = try parseDay(row.scheduledDate)
                    // Same ID is idempotent after a lost ACK; never duplicate.
                    let existing = store.state.routines.contains { routine in
                        routine.id != row.id && routine.scheduledDate.map {
                            Calendar.current.isDate($0, inSameDayAs: date)
                        } == true
                    }
                    if existing {
                        reasons.append("\(row.scheduledDate): ya existe un entreno para ese día.")
                        continue
                    }
                    // An earlier sync may already have saved this exact native routine
                    // but lost the remote ACK. Never overwrite later user edits.
                    if !store.state.routines.contains(where: { $0.id == row.id }) {
                        let plan = try buildRoutine(row, date: date, store: store)
                        guard store.saveRoutine(plan) else {
                            reasons.append("\(row.scheduledDate): no se pudo guardar la rutina.")
                            continue
                        }
                    }
                    let result: [String: String] = [
                        "status": "applied",
                        "applied_at": ISO8601DateFormatter().string(from: Date())
                    ]
                    try await client.from("ai_training_plans")
                        .update(result)
                        .eq("owner_id", value: uid.uuidString)
                        .eq("id", value: row.id.uuidString)
                        .eq("status", value: "pending")
                        .execute()
                    imported += 1
                    lastImportedTitle = row.title
                } catch {
                    reasons.append("\(row.scheduledDate): \(error.localizedDescription)")
                }
            }
            importedCount = imported
            pendingCount = max(0, rows.count - imported)
            conflicts = reasons
            lastError = reasons.isEmpty ? nil : "Hay \(reasons.count) planes de IA pendientes de revisión."
            return reasons.isEmpty
        } catch {
            lastError = "No se pudieron sincronizar los planes de IA: \(error.localizedDescription)"
            return false
        }
    }

    private func parseDay(_ value: String) throws -> Date {
        let parts = value.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3, (2020...2100).contains(parts[0]),
              let date = Calendar.current.date(from: DateComponents(
                year: parts[0], month: parts[1], day: parts[2], hour: 12
              )),
              Calendar.current.component(.year, from: date) == parts[0],
              Calendar.current.component(.month, from: date) == parts[1],
              Calendar.current.component(.day, from: date) == parts[2] else {
            throw ImportError.invalidDate
        }
        return date
    }

    private func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "es_ES"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func planned(_ sets: [InputSet]) throws -> [PlannedSet] {
        guard !sets.isEmpty, sets.count <= 30,
              sets.allSatisfy({ $0.reps > 0 && $0.reps <= 5000 &&
                  ($0.weightKg == nil || ($0.weightKg!.isFinite && $0.weightKg! >= 0)) &&
                  ($0.rir == nil || ($0.rir!.isFinite && (0...10).contains($0.rir!))) &&
                  ($0.percent1RM == nil || ($0.percent1RM!.isFinite && (1...150).contains($0.percent1RM!))) })
        else { throw ImportError.invalidPayload }
        return sets.map { PlannedSet(targetReps: $0.reps,
                                      targetWeightKg: $0.weightKg,
                                      targetRir: $0.rir,
                                      targetPercent1RM: $0.percent1RM,
                                      targetPercent1RMIsMinimum: $0.percent1RMIsMinimum ?? false) }
    }

    private func catalogExercise(name: String, key: String?, store: ReperaStore) -> Exercise {
        if let key, let exact = store.state.exercises.first(where: { $0.catalogId == key }) {
            return exact
        }
        if let named = store.state.exercises.first(where: { normalize($0.name) == normalize(name) }) {
            return named
        }
        // Free/unmapped exercise: native app supports locally-defined movements.
        // It remains usable/editable in the same block and workout logger.
        let free = Exercise(name: name, muscleGroup: "Otros", isCustom: true)
        store.state.exercises.append(free)
        return free
    }

    private func buildRoutine(_ row: PlanRow, date: Date, store: ReperaStore) throws -> Routine {
        let payload = row.payload
        guard payload.schemaVersion == 1, (1...12).contains(payload.blocks.count),
              !row.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { throw ImportError.invalidPayload }
        var blocks: [RoutineBlock] = []
        for b in payload.blocks {
            guard !b.title.isEmpty else { throw ImportError.invalidPayload }
            switch b.kind {
            case "strength":
                guard !b.exercises.isEmpty, b.movements.isEmpty else { throw ImportError.invalidPayload }
                let exercises = try b.exercises.map { entry -> RoutineExercise in
                    guard !entry.name.isEmpty else { throw ImportError.invalidPayload }
                    let sets = try planned(entry.plannedSets)
                    let exercise = catalogExercise(name: entry.name, key: entry.catalogKey, store: store)
                    return RoutineExercise(exerciseId: exercise.id, plannedSets: sets, restSeconds: entry.restSeconds)
                }
                blocks.append(RoutineBlock(title: b.title, kind: .strength, exercises: exercises))
            case "wod":
                guard b.exercises.isEmpty, !b.movements.isEmpty,
                      let raw = b.wodFormat, let format = WODFormat(rawValue: raw)
                else { throw ImportError.invalidPayload }
                let moves = try b.movements.map { entry -> WODMovement in
                    guard !entry.name.isEmpty else { throw ImportError.invalidPayload }
                    let isRest = entry.isRest ?? false
                    let exercise = isRest ? nil : catalogExercise(name: entry.name, key: entry.catalogKey, store: store)
                    let explicit = try entry.explicitPlannedSets.map { try planned($0) }
                    return WODMovement(
                        exerciseId: exercise?.id,
                        name: entry.name,
                        reps: entry.reps,
                        repScheme: entry.repScheme,
                        distanceMeters: entry.distanceMeters,
                        calories: entry.calories,
                        weightMaleKg: entry.weightMaleKg,
                        weightFemaleKg: entry.weightFemaleKg,
                        isRest: isRest,
                        restSeconds: entry.restSeconds,
                        scaleAlternative: entry.scaleAlternative,
                        explicitPlannedSets: explicit
                    )
                }
                var block = RoutineBlock(
                    title: b.title, kind: .wod, movements: moves, wodFormat: format,
                    timeCapMinutes: b.timeCapMinutes,
                    emomIntervalSeconds: b.emomIntervalSeconds,
                    rounds: b.rounds, workSeconds: b.workSeconds,
                    restSeconds: b.restSeconds,
                    restBetweenRoundsSeconds: b.restBetweenRoundsSeconds,
                    wodNotes: b.wodNotes
                )
                block.deriveEmomRoundsIfNeeded()
                blocks.append(block)
            default: throw ImportError.invalidPayload
            }
        }
        return Routine(
            id: row.id,
            title: row.title, weekday: nil,
            scheduledDate: date,
            scheduledTimeMinutes: row.scheduledTimeMinutes,
            blocks: blocks,
            progression: .off
        )
    }
}
