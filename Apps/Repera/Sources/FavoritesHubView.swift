import ReperaDomain
import SwiftUI

/// Crear → Favoritos: entrenos y temporizadores habituales.
struct FavoritesHubView: View {
    @Environment(ReperaStore.self) private var store
    var onOpenedWorkout: () -> Void

    @State private var editing: Routine?
    @State private var isCreating = false
    @State private var openTimer: FavoriteTimer?

    private var hasAnyFavorite: Bool {
        !store.favoriteRoutines.isEmpty || !store.state.favoriteTimers.isEmpty
    }

    var body: some View {
        List {
            if !hasAnyFavorite {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "star")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(OG.accent)
                        Text("Sin favoritos")
                            .font(.headline)
                            .foregroundStyle(OG.label)
                        Text("Pulsa la estrella de un entreno para guardarlo aquí y reutilizarlo cuando quieras.")
                            .font(.subheadline)
                            .foregroundStyle(OG.label2)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 220)
                    .padding(24)
                    .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard))
                    .overlay {
                        RoundedRectangle(cornerRadius: OG.radiusCard)
                            .strokeBorder(OG.surface3.opacity(0.75), lineWidth: 0.7)
                    }
                    .ogCardListRow(top: 0, bottom: 8)
                }
            }

            if !store.favoriteRoutines.isEmpty {
                Section("Entrenos") {
                    ForEach(store.favoriteRoutines) { routine in
                        Button {
                            store.startSession(from: routine)
                            onOpenedWorkout()
                        } label: {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(routine.title)
                                        .foregroundStyle(OG.label)
                                    Text(favoriteSubtitle(routine))
                                        .font(.caption)
                                        .foregroundStyle(OG.label2)
                                }
                            } icon: {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(OG.yellow)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            OGSwipeDeleteButton {
                                store.removeFavorite(routine.id)
                            }
                            Button {
                                isCreating = false
                                editing = routine
                            } label: {
                                Image(systemName: "pencil")
                            }
                            .tint(OG.blue)
                            .accessibilityLabel("Editar")
                        }
                    }
                }
            }

            if !store.state.favoriteTimers.isEmpty {
                Section("Temporizadores") {
                    ForEach(store.state.favoriteTimers) { timer in
                        Button {
                            openTimer = timer
                        } label: {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(timer.title)
                                        .foregroundStyle(OG.label)
                                    Text(StandaloneTimerConfig(favorite: timer).shortLabel)
                                        .font(.caption)
                                        .foregroundStyle(OG.label2)
                                }
                            } icon: {
                                Image(systemName: "timer")
                                    .foregroundStyle(OG.orange)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            OGSwipeDeleteButton {
                                store.deleteFavoriteTimer(timer.id)
                            }
                        }
                    }
                }
            }

            Section {
                Button {
                    isCreating = true
                    editing = Routine(
                        title: "Mi favorito",
                        weekday: nil,
                        blocks: [.strength(title: "Bloque 1")],
                        progression: .off,
                        isFavorite: true
                    )
                } label: {
                    Label("Crear entreno favorito", systemImage: "star.circle")
                }
                NavigationLink {
                    StandaloneTimerView(embedsNavigation: false)
                } label: {
                    Label("Crear temporizador favorito", systemImage: "timer")
                }
            } footer: {
                Text("En el temporizador usa «Guardar en favoritos» con la configuración que quieras reutilizar.")
            }
        }
        .ogListChrome()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(OG.bg.ignoresSafeArea())
        .ogPinnedTransparentNav("Favoritos")
        .navigationBarBackButtonHidden(false)
        .navigationDestination(item: $editing) { routine in
            DayEditorView(
                routine: routine,
                mode: .favorite(isNew: isCreating),
                onClose: {
                    editing = nil
                    isCreating = false
                },
                embedsNavigationStack: false,
                usesPageCloseHeader: true
            )
        }
        .navigationDestination(item: $openTimer) { timer in
            StandaloneTimerView(
                embedsNavigation: false,
                config: StandaloneTimerConfig(favorite: timer),
                editingFavoriteId: timer.id
            )
        }
    }

    private func favoriteSubtitle(_ routine: Routine) -> String {
        let blocks = routine.blocks.count
        let moves = routine.blocks.reduce(0) { $0 + $1.exercises.count + $1.movements.filter { !$0.isRest }.count }
        var parts = ["\(blocks) bloque\(blocks == 1 ? "" : "s")", "\(moves) movimiento\(moves == 1 ? "" : "s")"]
        if let day = routine.weekday {
            parts.append("También · \(CalendarHelpers.weekdayName(day))")
        }
        return parts.joined(separator: " · ")
    }
}
