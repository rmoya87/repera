package dev.repera.domain

/**
 * Port of Apple WorkoutExercise.displayBlockHeader and plannedIntervals (EMOM), fc3ef7e1 Models.swift.
 * Deviation: an empty header string is treated like an absent one (Apple would return ""),
 * so a watch button is never blank.
 */
object WearBlockHeader {
    fun display(
        strengthKind: Boolean, format: WodFormat?, header: String?, timeCapMinutes: Int?,
        rounds: Int?, intervalSeconds: Int?, workSeconds: Int?, restSeconds: Int?
    ): String {
        val h = header?.takeIf { it.isNotBlank() }
        if (strengthKind || format == null || format == WodFormat.STRENGTH) return h ?: "Fuerza"
        return when (format) {
            WodFormat.AMRAP -> "AMRAP ${timeCapMinutes ?: 12}'"
            WodFormat.EMOM -> {
                val planned = emomIntervals(timeCapMinutes, rounds, intervalSeconds)
                val mins = timeCapMinutes ?: planned ?: rounds ?: 10
                val interval = intervalSeconds ?: 60
                if (interval != 60) {
                    val every = maxOf(1, interval / 60)
                    val r = rounds ?: planned
                    if (r != null) "Every $every' × $r" else "Every $every'"
                } else "EMOM $mins'"
            }
            WodFormat.FOR_TIME -> if (rounds != null) "$rounds RFT (TC ${timeCapMinutes ?: 12}')" else "For Time (TC ${timeCapMinutes ?: 12}')"
            WodFormat.TABATA -> "Tabata ${workSeconds ?: 20}/${restSeconds ?: 10} ×${rounds ?: 8}"
            WodFormat.CHIPPER -> "Chipper"
            WodFormat.DEATH_BY -> "Muerte por"
            WodFormat.AFAP -> "AFAP"
            WodFormat.LADDER -> h ?: "Ladder"
            WodFormat.PARTNER -> "Partner"
            WodFormat.BUY_IN_CASH_OUT -> h ?: "Buy-in / Cash-out"
            WodFormat.ROUNDS_FOR_QUALITY -> if (rounds != null) "$rounds RFQ" else "Rounds for Quality"
            WodFormat.CIRCUIT -> "Circuito"
            WodFormat.MAX_EFFORT -> "Max effort"
            WodFormat.STRENGTH -> h ?: "Fuerza"
        }
    }

    private fun emomIntervals(cap: Int?, rounds: Int?, intervalSeconds: Int?): Int? {
        val interval = maxOf(1, intervalSeconds ?: 60)
        if (cap != null && cap > 0) return maxOf(1, (cap * 60) / interval)
        if (rounds != null && rounds > 0) return rounds
        return null
    }
}
