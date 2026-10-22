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
    @State private var exportURL: URL?
    @State private var showingImporter = false
    @State private var showingCSVImporter = false
    @State private var confirmReset = false
    @State private var photoItem: PhotosPickerItem?
    @State private var isPhotoPickerPresented = false
    @State private var restoreMessage: String?
    @State private var notificationsStatus: UNAuthorizationStatus = .notDetermined
    @State private var confirmSignOut = false
    @State private var isSyncingEverything = false
    @State private var syncIconSpinning = false
    @State private var syncFeedback: String?
    @AppStorage("repera.settings.lastFullSyncAt") private var lastFullSyncAt: Double = 0
 
    var body: some View {
        @Bindable var store = store
        Form {
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
                            Text(appleAuth.isSignedIn ? "Sesión iniciada" : "Sin sesión")
                            if let email = appleAuth.email, !email.isEmpty {
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

                Button {
                    Task { await syncEverything() }
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.body.weight(.semibold))
                            .frame(width: 24, height: 25)
                            .rotationEffect(.degrees(syncIconSpinning ? 360 : 0))
                            .animation(
                                syncIconSpinning
                                    ? .linear(duration: 0.85).repeatForever(autoreverses: false)
                                    : .default,
                                value: syncIconSpinning
                            )
                        VStack(alignment: .leading, spacing: 3) {
                            Text(isSyncingEverything ? "Sincronizando…" : "Sincronizar ahora")
                                .font(.body)
                            if let syncFeedback {
                                Text(syncFeedback)
                                    .font(.caption)
                                    .foregroundStyle(OG.red)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            } else if lastFullSyncAt > 0 {
                                Text("Última actualización: \(Date(timeIntervalSince1970: lastFullSyncAt).formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(OG.label2)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            if workoutSync.restoredBlockSnapshots > 0 {
                                Text("\(workoutSync.restoredBlockSnapshots) entrenamientos antiguos recuperaron sus bloques originales.")
                                    .font(.caption)
                                    .foregroundStyle(OG.label2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            if workoutSync.incompleteHistoricalWODCount > 0 {
                                Text("\(workoutSync.incompleteHistoricalWODCount) WOD antiguos aún no tienen el detalle original de bloques en Supabase. No se inventarán comparaciones.")
                                    .font(.caption)
                                    .foregroundStyle(OG.label2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .layoutPriority(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(OG.label)
                }
                .disabled(isSyncingEverything)

                Button("Cerrar sesión", role: .destructive) {
                    confirmSignOut = true
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
                NavigationLink {
                    AIAccessView()
                } label: {
                    Label("Acceso IA", systemImage: "brain.head.profile")
                        .foregroundStyle(OG.label)
                }
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

        syncFeedback = nil
        await store.refreshFromiCloud()
        guard store.syncPhase == .ready else {
            syncFeedback = "No se ha confirmado iCloud."
            return
        }
        if !businessAuth.isConnected {
            await businessAuth.restoreSession()
            if !businessAuth.isConnected {
                _ = businessAuth.connectFromCachedSessionIfPossible()
            }
        }
        guard businessAuth.isConnected else {
            syncFeedback = "iCloud sincronizado. La sesión de Supabase no está disponible con esta cuenta Apple; vuelve a iniciar sesión para recuperar la conexión."
            return
        }
        await businessAuth.syncPublicProfile(
            displayName: store.state.settings.profileDisplayName ?? appleAuth.displayName,
            avatarJPEG: store.state.settings.profileAvatarJPEG
        )
        await businessData.refresh()
        // App launch, foreground handlers and Realtime can trigger the same
        // stores concurrently. Wait for the in-flight tasks instead of
        // incorrectly reporting an operation as failed due to an active sync.
        for _ in 0..<80 {
            if !workoutSync.isSyncing,
               !AITrainingInboxStore.shared.isSyncing,
               !AITrainingContextStore.shared.isSyncing {
                break
            }
            try? await Task.sleep(for: .milliseconds(150))
        }
        let workoutsUploaded = await workoutSync.sync(store: store)
        let plansSynced = await AITrainingInboxStore.shared.sync(store: store)
        let calendarSynced = await AITrainingContextStore.shared.syncCalendar(store: store)
        let customExercisesSynced = await AIChangeRequestStore.shared.syncCustomExercises(store: store)
        await AIChangeRequestStore.shared.refresh(store: store)
        // Perfil público es opcional: un error al subir una foto jamás bloquea
        // el historial deportivo. El diagnóstico se comunica en Cuenta.
        var incomplete: [String] = []
        if !workoutsUploaded {
            incomplete.append(workoutSync.lastError ?? "entrenamientos pendientes (iCloud o Supabase no están listos)")
        }
        if !plansSynced {
            incomplete.append(AITrainingInboxStore.shared.lastError ?? "propuestas de IA pendientes")
        }
        if !calendarSynced {
            incomplete.append("calendario deportivo pendiente de envío")
        }
        if !customExercisesSynced {
            incomplete.append("catálogo privado de ejercicios pendiente de envío")
        }
        if let profileError = businessAuth.profileMigrationErrorMessage {
            incomplete.append(profileError)
        }
        if incomplete.isEmpty {
            lastFullSyncAt = Date().timeIntervalSince1970
            syncFeedback = nil
        } else {
            syncFeedback = "iCloud actualizado. Pendiente: " + incomplete.joined(separator: " · ")
        }
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
