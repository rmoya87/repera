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
/// Nueve pictogramas de partes del cuerpo, compartidos por los 18 músculos
/// del catálogo. Contornos redondeados, sin detalle anatómico: legibles a 16 pt.
private enum BodyPartGlyphArea {
    case shoulders, upperArm, forearm, chest, back, core, hips, thigh, lowerLeg, unknown

    /// Acepta el slug del catálogo y el nombre localizado que muestran los chips.
    static func forMuscle(_ muscle: String) -> Self {
        let key = muscle.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive],
                     locale: Locale(identifier: "es_ES"))
            .lowercased()
        switch key {
        case "deltoids", "deltoides", "delts", "hombros", "shoulders",
             "trapezius", "trapezio", "trapecio", "trapecios", "traps":
            return .shoulders
        case "biceps", "triceps", "brachialis", "brazo", "upper arms":
            return .upperArm
        case "forearm", "forearms", "antebrazo", "antebrazos", "grip", "agarre":
            return .forearm
        case "chest", "pecho", "pectorals", "pectoral", "pectorales",
             "serratus", "serrato":
            return .chest
        case "upper-back", "upper back", "espalda alta", "lats",
             "latissimus dorsi", "dorsales", "dorsal", "dorsal ancho",
             "back", "espalda", "lower-back", "lower back", "lumbar":
            return .back
        case "abs", "abdominals", "abdomen", "abdominales",
             "obliques", "oblicuos", "core":
            return .core
        case "gluteal", "glutes", "gluteos", "gluteo",
             "hip-flexors", "hip flexors", "flexores de cadera",
             "adductors", "aductores", "abductors", "abductores",
             "hips", "cadera":
            return .hips
        case "quadriceps", "cuadriceps", "quads", "hamstring",
             "hamstrings", "isquios", "isquiotibiales", "muslo":
            return .thigh
        case "calves", "gemelos", "soleus", "tibialis", "tibial",
             "pantorrilla", "lower legs":
            return .lowerLeg
        default:
            return .unknown
        }
    }
}

