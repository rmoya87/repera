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
        // Título fuera de List: evita el recorte de glifos del row agrupado.
        // Una única franja superior de 6 pt; la List empieza sin inset extra.
        VStack(spacing: 0) {
            OGScrollablePageTitle("Buscar")
                .padding(.horizontal, OG.pad)
                .padding(.top, 6)
                .frame(maxWidth: OG.contentColumnMaxWidth, alignment: .leading)
                .frame(maxWidth: .infinity)

            List {
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
            .ogListChrome()
            .contentMargins(.top, 0, for: .scrollContent)
        }
        .background(OG.bg.ignoresSafeArea())
        .onSubmit(of: .search) {
            guard businessAuth.isConnected else { return }
            ReperaAnalytics.track(.centerSearchUsed, parameters: [
                "feature_area": "center",
                "result": "success"
            ])
            Task { await businessData.searchDirectory(query: query) }
        }
        .onChange(of: query) { _, value in
            Task {
                try? await Task.sleep(for: .milliseconds(350))
                guard query == value, businessAuth.isConnected else { return }
                guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                ReperaAnalytics.track(.centerSearchUsed, parameters: [
                    "feature_area": "center",
                    "result": "success"
                ])
                await businessData.searchDirectory(query: value)
            }
        }
        .ogScrollingTitleNav(usesGroupedList: false)
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

    private var payments: [BusinessPass] {
        businessData.paymentHistory(for: center.id)
    }

    private var classHistory: [(booking: BusinessBooking, occurrence: BusinessOccurrence)] {
        let occById = Dictionary(uniqueKeysWithValues: businessData.occurrences.map { ($0.id, $0) })
        return businessData.pastBookings(for: center.id).compactMap { booking in
            guard let occ = occById[booking.occurrenceId] else { return nil }
            return (booking, occ)
        }
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
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                if payments.isEmpty {
                    Text("Todavía no hay pagos registrados con este centro.")
                        .foregroundStyle(OG.label2)
                } else {
                    ForEach(payments) { pass in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(businessData.offerName(for: pass) ?? (pass.kind == "class" ? "Plan de clases" : "Plan de citas"))
                                .font(.headline)
                            HStack {
                                Text(linkedPaymentLabel(pass))
                                Spacer()
                                if let cents = pass.paidAmountCents {
                                    Text((Double(cents) / 100).formatted(.currency(code: "EUR")))
                                        .fontWeight(.semibold)
                                }
                            }
                            .font(.subheadline)
                            .foregroundStyle(OG.label2)
                            if let when = BusinessDataStore.date(pass.paidAt ?? pass.validFrom) {
                                Text(when.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(OG.label2)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            } header: {
                Text("Historial de pagos")
            } footer: {
                Text("Los cobros se confirman fuera de Repera; aquí solo ves el registro del centro.")
            }

            Section {
                if classHistory.isEmpty {
                    Text("Aún no has asistido ni reservado clases con este centro.")
                        .foregroundStyle(OG.label2)
                } else {
                    ForEach(classHistory, id: \.booking.id) { row in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(row.occurrence.title).font(.headline)
                            if let start = BusinessDataStore.date(row.occurrence.startsAt) {
                                Text(start.formatted(date: .abbreviated, time: .shortened))
                                    .font(.subheadline)
                                    .foregroundStyle(OG.label2)
                            }
                            Text(linkedBookingStatus(row.booking.status))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(OG.accent)
                        }
                        .padding(.vertical, 2)
                    }
                }
            } header: {
                Text("Historial de clases")
            }

            if let error = businessData.errorMessage {
                Section {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(OG.red)
                }
            }

            Section {
                Button("Desvincularme como cliente", role: .destructive) {
                    confirmLeave = true
                }
                .disabled(businessData.isSubmitting)
            } footer: {
                Text("Se cancelarán tus reservas futuras y bonos activos. Si administras el centro, conservarás tus permisos de gestión. Tu historial personal no se borra.")
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
                        Text("¿Dejar de ser cliente de \(center.name)?")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(OG.label)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Esta acción no se puede deshacer.")
                            .font(.subheadline)
                            .foregroundStyle(OG.label2)
                    }
                }

                Text("Se cancelarán las reservas futuras y los bonos activos de este centro. Tus resultados y entrenamientos personales no se borrarán. Si eres propietario o miembro del equipo, seguirás teniendo acceso a la gestión.")
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
                        Text(businessData.isSubmitting ? "Desvinculando…" : "Desvincularme como cliente")
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

    private func linkedPaymentLabel(_ pass: BusinessPass) -> String {
        if pass.issuanceType == "complimentary" || pass.paymentMethod == "complimentary" {
            return "Cortesía"
        }
        switch pass.paymentMethod {
        case "cash": return "Efectivo"
        case "transfer": return "Transferencia"
        case "card": return "Tarjeta"
        case "other": return "Otro cobro"
        default: return pass.issuanceType == "manual_offline" ? "Cobro externo" : "Plan"
        }
    }

    private func linkedBookingStatus(_ status: String) -> String {
        switch status {
        case "attended": return "Asististe"
        case "booked": return "Reservada"
        case "waitlist": return "Lista de espera"
        case "cancelled": return "Cancelada"
        case "no_show": return "No presentado"
        default: return status
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
