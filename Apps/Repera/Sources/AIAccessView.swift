import Foundation
import Observation
import ReperaDomain
import Supabase
import SwiftUI
import UIKit

private struct AIAccessTokenInfo: Decodable, Identifiable {
    let id: UUID
    let label: String
    let tokenPrefix: String
    let createdAt: String
    let expiresAt: String?
    let revokedAt: String?
    let lastUsedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, label
        case tokenPrefix = "token_prefix"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case revokedAt = "revoked_at"
        case lastUsedAt = "last_used_at"
    }
    var isActive: Bool {
        guard revokedAt == nil else { return false }
        guard let expiresAt, let date = ISO8601DateFormatter().date(from: expiresAt) else {
            return expiresAt == nil
        }
        return date > Date()
    }
    var expiryLabel: String {
        guard let expiresAt else { return "Sin caducidad" }
        if let date = ISO8601DateFormatter().date(from: expiresAt) {
            return "Caduca el \(date.formatted(date: .abbreviated, time: .omitted))"
        }
        return "Caducidad: \(expiresAt.prefix(10))"
    }
}
private struct AINewTokenResponse: Decodable {
    let token: String
    let label: String
}
private struct AIFunctionError: Decodable {
    let error: String
}

/// Personal bearer-token management. Server generates the 256-bit token; only
/// its SHA-256 digest is stored. Plaintext stays in volatile view state until
/// the one-time sheet is dismissed.
struct AIAccessView: View {
    @Environment(BusinessAuthStore.self) private var auth
    @Environment(ReperaStore.self) private var store
    @State private var inbox = AITrainingInboxStore.shared
    @State private var tokens: [AIAccessTokenInfo] = []
    @State private var tokenName = ""
    @State private var expiry = "90d"
    @State private var createdToken: String?
    @State private var isBusy = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        Form {
            Section {
                if !auth.isConnected {
                    Label("Inicia sesión con Apple y conecta Repera a Supabase para crear accesos de IA.", systemImage: "lock.shield")
                        .foregroundStyle(.secondary)
                } else {
                    TextField("Nombre del acceso (ej. Mi entrenador IA)", text: $tokenName)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled()
                    Picker("Caducidad", selection: $expiry) {
                        Text("7 días").tag("7d")
                        Text("30 días").tag("30d")
                        Text("90 días").tag("90d")
                        Text("1 año").tag("365d")
                        Text("Ilimitado").tag("unlimited")
                    }
                    if expiry == "unlimited" {
                        Label("Un token ilimitado seguirá funcionando hasta que lo revoques. Úsalo solo con asistentes de confianza.", systemImage: "exclamationmark.shield")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Button {
                        Task { await createToken() }
                    } label: {
                        Label(isBusy ? "Creando acceso…" : "Crear token", systemImage: "plus.circle.fill")
                    }
                    .disabled(isBusy || tokenName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } header: {
                Text("Nuevo acceso IA")
            } footer: {
                Text("El token se genera en el servidor y se muestra solo una vez. Repera almacena únicamente su huella SHA-256, nunca el token original. Se transmite por HTTPS y puedes revocarlo cuando quieras.")
            }

            Section {
                if tokens.isEmpty {
                    Text("No tienes tokens de IA creados.")
                        .foregroundStyle(.secondary)
                }
                ForEach(tokens) { token in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(token.label).font(.headline)
                            Spacer()
                            if token.isActive {
                                Image(systemName: "checkmark.shield.fill").foregroundStyle(.green)
                            } else {
                                Image(systemName: "lock.shield").foregroundStyle(.secondary)
                            }
                        }
                        Text("\(token.tokenPrefix)…")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                        Text(token.revokedAt != nil ? "Revocado" : token.expiryLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if token.isActive {
                            Button("Revocar token", role: .destructive) {
                                Task { await revoke(token) }
                            }
                            .disabled(isBusy)
                            .font(.subheadline)
                        }
                    }
                    .padding(.vertical, 5)
                }
            } header: {
                Text("Mis tokens")
            } footer: {
                Text("Un token concede acceso a tu historial deportivo y permite crear propuestas de entrenamientos. No da acceso a Apple Salud ni a tus rutas GPS.")
            }

            Section {
                Button {
                    Task {
                        _ = await inbox.sync(store: store)
                        await refreshTokens()
                    }
                } label: {
                    Label("Actualizar entrenamientos de IA", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(inbox.isSyncing || !auth.isConnected)
                if inbox.pendingCount > 0 {
                    Text("\(inbox.pendingCount) entrenamientos pendientes de incorporación.")
                        .foregroundStyle(.secondary)
                }
                ForEach(inbox.conflicts, id: \.self) { issue in
                    Text(issue).font(.footnote).foregroundStyle(.orange)
                }
            } header: {
                Text("Entrenamientos enviados por la IA")
            } footer: {
                Text("Se incorporan automáticamente a Diario e Inicio al sincronizar. Si ya tienes un entrenamiento para una fecha, no se sobrescribe y queda pendiente.")
            }

            if let errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            if let successMessage {
                Section {
                    Label(successMessage, systemImage: "checkmark.circle")
                        .font(.footnote)
                        .foregroundStyle(.green)
                }
            }
        }
        .navigationTitle("Acceso IA")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: Binding(
            get: { createdToken != nil },
            set: { if !$0 { createdToken = nil } }
        )) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 18) {
                    Label("Token creado", systemImage: "checkmark.shield.fill")
                        .font(.title2.bold())
                        .foregroundStyle(.green)
                    Text("Cópialo y guárdalo en tu asistente. Por seguridad no volverá a mostrarse.")
                    Text(createdToken ?? "")
                        .font(.footnote.monospaced())
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
                    Button {
                        if let createdToken {
                            // Explicit copy; expire clipboard data after two minutes.
                            UIPasteboard.general.setItems(
                                [["public.utf8-plain-text": createdToken]],
                                options: [.expirationDate: Date().addingTimeInterval(120)]
                            )
                        }
                    } label: {
                        Label("Copiar token", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.borderedProminent)
                    Text("Este token permite que quien lo conozca consulte tu historial deportivo y envíe entrenamientos. No lo publiques ni lo compartas en capturas.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(24)
                .navigationTitle("Nuevo token")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Cerrar") { createdToken = nil }
                    }
                }
            }
        }
        .task { await refreshTokens() }
    }

