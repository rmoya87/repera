package dev.repera.domain

/**
 * Deterministic version ordering from Swift SyncConflictResolver.winner.
 * Transport-independent so cloud clients and tests share the same rules.
 */
data class SyncVersion(
    val revision: Int,
    val updatedAtMillis: Long,
    val deviceId: String
) : Comparable<SyncVersion> {
    override fun compareTo(other: SyncVersion): Int {
        val revisionOrder = revision.compareTo(other.revision)
        if (revisionOrder != 0) return revisionOrder
        val timeOrder = updatedAtMillis.compareTo(other.updatedAtMillis)
        return if (timeOrder != 0) timeOrder else deviceId.compareTo(other.deviceId)
    }
}
