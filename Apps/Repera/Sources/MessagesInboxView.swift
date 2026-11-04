import SwiftUI

/// Chat nativo 1:1 con el centro o entrenador (burbujas enviadas/recibidas).
struct MessagesInboxView: View {
    @Environment(BusinessDataStore.self) private var businessData
    @Environment(BusinessAuthStore.self) private var businessAuth
    var initialOrgId: UUID? = nil

    @State private var selectedOrgId: UUID?
    @State private var draft = ""
    @FocusState private var composerFocused: Bool

    private var linked: [BusinessOrganization] {
        businessData.linkedCenters()
    }

    private var activeOrgId: UUID? {
        selectedOrgId ?? initialOrgId ?? linked.first?.id
    }

    private var thread: [BusinessConversationMessage] {
        guard let orgId = activeOrgId else { return [] }
        return businessData.conversationMessages.filter { $0.orgId == orgId }
    }

    var body: some View {
        VStack(spacing: 0) {
            if !businessAuth.isConnected {
                ContentUnavailableView {
                    Label("Conecta tu cuenta", systemImage: "person.crop.circle.badge.exclamationmark")
                } description: {
                    Text("Inicia sesión en Repera para ver los mensajes de tu centro o entrenador.")
                } actions: {
                    Button("Reintentar") {
                        Task { await reconnect() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(OG.accent)
                    .foregroundStyle(.black)
                }
            } else if linked.isEmpty {
                ContentUnavailableView {
                    Label("Sin centros vinculados", systemImage: "bubble.left.and.bubble.right")
                } description: {
                    Text("Vincúlate a un centro o entrenador para chatear.")
                } actions: {
                    NavigationLink("Buscar centro o entrenador") {
                        FindCenterTrainerView()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(OG.accent)
                    .foregroundStyle(.black)
                }
            } else {
                if linked.count > 1 {
                    Picker("Centro", selection: Binding(
                        get: { activeOrgId ?? linked[0].id },
                        set: { selectedOrgId = $0; Task { await loadSelected() } }
                    )) {
                        ForEach(linked) { center in
                            Text(center.name).tag(center.id)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, OG.pad)
                    .padding(.vertical, 10)
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            if thread.isEmpty && businessData.isLoading {
                                ProgressView("Cargando mensajes…")
                                    .tint(OG.accent)
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 40)
                            } else if thread.isEmpty {
                                ContentUnavailableView {
                                    Label("Sin mensajes", systemImage: "bubble.left.and.text.bubble.right")
                                } description: {
                                    Text("Escribe a \(activeCenterName) y verás aquí su respuesta.")
                                } actions: {
                                    Button("Escribir mensaje") {
                                        composerFocused = true
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(OG.accent)
                                    .foregroundStyle(.black)
                                }
                                .padding(.top, 24)
                            }
                            ForEach(thread) { message in
                                chatBubble(message)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal, OG.pad)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: thread.count) { _, _ in
                        if let last = thread.last {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

            }

            if let err = businessData.errorMessage {
                Text(err)
                    .font(.footnote)
                    .foregroundStyle(OG.red)
                    .padding(.horizontal, OG.pad)
                    .padding(.bottom, 8)
            }
        }
        .background(OG.bg)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if businessAuth.isConnected && !linked.isEmpty {
                composer
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .ogPinnedTransparentNav("Mensajes")
        .task {
            if selectedOrgId == nil {
                selectedOrgId = initialOrgId ?? linked.first?.id
            }
            if businessAuth.isConnected {
                await businessData.refresh()
                await loadSelected()
            }
        }
        .refreshable {
            await loadSelected()
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Mensaje", text: $draft, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(OG.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .focused($composerFocused)

            Button {
                Task { await send() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        canSend ? OG.accent : OG.label2.opacity(0.35)
                    )
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .disabled(!canSend || businessData.isSubmitting)
            .accessibilityLabel("Enviar")
        }
        .padding(.horizontal, OG.pad)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private var canSend: Bool {
        draft.trimmingCharacters(in: .whitespacesAndNewlines).count >= 1
            && activeOrgId != nil
    }

    @ViewBuilder
    private func chatBubble(_ message: BusinessConversationMessage) -> some View {
        let mine = !message.isFromStaff
        HStack {
            if mine { Spacer(minLength: 48) }
            VStack(alignment: mine ? .trailing : .leading, spacing: 4) {
                Text(message.body)
                    .font(.body)
                    .foregroundStyle(mine ? Color.white : OG.label)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        mine ? OG.accent : OG.surface,
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                HStack(spacing: 6) {
                    if message.batchId != nil {
                        Text("Aviso")
                    }
                    if let when = BusinessDataStore.date(message.createdAt) {
                        Text(when.formatted(date: .omitted, time: .shortened))
                    }
                }
                .font(.caption2)
                .foregroundStyle(OG.label2)
            }
            if !mine { Spacer(minLength: 48) }
        }
    }

    private var activeCenterName: String {
        let name = activeOrgId.map { businessData.centerName($0) } ?? ""
        return name.isEmpty ? "tu centro" : name
    }

    private func reconnect() async {
        await businessAuth.restoreSession()
        if !businessAuth.isConnected {
            _ = businessAuth.connectFromCachedSessionIfPossible()
        }
        guard businessAuth.isConnected else { return }
        await businessData.refresh()
        await loadSelected()
    }

    private func loadSelected() async {
        guard let orgId = activeOrgId else { return }
        await businessData.loadThread(orgId: orgId)
    }

    private func send() async {
        guard let orgId = activeOrgId else { return }
        let body = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        draft = ""
        let ok = await businessData.sendChatMessage(to: orgId, body: body)
        if !ok {
            draft = body
        }
    }
}
