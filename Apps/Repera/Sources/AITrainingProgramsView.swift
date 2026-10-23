import Foundation
import Supabase
import SwiftUI

/// Read and accept the multi-week program framework. Daily workout proposals
/// remain separate and are never silently overwritten.
struct AITrainingProgramsView: View {
    @Environment(BusinessAuthStore.self) private var auth
    @State private var programs: [TrainingProgram] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var updatingId: UUID?

    private struct TrainingProgram: Decodable, Identifiable {
        let id: UUID
        let title: String
        let primaryGoal: String
        let startDate: String
        let startTimeZone: String?
        let durationWeeks: Int
        let phases: [Phase]
        let status: String
        let revision: Int
        enum CodingKeys: String, CodingKey {
            case id,title,phases,status,revision
            case primaryGoal = "primary_goal"
            case startDate = "start_date"
            case startTimeZone = "start_time_zone"
            case durationWeeks = "duration_weeks"
        }
    }
    private struct Phase: Decodable, Identifiable {
        let title: String
        let weeks: Int
        let focus: String
        let targetSessionsPerWeek: Int
        let progressionRule: String
        var id: String { title }
    }
    var body: some View {
        List {
            if isLoading && programs.isEmpty { ProgressView("Cargando programas…") }
            if !isLoading && programs.isEmpty {
                ContentUnavailableView("No hay programas de IA",
                    systemImage: "calendar.badge.plus",
                    description: Text("Cuando tu asistente cree un programa, aparecerá aquí para que lo revises."))
            }
            ForEach(programs) { program in
                Section {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(program.title).font(.headline)
                        Text("\(program.durationWeeks) semanas · desde \(program.startDate)" +
                             (program.startTimeZone.map { " · \($0)" } ?? ""))
                            .foregroundStyle(.secondary).font(.subheadline)
                        Text(program.primaryGoal).font(.subheadline)
                        Label(statusLabel(program.status), systemImage: "flag")
                            .font(.caption).foregroundStyle(.secondary)
                        ForEach(program.phases.indices, id: \.self) { ix in
                            let phase = program.phases[ix]
                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(phase.title) · \(phase.weeks) sem.").font(.subheadline.bold())
                                Text(phase.focus).font(.footnote)
                                Text("Sesiones/semana: \(phase.targetSessionsPerWeek)")
                                    .foregroundStyle(.secondary).font(.caption)
                            }
                        }
                    }.padding(.vertical, 6)
                    if program.status == "proposed" || program.status == "paused" {
                        Button("Activar programa") { Task { await change(program, to: "active") } }
                            .disabled(updatingId != nil)
                    } else if program.status == "active" {
                        Button("Pausar programa") { Task { await change(program, to: "paused") } }
                            .disabled(updatingId != nil)
                    }
                }
            }
            if let errorMessage {
                Text(errorMessage).font(.footnote).foregroundStyle(.red)
            }
        }
        .navigationTitle("Programas IA")
        .navigationBarTitleDisplayMode(.large)
        .ogTransparentNav()
        .toolbar {
            ToolbarItem(placement:.topBarTrailing) {
                Button { Task { await reload() } } label: {
                    Image(systemName:"arrow.clockwise")
                }.disabled(isLoading)
                .accessibilityLabel("Actualizar programas")
            }
        }
        .task { await reload() }
    }

    private func statusLabel(_ status: String) -> String {
        switch status {
        case "proposed": "Propuesto"
        case "active": "Activo"
        case "paused": "En pausa"
        case "completed": "Completado"
        case "cancelled": "Cancelado"
        default: status
        }
    }

    @MainActor private func reload() async {
        guard !isLoading, auth.isConnected, let client=auth.apiClient else { return }
        isLoading=true; defer { isLoading=false }
        do {
            let session=try await client.auth.session
            guard !session.isExpired else { return }
            let rows: [TrainingProgram] = try await client.from("athlete_training_programs")
                .select("id,title,primary_goal,start_date,start_time_zone,duration_weeks,phases,status,revision")
                .eq("owner_id",value:session.user.id.uuidString)
                .order("start_date",ascending:false).limit(100).execute().value
            guard auth.apiClient?.auth.currentSession?.user.id == session.user.id else { return }
            programs=rows
            errorMessage=nil
        } catch { errorMessage="No se pudieron cargar los programas: \(error.localizedDescription)" }
    }
    @MainActor private func change(_ item: TrainingProgram, to status: String) async {
        guard updatingId == nil, auth.isConnected, let client=auth.apiClient else { return }
        updatingId=item.id
        defer { updatingId=nil }
        do {
            let session=try await client.auth.session
            guard !session.isExpired else { return }
            try await client.from("athlete_training_programs")
                .update(["status":status])
                .eq("owner_id",value:session.user.id.uuidString)
                .eq("id",value:item.id.uuidString)
                .eq("revision",value:item.revision).execute()
            await reload()
        } catch { errorMessage="No se pudo actualizar el programa: \(error.localizedDescription)" }
    }
}
