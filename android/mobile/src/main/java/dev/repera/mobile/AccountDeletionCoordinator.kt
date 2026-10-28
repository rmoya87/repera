package dev.repera.mobile

import android.content.Context
import java.io.File
import org.json.JSONObject

/**
 * Pasos locales de borrado de cuenta (paridad iOS `deleteCurrentAccount`
 * sin iCloud): vaciar snapshot del usuario, preferencias de places/timer y
 * provenance; Drive appData se limpia best-effort por el caller.
 */
object AccountDeletionCoordinator {
    fun assertNoActiveSession(state: JSONObject?) {
        val active = state?.optJSONObject("activeSession")
        if (active != null && active.optString("id").isNotBlank()) {
            throw AccountDeletionClient.AccountDeletionException(
                "Finaliza primero el entrenamiento en curso."
            )
        }
    }

    /** Shell vacío local tras borrado remoto OK (catálogo se rehidrata al login). */
    fun emptyShellState(): JSONObject = JSONObject()
        .put("syncRevision", 0)
        .put("workouts", org.json.JSONArray())
        .put("routines", org.json.JSONArray())
        .put("exercises", org.json.JSONArray())
        .put("settings", JSONObject())

    fun clearAccountPreferences(context: Context, deletedOwnerId: String?) {
        context.getSharedPreferences("repera.places.recent.v1", Context.MODE_PRIVATE)
            .edit().clear().apply()
        context.getSharedPreferences("repera.timer.lastCompletion.v1", Context.MODE_PRIVATE)
            .edit().clear().apply()
        context.getSharedPreferences("repera.live.guidance", Context.MODE_PRIVATE)
            .edit().clear().apply()
        if (!deletedOwnerId.isNullOrBlank()) {
            val prefix = "repera.supabaseWorkoutMirror.v1.${deletedOwnerId.lowercase()}."
            // Mirror prefs viven en archivos con nombre de cuenta; borrar carpeta users/ lo cubre
            // LocalSnapshotStore. Aquí limpiamos SharedPreferences sueltas si existen.
            context.getSharedPreferences("repera_sync_status", Context.MODE_PRIVATE)
                .edit().clear().apply()
            runCatching {
                val dir = File(context.applicationInfo.dataDir, "shared_prefs")
                dir.listFiles()?.forEach { file ->
                    if (file.name.startsWith(prefix) || file.name.contains(deletedOwnerId)) {
                        file.delete()
                    }
                }
            }
        }
    }

    fun wipeLocalUserFolder(context: Context, uniqueGoogleId: String) {
        val folder = File(
            context.filesDir,
            "users/" + sha256(uniqueGoogleId)
        )
        if (folder.exists()) folder.deleteRecursively()
    }

    private fun sha256(value: String): String {
        val digest = java.security.MessageDigest.getInstance("SHA-256")
            .digest(value.toByteArray(Charsets.UTF_8))
        return digest.joinToString("") { "%02x".format(it) }
    }
}
