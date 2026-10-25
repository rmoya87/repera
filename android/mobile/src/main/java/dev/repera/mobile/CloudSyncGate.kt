package dev.repera.mobile

import java.util.concurrent.atomic.AtomicInteger

/**
 * Equivalente de `!isSyncingiCloud` en ReperaStore.mergeRecoveredWorkoutsFromSupabase (iOS): la recuperación
 * remota→local del espejo Supabase no corre mientras una sincronización de Drive está en curso (Activity o worker).
 * No replica `didCompleteInitialRemoteSync` (Android no tiene fase inicial equivalente): diferencia documentada.
 */
object CloudSyncGate {
    private val running = AtomicInteger(0)
    fun isDriveSyncRunning(): Boolean = running.get() > 0
    fun <T> driveSync(block: () -> T): T {
        running.incrementAndGet()
        try { return block() } finally { running.decrementAndGet() }
    }
}
