package dev.repera.mobile

import android.content.Context

/**
 * Formato elegido en Play (EMOM/Tabata/…) mientras el flush async puede
 * fallar o llegar tarde. Sobrevive al dispose al abrir el reloj; al volver
 * a Play se reaplica y se vuelve a encolar el persist.
 */
internal data class PlayBlockFormatSnapshot(
    val format: String,
    val workSeconds: Int = 20,
    val restSeconds: Int = 10,
    val rounds: Int = 8,
    val intervalSeconds: Int = 60,
    val timeCapMinutes: Int = 12,
)

internal object PlayBlockFormatStore {
    private const val PREFS = "repera.play.block.format"

    fun save(
        context: Context,
        accountId: String,
        sessionId: String,
        blockKey: String,
        snapshot: PlayBlockFormatSnapshot,
    ) {
        if (snapshot.format.isBlank() || snapshot.format == "strength") {
            clearBlock(context, accountId, sessionId, blockKey)
            return
        }
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(key(accountId, sessionId, blockKey, "format"), snapshot.format)
            .putInt(key(accountId, sessionId, blockKey, "work"), snapshot.workSeconds)
            .putInt(key(accountId, sessionId, blockKey, "rest"), snapshot.restSeconds)
            .putInt(key(accountId, sessionId, blockKey, "rounds"), snapshot.rounds)
            .putInt(key(accountId, sessionId, blockKey, "interval"), snapshot.intervalSeconds)
            .putInt(key(accountId, sessionId, blockKey, "cap"), snapshot.timeCapMinutes)
            .apply()
    }

    fun read(
        context: Context,
        accountId: String,
        sessionId: String,
        blockKey: String,
    ): PlayBlockFormatSnapshot? {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val format = prefs.getString(key(accountId, sessionId, blockKey, "format"), null)
            ?.takeIf { it.isNotBlank() && it != "strength" }
            ?: return null
        return PlayBlockFormatSnapshot(
            format = format,
            workSeconds = prefs.getInt(key(accountId, sessionId, blockKey, "work"), 20)
                .coerceAtLeast(1),
            restSeconds = prefs.getInt(key(accountId, sessionId, blockKey, "rest"), 10)
                .coerceAtLeast(0),
            rounds = prefs.getInt(key(accountId, sessionId, blockKey, "rounds"), 8)
                .coerceAtLeast(1),
            intervalSeconds = prefs.getInt(key(accountId, sessionId, blockKey, "interval"), 60)
                .coerceAtLeast(15),
            timeCapMinutes = prefs.getInt(key(accountId, sessionId, blockKey, "cap"), 12)
                .coerceAtLeast(1),
        )
    }

    fun clearSession(context: Context, accountId: String, sessionId: String) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val prefix = "$accountId|$sessionId|"
        val editor = prefs.edit()
        prefs.all.keys.filter { it.startsWith(prefix) }.forEach { editor.remove(it) }
        editor.apply()
    }

    private fun clearBlock(
        context: Context,
        accountId: String,
        sessionId: String,
        blockKey: String,
    ) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .remove(key(accountId, sessionId, blockKey, "format"))
            .remove(key(accountId, sessionId, blockKey, "work"))
            .remove(key(accountId, sessionId, blockKey, "rest"))
            .remove(key(accountId, sessionId, blockKey, "rounds"))
            .remove(key(accountId, sessionId, blockKey, "interval"))
            .remove(key(accountId, sessionId, blockKey, "cap"))
            .apply()
    }

    private fun key(accountId: String, sessionId: String, blockKey: String, field: String) =
        "$accountId|$sessionId|$blockKey|$field"
}
