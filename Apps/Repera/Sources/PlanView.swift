import ReperaDomain
import Supabase
import SwiftUI
import UniformTypeIdentifiers

enum DiarioSection: String, CaseIterable, Identifiable {
    case schedule
    case routines

    var id: String { rawValue }

    var title: String {
        switch self {
        case .schedule: return "Programado"
        case .routines: return "Rutinas"
        }
    }
}

/// Diario: Programado (personal + lo publicado por el entrenador/centro) y Rutinas.
struct PlanView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(BusinessDataStore.self) private var businessData
    @Environment(BusinessAuthStore.self) private var businessAuth
    @State private var aiPrograms: [AIProgramSummary] = []
    @Binding var section: DiarioSection
    var onOpenRoutine: (Routine) -> Void = { _ in }
    @State private var editing: Routine?
    @State private var isCreating = false
    @State private var confirmClearSchedule = false
    @State private var assigningDay: Int?
    @State private var copyWeekFlash: Int?

    private struct AIProgramSummary: Decodable, Identifiable {
        let id: UUID
        let title: String
        let startDate: String
        let startTimeZone: String?
        let durationWeeks: Int
        let status: String
        enum CodingKeys: String, CodingKey {
            case id, title, status
            case startDate = "start_date"
            case startTimeZone = "start_time_zone"
            case durationWeeks = "duration_weeks"
        }
    }

    @MainActor
    private func refreshAIPrograms() async {
        guard businessAuth.isConnected, let client = businessAuth.apiClient else {
            aiPrograms = []
            return
        }
        do {
            let session = try await client.auth.session
            guard !session.isExpired else { return }
            let rows: [AIProgramSummary] = try await client.from("athlete_training_programs")
                .select("id,title,start_date,start_time_zone,duration_weeks,status")
                .eq("owner_id", value: session.user.id.uuidString)
                .in("status", values: ["active","proposed","paused"])
                .order("start_date", ascending: false).limit(30).execute().value
            guard businessAuth.apiClient?.auth.currentSession?.user.id == session.user.id else { return }
            aiPrograms = rows
        } catch {
            // Calendar remains usable offline; return to read on next foreground.
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Sección", selection: $section) {
                        ForEach(DiarioSection.allCases) { tab in
                            Text(tab.title).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .ogSegmentedListRow()
                }

                switch section {
                case .schedule:
                    scheduleContent
                case .routines:
                    routinesContent
                }
            }
            .listStyle(.insetGrouped)
            .ogListChrome()
            .refreshable {
                await businessData.refresh()
                await refreshAIPrograms()
            }
            .task { await refreshAIPrograms() }
            .onChange(of: businessAuth.isConnected) { _, _ in
                Task { await refreshAIPrograms() }
            }
            .ogFixedTopBar("Diario") {
                if section == .schedule {
                    Menu {
                        Button {
                            let n = store.copyPreviousWeekSchedule()
                            copyWeekFlash = n
                        } label: {
                            Label("Copiar semana pasada", systemImage: "calendar.badge.clock")
                        }
                        if !store.plannedRoutines.isEmpty {
                            Button(role: .destructive) {
                                confirmClearSchedule = true
                            } label: {
                                Label("Vaciar programación", systemImage: "calendar.badge.minus")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: OG.toolbarGlassIcon, weight: .semibold))
                            .foregroundStyle(OG.label)
                            .frame(width: OG.toolbarGlassSize, height: OG.toolbarGlassSize)
                            .contentShape(Circle())
                            .glassEffect(.regular.interactive(), in: .circle)
                    }
                    .accessibilityLabel("Más opciones")
                }
            }
            .navigationDestination(item: $editing) { routine in
                DayEditorView(
                    routine: routine,
                    mode: .plan(isNew: isCreating),
                    embedsNavigationStack: false,
                    usesPageCloseHeader: true
                )
                .onDisappear { isCreating = false }
            }
            .sheet(item: Binding(
                get: { assigningDay.map { WeekdayBox(day: $0) } },
                set: { assigningDay = $0?.day }
            )) { box in
                DayOverrideSheet(
                    isoWeekday: box.day,
                    dayLabel: CalendarHelpers.weekdayName(box.day),
                    onCreateNew: {
                        isCreating = true
                        editing = Routine(
                            title: CalendarHelpers.weekdayName(box.day),
                            weekday: box.day,
                            scheduledDate: nil,
                            blocks: [.strength()]
                        )
                    }
                )
            }
            .sheet(isPresented: $confirmClearSchedule) {
                OGConfirmSheet(
                    systemImage: "calendar.badge.minus",
                    title: "¿Vaciar programación?",
                    message: "Se quitan las rutinas de todos los días. Las plantillas en Rutinas se conservan. Los entrenos ya registrados se mantienen.",
                    confirmTitle: "Vaciar",
                    onConfirm: {
                        store.clearWeeklySchedule()
                        confirmClearSchedule = false
                    },
                    onCancel: { confirmClearSchedule = false }
                )
            }
            .alert(
                "Semana copiada",
                isPresented: Binding(
                    get: { copyWeekFlash != nil },
                    set: { if !$0 { copyWeekFlash = nil } }
                )
            ) {
                Button("OK", role: .cancel) { copyWeekFlash = nil }
            } message: {
                let n = copyWeekFlash ?? 0
                Text(n == 0
                     ? "No había entrenos sueltos en la semana ISO anterior."
                     : "Se añadieron \(n) entreno\(n == 1 ? "" : "s") a esta semana.")
            }
        }
    }

    // MARK: - Programado (Lu–Do + sesiones del entrenador/centro)

    @ViewBuilder
    private var scheduleContent: some View {
        if !aiPrograms.isEmpty {
            Section {
                ForEach(aiPrograms) { program in
                    NavigationLink {
                        AITrainingProgramsView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .foregroundStyle(OG.accent)
                                .frame(width: 42, height: 42)
                                .background(OG.surface2, in: RoundedRectangle(cornerRadius: 10))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(program.title).font(.headline).foregroundStyle(OG.label)
                                Text("\(program.durationWeeks) semanas · \(program.startDate)" +
                                     (program.startTimeZone.map { " · \($0)" } ?? "") +
                                     " · \(program.status == "active" ? "Activo" : program.status == "paused" ? "En pausa" : "Propuesto")")
                                    .font(.caption).foregroundStyle(OG.label2)
                            }
                        }
                    }
                }
            } header: {
                Text("De tu entrenador IA")
            }
        }
        if !businessData.trainingSessions.isEmpty {
            Section {
                ForEach(businessData.trainingSessions) { session in
                    BusinessProfessionalSessionCard(
                        session: session,
                        centerName: businessData.centerName(session.orgId)
                    )
                    .ogCardListRow(top: 6, bottom: 6)
                }
            } header: {
                Text("De tu entrenador o centro")
            }
        }

        // Diario únicamente muestra su plan semanal y publicaciones profesionales.
        // Rutinas con scheduledDate (entrenos sueltos de Inicio/IA) NO pertenecen
        // necesariamente a la programación del Diario y no deben aparecer aquí.
        Section {
            ForEach(1...7, id: \.self) { day in
                let routine = store.routine(forWeekday: day)
                Button {
                    if let routine {
                        onOpenRoutine(routine)
                    } else {
                        assigningDay = day
                    }
                } label: {
                    HStack(alignment: .top, spacing: 14) {
                        Text(String(CalendarHelpers.weekdayName(day).prefix(2)).uppercased())
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(routine == nil ? OG.label3 : OG.onAccent)
                            .frame(width: 44, height: 44)
                            .background(
                                routine == nil ? OG.surface3 : OG.accent,
                                in: Circle()
                            )
                            .overlay {
                                if routine != nil {
                                    Circle()
                                        .strokeBorder(OG.accent.opacity(0.35), lineWidth: 3)
                                        .padding(-3)
                                }
                            }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(CalendarHelpers.weekdayName(day))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(OG.label)

                            if let routine {
                                Text(routine.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(OG.label2)
                                    .lineLimit(1)
                                scheduleChips(for: routine)
                            } else {
                                Text("Día libre · toca para asignar")
                                    .font(.system(size: 13))
                                    .foregroundStyle(OG.label3)
                            }
                        }
                        Spacer(minLength: 8)
                        Image(systemName: routine == nil ? "moon.fill" : "chevron.right")
                            .font(.system(size: routine == nil ? 14 : 13, weight: .semibold))
                            .foregroundStyle(routine == nil ? OG.label3.opacity(0.7) : OG.label3)
                            .padding(.top, 12)
                    }
                    .padding(.vertical, 6)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    if let routine {
                        OGSwipeDeleteButton(systemImage: "trash", accessibilityLabel: "Quitar del día", tint: OG.red) {
                            store.assignRoutine(routine.id, toWeekday: nil)
                        }
                    }
                }
            }
        } header: {
            Text("Tu programación")
        }
    }

    @ViewBuilder
    private func scheduleChips(for routine: Routine) -> some View {
        let strength = routine.blocks.filter { $0.kind == .strength }.flatMap(\.exercises).count
        let wods = routine.blocks.filter { $0.kind == .wod }.count
        let time = routine.normalizedScheduledTimeMinutes.map { SpanishDate.time(minutesFromMidnight: $0) }

        if strength == 0, wods == 0, time == nil {
            scheduleChip("Vacía", tint: OG.label3)
        } else {
            HStack(spacing: 6) {
                if let time {
                    scheduleChip(time, tint: OG.blue)
                }
                if strength > 0 {
                    scheduleChip("\(strength) ej.", tint: OG.accent)
                }
                if wods > 0 {
                    scheduleChip("\(wods) WOD", tint: OG.orange)
                }
            }
        }
    }

    private func scheduleChip(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(OG.surface2, in: Capsule())
    }

    // MARK: - Rutinas

    @ViewBuilder
    private var routinesContent: some View {
        if store.libraryRoutines.isEmpty {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(OG.accent)
                    Text("Sin rutinas")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(OG.label)
                    Text("Crea plantillas reutilizables (Push, Pull, Piernas…) y asígnalas en Programado.")
                        .font(.system(size: 14))
                        .foregroundStyle(OG.label2)
                        .multilineTextAlignment(.center)
                    newRoutineGreenButton
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .listRowBackground(Color.clear)
            }
        } else {
            Section {
                ForEach(store.libraryRoutines) { routine in
                    Button {
                        isCreating = false
                        editing = routine
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: routine.isFavorite ? "star.fill" : "figure.strengthtraining.traditional")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(routine.isFavorite ? OG.yellow : OG.accent)
                                .frame(width: 40, height: 40)
                                .background(OG.surface2, in: Circle())
                            VStack(alignment: .leading, spacing: 3) {
                                Text(routine.title)
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(OG.label)
                                Text(librarySubtitle(routine))
                                    .font(.system(size: 13))
                                    .foregroundStyle(OG.label2)
                            }
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(OG.label3)
                        }
                        .padding(.vertical, 4)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        OGSwipeDeleteButton {
                            store.deleteRoutine(routine.id)
                        }
                        if routine.weekday != nil {
                            Button {
                                store.assignRoutine(routine.id, toWeekday: nil)
                            } label: {
                                Image(systemName: "calendar.badge.minus")
                            }
                            .tint(OG.orange)
                            .accessibilityLabel("Desasignar")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            store.setRoutineFavorite(routine.id, isFavorite: !routine.isFavorite)
                        } label: {
                            Image(systemName: routine.isFavorite ? "star.slash" : "star")
                        }
                        .tint(OG.yellow)
                        .accessibilityLabel(routine.isFavorite ? "Quitar favorito" : "Favorito")
                    }
                }
            }

            Section {
                newRoutineGreenButton
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowSeparator(.hidden)
            }
        }
    }

    private var newRoutineGreenButton: some View {
        Button(action: createNewRoutine) {
            Text("Nueva rutina")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(OG.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(OG.accent, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func createNewRoutine() {
        let decision = subscriptions.canCreateLibraryRoutine(isNew: true)
        guard decision.allowed else {
            subscriptions.presentPaywall(decision.paywallContext, feature: .unlimitedRoutines)
            return
        }
        isCreating = true
        editing = Routine(title: "Nueva rutina", weekday: nil, scheduledDate: nil, blocks: [.strength()])
    }

    private func librarySubtitle(_ routine: Routine) -> String {
        var parts = [routineSubtitle(routine)]
        if let day = routine.weekday {
            parts.append(CalendarHelpers.weekdayName(day))
        } else {
            parts.append("Sin día")
        }
        return parts.joined(separator: " · ")
    }

    private func routineSubtitle(_ routine: Routine) -> String {
        let strength = routine.blocks.filter { $0.kind == .strength }.flatMap(\.exercises).count
        let wods = routine.blocks.filter { $0.kind == .wod }.count
        var parts: [String] = []
        if let minutes = routine.normalizedScheduledTimeMinutes {
            parts.append(SpanishDate.time(minutesFromMidnight: minutes))
        }
        if strength > 0 { parts.append("\(strength) ej.") }
        if wods > 0 { parts.append("\(wods) WOD") }
        if parts.isEmpty { parts.append("Vacía") }
        return parts.joined(separator: " · ")
    }

    private struct WeekdayBox: Identifiable {
        var day: Int
        var id: Int { day }
    }
}

// MARK: - Editor de rutina / día / crear entreno

/// Chrome del editor: página push → volver + check; modal → solo check (swipe para cerrar).
private struct DayEditorChromeModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let usesPageCloseHeader: Bool
    let embedsNavigationStack: Bool
    let canConfirm: Bool
    let confirmTitle: String
    let onConfirm: () -> Void

    func body(content: Content) -> some View {
        if usesPageCloseHeader {
            content
                .ogPinnedTransparentNav(title)
                // Los botones no comparten cápsula ni color: volver neutro,
                // confirmar verde al otro lado del topbar.
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { dismiss() } label: {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(OG.label)
                        }
                        .tint(OG.label)
                        .accessibilityLabel("Volver")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        confirmButton
                    }
                }
        } else {
            content
                .ogFixedTopBar(title) { confirmButton }
                .navigationBarBackButtonHidden(embedsNavigationStack)
        }
    }

    @ViewBuilder
    private var confirmButton: some View {
        if usesPageCloseHeader {
            // La toolbar de iOS 27 dibuja el círculo; no aplicar otro glass manual.
            Button(action: onConfirm) {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(OG.onAccent)
            }
            .buttonStyle(.borderedProminent)
            .tint(OG.accent)
            .accessibilityLabel(confirmTitle)
            .opacity(canConfirm ? 1 : 0.4)
            .disabled(!canConfirm)
        } else {
            OGToolbarGlassButton(
                systemName: "checkmark",
                accessibilityLabel: confirmTitle,
                tint: .white,
                appliesGlass: true,
                glassTint: OG.accent,
                action: onConfirm
            )
            .opacity(canConfirm ? 1 : 0.4)
            .disabled(!canConfirm)
        }
    }
}

