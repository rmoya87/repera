package dev.repera.domain

/**
 * Formats Wear finished-session duration without copying the Apple Watch bug
 * that renders total seconds as `%02d:%02d` (e.g. «5865:52»).
 *
 * Prefer a measured duration when present; otherwise derive from
 * startedAt/finishedAt and clamp to a sane session window.
 */
object WearSessionDuration {
    /** Hard ceiling: 12 h. Stale startedAt must never produce multi-day clocks. */
    const val MAX_SECONDS = 12 * 60 * 60

    fun resolveSeconds(
        startedAtIso: String?,
        finishedAtIso: String?,
        measuredSeconds: Double? = null
    ): Int {
        measuredSeconds?.takeIf { it.isFinite() && it >= 0 }?.let {
            return it.toInt().coerceIn(0, MAX_SECONDS)
        }
        if (startedAtIso.isNullOrBlank() || finishedAtIso.isNullOrBlank()) return 0
        return runCatching {
            val start = java.time.Instant.parse(startedAtIso).toEpochMilli()
            val end = java.time.Instant.parse(finishedAtIso).toEpochMilli()
            ((end - start) / 1000L).toInt().coerceIn(0, MAX_SECONDS)
        }.getOrDefault(0)
    }

    /** h:mm:ss if ≥1 h, otherwise mm:ss (zero-padded minutes). */
    fun format(seconds: Int): String =
        LiveSportHistory.formatDuration(seconds.coerceAtLeast(0).toDouble())
}
