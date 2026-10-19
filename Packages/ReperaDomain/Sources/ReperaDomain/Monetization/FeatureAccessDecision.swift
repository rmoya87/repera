import Foundation

public enum FeatureDenialReason: String, Sendable, Codable, Equatable {
    case requiresPro
    case freeLimitReached
    case commercialUnavailable
    case subscriptionExpired
    case subscriptionRevoked
}

/// Resultado de preguntar a la política: ¿puede? ¿cuánto queda? ¿por qué no? ¿qué decir?
public struct FeatureAccessDecision: Sendable, Equatable {
    public var allowed: Bool
    public var reason: FeatureDenialReason?
    public var remainingFreeUses: Int?
    public var usedFreeUses: Int?
    public var freeLimit: Int?
    public var userMessageTitle: String?
    public var userMessageBody: String?
    public var paywallContext: PaywallContext

    public init(
        allowed: Bool,
        reason: FeatureDenialReason? = nil,
        remainingFreeUses: Int? = nil,
        usedFreeUses: Int? = nil,
        freeLimit: Int? = nil,
        userMessageTitle: String? = nil,
        userMessageBody: String? = nil,
        paywallContext: PaywallContext = .generic
    ) {
        self.allowed = allowed
        self.reason = reason
        self.remainingFreeUses = remainingFreeUses
        self.usedFreeUses = usedFreeUses
        self.freeLimit = freeLimit
        self.userMessageTitle = userMessageTitle
        self.userMessageBody = userMessageBody
        self.paywallContext = paywallContext
    }

    public static func allow(
        remainingFreeUses: Int? = nil,
        usedFreeUses: Int? = nil,
        freeLimit: Int? = nil
    ) -> FeatureAccessDecision {
        FeatureAccessDecision(
            allowed: true,
            remainingFreeUses: remainingFreeUses,
            usedFreeUses: usedFreeUses,
            freeLimit: freeLimit
        )
    }

    public static func deny(
        reason: FeatureDenialReason,
        context: PaywallContext,
        title: String,
        body: String,
        remainingFreeUses: Int? = nil,
        usedFreeUses: Int? = nil,
        freeLimit: Int? = nil
    ) -> FeatureAccessDecision {
        FeatureAccessDecision(
            allowed: false,
            reason: reason,
            remainingFreeUses: remainingFreeUses,
            usedFreeUses: usedFreeUses,
            freeLimit: freeLimit,
            userMessageTitle: title,
            userMessageBody: body,
            paywallContext: context
        )
    }
}
