package dev.repera.domain

/** Paridad matemática con AdaptiveRoutePace.swift; solo presentación. */
object AdaptiveRoutePace {
    enum class Mode(val minimumSpanMps: Double) {
        WALKING(0.5 / 3.6), RUNNING(1.0 / 3.6), CYCLING(2.0 / 3.6),
        WATER(1.2 / 3.6), OTHER(0.8 / 3.6)
    }
    data class Sample(val speedMps: Double, val distanceMeters: Double,
                      val estimated: Boolean = false)
    data class Scale(val medianMps: Double, val lowMps: Double, val highMps: Double,
                     val minimumSpanMps: Double, val hasMeaningfulVariation: Boolean) {
        fun position(speedMps: Double): Double {
            if (!speedMps.isFinite()) return 0.5
            if (!hasMeaningfulVariation)
                return (0.5 + (speedMps - medianMps) / (minimumSpanMps * 4))
                    .coerceIn(0.40, 0.60)
            val side = if (speedMps < medianMps)
                maxOf(medianMps - lowMps, minimumSpanMps / 2)
                else maxOf(highMps - medianMps, minimumSpanMps / 2)
            return (0.5 + 0.5 * (speedMps - medianMps) / side).coerceIn(0.0, 1.0)
        }
    }
    fun scale(samples: List<Sample>, mode: Mode): Scale? {
        val sorted = samples.filter {
            !it.estimated && it.speedMps.isFinite() && it.speedMps in 0.2..55.0 &&
                it.distanceMeters.isFinite() && it.distanceMeters >= 1.0
        }.sortedBy { it.speedMps }
        if (sorted.isEmpty()) return null
        val total = sorted.sumOf { minOf(30.0, it.distanceMeters) }
        fun quantile(p: Double): Double {
            val target = p * total
            var accumulated = 0.0
            for (sample in sorted) {
                accumulated += minOf(30.0, sample.distanceMeters)
                if (accumulated >= target) return sample.speedMps
            }
            return sorted.last().speedMps
        }
        val low = quantile(0.1); val median = quantile(0.5); val high = quantile(0.9)
        return Scale(median, low, high, mode.minimumSpanMps,
            high - low >= mode.minimumSpanMps)
    }
    fun color(position: Double, water: Boolean = false): Long {
        val t = (if (position.isFinite()) position else 0.5).coerceIn(0.0, 1.0)
        val stops = listOf(
            if (water) Triple(0.0, 0.85, 0.55) else Triple(0.086, 0.722, 0.361),
            Triple(0.486, 0.824, 0.294), Triple(0.902, 0.847, 0.286),
            Triple(1.0, 0.612, 0.137), Triple(0.941, 0.235, 0.22))
        val section = minOf(3, (t * 4).toInt())
        val mix = t * 4 - section
        val a = stops[section]; val b = stops[section + 1]
        fun channel(x: Double, y: Double): Long =
            ((x + (y - x) * mix).coerceIn(0.0, 1.0) * 255).toLong()
        return 0xFF000000L or (channel(a.first, b.first) shl 16) or
            (channel(a.second, b.second) shl 8) or channel(a.third, b.third)
    }
    fun modeForSport(name: String): Mode = when (name.uppercase()) {
        "WALKING", "HIKING", "GOLF" -> Mode.WALKING
        "RUNNING", "TRAIL" -> Mode.RUNNING
        "CYCLING", "MOUNTAIN_BIKE", "GRAVEL", "MOUNTAINBIKE" -> Mode.CYCLING
        "SURFING", "WINDSURFING", "KITESURFING", "KAYAKING",
        "ROWING", "CANOEING", "SAILING", "SWIMMING" -> Mode.WATER
        else -> Mode.OTHER
    }
}