/// Trazos vectoriales originales de referencia 20×20. Se dibuja la silueta
/// y una única marca de área: igual icono para músculos de la misma zona.
/// Evitamos imágenes añadidas al asset catalog para que Xcode no requiera
/// regenerar el proyecto en instalaciones existentes.
private enum BodyPartGlyphDrawing {
    static func paths(for area: BodyPartGlyphArea) -> (outline: Path, highlight: Path) {
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
        var line = Path()
        var mark = Path()

        switch area {
        case .shoulders:
            // Línea de hombros y cuello; marcas amplias en ambos deltoides.
            line.move(to: pt(7, 2))
            line.addQuadCurve(to: pt(6, 5), control: pt(7, 4))
            line.addQuadCurve(to: pt(2, 7), control: pt(3, 5))
            line.addLine(to: pt(1.5, 14))
            line.move(to: pt(13, 2))
            line.addQuadCurve(to: pt(14, 5), control: pt(13, 4))
            line.addQuadCurve(to: pt(18, 7), control: pt(17, 5))
            line.addLine(to: pt(18.5, 14))
            line.move(to: pt(7, 5))
            line.addQuadCurve(to: pt(13, 5), control: pt(10, 7))
            line.move(to: pt(5, 10))
            line.addLine(to: pt(6, 16))
            line.move(to: pt(15, 10))
            line.addLine(to: pt(14, 16))
            mark.addEllipse(in: CGRect(x: 2.4, y: 6.7, width: 3.5, height: 4))
            mark.addEllipse(in: CGRect(x: 14.1, y: 6.7, width: 3.5, height: 4))
        case .upperArm:
            // Brazo flexionado, icono de fuerza reconocible como pictograma.
            line.move(to: pt(3, 12))
            line.addQuadCurve(to: pt(4, 5), control: pt(2, 8))
            line.addQuadCurve(to: pt(8, 3.5), control: pt(5, 2))
            line.addQuadCurve(to: pt(10, 8), control: pt(11, 5))
            line.addQuadCurve(to: pt(15, 6), control: pt(12, 5))
            line.addQuadCurve(to: pt(18, 11), control: pt(19, 8))
            line.addQuadCurve(to: pt(14, 17), control: pt(18, 16))
            line.addQuadCurve(to: pt(3, 12), control: pt(6, 19))
            mark.addEllipse(in: CGRect(x: 10.1, y: 8, width: 5.1, height: 4))
        case .forearm:
            // Brazo extendido terminado en un puño, con marca en el antebrazo.
            line.move(to: pt(3, 2))
            line.addLine(to: pt(6, 10))
            line.addQuadCurve(to: pt(12, 15), control: pt(8, 13))
            line.addLine(to: pt(15, 17))
            line.addQuadCurve(to: pt(18, 13), control: pt(18.5, 16))
            line.addLine(to: pt(14, 11))
            line.addLine(to: pt(10, 9))
            line.addLine(to: pt(8, 2))
            mark.addEllipse(in: CGRect(x: 8, y: 9, width: 5, height: 4))
        case .chest:
            // Silueta frontal, pectorales amplios sin dibujos anatómicos.
            line.move(to: pt(7, 2))
            line.addQuadCurve(to: pt(5, 5), control: pt(7, 4))
            line.addQuadCurve(to: pt(2, 7), control: pt(3, 5))
            line.addLine(to: pt(1.5, 14))
            line.move(to: pt(13, 2))
            line.addQuadCurve(to: pt(15, 5), control: pt(13, 4))
            line.addQuadCurve(to: pt(18, 7), control: pt(17, 5))
            line.addLine(to: pt(18.5, 14))
            line.move(to: pt(5, 9))
            line.addLine(to: pt(6, 17))
            line.move(to: pt(15, 9))
            line.addLine(to: pt(14, 17))
            mark.addEllipse(in: CGRect(x: 4.4, y: 6, width: 5, height: 4.7))
            mark.addEllipse(in: CGRect(x: 10.6, y: 6, width: 5, height: 4.7))
        case .back:
            // Espalda vista desde atrás, columna central y dos grandes zonas.
            line.move(to: pt(7, 2))
            line.addQuadCurve(to: pt(3, 6), control: pt(7, 4))
            line.addLine(to: pt(2, 14))
            line.move(to: pt(13, 2))
            line.addQuadCurve(to: pt(17, 6), control: pt(13, 4))
            line.addLine(to: pt(18, 14))
            line.move(to: pt(5, 10))
            line.addLine(to: pt(6, 17))
            line.move(to: pt(15, 10))
            line.addLine(to: pt(14, 17))
            line.move(to: pt(10, 5))
            line.addLine(to: pt(10, 16))
            mark.addEllipse(in: CGRect(x: 5, y: 6, width: 4.2, height: 8))
            mark.addEllipse(in: CGRect(x: 10.8, y: 6, width: 4.2, height: 8))
        case .core:
            // Cintura y un bloque abdominal único, visible a tamaño reducido.
            line.move(to: pt(4, 2))
            line.addQuadCurve(to: pt(4, 17), control: pt(6, 9))
            line.move(to: pt(16, 2))
            line.addQuadCurve(to: pt(16, 17), control: pt(14, 9))
            line.move(to: pt(6, 4))
            line.addLine(to: pt(14, 4))
            line.move(to: pt(6, 16))
            line.addLine(to: pt(14, 16))
            mark.addEllipse(in: CGRect(x: 7, y: 7, width: 6, height: 7))
        case .hips:
            // Cadera en forma de pelvis, sin detalle de músculos glúteos.
            line.move(to: pt(5, 2))
            line.addQuadCurve(to: pt(3, 10), control: pt(2, 5))
            line.addQuadCurve(to: pt(8, 16), control: pt(4, 14))
            line.addLine(to: pt(10, 18))
            line.addLine(to: pt(12, 16))
            line.addQuadCurve(to: pt(17, 10), control: pt(16, 14))
            line.addQuadCurve(to: pt(15, 2), control: pt(18, 5))
            line.move(to: pt(8, 12))
            line.addQuadCurve(to: pt(12, 12), control: pt(10, 9))
            mark.addEllipse(in: CGRect(x: 4.9, y: 7, width: 5, height: 6))
            mark.addEllipse(in: CGRect(x: 10.1, y: 7, width: 5, height: 6))
        case .thigh:
            // Ambas piernas hasta la rodilla, con separación central clara.
            line.move(to: pt(4, 2))
            line.addLine(to: pt(3, 8))
            line.addLine(to: pt(4, 17))
            line.move(to: pt(16, 2))
            line.addLine(to: pt(17, 8))
            line.addLine(to: pt(16, 17))
            line.move(to: pt(4, 2))
            line.addQuadCurve(to: pt(16, 2), control: pt(10, 5))
            line.move(to: pt(10, 8))
            line.addLine(to: pt(8, 17))
            line.move(to: pt(10, 8))
            line.addLine(to: pt(12, 17))
            mark.addEllipse(in: CGRect(x: 4.2, y: 8, width: 3.6, height: 7))
            mark.addEllipse(in: CGRect(x: 12.2, y: 8, width: 3.6, height: 7))
        case .lowerLeg:
            // Gemelo / tibia + pie lateral: distinto del icono de muslo.
            line.move(to: pt(6, 2))
            line.addQuadCurve(to: pt(6, 10), control: pt(4, 6))
            line.addLine(to: pt(5, 15))
            line.addQuadCurve(to: pt(2, 18), control: pt(4, 17))
            line.addLine(to: pt(16, 18))
            line.addQuadCurve(to: pt(14, 15), control: pt(17, 16))
            line.addLine(to: pt(12, 13))
            line.addQuadCurve(to: pt(13, 2), control: pt(15, 7))
            mark.addEllipse(in: CGRect(x: 7.1, y: 5.5, width: 4.5, height: 7))
        case .unknown:
            break
        }
        return (line, mark)
    }
}

