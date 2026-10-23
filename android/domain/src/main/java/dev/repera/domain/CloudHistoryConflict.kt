package dev.repera.domain

/**
 * Guard before applying Swift's deterministic whole-document SyncConflictResolver.
 * Divergent athlete-owned workout histories are never silently overwritten.
 */
object CloudHistoryConflict {
    fun requiresManualResolution(
        localWorkoutIds: Set<String>,
        remoteWorkoutIds: Set<String>,
        localActiveDocument: String?,
        remoteActiveDocument: String?
    ): Boolean {
        val onlyLocal = (localWorkoutIds - remoteWorkoutIds).isNotEmpty()
        val onlyRemote = (remoteWorkoutIds - localWorkoutIds).isNotEmpty()
        if (onlyLocal && onlyRemote) return true
        if (localActiveDocument != null && remoteActiveDocument != null &&
            localActiveDocument != remoteActiveDocument) return true
        if (localActiveDocument != null && remoteActiveDocument == null && onlyRemote) return true
        if (remoteActiveDocument != null && localActiveDocument == null && onlyLocal) return true
        return false
    }
}
