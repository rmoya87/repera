package dev.repera.mobile

import java.util.concurrent.TimeUnit
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject

/**
 * Cliente de eliminación de cuenta (paridad iOS `requestAccountDeletion`).
 * El Edge Function `repera-delete-account` usa el JWT personal; la app nunca
 * envía un UUID de usuario. Acciones: `preflight` | `delete`.
 */
class AccountDeletionClient(
    private val baseUrl: String = BuildConfig.SUPABASE_URL,
    private val publishableKey: String = BuildConfig.SUPABASE_PUBLISHABLE_KEY,
    private val http: OkHttpClient = OkHttpClient.Builder()
        .callTimeout(45, TimeUnit.SECONDS)
        .build()
) {
    class AccountDeletionException(message: String) : Exception(message)

    suspend fun request(action: String, accessToken: String): Unit = withContext(Dispatchers.IO) {
        require(action == "preflight" || action == "delete")
        if (accessToken.isBlank()) {
            throw AccountDeletionException(
                "Necesitas iniciar sesión y tener conexión para eliminar la cuenta."
            )
        }
        val expectedHost = expectedSupabaseHost()
        val url = "$baseUrl/functions/v1/repera-delete-account"
        val host = runCatching { java.net.URI(url).host }.getOrNull()
        if (baseUrl.isBlank() || host.isNullOrBlank() ||
            (expectedHost != null && host != expectedHost)
        ) {
            throw AccountDeletionException("No se pudo verificar la conexión segura con Repera.")
        }
        val body = JSONObject().put("action", action).toString()
            .toRequestBody(JSON)
        val request = Request.Builder()
            .url(url)
            .header("Authorization", "Bearer $accessToken")
            .header("apikey", publishableKey)
            .header("Content-Type", "application/json")
            .post(body)
            .build()
        http.newCall(request).execute().use { response ->
            val payload = response.body?.string().orEmpty()
            val json = runCatching { JSONObject(payload) }.getOrNull()
            if (response.code !in 200..299 || json?.optBoolean("ok") != true) {
                throw AccountDeletionException(
                    json?.optString("error")?.takeIf { it.isNotBlank() }
                        ?: "No se pudo confirmar la eliminación remota (${response.code})."
                )
            }
        }
    }

    companion object {
        private val JSON = "application/json; charset=utf-8".toMediaType()

        /** Misma host allowlist que iOS SettingsView (bundle URL). */
        private fun expectedSupabaseHost(): String? =
            runCatching { java.net.URI(BuildConfig.SUPABASE_URL).host }.getOrNull()
    }
}
