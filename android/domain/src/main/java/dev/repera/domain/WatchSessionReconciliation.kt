package dev.repera.domain

/**
 * A missing phone snapshot is not an instruction to delete offline watch work.
 * Wear Data Layer updates can be stale or arrive out of order after reconnection.
 * Only a matching explicit discard or finished workout closes local work.
 */
object WatchSessionReconciliation {
    fun preserveLocal(
        watchStarted: Boolean,
        localId: String?,
        incomingId: String?,
        finishedId: String?,
        explicitlyDiscardedId: String? = null
    ): Boolean {
        if (!watchStarted || localId.isNullOrBlank()) return false
        if (finishedId == localId || explicitlyDiscardedId == localId) return false
        if (incomingId.isNullOrBlank()) return true
        return incomingId != localId
    }

    fun phoneDiscarded(
        localId: String?,
        incomingId: String?,
        finishedId: String?,
        explicitlyDiscardedId: String? = null
    ): Boolean =
        !localId.isNullOrBlank() &&
            explicitlyDiscardedId == localId &&
            finishedId != localId
}
