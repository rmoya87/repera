import Foundation
import ReperaDomain
import SwiftUI

/// SF Symbols compartidos por los filtros de Ejercicios y las etiquetas de su ficha.
/// Usar el mismo icono independientemente de la pantalla que muestra la disciplina.
enum ExerciseCategorySymbols {
    static let muscle = "figure.stand"
    static let equipment = "dumbbell"

    static func discipline(_ name: String) -> String {
        switch name.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es_ES"))
            .lowercased() {
        case "crossfit", "cross fit":
            return "figure.cross.training"
        case "gimnasia", "gimnasticos", "gymnastics", "gymnastic":
            return "figure.play"
        case "hyrox":
            return "figure.run"
        case "movilidad", "mobility":
            return "figure.flexibility"
        case "halterofilia", "weightlifting":
            return "figure.strengthtraining.traditional"
        case "cardio":
            return "heart"
        default:
            return "sportscourt"
        }
    }

    /// Símbolos individuales por aparato. Se usan tanto para elementos únicos
    /// como para montajes con varios materiales (p. ej. cajón + kettlebell).
    static func equipmentSymbol(for material: String) -> String {
        let e = material.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive],
                     locale: Locale(identifier: "es_ES"))
            .lowercased()
        if e.contains("cajon") || e.contains("step") || e.contains("plataforma") { return "cube" }
        if e.contains("anillas") || e.contains("rings") { return "circle" }
        if e.contains("barra de dominadas") || e.contains("barra fija") { return "figure.climbing" }
        if e.contains("barra") || e.contains("barbell") { return "figure.strengthtraining.traditional" }
        if e.contains("mancuerna") || e.contains("dumbbell") { return "dumbbell" }
        if e.contains("kettlebell") || e.contains("pesa rusa") { return "scalemass" }
        if e.contains("lastre") || e.contains("chaleco") { return "scalemass" }
        if e.contains("comba") { return "figure.jumprope" }
        if e.contains("cuerda de trepa") { return "figure.climbing" }
        if e.contains("paralela") || e.contains("parallete") { return "figure.strengthtraining.functional" }
        if e.contains("rueda abdominal") || e.contains("ab wheel") { return "circle.circle" }
        if e.contains("rodillo") { return "circle" }
        if e.contains("banco") { return "chair.lounge" }
        if e.contains("pared") || e.contains("muro") { return "square.grid.3x3" }
        if e.contains("puerta") { return "door.left.hand.closed" }
        if e.contains("banda") || e.contains("goma") { return "circle.dashed" }
        if e.contains("pica") { return "line.diagonal" }
        if e.contains("disco") { return "circle.dotted.circle" }
        if e.contains("balon") || e.contains("ball") { return "basketball" }
        if e.contains("ski") || e.contains("esqui") { return "figure.skiing.crosscountry" }
        if e.contains("remo") || e.contains("rowerg") { return "figure.rower" }
        if e.contains("cinta de correr") || e.contains("treadmill") { return "figure.run" }
        if e.contains("bicicleta") || e.contains("bike") { return "bicycle" }
        if e.contains("ghd") { return "figure.core.training" }
        if e.contains("pegboard") { return "circle.grid.3x3" }
        if e.contains("polea") { return "gearshape.2" }
        if e.contains("saco") || e.contains("sandbag") { return "bag" }
        if e.contains("trineo") || e.contains("sled") { return "shippingbox" }
        if e.contains("yoke") { return "figure.strengthtraining.traditional" }
        if e.contains("maquina") || e.contains("machine") { return "gearshape" }
        if e.contains("peso corporal") || e.contains("sin material") { return "figure.stand" }
        return equipment
    }
}

/// Glifo monocromo de 16 pt inspirado en SF Symbols. Tres contornos legibles a
/// tamaño de chip (torso, brazo y pierna) con una única zona rellena; sin
/// miniaturas anatómicas detalladas que se volverían ilegibles.
private enum MuscleGlyphPart {
    case torso, arm, leg, unknown
}

