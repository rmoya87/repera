import GymbroDomain
import SwiftUI

private enum ExerciseBrowseMode: String, CaseIterable, Identifiable {
    case alphabetical
    case muscle
    case sport
    case favorites

    var id: String { rawValue }

    var title: String {
        switch self {
        case .alphabetical: return "Alfabético"
        case .muscle: return "Músculo"
        case .sport: return "Deporte"
        case .favorites: return "Favoritos"
        }
    }

    var icon: String {
        switch self {
        case .alphabetical: return "textformat.abc"
        case .muscle: return "figure.strengthtraining.traditional"
        case .sport: return "sportscourt"
        case .favorites: return "star.fill"
        }
    }
}

struct LibraryView: View {
    @Environment(GymbroStore.self) private var store
    @State private var query = ""
    @State private var showingAdd = false
    @State private var showFilter = false
    @State private var name = ""
    @State private var muscle = "Pecho"
    @State private var equipment = ""
    @State private var targetMuscle = ""
    @State private var bodyPart = ""
    @State private var secondaryText = ""
    @State private var detailDescription = ""
    @State private var instructionsText = ""
    @State private var browseMode: ExerciseBrowseMode = .alphabetical
    @State private var planFlashId: UUID?

    private let muscles = [
        "Pecho", "Espalda", "Piernas", "Isquios", "Hombros", "Bíceps", "Tríceps",
        "Core", "Glúteos", "Gemelos", "Cardio", "CrossFit", "Halterofilia", "Gimnasia",
    ]

    private let sportGroups: Set<String> = ["CrossFit", "Halterofilia", "Gimnasia", "Cardio"]

