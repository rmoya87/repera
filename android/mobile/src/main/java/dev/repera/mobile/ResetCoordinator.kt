package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject

/** Puertos del reset. En produccion los cablearia WorkoutRepository (aun NO cableado, sin UI). */
interface ResetPorts {
    fun loadIntent(): String?
    fun storeIntent(json: String)
    fun clearIntent()
    fun readState(): JSONObject?
    /** Guardado con CAS sobre el snapshot leido; false si otro escritor lo toco. */
    fun saveState(state: JSONObject): Boolean
    /** Tombstone idempotente (WorkoutMirrorStore.noteDeleted). */
    fun noteDeleted(id: String)
}

/**
 * Diario de intencion para el reset, orden: intencion -> guardar snapshot (CAS) -> tombstones -> borrar intencion.
 * Nunca hay tombstone mientras el snapshot aun conserva los ids (evita el riesgo de deleteWorkout con CAS fallido).
 * Mientras exista intencion, los ids deben tratarse como borrados al recuperar del espejo (ver [protectedIds]).
 * Si tras guardar reaparecen ids de la intencion (otro dispositivo restauro historial) NO se vuelve a borrar solo:
 * se informa como [Recovery.ResurrectedNeedsDecision].
 */
class ResetCoordinator(private val ports: ResetPorts) {
    sealed interface Outcome {
        data object NothingToReset : Outcome
        data object Done : Outcome
        data object CasFailedNothingChanged : Outcome
        data object PendingRecoveryRequired : Outcome
    }
    sealed interface Recovery {
        data object NoIntent : Recovery
        data object DiscardedUnsavedIntent : Recovery
        data object PromotedTombstones : Recovery
        /** No se puede leer el snapshot: no se puede probar que el guardado ocurrio; se conserva la intencion. */
        data object StateUnavailableKeptIntent : Recovery
        /** Intencion ilegible: no se sabe que ids afecta; se conserva y no se borra nada. */
        data object CorruptIntentKept : Recovery
        data class ResurrectedNeedsDecision(val ids: Set<String>) : Recovery
    }

    /** Ids que el espejo no debe recuperar mientras haya intencion viva. */
    fun protectedIds(): Set<String> = intentIds(ports.loadIntent())

    fun reset(resetId: String): Outcome = synchronized(LOCK) { resetLocked(resetId) }

    private fun resetLocked(resetId: String): Outcome {
        if (ports.loadIntent() != null) return Outcome.PendingRecoveryRequired
        val state = ports.readState() ?: return Outcome.NothingToReset
        val ids = UserDataReset.discardedIds(state)
        if (ids.isEmpty() && !hasUserData(state)) return Outcome.NothingToReset
        ports.storeIntent(JSONObject().put("resetId", resetId).put("ids", JSONArray(ids)).toString())
        UserDataReset.clear(state)
        if (!ports.saveState(state)) {
            ports.clearIntent()
            return Outcome.CasFailedNothingChanged
        }
        ids.forEach { ports.noteDeleted(it) }
        ports.clearIntent()
        return Outcome.Done
    }

    /** Idempotente: llamar al arrancar y antes de cada sync del espejo. */
    fun recover(): Recovery = synchronized(LOCK) { recoverLocked() }

    private fun recoverLocked(): Recovery {
        val raw = ports.loadIntent() ?: return Recovery.NoIntent
        val ids = runCatching { intentIdsStrict(raw) }.getOrNull() ?: return Recovery.CorruptIntentKept
        val state = ports.readState() ?: return Recovery.StateUnavailableKeptIntent
        val present = UserDataReset.discardedIds(state).toSet().intersect(ids)
        return when {
            present.isEmpty() -> { ids.forEach { ports.noteDeleted(it) }; ports.clearIntent(); Recovery.PromotedTombstones }
            present.size == ids.size -> { ports.clearIntent(); Recovery.DiscardedUnsavedIntent }
            else -> Recovery.ResurrectedNeedsDecision(present)
        }
    }

    private companion object { val LOCK = Any() }

    private fun hasUserData(state: JSONObject) =
        listOf("routines", "bodyWeights").any { (state.optJSONArray(it)?.length() ?: 0) > 0 }

    private fun intentIdsStrict(raw: String): Set<String> {
        val a = JSONObject(raw).getJSONArray("ids")
        return (0 until a.length()).map { a.getString(it) }.toSet()
    }

    private fun intentIds(raw: String?): Set<String> {
        if (raw == null) return emptySet()
        return runCatching { intentIdsStrict(raw) }.getOrDefault(emptySet())
    }
}

/**
 * SIMULACION de la politica de epoca de reset: NO implementada en el snapshot ni compatible con Apple.
 * Solo fija la regla que habria que acordar: mayor epoca gana sobre cualquier revision.
 */
object ResetEpochPolicy {
    enum class Winner { Local, Remote, UseRevisionRule }
    fun resolve(localEpoch: Long, remoteEpoch: Long): Winner = when {
        localEpoch > remoteEpoch -> Winner.Local
        localEpoch < remoteEpoch -> Winner.Remote
        else -> Winner.UseRevisionRule
    }
}