private struct MuscleChipGlyph: View {
    let muscle: String
    let emphasized: Bool

    private var area: BodyPartGlyphArea {
        BodyPartGlyphArea.forMuscle(muscle)
    }

    var body: some View {
        Group {
            if muscle.trimmingCharacters(in: .whitespacesAndNewlines)
                .caseInsensitiveCompare("Cardio") == .orderedSame {
                // Mismo corazón que el filtro Cardio de la biblioteca.
                Image(systemName: ExerciseCategorySymbols.discipline("Cardio"))
                    .font(.system(size: 12, weight: .semibold))
            } else if area == .unknown {
                Image(systemName: ExerciseCategorySymbols.muscle)
                    .font(.system(size: 12, weight: .semibold))
            } else {
                Canvas { context, size in
                    let paths = BodyPartGlyphDrawing.paths(for: area)
                    let scale = CGAffineTransform(
                        scaleX: size.width / 20, y: size.height / 20
                    )
                    // Verde en chips neutrales; negro sobre el chip verde principal.
                    let ink = emphasized ? OG.onAccent : OG.label
                    let highlight = emphasized ? OG.onAccent.opacity(0.65) : OG.accent
                    context.fill(paths.highlight.applying(scale), with: .color(highlight))
                    context.stroke(paths.outline.applying(scale), with: .color(ink),
                                   style: StrokeStyle(lineWidth: 1.5,
                                                      lineCap: .round,
                                                      lineJoin: .round))
                }
            }
        }
        .frame(width: 16, height: 16)
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
    /// En DUO/iPad el encabezado y sus acciones viven dentro del panel derecho.
    var showsQuickLogToolbarAction = true
    var showsInlineHeader = false

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
                        if !showsInlineHeader {
                            OGScrollablePageTitle(exercise.name)
                                .padding(.horizontal, OG.pad)
                                .padding(.top, 8)
                        }
                        if showsInlineHeader {
                            HStack(alignment: .center, spacing: 10) {
                                Text(exercise.name)
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(OG.label)
                                    .lineLimit(2)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Button {
                                    store.toggleFavorite(resolvedId)
                                } label: {
                                    Image(systemName: exercise.isFavorite ? "star.fill" : "star")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(exercise.isFavorite ? OG.yellow : OG.label)
                                        .frame(width: OG.toolbarGlassSize, height: OG.toolbarGlassSize)
                                        .glassEffect(.regular.interactive(), in: .circle)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(exercise.isFavorite ? "Quitar de favoritos" : "Marcar favorito")
                                Button {
                                    showQuickLog = true
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(OG.label)
                                        .frame(width: OG.toolbarGlassSize, height: OG.toolbarGlassSize)
                                        .glassEffect(.regular.interactive(), in: .circle)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Apuntar ejercicio")
                            }
                            .padding(.horizontal, OG.pad)
                            .padding(.top, 12)
                        }

                        // Título y acciones quedan sobre la imagen en el panel derecho.
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
                .ogScrollingTitleNav(usesGroupedList: false)
                .ogDiaryTransparentNav()
                .toolbar(showsInlineHeader ? .hidden : .visible, for: .navigationBar)
                .toolbar {
                    if !showsInlineHeader {
                    ToolbarItem(placement: .topBarTrailing) {
                        OGToolbarGlassButton(
                            systemName: exercise.isFavorite ? "star.fill" : "star",
                            accessibilityLabel: exercise.isFavorite ? "Quitar de favoritos" : "Favorito",
                            tint: exercise.isFavorite ? OG.yellow : OG.label
                        ) {
                            store.toggleFavorite(resolvedId)
                        }
                    }
                    if showsQuickLogToolbarAction {
                        ToolbarItem(placement: .topBarTrailing) {
                            OGToolbarGlassButton(
                                systemName: "plus",
                                accessibilityLabel: "Apuntar ejercicio",
                                tint: OG.accent
                            ) {
                                showQuickLog = true
                            }
                        }
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
                    Text("\(ReperaNumberFormat.decimal(kg)) kg")
                        .font(.system(size: 28, weight: .bold).monospacedDigit())
                        .foregroundStyle(OG.label)
                }

                Slider(value: $suggestPercent, in: 50...95, step: 5)
                    .tint(OG.accent)

                Text("Pasos de 5% · sobre \(source ?? "1RM") \(ReperaNumberFormat.decimal(oneRM)) kg")
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
                MuscleChipGlyph(muscle: muscle, emphasized: emphasized)
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
