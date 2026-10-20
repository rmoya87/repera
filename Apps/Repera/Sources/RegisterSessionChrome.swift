import SwiftUI

/// Icono circular de fila de entreno / actividad (Inicio + Historial).
struct OGRegisterLeadingIcon: View {
    var systemName: String
    var tint: Color

    var body: some View {
        ZStack {
            Circle().fill(tint.opacity(0.22))
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: 44, height: 44)
    }
}

/// Chip de métrica (min / kcal / nota / PR…) compartido por Inicio e Historial.
struct OGRegisterChip: View {
    var text: String
    var icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundStyle(OG.label2)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(OG.surface3.opacity(0.65), in: Capsule())
    }
}

/// Carrusel horizontal de chips alineado al título (tras icono 44 + gap 12).
struct OGRegisterChipsRow<Content: View>: View {
    var leadingInset: CGFloat
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                content()
            }
            .padding(.leading, leadingInset)
        }
        .contentMargins(.horizontal, 0, for: .scrollContent)
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

enum WorkoutListCaption {
    /// Misma etiqueta que Inicio: «ENTRENO · 18:30» (hoy) o «LUNES · 18:30».
    static func dayTimeLine(for day: Date, time: String?) -> String {
        let cal = Calendar.current
        let dayLabel: String
        if cal.isDateInToday(day) {
            dayLabel = "ENTRENO"
        } else {
            let f = DateFormatter()
            f.locale = Locale(identifier: "es_ES")
            f.setLocalizedDateFormatFromTemplate("EEEE")
            dayLabel = f.string(from: day).uppercased()
        }
        guard let time, !time.isEmpty else { return dayLabel }
        return "\(dayLabel) · \(time)"
    }
}