    var body: some View {
        NavigationStack {
            List {
                ForEach(sections, id: \.key) { group in
                    if let title = group.title {
                        Section(title) {
                            exerciseRows(group.items)
                        }
                    } else {
                        Section {
                            exerciseRows(group.items)
                        }
                    }
                }
            }
            .ogListChrome()
            .searchable(text: $query, prompt: "Nombre, músculo o equipo")
            .navigationTitle("Ejercicios")
            .navigationBarTitleDisplayMode(.large)
            .ogTransparentNav()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    OGToolbarGlassButton(
                        systemName: "line.3.horizontal.decrease",
                        accessibilityLabel: "Filtrar y ordenar"
                    ) {
                        showFilter = true
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    OGToolbarGlassButton(
                        systemName: "plus",
                        accessibilityLabel: "Nuevo ejercicio"
                    ) {
                        showingAdd = true
                    }
                }
            }
            .sheet(isPresented: $showFilter) {
                filterSheet
            }
            .sheet(isPresented: $showingAdd) {
                addExerciseSheet
            }
        }
    }

    private var addExerciseSheet: some View {
        NavigationStack {
            Form {
                Section("Básico") {
                    TextField("Nombre", text: $name)
                    Picker("Grupo muscular", selection: $muscle) {
                        ForEach(muscles, id: \.self) { Text($0).tag($0) }
                    }
                    TextField("Equipamiento (barra, mancuernas…)", text: $equipment)
                }
                Section("Detalle") {
                    TextField("Músculo objetivo", text: $targetMuscle)
                    TextField("Parte del cuerpo", text: $bodyPart)
                    TextField("Secundarios (separados por coma)", text: $secondaryText)
                    TextField("Descripción", text: $detailDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section("Instrucciones") {
                    TextField("Un paso por línea", text: $instructionsText, axis: .vertical)
                        .lineLimit(4...10)
                }
            }
            .ogListChrome()
            .navigationTitle("Nuevo ejercicio")
            .navigationBarTitleDisplayMode(.inline)
            .ogTransparentNav()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showingAdd = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Añadir") {
                        let secondary = secondaryText
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        let instructions = instructionsText
                            .split(whereSeparator: \.isNewline)
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        store.addCustomExercise(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            muscleGroup: muscle,
                            equipment: equipment.isEmpty ? nil : equipment,
                            targetMuscle: targetMuscle.isEmpty ? nil : targetMuscle,
                            secondaryMuscles: secondary,
                            bodyPart: bodyPart.isEmpty ? nil : bodyPart,
                            detailDescription: detailDescription.isEmpty ? nil : detailDescription,
                            instructions: instructions
                        )
                        resetAddForm()
                        showingAdd = false
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func resetAddForm() {
        name = ""
        equipment = ""
        targetMuscle = ""
        bodyPart = ""
        secondaryText = ""
        detailDescription = ""
        instructionsText = ""
        muscle = "Pecho"
    }

    private var filterSheet: some View {
        NavigationStack {
            List {
                Section("Ordenar / filtrar") {
                    ForEach(ExerciseBrowseMode.allCases) { mode in
                        Button {
                            browseMode = mode
                            showFilter = false
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: mode.icon)
                                    .foregroundStyle(browseMode == mode ? OG.accent : OG.label2)
                                    .frame(width: 24)
                                Text(mode.title)
                                    .foregroundStyle(OG.label)
                                Spacer()
                                if browseMode == mode {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(OG.accent)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                }
            }
            .ogListChrome()
            .navigationTitle("Filtro")
            .navigationBarTitleDisplayMode(.inline)
            .ogTransparentNav()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseToolbarButton { showFilter = false }
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium])
    }

    @ViewBuilder
    private func exerciseRows(_ items: [Exercise]) -> some View {
        ForEach(items) { exercise in
            HStack(spacing: 12) {
                NavigationLink {
                    ExerciseDetailView(exerciseId: exercise.id)
                } label: {
                    HStack(spacing: 12) {
                        ExerciseThumb(exercise: exercise)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(exercise.name)
                                    .foregroundStyle(OG.label)
                                if exercise.isFavorite {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundStyle(OG.yellow)
                                }
                            }
                            Text(librarySubtitle(exercise))
                                .font(.caption)
                                .foregroundStyle(OG.label2)
                        }
                        Spacer(minLength: 0)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    store.addExerciseToTodayWorkout(exercise.id)
                    planFlashId = exercise.id
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        if planFlashId == exercise.id { planFlashId = nil }
                    }
                } label: {
                    Text(planFlashId == exercise.id ? "OK" : "+ Plan")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(OG.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Añadir al entreno del día")
            }
            .swipeActions {
                Button {
                    store.toggleFavorite(exercise.id)
                } label: {
                    Label(exercise.isFavorite ? "Quitar" : "Favorito", systemImage: "star")
                }
                .tint(OG.yellow)
                if exercise.isCustom {
                    Button(role: .destructive) {
                        store.deleteExercise(exercise.id)
                    } label: {
                        Label("Borrar", systemImage: "trash")
                    }
                }
            }
        }
    }

    private func librarySubtitle(_ exercise: Exercise) -> String {
        var parts: [String] = [exercise.muscleGroup]
        if let eq = exercise.equipment, !eq.isEmpty {
            parts.append(eq)
        }
        return parts.joined(separator: " · ")
    }

    private struct SectionModel: Identifiable {
        var id: String { key }
        var key: String
        var title: String?
        var items: [Exercise]
    }

    private var filtered: [Exercise] {
        var list = store.state.exercises
        if browseMode == .favorites {
            list = list.filter(\.isFavorite)
        }
        let q = query.lowercased()
        if !q.isEmpty {
            list = list.filter {
                $0.name.lowercased().contains(q)
                    || $0.muscleGroup.lowercased().contains(q)
                    || ($0.equipment?.lowercased().contains(q) ?? false)
                    || ($0.targetMuscle?.lowercased().contains(q) ?? false)
                    || ($0.detailDescription?.lowercased().contains(q) ?? false)
                    || $0.instructions.contains { $0.lowercased().contains(q) }
            }
        }
        return list
    }

    private var sections: [SectionModel] {
        let list = filtered
        switch browseMode {
        case .alphabetical, .favorites:
            return [
                SectionModel(
                    key: "all",
                    title: nil,
                    items: list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                ),
            ]
        case .muscle:
            return Dictionary(grouping: list, by: \.muscleGroup)
                .map { key, value in
                    SectionModel(
                        key: key,
                        title: key,
                        items: value.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                    )
                }
                .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
        case .sport:
            return Dictionary(grouping: list) { sportBucket(for: $0.muscleGroup) }
                .map { key, value in
                    SectionModel(
                        key: key,
                        title: key,
                        items: value.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                    )
                }
                .sorted { sportSort($0.key) < sportSort($1.key) }
        }
    }

    private func sportBucket(for muscleGroup: String) -> String {
        if sportGroups.contains(muscleGroup) { return muscleGroup }
        return "Fuerza"
    }

    private func sportSort(_ key: String) -> Int {
        switch key {
        case "Fuerza": return 0
        case "CrossFit": return 1
        case "Halterofilia": return 2
        case "Gimnasia": return 3
        case "Cardio": return 4
        default: return 99
        }
    }
}
