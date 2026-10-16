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
    var onOpenedWorkout: (() -> Void)? = nil
    /// Texto del campo de búsqueda (filtra al instante; el índice precomputado hace barato el rank).
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
    /// Secciones cacheadas: no reordenar ~200 filas en cada tecla.
    @State private var cachedSections: [LibrarySectionModel] = []
    /// Nombres/meta ya normalizados (evitar re-normalize en cada tecla).
    @State private var searchIndex: [ExerciseSearch.Document] = []
    @State private var didPrefetchThumbs = false

    private let muscles = [
        "Pecho", "Espalda", "Piernas", "Isquios", "Hombros", "Bíceps", "Tríceps",
        "Core", "Glúteos", "Gemelos", "Antebrazos", "Cardio",
    ]

    private let sportTags: Set<String> = ["CrossFit", "Halterofilia", "Gimnasia", "Cardio"]

    var body: some View {
        NavigationStack {
            LibraryExerciseList(
                sections: cachedSections,
                onToggleFavorite: { store.toggleFavorite($0) },
                onDelete: { store.deleteExercise($0) }
            )
            .ogListChrome()
            .scrollDismissesKeyboard(.interactively)
            // Sin animaciones al filtrar / al activar teclado (isSearching).
            .transaction { $0.animation = nil }
            .animation(nil, value: query)
            .onChange(of: query) { _, _ in
                rebuildSections(reason: "query")
            }
            .onChange(of: browseMode) { _, _ in
                rebuildSections(reason: "browseMode")
            }
            .onChange(of: store.state.exercises) { _, exercises in
                searchIndex = ExerciseSearch.makeIndex(exercises)
                rebuildSections(reason: "exercises")
                prefetchThumbsIfNeeded()
            }
            .onAppear {
                if searchIndex.isEmpty {
                    searchIndex = ExerciseSearch.makeIndex(store.state.exercises)
                }
                if cachedSections.isEmpty {
                    rebuildSections(reason: "appear")
                }
                prefetchThumbsIfNeeded()
            }
            .navigationTitle("Ejercicios")
            .navigationBarTitleDisplayMode(.inline)
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
            // Campo nativo del sistema debajo del título / filtro / +.
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Nombre, músculo o equipo"
            )
            .navigationDestination(for: UUID.self) { id in
                ExerciseDetailView(exerciseId: id, onOpenedWorkout: onOpenedWorkout)
            }
            .sheet(isPresented: $showFilter) {
                filterSheet
            }
            .sheet(isPresented: $showingAdd) {
                addExerciseSheet
                    .ogSheetCorners()
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
        VStack(alignment: .leading, spacing: 14) {
            OGPageHeader(title: "Filtro") {
                CloseToolbarButton { showFilter = false }
            }
            .padding(.top, 4)

            Text("Ordenar / filtrar")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(OG.label2)
                .textCase(.uppercase)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(ExerciseBrowseMode.allCases.enumerated()), id: \.element.id) { index, mode in
                    if index > 0 {
                        Divider().opacity(0.35).padding(.leading, 50)
                    }
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

    private func prefetchThumbsIfNeeded() {
        guard !didPrefetchThumbs else { return }
        didPrefetchThumbs = true
        ExerciseArt.prefetchThumbs(for: store.state.exercises)
    }

    private func rebuildSections(reason: String) {
        let t0 = CFAbsoluteTimeGetCurrent()
        let sections = makeSections()
        // Evita invalidar la List si el resultado no cambió (p. ej. espacios al final).
        if sections == cachedSections { return }
        cachedSections = sections
        let items = sections.reduce(0) { $0 + $1.items.count }
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        LibrarySearchLog.rebuildSections(
            reason: reason,
            count: items,
            queryEmpty: q.isEmpty,
            ms: (CFAbsoluteTimeGetCurrent() - t0) * 1000
        )
        #if DEBUG
        if !q.isEmpty, let top = sections.first?.items.prefix(3) {
            let labels = top.map {
                "\($0.name)(\(ExerciseSearch.score($0.exercise, query: q)))"
            }
            LibrarySearchLog.info("rank top: \(labels.joined(separator: ", "))")
        }
        #endif
    }

    private func filteredExercises() -> [Exercise] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let docs: [ExerciseSearch.Document]
        if browseMode == .favorites {
            docs = searchIndex.filter(\.exercise.isFavorite)
        } else {
            docs = searchIndex
        }
        guard !q.isEmpty else {
            return docs.map(\.exercise)
        }
        return ExerciseSearch.ranked(docs, query: q)
    }

    private func rowModels(from exercises: [Exercise]) -> [LibraryRowModel] {
        exercises.map { ex in
            LibraryRowModel(
                id: ex.id,
                name: ex.name,
                subtitle: librarySubtitle(ex),
                isFavorite: ex.isFavorite,
                isCustom: ex.isCustom,
                exercise: ex
            )
        }
    }

    private func librarySubtitle(_ exercise: Exercise) -> String {
        var parts: [String] = [exercise.muscleGroup]
        if let sport = exercise.sportTag, !sport.isEmpty {
            parts.append(sport)
        }
        if let eq = exercise.equipment, !eq.isEmpty {
            parts.append(LocalizedMuscle.es(eq))
        }
        return parts.joined(separator: " · ")
    }

    private func makeSections() -> [LibrarySectionModel] {
        let list = filteredExercises()
        let searching = !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        // Misma `key` en lista plana: SwiftUI reusa filas/thumbs al filtrar (diff por id).
        if searching {
            return [
                LibrarySectionModel(key: "flat", title: nil, items: rowModels(from: list)),
            ]
        }
        if browseMode == .alphabetical || browseMode == .favorites {
            let sorted = list.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            return [
                LibrarySectionModel(key: "flat", title: nil, items: rowModels(from: sorted)),
            ]
        }
        switch browseMode {
        case .alphabetical, .favorites:
            let sorted = list.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            return [
                LibrarySectionModel(key: "flat", title: nil, items: rowModels(from: sorted)),
            ]
        case .muscle:
            return Dictionary(grouping: list, by: \.muscleGroup)
                .map { key, value in
                    let sorted = value.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
                    return LibrarySectionModel(key: key, title: key, items: rowModels(from: sorted))
                }
                .sorted { $0.key < $1.key }
        case .sport:
            return Dictionary(grouping: list) { sportBucket(for: $0) }
                .map { key, value in
                    let sorted = value.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
                    return LibrarySectionModel(key: key, title: key, items: rowModels(from: sorted))
                }
                .sorted { sportSort($0.key) < sportSort($1.key) }
        }
    }

    private func sportBucket(for exercise: Exercise) -> String {
        if let tag = exercise.sportTag, sportTags.contains(tag) { return tag }
        if exercise.muscleGroup == "Cardio" { return "Cardio" }
        if sportTags.contains(exercise.muscleGroup) { return exercise.muscleGroup }
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

private struct LibrarySectionModel: Identifiable, Equatable {
    var id: String { key }
    var key: String
    var title: String?
    var items: [LibraryRowModel]
}

private struct LibraryRowModel: Identifiable, Equatable {
    let id: UUID
    let name: String
    let subtitle: String
    let isFavorite: Bool
    let isCustom: Bool
    let exercise: Exercise
}

/// Lista aislada: lee `isSearching` y corta animaciones al abrir el teclado.
private struct LibraryExerciseList: View {
    @Environment(\.isSearching) private var isSearching

    let sections: [LibrarySectionModel]
    var onToggleFavorite: (UUID) -> Void
    var onDelete: (UUID) -> Void

    var body: some View {
        List {
            ForEach(sections) { group in
                if let title = group.title {
                    Section(title) {
                        rows(group.items)
                    }
                } else {
                    Section {
                        rows(group.items)
                    }
                }
            }
        }
        .animation(nil, value: isSearching)
        .transaction { tx in
            tx.animation = nil
            if isSearching {
                tx.disablesAnimations = true
            }
        }
    }

    @ViewBuilder
    private func rows(_ items: [LibraryRowModel]) -> some View {
        ForEach(items) { row in
            NavigationLink(value: row.id) {
                LibraryExerciseRowLabel(row: row)
            }
            .swipeActions {
                Button {
                    onToggleFavorite(row.id)
                } label: {
                    Label(row.isFavorite ? "Quitar" : "Favorito", systemImage: "star")
                }
                .tint(OG.yellow)
                if row.isCustom {
                    Button(role: .destructive) {
                        onDelete(row.id)
                    } label: {
                        Label("Borrar", systemImage: "trash")
                    }
                }
            }
        }
    }
}

private struct LibraryExerciseRowLabel: View {
    let row: LibraryRowModel

    var body: some View {
        HStack(spacing: 12) {
            ExerciseThumb(exercise: row.exercise)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(row.name)
                        .foregroundStyle(OG.label)
                    if row.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(OG.yellow)
                    }
                }
                Text(row.subtitle)
                    .font(.caption)
                    .foregroundStyle(OG.label2)
            }
            Spacer(minLength: 0)
        }
    }
}
