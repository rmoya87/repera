package dev.repera.mobile

import android.content.Context

/** Last background-sync outcome, surfaced in the UI so sync never looks silent. */
class SyncStatusStore(context: Context) {
    private val preferences = context.applicationContext
        .getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    enum class State { NEVER, SYNCED, CONSENT_REQUIRED, FAILED }

    data class Status(val state: State, val detail: String?, val epochSeconds: Long)

    fun read(): Status {
        val state = preferences.getString(KEY_STATE, null)
            ?.let { runCatching { State.valueOf(it) }.getOrNull() } ?: State.NEVER
        return Status(
            state = state,
            detail = preferences.getString(KEY_DETAIL, null),
            epochSeconds = preferences.getLong(KEY_AT, 0L)
        )
    }

    fun markSynced(outcome: DriveSnapshotService.Outcome) = write(
        State.SYNCED,
        when (outcome) {
            DriveSnapshotService.Outcome.Empty -> "Drive aún no tiene datos"
            DriveSnapshotService.Outcome.Unchanged -> "Datos actualizados"
            DriveSnapshotService.Outcome.Uploaded -> "Copia subida a Drive"
            DriveSnapshotService.Outcome.Downloaded -> "Datos recuperados de Drive"
            DriveSnapshotService.Outcome.Conflict -> "Copias distintas: revisión manual pendiente"
        }
    )

    fun markConsentRequired() = write(State.CONSENT_REQUIRED, "Drive pide autorización al abrir la app")

    fun markFailed(detail: String?) = write(State.FAILED, detail)

    private fun write(state: State, detail: String?) {
        preferences.edit()
            .putString(KEY_STATE, state.name)
            .putString(KEY_DETAIL, detail)
            .putLong(KEY_AT, System.currentTimeMillis() / 1000)
            .apply()
    }

    companion object {
        private const val PREFS = "repera_sync_status"
        private const val KEY_STATE = "state"
        private const val KEY_DETAIL = "detail"
        private const val KEY_AT = "at"
    }
}
