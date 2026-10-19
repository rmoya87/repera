#if canImport(RevenueCat)
import Foundation
import ReperaDomain
import RevenueCat

/// Proveedor real de derechos vía RevenueCat + StoreKit.
final class RevenueCatEntitlementProvider: NSObject, EntitlementProviding, @unchecked Sendable {
    private let apiKey: String
    private var didConfigure = false

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    var isConfigured: Bool { true }

    private func ensureConfigured() {
        guard !didConfigure else { return }
        // `.debug` satura la consola y ralentiza el arranque en simulador.
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: apiKey)
        didConfigure = true
    }

    func refresh() async -> CommercialSnapshot {
        ensureConfigured()
        do {
            let info = try await Purchases.shared.customerInfo()
            return Self.map(info: info, configured: true, offlineFailure: false)
        } catch {
            return CommercialSnapshot(
                status: .unknown,
                isConfigured: true,
                lastRefreshFailedOffline: true
            )
        }
    }

    func purchase(productID: String) async throws -> CommercialSnapshot {
        ensureConfigured()
        let products = await Purchases.shared.products([productID])
        guard let product = products.first else {
            throw EntitlementError.productUnavailable
        }
        do {
            let result = try await Purchases.shared.purchase(product: product)
            if result.userCancelled {
                throw EntitlementError.userCancelled
            }
            return Self.map(info: result.customerInfo, configured: true, offlineFailure: false)
        } catch let error as EntitlementError {
            throw error
        } catch {
            let ns = error as NSError
            if ns.domain == ErrorCode.errorDomain,
               ErrorCode(rawValue: ns.code) == .purchaseCancelledError {
                throw EntitlementError.userCancelled
            }
            throw EntitlementError.purchaseFailed(error.localizedDescription)
        }
    }

    func restore() async throws -> CommercialSnapshot {
        ensureConfigured()
        do {
            let info = try await Purchases.shared.restorePurchases()
            return Self.map(info: info, configured: true, offlineFailure: false)
        } catch {
            throw EntitlementError.restoreFailed(error.localizedDescription)
        }
    }

    func offerings() async throws -> CommercialOfferings {
        ensureConfigured()
        do {
            let offerings = try await Purchases.shared.offerings()
            let offering = offerings.offering(identifier: CommercialConfig.offeringID) ?? offerings.current
            guard let offering else {
                return CommercialOfferings(packages: [], unavailableReason: "No hay offering «default».")
            }
            let packages = offering.availablePackages.compactMap { Self.mapPackage($0) }
            if packages.isEmpty {
                return CommercialOfferings(packages: [], unavailableReason: "Offering sin paquetes.")
            }
            return CommercialOfferings(packages: packages, unavailableReason: nil)
        } catch {
            throw EntitlementError.productUnavailable
        }
    }

    // MARK: - Mapping

    static func map(info: CustomerInfo, configured: Bool, offlineFailure: Bool) -> CommercialSnapshot {
        let entitlement = info.entitlements[CommercialConfig.entitlementID]
        guard let entitlement, entitlement.isActive else {
            let inactive = info.entitlements.all[CommercialConfig.entitlementID]
            let status: SubscriptionStatus
            if inactive?.unsubscribeDetectedAt != nil {
                status = .revoked
            } else if inactive != nil {
                status = .expired
            } else {
                status = .free
            }
            return CommercialSnapshot(
                status: status,
                isConfigured: configured,
                lastRefreshFailedOffline: offlineFailure
            )
        }

        let productID = entitlement.productIdentifier
        let periodType = entitlement.periodType
        let status: SubscriptionStatus
        if entitlement.billingIssueDetectedAt != nil {
            status = .gracePeriod
        } else if periodType == .trial {
            status = .trial
        } else if productID == CommercialConfig.monthlyProductID {
            status = .proMonthly
        } else if productID == CommercialConfig.annualProductID {
            status = .proAnnual
        } else {
            status = .proAnnual
        }

        return CommercialSnapshot(
            status: status,
            lastVerifiedProStatus: status,
            lastVerifiedProAt: Date(),
            expirationDate: entitlement.expirationDate,
            activeProductID: productID,
            isConfigured: configured,
            lastRefreshFailedOffline: offlineFailure
        )
    }

    private static func mapPackage(_ package: Package) -> CommercialPackageInfo? {
        let product = package.storeProduct
        let isAnnual = package.packageType == .annual
            || product.productIdentifier == CommercialConfig.annualProductID
        let intro = product.introductoryDiscount
        var introSummary: String?
        var hasTrial = false
        if let intro {
            if intro.paymentMode == .freeTrial {
                hasTrial = true
                let units = intro.subscriptionPeriod.value
                switch intro.subscriptionPeriod.unit {
                case .day:
                    introSummary = units == 14 ? "14 días gratis" : "\(units) días gratis"
                case .week:
                    introSummary = "\(units) semana\(units == 1 ? "" : "s") gratis"
                case .month:
                    introSummary = "\(units) mes\(units == 1 ? "" : "es") gratis"
                case .year:
                    introSummary = "\(units) año\(units == 1 ? "" : "s") gratis"
                @unknown default:
                    introSummary = "Oferta introductoria"
                }
            } else if intro.paymentMode == .payUpFront || intro.paymentMode == .payAsYouGo {
                introSummary = "Oferta introductoria: \(intro.localizedPriceString)"
            }
        }
        return CommercialPackageInfo(
            productID: product.productIdentifier,
            localizedPrice: product.localizedPriceString,
            localizedTitle: product.localizedTitle,
            localizedDescription: product.localizedDescription,
            isAnnual: isAnnual,
            introductoryOfferSummary: introSummary,
            hasFreeTrial: hasTrial,
            priceValue: product.price,
            currencyCode: product.currencyCode
        )
    }
}
#endif
