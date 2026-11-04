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
        case .strength: return Color(red: 1.0, green: 0.58, blue: 0.0) // naranja fuerza
        case .fitness: return Color(red: 0.35, green: 0.78, blue: 0.98)
        case .heart: return OG.red
        case .recovery: return Color(red: 0.20, green: 0.78, blue: 0.72)
        case .sports: return Color(red: 0.55, green: 0.45, blue: 0.95)
        }
    }
}

/// Fila horizontal de chips glance: icono + valor + título.
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
            .padding(.vertical, 2)
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

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: category.systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(category.accent)
                    .frame(height: 18, alignment: .leading)
                Text(value)
                    .font(.system(size: 15, weight: .bold).monospacedDigit())
                    .foregroundStyle(OG.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(category.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(OG.label2)
                    .lineLimit(1)
            }
            .frame(width: 92, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(OG.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? OG.accent : OG.surface3.opacity(0.75), lineWidth: isSelected ? 2 : 0.7)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.title), \(value)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Cabecera de insight estilo Salud (frase + chevron), sobre tokens OG.
struct ProgressInsightHeader: View {
    let title: String
    let systemImage: String
    var tint: Color = OG.accent

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(OG.label3)
        }
    }
}
