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

    /** Apple shows no delta text when it is nil or zero. Apple 79b34354: el delta
     *  de tiempo se muestra en minutos con unidad ′ y el entero localizado. */
    fun deltaLabel(delta: Int?, unit: String = ""): String? = when {
        delta == null || delta == 0 -> null
        else -> "${if (delta > 0) "+" else ""}${dev.repera.domain.ReperaNumberFormat.integer(delta)}$unit"
    }

    fun mobilityDuration(seconds: Int): String =
        if (seconds < 60) "$seconds s" else "${seconds / 60} min ${seconds % 60} s"

    data class Tile(val label: String, val value: String, val delta: Int?, val deltaUnit: String = "")

    /** Apple tilesGrid / freeTilesGrid tras 602e9c39: Entrenos, Tiempo TOTAL, Racha.
     *  El tiempo es totalMinutes acumulado real (no media × sesiones), con delta
     *  frente al periodo comparable en ambos niveles. */
    fun tiles(sessions: Int, totalMinutes: Double, previousSessions: Int?, previousTotalMinutes: Double?,
              streak: Int, previousStreak: Int, pro: Boolean): List<Tile> {
        val total = roundHalfAway(totalMinutes)
        val time = "${dev.repera.domain.ReperaNumberFormat.integer(total)}′"
        val timeDelta = previousTotalMinutes?.let { total - roundHalfAway(it) }
        return listOf(
            Tile("Entrenos", "$sessions", previousSessions?.let { sessions - it }),
            Tile("Tiempo", time, timeDelta, "′"),
            Tile("Racha", "$streak", streak - previousStreak))
    }
}
