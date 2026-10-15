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
    @State private var browseMode: ExerciseBrowseMode = .alphabetical

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
            .toolbarBackground(OG.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showFilter = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Filtrar y ordenar")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showFilter) {
                filterSheet
            }
            .sheet(isPresented: $showingAdd) {
                NavigationStack {
                    Form {
                        TextField("Nombre", text: $name)
                        Picker("Músculo", selection: $muscle) {
                            ForEach(muscles, id: \.self) { Text($0).tag($0) }
                        }
                        TextField("Equipamiento", text: $equipment)
                    }
                    .navigationTitle("Nuevo ejercicio")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancelar") { showingAdd = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Añadir") {
                                store.addCustomExercise(
                                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                    muscleGroup: muscle,
                                    equipment: equipment.isEmpty ? nil : equipment
                                )
                                name = ""
                                equipment = ""
                                showingAdd = false
                            }
                            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
                .preferredColorScheme(.dark)
            }
        }
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
            NavigationLink {
                ExerciseDetailView(exerciseId: exercise.id)
            } label: {
                HStack(spacing: 12) {
                    ExerciseThumb(exercise: exercise)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(exercise.name)
                            if exercise.isFavorite {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundStyle(OG.yellow)
                            }
                        }
                        HStack {
                            Text(exercise.muscleGroup)
                            if let eq = exercise.equipment {
                                Text("· \(eq)")
                            }
                            if let target = exercise.targetMuscle {
                                Text("· \(LocalizedMuscle.es(target))")
                            }
                            if exercise.isCustom {
                                Text("Propio")
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(OG.surface2, in: Capsule())
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(OG.label2)
                    }
                    Spacer()
                }
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
