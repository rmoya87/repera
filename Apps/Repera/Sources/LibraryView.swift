import ReperaDomain
import SwiftUI

private enum ExerciseBrowseMode: String, CaseIterable, Identifiable, Sendable {
    case alphabetical
    case muscle
    case sport
    case hyrox
    case favorites
    case wods

    var id: String { rawValue }

    var title: String {
        switch self {
        case .alphabetical: return "Alfabético"
        case .muscle: return "Músculo"
        case .sport: return "Deporte"
        case .hyrox: return "HYROX"
        case .favorites: return "Favoritos"
        case .wods: return "WODs"
        }
    }

    var icon: String {
        switch self {
        case .alphabetical: return "textformat.abc"
        case .muscle: return "figure.strengthtraining.traditional"
        case .sport: return "sportscourt"
        case .hyrox: return "figure.run"
        case .favorites: return "star.fill"
        case .wods: return "timer"
        }
    }
}

struct LibraryView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
    @Namespace private var exerciseZoomNamespace

    private let muscles = [
        "Pecho", "Espalda", "Piernas", "Isquios", "Hombros", "Bíceps", "Tríceps",
        "Core", "Glúteos", "Gemelos", "Antebrazos", "Cardio",
    ]

    private let sportTags: Set<String> = ["CrossFit", "HYROX", "Halterofilia", "Gimnasia", "Cardio"]

    var body: some View {
        NavigationStack {
            Group {
                // En WODs, si la búsqueda no pega con ningún WOD (p. ej. «back squat»),
                // mostrar ejercicios: si no, parece que «no hay ejercicio».
                if browseMode == .wods, query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || !filteredWODTemplates.isEmpty {
                    wodsList
                } else {
                    LibraryExerciseList(
                        sections: cachedSections,
                        zoomNamespace: exerciseZoomNamespace,
                        reduceMotion: reduceMotion,
                        onToggleFavorite: { store.toggleFavorite($0) },
                        onDelete: { store.deleteExercise($0) }
                    )
                }
            }
            .scrollDismissesKeyboard(.interactively)
            // Only mute list diff animations — do not disable keyboard / focus transitions.
            .animation(nil, value: cachedSections.map(\.id))
            .task(id: store.catalogEpoch) {
                await rebuildIndexOffMain(reason: "catalog")
            }
            .task(id: "\(query)|\(browseMode.rawValue)|\(searchIndex.count)") {
                await applySectionsCancelable(reason: query.isEmpty ? "browse" : "query")
            }
            .onChange(of: browseMode) { _, _ in
                if browseMode != .wods {
                    prefetchVisibleThumbs()
                }
            }
            .onAppear {
                if browseMode != .wods {
                    prefetchVisibleThumbs()
                }
            }
            .onDisappear {
                ExerciseArt.cancelThumbPrefetch()
            }
            .navigationTitle(browseMode == .wods ? "WODs" : "Ejercicios")
            .navigationBarTitleDisplayMode(.inline)
            .ogDiaryTransparentNav()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    OGToolbarGlassButton(
                        systemName: "line.3.horizontal.decrease",
                        accessibilityLabel: "Filtrar y ordenar"
                    ) {
                        showFilter = true
                    }
                }
                if browseMode != .wods {
                    ToolbarItem(placement: .topBarTrailing) {
                        OGToolbarGlassButton(
                            systemName: "plus",
                            accessibilityLabel: "Nuevo ejercicio"
                        ) {
                            let decision = subscriptions.canCreateCustomExercise(isNew: true)
                            if decision.allowed {
                                showingAdd = true
                            } else {
                                subscriptions.presentPaywall(
                                    decision.paywallContext,
                                    feature: .unlimitedCustomExercises
                                )
                            }
                        }
                    }
                }
            }
            // Campo nativo del sistema debajo del título / filtro / +.
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: browseMode == .wods ? "Nombre o formato" : "Nombre, músculo o equipo"
            )
            .navigationDestination(for: UUID.self) { id in
                ExerciseDetailView(exerciseId: id, onOpenedWorkout: onOpenedWorkout)
                    .modifier(ExerciseZoomDestinationModifier(
                        id: id,
                        namespace: exerciseZoomNamespace,
                        enabled: !reduceMotion
                    ))
            }
            .navigationDestination(for: String.self) { templateId in
                if let template = CatalogWODs.template(id: templateId) {
                    WODTemplateDetailView(
                        template: template,
                        history: wodHistory(for: templateId),
                        showSessionActions: true,
                        onOpenedWorkout: onOpenedWorkout,
                        unlockFullHistory: subscriptions.isPro
                    )
                }
            }
            .sheet(isPresented: $showFilter) {
                filterSheet
            }
            .navigationDestination(isPresented: $showingAdd) {
                addExercisePage
            }
        }
    }

    private var wodsList: some View {
        List {
            ForEach(filteredWODTemplates) { template in
                NavigationLink(value: template.id) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(template.name)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(OG.label)
                                if store.isWODTemplateFavorite(template.id) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(OG.yellow)
                                }
                            }
                            Text(template.formatLabel)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(OG.accent)
                            if !template.muscles.isEmpty {
                                Text(template.musclesLabel)
                                    .font(.system(size: 12))
                                    .foregroundStyle(OG.label3)
                                    .lineLimit(1)
                            }
                        }
                        Spacer(minLength: 0)
                        VStack(alignment: .trailing, spacing: 4) {
                            if let typical = template.typicalLabel {
                                Text(typical)
                                    .font(.system(size: 13, weight: .semibold).monospacedDigit())
                                    .foregroundStyle(OG.label2)
                            }
                            let hist = wodHistory(for: template.id)
                            if let best = hist.first {
                                Text(best.summaryLabel)
                                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                                    .foregroundStyle(OG.accent)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .listStyle(.insetGrouped)
        .contentMargins(.top, 0, for: .scrollContent)
        .listSectionSpacing(.compact)
        .ogListChrome()
    }

    private var filteredWODTemplates: [WODTemplate] {
        CatalogWODs.search(query).sorted { a, b in
            let fa = store.isWODTemplateFavorite(a.id)
            let fb = store.isWODTemplateFavorite(b.id)
            if fa != fb { return fa && !fb }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }

    private func wodHistory(for templateId: String) -> [WODBlockResult] {
        store.state.workouts
            .flatMap(\.wodResults)
            .filter { $0.wodTemplateId == templateId }
            .sorted { lhs, rhs in
                // Mejor For Time = menor tiempo; mejor AMRAP = más reps.
                if let le = lhs.elapsedSeconds, let re = rhs.elapsedSeconds {
                    return le < re
                }
                if let lr = lhs.totalReps, let rr = rhs.totalReps {
                    return lr > rr
                }
                return false
            }
    }

    /// Página push (no sheet): mismo patrón que el resto de subpáginas de Ejercicios.
    private var addExercisePage: some View {
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
        .listStyle(.insetGrouped)
        .ogListChrome()
        .ogPinnedTransparentNav("Nuevo ejercicio")
        .toolbar {
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
                    let ok = store.addCustomExercise(
                        name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                        muscleGroup: muscle,
                        equipment: equipment.isEmpty ? nil : equipment,
                        targetMuscle: targetMuscle.isEmpty ? nil : targetMuscle,
                        secondaryMuscles: secondary,
                        bodyPart: bodyPart.isEmpty ? nil : bodyPart,
                        detailDescription: detailDescription.isEmpty ? nil : detailDescription,
                        instructions: instructions
                    )
                    if ok {
                        resetAddForm()
                        showingAdd = false
                    } else {
                        showingAdd = false
                        let decision = store.lastAccessDenial
                            ?? subscriptions.canCreateCustomExercise(isNew: true)
                        subscriptions.presentPaywall(
                            decision.paywallContext,
                            feature: .unlimitedCustomExercises
                        )
                    }
                }
                .fontWeight(.semibold)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onDisappear {
            resetAddForm()
        }
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
        .ogFittedSheet()
    }

    private func prefetchVisibleThumbs() {
        let ids = cachedSections.prefix(2).flatMap(\.items).prefix(20).map(\.id)
        let exercises = ids.compactMap { id in store.state.exercises.first { $0.id == id } }
        let source = exercises.isEmpty ? Array(store.state.exercises.prefix(16)) : exercises
        ExerciseArt.prefetchThumbs(for: source, limit: 20)
        didPrefetchThumbs = true
    }

    private func rebuildIndexOffMain(reason: String) async {
        let exercises = store.state.exercises
        LibrarySearchLog.signpostBegin("IndexBuild")
        let index = await Task.detached(priority: .userInitiated) {
            ExerciseSearch.makeIndex(exercises)
        }.value
        guard !Task.isCancelled else {
            LibrarySearchLog.signpostEnd("IndexBuild")
            return
        }
        searchIndex = index
        LibrarySearchLog.signpostEnd("IndexBuild")
        LibrarySearchLog.info("index ready reason=\(reason) docs=\(index.count)")
        await applySectionsCancelable(reason: reason)
        prefetchVisibleThumbs()
    }

    private func applySectionsCancelable(reason: String) async {
        let t0 = CFAbsoluteTimeGetCurrent()
        LibrarySearchLog.signpostBegin("SectionsBuild")
        let index = searchIndex
        let mode = browseMode
        let q = query
        let byId = Dictionary(uniqueKeysWithValues: store.state.exercises.map { ($0.id, $0) })
        let sections = await Task.detached(priority: .userInitiated) {
            Self.makeSections(
                index: index,
                query: q,
                browseMode: mode,
                sportTags: ["CrossFit", "HYROX", "Halterofilia", "Gimnasia", "Cardio"],
                exercisesById: byId
            )
        }.value
        guard !Task.isCancelled else {
            LibrarySearchLog.signpostEnd("SectionsBuild")
            return
        }
        if sections != cachedSections {
            cachedSections = sections
        }
        let items = sections.reduce(0) { $0 + $1.items.count }
        LibrarySearchLog.signpostEnd("SectionsBuild")
        LibrarySearchLog.rebuildSections(
            reason: reason,
            count: items,
            queryEmpty: q.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            ms: (CFAbsoluteTimeGetCurrent() - t0) * 1000
        )
    }

    nonisolated private static func makeSections(
        index: [ExerciseSearch.Document],
        query: String,
        browseMode: ExerciseBrowseMode,
        sportTags: Set<String>,
        exercisesById: [UUID: Exercise]
    ) -> [LibrarySectionModel] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let docs: [ExerciseSearch.Document]
        if browseMode == .favorites {
            docs = index.filter(\.isFavorite)
        } else if browseMode == .hyrox {
            docs = index.filter { $0.disciplineTags.contains("HYROX") }
        } else {
            docs = index
        }
        let rankedDocs: [ExerciseSearch.Document]
        if q.isEmpty {
            rankedDocs = docs.sorted {
                $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
            }
        } else {
            rankedDocs = ExerciseSearch.rankedDocuments(docs, query: q)
        }
        let rows = rankedDocs.compactMap { doc -> LibraryRowModel? in
            guard let ex = exercisesById[doc.id] else { return nil }
            return LibraryRowModel(
                id: doc.id,
                name: doc.displayName,
                subtitle: librarySubtitle(doc),
                isFavorite: doc.isFavorite,
                isCustom: ex.isCustom,
                exercise: ex
            )
        }
        if !q.isEmpty || browseMode == .alphabetical || browseMode == .favorites || browseMode == .hyrox {
            return [LibrarySectionModel(key: "flat", title: nil, items: rows)]
        }
        switch browseMode {
        case .alphabetical, .favorites, .hyrox, .wods:
            return [LibrarySectionModel(key: "flat", title: nil, items: rows)]
        case .muscle:
            return Dictionary(grouping: rows, by: { exercisesById[$0.id]?.muscleGroup ?? "" })
                .map { key, value in
                    LibrarySectionModel(key: key, title: key, items: value)
                }
                .sorted { $0.key < $1.key }
        case .sport:
            // Un ejercicio puede aparecer en varias disciplinas sin duplicar el modelo/UUID.
            var buckets: [String: [LibraryRowModel]] = [:]
            for row in rows {
                let tags = exercisesById[row.id]?.disciplineTags.filter { sportTags.contains($0) } ?? []
                let groups = tags.isEmpty
                    ? [sportBucket(for: exercisesById[row.id], sportTags: sportTags)]
                    : tags
                for group in groups {
                    buckets[group, default: []].append(row)
                }
            }
            return buckets.map { key, value in
                LibrarySectionModel(key: key, title: key, items: value)
            }
            .sorted { sportSort($0.key) < sportSort($1.key) }
        }
    }

    nonisolated private static func librarySubtitle(_ doc: ExerciseSearch.Document) -> String {
        var parts: [String] = [doc.muscleGroup]
        parts.append(contentsOf: doc.disciplineTags.filter { !$0.isEmpty })
        if let eq = doc.equipment, !eq.isEmpty {
            parts.append(LocalizedMuscle.es(eq))
        }
        return parts.joined(separator: " · ")
    }

    nonisolated private static func sportBucket(for exercise: Exercise?, sportTags: Set<String>) -> String {
        guard let exercise else { return "Fuerza" }
        if let tag = exercise.sportTag, sportTags.contains(tag) { return tag }
        if exercise.muscleGroup == "Cardio" { return "Cardio" }
        if sportTags.contains(exercise.muscleGroup) { return exercise.muscleGroup }
        return "Fuerza"
    }

    nonisolated private static func sportSort(_ key: String) -> Int {
        switch key {
        case "Fuerza": return 0
        case "CrossFit": return 1
        case "HYROX": return 2
        case "Halterofilia": return 3
        case "Gimnasia": return 4
        case "Cardio": return 5
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

/// Lista aislada. Does not disable system search/keyboard animations.
private struct LibraryExerciseList: View {
    let sections: [LibrarySectionModel]
    var zoomNamespace: Namespace.ID
    var reduceMotion: Bool
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
        .listStyle(.insetGrouped)
        .ogListChrome()
    }

    @ViewBuilder
    private func rows(_ items: [LibraryRowModel]) -> some View {
        ForEach(items) { row in
            NavigationLink(value: row.id) {
                LibraryExerciseRowLabel(row: row)
            }
            .modifier(ExerciseZoomSourceModifier(
                id: row.id,
                namespace: zoomNamespace,
                enabled: !reduceMotion
            ))
            .swipeActions {
                Button {
                    onToggleFavorite(row.id)
                } label: {
                    Image(systemName: row.isFavorite ? "star.slash" : "star")
                }
                .tint(OG.yellow)
                .accessibilityLabel(row.isFavorite ? "Quitar de favoritos" : "Marcar favorito")
                if row.isCustom {
                    OGSwipeDeleteButton(accessibilityLabel: "Borrar ejercicio personalizado") {
                        onDelete(row.id)
                    }
                }
            }
        }
    }
}

private struct ExerciseZoomSourceModifier: ViewModifier {
    let id: UUID
    let namespace: Namespace.ID
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}

private struct ExerciseZoomDestinationModifier: ViewModifier {
    let id: UUID
    let namespace: Namespace.ID
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            content
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
