package dev.repera.mobile.monetization

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import dev.repera.domain.ProgressTimeRange
import dev.repera.domain.monetization.CommercialSnapshot
import dev.repera.domain.monetization.FeatureAccessDecision
import dev.repera.domain.monetization.FeatureAccessPolicy
import dev.repera.domain.monetization.PaywallContext
import dev.repera.domain.monetization.ReperaFeature
import dev.repera.domain.monetization.SubscriptionStatus

/**
 * Fachada observable: estado comercial + política + cuotas + paywall.
 * Port 1:1 de SubscriptionManager.swift.
 *
 * SEGURIDAD: Pro solo se concede desde snapshots verificados por backend
 * ([PlayPurchaseVerifyClient]). La detección local de Play queda UNKNOWN
 * hasta verify; la caché offline solo consolida lo ya verificado.
 */
class SubscriptionManager(
    private var provider: EntitlementProvider = UnconfiguredEntitlementProvider(),
    val freeUsage: FreeUsageStore,
    private val verifyClient: PlayPurchaseVerifyClient? = null,
    private val accessTokenProvider: () -> String? = { null }
) {
    var snapshot by mutableStateOf(CommercialSnapshot())
        private set
    /** Snapshot de Billing/verify antes del override debug. */
    private var backingSnapshot: CommercialSnapshot = CommercialSnapshot()
    /** Cache estable: las vistas que solo leen Pro no se invalidan por cuotas. */
    var isPro by mutableStateOf(false)
        private set
    /** Acceso completo mientras está vinculado a un centro/entrenador que paga. */
    var businessSponsoredAccess by mutableStateOf(false)
        private set
    var offerings by mutableStateOf(CommercialOfferings.empty)
        private set
    var isRefreshing by mutableStateOf(false)
        private set
    var lastErrorMessage by mutableStateOf<String?>(null)
        private set
    var purchaseInFlight by mutableStateOf(false)
        private set
    /** true cuando el Edge Function responde configured=false (falta SA de Ramón). */
    var verificationBackendConfigured by mutableStateOf(true)
        private set

    val paywall = PaywallCoordinator()

    private var libraryRoutineCount = 0
    private var customExerciseCount = 0
    private var favoriteCount = 0
    private var didStart = false
    private var lastForegroundRefreshAt: Long? = null

    val policy: FeatureAccessPolicy
        get() = FeatureAccessPolicy(
            snapshot = snapshot,
            freeUsage = freeUsage.state,
            libraryRoutineCount = libraryRoutineCount,
            customExerciseCount = customExerciseCount,
            favoriteCount = favoriteCount,
            businessSponsoredAccess = businessSponsoredAccess
        )

    fun updateBusinessSponsoredAccess(enabled: Boolean) {
        if (businessSponsoredAccess == enabled) {
            isPro = snapshot.grantsProAccess || businessSponsoredAccess
            return
        }
        businessSponsoredAccess = enabled
        isPro = snapshot.grantsProAccess || enabled
    }

    val status: SubscriptionStatus get() = snapshot.effectiveStatus()

    suspend fun start() {
        if (didStart) {
            refresh()
            return
        }
        didStart = true
        freeUsage.load()
        refresh()
    }

    suspend fun refreshOnForeground() {
        val last = lastForegroundRefreshAt
        if (last != null && System.currentTimeMillis() - last < 30_000) return
        lastForegroundRefreshAt = System.currentTimeMillis()
        refresh()
    }

    fun syncCounts(libraryRoutines: Int, customExercises: Int, favorites: Int = favoriteCount) {
        if (libraryRoutineCount == libraryRoutines &&
            customExerciseCount == customExercises &&
            favoriteCount == favorites
        ) return
        libraryRoutineCount = libraryRoutines
        customExerciseCount = customExercises
        favoriteCount = favorites
    }

    fun decision(feature: ReperaFeature): FeatureAccessDecision = policy.decision(feature)
    fun canCreateLibraryRoutine(isNew: Boolean) = policy.canCreateLibraryRoutine(isNew)
    fun canCreateCustomExercise(isNew: Boolean) = policy.canCreateCustomExercise(isNew)
    fun canCreateFavorite(isNew: Boolean) = policy.canCreateFavorite(isNew)
    fun canStartBoardScan() = policy.canStartBoardScan()
    fun canSelectProgressRange(range: ProgressTimeRange) = policy.canSelectProgressRange(range)

    fun consumeBoardScanIfNeeded(attemptID: String): Boolean =
        freeUsage.consumeBoardScan(attemptID, isPro)

    /** Comprobar Play y el backend verificador antes de anunciar un upgrade. */
    suspend fun refreshEntitlementsForFeatureAction() {
        if (didStart) refresh() else start()
    }

    fun presentPaywall(context: PaywallContext, feature: ReperaFeature? = null) {
        // Igual que en iOS: no vender a un Pro verificado ni a un deportista
        // con acceso incluido por su entrenador/centro.
        if (policy.isPro || (feature != null && policy.canAccess(feature))) return
        if (feature != null && !policy.canAccess(feature)) {
            MonetizationAnalytics.track(
                MonetizationAnalytics.Event.PREMIUM_FEATURE_TAPPED, feature = feature, context = context
            )
        }
        if (feature != null) {
            val decision = policy.decision(feature)
            if (!decision.allowed && decision.reason == dev.repera.domain.monetization.FeatureDenialReason.FREE_LIMIT_REACHED) {
                MonetizationAnalytics.track(
                    MonetizationAnalytics.Event.FREE_LIMIT_REACHED, feature = feature, context = context
                )
            }
        }
        paywall.present(context)
        MonetizationAnalytics.track(MonetizationAnalytics.Event.PAYWALL_VIEWED, feature = feature, context = context)
    }

    fun dismissPaywall() {
        paywall.dismiss()
        MonetizationAnalytics.track(MonetizationAnalytics.Event.PAYWALL_DISMISSED, context = paywall.context)
    }

    suspend fun loadOfferings() {
        offerings = try {
            val loaded = provider.offerings()
            val validIDs = setOf(CommercialConfig.MONTHLY_PRODUCT_ID, CommercialConfig.ANNUAL_PRODUCT_ID)
            loaded.copy(packages = loaded.packages.filter { it.productID in validIDs })
        } catch (error: Exception) {
            CommercialOfferings(emptyList(), error.message)
        }
    }

    suspend fun purchase(productID: String): Boolean {
        if (productID !in setOf(CommercialConfig.MONTHLY_PRODUCT_ID, CommercialConfig.ANNUAL_PRODUCT_ID)) {
            lastErrorMessage = "La suscripción seleccionada no coincide con el catálogo."
            return false
        }
        if (purchaseInFlight) return false
        purchaseInFlight = true
        lastErrorMessage = null
        try {
            val previous = snapshot
            var next = mergedVerifiedCache(provider.purchase(productID), previous)
            next = verifyPendingIfNeeded(next, previous)
            applySnapshot(next)
            if (snapshot.grantsProAccess) {
                if (snapshot.status == SubscriptionStatus.TRIAL) {
                    MonetizationAnalytics.track(
                        MonetizationAnalytics.Event.TRIAL_STARTED,
                        context = paywall.context, productID = productID
                    )
                } else {
                    MonetizationAnalytics.track(
                        MonetizationAnalytics.Event.SUBSCRIPTION_STARTED,
                        context = paywall.context, productID = productID
                    )
                }
                paywall.dismiss()
                return true
            }
            if (!verificationBackendConfigured) {
                lastErrorMessage =
                    "Compra detectada, pero la verificación de Play aún no está configurada en el servidor."
            } else if (snapshot.status == SubscriptionStatus.UNKNOWN) {
                lastErrorMessage = "Compra pendiente de verificación. Reintenta al recuperar la red."
            }
            return false
        } catch (_: EntitlementError.UserCancelled) {
            return false
        } catch (error: Exception) {
            lastErrorMessage = error.message
            MonetizationAnalytics.track(
                MonetizationAnalytics.Event.PURCHASE_FAILED,
                context = paywall.context, productID = productID, result = error.message
            )
            return false
        } finally {
            purchaseInFlight = false
        }
    }

    suspend fun restorePurchases(): Boolean {
        purchaseInFlight = true
        lastErrorMessage = null
        try {
            val previous = snapshot
            var next = mergedVerifiedCache(provider.restore(), previous)
            next = verifyPendingIfNeeded(next, previous)
            applySnapshot(next)
            if (snapshot.grantsProAccess) {
                MonetizationAnalytics.track(
                    MonetizationAnalytics.Event.SUBSCRIPTION_RESTORED, context = paywall.context
                )
                paywall.dismiss()
                return true
            }
            lastErrorMessage = when {
                !verificationBackendConfigured ->
                    "La verificación de Play aún no está configurada en el servidor."
                else -> "No se encontró ninguna suscripción para restaurar."
            }
            return false
        } catch (error: Exception) {
            lastErrorMessage = error.message
            return false
        } finally {
            purchaseInFlight = false
        }
    }

    private suspend fun refresh() {
        isRefreshing = true
        try {
            val previous = backingSnapshot
            var next = try {
                provider.refresh()
            } catch (error: Exception) {
                // Billing/red caídos en arranque: conservar caché, no tumbar la app.
                lastErrorMessage = error.message
                CommercialSnapshot(
                    status = SubscriptionStatus.UNKNOWN,
                    isConfigured = provider.isConfigured,
                    lastRefreshFailedOffline = true,
                    lastVerifiedProStatus = previous.lastVerifiedProStatus,
                    lastVerifiedProAt = previous.lastVerifiedProAt,
                    expirationDate = previous.expirationDate,
                    activeProductID = previous.activeProductID
                )
            }
            next = verifyPendingIfNeeded(next, previous)
            // Offline: si el provider devolvió unknown, conservar Pro verificado.
            if (next.status == SubscriptionStatus.UNKNOWN &&
                (previous.grantsProAccess || previous.lastVerifiedProStatus != null)
            ) {
                next = next.copy(
                    lastVerifiedProStatus = previous.lastVerifiedProStatus ?: previous.status,
                    lastVerifiedProAt = previous.lastVerifiedProAt ?: System.currentTimeMillis(),
                    expirationDate = next.expirationDate ?: previous.expirationDate,
                    lastRefreshFailedOffline = true
                )
            } else if (next.grantsProAccess) {
                next = next.copy(
                    lastVerifiedProStatus = next.status,
                    lastVerifiedProAt = System.currentTimeMillis()
                )
            }
            applySnapshot(next)
        } finally {
            isRefreshing = false
        }
    }

    /**
     * Si Play reportó tokens pendientes y hay cliente + sesión, consulta el
     * Edge Function. Solo un snapshot verificado concede Pro / actualiza caché.
     */
    private suspend fun verifyPendingIfNeeded(
        incoming: CommercialSnapshot,
        previous: CommercialSnapshot
    ): CommercialSnapshot {
        val play = provider as? PlayBillingEntitlementProvider ?: return incoming
        val pending = play.pendingPurchases
        if (pending.isEmpty()) return incoming
        val client = verifyClient ?: return incoming
        val token = accessTokenProvider()?.takeIf { it.isNotBlank() }
        if (token == null) {
            // Compra local sin sesión: no se puede verificar; UNKNOWN sin Pro.
            return mergedVerifiedCache(incoming, previous)
        }
        val first = pending.first()
        return when (val result = client.verify(token, first.purchaseToken, first.productId)) {
            is PlayPurchaseVerifyClient.VerifyResult.Verified -> {
                verificationBackendConfigured = true
                mergedVerifiedCache(result.snapshot, previous)
            }
            is PlayPurchaseVerifyClient.VerifyResult.NotConfigured -> {
                verificationBackendConfigured = false
                lastErrorMessage = result.message
                mergedVerifiedCache(incoming, previous)
            }
            is PlayPurchaseVerifyClient.VerifyResult.Unavailable -> {
                lastErrorMessage = result.message
                mergedVerifiedCache(
                    incoming.copy(lastRefreshFailedOffline = true),
                    previous
                )
            }
        }
    }

    /** Reaplica el snapshot de Billing respetando el override debug. */
    fun applyDebugProvider() {
        publishSnapshot(backingSnapshot)
    }

    private fun applySnapshot(next: CommercialSnapshot) {
        backingSnapshot = next
        publishSnapshot(next)
    }

    private fun publishSnapshot(next: CommercialSnapshot) {
        val effective = DebugEntitlementController.applyTo(next)
        if (effective == snapshot) {
            isPro = snapshot.grantsProAccess || businessSponsoredAccess
            return
        }
        snapshot = effective
        isPro = effective.grantsProAccess || businessSponsoredAccess
    }

    private fun mergedVerifiedCache(
        incoming: CommercialSnapshot,
        previous: CommercialSnapshot
    ): CommercialSnapshot {
        var next = incoming
        if (next.grantsProAccess) {
            next = next.copy(
                lastVerifiedProStatus = next.status,
                lastVerifiedProAt = System.currentTimeMillis()
            )
        } else if (next.status == SubscriptionStatus.UNKNOWN) {
            next = next.copy(
                lastVerifiedProStatus = previous.lastVerifiedProStatus,
                lastVerifiedProAt = previous.lastVerifiedProAt,
                expirationDate = next.expirationDate ?: previous.expirationDate
            )
        }
        return next
    }
}
