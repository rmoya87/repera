package dev.repera.domain

/** Esfuerzo por serie (RIR/RPE). Port 1:1 de Effort.swift (iOS). */
object Effort {
    const val hardRIR: Double = 2.0

    /** Nombre corto de la unidad de esfuerzo (EffortUnit.displayName en Apple). */
    fun displayName(unit: String): String = if (unit == "rpe") "RPE" else "RIR"

    fun toRIR(value: Double, unit: String): Double = when (unit) {
        "rpe" -> maxOf(0.0, 10.0 - value)
        else -> value
    }

    fun fromRIR(rir: Double, unit: String): Double = when (unit) {
        "rpe" -> maxOf(0.0, 10.0 - rir)
        else -> rir
    }

    /** Etiqueta localizada "RIR 2" / "RPE 8,5" (port de Effort.label, Apple
     *  b8cca90a: formato es_ES, no %g con punto). */
    fun label(rir: Double?, unit: String): String? {
        if (rir == null) return null
        val display = fromRIR(rir, unit)
        return displayName(unit) + " " + ReperaNumberFormat.decimal(display)
    }

    fun isHard(rir: Double?): Boolean = rir != null && rir <= hardRIR

    fun plainLanguage(rir: Double): String = when {
        rir <= 0 -> "Fallo / sin reps en reserva"
        rir <= 1 -> "Muy duro (1 en reserva)"
        rir <= 2 -> "Duro (cerca del fallo)"
        rir <= 4 -> "Moderado"
        else -> "Holgado"
    }
}
