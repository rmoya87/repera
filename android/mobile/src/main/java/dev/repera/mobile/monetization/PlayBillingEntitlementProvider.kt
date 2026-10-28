package dev.repera.mobile.monetization

import android.app.Activity
import android.content.Context
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClient.BillingResponseCode
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.PurchasesUpdatedListener
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams
import dev.repera.domain.monetization.CommercialSnapshot
import dev.repera.domain.monetization.SubscriptionStatus
import kotlin.coroutines.resume
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/**
 * Provider de Google Play Billing con modelo de seguridad estricto:
 * una compra detectada localmente NO concede Pro hasta que el backend la
 * verifique con purchases.subscriptionsv2.get (purchaseToken -> backend).
 * Documentación: android/docs/MONETIZATION_PLAY_BILLING.md.
 */
class PlayBillingEntitlementProvider(
    context: Context,
    private val billingAccountId: () -> String? = { null },
    private val activityProvider: () -> Activity? = { context as? Activity }
) : EntitlementProvider {

    data class PendingPurchase(
        val purchaseToken: String,
        val productId: String?
    )

    var pendingPurchases: List<PendingPurchase> = emptyList()
        private set

    val pendingVerificationTokens: List<String>
        get() = pendingPurchases.map { it.purchaseToken }

    private val purchaseMutex = Mutex()
    @Volatile private var purchaseWaiter: CompletableDeferred<CommercialSnapshot>? = null

    private val listener = PurchasesUpdatedListener { result, purchases ->
        val waiter = purchaseWaiter
        when (result.responseCode) {
            BillingResponseCode.OK -> {
                val owned = purchases.orEmpty().mapNotNull { it.asPending() }
                pendingPurchases = owned
                waiter?.complete(
                    CommercialSnapshot(
                        status = SubscriptionStatus.UNKNOWN,
                        isConfigured = true,
                        activeProductID = owned.firstOrNull()?.productId,
                        lastRefreshFailedOffline = false
                    )
                )
            }
            BillingResponseCode.USER_CANCELED ->
                waiter?.completeExceptionally(EntitlementError.UserCancelled())
            else ->
                waiter?.completeExceptionally(
                    EntitlementError.PurchaseFailed("Billing ${result.responseCode}")
                )
        }
        if (waiter != null) purchaseWaiter = null
    }

    override val isConfigured: Boolean get() = true

    private val client: BillingClient = BillingClient.newBuilder(context.applicationContext)
        .enablePendingPurchases(
            PendingPurchasesParams.newBuilder().enableOneTimeProducts().build()
        )
        .setListener(listener)
        .build()

    override suspend fun offerings(): CommercialOfferings {
        if (!ensureConnected()) {
            return CommercialOfferings(
                packages = emptyList(),
                unavailableReason = "Catálogo no disponible ahora mismo."
            )
        }
        return suspendCancellableCoroutine { cont ->
            val products = CommercialConfig.ALL_PRODUCT_IDS.map { id ->
                QueryProductDetailsParams.Product.newBuilder()
                    .setProductId(id)
                    .setProductType(BillingClient.ProductType.SUBS)
                    .build()
            }
            client.queryProductDetailsAsync(
                QueryProductDetailsParams.newBuilder().setProductList(products).build()
            ) { queryResult, detailsResult ->
                if (queryResult.responseCode != BillingResponseCode.OK) {
                    cont.resume(
                        CommercialOfferings(
                            packages = emptyList(),
                            unavailableReason = "Catálogo no disponible ahora mismo."
                        )
                    )
                    return@queryProductDetailsAsync
                }
                val packages = detailsResult.productDetailsList.mapNotNull { it.toPackageInfo() }
                cont.resume(
                    if (packages.isEmpty()) {
                        CommercialOfferings(
                            packages = emptyList(),
                            unavailableReason =
                                "Catálogo no configurado: pendiente decisión de productos, precios y trials en Play Console."
                        )
                    } else {
                        CommercialOfferings(packages = packages.sortedBy { it.productID })
                    }
                )
            }
        }
    }

    private fun ProductDetails.toPackageInfo(): CommercialPackageInfo? {
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

    override suspend fun purchase(productID: String): CommercialSnapshot = purchaseMutex.withLock {
        if (productID !in CommercialConfig.ALL_PRODUCT_IDS) {
            throw EntitlementError.ProductUnavailable()
        }
        val accountId = billingAccountId()?.takeIf { it.matches(Regex("[0-9a-f]{64}")) }
            ?: throw EntitlementError.PurchaseFailed("Inicia sesión antes de comprar Pro.")
        val activity = activityProvider()
            ?: throw EntitlementError.PurchaseFailed("No hay Activity para lanzar la compra.")
        if (!ensureConnected()) {
            throw EntitlementError.PurchaseFailed("Billing no disponible")
        }
        val details = queryProductDetails(productID)
            ?: throw EntitlementError.ProductUnavailable()
        val offerToken = details.subscriptionOfferDetails?.firstOrNull()?.offerToken
            ?: throw EntitlementError.ProductUnavailable()
        val deferred = CompletableDeferred<CommercialSnapshot>()
        purchaseWaiter = deferred
        val flowParams = BillingFlowParams.newBuilder()
            .setObfuscatedAccountId(accountId)
            .setProductDetailsParamsList(
                listOf(
                    BillingFlowParams.ProductDetailsParams.newBuilder()
                        .setProductDetails(details)
                        .setOfferToken(offerToken)
                        .build()
                )
            )
            .build()
        val launched = client.launchBillingFlow(activity, flowParams)
        if (launched.responseCode != BillingResponseCode.OK) {
            purchaseWaiter = null
            throw EntitlementError.PurchaseFailed(
                "No se pudo abrir el flujo de compra (${launched.responseCode})"
            )
        }
        // Local PURCHASED ≠ Pro. UNKNOWN + pending token hasta verify backend.
        return deferred.await()
    }

    override suspend fun restore(): CommercialSnapshot = refresh()

    override suspend fun refresh(): CommercialSnapshot {
        // Billing ausente (emulador sin Play, OEM, offline): UNKNOWN + cache
        // en SubscriptionManager — nunca tumbar el arranque de usuarios Gratis.
        if (!ensureConnected()) {
            return CommercialSnapshot(
                status = SubscriptionStatus.UNKNOWN,
                isConfigured = true,
                lastRefreshFailedOffline = true
            )
        }
        return suspendCancellableCoroutine { continuation ->
            client.queryPurchasesAsync(
                QueryPurchasesParams.newBuilder()
                    .setProductType(BillingClient.ProductType.SUBS)
                    .build()
            ) { purchasesResult, purchases ->
                if (purchasesResult.responseCode != BillingResponseCode.OK) {
                    continuation.resume(
                        CommercialSnapshot(
                            status = SubscriptionStatus.UNKNOWN,
                            isConfigured = true,
                            lastRefreshFailedOffline = true
                        )
                    )
                    return@queryPurchasesAsync
                }
                val owned = purchases.mapNotNull { it.asPending() }
                pendingPurchases = owned
                continuation.resume(
                    if (owned.isEmpty()) {
                        CommercialSnapshot(
                            status = SubscriptionStatus.FREE,
                            isConfigured = true,
                            lastRefreshFailedOffline = false
                        )
                    } else {
                        CommercialSnapshot(
                            status = SubscriptionStatus.UNKNOWN,
                            isConfigured = true,
                            activeProductID = owned.first().productId,
                            lastRefreshFailedOffline = false
                        )
                    }
                )
            }
        }
    }

    private suspend fun queryProductDetails(productID: String): ProductDetails? =
        suspendCancellableCoroutine { cont ->
            val product = QueryProductDetailsParams.Product.newBuilder()
                .setProductId(productID)
                .setProductType(BillingClient.ProductType.SUBS)
                .build()
            client.queryProductDetailsAsync(
                QueryProductDetailsParams.newBuilder().setProductList(listOf(product)).build()
            ) { result, details ->
                if (result.responseCode != BillingResponseCode.OK) cont.resume(null)
                else cont.resume(details.productDetailsList.firstOrNull { it.productId == productID })
            }
        }

    /** true si Billing queda listo; false si el servicio no está (sin lanzar). */
    private suspend fun ensureConnected(): Boolean {
        if (client.isReady) return true
        return suspendCancellableCoroutine { cont ->
            client.startConnection(object : BillingClientStateListener {
                override fun onBillingSetupFinished(result: BillingResult) {
                    cont.resume(result.responseCode == BillingResponseCode.OK)
                }

                override fun onBillingServiceDisconnected() = Unit
            })
        }
    }

    private fun Purchase.asPending(): PendingPurchase? {
        if (purchaseState != Purchase.PurchaseState.PURCHASED) return null
        val productId = products.firstOrNull { it in CommercialConfig.ALL_PRODUCT_IDS } ?: return null
        return PendingPurchase(purchaseToken = purchaseToken, productId = productId)
    }
}
