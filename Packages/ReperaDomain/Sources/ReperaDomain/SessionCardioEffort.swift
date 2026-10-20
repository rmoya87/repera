import Foundation

/// Muestra de cardio/Salud asociada a un entreno (sin acoplar HealthKit).
public struct SessionCardioSample: Sendable, Equatable {
    public var averageHeartRateBpm: Double?
    public var maxHeartRateBpm: Double?
    /// Puntos FC opcionales para estimar tiempo en zona vigorosa.
    public var heartRateBpmSamples: [Double]
    public var activeEnergyKcal: Double?
    public var durationMinutes: Double?

    public init(
        averageHeartRateBpm: Double? = nil,
        maxHeartRateBpm: Double? = nil,
        heartRateBpmSamples: [Double] = [],
        activeEnergyKcal: Double? = nil,
        durationMinutes: Double? = nil
    ) {
        self.averageHeartRateBpm = averageHeartRateBpm
        self.maxHeartRateBpm = maxHeartRateBpm
        self.heartRateBpmSamples = heartRateBpmSamples
        self.activeEnergyKcal = activeEnergyKcal
        self.durationMinutes = durationMinutes
    }

    public var hasUsableSignal: Bool {
        (averageHeartRateBpm ?? 0) >= 80
            || (maxHeartRateBpm ?? 0) >= 100
            || !heartRateBpmSamples.isEmpty
            || ((activeEnergyKcal ?? 0) > 40 && (durationMinutes ?? 0) >= 5)
    }
}

public enum CardioEffortBand: String, Sendable, Equatable {
    case easy
    case moderate
    case hard
    case veryHard

    public var label: String {
        switch self {
        case .easy: return "suave"
        case .moderate: return "moderado"
        case .hard: return "exigente"
        case .veryHard: return "muy exigente"
        }
    }
}

/// Ajusta la nota 1–10 según el esfuerzo cardiovascular real (FC / kcal de Salud).
public enum SessionCardioEffort {
    public struct Adjustment: Sendable, Equatable {
        public var delta: Int
        public var band: CardioEffortBand
        public var intensityFraction: Double
        public var summary: String
    }

    /// Estima HRmáx fisiológica (sin edad en perfil).
    /// Solo usa el pico de sesión si es alto (≥160): un pico bajo indica poco esfuerzo, no un HRmáx bajo.
    public static func estimatedMaxHR(observedMax: Double?, average: Double?) -> Double {
        let fallback = 190.0
        if let peak = observedMax, peak >= 160 {
            // Pico alto → plausible ~90–95 % del máximo usable.
            return max(peak / 0.93, peak, fallback * 0.9)
        }
        // Media/pico moderados: no invertir; usar ancla estándar.
        if let avg = average, avg >= 150 {
            return max(avg / 0.80, fallback)
        }
        return fallback
    }

