import SwiftUI

/// Directory + invitations to link with a gym or trainer and pick a pass.
struct FindCenterTrainerView: View {
    @Environment(BusinessAuthStore.self) private var businessAuth
    @Environment(BusinessDataStore.self) private var businessData
    @Environment(AppleAuthStore.self) private var appleAuth
    @Environment(ReperaStore.self) private var store
    @State private var query = ""
    @State private var selectedOrg: BusinessOrganization?
    @State private var passKind = "class"
    @State private var note = ""
    @State private var appleConnectionError: String?

    var body: some View {
        List {
            if !businessAuth.isConnected {
                Section {
                    Text("Inicia sesión con Apple para buscar centros y entrenadores.")
                        .foregroundStyle(OG.label2)
                    Button {
                        Task {
                            do {
                                try await appleAuth.signIn()
                                await businessAuth.migrateLocalProfileIfNeeded(
                                    displayName: store.state.settings.profileDisplayName ?? appleAuth.displayName
                                )
                                await businessData.refresh()
                                await businessData.searchDirectory(query: query)
                            } catch {
                                appleConnectionError = error.localizedDescription
                            }
                        }
                    } label: {
                        Label("Conectar con Apple", systemImage: "apple.logo")
                            .foregroundStyle(OG.label)
                    }
                    .disabled(appleAuth.isSigningIn || businessAuth.isConnecting)
                    if let appleConnectionError {
                        Text(appleConnectionError).font(.footnote).foregroundStyle(OG.red)
                    }
                    if let err = businessAuth.lastErrorMessage {
                        Text(err).font(.footnote).foregroundStyle(OG.red)
                    }
                }
            }

            let linked = businessData.linkedCenters()
            if !linked.isEmpty {
                Section {
                    ForEach(linked) { center in
                        NavigationLink {
                            LinkedCenterDetailView(center: center)
                        } label: {
                            CenterRow(center: center, linked: true)
                        }
                    }
                } header: {
                    Text("Vinculados")
                }
            }

            if !businessData.invitations.isEmpty {
                Section {
                    ForEach(businessData.invitations) { invite in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Invitación pendiente")
                                .font(.headline)
                            Text(invite.invitedRole == "athlete" ? "Como deportista" : invite.invitedRole)
                                .font(.subheadline)
                                .foregroundStyle(OG.label2)
                            Button {
                                Task { await businessData.accept(invite) }
                            } label: {
                                Text("Aceptar")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(OG.label)
                            }
                            .disabled(businessData.isSubmitting)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Invitaciones")
                }
            }

            Section {
                TextField("Buscar por nombre", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit {
                        Task { await businessData.searchDirectory(query: query) }
                    }
                    .onChange(of: query) { _, value in
                        Task {
                            try? await Task.sleep(for: .milliseconds(350))
                            guard query == value else { return }
                            await businessData.searchDirectory(query: value)
                        }
                    }

                if businessData.isSearchingDirectory {
                    ProgressView()
                } else if businessData.directory.isEmpty {
                    Text("No hay resultados. Prueba otro nombre o pide invitación a tu centro.")
                        .foregroundStyle(OG.label2)
                } else {
                    ForEach(businessData.directory) { org in
                        Button {
                            selectedOrg = org
                        } label: {
                            CenterRow(
                                center: org,
                                linked: businessData.athleteCenterIds.contains(org.id)
                            )
                        }
                        .disabled(businessData.athleteCenterIds.contains(org.id))
                    }
                }
            } header: {
                Text("Buscar")
            } footer: {
                Text("Al vincularte eliges el bono y la app pasa a acceso completo mientras mantengas el vínculo. Puedes desvincularte cuando quieras.")
            }

            if let err = businessData.errorMessage {
                Section {
                    Text(err).font(.footnote).foregroundStyle(OG.red)
                }
            }
        }
        .ogPinnedTransparentNav("Buscar centro o entrenador")
        .task {
            if businessAuth.isConnected {
                await businessData.refresh()
                await businessData.searchDirectory(query: query)
            }
        }
        .sheet(item: $selectedOrg) { org in
            LinkPassSheet(
                org: org,
                passKind: $passKind,
                note: $note
            ) {
                Task {
                    let ok = await businessData.requestLink(
                        to: org,
                        passKind: passKind,
                        note: note.isEmpty ? nil : note
                    )
                    if ok {
                        selectedOrg = nil
                        note = ""
                    }
                }
            }
            .ogSheetChrome(detents: [.medium, .large])
        }
    }
}

/// Detail of a linked center: passes, sessions, sharing, unlink.
struct LinkedCenterDetailView: View {
    @Environment(BusinessDataStore.self) private var businessData
    @Environment(BusinessWorkoutSyncStore.self) private var workoutSync
    let center: BusinessOrganization
    @State private var confirmLeave = false
    @Environment(\.dismiss) private var dismiss

    private var orgPasses: [BusinessPass] {
        businessData.passesForOrg(center.id)
    }

    private var orgSessions: [BusinessProfessionalTrainingSession] {
        businessData.trainingSessions.filter { $0.orgId == center.id }
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 14) {
                    OrganizationAvatarView(center: center, size: 56)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(center.name).font(.headline)
                        Text(center.kindLabel)
                            .font(.subheadline)
                            .foregroundStyle(OG.label2)
                        if let tagline = center.tagline, !tagline.isEmpty {
                            Text(tagline)
                                .font(.caption)
                                .foregroundStyle(OG.label2)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                if orgPasses.isEmpty {
                    Text("Sin bonos activos. El centro confirmará tu bono solicitado.")
                        .foregroundStyle(OG.label2)
                } else {
                    ForEach(orgPasses) { pass in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pass.kind == "appointment" ? "Sesiones personales" : "Clases")
                                .font(.headline)
                            Text("\(pass.remainingCredits) de \(pass.totalCredits) disponibles")
                                .foregroundStyle(OG.label)
                            if let end = BusinessDataStore.date(pass.validUntil) {
                                Text("Caduca: \(end.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(OG.label2)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            } header: {
                Text("Bonos y sesiones")
            }

            if !orgSessions.isEmpty {
                Section {
                    ForEach(orgSessions.prefix(12)) { session in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(session.title).font(.subheadline.weight(.medium))
                            Text(session.scheduledDate)
                                .font(.caption)
                                .foregroundStyle(OG.label2)
                        }
                    }
                } header: {
                    Text("Planificación")
                }
            }

            Section {
                Toggle(isOn: Binding(
                    get: { workoutSync.sharingByCenter[center.id] == true },
                    set: { enabled in
                        Task { await workoutSync.setSharing(enabled, for: center.id) }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Compartir resultados")
                        Text("Series, repeticiones y marcas con el equipo. Puedes desactivarlo.")
                            .font(.caption)
                            .foregroundStyle(OG.label2)
                    }
                }
                .disabled(workoutSync.updatingSharingCenter != nil)
            } header: {
                Text("Privacidad")
            }

            Section {
                Button("Desvincularme", role: .destructive) {
                    confirmLeave = true
                }
                .disabled(businessData.isSubmitting)
            } footer: {
                Text("Al desvincularte pierdes el acceso completo asociado a este centro, salvo que tengas Repera Pro.")
            }
        }
        .navigationTitle(center.name)
        .navigationBarTitleDisplayMode(.inline)
        .ogTransparentNav()
        .confirmationDialog(
            "¿Desvincularte de \(center.name)?",
            isPresented: $confirmLeave,
            titleVisibility: .visible
        ) {
            Button("Desvincularme", role: .destructive) {
                Task {
                    if await businessData.leave(center) {
                        dismiss()
                    }
                }
            }
            Button("Cancelar", role: .cancel) {}
        }
    }
}

private struct LinkPassSheet: View {
    let org: BusinessOrganization
    @Binding var passKind: String
    @Binding var note: String
    var onConfirm: () -> Void
    @Environment(BusinessDataStore.self) private var businessData
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        OrganizationAvatarView(center: org, size: 48)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(org.name).font(.headline)
                            Text(org.kindLabel)
                                .font(.subheadline)
                                .foregroundStyle(OG.label2)
                        }
                    }
                }

                Section {
                    Picker("Bono", selection: $passKind) {
                        Text("Clases / bono de sesiones").tag("class")
                        Text("Entrenador personal").tag("appointment")
                        Text("Acceso ilimitado").tag("unlimited")
                    }
                    TextField("Nota para el centro (opcional)", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Qué quieres contratar")
                } footer: {
                    Text("El centro confirmará el bono. Mientras estés vinculado, la app tendrá acceso completo.")
                }

                Section {
                    Button {
                        onConfirm()
                    } label: {
                        if businessData.isSubmitting {
                            ProgressView()
                        } else {
                            Text("Vincularme y continuar")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(OG.label)
                        }
                    }
                    .disabled(businessData.isSubmitting)
                }
            }
            .navigationTitle("Vincular")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}

struct CenterRow: View {
    let center: BusinessOrganization
    var linked: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            OrganizationAvatarView(center: center, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(center.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(OG.label)
                Text(center.kindLabel + (linked ? " · Vinculado" : ""))
                    .font(.caption)
                    .foregroundStyle(OG.label2)
            }
            Spacer(minLength: 0)
            if linked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(OG.label)
            }
        }
    }
}

struct OrganizationAvatarView: View {
    let center: BusinessOrganization
    var size: CGFloat = 40

    var body: some View {
        Group {
            if let urlString = center.avatarUrl,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var placeholder: some View {
        ZStack {
            Circle().fill(OG.surface2)
            Text(initials)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(OG.label)
        }
    }

    private var initials: String {
        let parts = center.name.split(separator: " ").prefix(2)
        let chars = parts.compactMap { $0.first.map(String.init) }
        return chars.joined().uppercased().isEmpty ? "R" : chars.joined().uppercased()
    }
}
