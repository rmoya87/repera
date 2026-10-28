package dev.repera.domain

import kotlin.math.max
import kotlin.math.roundToInt

/**
 * Locución de cada kilómetro GPS confirmado (paridad
 * `KilometerVoiceAnnouncement` iOS / origin/main).
 * Se calcula en el instante del cruce; no depende de UI ni de restauraciones.
 */
object KilometerVoiceAnnouncement {
    fun message(kilometer: Int, splitSeconds: Double, elapsedSeconds: Double): String? {
        if (kilometer <= 0 ||
            !splitSeconds.isFinite() || splitSeconds <= 0.0 ||
            !elapsedSeconds.isFinite() || elapsedSeconds <= 0.0 ||
            elapsedSeconds < splitSeconds
        ) {
            return null
        }
        val segmentSpeed = 3600.0 / splitSeconds
        if (!segmentSpeed.isFinite()) return null
        val sentences = mutableListOf(
            "Kilómetro $kilometer completado.",
            "Tiempo del tramo: ${spokenDuration(splitSeconds)}.",
            "Velocidad media del tramo: ${spokenSpeed(segmentSpeed)} kilómetros por hora."
        )
        if (kilometer > 1) {
            val overall = kilometer * 3600.0 / elapsedSeconds
            if (overall.isFinite()) {
                sentences.add(
                    "Velocidad media desde el inicio: ${spokenSpeed(overall)} kilómetros por hora."
                )
            }
        }
        return sentences.joinToString(" ")
    }

    private fun spokenSpeed(kmh: Double): String =
        "%.1f".format(java.util.Locale("es", "ES"), kmh)

    private fun spokenDuration(duration: Double): String {
        val rounded = max(1, duration.roundToInt())
        val hours = rounded / 3600
        val minutes = (rounded % 3600) / 60
        val seconds = rounded % 60
        val parts = mutableListOf<String>()
        if (hours > 0) parts.add("$hours hora${if (hours == 1) "" else "s"}")
        if (minutes > 0) parts.add("$minutes minuto${if (minutes == 1) "" else "s"}")
        if (seconds > 0 || parts.isEmpty()) {
            parts.add("$seconds segundo${if (seconds == 1) "" else "s"}")
        }
        return when (parts.size) {
            1 -> parts[0]
            else -> parts.dropLast(1).joinToString(", ") + " y " + parts.last()
        }
    }
}