    public static func analyze(_ sample: SessionCardioSample) -> Adjustment? {
        guard sample.hasUsableSignal else { return nil }

        let avg = sample.averageHeartRateBpm
            ?? (sample.heartRateBpmSamples.isEmpty
                ? nil
                : sample.heartRateBpmSamples.reduce(0, +) / Double(sample.heartRateBpmSamples.count))
        let peak = sample.maxHeartRateBpm
            ?? sample.heartRateBpmSamples.max()

        let hrMax = estimatedMaxHR(observedMax: peak, average: avg)
        var intensity = (avg.map { $0 / hrMax } ?? 0)

        // Tiempo en zona vigorosa (≥77 % HRmáx, CDC) refuerza la lectura.
        if !sample.heartRateBpmSamples.isEmpty {
            let vigorousCut = hrMax * 0.77
            let vigorous = sample.heartRateBpmSamples.filter { $0 >= vigorousCut }.count
            let fraction = Double(vigorous) / Double(sample.heartRateBpmSamples.count)
            if fraction >= 0.35 {
                intensity = max(intensity, 0.78 + min(0.15, fraction * 0.2))
            } else if fraction >= 0.15 {
                intensity = max(intensity, 0.70)
            }
        }

        // Señal secundaria: densidad de kcal (si no hay FC clara).
        if intensity < 0.5,
           let kcal = sample.activeEnergyKcal, kcal > 40,
           let minutes = sample.durationMinutes, minutes >= 5 {
            let perMin = kcal / minutes
            if perMin >= 12 { intensity = max(intensity, 0.80) }
            else if perMin >= 8 { intensity = max(intensity, 0.70) }
            else if perMin >= 5 { intensity = max(intensity, 0.58) }
            else { intensity = max(intensity, 0.45) }
        }

        let band: CardioEffortBand
        if intensity >= 0.85 { band = .veryHard }
        else if intensity >= 0.75 { band = .hard }
        else if intensity >= 0.60 { band = .moderate }
        else { band = .easy }

        let summary: String = {
            if let avg {
                let bpm = Int(avg.rounded())
                switch band {
                case .veryHard:
                    return "FC media \(bpm) lpm: esfuerzo muy exigente."
                case .hard:
                    return "FC media \(bpm) lpm: buen esfuerzo."
                case .moderate:
                    return "FC media \(bpm) lpm: esfuerzo moderado."
                case .easy:
                    return "FC media \(bpm) lpm: el ritmo cardíaco fue más suave."
                }
            }
            if let kcal = sample.activeEnergyKcal, let minutes = sample.durationMinutes, minutes > 0 {
                let perMin = Int((kcal / minutes).rounded())
                return "Unas \(Int(kcal.rounded())) kcal (\(perMin)/min): esfuerzo \(band.label)."
            }
            return "Esfuerzo \(band.label) según Salud."
        }()

        return Adjustment(delta: 0, band: band, intensityFraction: intensity, summary: summary)
    }

    /// Delta −2…+2 según si el esfuerzo confirma o corrige la nota de rendimiento.
    public static func scoreDelta(baseScore: Int, adjustment: Adjustment) -> Int {
        let s = baseScore
        switch adjustment.band {
        case .easy:
            // Nota alta con FC suave → posiblemente sobrevalorada.
            if s >= 8 { return -2 }
            if s >= 6 { return -1 }
            return 0
        case .moderate:
            return 0
        case .hard:
            // Esfuerzo alto sostiene o sube notas medias.
            if s <= 5 { return 1 }
            if s <= 7 { return 1 }
            return 0
        case .veryHard:
            if s <= 5 { return 2 }
            if s <= 7 { return 1 }
            return 0
        }
    }

    public static func apply(to review: SessionReview, sample: SessionCardioSample?) -> SessionReview {
        guard let sample, let analyzed = analyze(sample) else { return review }
        let delta = scoreDelta(baseScore: review.overallScore, adjustment: analyzed)
        let score = min(10, max(1, review.overallScore + delta))

        var standard = review.vsStandardSummary
        if let existing = standard, !existing.isEmpty {
            if !existing.contains("FC media") && !existing.contains("kcal") {
                standard = "\(existing) \(analyzed.summary)"
            }
        } else {
            standard = analyzed.summary
        }

        var keep = review.keepTips
        var improve = review.improveTips
        switch analyzed.band {
        case .veryHard, .hard:
            if delta > 0 {
                keep.append("La FC confirma que te exigiste de verdad.")
            } else if !keep.contains(where: { $0.contains("FC") || $0.contains("esfuerzo") }) {
                keep.append("Esfuerzo cardíaco \(analyzed.band.label): buen trabajo.")
            }
        case .moderate:
            break
        case .easy:
            if delta < 0 {
                improve.append("La FC fue más suave: puedes subir un poco la intensidad.")
            }
        }

        let headline: String = {
            if let level = review.level {
                let name = review.headline.split(separator: ":").first.map(String.init) ?? "Entreno"
                return "\(name): \(level.label) · \(score)/10"
            }
            return review.headline.replacingOccurrences(
                of: "\(review.overallScore)/10",
                with: "\(score)/10"
            )
        }()

        return SessionReview(
            overallScore: score,
            level: review.level,
            headline: headline,
            vsHistorySummary: review.vsHistorySummary,
            vsStandardSummary: standard,
            keepTips: Array(keep.prefix(3)),
            improveTips: Array(improve.prefix(3)),
            movements: review.movements,
            wodTemplateId: review.wodTemplateId,
            scoreBasis: review.scoreBasis
        )
    }
}
