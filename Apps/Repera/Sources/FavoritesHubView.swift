import ReperaDomain
import SwiftUI

/// Crear → Favoritos: entrenos y temporizadores habituales.
struct FavoritesHubView: View {
    @Environment(ReperaStore.self) private var store
    var onOpenedWorkout: () -> Void
    /// Las actividades registradas sin series se reabren desde Comenzar.
    var onOpenSport: ((String) -> Void)? = nil
    /// Guardar un temporizador reutilizado debe abrir su sesión en Inicio.
    var onSavedTimer: ((Date) -> Void)? = nil
    /// Desde el + del calendario se reutiliza planificando para ese día.
    /// Desde el hub general, seleccionar sigue iniciando la sesión.
    var targetDate: Date? = nil
    var onScheduledWorkout: (() -> Void)? = nil

    @State private var editing: Routine?
    @State private var isCreating = false
    @State private var openTimer: FavoriteTimer?
    @State private var startFailureMessage: String?

    private var hasAnyFavorite: Bool {
        !store.favoriteRoutines.isEmpty
            || (targetDate == nil && !store.state.favoriteSportActivities.isEmpty)
            || !store.state.favoriteTimers.isEmpty
    }

    var body: some View {
        List {
            OGScrollablePageTitle("Favoritos").ogScrollingTitleListRow()
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
                Section {
                    ForEach(store.favoriteRoutines) { routine in
                        Button {
                            if let date = targetDate {
                                store.assignRoutine(routine.id, toDate: date)
                                onScheduledWorkout?()
                            } else {
                                if store.state.activeSession != nil {
                                    onOpenedWorkout()
                                } else {
                                    HealthKitStore.shared.lastError = nil
                                    store.startSession(from: routine)
                                    if store.state.activeSession?.routineId == routine.id {
                                        onOpenedWorkout()
                                    } else {
                                        startFailureMessage = HealthKitStore.shared.lastError
                                            ?? "No se ha podido iniciar «\(routine.title)». Comprueba que no haya otra actividad activa."
                                    }
                                }
                            }
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
                        // Derecha: editar la plantilla guardada, nunca iniciar
                        // la sesión ni crear otra plantilla al pulsar el lápiz.
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                isCreating = false
                                editing = routine
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                            }
                            .tint(OG.blue)
                            .accessibilityLabel("Editar plantilla favorita")
                        }
                        // Izquierda: mantener el borrado rojo en el gesto habitual.
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            OGSwipeDeleteButton {
                                store.removeFavorite(routine.id)
                            }
                        }
                    }
                } header: {
                    Text("Entrenos")
                } footer: {
                    if targetDate != nil {
                        Text("Selecciona un favorito para añadir una copia al día elegido sin cambiar la plantilla original.")
                    }
                }
            }

            if targetDate == nil, !store.state.favoriteSportActivities.isEmpty {
                Section("Actividades") {
                    ForEach(store.state.favoriteSportActivities) { activity in
                        Button {
                            onOpenSport?(activity.sportID)
                        } label: {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(activity.title)
                                        .foregroundStyle(OG.label)
                                    Text("Iniciar otra actividad del mismo tipo")
                                        .font(.caption)
                                        .foregroundStyle(OG.label2)
                                }
                            } icon: {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(OG.yellow)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            OGSwipeDeleteButton {
                                store.removeFavoriteSportActivity(activity.id)
                            }
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
                    StandaloneTimerView(embedsNavigation: false, onSaved: onSavedTimer)
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
        .ogScrollingTitleNav()
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
        .alert("No se ha podido iniciar el favorito", isPresented: Binding(
            get: { startFailureMessage != nil },
            set: { if !$0 { startFailureMessage = nil } }
        )) {
            Button("Aceptar", role: .cancel) { startFailureMessage = nil }
        } message: {
            Text(startFailureMessage ?? "")
        }
        .navigationDestination(item: $openTimer) { timer in
            StandaloneTimerView(
                embedsNavigation: false,
                config: StandaloneTimerConfig(favorite: timer),
                editingFavoriteId: timer.id,
                onSaved: onSavedTimer
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
