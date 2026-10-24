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
 * SEGURIDAD (decisión 24-oct): Pro solo se concede desde snapshots
 * verificados por backend. Con el provider no configurado, el estado es
 * Gratis/UNKNOWN y la caché offline solo consolida lo ya verificado.
 */
class SubscriptionManager(
    private var provider: EntitlementProvider = UnconfiguredEntitlementProvider(),
    val freeUsage: FreeUsageStore
) {
    var snapshot by mutableStateOf(CommercialSnapshot())
        private set
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

    val paywall = PaywallCoordinator()

    private var libraryRoutineCount = 0
    private var customExerciseCount = 0
    private var didStart = false
    private var lastForegroundRefreshAt: Long? = null


    val policy: FeatureAccessPolicy
        get() = FeatureAccessPolicy(
            snapshot = snapshot,
            freeUsage = freeUsage.state,
            libraryRoutineCount = libraryRoutineCount,
            customExerciseCount = customExerciseCount,
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

    fun syncCounts(libraryRoutines: Int, customExercises: Int) {
        if (libraryRoutineCount == libraryRoutines && customExerciseCount == customExercises) return
        libraryRoutineCount = libraryRoutines
        customExerciseCount = customExercises
    }

    fun decision(feature: ReperaFeature): FeatureAccessDecision = policy.decision(feature)
    fun canCreateLibraryRoutine(isNew: Boolean) = policy.canCreateLibraryRoutine(isNew)
    fun canCreateCustomExercise(isNew: Boolean) = policy.canCreateCustomExercise(isNew)
    fun canStartBoardScan() = policy.canStartBoardScan()
    fun canSelectProgressRange(range: ProgressTimeRange) = policy.canSelectProgressRange(range)

    fun consumeBoardScanIfNeeded(attemptID: String): Boolean =
        freeUsage.consumeBoardScan(attemptID, isPro)

    fun presentPaywall(context: PaywallContext, feature: ReperaFeature? = null) {
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
            val next = mergedVerifiedCache(provider.purchase(productID), previous)
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
            val next = mergedVerifiedCache(provider.restore(), previous)
            applySnapshot(next)
            if (snapshot.grantsProAccess) {
                MonetizationAnalytics.track(
                    MonetizationAnalytics.Event.SUBSCRIPTION_RESTORED, context = paywall.context
                )
                paywall.dismiss()
                return true
            }
            lastErrorMessage = "No se encontró ninguna suscripción para restaurar."
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
            val previous = snapshot
            var next = provider.refresh()
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

    private fun applySnapshot(next: CommercialSnapshot) {
        if (next == snapshot) {
            isPro = snapshot.grantsProAccess || businessSponsoredAccess
            return
        }
        snapshot = next
        isPro = next.grantsProAccess || businessSponsoredAccess
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
