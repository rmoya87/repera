package dev.repera.domain

/**
 * Compare two logged WOD results only if their prescriptions, RX/scaled
 * execution, format and scoring semantics are identical. This never assigns
 * scores to missing or legacy data.
 */
data class ComparableWodResult(
    val format: String,
    val prescriptionFingerprint: String,
    /** null = unknown. Explicitly different RX or scaled variants never mix. */
    val isRx: Boolean?,
    /** Actual modifications: must match exactly for two scaled attempts. */
    val scalingFingerprint: String,
    val roundsCompleted: Int? = null,
    val extraReps: Int? = null,
    val elapsedSeconds: Int? = null,
    val repsPerRound: Int? = null,
    val timeCapSeconds: Int? = null,
    val measuredMetric: String? = null,
    val measuredValue: Double? = null
)

data class WodResultComparison(
    val improvement: Int,
    /** "reps" or "segundos"; positive improvement always means better. */
    val unit: String
)

data class WodPreciseMeasurementComparison(
    val improvement: Double, val unit: String
)

object WODComparisonEngine {
    fun compareMeasurement(previous: ComparableWodResult,
                           current: ComparableWodResult): WodPreciseMeasurementComparison? {
        if (previous.format != "maxEffort" || current.format != "maxEffort" ||
            previous.prescriptionFingerprint.isBlank() ||
            previous.prescriptionFingerprint != current.prescriptionFingerprint ||
            previous.isRx == null || previous.isRx != current.isRx ||
            previous.scalingFingerprint != current.scalingFingerprint ||
            previous.timeCapSeconds != current.timeCapSeconds ||
            (previous.isRx == false && previous.scalingFingerprint.isBlank()) ||
            (previous.isRx == true && previous.scalingFingerprint.isNotBlank()))
            return null
        val metric = previous.measuredMetric
        if (metric !in setOf("loadKg", "calories", "distanceMeters") ||
            metric != current.measuredMetric) return null
        val old = previous.measuredValue ?: return null
        val latest = current.measuredValue ?: return null
        if (!old.isFinite() || !latest.isFinite() || old <= 0 || latest <= 0) return null
        return WodPreciseMeasurementComparison(latest - old,
            when (metric) { "loadKg" -> "kg"; "calories" -> "kcal"; else -> "m" })
    }

    fun compare(previous: ComparableWodResult, current: ComparableWodResult): WodResultComparison? {
        if (previous.format != current.format ||
            previous.prescriptionFingerprint.isBlank() ||
            previous.prescriptionFingerprint != current.prescriptionFingerprint ||
            previous.isRx == null || previous.isRx != current.isRx ||
            previous.scalingFingerprint != current.scalingFingerprint ||
            previous.timeCapSeconds != current.timeCapSeconds) return null

        // Two scaled attempts are only comparable with explicit identical scaling.
        if (previous.isRx == false && previous.scalingFingerprint.isBlank()) return null
        // An RX attempt cannot have a recorded scaling modification.
        if (previous.isRx == true && previous.scalingFingerprint.isNotBlank()) return null

        return when (current.format) {
            "amrap" -> {
                val repsPerRound = previous.repsPerRound
                if (repsPerRound == null || repsPerRound <= 0 ||
                    repsPerRound != current.repsPerRound) return null
                val roundsA = previous.roundsCompleted
                val roundsB = current.roundsCompleted
                val extraA = previous.extraReps
                val extraB = current.extraReps
                if (roundsA == null || roundsB == null || roundsA < 0 || roundsB < 0 ||
                    extraA == null || extraB == null ||
                    extraA !in 0 until repsPerRound || extraB !in 0 until repsPerRound) return null
                WodResultComparison(
                    improvement = (roundsB - roundsA) * repsPerRound + (extraB - extraA),
                    unit = "reps"
                )
            }
            "maxEffort" -> {
                val unit = previous.measuredMetric
                val old = previous.measuredValue
                val latest = current.measuredValue
                if (unit !in setOf("loadKg", "calories", "distanceMeters") ||
                    unit != current.measuredMetric || old == null || latest == null ||
                    !old.isFinite() || !latest.isFinite() || old <= 0 || latest <= 0 ||
                    old != old.toInt().toDouble() || latest != latest.toInt().toDouble()) return null
                WodResultComparison(
                    improvement = latest.toInt() - old.toInt(),
                    unit = when (unit) { "loadKg" -> "kg"; "calories" -> "kcal"; else -> "metros" }
                )
            }
            "forTime", "afap", "chipper" -> {
                val a = previous.elapsedSeconds ?: return null
                val b = current.elapsedSeconds ?: return null
                if (a <= 0 || b <= 0) return null
                val cap = previous.timeCapSeconds
                if (cap != null && (a >= cap || b >= cap)) return null
                WodResultComparison(improvement = a - b, unit = "segundos")
            }
            else -> null
        }
    }
}
