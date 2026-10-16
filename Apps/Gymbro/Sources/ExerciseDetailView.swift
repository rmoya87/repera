import GymbroDomain
import SwiftUI

/// Ficha de ejercicio: tags, descripción, añadir al día, placas, 1RM, progreso e historial.
struct ExerciseDetailView: View {
    @Environment(GymbroStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let exerciseId: UUID

    var onOpenedWorkout: (() -> Void)? = nil

    @State private var estimateWeight: Double = 20
    @State private var estimateReps: Int = 5
    @State private var showQuickLog = false
    @State private var suggestPercent: Double = 70

    private var exercise: Exercise? {
        store.state.exercises.first { $0.id == exerciseId }
    }

    private var loadPref: ExerciseLoadPreference {
        store.loadPreference(for: exerciseId)
    }

    private var estimateOneRM: Double {
        PlateMath.epleyOneRM(weightKg: estimateWeight, reps: estimateReps)
    }

    var body: some View {
        Group {
            if let exercise {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        OGBackPageHeader(title: exercise.name, onBack: { dismiss() }) {
                            HStack(spacing: 8) {
                                OGToolbarGlassButton(
                                    systemName: exercise.isFavorite ? "star.fill" : "star",
                                    accessibilityLabel: exercise.isFavorite ? "Quitar de favoritos" : "Favorito",
                                    tint: exercise.isFavorite ? OG.yellow : OG.label,
                                    appliesGlass: true
                                ) {
                                    store.toggleFavorite(exerciseId)
                                }
                                OGToolbarGlassButton(
                                    systemName: "plus",
                                    accessibilityLabel: "Apuntar series",
                                    tint: .white,
                                    appliesGlass: true,
                                    glassTint: OG.accent
                                ) {
                                    showQuickLog = true
                                }
                            }
                        }
                        .padding(.horizontal, OG.pad)

                        // Imagen edge-to-edge; técnica solo aquí (no repetir abajo).
                        ExerciseArtView(exercise: exercise, showStepCaptions: true)

                        VStack(alignment: .leading, spacing: 12) {
                            tagChips(exercise)

                            OGCard { suggestedLoadSection(exercise) }

                            OGCard { plateLoadingSection }

                            OGCard { estimatedOneRMSection }

                            NavigationLink {
                                ExerciseProgressView(exerciseId: exercise.id)
                            } label: {
                                OGCard {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Progreso del ejercicio")
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundStyle(OG.label)
                                            Text("Top set · 1RM · esfuerzo · sesiones")
                                                .font(.system(size: 12))
                                                .foregroundStyle(OG.label2)
                                        }
                                        Spacer()
                                        Image(systemName: "chart.xyaxis.line")
                                            .foregroundStyle(OG.blue)
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(OG.label3)
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            historySection(exercise)
                        }
                        .padding(.horizontal, OG.pad)
                    }
                    .padding(.top, 0)
                    .padding(.bottom, 28)
                }
                .background(OG.bg)
                .ogContentTitleNav()
                .navigationBarBackButtonHidden(true)
                .onAppear {
                    seedEstimateFromHistory(exercise)
                }
                .sheet(isPresented: $showQuickLog) {
                    QuickLogSheet(exercise: exercise)
                }
            } else {
                ContentUnavailableView("Ejercicio no encontrado", systemImage: "questionmark")
            }
        }
    }

