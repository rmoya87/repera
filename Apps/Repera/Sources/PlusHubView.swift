import ReperaDomain
import SwiftUI
import UIKit

/// Tab «+» entre Comenzar y Progreso: Clases del día | Centro (plan, contacto, historiales).
struct PlusHubView: View {
    @Environment(BusinessAuthStore.self) private var auth
    @Environment(BusinessDataStore.self) private var business
    /// Abre preview/Play de una prescripción de clase (mismo flujo que entreno programado).
    var onStartRoutine: (Routine) -> Void = { _ in }

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
    @State private var classCalendarScrollID: String?
    @ScaledMetric(relativeTo: .body) private var classCarouselHeight: CGFloat = 72
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
                    },
                    onStartRoutine: onStartRoutine
                )
            }
            .navigationDestination(for: PlusHubCenterListPage.self) { page in
                switch page {
                case .payments(let orgId):
                    CenterPaymentsListPage(orgId: orgId)
                case .classHistory(let orgId):
                    CenterClassHistoryListPage(orgId: orgId)
                }
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

        if let message = business.errorMessage {
            Text(message).foregroundStyle(OG.red).font(.footnote)
        }
        if dayClasses.isEmpty && !business.isLoading {
            OGCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Sin clases este día", systemImage: "calendar")
                        .font(.headline)
                    Text("Cuando tu gimnasio publique horarios, aparecerán aquí.")
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

    /// El mismo carrusel de días que Inicio: casillas cuadradas, mes visible,
    /// peek del día anterior y desplazamiento continuo sin botones de semana.
    private var dayStrip: some View {
        let cal = Calendar.current
        let days = (-367...367).compactMap {
            cal.date(byAdding: .day, value: $0, to: cal.startOfDay(for: Date()))
        }
        let availableClassDays = Set(business.occurrences.compactMap { occurrence -> String? in
            guard occurrence.kind == "class", occurrence.status == "active",
                  let start = BusinessDataStore.date(occurrence.startsAt) else { return nil }
            return BusinessDataStore.localDayKey(start)
        })
        let headerDate = classCalendarScrollID.flatMap(BusinessDataStore.parseDayKey) ?? selectedDay
        return VStack(alignment: .leading, spacing: 8) {
            Text(headerDate.formatted(Date.FormatStyle().month(.wide).year().locale(SpanishDate.appLocale)))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(OG.label2)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, OG.pad)

            GeometryReader { geo in
                let preferredSide = max(1, classCarouselHeight - 8)
                let visibleDays = geo.size.width >= 540
                    ? max(7, Int((geo.size.width + 4) / (preferredSide + 12)))
                    : 7
                let side = min(
                    preferredSide,
                    max(1, (geo.size.width - 4 * CGFloat(visibleDays - 1)) / CGFloat(visibleDays))
                )
                let spacing = geo.size.width >= 540 && visibleDays > 1
                    ? max(4, (geo.size.width - CGFloat(visibleDays) * side) / CGFloat(visibleDays - 1))
                    : CGFloat(4)
                let leadingPeek = side * 0.7

                ScrollView(.horizontal) {
                    LazyHStack(spacing: spacing) {
                        ForEach(days, id: \.self) { day in
                            let key = BusinessDataStore.localDayKey(day)
                            Button {
                                selectedDay = day
                            } label: {
                                classCalendarDay(
                                    day,
                                    side: side,
                                    hasClass: availableClassDays.contains(key)
                                )
                            }
                            .buttonStyle(.plain)
                            .id(key)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $classCalendarScrollID, anchor: .leading)
                .frame(width: geo.size.width + leadingPeek, alignment: .leading)
                .offset(x: -leadingPeek)
            }
            .frame(height: classCarouselHeight)
            .clipped()
            .ignoresSafeArea(edges: .horizontal)
        }
        .onAppear {
            if classCalendarScrollID == nil {
                classCalendarScrollID = BusinessDataStore.localDayKey(selectedDay)
            }
        }
    }

    private func classCalendarDay(_ day: Date, side: CGFloat, hasClass: Bool) -> some View {
        let cal = Calendar.current
        let selected = cal.isDate(day, inSameDayAs: selectedDay)
        let isToday = cal.isDateInToday(day)
        let labels = ["DO", "LU", "MA", "MI", "JU", "VI", "SA"]
        let dayName = labels[cal.component(.weekday, from: day) - 1]
        return VStack(spacing: 2) {
            Text(dayName)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(selected ? OG.onAccent : OG.label2)
            Text("\(cal.component(.day, from: day))")
                .font(.system(size: 17, weight: selected ? .semibold : .medium))
                .foregroundStyle(selected ? OG.onAccent : OG.label)
            if hasClass {
                Circle()
                    .fill(selected ? OG.onAccent : OG.accent)
                    .frame(width: 4, height: 4)
            } else {
                Color.clear.frame(width: 4, height: 4)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: side, height: side)
        .background(
            selected ? OG.accent : OG.surface,
            in: RoundedRectangle(cornerRadius: 11, style: .continuous)
        )
        .overlay {
            if !selected {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(
                        isToday ? OG.accent : OG.surface3.opacity(0.75),
                        lineWidth: isToday ? 1.5 : 0.7
                    )
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(day.formatted(date: .complete, time: .omitted))
        .accessibilityAddTraits(selected ? [.isSelected] : [])
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
        let aforo = Self.aforoLabel(capacity: occurrence.capacity, remaining: places)

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
                            if let aforo {
                                Label(aforo, systemImage: "person.3")
                                    .font(.caption.weight(.semibold))
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

                        if let opensAt {
                            Text("Inscripción desde \(opensAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(OG.label2)
                        }
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
        let email = center.publicEmail?.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = center.phone?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasEmail = !(email ?? "").isEmpty
        let hasPhone = !(phone ?? "").isEmpty
        return OGCard {
            HStack(alignment: .top, spacing: 14) {
                OrganizationAvatarView(center: center, size: 64)
                VStack(alignment: .leading, spacing: 8) {
                    Text(center.name)
                        .font(.title3.weight(.bold))
                    if let tagline = center.tagline, !tagline.isEmpty {
                        Text(tagline)
                            .font(.subheadline)
                            .foregroundStyle(OG.label2)
                    }
                    if hasEmail || hasPhone {
                        VStack(alignment: .leading, spacing: 8) {
                            if let email, hasEmail {
                                Button {
                                    openMailCompose(to: email)
                                } label: {
                                    Label(email, systemImage: "envelope.fill")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(OG.label)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Abre el correo para escribir a este centro")
                            }
                            if let phone, hasPhone {
                                Button {
                                    openPhoneDial(phone)
                                } label: {
                                    Label(phone, systemImage: "phone.fill")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(OG.label)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Llama a este número")
                            }
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func openMailCompose(to email: String) {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email
        guard let url = components.url else { return }
        UIApplication.shared.open(url)
    }

    private func openPhoneDial(_ phone: String) {
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        guard !digits.isEmpty else { return }
        var components = URLComponents()
        components.scheme = "tel"
        components.path = digits
        guard let url = components.url else { return }
        UIApplication.shared.open(url)
    }

    @ViewBuilder
    private func paymentsBlock(_ center: BusinessOrganization) -> some View {
        let all = business.paymentHistory(for: center.id)
        let payments = Array(all.prefix(3))
        OGCardSectionTitle(title: "Últimos pagos")
        OGCard {
            if payments.isEmpty {
                Text("Todavía no hay pagos registrados con este centro.")
                    .font(.subheadline)
                    .foregroundStyle(OG.label2)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(payments) { pass in
                        paymentRow(pass)
                        if pass.id != payments.last?.id {
                            Divider().opacity(0.35)
                        }
                    }
                    if all.count > 3 {
                        Button {
                            path.append(PlusHubCenterListPage.payments(center.id))
                        } label: {
                            Text("Ver más")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(OG.accent)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func classHistoryBlock(_ center: BusinessOrganization) -> some View {
        let all = business.pastBookings(for: center.id)
        let history = Array(all.prefix(3))
        let occById = Dictionary(uniqueKeysWithValues: business.occurrences.map { ($0.id, $0) })
        OGCardSectionTitle(title: "Historial de clases")
        OGCard {
            if history.isEmpty {
                Text("Aún no has asistido ni reservado clases con este centro.")
                    .font(.subheadline)
                    .foregroundStyle(OG.label2)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(history, id: \.id) { booking in
                        classHistoryRow(booking: booking, occurrence: occById[booking.occurrenceId])
                        if booking.id != history.last?.id {
                            Divider().opacity(0.35)
                        }
                    }
                    if all.count > 3 {
                        Button {
                            path.append(PlusHubCenterListPage.classHistory(center.id))
                        } label: {
                            Text("Ver más")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(OG.accent)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func paymentRow(_ pass: BusinessPass) -> some View {
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
    }

    private func classHistoryRow(booking: BusinessBooking, occurrence: BusinessOccurrence?) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(occurrence?.title ?? "Clase")
                    .font(.subheadline.weight(.semibold))
                if let raw = occurrence?.startsAt, let start = BusinessDataStore.date(raw) {
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

    /// Aforo siempre visible (también si ya estás apuntado): ocupadas/capacidad.
    static func aforoLabel(capacity: Int, remaining: Int?) -> String? {
        guard capacity > 0 else { return nil }
        if let remaining {
            let reserved = max(0, capacity - remaining)
            return "\(reserved)/\(capacity)"
        }
        return "\(capacity) plazas"
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

private enum PlusHubCenterListPage: Hashable {
    case payments(UUID)
    case classHistory(UUID)
}

private struct CenterPaymentsListPage: View {
    @Environment(BusinessDataStore.self) private var business
    let orgId: UUID

    private var payments: [BusinessPass] { business.paymentHistory(for: orgId) }
    private var title: String { business.centerName(orgId) }

    var body: some View {
        List {
            Section {
                if payments.isEmpty {
                    Text("Todavía no hay pagos registrados con este centro.")
                        .foregroundStyle(OG.label2)
                } else {
                    ForEach(payments) { pass in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(business.offerName(for: pass) ?? (pass.kind == "class" ? "Plan de clases" : "Plan de citas"))
                                .font(.headline)
                            HStack {
                                Text(PlusHubView.paymentLabel(pass))
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
                                    .foregroundStyle(OG.label3)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            } footer: {
                Text("Los cobros se confirman fuera de Repera; aquí solo ves el registro del centro.")
            }
        }
        .ogListChrome()
        .ogPinnedTransparentNav(title.isEmpty ? "Pagos" : "Pagos · \(title)")
    }
}

private struct CenterClassHistoryListPage: View {
    @Environment(BusinessDataStore.self) private var business
    let orgId: UUID

    private var rows: [(booking: BusinessBooking, occurrence: BusinessOccurrence?)] {
        let occById = Dictionary(uniqueKeysWithValues: business.occurrences.map { ($0.id, $0) })
        return business.pastBookings(for: orgId).map { ($0, occById[$0.occurrenceId]) }
    }

    var body: some View {
        List {
            Section {
                if rows.isEmpty {
                    Text("Aún no has asistido ni reservado clases con este centro.")
                        .foregroundStyle(OG.label2)
                } else {
                    ForEach(rows, id: \.booking.id) { row in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(row.occurrence?.title ?? "Clase")
                                .font(.headline)
                            if let raw = row.occurrence?.startsAt, let start = BusinessDataStore.date(raw) {
                                Text(start.formatted(date: .abbreviated, time: .shortened))
                                    .font(.subheadline)
                                    .foregroundStyle(OG.label2)
                            }
                            Text(PlusHubView.bookingStatusLabel(row.booking.status))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(OG.accent)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .ogListChrome()
        .ogPinnedTransparentNav("Historial de clases")
    }
}

struct ClassOccurrenceDetailPage: View {
    @Environment(BusinessDataStore.self) private var business
    @Environment(ReperaStore.self) private var store
    let occurrence: BusinessOccurrence
    var onRequestCancel: (BusinessBooking) -> Void
    /// Abre SessionPreview → Play (mismo flujo que un entreno programado).
    var onStartRoutine: (Routine) -> Void = { _ in }

    @State private var roster: BusinessClassRoster?
    @State private var loadingRoster = false
    @State private var startFailureMessage: String?
    @State private var openExerciseId: UUID?

    private var booking: BusinessBooking? { business.booking(for: occurrence.id) }
    private var places: Int? { business.remainingPlaces(for: occurrence) }
    private var color: Color { Color(plusHubHex: occurrence.color ?? "#22834d") ?? OG.accent }

    /// Prescripción publicada por el centro para esta clase (si existe).
    private var associatedSession: BusinessProfessionalTrainingSession? {
        if let booking {
            if let match = business.trainingSessions.first(where: {
                $0.sourceOccurrenceId == occurrence.id && $0.clientId == booking.clientId
            }) { return match }
        }
        return business.trainingSessions.first { $0.sourceOccurrenceId == occurrence.id }
    }

    /// Rutina ejecutable; nil si no hay bloques (entonces no se pinta la sección).
    private var planRoutine: Routine? {
        let minutes: Int? = {
            if let start = BusinessDataStore.date(occurrence.startsAt) {
                let cal = Calendar.current
                return cal.component(.hour, from: start) * 60 + cal.component(.minute, from: start)
            }
            return nil
        }()
        let day = BusinessDataStore.date(occurrence.startsAt)
        let built: Routine?
        if let session = associatedSession, let prescription = session.prescription {
            built = store.routineFromProfessionalPrescription(
                prescription,
                id: session.id,
                title: session.title.isEmpty ? occurrence.title : session.title,
                scheduledDate: day ?? Self.parseDayKey(session.scheduledDate),
                scheduledTimeMinutes: minutes ?? session.scheduledTimeMinutes
            )
        } else if let prescription = occurrence.prescription, prescription.isCanonicalV1 {
            let title = (occurrence.trainingTitle?.isEmpty == false)
                ? occurrence.trainingTitle!
                : occurrence.title
            built = store.routineFromProfessionalPrescription(
                prescription,
                id: occurrence.id,
                title: title,
                scheduledDate: day,
                scheduledTimeMinutes: minutes
            )
        } else {
            built = nil
        }
        guard let built, !built.blocks.isEmpty else { return nil }
        return built
    }

    private var daySubtitle: String {
        guard let start = BusinessDataStore.date(occurrence.startsAt) else { return "" }
        return SpanishDate.format(start, date: .abbreviated, time: .shortened)
    }

    var body: some View {
        List {
            // Clase: título + meta (como ficha de reserva).
            OGScrollablePageTitle(occurrence.title)
                .ogScrollingTitleListRow()
            if !daySubtitle.isEmpty {
                Text(daySubtitle)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(OG.label2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .ogSessionDateListRow()
            }

            Section {
                if let booking {
                    Text(booking.status == "waitlist" ? "Lista de espera" : "Apuntado")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(booking.status == "waitlist" ? OG.label2 : OG.accent)
                }

                if let start = BusinessDataStore.date(occurrence.startsAt),
                   let end = BusinessDataStore.date(occurrence.endsAt) {
                    detailRow(
                        icon: "calendar",
                        title: "Fecha",
                        value: SpanishDate.format(start, date: .abbreviated, time: .omitted)
                    )
                    detailRow(
                        icon: "clock",
                        title: "Hora",
                        value: "\(SpanishDate.time(start)) – \(SpanishDate.time(end))"
                    )
                    detailRow(
                        icon: "timer",
                        title: "Duración",
                        value: PlusHubView.durationLabel(start: start, end: end)
                    )
                }
                let reserved = roster?.reserved ?? places.map { occurrence.capacity - $0 }
                let capacity = roster?.capacity ?? occurrence.capacity
                if let reserved {
                    detailRow(icon: "person.3.fill", title: "Plazas", value: "\(reserved) / \(capacity)")
                }
                if let location = occurrence.location, !location.isEmpty {
                    detailRow(icon: "mappin.and.ellipse", title: "Sala", value: location)
                }
            }

            // Entreno programado: mismos bloques que SessionPreviewView (solo si hay ejercicios).
            if let plan = planRoutine {
                Section {
                    let instructions = associatedSession?.instructions
                        ?? occurrence.trainingInstructions
                    if let instructions, !instructions.isEmpty {
                        Text(instructions)
                            .font(.subheadline)
                            .foregroundStyle(OG.label2)
                    }
                    OGRoutineBlocksList(
                        blocks: plan.blocks,
                        opensExerciseDetail: true,
                        onOpenExercise: { openExerciseId = $0 }
                    )
                }
            }

            if shouldShowCoach, let coach = roster?.coach {
                Section("Entrenador") {
                    personRow(name: coach.displayName, avatar: coach.avatarUrl, subtitle: "Impartirá la clase", large: true)
                }
            }

            Section(roster.map { "Apuntados (\($0.attendees.count))" } ?? "Apuntados") {
                if loadingRoster {
                    ProgressView().tint(OG.accent)
                } else if let people = roster?.attendees, !people.isEmpty {
                    ForEach(people) { person in
                        personRow(
                            name: person.displayName,
                            avatar: person.avatarUrl,
                            subtitle: person.status == "waitlist" ? "Lista de espera" : nil,
                            large: false
                        )
                    }
                } else {
                    Text("Todavía no hay nadie apuntado. Sé el primero.")
                        .font(.subheadline)
                        .foregroundStyle(OG.label2)
                }
            }
        }
        .ogListChrome()
        .ogScrollingTitleNav()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bookingBottomAction
        }
        .navigationDestination(item: $openExerciseId) { exerciseId in
            ExerciseDetailView(exerciseId: exerciseId)
        }
        .toolbar {
            if planRoutine != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        beginClassPlan()
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(OG.accent)
                    .accessibilityLabel("Comenzar entreno")
                }
            }
        }
        .alert("No se ha podido iniciar el entreno", isPresented: Binding(
            get: { startFailureMessage != nil },
            set: { if !$0 { startFailureMessage = nil } }
        )) {
            Button("Aceptar", role: .cancel) { startFailureMessage = nil }
        } message: {
            Text(startFailureMessage ?? "")
        }
        .task {
            loadingRoster = true
            roster = await business.loadClassRoster(for: occurrence.id)
            loadingRoster = false
        }
    }

    private func beginClassPlan() {
        guard let plan = planRoutine else { return }
        let saved = store.ensureProfessionalRoutineInLibrary(plan)
        onStartRoutine(saved)
    }

    private static func parseDayKey(_ key: String) -> Date? {
        let fmt = DateFormatter()
        fmt.calendar = Calendar(identifier: .gregorian)
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = .current
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.date(from: key)
    }

    private var shouldShowCoach: Bool {
        if loadingRoster { return false }
        return roster?.coach != nil
    }

    /// Una única acción persistente, con el mismo resultado que el acceso
    /// anterior de la barra. Cancelar sigue mostrando la confirmación nativa.
    private var bookingBottomAction: some View {
        let canBook = business.canBookNow(occurrence)
            && (places ?? 1) > 0
            && business.availablePasses(for: occurrence).first != nil
        return Button {
            if let booking {
                onRequestCancel(booking)
            } else {
                guard let pass = business.availablePasses(for: occurrence).first else { return }
                Task { await business.book(occurrence, using: pass) }
            }
        } label: {
            Text(booking == nil ? "Apuntarme" : "Cancelar clase")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(booking == nil ? Color.black : Color.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(
                    booking == nil ? OG.accent : OG.red,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .disabled(business.isSubmitting || (booking == nil && !canBook))
        .opacity(business.isSubmitting || (booking == nil && !canBook) ? 0.55 : 1)
        .padding(.horizontal, OG.pad)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(OG.accent)
                .frame(width: 18)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(OG.label2)
            Spacer(minLength: 10)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(OG.label)
                .multilineTextAlignment(.trailing)
                .lineLimit(title == "Fecha" ? 1 : nil)
                .minimumScaleFactor(title == "Fecha" ? 0.75 : 1)
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
