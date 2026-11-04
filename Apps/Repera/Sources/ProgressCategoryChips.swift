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
        case .fitness: return "Forma física"
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
        case .recovery: return "leaf.fill"
        case .sports: return "flag.checkered"
        }
    }

    var accent: Color {
        switch self {
        case .training: return OG.accent
        case .strength: return Color(red: 1.0, green: 0.58, blue: 0.0)
        case .fitness: return Color(red: 0.35, green: 0.78, blue: 0.98)
        case .heart: return OG.red
        case .recovery: return Color(red: 0.20, green: 0.78, blue: 0.72)
        case .sports: return Color(red: 0.55, green: 0.45, blue: 0.95)
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

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .symbolRenderingMode(.hierarchical)
            Text(title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(tint)
            Spacer(minLength: 0)
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
    @ViewBuilder var content: () -> Content

    init(
        title: String,
        systemImage: String,
        narrative: String,
        tint: Color = OG.accent,
        showsChevron: Bool = false,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.title = title
        self.systemImage = systemImage
        self.narrative = narrative
        self.tint = tint
        self.showsChevron = showsChevron
        self.content = content
    }

    var body: some View {
        OGCard {
            VStack(alignment: .leading, spacing: 12) {
                ProgressInsightHeader(
                    title: title,
                    systemImage: systemImage,
                    tint: tint,
                    showsChevron: showsChevron
                )
                Text(narrative)
                    .font(.subheadline)
                    .foregroundStyle(OG.label2)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
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
    @ViewBuilder var accessory: () -> Accessory

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .ogFont(44, weight: .bold, design: .rounded, relativeTo: .largeTitle)
                        .monospacedDigit()
                        .foregroundStyle(OG.label)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    if let unit {
                        Text(unit)
                            .font(.headline)
                            .foregroundStyle(OG.label2)
                    }
                }
                if let caption {
                    Text(caption)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(OG.label3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            accessory()
        }
    }
}

/// Métrica compacta estilo Salud: etiqueta tintada + valor grande.
struct ProgressMetricGlanceCard: View {
    let title: String
    let value: String
    var tint: Color = OG.accent
    var footnote: String? = nil

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

/// Mini barras de rango (estilo FC Salud) a partir de valores 0…1.
struct ProgressMiniRangeBars: View {
    let samples: [ClosedRange<Double>]
    var tint: Color = OG.red
    var height: CGFloat = 72

    var body: some View {
        GeometryReader { geo in
            let w = max(geo.size.width, 1)
            let spacing: CGFloat = 3
            let count = max(samples.count, 1)
            let barW = max((w - spacing * CGFloat(count - 1)) / CGFloat(count), 2)
            HStack(alignment: .bottom, spacing: spacing) {
                ForEach(Array(samples.enumerated()), id: \.offset) { _, range in
                    let lo = min(max(range.lowerBound, 0), 1)
                    let hi = min(max(range.upperBound, 0), 1)
                    let top = height * (1 - hi)
                    let barH = max(height * (hi - lo), 4)
                    Capsule()
                        .fill(tint.opacity(0.85))
                        .frame(width: barW, height: barH)
                        .padding(.top, top)
                        .frame(height: height, alignment: .top)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: height)
        .accessibilityHidden(true)
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
