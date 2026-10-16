import GymbroDomain
import SwiftUI

private enum DiarioSection: String, CaseIterable, Identifiable {
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

/// Diario: Programado (días → asignación) y Rutinas (plantillas reutilizables).
struct PlanView: View {
    @Environment(GymbroStore.self) private var store
    @State private var section: DiarioSection = .schedule
    @State private var editing: Routine?
    @State private var isCreating = false
    @State private var confirmClearSchedule = false
    @State private var assigningDay: Int?
    @State private var dayActionRoutine: Routine?
    @State private var copyWeekFlash: Int?

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
            .ogListChrome()
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
            .sheet(item: $editing) { routine in
                DayEditorView(routine: routine, mode: .plan(isNew: isCreating))
                    .ogSheetCorners()
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
            .confirmationDialog(
                dayActionRoutine?.title ?? "Día",
                isPresented: Binding(
                    get: { dayActionRoutine != nil },
                    set: { if !$0 { dayActionRoutine = nil } }
                ),
                titleVisibility: .visible
            ) {
                if let routine = dayActionRoutine {
                    Button("Editar rutina") {
                        isCreating = false
                        editing = routine
                        dayActionRoutine = nil
                    }
                    Button("Cambiar asignación") {
                        assigningDay = routine.weekday
                        dayActionRoutine = nil
                    }
                    Button("Quitar del día", role: .destructive) {
                        store.assignRoutine(routine.id, toWeekday: nil)
                        dayActionRoutine = nil
                    }
                    Button("Cancelar", role: .cancel) {
                        dayActionRoutine = nil
                    }
                }
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

    // MARK: - Programado (solo asignación Lu–Do)

    @ViewBuilder
    private var scheduleContent: some View {
        Section {
            ForEach(1...7, id: \.self) { day in
                let routine = store.routine(forWeekday: day)
                Button {
                    if let routine {
                        dayActionRoutine = routine
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
                        Button(role: .destructive) {
                            store.assignRoutine(routine.id, toWeekday: nil)
                        } label: {
                            Label("Quitar", systemImage: "xmark")
                        }
                        .tint(OG.red)
                    }
                }
            }
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
                        Button(role: .destructive) {
                            store.deleteRoutine(routine.id)
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                        .tint(OG.red)
                        if routine.weekday != nil {
                            Button {
                                store.assignRoutine(routine.id, toWeekday: nil)
                            } label: {
                                Label("Desasignar", systemImage: "calendar.badge.minus")
                            }
                            .tint(OG.orange)
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            store.setRoutineFavorite(routine.id, isFavorite: !routine.isFavorite)
                        } label: {
                            Label(
                                routine.isFavorite ? "Quitar favorito" : "Favorito",
                                systemImage: routine.isFavorite ? "star.slash" : "star"
                            )
                        }
                        .tint(OG.yellow)
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

enum DayEditorMode: Equatable {
    case plan(isNew: Bool)
    /// Entreno suelto de un día concreto (Inicio); no forma parte del plan semanal.
    case oneOff(isNew: Bool)
    case session
    case favorite(isNew: Bool)
}

struct DayEditorView: View {
    @Environment(GymbroStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State var routine: Routine
    var mode: DayEditorMode
    var onSessionStarted: (() -> Void)? = nil
    /// Cierre explícito cuando se presenta como página (push), no modal.
    var onClose: (() -> Void)? = nil
    var embedsNavigationStack: Bool = true
    /// Cabecera con X arriba y título debajo (flujo Entreno → Editar).
    var usesPageCloseHeader: Bool = false
    @State private var pickExerciseForBlock: UUID?
    @State private var pickMovementForBlock: UUID?
    @State private var showRoutinePicker = false
    @State private var saveAsFavorite = false

    var body: some View {
        Group {
            if embedsNavigationStack {
                NavigationStack { editorForm }
                    .preferredColorScheme(.dark)
            } else {
                editorForm
                    .preferredColorScheme(.dark)
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
                    Toggle("También en favoritos", isOn: $routine.isFavorite)
                case .oneOff:
                    if let date = routine.scheduledDate {
                        Text(SpanishDate.long(date))
                            .foregroundStyle(OG.label2)
                    }
                    scheduledTimeControls
                    Toggle("También en favoritos", isOn: $routine.isFavorite)
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
                    Toggle("Guardar en favoritos", isOn: $saveAsFavorite)
                }
            } footer: {
                switch mode {
                case .session:
                    Text("Solo empieza la sesión. El plan semanal se gestiona en Diario.")
                case .favorite:
                    Text("Los favoritos se reutilizan desde Crear. Opcionalmente puedes asignarlos a un día en Programado.")
                case .oneOff:
                    Text("Entreno solo para este día. No aparece en el plan semanal de Diario.")
                case .plan:
                    Text("La rutina es reutilizable. En Programado puedes cambiar el día sin editar el contenido.")
                }
            }

            ForEach(Array(routine.blocks.enumerated()), id: \.element.id) { index, block in
                Section {
                    HStack {
                        TextField("Nombre", text: $routine.blocks[index].title)
                        Button(role: .destructive) {
                            routine.blocks.remove(at: index)
                        } label: {
                            Image(systemName: "trash").foregroundStyle(OG.orange)
                        }
                    }
                    if block.kind == .strength {
                        strengthBlock(index: index)
                    } else {
                        wodBlock(index: index)
                    }
                } header: {
                    Text(block.kind == .wod ? "Bloque · \(block.headerLabel)" : "Bloque")
                }
            }

            Section {
                Button {
                    routine.blocks.append(.strength(title: "Bloque"))
                } label: {
                    Label("Añadir bloque", systemImage: "square.stack.3d.up")
                }
                Menu {
                    ForEach(WODFormat.allCases, id: \.self) { format in
                        Button(format.displayName) {
                            routine.blocks.append(.wod(format: format))
                        }
                    }
                } label: {
                    Label("Añadir WOD", systemImage: "timer")
                }
                if !importableRoutines.isEmpty {
                    Button {
                        showRoutinePicker = true
                    } label: {
                        Label("Añadir rutina", systemImage: "list.bullet.rectangle")
                    }
                }
            } footer: {
                switch mode {
                case .session:
                    Text("Bloques de fuerza (series/reps) y WODs (AMRAP, EMOM, RFT, Tabata…). También puedes pegar una rutina existente.")
                case .oneOff, .plan, .favorite:
                    Text("Añadir rutina copia los bloques de una plantilla. AMRAP / EMOM / RFT / Tabata se configuran en cada WOD.")
                }
            }
        }
        .ogListChrome()
        .ogFixedTopBar(navTitle) {
            HStack(spacing: 8) {
                // Push (Entreno → Editar): X a la izquierda del check. Modal Diario: solo check (swipe para cerrar).
                if usesPageCloseHeader {
                    CloseToolbarButton(action: { closeEditor() }, large: true)
                }
                OGToolbarGlassButton(
                    systemName: "checkmark",
                    accessibilityLabel: confirmTitle,
                    tint: .white,
                    appliesGlass: true,
                    glassTint: OG.accent
                ) {
                    confirm()
                }
                .opacity(canConfirm ? 1 : 0.4)
                .disabled(!canConfirm)
            }
        }
        .navigationBarBackButtonHidden(usesPageCloseHeader || embedsNavigationStack)
        .sheet(item: Binding(
            get: { pickExerciseForBlock.map { IDBox(id: $0) } },
            set: { pickExerciseForBlock = $0?.id }
        )) { box in
            ExercisePickerView { exercise in
                if let idx = routine.blocks.firstIndex(where: { $0.id == box.id }) {
                    let sets = (0..<3).map { _ in PlannedSet(targetReps: 8, targetWeightKg: nil) }
                    routine.blocks[idx].exercises.append(
                        RoutineExercise(exerciseId: exercise.id, plannedSets: sets)
                    )
                }
                pickExerciseForBlock = nil
            }
        }
        .sheet(item: Binding(
            get: { pickMovementForBlock.map { IDBox(id: $0) } },
            set: { pickMovementForBlock = $0?.id }
        )) { box in
            ExercisePickerView { exercise in
                if let idx = routine.blocks.firstIndex(where: { $0.id == box.id }) {
                    routine.blocks[idx].movements.append(
                        WODMovement(exerciseId: exercise.id, name: exercise.name, reps: 10)
                    )
                }
                pickMovementForBlock = nil
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
        switch mode {
        case .session: return "Crear entreno"
        case .oneOff(let isNew): return isNew ? "Entreno del día" : "Editar entreno"
        case .favorite(let isNew): return isNew ? "Nuevo favorito" : "Editar favorito"
        case .plan(let isNew):
            return isNew ? "Nueva rutina" : "Editar rutina"
        }
    }

    private var confirmTitle: String {
        switch mode {
        case .session: return "Empezar"
        case .plan, .favorite, .oneOff: return "Guardar"
        }
    }

    private var canConfirm: Bool {
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
        switch mode {
        case .plan:
            var draft = routine
            draft.scheduledDate = nil
            if draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                draft.title = "Rutina"
            }
            store.saveRoutine(draft)
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
            store.saveRoutine(draft)
            closeEditor()
        case .favorite:
            var draft = routine
            draft.isFavorite = true
            if draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                draft.title = "Favorito"
            }
            store.saveRoutine(draft)
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
                store.saveRoutine(draft)
            }
            store.startSession(from: draft)
            closeEditor()
            onSessionStarted?()
        }
    }

    private struct IDBox: Identifiable { var id: UUID }

    @ViewBuilder
    private func strengthBlock(index: Int) -> some View {
        ForEach(Array(routine.blocks[index].exercises.enumerated()), id: \.element.id) { exIndex, item in
            if let ex = store.state.exercises.first(where: { $0.id == item.exerciseId }) {
                NavigationLink {
                    RoutineExerciseEditor(
                        exerciseName: ex.name,
                        exerciseId: ex.id,
                        item: Binding(
                            get: { routine.blocks[index].exercises[exIndex] },
                            set: { routine.blocks[index].exercises[exIndex] = $0 }
                        )
                    )
                } label: {
                    HStack(spacing: 12) {
                        ExerciseThumb(exercise: ex, size: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ex.name)
                            Text(setSummary(item)).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        routine.blocks[index].exercises.remove(at: exIndex)
                    } label: { Label("Quitar", systemImage: "trash") }
                }
            }
        }
        Button("Añadir ejercicio") { pickExerciseForBlock = routine.blocks[index].id }
    }

    @ViewBuilder
    private func wodBlock(index: Int) -> some View {
        Picker("Formato", selection: Binding(
            get: { routine.blocks[index].wodFormat ?? .amrap },
            set: { new in
                routine.blocks[index].wodFormat = new
                if new == .tabata {
                    routine.blocks[index].workSeconds = routine.blocks[index].workSeconds ?? 20
                    routine.blocks[index].restSeconds = routine.blocks[index].restSeconds ?? 10
                    routine.blocks[index].rounds = routine.blocks[index].rounds ?? 8
                }
                if new == .forTime {
                    routine.blocks[index].rounds = routine.blocks[index].rounds ?? 4
                    routine.blocks[index].timeCapMinutes = routine.blocks[index].timeCapMinutes ?? 12
                }
                if new == .amrap || new == .emom {
                    routine.blocks[index].timeCapMinutes = routine.blocks[index].timeCapMinutes ?? 12
                }
            }
        )) {
            ForEach(WODFormat.allCases, id: \.self) { Text($0.displayName).tag($0) }
        }

        if let format = routine.blocks[index].wodFormat {
            Text(format.detail).font(.caption).foregroundStyle(.secondary)
        }

        if routine.blocks[index].wodFormat == .amrap || routine.blocks[index].wodFormat == .forTime
            || routine.blocks[index].wodFormat == .emom || routine.blocks[index].wodFormat == .chipper {
            Stepper(
                "Time cap: \(routine.blocks[index].timeCapMinutes ?? 12) min",
                value: Binding(
                    get: { routine.blocks[index].timeCapMinutes ?? 12 },
                    set: { routine.blocks[index].timeCapMinutes = $0 }
                ),
                in: 1...60
            )
        }
        if routine.blocks[index].wodFormat == .forTime || routine.blocks[index].wodFormat == .deathBy
            || routine.blocks[index].wodFormat == .emom {
            Stepper(
                "Rondas: \(routine.blocks[index].rounds ?? (routine.blocks[index].wodFormat == .emom ? 8 : 4))",
                value: Binding(
                    get: { routine.blocks[index].rounds ?? (routine.blocks[index].wodFormat == .emom ? 8 : 4) },
                    set: { routine.blocks[index].rounds = $0 }
                ),
                in: 1...30
            )
        }
        if routine.blocks[index].wodFormat == .forTime {
            Stepper(
                "Descanso entre rondas: \(routine.blocks[index].restBetweenRoundsSeconds ?? 0)s",
                value: Binding(
                    get: { routine.blocks[index].restBetweenRoundsSeconds ?? 0 },
                    set: { routine.blocks[index].restBetweenRoundsSeconds = $0 }
                ),
                in: 0...300,
                step: 15
            )
        }
        if routine.blocks[index].wodFormat == .emom {
            Stepper(
                "Intervalo: \(routine.blocks[index].emomIntervalSeconds ?? 60)s",
                value: Binding(
                    get: { routine.blocks[index].emomIntervalSeconds ?? 60 },
                    set: { routine.blocks[index].emomIntervalSeconds = $0 }
                ),
                in: 30...180,
                step: 15
            )
        }
        if routine.blocks[index].wodFormat == .tabata {
            Stepper(
                "Trabajo: \(routine.blocks[index].workSeconds ?? 20)s",
                value: Binding(
                    get: { routine.blocks[index].workSeconds ?? 20 },
                    set: { routine.blocks[index].workSeconds = $0 }
                ),
                in: 5...60,
                step: 5
            )
            Stepper(
                "Descanso: \(routine.blocks[index].restSeconds ?? 10)s",
                value: Binding(
                    get: { routine.blocks[index].restSeconds ?? 10 },
                    set: { routine.blocks[index].restSeconds = $0 }
                ),
                in: 5...60,
                step: 5
            )
            Stepper(
                "Rondas: \(routine.blocks[index].rounds ?? 8)",
                value: Binding(
                    get: { routine.blocks[index].rounds ?? 8 },
                    set: { routine.blocks[index].rounds = $0 }
                ),
                in: 1...30
            )
        }

        ForEach(Array(routine.blocks[index].movements.enumerated()), id: \.element.id) { mIndex, move in
            NavigationLink {
                WODMovementEditor(movement: Binding(
                    get: { routine.blocks[index].movements[mIndex] },
                    set: { routine.blocks[index].movements[mIndex] = $0 }
                ))
            } label: {
                HStack(spacing: 12) {
                    if move.isRest {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(OG.surface2)
                            Image(systemName: "pause.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(OG.label3)
                        }
                        .frame(width: 40, height: 40)
                    } else {
                        ExerciseThumb(exercise: resolvedExercise(for: move), size: 40)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(move.isRest ? "Descanso" : (resolvedExercise(for: move).name))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(OG.label)
                        Text(move.summaryLine)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            .swipeActions {
                Button(role: .destructive) {
                    routine.blocks[index].movements.remove(at: mIndex)
                } label: { Label("Quitar", systemImage: "trash") }
            }
        }

        Button("Añadir ejercicio al WOD") { pickMovementForBlock = routine.blocks[index].id }
        Button("Añadir descanso") {
            routine.blocks[index].movements.append(
                WODMovement(name: "REST", isRest: true, restSeconds: 60)
            )
        }
        Button("Añadir movimiento libre") {
            routine.blocks[index].movements.append(
                WODMovement(name: "Movimiento", reps: 10)
            )
        }

        TextField("Notas / texto del WOD", text: Binding(
            get: { routine.blocks[index].wodNotes ?? "" },
            set: { routine.blocks[index].wodNotes = $0.isEmpty ? nil : $0 }
        ), axis: .vertical)
        .lineLimit(2...5)
    }

    private func setSummary(_ item: RoutineExercise) -> String {
        let sets = item.plannedSets.count
        let reps = item.plannedSets.first?.targetReps ?? 8
        let weight = item.plannedSets.first?.targetWeightKg.map { String(format: "%g kg", $0) } ?? "—"
        return "\(sets)×\(reps) · \(weight)"
    }

    /// Resuelve el ejercicio del catálogo para miniaturas en bloques WOD (EMOM, AMRAP…).
    private func resolvedExercise(for move: WODMovement) -> Exercise {
        if let id = move.exerciseId, let ex = store.state.exercises.first(where: { $0.id == id }) {
            return ex
        }
        if let match = store.state.exercises.first(where: {
            $0.name.localizedCaseInsensitiveCompare(move.name) == .orderedSame
        }) {
            return match
        }
        return Exercise(name: move.name, muscleGroup: "WOD", isCustom: true)
    }
}

// MARK: - WOD movement editor

struct WODMovementEditor: View {
    @Binding var movement: WODMovement

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
                Stepper("Reps: \(movement.reps ?? 0)", value: Binding(
                    get: { movement.reps ?? 0 },
                    set: { movement.reps = $0 == 0 ? nil : $0 }
                ), in: 0...200)
                Stepper("Metros: \(movement.distanceMeters ?? 0)", value: Binding(
                    get: { movement.distanceMeters ?? 0 },
                    set: { movement.distanceMeters = $0 == 0 ? nil : $0 }
                ), in: 0...5000, step: 50)
                HStack {
                    Text("Peso H/M (kg)")
                    TextField("50", text: Binding(
                        get: { movement.weightMaleKg.map { String(format: "%g", $0) } ?? "" },
                        set: { movement.weightMaleKg = Double($0.replacingOccurrences(of: ",", with: ".")) }
                    ))
                    .ogKeyboardDone()
                    .multilineTextAlignment(.trailing)
                    Text("/")
                    TextField("35", text: Binding(
                        get: { movement.weightFemaleKg.map { String(format: "%g", $0) } ?? "" },
                        set: { movement.weightFemaleKg = Double($0.replacingOccurrences(of: ",", with: ".")) }
                    ))
                    .ogKeyboardDone()
                    .multilineTextAlignment(.trailing)
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
    }
}

// MARK: - Strength exercise editor + picker

struct RoutineExerciseEditor: View {
    @Environment(GymbroStore.self) private var store
    var exerciseName: String
    var exerciseId: UUID
    @Binding var item: RoutineExercise

    private var exercise: Exercise? {
        store.state.exercises.first { $0.id == exerciseId }
    }

    private var weightStep: Double { store.state.settings.weightIncrementKg }

    var body: some View {
        Form {
            if let exercise {
                Section {
                    ExerciseArtView(exercise: exercise, showBadge: false, showStepCaptions: false)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }
            Section {
                NavigationLink("Ver ficha del ejercicio") {
                    ExerciseDetailView(exerciseId: exerciseId)
                }
            }
            Section("Superserie") {
                Picker("Grupo", selection: Binding(
                    get: { item.supersetGroup ?? 0 },
                    set: { item.supersetGroup = $0 == 0 ? nil : $0 }
                )) {
                    Text("Ninguna").tag(0)
                    Text("Superserie A").tag(1)
                    Text("Superserie B").tag(2)
                    Text("Superserie C").tag(3)
                }
            }
            Section {
                HStack(spacing: 8) {
                    Text("#")
                        .frame(width: 28, alignment: .center)
                    Text("PESO (KG)")
                        .frame(maxWidth: .infinity)
                    Text("REPS")
                        .frame(width: 88)
                    Text("RIR")
                        .frame(width: 52, alignment: .center)
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(OG.label3)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 0, trailing: 12))

                ForEach(Array(item.plannedSets.enumerated()), id: \.element.id) { index, _ in
                    PlannedSetConfigRow(
                        index: index + 1,
                        set: binding(for: index),
                        weightStep: weightStep,
                        canDelete: item.plannedSets.count > 1,
                        onDelete: { deleteSet(at: index) }
                    )
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                }

                Button {
                    addSet()
                } label: {
                    Label("Añadir serie", systemImage: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(OG.accent)
                }
            } header: {
                Text("Objetivo por serie")
            } footer: {
                Text("Cada serie puede tener peso, reps y RIR distintos.")
            }
        }
        .ogListChrome()
        .ogPinnedTransparentNav(exerciseName)
        .onAppear {
            if item.plannedSets.isEmpty {
                item.plannedSets = [PlannedSet(targetReps: 8, targetWeightKg: nil)]
            }
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
                targetRir: last?.targetRir
            )
        )
    }

    private func deleteSet(at index: Int) {
        guard item.plannedSets.count > 1, item.plannedSets.indices.contains(index) else { return }
        item.plannedSets.remove(at: index)
    }
}

/// Fila de objetivo: peso / reps / RIR independientes por serie.
private struct PlannedSetConfigRow: View {
    var index: Int
    @Binding var set: PlannedSet
    var weightStep: Double
    var canDelete: Bool
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("\(index)")
                .font(.system(size: 13, weight: .bold).monospacedDigit())
                .foregroundStyle(OG.label)
                .frame(width: 28, height: 28)
                .background(OG.surface2, in: Circle())

            OGRepeatStepper(
                display: set.targetWeightKg.map { String(format: "%g", $0) } ?? "—",
                keyboard: .decimalPad,
                onMinus: { bumpWeight(-weightStep) },
                onPlus: { bumpWeight(weightStep) },
                onCommitText: { text in
                    let normalized = text.replacingOccurrences(of: ",", with: ".")
                    if normalized.isEmpty || normalized == "—" {
                        set.targetWeightKg = nil
                    } else if let value = Double(normalized) {
                        set.targetWeightKg = value > 0 ? ((value * 10).rounded() / 10) : nil
                    }
                }
            )
            .frame(maxWidth: .infinity)

            OGRepeatStepper(
                display: "\(set.targetReps)",
                keyboard: .numberPad,
                onMinus: { set.targetReps = max(1, set.targetReps - 1) },
                onPlus: { set.targetReps = min(50, set.targetReps + 1) },
                onCommitText: { text in
                    if let value = Int(text), value > 0 {
                        set.targetReps = min(50, value)
                    }
                }
            )
            .frame(width: 96)

            Menu {
                Button("Sin RIR") { set.targetRir = nil }
                ForEach(0...5, id: \.self) { rir in
                    Button("\(rir)") { set.targetRir = Double(rir) }
                }
            } label: {
                Text(set.targetRir.map { String(format: "%g", $0) } ?? "RIR")
                    .font(.system(size: 13, weight: .semibold).monospacedDigit())
                    .foregroundStyle(set.targetRir == nil ? OG.label3 : OG.label)
                    .frame(width: 52, height: 36)
                    .background(OG.surface2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if canDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Eliminar", systemImage: "trash")
                }
            }
        }
    }

    private func bumpWeight(_ delta: Double) {
        let current = set.targetWeightKg ?? 0
        let next = max(0, ((current + delta) * 10).rounded() / 10)
        set.targetWeightKg = next > 0 ? next : nil
    }
}

struct ExercisePickerView: View {
    @Environment(GymbroStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    var onPick: (Exercise) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { exercise in
                    Button {
                        onPick(exercise)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            ExerciseThumb(exercise: exercise)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name).foregroundStyle(OG.label)
                                Text(pickerSubtitle(exercise))
                                    .font(.caption)
                                    .foregroundStyle(OG.label2)
                            }
                        }
                    }
                }
            }
            .ogListChrome()
            .searchable(text: $query, prompt: "Buscar ejercicio")
            .ogPinnedTransparentNav("Ejercicio")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseToolbarButton(action: { dismiss() }, large: false)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func pickerSubtitle(_ exercise: Exercise) -> String {
        var parts: [String] = [exercise.muscleGroup]
        if let eq = exercise.equipment, !eq.isEmpty {
            parts.append(eq)
        }
        return parts.joined(separator: " · ")
    }

    private var filtered: [Exercise] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return store.state.exercises }
        return store.state.exercises.filter {
            $0.name.lowercased().contains(q) || $0.muscleGroup.lowercased().contains(q)
        }
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
        .preferredColorScheme(.dark)
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
