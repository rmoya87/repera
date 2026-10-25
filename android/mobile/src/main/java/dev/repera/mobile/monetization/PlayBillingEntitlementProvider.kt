package dev.repera.mobile.monetization

import android.content.Context
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClient.BillingResponseCode
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.PurchasesUpdatedListener
import com.android.billingclient.api.QueryPurchasesParams
import dev.repera.domain.monetization.CommercialSnapshot
import dev.repera.domain.monetization.SubscriptionStatus
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

/** Tokens detectados localmente pendientes de verificación backend. */

/**
 * Provider de Google Play Billing con modelo de seguridad estricto:
 * una compra detectada localmente NO concede Pro hasta que el backend la
 * verifique con purchases.subscriptionsv2.get (purchaseToken -> backend).
 * Por eso todos los snapshots devueltos llevan isVerified=false: la política
 * efectiva mantiene UNKNOWN y grantsProAccess=false mientras no exista el
 * paso de verificación. Documentación: android/docs/MONETIZATION_PLAY_BILLING.md.
 */
class PlayBillingEntitlementProvider(
    context: Context,
    private val onPurchasesChanged: suspend () -> Unit = {}
) : EntitlementProvider {

    var pendingVerificationTokens: List<String> = emptyList()
        private set

    private val listener = PurchasesUpdatedListener { _, purchases ->
        pendingVerificationTokens =
            purchases.orEmpty().mapNotNull { it.pendingVerificationToken() }
    }

    override val isConfigured: Boolean get() = true

    private val client: BillingClient = BillingClient.newBuilder(context.applicationContext)
        .enablePendingPurchases(
            PendingPurchasesParams.newBuilder().enableOneTimeProducts().build()
        )
        .setListener(listener)
        .build()

    /** Lectura de catálogo: precios REALES de Play (queryProductDetails).
     *  Nada de importes en código; solo lectura, sin habilitar cobro ni Pro. */
    override suspend fun offerings(): CommercialOfferings = suspendCoroutine { cont ->
        client.startConnection(object : com.android.billingclient.api.BillingClientStateListener {
            override fun onBillingSetupFinished(result: com.android.billingclient.api.BillingResult) {
                if (result.responseCode != BillingResponseCode.OK) {
                    client.endConnection()
                    cont.resume(CommercialOfferings(
                        packages = emptyList(),
                        unavailableReason = "Catálogo no disponible ahora mismo."
                    ))
                    return
                }
                val products = CommercialConfig.ALL_PRODUCT_IDS.map { id ->
                    com.android.billingclient.api.QueryProductDetailsParams.Product.newBuilder()
                        .setProductId(id)
                        .setProductType(BillingClient.ProductType.SUBS)
                        .build()
                }
                client.queryProductDetailsAsync(
                    com.android.billingclient.api.QueryProductDetailsParams.newBuilder()
                        .setProductList(products).build()
                ) { queryResult, detailsResult ->
                    client.endConnection()
                    if (queryResult.responseCode != BillingResponseCode.OK) {
                        cont.resume(CommercialOfferings(
                            packages = emptyList(),
                            unavailableReason = "Catálogo no disponible ahora mismo."
                        ))
                        return@queryProductDetailsAsync
                    }
                    val packages = detailsResult.productDetailsList.mapNotNull { it.toPackageInfo() }
                    if (packages.isEmpty()) {
                        // Estado live 25/10: sin productos en Play Console aún.
                        cont.resume(CommercialOfferings(
                            packages = emptyList(),
                            unavailableReason = "Catálogo no configurado: pendiente decisión de productos, precios y trials en Play Console."
                        ))
                    } else {
                        cont.resume(CommercialOfferings(
                            packages = packages.sortedBy { it.productID }
                        ))
                    }
                }
            }

            override fun onBillingServiceDisconnected() = Unit
        })
    }

    /** Plan base del producto: última fase = precio recurrente; una fase
     *  previa a 0 € = trial. Sin importes hardcodeados. */
    private fun com.android.billingclient.api.ProductDetails.toPackageInfo(): CommercialPackageInfo? {
        val offer = subscriptionOfferDetails?.firstOrNull() ?: return null
        val phases = offer.pricingPhases.pricingPhaseList
        val recurring = phases.lastOrNull() ?: return null
        val hasTrial = phases.dropLast(1).any { it.priceAmountMicros == 0L }
        return CommercialPackageInfo(
            productID = productId,
            localizedPrice = recurring.formattedPrice,
            localizedTitle = title,
            localizedDescription = description,
            isAnnual = productId == CommercialConfig.ANNUAL_PRODUCT_ID,
            hasFreeTrial = hasTrial,
            priceValue = recurring.priceAmountMicros / 1_000_000.0,
            currencyCode = recurring.priceCurrencyCode
        )
    }

    override suspend fun purchase(productID: String): CommercialSnapshot {
        // Sin catálogo configurado ni backend de verificación, ninguna compra concede Pro.
        throw EntitlementError.PurchaseFailed(
            "Compras deshabilitadas: catálogo sin configurar y verificación backend pendiente."
        )
    }

    override suspend fun restore(): CommercialSnapshot = refresh()

    override suspend fun refresh(): CommercialSnapshot = suspendCoroutine { continuation ->
        val resumeUnknown = {
            continuation.resume(
                CommercialSnapshot(
                    status = SubscriptionStatus.UNKNOWN,
                    isConfigured = true,
                    lastRefreshFailedOffline = true
                )
            )
            Unit
        }
        client.startConnection(object : com.android.billingclient.api.BillingClientStateListener {
            override fun onBillingSetupFinished(result: com.android.billingclient.api.BillingResult) {
                if (result.responseCode != BillingResponseCode.OK) {
                    client.endConnection()
                    resumeUnknown()
                    return
                }
                client.queryPurchasesAsync(
                    QueryPurchasesParams.newBuilder()
                        .setProductType(BillingClient.ProductType.SUBS)
                        .build()
                ) { purchasesResult, purchases ->
                    client.endConnection()
                    if (purchasesResult.responseCode != BillingResponseCode.OK) {
                        resumeUnknown()
                        return@queryPurchasesAsync
                    }
                    val active = purchases.firstOrNull {
                        it.purchaseState == Purchase.PurchaseState.PURCHASED &&
                            it.products.any { p -> p in CommercialConfig.ALL_PRODUCT_IDS }
                    }
                    if (active == null) {
                        pendingVerificationTokens = emptyList()
                        continuation.resume(
                            CommercialSnapshot(
                                status = SubscriptionStatus.FREE,
                                isConfigured = true,
                                lastRefreshFailedOffline = true
                            )
                        )
                    } else {
                        // Detectada localmente: PENDIENTE DE VERIFICACIÓN.
                        // UNKNOWN sin caché verificada = no concede Pro.
                        pendingVerificationTokens = listOf(active.purchaseToken)
                        continuation.resume(
                            CommercialSnapshot(
                                status = SubscriptionStatus.UNKNOWN,
                                isConfigured = true,
                                activeProductID = active.products.firstOrNull(),
                                lastRefreshFailedOffline = false
                            )
                        )
                    }
                }
            }

            override fun onBillingServiceDisconnected() = Unit
        })
    }

    /** Reconocimiento local de compra una vez VERIFICADA en backend (futuro). */
    suspend fun acknowledgeVerifiedPurchase(purchaseToken: String) = suspendCoroutine<Unit> { cont ->
        client.startConnection(object : com.android.billingclient.api.BillingClientStateListener {
            override fun onBillingSetupFinished(result: com.android.billingclient.api.BillingResult) {
                if (result.responseCode != BillingResponseCode.OK) {
                    client.endConnection()
                    cont.resumeWithException(EntitlementError.RestoreFailed("Billing no disponible"))
                    return
                }
                client.acknowledgePurchase(
                    AcknowledgePurchaseParams.newBuilder().setPurchaseToken(purchaseToken).build()
                ) { ack ->
                    client.endConnection()
                    if (ack.responseCode == BillingResponseCode.OK) cont.resume(Unit)
                    else cont.resumeWithException(
                        EntitlementError.RestoreFailed("Acknowledge falló: ${ack.responseCode}")
                    )
                }
            }

            override fun onBillingServiceDisconnected() = Unit
        })
    }

    private fun Purchase.pendingVerificationToken(): String? =
        if (purchaseState == Purchase.PurchaseState.PURCHASED &&
            products.any { it in CommercialConfig.ALL_PRODUCT_IDS }
        ) purchaseToken else null
}
