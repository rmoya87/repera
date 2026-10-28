package dev.repera.mobile.monetization

import dev.repera.domain.monetization.CommercialSnapshot
import dev.repera.domain.monetization.SubscriptionStatus
import dev.repera.mobile.BuildConfig
import java.util.concurrent.TimeUnit
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject

/**
 * Cliente de verificación de compras Play.
 * Envía purchaseToken al Edge Function `repera-play-billing-verify`, que es la
 * única capa autorizada a consultar purchases.subscriptionsv2.get.
 *
 * Sin secreto de cuenta de servicio en el dispositivo: si el backend no está
 * configurado (503 configured=false) o la red falla, el resultado es
 * [VerifyResult.Unavailable] y SubscriptionManager conserva UNKNOWN / caché.
 */
class PlayPurchaseVerifyClient(
    private val baseUrl: String = BuildConfig.SUPABASE_URL,
    private val publishableKey: String = BuildConfig.SUPABASE_PUBLISHABLE_KEY,
    private val http: OkHttpClient = OkHttpClient.Builder()
        .callTimeout(30, TimeUnit.SECONDS)
        .build()
) {
    sealed interface VerifyResult {
        data class Verified(val snapshot: CommercialSnapshot) : VerifyResult
        /** Backend sin secretos Play / endpoint no desplegado. */
        data class NotConfigured(val message: String) : VerifyResult
        data class Unavailable(val message: String) : VerifyResult
    }

    /**
     * Verifica en IO: OkHttp.execute() es bloqueante y nunca debe correr en
     * el hilo principal (arranque / paywall usan Main).
     */
    suspend fun verify(
        accessToken: String,
        purchaseToken: String,
        productId: String?
    ): VerifyResult = withContext(Dispatchers.IO) {
        if (accessToken.isBlank() || purchaseToken.isBlank()) {
            return@withContext VerifyResult.Unavailable("Sesión o token de compra ausente")
        }
        val payload = JSONObject()
            .put("purchaseToken", purchaseToken)
            .put("productId", productId ?: JSONObject.NULL)
            .put("packageName", PACKAGE_NAME)
        val request = Request.Builder()
            .url("$baseUrl/functions/v1/repera-play-billing-verify")
            .header("Authorization", "Bearer $accessToken")
            .header("apikey", publishableKey)
            .header("Content-Type", "application/json")
            .post(payload.toString().toRequestBody(JSON))
            .build()
        try {
            http.newCall(request).execute().use { response ->
                val body = response.body?.string().orEmpty()
                val json = runCatching { JSONObject(body) }.getOrNull()
                when (response.code) {
                    in 200..299 -> {
                        val mapped = mapSnapshot(json ?: JSONObject())
                            ?: return@use VerifyResult.Unavailable("Respuesta de verificación incompleta")
                        VerifyResult.Verified(mapped)
                    }
                    503 -> {
                        val configured = json?.optBoolean("configured", true) ?: true
                        val message = json?.optString("error").orEmpty()
                            .ifBlank { "Verificación de Play no disponible" }
                        if (!configured) VerifyResult.NotConfigured(message)
                        else VerifyResult.Unavailable(message)
                    }
                    401, 403 -> VerifyResult.Unavailable(
                        json?.optString("error").orEmpty()
                            .ifBlank { "Sesión no válida para verificar la compra" }
                    )
                    else -> VerifyResult.Unavailable(
                        json?.optString("error").orEmpty()
                            .ifBlank { "Error HTTP ${response.code}" }
                    )
                }
            }
        } catch (error: Exception) {
            VerifyResult.Unavailable(error.localizedMessage ?: "Sin red para verificar la compra")
        }
    }

    companion object {
        const val PACKAGE_NAME = "com.app.repera"
        private val JSON = "application/json".toMediaType()

        /** Mapeo estable wire ↔ CommercialSnapshot (también usable en tests JVM). */
        fun mapSnapshot(json: JSONObject, now: Long = System.currentTimeMillis()): CommercialSnapshot? {
            val wire = json.optString("status").takeIf { it.isNotBlank() && it != "null" } ?: return null
            val status = SubscriptionStatus.fromWire(wire)
            val expiry = json.optLong("expiryEpochMs", Long.MIN_VALUE)
                .takeIf { it != Long.MIN_VALUE && it > 0L }
            val productId = json.optString("productId").takeIf { it.isNotBlank() && it != "null" }
            return CommercialSnapshot(
                status = status,
                lastVerifiedProStatus = status.takeIf { it.grantsProAccess },
                lastVerifiedProAt = now.takeIf { status.grantsProAccess },
                expirationDate = expiry,
                activeProductID = productId,
                isConfigured = true,
                lastRefreshFailedOffline = false
            )
        }
    }
}
