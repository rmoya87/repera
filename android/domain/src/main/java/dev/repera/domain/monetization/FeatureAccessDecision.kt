package dev.repera.domain.monetization

enum class FeatureDenialReason(val wire: String) {
    REQUIRES_PRO("requiresPro"),
    FREE_LIMIT_REACHED("freeLimitReached"),
    COMMERCIAL_UNAVAILABLE("commercialUnavailable"),
    SUBSCRIPTION_EXPIRED("subscriptionExpired"),
    SUBSCRIPTION_REVOKED("subscriptionRevoked")
}

/**
 * Resultado de preguntar a la política: ¿puede? ¿cuánto queda? ¿por qué no? ¿qué decir?
 * Port 1:1 de FeatureAccessDecision.swift.
 */
data class FeatureAccessDecision(
    val allowed: Boolean,
    val reason: FeatureDenialReason? = null,
    val remainingFreeUses: Int? = null,
    val usedFreeUses: Int? = null,
    val freeLimit: Int? = null,
    val userMessageTitle: String? = null,
    val userMessageBody: String? = null,
    val paywallContext: PaywallContext = PaywallContext.GENERIC
) {
    companion object {
        fun allow(
            remainingFreeUses: Int? = null,
            usedFreeUses: Int? = null,
            freeLimit: Int? = null
        ) = FeatureAccessDecision(
            allowed = true,
            remainingFreeUses = remainingFreeUses,
            usedFreeUses = usedFreeUses,
            freeLimit = freeLimit
        )

        fun deny(
            reason: FeatureDenialReason,
            context: PaywallContext,
            title: String,
            body: String,
            remainingFreeUses: Int? = null,
            usedFreeUses: Int? = null,
            freeLimit: Int? = null
        ) = FeatureAccessDecision(
            allowed = false,
            reason = reason,
            remainingFreeUses = remainingFreeUses,
            usedFreeUses = usedFreeUses,
            freeLimit = freeLimit,
            userMessageTitle = title,
            userMessageBody = body,
            paywallContext = context
        )
    }
}
