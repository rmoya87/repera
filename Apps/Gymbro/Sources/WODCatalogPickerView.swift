import GymbroDomain
import SwiftUI

/// Lista de WODs conocidos + detalle (movimientos, tiempo medio, músculos).
struct WODCatalogPickerView: View {
    @Environment(\.dismiss) private var dismiss
    var onPick: (WODTemplate) -> Void

    @State private var query = ""
    @State private var selected: WODTemplate?

    private var templates: [WODTemplate] {
        CatalogWODs.search(query)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(templates) { template in
                    Button {
                        selected = template
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(OG.label)
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
                            if let typical = template.typicalLabel {
                                Text(typical)
                                    .font(.system(size: 13, weight: .semibold).monospacedDigit())
                                    .foregroundStyle(OG.label2)
                            }
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(OG.label3)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .ogListChrome()
            .searchable(text: $query, prompt: "Buscar WOD")
            .navigationTitle("Elegir WOD")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseToolbarButton { dismiss() }
                }
            }
            .navigationDestination(item: $selected) { template in
                WODTemplateDetailView(template: template) {
                    onPick(template)
                    dismiss()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct WODTemplateDetailView: View {
    @Environment(GymbroStore.self) private var store
    var template: WODTemplate
    /// Picker de Diario: botón «Usar este WOD».
    var onUse: (() -> Void)? = nil
    /// Historial del usuario (progresión) — opcional.
    var history: [WODBlockResult] = []
    /// Biblioteca: play / apuntar / favorito en topbar.
    var showSessionActions: Bool = false
    var onOpenedWorkout: (() -> Void)? = nil

    @State private var logRoutine: Routine?

    private var isFavorite: Bool {
        store.isWODTemplateFavorite(template.id)
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Formato", value: template.formatLabel)
                if let cap = template.timeCapMinutes {
                    LabeledContent("Time cap", value: "\(cap)'")
                }
                if let typical = template.typicalLabel {
                    LabeledContent("Tiempo típico", value: typical)
                }
                if !template.muscles.isEmpty {
                    LabeledContent("Músculos", value: template.musclesLabel)
                }
            } footer: {
                if let notes = template.notes, !notes.isEmpty {
                    Text(notes)
                }
            }

            Section("Movimientos") {
                ForEach(template.movements) { move in
                    HStack(spacing: 12) {
                        if move.isRest {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(OG.surface2)
                                Image(systemName: "pause.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(OG.label3)
                            }
                            .frame(width: 40, height: 40)
                        } else {
                            ExerciseThumb(exercise: resolvedExercise(for: move), size: 40)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(move.isRest ? "Descanso" : resolvedExercise(for: move).name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(OG.label)
                            Text(move.summaryLine)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            if !history.isEmpty {
                Section("Tu progresión") {
                    ForEach(history) { result in
                        HStack {
                            Text(result.summaryLabel)
                                .font(.system(size: 16, weight: .semibold).monospacedDigit())
                            Spacer()
                            if let format = result.format {
                                Text(format.displayName)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(OG.label3)
                            }
                        }
                    }
                }
            }

            if let onUse {
                Section {
                    Button {
                        onUse()
                    } label: {
                        Text("Usar este WOD")
                            .font(.system(size: 17, weight: .bold))
                            .frame(maxWidth: .infinity)
                    }
                    .tint(OG.accent)
                }
            }
        }
        .ogListChrome()
        .ogPinnedTransparentNav(template.name)
        .toolbar {
            if showSessionActions {
                ToolbarItem(placement: .topBarTrailing) {
                    OGToolbarGlassButton(
                        systemName: isFavorite ? "star.fill" : "star",
                        accessibilityLabel: isFavorite ? "Quitar de favoritos" : "Favorito",
                        tint: isFavorite ? OG.yellow : OG.label
                    ) {
                        store.toggleWODTemplateFavorite(template.id)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    OGToolbarGlassButton(
                        systemName: "plus",
                        accessibilityLabel: "Apuntar resultado",
                        tint: OG.accent
                    ) {
                        logRoutine = store.routineFromWODTemplate(template)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    OGToolbarGlassButton(
                        systemName: "play.fill",
                        accessibilityLabel: "Empezar ahora",
                        tint: OG.accent
                    ) {
                        playNow()
                    }
                }
            }
        }
        .navigationDestination(item: $logRoutine) { routine in
            LogFinalResultsView(routine: routine, onSaved: { logRoutine = nil })
        }
        .onAppear {
            let thumbs = template.movements
                .filter { !$0.isRest }
                .map { resolvedExercise(for: $0) }
            ExerciseArt.prefetchThumbs(for: thumbs, pointSize: 40, limit: 24)
        }
        .preferredColorScheme(.dark)
    }

    private func playNow() {
        let routine = store.routineFromWODTemplate(template)
        store.startSession(from: routine)
        onOpenedWorkout?()
    }

    private func resolvedExercise(for move: WODMovement) -> Exercise {
        if let id = move.exerciseId, let ex = store.state.exercises.first(where: { $0.id == id }) {
            return ex
        }
        let canonical = CrossFitGlossary.canonicalName(for: move.name)
        if let match = store.state.exercises.first(where: {
            $0.name.compare(canonical, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
                || $0.name.compare(move.name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }) {
            return match
        }
        return Exercise(name: canonical, muscleGroup: "WOD", isCustom: true)
    }
}
