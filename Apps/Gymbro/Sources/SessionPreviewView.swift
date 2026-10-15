import GymbroDomain
import SwiftUI

/// Resumen del plan de hoy antes de empezar, o gestión de sesión en curso.
/// Sesión en curso: tocar = continuar · swipe izquierda = cancelar.
/// También permite apuntar el resultado final sin seguir el entreno en vivo.
struct SessionPreviewView: View {
    @Environment(GymbroStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var routine: Routine?
    var onStart: () -> Void
    var onContinue: () -> Void

    @State private var showLogResults = false

    private var active: WorkoutSession? { store.state.activeSession }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    previewTopBar
                        .listRowInsets(EdgeInsets(top: 2, leading: OG.pad, bottom: 2, trailing: OG.pad))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                if let active {
                    Section {
                        Button {
                            dismiss()
                            onContinue()
                        } label: {
                            activeBanner(active)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 10, leading: OG.pad, bottom: 10, trailing: OG.pad))
                        .listRowBackground(OG.surface)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                store.endActiveSession(save: false)
                                dismiss()
                            } label: {
                                Label("Cancelar", systemImage: "xmark")
                            }
                            .tint(OG.red)
                        }
                    } footer: {
                        Text("Toca para continuar · desliza a la izquierda para cancelar")
                    }
                }

                if let routine {
                    Section {
                        Text(routine.title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(OG.label)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: OG.pad, bottom: 4, trailing: OG.pad))

                        if routine.blocks.isEmpty {
                            flatExercises(routine)
                        } else {
                            ForEach(routine.blocks) { block in
                                blockCard(block)
                                    .listRowInsets(EdgeInsets(top: 6, leading: OG.pad, bottom: 6, trailing: OG.pad))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }
                        }
                    }
                } else if active == nil {
                    Section {
                        Text("No hay plan para hoy.")
                            .foregroundStyle(OG.label2)
                    }
                }
            }
            .ogListChrome()
            .ogContentTitleNav()
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                if active == nil, let routine {
                    bottomActions(routine)
                }
            }
            .sheet(isPresented: $showLogResults) {
                if let routine {
                    LogFinalResultsView(routine: routine) {
                        showLogResults = false
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var previewTopBar: some View {
        HStack(alignment: .center, spacing: 12) {
            CloseToolbarButton(action: { dismiss() }, large: true)
            Text(active != nil ? "Sesión" : "Entreno")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(OG.label)
                .tracking(-0.4)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 8)
            if routine != nil, active == nil {
                OGToolbarGlassButton(
                    systemName: "pencil",
                    accessibilityLabel: "Apuntar resultado final",
                    tint: OG.label,
                    iconSize: 18,
                    hitSize: 44
                ) {
                    showLogResults = true
                }
            }
        }
        .padding(.top, 0)
        .padding(.bottom, 2)
    }

    private func bottomActions(_ routine: Routine) -> some View {
        VStack(spacing: 10) {
            Button {
                store.startSession(from: routine)
                dismiss()
                onStart()
            } label: {
                Text("Comenzar")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .background(.white, in: Capsule())
            }
            .buttonStyle(.plain)

            Button {
                showLogResults = true
            } label: {
                Text("Apuntar resultado final")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(OG.label)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
                    .background(OG.surface2, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, OG.pad)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }

    private func activeBanner(_ session: WorkoutSession) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(OG.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text("Sesión en curso")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(OG.orange)
                Text(session.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(OG.label)
                if let current = session.currentExercise {
                    Text("Ahora: \(current.exercise.name) · \(session.progressLabel)")
                        .font(.system(size: 13))
                        .foregroundStyle(OG.label2)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(OG.label3)
        }
        .contentShape(Rectangle())
    }

    private func blockCard(_ block: RoutineBlock) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(block.headerLabel)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(OG.accent)
                Spacer()
                if let cap = block.timeCapMinutes {
                    Text("\(cap)'")
                        .font(.system(size: 13, weight: .semibold).monospacedDigit())
                        .foregroundStyle(OG.label2)
                }
            }

            if block.kind == .strength {
                ForEach(block.exercises) { item in
                    if let ex = store.state.exercises.first(where: { $0.id == item.exerciseId }) {
                        exerciseRow(
                            ex,
                            detail: "\(item.plannedSets.count)×\(item.plannedSets.first?.targetReps ?? 0)"
                        )
                    }
                }
            } else {
                ForEach(block.movements.filter { !$0.isRest }) { move in
                    exerciseRow(resolvedExercise(move), detail: moveDetail(move))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }

    private func flatExercises(_ routine: Routine) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(routine.exercises) { item in
                if let ex = store.state.exercises.first(where: { $0.id == item.exerciseId }) {
                    exerciseRow(
                        ex,
                        detail: "\(item.plannedSets.count)×\(item.plannedSets.first?.targetReps ?? 0)"
                    )
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
        .listRowInsets(EdgeInsets(top: 6, leading: OG.pad, bottom: 6, trailing: OG.pad))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private func exerciseRow(_ exercise: Exercise, detail: String) -> some View {
        HStack(spacing: 12) {
            ExerciseThumb(exercise: exercise, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(OG.label)
                    .lineLimit(2)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(OG.label3)
            }
            Spacer(minLength: 0)
        }
    }

    private func resolvedExercise(_ move: WODMovement) -> Exercise {
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

    private func moveDetail(_ move: WODMovement) -> String {
        var parts: [String] = []
        if let reps = move.reps { parts.append("\(reps) reps") }
        if let m = move.distanceMeters { parts.append("\(m) m") }
        if let cal = move.calories { parts.append("\(cal) cal") }
        if let w = move.weightMaleKg { parts.append(String(format: "%g kg", w)) }
        return parts.isEmpty ? "Movimiento" : parts.joined(separator: " · ")
    }
}

// MARK: - Apuntar resultado final

/// Lista todos los parámetros del plan para completar y guardar el entreno como terminado.
struct LogFinalResultsView: View {
    @Environment(GymbroStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var routine: Routine
    var onSaved: () -> Void

    @State private var drafts: [DraftExercise] = []
    @State private var notes = ""

    private var weightStep: Double { store.state.settings.weightIncrementKg }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(alignment: .center, spacing: 12) {
                        CloseToolbarButton(action: { dismiss() }, large: true)
                        Text("Resultado final")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(OG.label)
                            .tracking(-0.4)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Spacer(minLength: 0)
                    }
                    .listRowInsets(EdgeInsets(top: 2, leading: OG.pad, bottom: 2, trailing: OG.pad))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                Section {
                    Text(routine.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(OG.label2)
                } footer: {
                    Text("Rellena peso, reps y RIR de cada serie. Lo que dejes vacío no se guarda. Luego el entreno cuenta como terminado.")
                }

                ForEach($drafts) { $draft in
                    Section {
                        HStack(spacing: 12) {
                            ExerciseThumb(exercise: draft.exercise, size: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(draft.exercise.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(OG.label)
                                if let header = draft.blockHeader {
                                    Text(header)
                                        .font(.caption)
                                        .foregroundStyle(OG.label3)
                                }
                            }
                        }

                        ForEach($draft.sets) { $set in
                            resultSetRow(set: $set, weightStep: weightStep)
                        }

                        Button {
                            let last = draft.sets.last
                            draft.sets.append(
                                DraftSet(
                                    reps: last?.reps ?? 8,
                                    weightKg: last?.weightKg,
                                    rir: last?.rir
                                )
                            )
                        } label: {
                            Label("Añadir serie", systemImage: "plus")
                                .foregroundStyle(OG.accent)
                        }
                    }
                }

                Section("Notas") {
                    TextField("Opcional", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .ogListChrome()
            .ogContentTitleNav()
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                Button(action: save) {
                    Text("Guardar y terminar")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(OG.onAccent)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 52)
                        .background(OG.accent, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.45)
                .padding(.horizontal, OG.pad)
                .padding(.top, 10)
                .padding(.bottom, 12)
                .background(.ultraThinMaterial)
            }
            .onAppear {
                if drafts.isEmpty {
                    drafts = Self.makeDrafts(routine: routine, catalog: store.state.exercises)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var canSave: Bool {
        drafts.contains { draft in
            draft.sets.contains { $0.reps > 0 || ($0.weightKg ?? 0) > 0 }
        }
    }

    private func save() {
        let sessionExercises: [SessionExercise] = drafts.map { draft in
            let logged = draft.sets.compactMap { set -> LoggedSet? in
                guard set.reps > 0 || (set.weightKg ?? 0) > 0 else { return nil }
                return LoggedSet(
                    reps: max(1, set.reps),
                    weightKg: set.weightKg,
                    rir: set.rir
                )
            }
            return SessionExercise(
                exercise: draft.exercise,
                plannedSets: draft.plannedSets,
                loggedSets: logged,
                isCompleted: !logged.isEmpty,
                blockHeader: draft.blockHeader
            )
        }
        _ = store.logFinalResults(
            from: routine,
            exercises: sessionExercises,
            notes: notes
        )
        onSaved()
    }

    @ViewBuilder
    private func resultSetRow(set: Binding<DraftSet>, weightStep: Double) -> some View {
        HStack(spacing: 8) {
            compactStepper(
                label: set.wrappedValue.weightKg.map { String(format: "%g" , $0) } ?? "—",
                onMinus: {
                    let current = set.wrappedValue.weightKg ?? 0
                    let next = max(0, ((current - weightStep) * 10).rounded() / 10)
                    set.wrappedValue.weightKg = next > 0 ? next : nil
                },
                onPlus: {
                    let current = set.wrappedValue.weightKg ?? 0
                    set.wrappedValue.weightKg = ((current + weightStep) * 10).rounded() / 10
                }
            )
            .frame(maxWidth: .infinity)

            compactStepper(
                label: "\(set.wrappedValue.reps)",
                onMinus: { set.wrappedValue.reps = max(0, set.wrappedValue.reps - 1) },
                onPlus: { set.wrappedValue.reps = min(50, set.wrappedValue.reps + 1) }
            )
            .frame(width: 88)

            Menu {
                Button("Sin RIR") { set.wrappedValue.rir = nil }
                ForEach(0...5, id: \.self) { rir in
                    Button("\(rir)") { set.wrappedValue.rir = Double(rir) }
                }
            } label: {
                Text(set.wrappedValue.rir.map { String(format: "%g", $0) } ?? "RIR")
                    .font(.system(size: 13, weight: .semibold).monospacedDigit())
                    .foregroundStyle(set.wrappedValue.rir == nil ? OG.label3 : OG.label)
                    .frame(width: 52, height: 36)
                    .background(OG.surface2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
    }

    private func compactStepper(
        label: String,
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
            Text(label)
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

    private static func makeDrafts(routine: Routine, catalog: [Exercise]) -> [DraftExercise] {
        let session = SessionController.from(routine: routine, exercises: catalog)
        return session.exercises.map { item in
            let sets: [DraftSet]
            if item.plannedSets.isEmpty {
                sets = [DraftSet(reps: 8, weightKg: nil, rir: nil)]
            } else {
                sets = item.plannedSets.map {
                    DraftSet(reps: $0.targetReps, weightKg: $0.targetWeightKg, rir: $0.targetRir)
                }
            }
            return DraftExercise(
                exercise: item.exercise,
                plannedSets: item.plannedSets,
                blockHeader: item.blockHeader,
                sets: sets
            )
        }
    }
}

private struct DraftExercise: Identifiable {
    let id = UUID()
    var exercise: Exercise
    var plannedSets: [PlannedSet]
    var blockHeader: String?
    var sets: [DraftSet]
}

private struct DraftSet: Identifiable {
    let id = UUID()
    var reps: Int
    var weightKg: Double?
    var rir: Double?
}
