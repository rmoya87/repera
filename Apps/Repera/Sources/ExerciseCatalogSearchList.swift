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
            return doc.disciplineTags.contains(tag) || (tag == "Cardio" && doc.muscleGroup == "Cardio")
        }
    }
}

enum ExerciseCatalogSelectionMode: Sendable {
    case single
    case multiple
}

/// Lista + `.searchable` compartida: índice/ranking off-main, filas ligeras, prefetch viewport.
struct ExerciseCatalogSearchList<Header: View, Footer: View>: View {
    @Environment(ReperaStore.self) private var store
    let exercises: [Exercise]
    var prompt: String = "Buscar ejercicio"
    var pageTitle: String? = nil
    var selectionMode: ExerciseCatalogSelectionMode = .single
    var subtitle: (ExerciseSearch.Document) -> String = { doc in
        var parts = [doc.muscleGroup]
        if let eq = doc.equipment, !eq.isEmpty { parts.append(eq) }
        return parts.joined(separator: " · ")
    }
    var onPick: (Exercise) -> Void = { _ in }
    var onPickMany: ([Exercise]) -> Void = { _ in }
    @ViewBuilder var header: () -> Header
    @ViewBuilder var footer: () -> Footer

    @State private var query = ""
    @State private var filter: ExercisePickerFilter = .all
    @State private var selectedIDs: Set<UUID> = []
    @State private var searchIndex: [ExerciseSearch.Document] = []
    /// Índice ya ordenado A–Z (query vacía sin re-sort).
    @State private var alphabeticalIndex: [ExerciseSearch.Document] = []
    @State private var rows: [PickerRow] = []
    @State private var rowIDsToken: String = ""
    @State private var byId: [UUID: Exercise] = [:]

    private var isMultiple: Bool { selectionMode == .multiple }

