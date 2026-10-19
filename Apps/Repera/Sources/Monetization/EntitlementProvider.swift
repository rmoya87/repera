import Foundation
import ReperaDomain

/// Abstracción de derechos comerciales (RevenueCat / Debug / stub).
protocol EntitlementProviding: AnyObject, Sendable {
    var isConfigured: Bool { get }
    func refresh() async -> CommercialSnapshot
    func purchase(productID: String) async throws -> CommercialSnapshot
    func restore() async throws -> CommercialSnapshot
    func offerings() async throws -> CommercialOfferings
}

struct CommercialPackageInfo: Sendable, Equatable, Identifiable {
    var id: String { productID }
    var productID: String
    var localizedPrice: String
    var localizedTitle: String
    var localizedDescription: String
    var isAnnual: Bool
    var introductoryOfferSummary: String?
    var hasFreeTrial: Bool
    /// Precio anual equivalente del mensual × 12 (si aplica) para calcular ahorro.
    var priceValue: Decimal?
    var currencyCode: String?
}

struct CommercialOfferings: Sendable, Equatable {
    var packages: [CommercialPackageInfo]
    var unavailableReason: String?

    static let empty = CommercialOfferings(packages: [], unavailableReason: "Productos no configurados")
}

enum EntitlementError: Error, LocalizedError, Sendable {
    case notConfigured
    case productUnavailable
    case userCancelled
    case purchaseFailed(String)
    case restoreFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Las compras no están configuradas en este build."
        case .productUnavailable:
            return "No hay productos disponibles ahora mismo."
        case .userCancelled:
            return "Compra cancelada."
        case .purchaseFailed(let message):
            return message
        case .restoreFailed(let message):
            return message
        }
    }
}

/// Stub de producción cuando no hay API key: Gratis, sin compras ficticias.
final class UnconfiguredEntitlementProvider: EntitlementProviding, @unchecked Sendable {
    var isConfigured: Bool { false }

    func refresh() async -> CommercialSnapshot {
        CommercialSnapshot(status: .free, isConfigured: false)
    }

    func purchase(productID: String) async throws -> CommercialSnapshot {
        throw EntitlementError.notConfigured
    }

    func restore() async throws -> CommercialSnapshot {
        throw EntitlementError.notConfigured
    }

    func offerings() async throws -> CommercialOfferings {
        CommercialOfferings(
            packages: [],
            unavailableReason: "Configura RevenueCatPublicAPIKey para activar compras."
        )
    }
}
