import Foundation
import Supabase
import SwiftUI

/// Minimal sports-only coaching preferences. Medical and HealthKit data are
/// intentionally not collected or sent to AI.
struct AITrainingProfileView: View {
    @Environment(BusinessAuthStore.self) private var auth
    @State private var goal = "general"
    @State private var experience = "unspecified"
    @State private var days = 3
    @State private var minutes = 60
    @State private var weekdays: Set<Int> = []
    @State private var equipmentText = ""
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var message: String?

    private let goals: [(String,String)] = [
        ("general","Condición física"), ("strength","Fuerza"),
        ("hypertrophy","Hipertrofia"), ("endurance","Resistencia"),
        ("crossfit","CrossFit"), ("weightlifting","Halterofilia"),
        ("mobility","Movilidad"),
    ]
    private let levels: [(String,String)] = [
        ("unspecified","Sin definir"), ("beginner","Principiante"),
        ("intermediate","Intermedio"), ("advanced","Avanzado"),
    ]
    private let weekdayNames = ["L", "M", "X", "J", "V", "S", "D"]

    private struct Record: Codable {
        let ownerId: UUID
        let primaryGoal: String
        let experienceLevel: String
        let trainingDaysPerWeek: Int?
        let preferredWeekdays: [Int]
        let sessionMinutes: Int?
        let equipment: [String]
        let coachingEnabled: Bool
        let updatedAt: Date

        enum CodingKeys: String, CodingKey {
            case equipment
            case ownerId = "owner_id"
            case primaryGoal = "primary_goal"
            case experienceLevel = "experience_level"
            case trainingDaysPerWeek = "training_days_per_week"
            case preferredWeekdays = "preferred_weekdays"
            case sessionMinutes = "session_minutes"
            case coachingEnabled = "coaching_enabled"
            case updatedAt = "updated_at"
        }
    }
    private struct Loaded: Decodable {
        let primaryGoal: String
        let experienceLevel: String
        let trainingDaysPerWeek: Int?
        let preferredWeekdays: [Int]
        let sessionMinutes: Int?
        let equipment: [String]
        enum CodingKeys: String, CodingKey {
            case equipment
            case primaryGoal = "primary_goal"
            case experienceLevel = "experience_level"
            case trainingDaysPerWeek = "training_days_per_week"
            case preferredWeekdays = "preferred_weekdays"
            case sessionMinutes = "session_minutes"
        }
    }

    var body: some View {
        Form {
            Section("Objetivos deportivos") {
                Picker("Objetivo principal", selection: $goal) {
                    ForEach(goals, id: \.0) { item in Text(item.1).tag(item.0) }
                }
                Picker("Nivel", selection: $experience) {
                    ForEach(levels, id: \.0) { item in Text(item.1).tag(item.0) }
                }
            }
            Section("Disponibilidad") {
                Stepper("Días por semana: \(days)", value: $days, in: 1...7)
                Stepper("Minutos por sesión: \(minutes)", value: $minutes, in: 15...240, step: 15)
                HStack(spacing: 8) {
                    ForEach(1...7, id: \.self) { value in
                        Button {
                            if weekdays.contains(value) { weekdays.remove(value) }
                            else { weekdays.insert(value) }
                        } label: {
                            Text(weekdayNames[value-1])
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity, minHeight: 34)
                                .background(weekdays.contains(value) ? Color.green.opacity(0.15) : Color.secondary.opacity(0.08),
                                            in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Día \(value) de la semana")
                    }
                }
            }
            Section("Material disponible") {
                TextField("Ej.: barra, mancuernas, anillas", text: $equipmentText, axis: .vertical)
                    .lineLimit(2...3)
            }
            Section {
                Button(isSaving ? "Guardando…" : "Guardar perfil") {
                    Task { await save() }
                }
                .disabled(isSaving || isLoading || !auth.isConnected)
                if let message {
                    Text(message).font(.footnote).foregroundStyle(.secondary)
                }
            } footer: {
                Text("Solo compartes objetivos y preferencias deportivas con los asistentes a los que autorices. Nunca se envían mediciones de Apple Salud ni datos médicos.")
            }
        }
        .navigationTitle("Perfil deportivo IA")
        .navigationBarTitleDisplayMode(.large)
        .task { await load() }
    }

    @MainActor
    private func load() async {
        guard !isLoading, auth.isConnected, let client=auth.apiClient else { return }
        isLoading=true
        defer { isLoading=false }
        do {
            let session=try await client.auth.session
            guard !session.isExpired else { return }
            let record: Loaded? = try await client.from("athlete_training_profiles")
                .select("primary_goal,experience_level,training_days_per_week,preferred_weekdays,session_minutes,equipment")
                .eq("owner_id",value:session.user.id.uuidString).maybeSingle().execute().value
            guard auth.apiClient?.auth.currentSession?.user.id == session.user.id else { return }
            if let record {
                goal=record.primaryGoal; experience=record.experienceLevel
                days=record.trainingDaysPerWeek ?? 3; minutes=record.sessionMinutes ?? 60
                weekdays=Set(record.preferredWeekdays)
                equipmentText=record.equipment.joined(separator:", ")
            }
        } catch { message="No se pudieron cargar tus preferencias. \(error.localizedDescription)" }
    }

    @MainActor
    private func save() async {
        guard !isSaving, auth.isConnected, let client=auth.apiClient else { return }
        isSaving=true
        defer { isSaving=false }
        do {
            let session=try await client.auth.session
            guard !session.isExpired else { throw ProfileError.sessionExpired }
            let equipment=Array(Set(equipmentText.split(separator:",").map {
                $0.trimmingCharacters(in:.whitespacesAndNewlines).lowercased()
            }.filter { !$0.isEmpty })).sorted().prefix(30)
            let record=Record(ownerId:session.user.id,primaryGoal:goal,experienceLevel:experience,
                              trainingDaysPerWeek:days,preferredWeekdays:weekdays.sorted(),
                              sessionMinutes:minutes,equipment:Array(equipment),coachingEnabled:true,
                              updatedAt:Date())
            try await client.from("athlete_training_profiles").upsert(record,onConflict:"owner_id").execute()
            guard auth.apiClient?.auth.currentSession?.user.id == session.user.id else { return }
            message="Perfil deportivo guardado."
        } catch { message="No se pudo guardar el perfil: \(error.localizedDescription)" }
    }
    private enum ProfileError: LocalizedError {
        case sessionExpired
        var errorDescription: String? { "Sesión caducada. Reconecta Supabase en Ajustes." }
    }
}
