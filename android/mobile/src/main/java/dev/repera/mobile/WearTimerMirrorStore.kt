package dev.repera.mobile

import android.content.Context
import org.json.JSONObject
import java.util.UUID

/**
 * Último estado de temporizador enviado por el Wear emparejado.
 * El estado es de UI, no un entreno: solo /timer-save crea una sesión histórica.
 * Aislamiento por cuenta y marca temporal para evitar estados huérfanos.
 */
internal class WearTimerMirrorStore(context: Context, owner: String) {
    private val prefs = context.getSharedPreferences(
        "repera.wear.timer.mirror.$owner", Context.MODE_PRIVATE
    )

    fun accept(update: JSONObject): Boolean {
        val id = update.optString("id")
        val phase = update.optString("phase")
        val stamp = update.optLong("updatedAtMillis", 0L)
        val now = System.currentTimeMillis()
        if (runCatching { UUID.fromString(id) }.isFailure ||
            phase !in setOf("running", "paused", "finished", "discarded") ||
            stamp <= 0 || stamp > now + 60_000L ||
            now - stamp > 12 * 60 * 60_000L ||
            update.optInt("configuredSeconds", 0) !in 1..86400 ||
            update.optInt("elapsedSeconds", -1) !in 0..86400) return false

        val old = last()
        // No permitir que un estado viejo reviva un temporizador finalizado.
        if (old != null && stamp < old.optLong("updatedAtMillis", 0L)) return false
        // Persistir también las marcas terminales para descartar reenvíos antiguos.
        prefs.edit().putString("snapshot", update.toString()).apply()
        return true
    }

    fun last(): JSONObject? = prefs.getString("snapshot", null)?.let {
        runCatching { JSONObject(it) }.getOrNull()
    }

    fun current(now: Long = System.currentTimeMillis()): JSONObject? {
        val value = last() ?: return null
        if (value.optString("phase") !in setOf("running", "paused")) return null
        if (now - value.optLong("updatedAtMillis") !in 0..60_000L) return null
        return value
    }

    fun clear() { prefs.edit().remove("snapshot").apply() }
}
