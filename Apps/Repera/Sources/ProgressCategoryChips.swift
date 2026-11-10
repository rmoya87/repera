import SwiftUI

/// Categorías del hub Progreso (estilo glance Salud, branding Repera).
enum ProgressCategory: String, CaseIterable, Identifiable, Hashable {
    case training
    case strength
    case fitness
    case heart
    case recovery
    case sports

    var id: String { rawValue }

    var title: String {
        switch self {
        case .training: return "Entreno"
        case .strength: return "Fuerza"
        case .fitness: return "Físico"
        case .heart: return "Corazón"
        case .recovery: return "Recuperación"
        case .sports: return "Deportes"
        }
    }

    /// Iconos propios Repera — no replicar anillos Activity ni set de Apple Salud.
    var systemImage: String {
        switch self {
        case .training: return "bolt.fill"
        case .strength: return "dumbbell.fill"
        case .fitness: return "figure.walk"
        case .heart: return "waveform.path.ecg"
        case .recovery: return "moon.fill"
        case .sports: return "flag.checkered"
        }
    }

    var accent: Color {
        switch self {
        case .training: return OG.accent
        case .strength: return Color(red: 1.0, green: 0.58, blue: 0.0)
        case .fitness: return Color(red: 0.35, green: 0.78, blue: 0.98)
        case .heart: return OG.red
        /// Noche / descanso: azul violáceo más claro en modo noche.
        case .recovery: return Color(red: 0.42, green: 0.36, blue: 0.72)
        /// Deportes: teal (no morado; el morado queda para Recuperación).
        case .sports: return Color(red: 0.10, green: 0.61, blue: 0.56)
        }
    }
}

/// Fila horizontal de chips: icono + nombre en la misma fila; valor debajo.
struct ProgressCategoryChipBar: View {
    @Binding var selection: ProgressCategory
    var glanceValues: (ProgressCategory) -> String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ProgressCategory.allCases) { category in
                    ProgressCategoryChip(
                        category: category,
                        value: glanceValues(category),
                        isSelected: selection == category
                    ) {
                        selection = category
                    }
                }
            }
            .padding(.horizontal, OG.pad)
            .padding(.vertical, 4)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Categorías de progreso")
    }
}

private struct ProgressCategoryChip: View {
    let category: ProgressCategory
    let value: String
    let isSelected: Bool
    let action: () -> Void

    private var foreground: Color { isSelected ? .black : OG.label }
    private var secondaryForeground: Color { isSelected ? .black.opacity(0.72) : OG.label2 }
    private var iconForeground: Color { isSelected ? .black : category.accent }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: category.systemImage)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(iconForeground)
                    Text(category.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(secondaryForeground)
                        .lineLimit(1)
                }
                Text(value)
                    .ogFont(18, weight: .bold, relativeTo: .body)
                    .monospacedDigit()
                    .foregroundStyle(foreground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(minWidth: 88, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .modifier(ProgressChipChrome(isSelected: isSelected))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.title), \(value)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Seleccionado: verde sólido. No seleccionado: Liquid Glass, sin borde gris.
private struct ProgressChipChrome: ViewModifier {
    let isSelected: Bool
    private let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

    func body(content: Content) -> some View {
        if isSelected {
            content.background(shape.fill(OG.accent))
        } else {
            content.glassEffect(.regular.interactive(), in: shape)
        }
    }
}

/// Cabecera de insight. El chevron solo si `showsChevron` (destino real).
struct ProgressInsightHeader: View {
    let title: String
    let systemImage: String
    var tint: Color = OG.accent
    var showsChevron: Bool = false
    var trailingText: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .symbolRenderingMode(.hierarchical)
            if !title.isEmpty {
                Text(title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(tint)
            }
            Spacer(minLength: 0)
            if let trailingText {
                Text(trailingText)
                    .font(.callout.weight(.semibold).monospacedDigit())
                    .foregroundStyle(tint)
                    .lineLimit(1)
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(OG.label3)
            }
        }
    }
}

/// Card insight estilo Apple Salud: cabecera tintada + frase narrativa + contenido visual opcional.
struct ProgressInsightCard<Content: View>: View {
    let title: String
    let systemImage: String
    let narrative: String
    var tint: Color = OG.accent
    var showsChevron: Bool = false
    var trailingText: String? = nil
    @ViewBuilder var content: () -> Content

