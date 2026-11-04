package dev.repera.wear

/** Lands just after the boundary so the label never repeats or skips a second. */
internal const val WEAR_TICK_SLACK_MS = 8L

/** Count-up clocks (elapsed, WOD): next whole-second change of [elapsedMs]. */
internal fun wearMsUntilNextSecond(elapsedMs: Long): Long =
    1_000L - Math.floorMod(elapsedMs, 1_000L) + WEAR_TICK_SLACK_MS

/** Countdowns shown with ceil (RestCountdown): next change of the visible second. */
internal fun wearMsUntilCountdownChange(remainingMs: Long): Long {
    if (remainingMs <= 0L) return 1_000L
    val rest = remainingMs % 1_000L
    return (if (rest == 0L) 1_000L else rest) + WEAR_TICK_SLACK_MS
}
