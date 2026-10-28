import SwiftUI

/// Directory + invitations to link with a gym or trainer and pick a pass.
struct FindCenterTrainerView: View {
    @Environment(BusinessAuthStore.self) private var businessAuth
    @Environment(BusinessDataStore.self) private var businessData
    @State private var query = ""
    @State private var selectedOrg: BusinessOrganization?
    @State private var passKind = "class"
    @State private var note = ""

    var body: some View {
        List {
            OGScrollablePageTitle("Buscar").ogScrollingTitleListRow()
            Section {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(OG.label2)
                    TextField("Nombre del entrenador o centro", text: $query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                    if !query.isEmpty {
                        Button { query = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(OG.label2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 5)
            }
            if !businessAuth.isConnected {
                Section {
                    Label("No se han podido cargar los centros.", systemImage: "wifi.exclamationmark")
                        .foregroundStyle(OG.label2)
                    if let error = businessAuth.lastErrorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(OG.label2)
                    }
                    Button("Reintentar") {
                        Task { await restoreAndLoadDirectory() }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(OG.accent)
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
                if !businessAuth.isConnected {
                    Text("La búsqueda estará disponible al recuperar la conexión.")
                        .foregroundStyle(OG.label2)
                } else if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass.circle")
                            .font(.system(size: 38, weight: .light))
                            .foregroundStyle(OG.accent)
                        Text("Busca tu entrenador o centro")
                            .font(.system(size: 17, weight: .semibold))
                        Text("Escribe su nombre para encontrarlo y solicitar la vinculación.")
                            .font(.subheadline)
                            .foregroundStyle(OG.label2)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .padding(14)
                    .background(OG.surface2.opacity(0.4), in: RoundedRectangle(cornerRadius: 14))
                    .listRowSeparator(.hidden)
                } else if businessData.isSearchingDirectory {
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
                        .buttonStyle(.plain)
                        .disabled(businessData.athleteCenterIds.contains(org.id))
                    }
                }
            } header: {
                if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Resultados")
                }
            }

            if let err = businessData.errorMessage {
                Section {
                    Text(err).font(.footnote).foregroundStyle(OG.red)
                }
            }
        }
        .listStyle(.insetGrouped)
        .ogListChrome()
         .onSubmit(of: .search) {
            guard businessAuth.isConnected else { return }
            Task { await businessData.searchDirectory(query: query) }
        }
        .onChange(of: query) { _, value in
            Task {
                try? await Task.sleep(for: .milliseconds(350))
                guard query == value, businessAuth.isConnected else { return }
                guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                await businessData.searchDirectory(query: value)
            }
        }
        .ogScrollingTitleNav()
        .task {
            await restoreAndLoadDirectory()
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

    /// Recupera la sesión Supabase creada durante el login Apple, sin otra autorización.
    private func restoreAndLoadDirectory() async {
        if !businessAuth.isConnected {
            await businessAuth.restoreSession()
            if !businessAuth.isConnected {
                _ = businessAuth.connectFromCachedSessionIfPossible()
            }
        }
        guard businessAuth.isConnected else { return }
        await businessData.refresh()
        if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            await businessData.searchDirectory(query: query)
        }
    }
}

/// Detail of a linked center: passes, sessions, sharing, unlink.
struct LinkedCenterDetailView: View {
    @Environment(BusinessDataStore.self) private var businessData
    let center: BusinessOrganization
    @State private var confirmLeave = false
    @State private var leaveSheetHeight: CGFloat = 310
    @Environment(\.dismiss) private var dismiss

    private var orgPasses: [BusinessPass] {
        businessData.passesForOrg(center.id)
    }

    private var orgOffers: [BusinessPassOffer] {
        businessData.offersForOrg(center.id)
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
                    Text("No tienes bonos activos con este entrenador o centro.")
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
                Text("Mis bonos")
            }

            Section {
                if orgOffers.isEmpty {
                    Text("El entrenador todavía no ha publicado bonos disponibles.")
                        .foregroundStyle(OG.label2)
                } else {
                    ForEach(orgOffers) { offer in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(offer.name).font(.headline)
                                Spacer()
                                Text(offer.localizedPrice).font(.subheadline.weight(.semibold))
                            }
                            Text("\(offer.credits) " +
                                 (offer.kind == "appointment" ? "sesiones personales" : "clases") +
                                 " · \(offer.validityDays) días de validez")
                                .foregroundStyle(OG.label2)
                                .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: {
                Text("Bonos disponibles")
            } footer: {
                Text("La compra se habilitará cuando el centro configure una pasarela de pago verificada. Los bonos publicados no se activan sin confirmación del cobro.")
            }

            if let error = businessData.errorMessage {
                Section {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(OG.red)
                }
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
        .listStyle(.insetGrouped)
        .ogListChrome()
        .navigationTitle(center.name)
        .navigationBarTitleDisplayMode(.inline)
        .ogTransparentNav()
        .sheet(isPresented: $confirmLeave) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.xmark")
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundStyle(OG.red)
                        .frame(width: 48, height: 48)
                        .background(OG.red.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("¿Desvincularte de \\(center.name)?")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(OG.label)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Esta acción no se puede deshacer.")
                            .font(.subheadline)
                            .foregroundStyle(OG.label2)
                    }
                }

                Text("Perderás el acceso asociado a este entrenador, sus clases y tus bonos. Se cancelarán las reservas futuras. Tus entrenamientos personales y resultados guardados en Repera no se borrarán.")
                    .font(.subheadline)
                    .foregroundStyle(OG.label2)
                    .fixedSize(horizontal: false, vertical: true)

                if let error = businessData.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(OG.red)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    Task {
                        if await businessData.leave(center) {
                            confirmLeave = false
                            dismiss()
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if businessData.isSubmitting {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(businessData.isSubmitting ? "Desvinculando…" : "Desvincularme")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(OG.red, in: RoundedRectangle(cornerRadius: 13))
                }
                .buttonStyle(.plain)
                .disabled(businessData.isSubmitting)

                Button("Cancelar") {
                    confirmLeave = false
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(OG.label)
                .frame(maxWidth: .infinity, minHeight: 48)
                .disabled(businessData.isSubmitting)
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            leaveSheetHeight = geometry.size.height
                        }
                        .onChange(of: geometry.size.height) { _, height in
                            if height > 0 { leaveSheetHeight = height }
                        }
                }
            }
            .presentationDetents([.height(max(260, leaveSheetHeight))])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(26)
            .presentationBackground(OG.surface)
            .interactiveDismissDisabled(businessData.isSubmitting)
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
                    Picker("Servicio de interés", selection: $passKind) {
                        Text("Clases / bono de sesiones").tag("class")
                        Text("Entrenador personal").tag("appointment")
                    }
                    TextField("Nota para el centro (opcional)", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Qué quieres contratar")
                } footer: {
                    Text("La vinculación no compra ni activa un bono. Los precios los publica cada entrenador o centro.")
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
            .ogTransparentNav()
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
