import SwiftUI

/// Hub de relación Center: bonos, aforo, reservas, chat y agenda unificada.
/// Nunca inventa plazas ni cupos: aforo vía `get_service_availability`.
struct CenterView: View {
    @Environment(BusinessAuthStore.self) private var auth
    @Environment(BusinessDataStore.self) private var business

    private enum CenterSection: String, CaseIterable, Identifiable {
        case classes, appointments, openAccess, agenda
        var id: Self { self }
        var title: String {
            switch self {
            case .classes: "Clases"
            case .appointments: "Citas"
            case .openAccess: "Acceso libre"
            case .agenda: "Agenda"
            }
        }
        var serviceKind: String? {
            switch self {
            case .classes: "class"
            case .appointments: "appointment"
            case .openAccess: "open_access"
            case .agenda: nil
            }
        }
    }

    private var visibleSections: [CenterSection] {
        let showOpen = business.centers.contains { business.openAccessEnabled(for: $0.id) }
        return CenterSection.allCases.filter { $0 != .openAccess || showOpen }
    }
    @State private var selectedSection: CenterSection = .classes
    @State private var bookingPendingCancellation: BusinessBooking?
    @State private var chatOrgId: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                OGCardSectionTitle(title: "Mis centros y entrenadores")

                if !auth.isConnected {
                    OGCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("No se han podido cargar tus centros", systemImage: "wifi.exclamationmark")
                                .font(.headline)
                            Button("Reintentar") {
                                Task { await refreshCenters() }
                            }
                            .fontWeight(.semibold)
                            .foregroundStyle(OG.accent)
                        }
                    }
                } else {
                    if business.isLoading {
                        ProgressView("Sincronizando centros…").tint(OG.accent)
                    }
                    if let message = business.errorMessage {
                        Text(message).foregroundStyle(OG.red).font(.footnote)
                    }
                    if business.linkedCenters().isEmpty && business.invitations.isEmpty {
                        OGCard {
                            Text("Todavía no perteneces a ningún centro. Tu entrenador o gimnasio puede invitarte al correo de tu cuenta.")
                                .foregroundStyle(OG.label2)
                        }
                    }
                    ForEach(business.invitations) { invitation in
                        invitationCard(invitation)
                    }
                    ForEach(business.linkedCenters()) { center in
                        centerHubCard(center)
                    }
                }

                OGCardSectionTitle(title: "Reservas y agenda")
                Picker("Tipo", selection: $selectedSection) {
                    ForEach(visibleSections) { section in
                        Text(section.title).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Clases, citas, acceso libre o agenda")

                if selectedSection == .agenda {
                    agendaSection
                } else {
                    let kind = selectedSection.serviceKind!
                    let available = business.occurrences.filter {
                        $0.kind == kind
                            && (BusinessDataStore.date($0.startsAt) ?? .distantPast) > Date()
                    }
                    if available.isEmpty {
                        OGCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Label(
                                    selectedSection == .classes ? "Sin clases disponibles"
                                        : selectedSection == .openAccess ? "Sin franjas de acceso libre"
                                        : "Sin citas disponibles",
                                    systemImage: "calendar.badge.clock"
                                )
                                    .font(.headline)
                                Text("Se mostrarán aquí los horarios reales que publique tu centro o entrenador.")
                                    .font(.subheadline)
                                    .foregroundStyle(OG.label2)
                            }
                        }
                    }
                    ForEach(available) { occurrence in
                        occurrenceCard(occurrence)
                    }
                }

                NavigationLink {
                    SettingsView()
                } label: {
                    Label("Más opciones en Ajustes", systemImage: "gearshape")
                        .foregroundStyle(OG.accent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                }
            }
            .padding(.horizontal, OG.pad)
            .padding(.top, 12)
            .padding(.bottom, 40)
            .ogReadableColumn()
        }
        .background(OG.bg)
        .ogFixedTopBar("Center") {
            OGToolbarGlassButton(systemName: "arrow.clockwise", accessibilityLabel: "Actualizar Center") {
                Task { await refreshCenters() }
            }
        }
        .task { await refreshCenters() }
        .navigationDestination(item: $chatOrgId) { orgId in
            MessagesInboxView(initialOrgId: orgId)
        }
        .sheet(item: $bookingPendingCancellation) { booking in
            OGConfirmSheet(
                systemImage: "calendar.badge.minus",
                title: "¿Cancelar la reserva?",
                message: cancellationNotice,
                confirmTitle: "Confirmar cancelación",
                onConfirm: {
                    bookingPendingCancellation = nil
                    Task { await business.cancel(booking) }
                },
                onCancel: { bookingPendingCancellation = nil }
            )
        }
    }

    @ViewBuilder
    private var agendaSection: some View {
        let upcomingBookings = business.bookings.filter { $0.status == "booked" }
        let todayKey = BusinessDataStore.localDayKey(Date())
        let plans = business.trainingSessions.filter { $0.scheduledDate >= todayKey }
        if upcomingBookings.isEmpty && plans.isEmpty {
            OGCard {
                Text("No tienes clases, citas ni entrenos prescritos próximos.")
                    .foregroundStyle(OG.label2)
            }
        }
        ForEach(upcomingBookings) { booking in
            if let occurrence = business.occurrences.first(where: { $0.id == booking.occurrenceId }) {
                OGCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(occurrence.title).font(.headline)
                        Text(business.centerName(occurrence.orgId))
                            .font(.subheadline).foregroundStyle(OG.label2)
                        if let start = BusinessDataStore.date(occurrence.startsAt) {
                            Text(start.formatted(date: .abbreviated, time: .shortened))
                        }
                        Text(occurrence.kind == "class" ? "Clase reservada" : "Cita reservada")
                            .font(.caption).foregroundStyle(OG.accent)
                    }
                }
            }
        }
        ForEach(plans) { session in
            OGCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text(session.title).font(.headline)
                    Text(business.centerName(session.orgId))
                        .font(.subheadline).foregroundStyle(OG.label2)
                    Text("Entreno prescrito · \(session.scheduledDate)")
                        .font(.caption).foregroundStyle(OG.label2)
                    if session.scheduledTimeMinutes == nil {
                        Text("Sin hora concreta — aparece en tu día de Inicio.")
                            .font(.footnote).foregroundStyle(OG.label2)
                    }
                }
            }
        }
    }

    private func invitationCard(_ invitation: BusinessInvitation) -> some View {
        OGCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Invitación a un centro", systemImage: "envelope.badge")
                    .font(.headline)
                Text("Perfil: \(invitation.invitedRole). Aceptar vinculará tu cuenta sin compartir tu historial personal.")
                    .font(.footnote)
                    .foregroundStyle(OG.label2)
                HStack(spacing: 12) {
                    Button("Aceptar") {
                        Task { await business.accept(invitation) }
                    }
                    .disabled(business.isSubmitting)
                    .foregroundStyle(OG.accent)
                    Button("Rechazar", role: .destructive) {
                        Task { await business.decline(invitation) }
                    }
                    .disabled(business.isSubmitting)
                }
            }
        }
    }

    private func centerHubCard(_ center: BusinessOrganization) -> some View {
        let wallets = business.activePasses(for: center.id)
        return OGCard {
            VStack(alignment: .leading, spacing: 12) {
                Label(center.name, systemImage: center.kind == "personal_trainer" ? "person.fill" : "building.2")
                    .font(.headline)
                if let tagline = center.tagline, !tagline.isEmpty {
                    Text(tagline).font(.footnote).foregroundStyle(OG.label2)
                }
                if wallets.isEmpty {
                    Text("Sin bono activo. Pide a tu centro que te asigne uno.")
                        .font(.footnote).foregroundStyle(OG.label2)
                } else {
                    ForEach(wallets) { pass in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pass.kind == "appointment" ? "Sesiones personales" : "Clases")
                                .font(.subheadline.weight(.semibold))
                            Text("\(pass.remainingCredits) de \(pass.totalCredits) disponibles")
                                .font(.footnote)
                            if let end = BusinessDataStore.date(pass.validUntil) {
                                Text("Caduca \(end.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption2).foregroundStyle(OG.label2)
                            }
                        }
                    }
                }
                Button {
                    chatOrgId = center.id
                } label: {
                    Label("Contactar / chat", systemImage: "bubble.left.and.bubble.right")
                        .foregroundStyle(OG.accent)
                }
                .disabled(business.clientId(for: center.id) == nil)
            }
        }
    }

    private func refreshCenters() async {
        if !auth.isConnected {
            await auth.restoreSession()
            if !auth.isConnected {
                _ = auth.connectFromCachedSessionIfPossible()
            }
        }
        guard auth.isConnected else { return }
        await business.refresh()
    }

    private var cancellationNotice: String {
        guard let booking = bookingPendingCancellation,
              let occurrence = business.occurrences.first(where: { $0.id == booking.occurrenceId }),
              let startsAt = BusinessDataStore.date(occurrence.startsAt) else {
            return "El centro aplicará su política de cancelación. Se comprobará el saldo real tras confirmar."
        }
        if startsAt > Date().addingTimeInterval(12 * 3600) {
            return "Si cancelas con más de 12 horas de antelación, normalmente recuperas la sesión. El servidor confirma el saldo."
        }
        return "Estás dentro de las últimas 12 horas: la política provisional no devuelve la sesión. ¿Cancelar de todos modos?"
    }

    @ViewBuilder
    private func occurrenceCard(_ occurrence: BusinessOccurrence) -> some View {
        OGCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(occurrence.title)
                    .font(.headline)
                    .foregroundStyle(OG.label)
                Text(business.centerName(occurrence.orgId))
                    .foregroundStyle(OG.label2)
                    .font(.subheadline)
                if let room = business.roomName(for: occurrence), business.useRooms(for: occurrence.orgId) {
                    Label(room, systemImage: "door.left.hand.open")
                        .font(.subheadline)
                        .foregroundStyle(OG.label2)
                }
                if occurrence.kind == "open_access" {
                    Text("Acceso libre · aforo limitado")
                        .font(.footnote)
                        .foregroundStyle(OG.label2)
                } else if occurrence.prescription != nil || !(occurrence.trainingTitle ?? "").isEmpty {
                    Text("Hay entreno publicado")
                        .font(.footnote)
                        .foregroundStyle(OG.accent)
                }
                if let start = BusinessDataStore.date(occurrence.startsAt) {
                    Text(start.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                }
                if let booking = business.booking(for: occurrence.id) {
                    Label(
                        booking.status == "waitlist"
                            ? "Lista de espera · te avisamos si hay plaza"
                            : "Reservado · También en Inicio",
                        systemImage: booking.status == "waitlist" ? "clock.badge.checkmark" : "checkmark.circle.fill"
                    )
                    .foregroundStyle(OG.accent)
                    Button("Cancelar reserva", role: .destructive) {
                        bookingPendingCancellation = booking
                    }
                    .disabled(business.isSubmitting)
                    let hours = business.operationSettingsByOrg[occurrence.orgId]?.cancelCreditHours ?? 12
                    Text(booking.status == "waitlist"
                         ? "En espera no se descuenta crédito hasta confirmar plaza."
                         : "Cancelar con más de \(hours) h suele devolver el crédito; dentro de ese plazo, no.")
                        .font(.footnote)
                        .foregroundStyle(OG.label2)
                } else if let places = business.remainingPlaces(for: occurrence), places == 0 {
                    Label("Completo", systemImage: "xmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(OG.label2)
                    Text("Sin plazas. Puedes apuntarte a la lista de espera; te avisaremos si se libera una.")
                        .font(.footnote)
                        .foregroundStyle(OG.label2)
                    let wallets = business.availablePasses(for: occurrence)
                    if let pass = wallets.first {
                        Button("Entrar en lista de espera") {
                            Task { await business.book(occurrence, using: pass) }
                        }
                        .disabled(business.isSubmitting)
                        .foregroundStyle(OG.accent)
                    }
                } else if let places = business.remainingPlaces(for: occurrence) {
                    Text(occurrence.kind == "appointment"
                         ? "Horario disponible"
                         : "\(places) plaza\(places == 1 ? "" : "s") disponible\(places == 1 ? "" : "s")")
                        .font(.footnote)
                        .foregroundStyle(OG.label2)
                    let wallets = business.availablePasses(for: occurrence)
                    if wallets.isEmpty {
                        Text("Necesitas un bono vigente de este servicio para reservar.")
                            .font(.footnote)
                            .foregroundStyle(OG.label2)
                    } else {
                        ForEach(wallets) { pass in
                            Button {
                                Task { await business.book(occurrence, using: pass) }
                            } label: {
                                Label("Reservar · \(pass.remainingCredits) sesiones", systemImage: "checkmark.circle")
                                    .foregroundStyle(OG.accent)
                            }
                            .disabled(business.isSubmitting)
                        }
                    }
                } else {
                    Text("El aforo no está sincronizado. Actualiza Center antes de reservar.")
                        .font(.footnote)
                        .foregroundStyle(OG.label2)
                }
            }
        }
    }
}
