import Foundation
import SwiftUI
import Supabase

/// OAuth consent is independent from coach/gym workout-sharing consent.
/// This screen can revoke access without sharing Apple Health or location data.
private struct MCPConsentRow: Decodable, Identifiable {
    let clientId: String
    let enabled: Bool

    var id: String { clientId }

    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case enabled
    }
}

struct MCPConnectionsView: View {
    @Environment(BusinessAuthStore.self) private var businessAuth
    @State private var consents: [MCPConsentRow] = []
    @State private var isLoading = false
    @State private var revokingClientId: String?
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                if !businessAuth.isConnected {
                    Label("Conecta tu cuenta Repera a Supabase para ver los permisos.", systemImage: "lock")
                        .foregroundStyle(.secondary)
                } else if isLoading && consents.isEmpty {
                    ProgressView("Consultando autorizaciones…")
                } else if consents.isEmpty {
                    ContentUnavailableView(
                        "Sin asistentes autorizados",
                        systemImage: "shield.checkered",
                        description: Text("No hay aplicaciones de IA con permiso para consultar tu historial.")
                    )
                } else {
                    ForEach(consents) { consent in
                        HStack(spacing: 12) {
                            Image(systemName: consent.enabled ? "checkmark.shield" : "lock.shield")
                                .foregroundStyle(consent.enabled ? Color.green : Color.secondary)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Cliente OAuth")
                                    .font(.headline)
                                Text(consent.clientId)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Text(consent.enabled ? "Acceso de lectura permitido" : "Permiso revocado")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if consent.enabled {
                                if revokingClientId == consent.clientId {
                                    ProgressView()
                                } else {
                                    Button("Revocar", role: .destructive) {
                                        Task { await revoke(consent) }
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Permisos de asistentes")
            } footer: {
                Text("Estos permisos afectan únicamente a la lectura de tu historial deportivo en Repera. No autorizan acceso a Apple Salud, GPS, notas privadas ni edición de entrenamientos. Un entrenador necesita otro permiso distinto.")
            }
        }
        .navigationTitle("Conexiones IA")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await reload() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isLoading)
                .accessibilityLabel("Actualizar permisos")
            }
        }
        .task { await reload() }
    }

    @MainActor
    private func reload() async {
        guard !isLoading, let client = businessAuth.apiClient, businessAuth.isConnected else {
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let session = try await client.auth.session
            guard !session.isExpired else {
                throw MCPConnectionError.sessionExpired
            }
            let rows: [MCPConsentRow] = try await client.from("mcp_user_consents")
                .select("client_id,enabled")
                .eq("user_id", value: session.user.id.uuidString)
                .order("client_id")
                .execute().value
            guard businessAuth.apiClient?.auth.currentSession?.user.id == session.user.id else {
                return
            }
            consents = rows
            errorMessage = nil
        } catch {
            errorMessage = "No se pudieron consultar los permisos: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func revoke(_ consent: MCPConsentRow) async {
        guard revokingClientId == nil,
              let client = businessAuth.apiClient,
              businessAuth.isConnected else { return }
        revokingClientId = consent.clientId
        defer { revokingClientId = nil }
        do {
            let session = try await client.auth.session
            guard !session.isExpired else { throw MCPConnectionError.sessionExpired }
            try await client.from("mcp_user_consents")
                .update(["enabled": false])
                .eq("user_id", value: session.user.id.uuidString)
                .eq("client_id", value: consent.clientId)
                .execute()
            guard businessAuth.apiClient?.auth.currentSession?.user.id == session.user.id else { return }
            consents = consents.map {
                $0.clientId == consent.clientId
                    ? MCPConsentRow(clientId: $0.clientId, enabled: false)
                    : $0
            }
            errorMessage = nil
        } catch {
            errorMessage = "No se pudo revocar el acceso: \(error.localizedDescription)"
        }
    }

    private enum MCPConnectionError: LocalizedError {
        case sessionExpired
        var errorDescription: String? {
            "Tu sesión de Supabase ha caducado. Reconecta la cuenta desde Ajustes."
        }
    }
}
