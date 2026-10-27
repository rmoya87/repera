package dev.repera.domain

/** A stale empty phone snapshot is not evidence that a watch-started workout was saved. */
object WatchSessionReconciliation {
    fun preserveLocal(watchStarted:Boolean,localId:String?,incomingId:String?,finishedId:String?):Boolean =
        watchStarted && localId!=null && finishedId!=localId && incomingId!=localId
}