    var body: some View {
        List {
            if let pageTitle {
                OGScrollablePageTitle(pageTitle).ogScrollingTitleListRow()
            }
            if isMultiple {
                Section {
                    muscleChipScroller
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            if isMultiple, !recentRows.isEmpty, query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Section("Recientes") {
                    pickerRows(recentRows)
                }
            }
            Section {
                pickerRows(rows)
            } header: {
                // No mezclar Section(String) con header:/footer: — Xcode lo
                // interpreta como Binding y falla al compilar.
                if isMultiple,
                   query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Todos (A–Z)")
                }
                header()
            } footer: {
                footer()
            }
        }
        .listStyle(.insetGrouped)
        .ogListChrome()
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            if isMultiple, !selectedIDs.isEmpty {
                OGFloatingPrimaryCTA(
                    title: "Añadir \(selectedIDs.count) ejercicio\(selectedIDs.count == 1 ? "" : "s")"
                ) {
                    let picked = selectedIDs.compactMap { byId[$0] }
                    guard !picked.isEmpty else { return }
                    onPickMany(picked)
                }
            }
        }
        .toolbar {
            if !isMultiple {
                ToolbarItem(placement: .topBarTrailing) {
                    filterMenu
                }
            }
        }
        .animation(nil, value: rowIDsToken)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: prompt)
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
            ExerciseArt.cancelThumbPrefetch()
        }
        .onChange(of: rowIDsToken) { _, _ in
            prefetchWindow()
        }
    }

    private var muscleChipScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                muscleChip("Todos", active: filter == .all) { filter = .all }
                ForEach(muscleOptions, id: \.self) { muscle in
                    muscleChip(muscle, active: filter == .muscle(muscle)) {
                        filter = .muscle(muscle)
                    }
                }
            }
            .padding(.horizontal, OG.pad)
            .padding(.vertical, 4)
        }
    }

  private func muscleChip(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(active ? OG.onAccent : OG.label)
                .padding(.horizontal, 14)
                .frame(height: 34)
                .background(active ? OG.accent : OG.surface2, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var filterMenu: some View {
        Menu {
            Button { filter = .all } label: {
                Label("Todos", systemImage: filter == .all ? "checkmark" : "list.bullet")
            }
            Button { filter = .favorites } label: {
                Label("Favoritos", systemImage: filter == .favorites ? "checkmark" : "star")
            }
            Menu("Grupo muscular") {
                ForEach(muscleOptions, id: \.self) { muscle in
                    Button { filter = .muscle(muscle) } label: {
                        if filter == .muscle(muscle) {
                            Label(muscle, systemImage: "checkmark")
                        } else {
                            Text(muscle)
                        }
                    }
                }
            }
            Menu("Disciplina") {
                ForEach(["Fuerza", "CrossFit", "HYROX", "Halterofilia", "Gimnasia", "Cardio"], id: \.self) { sport in
                    Button { filter = .sport(sport) } label: {
                        if filter == .sport(sport) {
                            Label(sport, systemImage: "checkmark")
                        } else {
                            Text(sport)
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(filter == .all ? OG.label : OG.accent)
        }
        .accessibilityLabel(
            filter == .all
                ? "Filtrar ejercicios por grupo muscular o disciplina"
                : "Filtro: \(filter.title)"
        )
    }

    @ViewBuilder
    private func pickerRows(_ source: [PickerRow]) -> some View {
        ForEach(source) { row in
            if isMultiple {
                multiSelectRow(row)
            } else {
                singleSelectRow(row)
            }
        }
    }

    private func singleSelectRow(_ row: PickerRow) -> some View {
        Button {
            if let exercise = byId[row.id] {
                onPick(exercise)
            }
        } label: {
            rowLabel(row, trailing: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(OG.label3)
            })
        }
        .buttonStyle(.plain)
    }

    private func multiSelectRow(_ row: PickerRow) -> some View {
        Button {
            if selectedIDs.contains(row.id) {
                selectedIDs.remove(row.id)
            } else {
                selectedIDs.insert(row.id)
            }
        } label: {
            let selected = selectedIDs.contains(row.id)
            rowLabel(row, trailing: {
                Image(systemName: selected ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(selected ? OG.accent : OG.label3)
            })
        }
        .buttonStyle(.plain)
    }

    private func rowLabel<Trailing: View>(
        _ row: PickerRow,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
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
            trailing()
        }
        .contentShape(Rectangle())
    }

    private var recentRows: [PickerRow] {
        recentExerciseIDs.compactMap { id in
            guard let exercise = byId[id] else { return nil }
            return PickerRow(
                id: id,
                name: exercise.name,
                subtitle: subtitle(for: exercise)
            )
        }
    }

    private func subtitle(for exercise: Exercise) -> String {
        var parts = [exercise.muscleGroup]
        if let eq = exercise.equipment, !eq.isEmpty { parts.append(eq) }
        return parts.joined(separator: " · ")
    }

    private var recentExerciseIDs: [UUID] {
        var seen = Set<UUID>()
        var ids: [UUID] = []
        for session in store.state.workouts.prefix(20) {
            for item in session.exercises {
                let exerciseID = item.exercise.id
                if seen.insert(exerciseID).inserted {
                    ids.append(exerciseID)
                    if ids.count >= 8 { return ids }
                }
            }
        }
        return ids
    }

    private var muscleOptions: [String] {
        Array(Set(exercises.map(\.muscleGroup))).filter { !$0.isEmpty }.sorted()
    }

    private var catalogToken: String {
        "\(store.catalogEpoch)|\(exercises.count)|\(exercises.first?.id.uuidString ?? "")|\(exercises.last?.id.uuidString ?? "")"
    }

    private func rebuildIndex() async {
        let catalog = exercises.filter { !$0.isCatalogArchived }
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
        pageTitle: String? = nil,
        selectionMode: ExerciseCatalogSelectionMode = .single,
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
            pageTitle: pageTitle,
            selectionMode: selectionMode,
            subtitle: subtitle,
            onPick: onPick,
            onPickMany: { _ in },
            header: { EmptyView() },
            footer: { EmptyView() }
        )
    }

    init(
        exercises: [Exercise],
        prompt: String = "Buscar ejercicio",
        pageTitle: String? = nil,
        selectionMode: ExerciseCatalogSelectionMode = .multiple,
        subtitle: @escaping (ExerciseSearch.Document) -> String = { doc in
            var parts = [doc.muscleGroup]
            if let eq = doc.equipment, !eq.isEmpty { parts.append(eq) }
            return parts.joined(separator: " · ")
        },
        onPickMany: @escaping ([Exercise]) -> Void
    ) {
        self.init(
            exercises: exercises,
            prompt: prompt,
            pageTitle: pageTitle,
            selectionMode: selectionMode,
            subtitle: subtitle,
            onPick: { _ in },
            onPickMany: onPickMany,
            header: { EmptyView() },
            footer: { EmptyView() }
        )
    }
}
