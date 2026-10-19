import SwiftUI

/// Center: real class and personal appointment availability from Supabase.
/// Never invents slots or counts. All booking/credit mutations are server-side RPCs.
struct CenterView: View {
    @Environment(BusinessAuthStore.self) private var auth
    @Environment(BusinessDataStore.self) private var business

    private enum CenterSection: String, CaseIterable, Identifiable {
        case classes, appointments
        var id: Self { self }
        var title: String { self == .classes ? "Clases" : "Citas" }
        var serviceKind: String { self == .classes ? "class" : "appointment" }
    }
    @State private var selectedSection: CenterSection = .classes
    @State private var bookingPendingCancellation: BusinessBooking?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    OGCardSectionTitle(title: "Mis centros y entrenadores")

                    if !auth.isConnected {
                        OGCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Conecta tu cuenta para consultar tus centros", systemImage: "person.crop.circle.badge.questionmark")
                                    .font(.headline)
                                Text("En Ajustes puedes autorizar tu identidad Apple en Repera Business. Tus entrenamientos personales no se comparten.")
                                    .font(.subheadline)
                                    .foregroundStyle(OG.label2)
                                NavigationLink("Abrir Ajustes") { SettingsView() }
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
                        if business.centers.isEmpty && business.invitations.isEmpty {
                            OGCard {
                                Text("Todavía no perteneces a ningún centro. Tu entrenador o gimnasio puede invitarte al correo de tu cuenta.")
                                    .foregroundStyle(OG.label2)
                            }
                        }
                        ForEach(business.invitations) { invitation in
                            OGCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    Label("Invitación a un centro", systemImage: "envelope.badge")
                                        .font(.headline)
                                    Text("Perfil: \(invitation.invitedRole). Aceptar la invitación vinculará tu cuenta, pero no compartirá tu historial deportivo personal.")
                                        .font(.footnote)
                                        .foregroundStyle(OG.label2)
                                    Button("Aceptar invitación") {
                                        Task { await business.accept(invitation) }
                                    }
                                    .disabled(business.isSubmitting)
                                    .foregroundStyle(OG.accent)
                                }
                            }
                        }
                        ForEach(business.centers) { center in
                            OGCard {
                                Label(center.name, systemImage: center.kind == "personal_trainer" ? "person.fill" : "building.2")
                                    .font(.headline)
                            }
                        }
                    }

                    OGCardSectionTitle(title: "Reservas")
                    Picker("Tipo de reserva", selection: $selectedSection) {
                        ForEach(CenterSection.allCases) { section in
                            Text(section.title).tag(section)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Clases o citas personales")

                    let available = business.occurrences.filter {
                        $0.kind == selectedSection.serviceKind
                            && (BusinessDataStore.date($0.startsAt) ?? .distantPast) > Date()
                    }

                    if available.isEmpty {
                        OGCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Label(selectedSection == .classes ? "Sin clases disponibles" : "Sin citas disponibles",
                                      systemImage: "calendar.badge.clock")
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

                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Ver centros, entrenadores y bonos", systemImage: "person.crop.circle")
                            .foregroundStyle(OG.accent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10)
                    }
                }
                .padding(.horizontal, OG.pad)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .background(OG.bg)
            .ogFixedTopBar("Center") {
                OGToolbarGlassButton(systemName: "arrow.clockwise", accessibilityLabel: "Actualizar Center") {
                    Task { await business.refresh() }
                }
            }
            .task { await business.refresh() }
            .confirmationDialog(
                "¿Cancelar la reserva?",
                isPresented: Binding(
                    get: { bookingPendingCancellation != nil },
                    set: { if !$0 { bookingPendingCancellation = nil } }
                ),
                titleVisibility: .visible
            ) {
                if let booking = bookingPendingCancellation {
                    Button("Confirmar cancelación", role: .destructive) {
                        bookingPendingCancellation = nil
                        Task { await business.cancel(booking) }
                    }
                }
            } message: {
                Text(cancellationNotice)
            }
        }
    }

    private var cancellationNotice: String {
        guard let booking = bookingPendingCancellation,
              let occurrence = business.occurrences.first(where: { $0.id == booking.occurrenceId }),
              let startsAt = BusinessDataStore.date(occurrence.startsAt) else {
            return "El centro aplicará su política de cancelación. Se comprobará el saldo real tras confirmar."
        }
        if startsAt > Date().addingTimeInterval(12 * 3600) {
            return "Según la política provisional, recuperarás una sesión si cancelas con más de 12 horas de antelación. El servidor confirma el saldo."
        }
        return "Estás dentro de las últimas 12 horas: la política provisional NO devuelve la sesión utilizada. ¿Deseas cancelar de todos modos?"
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
                if let start = BusinessDataStore.date(occurrence.startsAt) {
                    Text(start.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                }
                if let booking = business.booking(for: occurrence.id) {
                    Label("Reservado · Aparece también en Inicio", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(OG.accent)
                    Button("Cancelar reserva", role: .destructive) {
                        bookingPendingCancellation = booking
                    }
                    .disabled(business.isSubmitting)
                    Text("Política provisional: cancelaciones con más de 12 horas de antelación recuperan el crédito.")
                        .font(.footnote)
                        .foregroundStyle(OG.label2)
                } else if let places = business.remainingPlaces(for: occurrence), places == 0 {
                    Label("Completo", systemImage: "xmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(OG.label2)
                    Text("No quedan plazas. La lista de espera aún no está habilitada.")
                        .font(.footnote)
                        .foregroundStyle(OG.label2)
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
                                Label("Reservar · \(pass.remainingCredits) sesiones disponibles", systemImage: "checkmark.circle")
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
