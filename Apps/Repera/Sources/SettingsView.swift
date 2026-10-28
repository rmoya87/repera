import ReperaDomain
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import UserNotifications

struct SettingsView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(HealthKitStore.self) private var health
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(AppleAuthStore.self) private var appleAuth
    @Environment(BusinessAuthStore.self) private var businessAuth
    @Environment(BusinessDataStore.self) private var businessData
    @Environment(OnboardingStore.self) private var onboarding
    @Environment(WorkoutLocationTracker.self) private var location
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    @State private var exportURL: URL?
    @State private var showingImporter = false
    @State private var showingCSVImporter = false
    @State private var confirmDeleteAccount = false
    @State private var isDeletingAccount = false
    @State private var accountDeleteError: String?
    @State private var importFeedback: String?
    @State private var photoItem: PhotosPickerItem?
    @State private var isPhotoPickerPresented = false
    @State private var restoreMessage: String?
    @State private var accessFeedbackTitle = "Acceso Pro"
    @State private var isVerifyingSubscription = false
    @State private var notificationsStatus: UNAuthorizationStatus = .notDetermined
    @State private var confirmSignOut = false
    @State private var googleLinkFeedback: String?
    @State private var workoutSync = BusinessWorkoutSyncStore.shared
    var body: some View {
        @Bindable var store = store
        Form {
            OGScrollablePageTitle("Ajustes").ogScrollingTitleListRow()
            Section {
                HStack(spacing: 12) {
                    Button {
                        isPhotoPickerPresented = true
                    } label: {
                        ZStack(alignment: .bottomTrailing) {
                            iCloudAvatarBadge
                                .frame(width: 52, height: 52)
                            Image(systemName: "apple.logo")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 20, height: 20)
                                .background(.black, in: Circle())
                                .overlay(Circle().stroke(OG.bg, lineWidth: 2))
                                .offset(x: 2, y: 2)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .photosPicker(
                        isPresented: $isPhotoPickerPresented,
                        selection: $photoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    )
                    .accessibilityLabel("Cambiar foto de perfil")
                    VStack(alignment: .leading, spacing: 4) {
                        TextField(
                            "Tu nombre",
                            text: Binding(
                                get: { store.state.settings.profileDisplayName ?? appleAuth.displayName ?? "" },
                                set: {
                                    var settings = store.state.settings
                                    let trimmed = $0.trimmingCharacters(in: .whitespacesAndNewlines)
                                    settings.profileDisplayName = trimmed.isEmpty ? nil : trimmed
                                    store.updateSettings(settings)
                                }
                            )
                        )
                        .font(.headline)
                        .onSubmit {
                            Task {
                                await businessAuth.syncPublicProfile(
                                    displayName: store.state.settings.profileDisplayName ?? appleAuth.displayName,
                                    avatarJPEG: store.state.settings.profileAvatarJPEG
                                )
                            }
                        }
                        HStack(spacing: 5) {
                            Text(businessAuth.isConnected ? "Sesión iniciada" : "Sin sesión")
                            if let email = businessAuth.accountEmail ?? appleAuth.email, !email.isEmpty {
                                Text("·")
                                Text(email).lineLimit(1).truncationMode(.middle)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(OG.label2)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 6)
                .onChange(of: photoItem) { _, item in
                    guard let item else { return }
                    Task { @MainActor in
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data),
                           let jpeg = ProfileAvatar.jpegData(from: image) {
                            var settings = store.state.settings
                            settings.profileAvatarJPEG = jpeg
                            store.updateSettings(settings)
                            await businessAuth.syncPublicProfile(
                                displayName: settings.profileDisplayName ?? appleAuth.displayName,
                                avatarJPEG: jpeg
                            )
                        }
                        photoItem = nil
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(OG.label2)
                    Text("Sincronización automática")
                        .foregroundStyle(OG.label2)
                    Spacer()
                    if workoutSync.isSyncing {
                        ProgressView().controlSize(.small)
                    } else if let lastSync = workoutSync.lastSyncAt {
                        Text(lastSync, style: .relative)
                            .font(.caption)
                            .foregroundStyle(OG.label3)
                    }
                }
                .font(.footnote)
                .padding(.vertical, 4)

                if businessAuth.isConnected, !businessAuth.isGoogleSignedIn {
                    Button {
                        Task {
                            let linked = await businessAuth.linkGoogleToCurrentAccount()
                            googleLinkFeedback = linked
                                ? "Google vinculado a esta cuenta."
                                : businessAuth.lastErrorMessage
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image("GoogleSignInLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                            Text("Vincular con Google")
                                .font(.system(size: 15, weight: .semibold))
                            Spacer(minLength: 0)
                            if businessAuth.isConnecting { ProgressView().controlSize(.small) }
                        }
                        .foregroundStyle(colorScheme == .dark
                            ? Color(red: 227 / 255, green: 227 / 255, blue: 227 / 255)
                            : Color(red: 31 / 255, green: 31 / 255, blue: 31 / 255))
                        .padding(.horizontal, 16)
                        .frame(minHeight: 50)
                        .background(colorScheme == .dark
                            ? Color(red: 19 / 255, green: 19 / 255, blue: 20 / 255)
                            : .white, in: RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(colorScheme == .dark
                                    ? Color(red: 142 / 255, green: 145 / 255, blue: 143 / 255)
                                    : Color(red: 116 / 255, green: 119 / 255, blue: 117 / 255),
                                    lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(businessAuth.isConnecting)
                }
                if let googleLinkFeedback {
                    Text(googleLinkFeedback)
                        .font(.caption)
                        .foregroundStyle(OG.label2)
                }
                HStack(spacing: 10) {
                    Image(systemName: businessAuth.isGoogleSignedIn
                        ? "person.crop.circle" : "apple.logo")
                        .foregroundStyle(OG.label)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(businessAuth.isGoogleSignedIn ? "Google" : "Apple")
                            .font(.subheadline.weight(.medium))
                        if let email = businessAuth.accountEmail ?? appleAuth.email {
                            Text(email).font(.caption).foregroundStyle(OG.label2)
                                .lineLimit(1).truncationMode(.middle)
                        }
                    }
                    Spacer(minLength: 8)
                    Button("Cerrar sesión", role: .destructive) {
                        confirmSignOut = true
                    }
                    .font(.subheadline.weight(.semibold))
                }
            } header: {
                Text("Cuenta")
            }

            Section {
                let linked = businessData.linkedCenters()
                ForEach(linked) { center in
                    NavigationLink {
                        LinkedCenterDetailView(center: center)
                    } label: {
                        CenterRow(center: center, linked: true)
                    }
                }

                NavigationLink {
                    FindCenterTrainerView()
                } label: {
                    Label("Buscar centro o entrenador", systemImage: "magnifyingglass")
                        .foregroundStyle(OG.label)
                }

                // La identidad Apple y la sesión Supabase se obtienen en el login.
                // Ajustes nunca solicita otra autorización Apple para Business.
            } header: {
                Text("Centro y entrenador")
            }


            Section {
                if subscriptions.businessSponsoredAccess {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Acceso completo")
                                .font(.headline)
                            Text("Incluido con tu centro o entrenador")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(OG.label)
                    }
                } else if subscriptions.snapshot.grantsProAccess {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Repera Pro activo")
                                .font(.headline)
                            Text(subscriptions.status.displayName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if let exp = subscriptions.snapshot.expirationDate {
                                Text("Renueva o finaliza: \(exp.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(OG.label)
                    }
                    Button("Gestionar suscripción") {
                        openURL(CommercialConfig.manageSubscriptionsURL)
                    }
                    .foregroundStyle(OG.label)
                } else {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Repera Pro")
                                .font(.headline)
                            Text("O vincula un centro para acceso completo")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "lock.fill")
                            .foregroundStyle(OG.label)
                    }
                    Button("Descubrir Pro") {
                        subscriptions.presentPaywall(.settings, feature: .advancedProgress)
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(OG.label)
                }
                if !subscriptions.businessSponsoredAccess {
                    Button {
                        guard !isVerifyingSubscription else { return }
                        isVerifyingSubscription = true
                        Task {
                            await subscriptions.refreshEntitlementsForFeatureAction()
                            isVerifyingSubscription = false
                            accessFeedbackTitle = "Comprobar acceso Pro"
                            if subscriptions.snapshot.grantsProAccess,
                               subscriptions.snapshot.status == .unknown {
                                restoreMessage = "Acceso Pro conservado desde la última verificación. No se ha podido comprobar de nuevo la compra ahora mismo. Prueba «Restaurar compras» cuando tengas conexión."
                            } else if subscriptions.snapshot.grantsProAccess {
                                restoreMessage = "Acceso \(subscriptions.status.displayName) verificado en este dispositivo. Las compras de prueba de TestFlight no tienen por qué aparecer en la lista de suscripciones reales de Apple."
                            } else {
                                restoreMessage = "No se ha encontrado un acceso Pro activo para esta cuenta de compras. Si ya activaste una suscripción de prueba, utiliza «Restaurar compras»."
                            }
                        }
                    } label: {
                        Label(
                            isVerifyingSubscription ? "Comprobando acceso…" : "Comprobar acceso Pro",
                            systemImage: "checkmark.shield"
                        )
                    }
                    .disabled(isVerifyingSubscription || subscriptions.purchaseInFlight)
                    .foregroundStyle(OG.label)
                    Button("Restaurar compras") {
                        Task {
                            let ok = await subscriptions.restorePurchases()
                            accessFeedbackTitle = "Restaurar compras"
                            restoreMessage = ok
                                ? "Suscripción restaurada."
                                : (subscriptions.lastErrorMessage ?? "No se encontró ninguna suscripción.")
                        }
                    }
                    .disabled(subscriptions.purchaseInFlight)
                    .foregroundStyle(OG.label)
                }
                NavigationLink {
                    AIAccessView()
                } label: {
                    Label("Conecta tu IA", systemImage: "brain.head.profile")
                        .foregroundStyle(OG.label)
                }
            } header: {
                Text("Acceso")
            }

            #if DEBUG
            Section {
                Toggle("Simular suscripción", isOn: Binding(
                    get: { DebugEntitlementController.shared.overrideEnabled },
                    set: {
                        DebugEntitlementController.shared.overrideEnabled = $0
                        subscriptions.applyDebugProvider()
                    }
                ))
                Picker("Estado", selection: Binding(
                    get: { DebugEntitlementController.shared.forcedStatus },
                    set: {
                        DebugEntitlementController.shared.forcedStatus = $0
                        DebugEntitlementController.shared.overrideEnabled = true
                        subscriptions.applyDebugProvider()
                    }
                )) {
                    ForEach([
                        SubscriptionStatus.free,
                        .trial,
                        .proMonthly,
                        .proAnnual,
                        .gracePeriod,
                        .expired,
                        .revoked,
                        .unknown,
                    ], id: \.self) { status in
                        Text(status.displayName).tag(status)
                    }
                }
                Toggle("Simular offline", isOn: Binding(
                    get: { DebugEntitlementController.shared.simulateOffline },
                    set: {
                        DebugEntitlementController.shared.simulateOffline = $0
                        subscriptions.applyDebugProvider()
                    }
                ))
                Button("Reset cuota escáner") {
                    subscriptions.freeUsage.resetForDebug()
                }
            } header: {
                Text("Debug Pro (solo Debug)")
            }
            #endif

            Section {
                permissionStatusRow(
                    title: "Notificaciones",
                    detail: notificationsStatusLabel,
                    symbol: "bell"
                ) {
                    Task {
                        _ = try? await UNUserNotificationCenter.current()
                            .requestAuthorization(options: [.alert, .sound, .badge])
                        await refreshNotificationsStatus()
                    }
                }
                NavigationLink {
                    ConnectedHealthSettingsView()
                } label: {
                    HStack(spacing: 10) {
                        Label(
                            health.isAuthorized ? "Apple Salud" : "Conectar con Salud",
                            systemImage: "heart"
                        )
                        .foregroundStyle(OG.label)
                        Spacer(minLength: 8)

                    }
                }

                permissionStatusRow(
                    title: "Ubicación",
                    detail: location.isAuthorized ? "Permitida" : "No permitida",
                    symbol: "location"
                ) {
                    Task {
                        let ok = await location.ensureWhenInUseAuthorized()
                        location.refreshStatus()
                        if !ok,
                           location.authorizationStatus == .denied
                            || location.authorizationStatus == .restricted,
                           let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                }

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                } label: {
                    Label("Abrir Ajustes del sistema", systemImage: "gearshape")
                        .foregroundStyle(OG.label)
                }

                NavigationLink {
                    HealthGoalsView()
                } label: {
                    Label("Objetivos", systemImage: "target")
                        .foregroundStyle(OG.label)
                }

                NavigationLink {
                    BodyWeightListView()
                } label: {
                    HStack {
                        Label("Peso", systemImage: "scalemass")
                            .foregroundStyle(OG.label)
                        Spacer()
                        if let latest = store.state.bodyWeights.first {
                            Text("\(ReperaNumberFormat.decimal(latest.weightKg)) kg")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        } else if let kg = health.latestWeightKg {
                            Text("\(ReperaNumberFormat.decimal(kg)) kg")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
            } header: {
                Text("Salud")
            }
            .task {
                await refreshNotificationsStatus()
                location.refreshStatus()
            }

            Section("Entrenamiento") {
                NavigationLink {
                    HistoryView()
                } label: {
                    Label("Historial", systemImage: "clock")
                        .foregroundStyle(OG.label)
                }
                Picker("Unidad", selection: Binding(
                    get: { store.state.settings.weightUnit },
                    set: {
                        var s = store.state.settings
                        s.weightUnit = $0
                        store.updateSettings(s)
                    }
                )) {
                    Text("kg").tag(WeightUnit.kg)
                    Text("lb").tag(WeightUnit.lb)
                }
                Picker("Modo de plan", selection: Binding(
                    get: { store.state.settings.scheduleMode },
                    set: { store.setScheduleMode($0) }
                )) {
                    ForEach(ScheduleMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                if store.state.settings.scheduleMode == .rotation {
                    NavigationLink {
                        RotationPlanEditor()
                    } label: {
                        Label("Editar rotación", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                Text("Los días del plan semanal se editan en Diario → Programado / Rutinas.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Picker("Semana empieza", selection: Binding(
                    get: { store.state.settings.weekStartsOn },
                    set: {
                        var s = store.state.settings
                        s.weekStartsOn = $0
                        store.updateSettings(s)
                    }
                )) {
                    Text("Lunes").tag(WeekStart.monday)
                    Text("Domingo").tag(WeekStart.sunday)
                }
                Picker("Esfuerzo (registro)", selection: Binding(
                    get: { store.state.settings.effortUnit },
                    set: {
                        var s = store.state.settings
                        s.effortUnit = $0
                        store.updateSettings(s)
                    }
                )) {
                    ForEach(EffortUnit.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }

            }

            Section("Datos") {
                LabeledContent("Entrenamientos", value: "\(store.state.workouts.count)")
                Button("Exportar JSON") { exportBackup() }
                Button("Importar JSON") { showingImporter = true }
                Button("Importar CSV Strong/Hevy") { showingCSVImporter = true }
                if let summary = store.lastImportSummary {
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let importFeedback {
                    Text(importFeedback)
                        .font(.footnote)
                        .foregroundStyle(OG.label2)
                }
                Button("Eliminar mi cuenta", role: .destructive) {
                    confirmDeleteAccount = true
                }
                .disabled(isDeletingAccount)
            }
        }
        .listStyle(.insetGrouped)
        .ogListChrome()
        .ogScrollingTitleNav()
        .alert(accessFeedbackTitle, isPresented: Binding(
            get: { restoreMessage != nil },
            set: { if !$0 { restoreMessage = nil } }
        )) {
            Button("OK", role: .cancel) { restoreMessage = nil }
        } message: {
            Text(restoreMessage ?? "")
        }
        .sheet(isPresented: $confirmSignOut) {
            OGConfirmSheet(
                systemImage: "person.crop.circle.badge.xmark",
                title: "¿Cerrar sesión?",
                message: "Volverás al acceso con Apple o Google. Tus datos locales se conservan.",
                confirmTitle: "Cerrar sesión",
                onConfirm: {
                    appleAuth.signOut()
                    businessData.clear()
                    Task { await businessAuth.signOut() }
                    onboarding.resetToSignIn()
                    confirmSignOut = false
                },
                onCancel: { confirmSignOut = false }
            )
        }
        .task {
            health.refreshAuthorizationStatus()
            await refreshNotificationsStatus()
            location.refreshStatus()
            if health.isAuthorized {
                await health.refreshToday()
            }
            // Reutilizar el inicio de sesión Apple → Supabase, sin otra CTA.
            if !businessAuth.isConnected {
                await businessAuth.restoreSession()
                if !businessAuth.isConnected {
                    _ = businessAuth.connectFromCachedSessionIfPossible()
                }
            }
            if businessAuth.isConnected {
                await businessData.refresh()
            }
        }
        .sheet(isPresented: $confirmDeleteAccount) {
            OGConfirmSheet(
                systemImage: "person.crop.circle.badge.xmark",
                title: "¿Eliminar mi cuenta definitivamente?",
                message: "Se eliminará tu cuenta de Repera y su historial de iCloud y Supabase. No se puede deshacer. Los entrenamientos existentes en Apple Salud y las suscripciones de Apple se gestionan por separado.",
                confirmTitle: "Eliminar mi cuenta",
                onConfirm: {
                    confirmDeleteAccount = false
                    Task { await deleteCurrentAccount() }
                },
                onCancel: { confirmDeleteAccount = false }
            )
        }
        .alert("No se ha podido eliminar la cuenta", isPresented: Binding(
            get: { accountDeleteError != nil },
            set: { if !$0 { accountDeleteError = nil } }
        )) {
            Button("Aceptar", role: .cancel) { accountDeleteError = nil }
        } message: {
            Text(accountDeleteError ?? "")
        }
        .overlay {
            if isDeletingAccount {
                ZStack {
                    Color.black.opacity(0.25).ignoresSafeArea()
                    ProgressView("Eliminando cuenta y datos…")
                        .padding(28)
                        .background(OG.surface, in: RoundedRectangle(cornerRadius: 18))
                }
            }
        }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
            importJSONBackup(result)
        }
        .fileImporter(
            isPresented: $showingCSVImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText]
        ) { result in
            importWorkoutCSV(result)
        }
        .sheet(isPresented: Binding(
            get: { exportURL != nil },
            set: { if !$0 { exportURL = nil } }
        )) {
            if let exportURL {
                ShareLink(item: exportURL) {
                    Text("Compartir backup")
                }
                .padding()
                .ogSheetChrome(detents: [.medium])
            }
        }
    }

    private var notificationsStatusLabel: String {
        switch notificationsStatus {
        case .authorized, .provisional, .ephemeral: return "Permitidas"
        case .denied: return "Denegadas"
        default: return "Sin configurar"
        }
    }

    private func refreshNotificationsStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationsStatus = settings.authorizationStatus
    }

    private func permissionStatusRow(
        title: String,
        detail: String,
        symbol: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: symbol)
                    .foregroundStyle(OG.label)
                Spacer()
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var iCloudAvatarBadge: some View {
        let synced = store.iCloudStatus == .available
        ZStack {
            Circle()
                .fill(synced ? OG.label.opacity(0.12) : OG.surface2)
                .frame(width: 44, height: 44)
            if let img = ProfileAvatar.uiImage(from: store.state.settings.profileAvatarJPEG) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            } else {
                Image(systemName: synced ? "person.crop.circle.fill" : "icloud.slash")
                    .font(.system(size: synced ? 26 : 18, weight: .regular))
                    .foregroundStyle(synced ? OG.label : OG.label2)
            }
        }
    }

    /// Backup del usuario (no sustituye credenciales ni autoriza acciones remotas).
    private func importJSONBackup(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else {
            if case .failure(let error) = result {
                importFeedback = "No se pudo abrir el archivo: \(error.localizedDescription)"
            }
            return
        }
        guard url.startAccessingSecurityScopedResource() else {
            importFeedback = "No se pudo acceder al JSON seleccionado."
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        do {
            let data = try Data(contentsOf: url)
            guard let imported = LocalStore.shared.importJSON(data) else {
                importFeedback = "El JSON no contiene un backup válido de Repera."
                return
            }
            guard store.state.activeSession == nil else {
                importFeedback = "Finaliza el entrenamiento en curso antes de importar."
                return
            }
            store.state = imported
            store.persist(touchWorkouts: true)
            importFeedback = "Backup restaurado: \(imported.workouts.count) entrenamientos."
        } catch {
            importFeedback = "No se pudo importar JSON: \(error.localizedDescription)"
        }
    }

    private func importWorkoutCSV(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else {
            if case .failure(let error) = result {
                importFeedback = "No se pudo abrir el CSV: \(error.localizedDescription)"
            }
            return
        }
        guard url.startAccessingSecurityScopedResource() else {
            importFeedback = "No se pudo acceder al CSV seleccionado."
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        do {
            guard store.state.activeSession == nil else {
                importFeedback = "Finaliza el entrenamiento en curso antes de importar."
                return
            }
            let data = try Data(contentsOf: url)
            guard let text = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .isoLatin1) else {
                importFeedback = "Codificación CSV no compatible."
                return
            }
            let result = store.importCSV(text)
            importFeedback = "\(result.source.rawValue): \(result.workouts.count) entrenamientos importados."
        } catch {
            importFeedback = "No se pudo importar CSV: \(error.localizedDescription)"
        }
    }

    /// El endpoint jamás acepta un UUID aportado por la app: usa el del JWT
    /// personal verificado por Supabase. La fase previa evita borrar iCloud
    /// si el usuario aún tiene responsabilidades empresariales.
    private func requestAccountDeletion(_ action: String) async throws {
        guard await businessAuth.ensureUsableSession(),
              let client = businessAuth.apiClient else {
            throw AccountDeletionError.message("Necesitas iniciar sesión y tener conexión para eliminar la cuenta.")
        }
        let session = try await client.auth.session
        guard !session.isExpired, !session.accessToken.isEmpty,
              let base = Bundle.main.object(forInfoDictionaryKey: "ReperaSupabaseURL") as? String,
              let url = URL(string: base + "/functions/v1/repera-delete-account"),
              url.scheme == "https", url.host == "uvzgujlrqohreoucirms.supabase.co"
        else { throw AccountDeletionError.message("No se pudo verificar la conexión segura con Repera.") }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["action": action])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw AccountDeletionError.message("Respuesta inválida del servidor.")
        }
        let payload = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        guard (200..<300).contains(response.statusCode), payload?["ok"] as? Bool == true else {
            throw AccountDeletionError.message(
                payload?["error"] as? String
                    ?? "No se pudo confirmar la eliminación remota (\(response.statusCode))."
            )
        }
    }

    private func deleteCurrentAccount() async {
        guard !isDeletingAccount else { return }
        isDeletingAccount = true
        defer { isDeletingAccount = false }
        accountDeleteError = nil
        do {
            guard store.state.activeSession == nil else {
                throw AccountDeletionError.message("Finaliza primero el entrenamiento en curso.")
            }
            let deletedOwnerID = businessAuth.apiClient?.auth.currentSession?.user.id.uuidString.lowercased()
            try await requestAccountDeletion("preflight")
            // La eliminación de iCloud es coordinada; si no se puede comprobar,
            // NO se elimina la cuenta remota ni se muestra un falso éxito.
            try await LocalStore.shared.purgeDeletedAccountDocuments()
            do {
                try await requestAccountDeletion("delete")
            } catch {
                // Falló Supabase: recuperar el respaldo local aún en memoria.
                LocalStore.shared.resumeStorageForNewLogin()
                store.persist(touchWorkouts: true)
                throw error
            }
            // Nunca sincronizar la copia anterior tras borrar su identidad.
            store.state = LocalStore.shared.emptyShellState()
            UserDefaults.standard.removeObject(forKey: "repera.places.recent.v1")
            UserDefaults.standard.removeObject(forKey: "repera.timer.lastCompletion.v1")
            if let deletedOwnerID {
                let prefix = "repera.supabaseWorkoutMirror.v1.\(deletedOwnerID)."
                for key in UserDefaults.standard.dictionaryRepresentation().keys
                    where key.hasPrefix(prefix) {
                    UserDefaults.standard.removeObject(forKey: key)
                }
            }
            appleAuth.signOut()
            businessData.clear()
            await businessAuth.signOut()
            businessAuth.forgetDeletedAccountBinding()
            onboarding.resetToSignIn()
        } catch let error as AccountDeletionError {
            accountDeleteError = error.localizedDescription
        } catch {
            accountDeleteError = "No se ha completado la eliminación. Comprueba que iCloud Drive esté disponible y que tengas conexión, y vuelve a intentarlo."
        }
    }

    private enum AccountDeletionError: LocalizedError {
        case message(String)
        var errorDescription: String? {
            if case .message(let detail) = self { return detail }
            return nil
        }
    }

    private func exportBackup() {
        guard let data = LocalStore.shared.exportJSON(store.state) else {
            importFeedback = "No se pudo crear el backup JSON."
            return
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("repera-backup-\(UUID().uuidString).json")
        do {
            try data.write(to: url, options: .atomic)
            exportURL = url
            importFeedback = nil
        } catch {
            importFeedback = "No se pudo exportar JSON: \(error.localizedDescription)"
        }
    }
}

// MARK: - Rotación A→B→C

/// Orden de plantillas cuando el plan está en modo rotación (no por día de la semana).
struct RotationPlanEditor: View {
    @Environment(ReperaStore.self) private var store

    private var library: [Routine] {
        store.libraryRoutines
    }

    private var orderedIds: [UUID] {
        store.state.rotation?.routineIds ?? []
    }

    var body: some View {
        List {
            OGScrollablePageTitle("Rotación").ogScrollingTitleListRow()
            Section {
                if orderedIds.isEmpty {
                    Text("Añade rutinas de Diario → Rutinas para armar la cola.")
                        .font(.footnote)
                        .foregroundStyle(OG.label2)
                }
                ForEach(orderedIds, id: \.self) { id in
                    let title = library.first(where: { $0.id == id })?.title
                        ?? store.state.routines.first(where: { $0.id == id })?.title
                        ?? "Rutina"
                    Text(title)
                        .foregroundStyle(OG.label)
                }
                .onMove(perform: move)
                .onDelete(perform: delete)
            } header: {
                Text("Orden")
            } footer: {
                Text("El siguiente entreno del día sigue este orden, no el día de la semana. Arrastra para reordenar.")
            }

            Section("Disponibles") {
                let inRotation = Set(orderedIds)
                let available = library.filter { !inRotation.contains($0.id) }
                if available.isEmpty {
                    Text("No hay más rutinas. Crea alguna en Diario → Rutinas.")
                        .font(.footnote)
                        .foregroundStyle(OG.label2)
                } else {
                    ForEach(available) { routine in
                        Button {
                            append(routine.id)
                        } label: {
                            Label(routine.title, systemImage: "plus.circle")
                        }
                    }
                }
            }
        }
        .ogListChrome()
        .ogScrollingTitleNav()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .onAppear {
            if store.state.rotation == nil, store.state.settings.scheduleMode == .rotation {
                store.updateRotation(RotationPlan(routineIds: library.map(\.id)))
            }
        }
    }

    private func append(_ id: UUID) {
        var plan = store.state.rotation ?? RotationPlan()
        guard !plan.routineIds.contains(id) else { return }
        plan.routineIds.append(id)
        store.updateRotation(plan)
    }

    private func move(from source: IndexSet, to destination: Int) {
        var plan = store.state.rotation ?? RotationPlan()
        plan.routineIds.move(fromOffsets: source, toOffset: destination)
        store.updateRotation(plan)
    }

    private func delete(at offsets: IndexSet) {
        var plan = store.state.rotation ?? RotationPlan()
        plan.routineIds.remove(atOffsets: offsets)
        store.updateRotation(plan.routineIds.isEmpty ? nil : plan)
    }
}

// MARK: - Objetivos de Salud (en el mismo archivo de Ajustes para proyectos Xcode sin regenerar)
/// Objetivos opcionales, sincronizados en AppSettings con el resto de la cuenta.
/// Mantiene el objetivo de peso histórico sin migraciones destructivas.
struct HealthGoalsView: View {
    @Environment(ReperaStore.self) private var store

    @State private var steps = ""
    @State private var energy = ""
    @State private var minutes = ""
    @State private var weekly = ""
    @State private var weight = ""
    @State private var hasLoaded = false
    @State private var focusedGoal: GoalField?

    private enum GoalField: String { case steps, energy, minutes, weekly, weight }

    var body: some View {
        Form {
            OGScrollablePageTitle("Objetivos").ogScrollingTitleListRow()
            Section {
                goalRow("Pasos", icon: "figure.walk", field: .steps, next: .energy, text: $steps, unit: "pasos")
                goalRow("Calorías activas", icon: "flame", field: .energy, next: .minutes, text: $energy, unit: "kcal")
                goalRow("T. de entreno", icon: "clock", field: .minutes, next: .weekly, text: $minutes, unit: "min")
            } header: {
                Text("Objetivos diarios")
            }

            Section {
                goalRow("Entreno", icon: "checkmark.circle", field: .weekly, next: .weight, text: $weekly, unit: "semana")
            } header: {
                Text("Objetivo semanal")
            }

            Section {
                goalRow("Peso objetivo", icon: "scalemass", field: .weight, text: $weight, unit: "kg", decimal: true)
                if let current = store.state.bodyWeights.first?.weightKg {
                    LabeledContent("Peso registrado", value: "\(ReperaNumberFormat.decimal(current)) kg")
                        .foregroundStyle(OG.label2)
                }
            } header: {
                Text("Objetivo corporal")
            }


        }
        .ogListChrome()
        .ogScrollingTitleNav()
        .onAppear(perform: loadOnce)
        .onChange(of: steps) { _, text in persistInt(text, range: 100...100_000, keyPath: \.dailyStepsGoal) }
        .onChange(of: energy) { _, text in persistInt(text, range: 10...10_000, keyPath: \.dailyActiveEnergyGoalKcal) }
        .onChange(of: minutes) { _, text in persistInt(text, range: 1...1_440, keyPath: \.dailyWorkoutMinutesGoal) }
        .onChange(of: weekly) { _, text in persistInt(text, range: 1...21, keyPath: \.weeklyWorkoutGoal) }
        .onChange(of: weight) { _, text in persistWeight(text) }
    }

    private func goalRow(
        _ name: String,
        icon: String,
        field: GoalField,
        next: GoalField? = nil,
        text: Binding<String>,
        unit: String,
        decimal: Bool = false
    ) -> some View {
        HStack(spacing: 10) {
            Label(name, systemImage: icon)
                .foregroundStyle(OG.label)
            Spacer(minLength: 6)
            OGNumericTextField(
                text: text,
                allowsDecimal: decimal,
                textAlignment: .right,
                fontSize: 17,
                autoFocus: false,
                isFocused: focusedGoal == field,
                submitTitle: next == nil ? "✓" : "Siguiente",
                focusIdentifier: "health-goal-\(field.rawValue)",
                nextFocusIdentifier: next.map { "health-goal-\($0.rawValue)" },
                onFocused: { focusedGoal = field },
                onFocusLost: { if focusedGoal == field { focusedGoal = nil } },
                onCommit: { focusedGoal = next }
            )
            .frame(width: 82, height: 44)
            .accessibilityLabel(name)
            Text(unit)
                .font(.footnote)
                .foregroundStyle(OG.label2)
        }
    }

    private func loadOnce() {
        guard !hasLoaded else { return }
        hasLoaded = true
        let s = store.state.settings
        steps = s.dailyStepsGoal.map { String($0) } ?? ""
        energy = s.dailyActiveEnergyGoalKcal.map { String($0) } ?? ""
        minutes = s.dailyWorkoutMinutesGoal.map { String($0) } ?? ""
        weekly = s.weeklyWorkoutGoal.map { String($0) } ?? ""
        weight = s.bodyWeightGoalKg.map { ReperaNumberFormat.decimal($0) } ?? ""
    }

    /// Persiste solo el campo editado; permite borrar su meta dejándolo vacío.
    private func persistInt(_ draft: String, range: ClosedRange<Int>, keyPath: WritableKeyPath<AppSettings, Int?>) {
        guard hasLoaded else { return }
        let input = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        let next: Int?
        if input.isEmpty { next = nil }
        else {
            guard let number = Int(input), range.contains(number) else { return }
            next = number
        }
        var settings = store.state.settings
        guard settings[keyPath: keyPath] != next else { return }
        settings[keyPath: keyPath] = next
        store.updateSettings(settings)
    }

    private func persistWeight(_ draft: String) {
        guard hasLoaded else { return }
        let input = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        let next: Double?
        if input.isEmpty { next = nil }
        else {
            guard let number = ReperaNumberFormat.parse(input),
                  number.isFinite, (20...350).contains(number) else { return }
            next = number
        }
        var settings = store.state.settings
        guard settings.bodyWeightGoalKg != next else { return }
        settings.bodyWeightGoalKg = next
        store.updateSettings(settings)
    }
}
