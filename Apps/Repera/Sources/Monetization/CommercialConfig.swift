import Foundation

/// Identificadores comerciales centralizados. No incluye secretos.
enum CommercialConfig {
    /// Identificador lógico de Pro (StoreKit / política). No hay SDK de terceros.
    static let entitlementID = "pro"
    static let monthlyProductID = "com.app.repera.premium.monthly"
    static let annualProductID = "com.app.repera.premium.yearly"

    static let privacyPolicyURL = URL(string: "https://repera.app/privacy")!
    static let termsOfUseURL = URL(string: "https://repera.app/terms")!
    /// Deep link de gestión de suscripciones de Apple.
    static let manageSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!
}
