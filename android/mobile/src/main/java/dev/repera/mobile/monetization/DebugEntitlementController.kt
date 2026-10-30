package dev.repera.mobile.monetization

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import dev.repera.domain.monetization.CommercialSnapshot
import dev.repera.domain.monetization.SubscriptionStatus

/**
 * Override local de entitlements para builds debug / emulador.
 * Port de DebugEntitlementController.swift (iOS).
 */
object DebugEntitlementController {
    var overrideEnabled by mutableStateOf(false)
    var forcedStatus by mutableStateOf(SubscriptionStatus.FREE)
    var simulateOffline by mutableStateOf(false)

    fun applyTo(base: CommercialSnapshot): CommercialSnapshot {
        if (!overrideEnabled) return base
        if (simulateOffline) {
            return CommercialSnapshot(
                status = SubscriptionStatus.UNKNOWN,
                lastVerifiedProStatus = if (forcedStatus.grantsProAccess) forcedStatus else null,
                lastVerifiedProAt = System.currentTimeMillis(),
                lastRefreshFailedOffline = true,
                isConfigured = true,
                expirationDate = base.expirationDate,
                activeProductID = base.activeProductID
            )
        }
        return CommercialSnapshot(
            status = forcedStatus,
            lastVerifiedProStatus = if (forcedStatus.grantsProAccess) forcedStatus else null,
            lastVerifiedProAt = System.currentTimeMillis(),
            isConfigured = true,
            expirationDate = base.expirationDate,
            activeProductID = base.activeProductID
        )
    }
}
