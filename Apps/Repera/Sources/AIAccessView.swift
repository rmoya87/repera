import Foundation
import Observation
import ReperaDomain
import Supabase
import SwiftUI
import UIKit

private struct AIAccessTokenInfo: Decodable, Identifiable, Hashable {
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
        return "Último uso: \(SpanishDate.format(date, date: .abbreviated, time: .shortened))"
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
            return "Caduca el \(SpanishDate.format(date, date: .abbreviated, time: .omitted))"
        }
        return "Caducidad: \(expiresAt.prefix(10))"
    }

    var allowsWrite: Bool { scopes?.contains("training:write") == true }
    var allowsDelete: Bool { scopes?.contains("training:delete") == true }
    var permissionSummary: String {
        var parts = ["Lectura"]
        if allowsWrite { parts.append("Editar") }
        if allowsDelete { parts.append("Borrar") }
        return parts.joined(separator: " · ")
    }
}
private struct AINewTokenResponse: Decodable {
    let token: String
    let label: String
    let mcpUrl: String?
    let setupUrl: String?
    let setupExpiresAt: String?
}
private struct AIFunctionError: Decodable {
    let error: String
}

private struct AIConnectionProvider: Decodable, Identifiable, Hashable {
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
        guard setup?.kind == "claude_prompt" || setup?.kind == "chatgpt_prompt" || setup?.kind == "oauth" else { return nil }
        return setup?.clientID
    }
    var claudeClientID: UUID? {
        guard id == "claude" else { return nil }
        return oauthClientID
    }
    var chatgptClientID: UUID? {
        guard id == "chatgpt" else { return nil }
        return oauthClientID
    }

    var isAvailable: Bool { oauthClientID != nil || connectionURL != nil }

    var connectionURL: URL? {
        guard let directoryURL, let url = URL(string: directoryURL),
              url.scheme == "https", url.user == nil, url.password == nil, url.port == nil,
              url.path.count > 1 else { return nil }
        let hosts = id == "chatgpt" ? ["chatgpt.com"] : id == "claude" ? ["claude.ai", "claude.com"] : []
        return hosts.contains(url.host ?? "") ? url : nil
    }
}
private struct AIConnectionSetup: Decodable, Hashable {
    let kind: String
    let clientID: UUID
}
private struct AIConnectionCatalog: Decodable {
    let providers: [AIConnectionProvider]
}

private enum AIProviderLaunch {
    /// URL pública para pegar en asistentes (proxy canónico en repera.app).
    static let publicServer = "https://repera.app/mcp"
    /// Endpoint Edge real (OAuth / discovery / Bearer).
    static let server = "https://uvzgujlrqohreoucirms.supabase.co/functions/v1/repera-mcp"

    /// Chat nuevo con el prompt en `q` (Universal Links abren la app si está).
    static func chatURL(for id: String, prompt: String) -> URL? {
        let base: String
        switch id {
        case "chatgpt": base = "https://chatgpt.com/"
        case "claude": base = "https://claude.ai/new"
        case "grok": base = "https://grok.com/"
        default: return nil
        }
        var components = URLComponents(string: base)
        components?.queryItems = [URLQueryItem(name: "q", value: prompt)]
        return components?.url
    }

    /// Claude: esquema nativo documentado primero; ChatGPT/Grok: HTTPS con `?q=`
    /// (AASA / App Links abren la app instalada con el prompt; `chatgpt://` no lo garantiza).
    static func preferredLaunchURLs(for id: String, prompt: String) -> [URL] {
        var urls: [URL] = []
        if id == "claude" {
            var app = URLComponents(string: "claude://claude.ai/new")
            app?.queryItems = [URLQueryItem(name: "q", value: prompt)]
            if let appURL = app?.url { urls.append(appURL) }
        }
        if let web = chatURL(for: id, prompt: prompt) { urls.append(web) }
        return urls
    }