    @ViewBuilder
    private func suggestedLoadSection(_ exercise: Exercise) -> some View {
        let hist = StatsEngine.history(for: exercise.id, workouts: store.state.workouts)
        let oneRM = hist.estimatedOneRM
        VStack(alignment: .leading, spacing: 10) {
            OGCardSectionTitle(title: "Carga sugerida (% → kg)")
            if let oneRM, oneRM > 0 {
                let increment = store.state.settings.weightIncrementKg
                let kg = LoadSuggestion.weightKg(
                    oneRM: oneRM,
                    percent: suggestPercent,
                    roundTo: increment
                )
                HStack {
                    Text("\(Int(suggestPercent))% e1RM")
                        .foregroundStyle(OG.label2)
                    Spacer()
                    Text("\(kg.formatted(.number.precision(.fractionLength(0...1)))) kg")
                        .font(.system(size: 20, weight: .semibold).monospacedDigit())
                        .foregroundStyle(OG.label)
                }
                Slider(value: $suggestPercent, in: 50...95, step: 5)
                    .tint(OG.accent)
                Text("e1RM ≈ \(oneRM.formatted(.number.precision(.fractionLength(0...1)))) kg")
                    .font(.caption)
                    .foregroundStyle(OG.label3)
                if loadPref.mode != .off {
                    let solution = PlateMath.solve(
                        targetKg: kg,
                        baseKg: loadPref.baseWeightKg,
                        mode: loadPref.mode,
                        availablePlatesKg: store.state.settings.ownedPlatesKg
                    )
                    if let compact = solution.perSideCompact {
                        Text(compact)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(OG.label2)
                    }
                }
            } else {
                Text("Sin historial de peso aún. Apunta series para estimar 1RM.")
                    .font(.footnote)
                    .foregroundStyle(OG.label2)
            }
        }
    }

    // MARK: - Tags

