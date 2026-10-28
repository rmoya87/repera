package dev.repera.domain

import org.json.JSONObject

/**
 * Datos reales de un temporizador libre guardado, sin métricas fabricadas de Salud.
 * Paridad TimerCompletionDetails (Models.swift / main).
 */
data class TimerCompletionDetails(
    val modeRaw: String,
    val configuredSeconds: Int,
    val rounds: Int,
    val workSeconds: Int,
    val restSeconds: Int,
    val countdownSeconds: Int
) {
    init {
        require(configuredSeconds >= 1)
        require(rounds >= 1)
        require(workSeconds >= 0)
        require(restSeconds >= 0)
        require(countdownSeconds >= 0)
    }

    val modeTitle: String
        get() = when (modeRaw) {
            "up" -> "Arriba"
            "down" -> "Abajo"
            "intervals" -> "Intervalos"
            else -> "Temporizador"
        }

    /** Minutos de lista / stats: duración configurada, no reloj de pared. */
    val displayDurationMinutes: Double
        get() = configuredSeconds / 60.0

    fun toJson(): JSONObject = JSONObject()
        .put("modeRaw", modeRaw)
        .put("configuredSeconds", configuredSeconds)
        .put("rounds", rounds)
        .put("workSeconds", workSeconds)
        .put("restSeconds", restSeconds)
        .put("countdownSeconds", countdownSeconds)

    companion object {
        fun fromJson(raw: JSONObject?): TimerCompletionDetails? {
            if (raw == null) return null
            val mode = raw.optString("modeRaw").ifBlank { return null }
            val configured = raw.optInt("configuredSeconds", 0)
            if (configured < 1) return null
            return TimerCompletionDetails(
                modeRaw = mode,
                configuredSeconds = configured,
                rounds = raw.optInt("rounds", 1).coerceAtLeast(1),
                workSeconds = raw.optInt("workSeconds", 0).coerceAtLeast(0),
                restSeconds = raw.optInt("restSeconds", 0).coerceAtLeast(0),
                countdownSeconds = raw.optInt("countdownSeconds", 0).coerceAtLeast(0)
            )
        }

        /** Extrae timerDetails de una sesión JSON; null en históricos sin campo. */
        fun fromSession(session: JSONObject): TimerCompletionDetails? =
            fromJson(session.optJSONObject("timerDetails"))
    }
}
