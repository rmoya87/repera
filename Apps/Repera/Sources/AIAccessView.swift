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
    let scopes: [String]?

    enum CodingKeys: String, CodingKey {
        case id, label
        case tokenPrefix = "token_prefix"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case revokedAt = "revoked_at"
        case lastUsedAt = "last_used_at"
        case scopes
    }
    // PostgreSQL timestamps may include fractional seconds. The default
    // ISO8601DateFormatter rejects these without .withFractionalSeconds.
    private static func parseTimestamp(_ raw: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: raw) { return date }
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: raw)
    }

    var isActive: Bool {
        guard revokedAt == nil else { return false }
        guard let expiresAt else { return true }
        guard let date = Self.parseTimestamp(expiresAt) else { return false }
        return date > Date()
    }
    var expiryLabel: String {
        guard let expiresAt else { return "Sin caducidad" }
        if let date = Self.parseTimestamp(expiresAt) {
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
    @State private var inbox = AITrainingInboxStore.shared
    @State private var tokens: [AIAccessTokenInfo] = []
    @State private var tokenName = ""
    @State private var expiry = "90d"
    @State private var canWrite = true
    @State private var createdToken: String?
    @State private var isBusy = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        Form {
            Section {
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
                    Toggle("Permitir enviar y editar entrenamientos", isOn: $canWrite)
                        .tint(OG.accent)
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
                    .disabled(isBusy || !auth.isConnected || tokenName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } header: {
                Text("Nuevo acceso IA")
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
                        Text(token.scopes?.contains("training:write") == true
                             ? "Lectura y escritura" : "Solo lectura")
                            .font(.caption).foregroundStyle(.secondary)
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
            }

            if inbox.pendingCount > 0 || !inbox.conflicts.isEmpty {
                Section {
                    if inbox.pendingCount > 0 {
                        Label("\(inbox.pendingCount) entrenamientos pendientes", systemImage: "clock")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(inbox.conflicts, id: \.self) { issue in
                        Text(issue).font(.footnote).foregroundStyle(.orange)
                    }
                } header: {
                    Text("Entrenamientos enviados por la IA")
                }
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
                        .background(Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
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
        .task {
            // Apple login happens during the regular Repera launch, not here.
            // Recover a previously linked Supabase session if needed.
            if !auth.isConnected, auth.hasCachedSupabaseSession {
                await auth.restoreSession()
            }
            await refreshTokens()
        }
        .onChange(of: auth.isConnected) { _, connected in
            if connected { Task { await refreshTokens() } }
            else { tokens = [] }
        }
    }

    @MainActor
    private func refreshTokens() async {
        guard auth.isConnected, let client = auth.apiClient else { return }
        do {
            let session = try await client.auth.session
            guard !session.isExpired else { return }
            let items: [AIAccessTokenInfo] = try await client.from("ai_access_tokens")
                .select("id,label,token_prefix,created_at,expires_at,revoked_at,last_used_at,scopes")
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
                "expiry": expiry,
                "canWrite": canWrite
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
