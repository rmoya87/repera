import Foundation
import ReperaDomain
import StoreKit

/// Precios y compras desde StoreKit / App Store Connect (sin hardcodear importes).
/// Se usa cuando no hay clave RevenueCat, o como fuente de verdad de catálogo local/sandbox.
final class StoreKitEntitlementProvider: EntitlementProviding, @unchecked Sendable {
    var isConfigured: Bool { true }

    private let productIDs: [String] = [
        CommercialConfig.annualProductID,
        CommercialConfig.monthlyProductID,
    ]

    func refresh() async -> CommercialSnapshot {
        await snapshotFromCurrentEntitlements()
    }

    func purchase(productID: String) async throws -> CommercialSnapshot {
        let products = try await Product.products(for: [productID])
        guard let product = products.first else {
            throw EntitlementError.productUnavailable
        }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            // The verified transaction itself is authoritative. currentEntitlements
            // can lag behind the purchase callback in TestFlight's sandbox.
            let purchased = snapshotFromVerifiedTransaction(
                transaction,
                isFreeTrial: product.subscription?.introductoryOffer?.paymentMode == .freeTrial
            )
            await transaction.finish()
            if purchased.grantsProAccess { return purchased }
            return await snapshotFromCurrentEntitlements()
        case .userCancelled:
            throw EntitlementError.userCancelled
        case .pending:
            throw EntitlementError.purchaseFailed("La compra está pendiente de aprobación.")
        @unknown default:
            throw EntitlementError.purchaseFailed("Resultado de compra desconocido.")
        }
    }

    func restore() async throws -> CommercialSnapshot {
        try await AppStore.sync()
        let snap = await snapshotFromCurrentEntitlements()
        if !snap.grantsProAccess {
            throw EntitlementError.restoreFailed("No se encontró ninguna suscripción para restaurar.")
        }
        return snap
    }

    func offerings() async throws -> CommercialOfferings {
        let products = try await Product.products(for: Set(productIDs))
        guard !products.isEmpty else {
            return CommercialOfferings(
                packages: [],
                unavailableReason: "Apple no ha devuelto los planes de Repera Pro. Comprueba en App Store Connect el bundle com.app.repera, los productos repera_pro_monthly y repera_pro_annual y el acuerdo de aplicaciones de pago."
            )
        }
        let packages = products.compactMap(Self.mapProduct(_:))
            .sorted { lhs, rhs in
                // Anual primero (destacado).
                if lhs.isAnnual != rhs.isAnnual { return lhs.isAnnual && !rhs.isAnnual }
                return lhs.productID < rhs.productID
            }
        return CommercialOfferings(packages: packages, unavailableReason: nil)
    }

    // MARK: - Helpers

    private func snapshotFromVerifiedTransaction(
        _ transaction: Transaction,
        isFreeTrial: Bool
    ) -> CommercialSnapshot {
        guard productIDs.contains(transaction.productID),
              transaction.revocationDate == nil,
              !transaction.isUpgraded,
              transaction.expirationDate.map({ $0 > Date() }) ?? true else {
            return CommercialSnapshot(status: .free, isConfigured: true)
        }
        let status: ReperaDomain.SubscriptionStatus
        if isFreeTrial && transaction.offer?.type == .introductory {
            status = .trial
        } else if transaction.productID == CommercialConfig.monthlyProductID {
            status = .proMonthly
        } else {
            status = .proAnnual
        }
        return CommercialSnapshot(
            status: status,
            lastVerifiedProStatus: status,
            lastVerifiedProAt: Date(),
            expirationDate: transaction.expirationDate,
            activeProductID: transaction.productID,
            isConfigured: true,
            lastRefreshFailedOffline: false
        )
    }

    private func snapshotFromCurrentEntitlements() async -> CommercialSnapshot {
        var activeProductID: String?
        var expiration: Date?
        var isTrial = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            guard productIDs.contains(transaction.productID),
                  transaction.revocationDate == nil,
                  !transaction.isUpgraded else { continue }
            if let exp = transaction.expirationDate, exp < Date() { continue }
            activeProductID = transaction.productID
            expiration = transaction.expirationDate
            // Only the configured monthly intro is a free trial; annual intro is discounted.
            isTrial = transaction.offer?.type == .introductory
                && transaction.productID == CommercialConfig.monthlyProductID
        }

        guard let activeProductID else {
            return CommercialSnapshot(status: .free, isConfigured: true)
        }

        let status: ReperaDomain.SubscriptionStatus
        if isTrial {
            status = .trial
        } else if activeProductID == CommercialConfig.monthlyProductID {
            status = .proMonthly
        } else {
            status = .proAnnual
        }

        return CommercialSnapshot(
            status: status,
            lastVerifiedProStatus: status,
            lastVerifiedProAt: Date(),
            expirationDate: expiration,
            activeProductID: activeProductID,
            isConfigured: true,
            lastRefreshFailedOffline: false
        )
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw EntitlementError.purchaseFailed(error.localizedDescription)
        case .verified(let value):
            return value
        }
    }

    private static func mapProduct(_ product: Product) -> CommercialPackageInfo? {
        let isAnnual = product.id == CommercialConfig.annualProductID
            || product.subscription?.subscriptionPeriod.unit == .year
        var introSummary: String?
        var hasTrial = false
        if let intro = product.subscription?.introductoryOffer {
            if intro.paymentMode == .freeTrial {
                hasTrial = true
                let value = intro.period.value
                switch intro.period.unit {
                case .day:
                    introSummary = value == 14 ? "14 días gratis" : "\(value) días gratis"
                case .week:
                    introSummary = "\(value) semana\(value == 1 ? "" : "s") gratis"
                case .month:
                    introSummary = "\(value) mes\(value == 1 ? "" : "es") gratis"
                case .year:
                    introSummary = "\(value) año\(value == 1 ? "" : "s") gratis"
                @unknown default:
                    introSummary = "Oferta introductoria"
                }
            } else {
                introSummary = "Oferta introductoria: \(intro.displayPrice)"
            }
        }
        return CommercialPackageInfo(
            productID: product.id,
            localizedPrice: product.displayPrice,
            localizedTitle: product.displayName,
            localizedDescription: product.description,
            isAnnual: isAnnual,
            introductoryOfferSummary: introSummary,
            hasFreeTrial: hasTrial,
            priceValue: product.price,
            currencyCode: product.priceFormatStyle.locale.currency?.identifier
        )
    }
}