    init(
        title: String,
        systemImage: String,
        narrative: String = "",
        tint: Color = OG.accent,
        showsChevron: Bool = false,
        trailingText: String? = nil,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.title = title
        self.systemImage = systemImage
        self.narrative = narrative
        self.tint = tint
        self.showsChevron = showsChevron
        self.trailingText = trailingText
        self.content = content
    }

    var body: some View {
        OGCard {
            VStack(alignment: .leading, spacing: 12) {
                ProgressInsightHeader(
                    title: title,
                    systemImage: systemImage,
                    tint: tint,
                    showsChevron: showsChevron,
                    trailingText: trailingText
                )
                if !narrative.isEmpty {
                    Text(narrative)
                        .font(.subheadline)
                        .foregroundStyle(OG.label2)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2)
                }
                content()
            }
        }
    }
}

/// Héroe numérico grande (p. ej. 69 LPM) a la izquierda + accesorio visual a la derecha.
struct ProgressHeroMetricRow<Accessory: View>: View {
    let value: String
    let unit: String?
    let caption: String?
    /// Tamaño del número héroe (Estímulo/FC usan ~54).
    var valuePointSize: CGFloat = 44
    /// Meta apilada a la derecha del número (p. ej. tiempo encima de «salidas»), misma tipografía.
    var stackedMeta: (top: String, bottom: String)? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ViewBuilder var accessory: () -> Accessory

    init(
        value: String,
        unit: String? = nil,
        caption: String? = nil,
        valuePointSize: CGFloat = 44,
        stackedMeta: (top: String, bottom: String)? = nil,
        @ViewBuilder accessory: @escaping () -> Accessory
    ) {
        self.value = value
        self.unit = unit
        self.caption = caption
        self.valuePointSize = valuePointSize
        self.stackedMeta = stackedMeta
        self.accessory = accessory
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Group {
                if let stackedMeta {
                    HStack(alignment: .center, spacing: 12) {
                        Text(value)
                            .ogFont(valuePointSize, weight: .bold, design: .rounded, relativeTo: .largeTitle)
                            .monospacedDigit()
                            .foregroundStyle(OG.label)
                            .minimumScaleFactor(0.55)
                            .lineLimit(1)
                            .ogNumericText(value: value, reduceMotion: reduceMotion)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stackedMeta.top)
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(OG.label2)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .ogNumericText(value: stackedMeta.top, reduceMotion: reduceMotion)
                            Text(stackedMeta.bottom)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(OG.label2)
                                .lineLimit(1)
                        }
                        .frame(minHeight: valuePointSize * 0.85, alignment: .center)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(value)
                                .ogFont(valuePointSize, weight: .bold, design: .rounded, relativeTo: .largeTitle)
                                .monospacedDigit()
                                .foregroundStyle(OG.label)
                                .minimumScaleFactor(0.55)
                                .lineLimit(1)
                                .ogNumericText(value: value, reduceMotion: reduceMotion)
                            if let unit {
                                Text(unit)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(OG.label2)
                            }
                        }
                        if let caption {
                            Text(caption)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(OG.label3)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            accessory()
        }
    }
}

/// Card insight: título arriba; el sobrante hasta el caption es el dato grande;
/// caption alineado abajo con la gráfica.
struct ProgressInsightElevatedCard<Chart: View>: View {
    let title: String
    let systemImage: String
    var tint: Color = OG.accent
    var value: String
    var unit: String? = nil
    var caption: String? = nil
    var valuePointSize: CGFloat = 64
    var showsChevron: Bool = false
    var trailingText: String? = nil
    /// FC estilo Salud: gráfica a ancho completo bajo el héroe (barras min–máx).
    var chartBelow: Bool = false
    var chartHeight: CGFloat = 72
    /// Carga / Estímulo: la gráfica sube hasta la fila del título (junto a header + héroe).
    var chartBesideTitle: Bool = false
    /// Levitating (FC): alinear al centro para no recortar cápsulas. Fill/área: abajo con caption.
    var chartAlignsBottom: Bool = true
    @ViewBuilder var chart: () -> Chart