    /// Elige URL instalable (esquema custom si `canOpenURL`, si no HTTPS). Solo MainActor.
    @MainActor
    static func preferredOpenURL(for id: String, prompt: String) -> URL? {
        for url in preferredLaunchURLs(for: id, prompt: prompt) {
            let isCustomScheme = url.scheme != "https" && url.scheme != "http"
            if isCustomScheme {
                if UIApplication.shared.canOpenURL(url) { return url }
                continue
            }
            return url
        }
        return nil
    }

    static func setupHint(for provider: AIConnectionProvider) -> String {
        switch provider.id {
        case "claude":
            return "En Claude: Personalizar → Conectores → conector remoto con OAuth (cliente propio). La autenticación abre https://repera.app/ai/."
        case "chatgpt":
            return "En ChatGPT (web): Configuración → conectores MCP con OAuth. La autenticación abre https://repera.app/ai/."
        case "grok":
            return "En Grok / Grok Bot: conectores o plugins MCP si tu cuenta los ofrece. El token se obtiene en https://repera.app/ai/."
        default:
            return "Configura el conector solo dentro de \(provider.name)."
        }
    }

    /// ChatGPT / Claude: OAuth → consentimiento en https://repera.app/ai/ (sin PAT en el chat).
    static func oauthInstructions(for provider: AIConnectionProvider, clientID: UUID) -> String {
        let name = provider.name
        let mcp = publicServer
        let id = clientID.uuidString.lowercased()
        return """
        Quiero conectar Repera (https://repera.app) solo con \(name) para consultar y preparar mis entrenamientos. Ayúdame en español, paso a paso, sin realizar cambios todavía. No menciones ni configures otros asistentes.

        Si tienes disponible la herramienta de Repera get_mcp_access_info, ejecútala únicamente para verificar la conexión, sin leer ni modificar mis entrenamientos. Si responde correctamente, confirma la conexión.

        Si no está conectado, indícame cómo añadir un conector MCP remoto en \(name) con:
        Nombre: Repera
        URL del servidor MCP: \(mcp)
        Autenticación: OAuth
        Usa tu propio cliente OAuth (no registro automático / CIMD).
        Client ID: \(id)
        Client secret: (vacío)
        La autorización debe abrir https://repera.app/ai/ para que yo inicie sesión en Repera y apruebe el acceso. No me pidas tokens en el chat.

        Si tu plan o interfaz no admite OAuth con cliente propio para MCP, dímelo claramente y no confirmes ninguna conexión.

        Comprueba el acceso solo con get_mcp_access_info. No crees, borres ni modifiques entrenamientos sin mi solicitud expresa.
        """
    }

    /// Grok / Conexión manual: Bearer + enlace de setup en /ai (pide login).
    static func instructions(for provider: AIConnectionProvider, setupUrl: String) -> String {
        let name = provider.name
        let mcp = publicServer
        return """
        Quiero conectar Repera (https://repera.app) solo con \(name) para consultar y preparar mis entrenamientos. Ayúdame en español, paso a paso, sin realizar cambios todavía. No menciones ni configures otros asistentes.

        Si tienes disponible la herramienta de Repera get_mcp_access_info, ejecútala únicamente para verificar la conexión, sin leer ni modificar mis entrenamientos. Si responde correctamente, confirma la conexión.

        Si no está conectado, indícame cómo añadir un conector MCP remoto o plugin en \(name) con:
        Nombre: Repera
        URL del servidor MCP: \(mcp)
        Autenticación: token Bearer / API key en el header Authorization.

        El token de un solo uso lo obtengo yo abriendo este enlace (pide autenticación en Repera; válido 15 minutos; no lo pegues en el chat):
        \(setupUrl)
        Indícame dónde configurar el token en \(name); no me pidas que lo escriba aquí.

        Si tu aplicación o mi plan no admite conectores MCP / plugins con Bearer, dímelo claramente y no confirmes ninguna conexión.

        Comprueba el acceso solo con get_mcp_access_info. No crees, borres ni modifiques entrenamientos sin mi solicitud expresa.
        """
    }

