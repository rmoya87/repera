package dev.repera.domain

/** Motion counts repetitions, never elapsed time, machine quantity or loaded metres. */
object WatchQuantityPolicy {
    fun usesMotion(mode: String): Boolean = mode in setOf("strength", "repsOnly", "hspuDeficit")
    fun adjusted(current: Int, delta: Int): Int =
        (current.toLong() + delta.toLong()).coerceIn(0L, 10000L).toInt()
}
