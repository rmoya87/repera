package dev.repera.mobile

import android.content.Context

/**
 * Persists the manual strength clock spec for the current authenticated block.
 * The service must be able to rebuild its foreground notification after UI recreation.
 */
internal object ManualClockServiceStore {
    private const val PREFS = "repera.manual.clock.foreground"

    fun save(context: Context, accountId: String, sessionId: String, blockIndex: Int,
             config: ManualBlockTimerConfig) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString("account", accountId)
            .putString("session", sessionId)
            .putInt("index", blockIndex)
            .putInt("work", config.workSeconds.coerceAtLeast(1))
            .putInt("rest", config.restSeconds.coerceAtLeast(0))
            .putInt("rounds", config.rounds.coerceAtLeast(1))
            .apply()
    }

    fun read(context: Context, accountId: String, active: ActiveWorkout): ManualBlockTimerConfig? {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (active.wod != null || prefs.getString("account", null) != accountId ||
            prefs.getString("session", null) != active.id ||
            prefs.getInt("index", -1) != active.index) return null
        val work = prefs.getInt("work", -1)
        val rounds = prefs.getInt("rounds", -1)
        if (work <= 0 || rounds <= 0) return null
        return ManualBlockTimerConfig(work, prefs.getInt("rest", 0).coerceAtLeast(0), rounds)
    }

    fun clear(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().clear().apply()
    }
}
