import Foundation
import Observation
import ReperaDomain
import Supabase

/// AI cannot mutate finished workouts or personal exercises on its own.
/// These commands become native changes only after the athlete taps Apply.
@MainActor @Observable
final class AIChangeRequestStore {
    static let shared = AIChangeRequestStore()
    private(set) var pending: [Change] = []
    private(set) var isBusy = false
    var lastError: String?
    private init() {}

    struct SetChange: Decodable {
        let exerciseEntryId: UUID
        let loggedSetId: UUID
        let reps: Int?
        let weightKg: Double?
        let rir: Double?
        let clearWeight: Bool?
        let clearRir: Bool?
    }
    struct Payload: Decodable {
        let title: String?
        let workoutTitle: String?
        let setChanges: [SetChange]?
        let name: String?
        let muscleGroup: String?
        let equipment: String?
        let targetMuscle: String?
        let secondaryMuscles: [String]?
    }
    struct Change: Decodable, Identifiable {
        let id: UUID
        let operation: String
        let targetId: UUID?
        let expectedUpdatedAt: Date?
        let payload: Payload
        let createdAt: Date
        enum CodingKeys: String, CodingKey {
            case id,operation,payload
            case targetId = "target_id"
            case expectedUpdatedAt = "expected_updated_at"
            case createdAt = "created_at"
        }
        var summary: String {
            switch operation {
            case "update_workout": "Corregir: \(payload.workoutTitle ?? "entrenamiento")"
            case "delete_workout": "Eliminar: \(payload.workoutTitle ?? "entrenamiento registrado")"
            case "create_exercise": "Añadir ejercicio: \(payload.name ?? "")"
            case "update_exercise": "Editar ejercicio personalizado: \(payload.name ?? "")"
            case "delete_exercise": "Eliminar ejercicio: \(payload.name ?? "personalizado")"
            default: "Cambio solicitado"
            }
        }
        var isDestructive: Bool {
            operation == "delete_workout" || operation == "delete_exercise"
        }
    }
    private struct MirrorExercise: Encodable {
        let ownerId: UUID
        let exerciseId: UUID
        let name: String
        let muscleGroup: String
        let equipment: String?
        let targetMuscle: String?
        let secondaryMuscles: [String]
        let updatedAt: Date
        enum CodingKeys: String, CodingKey {
            case name,equipment
            case ownerId = "owner_id"
            case exerciseId = "exercise_id"
            case muscleGroup = "muscle_group"
            case targetMuscle = "target_muscle"
            case secondaryMuscles = "secondary_muscles"
            case updatedAt = "updated_at"
        }
    }
    private struct ExistingExercise: Decodable {
        let exerciseId: UUID
        enum CodingKeys: String, CodingKey { case exerciseId = "exercise_id" }
    }
    private struct MirrorRevision: Decodable {
        let updatedAt: Date
        let deletedAt: Date?
        enum CodingKeys: String, CodingKey {
            case updatedAt = "updated_at"
            case deletedAt = "deleted_at"
        }
    }
    private struct Decision: Encodable {
        let status: String
        let decidedAt: Date
        let decisionMessage: String
        enum CodingKeys: String, CodingKey {
            case status
            case decidedAt = "decided_at"
            case decisionMessage = "decision_message"
        }
    }

