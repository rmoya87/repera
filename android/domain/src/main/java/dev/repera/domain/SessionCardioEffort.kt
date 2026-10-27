package dev.repera.domain

import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/** Muestra de cardio/Salud asociada a un entreno (port 1:1 de
 *  SessionCardioEffort.swift iOS; sin acoplar Health Connect al dominio). */
data class SessionCardioSample(
    val averageHeartRateBpm: Double? = null,
    val maxHeartRateBpm: Double? = null,
    val heartRateBpmSamples: List<Double> = emptyList(),
    val activeEnergyKcal: Double? = null,
    val durationMinutes: Double? = null,
    /** Health Connect record this sample was read from (null when unknown). */
    val sourceRecordId: String? = null
) {
    val hasUsableSignal: Boolean
        get() = (averageHeartRateBpm ?: 0.0) >= 80 ||
            (maxHeartRateBpm ?: 0.0) >= 100 ||
            heartRateBpmSamples.isNotEmpty() ||
            ((activeEnergyKcal ?: 0.0) > 40 && (durationMinutes ?: 0.0) >= 5)
}

enum class CardioEffortBand(val label: String) {
    EASY("suave"),
    MODERATE("moderado"),
    HARD("exigente"),
    VERY_HARD("muy exigente")
}

/** Ajusta la nota 1–10 según el esfuerzo cardiovascular real (FC / kcal de Salud). */
object SessionCardioEffort {

    data class Adjustment(
        val delta: Int,
        val band: CardioEffortBand,
        val intensityFraction: Double,
        val summary: String
    )

    /** Estima HRmáx fisiológica (sin edad en perfil). Solo usa el pico de
     *  sesión si es alto (≥160): un pico bajo indica poco esfuerzo. */
    fun estimatedMaxHR(observedMax: Double?, average: Double?): Double {
        val fallback = 190.0
        if (observedMax != null && observedMax >= 160) {
            return max(max(observedMax / 0.93, observedMax), fallback * 0.9)
        }
        if (average != null && average >= 150) {
            return max(average / 0.80, fallback)
        }
        return fallback
    }

    fun analyze(sample: SessionCardioSample): Adjustment? {
        if (!sample.hasUsableSignal) return null

        val avg = sample.averageHeartRateBpm
            ?: if (sample.heartRateBpmSamples.isEmpty()) null
               else sample.heartRateBpmSamples.average()
        val peak = sample.maxHeartRateBpm ?: sample.heartRateBpmSamples.maxOrNull()

        val hrMax = estimatedMaxHR(peak, avg)
        var intensity = avg?.let { it / hrMax } ?: 0.0

        // Tiempo en zona vigorosa (≥77 % HRmáx, CDC) refuerza la lectura.
        if (sample.heartRateBpmSamples.isNotEmpty()) {
            val vigorousCut = hrMax * 0.77
            val vigorous = sample.heartRateBpmSamples.count { it >= vigorousCut }
            val fraction = vigorous.toDouble() / sample.heartRateBpmSamples.size
            if (fraction >= 0.35) {
                intensity = max(intensity, 0.78 + min(0.15, fraction * 0.2))
            } else if (fraction >= 0.15) {
                intensity = max(intensity, 0.70)
            }
        }

        // Señal secundaria: densidad de kcal (si no hay FC clara).
        val kcal = sample.activeEnergyKcal
        val minutes = sample.durationMinutes
        if (intensity < 0.5 && kcal != null && kcal > 40 &&
            minutes != null && minutes >= 5) {
            val perMin = kcal / minutes
            intensity = when {
                perMin >= 12 -> max(intensity, 0.80)
                perMin >= 8 -> max(intensity, 0.70)
                perMin >= 5 -> max(intensity, 0.58)
                else -> max(intensity, 0.45)
            }
        }

        val band = when {
            intensity >= 0.85 -> CardioEffortBand.VERY_HARD
            intensity >= 0.75 -> CardioEffortBand.HARD
            intensity >= 0.60 -> CardioEffortBand.MODERATE
            else -> CardioEffortBand.EASY
        }

        val summary: String = if (avg != null) {
            val bpm = avg.roundToInt()
            when (band) {
                CardioEffortBand.VERY_HARD -> "FC media $bpm lpm: esfuerzo muy exigente."
                CardioEffortBand.HARD -> "FC media $bpm lpm: buen esfuerzo."
                CardioEffortBand.MODERATE -> "FC media $bpm lpm: esfuerzo moderado."
                CardioEffortBand.EASY -> "FC media $bpm lpm: el ritmo cardíaco fue más suave."
            }
        } else if (kcal != null && minutes != null && minutes > 0) {
            val perMin = (kcal / minutes).roundToInt()
            "Unas ${kcal.roundToInt()} kcal ($perMin/min): esfuerzo ${band.label}."
        } else {
            "Esfuerzo ${band.label} según Salud."
        }

        return Adjustment(delta = 0, band = band,
            intensityFraction = intensity, summary = summary)
    }

    /** Delta −2…+2 según si el esfuerzo confirma o corrige la nota de rendimiento. */
    fun scoreDelta(baseScore: Int, adjustment: Adjustment): Int {
        return when (adjustment.band) {
            CardioEffortBand.EASY -> when {
                baseScore >= 8 -> -2
                baseScore >= 6 -> -1
                else -> 0
            }
            CardioEffortBand.MODERATE -> 0
            CardioEffortBand.HARD -> when {
                baseScore <= 5 -> 1
                baseScore <= 7 -> 1
                else -> 0
            }
            CardioEffortBand.VERY_HARD -> when {
                baseScore <= 5 -> 2
                baseScore <= 7 -> 1
                else -> 0
            }
        }
    }

    fun apply(review: SessionReview, sample: SessionCardioSample?): SessionReview {
        if (sample == null) return review
        val analyzed = analyze(sample) ?: return review
        val delta = scoreDelta(review.overallScore, analyzed)
        val score = min(10, max(1, review.overallScore + delta))

        val existing = review.vsStandardSummary
        val standard: String? = if (!existing.isNullOrEmpty()) {
            if (!existing.contains("FC media") && !existing.contains("kcal")) {
                "$existing ${analyzed.summary}"
            } else existing
        } else analyzed.summary

        val keep = review.keepTips.toMutableList()
        val improve = review.improveTips.toMutableList()
        when (analyzed.band) {
            CardioEffortBand.VERY_HARD, CardioEffortBand.HARD ->
                if (delta > 0) {
                    keep.add("La FC confirma que te exigiste de verdad.")
                } else if (keep.none { it.contains("FC") || it.contains("esfuerzo") }) {
                    keep.add("Esfuerzo cardíaco ${analyzed.band.label}: buen trabajo.")
                }
            CardioEffortBand.MODERATE -> Unit
            CardioEffortBand.EASY ->
                if (delta < 0) {
                    improve.add("La FC fue más suave: puedes subir un poco la intensidad.")
                }
        }

        val headline: String = run {
            val level = review.level
            if (level != null) {
                val name = review.headline.substringBefore(':')
                    .ifBlank { "Entreno" }
                "$name: ${level.label} · $score/10"
            } else {
                review.headline.replace("${review.overallScore}/10", "$score/10")
            }
        }

        return review.copy(
            overallScore = score,
            headline = headline,
            vsStandardSummary = standard,
            keepTips = keep.take(3),
            improveTips = improve.take(3)
        )
    }
}