    /// Reabrir chat cuando la conexión ya existe (sin nuevo código de setup).
    static func reopenInstructions(for provider: AIConnectionProvider) -> String {
        let name = provider.name
        return """
        Ya tengo Repera conectado o pendiente con \(name). Ayúdame en español a comprobar la conexión.
        Servidor MCP: \(publicServer)
        Si tienes get_mcp_access_info, ejecútala solo para verificar, sin leer ni modificar entrenamientos.
        Si hace falta reconfigurar el conector, dime los pasos en \(name) sin pedirme tokens en el chat; generaré un enlace de setup nuevo desde la app Repera.
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
    @State private var launchMessage: String?
    /// Instrucciones de un solo asistente (nunca las tres apiladas).
    @State private var instructionsProvider: AIConnectionProvider?
    @State private var lastInstructionsPrompt: String?

    @Environment(BusinessAuthStore.self) private var auth
    @Environment(ReperaStore.self) private var store
    @State private var changeRequests = AIChangeRequestStore.shared
    @State private var inbox = AITrainingInboxStore.shared
    @State private var tokens: [AIAccessTokenInfo] = []
    @State private var tokenName = ""
    @State private var expiry = "90d"
    @State private var canWrite = false
    @State private var canDelete = false
    @State private var editingToken: AIAccessTokenInfo?
    @State private var editLabel = ""
    @State private var editCanWrite = false
    @State private var editCanDelete = false
    @State private var createdToken: String?
    @State private var createdSetupUrl: String?
    /// Inicio de la ventana de 15 min del sheet «Nuevo token».
    @State private var createdTokenAt: Date?
    @State private var isBusy = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var hasLoadedConnections = false
    @State private var isLoadingConnections = false
    @State private var connectionsError: String?
    /// Filas ocultas tras swipe si el servidor aún no admite DELETE.
    @State private var hiddenConnectionIDs: Set<UUID> = []

    var body: some View {
        Form {
            // Título en sección propia: row suelto se absorbe en «Elige tu asistente».
            Section {
                OGScrollablePageTitle("Conecta tu IA").ogScrollingTitleListRow()
            }
            .listSectionSpacing(0)
            connectionSection
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
                                        change.weightKg.map { "\(ReperaNumberFormat.decimal($0)) kg" },
                                        change.rir.map { "RIR \(ReperaNumberFormat.decimal($0))" },
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
        .ogScrollingTitleNav()
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showManualAccess) {
            manualAccessSheet
        }
        .sheet(item: $instructionsProvider) { provider in
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(lastInstructionsPrompt
                             ?? AIProviderLaunch.reopenInstructions(for: provider))
                            .font(.footnote)
                            .foregroundStyle(OG.label)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button("Copiar instrucciones") {
                            UIPasteboard.general.string = lastInstructionsPrompt
                                ?? AIProviderLaunch.reopenInstructions(for: provider)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(OG.accent)
                        Text(AIProviderLaunch.setupHint(for: provider))
                            .font(.caption)
                            .foregroundStyle(OG.label2)
                    }
                    .padding(OG.pad)
                }
                .background(OG.bg.ignoresSafeArea())
                .navigationTitle(provider.name)
                .navigationBarTitleDisplayMode(.inline)
                .ogTransparentNav()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Cerrar") { instructionsProvider = nil }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $editingToken) { token in
            editConnectionSheet(token)
        }
        .sheet(isPresented: Binding(
            get: { createdToken != nil },
            set: { if !$0 { dismissCreatedToken() } }
        )) {
            createdTokenSheet
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
                Task {
                    await refreshTokens()
                    await refreshProviders()
                    _ = await changeRequests.syncCustomExercises(store: store)
                }
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
                hasLoadedConnections = false
                connectionsError = nil
                changeRequests.clearSession()
            }
        }
    }

    private var connectionSection: some View {
        Section {
            ForEach(Array(providers.enumerated()), id: \.element.id) { index, provider in
                // Text+tap (no Button): Form no promociona filas sueltas.
                // Icono + título centrados (no icono a la izquierda).
                HStack(spacing: 10) {
                    Spacer(minLength: 0)
                    Image("AILogo" + (provider.id == "chatgpt" ? "Openai" : provider.id == "claude" ? "Claude" : "Grok"))
                        .resizable()
                        .renderingMode(provider.id == "claude" ? .original : .template)
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .accessibilityHidden(true)
                    Text("Continuar con \(provider.name)")
                        .fontWeight(.semibold)
                    Spacer(minLength: 0)
                }
                .foregroundStyle(OG.label)
                .frame(height: 48)
                .padding(.horizontal, 14)
                .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Color.secondary.opacity(0.25)))
                .contentShape(Rectangle())
                .onTapGesture {
                    guard auth.isConnected else { return }
                    launch(provider)
                }
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("Continuar con \(provider.name)")
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(
                    top: index == 0 ? 12 : 3,
                    leading: 16,
                    bottom: 3,
                    trailing: 16
                ))
            }
            // Cuarto botón dentro de «Elige tu asistente».
            HStack(spacing: 10) {
                Spacer(minLength: 0)
                Image(systemName: "key.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 22, height: 22)
                    .accessibilityHidden(true)
                Text("Conexión manual")
                    .fontWeight(.semibold)
                Spacer(minLength: 0)
            }
            .foregroundStyle(OG.label)
            .frame(height: 48)
            .padding(.horizontal, 14)
            .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Color.secondary.opacity(0.25)))
            .contentShape(Rectangle())
            .onTapGesture { showManualAccess = true }
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Conexión manual")
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 12, trailing: 16))
            if !auth.isConnected {
                Text("Inicia sesión en Repera para conectar tu asistente.")
                    .font(.footnote).foregroundStyle(.secondary)
                    .listRowSeparator(.hidden)
            }
            if let launchMessage {
                Text(launchMessage).font(.footnote).foregroundStyle(.secondary)
                    .listRowSeparator(.hidden)
            }
        } header: { Text("Elige tu asistente") }
    }

    private func launch(_ provider: AIConnectionProvider) {
        ReperaAnalytics.track(.aiConnectionStarted, parameters: [
            "feature_area": "ai",
            "entry_point": provider.id,
            "result": "pending"
        ])
        // ChatGPT / Claude: OAuth → /ai. Grok (plugins): Bearer + setup en /ai.
        // Si ChatGPT aún no tiene client OAuth en catálogo, cae a Bearer temporal.
        if provider.id == "grok" {
            Task { await launchWithSetupToken(provider) }
        } else if let clientID = provider.oauthClientID {
            Task { await launchWithOAuth(provider, clientID: clientID) }
        } else {
            Task { await launchWithSetupToken(provider) }
        }
    }

    /// OAuth: abre el chat con client ID; la autenticación ocurre en https://repera.app/ai/.
    @MainActor
    private func launchWithOAuth(_ provider: AIConnectionProvider, clientID: UUID) async {
        guard !isBusy, auth.isConnected else {
            launchMessage = "Inicia sesión en Repera para conectar \(provider.name)."
            return
        }
        let prompt = AIProviderLaunch.oauthInstructions(for: provider, clientID: clientID)
        lastInstructionsPrompt = prompt
        UIPasteboard.general.string = prompt
        launchMessage = nil
        openProviderChat(provider, prompt: prompt) {
            instructionsProvider = provider
            launchMessage = "No se pudo abrir \(provider.name). Las instrucciones permanecen copiadas."
        }
    }

    /// Bearer / plugins: crea PAT y abre el chat con setupUrl (login en /ai/?code=).
    @MainActor
    private func launchWithSetupToken(_ provider: AIConnectionProvider) async {
        guard !isBusy, auth.isConnected, let client = auth.apiClient else {
            launchMessage = "Inicia sesión en Repera para conectar \(provider.name)."
            return
        }
        isBusy = true
        defer { isBusy = false }
        errorMessage = nil
        do {
            let session = try await client.auth.session
            guard !session.isExpired else { throw AccessError.sessionExpired }
            let url = URL(string: "https://uvzgujlrqohreoucirms.supabase.co/functions/v1/repera-ai-tokens")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "label": provider.name,
                "expiry": "90d",
                "canWrite": false
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
            guard let setupUrl = value.setupUrl, !setupUrl.isEmpty else {
                throw AccessError.message("El servidor no devolvió el enlace de setup.")
            }
            await refreshTokens()
            // Prompt de un solo asistente — nunca apilar Claude+ChatGPT+Grok.
            let prompt = AIProviderLaunch.instructions(for: provider, setupUrl: setupUrl)
            lastInstructionsPrompt = prompt
            UIPasteboard.general.string = prompt
            guard AIProviderLaunch.chatURL(for: provider.id, prompt: prompt) != nil else {
                instructionsProvider = provider
                return
            }
            launchMessage = nil
            openProviderChat(provider, prompt: prompt) {
                instructionsProvider = provider
                launchMessage = "No se pudo abrir \(provider.name). Las instrucciones permanecen copiadas."
            }
        } catch {
            errorMessage = "No se pudo preparar la conexión: \(error.localizedDescription)"
            launchMessage = nil
        }
    }

    @MainActor
    private func openProviderChat(
        _ provider: AIConnectionProvider,
        prompt: String,
        onFailure: @escaping @MainActor () -> Void
    ) {
        guard let url = AIProviderLaunch.preferredOpenURL(for: provider.id, prompt: prompt) else {
            onFailure()
            return
        }
        openURL(url) { accepted in
            guard !accepted else { return }
            Task { @MainActor in onFailure() }
        }
    }

    private var connectionsSection: some View {
        Section {
            if !hasLoadedConnections && isLoadingConnections {
                ProgressView("Comprobando conexiones…")
                    .font(.footnote)
            } else if let connectionsError {
                Label(connectionsError, systemImage: "wifi.exclamationmark")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Reintentar") { Task { await refreshTokens() } }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(OG.accent)
                    .disabled(isLoadingConnections)
            } else if hasLoadedConnections && tokens.isEmpty {
                Text("Aún no tienes asistentes conectados.").foregroundStyle(.secondary)
            } else if !auth.isConnected {
                Text("Inicia sesión para consultar tus conexiones.")
                    .foregroundStyle(.secondary)
            }
            ForEach(displayedTokens) { token in
                connectionRow(token)
                    // Sin full-swipe: en Form puede desincronizar filas vecinas.
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            Task { await deleteConnection(token) }
                        } label: {
                            Label("Borrar", systemImage: "trash")
                        }
                        .tint(OG.red)
                        .accessibilityLabel("Borrar conexión")
                    }
            }
        } header: { Text("Mis conexiones") }
    }

    private var displayedTokens: [AIAccessTokenInfo] {
        tokens.filter { !hiddenConnectionIDs.contains($0.id) }
    }

    @ViewBuilder
    private func connectionRow(_ token: AIAccessTokenInfo) -> some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                Text(token.label).font(.headline)
                Text(token.permissionSummary)
                    .font(.caption).foregroundStyle(.secondary)
                if let lastUse = token.lastUseLabel {
                    Text(lastUse).font(.caption).foregroundStyle(.secondary)
                }
                if token.oauthClientID == nil {
                    Text(token.expiryLabel).font(.caption).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 88)

            VStack(alignment: .trailing, spacing: 0) {
                Text(token.isActive
                     ? (token.hasConnected ? "Conectado" : "Pendiente de conexión")
                     : "Desconectado")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
                Spacer(minLength: 0)
                if token.isActive {
                    Text("Editar")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(OG.accent)
                        .opacity(isBusy ? 0.4 : 1)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard !isBusy else { return }
                            editLabel = token.label
                            editCanWrite = token.allowsWrite
                            editCanDelete = token.allowsDelete
                            editingToken = token
                        }
                        .accessibilityAddTraits(.isButton)
                        .accessibilityLabel("Editar")
                }
            }
            .frame(maxHeight: .infinity, alignment: .topTrailing)
        }
        .padding(.vertical, 5)
    }

    private var canCreateManualToken: Bool {
        tokenName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
            && auth.isConnected
            && !isBusy
    }

    private var canSaveEdit: Bool {
        !editLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && auth.isConnected
            && !isBusy
    }

    private func editConnectionSheet(_ token: AIAccessTokenInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            OGPageHeader(title: "Editar conexión") {
                CloseToolbarButton(action: { editingToken = nil }, large: true)
            }
            .padding(.top, 4)

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nombre")
                        .font(.caption)
                        .foregroundStyle(OG.label2)
                    TextField("Nombre de la conexión", text: $editLabel)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(OG.label)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

                Divider().opacity(0.35).padding(.leading, 14)

                Toggle("Lectura", isOn: .constant(true))
                    .tint(OG.accent)
                    .disabled(true)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                Toggle("Editar", isOn: $editCanWrite)
                    .tint(OG.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                Toggle("Borrar", isOn: $editCanDelete)
                    .tint(OG.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
            }
            .background(OG.surface.opacity(0.55), in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))

            Button {
                Task { await updateConnection(token) }
            } label: {
                Text(isBusy ? "Guardando…" : "Guardar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(canSaveEdit ? OG.onAccent : OG.label2)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(canSaveEdit ? OG.accent : OG.surface2, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!canSaveEdit)

            Button {
                Task {
                    let target = token
                    editingToken = nil
                    await deleteConnection(target)
                }
            } label: {
                Text("Borrar conexión")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(OG.red)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
            .disabled(isBusy)
        }
        .padding(.horizontal, OG.pad)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .ogFittedHeight()
        .ogFittedSheet()
        .tint(OG.accent)
    }

    private var manualAccessSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            OGPageHeader(title: "Conexión manual") {
                CloseToolbarButton(action: { showManualAccess = false }, large: true)
            }
            .padding(.top, 4)

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nombre")
                        .font(.caption)
                        .foregroundStyle(OG.label2)
                    TextField("Ej. Mi entrenador IA", text: $tokenName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(OG.label)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

                Divider().opacity(0.35).padding(.leading, 14)

                HStack {
                    Text("Caducidad")
                        .font(.body)
                        .foregroundStyle(OG.label)
                    Spacer(minLength: 8)
                    Picker("Caducidad", selection: $expiry) {
                        Text("7 días").tag("7d")
                        Text("30 días").tag("30d")
                        Text("90 días").tag("90d")
                        Text("1 año").tag("365d")
                        Text("Ilimitado").tag("unlimited")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .tint(OG.accent)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

                Divider().opacity(0.35).padding(.leading, 14)

                Toggle("Lectura", isOn: .constant(true))
                    .tint(OG.accent)
                    .disabled(true)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                Toggle("Editar", isOn: $canWrite)
                    .tint(OG.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                Toggle("Borrar", isOn: $canDelete)
                    .tint(OG.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }
            .background(OG.surface.opacity(0.55), in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Servidor MCP")
                    .font(.caption)
                    .foregroundStyle(OG.label2)
                HStack(alignment: .center, spacing: 12) {
                    Text(AIProviderLaunch.publicServer)
                        .font(.system(size: 17, weight: .semibold, design: .monospaced))
                        .foregroundStyle(OG.label)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button {
                        UIPasteboard.general.string = AIProviderLaunch.publicServer
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(OG.accent)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Copiar URL del servidor MCP")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(OG.surface.opacity(0.55), in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))

            if expiry == "unlimited" {
                Label(
                    "Un token ilimitado seguirá funcionando hasta que lo revoques. Úsalo solo con asistentes de confianza.",
                    systemImage: "exclamationmark.shield"
                )
                .font(.footnote)
                .foregroundStyle(OG.label2)
                .padding(.horizontal, 4)
            }

            Button {
                Task { await createToken() }
            } label: {
                Text(isBusy ? "Creando acceso…" : "Crear token")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(canCreateManualToken ? OG.onAccent : OG.label2)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(
                        canCreateManualToken ? OG.accent : OG.surface2,
                        in: Capsule()
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canCreateManualToken)
            .opacity(canCreateManualToken ? 1 : 0.55)
        }
        .padding(.horizontal, OG.pad)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .ogFittedHeight()
        .ogFittedSheet()
        .tint(OG.accent)
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
            // Conservar la última configuración conocida ante un fallo temporal.
            catalogError = "No se pudo actualizar el catálogo de asistentes."
        }
    }

    @MainActor
    private func refreshTokens() async {
        guard auth.isConnected, let client = auth.apiClient else { return }
        guard !isLoadingConnections else { return }
        isLoadingConnections = true
        defer { isLoadingConnections = false }
        do {
            let session = try await client.auth.session
            guard !session.isExpired else {
                connectionsError = "Tu sesión ha caducado. Vuelve a iniciar sesión en Repera."
                return
            }
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
            let previouslyVerified = Set(tokens.filter(\.hasConnected).map(\.id))
            tokens = items.filter { !hiddenConnectionIDs.contains($0.id) }
            // Si el servidor ya no tiene la fila, soltar el ocultado local.
            let remoteIDs = Set(items.map(\.id))
            hiddenConnectionIDs = hiddenConnectionIDs.filter { remoteIDs.contains($0) }
            hasLoadedConnections = true
            connectionsError = nil
            for token in items where token.hasConnected && !previouslyVerified.contains(token.id) {
                ReperaAnalytics.track(.aiConnectionVerified, parameters: [
                    "feature_area": "ai",
                    "result": "success"
                ])
            }
        } catch {
            // Un error de red NO equivale a una lista vacía.
            connectionsError = "No se han podido consultar tus conexiones. Vuelve a intentarlo."
        }
    }

    @MainActor
    private func createToken() async {
        guard canCreateManualToken, let client = auth.apiClient else { return }
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
                "canWrite": canWrite,
                "canDelete": canDelete
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
            createdSetupUrl = value.setupUrl
            createdTokenAt = Date()
            tokenName = ""
            canWrite = false
            canDelete = false
            showManualAccess = false
            await refreshTokens()
        } catch {
            errorMessage = "No se pudo crear el token: \(error.localizedDescription)"
        }
    }

    private func dismissCreatedToken() {
        createdToken = nil
        createdSetupUrl = nil
        createdTokenAt = nil
    }

    private var createdTokenSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            OGPageHeader(title: "Nuevo token") {
                CloseToolbarButton(action: dismissCreatedToken, large: true)
            }
            .padding(.top, 4)

            TimelineView(.periodic(from: .now, by: 1)) { context in
                let remaining = Self.createdTokenRemaining(
                    at: context.date,
                    since: createdTokenAt
                )
                Text(Self.formatCountdown(remaining))
                    .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(remaining > 0 ? OG.label : OG.label2)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Cuenta atrás \(Self.formatCountdown(remaining))")
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Enlace del MCP")
                    .font(.caption)
                    .foregroundStyle(OG.label2)
                HStack(spacing: 10) {
                    Text(AIProviderLaunch.publicServer)
                        .font(.system(size: 15, weight: .semibold).monospaced())
                        .foregroundStyle(OG.label)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .textSelection(.enabled)
                    Spacer(minLength: 0)
                    Button {
                        UIPasteboard.general.setItems(
                            [["public.utf8-plain-text": AIProviderLaunch.publicServer]],
                            options: [.expirationDate: Date().addingTimeInterval(120)]
                        )
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.body.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(OG.accent)
                    .accessibilityLabel("Copiar enlace del MCP")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(OG.surface.opacity(0.55), in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))

            Text(createdToken ?? "")
                .font(.footnote.monospaced())
                .textSelection(.enabled)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(OG.surface.opacity(0.55), in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))

            Button {
                if let createdToken {
                    UIPasteboard.general.setItems(
                        [["public.utf8-plain-text": createdToken]],
                        options: [.expirationDate: Date().addingTimeInterval(120)]
                    )
                }
            } label: {
                Label("Copiar token", systemImage: "doc.on.doc")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(OG.onAccent)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(OG.accent, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, OG.pad)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .ogFittedHeight()
        .ogFittedSheet()
        .tint(OG.accent)
    }

    private static let createdTokenWindow: TimeInterval = 15 * 60

    private static func createdTokenRemaining(at now: Date, since start: Date?) -> TimeInterval {
        guard let start else { return 0 }
        return max(0, createdTokenWindow - now.timeIntervalSince(start))
    }

    private static func formatCountdown(_ remaining: TimeInterval) -> String {
        let total = Int(remaining.rounded(.down))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    @MainActor
    private func updateConnection(_ token: AIAccessTokenInfo) async {
        guard canSaveEdit, let client = auth.apiClient else { return }
        isBusy = true
        defer { isBusy = false }
        errorMessage = nil
        successMessage = nil
        do {
            let session = try await client.auth.session
            guard !session.isExpired else { throw AccessError.sessionExpired }
            let url = URL(string: "https://uvzgujlrqohreoucirms.supabase.co/functions/v1/repera-ai-tokens")!
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "id": token.id.uuidString,
                "label": editLabel.trimmingCharacters(in: .whitespacesAndNewlines),
                "canRead": true,
                "canWrite": editCanWrite,
                "canDelete": editCanDelete
            ])
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw AccessError.server }
            guard (200..<300).contains(http.statusCode) else {
                let issue = try? JSONDecoder().decode(AIFunctionError.self, from: data)
                throw AccessError.message(issue?.error ?? "Error HTTP \(http.statusCode)")
            }
            editingToken = nil
            successMessage = "Conexión actualizada."
            await refreshTokens()
        } catch {
            errorMessage = "No se pudo actualizar: \(error.localizedDescription)"
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
            successMessage = "Acceso desactivado. Ya no permite acceder a Repera."
        } catch {
            errorMessage = "No se pudo desactivar: \(error.localizedDescription)"
        }
    }

    /// Swipe: quita la fila. Edge `delete` (service role); si falla, oculta en UI.
    @MainActor
    private func deleteConnection(_ token: AIAccessTokenInfo) async {
        guard !isBusy, auth.isConnected, let client = auth.apiClient else { return }
        isBusy = true
        defer { isBusy = false }
        errorMessage = nil
        successMessage = nil
        // Quitar ya la fila para que el swipe no deje basura en el Form.
        hiddenConnectionIDs.insert(token.id)
        tokens.removeAll { $0.id == token.id }
        do {
            let session = try await client.auth.session
            guard !session.isExpired else { throw AccessError.sessionExpired }
            let url = URL(string: "https://uvzgujlrqohreoucirms.supabase.co/functions/v1/repera-ai-connect/delete")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: ["id": token.id.uuidString])
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                successMessage = "Conexión eliminada."
                await refreshTokens()
                return
            }
            // Fallback: desactivar + DELETE REST (migración owner delete) o solo ocultar.
            if token.isActive {
                if token.oauthClientID != nil {
                    let disconnect = URL(string: "https://uvzgujlrqohreoucirms.supabase.co/functions/v1/repera-ai-connect/disconnect")!
                    var disconnectRequest = URLRequest(url: disconnect)
                    disconnectRequest.httpMethod = "POST"
                    disconnectRequest.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
                    disconnectRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    disconnectRequest.httpBody = try JSONSerialization.data(withJSONObject: ["id": token.id.uuidString])
                    _ = try await URLSession.shared.data(for: disconnectRequest)
                } else {
                    try await client.from("ai_access_tokens")
                        .update(["revoked_at": ISO8601DateFormatter().string(from: Date())])
                        .eq("id", value: token.id.uuidString)
                        .eq("owner_id", value: session.user.id.uuidString)
                        .execute()
                }
            }
            _ = try? await client.from("ai_access_tokens")
                .delete()
                .eq("id", value: token.id.uuidString)
                .eq("owner_id", value: session.user.id.uuidString)
                .execute()
            successMessage = "Conexión eliminada."
            await refreshTokens()
        } catch {
            // La fila ya no se muestra; el acceso queda revocado si el fallback lo logró.
            successMessage = "Conexión quitada de la lista."
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
