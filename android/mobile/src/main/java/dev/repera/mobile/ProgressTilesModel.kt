package dev.repera.mobile

import kotlin.math.abs
import kotlin.math.floor

/** Pure display decisions of Apple StatsView tilesGrid / mobilityProgressCard. */
internal object ProgressTilesModel {
    /** Swift Double.rounded(): half away from zero. */
    fun roundHalfAway(value: Double): Int {
        val r = floor(abs(value) + 0.5).toInt()
        return if (value < 0) -r else r
    }

    fun minutesLabel(average: Double?): String = average?.let { "${roundHalfAway(it)}′" } ?: "—"

    /** Apple: delta only when both averages exist; rounded difference of the unrounded values. */
    fun minutesDelta(current: Double?, previous: Double?): Int? =
        if (current == null || previous == null) null else roundHalfAway(current - previous)

    /** Apple shows no delta text when it is nil or zero. */
    fun deltaLabel(delta: Int?): String? = when {
        delta == null || delta == 0 -> null
        delta > 0 -> "+$delta"
        else -> "$delta"
    }

    fun mobilityDuration(seconds: Int): String =
        if (seconds < 60) "$seconds s" else "${seconds / 60} min ${seconds % 60} s"

    data class Tile(val label: String, val value: String, val delta: Int?)

    /** Apple tilesGrid (Pro) / freeTilesGrid (Free): Entrenos, Tiempo (medio), Racha. */
    fun tiles(sessions: Int, average: Double?, previousSessions: Int?, previousAverage: Double?,
              streak: Int, previousStreak: Int, pro: Boolean): List<Tile> {
        val time = if (pro) minutesLabel(average)
            else if (average != null && sessions > 0) "${roundHalfAway(average * sessions)}′" else "—"
        return listOf(
            Tile("Entrenos", "$sessions", if (pro) previousSessions?.let { sessions - it } else null),
            Tile(if (pro) "Tiempo medio" else "Tiempo", time, if (pro) minutesDelta(average, previousAverage) else null),
            Tile("Racha", "$streak", streak - previousStreak))
    }
}
