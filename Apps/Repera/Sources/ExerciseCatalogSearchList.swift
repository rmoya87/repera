import ReperaDomain
import SwiftUI

/// Fila ligera (sin `Exercise` embebido → Equatable/diff barato).
private struct PickerRow: Identifiable, Equatable {
    let id: UUID
    let name: String
    let subtitle: String
}

private enum ExercisePickerFilter: Hashable, Sendable {
    case all
    case favorites
    case muscle(String)
    case sport(String)

    var title: String {
        switch self {
        case .all: return "Todos"
        case .favorites: return "Favoritos"
        case .muscle(let name), .sport(let name): return name
        }
    }

    func matches(_ doc: ExerciseSearch.Document) -> Bool {
        switch self {
        case .all: return true
        case .favorites: return doc.isFavorite
        case .muscle(let name): return doc.muscleGroup == name
        case .sport(let tag):
            if tag == "Fuerza" {
                return doc.sportTag == nil && doc.muscleGroup != "Cardio"
            }
            return doc.sportTag == tag || (tag == "Cardio" && doc.muscleGroup == "Cardio")
        }
    }
}

/// Lista + `.searchable` compartida: índice/ranking off-main, filas ligeras, prefetch viewport.
struct ExerciseCatalogSearchList<Header: View, Footer: View>: View {
    let exercises: [Exercise]
    var prompt: String = "Buscar ejercicio"
    var subtitle: (ExerciseSearch.Document) -> String = { doc in
        var parts = [doc.muscleGroup]
        if let eq = doc.equipment, !eq.isEmpty { parts.append(eq) }
        return parts.joined(separator: " · ")
    }
    var onPick: (Exercise) -> Void
    @ViewBuilder var header: () -> Header
    @ViewBuilder var footer: () -> Footer

    @State private var query = ""
    @State private var filter: ExercisePickerFilter = .all
    @State private var searchIndex: [ExerciseSearch.Document] = []
    /// Índice ya ordenado A–Z (query vacía sin re-sort).
    @State private var alphabeticalIndex: [ExerciseSearch.Document] = []
    @State private var rows: [PickerRow] = []
    @State private var rowIDsToken: String = ""
    @State private var byId: [UUID: Exercise] = [:]

