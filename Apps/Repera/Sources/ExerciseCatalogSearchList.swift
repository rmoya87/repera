import ReperaDomain
import SwiftUI

/// Fila ligera (sin `Exercise` embebido → Equatable/diff barato).
private struct PickerRow: Identifiable, Equatable {
    let id: UUID
    let name: String
    let subtitle: String
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
        .animation(nil, value: rowIDsToken)
        .searchable(
            text: $query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: prompt
        )
        .task(id: catalogToken) {
            await rebuildIndex()
        }
        .task(id: "\(query)|\(searchIndex.count)") {
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

        let newRows = ranked.map {
            PickerRow(id: $0.id, name: $0.displayName, subtitle: subtitle($0))
        }
        let token = String(newRows.count) + ":" + (newRows.first?.id.uuidString ?? "")
            + ":" + (newRows.last?.id.uuidString ?? "")
            + ":" + trimmed
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
