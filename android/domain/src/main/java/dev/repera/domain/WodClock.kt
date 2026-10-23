package dev.repera.domain

/**
 * Port of WatchSessionHub clock descriptors / time-cap and interval semantics.
 * This class calculates frames from elapsed time. UI callbacks are never treated as ticks.
 */
data class WodClockSpec(
    val format: WodFormat?,
    val blockTimeCapMinutes: Int? = null,
    val intervalSeconds: Int? = null,
    val plannedIntervals: Int? = null,
    val rounds: Int? = null,
    val workSeconds: Int? = null,
    val restSeconds: Int? = null,
    val restBetweenRoundsSeconds: Int? = null,
    val stations: Int = 1
)

data class WodClockFace(
    val primarySeconds: Int,
    val label: String?,
    val timeCapSeconds: Int,
    val countsUp: Boolean,
    val finishedIntervals: Boolean
)

object WodClock {
    private data class Phase(val seconds: Int, val label: String)

    private fun phases(spec: WodClockSpec): List<Phase> {
        if (spec.format != WodFormat.CIRCUIT) return emptyList()
        val stations = spec.stations.coerceAtLeast(1)
        val interval = (spec.intervalSeconds ?: 60).coerceAtLeast(5)
        // Total station intervals = stations × rounds, regardless of whether
        // the block also carries a time cap. A cap must never erase later rounds.
        val count = (spec.plannedIntervals
            ?: stations * (spec.rounds ?: 1).coerceAtLeast(1)).coerceIn(1, 10000)
        val rest = (spec.restBetweenRoundsSeconds ?: 0).coerceAtLeast(0)
        return buildList {
            for (index in 0 until count) {
                val round = index / stations + 1
                add(Phase(interval, "Estación ${index % stations + 1}/$stations · R$round"))
                if ((index + 1) % stations == 0 && index + 1 < count && rest > 0)
                    add(Phase(rest, "Descanso · ronda $round"))
            }
        }
    }

    fun timeCapSeconds(spec: WodClockSpec): Int {
        val cap = spec.blockTimeCapMinutes ?: 0
        val interval = (spec.intervalSeconds ?: 60).coerceAtLeast(15)
        return when (spec.format) {
            WodFormat.EMOM -> (spec.plannedIntervals ?: spec.rounds ?: 10).coerceAtLeast(1) * interval
            WodFormat.DEATH_BY -> (spec.plannedIntervals ?: spec.blockTimeCapMinutes ?: 30).coerceAtLeast(1) * interval
            WodFormat.CIRCUIT -> phases(spec).sumOf { it.seconds }
            WodFormat.TABATA -> (spec.rounds ?: 8).coerceAtLeast(1) *
                ((spec.workSeconds ?: 20).coerceAtLeast(5) + (spec.restSeconds ?: 10).coerceAtLeast(0))
            WodFormat.AMRAP, WodFormat.MAX_EFFORT -> (cap.takeIf { it > 0 } ?: 12).coerceAtLeast(1) * 60
            WodFormat.FOR_TIME, WodFormat.CHIPPER, WodFormat.AFAP,
            WodFormat.LADDER, WodFormat.BUY_IN_CASH_OUT -> 0
            else -> cap.coerceAtLeast(0) * 60
        }
    }

    fun face(spec: WodClockSpec, elapsedSeconds: Int): WodClockFace {
        val elapsed = elapsedSeconds.coerceAtLeast(0)
        val cap = timeCapSeconds(spec)
        val countsUp = when (spec.format) {
            WodFormat.FOR_TIME, WodFormat.CHIPPER, WodFormat.AFAP,
            WodFormat.LADDER, WodFormat.BUY_IN_CASH_OUT -> true
            WodFormat.AMRAP, WodFormat.EMOM, WodFormat.TABATA,
            WodFormat.DEATH_BY, WodFormat.CIRCUIT, WodFormat.MAX_EFFORT -> false
            else -> cap <= 0
        }
        // AMRAP/Max Effort must also show Finalizado at the programmed cap.
        // For Time and other stopwatch formats continue counting up.
        val finished = !countsUp && cap > 0 && elapsed >= cap
        val intervalRemaining: Int?
        val label: String?
        if (finished) {
            intervalRemaining = 0
            label = "Finalizado"
        } else {
            when (spec.format) {
                WodFormat.EMOM, WodFormat.DEATH_BY -> {
                    val step = (spec.intervalSeconds ?: 60).coerceAtLeast(1)
                    intervalRemaining = step - elapsed % step
                    label = "Intervalo ${elapsed / step + 1}"
                }
                WodFormat.CIRCUIT -> {
                    var cursor = elapsed
                    val phase = phases(spec).firstOrNull {
                        if (cursor < it.seconds) true else { cursor -= it.seconds; false }
                    }
                    intervalRemaining = phase?.seconds?.minus(cursor) ?: 0
                    label = phase?.label
                }
                WodFormat.TABATA -> {
                    val work = (spec.workSeconds ?: 20).coerceAtLeast(1)
                    val rest = (spec.restSeconds ?: 10).coerceAtLeast(0)
                    val cycle = (work + rest).coerceAtLeast(1)
                    val position = elapsed % cycle
                    intervalRemaining = if (position < work) work - position else work + rest - position
                    label = if (position < work) "Trabajo" else "Descanso"
                }
                else -> {
                    intervalRemaining = null
                    label = if (!countsUp && cap > 0) spec.format?.wireName
                        else if (countsUp && spec.blockTimeCapMinutes != null &&
                            elapsed > spec.blockTimeCapMinutes * 60) "TC superado" else null
                }
            }
        }
        val primary = intervalRemaining ?: if (countsUp) elapsed
            else (cap - elapsed).coerceAtLeast(0)
        return WodClockFace(
            primarySeconds = primary,
            label = label,
            timeCapSeconds = cap,
            countsUp = countsUp,
            finishedIntervals = finished
        )
    }
}
