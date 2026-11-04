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
    /// Full app access while linked to a paying center/trainer (independent of StoreKit).
    private(set) var businessSponsoredAccess = false
    private(set) var offerings = CommercialOfferings.empty
    private(set) var isRefreshing = false
    private(set) var lastErrorMessage: String?
    private(set) var purchaseInFlight = false

    let freeUsage = FreeUsageStore()
    let paywall = PaywallCoordinator()

    /// Conteos deportivos inyectados desde ReperaStore (no viven aquí).
    private(set) var libraryRoutineCount = 0
    private(set) var favoriteCount = 0
    private(set) var customExerciseCount = 0

    @ObservationIgnored private var provider: any EntitlementProviding
    @ObservationIgnored private var didStart = false
    @ObservationIgnored private var lastForegroundRefreshAt: Date?

    var policy: FeatureAccessPolicy {
        FeatureAccessPolicy(
            snapshot: snapshot,
            freeUsage: freeUsage.state,
            libraryRoutineCount: libraryRoutineCount,
            favoriteCount: favoriteCount,
            customExerciseCount: customExerciseCount,
            businessSponsoredAccess: businessSponsoredAccess
        )
    }

    func setBusinessSponsoredAccess(_ enabled: Bool) {
        guard businessSponsoredAccess != enabled else {
            isPro = snapshot.grantsProAccess || businessSponsoredAccess
            return
        }
        businessSponsoredAccess = enabled
        isPro = snapshot.grantsProAccess || enabled
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
        // Precios y cargos directamente desde StoreKit (ASC o .storekit del scheme).
        return StoreKitEntitlementProvider()
    }

    /// El App debe instalarlo al principio de su arranque; también se llama
    /// desde start() para entornos de prueba y caminos de inicio secundarios.
    func startTransactionUpdatesObservation() {
        StoreKitEntitlementProvider.startTransactionUpdates { [weak self] in
            guard let self else { return false }
            await self.refresh(reason: "verified-storekit-transaction")
            return self.provider is StoreKitEntitlementProvider
        }
    }

    func start() async {
        guard !didStart else {
            await refresh(reason: "restart")
            return
        }
        didStart = true
        startTransactionUpdatesObservation()
        await freeUsage.load()
        // Solo entitlement en launch. Offerings se cargan al abrir el paywall.
        await refresh(reason: "launch")
    }

    /// Una acción bloqueada por una cuota consulta los derechos actuales antes
    /// de solicitar otra compra. Es una comprobación explícita, sin cooldown.
    func refreshEntitlementsForFeatureAction() async {
        if !didStart {
            await start()
        } else {
            await refresh(reason: "feature-gate")
        }
    }

    func refreshOnForeground() async {
        // Evita tormenta de customerInfo al volver de background varias veces.
        if let last = lastForegroundRefreshAt, Date().timeIntervalSince(last) < 30 {
            return
        }
        lastForegroundRefreshAt = Date()
        await refresh(reason: "foreground")
    }

    func syncCounts(libraryRoutines: Int, customExercises: Int, favorites: Int = 0) {
        guard libraryRoutineCount != libraryRoutines
            || customExerciseCount != customExercises
            || favoriteCount != favorites else { return }
        libraryRoutineCount = libraryRoutines
        customExerciseCount = customExercises
        favoriteCount = favorites
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
        // Nunca pedir que pague de nuevo a un usuario con Pro o con
        // acceso incluido en su centro. Proteger también llamadas erróneas
        // de vistas que confunden fallo de guardado con límite comercial.
        guard !policy.isPro else { return }
        if let feature, policy.canAccess(feature) { return }
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
        do {
            var loaded = try await provider.offerings()
            let validIDs: Set<String> = [
                CommercialConfig.monthlyProductID, CommercialConfig.annualProductID,
            ]
            loaded.packages = loaded.packages.filter { validIDs.contains($0.productID) }
            offerings = loaded
        } catch {
            offerings = CommercialOfferings(
                packages: [],
                unavailableReason: error.localizedDescription
            )
        }
    }

    func purchase(productID: String) async -> Bool {
        guard [CommercialConfig.monthlyProductID, CommercialConfig.annualProductID].contains(productID) else {
            lastErrorMessage = "La suscripción seleccionada no coincide con App Store Connect."
            return false
        }
        guard !purchaseInFlight else { return false }
        purchaseInFlight = true
        lastErrorMessage = nil
        defer { purchaseInFlight = false }
        do {
            let previous = snapshot
            var next = try await provider.purchase(productID: productID)
            next = await verifiedAppleAccessIfNeeded(next)
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

        let previous = snapshot
        var verifiedRestore = false
        var restoreFailure: String?
        do {
            var next = try await provider.restore()
            next = await verifiedAppleAccessIfNeeded(next)
            next = mergedVerifiedCache(next, from: previous)
            applySnapshot(next)
            verifiedRestore = next.grantsProAccess
        } catch {
            restoreFailure = error.localizedDescription
        }

        if !verifiedRestore {
            // Si AppStore.sync() falló, no ignorar una transacción local
            // todavía válida que currentEntitlements sí puede verificar.
            let apple = StoreKitEntitlementProvider()
            let appleSnapshot = await apple.refresh()
            if appleSnapshot.grantsProAccess {
                provider = apple
                applySnapshot(mergedVerifiedCache(appleSnapshot, from: previous))
                verifiedRestore = true
            }
        }

        if verifiedRestore {
            MonetizationAnalytics.track(.subscriptionRestored, context: paywall.context)
            paywall.dismiss()
            return true
        }

        lastErrorMessage = restoreFailure
            ?? "No se encontró ninguna suscripción activa para restaurar en este Apple ID."
        return false
    }

    private func refresh(reason: String) async {
        isRefreshing = true
        defer { isRefreshing = false }
        let previous = snapshot
        var next = await provider.refresh()
        // En TestFlight/App Store la compra verificada por Apple sigue siendo
        // válida aunque el proveedor principal no encuentre su entitlement.
        next = await verifiedAppleAccessIfNeeded(next)
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

    /// Solo valida transacciones firmadas por Apple y productos propios.
    /// Nunca concede Pro por un estado local o una compra no verificada.
    private func verifiedAppleAccessIfNeeded(_ snapshot: CommercialSnapshot) async -> CommercialSnapshot {
        // StoreKit es el único proveedor de producción: el snapshot ya viene de él.
        snapshot
    }

    private func applySnapshot(_ next: CommercialSnapshot) {
        guard next != snapshot else {
            isPro = snapshot.grantsProAccess || businessSponsoredAccess
            return
        }
        snapshot = next
        isPro = next.grantsProAccess || businessSponsoredAccess
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
