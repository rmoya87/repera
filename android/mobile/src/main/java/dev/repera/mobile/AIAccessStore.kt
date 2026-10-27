package dev.repera.mobile

import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.util.concurrent.TimeUnit

/**
 * Gestión de tokens personales de acceso IA (MCP).
 * Port 1:1 de la capa de red de AIAccessView.swift (iOS): tabla
 * ai_access_tokens + edge function repera-ai-tokens. El servidor genera el
 * token de 256 bits y solo guarda su digest SHA-256; el plano solo vive en
 * memoria hasta que el usuario lo copia (igual que en iOS).
 */
class AIAccessStore(
    private val http: OkHttpClient = OkHttpClient.Builder()
        .callTimeout(20, TimeUnit.SECONDS).build(),
    private val stillAuthorized:()->Boolean={true}
) {
    private fun authorize() = check(stillAuthorized()) {"La cuenta cambió durante el acceso IA"}
    private fun executeAuthorized(request:Request):okhttp3.Response {
        authorize()
        val response=http.newCall(request).execute()
        try {authorize()} catch(error:Exception) {response.close();throw error}
        return response
    }

    data class TokenInfo(
        val id: String,
        val label: String,
        val tokenPrefix: String,
        val createdAt: String,
        val expiresAt: String?,
        val revokedAt: String?,
        val lastUsedAt: String?,
        val scopes: List<String>?
    ) {
        val isActive: Boolean
            get() {
                if (revokedAt != null) return false
                val expiry = expiresAt ?: return true
                val date = parseInstant(expiry) ?: return false
                return date.isAfter(Instant.now())
            }
        val canWrite: Boolean
            get() = scopes?.contains("training:write") == true
    }

    sealed class LoadResult {
        data class Loaded(val tokens: List<TokenInfo>) : LoadResult()
        data class Failed(val message: String) : LoadResult()
    }

    sealed class CreateResult {
        data class Created(val token: String, val label: String) : CreateResult()
        data class Failed(val message: String) : CreateResult()
    }

    fun refresh(session: SupabaseIdentity.Session): LoadResult {
        val url = BuildConfig.SUPABASE_URL + "/rest/v1/ai_access_tokens" +
            "?select=id,label,token_prefix,created_at,expires_at,revoked_at,last_used_at,scopes" +
            "&owner_id=eq.${session.userId}&order=created_at.desc"
        val request = Request.Builder().url(url)
            .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
            .header("Authorization", "Bearer " + session.accessToken)
            .get().build()
        return try {
            executeAuthorized(request).use { response ->
                val body = response.body?.string().orEmpty()
                authorize()
                if (!response.isSuccessful) {
                    return LoadResult.Failed("No se pudieron obtener los tokens: HTTP " + response.code)
                }
                LoadResult.Loaded(parseTokens(JSONArray(body)))
            }
        } catch (error: Exception) {
            LoadResult.Failed("No se pudieron obtener los tokens: " +
                (error.localizedMessage ?: ""))
        }
    }

    fun create(session: SupabaseIdentity.Session,
               label: String, expiry: String, canWrite: Boolean): CreateResult {
        val url = BuildConfig.SUPABASE_URL + "/functions/v1/repera-ai-tokens"
        val payload = JSONObject()
            .put("label", label.trim())
            .put("expiry", expiry)
            .put("canWrite", canWrite)
        val request = Request.Builder().url(url)
            .header("Authorization", "Bearer " + session.accessToken)
            .header("Content-Type", "application/json")
            .post(payload.toString().toRequestBody("application/json".toMediaType()))
            .build()
        return try {
            executeAuthorized(request).use { response ->
                val body = response.body?.string().orEmpty()
                authorize()
                if (response.code !in 200..299) {
                    val issue = runCatching { JSONObject(body).optString("error") }
                        .getOrDefault("")
                    return CreateResult.Failed(if (issue.isNotBlank()) issue
                        else "Error HTTP " + response.code)
                }
                val value = JSONObject(body)
                CreateResult.Created(value.getString("token"), value.optString("label"))
            }
        } catch (error: Exception) {
            CreateResult.Failed("No se pudo crear el token: " +
                (error.localizedMessage ?: ""))
        }
    }

    fun revoke(session: SupabaseIdentity.Session, tokenId: String): String? {
        val url = BuildConfig.SUPABASE_URL + "/rest/v1/ai_access_tokens" +
            "?id=eq.$tokenId&owner_id=eq.${session.userId}"
        val payload = JSONObject().put("revoked_at", Instant.now().toString())
        val request = Request.Builder().url(url)
            .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
            .header("Authorization", "Bearer " + session.accessToken)
            .header("Content-Type", "application/json")
            .header("Prefer", "return=minimal")
            .patch(payload.toString().toRequestBody("application/json".toMediaType()))
            .build()
        return try {
            executeAuthorized(request).use { response ->
                if (response.isSuccessful) null
                else "No se pudo revocar el token: HTTP " + response.code
            }
        } catch (error: Exception) {
            "No se pudo revocar el token: " + (error.localizedMessage ?: "")
        }
    }

    companion object {
        internal fun parseInstant(value: String?): Instant? {
            if (value.isNullOrBlank()) return null
            return runCatching { Instant.parse(value) }.getOrNull()
        }

        internal fun parseTokens(rows: JSONArray): List<TokenInfo> =
            (0 until rows.length()).map { i ->
                val row = rows.getJSONObject(i)
                TokenInfo(
                    id = row.getString("id"),
                    label = row.optString("label"),
                    tokenPrefix = row.optString("token_prefix"),
                    createdAt = row.optString("created_at"),
                    expiresAt = row.optString("expires_at").ifBlank { null },
                    revokedAt = row.optString("revoked_at").ifBlank { null },
                    lastUsedAt = row.optString("last_used_at").ifBlank { null },
                    scopes = row.optJSONArray("scopes")?.let { scopes ->
                        (0 until scopes.length()).map { scopes.getString(it) }
                    }
                )
            }
    }
}
