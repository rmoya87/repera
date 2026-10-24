package dev.repera.domain

import kotlin.math.max
import kotlin.math.roundToInt

/** Sugiere kg a partir de % de 1RM (pizarra `#70%` / notas) y e1RM del historial.
 *  Port 1:1 de LoadSuggestion.swift (iOS). La aplicación a bloques
 *  (applyPercentLoads) vive en mobile, que es donde están los modelos JSON. */
object LoadSuggestion {

    data class Percent(val value: Double, val isMinimum: Boolean)

    /** Extrae porcentaje (70, 80…) desde notas u OCR (`#70%`, `#>80%`, `70%`). */
    fun percentOfOneRM(text: String?): Percent? {
        if (text.isNullOrEmpty()) return null
        val match = Regex("[#@]?\\s*(>?)(\\d{1,3})\\s*%").find(text) ?: return null
        val isMin = match.groupValues[1] == ">"
        val pct = match.groupValues[2].toDoubleOrNull() ?: return null
        if (pct <= 0 || pct > 100) return null
        return Percent(pct, isMin)
    }

    fun weightKg(oneRM: Double, percent: Double, roundTo: Double = 2.5): Double {
        if (oneRM <= 0 || percent <= 0) return 0.0
        val raw = oneRM * (percent / 100)
        val step = max(roundTo, 0.5)
        return (raw / step).roundToInt() * step
    }

    /** Peso para `reps` dejando `targetRir` en reserva (Epley inverso:
     *  RTF = reps + RIR). Ejemplo: 8 reps @ RIR 2 → carga ≈ 1RM / (1 + 10/30). */
    fun weightKg(oneRM: Double, reps: Int, targetRir: Double, roundTo: Double = 2.5): Double {
        if (oneRM <= 0 || reps <= 0) return 0.0
        val rir = max(0.0, targetRir)
        val repsToFailure = reps + rir
        val raw = oneRM / (1 + repsToFailure / 30.0)
        val step = max(roundTo, 0.5)
        return (raw / step).roundToInt() * step
    }

    /** Si no hay 1RM, estima desde la última serie de trabajo (mismo Epley). */
    fun weightKgFromLastSet(
        lastWeightKg: Double,
        lastReps: Int,
        lastRir: Double?,
        targetReps: Int,
        targetRir: Double,
        roundTo: Double = 2.5
    ): Double {
        if (lastWeightKg <= 0 || lastReps <= 0 || targetReps <= 0) return 0.0
        val lastRTF = lastReps + max(0.0, lastRir ?: 2.0)
        val oneRM = lastWeightKg * (1 + lastRTF / 30.0)
        return weightKg(oneRM, targetReps, targetRir, roundTo)
    }
}
