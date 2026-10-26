import ReperaDomain
import SwiftUI

/// Tile de cabecera idéntico en entrenamientos, Comenzar y Salud.
/// Los campos concretos dependen de la disciplina, no cambia el diseño.
struct WorkoutSummaryTile: View {
    var title: String
    var value: String
    var icon: String
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(OG.label3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(OG.label)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .topLeading)
        .padding(12)
        .background(OG.surface, in: RoundedRectangle(
            cornerRadius: OG.radiusCard, style: .continuous
        ))
    }
}

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

/// Misma secuencia de chips en Inicio e Historial (min / kcal / nota / PR [/ notas]).
enum WorkoutRegisterChips {
    /// Entreno Repera terminado.
    @ViewBuilder
    static func repera(session: WorkoutSession, prCount: Int, verifiedHealthKcal: Double? = nil) -> some View {
        let minutes = session.displayDurationMinutes
        if minutes > 0 {
            OGRegisterChip(text: "\(Int(minutes.rounded())) min", icon: "timer")
        }
        // Nunca usar session.appleActiveEnergyKcal: en versiones anteriores
        // podía ser un valor MET estimado, incluso escrito por Repera en Salud.
        if let kcal = verifiedHealthKcal, kcal > 0 {
            OGRegisterChip(text: "\(Int(kcal.rounded())) kcal", icon: "flame.fill")
        }
        if let review = session.sessionReview {
            OGRegisterChip(text: review.scoreLabel, icon: review.scoreSymbolName)
        }
        if prCount > 0 {
            OGRegisterChip(text: "\(prCount) PR", icon: "trophy.fill")
        }
        let notes = session.notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !notes.isEmpty {
            OGRegisterChip(text: "Notas", icon: "note.text")
        }
    }

    /// Actividad importada de Apple Salud.
    @ViewBuilder
    static func health(_ activity: HealthKitStore.ExternalActivity) -> some View {
        OGRegisterChip(text: "Salud", icon: "heart.fill")
        if activity.durationMinutes > 0 {
            OGRegisterChip(text: "\(Int(activity.durationMinutes.rounded())) min", icon: "timer")
        }
        if let kcal = activity.activeEnergyKcal, kcal > 0 {
            OGRegisterChip(text: "\(Int(kcal.rounded())) kcal", icon: "flame.fill")
        }
        if let meters = activity.distanceMeters, meters > 0 {
            OGRegisterChip(text: distanceLabel(meters), icon: "figure.walk")
        }
    }

    private static func distanceLabel(_ meters: Double) -> String {
        if meters >= 1000 {
            let km = meters / 1000
            return "\(ReperaNumberFormat.decimal(km)) km"
        }
        return "\(Int(meters.rounded())) m"
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