    @ViewBuilder
    private func tagChips(_ exercise: Exercise) -> some View {
        let tags = detailTags(exercise)
        if !tags.isEmpty {
            OGCard {
                VStack(alignment: .leading, spacing: 10) {
                    OGCardSectionTitle(title: "Músculos y equipo")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(tags.enumerated()), id: \.offset) { index, tag in
                                HStack(spacing: 5) {
                                    if let icon = tag.icon {
                                        Image(systemName: icon)
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    Text(tag.label)
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundStyle(index == 0 ? OG.onAccent : OG.label)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(index == 0 ? OG.accent : OG.surface2, in: Capsule())
                            }
                        }
                    }
                }
            }
        }
    }

    private struct DetailTag {
        var label: String
        var icon: String?
    }

    private func detailTags(_ exercise: Exercise) -> [DetailTag] {
        var tags: [DetailTag] = []
        var seen = Set<String>()
        func add(_ raw: String?, icon: String? = nil) {
            guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            let label = LocalizedMuscle.es(raw)
            let key = label.lowercased()
            guard !seen.contains(key) else { return }
            seen.insert(key)
            tags.append(DetailTag(label: label, icon: icon))
        }
        add(exercise.bodyPart)
        add(exercise.targetMuscle ?? exercise.muscleGroup, icon: "figure.strengthtraining.traditional")
        if let eq = exercise.equipment, !eq.isEmpty {
            add(eq, icon: "dumbbell.fill")
        }
        for secondary in exercise.secondaryMuscles {
            add(secondary)
        }
        return tags
    }

    // MARK: - Plate loading

    private var plateLoadingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            OGCardSectionTitle(title: "Carga de discos")

            Picker("Modo", selection: Binding(
                get: { loadPref.mode },
                set: { newMode in
                    var pref = loadPref
                    pref.mode = newMode
                    store.setLoadPreference(pref, for: exerciseId)
                }
            )) {
                ForEach(PlateLoadMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text(plateModeCaption(loadPref.mode))
                .font(.system(size: 12))
                .foregroundStyle(OG.label3)

            if loadPref.mode != .off {
                Text("Peso base (kg)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(OG.label2)
                    .frame(maxWidth: .infinity)

                detailStepper(
                    valueLabel: String(format: "%g", loadPref.baseWeightKg),
                    onMinus: {
                        var pref = loadPref
                        pref.baseWeightKg = max(0, ((pref.baseWeightKg - 1.25) * 100).rounded() / 100)
                        store.setLoadPreference(pref, for: exerciseId)
                    },
                    onPlus: {
                        var pref = loadPref
                        pref.baseWeightKg = ((pref.baseWeightKg + 1.25) * 100).rounded() / 100
                        store.setLoadPreference(pref, for: exerciseId)
                    }
                )

                Text(plateBaseFooter(loadPref.mode))
                    .font(.system(size: 12))
                    .foregroundStyle(OG.label3)
            }
        }
    }

    private func plateModeCaption(_ mode: PlateLoadMode) -> String {
        switch mode {
        case .perSide:
            return "Barra olímpica u otra carga simétrica: mismos discos a cada lado."
        case .singleStack:
            return "Una pila: cinturón, landmine, máquina de discos o trineo."
        case .off:
            return "Sin línea de discos bajo cada serie."
        }
    }

    private func plateBaseFooter(_ mode: PlateLoadMode) -> String {
        switch mode {
        case .perSide:
            return "Peso de la barra antes de los discos. Sigues registrando el total; esto solo alimenta la línea de discos."
        case .singleStack:
            return "La máquina o el trineo, antes de poner discos. 0 si es todo discos. Sigues registrando el total."
        case .off:
            return ""
        }
    }

    // MARK: - 1RM

    private var estimatedOneRMSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            OGCardSectionTitle(title: "1RM estimado")

            HStack(spacing: 12) {
                VStack(spacing: 6) {
                    Text("Peso (kg)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(OG.label2)
                    detailStepper(
                        valueLabel: String(format: "%g", estimateWeight),
                        onMinus: { estimateWeight = max(0, ((estimateWeight - store.state.settings.weightIncrementKg) * 10).rounded() / 10) },
                        onPlus: { estimateWeight = ((estimateWeight + store.state.settings.weightIncrementKg) * 10).rounded() / 10 }
                    )
                }
                VStack(spacing: 6) {
                    Text("Reps")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(OG.label2)
                    detailStepper(
                        valueLabel: "\(estimateReps)",
                        onMinus: { estimateReps = max(1, estimateReps - 1) },
                        onPlus: { estimateReps = min(30, estimateReps + 1) }
                    )
                }
            }

            HStack {
                Text("Estimación")
                    .font(.system(size: 15))
                    .foregroundStyle(OG.label2)
                Spacer()
                Text("\(estimateOneRM.formatted(.number.precision(.fractionLength(0...1)))) kg")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(OG.accent)
            }
            .padding(.top, 4)

            Text("Fórmula de Epley: calculado a partir de una serie, no un máximo testado.")
                .font(.system(size: 12))
                .foregroundStyle(OG.label3)
        }
    }

    private func detailStepper(
        valueLabel: String,
        onMinus: @escaping () -> Void,
        onPlus: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 0) {
            Button(action: onMinus) {
                Image(systemName: "minus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(OG.label2)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Text(valueLabel)
                .font(.system(size: 18, weight: .semibold).monospacedDigit())
                .foregroundStyle(OG.label)
                .frame(maxWidth: .infinity)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Button(action: onPlus) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(OG.label2)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func seedEstimateFromHistory(_ exercise: Exercise) {
        let h = StatsEngine.history(for: exercise.id, workouts: store.state.workouts)
        if let w = h.lastWeightKg ?? h.maxWeightKg {
            estimateWeight = w
        }
        if let r = h.lastReps ?? h.repsAtMaxWeight {
            estimateReps = max(1, r)
        }
    }

    // MARK: - History

    private func historySection(_ exercise: Exercise) -> some View {
        let h = StatsEngine.history(for: exercise.id, workouts: store.state.workouts)
        return OGCard {
            VStack(alignment: .leading, spacing: 10) {
                OGCardSectionTitle(title: "Tu historial")
                if !h.hasData {
                    Text("Cuando lo entrenes, verás máximos y la última sesión aquí.")
                        .font(.system(size: 14))
                        .foregroundStyle(OG.label2)
                } else {
                    HStack(spacing: 10) {
                        histTile("Máx.", h.maxWeightKg.map { "\($0.formatted(.number.precision(.fractionLength(0)))) kg" } ?? "—")
                        histTile("Reps máx.", h.bestReps.map(String.init) ?? "—")
                        histTile("Veces", "\(h.timesPerformed)")
                    }
                    if let w = h.maxWeightKg, let r = h.repsAtMaxWeight {
                        labeled("Mejor serie", "\(r) reps × \(w.formatted(.number.precision(.fractionLength(1)))) kg", tint: OG.accent)
                    }
                    if let e1 = h.estimatedOneRM {
                        labeled("1RM est.", "\(e1.formatted(.number.precision(.fractionLength(1)))) kg", tint: OG.yellow)
                    }
                    if let date = h.lastDate {
                        let last = [
                            h.lastReps.map { "\($0) reps" },
                            h.lastWeightKg.map { "\($0.formatted(.number.precision(.fractionLength(1)))) kg" },
                        ].compactMap { $0 }.joined(separator: " · ")
                        labeled("Última vez", "\(SpanishDate.short(date))" + (last.isEmpty ? "" : " · \(last)"), tint: OG.label)
                    }
                }
            }
        }
    }

    private func histTile(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(OG.label)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(OG.label3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func labeled(_ title: String, _ value: String, tint: Color) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(OG.label2)
                .frame(width: 96, alignment: .leading)
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(tint == OG.label2 ? OG.label : tint)
        }
    }
}

struct FlowChips: View {
    var items: [String]
    var body: some View {
        FlexibleChipWrap(items: Array(Set(items)).sorted())
    }
}

struct FlexibleChipWrap: View {
    var items: [String]
    var body: some View {
        let rows = items.chunked(into: 3)
        return VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { item in
                        Text(item)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(OG.label)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(OG.surface2, in: Capsule())
                    }
                }
            }
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}

struct MuscleImpactDiagram: View {
    var primaries: [String]
    var secondaries: [String]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(zoneColor("chest").opacity(0.35))
                    .frame(width: w * 0.42, height: h * 0.38)
                    .position(x: w * 0.5, y: h * 0.38)
                Capsule()
                    .fill(zoneColor("shoulders").opacity(0.55))
                    .frame(width: w * 0.62, height: h * 0.10)
                    .position(x: w * 0.5, y: h * 0.22)
                Capsule()
                    .fill(zoneColor("arms").opacity(0.5))
                    .frame(width: w * 0.10, height: h * 0.34)
                    .position(x: w * 0.22, y: h * 0.42)
                Capsule()
                    .fill(zoneColor("arms").opacity(0.5))
                    .frame(width: w * 0.10, height: h * 0.34)
                    .position(x: w * 0.78, y: h * 0.42)
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(zoneColor("core").opacity(0.4))
                    .frame(width: w * 0.28, height: h * 0.16)
                    .position(x: w * 0.5, y: h * 0.58)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(zoneColor("legs").opacity(0.45))
                    .frame(width: w * 0.38, height: h * 0.28)
                    .position(x: w * 0.5, y: h * 0.78)
            }
        }
    }

    private func zoneColor(_ zone: String) -> Color {
        let keys = (primaries + secondaries).map { $0.lowercased() }
        let hit = keys.contains { $0.contains(zone) || zone.contains($0) }
            || keys.contains { LocalizedMuscle.es($0).lowercased().contains(zone) }
        return hit ? OG.accent : OG.surface3
    }
}