    var body: some View {
        OGCard {
            if chartBesideTitle {
                // Misma altura que la gráfica: título arriba, caption abajo con las barras,
                // dato grande en el sobrante.
                HStack(alignment: .bottom, spacing: 12) {
                    VStack(alignment: .leading, spacing: 0) {
                        ProgressInsightHeader(
                            title: title,
                            systemImage: systemImage,
                            tint: tint,
                            showsChevron: showsChevron,
                            trailingText: trailingText
                        )
                        Spacer(minLength: 4)
                        heroValueBlock
                        if let caption {
                            Text(caption)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(OG.label3)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: chartHeight, alignment: .bottom)
                    chart()
                        .frame(width: 152, height: chartHeight, alignment: .bottom)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ProgressInsightHeader(
                        title: title,
                        systemImage: systemImage,
                        tint: tint,
                        showsChevron: showsChevron,
                        trailingText: trailingText
                    )
                    if chartBelow {
                        heroMetricsStacked
                        chart()
                            .frame(maxWidth: .infinity)
                            .frame(height: chartHeight)
                    } else {
                        HStack(
                            alignment: chartAlignsBottom ? .bottom : .center,
                            spacing: 12
                        ) {
                            VStack(alignment: .leading, spacing: 0) {
                                Spacer(minLength: 0)
                                heroValueBlock
                                if let caption {
                                    Text(caption)
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(OG.label3)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: chartHeight, alignment: .bottom)
                            chart()
                                .frame(
                                    width: 152,
                                    height: chartHeight,
                                    alignment: chartAlignsBottom ? .bottom : .center
                                )
                        }
                    }
                }
            }
        }
    }

    private var heroValueBlock: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value)
                .ogFont(valuePointSize, weight: .bold, design: .rounded, relativeTo: .largeTitle)
                .monospacedDigit()
                .foregroundStyle(OG.label)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            if let unit {
                Text(unit)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(OG.label2)
            }
        }
    }

    private var heroMetricsStacked: some View {
        VStack(alignment: .leading, spacing: 0) {
            heroValueBlock
            if let caption {
                Text(caption)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(OG.label3)
                    .padding(.top, -2)
            }
        }
    }
}

/// Métrica compacta estilo Salud: etiqueta tintada + valor grande.
struct ProgressMetricGlanceCard: View {
    let title: String
    let value: String
    var tint: Color = OG.accent
    var footnote: String? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        OGCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Text(value)
                    .font(.system(.title, design: .rounded, weight: .bold).monospacedDigit())
                    .foregroundStyle(OG.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .ogNumericText(value: value, reduceMotion: reduceMotion)
                if let footnote {
                    Text(footnote)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(OG.label3)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        }
    }
}

/// Barras levitando (estilo Salud): cada cápsula va de `lower`→`upper` en Y normalizado.
/// `0` = suelo del plot, `1` = techo. Si el mín del día es 58 lpm, `lower` es Y(58), no el eje X.
struct ProgressMiniRangeBars: View {
    let samples: [ClosedRange<Double>]
    var tint: Color = OG.red
    var height: CGFloat = 72

