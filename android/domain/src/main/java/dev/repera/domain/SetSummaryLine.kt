package dev.repera.domain

import java.util.Locale

/**
 * Línea compacta de serie para apariciones y comparativas (port 1:1 de
 * LoggedSet.displaySummaryLine / SessionExercise.prescriptionSummaryLine de
 * Models.swift iOS). NO sustituye el formato detallado de la tarjeta de
 * historial Android: es el formato compacto de ThisSessionCard y afines.
 */
object SetSummaryLine {

    /** Apple a192c38b: las cantidades usan el formato localizado (coma
     *  es_ES), no %g con punto. */
    private fun g(value: Double): String = ReperaNumberFormat.decimal(value)

    private fun clock(seconds: Int): String {
        val m = seconds / 60
        val s = seconds % 60
        return if (s == 0) "$m:00" else String.format(Locale.US, "%d:%02d", m, s)
    }

    private fun unitShortLabel(quantityUnit: String): String = when (quantityUnit) {
        "calories" -> "cal"
        "meters" -> "m"
        else -> quantityUnit
    }

    fun displayLine(
        reps: Int,
        quantityUnit: String? = null,
        weightKg: Double? = null,
        durationSeconds: Int? = null,
        deficitCm: Double? = null
    ): String {
        val unit = quantityUnit ?: "reps"
        if (unit != "reps") {
            val parts = mutableListOf("$reps ${unitShortLabel(unit)}")
            // Apple faa68128: metros/calorias muestran tambien la carga (20 m · 16 kg).
            weightKg?.let { parts.add("${g(it)} kg") }
            if (durationSeconds != null && durationSeconds > 0) parts.add(clock(durationSeconds))
            return parts.joinToString(" · ")
        }
        if (durationSeconds != null && durationSeconds > 0 && weightKg == null && deficitCm == null) {
            // Comba / intervalos: veces + tiempo.
            return "$reps veces · ${clock(durationSeconds)}"
        }
        if (deficitCm != null) {
            return "${g(deficitCm)} cm × $reps"
        }
        val w = weightKg?.let { g(it) } ?: "—"
        var line = "$w×$reps"
        if (durationSeconds != null && durationSeconds > 0) {
            line += " · ${clock(durationSeconds)}"
        }
        // RIR va en columna aparte en el detalle; no repetirlo aquí (iOS).
        return line
    }

    /** prescriptionSummaryLine iOS: primera serie planificada o nombre. */
    fun prescriptionLine(
        targetReps: Int?,
        targetWeightKg: Double?,
        exerciseName: String
    ): String {
        if (targetReps != null) {
            if (targetWeightKg != null && targetWeightKg > 0) {
                // fractionLength(0...1) de iOS: sin decimales si es entera.
                val kg = if (targetWeightKg == Math.floor(targetWeightKg))
                    targetWeightKg.toLong().toString()
                else ReperaNumberFormat.decimal(targetWeightKg, maximumFractionDigits = 1)
                return "$targetReps @ $kg kg"
            }
            if (targetReps > 0) return "$targetReps reps"
        }
        return exerciseName
    }
}
