package dev.repera.domain

import kotlin.math.max
import kotlin.math.roundToInt

/** Frase hablada del parcial por kilómetro (Apple LiveActivityRecorder, live main 26 Oct). */
object LiveSpokenPhrases {
    fun kilometer(kilometer: Int, splitSeconds: Double, displaysSpeed: Boolean): String {
        if (displaysSpeed) {
            val speed = "%.1f".format(java.util.Locale.ROOT, 3600.0 / splitSeconds).replace('.', ',')
            return "Kilómetro $kilometer completado. Has ido a $speed kilómetros por hora, de media."
        }
        val seconds = max(1, splitSeconds.roundToInt())
        val minutes = seconds / 60
        val remaining = seconds % 60
        val time = when {
            minutes == 0 -> "$remaining segundo${if (remaining == 1) "" else "s"}"
            remaining == 0 -> "$minutes minuto${if (minutes == 1) "" else "s"}"
            else -> "$minutes minuto${if (minutes == 1) "" else "s"} y $remaining segundos"
        }
        return "Kilómetro $kilometer completado. Tu tiempo ha sido de $time."
    }
    /** Apple live main: "Ahora, <dir>." within 20 m, otherwise "En unos N metros, <dir>.". */
    fun turn(meters: Int, direction: String): String =
        if (meters <= 20) "Ahora, $direction." else "En unos $meters metros, $direction."
}
