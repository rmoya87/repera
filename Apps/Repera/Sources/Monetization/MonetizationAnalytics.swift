import Foundation
import ReperaDomain
import os

/// Instrumentación comercial: logging local y adaptador GA4 (activo si Firebase está configurado).
@MainActor
enum MonetizationAnalytics {
    private static let log = Logger(subsystem: "com.app.repera", category: "Monetization")

    static func track(
        _ event: Event,
        feature: ReperaFeature? = nil,
        context: PaywallContext? = nil,
        productID: String? = nil,
        result: String? = nil
    ) {
        var parts: [String] = [event.rawValue]
        if let feature { parts.append("feature=\(feature.rawValue)") }
        if let context { parts.append("context=\(context.rawValue)") }
        if let productID { parts.append("product=\(productID)") }
        if let result { parts.append("result=\(result)") }
        log.info("\(parts.joined(separator: " "), privacy: .public)")
        if let canonical = ReperaAnalytics.Event(rawValue: event.rawValue) {
            var parameters: [String: String] = [:]
            if let feature { parameters["feature_id"] = feature.rawValue }
            if let context { parameters["paywall_context"] = context.rawValue }
            if let result { parameters["result"] = result }
            // Product identifiers remain with the verified billing source, not GA4.
            ReperaAnalytics.track(canonical, parameters: parameters)
        }
    }

    enum Event: String {
        case paywallViewed = "paywall_viewed"
        case paywallDismissed = "paywall_dismissed"
        case premiumFeatureTapped = "premium_feature_tapped"
        case freeLimitReached = "free_limit_reached"
        case trialStarted = "trial_started"
        case subscriptionStarted = "subscription_started"
        case subscriptionRestored = "subscription_restored"
        case purchaseFailed = "purchase_failed"
    }
}
