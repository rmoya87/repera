package dev.repera.mobile

import android.content.Context
import android.os.SystemClock
import java.security.MessageDigest

/** Monotonic, persisted Android clock, isolated per Google user and active WOD block. */
data class WodTimerState(
    val elapsedMillis: Long,
    val running: Boolean,
    /** Apple 39a3f7f2 pendingEnd: fin pendiente de confirmar. Se congela al
     *  terminar el reloj ("Terminar"), sobrevive a la muerte del proceso y lo
     *  consume una unica vez el editor de resultado (For Time). */
    val pendingEndReason: String? = null,
    val pendingElapsedSeconds: Int = 0
) {
    val elapsedSeconds: Int get() = (elapsedMillis / 1000L).coerceAtMost(Int.MAX_VALUE.toLong()).toInt()
}

internal class WodTimerStore(
    context: Context,
    googleAccountId: String,
    private val uptimeMillis: () -> Long = { SystemClock.elapsedRealtime() }
) {
    private val userKey = MessageDigest.getInstance("SHA-256")
        .digest(googleAccountId.toByteArray(Charsets.UTF_8))
        .joinToString("") { "%02x".format(it) }
    private val preferences = context.getSharedPreferences("repera.wod.timer.$userKey", Context.MODE_PRIVATE)

    /**
     * Apple 48060202/00fee1b4: el reloj solo se restaura para la sesion Y el
     * bloque originales. Un cambio de bloque justo antes de morir el proceso
     * no debe restaurar un reloj ajeno sobre el ejercicio actual: la clave
     * sesion:indice es posicional, asi que se valida ademas la identidad
     * estable del bloque (blockId). null = sin validacion (fuente antigua).
     * El pendingEnd sigue la misma guarda: nunca se presenta en otro bloque.
     */
    @Synchronized fun read(sessionId: String, index: Int, blockId: String? = null): WodTimerState {
        val key = "$sessionId:$index"
        if (preferences.getString("key", null) != key) return WodTimerState(0L, false)
        val storedBlock = preferences.getString("blockId", null)
        if (blockId != null && storedBlock != null && storedBlock != blockId)
            return WodTimerState(0L, false)
        val elapsed = preferences.getLong("elapsedMs", 0L).coerceAtLeast(0)
        val running = preferences.getBoolean("running", false)
        val pendingReason = preferences.getString("pendingEndReason", null)
        val pendingSeconds = preferences.getInt("pendingElapsedSeconds", 0).coerceAtLeast(0)
        if (!running) return WodTimerState(elapsed, false, pendingReason, pendingSeconds)
        val since = preferences.getLong("startAtUptimeMs", 0L)
        val now = uptimeMillis()
        if (now < since || since <= 0L) {
            // A reboot invalidates elapsedRealtime anchors: pause, never invent elapsed work.
            preferences.edit().putBoolean("running", false).apply()
            return WodTimerState(elapsed, false, pendingReason, pendingSeconds)
        }
        return WodTimerState((elapsed + (now - since)).coerceAtLeast(0L), true,
            pendingReason, pendingSeconds)
    }

    @Synchronized fun update(sessionId: String, index: Int, action: String, blockId: String? = null): WodTimerState {
        require(action in setOf("start", "pause", "reset", "finish"))
        val key = "$sessionId:$index"
        val current = read(sessionId, index)
        val edit = preferences.edit().putString("key", key)
        if (blockId != null) edit.putString("blockId", blockId)
        when (action) {
            "reset" -> edit.putLong("elapsedMs", 0).putBoolean("running", false)
                .putLong("startAtUptimeMs", 0)
                .remove("pendingEndReason").remove("pendingElapsedSeconds")
            "pause" -> edit.putLong("elapsedMs", current.elapsedMillis)
                .putBoolean("running", false).putLong("startAtUptimeMs", 0)
            // Reanudar abandona el fin pendiente: el atleta eligio seguir.
            "start" -> if (!current.running) edit
                .putLong("elapsedMs", current.elapsedMillis)
                .putBoolean("running", true)
                .putLong("startAtUptimeMs", uptimeMillis().coerceAtLeast(1))
                .remove("pendingEndReason").remove("pendingElapsedSeconds")
            // Apple 39a3f7f2 finishByUser (userFinished): congela el elapsed
            // REAL en el instante de terminar y lo persiste; el editor For
            // Time lo consume una vez aunque el proceso muera antes.
            "finish" -> edit.putLong("elapsedMs", current.elapsedMillis)
                .putBoolean("running", false).putLong("startAtUptimeMs", 0)
                .putString("pendingEndReason", "userFinished")
                .putInt("pendingElapsedSeconds", current.elapsedSeconds)
        }
        check(edit.commit()) { "No se pudo guardar el cronómetro" }
        return read(sessionId, index)
    }

    /** Consume una unica vez el fin pendiente de ESTE bloque (Apple
     *  consumePendingEnd): devuelve (reason, elapsed) y lo borra. */
    @Synchronized fun consumePendingEnd(sessionId: String, index: Int, blockId: String? = null): Pair<String, Int>? {
        val state = read(sessionId, index, blockId)
        val reason = state.pendingEndReason ?: return null
        val elapsed = state.pendingElapsedSeconds
        preferences.edit().remove("pendingEndReason").remove("pendingElapsedSeconds").apply()
        return reason to elapsed
    }
}
