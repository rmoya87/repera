import Foundation
import ReperaDomain

#if DEBUG
/// Solo Debug: simula estados comerciales sin StoreKit. Nunca se enlaza en Release.
@MainActor
@Observable
final class DebugEntitlementController {
    static let shared = DebugEntitlementController()

    var overrideEnabled = false
    var forcedStatus: SubscriptionStatus = .free
    var simulateOffline = false
    var offeringsUnavailable = false

    var provider: DebugEntitlementProvider {
        DebugEntitlementProvider(controller: self)
    }
}

final class DebugEntitlementProvider: EntitlementProviding, @unchecked Sendable {
    private let controller: DebugEntitlementController

    init(controller: DebugEntitlementController) {
        self.controller = controller
    }

    var isConfigured: Bool { true }

    @MainActor
    private var status: SubscriptionStatus {
        controller.overrideEnabled ? controller.forcedStatus : .free
    }

    func refresh() async -> CommercialSnapshot {
        await MainActor.run {
            if controller.simulateOffline {
                let last: SubscriptionStatus? = controller.forcedStatus.grantsProAccess
                    ? controller.forcedStatus : nil
                return CommercialSnapshot(
                    status: .unknown,
                    lastVerifiedProStatus: last,
                    lastVerifiedProAt: last != nil ? Date() : nil,
                    expirationDate: last != nil ? Date().addingTimeInterval(86_400 * 30) : nil,
                    isConfigured: true,
                    lastRefreshFailedOffline: true
                )
            }
            return map(status)
        }
    }

    func purchase(productID: String) async throws -> CommercialSnapshot {
        await MainActor.run {
            if productID == CommercialConfig.monthlyProductID {
                controller.forcedStatus = .proMonthly
            } else {
                controller.forcedStatus = .proAnnual
            }
            controller.overrideEnabled = true
            return map(controller.forcedStatus)
        }
    }

    func restore() async throws -> CommercialSnapshot {
        await MainActor.run {
            controller.overrideEnabled = true
            if !controller.forcedStatus.grantsProAccess {
                controller.forcedStatus = .proAnnual
            }
            return map(controller.forcedStatus)
        }
    }

    func offerings() async throws -> CommercialOfferings {
        await MainActor.run {
            if controller.offeringsUnavailable {
                return .empty
            }
            return CommercialOfferings(
                packages: [
                    CommercialPackageInfo(
                        productID: CommercialConfig.annualProductID,
                        localizedPrice: "39,99 €",
                        localizedTitle: "Repera Pro Anual",
                        localizedDescription: "Facturación anual",
                        isAnnual: true,
                        introductoryOfferSummary: "14 días gratis",
                        hasFreeTrial: true,
                        priceValue: Decimal(string: "39.99"),
                        currencyCode: "EUR"
                    ),
                    CommercialPackageInfo(
                        productID: CommercialConfig.monthlyProductID,
                        localizedPrice: "5,99 €",
                        localizedTitle: "Repera Pro Mensual",
                        localizedDescription: "Facturación mensual",
                        isAnnual: false,
                        introductoryOfferSummary: nil,
                        hasFreeTrial: false,
                        priceValue: Decimal(string: "5.99"),
                        currencyCode: "EUR"
                    ),
                ],
                unavailableReason: nil
            )
        }
    }

    private func map(_ status: SubscriptionStatus) -> CommercialSnapshot {
        let grants = status.grantsProAccess
        return CommercialSnapshot(
            status: status,
            lastVerifiedProStatus: grants ? status : nil,
            lastVerifiedProAt: grants ? Date() : nil,
            expirationDate: grants ? Date().addingTimeInterval(86_400 * 30) : nil,
            activeProductID: status == .proMonthly
                ? CommercialConfig.monthlyProductID
                : (grants ? CommercialConfig.annualProductID : nil),
            isConfigured: true,
            lastRefreshFailedOffline: false
        )
    }
}
#endif