    @MainActor
    private func refreshTokens() async {
        guard auth.isConnected, let client = auth.apiClient else { return }
        do {
            let session = try await client.auth.session
            guard !session.isExpired else { return }
            let items: [AIAccessTokenInfo] = try await client.from("ai_access_tokens")
                .select("id,label,token_prefix,created_at,expires_at,revoked_at,last_used_at")
                .eq("owner_id", value: session.user.id.uuidString)
                .order("created_at", ascending: false)
                .execute().value
            guard auth.apiClient?.auth.currentSession?.user.id == session.user.id else { return }
            tokens = items
        } catch {
            errorMessage = "No se pudieron obtener los tokens: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func createToken() async {
        guard !isBusy, auth.isConnected, let client = auth.apiClient else { return }
        isBusy = true
        defer { isBusy = false }
        errorMessage = nil
        successMessage = nil
        do {
            let session = try await client.auth.session
            guard !session.isExpired else { throw AccessError.sessionExpired }
            let url = URL(string: "https://uvzgujlrqohreoucirms.supabase.co/functions/v1/repera-ai-tokens")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "label": tokenName.trimmingCharacters(in: .whitespacesAndNewlines),
                "expiry": expiry
            ])
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw AccessError.server }
            guard (200..<300).contains(http.statusCode) else {
                let issue = try? JSONDecoder().decode(AIFunctionError.self, from: data)
                throw AccessError.message(issue?.error ?? "Error HTTP \(http.statusCode)")
            }
            let value = try JSONDecoder().decode(AINewTokenResponse.self, from: data)
            guard auth.apiClient?.auth.currentSession?.user.id == session.user.id else {
                throw AccessError.sessionExpired
            }
            createdToken = value.token
            tokenName = ""
            await refreshTokens()
        } catch {
            errorMessage = "No se pudo crear el token: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func revoke(_ token: AIAccessTokenInfo) async {
        guard !isBusy, auth.isConnected, let client = auth.apiClient else { return }
        isBusy = true
        defer { isBusy = false }
        errorMessage = nil
        successMessage = nil
        do {
            let session = try await client.auth.session
            guard !session.isExpired else { throw AccessError.sessionExpired }
            try await client.from("ai_access_tokens")
                .update(["revoked_at": ISO8601DateFormatter().string(from: Date())])
                .eq("id", value: token.id.uuidString)
                .eq("owner_id", value: session.user.id.uuidString)
                .execute()
            await refreshTokens()
            successMessage = "Token revocado. Ya no permite acceder a Repera."
        } catch {
            errorMessage = "No se pudo revocar el token: \(error.localizedDescription)"
        }
    }

    private enum AccessError: LocalizedError {
        case sessionExpired, server, message(String)
        var errorDescription: String? {
            switch self {
            case .sessionExpired: "Sesión caducada. Reconecta tu cuenta en Ajustes."
            case .server: "Respuesta inesperada del servidor."
            case .message(let message): message
            }
        }
    }
}
