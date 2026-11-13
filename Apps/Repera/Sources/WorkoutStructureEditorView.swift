import SwiftUI
import ReperaDomain

/// Shared native controls for Create, Edit and Play. No new WOD picker is
/// introduced: team modes and nested phases belong to the existing block.
struct WorkoutStructureEditorView: View {
    @Binding var block: RoutineBlock
    @State private var isExpanded = false

    private var available: [(id: UUID, title: String)] {
        if block.kind == .wod {
            return block.movements.filter { !$0.isRest }.map { ($0.id, $0.name) }
        }
        return block.exercises.enumerated().map { ($0.element.id, "Ejercicio \($0.offset + 1)") }
    }

    private var structure: WorkoutStructure {
        block.structure ?? WorkoutStructure()
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Sección", selection: Binding<String>(
                    get: { structure.section?.rawValue ?? "none" },
                    set: { value in update { $0.section = WorkoutSection(rawValue: value) } }
                )) {
                    Text("Sin sección").tag("none")
                    ForEach(WorkoutSection.allCases, id: \.self) {
                        Text(label(for: $0)).tag($0.rawValue)
                    }
                }
                .pickerStyle(.menu)

                if block.kind == .wod {
                    Picker("Trabajo en equipo", selection: Binding<WorkoutCollaboration>(
                        get: { structure.collaboration ?? .solo },
                        set: { value in update { $0.collaboration = value } }
                    )) {
                        Text("Individual").tag(WorkoutCollaboration.solo)
                        Text("Alternando").tag(WorkoutCollaboration.youGoIGo)
                        Text("Sincronizado").tag(WorkoutCollaboration.synchronized)
                        Text("Reps compartidas").tag(WorkoutCollaboration.sharedReps)
                        Text("Juntos").tag(WorkoutCollaboration.together)
                    }
                    .pickerStyle(.menu)
                }

                if structure.phases.isEmpty {
                    Text("Añade una fase para separar trabajo, pausas, buy-in o cash-out.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ForEach(Array(structure.phases.enumerated()), id: \.element.id) { index, phase in
                    WorkoutPhaseRow(
                        phase: phase, references: available, level: 0,
                        onChange: { changed in
                            update { $0.phases[index] = changed }
                        },
                        onDelete: {
                            update { $0.phases.removeAll { $0.id == phase.id } }
                        },
                        onMove: { amount in
                            update { model in
                                guard let old = model.phases.firstIndex(where: { $0.id == phase.id }) else { return }
                                let target = old + amount
                                guard model.phases.indices.contains(target) else { return }
                                model.phases.swapAt(old, target)
                            }
                        }
                    )
                }
                Button {
                    update { model in
                        model.phases.append(WorkoutPhase(
                            kind: .main, title: "Trabajo principal",
                            movementIDs: available.map { $0.id }
                        ))
                    }
                } label: {
                    Label("Añadir fase", systemImage: "plus")
                }
                .buttonStyle(.borderless)
            }
            .padding(.top, 8)
        } label: {
            Label("Estructura avanzada", systemImage: "square.stack.3d.up")
                .font(.subheadline.weight(.medium))
        }
    }

    private func update(_ change: (inout WorkoutStructure) -> Void) {
        var next = structure
        change(&next)
        block.structure = next
    }

    private func label(for section: WorkoutSection) -> String {
        switch section {
        case .warmUp: "Calentamiento"
        case .strength: "Fuerza"
        case .skill: "Técnica"
        case .metcon: "Metcon"
        case .accessory: "Accesorios"
        case .coolDown: "Vuelta a la calma"
        }
    }
}

