package dev.repera.domain

/**
 * Delivery rules for a Wear OS-owned workout mirrored on Android.
 * Stored capture watermarks and terminal UUID tombstones are supplied by the
 * authenticated phone inbox. This does not authorize any Health Connect write.
 */
object WearOwnedLiveDeliveryPolicy {
    fun accepts(
        phase: String,
        capturedAtMillis: Long,
        nowMillis: Long,
        previousCapturedAtMillis: Long,
        isClosed: Boolean
    ): Boolean {
        if (phase !in setOf("recording", "paused", "finished")) return false
        val age = nowMillis - capturedAtMillis
        if (age < -5_000L || age > (if (phase == "finished") 3_600_000L else 90_000L)) {
            return false
        }
        // A terminal packet is allowed even if its initial live notification
        // was missed. The caller only closes the exact UUID it belongs to.
        if (phase == "finished") return true
        return !isClosed && capturedAtMillis > previousCapturedAtMillis
    }
}
