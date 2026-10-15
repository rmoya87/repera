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

    var body: some View {
        NavigationStack {
            List {
                Section {
                    OGPageHeader(title: "Diario")
                        .ogListPageHeaderRow()
                }

                Section {
                    Picker("Sección", selection: $section) {
                        ForEach(DiarioSection.allCases) { tab in
                            Text(tab.title).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: OG.pad, bottom: 4, trailing: OG.pad))
                }

                switch section {
                case .schedule:
                    scheduleContent
                case .routines:
                    routinesContent
                }
            }
            .ogListChrome()
            .ogContentTitleNav()
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $editing) { routine in
                DayEditorView(routine: routine, mode: .plan(isNew: isCreating))
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
            .alert("Vaciar programación", isPresented: $confirmClearSchedule) {
                Button("Vaciar", role: .destructive) {
                    store.clearWeeklySchedule()
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Se quitan las rutinas de todos los días. Las plantillas en Rutinas se conservan. Los entrenos ya registrados se mantienen.")
            }
        }
    }

    // MARK: - Programado

    @ViewBuilder
    private var scheduleContent: some View {
        Section {
            ForEach(1...7, id: \.self) { day in
                let routine = store.routine(forWeekday: day)
                Button {
                    if let routine {
                        dayActionRoutine = routine
                    } else if store.libraryRoutines.isEmpty {
                        isCreating = true
                        editing = Routine(
                            title: CalendarHelpers.weekdayName(day),
                            weekday: day,
                            scheduledDate: nil,
                            blocks: [.strength()]
                        )
                    } else {
                        assigningDay = day
                    }
                } label: {
                    HStack(spacing: 12) {
                        Text(String(CalendarHelpers.weekdayName(day).prefix(2)).uppercased())
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(OG.onAccent)
                            .frame(width: 36, height: 36)
                            .background(routine == nil ? OG.surface3 : OG.accent, in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(CalendarHelpers.weekdayName(day)).foregroundStyle(OG.label)
                            Text(routine.map { "\($0.title) · \(routineSubtitle($0))" }
                                  ?? "Sin rutina · toca para asignar")
                                .font(.caption)
                                .foregroundStyle(OG.label2)
                                .lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(OG.label3)
                    }
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
        } footer: {
            Text("Los días solo asignan rutinas. Crea y edita el contenido en Rutinas.")
        }

        if store.plannedRoutines.isEmpty && store.libraryRoutines.isEmpty {
            Section {
                VStack(spacing: 12) {
                    Text("Empieza creando una rutina reutilizable y asígnala a los días que entrenas.")
                        .font(.system(size: 14))
                        .foregroundStyle(OG.label2)
                        .multilineTextAlignment(.center)
                    Button {
                        section = .routines
                        createNewRoutine()
                    } label: {
                        Text("Crear primera rutina")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(OG.onAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(OG.accent, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }
        }

        if !store.plannedRoutines.isEmpty {
            Section {
                Button("Vaciar programación", role: .destructive) {
                    confirmClearSchedule = true
                }
            }
        }
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
                    Button(action: createNewRoutine) {
                        Text("Nueva rutina")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(OG.onAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(OG.accent, in: Capsule())
                    }
                    .buttonStyle(.plain)
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
                        HStack(spacing: 12) {
                            Image(systemName: routine.isFavorite ? "star.fill" : "figure.strengthtraining.traditional")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(routine.isFavorite ? OG.yellow : OG.accent)
                                .frame(width: 36, height: 36)
                                .background(OG.surface2, in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(routine.title).foregroundStyle(OG.label)
                                Text(librarySubtitle(routine))
                                    .font(.caption)
                                    .foregroundStyle(OG.label2)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(OG.label3)
                        }
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
            } footer: {
                Text("Edita aquí el contenido. En Programado solo eliges qué rutina va cada día.")
            }
        }

        Section {
            Button(action: createNewRoutine) {
                Label("Nueva rutina", systemImage: "plus")
            }
        }
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
    var embedsNavigationStack: Bool = true
    @State private var pickExerciseForBlock: UUID?
    @State private var pickMovementForBlock: UUID?
    /// En modo sesión: día ISO opcional para guardar en el plan (0 = no guardar día).
    @State private var saveToWeekday: Int = 0
    @State private var saveAsFavorite = false

    var body: some View {
        Group {
            if embedsNavigationStack {
                NavigationStack { editorForm }
                    .preferredColorScheme(.dark)
            } else {
                editorForm
            }
        }
    }

    private var editorForm: some View {
        Form {
            Section {
                OGPageHeader(title: navTitle)
                    .ogListPageHeaderRow()
            }

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
                    Picker("Progresión (fuerza)", selection: $routine.progression) {
                        ForEach(ProgressionPolicy.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }
                    Toggle("También en favoritos", isOn: $routine.isFavorite)
                case .oneOff:
                    if let date = routine.scheduledDate {
                        Text(SpanishDate.long(date))
                            .foregroundStyle(OG.label2)
                    }
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
                case .session:
                    Picker("Guardar en día del plan", selection: $saveToWeekday) {
                        Text("No guardar en plan").tag(0)
                        ForEach(1...7, id: \.self) { day in
                            Text(CalendarHelpers.weekdayName(day)).tag(day)
                        }
                    }
                    Toggle("Guardar en favoritos", isOn: $saveAsFavorite)
                }
            } footer: {
                switch mode {
                case .session:
                    Text("Si eliges un día, se asigna en Diario → Programado.")
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
            } footer: {
                switch mode {
                case .session:
                    Text("Bloques de fuerza (series/reps) y WODs (AMRAP, EMOM, RFT, Tabata…).")
                case .oneOff, .plan, .favorite:
                    Text("AMRAP: tiempo + lista. EMOM / EVERY 2′×N: intervalo por tiempo. RFT: rondas + time cap.")
                }
            }
        }
        .ogListChrome()
        .ogContentTitleNav()
        .toolbar {
            if embedsNavigationStack {
                ToolbarItem(placement: .cancellationAction) {
                    CloseToolbarButton { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(confirmTitle) { confirm() }
                    .fontWeight(.semibold)
                    .disabled(!canConfirm)
            }
        }
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
            dismiss()
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
            dismiss()
        case .favorite:
            var draft = routine
            draft.isFavorite = true
            if draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                draft.title = "Favorito"
            }
            store.saveRoutine(draft)
            dismiss()
        case .session:
            var draft = routine
            draft.progression = .off
            draft.scheduledDate = nil
            if draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                draft.title = "Mi entreno"
            }
            let planDay = saveToWeekday == 0 ? nil : saveToWeekday
            draft.weekday = planDay
            draft.isFavorite = saveAsFavorite
            if planDay != nil || saveAsFavorite {
                store.saveRoutine(draft)
            }
            var sessionDraft = draft
            sessionDraft.weekday = nil
            store.startSession(from: sessionDraft)
            dismiss()
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
                Text(move.summaryLine)
                    .font(.system(size: 14, weight: .medium))
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
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    Text("/")
                    TextField("35", text: Binding(
                        get: { movement.weightFemaleKg.map { String(format: "%g", $0) } ?? "" },
                        set: { movement.weightFemaleKg = Double($0.replacingOccurrences(of: ",", with: ".")) }
                    ))
                    .keyboardType(.decimalPad)
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
        .safeAreaInset(edge: .top, spacing: 0) {
            OGPageHeader(title: "Movimiento WOD")
                .padding(.horizontal, OG.pad)
                .padding(.top, 8)
                .background(OG.bg)
        }
        .ogContentTitleNav()
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
            Section {
                OGPageHeader(title: exerciseName)
                    .ogListPageHeaderRow()
            }
            if let exercise {
                Section {
                    ExerciseArtView(exercise: exercise, height: 140, showBadge: false, showStepCaptions: false)
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
                        barKg: store.state.settings.barbellKg,
                        plates: store.state.settings.ownedPlatesKg,
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
        .ogContentTitleNav()
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
    var barKg: Double
    var plates: [Double]
    var canDelete: Bool
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("\(index)")
                    .font(.system(size: 13, weight: .bold).monospacedDigit())
                    .foregroundStyle(OG.label)
                    .frame(width: 28, height: 28)
                    .background(OG.surface2, in: Circle())

                compactStepper(
                    valueLabel: set.targetWeightKg.map { String(format: "%g", $0) } ?? "—",
                    onMinus: { bumpWeight(-weightStep) },
                    onPlus: { bumpWeight(weightStep) }
                )
                .frame(maxWidth: .infinity)

                compactStepper(
                    valueLabel: "\(set.targetReps)",
                    onMinus: { set.targetReps = max(1, set.targetReps - 1) },
                    onPlus: { set.targetReps = min(50, set.targetReps + 1) }
                )
                .frame(width: 88)

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

            if let weight = set.targetWeightKg, weight > 0,
               let compact = PlateMath.solve(targetKg: weight, barKg: barKg, availablePlatesKg: plates).perSideCompact {
                HStack(spacing: 4) {
                    Image(systemName: "circle.grid.cross")
                        .font(.system(size: 10))
                    Text(compact)
                        .font(.system(size: 11))
                }
                .foregroundStyle(OG.label3)
                .padding(.leading, 36)
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

    private func compactStepper(
        valueLabel: String,
        onMinus: @escaping () -> Void,
        onPlus: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 0) {
            Button(action: onMinus) {
                Image(systemName: "minus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(OG.label2)
                    .frame(width: 28, height: 36)
            }
            .buttonStyle(.plain)

            Text(valueLabel)
                .font(.system(size: 15, weight: .semibold).monospacedDigit())
                .foregroundStyle(OG.label)
                .frame(maxWidth: .infinity)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Button(action: onPlus) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(OG.label2)
                    .frame(width: 28, height: 36)
            }
            .buttonStyle(.plain)
        }
        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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
                Section {
                    OGPageHeader(title: "Ejercicio") {
                        CloseToolbarButton { dismiss() }
                    }
                    .ogListPageHeaderRow()
                }
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
            .ogContentTitleNav()
            .toolbar(.hidden, for: .navigationBar)
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
