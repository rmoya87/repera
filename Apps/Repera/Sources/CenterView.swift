import SwiftUI

/// Native athlete Center entry point. Never substitute fake class availability for Supabase data.
/// Booking, contracts and center invitations are not connected to iOS yet.
struct CenterView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    OGCardSectionTitle(title: "Mis centros")

                    OGCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Image(systemName: "building.2")
                                .font(.system(size: 34, weight: .medium))
                                .foregroundStyle(OG.accent)

                            Text("Tus centros deportivos")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(OG.label)

                            Text("Cuando aceptes la invitación de un gimnasio o entrenador, podrás seleccionar aquí sus centros y servicios.")
                                .font(.subheadline)
                                .foregroundStyle(OG.label2)
                        }
                    }

                    OGCardSectionTitle(title: "Clases y reservas")

                    OGCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Calendario de clases", systemImage: "calendar")
                                .font(.headline)
                                .foregroundStyle(OG.label)

                            Text("En cuanto se conecte el calendario de tu centro, podrás consultar plazas reales, reservar y apuntarte a listas de espera.")
                                .font(.subheadline)
                                .foregroundStyle(OG.label2)

                            Label("Las reservas confirmadas aparecerán también en Inicio.", systemImage: "house")
                                .font(.footnote)
                                .foregroundStyle(OG.label2)

                            Text("Sin clases sincronizadas")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(OG.label2)
                                .padding(.top, 4)
                        }
                    }

                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Ver mis centros y servicios en Ajustes", systemImage: "person.crop.circle")
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
}
