import SwiftUI

/// Existing Apple/iCloud members do not have Supabase credentials in older builds.
/// Apple's private user identifier is not a server credential: they must explicitly
/// authenticate again to obtain a signed ID token bound to a fresh nonce.
/// No personal workouts or HealthKit data are uploaded during this migration.
struct LegacyAccountMigrationView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(AppleAuthStore.self) private var appleAuth
    @Environment(BusinessAuthStore.self) private var businessAuth
    let onContinueLocalOnly: () -> Void

    @State private var isMigrating = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 24)

                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 42, weight: .medium))
                    .foregroundStyle(OG.accent)
                    .frame(width: 84, height: 84)
                    .background(OG.accent.opacity(0.12),
                                in: RoundedRectangle(cornerRadius: 24))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Tu Repera de siempre, ahora conectada")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(OG.label)

                    Text("Ya hemos encontrado tu cuenta Apple en este dispositivo. Solo necesitamos confirmar tu identidad para asociarla a Supabase y activar tu entrenador, tus clases y tus reservas.")
                        .font(.body)
                        .foregroundStyle(OG.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 16) {
                    benefit(
                        icon: "checkmark.icloud",
                        title: "Tus entrenamientos siguen contigo",
                        detail: "No cambia tu historial, tus rutinas ni la copia de iCloud."
                    )
                    benefit(
                        icon: "person.text.rectangle",
                        title: "Migramos tu cuenta, no tu historial",
                        detail: "Solo asociamos la identidad Apple y, si hace falta, tu nombre de perfil."
                    )
                    benefit(
                        icon: "building.2",
                        title: "Tu entrenador y tu gimnasio",
                        detail: "Podrás aceptar invitaciones y ver las planificaciones autorizadas."
                    )
                }
                .padding(20)
                .background(OG.surface, in: RoundedRectangle(cornerRadius: 20))

                Button {
                    Task { await migrate() }
                } label: {
                    HStack(spacing: 10) {
                        if isMigrating {
                            ProgressView().tint(OG.onAccent)
                        } else {
                            Image(systemName: "apple.logo")
                        }
                        Text("Vincular mi cuenta con Apple")
                    }
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                }
                .foregroundStyle(OG.onAccent)
                .background(OG.accent, in: RoundedRectangle(cornerRadius: 16))
                .disabled(isMigrating)

                Button("Seguir con mis entrenamientos sin conexión") {
                    businessAuth.setPrefersLocalOnly(true)
                    onContinueLocalOnly()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(OG.label2)
                .frame(maxWidth: .infinity)
                .disabled(isMigrating)

                if let errorMessage = errorMessage ?? businessAuth.lastErrorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(OG.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text("El modo sin conexión mantiene las funciones personales locales, pero no podrá cargar clases, bonos ni entrenamientos de profesionales hasta que conectes Supabase desde Ajustes.")
                    .font(.footnote)
                    .foregroundStyle(OG.label3)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 12)
            }
            .padding(24)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(OG.bg.ignoresSafeArea())
    }

    private func benefit(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(OG.accent)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.bold)).foregroundStyle(OG.label)
                Text(detail).font(.footnote).foregroundStyle(OG.label2)
            }
        }
    }

    private func migrate() async {
        guard !isMigrating else { return }
        isMigrating = true
        defer { isMigrating = false }
        errorMessage = nil
        do {
            try await appleAuth.signIn()
            await businessAuth.migrateLocalProfileIfNeeded(
                displayName: store.state.settings.profileDisplayName ?? appleAuth.displayName
            )
        } catch let error as AppleAuthError where error == .cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
