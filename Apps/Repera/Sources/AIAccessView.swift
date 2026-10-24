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
    let oauthClientID: UUID?

    enum CodingKeys: String, CodingKey {
        case id, label
        case tokenPrefix = "token_prefix"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case revokedAt = "revoked_at"
        case lastUsedAt = "last_used_at"
        case scopes
        case oauthClientID = "oauth_client_id"
    }
    // PostgreSQL timestamps may include fractional seconds. The default
    // ISO8601DateFormatter rejects these without .withFractionalSeconds.
    private static func parseTimestamp(_ raw: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: raw) { return date }
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: raw)
    }

    var hasConnected: Bool { isActive && lastUsedAt != nil }
    var lastUseLabel: String? {
        guard let raw = lastUsedAt, let date = Self.parseTimestamp(raw) else { return nil }
        return "Último uso: \(date.formatted(date: .abbreviated, time: .shortened))"
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

private struct AIConnectionProvider: Decodable, Identifiable {
    let id: String
    let name: String
    let directoryURL: String?
    let setup: AIConnectionSetup?

    init(id: String, name: String, directoryURL: String?, setup: AIConnectionSetup? = nil) {
        self.id = id
        self.name = name
        self.directoryURL = directoryURL
        self.setup = setup
    }

    var oauthClientID: UUID? {
        guard setup?.kind == "claude_prompt" || setup?.kind == "oauth" else { return nil }
        return setup?.clientID
    }
    var claudeClientID: UUID? {
        guard id == "claude" else { return nil }
        return oauthClientID
    }

    var isAvailable: Bool { claudeClientID != nil || connectionURL != nil }

    var connectionURL: URL? {
        guard let directoryURL, let url = URL(string: directoryURL),
              url.scheme == "https", url.user == nil, url.password == nil, url.port == nil,
              url.path.count > 1 else { return nil }
        let hosts = id == "chatgpt" ? ["chatgpt.com"] : id == "claude" ? ["claude.ai", "claude.com"] : []
        return hosts.contains(url.host ?? "") ? url : nil
    }
}
private struct AIConnectionSetup: Decodable {
    let kind: String
    let clientID: UUID
}
private struct AIConnectionCatalog: Decodable {
    let providers: [AIConnectionProvider]
}

private enum AIProviderLaunch {
    static let server = "https://uvzgujlrqohreoucirms.supabase.co/functions/v1/repera-mcp"

    static func url(for id: String) -> URL? {
        let values = ["chatgpt": "https://chatgpt.com/", "claude": "https://claude.ai/", "grok": "https://grok.com/"]
        return values[id].flatMap(URL.init(string:))
    }

    static func instructions(for provider: AIConnectionProvider) -> String {
        let name = provider.name
        let connectorSteps: String
        if provider.id == "claude", let clientID = provider.claudeClientID {
            connectorSteps = """
            En Claude, abre https://claude.ai/customize/connectors y añade un conector personalizado Web con:
            Nombre: Repera
            URL del servidor MCP: \(server)
            Autenticación: OAuth / Iniciar sesión ahora
            Cliente OAuth: Usar tu propio cliente
            ID de cliente OAuth: \(clientID.uuidString.lowercased())
            Secreto: vacío (cliente público PKCE).
            """
        } else {
            connectorSteps = """
            Comprueba si tu versión de \(name) permite añadir un servidor MCP remoto con autenticación OAuth.
            Nombre: Repera
            URL del servidor MCP: \(server)
            Si solicita un ID de cliente, configuración especial o un plan que no tengo, explícamelo sin inventar datos ni dar por realizada la conexión.
            """
        }
        return """
        Quiero conectar Repera (https://repera.app) con \(name) para consultar y preparar mis entrenamientos. Ayúdame en español, paso a paso, sin realizar cambios todavía.

        Si tienes disponible la herramienta de Repera get_mcp_access_info, ejecútala únicamente para verificar la conexión, sin leer ni modificar mis entrenamientos. Si responde correctamente, confirma la conexión.

        Si no está conectado, indícame cómo configurar un conector MCP remoto en \(name). No basta con leer la web de Repera ni con recibir este mensaje.
        \(connectorSteps)

        Debo autorizar el acceso en Repera mediante el flujo oficial de inicio de sesión. No me pidas contraseñas, tokens ni claves privadas en el chat. Si tu aplicación o mi plan no admite conectores MCP remotos, dímelo claramente y no confirmes ninguna conexión.

        Comprueba el acceso solo con get_mcp_access_info. No crees, borres ni modifiques entrenamientos sin mi solicitud expresa.
        """
    }
}

struct AIAccessView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var providers = [
        AIConnectionProvider(id: "chatgpt", name: "ChatGPT", directoryURL: nil),
        AIConnectionProvider(id: "claude", name: "Claude", directoryURL: nil),
        AIConnectionProvider(id: "grok", name: "Grok", directoryURL: nil)
    ]
    @State private var catalogError: String?
    @State private var catalogLoading = true
    @State private var showManualAccess = false
    @State private var selectedInstructions: AIConnectionProvider?
    @State private var launchMessage: String?
    @State private var disconnectingProvider: AIConnectionProvider?
    @State private var showInstructions = false

    @Environment(BusinessAuthStore.self) private var auth
    @Environment(ReperaStore.self) private var store
    @State private var changeRequests = AIChangeRequestStore.shared
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
            connectionSection
            Section {
                DisclosureGroup("Conexión manual", isExpanded: $showManualAccess) {
                    Text("Para asistentes que requieren una clave de acceso. Pégala en su configuración, nunca en una conversación.")
                        .font(.footnote).foregroundStyle(.secondary)
                    manualAccessFields
                }
            }
            connectionsSection

            if !changeRequests.pending.isEmpty {
                Section {
                    ForEach(changeRequests.pending) { request in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(request.summary).font(.subheadline.weight(.medium))
                            if request.operation == "update_workout" {
                                if let newTitle=request.payload.title {
                                    Text("Nuevo título: \(newTitle)")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                ForEach(request.payload.setChanges ?? [],id:\.loggedSetId) { change in
                                    let parts = [
                                        change.reps.map { "\($0) reps" },
                                        change.weightKg.map { "\(String(format:"%g",$0)) kg" },
                                        change.rir.map { "RIR \(String(format:"%g",$0))" },
                                        change.clearWeight == true ? "sin peso" : nil,
                                        change.clearRir == true ? "sin RIR" : nil,
                                    ].compactMap { $0 }
                                    Text("Serie \(change.loggedSetId.uuidString.prefix(8)): " + parts.joined(separator:" · "))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            if request.operation == "delete_workout" {
                                Text("La eliminación de un entrenamiento también puede borrar su actividad vinculada de Apple Salud.")
                                    .font(.caption).foregroundStyle(.orange)
                            }
                            HStack {
                                Button("Rechazar") {
                                    Task { _ = await changeRequests.decide(request, approve:false, store:store) }
                                }.disabled(changeRequests.isBusy)
                                Spacer()
                                Button(request.isDestructive ? "Confirmar eliminación" : "Aplicar") {
                                    Task { _ = await changeRequests.decide(request, approve:true, store:store) }
                                }.disabled(changeRequests.isBusy)
                                    .foregroundStyle(request.isDestructive ? .red : .green)
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Cambios solicitados por la IA")
                }
            }
            if let changeError=changeRequests.lastError {
                Section {
                    Label(changeError,systemImage:"exclamationmark.triangle")
                        .font(.footnote).foregroundStyle(.orange)
                }
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
        .refreshable {
            await refreshTokens()
            await refreshProviders()
            await changeRequests.refresh(store:store)
        }
        .ogPinnedTransparentNav("Conecta tu IA")
        .sheet(isPresented: $showInstructions) {
            NavigationStack {
                Form {
                    ForEach(providers) { provider in
                        Section(provider.name) {
                            Text(AIProviderLaunch.instructions(for: provider))
                                .font(.footnote).textSelection(.enabled)
                            Button("Copiar instrucciones de \(provider.name)") {
                                UIPasteboard.general.string = AIProviderLaunch.instructions(for: provider)
                            }
                        }
                    }
                }
                .navigationTitle("Instrucciones")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Cerrar") { showInstructions = false } } }
            }
        }
        .confirmationDialog("Desconectar asistente", isPresented: Binding(
            get: { disconnectingProvider != nil },
            set: { if !$0 { disconnectingProvider = nil } }
        )) {
            if let provider = disconnectingProvider, let token = connectedToken(for: provider) {
                Button("Desconectar \(provider.name)", role: .destructive) {
                    disconnectingProvider = nil
                    Task { await revoke(token) }
                }
            }
            Button("Cancelar", role: .cancel) { disconnectingProvider = nil }
        } message: {
            Text("Se revocará el acceso del asistente a tu cuenta de Repera.")
        }
        .sheet(item: $selectedInstructions) { provider in
            NavigationStack {
                Form {
                    Section {
                        Text(AIProviderLaunch.instructions(for: provider))
                            .font(.footnote)
                            .textSelection(.enabled)
                        Button("Copiar instrucciones") {
                            UIPasteboard.general.string = AIProviderLaunch.instructions(for: provider)
                        }
                    } header: { Text("Instrucciones para \(provider.name)") }
                    Section {
                        if connectionVerified(for: provider) {
                            Label("Conexión comprobada", systemImage: "checkmark.circle")
                        }
                    }
                }
                .navigationTitle(provider.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Cerrar") { selectedInstructions = nil }
                    }
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { createdToken != nil },
            set: { if !$0 { createdToken = nil } }
        )) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 18) {
                    Label("Token creado", systemImage: "checkmark.shield.fill")
                        .font(.title2.bold())
                        .foregroundStyle(.green)
                    Text("Copia esta clave en la configuración de tu asistente. No la pegues en el chat. Solo se muestra una vez.")
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
                .ogTransparentNav()
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
            await refreshProviders()
            await changeRequests.syncCustomExercises(store:store)
            await changeRequests.refresh(store:store)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await refreshTokens(); await refreshProviders() }
            }
        }
        .onChange(of: auth.isConnected) { _, connected in
            if connected {
                Task {
                    await refreshTokens()
                    await changeRequests.refresh(store:store)
                }
            } else {
                tokens=[]
                selectedInstructions = nil
                changeRequests.clearSession()
            }
        }
    }

    private var connectionSection: some View {
        Section {
            Text("Usa tu asistente habitual para consultar tus entrenamientos y preparar tus próximas sesiones.")
                .foregroundStyle(OG.label2)
            ForEach(providers) { provider in
                Button {
                    if connectionVerified(for: provider) {
                        disconnectingProvider = provider
                    } else {
                        launch(provider)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image("AILogo" + (provider.id == "chatgpt" ? "Openai" : provider.id == "claude" ? "Claude" : "Grok"))
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .accessibilityHidden(true)
                        Spacer(minLength: 0)
                        Text(connectionVerified(for: provider) ? "\(provider.name) conectado" : "Continuar con \(provider.name)").fontWeight(.semibold)
                        Spacer(minLength: 0)
                        Color.clear.frame(width: 24, height: 1)
                    }
                    .foregroundStyle(OG.label)
                    .frame(height: 48)
                    .padding(.horizontal, 14)
                    .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 13))
                    .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Color.secondary.opacity(0.25)))
                }
                .buttonStyle(.plain)
                .disabled(!auth.isConnected)
            }
            if !auth.isConnected {
                Text("Inicia sesión en Repera para conectar tu asistente.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            if let launchMessage {
                Text(launchMessage).font(.footnote).foregroundStyle(.secondary)
            }
            Button("Ver instrucciones") { showInstructions = true }
                .buttonStyle(.borderless)
        } header: { Text("Elige tu asistente") }
    }

    private func connectionVerified(for provider: AIConnectionProvider) -> Bool {
        connectedToken(for: provider) != nil
    }

    private func connectedToken(for provider: AIConnectionProvider) -> AIAccessTokenInfo? {
        guard let clientID = provider.oauthClientID else { return nil }
        return tokens.first { $0.oauthClientID == clientID && $0.hasConnected }
    }

    private func launch(_ provider: AIConnectionProvider) {
        UIPasteboard.general.string = AIProviderLaunch.instructions(for: provider)
        guard let url = AIProviderLaunch.url(for: provider.id) else {
            launchMessage = "Las instrucciones están copiadas, pero no hay una dirección válida para este asistente."
            return
        }
        launchMessage = "Instrucciones copiadas. Pégalas en \(provider.name) al abrirlo."
        openURL(url) { accepted in
            if !accepted {
                launchMessage = "No se pudo abrir \(provider.name). Las instrucciones permanecen copiadas."
            }
        }
    }

    private var connectionsSection: some View {
        Section {
            if tokens.isEmpty {
                Text("Aún no tienes asistentes conectados.").foregroundStyle(.secondary)
            }
            ForEach(tokens) { token in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(token.label).font(.headline)
                        Spacer()
                        Text(token.isActive ? (token.hasConnected ? "Conectado" : "Pendiente de conexión") : "Desconectado")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Text(token.scopes?.contains("training:write") == true
                         ? "Puede consultar y preparar entrenamientos" : "Puede consultar tus entrenamientos")
                        .font(.caption).foregroundStyle(.secondary)
                    if let lastUse = token.lastUseLabel {
                        Text(lastUse).font(.caption).foregroundStyle(.secondary)
                    }
                    if token.oauthClientID == nil {
                        Text(token.expiryLabel).font(.caption).foregroundStyle(.secondary)
                    }
                    if token.isActive {
                        if token.hasConnected, let provider = providers.first(where: { $0.name == token.label }), token.oauthClientID != nil {
                            Button("Abrir \(provider.name)") {
                                openURL(URL(string: provider.id == "chatgpt" ? "https://chatgpt.com/" : "https://claude.ai/")!)
                            }
                        }
                        Button("Desconectar", role: .destructive) { Task { await revoke(token) } }
                            .disabled(isBusy)
                    }
                }.padding(.vertical, 5)
            }
        } header: { Text("Mis conexiones") }
    }

    private var manualAccessFields: some View {
        Group {
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

        }
    }

    @MainActor
    private func refreshProviders() async {
        catalogLoading = true
        defer { catalogLoading = false }
        do {
            let url = URL(string: "https://uvzgujlrqohreoucirms.supabase.co/functions/v1/repera-ai-connect/catalog")!
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else { throw AccessError.server }
            let catalog = try JSONDecoder().decode(AIConnectionCatalog.self, from: data)
            guard Set(catalog.providers.map(\.id)) == Set(["chatgpt", "claude"]), catalog.providers.count == 2 else { throw AccessError.server }
            providers = (catalog.providers + [AIConnectionProvider(id: "grok", name: "Grok", directoryURL: nil)])
                .sorted { ["chatgpt", "claude", "grok"].firstIndex(of: $0.id)! < ["chatgpt", "claude", "grok"].firstIndex(of: $1.id)! }
            catalogError = nil
        } catch {
            providers = providers.map { AIConnectionProvider(id: $0.id, name: $0.name, directoryURL: nil) }
            catalogError = "No se pudo comprobar la disponibilidad de las conexiones."
        }
    }

    @MainActor
    private func refreshTokens() async {
        guard auth.isConnected, let client = auth.apiClient else { return }
        do {
            let session = try await client.auth.session
            guard !session.isExpired else { return }
            let items: [AIAccessTokenInfo]
            do {
                items = try await client.from("ai_access_tokens")
                    .select("id,label,token_prefix,created_at,expires_at,revoked_at,last_used_at,scopes,oauth_client_id")
                    .eq("owner_id", value: session.user.id.uuidString)
                    .order("created_at", ascending: false)
                    .execute().value
            } catch let error as PostgrestError where error.code == "42703" {
                // Keep existing manual connections manageable during a staged
                // rollout, before the additive OAuth migration is applied.
                items = try await client.from("ai_access_tokens")
                    .select("id,label,token_prefix,created_at,expires_at,revoked_at,last_used_at,scopes")
                    .eq("owner_id", value: session.user.id.uuidString)
                    .order("created_at", ascending: false)
                    .execute().value
            }
            guard auth.apiClient?.auth.currentSession?.user.id == session.user.id else { return }
            tokens = items
            errorMessage = nil
        } catch {
            errorMessage = "No se pudieron cargar las conexiones: \(error.localizedDescription)"
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
            if token.oauthClientID != nil {
                let url = URL(string: "https://uvzgujlrqohreoucirms.supabase.co/functions/v1/repera-ai-connect/disconnect")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: ["id": token.id.uuidString])
                let (_, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw AccessError.server }
            } else {
            try await client.from("ai_access_tokens")
                .update(["revoked_at": ISO8601DateFormatter().string(from: Date())])
                .eq("id", value: token.id.uuidString)
                .eq("owner_id", value: session.user.id.uuidString)
                .execute()
            }
            await refreshTokens()
            successMessage = "Acceso desconectado. Ya no permite acceder a Repera."
        } catch {
            errorMessage = "No se pudo desconectar: \(error.localizedDescription)"
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
