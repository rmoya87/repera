import Foundation
import ReperaDomain
import StoreKit
import os

/// Precios y compras desde StoreKit 2 / App Store Connect (sin hardcodear importes).
final class StoreKitEntitlementProvider: EntitlementProviding, @unchecked Sendable {
    var isConfigured: Bool { true }

    private let logger = Logger(subsystem: "com.app.repera", category: "StoreKit")

    private let productIDs: [String] = [
        CommercialConfig.annualProductID,
        CommercialConfig.monthlyProductID,
    ]

    // Un único observador para toda la aplicación. Escucha compras aprobadas
    // después del cierre del sheet (Ask to Buy), renovaciones y reembolsos.
    @MainActor private static var updatesTask: Task<Void, Never>?
    @MainActor private static var onVerifiedUpdate: (@MainActor @Sendable () async -> Bool)?

    @MainActor
    static func startTransactionUpdates(
        onChange: @escaping @MainActor @Sendable () async -> Bool
    ) {
        onVerifiedUpdate = onChange
        guard updatesTask == nil else { return }

        updatesTask = Task.detached(priority: .utility) {
            for await verification in Transaction.updates {
                guard case .verified(let transaction) = verification else { continue }
                guard transaction.productID == CommercialConfig.monthlyProductID
                    || transaction.productID == CommercialConfig.annualProductID else { continue }
                // El manager aplica derechos verificados desde currentEntitlements
                // y solo pide finish si actualmente compra por StoreKit directo.
                let shouldFinish = await Self.processTransactionUpdate()
                if shouldFinish {
                    await transaction.finish()
                }
            }
        }
    }

    @MainActor
    private static func processTransactionUpdate() async -> Bool {
        guard let onVerifiedUpdate else { return false }
        return await onVerifiedUpdate()
    }

    func refresh() async -> CommercialSnapshot {
        await snapshotFromCurrentEntitlements()
    }

    func purchase(productID: String) async throws -> CommercialSnapshot {
        guard productIDs.contains(productID) else { throw EntitlementError.productUnavailable }
        let products = try await Product.products(for: [productID])
        guard let product = products.first else {
            throw EntitlementError.productUnavailable
        }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
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
        // StoreKit mantiene los derechos locales automáticamente, también en
        // TestFlight. Una cuenta con Pro verificado no debe depender del sync.
        let current = await snapshotFromCurrentEntitlements()
        if current.grantsProAccess { return current }

        // Solo una acción explícita del usuario permite forzar AppStore.sync().
        do {
            try await AppStore.sync()
        } catch {
            // La sincronización puede fallar en Sandbox aunque aparezca una
            // transacción firmada válida mientras esperábamos la respuesta.
            let recovered = await snapshotFromCurrentEntitlements()
            if recovered.grantsProAccess { return recovered }

            let nsError = error as NSError
            logger.error("AppStore.sync failed: domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)")
            throw EntitlementError.restoreFailed(
                "Apple no ha podido sincronizar las compras (código \(nsError.code)). " +
                "En TestFlight, comprueba la cuenta Sandbox y vuelve a intentarlo."
            )
        }

        let restored = await snapshotFromCurrentEntitlements()
        guard restored.grantsProAccess else {
            throw EntitlementError.restoreFailed(
                "Apple no ha encontrado ninguna suscripción Pro activa en esta cuenta de prueba. " +
                "Las suscripciones de TestFlight pueden caducar después de sus renovaciones aceleradas."
            )
        }
        return restored
    }

    func offerings() async throws -> CommercialOfferings {
        let products: [Product]
        do {
            products = try await Product.products(for: Set(productIDs))
        } catch {
            let nsError = error as NSError
            logger.error("Product.products failed: domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)")
            throw EntitlementError.productUnavailable
        }
        guard !products.isEmpty else {
            // Un catálogo vacío no demuestra que la suscripción haya vencido:
            // suele requerir revisar productos/territorios en App Store Connect.
            return CommercialOfferings(
                packages: [],
                unavailableReason: "Apple no está ofreciendo los planes de Repera. " +
                    "Comprueba su disponibilidad en App Store Connect y vuelve a intentarlo."
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

    private func snapshotFromCurrentEntitlements() async -> CommercialSnapshot {
        var activeProductID: String?
        var expiration: Date?
        var isTrial = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            guard productIDs.contains(transaction.productID) else { continue }
            if let exp = transaction.expirationDate, exp < Date() { continue }
            activeProductID = transaction.productID
            expiration = transaction.expirationDate
            isTrial = transaction.offer?.type == .introductory
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
