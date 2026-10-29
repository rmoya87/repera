package dev.repera.mobile

import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.TimeUnit

/**
 * Port de BusinessAuthStore.syncPublicProfile (Apple fc3ef7e1): nombre y avatar PUBLICOS en Supabase
 * (Storage "profile-avatars/{uid}/avatar.jpg" + profiles.display_name / avatar_url). No envia entrenos, Salud ni compras.
 *
 * Cableado desde MainActivity tras hidratar cuenta (login) y al guardar nombre/foto en Ajustes.
 */
class PublicProfileSync(
    private val baseUrl: String = BuildConfig.SUPABASE_URL,
    private val publishableKey: String = BuildConfig.SUPABASE_PUBLISHABLE_KEY,
    private val http: OkHttpClient = OkHttpClient.Builder().callTimeout(30, TimeUnit.SECONDS).build(),
    private val stillAuthorized: () -> Boolean = { true },
    private val nowMillis: () -> Long = { System.currentTimeMillis() }
) {
    class PhotoTooLarge : IllegalArgumentException("La foto supera 2 MB")

    private fun authorize() = check(stillAuthorized()) { "La cuenta cambió durante la sincronización del perfil" }

    /** @param avatarJpeg null o vacio = quitar avatar (Apple: remove best-effort + avatar_url NULL). */
    fun sync(session: SupabaseIdentity.Session, displayName: String?, avatarJpeg: ByteArray?) {
        authorize()
        require(session.accessToken.isNotBlank() && session.userId.isNotBlank())
        if (avatarJpeg != null && avatarJpeg.size > MAX_AVATAR_BYTES) throw PhotoTooLarge()
        val uid = session.userId.lowercase()
        val name = (displayName ?: "").trim().take(MAX_NAME)
        val path = "$uid/avatar.jpg"
        val avatarUrl: String?
        if (avatarJpeg != null && avatarJpeg.isNotEmpty()) {
            send(session, Request.Builder().url("$baseUrl/storage/v1/object/profile-avatars/$path")
                .header("cache-control", "3600").header("x-upsert", "true")
                .post(avatarJpeg.toRequestBody("image/jpeg".toMediaType())))
            avatarUrl = "$baseUrl/storage/v1/object/public/profile-avatars/$path?v=${nowMillis() / 1000}"
        } else {
            runCatching {
                send(session, Request.Builder().url("$baseUrl/storage/v1/object/profile-avatars")
                    .method("DELETE", JSONObject().put("prefixes", JSONArray().put(path)).toString()
                        .toRequestBody("application/json".toMediaType())))
            }
            avatarUrl = null
        }
        authorize()
        val patch = JSONObject().put("display_name", name).put("avatar_url", avatarUrl ?: JSONObject.NULL)
        send(session, Request.Builder().url("$baseUrl/rest/v1/profiles?id=eq.$uid")
            .header("Prefer", "return=minimal")
            .patch(patch.toString().toRequestBody("application/json".toMediaType())))
        authorize()
    }

    private fun send(session: SupabaseIdentity.Session, builder: Request.Builder) {
        authorize()
        val request = builder.header("apikey", publishableKey)
            .header("Authorization", "Bearer " + session.accessToken).build()
        http.newCall(request).execute().use { response ->
            authorize()
            if (!response.isSuccessful) throw IllegalStateException("HTTP " + response.code)
        }
    }

    companion object {
        const val MAX_AVATAR_BYTES = 2_097_152
        const val MAX_NAME = 100
    }
}
