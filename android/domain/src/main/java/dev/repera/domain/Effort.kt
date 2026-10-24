package dev.repera.domain

/** Esfuerzo por serie (RIR/RPE). Port 1:1 de Effort.swift (iOS). */
object Effort {
    const val hardRIR: Double = 2.0

    fun toRIR(value: Double, unit: String): Double = when (unit) {
        "rpe" -> maxOf(0.0, 10.0 - value)
        else -> value
    }

    fun fromRIR(rir: Double, unit: String): Double = when (unit) {
        "rpe" -> maxOf(0.0, 10.0 - rir)
        else -> rir
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
