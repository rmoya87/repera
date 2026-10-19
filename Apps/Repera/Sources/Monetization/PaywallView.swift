import ReperaDomain
import SwiftUI

struct PaywallView: View {
    enum Mode {
        case sheet
        case onboarding
    }

    var mode: Mode = .sheet
    var onContinueFree: (() -> Void)?
    var onPurchaseSuccess: (() -> Void)?

    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(\.openURL) private var openURL

    @State private var selectedProductID: String?
    @State private var showError = false
    @State private var isPreparing = true

    private var context: PaywallContext {
        mode == .onboarding ? .onboarding : subscriptions.paywall.context
    }
    private var packages: [CommercialPackageInfo] { subscriptions.offerings.packages }
    private var annual: CommercialPackageInfo? { packages.first(where: \.isAnnual) }
    private var monthly: CommercialPackageInfo? { packages.first(where: { !$0.isAnnual }) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    benefits
                    plans
                    primaryCTA
                    secondaryActions
                    legalFooter
                }
                .padding(.horizontal, OG.pad)
                .padding(.bottom, 28)
            }
            .background(OG.bg)
            .ogTransparentNav()
            .toolbar {
                if mode == .sheet {
                    ToolbarItem(placement: .topBarTrailing) {
                        CloseToolbarButton(
                            action: { subscriptions.dismissPaywall() },
                            large: false
                        )
                    }
                }
            }
            .task {
                // Real Apple prices and sandbox products, never fictitious purchases.
                await reloadProducts()
            }
            .onChange(of: packages.map(\.productID)) { _, _ in
                if selectedProductID == nil
                    || !packages.contains(where: { $0.productID == selectedProductID }) {
                    selectedProductID = annual?.productID ?? monthly?.productID
                }
            }
            .alert("No se pudo completar", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(subscriptions.lastErrorMessage ?? "Inténtalo de nuevo.")
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            if mode == .onboarding {
                HStack {
                    Spacer(minLength: 0)
                    ReperaMascot(pose: .hero, maxHeight: 160)
                    Spacer(minLength: 0)
                }
            } else {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(OG.accent)
                    .accessibilityHidden(true)
            }
            Text(context.headline)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(OG.label)
            Text(context.subtitle)
                .font(.body)
                .foregroundStyle(OG.label2)
        }
        .padding(.top, 8)
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(context.prioritizedBenefits, id: \.self) { benefit in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(OG.accent)
                    Text(benefit)
                        .foregroundStyle(OG.label)
                        .font(.subheadline)
                }
            }
        }
        .padding(OG.pad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }

    @ViewBuilder
    private var plans: some View {
        if packages.isEmpty {
            OGCard {
                VStack(alignment: .leading, spacing: 8) {
                    if isPreparing || subscriptions.isLoadingOfferings {
                        ProgressView("Cargando planes de Apple…")
                            .tint(OG.accent)
                    } else {
                        Text("Planes no disponibles")
                            .font(.headline)
                            .foregroundStyle(OG.label)
                        Text(subscriptions.offerings.unavailableReason
                             ?? "No se han encontrado suscripciones para esta app en App Store Connect.")
                            .font(.footnote)
                            .foregroundStyle(OG.label2)
                        Text("En TestFlight las compras se prueban con Sandbox. Los productos deben existir en App Store Connect.")
                            .font(.caption)
                            .foregroundStyle(OG.label3)
                    }
                }
            }
        } else {
            VStack(spacing: 10) {
                if let annual {
                    planRow(annual, badge: savingsBadge(annual: annual, monthly: monthly))
                }
                if let monthly {
                    planRow(monthly, badge: nil)
                }
            }
        }
    }

    private func planRow(_ package: CommercialPackageInfo, badge: String?) -> some View {
        let selected = selectedProductID == package.productID
        return Button {
            selectedProductID = package.productID
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? OG.accent : OG.label3)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(package.isAnnual ? "Anual" : "Mensual")
                            .font(.headline)
                            .foregroundStyle(OG.label)
                        if let badge {
                            Text(badge)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(OG.onAccent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(OG.accent, in: Capsule())
                        }
                    }
                    Text(package.localizedPrice + (package.isAnnual ? " / año" : " / mes"))
                        .font(.subheadline)
                        .foregroundStyle(OG.label2)
                    if let intro = package.introductoryOfferSummary {
                        Text(intro)
                            .font(.caption)
                            .foregroundStyle(OG.accent)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(OG.pad)
            .background(
                RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous)
                    .fill(OG.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous)
                            .strokeBorder(selected ? OG.accent : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(package.isAnnual ? "Anual" : "Mensual"), \(package.localizedPrice)")
    }

    private var primaryCTA: some View {
        let title: String = {
            if isPreparing || subscriptions.isLoadingOfferings {
                return "Cargando planes…"
            }
            if packages.isEmpty {
                return "Volver a cargar planes"
            }
            if let id = selectedProductID,
               let pkg = packages.first(where: { $0.productID == id }),
               pkg.hasFreeTrial {
                return "Probar Repera Pro"
            }
            return "Continuar con Repera Pro"
        }()
        return Button {
            Task { await handlePrimaryAction() }
        } label: {
            HStack(spacing: 10) {
                if isPreparing || subscriptions.isLoadingOfferings || subscriptions.purchaseInFlight {
                    ProgressView().tint(OG.onAccent)
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(OG.onAccent)
            .background(OG.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(isPreparing || subscriptions.isLoadingOfferings || subscriptions.purchaseInFlight)
        .accessibilityLabel(title)
    }

    private func reloadProducts() async {
        isPreparing = true
        defer { isPreparing = false }
        if mode == .onboarding {
            subscriptions.paywall.present(.onboarding)
        }
        await subscriptions.start()
        await subscriptions.loadOfferings()
        if selectedProductID == nil
            || !packages.contains(where: { $0.productID == selectedProductID }) {
            selectedProductID = annual?.productID ?? monthly?.productID
        }
    }

    private func handlePrimaryAction() async {
        guard !subscriptions.purchaseInFlight else { return }
        guard let id = selectedProductID,
              packages.contains(where: { $0.productID == id }) else {
            await reloadProducts()
            if packages.isEmpty {
                showError = true
            }
            return
        }
        let purchased = await subscriptions.purchase(productID: id)
        if purchased {
            if mode == .sheet {
                subscriptions.dismissPaywall()
            }
            onPurchaseSuccess?()
        } else if subscriptions.lastErrorMessage != nil {
            showError = true
        }
    }

    private var secondaryActions: some View {
        VStack(spacing: 12) {
            if mode == .onboarding {
                Button("Seguir con el plan Gratis") {
                    onContinueFree?()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(OG.label)
            }

            Button("Restaurar compras") {
                Task {
                    let ok = await subscriptions.restorePurchases()
                    if ok {
                        if mode == .onboarding {
                            onPurchaseSuccess?()
                        }
                    } else {
                        showError = true
                    }
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(OG.accent)
            .disabled(subscriptions.purchaseInFlight)

            if mode == .sheet {
                Button("Gestionar suscripción") {
                    openURL(CommercialConfig.manageSubscriptionsURL)
                }
                .font(.subheadline)
                .foregroundStyle(OG.label2)
            }

            HStack(spacing: 16) {
                Button("Privacidad") { openURL(CommercialConfig.privacyPolicyURL) }
                Button("Términos") { openURL(CommercialConfig.termsOfUseURL) }
            }
            .font(.caption)
            .foregroundStyle(OG.label3)
        }
        .frame(maxWidth: .infinity)
    }

    private var legalFooter: some View {
        Text(legalText)
            .font(.caption2)
            .foregroundStyle(OG.label3)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var legalText: String {
        var parts: [String] = [
            "El pago se cargará en tu cuenta de Apple al confirmar la compra.",
            "La suscripción se renueva automáticamente salvo que la canceles al menos 24 horas antes del final del periodo.",
        ]
        if let id = selectedProductID,
           let pkg = packages.first(where: { $0.productID == id }) {
            parts.append("Precio de renovación: \(pkg.localizedPrice)\(pkg.isAnnual ? " al año" : " al mes").")
            if pkg.hasFreeTrial, let intro = pkg.introductoryOfferSummary {
                parts.append("\(intro). Tras la prueba se aplica el precio de renovación indicado.")
            }
        }
        parts.append("Puedes gestionar o cancelar en Ajustes → Apple ID → Suscripciones.")
        return parts.joined(separator: " ")
    }

    private func savingsBadge(annual: CommercialPackageInfo, monthly: CommercialPackageInfo?) -> String? {
        guard let monthly,
              let annualPrice = annual.priceValue,
              let monthlyPrice = monthly.priceValue,
              monthlyPrice > 0 else { return nil }
        let yearOfMonthly = monthlyPrice * 12
        guard yearOfMonthly > annualPrice else { return nil }
        let saved = yearOfMonthly - annualPrice
        let pct = (saved / yearOfMonthly) * 100
        let ns = NSDecimalNumber(decimal: pct)
        let value = Int(ns.doubleValue.rounded())
        guard value > 0 else { return nil }
        return "Ahorra \(value)%"
    }
}
