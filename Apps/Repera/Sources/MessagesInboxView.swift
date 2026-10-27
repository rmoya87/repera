import SwiftUI

/// Bidirectional messages between athlete and linked center/trainer.
struct MessagesInboxView: View {
    @Environment(BusinessDataStore.self) private var businessData
    @Environment(BusinessAuthStore.self) private var businessAuth
    @State private var composeOrgId: UUID?
    @State private var draftTitle = ""
    @State private var draftBody = ""
    @State private var showCompose = false

    private var linked: [BusinessOrganization] {
        businessData.linkedCenters()
    }

    var body: some View {
        List {
            OGScrollablePageTitle("Mensajes").ogScrollingTitleListRow()
            if !businessAuth.isConnected || linked.isEmpty {
                Section {
                    Text(
                        linked.isEmpty
                            ? "Vincúlate a un centro o entrenador en Ajustes para enviar y recibir mensajes."
                            : "Conecta tu cuenta para ver mensajes."
                    )
                    .foregroundStyle(OG.label2)
                }
            }

            if !businessData.personalNotices.isEmpty {
                Section {
                    ForEach(businessData.personalNotices) { message in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(message.title)
                                .font(.headline)
                            Text(message.body)
                                .font(.subheadline)
                                .foregroundStyle(OG.label)
                            HStack {
                                Text(businessData.centerName(message.orgId))
                                Spacer()
                                if let when = BusinessDataStore.date(message.createdAt) {
                                    Text(when.formatted(date: .abbreviated, time: .shortened))
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(OG.label2)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Conversación")
                }
            } else if businessAuth.isConnected, !linked.isEmpty {
                Section {
                    Text("Todavía no hay mensajes.")
                        .foregroundStyle(OG.label2)
                }
            }

            if let err = businessData.errorMessage {
                Section {
                    Text(err).font(.footnote).foregroundStyle(OG.red)
                }
            }
        }
        .ogScrollingTitleNav()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !linked.isEmpty {
                    Button {
                        composeOrgId = linked.first?.id
                        draftTitle = ""
                        draftBody = ""
                        showCompose = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(OG.label)
                    }
                    .accessibilityLabel("Escribir mensaje")
                }
            }
        }
        .task {
            if businessAuth.isConnected {
                await businessData.refresh()
            }
        }
        .sheet(isPresented: $showCompose) {
            NavigationStack {
                Form {
                    if linked.count > 1 {
                        Picker("Para", selection: Binding(
                            get: { composeOrgId ?? linked.first?.id },
                            set: { composeOrgId = $0 }
                        )) {
                            ForEach(linked) { center in
                                Text(center.name).tag(Optional(center.id))
                            }
                        }
                    } else if let only = linked.first {
                        LabeledContent("Para", value: only.name)
                    }

                    TextField("Asunto", text: $draftTitle)
                    TextField("Mensaje", text: $draftBody, axis: .vertical)
                        .lineLimit(4...8)

                    Button {
                        Task {
                            guard let orgId = composeOrgId ?? linked.first?.id else { return }
                            let title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                            let body = draftBody.trimmingCharacters(in: .whitespacesAndNewlines)
                            let ok = await businessData.sendMessage(
                                to: orgId,
                                title: title.isEmpty ? "Mensaje" : title,
                                body: body
                            )
                            if ok {
                                showCompose = false
                            }
                        }
                    } label: {
                        if businessData.isSubmitting {
                            ProgressView()
                        } else {
                            Text("Enviar")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(OG.label)
                        }
                    }
                    .disabled(
                        businessData.isSubmitting
                            || draftBody.trimmingCharacters(in: .whitespacesAndNewlines).count < 2
                    )
                }
                .navigationTitle("Nuevo mensaje")
                .navigationBarTitleDisplayMode(.inline)
                .ogTransparentNav()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cerrar") { showCompose = false }
                    }
                }
            }
            .ogSheetChrome(detents: [.medium, .large])
        }
    }
}