    var body: some View {
        Canvas { context, size in
            let n = samples.count
            guard n > 0, size.height > 0, size.width > 0 else { return }
            let spacing = n > 14 ? CGFloat(2) : CGFloat(4)
            let slot = (size.width - spacing * CGFloat(n - 1)) / CGFloat(n)
            let barW = max(slot * 0.72, 3)
            for (i, range) in samples.enumerated() {
                let lo = min(max(range.lowerBound, 0), 1)
                let hi = min(max(range.upperBound, lo + 0.06), 1)
                // Y crece hacia abajo: hi arriba, lo abajo. Nunca anclar lo a y = size.height
                // salvo que lowerBound sea realmente 0 en el dominio (no lpm 0).
                let yTop = size.height * (1 - hi)
                let yBot = size.height * (1 - lo)
                let barH = max(yBot - yTop, 5)
                let x = CGFloat(i) * (slot + spacing) + (slot - barW) / 2
                let rect = CGRect(x: x, y: yTop, width: barW, height: barH)
                let path = Path(roundedRect: rect, cornerRadius: barW / 2, style: .continuous)
                context.fill(path, with: .color(tint.opacity(0.92)))
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

/// Barras rellenas desde la base (estímulo / minutos). Distinto del rango flotante de FC.
struct ProgressMiniFillBars: View {
    let fractions: [Double]
    var tint: Color = OG.accent
    var height: CGFloat = 72

    var body: some View {
        Canvas { context, size in
            let n = fractions.count
            guard n > 0, size.height > 0, size.width > 0 else { return }
            // Mes (~28–31): spacing estrecho para caber sin desbordar el marco.
            let spacing: CGFloat = n > 14 ? 2 : 4
            let slot = (size.width - spacing * CGFloat(n - 1)) / CGFloat(n)
            let barW = max(slot * 0.85, 2)
            for (i, raw) in fractions.enumerated() {
                let f = min(max(raw, 0), 1)
                let barH = max(size.height * CGFloat(f), 3)
                let x = CGFloat(i) * (slot + spacing) + (slot - barW) / 2
                let rect = CGRect(x: x, y: size.height - barH, width: barW, height: barH)
                // Cápsula completa: radio = mitad del ancho.
                let path = Path(roundedRect: rect, cornerRadius: barW / 2, style: .continuous)
                context.fill(path, with: .color(tint.opacity(0.9)))
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

/// Sparkline de carga / volumen: solo trazo (sin relleno degradado).
struct ProgressMiniAreaSpark: View {
    let fractions: [Double]
    var tint: Color = OG.accent
    var height: CGFloat = 72

    var body: some View {
        GeometryReader { geo in
            let values = Self.smoothed(fractions.map { min(max($0, 0), 1) })
            let n = max(values.count, 1)
            let w = max(geo.size.width, 1)
            let h = max(geo.size.height, 1)
            let step = n == 1 ? 0 : w / CGFloat(n - 1)
            let points: [CGPoint] = values.enumerated().map { i, v in
                CGPoint(x: CGFloat(i) * step, y: h * (1 - CGFloat(v)))
            }
            Path { path in
                Self.addSmoothCurve(to: &path, points: points, closeToBaseline: nil)
            }
            .stroke(tint, style: StrokeStyle(lineWidth: 4.8, lineCap: .round, lineJoin: .round))
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }

    /// Media móvil ligera (2 pases) para suavizar picos sin inventar tendencia.
    private static func smoothed(_ values: [Double]) -> [Double] {
        guard values.count > 2 else { return values }
        var current = values
        for _ in 0..<2 {
            var next = current
            for i in 1..<(current.count - 1) {
                next[i] = current[i - 1] * 0.22 + current[i] * 0.56 + current[i + 1] * 0.22
            }
            current = next
        }
        return current
    }

    /// Catmull–Rom → curvas cúbicas. `closeToBaseline` cierra el área inferior.
    private static func addSmoothCurve(
        to path: inout Path,
        points: [CGPoint],
        closeToBaseline: CGFloat?
    ) {
        guard let first = points.first else { return }
        if let baseline = closeToBaseline {
            path.move(to: CGPoint(x: first.x, y: baseline))
            path.addLine(to: first)
        } else {
            path.move(to: first)
        }
        guard points.count > 1 else {
            if let baseline = closeToBaseline {
                path.addLine(to: CGPoint(x: first.x, y: baseline))
                path.closeSubpath()
            }
            return
        }
        for i in 0..<(points.count - 1) {
            let p0 = points[max(i - 1, 0)]
            let p1 = points[i]
            let p2 = points[i + 1]
            let p3 = points[min(i + 2, points.count - 1)]
            let cp1 = CGPoint(
                x: p1.x + (p2.x - p0.x) / 6,
                y: p1.y + (p2.y - p0.y) / 6
            )
            let cp2 = CGPoint(
                x: p2.x - (p3.x - p1.x) / 6,
                y: p2.y - (p3.y - p1.y) / 6
            )
            path.addCurve(to: p2, control1: cp1, control2: cp2)
        }
        if let baseline = closeToBaseline, let last = points.last {
            path.addLine(to: CGPoint(x: last.x, y: baseline))
            path.closeSubpath()
        }
    }
}

/// Fila visual de días con/sin estímulo (consistencia semanal o mensual).
struct ProgressConsistencyDots: View {
    struct DayMark: Identifiable {
        let id: Date
        let label: String
        let trained: Bool
        let isToday: Bool
    }

    let days: [DayMark]
    var accent: Color = OG.accent

    var body: some View {
        HStack(spacing: 6) {
            ForEach(days) { day in
                VStack(spacing: 4) {
                    Circle()
                        .fill(day.trained ? accent : OG.surface3.opacity(0.55))
                        .frame(width: 28, height: 28)
                        .overlay {
                            if day.isToday {
                                Circle()
                                    .strokeBorder(accent, lineWidth: 2)
                                    .frame(width: 32, height: 32)
                            }
                        }
                    Text(day.label)
                        .ogFont(10, weight: day.isToday ? .semibold : .regular, relativeTo: .caption2)
                        .foregroundStyle(day.isToday ? accent : OG.label3)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        let n = days.filter(\.trained).count
        return "\(n) de \(days.count) días con entreno"
    }
}