    var body: some View {
        List {
            Section {
                ForEach(rows) { row in
                    Button {
                        if let exercise = byId[row.id] {
                            onPick(exercise)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            if let exercise = byId[row.id] {
                                ExerciseThumb(exercise: exercise)
                            } else {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(OG.surface2)
                                    .frame(width: 48, height: 48)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.name)
                                    .foregroundStyle(OG.label)
                                Text(row.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(OG.label2)
                            }
                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                header()
            } footer: {
                footer()
            }
        }
        .listStyle(.insetGrouped)
        .ogListChrome()
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        filter = .all
                    } label: {
                        Label("Todos", systemImage: filter == .all ? "checkmark" : "list.bullet")
                    }
                    Button {
                        filter = .favorites
                    } label: {
                        Label("Favoritos", systemImage: filter == .favorites ? "checkmark" : "star")
                    }
                    Menu("Grupo muscular") {
                        ForEach(muscleOptions, id: \.self) { muscle in
                            Button {
                                filter = .muscle(muscle)
                            } label: {
                                if filter == .muscle(muscle) {
                                    Label(muscle, systemImage: "checkmark")
                                } else {
                                    Text(muscle)
                                }
                            }
                        }
                    }
                    Menu("Disciplina") {
                        ForEach(["Fuerza", "CrossFit", "Halterofilia", "Gimnasia", "Cardio"], id: \.self) { sport in
                            Button {
                                filter = .sport(sport)
                            } label: {
                                if filter == .sport(sport) {
                                    Label(sport, systemImage: "checkmark")
                                } else {
                                    Text(sport)
                                }
                            }
                        }
                    }
                } label: {
                    Label(filter == .all ? "Filtrar" : filter.title, systemImage: "line.3.horizontal.decrease")
                }
                .accessibilityLabel("Filtrar ejercicios por grupo muscular o disciplina")
            }
        }
        .animation(nil, value: rowIDsToken)
        .searchable(
            text: $query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: prompt
        )
        .task(id: catalogToken) {
            await rebuildIndex()
        }
        .task(id: "\(query)|\(searchIndex.count)|\(filter.title)") {
            await applyQuery()
        }
        .onAppear {
            prefetchWindow()
        }
        .onDisappear {
            // Solo cancela prefetch group; los loads de celdas visibles siguen via cache.
            ExerciseArt.cancelThumbPrefetch()
        }
        .onChange(of: rowIDsToken) { _, _ in
            prefetchWindow()
        }
    }

    private var muscleOptions: [String] {
        Array(Set(exercises.map(\.muscleGroup))).filter { !$0.isEmpty }.sorted()
    }

    private var catalogToken: String {
        "\(exercises.count)|\(exercises.first?.id.uuidString ?? "")|\(exercises.last?.id.uuidString ?? "")"
    }

    private func rebuildIndex() async {
        let catalog = exercises
        let map = Dictionary(uniqueKeysWithValues: catalog.map { ($0.id, $0) })
        let built = await Task.detached(priority: .userInitiated) { () -> (index: [ExerciseSearch.Document], alpha: [ExerciseSearch.Document]) in
            let index = ExerciseSearch.makeIndex(catalog)
            let alpha = index.sorted {
                $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
            }
            return (index, alpha)
        }.value
        guard !Task.isCancelled else { return }
        byId = map
        searchIndex = built.index
        alphabeticalIndex = built.alpha
        LibrarySearchLog.info("picker index ready docs=\(built.index.count)")
    }

    private func applyQuery() async {
        let q = query
        let index = searchIndex
        let alpha = alphabeticalIndex
        let selectedFilter = filter
        guard !index.isEmpty || exercises.isEmpty else { return }

        let trimmed = q.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            try? await Task.sleep(for: .milliseconds(140))
            guard !Task.isCancelled else { return }
        }

        let t0 = CFAbsoluteTimeGetCurrent()
        let ranked = await Task.detached(priority: .userInitiated) { () -> [ExerciseSearch.Document] in
            if trimmed.isEmpty {
                return alpha.isEmpty
                    ? index.sorted {
                        $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
                    }
                    : alpha
            }
            return ExerciseSearch.rankedDocuments(index, query: trimmed)
        }.value
        guard !Task.isCancelled else { return }

        let newRows = ranked.filter { selectedFilter.matches($0) }.map {
            PickerRow(id: $0.id, name: $0.displayName, subtitle: subtitle($0))
        }
        let token = String(newRows.count) + ":" + (newRows.first?.id.uuidString ?? "")
            + ":" + (newRows.last?.id.uuidString ?? "")
            + ":" + trimmed + ":" + selectedFilter.title
        if token != rowIDsToken || newRows != rows {
            rows = newRows
            rowIDsToken = token
        }
        LibrarySearchLog.rebuildSections(
            reason: trimmed.isEmpty ? "picker-browse" : "picker-query",
            count: newRows.count,
            queryEmpty: trimmed.isEmpty,
            ms: (CFAbsoluteTimeGetCurrent() - t0) * 1000
        )
    }

    private func prefetchWindow() {
        let ids = rows.prefix(20).map(\.id)
        let window = ids.compactMap { byId[$0] }
        ExerciseArt.prefetchThumbs(for: window, limit: 20)
    }
}

extension ExerciseCatalogSearchList where Header == EmptyView, Footer == EmptyView {
    init(
        exercises: [Exercise],
        prompt: String = "Buscar ejercicio",
        subtitle: @escaping (ExerciseSearch.Document) -> String = { doc in
            var parts = [doc.muscleGroup]
            if let eq = doc.equipment, !eq.isEmpty { parts.append(eq) }
            return parts.joined(separator: " · ")
        },
        onPick: @escaping (Exercise) -> Void
    ) {
        self.init(
            exercises: exercises,
            prompt: prompt,
            subtitle: subtitle,
            onPick: onPick,
            header: { EmptyView() },
            footer: { EmptyView() }
        )
    }
}
