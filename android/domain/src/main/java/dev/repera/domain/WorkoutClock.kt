package dev.repera.domain

/**
 * Faithful port of ReperaDomain/WorkoutClockMath.swift.
 * Repaints never represent a fixed one-second tick.
 */
data class ClockStep(
    val advancedSeconds: Int,
    val sessionElapsed: Int,
    val blockElapsed: Int,
    val restRemaining: Int,
    val reachedTimeCap: Boolean
)

object WorkoutClock {
    fun advance(
        previousMillis: Long,
        nowMillis: Long,
        sessionElapsed: Int,
        blockElapsed: Int,
        restRemaining: Int,
        isCounting: Boolean,
        isWod: Boolean,
        timeCapSeconds: Int
    ): ClockStep {
        val delta = ((nowMillis - previousMillis).coerceAtLeast(0L) / 1000L)
            .coerceAtMost(Int.MAX_VALUE.toLong()).toInt()
        val rest = restRemaining.coerceAtLeast(0)
        val consumed = minOf(rest, delta)
        val remaining = rest - consumed
        val increment = if (isWod) delta else delta - consumed
        val nextBlock = if (isCounting) {
            val elapsed = blockElapsed.coerceAtLeast(0).toLong() + increment
            if (isWod && timeCapSeconds > 0) {
                minOf(elapsed, timeCapSeconds.toLong()).toInt()
            } else elapsed.coerceAtMost(Int.MAX_VALUE.toLong()).toInt()
        } else blockElapsed.coerceAtLeast(0)
        return ClockStep(
            advancedSeconds = delta,
            sessionElapsed = (sessionElapsed.coerceAtLeast(0).toLong() + delta)
                .coerceAtMost(Int.MAX_VALUE.toLong()).toInt(),
            blockElapsed = nextBlock,
            restRemaining = remaining,
            reachedTimeCap = isCounting && isWod && timeCapSeconds > 0
                && nextBlock >= timeCapSeconds
        )
    }
}