private struct WorkoutPhaseRow: View {
    let phase: WorkoutPhase
    let references: [(id: UUID, title: String)]
    let level: Int
    let onChange: (WorkoutPhase) -> Void
    let onDelete: () -> Void
    let onMove: (Int) -> Void
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 9) {
                TextField("Nombre de la fase", text: binding(\.title))
                    .textFieldStyle(.roundedBorder)
                Picker("Tipo", selection: binding(\.kind)) {
                    Text("Trabajo").tag(WorkoutPhaseKind.work)
                    Text("Descanso").tag(WorkoutPhaseKind.rest)
                    Text("Buy-in").tag(WorkoutPhaseKind.buyIn)
                    Text("Principal").tag(WorkoutPhaseKind.main)
                    Text("Cash-out").tag(WorkoutPhaseKind.cashOut)
                }
                .pickerStyle(.menu)

                Stepper("Repeticiones: \(phase.repeatCount ?? 1)",
                        value: optionalNumber(\.repeatCount, fallback: 1), in: 1...200)
                Stepper("Trabajo: \(phase.workSeconds ?? 0) s",
                        value: optionalNumber(\.workSeconds, fallback: 0), in: 0...86400, step: 15)
                Stepper("Descanso: \(phase.restSeconds ?? 0) s",
                        value: optionalNumber(\.restSeconds, fallback: 0), in: 0...3600, step: 15)

                Menu {
                    ForEach(references, id: \.id) { reference in
                        Button {
                            var value = phase
                            if value.movementIDs.contains(reference.id) {
                                value.movementIDs.removeAll { $0 == reference.id }
                            } else {
                                value.movementIDs.append(reference.id)
                            }
                            onChange(value)
                        } label: {
                            if phase.movementIDs.contains(reference.id) {
                                Label(reference.title, systemImage: "checkmark")
                            } else {
                                Text(reference.title)
                            }
                        }
                    }
                } label: {
                    Label("Ejercicios (\(phase.movementIDs.count))", systemImage: "list.bullet")
                }

                Picker("Método de fuerza", selection: Binding<WorkoutSetMethod>(
                    get: { phase.technique?.method ?? .standard },
                    set: { method in
                        var value = phase
                        var technique = value.technique ?? WorkoutStrengthTechnique(method: method)
                        technique.method = method
                        value.technique = method == .standard ? nil : technique
                        onChange(value)
                    }
                )) {
                    Text("Normal").tag(WorkoutSetMethod.standard)
                    Text("Superserie").tag(WorkoutSetMethod.superset)
                    Text("Triserie").tag(WorkoutSetMethod.triset)
                    Text("Giant set").tag(WorkoutSetMethod.giantSet)
                    Text("Cluster").tag(WorkoutSetMethod.cluster)
                    Text("Drop set").tag(WorkoutSetMethod.dropSet)
                    Text("Rest-pause").tag(WorkoutSetMethod.restPause)
                    Text("Tempo").tag(WorkoutSetMethod.tempo)
                    Text("Isométrico").tag(WorkoutSetMethod.isometric)
                }
                .pickerStyle(.menu)

                if phase.technique != nil {
                    TextField("Tempo (por ejemplo 31X1)", text: techniqueText(\.tempo))
                        .textFieldStyle(.roundedBorder)
                    Stepper("Pausa: \(phase.technique?.pauseSeconds ?? 0) s",
                            value: techniqueNumber(\.pauseSeconds), in: 0...300)
                    Stepper("Descanso intra-serie: \(phase.technique?.intraSetRestSeconds ?? 0) s",
                            value: techniqueNumber(\.intraSetRestSeconds), in: 0...300)
                    if phase.technique?.method == .cluster {
                        Stepper("Reps por cluster: \(phase.technique?.clusterReps ?? 1)",
                                value: techniqueNumber(\.clusterReps, fallback: 1), in: 1...100)
                    }
                }
                TextField("Indicaciones", text: optionalText(\.notes))
                    .textFieldStyle(.roundedBorder)

                if level == 0 {
                    ForEach(phase.children) { child in
                        WorkoutPhaseRow(
                            phase: child, references: references, level: 1,
                            onChange: { updated in
                                var next = phase
                                if let i = next.children.firstIndex(where: { $0.id == updated.id }) {
                                    next.children[i] = updated
                                    onChange(next)
                                }
                            },
                            onDelete: {
                                var next = phase
                                next.children.removeAll { $0.id == child.id }
                                onChange(next)
                            },
                            onMove: { direction in
                                var next = phase
                                guard let i = next.children.firstIndex(where: { $0.id == child.id }),
                                      next.children.indices.contains(i + direction) else { return }
                                next.children.swapAt(i, i + direction)
                                onChange(next)
                            }
                        )
                    }
                    Button {
                        var next = phase
                        next.children.append(WorkoutPhase(kind: .main, title: "Subfase"))
                        onChange(next)
                    } label: {
                        Label("Añadir subfase", systemImage: "plus")
                    }
                    .buttonStyle(.borderless)
                }
                HStack {
                    Button { onMove(-1) } label: { Image(systemName: "arrow.up") }
                    Button { onMove(1) } label: { Image(systemName: "arrow.down") }
                    Spacer()
                    Button(role: .destructive, action: onDelete) {
                        Label("Eliminar fase", systemImage: "trash")
                    }
                }
                .buttonStyle(.borderless)
            }
            .padding(.vertical, 4)
        } label: {
            Text(phase.title.isEmpty ? "Fase" : phase.title)
                .font(.subheadline)
        }
        .padding(.leading, CGFloat(level * 12))
    }

    private func binding<Value>(_ key: WritableKeyPath<WorkoutPhase, Value>) -> Binding<Value> {
        Binding(get: { phase[keyPath: key] }, set: {
            var next = phase
            next[keyPath: key] = $0
            onChange(next)
        })
    }

    private func optionalNumber(_ key: WritableKeyPath<WorkoutPhase, Int?>,
                                fallback: Int) -> Binding<Int> {
        Binding(get: { phase[keyPath: key] ?? fallback }, set: {
            var next = phase
            next[keyPath: key] = $0
            onChange(next)
        })
    }

    private func optionalText(_ key: WritableKeyPath<WorkoutPhase, String?>) -> Binding<String> {
        Binding(get: { phase[keyPath: key] ?? "" }, set: {
            var next = phase
            next[keyPath: key] = $0.isEmpty ? nil : $0
            onChange(next)
        })
    }

    private func techniqueText(_ key: WritableKeyPath<WorkoutStrengthTechnique, String?>) -> Binding<String> {
        Binding(get: { phase.technique?[keyPath: key] ?? "" }, set: {
            var next = phase
            guard var technique = next.technique else { return }
            technique[keyPath: key] = $0.isEmpty ? nil : $0
            next.technique = technique
            onChange(next)
        })
    }

    private func techniqueNumber(_ key: WritableKeyPath<WorkoutStrengthTechnique, Int?>,
                                 fallback: Int = 0) -> Binding<Int> {
        Binding(get: { phase.technique?[keyPath: key] ?? fallback }, set: {
            var next = phase
            guard var technique = next.technique else { return }
            technique[keyPath: key] = $0
            next.technique = technique
            onChange(next)
        })
    }
}
