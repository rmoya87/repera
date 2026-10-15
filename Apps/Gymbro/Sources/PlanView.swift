import GymbroDomain
import SwiftUI

/// Diario: crear plan por días → configurar cada día con bloques (fuerza / WOD).
struct PlanView: View {
    @Environment(GymbroStore.self) private var store
    @State private var editing: Routine?
    @State private var showCreatePlan = false
    @State private var isCreating = false
    @State private var confirmDeletePlan = false

    var body: some View {
        NavigationStack {
            Group {
                if store.state.routines.isEmpty {
                    emptyPlan
                } else {
                    planList
                }
            }
            .background(OG.bg)
            .navigationTitle("Diario")
            .toolbarBackground(OG.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $editing) { routine in
                DayEditorView(routine: routine, mode: .plan(isNew: isCreating))
                    .onDisappear { isCreating = false }
            }
            .sheet(isPresented: $showCreatePlan) {
                CreatePlanSheetHost(editing: $editing, isCreating: $isCreating)
            }
            .alert("Eliminar plan de entreno", isPresented: $confirmDeletePlan) {
                Button("Eliminar", role: .destructive) {
                    store.deleteAllRoutines()
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Se borran todos los días del plan. Los entrenos ya registrados se mantienen.")
            }
        }
    }

    private var emptyPlan: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(OG.accent)
            Text("Crea tu plan")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(OG.label)
            Text("Elige los días que entrenas y configura cada uno con bloques de ejercicios y WODs (AMRAP, EMOM, RFT…).")
                .font(.system(size: 15))
                .foregroundStyle(OG.label2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button { showCreatePlan = true } label: {
                Text("Crear plan")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(OG.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(OG.accent, in: Capsule())
            }
            .padding(.horizontal, 40)
            .buttonStyle(.plain)
            Spacer()
        }
    }

    private var planList: some View {
        List {
            Section {
                ForEach(1...7, id: \.self) { day in
                    let routine = store.state.routines.first { $0.weekday == day }
                    Button {
                        isCreating = routine == nil
                        editing = routine ?? Routine(title: CalendarHelpers.weekdayName(day), weekday: day)
                    } label: {
                        HStack(spacing: 12) {
                            Text(String(CalendarHelpers.weekdayName(day).prefix(2)).uppercased())
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(OG.onAccent)
                                .frame(width: 36, height: 36)
                                .background(routine == nil ? OG.surface3 : OG.accent, in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(CalendarHelpers.weekdayName(day)).foregroundStyle(OG.label)
                                Text(routine.map(routineSubtitle) ?? "Sin entreno · toca para configurar")
                                    .font(.caption)
                                    .foregroundStyle(OG.label2)
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
                                store.deleteRoutine(routine.id)
                            } label: {
                                Label("Eliminar día", systemImage: "xmark")
                            }
                            .tint(OG.red)
                        }
                    }
                }
            }

            Section {
                Button { showCreatePlan = true } label: {
                    Label("Añadir / cambiar días", systemImage: "calendar.badge.plus")
                }
                Button("Eliminar plan de entreno", role: .destructive) {
                    confirmDeletePlan = true
                }
            }
        }
        .ogListChrome()
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
}

// MARK: - Crear plan (elegir días)

struct CreatePlanSheetHost: View {
    @Environment(GymbroStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDays: Set<Int> = [1, 3, 5]
    @State private var planName = "Mi plan"
    @Binding var editing: Routine?
    @Binding var isCreating: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Nombre") {
                    TextField("Mi plan", text: $planName)
                }
                Section("¿Qué días entrenas?") {
                    ForEach(1...7, id: \.self) { day in
                        Toggle(CalendarHelpers.weekdayName(day), isOn: Binding(
                            get: { selectedDays.contains(day) },
                            set: { on in
                                if on { selectedDays.insert(day) } else { selectedDays.remove(day) }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Crear plan")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseToolbarButton { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continuar") {
                        let base = planName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let days = Set(selectedDays)
                        // Quita días desmarcados; conserva el contenido de los que siguen.
                        for routine in store.state.routines {
                            if let wd = routine.weekday, !days.contains(wd) {
                                if routine.isFavorite {
                                    store.assignRoutine(routine.id, toWeekday: nil)
                                } else {
                                    store.deleteRoutine(routine.id)
                                }
                            }
                        }
                        var first: Routine?
                        for day in days.sorted() {
                            if let existing = store.state.routines.first(where: { $0.weekday == day }) {
                                if first == nil { first = existing }
                                continue
                            }
                            let title = base.isEmpty
                                ? CalendarHelpers.weekdayName(day)
                                : "\(base) · \(CalendarHelpers.weekdayName(day))"
                            let routine = Routine(title: title, weekday: day, blocks: [.strength()])
                            store.saveRoutine(routine)
                            if first == nil { first = routine }
                        }
                        dismiss()
                        if let first {
                            isCreating = store.state.routines.first(where: { $0.id == first.id })?.blocks.first?.exercises.isEmpty == true
                            editing = first
                        }
                    }
                    .disabled(selectedDays.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Editor de día / crear entreno

enum DayEditorMode: Equatable {
    case plan(isNew: Bool)
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
                TextField(nameFieldPlaceholder, text: $routine.title)
                switch mode {
                case .plan:
                    Picker("Día", selection: Binding(
                        get: { routine.weekday ?? 0 },
                        set: { routine.weekday = $0 == 0 ? nil : $0 }
                    )) {
                        Text("Sin día").tag(0)
                        ForEach(1...7, id: \.self) { day in
                            Text(CalendarHelpers.weekdayName(day)).tag(day)
                        }
                    }
                    Picker("Progresión (fuerza)", selection: $routine.progression) {
                        ForEach(ProgressionPolicy.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }
                    Toggle("También en favoritos", isOn: $routine.isFavorite)
                case .favorite:
                    Toggle("Favorito", isOn: $routine.isFavorite)
                        .disabled(true)
                    Picker("También en el plan", selection: Binding(
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
                    Text("Si eliges un día (p. ej. viernes), se guarda en ese día del Diario, no en hoy.")
                case .favorite:
                    Text("Los favoritos se reutilizan desde Crear. Opcionalmente puedes asignarlos también a un día.")
                case .plan:
                    EmptyView()
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
                Text(mode == .session
                     ? "Igual que un día del plan: bloques de fuerza (series/reps) y WODs (AMRAP, EMOM, RFT, Tabata…)."
                     : "AMRAP: tiempo + lista. EMOM / EVERY 2′×N: intervalo por tiempo. RFT: rondas + time cap.")
            }
        }
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
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
        case .session: return "Nombre del entreno"
        case .favorite: return "Nombre del favorito"
        case .plan: return "Nombre del día"
        }
    }

    private var navTitle: String {
        switch mode {
        case .session: return "Crear entreno"
        case .favorite(let isNew): return isNew ? "Nuevo favorito" : "Editar favorito"
        case .plan(let isNew):
            return isNew ? "Nuevo día" : (routine.weekday.map(CalendarHelpers.weekdayName) ?? "Editar día")
        }
    }

    private var confirmTitle: String {
        switch mode {
        case .session: return "Empezar"
        case .plan, .favorite: return "Guardar"
        }
    }

    private var canConfirm: Bool {
        switch mode {
        case .plan, .favorite: return true
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
            // Respeta el día elegido en el picker (viernes → viernes).
            store.saveRoutine(routine)
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
            if draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                draft.title = "Mi entreno"
            }
            let planDay = saveToWeekday == 0 ? nil : saveToWeekday
            draft.weekday = planDay
            draft.isFavorite = saveAsFavorite
            if planDay != nil || saveAsFavorite {
                store.saveRoutine(draft)
            }
            // La sesión usa una copia; el plan/favorito ya quedó con el día correcto.
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
        .navigationTitle("Movimiento WOD")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Strength exercise editor + picker

struct RoutineExerciseEditor: View {
    @Environment(GymbroStore.self) private var store
    var exerciseName: String
    var exerciseId: UUID
    @Binding var item: RoutineExercise
    @State private var weightText = ""

    private var exercise: Exercise? {
        store.state.exercises.first { $0.id == exerciseId }
    }

    var body: some View {
        Form {
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
            Section("Objetivo") {
                Stepper("Series: \(item.plannedSets.count)", value: Binding(
                    get: { item.plannedSets.count },
                    set: { n in
                        let reps = item.plannedSets.first?.targetReps ?? 8
                        let w = item.plannedSets.first?.targetWeightKg
                        item.plannedSets = (0..<n).map { _ in PlannedSet(targetReps: reps, targetWeightKg: w) }
                    }
                ), in: 1...10)
                Stepper("Reps: \(item.plannedSets.first?.targetReps ?? 8)", value: Binding(
                    get: { item.plannedSets.first?.targetReps ?? 8 },
                    set: { reps in
                        item.plannedSets = item.plannedSets.map {
                            PlannedSet(id: $0.id, targetReps: reps, targetWeightKg: $0.targetWeightKg)
                        }
                    }
                ), in: 1...50)
                HStack {
                    Text("Peso (kg)")
                    TextField("opcional", text: $weightText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                .onAppear {
                    weightText = item.plannedSets.first?.targetWeightKg.map { String(format: "%g", $0) } ?? ""
                }
                .onChange(of: weightText) { _, text in
                    let w = Double(text.replacingOccurrences(of: ",", with: "."))
                    item.plannedSets = item.plannedSets.map {
                        PlannedSet(id: $0.id, targetReps: $0.targetReps, targetWeightKg: w)
                    }
                }
            }
        }
        .navigationTitle(exerciseName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ExercisePickerView: View {
    @Environment(GymbroStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    var onPick: (Exercise) -> Void

    var body: some View {
        NavigationStack {
            List(filtered) { exercise in
                Button {
                    onPick(exercise)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        ExerciseThumb(exercise: exercise)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.name).foregroundStyle(OG.label)
                            Text(exercise.muscleGroup).font(.caption).foregroundStyle(OG.label2)
                        }
                    }
                }
            }
            .ogListChrome()
            .searchable(text: $query, prompt: "Buscar ejercicio")
            .navigationTitle("Ejercicio")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseToolbarButton { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var filtered: [Exercise] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return store.state.exercises }
        return store.state.exercises.filter {
            $0.name.lowercased().contains(q) || $0.muscleGroup.lowercased().contains(q)
        }
    }
}