enum DayEditorMode: Equatable {
    case plan(isNew: Bool)
    /// Entreno suelto de un día concreto (Inicio); no forma parte del plan semanal.
    case oneOff(isNew: Bool)
    case session
    case favorite(isNew: Bool)
}

struct DayEditorView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(\.dismiss) private var dismiss
    @State var routine: Routine
    var mode: DayEditorMode
    var onSessionStarted: (() -> Void)? = nil
    /// Cierre explícito cuando se presenta como página (push), no modal.
    var onClose: (() -> Void)? = nil
    /// Si no es nil, el check aplica el draft y cierra sin guardar en el store (revisión de pizarra).
    var onApplyDraft: ((Routine) -> Void)? = nil
    /// Edición de una sesión terminada usando exactamente los mismos bloques/reordenación.
    var onApplyCompleted: ((Routine, WorkoutSession) -> Void)? = nil
    var completedSession: WorkoutSession? = nil
    var embedsNavigationStack: Bool = true
    /// Página push (Entreno → Editar): título large + chevron volver; sin X.
    var usesPageCloseHeader: Bool = false
    @State private var pickExerciseForBlock: UUID?
    @State private var pickMovementForBlock: UUID?
    @State private var createFreeMovementForBlock: UUID?
    @State private var showRoutinePicker = false
    @State private var showWODCatalog = false
    @State private var selectFormatForBlock: UUID?
    @State private var saveAsFavorite = false
    @FocusState private var focusedFormatField: OGSetFieldID?
    @State private var showsReorder = false
    @State private var completedDetails: WorkoutSession?
    @State private var scaledInputDrafts: [String: String] = [:]

    /// La ruta de Historial abre directamente una sesión finalizada. El diseño
    /// no debe esperar a que onAppear inicialice el estado para saber si muestra
    /// un score global o series: eso enseñaba el formulario de prescripción.
    private var isEditingCompletedWorkout: Bool {
        onApplyCompleted != nil && completedSession != nil
    }

    private var completedWorkoutDraft: WorkoutSession? {
        completedDetails ?? completedSession
    }

    private func ensureCompletedWorkoutDraft() {
        if completedDetails == nil { completedDetails = completedSession }
    }

    var body: some View {
        Group {
            if embedsNavigationStack {
                NavigationStack { editorForm }
            } else {
                editorForm
            }
        }
    }

    private var editorForm: some View {
        Form {
            Section {
                TextField(nameFieldPlaceholder, text: $routine.title)
                switch mode {
                case .plan:
                    Picker("Día en Programado", selection: Binding(
                        get: { routine.weekday ?? 0 },
                        set: { routine.weekday = $0 == 0 ? nil : $0 }
                    )) {
                        Text("Sin asignar").tag(0)
                        ForEach(1...7, id: \.self) { day in
                            Text(CalendarHelpers.weekdayName(day)).tag(day)
                        }
                    }
                    scheduledTimeControls
                    Picker("Progresión (fuerza)", selection: $routine.progression) {
                        ForEach(ProgressionPolicy.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }
                    Toggle("Favorito", isOn: $routine.isFavorite)
                case .oneOff:
                    if let date = routine.scheduledDate {
                        Text(SpanishDate.long(date))
                            .foregroundStyle(OG.label2)
                    }
                    scheduledTimeControls
                    Toggle("Favorito", isOn: $routine.isFavorite)
                case .favorite:
                    Toggle("Favorito", isOn: $routine.isFavorite)
                        .disabled(true)
                    Picker("También en Programado", selection: Binding(
                        get: { routine.weekday ?? 0 },
                        set: { routine.weekday = $0 == 0 ? nil : $0 }
                    )) {
                        Text("Solo favorito").tag(0)
                        ForEach(1...7, id: \.self) { day in
                            Text(CalendarHelpers.weekdayName(day)).tag(day)
                        }
                    }
                    scheduledTimeControls
                case .session:
                    if onApplyDraft == nil {
                        Toggle("Favorito", isOn: $saveAsFavorite)
                    }
                }
            } footer: {
                switch mode {
                case .session:
                    Text(onApplyCompleted != nil
                         ? "Edita los datos registrados sin modificar la rutina programada."
                         : onApplyDraft == nil
                            ? "Solo empieza la sesión. El plan semanal se gestiona en Diario."
                            : "Los cambios se aplican al revisar la pizarra; aún no se guarda el día.")
                case .favorite:
                    Text("Los favoritos se reutilizan desde Crear. Opcionalmente puedes asignarlos a un día en Programado.")
                case .oneOff:
                    EmptyView()
                case .plan:
                    Text("La rutina es reutilizable. En Programado puedes cambiar el día sin editar el contenido.")
                }
            }

            if onApplyCompleted != nil {
                Section {
                    DatePicker("Inicio", selection: completedDateBinding(isEnd: false),
                               displayedComponents: [.date, .hourAndMinute])
                        .tint(OG.accent)
                    DatePicker("Fin", selection: completedDateBinding(isEnd: true),
                               displayedComponents: [.date, .hourAndMinute])
                        .tint(OG.accent)
                    if completedDetails?.routePoints.isEmpty == true {
                        WorkoutPlacePickerRow(pin: Binding(
                            get: { completedDetails?.locationPin },
                            set: { completedDetails?.locationPin = $0 }
                        ))
                    }
                    TextField("Notas del entreno", text: Binding(
                        get: { completedDetails?.notes ?? "" },
                        set: { completedDetails?.notes = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(2...5)
                } header: {
                    Text("Datos del entreno realizado")
                }
            }

            ForEach(Array(routine.blocks.enumerated()), id: \.element.id) { index, block in
                Section {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 10) {
                            TextField("Nombre", text: $routine.blocks[index].title)
                                .font(.system(size: 16, weight: .semibold))
                            Menu {
                                Button {
                                    showsReorder = true
                                } label: {
                                    Label("Reordenar", systemImage: "arrow.up.arrow.down")
                                }
                                Button(role: .destructive) {
                                    routine.blocks.removeAll { $0.id == block.id }
                                } label: {
                                    Label("Eliminar bloque", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(OG.label)
                                    .frame(width: 38, height: 38)
                                    .glassEffect(.regular.interactive(), in: .circle)
                            }
                            .accessibilityLabel("Opciones del bloque \(block.title)")
                        }
                        formatSettings(index: index)
                        completedScoreEditor(for: block)
                    }
                    .listRowSeparator(.hidden)
                    if block.kind == .strength {
                        if isEditingCompletedWorkout,
                           let format = block.wodFormat,
                           format.resultCapture != .perMovementSets {
                            completedStrengthPrescription(index: index)
                        } else {
                            strengthBlock(index: index)
                        }
                    } else {
                        wodBlock(index: index)
                    }
                } header: {
                    Text(block.title)
                }
            }

            Section {
                Button {
                    routine.blocks.append(.strength(title: nextDefaultBlockTitle()))
                } label: {
                    Label("Añadir bloque", systemImage: "square.stack.3d.up")
                }
                Button {
                    showWODCatalog = true
                } label: {
                    Label("Elegir WOD", systemImage: "list.bullet.rectangle.portrait")
                }
                if !importableRoutines.isEmpty {
                    Button {
                        showRoutinePicker = true
                    } label: {
                        Label("Añadir rutina", systemImage: "list.bullet.rectangle")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .ogListChrome()
        .onAppear {
            ensureCompletedWorkoutDraft()
            ensureStrengthPlannedSets()
        }
        .reorderContainer(for: RoutineExercise.self, in: UUID.self) { difference in
            let blockId = difference.destination.collectionID
            guard let blockIndex = routine.blocks.firstIndex(where: { $0.id == blockId }) else { return }
            applyStrengthExerciseReorder(to: &routine.blocks[blockIndex].exercises, difference: difference)
        }
        .navigationDestination(isPresented: $showsReorder) {
            reorderSheet
        }
        .modifier(DayEditorChromeModifier(
            title: navTitle,
            usesPageCloseHeader: usesPageCloseHeader,
            embedsNavigationStack: embedsNavigationStack,
            canConfirm: canConfirm,
            confirmTitle: confirmTitle,
            onConfirm: confirm
        ))
        // Pickers de creación: push nativo horizontal con volver en topbar.
        .navigationDestination(item: $pickExerciseForBlock) { blockID in
            ExercisePickerView(embedsNavigationStack: false) { exercise in
                if let idx = routine.blocks.firstIndex(where: { $0.id == blockID }) {
                    let style = exercise.loggingStyle
                    let amount = style == .machineWork
                        ? (exercise.defaultQuantityUnit == .meters ? 500 : 15)
                        : (exercise.isMobility ? (exercise.isMobilityHold ? 1 : 8) : (style == .repsAndTime ? 50 : 8))
                    let count = style.usesDuration ? 1 : 3
                    let sets = (0..<count).map { _ in
                        PlannedSet(targetReps: amount, targetWeightKg: nil,
                            targetDurationSeconds: exercise.isMobility ? (exercise.isMobilityHold ? 30 : 60) : nil)
                    }
                    routine.blocks[idx].exercises.append(
                        RoutineExercise(
                            exerciseId: exercise.id,
                            plannedSets: sets,
                            quantityUnit: style == .machineWork ? exercise.defaultQuantityUnit : nil
                        )
                    )
                }
                pickExerciseForBlock = nil
            }
        }
        .navigationDestination(item: $pickMovementForBlock) { blockID in
            ExercisePickerView(embedsNavigationStack: false) { exercise in
                if let idx = routine.blocks.firstIndex(where: { $0.id == blockID }) {
                    routine.blocks[idx].movements.append(
                        WODMovement(exerciseId: exercise.id, name: exercise.name, reps: 10)
                    )
                }
                pickMovementForBlock = nil
            }
        }
        .navigationDestination(item: $createFreeMovementForBlock) { blockID in
            FreeWODMovementCreatePage { movement in
                if let idx = routine.blocks.firstIndex(where: { $0.id == blockID }) {
                    routine.blocks[idx].movements.append(movement)
                }
                createFreeMovementForBlock = nil
            }
        }
        .sheet(isPresented: $showRoutinePicker) {
            RoutineImportPickerSheet(
                routines: importableRoutines,
                onPick: { source in
                    routine.blocks.append(contentsOf: source.blocks.map { $0.duplicatingContent() })
                    showRoutinePicker = false
                },
                onCancel: { showRoutinePicker = false }
            )
        }
        .navigationDestination(isPresented: $showWODCatalog) {
            WODCatalogPickerView(embedsNavigationStack: false) { template in
                routine.blocks.append(template.makeBlock())
                if routine.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || routine.title == "Entreno"
                    || routine.title == "Nuevo entreno" {
                    routine.title = template.name
                }
                showWODCatalog = false
            }
        }
        .navigationDestination(item: $selectFormatForBlock) { blockID in
            WODFormatPickerPage { format in
                if let index = routine.blocks.firstIndex(where: { $0.id == blockID }) {
                    setWODFormat(format, at: index)
                }
                selectFormatForBlock = nil
            }
        }
    }

    /// Ordenación por arrastre: bloque → bloque, ejercicio → posición en cualquier bloque.
    /// La lista indentada hace evidente la jerarquía y mantiene el orden del modelo.
    private var reorderSheet: some View {
        // ScrollView en lugar de List: List consume los gestos drag y no expone
        // huecos reales como destinos de drop entre filas.
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(routine.blocks) { block in
                    reorderBlockDrop(before: block.id)
                    VStack(spacing: 0) {
                        HStack(spacing: 10) {
                            Image(systemName: "line.3.horizontal")
                                .foregroundStyle(OG.label3)
                                .accessibilityHidden(true)
                            Text(block.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(OG.label)
                            Spacer(minLength: 6)
                            Text(block.wodFormat?.displayName ?? "Libre")
                                .font(.caption)
                                .foregroundStyle(OG.label2)
                            Menu {
                                Button("Subir bloque", systemImage: "arrow.up") {
                                    moveBlock(block.id, offset: -1)
                                }
                                .disabled(routine.blocks.first?.id == block.id)
                                Button("Bajar bloque", systemImage: "arrow.down") {
                                    moveBlock(block.id, offset: 1)
                                }
                                .disabled(routine.blocks.last?.id == block.id)
                                Divider()
                                Button("Eliminar bloque", systemImage: "trash", role: .destructive) {
                                    routine.blocks.removeAll { $0.id == block.id }
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.system(size: 19))
                                    .foregroundStyle(OG.accent)
                                    .frame(width: 40, height: 44)
                            }
                            .accessibilityLabel("Opciones de \(block.title)")
                        }
                        .frame(minHeight: 50)
                        .contentShape(Rectangle())
                        .draggable("block:\(block.id.uuidString)")

                        if block.kind == .strength {
                            ForEach(block.exercises) { exercise in
                                reorderExerciseDrop(into: block.id, before: exercise.id)
                                reorderExerciseRow(
                                    store.state.exercises.first(where: { $0.id == exercise.exerciseId })?.name ?? "Ejercicio",
                                    blockID: block.id,
                                    itemID: exercise.id,
                                    type: "exercise"
                                )
                            }
                        } else {
                            ForEach(block.movements) { move in
                                reorderExerciseDrop(into: block.id, before: move.id)
                                reorderExerciseRow(
                                    move.isRest ? "Descanso" : move.name,
                                    blockID: block.id,
                                    itemID: move.id,
                                    type: "movement"
                                )
                            }
                        }
                        reorderExerciseDrop(into: block.id, before: nil)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
                }
                reorderBlockDrop(before: nil)
            }
            .padding(.horizontal, OG.pad)
            .padding(.vertical, 12)
        }
        .background(OG.bg)
        .navigationTitle("Reordenar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Listo") { showsReorder = false }
                    .fontWeight(.semibold)
                    .foregroundStyle(OG.accent)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Text("Arrastra hasta la línea entre dos elementos. Los menús también permiten mover o eliminar.")
                .font(.footnote)
                .foregroundStyle(OG.label2)
                .padding(.horizontal, OG.pad)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(OG.bg)
        }
    }

    private func reorderBlockDrop(before id: UUID?) -> some View {
        RoutineReorderDropSlot {
            token in
            guard token.hasPrefix("block:") else { return false }
            withAnimation(.smooth) {
                reorderBlockToken(token, before: id)
            }
            return true
        }
    }

    private func reorderExerciseDrop(into blockID: UUID, before id: UUID?) -> some View {
        RoutineReorderDropSlot {
            token in
            guard token.hasPrefix("exercise:") || token.hasPrefix("movement:") else { return false }
            withAnimation(.smooth) {
                applyReorder(token, into: blockID, before: id)
            }
            return true
        }
    }

    private func reorderExerciseRow(
        _ name: String,
        blockID: UUID,
        itemID: UUID,
        type: String
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.turn.down.right")
                .font(.system(size: 12))
                .foregroundStyle(OG.label3)
                .padding(.leading, 12)
            Text(name)
                .font(.system(size: 14))
                .foregroundStyle(OG.label)
            Spacer(minLength: 8)
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 12))
                .foregroundStyle(OG.label3)
            Menu {
                Button("Subir ejercicio", systemImage: "arrow.up") {
                    moveExercise(type: type, blockID: blockID, itemID: itemID, offset: -1)
                }
                Button("Bajar ejercicio", systemImage: "arrow.down") {
                    moveExercise(type: type, blockID: blockID, itemID: itemID, offset: 1)
                }
                if routine.blocks.count > 1 {
                    Menu {
                        ForEach(routine.blocks.filter { $0.id != blockID }) { target in
                            Button(target.title) {
                                withAnimation(.smooth) {
                                    applyReorder(
                                        "\(type):\(blockID.uuidString):\(itemID.uuidString)",
                                        into: target.id,
                                        before: nil
                                    )
                                }
                            }
                        }
                    } label: {
                        Label("Mover a otro bloque", systemImage: "arrowshape.turn.up.right")
                    }
                }
                Divider()
                Button("Eliminar ejercicio", systemImage: "trash", role: .destructive) {
                    deleteReorderExercise(type: type, blockID: blockID, itemID: itemID)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(OG.accent)
                    .frame(width: 40, height: 44)
            }
            .accessibilityLabel("Opciones de \(name)")
        }
        .padding(.leading, 8)
        .frame(minHeight: 46)
        .contentShape(Rectangle())
        .draggable("\(type):\(blockID.uuidString):\(itemID.uuidString)")
    }

    private func deleteReorderExercise(type: String, blockID: UUID, itemID: UUID) {
        guard let index = routine.blocks.firstIndex(where: { $0.id == blockID }) else { return }
        withAnimation(.smooth) {
            if type == "exercise" {
                routine.blocks[index].exercises.removeAll { $0.id == itemID }
            } else if type == "movement" {
                routine.blocks[index].movements.removeAll { $0.id == itemID }
            }
        }
    }

    private func reorderBlockToken(_ token: String, before destinationID: UUID?) {
        let parts = token.split(separator: ":")
        guard parts.count == 2,
              parts[0] == "block",
              let sourceID = UUID(uuidString: String(parts[1])),
              let source = routine.blocks.firstIndex(where: { $0.id == sourceID })
        else { return }
        if destinationID == sourceID { return }
        let moved = routine.blocks.remove(at: source)
        let destination = destinationID.flatMap { id in
            routine.blocks.firstIndex(where: { $0.id == id })
        } ?? routine.blocks.count
        routine.blocks.insert(moved, at: destination)
    }

    private func moveExercise(type: String, blockID: UUID, itemID: UUID, offset: Int) {
        guard let blockIndex = routine.blocks.firstIndex(where: { $0.id == blockID }) else { return }
        if type == "exercise" {
            guard let old = routine.blocks[blockIndex].exercises.firstIndex(where: { $0.id == itemID }),
                  routine.blocks[blockIndex].exercises.indices.contains(old + offset) else { return }
            withAnimation(.smooth) {
                let item = routine.blocks[blockIndex].exercises.remove(at: old)
                routine.blocks[blockIndex].exercises.insert(item, at: old + offset)
            }
        } else if type == "movement" {
            guard let old = routine.blocks[blockIndex].movements.firstIndex(where: { $0.id == itemID }),
                  routine.blocks[blockIndex].movements.indices.contains(old + offset) else { return }
            withAnimation(.smooth) {
                let item = routine.blocks[blockIndex].movements.remove(at: old)
                routine.blocks[blockIndex].movements.insert(item, at: old + offset)
            }
        }
    }

    private func moveBlock(_ id: UUID, offset: Int) {
        guard let old = routine.blocks.firstIndex(where: { $0.id == id }),
              routine.blocks.indices.contains(old + offset) else { return }
        withAnimation(.smooth) {
            routine.blocks.move(
                fromOffsets: IndexSet(integer: old),
                toOffset: old + offset + (offset > 0 ? 1 : 0)
            )
        }
    }

    private func applyReorder(_ token: String, into destinationID: UUID, before itemID: UUID?) {
        let parts = token.split(separator: ":").map(String.init)
        guard let targetIndex = routine.blocks.firstIndex(where: { $0.id == destinationID }) else { return }
        if parts.count == 2, parts[0] == "block" {
            reorderBlockToken(token, before: destinationID)
            return
        }
        guard parts.count == 3,
              let sourceBlockID = UUID(uuidString: parts[1]),
              let exerciseID = UUID(uuidString: parts[2]),
              let sourceIndex = routine.blocks.firstIndex(where: { $0.id == sourceBlockID })
        else { return }
        // Soltar una fila en su propio hueco anterior no cambia el orden.
        if sourceBlockID == destinationID && itemID == exerciseID { return }
        let source = routine.blocks[sourceIndex]
        let targetKind = routine.blocks[targetIndex].kind
        if parts[0] == "exercise" {
            guard let item = source.exercises.first(where: { $0.id == exerciseID }) else { return }
            let targetMovement: WODMovement?
            if targetKind == .wod {
                let name = store.state.exercises.first(where: { $0.id == item.exerciseId })?.name ?? "Ejercicio"
                targetMovement = WODMovement(
                    exerciseId: item.exerciseId,
                    name: name,
                    reps: item.plannedSets.first?.targetReps ?? 8,
                    distanceMeters: item.quantityUnit == .meters ? item.plannedSets.first?.targetReps : nil,
                    calories: item.quantityUnit == .calories ? item.plannedSets.first?.targetReps : nil,
                    weightMaleKg: item.plannedSets.first?.targetWeightKg,
                    explicitPlannedSets: item.plannedSets
                )
            } else { targetMovement = nil }
            routine.blocks[sourceIndex].exercises.removeAll { $0.id == exerciseID }
            if targetKind == .strength {
                let position = itemID.flatMap { id in
                    routine.blocks[targetIndex].exercises.firstIndex(where: { $0.id == id })
                } ?? routine.blocks[targetIndex].exercises.count
                routine.blocks[targetIndex].exercises.insert(item, at: position)
            } else if let targetMovement {
                let position = itemID.flatMap { id in
                    routine.blocks[targetIndex].movements.firstIndex(where: { $0.id == id })
                } ?? routine.blocks[targetIndex].movements.count
                routine.blocks[targetIndex].movements.insert(targetMovement, at: position)
            }
        } else if parts[0] == "movement" {
            guard let move = source.movements.first(where: { $0.id == exerciseID }) else { return }
            var targetExercise: RoutineExercise?
            if targetKind == .strength {
                guard !move.isRest else { return }
                var catalogID = move.exerciseId.flatMap { id in
                    store.state.exercises.contains(where: { $0.id == id }) ? id : nil
                } ?? store.state.exercises.first(where: {
                    $0.name.localizedCaseInsensitiveCompare(move.name) == .orderedSame
                })?.id
                if catalogID == nil {
                    guard store.addCustomExercise(name: move.name, muscleGroup: "Otros", equipment: nil) else { return }
                    catalogID = store.state.exercises.last(where: {
                        $0.name.localizedCaseInsensitiveCompare(move.name) == .orderedSame
                    })?.id
                }
                guard let resolvedID = catalogID else { return }
                targetExercise = RoutineExercise(
                    exerciseId: resolvedID,
                    plannedSets: move.explicitPlannedSets ?? move.plannedSetsFromReps,
                    quantityUnit: move.prescribedQuantityUnit
                )
            }
            routine.blocks[sourceIndex].movements.removeAll { $0.id == exerciseID }
            if targetKind == .wod {
                let position = itemID.flatMap { id in
                    routine.blocks[targetIndex].movements.firstIndex(where: { $0.id == id })
                } ?? routine.blocks[targetIndex].movements.count
                routine.blocks[targetIndex].movements.insert(move, at: position)
            } else if let targetExercise {
                let position = itemID.flatMap { id in
                    routine.blocks[targetIndex].exercises.firstIndex(where: { $0.id == id })
                } ?? routine.blocks[targetIndex].exercises.count
                routine.blocks[targetIndex].exercises.insert(targetExercise, at: position)
            }
        }
    }

    /// Nombre por defecto al añadir bloque: «Bloque 1», «Bloque 2», …
    private func nextDefaultBlockTitle() -> String {
        "Bloque \(routine.blocks.count + 1)"
    }

    private var importableRoutines: [Routine] {
        store.libraryRoutines.filter { $0.id != routine.id && !$0.blocks.isEmpty }
    }

    private func closeEditor() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    @ViewBuilder
    private var scheduledTimeControls: some View {
        Toggle("Hora programada", isOn: Binding(
            get: { routine.scheduledTimeMinutes != nil },
            set: { enabled in
                if enabled {
                    if routine.scheduledTimeMinutes == nil {
                        routine.scheduledTimeMinutes = 18 * 60
                    }
                } else {
                    routine.scheduledTimeMinutes = nil
                }
            }
        ))
        if routine.scheduledTimeMinutes != nil {
            DatePicker(
                "Hora",
                selection: Binding(
                    get: {
                        routine.scheduledDateTime(on: routine.scheduledDate ?? Date())
                            ?? Calendar.current.date(
                                bySettingHour: 18,
                                minute: 0,
                                second: 0,
                                of: Date()
                            )
                            ?? Date()
                    },
                    set: { routine.setScheduledTime(from: $0) }
                ),
                displayedComponents: .hourAndMinute
            )
        }
    }

    private var nameFieldPlaceholder: String {
        switch mode {
        case .session, .oneOff: return "Nombre del entreno"
        case .favorite: return "Nombre del favorito"
        case .plan: return "Nombre de la rutina"
        }
    }

    private var navTitle: String {
        if onApplyDraft != nil || onApplyCompleted != nil { return "Editar entreno" }
        switch mode {
        case .session: return "Crear entreno"
        case .oneOff(let isNew): return isNew ? "Entreno del día" : "Editar entreno"
        case .favorite(let isNew): return isNew ? "Nuevo favorito" : "Editar favorito"
        case .plan(let isNew):
            return isNew ? "Nueva rutina" : "Editar rutina"
        }
    }

    private var confirmTitle: String {
        if onApplyCompleted != nil { return "Guardar" }
        if onApplyDraft != nil { return "Listo" }
        switch mode {
        case .session: return "Empezar"
        case .plan, .favorite, .oneOff: return "Guardar"
        }
    }

    private var canConfirm: Bool {
        if onApplyDraft != nil || onApplyCompleted != nil {
            return routine.blocks.contains { block in
                switch block.kind {
                case .strength: return !block.exercises.isEmpty
                case .wod: return !block.movements.isEmpty
                }
            }
        }
        switch mode {
        case .plan, .favorite, .oneOff: return true
        case .session:
            return routine.blocks.contains { block in
                switch block.kind {
                case .strength: return !block.exercises.isEmpty
                case .wod: return !block.movements.isEmpty
                }
            }
        }
    }

    private func confirm() {
        if let onApplyCompleted, let completedDetails = completedWorkoutDraft {
            var edited = routine
            for index in edited.blocks.indices { edited.blocks[index].deriveEmomRoundsIfNeeded() }
            if edited.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                edited.title = "Entreno"
            }
            if saveAsFavorite {
                // La rutina original puede seguir programada: crear una copia
                // independiente, nunca sobrescribir su ID con valores ya registrados.
                let favorite = Routine(
                    title: edited.title,
                    blocks: edited.blocks.map { $0.duplicatingContent() },
                    isFavorite: true
                )
                guard store.saveRoutine(favorite) else {
                    presentRoutineLimitPaywall()
                    return
                }
            }
            onApplyCompleted(edited, completedDetails)
            closeEditor()
            return
        }
        if let onApplyDraft {
            var draft = routine
            for i in draft.blocks.indices {
                draft.blocks[i].deriveEmomRoundsIfNeeded()
            }
            if draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                draft.title = "Entreno"
            }
            onApplyDraft(draft)
            closeEditor()
            return
        }
        switch mode {
        case .plan:
            var draft = routine
            draft.scheduledDate = nil
            if draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                draft.title = "Rutina"
            }
            guard store.saveRoutine(draft) else {
                presentRoutineLimitPaywall()
                return
            }
            closeEditor()
        case .oneOff:
            var draft = routine
            draft.weekday = nil
            draft.progression = .off
            if draft.scheduledDate == nil {
                draft.scheduledDate = Calendar.current.startOfDay(for: Date())
            }
            if draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                draft.title = "Entreno"
            }
            // One-off (fecha) no cuenta como plantilla de biblioteca.
            _ = store.saveRoutine(draft)
            closeEditor()
        case .favorite:
            var draft = routine
            draft.isFavorite = true
            if draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                draft.title = "Favorito"
            }
            guard store.saveRoutine(draft) else {
                presentRoutineLimitPaywall()
                return
            }
            closeEditor()
        case .session:
            var draft = routine
            draft.progression = .off
            draft.scheduledDate = nil
            draft.weekday = nil
            if draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                draft.title = "Mi entreno"
            }
            draft.isFavorite = saveAsFavorite
            if saveAsFavorite {
                guard store.saveRoutine(draft) else {
                    presentRoutineLimitPaywall()
                    return
                }
            }
            store.startSession(from: draft)
            closeEditor()
            onSessionStarted?()
        }
    }

    /// Al editar una sesión finalizada se muestra el dato REAL anotado, no las
    /// series prescritas del WOD. Todos los formatos de score tienen edición.
    @ViewBuilder
    private func completedScoreEditor(for block: RoutineBlock) -> some View {
        if isEditingCompletedWorkout,
           let format = block.wodFormat,
           format.resultCapture != .perMovementSets {
            VStack(alignment: .leading, spacing: 10) {
                Text("Resultado del entreno")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(OG.label)

                if completedWorkoutDraft?.wodResults.contains(where: {
                    $0.id == block.id && ($0.format == nil || $0.format == format)
                }) == true {
                    switch format.resultCapture {
                    case .totalReps:
                        if format == .amrap || format == .deathBy {
                            HStack(spacing: 8) {
                                OGFormatNumberField(
                                    title: "Rondas completas", value: completedScoreBinding(id: block.id, field: .rounds),
                                    range: 0...200, focus: $focusedFormatField,
                                    fieldID: OGSetFieldID(rowID: block.id, column: 10),
                                    nextID: OGSetFieldID(rowID: block.id, column: 11)
                                )
                                OGFormatNumberField(
                                    title: "Reps adicionales", value: completedScoreBinding(id: block.id, field: .reps),
                                    range: 0...5000, focus: $focusedFormatField,
                                    fieldID: OGSetFieldID(rowID: block.id, column: 11)
                                )
                            }
                            Text("Solo las repeticiones de la ronda incompleta, no las acumuladas.")
                                .font(.caption)
                                .foregroundStyle(OG.label2)
                        } else {
                            OGFormatNumberField(
                                title: "Repeticiones máximas", value: completedScoreBinding(id: block.id, field: .reps),
                                range: 0...5000, focus: $focusedFormatField,
                                fieldID: OGSetFieldID(rowID: block.id, column: 10)
                            )
                        }
                    case .elapsedTime:
                        HStack(spacing: 8) {
                            OGFormatNumberField(
                                title: "Minutos", unit: "min",
                                value: completedScoreBinding(id: block.id, field: .minutes),
                                range: 0...180, focus: $focusedFormatField,
                                fieldID: OGSetFieldID(rowID: block.id, column: 10),
                                nextID: OGSetFieldID(rowID: block.id, column: 11)
                            )
                            OGFormatNumberField(
                                title: "Segundos", unit: "s",
                                value: completedScoreBinding(id: block.id, field: .seconds),
                                range: 0...59, focus: $focusedFormatField,
                                fieldID: OGSetFieldID(rowID: block.id, column: 11)
                            )
                        }
                        Text("Tiempo real empleado (no el time cap).")
                            .font(.caption)
                            .foregroundStyle(OG.label2)
                    case .perMovementSets:
                        EmptyView()
                    }
                } else {
                    Text("No hay resultado guardado para este bloque.")
                        .font(.footnote)
                        .foregroundStyle(OG.label2)
                    Button {
                        addCompletedResult(for: block)
                    } label: {
                        Label("Añadir resultado", systemImage: "plus.circle")
                            .foregroundStyle(OG.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func addCompletedResult(for block: RoutineBlock) {
        guard isEditingCompletedWorkout,
              let format = block.wodFormat, format.resultCapture != .perMovementSets,
              completedWorkoutDraft != nil,
              completedWorkoutDraft?.wodResults.contains(where: {
                  $0.id == block.id && ($0.format == nil || $0.format == format)
              }) != true
        else { return }
        // Si el formato cambió, el score anterior ya no tiene las mismas
        // unidades. Solo el usuario puede introducir la nueva marca.
        ensureCompletedWorkoutDraft()
        completedDetails?.wodResults.removeAll { $0.id == block.id }
        completedDetails?.wodResults.append(WODBlockResult(
            id: block.id, format: format,
            totalReps: format.resultCapture == .totalReps ? 0 : nil,
            elapsedSeconds: format.resultCapture == .elapsedTime ? 0 : nil,
            roundsCompleted: (format == .amrap || format == .deathBy) ? 0 : nil,
            wodTemplateId: block.wodTemplateId
        ))
    }

    private enum CompletedScoreField { case reps, rounds, minutes, seconds }

    private func completedScoreBinding(id: UUID, field: CompletedScoreField) -> Binding<Int> {
        Binding(
            get: {
                guard let result = completedWorkoutDraft?.wodResults.first(where: { $0.id == id }) else { return 0 }
                switch field {
                case .reps: return result.totalReps ?? 0
                case .rounds: return result.roundsCompleted ?? 0
                case .minutes: return max(0, result.elapsedSeconds ?? 0) / 60
                case .seconds: return max(0, result.elapsedSeconds ?? 0) % 60
                }
            },
            set: { value in
                ensureCompletedWorkoutDraft()
                guard let index = completedDetails?.wodResults.firstIndex(where: { $0.id == id }) else { return }
                switch field {
                case .reps:
                    completedDetails?.wodResults[index].totalReps = min(5000, max(0, value))
                case .rounds:
                    completedDetails?.wodResults[index].roundsCompleted = min(200, max(0, value))
                case .minutes:
                    let seconds = max(0, completedDetails?.wodResults[index].elapsedSeconds ?? 0)
                    completedDetails?.wodResults[index].elapsedSeconds = min(180, max(0, value)) * 60 + seconds % 60
                case .seconds:
                    let seconds = max(0, completedDetails?.wodResults[index].elapsedSeconds ?? 0)
                    completedDetails?.wodResults[index].elapsedSeconds = seconds / 60 * 60 + min(59, max(0, value))
                }
            }
        )
    }

    private func completedDateBinding(isEnd: Bool) -> Binding<Date> {
        Binding(
            get: {
                if isEnd {
                    return completedDetails?.finishedAt ?? completedDetails?.startedAt ?? Date()
                }
                return completedDetails?.startedAt ?? completedDetails?.finishedAt ?? Date()
            },
            set: { date in
                if isEnd { completedDetails?.finishedAt = date }
                else { completedDetails?.startedAt = date }
            }
        )
    }

    private func presentRoutineLimitPaywall() {
        let decision = store.lastAccessDenial
            ?? subscriptions.canCreateLibraryRoutine(isNew: true)
        subscriptions.presentPaywall(decision.paywallContext, feature: .unlimitedRoutines)
    }

    /// Al editar una sesión terminada la miniatura se alinea al título,
    /// y solo se muestran los campos de resultado realmente modificables.
    @ViewBuilder
    private func completedStrengthPrescription(index: Int) -> some View {
        ForEach(Array(routine.blocks[index].exercises.enumerated()), id: \.element.id) { _, item in
            if let exercise = store.state.exercises.first(where: { $0.id == item.exerciseId })
                ?? completedWorkoutDraft?.exercises.first(where: { $0.exercise.id == item.exerciseId })?.exercise {
                HStack(alignment: .top, spacing: 12) {
                    ExerciseThumb(exercise: exercise, size: 48)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(OG.label)
                        Text(item.plannedSets.compactSummary)
                            .font(.caption)
                            .foregroundStyle(OG.label2)
                        completedWODScalingFields(movementID: item.id, exercise: exercise)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.vertical, 5)
            }
        }
    }

    /// Los valores reales se presentan con los prescritos como valor inicial.
    /// No guardan una adaptación por el mero hecho de abrir el editor.
    @ViewBuilder
    private func completedWODScalingFields(movementID: UUID, exercise: Exercise) -> some View {
        let showsWeight = exercise.loggingStyle == .loadAndReps
            || !completedPrescribedValue(movementID: movementID, weight: true).isEmpty
        HStack(alignment: .top, spacing: 8) {
            completedActualField(
                label: exercise.loggingStyle == .machineWork ? "CANTIDAD REAL" : "REPS REALES",
                value: completedWODScaledValue(movementID: movementID, weight: false),
                allowsDecimal: false,
                name: exercise.name
            )
            if showsWeight && exercise.loadField != .deficitCm {
                completedActualField(
                    label: "KG REALES",
                    value: completedWODScaledValue(movementID: movementID, weight: true),
                    allowsDecimal: true,
                    name: exercise.name
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func completedActualField(
        label: String, value: Binding<String>, allowsDecimal: Bool, name: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(OG.label3)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            OGNumericTextField(text: value, allowsDecimal: allowsDecimal, autoFocus: false, onCommit: {})
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(OG.surface2, in: RoundedRectangle(cornerRadius: 11))
                .accessibilityLabel(label + " · " + name)
        }
        .frame(maxWidth: .infinity)
    }

    private func completedPrescribedValue(movementID: UUID, weight: Bool) -> String {
        for block in routine.blocks {
            if let item = block.exercises.first(where: { $0.id == movementID }) {
                let first = item.plannedSets.first
                if weight {
                    return first?.targetWeightKg.map { String(format: "%g", $0) } ?? ""
                }
                return first.map { String($0.targetReps) } ?? ""
            }
            if let move = block.movements.first(where: { $0.id == movementID }) {
                let first = block.plannedSets(for: move).first
                if weight {
                    return (move.weightMaleKg ?? first?.targetWeightKg).map { String(format: "%g", $0) } ?? ""
                }
                return (first?.targetReps ?? move.reps).map(String.init) ?? ""
            }
        }
        return ""
    }

    private func completedWODScaledValue(movementID: UUID, weight: Bool) -> Binding<String> {
        let key = movementID.uuidString + (weight ? "-kg" : "-reps")
        return Binding(
            get: {
                // Conservar la coma, el punto y los decimales a medio escribir.
                // No volver a formatear desde el modelo al pulsar cada tecla.
                if let draft = scaledInputDrafts[key] { return draft }
                let prescribed = completedPrescribedValue(movementID: movementID, weight: weight)
                guard let entry = completedWorkoutDraft?.exercises.first(where: { $0.id == movementID }) else {
                    return prescribed
                }
                if weight {
                    return entry.adaptedWeightKg.map { String(format: "%g", $0) } ?? prescribed
                }
                return entry.adaptedReps.map(String.init) ?? prescribed
            },
            set: { input in
                scaledInputDrafts[key] = input
                ensureCompletedWorkoutDraft()
                guard let index = completedDetails?.exercises.firstIndex(where: { $0.id == movementID })
                else { return }
                let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
                let prescribed = completedPrescribedValue(movementID: movementID, weight: weight)
                if weight {
                    if cleaned.isEmpty {
                        completedDetails?.exercises[index].adaptedWeightKg = nil
                    } else if let kg = Double(cleaned.replacingOccurrences(of: ",", with: ".")),
                              kg.isFinite, (0...1000).contains(kg) {
                        let rx = Double(prescribed.replacingOccurrences(of: ",", with: "."))
                        completedDetails?.exercises[index].adaptedWeightKg =
                            rx.map { abs(kg - $0) < 0.05 } == true ? nil : kg
                    }
                } else if cleaned.isEmpty {
                    completedDetails?.exercises[index].adaptedReps = nil
                } else if let reps = Int(cleaned), (0...10000).contains(reps) {
                    completedDetails?.exercises[index].adaptedReps =
                        reps == Int(prescribed) ? nil : reps
                }
            }
        )
    }

    @ViewBuilder
    private func strengthBlock(index: Int) -> some View {
        let blockId = routine.blocks[index].id
        let weightStep = store.state.settings.weightIncrementKg
        ForEach(Array(routine.blocks[index].exercises.enumerated()), id: \.element.id) { exIndex, item in
            if let ex = store.state.exercises.first(where: { $0.id == item.exerciseId })
                ?? completedDetails?.exercises.first(where: { $0.exercise.id == item.exerciseId })?.exercise {
                NavigationLink {
                    ExerciseDetailView(exerciseId: ex.id)
                } label: {
                    HStack(spacing: 12) {
                        ExerciseThumb(exercise: ex, size: 48)
                        Text(ex.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(OG.label)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .accessibilityHint("Ver ficha del ejercicio. Arrastra para cambiar el orden.")
                .listRowSeparator(.hidden, edges: .bottom)
                .swipeActions {
                    OGSwipeDeleteButton(accessibilityLabel: "Quitar") {
                        routine.blocks[index].exercises.remove(at: exIndex)
                    }
                }

                if ex.loggingStyle == .machineWork, ex.allowsCalorieOrDistanceToggle {
                    Picker("Unidad de cardio", selection: Binding(
                        get: { routine.blocks[index].exercises[exIndex].quantityUnit ?? ex.defaultQuantityUnit },
                        set: { routine.blocks[index].exercises[exIndex].quantityUnit = $0 }
                    )) {
                        Text("Calorías").tag(ExerciseQuantityUnit.calories)
                        Text("Metros").tag(ExerciseQuantityUnit.meters)
                    }
                    .pickerStyle(.segmented)
                }

                OGSetEntryHeader(
                    firstTitle: ex.isMobility ? "Tiempo (s)" : (ex.loggingStyle == .loadAndReps
                        ? (ex.loadField == .deficitCm ? "Déficit" : "KG")
                        : (ex.loggingStyle == .machineWork
                            ? (item.quantityUnit ?? ex.defaultQuantityUnit).shortLabel
                            : ex.quantityFieldLabel)),
                    secondTitle: ex.isMobility ? (ex.isMobilityHold ? nil : "Reps")
                        : (ex.loggingStyle == .loadAndReps ? "Reps" : nil),
                    showsRIR: ex.loggingStyle.usesRIR
                )
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 4, trailing: 16))
                .listRowSeparator(.hidden, edges: .top)

                ForEach(Array(routine.blocks[index].exercises[exIndex].plannedSets.enumerated()), id: \.element.id) { setIndex, _ in
                    PlannedSetConfigRow(
                        index: setIndex + 1,
                        set: plannedSetBinding(blockIndex: index, exerciseIndex: exIndex, setIndex: setIndex),
                        weightStep: weightStep,
                        exerciseStyle: ex.loggingStyle,
                        isMobility: ex.isMobility,
                        isMobilityHold: ex.isMobilityHold,
                        previous: {
                            let sets = store.cachedLastWorkingSession(for: ex.id)?.sets
                            return (sets?.indices.contains(setIndex) == true) ? sets?[setIndex] : nil
                        }(),
                        canDelete: routine.blocks[index].exercises[exIndex].plannedSets.count > 1,
                        onDelete: { deleteStrengthSet(blockIndex: index, exerciseIndex: exIndex, setIndex: setIndex) }
                    )
                }

                Button {
                    addStrengthSet(blockIndex: index, exerciseIndex: exIndex)
                } label: {
                    Label("Añadir serie", systemImage: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(OG.accent)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

            }
        }
        .reorderable(collectionID: blockId)
        Button("Añadir ejercicio") { pickExerciseForBlock = routine.blocks[index].id }
    }

    private func plannedSetBinding(blockIndex: Int, exerciseIndex: Int, setIndex: Int) -> Binding<PlannedSet> {
        Binding(
            get: {
                guard routine.blocks.indices.contains(blockIndex),
                      routine.blocks[blockIndex].exercises.indices.contains(exerciseIndex),
                      routine.blocks[blockIndex].exercises[exerciseIndex].plannedSets.indices.contains(setIndex)
                else {
                    return PlannedSet(targetReps: 8)
                }
                return routine.blocks[blockIndex].exercises[exerciseIndex].plannedSets[setIndex]
            },
            set: { newValue in
                guard routine.blocks.indices.contains(blockIndex),
                      routine.blocks[blockIndex].exercises.indices.contains(exerciseIndex),
                      routine.blocks[blockIndex].exercises[exerciseIndex].plannedSets.indices.contains(setIndex)
                else { return }
                routine.blocks[blockIndex].exercises[exerciseIndex].plannedSets[setIndex] = newValue
            }
        )
    }

    private func ensureStrengthPlannedSets() {
        for blockIndex in routine.blocks.indices where routine.blocks[blockIndex].kind == .strength {
            for exerciseIndex in routine.blocks[blockIndex].exercises.indices
            where routine.blocks[blockIndex].exercises[exerciseIndex].plannedSets.isEmpty {
                routine.blocks[blockIndex].exercises[exerciseIndex].plannedSets = [
                    PlannedSet(targetReps: 8, targetWeightKg: nil)
                ]
            }
        }
    }

    private func addStrengthSet(blockIndex: Int, exerciseIndex: Int) {
        guard routine.blocks.indices.contains(blockIndex),
              routine.blocks[blockIndex].exercises.indices.contains(exerciseIndex) else { return }
        var sets = routine.blocks[blockIndex].exercises[exerciseIndex].plannedSets
        if sets.isEmpty {
            sets = [PlannedSet(targetReps: 8, targetWeightKg: nil)]
        }
        guard sets.count < 12 else { return }
        let last = sets.last
        sets.append(
            PlannedSet(
                targetReps: last?.targetReps ?? 8,
                targetWeightKg: last?.targetWeightKg,
                targetDurationSeconds: last?.targetDurationSeconds,
                targetRir: last?.targetRir
            )
        )
        routine.blocks[blockIndex].exercises[exerciseIndex].plannedSets = sets
    }

    private func deleteStrengthSet(blockIndex: Int, exerciseIndex: Int, setIndex: Int) {
        guard routine.blocks.indices.contains(blockIndex),
              routine.blocks[blockIndex].exercises.indices.contains(exerciseIndex) else { return }
        var sets = routine.blocks[blockIndex].exercises[exerciseIndex].plannedSets
        guard sets.count > 1, sets.indices.contains(setIndex) else { return }
        sets.remove(at: setIndex)
        routine.blocks[blockIndex].exercises[exerciseIndex].plannedSets = sets
    }

    private func applyStrengthExerciseReorder(
        to exercises: inout [RoutineExercise],
        difference: ReorderDifference<UUID, UUID>
    ) {
        let sourceIDs = Set(difference.sources)
        let moved = difference.sources.compactMap { id in exercises.first { $0.id == id } }
        guard !moved.isEmpty else { return }
        exercises.removeAll { sourceIDs.contains($0.id) }
        let insertIndex: Int
        switch difference.destination.position {
        case .before(let anchorID):
            insertIndex = exercises.firstIndex { $0.id == anchorID } ?? exercises.count
        case .end:
            insertIndex = exercises.count
        }
        exercises.insert(contentsOf: moved, at: insertIndex)
    }

    /// Rondas mostradas: EMOM deriva vueltas (cap÷estaciones); RFT default 4.
    private func emomOrRFTRounds(at index: Int) -> Int {
        if let rounds = routine.blocks[index].rounds { return rounds }
        if routine.blocks[index].wodFormat == .emom {
            var block = routine.blocks[index]
            block.deriveEmomRoundsIfNeeded()
            return block.rounds ?? 4
        }
        return 4
    }

    private func setWODFormat(_ format: WODFormat?, at index: Int) {
        routine.blocks[index].wodFormat = format
        guard let format else { return }
        if format == .tabata {
            routine.blocks[index].workSeconds = routine.blocks[index].workSeconds ?? 20
            routine.blocks[index].restSeconds = routine.blocks[index].restSeconds ?? 10
            routine.blocks[index].rounds = routine.blocks[index].rounds ?? 8
        }
        if format == .forTime {
            routine.blocks[index].rounds = routine.blocks[index].rounds ?? 4
            routine.blocks[index].timeCapMinutes = routine.blocks[index].timeCapMinutes ?? 12
        }
        if format == .amrap || format == .emom {
            routine.blocks[index].timeCapMinutes = routine.blocks[index].timeCapMinutes ?? 12
        }
        if format == .emom {
            routine.blocks[index].deriveEmomRoundsIfNeeded()
        }
    }

    private enum BlockNumberField: Int, Hashable {
        case duration, interval, rounds, work, rest, roundRest

        var title: String {
            switch self {
            case .duration: return "Tiempo"
            case .interval: return "Intervalo"
            case .rounds: return "Rondas"
            case .work: return "Trabajo"
            case .rest: return "Descanso"
            case .roundRest: return "Entre rondas"
            }
        }

        var unit: String {
            switch self {
            case .duration: return "min"
            case .rounds: return ""
            case .interval, .work, .rest, .roundRest: return "s"
            }
        }

        var range: ClosedRange<Int> {
            switch self {
            case .duration: return 1...120
            case .rounds: return 1...99
            case .interval: return 15...900
            case .work, .rest: return 1...300
            case .roundRest: return 0...600
            }
        }
    }

    private func fieldsForFormat(_ block: RoutineBlock) -> [BlockNumberField] {
        guard let format = block.wodFormat else { return [] }
        switch format {
        case .tabata: return [.work, .rest, .rounds]
        case .emom, .circuit: return [.duration, .interval]
        case .amrap: return [.duration]
        case .forTime:
            return block.timeCapMinutes == nil ? [.rounds] : [.rounds, .duration, .roundRest]
        case .chipper, .afap, .ladder:
            return block.timeCapMinutes == nil ? [] : [.duration]
        case .deathBy, .roundsForQuality, .partner:
            return block.timeCapMinutes == nil ? [.rounds] : [.rounds, .duration]
        case .buyInCashOut, .maxEffort, .strength:
            return block.timeCapMinutes == nil ? [] : [.duration]
        }
    }

    private func numberBinding(_ field: BlockNumberField, blockIndex: Int) -> Binding<Int> {
        Binding(
            get: {
                guard routine.blocks.indices.contains(blockIndex) else { return 0 }
                let block = routine.blocks[blockIndex]
                switch field {
                case .duration: return block.timeCapMinutes ?? 12
                case .interval: return block.emomIntervalSeconds ?? 60
                case .rounds: return block.rounds ?? 8
                case .work: return block.workSeconds ?? 20
                case .rest: return block.restSeconds ?? 10
                case .roundRest: return block.restBetweenRoundsSeconds ?? 0
                }
            },
            set: { value in
                guard routine.blocks.indices.contains(blockIndex) else { return }
                switch field {
                case .duration: routine.blocks[blockIndex].timeCapMinutes = value
                case .interval: routine.blocks[blockIndex].emomIntervalSeconds = value
                case .rounds: routine.blocks[blockIndex].rounds = value
                case .work: routine.blocks[blockIndex].workSeconds = value
                case .rest: routine.blocks[blockIndex].restSeconds = value
                case .roundRest: routine.blocks[blockIndex].restBetweenRoundsSeconds = value
                }
            }
        )
    }

    /// Los parámetros de un formato se muestran como campos compactos en una sola fila.
    @ViewBuilder
    private func formatSettings(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                selectFormatForBlock = routine.blocks[index].id
            } label: {
                HStack(spacing: 10) {
                    Text("Formato")
                        .foregroundStyle(OG.label)
                    Spacer()
                    Text(routine.blocks[index].wodFormat?.displayName ?? "Sin formato")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(OG.label2)
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(OG.label3)
                }
            }
            .buttonStyle(.plain)

            if let format = routine.blocks[index].wodFormat {
                let fields = fieldsForFormat(routine.blocks[index])
                if !fields.isEmpty {
                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(Array(fields.enumerated()), id: \.element) { position, field in
                            OGFormatNumberField(
                                title: field.title,
                                unit: field.unit,
                                value: numberBinding(field, blockIndex: index),
                                range: field.range,
                                focus: $focusedFormatField,
                                fieldID: OGSetFieldID(rowID: routine.blocks[index].id, column: position),
                                nextID: position + 1 < fields.count
                                    ? OGSetFieldID(rowID: routine.blocks[index].id, column: position + 1)
                                    : nil
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
                if ![WODFormat.amrap, .emom, .tabata, .circuit].contains(format) {
                    Toggle("Límite de tiempo", isOn: Binding(
                        get: { routine.blocks[index].timeCapMinutes != nil },
                        set: { enabled in
                            routine.blocks[index].timeCapMinutes = enabled
                                ? (routine.blocks[index].timeCapMinutes ?? 12) : nil
                        }
                    ))
                    .tint(OG.accent)
                }
            }
        }

    }

    @ViewBuilder
    private func wodBlock(index: Int) -> some View {
        ForEach(Array(routine.blocks[index].movements.enumerated()), id: \.element.id) { mIndex, move in
            let resolved = resolvedExercise(for: move)
            let hasCatalog = !move.isRest && store.state.exercises.contains(where: { $0.id == resolved.id })
            if !move.isRest, isEditingCompletedWorkout,
               let format = routine.blocks[index].wodFormat,
               format.resultCapture != .perMovementSets {
                HStack(alignment: .top, spacing: 12) {
                    ExerciseThumb(exercise: resolved, size: 48)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 8) {
                        if hasCatalog {
                            NavigationLink {
                                ExerciseDetailView(exerciseId: resolved.id)
                            } label: {
                                Text(resolved.name)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(OG.label)
                            }
                        } else {
                            Text(resolved.name)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(OG.label)
                        }
                        Text(move.summaryLine)
                            .font(.caption)
                            .foregroundStyle(OG.label2)
                        completedWODScalingFields(movementID: move.id, exercise: resolved)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.vertical, 5)
                .swipeActions {
                    OGSwipeDeleteButton(accessibilityLabel: "Quitar") {
                        routine.blocks[index].movements.remove(at: mIndex)
                    }
                }
            } else {
                Group {
                    if hasCatalog {
                        NavigationLink {
                            ExerciseDetailView(exerciseId: resolved.id)
                        } label: {
                            movementRowLabel(move: move, resolved: resolved, showSummary: false)
                        }
                        .accessibilityHint("Ver ficha del ejercicio")
                    } else {
                        movementRowLabel(move: move, resolved: resolved, showSummary: false)
                    }
                }
                .swipeActions {
                    OGSwipeDeleteButton(accessibilityLabel: "Quitar") {
                        routine.blocks[index].movements.remove(at: mIndex)
                    }
                }
                .listRowSeparator(.hidden, edges: .bottom)
            }

            if move.isRest {
                Stepper(
                    "Segundos: \(routine.blocks[index].movements[mIndex].restSeconds ?? 60)",
                    value: Binding(
                        get: { routine.blocks[index].movements[mIndex].restSeconds ?? 60 },
                        set: { routine.blocks[index].movements[mIndex].restSeconds = $0 }
                    ),
                    in: 15...300,
                    step: 15
                )
            } else if isEditingCompletedWorkout,
                      let format = routine.blocks[index].wodFormat,
                      format.resultCapture != .perMovementSets {
                // Ya se registran los datos reales junto al título y miniatura.
                EmptyView()
            } else {
                if isEditingCompletedWorkout {
                    let logged = completedWorkoutDraft?.exercises.first(where: { $0.id == move.id
                        || ($0.blockId == routine.blocks[index].id
                            && $0.exercise.name.localizedCaseInsensitiveCompare(move.name) == .orderedSame)
                    })?.loggedSets.isEmpty == false
                    Text(logged ? "Series registradas" : "Sin series registradas · prescripción")
                        .font(.caption)
                        .foregroundStyle(OG.label2)
                }
                InlineWODMovementSets(
                    movement: Binding(
                        get: { routine.blocks[index].movements[mIndex] },
                        set: { routine.blocks[index].movements[mIndex] = $0 }
                    ),
                    block: routine.blocks[index]
                )
            }
        }

        Button("Añadir ejercicio al WOD") { pickMovementForBlock = routine.blocks[index].id }
        Button("Añadir descanso") {
            routine.blocks[index].movements.append(
                WODMovement(name: "REST", isRest: true, restSeconds: 60)
            )
        }
        Button("Añadir movimiento libre") {
            createFreeMovementForBlock = routine.blocks[index].id
        }

        TextField("Notas / texto del WOD", text: Binding(
            get: { routine.blocks[index].wodNotes ?? "" },
            set: { routine.blocks[index].wodNotes = $0.isEmpty ? nil : $0 }
        ), axis: .vertical)
        .lineLimit(2...5)
    }

    /// Resuelve el ejercicio del catálogo para miniaturas en bloques WOD (EMOM, AMRAP…).
    private func resolvedExercise(for move: WODMovement) -> Exercise {
        if let id = move.exerciseId, let ex = store.state.exercises.first(where: { $0.id == id }) {
            return ex
        }
        let canonical = CrossFitGlossary.resolveCatalogName(move.name, notes: move.notes)
        let rawCanonical = CrossFitGlossary.canonicalName(for: move.name)
        if let match = store.state.exercises.first(where: {
            $0.name.localizedCaseInsensitiveCompare(move.name) == .orderedSame
                || $0.name.localizedCaseInsensitiveCompare(canonical) == .orderedSame
                || $0.name.localizedCaseInsensitiveCompare(rawCanonical) == .orderedSame
        }) {
            return match
        }
        // Mantiene una identidad visual coherente incluso si el ejercicio
        // importado todavía no tiene ID en el catálogo del usuario.
        return Exercise(name: canonical, muscleGroup: "WOD", isCustom: true)
    }

    @ViewBuilder
    private func movementRowLabel(move: WODMovement, resolved: Exercise, showSummary: Bool = true) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if move.isRest {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(OG.surface2)
                    Image(systemName: "pause.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(OG.label3)
                }
                .frame(width: 48, height: 48)
            } else {
                ExerciseThumb(exercise: resolved, size: 48)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(move.isRest ? "Descanso" : resolved.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(OG.label)
                if showSummary {
                    Text(move.summaryLine)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Inline WOD sets (en la página de crear/editar entreno)

/// Controles de series WOD embebidos (mismo comportamiento que `WODMovementEditor`).
private struct InlineWODMovementSets: View {
    @Environment(ReperaStore.self) private var store
    @Binding var movement: WODMovement
    var block: RoutineBlock
    /// En historial, dibujar las series no reescribe automáticamente la prescripción Rx.
    var preservePrescriptionOnAppear = false

    @State private var draftSets: [PlannedSet] = []
    @State private var didSeedSets = false
    @FocusState private var focusedSetField: OGSetFieldID?

    private var weightStep: Double { store.state.settings.weightIncrementKg }

    private var loggingStyle: ExerciseLoggingStyle {
        let catalogName = CrossFitGlossary.resolveCatalogName(movement.name, notes: movement.notes)
        if let match = store.state.exercises.first(where: {
            $0.name.localizedCaseInsensitiveCompare(catalogName) == .orderedSame
        }) {
            return match.loggingStyle
        }
        return Exercise.loggingStyle(name: catalogName, equipment: movement.notes)
    }

    private var cardioUnitPicker: some View {
        Picker("Unidad de cardio", selection: Binding(
            get: { movement.prescribedQuantityUnit },
            set: { unit in
                let amount = draftSets.first?.targetReps ?? 10
                switch unit {
                case .calories:
                    movement.calories = amount
                    movement.distanceMeters = nil
                case .meters:
                    movement.distanceMeters = amount
                    movement.calories = nil
                case .reps:
                    movement.calories = nil
                    movement.distanceMeters = nil
                }
                writeSetsToMovement()
            }
        )) {
            Text("Calorías").tag(ExerciseQuantityUnit.calories)
            Text("Metros").tag(ExerciseQuantityUnit.meters)
        }
        .pickerStyle(.segmented)
    }

    private var resolvedLoadField: ExerciseLoadField {
        let catalogName = CrossFitGlossary.resolveCatalogName(movement.name, notes: movement.notes)
        if let match = store.state.exercises.first(where: {
            $0.name.localizedCaseInsensitiveCompare(catalogName) == .orderedSame
        }) {
            return match.loadField
        }
        return Exercise.loadField(name: catalogName, equipment: movement.notes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if loggingStyle == .machineWork { cardioUnitPicker }
            OGSetEntryHeader(
                firstTitle: loggingStyle == .loadAndReps ? (resolvedLoadField == .deficitCm ? "Déficit" : "KG") : (loggingStyle == .machineWork ? movement.prescribedQuantityUnit.shortLabel : "Reps"),
                secondTitle: loggingStyle == .loadAndReps ? "Reps" : nil,
                showsRIR: loggingStyle.usesRIR
            )
            ForEach(Array(draftSets.enumerated()), id: \.element.id) { index, _ in
                setRow(index: index)
                    .contextMenu {
                        if draftSets.count > 1 {
                            Button("Eliminar serie", role: .destructive) {
                                removeSet(at: index)
                            }
                        }
                    }
            }
            Button {
                addSet()
            } label: {
                Label("Añadir serie", systemImage: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(OG.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .onAppear { seedSetsIfNeeded() }
        .onChange(of: movement.id) { _, _ in
            didSeedSets = false
            seedSetsIfNeeded()
        }
    }

    private func seedSetsIfNeeded() {
        guard !didSeedSets, !movement.isRest else { return }
        didSeedSets = true
        draftSets = block.plannedSets(for: movement)
        if draftSets.isEmpty {
            draftSets = movement.plannedSetsFromReps
        }
        if draftSets.isEmpty {
            draftSets = [PlannedSet(targetReps: movement.reps ?? 10, targetWeightKg: movement.weightMaleKg)]
        }
        if !preservePrescriptionOnAppear {
            writeSetsToMovement()
        }
    }

    @ViewBuilder
    private func setRow(index: Int) -> some View {
        let style = loggingStyle
        let catalogName = CrossFitGlossary.resolveCatalogName(movement.name, notes: movement.notes)
        let catalogExercise = store.state.exercises.first {
            $0.name.localizedCaseInsensitiveCompare(catalogName) == .orderedSame
        }
        let oldSets = catalogExercise.flatMap { store.cachedLastWorkingSession(for: $0.id)?.sets }
        let oldSet = (oldSets?.indices.contains(index) == true) ? oldSets?[index] : nil
        VStack(alignment: .leading, spacing: 6) {
            OGSetEntryRow(
                rowID: draftSets[index].id,
                index: index + 1,
                previous: OGSetEntryRow.previousText(oldSet),
                firstValue: style == .loadAndReps
                    ? (draftSets[index].targetWeightKg.map { String(format: "%g", $0) } ?? "0")
                    : "\(draftSets[index].targetReps)",
                secondValue: style == .loadAndReps ? "\(draftSets[index].targetReps)" : nil,
                firstAllowsDecimal: style == .loadAndReps && resolvedLoadField == .weightKg,
                rir: draftSets[index].targetRir,
                showsRIR: style.usesRIR,
                onRIRChange: { value in
                    draftSets[index].targetRir = value
                    writeSetsToMovement()
                },
                focus: $focusedSetField,
                onFirstCommit: { text in
                    if style == .loadAndReps {
                        let normalized = text.replacingOccurrences(of: ",", with: ".")
                        if let parsed = Double(normalized) {
                            let value = resolvedLoadField == .deficitCm
                                ? min(60, max(0, parsed))
                                : max(0, parsed)
                            draftSets[index].targetWeightKg = value > 0 ? ((value * 10).rounded() / 10) : nil
                        } else if normalized.isEmpty {
                            draftSets[index].targetWeightKg = nil
                        }
                    } else if let parsed = Int(text) {
                        draftSets[index].targetReps = min(style.quantityCap, max(1, parsed))
                    }
                    writeSetsToMovement()
                },
                onSecondCommit: { text in
                    if let parsed = Int(text) {
                        draftSets[index].targetReps = min(style.quantityCap, max(1, parsed))
                        writeSetsToMovement()
                    }
                }
            )

        }
    }

    private func addSet() {
        guard draftSets.count < 20 else { return }
        let last = draftSets.last
        draftSets.append(
            PlannedSet(
                targetReps: last?.targetReps ?? movement.reps ?? 10,
                targetWeightKg: last?.targetWeightKg ?? movement.weightMaleKg,
                targetRir: last?.targetRir
            )
        )
        writeSetsToMovement()
    }

    private func removeSet(at index: Int) {
        guard draftSets.count > 1, draftSets.indices.contains(index) else { return }
        draftSets.remove(at: index)
        writeSetsToMovement()
    }

    private func writeSetsToMovement() {
        movement.explicitPlannedSets = draftSets
        let repsList = draftSets.map(\.targetReps)
        if loggingStyle == .machineWork {
            let qty = repsList.first
            switch movement.prescribedQuantityUnit {
            case .calories:
                movement.calories = qty
                if movement.distanceMeters == nil { movement.reps = nil }
            case .meters:
                movement.distanceMeters = qty
                if movement.calories == nil { movement.reps = nil }
            case .reps:
                movement.reps = qty
            }
            movement.repScheme = repsList.count > 1 ? repsList : nil
        } else if repsList.count <= 1 {
            movement.repScheme = nil
            movement.reps = repsList.first
        } else {
            movement.repScheme = repsList
            movement.reps = nil
        }
        if let kg = draftSets.compactMap(\.targetWeightKg).first {
            movement.weightMaleKg = kg
        }
    }
}

// MARK: - WOD movement editor

/// Editor de movimiento WOD alineado con Apuntar: series según estilo (kg / tiempo / reps).
struct WODMovementEditor: View {
    @Environment(ReperaStore.self) private var store
    @Binding var movement: WODMovement
    /// Bloque padre para derivar las mismas series que Empezar/Apuntar.
    var block: RoutineBlock? = nil

    @State private var draftSets: [PlannedSet] = []
    @State private var didSeedSets = false
    @FocusState private var focusedSetField: OGSetFieldID?
    @State private var weightFieldRowID = UUID()
    @State private var maleWeightDraft = ""
    @State private var femaleWeightDraft = ""
    @FocusState private var weightFieldFocus: OGSetFieldID?

    private var weightStep: Double { store.state.settings.weightIncrementKg }

    private var loggingStyle: ExerciseLoggingStyle {
        let catalogName = CrossFitGlossary.resolveCatalogName(movement.name, notes: movement.notes)
        if let match = store.state.exercises.first(where: {
            $0.name.localizedCaseInsensitiveCompare(catalogName) == .orderedSame
        }) {
            return match.loggingStyle
        }
        return Exercise.loggingStyle(name: catalogName, equipment: movement.notes)
    }

    private var cardioUnitPicker: some View {
        Picker("Unidad de cardio", selection: Binding(
            get: { movement.prescribedQuantityUnit },
            set: { unit in
                let amount = draftSets.first?.targetReps ?? 10
                switch unit {
                case .calories:
                    movement.calories = amount
                    movement.distanceMeters = nil
                case .meters:
                    movement.distanceMeters = amount
                    movement.calories = nil
                case .reps:
                    movement.calories = nil
                    movement.distanceMeters = nil
                }
                writeSetsToMovement()
            }
        )) {
            Text("Calorías").tag(ExerciseQuantityUnit.calories)
            Text("Metros").tag(ExerciseQuantityUnit.meters)
        }
        .pickerStyle(.segmented)
    }

    private var resolvedLoadField: ExerciseLoadField {
        let catalogName = CrossFitGlossary.resolveCatalogName(movement.name, notes: movement.notes)
        if let match = store.state.exercises.first(where: {
            $0.name.localizedCaseInsensitiveCompare(catalogName) == .orderedSame
        }) {
            return match.loadField
        }
        return Exercise.loadField(name: catalogName, equipment: movement.notes)
    }

    var body: some View {
        Form {
            Toggle("Es descanso", isOn: $movement.isRest)
            if movement.isRest {
                Stepper("Segundos: \(movement.restSeconds ?? 60)", value: Binding(
                    get: { movement.restSeconds ?? 60 },
                    set: { movement.restSeconds = $0 }
                ), in: 15...300, step: 15)
            } else {
                TextField("Nombre", text: $movement.name)

                Section {
                    if loggingStyle == .machineWork { cardioUnitPicker }
                    OGSetEntryHeader(
                        firstTitle: loggingStyle == .loadAndReps ? (resolvedLoadField == .deficitCm ? "Déficit" : "KG") : (loggingStyle == .machineWork ? movement.prescribedQuantityUnit.shortLabel : (loggingStyle == .repsAndTime ? "Veces" : "Reps")),
                        secondTitle: loggingStyle == .loadAndReps ? "Reps" : nil,
                        showsRIR: loggingStyle.usesRIR
                    )
                    ForEach(Array(draftSets.enumerated()), id: \.element.id) { index, _ in
                        wodSetRow(index: index)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                if draftSets.count > 1 {
                                    OGSwipeDeleteButton {
                                        removeSet(at: index)
                                    }
                                }
                            }
                    }
                    Button {
                        addSet()
                    } label: {
                        Label("Añadir serie", systemImage: "plus")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(OG.accent)
                    }
                } header: {
                    Text("Series al apuntar")
                } footer: {
                    switch loggingStyle {
                    case .repsAndTime:
                        Text("Comba: veces (dobles) · tiempo de la serie.")
                    case .machineWork:
                        Text("Máquina / carrera: prescribe calorías y/o metros (sin kilos).")
                    case .repsOnly:
                        Text("Solo reps (peso corporal).")
                    case .loadAndReps:
                        if resolvedLoadField == .deficitCm {
                            Text("HSPU: déficit (cm) · reps. 0 = sin déficit.")
                        } else {
                            Text("Peso/lastre · reps · RIR. Dominadas: lastre 0 = sin lastre.")
                        }
                    }
                }

                if loggingStyle != .machineWork {
                    Stepper("Metros: \(movement.distanceMeters ?? 0)", value: Binding(
                        get: { movement.distanceMeters ?? 0 },
                        set: { movement.distanceMeters = $0 == 0 ? nil : $0 }
                    ), in: 0...5000, step: 50)
                }
                if loggingStyle == .loadAndReps {
                    HStack(spacing: 8) {
                        Text("Peso H/M (kg)")
                            .font(.system(size: 13, weight: .medium))
                        Spacer(minLength: 4)
                        weightField(text: $maleWeightDraft, column: 0, nextColumn: 1)
                        Text("/").foregroundStyle(OG.label2)
                        weightField(text: $femaleWeightDraft, column: 1, nextColumn: nil)
                    }
                }
                TextField("Escala alternativa (ej. 100 SU)", text: Binding(
                    get: { movement.scaleAlternative ?? "" },
                    set: { movement.scaleAlternative = $0.isEmpty ? nil : $0 }
                ))
                TextField("Notas", text: Binding(
                    get: { movement.notes ?? "" },
                    set: { movement.notes = $0.isEmpty ? nil : $0 }
                ))
            }
            Section("Vista previa") {
                Text(movement.summaryLine)
                    .font(.system(.body, design: .monospaced))
            }
        }
        .ogListChrome()
        .ogPinnedTransparentNav("Movimiento WOD")
        .onAppear {
            seedSetsIfNeeded()
            maleWeightDraft = movement.weightMaleKg.map { String(format: "%g", $0) } ?? ""
            femaleWeightDraft = movement.weightFemaleKg.map { String(format: "%g", $0) } ?? ""
        }
    }

    private func weightField(
        text: Binding<String>,
        column: Int,
        nextColumn: Int?
    ) -> some View {
        let id = OGSetFieldID(rowID: weightFieldRowID, column: column)
        return OGNumericTextField(
            text: text,
            allowsDecimal: true,
            fontSize: 16,
            autoFocus: false,
            isFocused: weightFieldFocus == id,
            submitTitle: nextColumn == nil ? "✓" : "Siguiente",
            onFocused: { weightFieldFocus = id },
            onFocusLost: {
                commitWeightDraft(column: column)
                if weightFieldFocus == id { weightFieldFocus = nil }
            },
            onCommit: {
                commitWeightDraft(column: column)
                weightFieldFocus = nextColumn.map {
                    OGSetFieldID(rowID: weightFieldRowID, column: $0)
                }
            }
        )
        .frame(width: 80, height: 44)
        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func commitWeightDraft(column: Int) {
        if column == 0 {
            movement.weightMaleKg = Double(maleWeightDraft.replacingOccurrences(of: ",", with: "."))
            applyMovementWeightToEmptySets()
        } else {
            movement.weightFemaleKg = Double(femaleWeightDraft.replacingOccurrences(of: ",", with: "."))
        }
    }

    private func seedSetsIfNeeded() {
        guard !didSeedSets, !movement.isRest else { return }
        didSeedSets = true
        if let block {
            draftSets = block.plannedSets(for: movement)
        } else {
            draftSets = movement.plannedSetsFromReps
        }
        if draftSets.isEmpty {
            draftSets = [PlannedSet(targetReps: movement.reps ?? 10, targetWeightKg: movement.weightMaleKg)]
        }
    }

    private func wodSetRow(index: Int) -> some View {
        let style = loggingStyle
        let catalogName = CrossFitGlossary.resolveCatalogName(movement.name, notes: movement.notes)
        let catalogExercise = store.state.exercises.first {
            $0.name.localizedCaseInsensitiveCompare(catalogName) == .orderedSame
        }
        let oldSets = catalogExercise.flatMap { store.cachedLastWorkingSession(for: $0.id)?.sets }
        let oldSet = (oldSets?.indices.contains(index) == true) ? oldSets?[index] : nil
        return VStack(alignment: .leading, spacing: 6) {
            OGSetEntryRow(
                rowID: draftSets[index].id,
                index: index + 1,
                previous: OGSetEntryRow.previousText(oldSet),
                firstValue: style == .loadAndReps
                    ? (draftSets[index].targetWeightKg.map { String(format: "%g", $0) } ?? "0")
                    : "\(draftSets[index].targetReps)",
                secondValue: style == .loadAndReps ? "\(draftSets[index].targetReps)" : nil,
                firstAllowsDecimal: style == .loadAndReps && resolvedLoadField == .weightKg,
                rir: draftSets[index].targetRir,
                showsRIR: style.usesRIR,
                onRIRChange: { value in
                    draftSets[index].targetRir = value
                    writeSetsToMovement()
                },
                focus: $focusedSetField,
                onFirstCommit: { text in
                    if style == .loadAndReps {
                        let normalized = text.replacingOccurrences(of: ",", with: ".")
                        if let parsed = Double(normalized) {
                            let value = resolvedLoadField == .deficitCm
                                ? min(60, max(0, parsed))
                                : max(0, parsed)
                            draftSets[index].targetWeightKg = value > 0 ? ((value * 10).rounded() / 10) : nil
                        } else if normalized.isEmpty {
                            draftSets[index].targetWeightKg = nil
                        }
                    } else if let parsed = Int(text) {
                        draftSets[index].targetReps = min(style.quantityCap, max(1, parsed))
                    }
                    writeSetsToMovement()
                },
                onSecondCommit: { text in
                    if let parsed = Int(text) {
                        draftSets[index].targetReps = min(style.quantityCap, max(1, parsed))
                        writeSetsToMovement()
                    }
                }
            )

        }
    }

    private func addSet() {
        guard draftSets.count < 20 else { return }
        let last = draftSets.last
        draftSets.append(
            PlannedSet(
                targetReps: last?.targetReps ?? movement.reps ?? 10,
                targetWeightKg: last?.targetWeightKg ?? movement.weightMaleKg,
                targetRir: last?.targetRir
            )
        )
        writeSetsToMovement()
    }

    private func removeSet(at index: Int) {
        guard draftSets.count > 1, draftSets.indices.contains(index) else { return }
        draftSets.remove(at: index)
        writeSetsToMovement()
    }

    private func applyMovementWeightToEmptySets() {
        guard let kg = movement.weightMaleKg else { return }
        for i in draftSets.indices where draftSets[i].targetWeightKg == nil {
            draftSets[i].targetWeightKg = kg
        }
        writeSetsToMovement()
    }

    /// Persiste series explícitas (reps/peso/RIR) para que Apuntar/Empezar coincidan.
    private func writeSetsToMovement() {
        movement.explicitPlannedSets = draftSets
        let repsList = draftSets.map(\.targetReps)
        if loggingStyle == .machineWork {
            // En erg la cantidad de la 1.ª serie alimenta cal o metros prescritos.
            let qty = repsList.first
            switch movement.prescribedQuantityUnit {
            case .calories:
                movement.calories = qty
                if movement.distanceMeters == nil { movement.reps = nil }
            case .meters:
                movement.distanceMeters = qty
                if movement.calories == nil { movement.reps = nil }
            case .reps:
                movement.reps = qty
            }
            movement.repScheme = repsList.count > 1 ? repsList : nil
        } else if repsList.count <= 1 {
            movement.repScheme = nil
            movement.reps = repsList.first
        } else {
            movement.repScheme = repsList
            movement.reps = nil
        }
        if let kg = draftSets.compactMap(\.targetWeightKg).first {
            movement.weightMaleKg = kg
        }
    }
}

// MARK: - Strength exercise editor + picker

struct RoutineExerciseEditor: View {
    @Environment(ReperaStore.self) private var store
    var exerciseName: String
    var exerciseId: UUID
    @Binding var item: RoutineExercise

    private var exercise: Exercise? {
        store.state.exercises.first { $0.id == exerciseId }
    }

    private var weightStep: Double { store.state.settings.weightIncrementKg }

    private var referenceSet: PlannedSet {
        item.plannedSets.first ?? PlannedSet(targetReps: 8)
    }

    var body: some View {
        Form {
            if let exercise {
                Section {
                    ExerciseArtView(exercise: exercise, showBadge: false, showStepCaptions: false)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            if exercise?.loggingStyle == .loadAndReps {
                Section {
                    ExerciseLoadGuideCard(
                        exerciseId: exerciseId,
                        targetReps: referenceSet.targetReps,
                        targetRir: referenceSet.targetRir,
                        onApplySuggestedKg: { kg in
                            applySuggestedLoad(kg)
                        },
                        onApplyLastSession: { last in
                            applyLastSession(last)
                        }
                    )
                    .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                    .listRowBackground(OG.surface)
                } header: {
                    Text("Referencia")
                } footer: {
                    Text("Aplicar escala la última sesión al kg sugerido (misma progresión, reps y RIR).")
                }
            }

            Section {
                if let exercise, exercise.loggingStyle == .machineWork, exercise.allowsCalorieOrDistanceToggle {
                    Picker("Unidad de cardio", selection: Binding(
                        get: { item.quantityUnit ?? exercise.defaultQuantityUnit },
                        set: { item.quantityUnit = $0 }
                    )) {
                        Text("Calorías").tag(ExerciseQuantityUnit.calories)
                        Text("Metros").tag(ExerciseQuantityUnit.meters)
                    }
                    .pickerStyle(.segmented)
                }
                OGSetEntryHeader(
                    firstTitle: exercise?.isMobility == true ? "Tiempo (s)" : (exercise?.loggingStyle == .loadAndReps
                        ? (exercise?.loadField == .deficitCm ? "Déficit" : "KG")
                        : (exercise?.loggingStyle == .machineWork
                            ? (item.quantityUnit ?? exercise?.defaultQuantityUnit ?? .calories).shortLabel
                            : (exercise?.quantityFieldLabel ?? "Reps"))),
                    secondTitle: exercise?.isMobility == true
                        ? (exercise?.isMobilityHold == true ? nil : "Reps")
                        : (exercise?.loggingStyle == .loadAndReps ? "Reps" : nil),
                    showsRIR: exercise?.loggingStyle.usesRIR ?? false
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 4, trailing: 16))

                ForEach(Array(item.plannedSets.enumerated()), id: \.element.id) { index, _ in
                    PlannedSetConfigRow(
                        index: index + 1,
                        set: binding(for: index),
                        weightStep: weightStep,
                        exerciseStyle: exercise?.loggingStyle ?? .loadAndReps,
                        isMobility: exercise?.isMobility ?? false,
                        isMobilityHold: exercise?.isMobilityHold ?? false,
                        previous: {
                            let sets = store.cachedLastWorkingSession(for: exerciseId)?.sets
                            return (sets?.indices.contains(index) == true) ? sets?[index] : nil
                        }(),
                        canDelete: item.plannedSets.count > 1,
                        onDelete: { deleteSet(at: index) }
                    )
                }

                Button {
                    addSet()
                } label: {
                    Label("Añadir serie", systemImage: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(OG.accent)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            } header: {
                Text("Objetivo por serie")
            } footer: {
                Text(exercise?.isMobility == true
                     ? "Objetivo de duración por serie en segundos. Las posturas se registran por tiempo y la movilidad dinámica por repeticiones y tiempo; sin kg ni RIR."
                     : (exercise?.loggingStyle == .machineWork
                     ? "Introduce calorías o metros por serie; el cardio no utiliza kilogramos."
                     : "Cada serie puede tener cantidad, peso y RIR distintos según el movimiento."))
            }

            Section {
                NavigationLink("Ver ficha del ejercicio") {
                    ExerciseDetailView(exerciseId: exerciseId)
                }
            }
        }
        .listStyle(.insetGrouped)
        .ogListChrome()
        .ogPinnedTransparentNav(exerciseName)
        .onAppear {
            if item.plannedSets.isEmpty {
                let style = exercise?.loggingStyle ?? .loadAndReps
                let qty = style == .machineWork
                    ? (exercise?.defaultQuantityUnit == .meters ? 500 : 15)
                    : (exercise?.isMobility == true ? (exercise?.isMobilityHold == true ? 1 : 8) : (style == .repsAndTime ? 50 : 8))
                item.plannedSets = [PlannedSet(targetReps: qty, targetWeightKg: nil,
                    targetDurationSeconds: exercise?.isMobility == true ? (exercise?.isMobilityHold == true ? 30 : 60) : nil)]
            }
        }
    }

    /// Escala la última sesión al kg sugerido: misma progresión de pesos, mismas reps y RIR.
    private func applySuggestedLoad(_ kg: Double) {
        guard kg > 0 else { return }
        let step = max(weightStep, 0.5)
        let fallbackRir = referenceSet.targetRir ?? 2

        if let last = store.cachedLastWorkingSession(for: exerciseId),
           !last.sets.isEmpty {
            let anchor = last.topSet?.weightKg
                ?? last.sets.compactMap(\.weightKg).first
            if let anchor, anchor > 0 {
                let ratio = kg / anchor
                item.plannedSets = last.sets.map { set in
                    let scaled: Double? = {
                        guard let w = set.weightKg, w > 0 else { return kg }
                        let raw = w * ratio
                        let rounded = (raw / step).rounded() * step
                        return rounded > 0 ? rounded : nil
                    }()
                    return PlannedSet(
                        targetReps: set.reps,
                        targetWeightKg: scaled,
                        targetRir: set.rir ?? fallbackRir
                    )
                }
            } else {
                item.plannedSets = last.sets.map { set in
                    PlannedSet(
                        targetReps: set.reps,
                        targetWeightKg: kg,
                        targetRir: set.rir ?? fallbackRir
                    )
                }
            }
            return
        }

        for i in item.plannedSets.indices {
            item.plannedSets[i].targetWeightKg = kg
            if item.plannedSets[i].targetRir == nil {
                item.plannedSets[i].targetRir = fallbackRir
            }
        }
    }

    private func applyLastSession(_ last: ExerciseLastSession) {
        guard !last.sets.isEmpty else { return }
        item.plannedSets = last.sets.map { set in
            PlannedSet(
                targetReps: set.reps,
                targetWeightKg: set.weightKg,
                targetRir: set.rir
            )
        }
    }

    private func binding(for index: Int) -> Binding<PlannedSet> {
        Binding(
            get: {
                guard item.plannedSets.indices.contains(index) else {
                    return PlannedSet(targetReps: 8)
                }
                return item.plannedSets[index]
            },
            set: { newValue in
                guard item.plannedSets.indices.contains(index) else { return }
                item.plannedSets[index] = newValue
            }
        )
    }

    private func addSet() {
        guard item.plannedSets.count < 12 else { return }
        let last = item.plannedSets.last
        item.plannedSets.append(
            PlannedSet(
                targetReps: last?.targetReps ?? 8,
                targetWeightKg: last?.targetWeightKg,
                targetDurationSeconds: last?.targetDurationSeconds,
                targetRir: last?.targetRir
            )
        )
    }

    private func deleteSet(at index: Int) {
        guard item.plannedSets.count > 1, item.plannedSets.indices.contains(index) else { return }
        item.plannedSets.remove(at: index)
    }
}

/// Fila de objetivo: peso / reps / RIR. Borrar serie = swipe (sin icono de papelera).
private struct PlannedSetConfigRow: View {
    var index: Int
    @Binding var set: PlannedSet
    var weightStep: Double
    var exerciseStyle: ExerciseLoggingStyle = .loadAndReps
    var isMobility: Bool = false
    var isMobilityHold: Bool = false
    var previous: ExerciseLastSession.WorkSet? = nil
    var canDelete: Bool
    var onDelete: () -> Void
    @FocusState private var focusedSetField: OGSetFieldID?

    var body: some View {
        OGSetEntryRow(
            rowID: set.id,
            index: index,
            previous: OGSetEntryRow.previousText(previous),
            firstValue: isMobility ? "\(set.targetDurationSeconds ?? (isMobilityHold ? 30 : 60))"
                : (exerciseStyle == .loadAndReps
                ? (set.targetWeightKg.map { String(format: "%g", $0) } ?? "0")
                : "\(set.targetReps)"),
            secondValue: isMobility
                ? (isMobilityHold ? nil : "\(set.targetReps)")
                : (exerciseStyle == .loadAndReps ? "\(set.targetReps)" : nil),
            firstAllowsDecimal: exerciseStyle == .loadAndReps,
            rir: set.targetRir,
            showsRIR: exerciseStyle.usesRIR,
            onRIRChange: { set.targetRir = $0 },
            focus: $focusedSetField,
            onFirstCommit: { text in
                if isMobility {
                    if let seconds = Int(text), seconds > 0 { set.targetDurationSeconds = min(3600, seconds) }
                } else if exerciseStyle == .loadAndReps {
                    let normalized = text.replacingOccurrences(of: ",", with: ".")
                    if normalized.isEmpty {
                        set.targetWeightKg = nil
                    } else if let value = Double(normalized) {
                        set.targetWeightKg = value > 0 ? ((value * 10).rounded() / 10) : nil
                    }
                } else if let value = Int(text), value > 0 {
                    set.targetReps = min(exerciseStyle.quantityCap, value)
                }
            },
            onSecondCommit: { text in
                if let value = Int(text), value > 0 {
                    set.targetReps = min(exerciseStyle.quantityCap, value)
                }
            }
        )
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if canDelete {
                OGSwipeDeleteButton(action: onDelete)
            }
        }
    }
}

struct ExercisePickerView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var embedsNavigationStack = true
    var onPick: (Exercise) -> Void

    var body: some View {
        Group {
            if embedsNavigationStack {
                NavigationStack { pickerContent }
            } else {
                pickerContent
            }
        }
    }

    private var pickerContent: some View {
        ExerciseCatalogSearchList(
            exercises: store.state.exercises,
            prompt: "Buscar ejercicio"
        ) { exercise in
            onPick(exercise)
            if embedsNavigationStack { dismiss() }
        }
        .ogPinnedTransparentNav("Elegir ejercicio")
        .toolbar {
            if embedsNavigationStack {
                ToolbarItem(placement: .topBarLeading) {
                    CloseToolbarButton(action: { dismiss() }, large: false)
                }
            }
        }
    }
}

/// Alta de un movimiento libre como página push; se valida antes de añadirlo.
private struct FreeWODMovementCreatePage: View {
    @Environment(\.dismiss) private var dismiss
    var onCreate: (WODMovement) -> Void

    @State private var name = ""
    @State private var repsText = "10"
    @State private var maleWeightText = ""
    @State private var femaleWeightText = ""
    @State private var numericGroupID = UUID()
    @FocusState private var numericFocus: OGSetFieldID?

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Form {
            Section("Movimiento") {
                TextField("Nombre", text: $name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                numericRow("Repeticiones", text: $repsText, column: 0, nextColumn: 1, decimal: false)
            }
            Section("Carga opcional · kg") {
                numericRow("Carga masculina", text: $maleWeightText, column: 1, nextColumn: 2, decimal: true)
                numericRow("Carga femenina", text: $femaleWeightText, column: 2, nextColumn: nil, decimal: true)
            }
        }
        .ogListChrome()
        .ogPinnedTransparentNav("Nuevo movimiento")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Añadir") {
                    guard let reps = Int(repsText), reps > 0 else { return }
                    let movement = WODMovement(
                        name: trimmedName,
                        reps: reps,
                        weightMaleKg: Double(maleWeightText.replacingOccurrences(of: ",", with: ".")),
                        weightFemaleKg: Double(femaleWeightText.replacingOccurrences(of: ",", with: "."))
                    )
                    onCreate(movement)
                    dismiss()
                }
                .disabled(trimmedName.isEmpty || (Int(repsText) ?? 0) <= 0)
            }
        }
    }
    private func numericRow(
        _ label: String,
        text: Binding<String>,
        column: Int,
        nextColumn: Int?,
        decimal: Bool
    ) -> some View {
        let field = OGSetFieldID(rowID: numericGroupID, column: column)
        return HStack(spacing: 10) {
            Text(label)
                .foregroundStyle(OG.label)
            Spacer(minLength: 8)
            OGNumericTextField(
                text: text,
                allowsDecimal: decimal,
                fontSize: 17,
                autoFocus: false,
                isFocused: numericFocus == field,
                submitTitle: nextColumn == nil ? "✓" : "Siguiente",
                onFocused: { numericFocus = field },
                onFocusLost: {
                    if numericFocus == field { numericFocus = nil }
                },
                onCommit: {
                    numericFocus = nextColumn.map {
                        OGSetFieldID(rowID: numericGroupID, column: $0)
                    }
                }
            )
            .frame(width: 105, height: 44)
            .padding(.horizontal, 8)
            .background(OG.surface2, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
    }

}

/// Selección del formato como subpágina, nunca confirmationDialog.
private struct WODFormatPickerPage: View {
    var onPick: (WODFormat?) -> Void

    var body: some View {
        List {
            Button {
                onPick(nil)
            } label: {
                Label("Sin formato · libre", systemImage: "minus.circle")
                    .foregroundStyle(OG.label)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            .buttonStyle(.plain)

            ForEach(WODFormat.allCases, id: \.self) { format in
                Button {
                    onPick(format)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(format.displayName).foregroundStyle(OG.label)
                            Text(format.detail)
                                .font(.caption)
                                .foregroundStyle(OG.label2)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(OG.label3)
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .ogListChrome()
        .ogPinnedTransparentNav("Formato del bloque")
    }
}

// MARK: - Importar bloques de otra rutina

private struct RoutineImportPickerSheet: View {
    var routines: [Routine]
    var onPick: (Routine) -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            OGPageHeader(title: "Añadir rutina") {
                CloseToolbarButton(action: onCancel, large: true)
            }
            .padding(.top, 4)

            Text("Se copian los bloques; el título y el día de esta rutina no cambian.")
                .font(.footnote)
                .foregroundStyle(OG.label2)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(routines.enumerated()), id: \.element.id) { index, source in
                    if index > 0 {
                        Divider().opacity(0.35).padding(.leading, 14)
                    }
                    Button {
                        onPick(source)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(source.title)
                                    .foregroundStyle(OG.label)
                                Text(importSubtitle(source))
                                    .font(.caption)
                                    .foregroundStyle(OG.label2)
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(OG.accent)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                }
            }
            .background(OG.surface.opacity(0.55), in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
        }
        .padding(.horizontal, OG.pad)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .ogFittedHeight()
        .ogFittedSheet()
    }

    private func importSubtitle(_ routine: Routine) -> String {
        let strength = routine.blocks.filter { $0.kind == .strength }.flatMap(\.exercises).count
        let wods = routine.blocks.filter { $0.kind == .wod }.count
        var parts: [String] = []
        if strength > 0 { parts.append("\(strength) ej.") }
        if wods > 0 { parts.append("\(wods) WOD") }
        if parts.isEmpty { parts.append("\(routine.blocks.count) bloque\(routine.blocks.count == 1 ? "" : "s")") }
        return parts.joined(separator: " · ")
    }
}


/// Línea de inserción real entre elementos, no sobre la fila arrastrable.
/// La altura táctil sigue siendo suficiente incluso con la línea en reposo.
private struct RoutineReorderDropSlot: View {
    var onDrop: (String) -> Bool
    @State private var highlighted = false

    var body: some View {
        HStack(spacing: 8) {
            Capsule()
                .fill(highlighted ? OG.accent : OG.surface2)
                .frame(height: highlighted ? 5 : 2)
            if highlighted {
                Text("Soltar aquí")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(OG.accent)
                Image(systemName: "arrow.down.to.line")
                    .foregroundStyle(OG.accent)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: highlighted ? 42 : 30)
        .animation(.easeOut(duration: 0.12), value: highlighted)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .dropDestination(
            for: String.self,
            action: { tokens, _ in
                guard let token = tokens.first else { return false }
                return onDrop(token)
            },
            isTargeted: { highlighted = $0 }
        )
        .accessibilityLabel("Soltar aquí")
    }
}