private struct MuscleGlyphOutline: Shape {
    let part: MuscleGlyphPart

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch part {
        case .torso:
            // Cuello, hombros, costados y cintura: un contorno simple.
            path.move(to: CGPoint(x: 6, y: 1))
            path.addLine(to: CGPoint(x: 6, y: 3))
            path.addLine(to: CGPoint(x: 3, y: 4))
            path.addLine(to: CGPoint(x: 2, y: 8))
            path.move(to: CGPoint(x: 10, y: 1))
            path.addLine(to: CGPoint(x: 10, y: 3))
            path.addLine(to: CGPoint(x: 13, y: 4))
            path.addLine(to: CGPoint(x: 14, y: 8))
            path.move(to: CGPoint(x: 4, y: 5))
            path.addLine(to: CGPoint(x: 5, y: 14))
            path.addLine(to: CGPoint(x: 11, y: 14))
            path.addLine(to: CGPoint(x: 12, y: 5))
            path.move(to: CGPoint(x: 5, y: 8))
            path.addLine(to: CGPoint(x: 11, y: 8))
        case .arm:
            // Brazo flexionado: hombro, brazo y antebrazo.
            path.move(to: CGPoint(x: 5, y: 1))
            path.addQuadCurve(to: CGPoint(x: 3, y: 5), control: CGPoint(x: 2, y: 2))
            path.addLine(to: CGPoint(x: 4, y: 10))
            path.addLine(to: CGPoint(x: 9, y: 15))
            path.addLine(to: CGPoint(x: 12, y: 12))
            path.addLine(to: CGPoint(x: 9, y: 9))
            path.addLine(to: CGPoint(x: 9, y: 5))
            path.addQuadCurve(to: CGPoint(x: 5, y: 1), control: CGPoint(x: 10, y: 1))
        case .leg:
            // Muslo, rodilla y gemelo en un único contorno.
            path.move(to: CGPoint(x: 4, y: 1))
            path.addLine(to: CGPoint(x: 12, y: 1))
            path.addLine(to: CGPoint(x: 11, y: 7))
            path.addLine(to: CGPoint(x: 10, y: 10))
            path.addLine(to: CGPoint(x: 12, y: 15))
            path.addLine(to: CGPoint(x: 9, y: 15))
            path.addLine(to: CGPoint(x: 7, y: 11))
            path.addLine(to: CGPoint(x: 8, y: 8))
            path.addLine(to: CGPoint(x: 5, y: 6))
            path.closeSubpath()
        case .unknown:
            break
        }
        return path.applying(CGAffineTransform(
            scaleX: rect.width / 16, y: rect.height / 16
        ))
    }
}

private struct MuscleChipGlyph: View {
    let muscle: String

    private var part: MuscleGlyphPart {
        switch MuscleTaxonomy.canonical(muscle) {
        case "deltoids", "biceps", "triceps", "forearm": return .arm
        case "quadriceps", "hamstring", "gluteal", "adductors",
             "hip-flexors", "calves", "tibialis": return .leg
        case "chest", "upper-back", "lower-back", "trapezius",
             "serratus", "abs", "obliques": return .torso
        default: return .unknown
        }
    }

    /// Zona simple y claramente visible a 16 puntos, no un mapa muscular.
    private var mark: CGRect {
        switch MuscleTaxonomy.canonical(muscle) {
        case "deltoids": return CGRect(x: 4, y: 2, width: 4, height: 3)
        case "biceps": return CGRect(x: 4, y: 5, width: 3, height: 4)
        case "triceps": return CGRect(x: 7, y: 5, width: 3, height: 4)
        case "forearm": return CGRect(x: 8, y: 11, width: 3, height: 3)
        case "trapezius": return CGRect(x: 6, y: 2, width: 4, height: 3)
        case "chest": return CGRect(x: 5, y: 5, width: 6, height: 3)
        case "upper-back": return CGRect(x: 5, y: 6, width: 6, height: 4)
        case "serratus": return CGRect(x: 4, y: 8, width: 3, height: 3)
        case "abs": return CGRect(x: 6, y: 9, width: 4, height: 4)
        case "obliques": return CGRect(x: 4, y: 9, width: 3, height: 4)
        case "lower-back": return CGRect(x: 6, y: 11, width: 4, height: 3)
        case "gluteal": return CGRect(x: 5, y: 2, width: 6, height: 3)
        case "hip-flexors": return CGRect(x: 6, y: 3, width: 4, height: 3)
        case "quadriceps": return CGRect(x: 5, y: 5, width: 4, height: 4)
        case "hamstring": return CGRect(x: 8, y: 5, width: 3, height: 4)
        case "adductors": return CGRect(x: 7, y: 6, width: 3, height: 3)
        case "calves": return CGRect(x: 9, y: 10, width: 3, height: 4)
        case "tibialis": return CGRect(x: 7, y: 10, width: 3, height: 4)
        default: return .zero
        }
    }

