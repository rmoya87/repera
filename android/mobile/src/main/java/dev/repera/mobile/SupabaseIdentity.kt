package dev.repera.mobile

import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.util.concurrent.TimeUnit

/**
 * Native Google ID token -> verified Supabase Auth session.
 * Never uses the Google email/profile as an authorization decision.
 * The refresh token keeps the session durable across process restarts;
 * callers persist it via SessionStore (Android Keystore encryption).
 */
class SupabaseIdentity(
    private val http: OkHttpClient = OkHttpClient.Builder()
        .callTimeout(20, TimeUnit.SECONDS).build()
) {
    data class Session(
        val userId: String,
        val accessToken: String,
        val refreshToken: String,
        val expiresIn: Long,
        val issuedAtEpochSeconds: Long
    ) {
        val expiresAtEpochSeconds: Long get() = issuedAtEpochSeconds + expiresIn
    }

    fun signInWithGoogle(idToken: String, nonce: String): Session {
        require(idToken.isNotBlank() && nonce.isNotBlank())
        val json = requestPayload(idToken, nonce)
        val request = Request.Builder()
            .url(BuildConfig.SUPABASE_URL + "/auth/v1/token?grant_type=id_token")
            .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
            .post(json.toString().toRequestBody(JSON_MEDIA))
            .build()
        return execute(request)
    }

    /** Rotates the refresh token: the returned session carries a new one. */
    fun refresh(refreshToken: String): Session {
        require(refreshToken.isNotBlank())
        val json = JSONObject().put("refresh_token", refreshToken)
        val request = Request.Builder()
            .url(BuildConfig.SUPABASE_URL + "/auth/v1/token?grant_type=refresh_token")
            .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
            .post(json.toString().toRequestBody(JSON_MEDIA))
            .build()
        return execute(request)
    }

    fun signOut(session: Session) {
        val request = Request.Builder()
            .url(BuildConfig.SUPABASE_URL + "/auth/v1/logout?scope=local")
            .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
            .header("Authorization", "Bearer ${session.accessToken}")
            .post(byteArrayOf().toRequestBody(null))
            .build()
        http.newCall(request).execute().use { response ->
            if (!response.isSuccessful) throw IllegalStateException("Logout HTTP ${response.code}")
        }
    }

    private fun execute(request: Request): Session {
        http.newCall(request).execute().use { response ->
            // Do not echo auth responses or tokens into errors or device logs.
            if (!response.isSuccessful)
                throw IllegalStateException("Supabase Auth HTTP ${response.code}: revisa Google Client IDs")
            return parseSession(JSONObject(response.body?.string() ?: error("Respuesta vacía")))
        }
    }

    companion object {
        private val JSON_MEDIA = "application/json; charset=utf-8".toMediaType()

        internal fun requestPayload(token: String, nonce: String): JSONObject =
            JSONObject().put("provider", "google").put("id_token", token).put("nonce", nonce)

        internal fun parseSession(data: JSONObject): Session {
            val userId = data.optJSONObject("user")?.optString("id").orEmpty()
            val token = data.optString("access_token")
            val refresh = data.optString("refresh_token")
            val expiry = data.optLong("expires_in", 0)
            require(userId.isNotBlank() && token.isNotBlank() && refresh.isNotBlank() &&
                data.optString("token_type").equals("bearer", true) && expiry > 0) {
                "La respuesta de Supabase no contiene una sesión válida"
            }
            return Session(userId, token, refresh, expiry, System.currentTimeMillis() / 1000)
        }
    }
}
