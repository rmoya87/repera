import SwiftUI

/// Entry point for the athlete's center and personal-training services.
/// Availability, bookings and entitlements must come from authenticated Supabase data.
/// Until that integration exists, do not show fictional slots or allow fake bookings.
struct CenterView: View {
    private enum CenterSection: String, CaseIterable, Identifiable {
        case classes
        case appointments

        var id: Self { self }

        var title: String {
            switch self {
            case .classes: "Clases"
            case .appointments: "Citas"
            }
        }
    }

    @State private var selectedSection: CenterSection = .classes

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    OGCardSectionTitle(title: "Mis centros y entrenadores")

                    OGCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Image(systemName: "building.2")
                                .font(.system(size: 34, weight: .medium))
                                .foregroundStyle(OG.accent)

                            Text("Tu espacio de entrenamiento")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(OG.label)

                            Text("Aquí aparecerán tus centros y entrenadores personales cuando aceptes su invitación.")
                                .font(.subheadline)
                                .foregroundStyle(OG.label2)
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

                    switch selectedSection {
                    case .classes:
                        classesEmptyState
                    case .appointments:
                        appointmentsEmptyState
                    }

                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Ver mis centros, entrenadores y bonos", systemImage: "person.crop.circle")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(OG.accent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, OG.pad)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .background(OG.bg)
            .ogFixedTopBar("Center") { EmptyView() }
        }
    }

    private var classesEmptyState: some View {
        OGCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Clases del gimnasio", systemImage: "calendar")
                    .font(.headline)
                    .foregroundStyle(OG.label)

                Text("Consulta el calendario, las plazas disponibles y la lista de espera de tus centros cuando estén sincronizados.")
                    .font(.subheadline)
                    .foregroundStyle(OG.label2)

                Label("Las clases reservadas aparecerán en Inicio.", systemImage: "house")
                    .font(.footnote)
                    .foregroundStyle(OG.label2)

                Text("Sin clases sincronizadas")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(OG.label2)
            }
        }
    }

    private var appointmentsEmptyState: some View {
        OGCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Sesiones con tu entrenador", systemImage: "calendar.badge.clock")
                    .font(.headline)
                    .foregroundStyle(OG.label)

                Text("Cuando tu entrenador habilite su agenda, podrás elegir un horario libre para una sesión individual y consultar tus citas.")
                    .font(.subheadline)
                    .foregroundStyle(OG.label2)

                Label("Los bonos personales y las condiciones de cancelación se gestionan por separado de las clases del gimnasio.", systemImage: "ticket")
                    .font(.footnote)
                    .foregroundStyle(OG.label2)

                Label("Las citas confirmadas aparecerán en Inicio.", systemImage: "house")
                    .font(.footnote)
                    .foregroundStyle(OG.label2)

                Text("Sin citas sincronizadas")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(OG.label2)
            }
        }
    }
}
