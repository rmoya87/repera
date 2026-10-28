package dev.repera.mobile.monetization

import android.util.Log
import dev.repera.domain.monetization.PaywallContext
import dev.repera.domain.monetization.ReperaFeature

/** Instrumentación desacoplada: hoy solo logging local. Sin terceros. */
object MonetizationAnalytics {
    private const val TAG = "Monetization"

    enum class Event(val wire: String) {
        PAYWALL_VIEWED("paywall_viewed"),
        PAYWALL_DISMISSED("paywall_dismissed"),
        PREMIUM_FEATURE_TAPPED("premium_feature_tapped"),
        FREE_LIMIT_REACHED("free_limit_reached"),
        TRIAL_STARTED("trial_started"),
        SUBSCRIPTION_STARTED("subscription_started"),
        SUBSCRIPTION_RESTORED("subscription_restored"),
        PURCHASE_FAILED("purchase_failed")
    }

    fun track(
        event: Event,
        feature: ReperaFeature? = null,
        context: PaywallContext? = null,
        productID: String? = null,
        result: String? = null
    ) {
        val parts = mutableListOf(event.wire)
        feature?.let { parts += "feature=${it.wire}" }
        context?.let { parts += "context=${it.wire}" }
        productID?.let { parts += "product=$it" }
        result?.let { parts += "result=$it" }
        Log.i(TAG, parts.joinToString(" "))
    }
}
