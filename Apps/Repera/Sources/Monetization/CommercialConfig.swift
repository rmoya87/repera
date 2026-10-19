import Foundation

/// Identificadores comerciales centralizados. No incluye secretos.
enum CommercialConfig {
    static let entitlementID = "pro"
    static let offeringID = "default"
    static let monthlyProductID = "repera_pro_monthly"
    static let annualProductID = "repera_pro_annual"

    /// Clave pública del SDK (`appl_…`). Proviene de Info.plist / xcconfig — nunca hardcodear secretos.
    static var publicAPIKey: String? {
        let raw = Bundle.main.object(forInfoDictionaryKey: "RevenueCatPublicAPIKey") as? String
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty,
              trimmed != "YOUR_REVENUECAT_PUBLIC_API_KEY",
              trimmed.hasPrefix("appl_") || trimmed.hasPrefix("test_") else {
            return nil
        }
        return trimmed
    }

    static var isConfigured: Bool { publicAPIKey != nil }

    static let privacyPolicyURL = URL(string: "https://repera.app/privacy")!
    static let termsOfUseURL = URL(string: "https://repera.app/terms")!
    /// Deep link de gestión de suscripciones de Apple.
    static let manageSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!
}
