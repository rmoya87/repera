package dev.repera.domain

/**
 * Health Services CALORIES_TOTAL is total energy, including basal metabolic
 * expenditure. It is not an ActiveCaloriesBurnedRecord.
 *
 * A transient zero is never authoritative over a previously measured total.
 * Different session UUIDs must be reconciled outside this helper.
 */
object WearMeasuredEnergy {
    fun verifiedTotal(kcal: Double?): Double? =
        kcal?.takeIf { it.isFinite() && it > 0.0 }

    fun reconcileTotal(previous: Double?, incoming: Double?): Double? {
        val old = verifiedTotal(previous)
        val next = verifiedTotal(incoming)
        return when {
            old == null -> next
            next == null -> old
            else -> maxOf(old, next)
        }
    }

    fun verifiedAveragePulse(bpm: Double?): Double? =
        bpm?.takeIf { it.isFinite() && it in 25.0..250.0 }
}
