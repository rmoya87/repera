import ReperaDomain
import SwiftUI

/// Resumen del plan antes de empezar, o gestión de sesión en curso.
/// Top bar: X · Entreno · día debajo · ⋯ (editar / apuntar) · ▶ comenzar.
struct SessionPreviewView: View {
    @Environment(ReperaStore.self) private var store

    var routine: Routine?
    var onClose: () -> Void
    var onStart: () -> Void
    var onContinue: () -> Void
    var onEdit: (Routine) -> Void

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
            if active == nil, !dayLabel.isEmpty {
                Section {
                    Text(dayLabel)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(OG.label2)
                        .ogListPageHeaderRow()
                }
            }

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
                } footer: {
                    Text("Toca para continuar · desliza para eliminar (no se guarda)")
                }
            }

            if let routine = liveRoutine {
                Section {
                    if routine.blocks.isEmpty {
                        flatExercises(routine)
                    } else {
                        OGRoutineBlocksList(blocks: routine.blocks)
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
        .ogPinnedTransparentNav(active != nil ? "Sesión" : "Entreno")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CloseToolbarButton(action: onClose, large: false)
            }
            if active == nil, liveRoutine != nil {
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
                    OGToolbarGlassButton(
                        systemName: "pencil",
                        accessibilityLabel: "Editar o apuntar",
                        tint: OG.accent
                    ) {
                        if let routine = liveRoutine {
                            onEdit(routine)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    OGToolbarGlassButton(
                        systemName: "play.fill",
                        accessibilityLabel: "Comenzar",
                        tint: OG.accent
                    ) {
                        guard let routine = liveRoutine else { return }
                        store.startSession(from: routine)
                        onStart()
                    }
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
        OGRoutineBlockCard(block: synthetic)
            .ogCardListRow(top: 0, bottom: 8)
    }
}
