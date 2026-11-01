import SwiftUI

/// Tab «+» entre Comenzar y Progreso: Clases del día | Centro (plan, contacto, historiales).
struct PlusHubView: View {
    @Environment(BusinessAuthStore.self) private var auth
    @Environment(BusinessDataStore.self) private var business

    private enum HubTab: String, CaseIterable, Identifiable {
        case classes, center
        var id: Self { self }
        var title: String {
            switch self {
            case .classes: "Clases"
            case .center: "Centro"
            }
        }
    }

    @State private var hubTab: HubTab = .classes
    @State private var selectedDay = Calendar.current.startOfDay(for: Date())
    @State private var bookingPendingCancellation: BusinessBooking?
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Picker("Sección", selection: $hubTab) {
                        ForEach(HubTab.allCases) { tab in
                            Text(tab.title).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Clases o Centro")

                    if !auth.isConnected {
                        OGCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Conecta tu cuenta", systemImage: "wifi.exclamationmark")
                                    .font(.headline)
                                Text("Inicia sesión para ver clases del gimnasio y tu centro.")
                                    .font(.subheadline)
                                    .foregroundStyle(OG.label2)
                                Button("Reintentar") {
                                    Task { await refresh() }
                                }
                                .fontWeight(.semibold)
                                .foregroundStyle(OG.accent)
                            }
                        }
                    } else if hubTab == .classes {
                        classesPane
                    } else {
                        centerPane
                    }
                }
                .padding(.horizontal, OG.pad)
                .padding(.top, 12)
                .padding(.bottom, 40)
                .ogReadableColumn()
            }
            .background(OG.bg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: BusinessOccurrence.self) { occurrence in
                ClassOccurrenceDetailPage(
                    occurrence: occurrence,
                    onRequestCancel: { booking in
                        bookingPendingCancellation = booking
                    }
                )
            }
        }
        .task { await refresh() }
        .sheet(item: $bookingPendingCancellation) { booking in
            OGConfirmSheet(
                systemImage: "calendar.badge.minus",
                title: "¿Cancelar la reserva?",
                message: "Se te desapunta y, si tenías plaza confirmada, se te devuelve la sesión al plan.",
                confirmTitle: "Confirmar cancelación",
                onConfirm: {
                    bookingPendingCancellation = nil
                    Task { await business.cancel(booking) }
                },
                onCancel: { bookingPendingCancellation = nil }
            )
        }
    }

    // MARK: - Clases

    @ViewBuilder
    private var classesPane: some View {
        dayStrip
        let dayKey = BusinessDataStore.localDayKey(selectedDay)
        let dayClasses = business.occurrences.filter { occ in
            occ.kind == "class"
                && occ.status == "active"
                && BusinessDataStore.localDayKey(BusinessDataStore.date(occ.startsAt) ?? .distantPast) == dayKey
        }
        .sorted { $0.startsAt < $1.startsAt }

        if business.isLoading {
            ProgressView("Cargando clases…").tint(OG.accent)
        }
        if let message = business.errorMessage {
            Text(message).foregroundStyle(OG.red).font(.footnote)
        }
        if dayClasses.isEmpty {
            OGCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Sin clases este día", systemImage: "calendar")
                        .font(.headline)
                    Text("Cuando tu gimnasio publique horarios, aparecerán aquí con su color.")
                        .font(.subheadline)
                        .foregroundStyle(OG.label2)
                }
            }
        } else {
            ForEach(dayClasses) { occurrence in
                classDayCard(occurrence)
            }
        }
    }

    private var dayStrip: some View {
        let cal = Calendar.current
        let days = (-3...10).compactMap { cal.date(byAdding: .day, value: $0, to: cal.startOfDay(for: Date())) }
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(days, id: \.self) { day in
                    let selected = cal.isDate(day, inSameDayAs: selectedDay)
                    Button {
                        selectedDay = day
                    } label: {
                        VStack(spacing: 4) {
                            Text(day.formatted(.dateTime.weekday(.narrow)))
                                .font(.caption2.weight(.semibold))
                            Text(day.formatted(.dateTime.day()))
                                .font(.title3.weight(.bold))
                        }
                        .foregroundStyle(selected ? Color.white : OG.label)
                        .frame(width: 48, height: 56)
                        .background(selected ? OG.accent : OG.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(day.formatted(date: .complete, time: .omitted))
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func classDayCard(_ occurrence: BusinessOccurrence) -> some View {
        let color = Color(plusHubHex: occurrence.color ?? "#22834d") ?? OG.accent
        let booking = business.booking(for: occurrence.id)
        let places = business.remainingPlaces(for: occurrence)
        let open = business.canBookNow(occurrence)
        let opensAt = business.bookingOpensAt(for: occurrence)
        let full = (places ?? 1) == 0
        let wallets = business.availablePasses(for: occurrence)
        let canTap = open && !full && wallets.first != nil
        let start = BusinessDataStore.date(occurrence.startsAt)
        let end = BusinessDataStore.date(occurrence.endsAt)

        OGCard(padding: 0) {
            HStack(alignment: .top, spacing: 0) {
                RoundedRectangle(cornerRadius: 0)
                    .fill(color)
                    .frame(width: 5)
                    .frame(maxHeight: .infinity)

                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        path.append(occurrence)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(occurrence.title)
                                .font(.headline)
                                .foregroundStyle(OG.label)
                                .multilineTextAlignment(.leading)
                            Text(business.centerName(occurrence.orgId))
                                .font(.subheadline)
                                .foregroundStyle(OG.label2)
                            if let start, let end {
                                Label {
                                    Text("\(start.formatted(date: .omitted, time: .shortened)) – \(end.formatted(date: .omitted, time: .shortened)) · \(Self.durationLabel(start: start, end: end))")
                                } icon: {
                                    Image(systemName: "clock")
                                }
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(OG.label)
                            }
                            if let location = occurrence.location, !location.isEmpty {
                                Label(location, systemImage: "mappin.and.ellipse")
                                    .font(.caption)
                                    .foregroundStyle(OG.label2)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Abre el detalle de la clase")

                    if let booking {
                        HStack(spacing: 10) {
                            Label(
                                booking.status == "waitlist" ? "Lista de espera" : "Apuntado",
                                systemImage: booking.status == "waitlist" ? "clock.badge.checkmark" : "checkmark.circle.fill"
                            )
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(OG.accent)
                            Spacer(minLength: 0)
                            Button("Cancelar") {
                                bookingPendingCancellation = booking
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(OG.red)
                            .disabled(business.isSubmitting)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        // Horario arriba · Apuntarme · plazas debajo (entre horario y plazas).
                        Button {
                            guard let pass = wallets.first else { return }
                            Task { await business.book(occurrence, using: pass) }
                        } label: {
                            Text(full ? "Completa" : "Apuntarme")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(canTap ? Color.black : OG.label2.opacity(0.55))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(
                                    canTap ? OG.accent : OG.surface2,
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(!canTap || business.isSubmitting)

                        Group {
                            if let opensAt {
                                Text("Inscripción desde \(opensAt.formatted(date: .abbreviated, time: .shortened))")
                            } else if full {
                                Text("Sin plazas libres")
                            } else if let places {
                                Text("\(places) plaza\(places == 1 ? "" : "s") libre\(places == 1 ? "" : "s")")
                            }
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(OG.label2)
                    }
                }
                .padding(14)
            }
        }
    }

    // MARK: - Centro

    @ViewBuilder
    private var centerPane: some View {
        let centers = business.linkedCenters()
        if centers.isEmpty {
            OGCard {
                Text("Todavía no perteneces a ningún centro. Cuando te inviten, verás aquí su ficha y tu plan.")
                    .foregroundStyle(OG.label2)
            }
        }
        ForEach(centers) { center in
            centerHeroCard(center)

            let passes = business.activePasses(for: center.id)
            OGCardSectionTitle(title: "Plan")
            if passes.isEmpty {
                OGCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sin plan activo")
                            .font(.headline)
                        Text("Pide a tu centro que te asigne un bono o acceso.")
                            .font(.subheadline)
                            .foregroundStyle(OG.label2)
                    }
                }
            } else {
                ForEach(passes) { pass in
                    planCard(center: center, pass: pass)
                }
            }

            let upcoming = upcomingBookings(for: center.id)
            if !upcoming.isEmpty {
                OGCardSectionTitle(title: "Próximas reservas")
                OGCard {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(upcoming.prefix(3), id: \.booking.id) { row in
                            Button {
                                path.append(row.occurrence)
                            } label: {
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .fill(Color(plusHubHex: row.occurrence.color ?? "#22834d") ?? OG.accent)
                                        .frame(width: 4, height: 36)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(row.occurrence.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(OG.label)
                                        if let start = BusinessDataStore.date(row.occurrence.startsAt) {
                                            Text(start.formatted(date: .abbreviated, time: .shortened))
                                                .font(.caption)
                                                .foregroundStyle(OG.label2)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(OG.label3)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            paymentsBlock(center)
            classHistoryBlock(center)
        }
    }

    private func centerHeroCard(_ center: BusinessOrganization) -> some View {
        let next = upcomingBookings(for: center.id).first
        let email = center.publicEmail?.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = center.phone?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasEmail = !(email ?? "").isEmpty
        let hasPhone = !(phone ?? "").isEmpty
        return OGCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    OrganizationAvatarView(center: center, size: 64)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(center.name)
                            .font(.title3.weight(.bold))
                        if let tagline = center.tagline, !tagline.isEmpty {
                            Text(tagline)
                                .font(.subheadline)
                                .foregroundStyle(OG.label2)
                        }
                        if let next, let start = BusinessDataStore.date(next.occurrence.startsAt) {
                            Label(
                                "Próxima: \(next.occurrence.title) · \(start.formatted(date: .abbreviated, time: .shortened))",
                                systemImage: "calendar"
                            )
                            .font(.caption.weight(.medium))
                            .foregroundStyle(OG.label2)
                        }
                    }
                    Spacer(minLength: 0)
                }
                if hasEmail || hasPhone {
                    VStack(alignment: .leading, spacing: 10) {
                        if let email, hasEmail {
                            if let url = URL(string: "mailto:\(email)") {
                                Link(destination: url) {
                                    Label(email, systemImage: "envelope.fill")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(OG.label)
                                }
                            } else {
                                Label(email, systemImage: "envelope.fill")
                                    .font(.subheadline.weight(.medium))
                            }
                        }
                        if let phone, hasPhone {
                            let digits = phone.filter { $0.isNumber || $0 == "+" }
                            if let url = URL(string: "tel:\(digits)"), !digits.isEmpty {
                                Link(destination: url) {
                                    Label(phone, systemImage: "phone.fill")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(OG.label)
                                }
                            } else {
                                Label(phone, systemImage: "phone.fill")
                                    .font(.subheadline.weight(.medium))
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func paymentsBlock(_ center: BusinessOrganization) -> some View {
        let payments = business.paymentHistory(for: center.id).prefix(5)
        OGCardSectionTitle(title: "Últimos pagos")
        OGCard {
            if payments.isEmpty {
                Text("Todavía no hay pagos registrados con este centro.")
                    .font(.subheadline)
                    .foregroundStyle(OG.label2)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(payments)) { pass in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(business.offerName(for: pass) ?? (pass.kind == "class" ? "Plan de clases" : "Plan de citas"))
                                    .font(.subheadline.weight(.semibold))
                                Text(Self.paymentLabel(pass))
                                    .font(.caption)
                                    .foregroundStyle(OG.label2)
                                if let when = BusinessDataStore.date(pass.paidAt ?? pass.validFrom) {
                                    Text(when.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption2)
                                        .foregroundStyle(OG.label3)
                                }
                            }
                            Spacer()
                            if let cents = pass.paidAmountCents {
                                Text((Double(cents) / 100).formatted(.currency(code: "EUR")))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(OG.label)
                            }
                        }
                        if pass.id != payments.last?.id {
                            Divider().opacity(0.35)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func classHistoryBlock(_ center: BusinessOrganization) -> some View {
        let history = business.pastBookings(for: center.id).prefix(8)
        let occById = Dictionary(uniqueKeysWithValues: business.occurrences.map { ($0.id, $0) })
        OGCardSectionTitle(title: "Historial de clases")
        OGCard {
            if history.isEmpty {
                Text("Aún no has asistido ni reservado clases con este centro.")
                    .font(.subheadline)
                    .foregroundStyle(OG.label2)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(history), id: \.id) { booking in
                        let occ = occById[booking.occurrenceId]
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(occ?.title ?? "Clase")
                                    .font(.subheadline.weight(.semibold))
                                if let raw = occ?.startsAt, let start = BusinessDataStore.date(raw) {
                                    Text(start.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(OG.label2)
                                }
                            }
                            Spacer()
                            Text(Self.bookingStatusLabel(booking.status))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(OG.accent)
                        }
                        if booking.id != history.last?.id {
                            Divider().opacity(0.35)
                        }
                    }
                }
            }
        }
    }

    private func planCard(center: BusinessOrganization, pass: BusinessPass) -> some View {
        let unlimited = pass.remainingCredits >= 9000 || pass.totalCredits >= 9000
        let offerName = business.offerName(for: pass)
        let kindLabel = pass.kind == "class" ? "Clases / acceso" : "Citas 1:1"
        let remainingRatio = unlimited ? 1.0 : Double(pass.remainingCredits) / Double(max(1, pass.totalCredits))
        return OGCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(offerName ?? kindLabel)
                            .font(.title3.weight(.bold))
                        Text(center.name)
                            .font(.subheadline)
                            .foregroundStyle(OG.label2)
                    }
                    Spacer()
                    Text(kindLabel)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(OG.accent.opacity(0.12), in: Capsule())
                        .foregroundStyle(OG.accent)
                }

                if unlimited {
                    Text("Acceso ilimitado")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(OG.accent)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(pass.remainingCredits)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(OG.accent)
                        Text("de \(pass.totalCredits) sesiones")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(OG.label2)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(OG.surface2)
                            Capsule()
                                .fill(OG.accent)
                                .frame(width: max(8, geo.size.width * remainingRatio))
                        }
                    }
                    .frame(height: 8)
                }

                if let end = BusinessDataStore.date(pass.validUntil) {
                    let days = Calendar.current.dateComponents([.day], from: Date(), to: end).day ?? 0
                    HStack {
                        Label(
                            days >= 0 ? "Quedan \(days) día\(days == 1 ? "" : "s")" : "Caducado",
                            systemImage: "calendar"
                        )
                        .font(.subheadline.weight(.medium))
                        Spacer()
                        Text("Hasta \(end.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(OG.label2)
                    }
                }

                Text("Para renovar, habla con tu centro; te asignarán el siguiente plan cuando cobren fuera de Repera.")
                    .font(.footnote)
                    .foregroundStyle(OG.label2)
            }
        }
    }

    private func upcomingBookings(for orgId: UUID) -> [(booking: BusinessBooking, occurrence: BusinessOccurrence)] {
        let now = Date()
        return business.bookings.compactMap { booking -> (BusinessBooking, BusinessOccurrence)? in
            guard booking.orgId == orgId,
                  ["booked", "waitlist"].contains(booking.status),
                  let occ = business.occurrences.first(where: { $0.id == booking.occurrenceId }),
                  let start = BusinessDataStore.date(occ.startsAt),
                  start >= now else { return nil }
            return (booking, occ)
        }
        .sorted { a, b in
            (BusinessDataStore.date(a.1.startsAt) ?? .distantFuture) < (BusinessDataStore.date(b.1.startsAt) ?? .distantFuture)
        }
        .map { (booking: $0.0, occurrence: $0.1) }
    }

    static func durationLabel(start: Date, end: Date) -> String {
        let mins = Int(end.timeIntervalSince(start) / 60)
        if mins >= 60 {
            let h = mins / 60
            let m = mins % 60
            return m == 0 ? "\(h) h" : "\(h) h \(m) min"
        }
        return "\(max(1, mins)) min"
    }

    static func paymentLabel(_ pass: BusinessPass) -> String {
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

    static func bookingStatusLabel(_ status: String) -> String {
        switch status {
        case "attended": return "Asististe"
        case "booked": return "Reservada"
        case "waitlist": return "Lista de espera"
        case "cancelled": return "Cancelada"
        case "no_show": return "No presentado"
        default: return status
        }
    }

    private func refresh() async {
        if !auth.isConnected {
            await auth.restoreSession()
            if !auth.isConnected {
                _ = auth.connectFromCachedSessionIfPossible()
            }
        }
        guard auth.isConnected else { return }
        await business.refresh()
    }
}

// MARK: - Detalle de clase (página)

struct ClassOccurrenceDetailPage: View {
    @Environment(BusinessDataStore.self) private var business
    let occurrence: BusinessOccurrence
    var onRequestCancel: (BusinessBooking) -> Void

    @State private var roster: BusinessClassRoster?
    @State private var loadingRoster = false

    private var booking: BusinessBooking? { business.booking(for: occurrence.id) }
    private var places: Int? { business.remainingPlaces(for: occurrence) }
    private var color: Color { Color(plusHubHex: occurrence.color ?? "#22834d") ?? OG.accent }
    private var center: BusinessOrganization? { business.center(for: occurrence.orgId) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                summaryCard
                if shouldShowCoach {
                    coachBlock
                }
                attendeesBlock
            }
            .padding(.horizontal, OG.pad)
            .padding(.top, 12)
            .padding(.bottom, 40)
            .ogReadableColumn()
        }
        .background(OG.bg)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .ogTransparentNav()
        .task {
            loadingRoster = true
            roster = await business.loadClassRoster(for: occurrence.id)
            loadingRoster = false
        }
    }

    private var shouldShowCoach: Bool {
        if loadingRoster { return false }
        return roster?.coach != nil
    }

    private var summaryCard: some View {
        OGCard {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top, spacing: 14) {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(color)
                        .frame(width: 5)
                        .frame(minHeight: 56)
                    VStack(alignment: .leading, spacing: 10) {
                        Text(occurrence.title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(color)
                            .fixedSize(horizontal: false, vertical: true)
                        if let center {
                            HStack(spacing: 10) {
                                OrganizationAvatarView(center: center, size: 30)
                                Text(center.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(OG.label)
                            }
                        } else {
                            Text(business.centerName(occurrence.orgId))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(OG.label2)
                        }
                    }
                    Spacer(minLength: 10)
                    bookingGlassButton
                }

                if let booking {
                    Text(booking.status == "waitlist" ? "Lista de espera" : "Apuntado")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(booking.status == "waitlist" ? OG.label2 : color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            (booking.status == "waitlist" ? OG.surface2 : color.opacity(0.14)),
                            in: Capsule()
                        )
                }

                if let start = BusinessDataStore.date(occurrence.startsAt),
                   let end = BusinessDataStore.date(occurrence.endsAt) {
                    detailRow(icon: "calendar", title: "Fecha", value: start.formatted(date: .complete, time: .omitted))
                    HStack(alignment: .top, spacing: 12) {
                        metricTile(
                            icon: "clock",
                            title: "Hora",
                            value: "\(start.formatted(date: .omitted, time: .shortened)) – \(end.formatted(date: .omitted, time: .shortened))"
                        )
                        metricTile(
                            icon: "hourglass",
                            title: "Duración",
                            value: PlusHubView.durationLabel(start: start, end: end)
                        )
                    }
                }

                let reserved = roster?.reserved ?? places.map { occurrence.capacity - $0 }
                let capacity = roster?.capacity ?? occurrence.capacity
                VStack(alignment: .leading, spacing: 14) {
                    if let reserved {
                        detailRow(icon: "person.3.fill", title: "Plazas", value: "\(reserved) / \(capacity)")
                    }
                    if let location = occurrence.location, !location.isEmpty {
                        detailRow(icon: "mappin.and.ellipse", title: "Sala", value: location)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var bookingGlassButton: some View {
        if let booking {
            OGToolbarGlassButton(
                systemName: "xmark",
                accessibilityLabel: "Desapuntarse",
                tint: OG.red,
                appliesGlass: true,
                glassTint: OG.red.opacity(0.22)
            ) {
                onRequestCancel(booking)
            }
            .disabled(business.isSubmitting)
            .opacity(business.isSubmitting ? 0.45 : 1)
        } else {
            let open = business.canBookNow(occurrence)
            let full = (places ?? 1) == 0
            let canTap = open && !full && business.availablePasses(for: occurrence).first != nil
            OGToolbarGlassButton(
                systemName: "checkmark",
                accessibilityLabel: full ? "Clase completa" : (open ? "Apuntarme" : "Aún no se puede apuntar"),
                tint: canTap ? Color.white : OG.label3,
                appliesGlass: true,
                glassTint: canTap ? OG.accent : OG.surface2
            ) {
                guard let pass = business.availablePasses(for: occurrence).first else { return }
                Task { await business.book(occurrence, using: pass) }
            }
            .disabled(!canTap || business.isSubmitting)
            .opacity((!canTap || business.isSubmitting) ? 0.55 : 1)
        }
    }

    private func metricTile(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(OG.label2)
                .labelStyle(.titleAndIcon)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(OG.label)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 18)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(OG.label2)
            Spacer(minLength: 10)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(OG.label)
                .multilineTextAlignment(.trailing)
        }
    }

    @ViewBuilder
    private var coachBlock: some View {
        if let coach = roster?.coach {
            VStack(alignment: .leading, spacing: 12) {
                OGCardSectionTitle(title: "Entrenador")
                OGCard {
                    personRow(name: coach.displayName, avatar: coach.avatarUrl, subtitle: "Impartirá la clase", large: true)
                }
            }
        }
    }

    private var attendeesBlock: some View {
        let count = roster?.attendees.count ?? 0
        return VStack(alignment: .leading, spacing: 12) {
            OGCardSectionTitle(title: count > 0 ? "Apuntados (\(count))" : "Apuntados")
            OGCard {
                if loadingRoster {
                    ProgressView().tint(OG.accent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } else if let people = roster?.attendees, !people.isEmpty {
                    VStack(spacing: 16) {
                        ForEach(people) { person in
                            personRow(
                                name: person.displayName,
                                avatar: person.avatarUrl,
                                subtitle: person.status == "waitlist" ? "Lista de espera" : nil,
                                large: false
                            )
                        }
                    }
                } else {
                    Text("Todavía no hay nadie apuntado. Sé el primero.")
                        .font(.subheadline)
                        .foregroundStyle(OG.label2)
                        .padding(.vertical, 4)
                }
            }
        }
    }

    private func personRow(name: String, avatar: String?, subtitle: String?, large: Bool) -> some View {
        HStack(spacing: 12) {
            avatarView(url: avatar, name: name, size: large ? 48 : 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(large ? .body.weight(.semibold) : .subheadline.weight(.semibold))
                if let subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(OG.label2)
                }
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func avatarView(url: String?, name: String, size: CGFloat) -> some View {
        let initials = name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined()
        Group {
            if let url, let remote = URL(string: url) {
                AsyncImage(url: remote) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Text(initials.isEmpty ? "?" : initials)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(color)
                    }
                }
            } else {
                Text(initials.isEmpty ? "?" : initials)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(color)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

private extension Color {
    init?(plusHubHex: String) {
        var s = plusHubHex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let value = UInt64(s, radix: 16) else { return nil }
        let r = Double((value >> 16) & 0xff) / 255
        let g = Double((value >> 8) & 0xff) / 255
        let b = Double(value & 0xff) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
