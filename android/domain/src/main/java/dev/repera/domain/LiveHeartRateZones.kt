package dev.repera.domain

/**
 * Five-zone heart-rate estimate shared by Android phone and Wear OS.
 * Matches the SwiftUI Apple Watch cutoffs. Not a clinical diagnosis.
 * A zone must never be inferred without a valid measured BPM.
 */
object LiveHeartRateZones {
    fun zone(bpm: Int?, estimatedMaxBpm: Double = 190.0): Int? {
        if (bpm == null || bpm !in 25..250 ||
            !estimatedMaxBpm.isFinite() || estimatedMaxBpm <= 0.0) return null
        val ratio = bpm / estimatedMaxBpm
        return when {
            ratio < 0.60 -> 1
            ratio < 0.70 -> 2
            ratio < 0.80 -> 3
            ratio < 0.90 -> 4
            else -> 5
        }
    }
}
