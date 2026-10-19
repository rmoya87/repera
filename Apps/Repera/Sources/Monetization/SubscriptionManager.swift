import Foundation
import ReperaDomain
import Observation
import SwiftUI

/// Fachada observable: estado comercial + política + cuotas + paywall.
@MainActor
@Observable
final class SubscriptionManager {
    private(set) var snapshot = CommercialSnapshot()
    /// Cache estable: las vistas que solo leen Pro no se invalidan por cuotas/conteos.
    private(set) var isPro = false
    private(set) var offerings = CommercialOfferings.empty
    private(set) var isLoadingOfferings = false
    private(set) var isRefreshing = false
    private(set) var lastErrorMessage: String?
    private(set) var purchaseInFlight = false

    let freeUsage = FreeUsageStore()
    let paywall = PaywallCoordinator()

    /// Conteos deportivos inyectados desde ReperaStore (no viven aquí).
    private(set) var libraryRoutineCount = 0
    private(set) var customExerciseCount = 0

    @ObservationIgnored private var provider: any EntitlementProviding
    /// The catalog and the purchase must use the same provider.
    @ObservationIgnored private var offeringProvider: (any EntitlementProviding)?
    @ObservationIgnored private var didStart = false
    @ObservationIgnored private var lastForegroundRefreshAt: Date?

    var policy: FeatureAccessPolicy {
        FeatureAccessPolicy(
            snapshot: snapshot,
            freeUsage: freeUsage.state,
            libraryRoutineCount: libraryRoutineCount,
            customExerciseCount: customExerciseCount
        )
    }

    var status: SubscriptionStatus { snapshot.effectiveStatus() }

    init(provider: (any EntitlementProviding)? = nil) {
        if let provider {
            self.provider = provider
        } else {
            self.provider = Self.makeDefaultProvider()
        }
    }

    private static func makeDefaultProvider() -> any EntitlementProviding {
        #if DEBUG
        if DebugEntitlementController.shared.overrideEnabled {
            return DebugEntitlementController.shared.provider
        }
        #endif
        if let key = CommercialConfig.publicAPIKey {
            #if canImport(RevenueCat)
            // RevenueCat expone precios localizados desde App Store Connect / StoreKit.
            return RevenueCatEntitlementProvider(apiKey: key)
            #else
            return StoreKitEntitlementProvider()
            #endif
        }
        // Sin RevenueCat: precios y cargos directamente desde StoreKit (ASC o .storekit del scheme).
        return StoreKitEntitlementProvider()
    }

    func start() async {
        guard !didStart else {
            await refresh(reason: "restart")
            return
        }
        didStart = true
        await freeUsage.load()
        // Solo entitlement en launch. Offerings se cargan al abrir el paywall.
        await refresh(reason: "launch")
    }

    func refreshOnForeground() async {
        // Evita tormenta de customerInfo al volver de background varias veces.
        if let last = lastForegroundRefreshAt, Date().timeIntervalSince(last) < 30 {
            return
        }
        lastForegroundRefreshAt = Date()
        await refresh(reason: "foreground")
    }

    func syncCounts(libraryRoutines: Int, customExercises: Int) {
        guard libraryRoutineCount != libraryRoutines || customExerciseCount != customExercises else { return }
        libraryRoutineCount = libraryRoutines
        customExerciseCount = customExercises
    }

    func decision(for feature: ReperaFeature) -> FeatureAccessDecision {
        policy.decision(for: feature)
    }

    func canCreateLibraryRoutine(isNew: Bool) -> FeatureAccessDecision {
        policy.canCreateLibraryRoutine(isNew: isNew)
    }

    func canCreateCustomExercise(isNew: Bool) -> FeatureAccessDecision {
        policy.canCreateCustomExercise(isNew: isNew)
    }

    func canStartBoardScan() -> FeatureAccessDecision {
        policy.canStartBoardScan()
    }

    func canSelectProgressRange(_ range: ProgressTimeRange) -> FeatureAccessDecision {
        policy.canSelectProgressRange(range)
    }

    @discardableResult
    func consumeBoardScanIfNeeded(attemptID: String) -> Bool {
        freeUsage.consumeBoardScan(attemptID: attemptID, isPro: isPro)
    }

    func presentPaywall(_ context: PaywallContext, feature: ReperaFeature? = nil) {
        if let feature, !policy.canAccess(feature) {
            MonetizationAnalytics.track(.premiumFeatureTapped, feature: feature, context: context)
        }
        if let decision = feature.map({ policy.decision(for: $0) }), !decision.allowed,
           decision.reason == .freeLimitReached {
            MonetizationAnalytics.track(.freeLimitReached, feature: feature, context: context)
        }
        paywall.present(context)
        MonetizationAnalytics.track(.paywallViewed, feature: feature, context: context)
    }

    func dismissPaywall() {
        paywall.dismiss()
        MonetizationAnalytics.track(.paywallDismissed, context: paywall.context)
    }

    func loadOfferings() async {
        guard !isLoadingOfferings else { return }
        isLoadingOfferings = true
        lastErrorMessage = nil
        defer { isLoadingOfferings = false }
        // Never retain an old catalog's purchasing route after a retry.
        offeringProvider = nil
        do {
            let loaded = try await provider.offerings()
            if !loaded.packages.isEmpty {
                offerings = loaded
                offeringProvider = provider
                return
            }
            // RevenueCat may have no configured offering while Apple products exist.
            // Fallback must switch both the catalog AND the purchasing route.
            if !(provider is StoreKitEntitlementProvider) {
                let storeKit = StoreKitEntitlementProvider()
                let fallback = try await storeKit.offerings()
                if !fallback.packages.isEmpty {
                    offerings = fallback
                    offeringProvider = storeKit
                    return
                }
            }
            offerings = loaded
        } catch {
            do {
                let storeKit = StoreKitEntitlementProvider()
                let fallback = try await storeKit.offerings()
                offerings = fallback
                if !fallback.packages.isEmpty {
                    offeringProvider = storeKit
                    return
                }
            } catch {
                offerings = CommercialOfferings(packages: [], unavailableReason: error.localizedDescription)
            }
        }
        lastErrorMessage = offerings.unavailableReason
            ?? "No se pudieron cargar los planes. Comprueba las suscripciones en App Store Connect."
    }

