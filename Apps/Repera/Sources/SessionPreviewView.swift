import ReperaDomain
import SwiftUI

/// Resumen del plan antes de empezar, o gestión de sesión en curso.
/// Topbar: X · ⋯ (editar) · ▶ Play. Título y día, debajo de la barra.
struct SessionPreviewView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(SubscriptionManager.self) private var subscriptions

    var routine: Routine?
    var onClose: () -> Void
    var onStart: () -> Void
    var onContinue: () -> Void
    var onEdit: (Routine) -> Void
    /// Push del ejercicio por una única ruta en RootTabView.
    var onOpenExercise: (UUID) -> Void

    /// Copia de trabajo tras editar; si nil, se usa `routine`.
    @State private var editedSnapshot: Routine?
    @State private var showDeleteConfirm = false
    @State private var startFailureMessage: String?

    private var active: WorkoutSession? { store.state.activeSession }

    /// Rutina viva del store (para reflejar ediciones).
    private var liveRoutine: Routine? {
        if let id = editedSnapshot?.id ?? routine?.id,
           let live = store.state.routines.first(where: { $0.id == id }) {
            return live
        }
        return editedSnapshot ?? routine
    }

    private var dayLabel: String {
        let r = liveRoutine
        let day: String
        if let date = r?.scheduledDate {
            day = CalendarHelpers.weekdayName(CalendarHelpers.isoWeekday(for: date))
        } else if let wd = r?.weekday {
            day = CalendarHelpers.weekdayName(wd)
        } else {
            day = CalendarHelpers.weekdayName(CalendarHelpers.isoWeekday(for: Date()))
        }
        if let minutes = r?.normalizedScheduledTimeMinutes {
            return "\(day) · \(SpanishDate.time(minutesFromMidnight: minutes))"
        }
        return day
    }

    var body: some View {
        List {
            // Título y fecha forman parte del contenido desplazable,
            // nunca de la barra de navegación ni de un safeAreaInset fijo.
            VStack(alignment: .leading, spacing: 8) {
                OGScrollablePageTitle(active != nil ? "Sesión" : "Entreno")
                if active == nil, !dayLabel.isEmpty {
                    Text("Entreno · \(dayLabel)")
                        .font(.system(size: 15))
                        .foregroundStyle(OG.label2)
                }
            }
            .ogScrollingTitleListRow()

            if let active {
                Section {
                    Button {
                        onContinue()
                    } label: {
                        activeBanner(active)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .listRowBackground(OG.surface)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        OGSwipeDeleteButton(accessibilityLabel: "Descartar entreno en curso") {
                            store.endActiveSession(save: false)
                            onClose()
                        }
                    }
                }
            }

            if let routine = liveRoutine {
                Section {
                    if routine.blocks.isEmpty {
                        flatExercises(routine)
                    } else {
                        OGRoutineBlocksList(
                            blocks: routine.blocks,
                            opensExerciseDetail: true,
                            onOpenExercise: onOpenExercise
                        )
                    }
                }
            } else if active == nil {
                Section {
                    Text("No hay plan para hoy.")
                        .foregroundStyle(OG.label2)
                }
            }
        }
        .ogListChrome()
        // La barra nativa contiene exclusivamente cerrar, favorito, editar y Play.
        // El título de la primera fila desaparece al deslizar la lista.
        .ogScrollingTitleNav()
        .task(id: liveRoutine?.id) {
            guard let routine = liveRoutine else { return }
            // Reconstruir fichas oficiales que falten en un catálogo local
            // antiguo; no crear un ejercicio custom ni cambiar la prescripción.
            let known = Set(["burpee to target", "toes to bar"])
            let missing = Set(routine.blocks
                .filter { $0.kind == .wod }
                .flatMap(\.movements)
                .filter { !$0.isRest }
                .compactMap { move -> String? in
                    let key = CrossFitGlossary.normalize(
                        CrossFitGlossary.resolveCatalogName(move.name, notes: move.notes)
                    )
                    guard known.contains(key) else { return nil }
                    // El resolver ya incorpora un fallback empaquetado:
                    // comprobar la presencia REAL de su UUID en el Store
                    // para no omitir la reparación persistente.
                    let match = CrossFitGlossary.catalogExercise(for: move, in: store.state.exercises)
                    guard let match,
                          store.state.exercises.contains(where: {
                              $0.id == match.id && !$0.isCustom && !$0.isCatalogArchived
                          })
                    else { return key }
                    return nil
                })
            guard !missing.isEmpty else { return }
            let packaged = await Task.detached(priority: .utility) {
                Catalog.seed().filter {
                    missing.contains(CrossFitGlossary.normalize($0.name))
                }
            }.value
            guard !Task.isCancelled else { return }
            store.restoreMissingOfficialWODExercises(packaged)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CloseToolbarButton(action: onClose, large: false)
            }
            if active == nil, liveRoutine != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        guard let routine = liveRoutine else { return }
                        if store.state.routines.contains(where: { $0.id == routine.id }) {
                            guard store.setRoutineFavorite(
                                routine.id, isFavorite: !routine.isFavorite
                            ) else {
                                presentFavoriteLimitPaywall()
                                return
                            }
                        } else if !routine.isFavorite {
                            guard let saved = store.saveAsFavorite(routine) else {
                                presentFavoriteLimitPaywall()
                                return
                            }
                            editedSnapshot = saved
                        }
                    } label: {
                        Image(systemName: liveRoutine?.isFavorite == true ? "star.fill" : "star")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(liveRoutine?.isFavorite == true ? OG.yellow : OG.label)
                    }
                    .accessibilityLabel(liveRoutine?.isFavorite == true ? "Quitar de favoritos" : "Guardar en favoritos")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            if let routine = liveRoutine {
                                onEdit(routine)
                            }
                        } label: {
                            Label("Editar", systemImage: "pencil")
                        }
                        Divider()
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Borrar entreno", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(OG.label)
                            .frame(width: 36, height: 36)
                            .contentShape(Circle())
                    }
                    .accessibilityLabel("Más opciones")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        startVisibleRoutine()
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(OG.accent)
                    .accessibilityLabel("Comenzar")
                }
            }
        }
        .alert("No se ha podido iniciar el entreno", isPresented: Binding(
            get: { startFailureMessage != nil },
            set: { if !$0 { startFailureMessage = nil } }
        )) {
            Button("Aceptar", role: .cancel) { startFailureMessage = nil }
        } message: {
            Text(startFailureMessage ?? "")
        }
        .sheet(isPresented: $showDeleteConfirm) {
            OGConfirmSheet(
                title: "¿Borrar entreno?",
                message: deleteConfirmMessage,
                confirmTitle: "Borrar entreno",
                onConfirm: {
                    showDeleteConfirm = false
                    deleteCurrentEntreno()
                },
                onCancel: { showDeleteConfirm = false }
            )
        }
    }

    /// Usar la rutina que se está viendo (incluida una copia de Favoritos)
    /// y confirmar el ID real de la sesión creada antes de navegar. Así
    /// Play nunca se queda silencioso cuando Salud/Watch u otra actividad
    /// bloquea el inicio.
    private func startVisibleRoutine() {
        guard let routine = liveRoutine else { return }
        if store.state.activeSession != nil {
            onContinue()
            return
        }
        HealthKitStore.shared.lastError = nil
        store.startSession(from: routine)
        guard let started = store.state.activeSession,
              started.routineId == routine.id else {
            startFailureMessage = HealthKitStore.shared.lastError
                ?? "No se ha podido iniciar «\(routine.title)». Comprueba que no haya otra actividad activa y vuelve a intentarlo."
            return
        }
        onStart()
    }

    /// Una estrella solo confirma éxito cuando existe una plantilla persistida.
    /// Cuando la versión Gratis alcanza su límite, abrir el paywall igual
    /// que el editor en vez de mostrar un favorito que nunca se guardó.
    private func presentFavoriteLimitPaywall() {
        let decision = store.lastAccessDenial
            ?? subscriptions.canCreateLibraryRoutine(isNew: true)
        subscriptions.presentPaywall(decision.paywallContext, feature: .unlimitedRoutines)
    }

    private var deleteConfirmMessage: String {
        guard let routine = liveRoutine else {
            return "No se puede deshacer."
        }
        return routine.isOneOff
            ? "Se eliminará «\(routine.title)» de este día."
            : "Se quitará «\(routine.title)» de este día. La plantilla seguirá en Rutinas."
    }

    private func deleteCurrentEntreno() {
        guard let routine = liveRoutine else { return }
        if routine.isOneOff {
            store.deleteRoutine(routine.id)
        } else {
            store.assignRoutine(routine.id, toWeekday: nil)
        }
        editedSnapshot = nil
        onClose()
    }

    private func activeBanner(_ session: WorkoutSession) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(OG.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text("Sesión en curso")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(OG.orange)
                Text(session.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(OG.label)
                if let current = session.currentExercise {
                    Text("Ahora: \(current.exercise.name) · \(session.progressLabel)")
                        .font(.system(size: 13))
                        .foregroundStyle(OG.label2)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(OG.label3)
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func flatExercises(_ routine: Routine) -> some View {
        let synthetic = RoutineBlock.strength(title: "Ejercicios", exercises: routine.exercises)
        OGRoutineBlockCard(
            block: synthetic,
            opensExerciseDetail: true,
            onOpenExercise: onOpenExercise
        )
            .ogCardListRow(top: 0, bottom: 8)
    }
}
