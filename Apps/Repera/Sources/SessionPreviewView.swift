import ReperaDomain
import SwiftUI

/// Resumen del plan antes de empezar, o gestión de sesión en curso.
/// Topbar: X · ⋯ (editar) · ▶ Play. Título y día, debajo de la barra.
struct SessionPreviewView: View {
    @Environment(ReperaStore.self) private var store

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
        // Barra nativa solo para acciones: no fusionar "Entreno" con la X.
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        // Fondo estable (negro en noche, lienzo claro de día).
        // El material «automatic» del nav variaba de gris al hacer scroll.
        .toolbarBackground(OG.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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
        // Cabecera explícita bajo la barra (y sobre la lista), nunca detrás
        // del glass o dentro de la cápsula que contiene el botón Cerrar.
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(active != nil ? "Sesión" : "Entreno")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(OG.label)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .accessibilityAddTraits(.isHeader)
                if active == nil, !dayLabel.isEmpty {
                    Text("Entreno · \(dayLabel)")
                        .font(.system(size: 15))
                        .foregroundStyle(OG.label2)
                }
            }
            .frame(maxWidth: OG.contentColumnMaxWidth, alignment: .leading)
            .padding(.horizontal, OG.pad)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(OG.bg)
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
                            store.setRoutineFavorite(routine.id, isFavorite: !routine.isFavorite)
                        } else if !routine.isFavorite {
                            _ = store.saveAsFavorite(routine)
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
                        guard let routine = liveRoutine else { return }
                        if store.hasActiveSession {
                            // Continuar la sesión activa sin sustituirla por otra.
                            onStart()
                            return
                        }
                        store.startSession(from: routine)
                        if store.hasActiveSession { onStart() }
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