    private func ackKey(_ owner:UUID) -> String {
        "repera.ai.change.acks.\(owner.uuidString.lowercased())"
    }
    private func awaitingAck(_ owner:UUID) -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey:ackKey(owner)) ?? [])
    }
    private func queueAck(_ owner:UUID,_ id:UUID) {
        var outstanding=awaitingAck(owner)
        outstanding.insert(id.uuidString)
        UserDefaults.standard.set(Array(outstanding),forKey:ackKey(owner))
    }
    private func removeAck(_ owner:UUID,_ id:UUID) {
        var outstanding=awaitingAck(owner)
        outstanding.remove(id.uuidString)
        UserDefaults.standard.set(Array(outstanding),forKey:ackKey(owner))
    }
    func clearSession() { pending=[];lastError=nil }

    func refresh(store: ReperaStore) async {
        guard !isBusy,store.isHydrated,store.didCompleteInitialRemoteSync,
              !store.isSyncingiCloud,BusinessAuthStore.shared.isConnected,
              let client=BusinessAuthStore.shared.apiClient else {return}
        do {
            let session=try await client.auth.session
            guard !session.isExpired else {return}
            let rows: [Change]=try await client.from("ai_athlete_change_requests")
                .select("id,operation,target_id,expected_updated_at,payload,created_at")
                .eq("owner_id",value:session.user.id.uuidString)
                .eq("status",value:"pending")
                .order("created_at").limit(100).execute().value
            guard client.auth.currentSession?.user.id==session.user.id else {return}
            // Replay persisted ACKs when local change succeeded but network
            // failed: never re-delete HealthKit workouts on retry.
            let awaiting=awaitingAck(session.user.id)
            for row in rows where awaiting.contains(row.id.uuidString) {
                let update=Decision(status:"applied",decidedAt:Date(),
                                    decisionMessage:"Aplicado localmente tras consentimiento")
                do {
                    try await client.from("ai_athlete_change_requests").update(update)
                        .eq("id",value:row.id.uuidString)
                        .eq("owner_id",value:session.user.id.uuidString)
                        .eq("status",value:"pending").execute()
                    removeAck(session.user.id,row.id)
                } catch { /* Preserved until the next account sync */ }
            }
            pending=rows.filter{ !awaiting.contains($0.id.uuidString) }
            lastError=nil
        } catch {lastError="No se pudieron recuperar los cambios propuestos: \(error.localizedDescription)"}
    }

    /// Mirror ONLY user-authored custom exercises. The global curated catalog
    /// remains immutable; no Apple Health, location or private workout notes.
    @discardableResult
    func syncCustomExercises(store:ReperaStore) async -> Bool {
        guard store.isHydrated,store.didCompleteInitialRemoteSync,!store.isSyncingiCloud,
              BusinessAuthStore.shared.isConnected,
              let client=BusinessAuthStore.shared.apiClient else {return false}
        do {
            let session=try await client.auth.session
            guard !session.isExpired else {return false}
            let id=session.user.id
            let custom=store.state.exercises.filter(\.isCustom)
            guard custom.count<=1000 else {return false}
            let rows=custom.map {
                MirrorExercise(ownerId:id,exerciseId:$0.id,name:$0.name,
                               muscleGroup:$0.muscleGroup,equipment:$0.equipment,
                               targetMuscle:$0.targetMuscle,
                               secondaryMuscles:$0.secondaryMuscles,
                               updatedAt:Date())
            }
            for chunk in stride(from:0,to:rows.count,by:40) {
                try await client.from("athlete_custom_exercise_mirror")
                    .upsert(Array(rows[chunk..<min(chunk+40,rows.count)]),
                            onConflict:"owner_id,exercise_id").execute()
            }
            let stored:[ExistingExercise]=try await client.from("athlete_custom_exercise_mirror")
                .select("exercise_id").eq("owner_id",value:id.uuidString)
                .limit(1001).execute().value
            guard stored.count<=1000 else {return false}
            let ids=Set(custom.map(\.id))
            for remote in stored where !ids.contains(remote.exerciseId) {
                guard client.auth.currentSession?.user.id==id else {return false}
                try await client.from("athlete_custom_exercise_mirror").delete()
                    .eq("owner_id",value:id.uuidString)
                    .eq("exercise_id",value:remote.exerciseId.uuidString).execute()
            }
            return client.auth.currentSession?.user.id==id
        } catch {lastError="Catálogo personalizado pendiente: \(error.localizedDescription)";return false}
    }

    func decide(_ request:Change,approve:Bool,store:ReperaStore) async -> Bool {
        guard !isBusy,BusinessAuthStore.shared.isConnected,
              let client=BusinessAuthStore.shared.apiClient else {return false}
        isBusy=true
        defer {isBusy=false}
        do {
            let session=try await client.auth.session
            let owner=session.user.id
            guard !session.isExpired,client.auth.currentSession?.user.id==owner,
                  pending.contains(where:{$0.id==request.id}) else {return false}
            var status="rejected"
            var message="Rechazado por el deportista"
            if approve {
                // A client auth identity cannot act on anybody else's queue.
                if request.operation=="update_workout"||request.operation=="delete_workout" {
                    guard let id=request.targetId,let local=store.state.workouts.first(where:{$0.id==id}),
                          local.finishedAt != nil else {
                        lastError="El entrenamiento ya no está disponible en este dispositivo."
                        return false
                    }
                    let remote:MirrorRevision?=try await client.from("athlete_workout_mirror")
                        .select("updated_at,deleted_at")
                        .eq("owner_id",value:owner.uuidString)
                        .eq("id",value:id.uuidString).maybeSingle().execute().value
                    guard let remote,remote.deletedAt==nil,
                          let expected=request.expectedUpdatedAt,
                          abs(remote.updatedAt.timeIntervalSince(expected))<0.02 else {
                        lastError="La revisión del entrenamiento cambió. Rechaza la solicitud y pide una nueva."
                        return false
                    }
                    if request.operation=="delete_workout" {
                        store.deleteWorkout(id)
                    } else {
                        var changed=local
                        if let title=request.payload.title {changed.title=title}
                        for patch in request.payload.setChanges ?? [] {
                            guard let ei=changed.exercises.firstIndex(where:{$0.id==patch.exerciseEntryId}),
                                  let si=changed.exercises[ei].loggedSets.firstIndex(where:{$0.id==patch.loggedSetId}) else {
                                lastError="Una serie ya no coincide con el entrenamiento actual."
                                return false
                            }
                            var set=changed.exercises[ei].loggedSets[si]
                            if patch.reps != nil && (!set.drops.isEmpty || !set.clusters.isEmpty) {
                                lastError="Las series drop/rest-pause deben editarse manualmente."
                                return false
                            }
                            if let reps=patch.reps {set.reps=reps}
                            if let weight=patch.weightKg {set.weightKg=weight}
                            if patch.clearWeight==true {set.weightKg=nil}
                            if let rir=patch.rir {set.rir=rir;set.toFailure=false}
                            if patch.clearRir==true {set.rir=nil;set.toFailure=false}
                            changed.exercises[ei].loggedSets[si]=set
                        }
                        for index in changed.exercises.indices {
                            changed.exercises[index].completedReps=changed.exercises[index].loggedSets.reduce(0){$0+$1.reps}
                        }
                        store.saveWorkout(changed)
                    }
                } else {
                    let p=request.payload
                    if request.operation=="create_exercise" {
                        guard let name=p.name,let muscle=p.muscleGroup,
                              store.addCustomExercise(name:name,muscleGroup:muscle,
                                equipment:p.equipment,targetMuscle:p.targetMuscle,
                                secondaryMuscles:p.secondaryMuscles ?? [],id:request.id)
                        else {lastError="El límite de ejercicios personalizados impide crear este ejercicio.";return false}
                    } else if request.operation=="update_exercise" {
                        guard let id=request.targetId,let name=p.name,let muscle=p.muscleGroup,
                              store.updateCustomExercise(id:id,name:name,muscleGroup:muscle,
                                equipment:p.equipment,targetMuscle:p.targetMuscle,
                                secondaryMuscles:p.secondaryMuscles ?? [])
                        else {lastError="El ejercicio personalizado ya no existe.";return false}
                    } else if request.operation=="delete_exercise" {
                        guard let id=request.targetId,store.state.exercises.contains(where:{$0.id==id && $0.isCustom})
                        else {lastError="El ejercicio personalizado ya no existe.";return false}
                        store.deleteExercise(id)
                    } else {return false}
                    // The native operation has succeeded. A mirror upload
                    // failure cannot cause an already performed deletion to
                    // be re-executed on the next approval attempt.
                    _ = await syncCustomExercises(store:store)
                }
                status="applied";message="Aplicado localmente tras consentimiento"
                queueAck(owner,request.id)
            }
            let update=Decision(status:status,decidedAt:Date(),decisionMessage:message)
            try await client.from("ai_athlete_change_requests").update(update)
                .eq("id",value:request.id.uuidString)
                .eq("owner_id",value:owner.uuidString)
                .eq("status",value:"pending").execute()
            if approve {removeAck(owner,request.id)}
            pending.removeAll{$0.id==request.id}
            lastError=nil
            return true
        }catch {
            lastError="No se pudo confirmar el cambio: \(error.localizedDescription)"
            return false
        }
    }
}