    func purchase(productID: String) async -> Bool {
        guard !purchaseInFlight else { return false }
        purchaseInFlight = true
        lastErrorMessage = nil
        defer { purchaseInFlight = false }
        do {
            let previous = snapshot
            let source = offeringProvider ?? provider
            var next: CommercialSnapshot
            do {
                next = try await source.purchase(productID: productID)
            } catch EntitlementError.productUnavailable where !(source is StoreKitEntitlementProvider) {
                // RevenueCat could not resolve this product before starting a purchase.
                // Use native StoreKit for the same App Store Connect product ID.
                next = try await StoreKitEntitlementProvider().purchase(productID: productID)
            }
            if !next.grantsProAccess {
                // RevenueCat customerInfo may lag behind the verified Apple transaction.
                let apple = await StoreKitEntitlementProvider().refresh()
                if apple.grantsProAccess { next = apple }
            }
            next = mergedVerifiedCache(next, from: previous)
            applySnapshot(next)
            if snapshot.grantsProAccess {
                if snapshot.status == .trial {
                    MonetizationAnalytics.track(.trialStarted, context: paywall.context, productID: productID)
                } else {
                    MonetizationAnalytics.track(.subscriptionStarted, context: paywall.context, productID: productID)
                }
                paywall.dismiss()
                return true
            }
            lastErrorMessage = "Apple no ha confirmado todavía la suscripción. Comprueba el estado de la compra o inténtalo de nuevo."
            return false
        } catch EntitlementError.userCancelled {
            return false
        } catch {
            lastErrorMessage = error.localizedDescription
            MonetizationAnalytics.track(
                .purchaseFailed,
                context: paywall.context,
                productID: productID,
                result: error.localizedDescription
            )
            return false
        }
    }

    func restorePurchases() async -> Bool {
        guard !purchaseInFlight else { return false }
        purchaseInFlight = true
        lastErrorMessage = nil
        defer { purchaseInFlight = false }
        do {
            let previous = snapshot
            let source = offeringProvider ?? provider
            var next: CommercialSnapshot
            do {
                next = try await source.restore()
            } catch {
                // A StoreKit-verified purchase remains restorable even if
                // RevenueCat is unavailable or its offering is not configured.
                guard !(source is StoreKitEntitlementProvider) else { throw error }
                next = try await StoreKitEntitlementProvider().restore()
            }
            if !next.grantsProAccess && !(source is StoreKitEntitlementProvider) {
                let storeKit = await StoreKitEntitlementProvider().refresh()
                if storeKit.grantsProAccess { next = storeKit }
            }
            next = mergedVerifiedCache(next, from: previous)
            applySnapshot(next)
            if snapshot.grantsProAccess {
                MonetizationAnalytics.track(.subscriptionRestored, context: paywall.context)
                paywall.dismiss()
                return true
            }
            lastErrorMessage = "No se encontró ninguna suscripción para restaurar."
            return false
        } catch {
            lastErrorMessage = error.localizedDescription
            return false
        }
    }

    private func refresh(reason: String) async {
        isRefreshing = true
        defer { isRefreshing = false }
        let previous = snapshot
        var next = await provider.refresh()
        // A failed/missing RevenueCat entitlement must not hide a verified
        // Apple subscription, including one purchased via the StoreKit fallback.
        #if canImport(RevenueCat)
        if provider is RevenueCatEntitlementProvider && !next.grantsProAccess {
            let storeKit = await StoreKitEntitlementProvider().refresh()
            if storeKit.grantsProAccess { next = storeKit }
        }
        #endif
        // Offline: si el provider devolvió unknown, conservar Pro verificado.
        if next.status == .unknown, previous.grantsProAccess || previous.lastVerifiedProStatus != nil {
            next.lastVerifiedProStatus = previous.lastVerifiedProStatus ?? previous.status
            next.lastVerifiedProAt = previous.lastVerifiedProAt ?? Date()
            next.expirationDate = next.expirationDate ?? previous.expirationDate
            next.lastRefreshFailedOffline = true
        } else if next.grantsProAccess {
            next.lastVerifiedProStatus = next.status
            next.lastVerifiedProAt = Date()
        }
        applySnapshot(next)
        _ = reason
    }

    private func applySnapshot(_ next: CommercialSnapshot) {
        guard next != snapshot else {
            isPro = snapshot.grantsProAccess
            return
        }
        snapshot = next
        isPro = next.grantsProAccess
    }

    private func mergedVerifiedCache(_ snapshot: CommercialSnapshot, from previous: CommercialSnapshot) -> CommercialSnapshot {
        var next = snapshot
        if next.grantsProAccess {
            next.lastVerifiedProStatus = next.status
            next.lastVerifiedProAt = Date()
        } else if next.status == .unknown {
            next.lastVerifiedProStatus = previous.lastVerifiedProStatus
            next.lastVerifiedProAt = previous.lastVerifiedProAt
            next.expirationDate = next.expirationDate ?? previous.expirationDate
        }
        return next
    }

    #if DEBUG
    func applyDebugProvider() {
        provider = DebugEntitlementController.shared.provider
        Task { await refresh(reason: "debug") }
    }
    #endif
}
