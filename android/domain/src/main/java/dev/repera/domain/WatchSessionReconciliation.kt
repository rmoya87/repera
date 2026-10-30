package dev.repera.domain

/**
 * Decide whether a watch-started local session must survive a phone Data Layer update.
 *
 * Ramón 2026-10-29 (F-5 / sync): terminar o descartar en el teléfono cierra el
 * reloj; reabrir no debe resucitar la sesión. Por tanto un active vacío en el
 * teléfono (sin finished que coincida) **no** conserva el trabajo local.
 */
object WatchSessionReconciliation {
    /**
     * @param watchStarted sesión iniciada en el reloj aún no adoptada
     * @param localId id de la sesión visible en el reloj
     * @param incomingId id del activeSession del teléfono (null si no hay)
     * @param finishedId id del finished publicado (null si no hay)
     */
    fun preserveLocal(
        watchStarted: Boolean,
        localId: String?,
        incomingId: String?,
        finishedId: String?
    ): Boolean {
        if (!watchStarted || localId.isNullOrBlank()) return false
        // El teléfono terminó nuestra sesión → mostrar resumen, no conservar running.
        if (finishedId == localId) return false
        // An empty phone snapshot can mean the phone has not adopted the
        // watch-owned offline execution yet. Only an explicit, UUID-scoped
        // terminal event may discard this work.
        if (incomingId.isNullOrBlank()) return true
        // El teléfono tiene otra sesión viva → conservar la del reloj.
        return incomingId != localId
    }

    /** True when phone cleared active without finishing this session (cancel/discard). */
    fun phoneDiscarded(
        localId: String?,
        incomingId: String?,
        finishedId: String?
    ): Boolean =
        !localId.isNullOrBlank() &&
            incomingId.isNullOrBlank() &&
            finishedId != localId
}
