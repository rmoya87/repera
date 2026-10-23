import ReperaDomain
import SwiftUI

/// Ficha de ejercicio: tags, 1RM, carga sugerida y evolución (historial + gráfica).
struct ExerciseDetailView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(SubscriptionManager.self) private var subscriptions
    let exerciseId: UUID
    /// Entreno desde el que se abrió la ficha (para «Esta sesión» vs anteriores).
    var highlightSessionId: UUID? = nil
    /// Instancia concreta cuando el mismo ejercicio figura en varios bloques.
    var highlightExerciseInstanceId: UUID? = nil

    var onOpenedWorkout: (() -> Void)? = nil

    @State private var showQuickLog = false
    @State private var suggestPercent: Double = 70

    private var exercise: Exercise? {
        store.resolvedCatalogExercise(id: exerciseId)
    }

    private var resolvedId: UUID {
        exercise?.id ?? exerciseId
    }

    private var loadPref: ExerciseLoadPreference {
        store.loadPreference(for: resolvedId)
    }

    var body: some View {
        Group {
            if let exercise {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Imagen edge-to-edge; técnica solo aquí (no repetir abajo).
                        ExerciseArtView(exercise: exercise, showStepCaptions: true)

                        VStack(alignment: .leading, spacing: 12) {
                            muscleEquipmentBlock(exercise)

                            if let highlightSessionId {
                                ExerciseThisSessionCard(
                                    exerciseId: resolvedId,
                                    highlightSessionId: highlightSessionId,
                                    highlightExerciseInstanceId: highlightExerciseInstanceId
                                )
                            }

                            if exercise.sportTag != "Movilidad" {
                                VStack(alignment: .leading, spacing: 8) {
                                    OGCardSectionTitle(title: "Carga sugerida")
                                    OGCard { suggestedLoadSection(exercise) }
                                }
                            }

                            if subscriptions.isPro {
                                ExerciseEvolutionPanel(
                                    exerciseId: resolvedId,
                                    highlightSessionId: highlightSessionId
                                )
                            } else {
                                FreeExerciseSummaryCard(
                                    exerciseId: resolvedId,
                                    highlightSessionId: highlightSessionId
                                )
                            }
                        }
                        .padding(.horizontal, OG.pad)
                    }
                    .padding(.top, 0)
                    .padding(.bottom, 28)
                    .ogReadableColumn()
                }
                .background(OG.bg.ignoresSafeArea())
                .ogPinnedTransparentNav(exercise.name)
                .ogDiaryTransparentNav()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        OGToolbarGlassButton(
                            systemName: exercise.isFavorite ? "star.fill" : "star",
                            accessibilityLabel: exercise.isFavorite ? "Quitar de favoritos" : "Favorito",
                            tint: exercise.isFavorite ? OG.yellow : OG.label
                        ) {
                            store.toggleFavorite(resolvedId)
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        OGToolbarGlassButton(
                            systemName: "plus",
                            accessibilityLabel: "Apuntar series",
                            tint: OG.accent
                        ) {
                            showQuickLog = true
                        }
                    }
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
        // 1RM solo desde Evolución (Tope) o e1RM historial — sin duplicar el editor aquí.
        let hist = store.cachedHistory(for: exercise.id)
        let tested = loadPref.testedOneRMKg.flatMap { $0 > 0 ? $0 : nil }
        let estimated = hist.estimatedOneRM.flatMap { $0 > 0 ? $0 : nil }
        let oneRM = tested ?? estimated
        let source = tested != nil ? "1RM" : (estimated != nil ? "e1RM" : nil)
        let increment = store.state.settings.weightIncrementKg

        VStack(alignment: .leading, spacing: 12) {
            if let oneRM {
                let kg = LoadSuggestion.weightKg(
                    oneRM: oneRM,
                    percent: suggestPercent,
                    roundTo: increment
                )
                HStack(alignment: .firstTextBaseline) {
                    Text("\(Int(suggestPercent))%")
                        .font(.system(size: 28, weight: .bold).monospacedDigit())
                        .foregroundStyle(OG.accent)
                    Text(source ?? "")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(OG.label2)
                    Spacer()
                    Text("\(kg.formatted(.number.precision(.fractionLength(0...1)))) kg")
                        .font(.system(size: 28, weight: .bold).monospacedDigit())
                        .foregroundStyle(OG.label)
                }

                Slider(value: $suggestPercent, in: 50...95, step: 5)
                    .tint(OG.accent)

                Text("Pasos de 5% · sobre \(source ?? "1RM") \(oneRM.formatted(.number.precision(.fractionLength(0...1)))) kg")
                    .font(.caption)
                    .foregroundStyle(OG.label3)
            } else {
                Text("Fija el Tope 1RM en Evolución (o entrena con peso) para calcular kg.")
                    .font(.footnote)
                    .foregroundStyle(OG.label2)
            }
        }
    }

    // MARK: - Músculos / equipo

    @ViewBuilder
    private func muscleEquipmentBlock(_ exercise: Exercise) -> some View {
        let meta = detailMeta(exercise)
        if meta.hasContent {
            VStack(alignment: .leading, spacing: 8) {
                OGCardSectionTitle(title: "Músculos y equipo")
                OGCard {
                    VStack(alignment: .leading, spacing: 14) {
                        metaRow(title: "Músculo", icon: "figure.strengthtraining.traditional") {
                            chipFlow {
                                metaChip(meta.primary, emphasized: true)
                            }
                        }

                        if !meta.secondaries.isEmpty {
                            metaRow(title: "También", icon: nil) {
                                chipFlow {
                                    ForEach(meta.secondaries, id: \.self) { label in
                                        metaChip(label)
                                    }
                                }
                            }
                        }

                        if let equipment = meta.equipment {
                            metaRow(title: "Equipo", icon: "dumbbell.fill") {
                                chipFlow {
                                    metaChip(equipment, icon: "dumbbell.fill")
                                }
                            }
                        }

                        if let sport = meta.sport {
                            metaRow(title: "Deporte", icon: "sportscourt") {
                                chipFlow {
                                    metaChip(sport, icon: "sportscourt")
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    /// El layout necesita ancho máximo del padre para llenar la fila.
    @ViewBuilder
    private func chipFlow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        OGFlowLayout(spacing: 8) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func metaRow<Content: View>(
        title: String,
        icon: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.4)
            }
            .foregroundStyle(OG.label3)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metaChip(_ label: String, icon: String? = nil, emphasized: Bool = false) -> some View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
            }
            Text(label)
                .font(.system(size: emphasized ? 14 : 13, weight: .semibold))
        }
        .foregroundStyle(emphasized ? OG.onAccent : OG.label)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(emphasized ? OG.accent : OG.surface2, in: Capsule())
    }

    private struct DetailMeta {
        var primary: String
        var secondaries: [String]
        var equipment: String?
        var sport: String?
        var hasContent: Bool { !primary.isEmpty }
    }

    private func detailMeta(_ exercise: Exercise) -> DetailMeta {
        let primary = LocalizedMuscle.es(exercise.targetMuscle ?? exercise.muscleGroup)
        var seen: Set<String> = [primary.lowercased()]
        var secondaries: [String] = []
        for raw in exercise.secondaryMuscles {
            let label = LocalizedMuscle.es(raw)
            let key = label.lowercased()
            guard !key.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key)
            secondaries.append(label)
        }
        if let body = exercise.bodyPart, !body.isEmpty {
            let label = LocalizedMuscle.es(body)
            let key = label.lowercased()
            if !seen.contains(key) {
                seen.insert(key)
                secondaries.insert(label, at: 0)
            }
        }
        let equipment = exercise.equipment.flatMap { raw -> String? in
            let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : LocalizedMuscle.es(t)
        }
        let sport = exercise.sportTag.flatMap { raw -> String? in
            let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        }
        return DetailMeta(
            primary: primary,
            secondaries: secondaries,
            equipment: equipment,
            sport: sport
        )
    }

}

struct FlowChips: View {
    var items: [String]
    var body: some View {
        OGFlowLayout(spacing: 8) {
            ForEach(Array(Set(items)).sorted(), id: \.self) { item in
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

/// Chips en fila: usa todo el ancho propuesto; salta de línea solo al llenarlo.
struct OGFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let result = arrange(maxWidth: maxWidth, subviews: subviews)
        // Si el padre propone ancho concreto, lo reclamamos entero para no “encoger” la card.
        let width = maxWidth.isFinite ? maxWidth : result.width
        return CGSize(width: width, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(maxWidth: bounds.width, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            guard subviews.indices.contains(index) else { continue }
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private struct ArrangeResult {
        var frames: [CGRect]
        var width: CGFloat
        var height: CGFloat
    }

    private func arrange(maxWidth: CGFloat, subviews: Subviews) -> ArrangeResult {
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var usedWidth: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if maxWidth.isFinite, x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            usedWidth = max(usedWidth, x - spacing)
        }
        return ArrangeResult(frames: frames, width: usedWidth, height: y + rowHeight)
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
            // Músculos / zonas
            "pectorals": "Pectorales",
            "chest": "Pecho",
            "full body": "Cuerpo completo",
            "lats": "Dorsales",
            "latissimus dorsi": "Dorsales",
            "upper back": "Espalda alta",
            "upper-back": "Espalda alta",
            "back": "Espalda",
            "traps": "Trapecios",
            "trapezius": "Trapecio",
            "delts": "Deltoides",
            "deltoids": "Deltoides",
            "shoulders": "Hombros",
            "biceps": "Bíceps",
            "triceps": "Tríceps",
            "forearms": "Antebrazos",
            "forearm": "Antebrazos",
            "abs": "Abdominales",
            "abdominals": "Abdominales",
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
            "lower-back": "Lumbar",
            "spine": "Lumbar",
            "serratus": "Serrato",
            "serratus anterior": "Serrato",
            "tibialis": "Tibial",
            "grip": "Agarre",
            "cardiovascular system": "Cardio",
            "cardio": "Cardio",
            // Partes del cuerpo (catálogo EN)
            "upper legs": "Piernas",
            "lower legs": "Gemelos",
            "upper arms": "Brazos",
            "lower arms": "Antebrazos",
            "legs": "Piernas",
            "arms": "Brazos",
            "neck": "Cuello",
            // Equipo
            "body weight": "Peso corporal",
            "bodyweight": "Peso corporal",
            "peso corporal": "Peso corporal",
            "barbell": "Barra",
            "barra": "Barra",
            "dumbbell": "Mancuernas",
            "dumbbells": "Mancuernas",
            "mancuernas": "Mancuernas",
            "kettlebell": "Kettlebell",
            "cable": "Polea",
            "polea": "Polea",
            "machine": "Máquina",
            "máquina": "Máquina",
            "body only": "Peso corporal",
            "assisted": "Asistido",
            "band": "Banda",
            "bands": "Bandas",
            "medicine ball": "Balón medicinal",
            "stability ball": "Fitball",
            "ez barbell": "Barra EZ",
            "smith machine": "Máquina Smith",
            "leverage machine": "Máquina",
            "rope": "Cuerda",
            "sled": "Trineo",
            "trap bar": "Barra hexagonal",
            "olympic bar": "Barra olímpica",
            "plate": "Disco",
            "disco": "Disco",
            "rings": "Anillas",
            "anillas": "Anillas",
            "pull-up bar": "Barra de dominadas",
            "box": "Cajón",
            "cajón": "Cajón",
        ]
        let key = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let hit = map[key] { return hit }
        if let taxonomy = MuscleTaxonomy.displayNameES[key] { return taxonomy }
        // Evitar mostrar inglés crudo: capitaliza solo si ya parece español/corto.
        return raw
            .split(separator: " ")
            .map { part -> String in
                let p = String(part).lowercased()
                return map[p] ?? String(part).capitalized
            }
            .joined(separator: " ")
    }
}