enum LocalizedMuscle {
    static func es(_ raw: String) -> String {
        let map: [String: String] = [
            "pectorals": "Pectorales",
            "chest": "Pecho",
            "full body": "Cuerpo completo",
            "lats": "Dorsales",
            "upper back": "Espalda alta",
            "traps": "Trapecios",
            "delts": "Deltoides",
            "deltoids": "Deltoides",
            "shoulders": "Hombros",
            "biceps": "Bíceps",
            "triceps": "Tríceps",
            "forearms": "Antebrazos",
            "forearm": "Antebrazos",
            "abs": "Abdominales",
            "core": "Core",
            "waist": "Cintura",
            "obliques": "Oblicuos",
            "quads": "Cuádriceps",
            "quadriceps": "Cuádriceps",
            "hamstrings": "Isquios",
            "hamstring": "Isquios",
            "glutes": "Glúteos",
            "gluteal": "Glúteos",
            "calves": "Gemelos",
            "adductors": "Aductores",
            "abductors": "Abductores",
            "hip flexors": "Flexores de cadera",
            "hip-flexors": "Flexores de cadera",
            "lower back": "Lumbar",
            "grip": "Agarre",
            "cardiovascular system": "Cardio",
            "cardio": "Cardio",
            "body weight": "Peso corporal",
            "bodyweight": "Peso corporal",
            "barbell": "Barra",
            "dumbbell": "Mancuernas",
            "cable": "Polea",
            "machine": "Máquina",
            "body only": "Peso corporal",
            "assisted": "Asistido",
        ]
        let key = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return map[key] ?? raw.capitalized
    }
}
