package dev.repera.mobile.monetization

import dev.repera.domain.monetization.CommercialSnapshot
import dev.repera.domain.monetization.SubscriptionStatus

/**
 * Abstracción de derechos comerciales. Port 1:1 de EntitlementProvider.swift.
 * SEGURIDAD: un provider on-device NO verifica autenticidad; toda compra
 * detectada queda "pendiente de verificación" hasta que el backend la
 * confirme (ver android/docs/MONETIZATION_PLAY_BILLING.md).
 */
interface EntitlementProvider {
    val isConfigured: Boolean
    suspend fun refresh(): CommercialSnapshot
    suspend fun purchase(productID: String): CommercialSnapshot
    suspend fun restore(): CommercialSnapshot
    suspend fun offerings(): CommercialOfferings
}

data class CommercialPackageInfo(
    val productID: String,
    val localizedPrice: String,
    val localizedTitle: String,
    val localizedDescription: String,
    val isAnnual: Boolean,
    val introductoryOfferSummary: String? = null,
    val hasFreeTrial: Boolean = false,
    /** Precio anual equivalente del mensual x12 (si aplica) para calcular ahorro. */
    val priceValue: Double? = null,
    val currencyCode: String? = null
)

data class CommercialOfferings(
    val packages: List<CommercialPackageInfo>,
    val unavailableReason: String? = null
) {
    companion object {
        val empty = CommercialOfferings(emptyList(), "Productos no configurados")
    }
}

sealed class EntitlementError(message: String) : Exception(message) {
    class NotConfigured : EntitlementError("Las compras no están configuradas en este build.")
    class ProductUnavailable : EntitlementError("No hay productos disponibles ahora mismo.")
    class UserCancelled : EntitlementError("Compra cancelada.")
    class PurchaseFailed(message: String) : EntitlementError(message)
    class RestoreFailed(message: String) : EntitlementError(message)
}

/**
 * Producción sin backend de verificación: Gratis, sin compras ficticias.
 * Equivalente al stub UnconfiguredEntitlementProvider de iOS.
 */
class UnconfiguredEntitlementProvider : EntitlementProvider {
    override val isConfigured: Boolean get() = false
    override suspend fun refresh(): CommercialSnapshot =
        CommercialSnapshot(status = SubscriptionStatus.FREE, isConfigured = false)
    override suspend fun purchase(productID: String): CommercialSnapshot =
        throw EntitlementError.NotConfigured()
    override suspend fun restore(): CommercialSnapshot =
        throw EntitlementError.NotConfigured()
    override suspend fun offerings(): CommercialOfferings = CommercialOfferings(
        packages = emptyList(),
        unavailableReason = "Las compras se activarán cuando la verificación de pago esté configurada."
    )
}

/** IDs comerciales centralizados (sin secretos). Paridad CommercialConfig.swift. */
object CommercialConfig {
    const val MONTHLY_PRODUCT_ID = "com.app.repera.premium.monthly"
    const val ANNUAL_PRODUCT_ID = "com.app.repera.premium.yearly"
    val ALL_PRODUCT_IDS = setOf(MONTHLY_PRODUCT_ID, ANNUAL_PRODUCT_ID)
    const val PRIVACY_POLICY_URL = "https://repera.app/privacy"
    const val TERMS_OF_USE_URL = "https://repera.app/terms"
    /** Deep link de gestión de suscripciones de Google Play. */
    const val MANAGE_SUBSCRIPTIONS_URL =
        "https://play.google.com/store/account/subscriptions"
}