    var body: some View {
        Group {
            if part == .unknown {
                Image(systemName: ExerciseCategorySymbols.muscle)
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 16, height: 16)
            } else {
                ZStack(alignment: .topLeading) {
                    MuscleGlyphOutline(part: part)
                        .stroke(style: StrokeStyle(
                            lineWidth: 1.35, lineCap: .round, lineJoin: .round
                        ))
                    RoundedRectangle(cornerRadius: 1, style: .continuous)
                        .frame(width: mark.width, height: mark.height)
                        .position(x: mark.midX, y: mark.midY)
                }
                .frame(width: 16, height: 16)
            }
        }
        .accessibilityHidden(true)
    }
}

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
                        metaRow(title: "Músculo") {
                            chipFlow {
                                metaChip(meta.primary, muscle: meta.primary, emphasized: true)
                            }
                        }

                        if !meta.secondaries.isEmpty {
                            metaRow(title: "También") {
                                chipFlow {
                                    ForEach(meta.secondaries, id: \.self) { label in
                                        metaChip(label, muscle: label)
                                    }
                                }
                            }
                        }

                        if !meta.equipments.isEmpty {
                            metaRow(title: "Equipo") {
                                chipFlow {
                                    ForEach(meta.equipments, id: \.self) { equipment in
                                        metaChip(equipment, icon: ExerciseCategorySymbols.equipmentSymbol(for: equipment))
                                    }
                                }
                            }
                        }

                        if !meta.sports.isEmpty {
                            metaRow(title: "Disciplina") {
                                chipFlow {
                                    ForEach(meta.sports, id: \.self) { sport in
                                        metaChip(sport, icon: ExerciseCategorySymbols.discipline(sport))
                                    }
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
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.4)
                .foregroundStyle(OG.label3)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metaChip(
        _ label: String,
        icon: String? = nil,
        muscle: String? = nil,
        emphasized: Bool = false
    ) -> some View {
        HStack(spacing: 5) {
            if let muscle {
                MuscleChipGlyph(muscle: muscle)
            } else if let icon {
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
        var equipments: [String]
        var sports: [String]
        var hasContent: Bool { !primary.isEmpty }
    }

    private func detailMeta(_ exercise: Exercise) -> DetailMeta {
        let primary = LocalizedMuscle.es(exercise.targetMuscle ?? exercise.muscleGroup)
        var seen: Set<String> = [primary.lowercased()]
        var secondaries: [String] = []
        // Solo músculos verificables: «full body», «upper legs», «cardio»,
        // etc. son regiones genéricas, no músculos secundarios que deban
        // aparecer con un icono anatómico. Completar desde los slugs reales.
        for raw in exercise.secondaryMuscles + exercise.secondaryRegions {
            guard MuscleTaxonomy.canonical(raw) != nil else { continue }
            let label = LocalizedMuscle.es(raw)
            let key = label.lowercased()
            guard !key.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key)
            secondaries.append(label)
        }
        let equipments = (exercise.equipment ?? "")
            .split(separator: ",")
            .map { LocalizedMuscle.es(String($0).trimmingCharacters(in: .whitespacesAndNewlines)) }
            .filter { !$0.isEmpty }
        let sports = exercise.disciplineTags.filter {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return DetailMeta(
            primary: primary,
            secondaries: secondaries,
            equipments: equipments,
            sports: sports
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
