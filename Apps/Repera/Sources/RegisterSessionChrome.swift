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
        VStack(alignment: .center, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(OG.label3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(OG.label)
                .lineLimit(1)
                .minimumScaleFactor(0.45)
                .frame(maxWidth: .infinity, maxHeight: 26, alignment: .center)
        }
        // Altura fija para que Tiempo / Marca / Kcal alineen aunque el valor sea corto o largo.
        .frame(maxWidth: .infinity, minHeight: 52, maxHeight: 52, alignment: .center)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(OG.surface, in: RoundedRectangle(
            cornerRadius: OG.radiusCard, style: .continuous
        ))
    }
}

/// Tres tiles de cabecera según tipo de sesión (Historial + Guardar entreno).
struct SessionSummaryTileSpec: Equatable {
    var title: String
    var value: String
    var icon: String
    var tint: Color
}

enum SessionSummaryTilesBuilder {
    static func tiles(
        session: WorkoutSession,
        sport: LiveSport?,
        health: HealthKitStore.SessionHealthExtras?,
        durationLabel: String,
        paceOrSpeedLabel: String? = nil
    ) -> [SessionSummaryTileSpec] {
        let kcal = authenticKcal(session: session, health: health)
        let kcalValue = kcal.map { "\(Int($0.rounded()))" } ?? "—"
        let steps = health?.stepsCount.flatMap { $0 > 0 ? $0 : nil }
        let stepsValue = steps.map { ReperaNumberFormat.integer($0) } ?? "—"
        let avgHR = health?.averageHeartRateBpm.flatMap { $0 > 0 ? $0 : nil }
        let hrValue = avgHR.map { "\(Int($0.rounded()))" } ?? "—"
        let distanceMeters = resolvedDistanceMeters(session: session, health: health)
        let distanceValue: String = {
            guard let meters = distanceMeters, meters > 0 else { return "—" }
            if meters >= 1000 {
                return "\(ReperaNumberFormat.decimal(meters / 1000)) km"
            }
            return "\(Int(meters.rounded())) m"
        }()

        if let timer = session.timerDetails {
            var row = [
                SessionSummaryTileSpec(title: "Tiempo", value: DurationText.format(timer.configuredSeconds),
                                       icon: "clock.fill", tint: OG.blue),
                SessionSummaryTileSpec(title: "Modalidad", value: timer.modeTitle,
                                       icon: "timer", tint: OG.accent)
            ]
            if timer.modeRaw == "intervals" {
                row.append(SessionSummaryTileSpec(title: "Rondas", value: "\(timer.rounds)",
                                                  icon: "repeat", tint: OG.orange))
            } else {
                row.append(SessionSummaryTileSpec(title: "Kcal", value: kcalValue,
                                                  icon: "flame.fill", tint: OG.orange))
            }
            return row
        }

        let time = SessionSummaryTileSpec(
            title: "Tiempo", value: durationLabel, icon: "clock.fill", tint: OG.blue
        )

        if let sport, sport.usesGPS {
            let thirdTitle: String
            let thirdIcon: String
            if sport.showsElevationAndSpeedStats || sport.displaysSpeed {
                thirdTitle = "Vel. media"
                thirdIcon = "gauge.with.dots.needle.67percent"
            } else {
                thirdTitle = "Ritmo"
                thirdIcon = "speedometer"
            }
            return [
                time,
                SessionSummaryTileSpec(
                    title: "Distancia", value: distanceValue,
                    icon: "point.bottomleft.forward.to.point.topright.scurvepath", tint: OG.accent
                ),
                SessionSummaryTileSpec(
                    title: thirdTitle, value: paceOrSpeedLabel ?? "—",
                    icon: thirdIcon, tint: OG.blue
                )
            ]
        }

        if let sport, sport.usesStepsKcalSummaryTiles {
            return [
                time,
                SessionSummaryTileSpec(title: "Kcal", value: kcalValue, icon: "flame.fill", tint: OG.orange),
                SessionSummaryTileSpec(title: "Pasos", value: stepsValue, icon: "figure.walk", tint: OG.accent)
            ]
        }

        if let sport, sport.usesHeartRateSummaryTiles {
            return [
                time,
                SessionSummaryTileSpec(title: "Kcal", value: kcalValue, icon: "flame.fill", tint: OG.orange),
                SessionSummaryTileSpec(title: "FC media", value: hrValue, icon: "heart.fill", tint: OG.red)
            ]
        }

        if let sport, sport.usesFitnessClassSummaryTiles {
            let third: SessionSummaryTileSpec = {
                if avgHR != nil {
                    return SessionSummaryTileSpec(title: "FC media", value: hrValue,
                                                  icon: "heart.fill", tint: OG.red)
                }
                return SessionSummaryTileSpec(title: "Pasos", value: stepsValue,
                                              icon: "figure.walk", tint: OG.accent)
            }()
            return [
                time,
                SessionSummaryTileSpec(title: "Kcal", value: kcalValue, icon: "flame.fill", tint: OG.orange),
                third
            ]
        }

        if sport == .swimming || sport == .elliptical || sport == .stairClimbing || sport == .climbing {
            let third: SessionSummaryTileSpec = {
                if let meters = distanceMeters, meters > 0 {
                    return SessionSummaryTileSpec(
                        title: "Distancia", value: distanceValue,
                        icon: "point.bottomleft.forward.to.point.topright.scurvepath", tint: OG.accent
                    )
                }
                return SessionSummaryTileSpec(title: "FC media", value: hrValue,
                                              icon: "heart.fill", tint: OG.red)
            }()
            return [
                time,
                SessionSummaryTileSpec(title: "Kcal", value: kcalValue, icon: "flame.fill", tint: OG.orange),
                third
            ]
        }

        // Entreno programado (sin liveSport): fuerza → volumen; WOD → marca.
        if sport == nil {
            if let wod = session.wodResults.first {
                let mark = compactWODMark(wod)
                if mark != "—" {
                    return [
                        time,
                        SessionSummaryTileSpec(
                            title: "Marca", value: mark,
                            icon: "flag.checkered", tint: OG.accent
                        ),
                        SessionSummaryTileSpec(
                            title: "Kcal", value: kcalValue,
                            icon: "flame.fill", tint: OG.orange
                        )
                    ]
                }
            }
            let volume = session.totalVolumeKg > 0
                ? ReperaNumberFormat.integer(Int(session.totalVolumeKg.rounded()))
                : "—"
            return [
                time,
                SessionSummaryTileSpec(title: "Kcal", value: kcalValue, icon: "flame.fill", tint: OG.orange),
                SessionSummaryTileSpec(title: "Volumen", value: volume, icon: "scalemass.fill", tint: OG.accent)
            ]
        }

        // Fallback indoor / other.
        return [
            time,
            SessionSummaryTileSpec(title: "Kcal", value: kcalValue, icon: "flame.fill", tint: OG.orange),
            SessionSummaryTileSpec(title: "FC media", value: hrValue, icon: "heart.fill", tint: OG.red)
        ]
    }

