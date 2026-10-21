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
    @Environment(BusinessWorkoutSyncStore.self) private var workoutSync
    @Environment(OnboardingStore.self) private var onboarding
    @Environment(WorkoutLocationTracker.self) private var location
    @Environment(\.openURL) private var openURL
    @State private var goalText = ""
    @State private var exportURL: URL?
    @State private var showingImporter = false
    @State private var showingCSVImporter = false
    @State private var confirmReset = false
    @State private var photoItem: PhotosPickerItem?
    @State private var restoreMessage: String?
    @State private var notificationsStatus: UNAuthorizationStatus = .notDetermined
    @State private var confirmSignOut = false
    @State private var appleConnectionError: String?
    @State private var isSyncingEverything = false
    @State private var syncIconSpinning = false
    /// Última sync completa (iCloud + perfil + entrenamientos).
    @State private var lastFullSyncAt: Date? = {
        let t = UserDefaults.standard.double(forKey: "repera.settings.lastFullSyncAt")
        return t > 0 ? Date(timeIntervalSince1970: t) : nil
    }()

    var body: some View {
        @Bindable var store = store
        Form {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "apple.logo")
                        .font(.title2)
                        .foregroundStyle(OG.label)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appleAuth.displayName ?? store.state.settings.profileDisplayName ?? "Cuenta Apple")
                            .font(.headline)
                        Text(appleAuth.isSignedIn ? "Sesión activa" : "Sin sesión")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let email = appleAuth.email {
                            Text(email)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 14) {
                    iCloudAvatarBadge
                    TextField(
                        "Tu nombre",
                        text: Binding(
                            get: { store.state.settings.profileDisplayName ?? "" },
                            set: {
                                var s = store.state.settings
                                let trimmed = $0.trimmingCharacters(in: .whitespacesAndNewlines)
                                s.profileDisplayName = trimmed.isEmpty ? nil : trimmed
                                store.updateSettings(s)
                            }
                        )
                    )
                    .font(.headline)
                    .onSubmit {
                        Task {
                            await businessAuth.syncPublicProfile(
                                displayName: store.state.settings.profileDisplayName,
                                avatarJPEG: store.state.settings.profileAvatarJPEG
                            )
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 4)

                let hasAvatar = store.state.settings.profileAvatarJPEG != nil
                PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                    ProfilePhotoPickerLabel(hasPhoto: hasAvatar)
                }
                .onChange(of: photoItem) { _, item in
                    guard let item else { return }
                    Task { @MainActor in
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data),
                           let jpeg = ProfileAvatar.jpegData(from: image) {
                            var s = store.state.settings
                            s.profileAvatarJPEG = jpeg
                            store.updateSettings(s)
                            await businessAuth.syncPublicProfile(
                                displayName: s.profileDisplayName ?? appleAuth.displayName,
                                avatarJPEG: jpeg
                            )
                        }
                        photoItem = nil
                    }
                }

                if store.state.settings.profileAvatarJPEG != nil {
                    Button("Quitar foto", role: .destructive) {
                        var s = store.state.settings
                        s.profileAvatarJPEG = nil
                        store.updateSettings(s)
                        Task {
                            await businessAuth.syncPublicProfile(
                                displayName: s.profileDisplayName ?? appleAuth.displayName,
                                avatarJPEG: nil
                            )
                        }
                    }
                }

                Button {
                    Task { await syncEverything() }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.body.weight(.semibold))
                            .rotationEffect(.degrees(syncIconSpinning ? 360 : 0))
                            .animation(
                                syncIconSpinning
                                    ? .linear(duration: 0.85).repeatForever(autoreverses: false)
                                    : .default,
                                value: syncIconSpinning
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isSyncingEverything ? "Sincronizando…" : "Sincronizar ahora")
                                .font(.body)
                            if let when = lastFullSyncAt {
                                Text("Última vez \(when.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(OG.label)
                }
                .disabled(isSyncingEverything)

                if let problem = workoutSync.lastError {
                    Text(problem)
                        .font(.footnote)
                        .foregroundStyle(OG.red)
                }

                Button("Cerrar sesión", role: .destructive) {
                    confirmSignOut = true
                }
            } header: {
                Text("Cuenta")
            } footer: {
                Text("Sincroniza copia iCloud, perfil y entrenamientos privados. Compartir resultados con un centro se gestiona en su ficha.")
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

                if !businessAuth.isConnected {
                    Button {
                        Task {
                            do {
                                try await appleAuth.signIn()
                                await businessAuth.syncPublicProfile(
                                    displayName: store.state.settings.profileDisplayName ?? appleAuth.displayName,
                                    avatarJPEG: store.state.settings.profileAvatarJPEG
                                )
                                await businessData.refresh()
                            } catch {
                                appleConnectionError = error.localizedDescription
                            }
                        }
                    } label: {
                        Label("Conectar con Apple", systemImage: "apple.logo")
                            .foregroundStyle(OG.label)
                    }
                    .disabled(appleAuth.isSigningIn || businessAuth.isConnecting)
                    if let error = businessAuth.lastErrorMessage {
                        Text(error).font(.footnote).foregroundStyle(OG.red)
                    }
                    if let appleConnectionError {
                        Text(appleConnectionError).font(.footnote).foregroundStyle(OG.red)
                    }
                }
                if let issue = businessAuth.profileMigrationErrorMessage {
                    Text(issue).font(.footnote).foregroundStyle(OG.red)
                    Button("Reintentar sincronización del perfil") {
                        Task {
                            await businessAuth.syncPublicProfile(
                                displayName: store.state.settings.profileDisplayName ?? appleAuth.displayName,
                                avatarJPEG: store.state.settings.profileAvatarJPEG
                            )
                        }
                    }
                    .foregroundStyle(OG.label)
                }
            } header: {
                Text("Centro y entrenador")
            } footer: {
                Text("Al vincularte y elegir bono, la app queda con acceso completo mientras mantengas el vínculo. Bonos y sesiones se ven en la ficha del centro.")
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
                    Button("Restaurar compras") {
                        Task {
                            let ok = await subscriptions.restorePurchases()
                            restoreMessage = ok
                                ? "Suscripción restaurada."
                                : (subscriptions.lastErrorMessage ?? "No se encontró ninguna suscripción.")
                        }
                    }
                    .disabled(subscriptions.purchaseInFlight)
                    .foregroundStyle(OG.label)
                }
                if !CommercialConfig.isConfigured {
                    Text("Compras no configuradas en este build (falta RevenueCatPublicAPIKey).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                            health.isAuthorized ? "Salud conectada" : "Conectar con Salud",
                            systemImage: "heart"
                        )
                        .foregroundStyle(OG.label)
                        Spacer(minLength: 8)
                        if healthNeedsAttention {
                            Circle()
                                .fill(OG.red)
                                .frame(width: 8, height: 8)
                                .accessibilityLabel("Permisos pendientes")
                        }
                    }
                }

                permissionStatusRow(
                    title: "Ubicación",
                    detail: location.isAuthorized ? "Permitida" : "Pendiente o denegada",
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
                    BodyWeightListView()
                } label: {
                    HStack {
                        Label("Peso", systemImage: "scalemass")
                            .foregroundStyle(OG.label)
                        Spacer()
                        if let latest = store.state.bodyWeights.first {
                            Text("\(latest.weightKg.formatted(.number.precision(.fractionLength(1)))) kg")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        } else if let kg = health.latestWeightKg {
                            Text("\(kg.formatted(.number.precision(.fractionLength(1)))) kg")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
                HStack {
                    Text("Objetivo")
                        .foregroundStyle(OG.label)
                    Spacer()
                    OGNumericTextField(
                        text: $goalText,
                        allowsDecimal: true,
                        textAlignment: .right,
                        autoFocus: false,
                        onCommit: {}
                    )
                    .frame(width: 92, height: 44)
                    .accessibilityLabel("Objetivo de peso en kilogramos")
                    Button("Guardar") {
                        var s = store.state.settings
                        let trimmed = goalText.trimmingCharacters(in: .whitespacesAndNewlines)
                        s.bodyWeightGoalKg = trimmed.isEmpty
                            ? nil
                            : Double(trimmed.replacingOccurrences(of: ",", with: "."))
                        store.updateSettings(s)
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(OG.label)
                }
                if let latest = store.state.bodyWeights.first {
                    LabeledContent(
                        "Último",
                        value: "\(latest.weightKg.formatted(.number.precision(.fractionLength(1)))) kg · \(latest.source.displayName)"
                    )
                    .foregroundStyle(OG.label)
                } else if let kg = health.latestWeightKg {
                    LabeledContent(
                        "Último",
                        value: "\(kg.formatted(.number.precision(.fractionLength(1)))) kg · Salud"
                    )
                    .foregroundStyle(OG.label)
                }
                if let goal = store.state.settings.bodyWeightGoalKg,
                   let latest = store.state.bodyWeights.first {
                    let delta = latest.weightKg - goal
                    if abs(delta) < 0.3 {
                        Text("Estás en el objetivo.")
                            .font(.footnote)
                            .foregroundStyle(OG.label)
                    } else {
                        let sign = delta > 0 ? "+" : ""
                        Text("\(sign)\(delta.formatted(.number.precision(.fractionLength(1)))) kg respecto al objetivo")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Salud")
            } footer: {
                Text("Calorías de Salud/Watch; ubicación para el pin del gym. Un peso por día; el objetivo sale en Progreso. Puedes denegar permisos y seguir usando la app.")
            }
            .task {
                await refreshNotificationsStatus()
                location.refreshStatus()
            }
            .onAppear {
                if let g = store.state.settings.bodyWeightGoalKg {
                    goalText = String(format: "%g", g)
                }
            }

            Section("Entrenamiento") {
                NavigationLink {
                    HistoryView()
                } label: {
                    Label("Historial", systemImage: "clock")
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
                Stepper(
                    "Descanso: \(store.state.settings.defaultRestSeconds)s",
                    value: Binding(
                        get: { store.state.settings.defaultRestSeconds },
                        set: {
                            var s = store.state.settings
                            s.defaultRestSeconds = $0
                            store.updateSettings(s)
                        }
                    ),
                    in: 30...300,
                    step: 15
                )
                Toggle("Sonido al terminar descanso", isOn: Binding(
                    get: { store.state.settings.restSoundEnabled },
                    set: {
                        var s = store.state.settings
                        s.restSoundEnabled = $0
                        store.updateSettings(s)
                    }
                ))
                Toggle("Vibración en countdown", isOn: Binding(
                    get: { store.state.settings.restHapticEnabled },
                    set: {
                        var s = store.state.settings
                        s.restHapticEnabled = $0
                        store.updateSettings(s)
                    }
                ))
                Picker("Esfuerzo", selection: Binding(
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
                Picker("Progresión por defecto", selection: Binding(
                    get: { store.state.settings.defaultProgression },
                    set: {
                        var s = store.state.settings
                        s.defaultProgression = $0
                        store.updateSettings(s)
                    }
                )) {
                    ForEach(ProgressionPolicy.allCases, id: \.self) { policy in
                        Text(policy.displayName).tag(policy)
                    }
                }
                Stepper(
                    "Incremento: \(store.state.settings.weightIncrementKg.formatted(.number.precision(.fractionLength(1)))) kg",
                    value: Binding(
                        get: { store.state.settings.weightIncrementKg },
                        set: {
                            var s = store.state.settings
                            s.weightIncrementKg = $0
                            store.updateSettings(s)
                        }
                    ),
                    in: 0.5...10,
                    step: 0.5
                )
            }

            Section("Datos") {
                LabeledContent("Entrenamientos", value: "\(store.state.workouts.count)")
                LabeledContent("Ejercicios", value: "\(store.state.exercises.count)")
                LabeledContent("Rutinas", value: "\(store.state.routines.count)")
                Button("Exportar JSON") { exportBackup() }
                Button("Importar JSON") { showingImporter = true }
                Button("Importar CSV Strong/Hevy") { showingCSVImporter = true }
                if let summary = store.lastImportSummary {
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Button("Borrar mis datos", role: .destructive) {
                    confirmReset = true
                }
            }
        }
        .listStyle(.insetGrouped)
        .ogListChrome()
        .ogPinnedTransparentNav("Ajustes")
        .alert("Restaurar compras", isPresented: Binding(
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
                message: "Volverás a la pantalla de Sign in with Apple. Tus datos locales se conservan.",
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
        }
        .sheet(isPresented: $confirmReset) {
            OGConfirmSheet(
                systemImage: "trash.circle.fill",
                title: "¿Borrar datos?",
                message: "Se borran rutinas, entrenos y pesos. El catálogo de ejercicios se mantiene.",
                confirmTitle: "Borrar todo",
                onConfirm: {
                    store.resetUserData()
                    confirmReset = false
                },
                onCancel: { confirmReset = false }
            )
        }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
            if case .success(let url) = result,
               url.startAccessingSecurityScopedResource(),
               let data = try? Data(contentsOf: url),
               let imported = LocalStore.shared.importJSON(data) {
                store.state = imported
                store.persist()
                url.stopAccessingSecurityScopedResource()
            }
        }
        .fileImporter(
            isPresented: $showingCSVImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText]
        ) { result in
            if case .success(let url) = result,
               url.startAccessingSecurityScopedResource(),
               let data = try? Data(contentsOf: url),
               let text = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .isoLatin1) {
                _ = store.importCSV(text)
                url.stopAccessingSecurityScopedResource()
            }
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

    private var healthNeedsAttention: Bool {
        !health.isAuthorized || !HealthRecoveryStore.shared.pendingHealthItems.isEmpty
    }

    private var notificationsStatusLabel: String {
        switch notificationsStatus {
        case .authorized, .provisional, .ephemeral: return "Permitidas"
        case .denied: return "Denegadas"
        default: return "Pendiente"
        }
    }

    private func refreshNotificationsStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationsStatus = settings.authorizationStatus
    }

    /// iCloud + perfil Business (nombre/avatar) + espejo privado de entrenamientos.
    private func syncEverything() async {
        guard !isSyncingEverything else { return }
        isSyncingEverything = true
        syncIconSpinning = false
        // Arranca la rotación en el siguiente frame para que `repeatForever` anime bien.
        await Task.yield()
        syncIconSpinning = true
        defer {
            syncIconSpinning = false
            isSyncingEverything = false
        }

        await store.refreshFromiCloud()
        if businessAuth.isConnected {
            await businessAuth.syncPublicProfile(
                displayName: store.state.settings.profileDisplayName ?? appleAuth.displayName,
                avatarJPEG: store.state.settings.profileAvatarJPEG
            )
            await businessData.refresh()
            await workoutSync.sync(store: store)
        }
        let now = Date()
        lastFullSyncAt = now
        UserDefaults.standard.set(now.timeIntervalSince1970, forKey: "repera.settings.lastFullSyncAt")
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

    private func exportBackup() {
        guard let data = LocalStore.shared.exportJSON(store.state) else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("repera-backup.json")
        try? data.write(to: url)
        exportURL = url
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
        .ogPinnedTransparentNav("Rotación")
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