    private static func authenticKcal(
        session: WorkoutSession,
        health: HealthKitStore.SessionHealthExtras?
    ) -> Double? {
        if health?.hasExternalSaludSource == true,
           let kcal = health?.activeEnergyKcal, kcal > 0 {
            return kcal
        }
        if let kcal = session.appleActiveEnergyKcal, kcal > 0 { return kcal }
        return nil
    }

    private static func resolvedDistanceMeters(
        session: WorkoutSession,
        health: HealthKitStore.SessionHealthExtras?
    ) -> Double? {
        if let recorded = session.recordedDistanceMeters, recorded > 0 { return recorded }
        if let meters = health?.movementDistanceMeters, meters > 0 { return meters }
        return nil
    }

    /// Marca corta para el tile (el detalle WOD debajo lleva el texto completo).
    /// Ej.: `12:34`, `150`, `3+45` — evita «3 rondas + 45 reps» que no cabe.
    private static func compactWODMark(_ result: WODBlockResult) -> String {
        if let elapsedSeconds = result.elapsedSeconds {
            let m = elapsedSeconds / 60
            let s = elapsedSeconds % 60
            return String(format: "%d:%02d", m, s)
        }
        if let totalReps = result.totalReps {
            if let rounds = result.roundsCompleted {
                return "\(rounds)+\(totalReps)"
            }
            return "\(totalReps)"
        }
        if let rounds = result.roundsCompleted {
            return "\(rounds)"
        }
        return "—"
    }
}

struct SessionSummaryTilesRow: View {
    var specs: [SessionSummaryTileSpec]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(specs.enumerated()), id: \.offset) { _, spec in
                WorkoutSummaryTile(
                    title: spec.title, value: spec.value, icon: spec.icon, tint: spec.tint
                )
            }
        }
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
        if let timer = session.timerDetails {
            // Los temporizadores de pocos segundos no deben aparecer como 0 min.
            OGRegisterChip(text: DurationText.format(timer.configuredSeconds), icon: "timer")
            OGRegisterChip(text: timer.modeTitle, icon: "stopwatch")
        } else if minutes > 0 {
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
